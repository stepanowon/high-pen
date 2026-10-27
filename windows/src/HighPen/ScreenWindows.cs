using System;
using System.Collections.Generic;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Ink;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Animation;
using System.Windows.Shapes;
using System.Windows.Threading;

namespace HighPen
{
    // Transparent, borderless, topmost window covering the selected monitor.
    abstract class ScreenWindow : Window, ITopmost
    {
        protected ScreenWindow(int exStyle)
        {
            WindowStyle = WindowStyle.None;
            AllowsTransparency = true;
            Background = Brushes.Transparent;
            ShowInTaskbar = false;
            Topmost = true;
            ShowActivated = false;
            ResizeMode = ResizeMode.NoResize;
            Left = SystemParameters.VirtualScreenLeft;
            Top = SystemParameters.VirtualScreenTop;
            Width = SystemParameters.VirtualScreenWidth;
            Height = SystemParameters.VirtualScreenHeight;
            SourceInitialized += delegate { WindowUtil.AddExStyle(this, exStyle); };
        }

        public void MoveToScreen(int idx)
        {
            WindowUtil.PlaceRect(this, Monitors.Get(idx).Bounds);
        }

        public void BringTopmost()
        {
            WindowUtil.BringTopmost(this);
        }

        // A physical screen position in this window's coordinates.
        protected Point FromScreen(Native.POINT p)
        {
            DpiScale d = VisualTreeHelper.GetDpi(this);
            return new Point(p.X / d.DpiScaleX - Left, p.Y / d.DpiScaleY - Top);
        }
    }

    // Hosts the ink canvas (also used as the whiteboard). Each page has its own strokes and speech bubbles:
    // 0 = screen annotations, 1 = white board, 2 = black board.
    class OverlayWindow : ScreenWindow
    {
        public const int PageCount = 3;
        public readonly InkCanvas Canvas = new InkCanvas();
        public readonly StrokeCollection[] Pages = { new StrokeCollection(), new StrokeCollection(), new StrokeCollection() };
        readonly List<UIElement>[] bubbles = { new List<UIElement>(), new List<UIElement>(), new List<UIElement>() };
        int shownPage;

        public OverlayWindow() : base(Native.WS_EX_TOOLWINDOW)
        {
            Canvas.Background = Brushes.Transparent;
            Stylus.SetIsPressAndHoldEnabled(Canvas, false);
            Stylus.SetIsFlicksEnabled(Canvas, false);
            Stylus.SetIsTapFeedbackEnabled(Canvas, false);
            Canvas.Strokes = Pages[0];
            Content = Canvas;
        }

        public void ShowPage(int page)
        {
            Canvas.Strokes = Pages[page];
            if (shownPage == page) return;
            shownPage = page;
            Canvas.Children.Clear();
            foreach (UIElement el in bubbles[page]) Canvas.Children.Add(el);
        }

        public void AddBubble(int page, UIElement bubble)
        {
            bubbles[page].Add(bubble);
            Canvas.Children.Add(bubble);
        }

        // Removes the speech bubbles of the page being shown and returns them for RestoreBubbles.
        // Its strokes are cleared through InkHistory.
        public List<UIElement> ClearBubbles(int page)
        {
            List<UIElement> removed = new List<UIElement>(bubbles[page]);
            Canvas.Children.Clear();
            bubbles[page].Clear();
            return removed;
        }

        // Puts cleared speech bubbles back beneath any added since.
        public void RestoreBubbles(int page, List<UIElement> removed)
        {
            bubbles[page].InsertRange(0, removed);
            if (shownPage != page) return;
            for (int i = 0; i < removed.Count; i++) Canvas.Children.Insert(i, removed[i]);
        }

        // What the canvas does with input: nothing (speech bubble clicks are handled outside), erase, or ink.
        public void SetEditing(bool penMode, bool erase, bool text)
        {
            Canvas.EditingMode = text ? InkCanvasEditingMode.None : (erase ? InkCanvasEditingMode.EraseByStroke : InkCanvasEditingMode.Ink);
            // InkCanvas' built-in ink cursor is a barely visible dot, so use a real pointer
            Canvas.UseCustomCursor = true;
            Canvas.Cursor = text ? Cursors.IBeam : (erase ? Cursors.Cross : Cursors.Pen);
            Canvas.IsHitTestVisible = penMode;
        }

        public void UsePen(Color c, double size, bool pressure)
        {
            Canvas.DefaultDrawingAttributes = new DrawingAttributes { FitToCurve = true, Color = c, Width = size, Height = size, IgnorePressure = !pressure };
        }

        // Translucent marker, drawn beneath pen strokes (a rectangle tip spikes with FitToCurve).
        public void UseHighlighter(Color c, double size)
        {
            Canvas.DefaultDrawingAttributes = new DrawingAttributes { FitToCurve = true, Color = c, IsHighlighter = true, Width = size, Height = size, IgnorePressure = true };
        }

        // The board colour, or the screen. In pen mode a nearly invisible fill lets the canvas catch input everywhere.
        public void SetBackground(int board, bool penMode)
        {
            if (board == ToolState.WhiteBoard) Background = Brushes.White;
            else if (board == ToolState.BlackBoard) Background = Brushes.Black;
            else Background = penMode ? new SolidColorBrush(Color.FromArgb(1, 0, 0, 0)) : Brushes.Transparent;
        }

        // Ink lives in screen coordinates of the unzoomed desktop. While zoomed, scale the canvas
        // the same way the magnifier scales the desktop so strokes line up with what is shown,
        // and pen input maps back to the right content position.
        public void MatchZoom(System.Drawing.Rectangle bounds, Native.RECT source, double factor)
        {
            DpiScale d = VisualTreeHelper.GetDpi(this);
            double sx = (source.Left - bounds.X) / d.DpiScaleX;
            double sy = (source.Top - bounds.Y) / d.DpiScaleY;
            Canvas.RenderTransform = new MatrixTransform(factor, 0, 0, factor, -factor * sx, -factor * sy);
        }

        public void ResetZoom()
        {
            Canvas.RenderTransform = Transform.Identity;
        }
    }

    // Click-through window that draws the spot following the mouse pointer, and the click ripples.
    class SpotWindow : ScreenWindow
    {
        Ellipse spot = new Ellipse();
        Canvas root = new Canvas();
        DispatcherTimer timer = new DispatcherTimer();

        public SpotWindow() : base(Native.WS_EX_TRANSPARENT | Native.WS_EX_NOACTIVATE | Native.WS_EX_TOOLWINDOW)
        {
            IsHitTestVisible = false;
            spot.IsHitTestVisible = false;
            root.Children.Add(spot);
            Content = root;

            timer.Interval = TimeSpan.FromMilliseconds(12);
            timer.Tick += delegate { UpdatePosition(); };
            timer.Start();
        }

        public void SetStyle(Color c, double size)
        {
            spot.Width = size;
            spot.Height = size;
            spot.Fill = new SolidColorBrush(Color.FromArgb(0x66, c.R, c.G, c.B));
            spot.Stroke = null;
            spot.StrokeThickness = 0;
        }

        public void SetSpotVisible(bool on)
        {
            spot.Visibility = on ? Visibility.Visible : Visibility.Collapsed;
        }

        // Expanding ring at a click (physical screen pixels): solid for the left button, dashed for the right.
        public void ShowRipple(Native.POINT p, Color c, bool left)
        {
            // grows past the spot so it is not hidden behind it
            double size = (spot.Visibility == Visibility.Visible ? spot.Width : 0) + 60;
            Point at = FromScreen(p);
            Ellipse ring = new Ellipse { Width = size, Height = size, Stroke = new SolidColorBrush(c), StrokeThickness = 3, IsHitTestVisible = false, RenderTransformOrigin = new Point(0.5, 0.5) };
            if (!left) ring.StrokeDashArray = new DoubleCollection { 2, 1.5 };
            ScaleTransform st = new ScaleTransform(0.2, 0.2);
            ring.RenderTransform = st;
            Canvas.SetLeft(ring, at.X - size / 2);
            Canvas.SetTop(ring, at.Y - size / 2);
            root.Children.Add(ring);
            Duration dur = new Duration(TimeSpan.FromMilliseconds(450));
            DoubleAnimation grow = new DoubleAnimation(0.2, 1, dur);
            st.BeginAnimation(ScaleTransform.ScaleXProperty, grow);
            st.BeginAnimation(ScaleTransform.ScaleYProperty, grow);
            DoubleAnimation fade = new DoubleAnimation(1, 0, dur);
            fade.Completed += delegate { root.Children.Remove(ring); };
            ring.BeginAnimation(OpacityProperty, fade);
        }

        void UpdatePosition()
        {
            if (spot.Visibility != Visibility.Visible) return;
            Native.POINT p;
            if (!Native.GetCursorPos(out p)) return;
            Point at = FromScreen(p);
            Canvas.SetLeft(spot, at.X - spot.Width / 2);
            Canvas.SetTop(spot, at.Y - spot.Height / 2);
        }
    }
}
