using System;
using System.Collections.Generic;
using System.Windows.Threading;

namespace HighPen
{
    // Live zoom (1.5x / 2x / 2.5x) of the monitor under the mouse pointer, using the Windows Magnification API.
    // The real pointer stays on the unzoomed content, hidden, and the magnifier draws it enlarged in the image,
    // so a click lands exactly on what the pointer is shown over. The view holds still until the pointer
    // reaches one of its edges and then moves along with the pointer.
    // HighPen's own windows are not magnified, windows above the magnifier cover its image, and the ink canvas takes
    // input in display coordinates, so there the real pointer is shown instead, at the position on the display (see pointerDirect).
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
        // Something covers the zoomed image (the break screen, the snipping overlay): the pointer must show above it.
        public bool Direct;
        // Reports the zoomed monitor bounds and the source rect being shown (empty bounds = zoom off).
        public Action<System.Drawing.Rectangle, Native.RECT> ViewChanged;
        // The magnifier window's current placement (empty = place it on the next update).
        System.Drawing.Rectangle current;
        // The zoomed monitor, fixed when zoom starts: locked in physical pixels, lockedView in the process' own coordinates.
        IntPtr lockedMonitor;
        System.Drawing.Rectangle locked, lockedView;
        // Top left of the source rect in physical pixels, and the factor it was worked out for.
        int viewX, viewY;
        float viewFactor;
        bool viewSet;
        // The source rect in the process' own coordinates.
        Native.RECT shownView;
        // True: the real pointer is visible and its position is the position on the display.
        // False: it is hidden, on the content, and the magnifier draws it.
        bool pointerDirect = true;
        // Redraw on the next update even while frozen.
        bool redraw;
        System.Drawing.Rectangle clip;
        // HighPen's own windows, found on each update. While the pointer is drawn by the magnifier they let clicks
        // through: the hidden pointer can pass over them although it is shown somewhere else.
        readonly List<IntPtr> ownWindows = new List<IntPtr>();
        readonly List<IntPtr> madeClickThrough = new List<IntPtr>();
        readonly Native.EnumWindowsProc scanOwnWindow;
        Native.POINT scanPoint;
        bool scanHit;
        static readonly Predicate<IntPtr> WindowClosed = h => !Native.IsWindow(h);
        // The pointer position after the last update, and how many updates ago the windows were last looked at
        // and the image last refreshed. While the pointer rests both happen less often.
        Native.POINT lastPointer;
        int updatesSinceScan, updatesSinceDraw;
        bool coveredAtPointer, ownAtPointer;
        // Holding the real pointer on the monitor's edge over a HighPen window moves the view: about 200 ms before it
        // starts, so a pointer flung at the bar does not move anything, and then about 1.4 s across the whole view.
        const int EdgeHoldUpdates = 12, EdgeCrossUpdates = 90;
        int edgeHeld;
        // The Windows screens that sit above topmost windows but are not in the ordinary window order:
        // Start and search, Alt+Tab and Task View, quick settings, the tray overflow.
        static readonly string[] ShellOverlays = { "Windows.UI.Core.CoreWindow", "XamlExplorerHostIslandWindow", "XamlExplorerHostIslandWindow_WASDK", "ControlCenterWindow", "TopLevelWindowForOverflowXamlIsland", "NotifyIconOverflowWindow" };
        IntPtr checkedForeground;
        bool foregroundIsOverlay;
        // Where the pointer came off a window. The two coordinate systems round differently, so that position can map
        // back just inside the window; it only counts as over the window again once the pointer has moved.
        Native.POINT leftAt;
        bool justLeft;
        readonly DispatcherTimer timer = new DispatcherTimer();
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
                redraw = true;
                Update();
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
            scanOwnWindow = ScanOwnWindow;
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
            viewSet = false;
            pointerDirect = true;
            redraw = true;
            justLeft = false;
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
                clip = System.Drawing.Rectangle.Empty;
                RestoreClicks();
                ownWindows.Clear();
                if (!pointerDirect) Native.MagShowSystemCursor(true);
                pointerDirect = true;
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

        // Where a pointer position (in the process' own coordinates) appears on the display:
        // windows outside the magnified image, such as the spot, follow the pointer with this.
        public Native.POINT ToShown(Native.POINT p)
        {
            if (!Active || pointerDirect || lockedView.IsEmpty) return p;
            return ContentToDisplay(p, shownView.Left, shownView.Top, lockedView, factor);
        }

        void Update()
        {
            if (!Active) return;
            if (Frozen && pointerDirect && !redraw) return;
            Native.RECT r;
            IntPtr dpi = EnterPhysical();
            try { if (!UpdatePhysical(out r)) return; }
            finally { Leave(dpi); }
            // the rest of HighPen (the ink overlay) works in the process' own coordinates, which Windows scales
            // on a monitor whose scaling differs from the system DPI; hand the view over in those
            if (lockedView.IsEmpty) lockedView = Monitors.BoundsOf(lockedMonitor);
            if (lockedView.IsEmpty) lockedView = locked;
            shownView = ToView(r);
            if (ViewChanged != null) ViewChanged(lockedView, shownView);
        }

        // Moves the magnifier and the pointer, with every coordinate in physical pixels. Returns the source rect shown.
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
                locked = Monitors.BoundsOf(lockedMonitor);
                if (locked.IsEmpty) return false;
            }
            System.Drawing.Rectangle b = locked;
            int outsideX = p.X, outsideY = p.Y;
            p.X = Math.Max(b.Left, Math.Min(b.Right - 1, p.X));
            p.Y = Math.Max(b.Top, Math.Min(b.Bottom - 1, p.Y));
            // Windows can drop the clip when another window comes to the front; a hidden pointer must not get away
            if (!Direct && (p.X != outsideX || p.Y != outsideY))
            {
                Native.SetCursorPos(p.X, p.Y);
                clip = System.Drawing.Rectangle.Empty;
            }
            if (b != current)
            {
                current = b;
                Native.SetWindowPos(host, Native.HWND_TOPMOST, b.X, b.Y, b.Width, b.Height, Native.SWP_NOACTIVATE | Native.SWP_SHOWWINDOW);
                Native.MoveWindow(mag, 0, 0, b.Width, b.Height, true);
            }
            int w = (int)(b.Width / factor), h = (int)(b.Height / factor);
            if (!viewSet)
            {
                // the content under the pointer stays under the pointer when zoom starts
                viewSet = true;
                viewX = b.X + (int)Math.Round((p.X - b.X) * (1.0 - 1.0 / factor));
                viewY = b.Y + (int)Math.Round((p.Y - b.Y) * (1.0 - 1.0 / factor));
                viewFactor = factor;
            }
            else if (viewFactor != factor)
            {
                // the content the pointer is shown over stays there when the factor changes
                Native.POINT at = pointerDirect ? p : ContentToDisplay(p, viewX, viewY, b, viewFactor);
                viewX = (int)Math.Round(viewX + (at.X - b.X) * (1.0 / viewFactor - 1.0 / factor));
                viewY = (int)Math.Round(viewY + (at.Y - b.Y) * (1.0 / viewFactor - 1.0 / factor));
                viewFactor = factor;
            }
            viewX = Math.Max(b.Left, Math.Min(b.Right - w, viewX));
            viewY = Math.Max(b.Top, Math.Min(b.Bottom - h, viewY));

            Native.POINT shown = pointerDirect ? p : ContentToDisplay(p, viewX, viewY, b, factor);
            bool moved = p.X != lastPointer.X || p.Y != lastPointer.Y;
            // a window opening under a resting pointer is noticed a little later
            if (moved || redraw || ++updatesSinceScan >= 8)
            {
                updatesSinceScan = 0;
                ownAtPointer = ScanOwnWindows(shown);
                coveredAtPointer = ownAtPointer || ShellOverlayOn(b) || WindowAboveAt(shown);
            }
            bool covered = coveredAtPointer;
            if (justLeft)
            {
                if (p.X == leftAt.X && p.Y == leftAt.Y) covered = false;
                else justLeft = false;
            }
            // a held button stays with the pointer mode it was pressed in, so a drag is not cut off halfway
            if (covered != pointerDirect && ButtonHeld()) covered = pointerDirect;
            bool direct = Frozen || Direct || covered;
            bool switched = direct != pointerDirect;
            if (switched)
            {
                // the old clip could keep the pointer from reaching its new position
                SetClip(b);
                p = direct ? shown : DisplayToContent(p, b);
                Native.SetCursorPos(p.X, p.Y);
                ShowPointerInImage(!direct);
                leftAt = p;
                justLeft = !direct;
            }
            if (direct) RestoreClicks();
            else LetClicksThrough();

            int shownX = viewX, shownY = viewY;
            if (!direct)
            {
                if (Locked) KeepInView(ref p, w, h);
                else
                {
                    viewX = Pan(viewX, w, p.X);
                    viewY = Pan(viewY, h, p.Y);
                }
            }
            // a HighPen window along the monitor's edge keeps the hidden pointer from getting to the edge of the view
            if (direct && ownAtPointer && !Frozen && !Direct && !Locked && !ButtonHeld()) PanFromEdge(p, b, w, h);
            else edgeHeld = 0;
            lastPointer = p;
            // locked, the pointer cannot leave the part being shown: outside it there would be no pointer to see
            SetClip(!direct && Locked ? new System.Drawing.Rectangle(viewX, viewY, w, h) : b);

            r.Left = viewX;
            r.Top = viewY;
            r.Right = viewX + w;
            r.Bottom = viewY + h;
            // the image stays live while the pointer rests (a video may be playing), at about a third of the rate
            if (moved || redraw || switched || viewX != shownX || viewY != shownY || ++updatesSinceDraw >= 3)
            {
                updatesSinceDraw = 0;
                Native.MagSetWindowSource(mag, r);
                // asks for a redraw on every update, as Microsoft's magnifier sample does; not tested without it
                Native.InvalidateRect(mag, IntPtr.Zero, false);
            }
            redraw = false;
            return true;
        }

        // The start of the view along one axis, moved only as far as it takes to keep the pointer inside.
        static int Pan(int start, int size, int pointer)
        {
            if (pointer < start) return pointer;
            if (pointer >= start + size) return pointer - size + 1;
            return start;
        }

        void PanFromEdge(Native.POINT p, System.Drawing.Rectangle b, int w, int h)
        {
            int dx = p.X <= b.Left ? -1 : (p.X >= b.Right - 1 ? 1 : 0);
            int dy = p.Y <= b.Top ? -1 : (p.Y >= b.Bottom - 1 ? 1 : 0);
            if (dx == 0 && dy == 0) { edgeHeld = 0; return; }
            if (edgeHeld < EdgeHoldUpdates) { edgeHeld++; return; }
            viewX = Math.Max(b.Left, Math.Min(b.Right - w, viewX + dx * Math.Max(1, w / EdgeCrossUpdates)));
            viewY = Math.Max(b.Top, Math.Min(b.Bottom - h, viewY + dy * Math.Max(1, h / EdgeCrossUpdates)));
        }

        // Windows can drop the clip when another window comes to the front.
        void KeepInView(ref Native.POINT p, int w, int h)
        {
            int x = Math.Max(viewX, Math.Min(viewX + w - 1, p.X));
            int y = Math.Max(viewY, Math.Min(viewY + h - 1, p.Y));
            if (x == p.X && y == p.Y) return;
            p.X = x;
            p.Y = y;
            Native.SetCursorPos(x, y);
            clip = System.Drawing.Rectangle.Empty;
        }

        static Native.POINT ContentToDisplay(Native.POINT p, int left, int top, System.Drawing.Rectangle b, float f)
        {
            Native.POINT o;
            o.X = Math.Max(b.Left, Math.Min(b.Right - 1, b.X + (int)Math.Round((p.X - left) * f)));
            o.Y = Math.Max(b.Top, Math.Min(b.Bottom - 1, b.Y + (int)Math.Round((p.Y - top) * f)));
            return o;
        }

        Native.POINT DisplayToContent(Native.POINT p, System.Drawing.Rectangle b)
        {
            Native.POINT o;
            o.X = viewX + (int)((p.X - b.X) / factor);
            o.Y = viewY + (int)((p.Y - b.Y) / factor);
            return o;
        }

        void ShowPointerInImage(bool on)
        {
            int style = Native.GetWindowLong(mag, Native.GWL_STYLE);
            Native.SetWindowLong(mag, Native.GWL_STYLE, on ? style | Native.MS_SHOWMAGNIFIEDCURSOR : style & ~Native.MS_SHOWMAGNIFIEDCURSOR);
            Native.MagShowSystemCursor(!on);
            pointerDirect = !on;
        }

        void SetClip(System.Drawing.Rectangle area)
        {
            if (area == clip) return;
            clip = area;
            Native.RECT c;
            c.Left = area.Left; c.Top = area.Top; c.Right = area.Right; c.Bottom = area.Bottom;
            Native.ClipCursor(ref c);
        }

        static bool ButtonHeld()
        {
            return (Native.GetAsyncKeyState(Native.VK_LBUTTON) & 0x8000) != 0
                || (Native.GetAsyncKeyState(Native.VK_RBUTTON) & 0x8000) != 0
                || (Native.GetAsyncKeyState(Native.VK_MBUTTON) & 0x8000) != 0;
        }

        // Lists HighPen's own windows that take clicks and tells whether one of them is at the given point.
        bool ScanOwnWindows(Native.POINT at)
        {
            ownWindows.Clear();
            scanPoint = at;
            scanHit = false;
            Native.EnumThreadWindows(Native.GetCurrentThreadId(), scanOwnWindow, IntPtr.Zero);
            return scanHit;
        }

        bool ScanOwnWindow(IntPtr h, IntPtr data)
        {
            if (h == host || !Native.IsWindowVisible(h)) return true;
            bool throughAlways = (Native.GetWindowLong(h, Native.GWL_EXSTYLE) & Native.WS_EX_TRANSPARENT) != 0 && !madeClickThrough.Contains(h);
            if (throughAlways) return true;
            ownWindows.Add(h);
            if (Contains(h, scanPoint)) scanHit = true;
            return true;
        }

        // A Windows screen such as the Start menu is up on the zoomed monitor. It comes with the taskbar and covers the
        // image the pointer is drawn in, so the real pointer is used on the whole monitor until it closes.
        bool ShellOverlayOn(System.Drawing.Rectangle b)
        {
            IntPtr h = Native.GetForegroundWindow();
            if (h != checkedForeground)
            {
                checkedForeground = h;
                System.Text.StringBuilder name = new System.Text.StringBuilder(64);
                Native.GetClassName(h, name, name.Capacity);
                foregroundIsOverlay = Array.IndexOf(ShellOverlays, name.ToString()) >= 0;
            }
            if (!foregroundIsOverlay) return false;
            Native.RECT r;
            return Native.GetWindowRect(h, out r) && r.Left < b.Right && r.Right > b.Left && r.Top < b.Bottom && r.Bottom > b.Top;
        }

        // Another program's window above the magnifier at the given point, such as a topmost window until HighPen's
        // windows are next raised: it covers the image the pointer is drawn in, and it is shown where it really is.
        bool WindowAboveAt(Native.POINT at)
        {
            uint me = Native.GetCurrentThreadId();
            IntPtr h = Native.GetWindow(host, Native.GW_HWNDPREV);
            for (int i = 0; h != IntPtr.Zero && i < 256; i++, h = Native.GetWindow(h, Native.GW_HWNDPREV))
            {
                uint pid;
                if (!Native.IsWindowVisible(h) || Native.GetWindowThreadProcessId(h, out pid) == me) continue;
                if ((Native.GetWindowLong(h, Native.GWL_EXSTYLE) & Native.WS_EX_TRANSPARENT) != 0) continue;
                int cloaked;
                if (Native.DwmGetWindowAttribute(h, Native.DWMWA_CLOAKED, out cloaked, sizeof(int)) == 0 && cloaked != 0) continue;
                if (Contains(h, at)) return true;
            }
            return false;
        }

        static bool Contains(IntPtr h, Native.POINT p)
        {
            Native.RECT r;
            return Native.GetWindowRect(h, out r) && p.X >= r.Left && p.X < r.Right && p.Y >= r.Top && p.Y < r.Bottom;
        }

        void LetClicksThrough()
        {
            madeClickThrough.RemoveAll(WindowClosed);
            foreach (IntPtr h in ownWindows)
            {
                if (madeClickThrough.Contains(h)) continue;
                madeClickThrough.Add(h);
                Native.SetWindowLong(h, Native.GWL_EXSTYLE, Native.GetWindowLong(h, Native.GWL_EXSTYLE) | Native.WS_EX_TRANSPARENT);
            }
        }

        void RestoreClicks()
        {
            if (madeClickThrough.Count == 0) return;
            madeClickThrough.RemoveAll(WindowClosed);
            foreach (IntPtr h in madeClickThrough)
                Native.SetWindowLong(h, Native.GWL_EXSTYLE, Native.GetWindowLong(h, Native.GWL_EXSTYLE) & ~Native.WS_EX_TRANSPARENT);
            madeClickThrough.Clear();
        }

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
    }
}
