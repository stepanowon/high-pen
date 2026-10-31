using System;
using System.Collections.Generic;
using System.Windows;
using System.Windows.Threading;

namespace HighPen
{
    // Ties the windows and services together and carries out what the toolbar, the settings panel and the
    // shortcuts ask for. Each piece of behaviour lives in its own class; this one decides when it runs.
    class Controller : IToolbarActions, ISettingsActions
    {
        readonly Settings cfg;
        readonly ISettingsStore store;
        readonly OverlayWindow overlay;
        readonly SpotWindow spotWin;
        readonly BreakWindow breakWin;
        readonly Zoomer zoomer;
        readonly ClickHook clickHook;
        readonly IScreenCapture screenCapture;
        readonly ToolState tools = new ToolState();
        readonly InkHistory history;
        readonly SpeechBubbles bubbles;
        readonly HotkeyBindings bindings;
        readonly GlobalHotkeys hotkeys;
        readonly TopmostKeeper topmost = new TopmostKeeper();
        readonly SnippingWatcher snipping = new SnippingWatcher();
        public readonly ToolbarWindow Toolbar;

        AboutWindow aboutWin;
        ToastWindow toastWin;
        HotkeyEditorWindow hotkeyWin;
        UpdateWindow updateWin;
        bool checkingUpdate;
        bool capturing;
        readonly DispatcherTimer monitorTimer = new DispatcherTimer { Interval = TimeSpan.FromSeconds(1) };
        string monitorSignature; // the monitor layout everything was last placed for

        // The zoomed monitor and the part of it being shown (empty bounds = zoom off).
        System.Drawing.Rectangle zoomBounds = System.Drawing.Rectangle.Empty;
        Native.RECT zoomSource;

        public Controller(Settings cfg, ISettingsStore store, OverlayWindow overlay, SpotWindow spotWin,
            BreakWindow breakWin, Zoomer zoomer, ClickHook clickHook, IScreenCapture screenCapture)
        {
            this.cfg = cfg;
            this.store = store;
            this.overlay = overlay;
            this.spotWin = spotWin;
            this.breakWin = breakWin;
            this.zoomer = zoomer;
            this.clickHook = clickHook;
            this.screenCapture = screenCapture;

            bindings = new HotkeyBindings(cfg, store);
            AddCommands();
            Toolbar = new ToolbarWindow(cfg, bindings, this, this);
            hotkeys = new GlobalHotkeys(bindings, Toolbar);
            Toolbar.SourceInitialized += delegate
            {
                hotkeys.Attach();
                RegisterHotkeys(true);
            };

            // the undo history must see a press before text mode handles it
            history = new InkHistory(overlay.Canvas, overlay.Pages);
            bubbles = new SpeechBubbles(overlay, tools, cfg);
            bubbles.Finished = ApplyMode;

            Toolbar.Loaded += delegate
            {
                ApplyMonitor();
                WindowUtil.SetClickThrough(overlay, true);
                ApplyMode();
                ApplySpot();
                ApplyClicks();
                topmost.Reassert();
                monitorTimer.Start();
                // look for a newer version once start-up has settled
                Toolbar.Dispatcher.BeginInvoke(DispatcherPriority.ApplicationIdle, new Action(CheckForUpdate));
            };

            // Keep up with monitors being plugged in or removed (and resolution changes) while running.
            // The notification alone is not enough: it can come before Windows has finished removing an
            // unplugged monitor, so the monitor list is also checked every second.
            Microsoft.Win32.SystemEvents.DisplaySettingsChanged += OnDisplaySettingsChanged;
            monitorTimer.Tick += delegate { if (Monitors.Signature() != monitorSignature) OnMonitorsChanged(); };
            // The hook callback runs on this thread; do the drawing after it has returned.
            clickHook.Clicked = delegate (bool left) { Toolbar.Dispatcher.BeginInvoke(new Action(delegate { OnClick(left); })); };

            zoomer.ViewChanged = OnZoomView;
            zoomer.Factor = cfg.ZoomFactor;

            topmost.Add(zoomer);
            topmost.Add(overlay);
            topmost.Add(spotWin);
            topmost.Add(breakWin);
            topmost.Add(Toolbar);
            // Drawing activates the overlay, which lifts it above the toolbar until the next reassert;
            // without this a toolbar click right after drawing could land on the overlay instead.
            overlay.Activated += delegate { topmost.Reassert(); };
            snipping.Changed = OnSnippingChanged;
            snipping.Start();
            topmost.Start();
        }

        void Save() { store.Save(cfg); }

        // Every command that can have a shortcut, in the order the shortcut editor lists them.
        void AddCommands()
        {
            bindings.Add("Spot", "Ctrl+Alt+S", delegate { return Lang.T("MouseSpot"); }, ToggleSpot);
            bindings.Add("Pen", "Ctrl+Alt+P", delegate { return Lang.T("Pen"); }, TogglePen);
            bindings.Add("Highlighter", "Ctrl+Alt+L", delegate { return Lang.T("Highlighter"); }, ToggleHighlighter);
            bindings.Add("Eraser", "Ctrl+Alt+E", delegate { return Lang.T("Eraser"); }, EraserHotkey);
            bindings.Add("Board", "Ctrl+Alt+B", delegate { return Lang.T("Board"); }, CycleBoard);
            bindings.Add("Undo", "Ctrl+Alt+Z", delegate { return Lang.T("Undo"); }, Undo);
            bindings.Add("Clear", "Ctrl+Alt+C", delegate { return Lang.T("ClearTip"); }, Clear);
            bindings.Add("Bubble", "Ctrl+Alt+T", delegate { return Lang.T("Bubble"); }, ToggleText);
            bindings.Add("Zoom", "Ctrl+Alt+X", delegate { return Lang.T("Zoom"); }, ToggleZoom);
            bindings.Add("ZoomLock", "Ctrl+Shift+X", delegate { return Lang.T("ZoomLock"); }, ToggleZoomLock);
            bindings.Add("Capture", "Ctrl+Alt+F", delegate { return Lang.T("Capture"); }, Capture);
            bindings.Add("Break", "Ctrl+Alt+W", delegate { return Lang.T("BreakTip"); }, ToggleBreak);
            bindings.Add("Settings", "Ctrl+Alt+D", delegate { return Lang.T("Settings"); }, ToggleSettings);
            bindings.Add("Collapse", "Ctrl+Alt+H", delegate { return Lang.T("Collapse"); }, ToggleCollapse);
            bindings.Add("Quit", "Ctrl+Alt+Q", delegate { return Lang.T("Quit"); }, Quit);
            bindings.Add("Monitor", "Ctrl+Alt+M", delegate { return Lang.T("Monitor") + " (" + Lang.T("Cycle") + ")"; }, CycleMonitor);
            bindings.Add("Pressure", "Ctrl+Alt+R", delegate { return Lang.T("Pressure"); }, TogglePressure);
            bindings.Add("Clicks", "Ctrl+Alt+K", delegate { return Lang.T("ClickShow"); }, ToggleClicks);
            for (int i = 0; i < Palette.Hex.Length; i++)
            {
                int ci = i;
                bindings.Add("Color." + Palette.Names[i], HotkeyText.Format(HotkeyText.Ctrl | HotkeyText.Shift, Palette.Keys[i]),
                    delegate { return Lang.T("PenColor") + ": " + Lang.T(Palette.Names[ci]); }, delegate { SetPenColor(ci); });
            }
        }

        // Called when HighPen is launched again while already running.
        public void Summon()
        {
            if (Toolbar.Collapsed) ToggleCollapse();
            topmost.Reassert();
        }

        // ---------- applying state to the windows ----------

        void ApplyMode()
        {
            overlay.ShowPage(tools.Board);
            overlay.SetEditing(tools.PenMode, tools.Eraser, tools.TextMode);
            ApplyPen();
            overlay.SetBackground(tools.Board, tools.PenMode);
            zoomer.Frozen = tools.PenMode;
            ApplyZoomTransform();
            WindowUtil.SetClickThrough(overlay, !tools.PenMode || snipping.Active);
            Toolbar.ShowTools(tools);
            topmost.Reassert();
        }

        void ApplyPen()
        {
            if (tools.Highlighter) overlay.UseHighlighter(Theme.ParseColor(cfg.HighlightColor), cfg.HighlightSize);
            else overlay.UsePen(Theme.ParseColor(cfg.PenColor), cfg.PenSize, cfg.Pressure);
        }

        void ApplySpot()
        {
            spotWin.SetStyle(Theme.ParseColor(cfg.SpotColor), cfg.SpotSize);
            spotWin.SetSpotVisible(cfg.SpotOn);
            Toolbar.ShowSpot(cfg.SpotOn);
        }

        // The mouse hook is only installed while click display is on.
        void ApplyClicks()
        {
            if (cfg.ShowClicks) clickHook.Start();
            else clickHook.Stop();
        }

        void ApplyMonitor()
        {
            ResolveMonitor();
            monitorSignature = Monitors.Signature();
            overlay.MoveToScreen(cfg.Monitor);
            spotWin.MoveToScreen(cfg.Monitor);
            breakWin.MoveToScreen(cfg.Monitor);
            Toolbar.PlaceOnMonitor();
            topmost.Reassert();
        }

        // Uses the monitor the user chose while it is connected, otherwise the primary one; when the chosen
        // monitor comes back, HighPen returns to it. Monitors are found by device name because their order
        // in the list changes as monitors are plugged in and removed.
        void ResolveMonitor()
        {
            if (cfg.MonitorDevice.Length == 0)
            {
                // settings from before the device was saved: the index is all there is
                if (cfg.Monitor < 0 || cfg.Monitor >= Monitors.Count) cfg.Monitor = 0;
                cfg.MonitorDevice = Monitors.Get(cfg.Monitor).DeviceName;
                return;
            }
            int i = Monitors.IndexOf(cfg.MonitorDevice);
            cfg.Monitor = i >= 0 ? i : Monitors.PrimaryIndex;
        }

        void OnZoomView(System.Drawing.Rectangle b, Native.RECT r)
        {
            zoomBounds = b;
            zoomSource = r;
            ApplyZoomTransform();
        }

        // Ink only follows the zoom on the screen page of the monitor being zoomed.
        void ApplyZoomTransform()
        {
            if (zoomBounds.IsEmpty || tools.Board != ToolState.NoBoard || Monitors.Get(cfg.Monitor).Bounds != zoomBounds) overlay.ResetZoom();
            else overlay.MatchZoom(zoomBounds, zoomSource, zoomer.Factor);
        }

        // Rebuilds the toolbar and settings panel, keeping the current mode.
        void RebuildContent()
        {
            Toolbar.Rebuild();
            ShowHotkeyWarning();
            Toolbar.ShowZoom(zoomer.Active, zoomer.Locked);
            Toolbar.ShowBreak(breakWin.Running);
            Toolbar.SettingsPanel.MarkBreakMinutes(cfg.BreakMinutes);
            ApplySpot();
            ApplyMonitor();
            ApplyMode();
        }

        // While the snipping overlay is up, get out of its way: no input capture, no spot,
        // no z-order fighting. Normal state is restored when it closes.
        void OnSnippingChanged(bool active)
        {
            topmost.Suspended = active;
            if (active)
            {
                WindowUtil.SetClickThrough(overlay, true);
                spotWin.SetSpotVisible(false);
            }
            else
            {
                ApplyMode();
                ApplySpot();
            }
        }

        void OnDisplaySettingsChanged(object sender, EventArgs e)
        {
            Toolbar.Dispatcher.BeginInvoke(new Action(OnMonitorsChanged));
        }

        // Monitors were added, removed or rearranged: rebuild the monitor list and re-place everything.
        void OnMonitorsChanged()
        {
            // the zoomed monitor and the pointer clip may no longer be valid
            if (zoomer.Active) zoomer.Stop();
            RebuildContent();
        }

        void OnClick(bool left)
        {
            // while drawing every pen stroke would be a click
            if (!cfg.ShowClicks || tools.PenMode || snipping.Active) return;
            Native.POINT p;
            if (!Native.GetCursorPos(out p)) return;
            spotWin.ShowRipple(p, Theme.ParseColor(cfg.SpotColor), left);
        }

        // ---------- tools ----------

        public void ToggleSpot() { cfg.SpotOn = !cfg.SpotOn; ApplySpot(); Save(); }
        public void TogglePen() { tools.TogglePen(); ApplyMode(); }
        public void ToggleHighlighter() { tools.ToggleHighlighter(); ApplyMode(); }
        public void ToggleEraser() { tools.ToggleEraser(); ApplyMode(); }
        public void ToggleText() { tools.ToggleText(); ApplyMode(); }

        // First press enters eraser mode; pressing again while erasing wipes all strokes and speech bubbles on this page.
        void EraserHotkey()
        {
            if (tools.Eraser) Clear();
            else ToggleEraser();
        }

        public void CycleBoard()
        {
            tools.CycleBoard();
            // keep the pen visible against the board colour
            System.Windows.Media.Color c = Theme.ParseColor(cfg.PenColor);
            if (tools.Board == ToolState.BlackBoard && c == System.Windows.Media.Colors.Black) cfg.PenColor = "#FFFFFF";
            else if (tools.Board == ToolState.WhiteBoard && c == System.Windows.Media.Colors.White) cfg.PenColor = "#000000";
            ApplyMode();
        }

        public void Undo() { history.Undo(tools.Board); }

        // One undo step: undo brings back the strokes and speech bubbles together.
        public void Clear()
        {
            int page = tools.Board;
            List<UIElement> removed = overlay.ClearBubbles(page);
            history.Clear(page, removed.Count == 0 ? null : (Action)delegate { overlay.RestoreBubbles(page, removed); });
        }

        // Colour shortcuts change the tool in use: the highlighter while it is on, otherwise the pen.
        void SetPenColor(int i)
        {
            if (tools.Highlighter)
            {
                cfg.HighlightColor = Palette.Hex[i];
                Toolbar.SettingsPanel.MarkHighlightColor(cfg.HighlightColor);
            }
            else
            {
                cfg.PenColor = Palette.Hex[i];
                Toolbar.SettingsPanel.MarkPenColor(cfg.PenColor);
            }
            Save();
            ApplyPen();
        }

        public void ToggleZoom()
        {
            if (zoomer.Active) zoomer.Stop();
            else zoomer.Start(new IntPtr[] { WindowUtil.Handle(Toolbar), WindowUtil.Handle(overlay), WindowUtil.Handle(spotWin), WindowUtil.Handle(breakWin) });
            Toolbar.ShowZoom(zoomer.Active, zoomer.Locked);
            topmost.Reassert();
        }

        // Keeps the zoomed view where it is while the pointer moves on (and lets it follow again). Only while zoomed.
        void ToggleZoomLock()
        {
            if (!zoomer.Active) return;
            zoomer.Locked = !zoomer.Locked;
            Toolbar.ShowZoom(true, zoomer.Locked);
        }

        public void ToggleBreak()
        {
            if (breakWin.Running) breakWin.Stop();
            else breakWin.Start(cfg.BreakMinutes);
            Toolbar.ShowBreak(breakWin.Running);
            topmost.Reassert();
        }

        // ---------- toolbar ----------

        public void ToggleSettings() { Toolbar.SettingsOpen = !Toolbar.SettingsOpen; ApplyMode(); }
        public void ToggleCollapse() { Toolbar.ToggleCollapse(); ApplyMode(); }

        public void BarMoved()
        {
            int x, y;
            if (!Toolbar.GetBarOffset(out x, out y)) return;
            cfg.BarX = x;
            cfg.BarY = y;
            Save();
        }

        void CycleMonitor() { SetMonitor((cfg.Monitor + 1) % Monitors.Count); }

        public void Quit()
        {
            if (hotkeyWin != null) hotkeyWin.Close();
            zoomer.Stop();
            clickHook.Stop();
            monitorTimer.Stop();
            Microsoft.Win32.SystemEvents.DisplaySettingsChanged -= OnDisplaySettingsChanged;
            Save();
            Application.Current.Shutdown();
        }

        // ---------- settings panel ----------

        public void PenStyleChanged() { ApplyPen(); Save(); }
        public void SpotStyleChanged() { ApplySpot(); Save(); }

        public void SetMonitor(int i)
        {
            string device = Monitors.Get(i).DeviceName;
            // choosing the monitor HighPen fell back to also makes it the chosen one
            if (i == cfg.Monitor && device == cfg.MonitorDevice) return;
            // zoom belongs to the previous monitor (and confines the pointer to it)
            if (zoomer.Active) { zoomer.Stop(); Toolbar.ShowZoom(false, false); }
            cfg.Monitor = i;
            cfg.MonitorDevice = device;
            Save();
            ApplyMonitor();
        }

        public void TogglePressure()
        {
            cfg.Pressure = !cfg.Pressure;
            Save();
            Toolbar.SettingsPanel.ShowPressure(cfg.Pressure);
            ApplyPen();
        }

        public void ToggleClicks()
        {
            cfg.ShowClicks = !cfg.ShowClicks;
            Save();
            Toolbar.SettingsPanel.ShowClicks(cfg.ShowClicks);
            ApplyClicks();
        }

        public void SetZoomFactor(double f)
        {
            cfg.ZoomFactor = f;
            Save();
            zoomer.Factor = f;
            Toolbar.SettingsPanel.MarkZoomFactor(f);
            Toolbar.UpdateZoomTip();
        }

        // A break already running keeps its length.
        public void SetBreakMinutes(int minutes)
        {
            cfg.BreakMinutes = BreakTimes.Clamp(minutes);
            Save();
            Toolbar.SettingsPanel.MarkBreakMinutes(cfg.BreakMinutes);
        }

        // Rebuilds the toolbar in the new language, keeping the current mode.
        public void SetLanguage(int i)
        {
            Lang.Cur = i;
            cfg.Language = Lang.Codes[i];
            Save();
            RebuildContent();
        }

        // ---------- shortcuts ----------

        void RegisterHotkeys(bool startup)
        {
            hotkeys.RegisterAll();
            ShowHotkeyWarning();
            // tell the user once, after start-up has settled
            if (startup && hotkeys.Failed.Count > 0)
                Toolbar.Dispatcher.BeginInvoke(DispatcherPriority.ApplicationIdle, new Action(delegate { ShowToast(hotkeys.WarningText(), null, 8); }));
        }

        void ShowHotkeyWarning()
        {
            Toolbar.SettingsPanel.ShowHotkeyWarning(hotkeys.Failed.Count > 0 ? hotkeys.WarningText() : null);
        }

        // HighPen's own shortcuts are released while the editor is open so pressing them reaches it.
        public void ShowHotkeyEditor()
        {
            if (hotkeyWin != null) { hotkeyWin.Activate(); return; }
            hotkeys.UnregisterAll();
            HotkeyEditorWindow w = new HotkeyEditorWindow(bindings, hotkeys, Monitors.Get(cfg.Monitor).WorkingArea);
            topmost.Track(w);
            w.Closed += delegate
            {
                hotkeyWin = null;
                RegisterHotkeys(false);
                RebuildContent(); // tooltips show the new shortcuts
                if (hotkeys.Failed.Count > 0) ShowToast(hotkeys.WarningText(), null, 8);
            };
            hotkeyWin = w;
            w.Show();
        }

        // ---------- updates ----------

        // At start-up: only a newer version is worth telling about.
        void CheckForUpdate()
        {
            if (Updater.Supported) Updater.Check(delegate (UpdateInfo u, string error) { if (u != null) ShowUpdate(u); });
        }

        // The Update check button: shows the new version, or says HighPen is up to date or could not check.
        public void CheckForUpdates()
        {
            if (checkingUpdate) return;
            checkingUpdate = true;
            Updater.Check(delegate (UpdateInfo u, string error)
            {
                checkingUpdate = false;
                if (u != null) ShowUpdate(u);
                else ShowToast(error ?? string.Format(Lang.T("UpdateLatest"), AppInfo.AppVersion), null, 4);
            });
        }

        // Offers the new version, which is installed from the Microsoft Store.
        void ShowUpdate(UpdateInfo u)
        {
            if (updateWin != null) { updateWin.BringTopmost(); return; }
            UpdateWindow w = new UpdateWindow(u, Monitors.Get(cfg.Monitor).WorkingArea);
            topmost.Track(w);
            w.Closed += delegate { updateWin = null; };
            updateWin = w;
            w.Show();
        }

        // ---------- popups ----------

        public void ShowAbout()
        {
            if (aboutWin != null) { aboutWin.Close(); return; }
            AboutWindow w = new AboutWindow(Monitors.Get(cfg.Monitor).WorkingArea);
            topmost.Track(w);
            w.Closed += delegate { aboutWin = null; };
            aboutWin = w;
            w.Show();
        }

        void ShowToast(string text, string selectPath, double seconds)
        {
            if (toastWin != null) toastWin.Close();
            ToastWindow w = new ToastWindow(text, selectPath, seconds, Monitors.Get(cfg.Monitor).WorkingArea);
            topmost.Track(w);
            w.Closed += delegate { if (toastWin == w) toastWin = null; };
            toastWin = w;
            w.Show();
        }

        // Captures the selected monitor as shown (screen, board, ink, notes, zoom) without the toolbar and spot.
        public void Capture()
        {
            if (capturing) return;
            capturing = true;
            if (toastWin != null) toastWin.Close();
            Toolbar.Opacity = 0;
            spotWin.SetSpotVisible(false);
            // give the compositor a moment to drop the toolbar and spot from the screen
            DispatcherTimer t = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(200) };
            t.Tick += delegate
            {
                t.Stop();
                CaptureResult r = screenCapture.Capture(Monitors.Get(cfg.Monitor).Bounds);
                Toolbar.Opacity = 1;
                ApplySpot();
                capturing = false;
                if (r.Path == null) ShowToast(Lang.T("CaptureFailed"), null, 4);
                else ShowToast(string.Format(Lang.T(r.Copied ? "Saved" : "SavedOnly"), r.Path), r.Path, 5);
            };
            t.Start();
        }
    }
}
