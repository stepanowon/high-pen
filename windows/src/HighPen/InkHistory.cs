using System;
using System.Collections.Generic;
using System.Windows.Controls;
using System.Windows.Ink;

namespace HighPen
{
    // Undo history of each ink page. One step is a pen stroke, every stroke removed by one eraser drag, or a clear all.
    class InkHistory
    {
        class InkEdit
        {
            public StrokeCollection Added = new StrokeCollection();
            public StrokeCollection Removed = new StrokeCollection();
            // puts back what the step removed besides strokes (the speech bubbles of a clear all)
            public Action Restore;
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
            if (last.Restore != null) last.Restore();
        }

        // Removes every stroke of the page as one step, so undo brings them back and then runs restore.
        public void Clear(int page, Action restore)
        {
            StrokeCollection s = pages[page];
            if (s.Count == 0 && restore == null) return;
            InkEdit edit = new InkEdit { Restore = restore };
            edit.Removed.Add(s);
            history[page].Add(edit);
            undoing = true;
            s.Clear();
            undoing = false;
        }
    }
}
