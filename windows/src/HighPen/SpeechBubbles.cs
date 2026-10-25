using System;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Threading;

namespace HighPen
{
    // In text mode a click on the overlay opens a text box there. Enter (or clicking elsewhere) turns it into
    // a speech bubble on the current page, Esc drops it; either way text mode ends.
    class SpeechBubbles
    {
        readonly OverlayWindow overlay;
        readonly ToolState tools;
        readonly Settings cfg;
        // Called after a text box closes and text mode has ended.
        public Action Finished;

        public SpeechBubbles(OverlayWindow overlay, ToolState tools, Settings cfg)
        {
            this.overlay = overlay;
            this.tools = tools;
            this.cfg = cfg;
            overlay.Canvas.PreviewMouseLeftButtonDown += OnCanvasDown;
        }

        double FontSize { get { return Math.Max(16, cfg.PenSize * 4); } }

        void OnCanvasDown(object sender, MouseButtonEventArgs e)
        {
            if (!tools.TextMode) return;
            DependencyObject src = e.OriginalSource as DependencyObject;
            while (src != null && !(src is TextBox) && src != overlay.Canvas)
                src = (src is Visual || src is System.Windows.Media.Media3D.Visual3D) ? VisualTreeHelper.GetParent(src) : LogicalTreeHelper.GetParent(src);
            if (src is TextBox) return;
            e.Handled = true;
            Begin(e.GetPosition(overlay.Canvas));
        }

        void Begin(Point pos)
        {
            InkCanvas ic = overlay.Canvas;
            TextBox tb = new TextBox();
            tb.MinWidth = 120;
            tb.FontSize = FontSize;
            tb.AcceptsReturn = true;
            tb.Padding = new Thickness(6);
            tb.BorderBrush = new SolidColorBrush(Theme.ParseColor(cfg.PenColor));
            tb.BorderThickness = new Thickness(2);
            InkCanvas.SetLeft(tb, pos.X);
            InkCanvas.SetTop(tb, pos.Y);
            ic.Children.Add(tb);
            bool done = false;
            Action<bool> finish = delegate (bool commit)
            {
                if (done) return;
                done = true;
                ic.Children.Remove(tb);
                if (commit && tb.Text.Trim().Length > 0) Add(tb.Text.Trim(), pos);
                tools.EndText();
                if (Finished != null) Finished();
            };
            tb.PreviewKeyDown += delegate (object o, KeyEventArgs e)
            {
                if (e.Key == Key.Escape) finish(false);
                else if (e.Key == Key.Enter && (Keyboard.Modifiers & ModifierKeys.Shift) == 0) { finish(true); e.Handled = true; }
            };
            // Focus only after the overlay has actually been activated, and only treat focus loss
            // as "done" once the box has really had focus.
            overlay.Dispatcher.BeginInvoke(DispatcherPriority.Input, new Action(delegate
            {
                overlay.Activate();
                tb.Focus();
                Keyboard.Focus(tb);
                tb.LostKeyboardFocus += delegate { finish(true); };
            }));
        }

        void Add(string text, Point pos)
        {
            Color c = Theme.ParseColor(cfg.PenColor);
            Border b = new Border();
            b.Background = new SolidColorBrush(Color.FromArgb(0xEE, 255, 255, 255));
            b.BorderBrush = new SolidColorBrush(c);
            b.BorderThickness = new Thickness(2);
            b.CornerRadius = new CornerRadius(12);
            b.Padding = new Thickness(10, 6, 10, 6);
            b.Child = new TextBlock { Text = text, Foreground = Brushes.Black, FontSize = FontSize, TextWrapping = TextWrapping.Wrap, MaxWidth = 600 };
            InkCanvas.SetLeft(b, pos.X);
            InkCanvas.SetTop(b, pos.Y);
            overlay.AddBubble(tools.Board, b);
        }
    }
}
