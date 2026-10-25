using System;
using System.Windows.Input;

namespace HighPen
{
    // Shortcut text such as "Ctrl+Alt+P" <-> RegisterHotKey modifier flags + WPF key.
    static class HotkeyText
    {
        public const uint Alt = 1, Ctrl = 2, Shift = 4;

        public static string Format(uint mods, Key key)
        {
            string k = key >= Key.D0 && key <= Key.D9 ? ((int)(key - Key.D0)).ToString() : key.ToString();
            return ((mods & Ctrl) != 0 ? "Ctrl+" : "") + ((mods & Alt) != 0 ? "Alt+" : "") + ((mods & Shift) != 0 ? "Shift+" : "") + k;
        }

        public static uint FromModifiers(ModifierKeys m)
        {
            return ((m & ModifierKeys.Control) != 0 ? Ctrl : 0) | ((m & ModifierKeys.Alt) != 0 ? Alt : 0) | ((m & ModifierKeys.Shift) != 0 ? Shift : 0);
        }

        // "" (no shortcut) or anything unreadable gives false.
        public static bool TryParse(string s, out uint mods, out Key key)
        {
            mods = 0;
            key = Key.None;
            if (string.IsNullOrEmpty(s)) return false;
            string[] parts = s.Split('+');
            for (int i = 0; i < parts.Length - 1; i++)
            {
                if (parts[i] == "Ctrl") mods |= Ctrl;
                else if (parts[i] == "Alt") mods |= Alt;
                else if (parts[i] == "Shift") mods |= Shift;
                else return false;
            }
            string last = parts[parts.Length - 1];
            if (last.Length == 1 && last[0] >= '0' && last[0] <= '9') { key = Key.D0 + (last[0] - '0'); return true; }
            return Enum.TryParse(last, out key) && key != Key.None;
        }
    }
}
