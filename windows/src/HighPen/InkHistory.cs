using System.Collections.Generic;
using System.Windows.Controls;
using System.Windows.Ink;

namespace HighPen
{
    // Undo history of each ink page. One step is a pen stroke, or every stroke removed by one eraser drag.
    class InkHistory
    {
        class InkEdit
        {
            public StrokeCollection Added = new StrokeCollection();
            public StrokeCollection Removed = new StrokeCollection();
        }

        readonly StrokeCollection[] pages;
        readonly List<InkEdit>[] history;
        bool undoing, pressed, newEdit;

        public InkHistory(InkCanvas canvas, StrokeCollection[] pages)
        {
            this.pages = pages;
            history = new List<InkEdit>[pages.Length];
            for (int i = 0; i < pages.Length; i++)
            {
                int page = i;
                history[i] = new List<InkEdit>();
                pages[i].StrokesChanged += delegate (object sender, StrokeCollectionChangedEventArgs e) { Record(page, e); };
            }
            canvas.PreviewStylusDown += delegate { BeginPress(); };
            canvas.PreviewMouseLeftButtonDown += delegate { BeginPress(); };
            canvas.PreviewStylusUp += delegate { pressed = false; };
            canvas.PreviewMouseLeftButtonUp += delegate { pressed = false; };
        }

        // Stylus input is promoted to mouse events too, so only the first down of a press starts a new step.
        void BeginPress()
        {
            if (pressed) return;
            pressed = true;
            newEdit = true;
        }

        void Record(int page, StrokeCollectionChangedEventArgs e)
        {
            if (undoing) return;
            List<InkEdit> h = history[page];
            if (newEdit || !pressed || h.Count == 0) { h.Add(new InkEdit()); newEdit = false; }
            InkEdit top = h[h.Count - 1];
            foreach (Stroke st in e.Added) top.Added.Add(st);
            foreach (Stroke st in e.Removed)
            {
                if (top.Added.Contains(st)) top.Added.Remove(st);
                else top.Removed.Add(st);
            }
        }

        public void Undo(int page)
        {
            List<InkEdit> h = history[page];
            if (h.Count == 0) return;
            InkEdit last = h[h.Count - 1];
            h.RemoveAt(h.Count - 1);
            StrokeCollection s = pages[page];
            undoing = true;
            foreach (Stroke st in last.Added) if (s.Contains(st)) s.Remove(st);
            foreach (Stroke st in last.Removed) if (!s.Contains(st)) s.Add(st);
            undoing = false;
        }

        // Removes every stroke of the page, together with its history.
        public void Clear(int page)
        {
            history[page].Clear();
            undoing = true;
            pages[page].Clear();
            undoing = false;
        }
    }
}
