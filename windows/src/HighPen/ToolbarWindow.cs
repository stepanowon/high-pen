using System;
using System.Runtime.InteropServices;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Interop;
using System.Windows.Media;
using System.Windows.Shapes;
using System.Windows.Threading;

namespace HighPen
{
    // What the toolbar buttons ask of the app.
    interface IToolbarActions
    {
        void ToggleSpot();
        void TogglePen();
        void ToggleHighlighter();
        void ToggleEraser();
        void CycleBoard();
        void Undo();
        void Clear();
        void ToggleText();
        void ToggleZoom();
        void Capture();
        void ToggleBreak();
        void ToggleSettings();
        void ShowAbout();
        void ToggleCollapse();
        void Quit();
        // The bar was dragged somewhere else.
        void BarMoved();
    }

    // The floating tool bar and the settings panel beside it. It only shows state and reports clicks;
    // the app (IToolbarActions) decides what they do.
    class ToolbarWindow : Window, ITopmost
    {
        const string GlyphCollapse = "", GlyphExpand = "";
        // the bar, and what is left of it when collapsed: the arrow and the border
        const double BarWidth = 84, ArrowWidth = 28, CollapsedWidth = ArrowWidth + 2;

        readonly Settings cfg;
        readonly HotkeyBindings bindings;
        readonly IToolbarActions actions;
        readonly ISettingsActions settingsActions;

        // Whether the user wants the settings panel; it shows only while the bar is expanded.
        public bool SettingsOpen;
        public bool Collapsed { get; private set; }
        public SettingsPanel SettingsPanel { get; private set; }

        StackPanel buttons, barRow;
        Border mainPanel, grip;
        TextBlock arrow, boardLabel, zoomLabel;
        Border zoomBtn, bubbleBtn, spotBtn, penBtn, highlightBtn, eraserBtn, boardBtn, setBtn, breakBtn;
        // The settings panel opens to the right of the bar, or to its left when it would run past
        // the right edge of the monitor. The window moves so the bar itself stays where it is.
        bool settingsLeft;

        public ToolbarWindow(Settings cfg, HotkeyBindings bindings, IToolbarActions actions, ISettingsActions settingsActions)
        {
            this.cfg = cfg;
            this.bindings = bindings;
            this.actions = actions;
            this.settingsActions = settingsActions;

            WindowStyle = WindowStyle.None;
            AllowsTransparency = true;
            Background = Brushes.Transparent;
            ShowInTaskbar = true; // lets the user pin the running app to the taskbar
            Title = "HighPen";
            Topmost = true;
            ShowActivated = false;
            SizeToContent = SizeToContent.WidthAndHeight;
            ResizeMode = ResizeMode.NoResize;
            Left = SystemParameters.WorkArea.Right - 80;
            Top = SystemParameters.WorkArea.Top + 140;

            BuildContent();

            SourceInitialized += delegate
            {
                WindowUtil.AddExStyle(this, Native.WS_EX_NOACTIVATE);
                HwndSource.FromHwnd(WindowUtil.Handle(this)).AddHook(MoveHook);
            };
            // SizeChanged comes before the window itself is resized, so check once the resize has happened
            SizeChanged += delegate { Dispatcher.BeginInvoke(DispatcherPriority.Loaded, new Action(KeepOnMonitor)); };
        }

        public void BringTopmost()
        {
            WindowUtil.BringTopmost(this);
        }

        // Rebuilds the bar and settings panel (new language, shortcuts or monitors), staying collapsed or expanded.
        public void Rebuild()
        {
            BuildContent();
            ShowCollapsed();
        }

        // Collapsed, only the arrow is left, so the title no longer covers what is underneath.
        public void ToggleCollapse()
        {
            Collapsed = !Collapsed;
            ShowCollapsed();
        }

        void ShowCollapsed()
        {
            buttons.Visibility = Collapsed ? Visibility.Collapsed : Visibility.Visible;
            grip.Visibility = Collapsed ? Visibility.Collapsed : Visibility.Visible;
            mainPanel.Width = Collapsed ? CollapsedWidth : BarWidth;
            arrow.Text = Collapsed ? GlyphExpand : GlyphCollapse;
        }

        public void ShowTools(ToolState t)
        {
            Theme.Highlight(penBtn, t.PenActive);
            Theme.Highlight(highlightBtn, t.HighlighterActive);
            Theme.Highlight(eraserBtn, t.Eraser);
            Theme.Highlight(bubbleBtn, t.TextMode);
            Theme.Highlight(boardBtn, t.Board != ToolState.NoBoard);
            Theme.Highlight(setBtn, SettingsOpen);
            boardLabel.Text = Lang.T(t.Board == ToolState.NoBoard ? "Board" : (t.Board == ToolState.WhiteBoard ? "WhiteBoard" : "BlackBoard"));
            ShowSettingsPanel(SettingsOpen && !Collapsed);
        }

        public void ShowSpot(bool on) { Theme.Highlight(spotBtn, on); }
        // While the zoomed view is locked the button reads "Locked".
        public void ShowZoom(bool on, bool locked)
        {
            Theme.Highlight(zoomBtn, on);
            zoomLabel.Text = Lang.T(on && locked ? "ZoomLocked" : "Zoom");
        }

        public void ShowBreak(bool on) { Theme.Highlight(breakBtn, on); }

        public void UpdateZoomTip()
        {
            Tip(zoomBtn, string.Format(Lang.T("ZoomTip"), cfg.ZoomFactor.ToString(System.Globalization.CultureInfo.InvariantCulture)), "Zoom");
            zoomBtn.ToolTip += "\n" + Lang.T("ZoomLock") + bindings.KeySuffix("ZoomLock");
        }

        // ---------- placement: the toolbar stays inside the working area of the selected monitor ----------

        // Puts the bar at its saved offset on the selected monitor.
        public void PlaceOnMonitor()
        {
            System.Drawing.Rectangle wa = Monitors.Get(cfg.Monitor).WorkingArea;
            int bx = cfg.BarX, by = cfg.BarY;
            if (bx < 0 || by < 0 || bx > wa.Width - 40 || by > wa.Height - 40) { bx = 20; by = 20; }
            ShowSettingsPanel(false);
            WindowUtil.PlaceRect(this, wa.Left + bx, wa.Top + by, 0, 0, false);
            ShowSettingsPanel(SettingsOpen && !Collapsed);
            KeepOnMonitor();
            SettingsPanel.MarkMonitor(cfg.Monitor);
        }

        // Where the bar itself (not a settings panel on its left) sits within the monitor's working area.
        public bool GetBarOffset(out int x, out int y)
        {
            x = y = 0;
            Native.RECT r;
            if (!WindowUtil.GetRect(this, out r)) return false;
            System.Drawing.Rectangle wa = Monitors.Get(cfg.Monitor).WorkingArea;
            x = r.Left - wa.Left + (settingsLeft ? SettingsPanelPx() : 0);
            y = r.Top - wa.Top;
            return true;
        }

        void ClampToMonitor(ref Native.RECT r)
        {
            System.Drawing.Rectangle wa = Monitors.Get(cfg.Monitor).WorkingArea;
            int w = r.Right - r.Left, h = r.Bottom - r.Top;
            int x = Math.Max(wa.Left, Math.Min(wa.Right - w, r.Left));
            int y = Math.Max(wa.Top, Math.Min(wa.Bottom - h, r.Top));
            r.Left = x; r.Top = y; r.Right = x + w; r.Bottom = y + h;
        }

        // While dragging: adjust the proposed rect before the window moves.
        IntPtr MoveHook(IntPtr hwnd, int msg, IntPtr wParam, IntPtr lParam, ref bool handled)
        {
            if (msg != Native.WM_MOVING) return IntPtr.Zero;
            Native.RECT r = (Native.RECT)Marshal.PtrToStructure(lParam, typeof(Native.RECT));
            ClampToMonitor(ref r);
            Marshal.StructureToPtr(r, lParam, false);
            handled = true;
            return (IntPtr)1;
        }

        // After a size or monitor change (expanding, opening settings), pull the toolbar back inside.
        void KeepOnMonitor()
        {
            Native.RECT r;
            if (WindowUtil.Handle(this) == IntPtr.Zero || !WindowUtil.GetRect(this, out r)) return;
            Native.RECT c = r;
            ClampToMonitor(ref c);
            if (c.Left != r.Left || c.Top != r.Top) WindowUtil.PlaceRect(this, c.Left, c.Top, 0, 0, false);
        }

        int SettingsPanelPx() { return ToPx(SettingsPanel.ActualWidth); }
        int ToPx(double dip) { return (int)Math.Round(dip * VisualTreeHelper.GetDpi(this).DpiScaleX); }

        void ShowSettingsPanel(bool show)
        {
            if (show == (SettingsPanel.Visibility == Visibility.Visible)) return;
            Native.RECT r;
            bool placed = WindowUtil.GetRect(this, out r);
            if (!show)
            {
                int w = SettingsPanelPx();
                SettingsPanel.Visibility = Visibility.Collapsed;
                if (!settingsLeft) return;
                SetSettingsSide(false);
                UpdateLayout(); // shrink first, so the window never pokes past the monitor edge
                if (placed) WindowUtil.PlaceRect(this, r.Left + w, r.Top, 0, 0, false);
                return;
            }
            SettingsPanel.Visibility = Visibility.Visible;
            if (!placed || !IsLoaded) return;
            UpdateLayout();
            int pw = SettingsPanelPx();
            // the window rect may not have caught up with the layout yet, so use the bar's own width
            if (r.Left + ToPx(mainPanel.ActualWidth) + pw <= Monitors.Get(cfg.Monitor).WorkingArea.Right) return;
            SetSettingsSide(true);
            WindowUtil.PlaceRect(this, r.Left - pw, r.Top, 0, 0, false);
        }

        void SetSettingsSide(bool left)
        {
            settingsLeft = left;
            barRow.Children.Remove(SettingsPanel);
            barRow.Children.Insert(left ? 0 : barRow.Children.Count, SettingsPanel);
            SettingsPanel.BorderThickness = left ? new Thickness(1, 1, 0, 1) : new Thickness(0, 1, 1, 1);
        }

        // ---------- UI building ----------

        void BuildContent()
        {
            buttons = new StackPanel(); // a fresh panel: the old one is still parented to the previous toolbar
            barRow = new StackPanel { Orientation = Orientation.Horizontal };
            mainPanel = BuildMain();
            barRow.Children.Add(mainPanel);
            SettingsPanel = new SettingsPanel(cfg, bindings, settingsActions);
            SettingsPanel.Visibility = Visibility.Collapsed;
            settingsLeft = false;
            barRow.Children.Add(SettingsPanel);
            Content = barRow;
        }

        Border BuildMain()
        {
            StackPanel col = new StackPanel();

            // header: collapse arrow + grip (drag). The arrow is on the left so that, collapsed, it stays put.
            Grid header = new Grid();
            header.Height = 30;
            header.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            header.ColumnDefinitions.Add(new ColumnDefinition());
            grip = new Border();
            grip.Background = new SolidColorBrush(Color.FromRgb(0x4A, 0x52, 0x2A));
            grip.Cursor = Cursors.SizeAll;
            grip.MouseLeftButtonDown += delegate
            {
                try { DragMove(); } catch { }
                actions.BarMoved();
            };
            grip.Child = new TextBlock { Text = "HighPen", Foreground = Brushes.White, FontSize = 11, FontWeight = FontWeights.SemiBold, VerticalAlignment = VerticalAlignment.Center, Margin = new Thickness(6, 0, 0, 0), IsHitTestVisible = false, TextWrapping = TextWrapping.NoWrap };
            Border ab = new Border { Width = ArrowWidth, Background = Theme.Idle, Cursor = Cursors.Hand };
            arrow = new TextBlock { Text = GlyphCollapse, FontFamily = Theme.Icons, Foreground = Brushes.White, FontSize = 14, HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Center };
            ab.Child = arrow;
            ab.MouseLeftButtonUp += delegate { actions.ToggleCollapse(); };
            Grid.SetColumn(grip, 1);
            header.Children.Add(grip);
            header.Children.Add(ab);
            col.Children.Add(header);

            spotBtn = AddButton("◎", false, Lang.T("Spot"), Lang.T("MouseSpot"), "Spot", actions.ToggleSpot);
            penBtn = AddButton("", true, Lang.T("Pen"), Lang.T("Pen"), "Pen", actions.TogglePen);
            highlightBtn = AddButton("", true, Lang.T("Highlighter"), Lang.T("Highlighter"), "Highlighter", actions.ToggleHighlighter);
            eraserBtn = AddButton("", true, Lang.T("Eraser"), null, null, actions.ToggleEraser);
            eraserBtn.ToolTip = Lang.T("Eraser") + bindings.KeySuffix("Eraser") + "\n" + Lang.T("EraserTip");
            boardBtn = AddButton("▭", false, Lang.T("Board"), Lang.T("BoardTip"), "Board", actions.CycleBoard);
            boardLabel = (TextBlock)((StackPanel)boardBtn.Child).Children[1];
            AddButton("", true, Lang.T("Undo"), Lang.T("Undo"), "Undo", actions.Undo);
            AddButton("", true, Lang.T("Clear"), Lang.T("ClearTip"), "Clear", actions.Clear);
            bubbleBtn = AddButton("", true, Lang.T("Bubble"), Lang.T("Bubble"), "Bubble", actions.ToggleText);
            zoomBtn = AddButton("", true, Lang.T("Zoom"), null, null, actions.ToggleZoom);
            zoomLabel = (TextBlock)((StackPanel)zoomBtn.Child).Children[1];
            UpdateZoomTip();
            AddButton("", true, Lang.T("Capture"), Lang.T("CaptureTip"), "Capture", actions.Capture);
            breakBtn = AddButton("", true, Lang.T("Break"), Lang.T("BreakTip"), "Break", actions.ToggleBreak);
            setBtn = AddButton("", true, Lang.T("Settings"), Lang.T("Settings"), "Settings", actions.ToggleSettings);
            Border aboutBtn = AddButton("", true, Lang.T("About"), null, null, actions.ShowAbout);
            aboutBtn.ToolTip = Lang.T("AboutTip");
            Tip(ab, Lang.T("Collapse"), "Collapse");

            // red close button
            Border close = new Border { Height = 52, Background = Theme.Idle, Cursor = Cursors.Hand, Margin = new Thickness(0, 1, 0, 0) };
            Grid cg = new Grid { Width = 30, Height = 30, HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Center };
            cg.Children.Add(new Ellipse { Fill = new SolidColorBrush(Color.FromRgb(0xD9, 0x30, 0x25)), Stroke = Brushes.White, StrokeThickness = 2 });
            cg.Children.Add(new TextBlock { Text = "", FontFamily = Theme.Icons, Foreground = Brushes.White, FontSize = 14, FontWeight = FontWeights.Bold, HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Center });
            close.Child = cg;
            Tip(close, Lang.T("Quit"), "Quit");
            close.MouseLeftButtonUp += delegate { actions.Quit(); };
            buttons.Children.Add(close);

            col.Children.Add(buttons);

            return new Border { Width = BarWidth, Background = Theme.PanelBg, BorderBrush = Theme.Line, BorderThickness = new Thickness(1), Child = col };
        }

        // A tool button (icon over label) appended to the bar. tip/commandId give the tooltip and its shortcut;
        // pass null to set the tooltip yourself.
        Border AddButton(string glyph, bool segoe, string label, string tip, string commandId, Action click)
        {
            StackPanel sp = new StackPanel { VerticalAlignment = VerticalAlignment.Center };
            sp.Children.Add(new TextBlock { Text = glyph, Foreground = Brushes.White, FontSize = 20, HorizontalAlignment = HorizontalAlignment.Center, FontFamily = segoe ? Theme.Icons : Theme.Symbols });
            sp.Children.Add(new TextBlock { Text = label, Foreground = Brushes.White, FontSize = 10, HorizontalAlignment = HorizontalAlignment.Center });
            Border b = new Border { Height = 52, Background = Theme.Idle, Cursor = Cursors.Hand, Margin = new Thickness(0, 1, 0, 0), Child = sp };
            b.MouseLeftButtonUp += delegate { click(); };
            if (tip != null) Tip(b, tip, commandId);
            buttons.Children.Add(b);
            return b;
        }

        void Tip(Border b, string name, string commandId)
        {
            b.ToolTip = name + bindings.KeySuffix(commandId);
        }
    }
}
