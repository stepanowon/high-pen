using System;
using System.Collections.Generic;
using System.Windows;
using System.Windows.Interop;
using System.Windows.Media;

namespace HighPen
{
    // Win32 window operations on WPF windows.
    static class WindowUtil
    {
        public static IntPtr Handle(Window w)
        {
            return new WindowInteropHelper(w).Handle;
        }

        public static void AddExStyle(Window w, int style)
        {
            IntPtr h = Handle(w);
            Native.SetWindowLong(h, Native.GWL_EXSTYLE, Native.GetWindowLong(h, Native.GWL_EXSTYLE) | style);
        }

        public static void SetClickThrough(Window w, bool on)
        {
            IntPtr h = Handle(w);
            int s = Native.GetWindowLong(h, Native.GWL_EXSTYLE);
            s = on ? (s | Native.WS_EX_TRANSPARENT) : (s & ~Native.WS_EX_TRANSPARENT);
            Native.SetWindowLong(h, Native.GWL_EXSTYLE, s);
        }

        // Positions a window in physical pixels (avoids DPI rounding on multi-monitor setups).
        public static void PlaceRect(Window w, int x, int y, int cx, int cy, bool resize)
        {
            IntPtr h = new WindowInteropHelper(w).EnsureHandle();
            Native.SetWindowPos(h, Native.HWND_TOPMOST, x, y, cx, cy, Native.SWP_NOACTIVATE | (resize ? 0 : Native.SWP_NOSIZE));
        }

        public static void PlaceRect(Window w, System.Drawing.Rectangle r)
        {
            PlaceRect(w, r.X, r.Y, r.Width, r.Height, true);
        }

        public static void BringTopmost(Window w)
        {
            Native.SetWindowPos(Handle(w), Native.HWND_TOPMOST, 0, 0, 0, 0, Native.SWP_NOSIZE | Native.SWP_NOMOVE | Native.SWP_NOACTIVATE);
        }

        public static bool GetRect(Window w, out Native.RECT r)
        {
            return Native.GetWindowRect(Handle(w), out r);
        }

        // The window's laid-out size in physical pixels.
        public static System.Drawing.Size PixelSize(Window w)
        {
            DpiScale d = VisualTreeHelper.GetDpi(w);
            return new System.Drawing.Size((int)(w.ActualWidth * d.DpiScaleX), (int)(w.ActualHeight * d.DpiScaleY));
        }
    }

    // One connected display, in physical pixels.
    class MonitorInfo
    {
        public string DeviceName; // e.g. \\.\DISPLAY1; unlike the index it stays with the monitor while others come and go
        public System.Drawing.Rectangle Bounds, WorkingArea;
        public bool Primary;
    }

    // The connected displays in Windows' enumeration order (the order of Screen.AllScreens, so saved indexes
    // keep their meaning). The list is read fresh each time: Screen.AllScreens is cached until a display-change
    // notification arrives, and that notification can be missed or come too early when a monitor is unplugged.
    static class Monitors
    {
        // Replaceable for tests.
        public static Func<IList<MonitorInfo>> Source = Enumerate;

        public static IList<MonitorInfo> All { get { return Source(); } }
        public static int Count { get { return All.Count; } }

        // The monitor at idx, or the first one when idx is out of range.
        public static MonitorInfo Get(int idx)
        {
            IList<MonitorInfo> all = All;
            if (idx < 0 || idx >= all.Count) idx = 0;
            return all[idx];
        }

        // -1 when no connected monitor has that name.
        public static int IndexOf(string device)
        {
            IList<MonitorInfo> all = All;
            for (int i = 0; i < all.Count; i++)
                if (string.Equals(all[i].DeviceName, device, StringComparison.OrdinalIgnoreCase)) return i;
            return -1;
        }

        public static int PrimaryIndex
        {
            get
            {
                IList<MonitorInfo> all = All;
                for (int i = 0; i < all.Count; i++) if (all[i].Primary) return i;
                return 0;
            }
        }

        // Changes when a monitor is plugged in, removed, moved or resized.
        public static string Signature()
        {
            List<string> parts = new List<string>();
            foreach (MonitorInfo m in All) parts.Add(m.DeviceName + "@" + m.Bounds);
            return string.Join("|", parts);
        }

        static IList<MonitorInfo> Enumerate()
        {
            List<MonitorInfo> list = new List<MonitorInfo>();
            Native.MonitorEnumProc proc = delegate (IntPtr hm, IntPtr dc, ref Native.RECT r, IntPtr data)
            {
                Native.MONITORINFOEX mi = new Native.MONITORINFOEX();
                mi.cbSize = System.Runtime.InteropServices.Marshal.SizeOf(mi);
                if (Native.GetMonitorInfo(hm, ref mi))
                    list.Add(new MonitorInfo { DeviceName = mi.szDevice, Bounds = ToRectangle(mi.rcMonitor), WorkingArea = ToRectangle(mi.rcWork), Primary = (mi.dwFlags & Native.MONITORINFOF_PRIMARY) != 0 });
                return true;
            };
            Native.EnumDisplayMonitors(IntPtr.Zero, IntPtr.Zero, proc, IntPtr.Zero);
            if (list.Count == 0)
            {
                // mid-reconfiguration Windows can briefly report no monitor at all
                System.Windows.Forms.Screen s = System.Windows.Forms.Screen.PrimaryScreen;
                list.Add(new MonitorInfo { DeviceName = s.DeviceName, Bounds = s.Bounds, WorkingArea = s.WorkingArea, Primary = true });
            }
            return list;
        }

        static System.Drawing.Rectangle ToRectangle(Native.RECT r)
        {
            return System.Drawing.Rectangle.FromLTRB(r.Left, r.Top, r.Right, r.Bottom);
        }
    }
}
