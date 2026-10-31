using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;

namespace HighPen
{
    // The user's preferences. Where and how they are kept is up to an ISettingsStore.
    class Settings
    {
        public string PenColor = "#FF3B30";
        public double PenSize = 4;
        public string HighlightColor = "#FFD60A";
        public double HighlightSize = 20;
        public string SpotColor = "#FFD60A";
        public double SpotSize = 70;
        public bool SpotOn = true;
        public int Monitor = 0; // index of the monitor in use
        public string MonitorDevice = ""; // the monitor the user chose ("" = from before this was saved: use Monitor)
        public bool Pressure = true;
        public bool ShowClicks = false;
        public double ZoomFactor = 2;
        public int BreakMinutes = 10; // length of the break timer
        public int BarX = 20, BarY = 20; // offset from the monitor work area, in pixels
        public string Language = ""; // "" = English (the default)
        public bool CheckUpdates = true; // look for a newer version at start-up (not in the Store version)
        // Shortcuts changed from their defaults, by command id ("" = no shortcut).
        public Dictionary<string, string> Hotkeys = new Dictionary<string, string>();

        // Brings values from an older or hand-edited file back into range.
        public void Normalize()
        {
            if (Array.IndexOf(Zoomer.Factors, ZoomFactor) < 0) ZoomFactor = 2;
            HighlightSize = Math.Max(5, Math.Min(60, HighlightSize));
            BreakMinutes = BreakTimes.Clamp(BreakMinutes);
        }
    }

    interface ISettingsStore
    {
        Settings Load();
        void Save(Settings s);
    }

    // %APPDATA%\HighPen\settings.txt, one "Key=value" per line. Unreadable files fall back to the defaults.
    class SettingsFile : ISettingsStore
    {
        static readonly CultureInfo Inv = CultureInfo.InvariantCulture;
        const string HotkeyPrefix = "Hotkey.";

        class Field
        {
            public string Key;
            public Action<Settings, string> Read;
            public Func<Settings, string> Write;
        }

        // Every saved value, in file order. A new setting only needs a line here.
        static readonly Field[] Fields =
        {
            Text("PenColor", (s, v) => s.PenColor = v, s => s.PenColor),
            Number("PenSize", (s, v) => s.PenSize = v, s => s.PenSize),
            Text("HighlightColor", (s, v) => s.HighlightColor = v, s => s.HighlightColor),
            Number("HighlightSize", (s, v) => s.HighlightSize = v, s => s.HighlightSize),
            Text("SpotColor", (s, v) => s.SpotColor = v, s => s.SpotColor),
            Number("SpotSize", (s, v) => s.SpotSize = v, s => s.SpotSize),
            Flag("SpotOn", (s, v) => s.SpotOn = v, s => s.SpotOn),
            Integer("Monitor", (s, v) => s.Monitor = v, s => s.Monitor),
            Text("MonitorDevice", (s, v) => s.MonitorDevice = v, s => s.MonitorDevice),
            Flag("Pressure", (s, v) => s.Pressure = v, s => s.Pressure),
            Flag("ShowClicks", (s, v) => s.ShowClicks = v, s => s.ShowClicks),
            Number("ZoomFactor", (s, v) => s.ZoomFactor = v, s => s.ZoomFactor),
            Integer("BreakMinutes", (s, v) => s.BreakMinutes = v, s => s.BreakMinutes),
            Integer("BarX", (s, v) => s.BarX = v, s => s.BarX),
            Integer("BarY", (s, v) => s.BarY = v, s => s.BarY),
            Text("Language", (s, v) => s.Language = v, s => s.Language),
            Flag("CheckUpdates", (s, v) => s.CheckUpdates = v, s => s.CheckUpdates),
        };

        static Field Text(string key, Action<Settings, string> read, Func<Settings, string> write)
        {
            return new Field { Key = key, Read = read, Write = write };
        }

        static Field Number(string key, Action<Settings, double> read, Func<Settings, double> write)
        {
            return Text(key, (s, v) => read(s, double.Parse(v, Inv)), s => write(s).ToString(Inv));
        }

        static Field Integer(string key, Action<Settings, int> read, Func<Settings, int> write)
        {
            return Text(key, (s, v) => read(s, int.Parse(v)), s => write(s).ToString());
        }

        static Field Flag(string key, Action<Settings, bool> read, Func<Settings, bool> write)
        {
            return Text(key, (s, v) => read(s, v == "1"), s => write(s) ? "1" : "0");
        }

        static string FilePath
        {
            get
            {
                string dir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "HighPen");
                Directory.CreateDirectory(dir);
                return Path.Combine(dir, "settings.txt");
            }
        }

        public Settings Load()
        {
            Settings s = new Settings();
            try
            {
                foreach (string line in File.ReadAllLines(FilePath))
                {
                    int i = line.IndexOf('=');
                    if (i < 0) continue;
                    string k = line.Substring(0, i), v = line.Substring(i + 1);
                    if (k.StartsWith(HotkeyPrefix)) { s.Hotkeys[k.Substring(HotkeyPrefix.Length)] = v; continue; }
                    Field f = Array.Find(Fields, x => x.Key == k);
                    if (f != null) f.Read(s, v);
                }
            }
            catch { }
            s.Normalize();
            return s;
        }

        public void Save(Settings s)
        {
            try
            {
                List<string> lines = new List<string>();
                foreach (Field f in Fields) lines.Add(f.Key + "=" + f.Write(s));
                foreach (KeyValuePair<string, string> h in s.Hotkeys) lines.Add(HotkeyPrefix + h.Key + "=" + h.Value);
                File.WriteAllLines(FilePath, lines);
            }
            catch { }
        }
    }
}
