using System;
using System.Collections.Generic;
using System.IO;
using System.Runtime.InteropServices;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Ink;
using System.Windows.Input;
using System.Windows.Interop;
using System.Windows.Media;
using System.Windows.Shapes;
using System.Windows.Threading;

namespace HighPen
{
    static class Native
    {
        public const int GWL_EXSTYLE = -20;
        public const int WS_EX_TRANSPARENT = 0x20;
        public const int WS_EX_TOOLWINDOW = 0x80;
        public const int WS_EX_NOACTIVATE = 0x08000000;
        public static readonly IntPtr HWND_TOPMOST = new IntPtr(-1);
        public const uint SWP_NOSIZE = 1, SWP_NOMOVE = 2, SWP_NOACTIVATE = 0x10;

        [StructLayout(LayoutKind.Sequential)]
        public struct POINT { public int X, Y; }

        [DllImport("user32.dll")] public static extern int GetWindowLong(IntPtr h, int i);
        [DllImport("user32.dll")] public static extern int SetWindowLong(IntPtr h, int i, int v);
        [DllImport("user32.dll")] public static extern bool RegisterHotKey(IntPtr h, int id, uint mod, uint vk);
        [DllImport("user32.dll")] public static extern bool GetCursorPos(out POINT p);
        [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr after, int x, int y, int cx, int cy, uint flags);

        public static void AddExStyle(Window w, int style)
        {
            IntPtr h = new WindowInteropHelper(w).Handle;
            SetWindowLong(h, GWL_EXSTYLE, GetWindowLong(h, GWL_EXSTYLE) | style);
        }

        public static void SetClickThrough(Window w, bool on)
        {
            IntPtr h = new WindowInteropHelper(w).Handle;
            int s = GetWindowLong(h, GWL_EXSTYLE);
            s = on ? (s | WS_EX_TRANSPARENT) : (s & ~WS_EX_TRANSPARENT);
            SetWindowLong(h, GWL_EXSTYLE, s);
        }

        [StructLayout(LayoutKind.Sequential)]
        public struct RECT { public int Left, Top, Right, Bottom; }
        [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);

        public const int WS_EX_LAYERED = 0x80000, WS_EX_TOPMOST = 8;
        public const uint WS_POPUP = 0x80000000, WS_CHILD = 0x40000000, WS_VISIBLE = 0x10000000;

        [DllImport("user32.dll", CharSet = CharSet.Unicode)]
        public static extern IntPtr CreateWindowEx(int ex, string cls, string name, uint style, int x, int y, int w, int h, IntPtr parent, IntPtr menu, IntPtr inst, IntPtr param);
        [DllImport("user32.dll")] public static extern bool DestroyWindow(IntPtr h);
        [DllImport("user32.dll")] public static extern bool MoveWindow(IntPtr h, int x, int y, int w, int hh, bool repaint);
        [DllImport("user32.dll")] public static extern bool SetLayeredWindowAttributes(IntPtr h, uint key, byte alpha, uint flags);
        [DllImport("kernel32.dll", CharSet = CharSet.Unicode)] public static extern IntPtr GetModuleHandle(string name);

        [StructLayout(LayoutKind.Sequential)]
        public struct MAGTRANSFORM { [MarshalAs(UnmanagedType.ByValArray, SizeConst = 9)] public float[] v; }
        [DllImport("user32.dll")] public static extern bool ClipCursor(ref RECT r);
        [DllImport("user32.dll")] public static extern bool ClipCursor(IntPtr r);
        [DllImport("Magnification.dll")] public static extern bool MagInitialize();
        [DllImport("Magnification.dll")] public static extern bool MagUninitialize();
        [DllImport("Magnification.dll")] public static extern bool MagSetWindowSource(IntPtr h, RECT r);
        [DllImport("Magnification.dll")] public static extern bool MagSetWindowTransform(IntPtr h, ref MAGTRANSFORM t);
        [DllImport("Magnification.dll")] public static extern bool MagSetWindowFilterList(IntPtr h, uint mode, int count, IntPtr[] list);

        [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
        [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);

        static IntPtr lastFg = IntPtr.Zero;
        static bool lastFgIsSnip;

        // True while the Windows snipping overlay (Win+Shift+S) is the foreground, full-screen window.
        public static bool IsSnippingOverlayActive()
        {
            IntPtr h = GetForegroundWindow();
            if (h == IntPtr.Zero) { lastFg = IntPtr.Zero; return false; }
            if (h != lastFg)
            {
                lastFg = h;
                lastFgIsSnip = false;
                try
                {
                    uint pid;
                    GetWindowThreadProcessId(h, out pid);
                    string n = System.Diagnostics.Process.GetProcessById((int)pid).ProcessName;
                    lastFgIsSnip = n.Equals("SnippingTool", StringComparison.OrdinalIgnoreCase) || n.Equals("ScreenClippingHost", StringComparison.OrdinalIgnoreCase);
                }
                catch { }
            }
            if (!lastFgIsSnip) return false;
            RECT r;
            if (!GetWindowRect(h, out r)) return false;
            System.Drawing.Rectangle b = System.Windows.Forms.Screen.FromHandle(h).Bounds;
            // the overlay spans the whole screen; the editor window of Snipping Tool does not
            return (r.Right - r.Left) >= b.Width * 0.9 && (r.Bottom - r.Top) >= b.Height * 0.9;
        }

        public static System.Windows.Forms.Screen GetScreen(int idx)
        {
            System.Windows.Forms.Screen[] all = System.Windows.Forms.Screen.AllScreens;
            if (idx < 0 || idx >= all.Length) idx = 0;
            return all[idx];
        }

        // Positions a window in physical pixels (avoids DPI rounding on multi-monitor setups).
        public static void PlaceRect(Window w, int x, int y, int cx, int cy, bool resize)
        {
            IntPtr h = new WindowInteropHelper(w).EnsureHandle();
            SetWindowPos(h, HWND_TOPMOST, x, y, cx, cy, SWP_NOACTIVATE | (resize ? 0 : SWP_NOSIZE));
        }

        public static void BringTopmost(Window w)
        {
            IntPtr h = new WindowInteropHelper(w).Handle;
            SetWindowPos(h, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOSIZE | SWP_NOMOVE | SWP_NOACTIVATE);
        }
    }

    // Live zoom (1.5x / 2x / 2.5x) of the monitor under the mouse pointer, using the Windows Magnification API.
    // The view is positioned so the content under the pointer stays under the pointer,
    // so clicks (the host window is click-through) land exactly where they appear.
    class Zoomer
    {
        public static readonly double[] Factors = { 1.5, 2, 2.5 };
        float factor = 2f;
        IntPtr host, mag;
        IntPtr[] exclude;
        // While frozen the view stays put so the user can draw on it.
        public bool Frozen;
        // Reports the zoomed monitor bounds and the source rect being shown (empty bounds = zoom off).
        public Action<System.Drawing.Rectangle, Native.RECT> ViewChanged;
        System.Drawing.Rectangle current, locked;
        DispatcherTimer timer = new DispatcherTimer();
        public bool Active { get { return host != IntPtr.Zero; } }

        // Can be changed while zoomed; the view updates on the spot.
        public double Factor
        {
            get { return factor; }
            set
            {
                factor = (float)value;
                if (!Active) return;
                ApplyTransform();
                current = System.Drawing.Rectangle.Empty;
                bool f = Frozen; Frozen = false; Update(); Frozen = f;
            }
        }

        void ApplyTransform()
        {
            Native.MAGTRANSFORM t = new Native.MAGTRANSFORM();
            t.v = new float[] { factor, 0, 0, 0, factor, 0, 0, 0, 1 };
            Native.MagSetWindowTransform(mag, ref t);
        }

        public Zoomer()
        {
            timer.Interval = TimeSpan.FromMilliseconds(12);
            timer.Tick += delegate { Update(); };
        }

        public void Start(IntPtr[] excludeFromCapture)
        {
            if (Active) return;
            exclude = excludeFromCapture;
            if (!Native.MagInitialize()) return;
            IntPtr inst = Native.GetModuleHandle(null);
            host = Native.CreateWindowEx(Native.WS_EX_LAYERED | Native.WS_EX_TOPMOST | Native.WS_EX_TRANSPARENT | Native.WS_EX_NOACTIVATE | Native.WS_EX_TOOLWINDOW,
                "Static", "HighPenZoom", Native.WS_POPUP, 0, 0, 100, 100, IntPtr.Zero, IntPtr.Zero, inst, IntPtr.Zero);
            if (host == IntPtr.Zero) { Native.MagUninitialize(); return; }
            Native.SetLayeredWindowAttributes(host, 0, 255, 2);
            mag = Native.CreateWindowEx(0, "Magnifier", "HighPenMag", Native.WS_CHILD | Native.WS_VISIBLE, 0, 0, 100, 100, host, IntPtr.Zero, inst, IntPtr.Zero);
            if (mag == IntPtr.Zero) { Stop(); return; }
            ApplyTransform();
            // keep the zoom window itself, the toolbar, the ink overlay and the spot out of the magnified image
            IntPtr[] list = new IntPtr[exclude.Length + 1];
            list[0] = host;
            exclude.CopyTo(list, 1);
            Native.MagSetWindowFilterList(mag, 0, list.Length, list);
            current = System.Drawing.Rectangle.Empty;
            Update();
            Native.SetWindowPos(host, Native.HWND_TOPMOST, 0, 0, 0, 0, Native.SWP_NOSIZE | Native.SWP_NOMOVE | Native.SWP_NOACTIVATE | 0x40);
            timer.Start();
        }

        public void Stop()
        {
            timer.Stop();
            if (host != IntPtr.Zero)
            {
                Native.ClipCursor(IntPtr.Zero);
                locked = System.Drawing.Rectangle.Empty;
                Native.DestroyWindow(host); host = IntPtr.Zero; mag = IntPtr.Zero; Native.MagUninitialize();
                if (ViewChanged != null) ViewChanged(System.Drawing.Rectangle.Empty, new Native.RECT());
            }
        }

        public void BringTopmost()
        {
            if (Active) Native.SetWindowPos(host, Native.HWND_TOPMOST, 0, 0, 0, 0, Native.SWP_NOSIZE | Native.SWP_NOMOVE | Native.SWP_NOACTIVATE);
        }

        void Update()
        {
            if (!Active) return;
            if (Frozen && current != System.Drawing.Rectangle.Empty) return;
            Native.POINT p;
            if (!Native.GetCursorPos(out p)) return;
            // the zoomed monitor is fixed when zoom starts; the pointer is confined to it
            if (locked.IsEmpty)
            {
                locked = System.Windows.Forms.Screen.FromPoint(new System.Drawing.Point(p.X, p.Y)).Bounds;
                Native.RECT clip;
                clip.Left = locked.Left; clip.Top = locked.Top; clip.Right = locked.Right; clip.Bottom = locked.Bottom;
                Native.ClipCursor(ref clip);
            }
            System.Drawing.Rectangle b = locked;
            p.X = Math.Max(b.Left, Math.Min(b.Right - 1, p.X));
            p.Y = Math.Max(b.Top, Math.Min(b.Bottom - 1, p.Y));
            if (b != current)
            {
                current = b;
                Native.SetWindowPos(host, Native.HWND_TOPMOST, b.X, b.Y, b.Width, b.Height, Native.SWP_NOACTIVATE | 0x40);
                Native.MoveWindow(mag, 0, 0, b.Width, b.Height, true);
            }
            float k = 1f - 1f / factor;
            Native.RECT r;
            r.Left = b.X + (int)Math.Round((p.X - b.X) * k);
            r.Top = b.Y + (int)Math.Round((p.Y - b.Y) * k);
            r.Right = r.Left + (int)(b.Width / factor);
            r.Bottom = r.Top + (int)(b.Height / factor);
            Native.MagSetWindowSource(mag, r);
            if (ViewChanged != null) ViewChanged(b, r);
        }
    }

    // UI strings in Korean / Japanese / English. Cur is an index into Codes.
    static class Lang
    {
        public static readonly string[] Codes = { "ko", "ja", "en" };
        public static readonly string[] Names = { "한국어", "日本語", "English" };
        public static int Cur;

        static readonly Dictionary<string, string[]> Text = new Dictionary<string, string[]>
        {
            { "Spot",          new[] { "스팟", "スポット", "Spot" } },
            { "MouseSpot",     new[] { "마우스 스팟", "マウススポット", "Mouse spot" } },
            { "Pen",           new[] { "펜", "ペン", "Pen" } },
            { "Eraser",        new[] { "지우개", "消しゴム", "Eraser" } },
            { "EraserTip",     new[] { "지우개  (Ctrl+Alt+E, 지우개 상태에서 한 번 더 누르면 전체 삭제)", "消しゴム  (Ctrl+Alt+E、消しゴム中にもう一度押すと全消去)", "Eraser  (Ctrl+Alt+E, press again while erasing to clear all)" } },
            { "Board",         new[] { "칠판", "ボード", "Board" } },
            { "BoardTip",      new[] { "칠판 (흰색/검정/끄기)", "ボード (白/黒/オフ)", "Board (white/black/off)" } },
            { "WhiteBoard",    new[] { "흰 칠판", "白ボード", "White" } },
            { "BlackBoard",    new[] { "검은 칠판", "黒ボード", "Black" } },
            { "Undo",          new[] { "되돌리기", "元に戻す", "Undo" } },
            { "Clear",         new[] { "지우기", "全消去", "Clear" } },
            { "ClearTip",      new[] { "전체 지우기", "すべて消去", "Clear all" } },
            { "Zoom",          new[] { "확대", "拡大", "Zoom" } },
            { "ZoomTip",       new[] { "{0}배 확대", "{0}倍拡大", "{0}x zoom" } },
            { "ZoomFactor",    new[] { "확대 배율", "拡大倍率", "Zoom level" } },
            { "Bubble",        new[] { "말풍선", "吹き出し", "Note" } },
            { "Settings",      new[] { "설정", "設定", "Settings" } },
            { "Collapse",      new[] { "접기/펴기", "折りたたみ/展開", "Collapse/expand" } },
            { "Quit",          new[] { "종료", "終了", "Quit" } },
            { "Monitor",       new[] { "작동 모니터", "使用モニター", "Monitor" } },
            { "MonitorTip",    new[] { "모니터 {0}  (순환: Ctrl+Alt+M)", "モニター {0}  (切替: Ctrl+Alt+M)", "Monitor {0}  (cycle: Ctrl+Alt+M)" } },
            { "PenColor",      new[] { "펜 색상", "ペンの色", "Pen color" } },
            { "PenSize",       new[] { "펜 두께", "ペンの太さ", "Pen width" } },
            { "Pressure",      new[] { "필압 반영", "筆圧", "Pressure" } },
            { "On",            new[] { "켜짐", "オン", "on" } },
            { "Off",           new[] { "꺼짐", "オフ", "off" } },
            { "SpotColor",     new[] { "스팟 색상", "スポットの色", "Spot color" } },
            { "SpotSize",      new[] { "스팟 크기", "スポットの大きさ", "Spot size" } },
            { "Language",      new[] { "언어", "言語", "Language" } },
            { "Red",           new[] { "빨강", "赤", "Red" } },
            { "Orange",        new[] { "주황", "オレンジ", "Orange" } },
            { "Yellow",        new[] { "노랑", "黄", "Yellow" } },
            { "Green",         new[] { "초록", "緑", "Green" } },
            { "Blue",          new[] { "파랑", "青", "Blue" } },
            { "Purple",        new[] { "보라", "紫", "Purple" } },
            { "Black",         new[] { "검정", "黒", "Black" } },
            { "White",         new[] { "흰색", "白", "White" } },
        };

        public static string T(string key) { return Text[key][Cur]; }

        // Saved code, or English when nothing (or an unsupported code) is saved.
        public static int FromCode(string code)
        {
            int i = Array.IndexOf(Codes, code);
            return i < 0 ? 2 : i;
        }
    }

    class Settings
    {
        public string PenColor = "#FF3B30";
        public double PenSize = 4;
        public string SpotColor = "#FFD60A";
        public double SpotSize = 70;
        public bool SpotOn = true;
        public int Monitor = 0;
        public bool Pressure = true;
        public double ZoomFactor = 2;
        public int BarX = 20, BarY = 20; // offset from the monitor work area, in pixels
        public string Language = ""; // "" = English (the default)

        static string FilePath
        {
            get
            {
                string dir = System.IO.Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "HighPen");
                Directory.CreateDirectory(dir);
                return System.IO.Path.Combine(dir, "settings.txt");
            }
        }

        public static Settings Load()
        {
            Settings s = new Settings();
            try
            {
                foreach (string line in File.ReadAllLines(FilePath))
                {
                    int i = line.IndexOf('=');
                    if (i < 0) continue;
                    string k = line.Substring(0, i), v = line.Substring(i + 1);
                    if (k == "PenColor") s.PenColor = v;
                    else if (k == "PenSize") s.PenSize = double.Parse(v, System.Globalization.CultureInfo.InvariantCulture);
                    else if (k == "SpotColor") s.SpotColor = v;
                    else if (k == "SpotSize") s.SpotSize = double.Parse(v, System.Globalization.CultureInfo.InvariantCulture);
                    else if (k == "SpotOn") s.SpotOn = v == "1";
                    else if (k == "Pressure") s.Pressure = v == "1";
                    else if (k == "ZoomFactor") s.ZoomFactor = double.Parse(v, System.Globalization.CultureInfo.InvariantCulture);
                    else if (k == "Monitor") s.Monitor = int.Parse(v);
                    else if (k == "BarX") s.BarX = int.Parse(v);
                    else if (k == "BarY") s.BarY = int.Parse(v);
                    else if (k == "Language") s.Language = v;
                }
            }
            catch { }
            if (Array.IndexOf(Zoomer.Factors, s.ZoomFactor) < 0) s.ZoomFactor = 2;
            return s;
        }

        public void Save()
        {
            try
            {
                var ic = System.Globalization.CultureInfo.InvariantCulture;
                File.WriteAllLines(FilePath, new string[] {
                    "PenColor=" + PenColor,
                    "PenSize=" + PenSize.ToString(ic),
                    "SpotColor=" + SpotColor,
                    "SpotSize=" + SpotSize.ToString(ic),
                    "SpotOn=" + (SpotOn ? "1" : "0"),
                    "Monitor=" + Monitor,
                    "Pressure=" + (Pressure ? "1" : "0"),
                    "ZoomFactor=" + ZoomFactor.ToString(ic),
                    "BarX=" + BarX,
                    "BarY=" + BarY,
                    "Language=" + Language });
            }
            catch { }
        }
    }

    // Full-screen transparent window that hosts the ink canvas (also used as the whiteboard).
    class OverlayWindow : Window
    {
        public InkCanvas Canvas = new InkCanvas();
        // 0 = screen annotations, 1 = white board, 2 = black board
        public List<UIElement>[] Bubbles = new List<UIElement>[] { new List<UIElement>(), new List<UIElement>(), new List<UIElement>() };
        public StrokeCollection[] Pages = new StrokeCollection[] { new StrokeCollection(), new StrokeCollection(), new StrokeCollection() };

        public void MoveToScreen(int idx)
        {
            System.Drawing.Rectangle b = Native.GetScreen(idx).Bounds;
            Native.PlaceRect(this, b.X, b.Y, b.Width, b.Height, true);
        }

        public OverlayWindow()
        {
            WindowStyle = WindowStyle.None;
            AllowsTransparency = true;
            Background = Brushes.Transparent;
            ShowInTaskbar = false;
            Topmost = true;
            ShowActivated = false;
            ResizeMode = ResizeMode.NoResize;
            Left = SystemParameters.VirtualScreenLeft;
            Top = SystemParameters.VirtualScreenTop;
            Width = SystemParameters.VirtualScreenWidth;
            Height = SystemParameters.VirtualScreenHeight;

            Canvas.Background = Brushes.Transparent;
            Stylus.SetIsPressAndHoldEnabled(Canvas, false);
            Stylus.SetIsFlicksEnabled(Canvas, false);
            Stylus.SetIsTapFeedbackEnabled(Canvas, false);
            Canvas.Strokes = Pages[0];
            Content = Canvas;

            SourceInitialized += delegate { Native.AddExStyle(this, Native.WS_EX_TOOLWINDOW); };
        }
    }

    // Click-through window that draws the spot following the mouse pointer.
    class SpotWindow : Window
    {
        Ellipse spot = new Ellipse();
        Canvas root = new Canvas();
        DispatcherTimer timer = new DispatcherTimer();

        public void MoveToScreen(int idx)
        {
            System.Drawing.Rectangle b = Native.GetScreen(idx).Bounds;
            Native.PlaceRect(this, b.X, b.Y, b.Width, b.Height, true);
        }

        public SpotWindow()
        {
            WindowStyle = WindowStyle.None;
            AllowsTransparency = true;
            Background = Brushes.Transparent;
            ShowInTaskbar = false;
            Topmost = true;
            ShowActivated = false;
            ResizeMode = ResizeMode.NoResize;
            Left = SystemParameters.VirtualScreenLeft;
            Top = SystemParameters.VirtualScreenTop;
            Width = SystemParameters.VirtualScreenWidth;
            Height = SystemParameters.VirtualScreenHeight;
            IsHitTestVisible = false;

            spot.IsHitTestVisible = false;
            root.Children.Add(spot);
            Content = root;

            SourceInitialized += delegate
            {
                Native.AddExStyle(this, Native.WS_EX_TRANSPARENT | Native.WS_EX_NOACTIVATE | Native.WS_EX_TOOLWINDOW);
            };
            timer.Interval = TimeSpan.FromMilliseconds(12);
            timer.Tick += delegate { UpdatePosition(); };
            timer.Start();
        }

        public void SetStyle(Color c, double size)
        {
            spot.Width = size;
            spot.Height = size;
            spot.Fill = new SolidColorBrush(Color.FromArgb(0x66, c.R, c.G, c.B));
            spot.Stroke = null;
            spot.StrokeThickness = 0;
        }

        public void SetSpotVisible(bool on)
        {
            spot.Visibility = on ? Visibility.Visible : Visibility.Collapsed;
        }

        void UpdatePosition()
        {
            if (spot.Visibility != Visibility.Visible) return;
            Native.POINT p;
            if (!Native.GetCursorPos(out p)) return;
            DpiScale d = VisualTreeHelper.GetDpi(this);
            double x = p.X / d.DpiScaleX - Left;
            double y = p.Y / d.DpiScaleY - Top;
            Canvas.SetLeft(spot, x - spot.Width / 2);
            Canvas.SetTop(spot, y - spot.Height / 2);
        }
    }

    class ToolbarWindow : Window
    {
        const string AppVersion = "1.2.0"; // keep in sync with Version in Setup.cs
        static readonly string[] Palette = { "#FF3B30", "#FF9500", "#FFD60A", "#34C759", "#0A84FF", "#BF5AF2", "#000000", "#FFFFFF" };
        static readonly string[] ColorNames = { "Red", "Orange", "Yellow", "Green", "Blue", "Purple", "Black", "White" }; // Lang keys
        static readonly Key[] ColorKeys = { Key.R, Key.O, Key.Y, Key.G, Key.B, Key.P, Key.K, Key.W };
        static readonly string[] ColorKeyText = { "R", "O", "Y", "G", "B", "P", "K", "W" };
        static readonly Brush PanelBg = new SolidColorBrush(Color.FromRgb(0x2B, 0x2E, 0x33));
        static readonly Brush Active = new SolidColorBrush(Color.FromRgb(0x3E, 0x6F, 0xB0));
        static readonly Brush Idle = new SolidColorBrush(Color.FromRgb(0x3A, 0x3D, 0x42));
        static readonly Brush Line = new SolidColorBrush(Color.FromRgb(0x14, 0x15, 0x17));

        Settings cfg;
        OverlayWindow overlay;
        SpotWindow spotWin;
        Zoomer zoomer = new Zoomer();

        bool penMode, eraser, collapsed, settingsOpen, textMode;
        int shownBoard;
        int board; // 0 none, 1 white, 2 black

        StackPanel buttons = new StackPanel();
        Border settingsPanel;
        TextBlock arrow;
        Border zoomBtn, bubbleBtn, spotBtn, penBtn, eraserBtn, boardBtn, setBtn;
        TextBlock boardLabel;
        DispatcherTimer topTimer = new DispatcherTimer();

        public ToolbarWindow(Settings s, OverlayWindow o, SpotWindow sw)
        {
            cfg = s; overlay = o; spotWin = sw;

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

            SourceInitialized += delegate { Native.AddExStyle(this, Native.WS_EX_NOACTIVATE); RegisterHotkeys(); };
            for (int i = 0; i < overlay.Pages.Length; i++)
            {
                int page = i;
                overlay.Pages[i].StrokesChanged += delegate (object sender, StrokeCollectionChangedEventArgs e) { RecordInkEdit(page, e); };
            }
            overlay.Canvas.PreviewStylusDown += delegate { BeginPress(); };
            overlay.Canvas.PreviewMouseLeftButtonDown += delegate { BeginPress(); };
            overlay.Canvas.PreviewStylusUp += delegate { pressed = false; };
            overlay.Canvas.PreviewMouseLeftButtonUp += delegate { pressed = false; };
            overlay.Canvas.PreviewMouseLeftButtonDown += delegate (object sender, MouseButtonEventArgs e)
            {
                if (!textMode) return;
                DependencyObject src = e.OriginalSource as DependencyObject;
                while (src != null && !(src is TextBox) && src != overlay.Canvas)
                    src = (src is Visual || src is System.Windows.Media.Media3D.Visual3D) ? VisualTreeHelper.GetParent(src) : LogicalTreeHelper.GetParent(src);
                if (src is TextBox) return;
                e.Handled = true;
                BeginBubble(e.GetPosition(overlay.Canvas));
            };
            Loaded += delegate
            {
                ApplyMonitor();
                Native.SetClickThrough(overlay, true);
                ApplyMode();
                ApplySpot();
                ReassertTop();
            };

            // Slideshow / other topmost windows can cover us; re-assert periodically.
            zoomer.ViewChanged = OnZoomView;
            zoomer.Factor = cfg.ZoomFactor;
            snipTimer.Interval = TimeSpan.FromMilliseconds(100);
            snipTimer.Tick += delegate { CheckSnipping(); };
            snipTimer.Start();
            topTimer.Interval = TimeSpan.FromSeconds(1.5);
            topTimer.Tick += delegate { ReassertTop(); };
            topTimer.Start();
        }

        // Ink lives in screen coordinates of the unzoomed desktop. While zoomed, scale the canvas
        // the same way the magnifier scales the desktop so strokes line up with what is shown,
        // and pen input maps back to the right content position.
        System.Drawing.Rectangle zoomBounds = System.Drawing.Rectangle.Empty;
        Native.RECT zoomSource;

        void OnZoomView(System.Drawing.Rectangle b, Native.RECT r)
        {
            zoomBounds = b;
            zoomSource = r;
            ApplyZoomTransform();
        }

        void ApplyZoomTransform()
        {
            InkCanvas ic = overlay.Canvas;
            if (zoomBounds.IsEmpty || board != 0 || Native.GetScreen(cfg.Monitor).Bounds != zoomBounds)
            {
                ic.RenderTransform = Transform.Identity;
                return;
            }
            DpiScale d = VisualTreeHelper.GetDpi(overlay);
            double sx = (zoomSource.Left - zoomBounds.X) / d.DpiScaleX;
            double sy = (zoomSource.Top - zoomBounds.Y) / d.DpiScaleY;
            double f = zoomer.Factor;
            ic.RenderTransform = new MatrixTransform(f, 0, 0, f, -f * sx, -f * sy);
        }

        void ApplyMonitor()
        {
            if (cfg.Monitor >= System.Windows.Forms.Screen.AllScreens.Length) cfg.Monitor = 0;
            overlay.MoveToScreen(cfg.Monitor);
            spotWin.MoveToScreen(cfg.Monitor);
            System.Drawing.Rectangle wa = Native.GetScreen(cfg.Monitor).WorkingArea;
            DpiScale d = VisualTreeHelper.GetDpi(this);
            int bx = cfg.BarX, by = cfg.BarY;
            if (bx < 0 || by < 0 || bx > wa.Width - 40 || by > wa.Height - 40) { bx = 20; by = 20; }
            Native.PlaceRect(this, wa.Left + bx, wa.Top + by, 0, 0, false);
            for (int i = 0; i < monitorBtns.Count; i++)
                monitorBtns[i].Background = i == cfg.Monitor ? Active : Idle;
            ReassertTop();
        }

        void SaveBarPosition()
        {
            Native.RECT r;
            if (!Native.GetWindowRect(new WindowInteropHelper(this).Handle, out r)) return;
            System.Drawing.Rectangle wa = Native.GetScreen(cfg.Monitor).WorkingArea;
            cfg.BarX = r.Left - wa.Left;
            cfg.BarY = r.Top - wa.Top;
            cfg.Save();
        }

        void CycleMonitor()
        {
            cfg.Monitor = (cfg.Monitor + 1) % System.Windows.Forms.Screen.AllScreens.Length;
            cfg.Save();
            ApplyMonitor();
        }

        Panel penSwatches;

        void SetPenColor(int i)
        {
            cfg.PenColor = Palette[i];
            cfg.Save();
            foreach (Border b in penSwatches.Children)
            {
                bool sel = string.Equals((string)b.Tag, cfg.PenColor, StringComparison.OrdinalIgnoreCase);
                b.BorderBrush = sel ? Brushes.White : Brushes.Gray;
                b.BorderThickness = new Thickness(sel ? 3 : 1);
            }
            ApplyPen();
        }

        Border pressureBtn;
        TextBlock pressureText;

        void UpdatePressureButton()
        {
            pressureText.Text = Lang.T("Pressure") + ": " + Lang.T(cfg.Pressure ? "On" : "Off");
            pressureBtn.Background = cfg.Pressure ? Active : Idle;
        }

        void TogglePressure()
        {
            cfg.Pressure = !cfg.Pressure;
            cfg.Save();
            UpdatePressureButton();
            ApplyPen();
        }

        List<Border> monitorBtns = new List<Border>();
        List<Border> zoomFactorBtns = new List<Border>();

        // While the snipping overlay is up, get out of its way: no input capture, no spot,
        // no z-order fighting. Normal state is restored when it closes.
        bool suspended;
        DispatcherTimer snipTimer = new DispatcherTimer();

        void CheckSnipping()
        {
            bool snip = Native.IsSnippingOverlayActive();
            if (snip == suspended) return;
            suspended = snip;
            if (suspended)
            {
                Native.SetClickThrough(overlay, true);
                spotWin.SetSpotVisible(false);
            }
            else
            {
                ApplyMode();
                ApplySpot();
            }
        }

        void ReassertTop()
        {
            if (suspended) return;
            zoomer.BringTopmost();
            Native.BringTopmost(overlay);
            Native.BringTopmost(spotWin);
            Native.BringTopmost(this);
        }

        // ---------- UI building ----------

        void BuildContent()
        {
            buttons = new StackPanel(); // a fresh panel: the old one is still parented to the previous toolbar
            monitorBtns.Clear();
            StackPanel row = new StackPanel();
            row.Orientation = Orientation.Horizontal;
            row.Children.Add(BuildMain());
            settingsPanel = BuildSettings();
            settingsPanel.Visibility = Visibility.Collapsed;
            row.Children.Add(settingsPanel);
            Content = row;
        }

        // Rebuilds the toolbar in the new language, keeping the current mode.
        void SetLanguage(int i)
        {
            Lang.Cur = i;
            cfg.Language = Lang.Codes[i];
            cfg.Save();
            BuildContent();
            buttons.Visibility = collapsed ? Visibility.Collapsed : Visibility.Visible;
            arrow.Text = collapsed ? "" : "";
            Highlight(zoomBtn, zoomer.Active);
            ApplySpot();
            ApplyMonitor();
            ApplyMode();
        }

        Border BuildMain()
        {
            StackPanel col = new StackPanel();

            // header: grip (drag) + collapse arrow
            Grid header = new Grid();
            header.Height = 30;
            header.ColumnDefinitions.Add(new ColumnDefinition());
            header.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            Border grip = new Border();
            grip.Background = new SolidColorBrush(Color.FromRgb(0x4A, 0x52, 0x2A));
            grip.Cursor = Cursors.SizeAll;
            grip.MouseLeftButtonDown += delegate
            {
                try { DragMove(); } catch { }
                SaveBarPosition();
            };
            TextBlock gt = new TextBlock { Text = "HighPen", Foreground = Brushes.White, FontSize = 11, FontWeight = FontWeights.SemiBold, VerticalAlignment = VerticalAlignment.Center, Margin = new Thickness(6, 0, 0, 0), IsHitTestVisible = false, TextWrapping = TextWrapping.NoWrap };
            grip.Child = gt;
            Border ab = new Border { Width = 28, Background = Idle, Cursor = Cursors.Hand };
            arrow = new TextBlock { Text = "", FontFamily = new FontFamily("Segoe MDL2 Assets"), Foreground = Brushes.White, FontSize = 14, HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Center };
            ab.Child = arrow;
            ab.MouseLeftButtonUp += delegate { ToggleCollapse(); };
            Grid.SetColumn(ab, 1);
            header.Children.Add(grip);
            header.Children.Add(ab);
            col.Children.Add(header);

            spotBtn = MakeButton("◎", Lang.T("Spot"), false, delegate { ToggleSpot(); });
            penBtn = MakeButton("", Lang.T("Pen"), true, delegate { TogglePen(); });
            eraserBtn = MakeButton("", Lang.T("Eraser"), true, delegate { ToggleEraser(); });
            boardBtn = MakeButton("▭", Lang.T("Board"), false, delegate { CycleBoard(); });
            Border undo = MakeButton("", Lang.T("Undo"), true, delegate { UndoStroke(); });
            Border clear = MakeButton("", Lang.T("Clear"), true, delegate { ClearPage(); });
            zoomBtn = MakeButton("", Lang.T("Zoom"), true, delegate { ToggleZoom(); });
            bubbleBtn = MakeButton("", Lang.T("Bubble"), true, delegate { ToggleText(); });
            setBtn = MakeButton("", Lang.T("Settings"), true, delegate { ToggleSettings(); });
            boardLabel = (TextBlock)((StackPanel)boardBtn.Child).Children[1];

            Tip(spotBtn, Lang.T("MouseSpot"), "S");
            Tip(penBtn, Lang.T("Pen"), "P");
            eraserBtn.ToolTip = Lang.T("EraserTip");
            Tip(boardBtn, Lang.T("BoardTip"), "B");
            Tip(undo, Lang.T("Undo"), "Z");
            Tip(clear, Lang.T("ClearTip"), "C");
            Tip(zoomBtn, ZoomTipText(), "X");
            Tip(bubbleBtn, Lang.T("Bubble"), "T");
            Tip(setBtn, Lang.T("Settings"), "D");
            Tip(ab, Lang.T("Collapse"), "H");

            buttons.Children.Add(spotBtn);
            buttons.Children.Add(penBtn);
            buttons.Children.Add(eraserBtn);
            buttons.Children.Add(boardBtn);
            buttons.Children.Add(undo);
            buttons.Children.Add(clear);
            buttons.Children.Add(bubbleBtn);
            buttons.Children.Add(zoomBtn);
            buttons.Children.Add(setBtn);

            // red close button
            Border close = new Border { Height = 52, Background = Idle, Cursor = Cursors.Hand, Margin = new Thickness(0, 1, 0, 0) };
            Grid cg = new Grid { Width = 30, Height = 30, HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Center };
            cg.Children.Add(new Ellipse { Fill = new SolidColorBrush(Color.FromRgb(0xD9, 0x30, 0x25)), Stroke = Brushes.White, StrokeThickness = 2 });
            cg.Children.Add(new TextBlock { Text = "", FontFamily = new FontFamily("Segoe MDL2 Assets"), Foreground = Brushes.White, FontSize = 14, FontWeight = FontWeights.Bold, HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Center });
            close.Child = cg;
            Tip(close, Lang.T("Quit"), "Q");
            close.MouseLeftButtonUp += delegate { Quit(); };
            buttons.Children.Add(close);

            col.Children.Add(buttons);

            return new Border { Width = 84, Background = PanelBg, BorderBrush = Line, BorderThickness = new Thickness(1), Child = col };
        }

        static void Tip(Border b, string name, string key)
        {
            b.ToolTip = name + "  (Ctrl+Alt+" + key + ")";
        }

        Border MakeButton(string glyph, string label, bool segoe, MouseButtonEventHandler click)
        {
            StackPanel sp = new StackPanel { VerticalAlignment = VerticalAlignment.Center };
            TextBlock g = new TextBlock { Text = glyph, Foreground = Brushes.White, FontSize = 20, HorizontalAlignment = HorizontalAlignment.Center };
            g.FontFamily = segoe ? new FontFamily("Segoe MDL2 Assets") : new FontFamily("Segoe UI Symbol");
            TextBlock l = new TextBlock { Text = label, Foreground = Brushes.White, FontSize = 10, HorizontalAlignment = HorizontalAlignment.Center };
            sp.Children.Add(g);
            sp.Children.Add(l);
            Border b = new Border { Height = 52, Background = Idle, Cursor = Cursors.Hand, Margin = new Thickness(0, 1, 0, 0), Child = sp };
            b.MouseLeftButtonUp += click;
            return b;
        }

        Border BuildSettings()
        {
            StackPanel p = new StackPanel { Margin = new Thickness(10), Width = 190 };

            p.Children.Add(SecTitle(Lang.T("Monitor")));
            WrapPanel mp = new WrapPanel();
            int n = System.Windows.Forms.Screen.AllScreens.Length;
            for (int i = 0; i < n; i++)
            {
                int idx = i;
                Border mb = new Border { Width = 34, Height = 26, Margin = new Thickness(2), Cursor = Cursors.Hand, Background = Idle };
                mb.Child = new TextBlock { Text = (i + 1).ToString(), Foreground = Brushes.White, HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Center };
                mb.ToolTip = string.Format(Lang.T("MonitorTip"), i + 1);
                mb.MouseLeftButtonUp += delegate { cfg.Monitor = idx; cfg.Save(); ApplyMonitor(); };
                monitorBtns.Add(mb);
                mp.Children.Add(mb);
            }
            p.Children.Add(mp);
            p.Children.Add(new Separator { Margin = new Thickness(0, 8, 0, 4) });

            p.Children.Add(SecTitle(Lang.T("PenColor")));
            penSwatches = Swatches(cfg.PenColor, delegate (string c) { cfg.PenColor = c; ApplyPen(); cfg.Save(); }, true);
            p.Children.Add(penSwatches);
            p.Children.Add(SecTitle(Lang.T("PenSize")));
            p.Children.Add(MakeSlider(1, 30, cfg.PenSize, delegate (double v) { cfg.PenSize = v; ApplyPen(); cfg.Save(); }));

            pressureBtn = new Border { Height = 26, Margin = new Thickness(0, 6, 0, 0), Cursor = Cursors.Hand, ToolTip = Lang.T("Pressure") + "  (Ctrl+Alt+R)" };
            pressureText = new TextBlock { Foreground = Brushes.White, HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Center };
            pressureBtn.Child = pressureText;
            pressureBtn.MouseLeftButtonUp += delegate { TogglePressure(); };
            UpdatePressureButton();
            p.Children.Add(pressureBtn);

            p.Children.Add(new Separator { Margin = new Thickness(0, 8, 0, 4) });

            p.Children.Add(SecTitle(Lang.T("SpotColor")));
            p.Children.Add(Swatches(cfg.SpotColor, delegate (string c) { cfg.SpotColor = c; ApplySpot(); cfg.Save(); }, false));
            p.Children.Add(SecTitle(Lang.T("SpotSize")));
            p.Children.Add(MakeSlider(20, 200, cfg.SpotSize, delegate (double v) { cfg.SpotSize = v; ApplySpot(); cfg.Save(); }));

            p.Children.Add(new Separator { Margin = new Thickness(0, 8, 0, 4) });
            p.Children.Add(SecTitle(Lang.T("ZoomFactor")));
            WrapPanel zp = new WrapPanel();
            zoomFactorBtns.Clear();
            foreach (double f in Zoomer.Factors)
            {
                double fv = f;
                Border zb = new Border { Width = 58, Height = 26, Margin = new Thickness(2), Cursor = Cursors.Hand, Background = f == cfg.ZoomFactor ? Active : Idle };
                zb.Child = new TextBlock { Text = FactorText(f) + "x", Foreground = Brushes.White, HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Center };
                zb.MouseLeftButtonUp += delegate { SetZoomFactor(fv); };
                zoomFactorBtns.Add(zb);
                zp.Children.Add(zb);
            }
            p.Children.Add(zp);

            p.Children.Add(new Separator { Margin = new Thickness(0, 8, 0, 4) });
            p.Children.Add(SecTitle(Lang.T("Language")));
            WrapPanel lp = new WrapPanel();
            for (int i = 0; i < Lang.Codes.Length; i++)
            {
                int idx = i;
                Border lb = new Border { Width = 58, Height = 26, Margin = new Thickness(2), Cursor = Cursors.Hand, Background = i == Lang.Cur ? Active : Idle };
                lb.Child = new TextBlock { Text = Lang.Names[i], Foreground = Brushes.White, FontSize = 11, HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Center };
                lb.MouseLeftButtonUp += delegate { if (idx != Lang.Cur) SetLanguage(idx); };
                lp.Children.Add(lb);
            }
            p.Children.Add(lp);

            p.Children.Add(new Separator { Margin = new Thickness(0, 8, 0, 4) });
            p.Children.Add(new TextBlock { Text = "HighPen v" + AppVersion, Foreground = Brushes.Gray, FontSize = 11, HorizontalAlignment = HorizontalAlignment.Center });

            return new Border { Background = PanelBg, BorderBrush = Line, BorderThickness = new Thickness(0, 1, 1, 1), Child = p, VerticalAlignment = VerticalAlignment.Top };
        }

        static TextBlock SecTitle(string t)
        {
            return new TextBlock { Text = t, Foreground = Brushes.White, FontSize = 12, Margin = new Thickness(0, 6, 0, 4) };
        }

        static Color ParseColor(string s)
        {
            return (Color)ColorConverter.ConvertFromString(s);
        }

        static Panel Swatches(string current, Action<string> onPick, bool pen)
        {
            WrapPanel wp = new WrapPanel();
            List<Border> list = new List<Border>();
            for (int pi = 0; pi < Palette.Length; pi++)
            {
                string h = Palette[pi];
                Border b = new Border { Width = 24, Height = 24, CornerRadius = new CornerRadius(12), Margin = new Thickness(2), Cursor = Cursors.Hand, Background = new SolidColorBrush(ParseColor(h)), BorderBrush = Brushes.Gray, BorderThickness = new Thickness(1), Tag = h };
                b.ToolTip = Lang.T(ColorNames[pi]) + (pen ? "  (Ctrl+Shift+" + ColorKeyText[pi] + ")" : "");
                if (string.Equals(h, current, StringComparison.OrdinalIgnoreCase)) { b.BorderBrush = Brushes.White; b.BorderThickness = new Thickness(3); }
                b.MouseLeftButtonUp += delegate
                {
                    foreach (Border o in list) { o.BorderBrush = Brushes.Gray; o.BorderThickness = new Thickness(1); }
                    b.BorderBrush = Brushes.White; b.BorderThickness = new Thickness(3);
                    onPick(h);
                };
                list.Add(b);
                wp.Children.Add(b);
            }
            return wp;
        }

        static Slider MakeSlider(double min, double max, double val, Action<double> onChange)
        {
            Slider s = new Slider { Minimum = min, Maximum = max, Value = val, Width = 170, HorizontalAlignment = HorizontalAlignment.Left };
            s.ValueChanged += delegate { onChange(s.Value); };
            return s;
        }

        // ---------- behaviour ----------

        void ToggleSpot() { cfg.SpotOn = !cfg.SpotOn; ApplySpot(); cfg.Save(); }
        void TogglePen()
        {
            if (penMode && !eraser && !textMode) { SetPen(false); return; }
            eraser = false;
            textMode = false;
            SetPen(true);
        }
        void ToggleEraser() { eraser = !eraser; textMode = false; if (eraser) penMode = true; ApplyMode(); }
        // First press enters eraser mode; pressing again while erasing wipes all strokes and speech bubbles on this page.
        void EraserHotkey()
        {
            if (eraser) ClearPage();
            else ToggleEraser();
        }
        void ToggleText() { textMode = !textMode; if (textMode) { penMode = true; eraser = false; } ApplyMode(); }
        void ToggleSettings() { settingsOpen = !settingsOpen; ApplyMode(); }
        void ToggleZoom()
        {
            if (zoomer.Active) zoomer.Stop();
            else zoomer.Start(new IntPtr[] {
                new WindowInteropHelper(this).Handle,
                new WindowInteropHelper(overlay).Handle,
                new WindowInteropHelper(spotWin).Handle });
            Highlight(zoomBtn, zoomer.Active);
            ReassertTop();
        }
        static string FactorText(double f) { return f.ToString(System.Globalization.CultureInfo.InvariantCulture); }
        string ZoomTipText() { return string.Format(Lang.T("ZoomTip"), FactorText(cfg.ZoomFactor)); }

        void SetZoomFactor(double f)
        {
            cfg.ZoomFactor = f;
            cfg.Save();
            zoomer.Factor = f;
            for (int i = 0; i < zoomFactorBtns.Count; i++)
                zoomFactorBtns[i].Background = Zoomer.Factors[i] == f ? Active : Idle;
            Tip(zoomBtn, ZoomTipText(), "X");
        }

        void Quit() { zoomer.Stop(); cfg.Save(); Application.Current.Shutdown(); }

        // ---------- global hotkeys (Ctrl+Alt+key) ----------

        const int WM_HOTKEY = 0x0312;
        const uint MOD_ALT = 1, MOD_CONTROL = 2, MOD_SHIFT = 4, MOD_NOREPEAT = 0x4000;
        Dictionary<int, Action> hotkeys = new Dictionary<int, Action>();

        void RegisterHotkeys()
        {
            IntPtr h = new WindowInteropHelper(this).Handle;
            HwndSource.FromHwnd(h).AddHook(HotkeyHook);
            AddHotkey(h, Key.S, ToggleSpot);
            AddHotkey(h, Key.P, TogglePen);
            AddHotkey(h, Key.E, EraserHotkey);
            AddHotkey(h, Key.B, CycleBoard);
            AddHotkey(h, Key.Z, UndoStroke);
            AddHotkey(h, Key.C, delegate { ClearPage(); });
            AddHotkey(h, Key.D, ToggleSettings);
            AddHotkey(h, Key.T, ToggleText);
            AddHotkey(h, Key.X, ToggleZoom);
            AddHotkey(h, Key.M, CycleMonitor);
            AddHotkey(h, Key.R, TogglePressure);
            for (int i = 0; i < Palette.Length; i++)
            {
                int ci = i;
                AddHotkey(h, ColorKeys[i], MOD_CONTROL | MOD_SHIFT, delegate { SetPenColor(ci); });
            }
            AddHotkey(h, Key.H, ToggleCollapse);
            AddHotkey(h, Key.Q, Quit);
        }

        void AddHotkey(IntPtr h, Key key, Action a)
        {
            AddHotkey(h, key, MOD_CONTROL | MOD_ALT, a);
        }

        void AddHotkey(IntPtr h, Key key, uint mods, Action a)
        {
            int id = hotkeys.Count + 1;
            if (Native.RegisterHotKey(h, id, mods | MOD_NOREPEAT, (uint)KeyInterop.VirtualKeyFromKey(key)))
                hotkeys[id] = a;
        }

        IntPtr HotkeyHook(IntPtr hwnd, int msg, IntPtr wParam, IntPtr lParam, ref bool handled)
        {
            Action a;
            if (msg == WM_HOTKEY && hotkeys.TryGetValue(wParam.ToInt32(), out a)) { a(); handled = true; }
            return IntPtr.Zero;
        }

        void ToggleCollapse()
        {
            collapsed = !collapsed;
            buttons.Visibility = collapsed ? Visibility.Collapsed : Visibility.Visible;
            arrow.Text = collapsed ? "" : "";
            ApplyMode();
        }

        void SetPen(bool on)
        {
            penMode = on;
            if (!on) textMode = false;
            if (!on) { eraser = false; board = 0; }
            ApplyMode();
        }

        void CycleBoard()
        {
            board = (board + 1) % 3;
            if (board != 0) { penMode = true; eraser = false; textMode = false; }
            // keep the pen visible against the board colour
            Color c = ParseColor(cfg.PenColor);
            if (board == 2 && c == Colors.Black) cfg.PenColor = "#FFFFFF";
            else if (board == 1 && c == Colors.White) cfg.PenColor = "#000000";
            ApplyMode();
        }

        void ClearPage()
        {
            history[board].Clear();
            undoing = true;
            overlay.Canvas.Strokes.Clear();
            undoing = false;
            overlay.Canvas.Children.Clear();
            overlay.Bubbles[board].Clear();
        }

        // ---------- speech bubbles ----------

        void BeginBubble(Point pos)
        {
            InkCanvas ic = overlay.Canvas;
            TextBox tb = new TextBox();
            tb.MinWidth = 120;
            tb.FontSize = Math.Max(16, cfg.PenSize * 4);
            tb.AcceptsReturn = true;
            tb.Padding = new Thickness(6);
            tb.BorderBrush = new SolidColorBrush(ParseColor(cfg.PenColor));
            tb.BorderThickness = new Thickness(2);
            InkCanvas.SetLeft(tb, pos.X);
            InkCanvas.SetTop(tb, pos.Y);
            ic.Children.Add(tb);
            bool done = false;
            Action<bool> finish = delegate (bool commit)
            {
                if (done) return;
                done = true;
                ic.Children.Remove(tb);
                if (commit && tb.Text.Trim().Length > 0) AddBubble(tb.Text.Trim(), pos);
                textMode = false;
                ApplyMode();
            };
            tb.PreviewKeyDown += delegate (object o, KeyEventArgs e)
            {
                if (e.Key == Key.Escape) finish(false);
                else if (e.Key == Key.Enter && (Keyboard.Modifiers & ModifierKeys.Shift) == 0) { finish(true); e.Handled = true; }
            };
            // Focus only after the overlay has actually been activated, and only treat focus loss
            // as "done" once the box has really had focus.
            Dispatcher.BeginInvoke(DispatcherPriority.Input, new Action(delegate
            {
                overlay.Activate();
                tb.Focus();
                Keyboard.Focus(tb);
                tb.LostKeyboardFocus += delegate { finish(true); };
            }));
        }

        void AddBubble(string text, Point pos)
        {
            Color c = ParseColor(cfg.PenColor);
            Border b = new Border();
            b.Background = new SolidColorBrush(Color.FromArgb(0xEE, 255, 255, 255));
            b.BorderBrush = new SolidColorBrush(c);
            b.BorderThickness = new Thickness(2);
            b.CornerRadius = new CornerRadius(12);
            b.Padding = new Thickness(10, 6, 10, 6);
            b.Child = new TextBlock { Text = text, Foreground = Brushes.Black, FontSize = Math.Max(16, cfg.PenSize * 4), TextWrapping = TextWrapping.Wrap, MaxWidth = 600 };
            InkCanvas.SetLeft(b, pos.X);
            InkCanvas.SetTop(b, pos.Y);
            overlay.Bubbles[board].Add(b);
            overlay.Canvas.Children.Add(b);
        }

        // ---------- undo ----------

        // One undo step: a pen stroke, or every stroke removed by one eraser drag.
        class InkEdit
        {
            public StrokeCollection Added = new StrokeCollection();
            public StrokeCollection Removed = new StrokeCollection();
        }

        List<InkEdit>[] history = { new List<InkEdit>(), new List<InkEdit>(), new List<InkEdit>() };
        bool undoing, pressed, newEdit;

        // Stylus input is promoted to mouse events too, so only the first down of a press starts a new step.
        void BeginPress()
        {
            if (pressed) return;
            pressed = true;
            newEdit = true;
        }

        void RecordInkEdit(int page, StrokeCollectionChangedEventArgs e)
        {
            if (undoing) return;
            List<InkEdit> h = history[page];
            if (newEdit || !pressed || h.Count == 0) { h.Add(new InkEdit()); newEdit = false; }
            InkEdit top = h[h.Count - 1];
            foreach (Stroke st in e.Added) top.Added.Add(st);
            foreach (Stroke st in e.Removed)
            {
                if (top.Added.Contains(st)) top.Added.Remove(st);
                else top.Removed.Add(st);
            }
        }

        void UndoStroke()
        {
            List<InkEdit> h = history[board];
            if (h.Count == 0) return;
            InkEdit last = h[h.Count - 1];
            h.RemoveAt(h.Count - 1);
            StrokeCollection s = overlay.Pages[board];
            undoing = true;
            foreach (Stroke st in last.Added) if (s.Contains(st)) s.Remove(st);
            foreach (Stroke st in last.Removed) if (!s.Contains(st)) s.Add(st);
            undoing = false;
        }

        void ApplyPen()
        {
            DrawingAttributes da = new DrawingAttributes();
            da.Color = ParseColor(cfg.PenColor);
            da.Width = cfg.PenSize;
            da.Height = cfg.PenSize;
            da.FitToCurve = true;
            da.IgnorePressure = !cfg.Pressure;
            overlay.Canvas.DefaultDrawingAttributes = da;
        }

        void ApplySpot()
        {
            spotWin.SetStyle(ParseColor(cfg.SpotColor), cfg.SpotSize);
            spotWin.SetSpotVisible(cfg.SpotOn);
            Highlight(spotBtn, cfg.SpotOn);
        }

        void ApplyMode()
        {
            InkCanvas ic = overlay.Canvas;
            ic.Strokes = overlay.Pages[board];
            ic.EditingMode = textMode ? InkCanvasEditingMode.None : (eraser ? InkCanvasEditingMode.EraseByStroke : InkCanvasEditingMode.Ink);
            if (shownBoard != board)
            {
                shownBoard = board;
                ic.Children.Clear();
                foreach (UIElement el in overlay.Bubbles[board]) ic.Children.Add(el);
            }
            // InkCanvas' built-in ink cursor is a barely visible dot, so use a real pointer
            ic.UseCustomCursor = true;
            ic.Cursor = textMode ? Cursors.IBeam : (eraser ? Cursors.Cross : Cursors.Pen);
            ApplyPen();

            if (board == 1) overlay.Background = Brushes.White;
            else if (board == 2) overlay.Background = Brushes.Black;
            else overlay.Background = penMode ? new SolidColorBrush(Color.FromArgb(1, 0, 0, 0)) : Brushes.Transparent;

            zoomer.Frozen = penMode;
            ApplyZoomTransform();
            Native.SetClickThrough(overlay, !penMode || suspended);
            ic.IsHitTestVisible = penMode;

            Highlight(penBtn, penMode && !eraser && !textMode);
            Highlight(eraserBtn, eraser);
            Highlight(bubbleBtn, textMode);
            Highlight(boardBtn, board != 0);
            Highlight(setBtn, settingsOpen);
            boardLabel.Text = Lang.T(board == 0 ? "Board" : (board == 1 ? "WhiteBoard" : "BlackBoard"));

            settingsPanel.Visibility = (settingsOpen && !collapsed) ? Visibility.Visible : Visibility.Collapsed;
            ReassertTop();
        }

        static void Highlight(Border b, bool on)
        {
            b.Background = on ? Active : Idle;
        }
    }

    class App : Application
    {
        [STAThread]
        static void Main()
        {
            App app = new App();
            app.ShutdownMode = ShutdownMode.OnExplicitShutdown;
            Settings cfg = Settings.Load();
            Lang.Cur = Lang.FromCode(cfg.Language);
            OverlayWindow overlay = new OverlayWindow();
            SpotWindow spot = new SpotWindow();
            ToolbarWindow bar = new ToolbarWindow(cfg, overlay, spot);
            overlay.Show();
            spot.Show();
            bar.Show();
            app.Run();
        }
    }
}
