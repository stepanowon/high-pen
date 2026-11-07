using System;
using System.Collections.Generic;
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
        const double ButtonHeight = 52;
        // Lying along an edge the buttons show only their icons, to keep the bar low; the tooltips still name them.
        const double WideButtonWidth = 56, WideCloseWidth = 44, WideHeight = 36;
        // How far from the edge of the working area the pointer takes the bar onto that edge, and off it again.
        const double EdgeEnter = 30, EdgeLeave = 60;
        static readonly Brush GripBg = Theme.Frozen(0x4A, 0x52, 0x2A);
        static readonly Brush CloseRed = Theme.Frozen(0xD9, 0x30, 0x25);

        readonly Settings cfg;
        readonly HotkeyBindings bindings;
        readonly IToolbarActions actions;
        readonly ISettingsActions settingsActions;

        // Whether the user wants the settings panel; it shows only while the bar is expanded.
        public bool SettingsOpen;
        public bool Collapsed { get; private set; }
        public SettingsPanel SettingsPanel { get; private set; }
        // The edge the bar lies along now (Settings.BarFree, BarTop or BarBottom).
        public int Edge { get; private set; }
        bool Horizontal { get { return Edge != Settings.BarFree; } }

        StackPanel buttons, barRow, barColumn;
        Grid header;
        Border mainPanel, grip, arrowBtn;
        // At the right end of the working area the arrow goes to the right of the title, so that it stays in the corner when collapsed.
        bool arrowRight;
        TextBlock arrow, boardLabel, zoomLabel;
        Border zoomBtn, bubbleBtn, spotBtn, penBtn, highlightBtn, eraserBtn, boardBtn, setBtn, breakBtn;
        readonly List<TextBlock> buttonLabels = new List<TextBlock>();
        Border closeBtn;
        // The label on the zoom button says so while the view is locked; along an edge only the tooltip can.
        bool zoomLocked;
        // Upright, the settings panel opens to the right of the bar, or to its left when it would run past
        // the right edge of the monitor. Along an edge it opens on the side away from that edge.
        // The window moves so the bar itself stays where it is.
        bool settingsBefore;
        // The working area read once when a drag starts: the pointer moves many times a second.
        System.Drawing.Rectangle? dragArea;
        bool dragging, dragMoved, dragFitsEdge;
        Native.POINT dragStart;
        // Where the bar was grabbed, from its top left.
        int grabX, grabY;

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
            Native.RECT r;
            bool move = WindowUtil.GetRect(this, out r) && arrowRight;
            int shift = ToPx(BarWidth - CollapsedWidth);
            Collapsed = !Collapsed;
            // the arrow stays where it is: its side of the bar is what stays put
            if (move && !Collapsed) WindowUtil.PlaceRect(this, r.Left - shift, r.Top, 0, 0, false);
            ShowCollapsed();
            if (move && Collapsed)
            {
                UpdateLayout(); // shrink first, so the window never pokes past the monitor edge
                WindowUtil.PlaceRect(this, r.Left + shift, r.Top, 0, 0, false);
            }
        }

        void ShowCollapsed()
        {
            buttons.Visibility = Collapsed ? Visibility.Collapsed : Visibility.Visible;
            grip.Visibility = Collapsed ? Visibility.Collapsed : Visibility.Visible;
            mainPanel.Width = Collapsed ? CollapsedWidth : (Horizontal ? double.NaN : BarWidth);
            // along an edge the arrow keeps its height, so it stays put on the bottom edge too
            header.Width = !Horizontal ? double.NaN : (Collapsed ? ArrowWidth : BarWidth - 2);
            // upright at the right end it collapses to the right; along an edge the buttons are always to the right of it
            bool mirrored = arrowRight && !Horizontal;
            arrow.Text = Collapsed != mirrored ? GlyphExpand : GlyphCollapse;
        }

        // Lays the bar out upright or along an edge. The window is moved by the caller.
        void ApplyOrientation()
        {
            bool h = Horizontal;
            barRow.Orientation = h ? Orientation.Vertical : Orientation.Horizontal;
            barColumn.Orientation = h ? Orientation.Horizontal : Orientation.Vertical;
            buttons.Orientation = h ? Orientation.Horizontal : Orientation.Vertical;
            header.Height = h ? WideHeight : 30;
            // no border on the screen's edge: a pointer thrown against it lands on the buttons
            mainPanel.BorderThickness = new Thickness(1, Edge == Settings.BarTop ? 0 : 1, 1, Edge == Settings.BarBottom ? 0 : 1);
            foreach (UIElement e in buttons.Children)
            {
                Border b = (Border)e;
                b.Width = !h ? double.NaN : (b == closeBtn ? WideCloseWidth : WideButtonWidth);
                b.Height = h ? WideHeight : ButtonHeight;
                b.Margin = h ? new Thickness(1, 0, 0, 0) : new Thickness(0, 1, 0, 0);
            }
            foreach (TextBlock label in buttonLabels) label.Visibility = h ? Visibility.Collapsed : Visibility.Visible;
            // along an edge the panel sits by the settings button, at the end of the bar
            SettingsPanel.HorizontalAlignment = h ? HorizontalAlignment.Right : HorizontalAlignment.Stretch;
            SettingsPanel.SetWide(h);
            ApplyArrowSide();
            SetSettingsSide(settingsBefore);
            ShowCollapsed();
        }

        void ApplyArrowSide()
        {
            header.ColumnDefinitions[0].Width = arrowRight ? new GridLength(1, GridUnitType.Star) : GridLength.Auto;
            header.ColumnDefinitions[1].Width = arrowRight ? GridLength.Auto : new GridLength(1, GridUnitType.Star);
            Grid.SetColumn(grip, arrowRight ? 0 : 1);
            Grid.SetColumn(arrowBtn, arrowRight ? 1 : 0);
        }

        // Puts the arrow on the side that suits where the window now is. Collapsed it stays as it is.
        void UpdateArrowSide(int windowLeft)
        {
            if (Collapsed) return;
            int barLeft = windowLeft + (settingsBefore && !Horizontal ? SettingsPanelPx() : 0);
            bool right = barLeft + ToPx(mainPanel.ActualWidth) >= (dragArea ?? WorkArea).Right;
            if (right == arrowRight) return;
            arrowRight = right;
            ApplyArrowSide();
            ShowCollapsed();
        }

        // The bar's width along an edge: the header, the buttons with their gaps, and the close button.
        double WideWidth() { return BarWidth + (buttons.Children.Count - 1) * (WideButtonWidth + 1) + WideCloseWidth + 1; }

        bool FitsAlongEdge() { return ToPx(WideWidth()) <= WorkArea.Width; }

        public void ShowTools(ToolState t)
        {
            Theme.Highlight(penBtn, t.PenActive);
            Theme.Highlight(highlightBtn, t.HighlighterActive);
            Theme.Highlight(eraserBtn, t.Eraser);
            Theme.Highlight(bubbleBtn, t.TextMode);
            Theme.Highlight(boardBtn, t.Board != ToolState.NoBoard);
            Theme.Highlight(setBtn, SettingsOpen);
            boardLabel.Text = Lang.T(t.Board == ToolState.NoBoard ? "Board" : (t.Board == ToolState.WhiteBoard ? "WhiteBoard" : "BlackBoard"));
            Tip(boardBtn, Lang.T("BoardTip"), "Board");
            if (t.Board != ToolState.NoBoard) boardBtn.ToolTip = boardLabel.Text + "\n" + boardBtn.ToolTip;
            ShowSettingsPanel(SettingsOpen && !Collapsed);
        }

        public void ShowSpot(bool on) { Theme.Highlight(spotBtn, on); }
        // While the zoomed view is locked the button reads "Locked".
        public void ShowZoom(bool on, bool locked)
        {
            Theme.Highlight(zoomBtn, on);
            zoomLabel.Text = Lang.T(on && locked ? "ZoomLocked" : "Zoom");
            zoomLocked = on && locked;
            UpdateZoomTip();
        }

        public void ShowBreak(bool on) { Theme.Highlight(breakBtn, on); }

        public void UpdateZoomTip()
        {
            Tip(zoomBtn, string.Format(Lang.T("ZoomTip"), cfg.ZoomFactor.ToString(System.Globalization.CultureInfo.InvariantCulture)), "Zoom");
            zoomBtn.ToolTip += "\n" + Lang.T("ZoomLock") + bindings.KeySuffix("ZoomLock");
            if (zoomLocked) zoomBtn.ToolTip = Lang.T("ZoomLocked") + "\n" + zoomBtn.ToolTip;
        }

        // ---------- placement: the toolbar stays inside the working area of the selected monitor ----------

        System.Drawing.Rectangle WorkArea { get { return Monitors.Get(cfg.Monitor).WorkingArea; } }

        // Puts the bar at its saved offset on the selected monitor.
        public void PlaceOnMonitor()
        {
            System.Drawing.Rectangle wa = WorkArea;
            ShowSettingsPanel(false);
            // the saved edge comes back on a monitor where the bar fits along it
            Edge = cfg.BarEdge != Settings.BarFree && FitsAlongEdge() ? cfg.BarEdge : Settings.BarFree;
            ApplyOrientation();
            UpdateLayout();
            int bx = cfg.BarX, by = cfg.BarY;
            if (bx < 0 || bx > wa.Width - 40 || by < 0 || by > wa.Height - 40) { bx = 20; by = 20; }
            int collapsedShift = Collapsed && arrowRight ? ToPx(BarWidth - CollapsedWidth) : 0;
            WindowUtil.PlaceRect(this, wa.Left + bx + collapsedShift, wa.Top + by, 0, 0, false);
            ShowSettingsPanel(SettingsOpen && !Collapsed);
            KeepOnMonitor();
            SettingsPanel.MarkMonitor(cfg.Monitor);
        }

        // Where the bar itself (not a settings panel before it) sits within the monitor's working area.
        public bool GetBarOffset(out int x, out int y)
        {
            x = y = 0;
            Native.RECT r;
            if (!WindowUtil.GetRect(this, out r)) return false;
            System.Drawing.Rectangle wa = WorkArea;
            x = r.Left - wa.Left + (settingsBefore && !Horizontal ? SettingsPanelPx() : 0);
            y = r.Top - wa.Top + (settingsBefore && Horizontal ? SettingsPanelPx() : 0);
            return true;
        }

        void ClampToMonitor(ref Native.RECT r)
        {
            System.Drawing.Rectangle wa = dragArea ?? WorkArea;
            int w = r.Right - r.Left, h = r.Bottom - r.Top;
            int x = Math.Max(wa.Left, Math.Min(wa.Right - w, r.Left));
            int y = Math.Max(wa.Top, Math.Min(wa.Bottom - h, r.Top));
            if (Edge == Settings.BarTop) y = wa.Top;
            else if (Edge == Settings.BarBottom) y = wa.Bottom - h;
            r.Left = x; r.Top = y; r.Right = x + w; r.Bottom = y + h;
        }

        // grabbed: where the button went down, from the bar's top left. The pointer may have moved on since.
        void StartDrag(Point grabbed)
        {
            Native.POINT p;
            if (!Native.GetCursorPos(out p)) return;
            dragArea = WorkArea;
            dragStart = p;
            dragMoved = false;
            dragFitsEdge = FitsAlongEdge();
            grabX = ToPx(grabbed.X);
            grabY = ToPx(grabbed.Y);
            dragging = grip.CaptureMouse();
            if (!dragging) dragArea = null;
        }

        // The window is moved here rather than by Windows' own drag, which keeps the size it started with.
        void DragToPointer()
        {
            Native.POINT p;
            if (!dragging || !Native.GetCursorPos(out p)) return;
            if (!dragMoved && p.X == dragStart.X && p.Y == dragStart.Y) return;
            dragMoved = true;
            int next = EdgeAt(p);
            if (next != Edge) SwitchEdge(next);
            Native.RECT r = DragRect(p);
            WindowUtil.PlaceRect(this, r.Left, r.Top, 0, 0, false);
            UpdateArrowSide(r.Left);
        }

        // Where the window goes with the pointer at p, in its present orientation.
        Native.RECT DragRect(Native.POINT p)
        {
            int w = ToPx(barRow.ActualWidth), h = ToPx(barRow.ActualHeight);
            Native.RECT r;
            r.Left = p.X - grabX - (settingsBefore && !Horizontal ? SettingsPanelPx() : 0);
            r.Top = p.Y - grabY - (settingsBefore && Horizontal ? SettingsPanelPx() : 0);
            r.Right = r.Left + w;
            r.Bottom = r.Top + h;
            ClampToMonitor(ref r);
            return r;
        }

        // Near the top or bottom of the working area the bar lies along it. Leaving takes a longer way
        // than arriving, so that the bar does not flip back and forth around one spot.
        // An upright bar against the left or right end stays upright, so it can slide along that side into a corner.
        int EdgeAt(Native.POINT p)
        {
            if (!dragFitsEdge) return Settings.BarFree;
            if (Edge == Settings.BarFree && AgainstSide(DragRect(p).Left)) return Settings.BarFree;
            System.Drawing.Rectangle wa = dragArea ?? WorkArea;
            if (p.Y < wa.Top + ToPx(Edge == Settings.BarTop ? EdgeLeave : EdgeEnter)) return Settings.BarTop;
            if (p.Y >= wa.Bottom - ToPx(Edge == Settings.BarBottom ? EdgeLeave : EdgeEnter)) return Settings.BarBottom;
            return Settings.BarFree;
        }

        // Whether the bar itself, not a settings panel beside it, touches the left or right end of the working area.
        bool AgainstSide(int windowLeft)
        {
            System.Drawing.Rectangle wa = dragArea ?? WorkArea;
            int barLeft = windowLeft + (settingsBefore && !Horizontal ? SettingsPanelPx() : 0);
            return barLeft <= wa.Left || barLeft + ToPx(mainPanel.ActualWidth) >= wa.Right;
        }

        void SwitchEdge(int next)
        {
            bool open = SettingsPanel.Visibility == Visibility.Visible;
            ShowSettingsPanel(false);
            Edge = next;
            ApplyOrientation();
            UpdateLayout();
            ShowSettingsPanel(open);
            // the upright bar's grip is lower than the one along an edge: keep the pointer on it
            if (!Horizontal) grabY = Math.Min(grabY, ToPx(header.ActualHeight) - 1);
        }

        void EndDrag()
        {
            if (!dragging) return;
            dragging = false;
            dragArea = null;
            grip.ReleaseMouseCapture();
            KeepOnMonitor(); // the laid-out size can differ from the window's by a pixel
            if (dragMoved) actions.BarMoved();
        }

        // Moved by other means than the grip, such as Move in the taskbar menu: adjust the proposed rect before the window moves.
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
            UpdateArrowSide(c.Left);
        }

        // The room the settings panel takes along the row it shares with the bar.
        int SettingsPanelPx() { return ToPx(Horizontal ? SettingsPanel.ActualHeight : SettingsPanel.ActualWidth); }
        int ToPx(double dip) { return (int)Math.Round(dip * VisualTreeHelper.GetDpi(this).DpiScaleX); }

        void ShowSettingsPanel(bool show)
        {
            if (show == (SettingsPanel.Visibility == Visibility.Visible)) return;
            Native.RECT r;
            bool placed = WindowUtil.GetRect(this, out r);
            if (!show)
            {
                int size = SettingsPanelPx();
                SettingsPanel.Visibility = Visibility.Collapsed;
                if (!settingsBefore) return;
                bool h = Horizontal;
                SetSettingsSide(false);
                UpdateLayout(); // shrink first, so the window never pokes past the monitor edge
                if (placed) WindowUtil.PlaceRect(this, h ? r.Left : r.Left + size, h ? r.Top + size : r.Top, 0, 0, false);
                return;
            }
            // along an edge the panel and the bar share the height of the working area
            SettingsPanel.MaxHeight = Horizontal ? WorkArea.Height / VisualTreeHelper.GetDpi(this).DpiScaleY - mainPanel.ActualHeight : double.PositiveInfinity;
            SettingsPanel.Visibility = Visibility.Visible;
            if (!placed || !IsLoaded) return;
            UpdateLayout();
            int ps = SettingsPanelPx();
            // the window rect may not have caught up with the layout yet, so use the bar's own width
            bool before = Horizontal ? Edge == Settings.BarBottom : r.Left + ToPx(mainPanel.ActualWidth) + ps > WorkArea.Right;
            if (!before) return;
            SetSettingsSide(true);
            WindowUtil.PlaceRect(this, Horizontal ? r.Left : r.Left - ps, Horizontal ? r.Top - ps : r.Top, 0, 0, false);
        }

        void SetSettingsSide(bool before)
        {
            settingsBefore = before;
            barRow.Children.Remove(SettingsPanel);
            barRow.Children.Insert(before ? 0 : barRow.Children.Count, SettingsPanel);
            if (Horizontal) SettingsPanel.BorderThickness = before ? new Thickness(1, 1, 1, 0) : new Thickness(1, 0, 1, 1);
            else SettingsPanel.BorderThickness = before ? new Thickness(1, 1, 0, 1) : new Thickness(0, 1, 1, 1);
        }

        // ---------- UI building ----------

        void BuildContent()
        {
            buttons = new StackPanel(); // a fresh panel: the old one is still parented to the previous toolbar
            barRow = new StackPanel();
            buttonLabels.Clear();
            mainPanel = BuildMain();
            barRow.Children.Add(mainPanel);
            SettingsPanel = new SettingsPanel(cfg, bindings, settingsActions);
            SettingsPanel.Visibility = Visibility.Collapsed;
            settingsBefore = false;
            barRow.Children.Add(SettingsPanel);
            Content = barRow;
            ApplyOrientation();
        }

        Border BuildMain()
        {
            barColumn = new StackPanel();

            // header: collapse arrow + grip (drag). The arrow is on the left so that, collapsed, it stays put.
            header = new Grid();
            header.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            header.ColumnDefinitions.Add(new ColumnDefinition());
            grip = new Border();
            grip.Background = GripBg;
            grip.Cursor = Cursors.SizeAll;
            grip.MouseLeftButtonDown += delegate (object s, MouseButtonEventArgs e) { StartDrag(e.GetPosition(mainPanel)); };
            grip.MouseMove += delegate { DragToPointer(); };
            grip.MouseLeftButtonUp += delegate { DragToPointer(); EndDrag(); };
            grip.LostMouseCapture += delegate { EndDrag(); };
            grip.Child = new TextBlock { Text = "HighPen", Foreground = Brushes.White, FontSize = 11, FontWeight = FontWeights.SemiBold, VerticalAlignment = VerticalAlignment.Center, Margin = new Thickness(6, 0, 0, 0), IsHitTestVisible = false, TextWrapping = TextWrapping.NoWrap };
            Border ab = new Border { Width = ArrowWidth, Background = Theme.Idle, Cursor = Cursors.Hand };
            arrowBtn = ab;
            arrow = new TextBlock { Text = GlyphCollapse, FontFamily = Theme.Icons, Foreground = Brushes.White, FontSize = 14, HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Center };
            ab.Child = arrow;
            ab.MouseLeftButtonUp += delegate { actions.ToggleCollapse(); };
            header.Children.Add(grip);
            header.Children.Add(ab);
            barColumn.Children.Add(header);

            spotBtn = AddButton("◎", false, Lang.T("Spot"), Lang.T("MouseSpot"), "Spot", actions.ToggleSpot);
            penBtn = AddButton("", true, Lang.T("Pen"), Lang.T("Pen"), "Pen", actions.TogglePen);
            highlightBtn = AddButton("", true, Lang.T("Highlighter"), Lang.T("Highlighter"), "Highlighter", actions.ToggleHighlighter);
            eraserBtn = AddButton("", true, Lang.T("Eraser"), null, null, actions.ToggleEraser);
            eraserBtn.ToolTip = Lang.T("Eraser") + bindings.KeySuffix("Eraser") + "\n" + Lang.T("EraserTip");
            boardBtn = AddButton("▭", false, Lang.T("Board"), Lang.T("BoardTip"), "Board", actions.CycleBoard, out boardLabel);
            AddButton("", true, Lang.T("Undo"), Lang.T("Undo"), "Undo", actions.Undo);
            AddButton("", true, Lang.T("Clear"), Lang.T("ClearTip"), "Clear", actions.Clear);
            bubbleBtn = AddButton("", true, Lang.T("Bubble"), Lang.T("Bubble"), "Bubble", actions.ToggleText);
            zoomBtn = AddButton("", true, Lang.T("Zoom"), null, null, actions.ToggleZoom, out zoomLabel);
            UpdateZoomTip();
            AddButton("", true, Lang.T("Capture"), Lang.T("CaptureTip"), "Capture", actions.Capture);
            breakBtn = AddButton("", true, Lang.T("Break"), Lang.T("BreakTip"), "Break", actions.ToggleBreak);
            setBtn = AddButton("", true, Lang.T("Settings"), Lang.T("Settings"), "Settings", actions.ToggleSettings);
            Border aboutBtn = AddButton("", true, Lang.T("About"), null, null, actions.ShowAbout);
            aboutBtn.ToolTip = Lang.T("AboutTip");
            Tip(ab, Lang.T("Collapse"), "Collapse");

            // red close button
            Border close = new Border { Height = ButtonHeight, Background = Theme.Idle, Cursor = Cursors.Hand };
            Grid cg = new Grid { Width = 30, Height = 30, HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Center };
            cg.Children.Add(new Ellipse { Fill = CloseRed, Stroke = Brushes.White, StrokeThickness = 2 });
            cg.Children.Add(new TextBlock { Text = "", FontFamily = Theme.Icons, Foreground = Brushes.White, FontSize = 14, FontWeight = FontWeights.Bold, HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Center });
            close.Child = cg;
            Tip(close, Lang.T("Quit"), "Quit");
            close.MouseLeftButtonUp += delegate { actions.Quit(); };
            buttons.Children.Add(close);
            closeBtn = close;

            barColumn.Children.Add(buttons);

            return new Border { Background = Theme.PanelBg, BorderBrush = Theme.Line, BorderThickness = new Thickness(1), Child = barColumn };
        }

        // A tool button (icon over label) appended to the bar. tip/commandId give the tooltip and its shortcut;
        // pass null to set the tooltip yourself.
        Border AddButton(string glyph, bool segoe, string label, string tip, string commandId, Action click)
        {
            TextBlock labelText;
            return AddButton(glyph, segoe, label, tip, commandId, click, out labelText);
        }

        // labelText: the label, for buttons whose label changes with their state.
        Border AddButton(string glyph, bool segoe, string label, string tip, string commandId, Action click, out TextBlock labelText)
        {
            StackPanel sp = new StackPanel { VerticalAlignment = VerticalAlignment.Center };
            sp.Children.Add(new TextBlock { Text = glyph, Foreground = Brushes.White, FontSize = 20, HorizontalAlignment = HorizontalAlignment.Center, FontFamily = segoe ? Theme.Icons : Theme.Symbols });
            labelText = new TextBlock { Text = label, Foreground = Brushes.White, FontSize = 10, HorizontalAlignment = HorizontalAlignment.Center };
            sp.Children.Add(labelText);
            Border b = new Border { Height = ButtonHeight, Background = Theme.Idle, Cursor = Cursors.Hand, Child = sp };
            buttonLabels.Add(labelText);
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
