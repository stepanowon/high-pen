using System;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Threading;

namespace HighPen
{
    // The break lengths offered, in minutes.
    static class BreakTimes
    {
        public const int Min = 1, Max = 120;
        public static readonly int[] Presets = { 5, 10, 15, 20 };
    }

    // Break-time countdown over the whole selected monitor, so it is easy to read on a shared screen.
    // Click-through: the presenter can keep working, and the toolbar stays above it to stop the break.
    class BreakWindow : ScreenWindow
    {
        static readonly Brush TimeBrush = Brushes.White;
        static readonly Brush OverBrush = new SolidColorBrush(Color.FromRgb(0xFF, 0x45, 0x3A));
        // the last minute is shown in this colour
        static readonly TimeSpan Warn = TimeSpan.FromMinutes(1);

        readonly Grid root = new Grid();
        readonly TextBlock title = new TextBlock { Foreground = Brushes.White, FontSize = 40, HorizontalAlignment = HorizontalAlignment.Center };
        readonly TextBlock time = new TextBlock { FontSize = 200, FontWeight = FontWeights.SemiBold, HorizontalAlignment = HorizontalAlignment.Center };
        readonly TextBlock resume = new TextBlock { Foreground = Brushes.Gray, FontSize = 30, HorizontalAlignment = HorizontalAlignment.Center };
        readonly DispatcherTimer timer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(200) };
        DateTime end;

        public bool Running { get; private set; }

        public BreakWindow() : base(Native.WS_EX_TRANSPARENT | Native.WS_EX_NOACTIVATE | Native.WS_EX_TOOLWINDOW)
        {
            IsHitTestVisible = false;
            root.Background = new SolidColorBrush(Color.FromArgb(0xE6, 0x12, 0x14, 0x18));
            // the text is scaled to the monitor: the middle half of its height
            root.RowDefinitions.Add(new RowDefinition());
            root.RowDefinitions.Add(new RowDefinition { Height = new GridLength(2, GridUnitType.Star) });
            root.RowDefinitions.Add(new RowDefinition());
            StackPanel p = new StackPanel();
            p.Children.Add(title);
            p.Children.Add(time);
            p.Children.Add(resume);
            Viewbox v = new Viewbox { Child = p };
            Grid.SetRow(v, 1);
            root.Children.Add(v);
            root.Visibility = Visibility.Collapsed;
            Content = root;
            timer.Tick += delegate { Refresh(); };
        }

        public void Start(int minutes)
        {
            end = DateTime.Now.AddMinutes(minutes);
            Running = true;
            Refresh();
            root.Visibility = Visibility.Visible;
            timer.Start();
        }

        public void Stop()
        {
            timer.Stop();
            Running = false;
            root.Visibility = Visibility.Collapsed;
        }

        // Stays up at 00:00 once the break is over, until it is stopped.
        void Refresh()
        {
            TimeSpan left = end - DateTime.Now;
            bool over = left <= TimeSpan.Zero;
            // round up, so the display reaches 00:00 exactly when the break ends
            int secs = over ? 0 : (int)Math.Ceiling(left.TotalSeconds);
            title.Text = Lang.T(over ? "BreakOver" : "BreakTitle");
            time.Text = secs >= 3600
                ? string.Format("{0}:{1:00}:{2:00}", secs / 3600, secs / 60 % 60, secs % 60)
                : string.Format("{0:00}:{1:00}", secs / 60, secs % 60);
            time.Foreground = over ? OverBrush : (left <= Warn ? Theme.Warning : TimeBrush);
            resume.Text = string.Format(Lang.T("BreakEnds"), end.ToString("HH:mm"));
            resume.Visibility = over ? Visibility.Hidden : Visibility.Visible;
        }
    }
}
