using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;

namespace HighPen
{
    static class AppInfo
    {
        public const string AppVersion = "1.8.7"; // keep in sync with Version in Setup.cs
        public const string AuthorName = "StephenWon";
        public const string AuthorEmail = "stepanowon@gmail.com";
        public const string RepoUrl = "https://github.com/stepanowon/high-pen";
    }

    // The colours offered for the pen, highlighter and spot. Names are Lang keys; Keys are the letters of the
    // default Ctrl+Shift colour shortcuts.
    static class Palette
    {
        public static readonly string[] Hex = { "#FF3B30", "#FF9500", "#FFD60A", "#34C759", "#0A84FF", "#BF5AF2", "#000000", "#FFFFFF" };
        public static readonly string[] Names = { "Red", "Orange", "Yellow", "Green", "Blue", "Purple", "Black", "White" };
        public static readonly Key[] Keys = { Key.R, Key.O, Key.Y, Key.G, Key.B, Key.P, Key.K, Key.W };
    }

    // Colours, fonts and small building blocks shared by the toolbar, the settings panel and the popups.
    static class Theme
    {
        // Shared by every window, so they are frozen: an unfrozen brush keeps track of each element that uses it,
        // and the toolbar, settings panel and popups are rebuilt over and over.
        public static readonly Brush PanelBg = Frozen(0x2B, 0x2E, 0x33);
        public static readonly Brush Active = Frozen(0x3E, 0x6F, 0xB0);
        public static readonly Brush Idle = Frozen(0x3A, 0x3D, 0x42);
        public static readonly Brush Line = Frozen(0x14, 0x15, 0x17);
        public static readonly Brush Warning = Frozen(0xFF, 0x9F, 0x0A);
        public static readonly Brush Link = Frozen(0x7F, 0xB2, 0xFF);
        public static readonly FontFamily Icons = new FontFamily("Segoe MDL2 Assets");
        public static readonly FontFamily Symbols = new FontFamily("Segoe UI Symbol");

        public static Brush Frozen(byte r, byte g, byte b)
        {
            return Frozen(Color.FromRgb(r, g, b));
        }

        public static Brush Frozen(Color c)
        {
            SolidColorBrush brush = new SolidColorBrush(c);
            brush.Freeze();
            return brush;
        }

        public static Color ParseColor(string s)
        {
            return (Color)ColorConverter.ConvertFromString(s);
        }

        public static void Highlight(Border b, bool on)
        {
            b.Background = on ? Active : Idle;
        }

        public static TextBlock SectionTitle(string t)
        {
            return new TextBlock { Text = t, Foreground = Brushes.White, FontSize = 12, Margin = new Thickness(0, 6, 0, 4) };
        }

        // A flat button with centred white text (NaN width = as wide as its container allows).
        public static Border TextButton(string text, double width, double height, Thickness margin)
        {
            Border b = new Border { Width = width, Height = height, Margin = margin, Cursor = Cursors.Hand, Background = Idle };
            b.Child = new TextBlock { Text = text, Foreground = Brushes.White, HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Center };
            return b;
        }
    }
}
