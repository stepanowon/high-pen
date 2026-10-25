using System;

namespace HighPen
{
    // Global low-level mouse hook that reports left/right button presses anywhere on the desktop
    // (the overlay is click-through, so it never sees those clicks itself).
    class ClickHook
    {
        Native.HookProc proc; // kept referenced so the GC does not collect the callback
        IntPtr hook;
        // true = left button, false = right button
        public Action<bool> Clicked;

        public void Start()
        {
            if (hook != IntPtr.Zero) return;
            proc = Callback;
            hook = Native.SetWindowsHookEx(Native.WH_MOUSE_LL, proc, Native.GetModuleHandle(null), 0);
        }

        public void Stop()
        {
            if (hook == IntPtr.Zero) return;
            Native.UnhookWindowsHookEx(hook);
            hook = IntPtr.Zero;
        }

        IntPtr Callback(int code, IntPtr wParam, IntPtr lParam)
        {
            if (code >= 0 && Clicked != null)
            {
                int msg = wParam.ToInt32();
                if (msg == Native.WM_LBUTTONDOWN) Clicked(true);
                else if (msg == Native.WM_RBUTTONDOWN) Clicked(false);
            }
            return Native.CallNextHookEx(hook, code, wParam, lParam);
        }
    }
}
