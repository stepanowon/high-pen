using System;
using System.Windows.Threading;

namespace HighPen
{
    // Watches for the Windows snipping overlay (Win+Shift+S) and reports when it appears or goes away,
    // so HighPen can get out of its way while it is up.
    class SnippingWatcher
    {
        readonly DispatcherTimer timer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(100) };
        IntPtr lastFg = IntPtr.Zero;
        bool lastFgIsSnip;

        public bool Active { get; private set; }
        public Action<bool> Changed;

        public SnippingWatcher()
        {
            timer.Tick += delegate { Check(); };
        }

        public void Start() { timer.Start(); }

        void Check()
        {
            bool snip = IsOverlayActive();
            if (snip == Active) return;
            Active = snip;
            if (Changed != null) Changed(snip);
        }

        // True while the snipping overlay is the foreground, full-screen window.
        bool IsOverlayActive()
        {
            IntPtr h = Native.GetForegroundWindow();
            if (h == IntPtr.Zero) { lastFg = IntPtr.Zero; return false; }
            if (h != lastFg)
            {
                lastFg = h;
                lastFgIsSnip = false;
                try
                {
                    uint pid;
                    Native.GetWindowThreadProcessId(h, out pid);
                    string n = System.Diagnostics.Process.GetProcessById((int)pid).ProcessName;
                    lastFgIsSnip = n.Equals("SnippingTool", StringComparison.OrdinalIgnoreCase) || n.Equals("ScreenClippingHost", StringComparison.OrdinalIgnoreCase);
                }
                catch { }
            }
            if (!lastFgIsSnip) return false;
            Native.RECT r;
            if (!Native.GetWindowRect(h, out r)) return false;
            System.Drawing.Rectangle b = System.Windows.Forms.Screen.FromHandle(h).Bounds;
            // the overlay spans the whole screen; the editor window of Snipping Tool does not
            return (r.Right - r.Left) >= b.Width * 0.9 && (r.Bottom - r.Top) >= b.Height * 0.9;
        }
    }
}
