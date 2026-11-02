using System;
using System.Windows.Threading;

namespace HighPen
{
    // Live zoom (1.5x / 2x / 2.5x) of the monitor under the mouse pointer, using the Windows Magnification API.
    // The view is positioned so the content under the pointer stays under the pointer,
    // so clicks (the host window is click-through) land exactly where they appear —
    // except after the pointer touches a monitor edge, when the view holds at that edge until
    // the pointer passes the middle of the screen again (see Offset).
    class Zoomer : ITopmost
    {
        public static readonly double[] Factors = { 1.5, 2, 2.5 };
        float factor = 2f;
        IntPtr host, mag;
        IntPtr[] exclude;
        // While frozen the view stays put so the user can draw on it.
        public bool Frozen;
        // Set by the user (zoom lock): the view stays put while the pointer moves. Cleared when zoom stops.
        public bool Locked;
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
                bool f = Frozen, l = Locked; Frozen = Locked = false; Update(); Frozen = f; Locked = l;
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
            // created per-monitor DPI aware, so Windows does not stretch the zoom window on a monitor whose
            // scaling differs from the system DPI and the window can be sized in physical pixels
            IntPtr dpi = EnterPhysical();
            try
            {
                host = Native.CreateWindowEx(Native.WS_EX_LAYERED | Native.WS_EX_TOPMOST | Native.WS_EX_TRANSPARENT | Native.WS_EX_NOACTIVATE | Native.WS_EX_TOOLWINDOW,
                    "Static", "HighPenZoom", Native.WS_POPUP, 0, 0, 100, 100, IntPtr.Zero, IntPtr.Zero, inst, IntPtr.Zero);
                if (host != IntPtr.Zero)
                    mag = Native.CreateWindowEx(0, "Magnifier", "HighPenMag", Native.WS_CHILD | Native.WS_VISIBLE, 0, 0, 100, 100, host, IntPtr.Zero, inst, IntPtr.Zero);
            }
            finally { Leave(dpi); }
            if (host == IntPtr.Zero) { Native.MagUninitialize(); return; }
            Native.SetLayeredWindowAttributes(host, 0, 255, 2);
            if (mag == IntPtr.Zero) { Stop(); return; }
            ApplyTransform();
            // keep the zoom window itself, the toolbar, the ink overlay and the spot out of the magnified image
            IntPtr[] list = new IntPtr[exclude.Length + 1];
            list[0] = host;
            exclude.CopyTo(list, 1);
            Native.MagSetWindowFilterList(mag, 0, list.Length, list);
            current = System.Drawing.Rectangle.Empty;
            edgeX = edgeY = 0;
            Update();
            Native.SetWindowPos(host, Native.HWND_TOPMOST, 0, 0, 0, 0, Native.SWP_NOSIZE | Native.SWP_NOMOVE | Native.SWP_NOACTIVATE | Native.SWP_SHOWWINDOW);
            timer.Start();
        }

        public void Stop()
        {
            timer.Stop();
            if (host != IntPtr.Zero)
            {
                Native.ClipCursor(IntPtr.Zero);
                locked = lockedView = System.Drawing.Rectangle.Empty;
                Locked = false;
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
            if ((Frozen || Locked) && current != System.Drawing.Rectangle.Empty) return;
            Native.RECT r;
            IntPtr dpi = EnterPhysical();
            try { if (!UpdatePhysical(out r)) return; }
            finally { Leave(dpi); }
            // the rest of HighPen (the ink overlay) works in the process' own coordinates, which Windows scales
            // on a monitor whose scaling differs from the system DPI; hand the view over in those
            if (lockedView.IsEmpty) lockedView = MonitorBounds(lockedMonitor);
            if (lockedView.IsEmpty) lockedView = locked;
            if (ViewChanged != null) ViewChanged(lockedView, ToView(r));
        }

        // Moves the magnifier, with every coordinate in physical pixels. Returns the source rect shown.
        // The Magnification API takes physical pixels, while HighPen itself is only system DPI aware; mixing the
        // two showed the wrong part of a monitor whose scaling differs from the system DPI.
        bool UpdatePhysical(out Native.RECT r)
        {
            r = new Native.RECT();
            Native.POINT p;
            if (!Native.GetCursorPos(out p)) return false;
            // the zoomed monitor is fixed when zoom starts; the pointer is confined to it
            if (locked.IsEmpty)
            {
                lockedMonitor = Native.MonitorFromPoint(p, Native.MONITOR_DEFAULTTONEAREST);
                locked = MonitorBounds(lockedMonitor);
                if (locked.IsEmpty) return false;
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
                Native.SetWindowPos(host, Native.HWND_TOPMOST, b.X, b.Y, b.Width, b.Height, Native.SWP_NOACTIVATE | Native.SWP_SHOWWINDOW);
                Native.MoveWindow(mag, 0, 0, b.Width, b.Height, true);
            }
            double k = 1.0 - 1.0 / factor;
            r.Left = b.X + (int)Math.Round(Offset(p.X - b.X, b.Width, k, ref edgeX));
            r.Top = b.Y + (int)Math.Round(Offset(p.Y - b.Y, b.Height, k, ref edgeY));
            r.Right = r.Left + (int)(b.Width / factor);
            r.Bottom = r.Top + (int)(b.Height / factor);
            Native.MagSetWindowSource(mag, r);
            return true;
        }

        // The zoomed monitor: locked in physical pixels, lockedView in the process' own coordinates.
        IntPtr lockedMonitor;
        System.Drawing.Rectangle lockedView;

        // A physical source rect on the zoomed monitor in the process' own coordinates.
        Native.RECT ToView(Native.RECT r)
        {
            System.Drawing.Rectangle p = locked, v = lockedView;
            if (p == v || p.Width <= 0 || p.Height <= 0) return r;
            double sx = (double)v.Width / p.Width, sy = (double)v.Height / p.Height;
            Native.RECT o;
            o.Left = v.X + (int)Math.Round((r.Left - p.X) * sx);
            o.Top = v.Y + (int)Math.Round((r.Top - p.Y) * sy);
            o.Right = v.X + (int)Math.Round((r.Right - p.X) * sx);
            o.Bottom = v.Y + (int)Math.Round((r.Bottom - p.Y) * sy);
            return o;
        }

        static System.Drawing.Rectangle MonitorBounds(IntPtr monitor)
        {
            Native.MONITORINFOEX mi = new Native.MONITORINFOEX();
            mi.cbSize = System.Runtime.InteropServices.Marshal.SizeOf(mi);
            if (monitor == IntPtr.Zero || !Native.GetMonitorInfo(monitor, ref mi)) return System.Drawing.Rectangle.Empty;
            return System.Drawing.Rectangle.FromLTRB(mi.rcMonitor.Left, mi.rcMonitor.Top, mi.rcMonitor.Right, mi.rcMonitor.Bottom);
        }

        // Switches this thread to per-monitor DPI awareness (physical pixels) and returns the previous context;
        // IntPtr.Zero when Windows is older than 10 1607, where the coordinates stay as they were.
        static IntPtr EnterPhysical()
        {
            try { return Native.SetThreadDpiAwarenessContext(Native.DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2); }
            catch (EntryPointNotFoundException) { return IntPtr.Zero; }
        }

        static void Leave(IntPtr previous)
        {
            if (previous != IntPtr.Zero) Native.SetThreadDpiAwarenessContext(previous);
        }

        // Which edge of the monitor the pointer last touched on each axis (-1 = start/left/top, 1 = end/right/bottom, 0 = none yet).
        int edgeX, edgeY;

        // Offset of the shown area along one axis, for pointer position t in [0, size-1].
        // Until an edge is touched the content under the pointer stays under the pointer.
        // After the pointer touches an edge the view stays at that edge until the pointer passes
        // the middle of the screen; from there it pans to the opposite edge, reaching it together with the pointer.
        static double Offset(int t, int size, double k, ref int edge)
        {
            int last = size - 1;
            if (last <= 0) return 0;
            if (t <= 0) edge = -1;
            else if (t >= last) edge = 1;
            double max = last * k, mid = last / 2.0;
            if (edge < 0) return t <= mid ? 0 : max * (t - mid) / (last - mid);
            if (edge > 0) return t >= mid ? max : max * t / mid;
            return t * k;
        }
    }
}
