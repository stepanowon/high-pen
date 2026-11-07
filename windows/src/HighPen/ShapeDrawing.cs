using System;
using System.Windows;
using System.Windows.Ink;
using System.Windows.Input;

namespace HighPen
{
    // Draws rectangles and ellipses while the shape tool is on: press, drag to the opposite corner, release.
    // Holding Shift makes a square or a circle. A shape is an ordinary stroke in the pen's colour and width,
    // so the eraser, undo, capture, the boards and the zoom treat it like any other ink.
    class ShapeDrawer
    {
        // A click, or a drag shorter than this, leaves nothing behind.
        const double MinSize = 3;
        const int VK_SHIFT = 0x10;

        readonly OverlayWindow overlay;
        readonly ToolState tools;
        bool down;
        int shape;
        Point start;
        Stroke stroke;

        // Needs to be created after InkHistory, which must see the press first to make the shape one undo step.
        public ShapeDrawer(OverlayWindow overlay, ToolState tools)
        {
            this.overlay = overlay;
            this.tools = tools;
            overlay.Canvas.PreviewMouseLeftButtonDown += OnDown;
            overlay.Canvas.PreviewMouseMove += delegate (object s, MouseEventArgs e) { if (down) Drag(e.GetPosition(overlay.Canvas)); };
            overlay.Canvas.PreviewMouseLeftButtonUp += OnUp;
            overlay.Canvas.LostMouseCapture += delegate { End(); };
        }

        void OnDown(object sender, MouseButtonEventArgs e)
        {
            if (!tools.ShapeActive || down) return;
            // the eraser end of a pen does not draw
            if (e.StylusDevice != null && e.StylusDevice.Inverted) return;
            // the position on the canvas is in content coordinates, also while zoomed
            start = e.GetPosition(overlay.Canvas);
            shape = tools.Shape;
            stroke = null;
            down = overlay.Canvas.CaptureMouse();
            e.Handled = true;
        }

        void OnUp(object sender, MouseButtonEventArgs e)
        {
            if (!down) return;
            Drag(e.GetPosition(overlay.Canvas));
            End();
            e.Handled = true;
        }

        // The shape follows the pointer. It joins the page once it is big enough, and from then on only its
        // points change, so the whole drag is one stroke added: one undo step.
        void Drag(Point p)
        {
            double dx = p.X - start.X, dy = p.Y - start.Y;
            if ((Native.GetAsyncKeyState(VK_SHIFT) & 0x8000) != 0)
            {
                double side = Math.Max(Math.Abs(dx), Math.Abs(dy));
                dx = dx < 0 ? -side : side;
                dy = dy < 0 ? -side : side;
            }
            Point end = new Point(start.X + dx, start.Y + dy);
            if (stroke == null)
            {
                if (Math.Abs(dx) < MinSize && Math.Abs(dy) < MinSize) return;
                DrawingAttributes a = overlay.Canvas.DefaultDrawingAttributes.Clone();
                // corners stay sharp, and the width is the pen's whatever the pressure
                a.FitToCurve = false;
                a.IgnorePressure = true;
                a.IsHighlighter = false;
                stroke = new Stroke(Points(start, end), a);
                overlay.Canvas.Strokes.Add(stroke);
            }
            else stroke.StylusPoints = Points(start, end);
        }

        void End()
        {
            if (!down) return;
            down = false;
            stroke = null;
            if (overlay.Canvas.IsMouseCaptured) overlay.Canvas.ReleaseMouseCapture();
        }

        StylusPointCollection Points(Point a, Point b)
        {
            double left = Math.Min(a.X, b.X), top = Math.Min(a.Y, b.Y), right = Math.Max(a.X, b.X), bottom = Math.Max(a.Y, b.Y);
            StylusPointCollection pts = new StylusPointCollection();
            if (shape == ToolState.RectShape)
            {
                pts.Add(new StylusPoint(left, top));
                pts.Add(new StylusPoint(right, top));
                pts.Add(new StylusPoint(right, bottom));
                pts.Add(new StylusPoint(left, bottom));
                pts.Add(new StylusPoint(left, top));
                return pts;
            }
            double cx = (left + right) / 2, cy = (top + bottom) / 2, rx = (right - left) / 2, ry = (bottom - top) / 2;
            // about one point every 3 pixels of the outline keeps the curve smooth
            double around = 2 * Math.PI * Math.Sqrt((rx * rx + ry * ry) / 2);
            int n = Math.Max(24, Math.Min(720, (int)(around / 3)));
            for (int i = 0; i <= n; i++)
            {
                double t = 2 * Math.PI * i / n;
                pts.Add(new StylusPoint(cx + rx * Math.Cos(t), cy + ry * Math.Sin(t)));
            }
            return pts;
        }
    }
}
