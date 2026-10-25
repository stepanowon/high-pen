using System;
using System.Collections.Generic;
using System.Windows;
using System.Windows.Input;
using System.Windows.Interop;

namespace HighPen
{
    // Something the user can trigger with a global shortcut.
    class AppCommand
    {
        public string Id;
        public string Default; // the shortcut out of the box, e.g. "Ctrl+Alt+P" ("" = none)
        public Func<string> Name; // in the current language, for the shortcut editor
        public Action Run;
    }

    // The shortcut of each command: the user's choice from Settings.Hotkeys, otherwise the default.
    class HotkeyBindings
    {
        readonly Settings cfg;
        readonly ISettingsStore store;
        // In the order the shortcut editor lists them.
        public readonly List<AppCommand> Commands = new List<AppCommand>();

        public HotkeyBindings(Settings cfg, ISettingsStore store)
        {
            this.cfg = cfg;
            this.store = store;
        }

        public void Add(string id, string defaultCombo, Func<string> name, Action run)
        {
            Commands.Add(new AppCommand { Id = id, Default = defaultCombo, Name = name, Run = run });
        }

        // The command's current shortcut, or "" when it has none.
        public string Combo(string id)
        {
            string c;
            if (cfg.Hotkeys.TryGetValue(id, out c)) return c;
            AppCommand a = Commands.Find(x => x.Id == id);
            return a == null ? "" : a.Default;
        }

        // "  (Ctrl+Alt+P)" for the command's current shortcut, or "" when it has none.
        public string KeySuffix(string id)
        {
            string c = Combo(id);
            return c.Length == 0 ? "" : "  (" + c + ")";
        }

        // Another command that already uses the combination, or null.
        public AppCommand UsedBy(string combo, AppCommand except)
        {
            return Commands.Find(x => x != except && Combo(x.Id) == combo);
        }

        public void Assign(AppCommand a, string combo)
        {
            if (combo == a.Default) cfg.Hotkeys.Remove(a.Id);
            else cfg.Hotkeys[a.Id] = combo;
            store.Save(cfg);
        }

        public void ResetAll()
        {
            cfg.Hotkeys.Clear();
            store.Save(cfg);
        }
    }

    // Tells whether a combination can be registered right now.
    interface IHotkeyProbe
    {
        bool IsFree(uint mods, Key key);
    }

    // Registers the bound shortcuts with Windows for one window and runs a command when its shortcut is
    // pressed anywhere.
    class GlobalHotkeys : IHotkeyProbe
    {
        const int TestId = 0xBFFF; // used briefly to check whether another app owns a combination
        readonly HotkeyBindings bindings;
        readonly Window owner;
        readonly Dictionary<int, Action> registered = new Dictionary<int, Action>();
        // Shortcuts that could not be registered, e.g. "Ctrl+Alt+S" (another app already owns them).
        public readonly List<string> Failed = new List<string>();

        public GlobalHotkeys(HotkeyBindings bindings, Window owner)
        {
            this.bindings = bindings;
            this.owner = owner;
        }

        // Call once the owner has a window handle.
        public void Attach()
        {
            HwndSource.FromHwnd(WindowUtil.Handle(owner)).AddHook(WndProc);
        }

        public void RegisterAll()
        {
            UnregisterAll();
            Failed.Clear();
            IntPtr h = WindowUtil.Handle(owner);
            int id = 1;
            foreach (AppCommand a in bindings.Commands)
            {
                uint mods;
                Key key;
                string c = bindings.Combo(a.Id);
                if (!HotkeyText.TryParse(c, out mods, out key)) continue;
                if (Native.RegisterHotKey(h, id, mods | Native.MOD_NOREPEAT, (uint)KeyInterop.VirtualKeyFromKey(key))) registered[id] = a.Run;
                else Failed.Add(c);
                id++;
            }
        }

        public void UnregisterAll()
        {
            IntPtr h = WindowUtil.Handle(owner);
            foreach (int id in registered.Keys) Native.UnregisterHotKey(h, id);
            registered.Clear();
        }

        public bool IsFree(uint mods, Key key)
        {
            IntPtr h = WindowUtil.Handle(owner);
            if (!Native.RegisterHotKey(h, TestId, mods | Native.MOD_NOREPEAT, (uint)KeyInterop.VirtualKeyFromKey(key))) return false;
            Native.UnregisterHotKey(h, TestId);
            return true;
        }

        public string WarningText()
        {
            return Lang.T("HotkeyFail") + "\n" + string.Join(", ", Failed);
        }

        IntPtr WndProc(IntPtr hwnd, int msg, IntPtr wParam, IntPtr lParam, ref bool handled)
        {
            Action a;
            if (msg == Native.WM_HOTKEY && registered.TryGetValue(wParam.ToInt32(), out a)) { a(); handled = true; }
            return IntPtr.Zero;
        }
    }
}
