using System;
using System.Collections.Generic;
using System.Windows;
using System.Windows.Threading;

namespace HighPen
{
    // Something that can be put back above other topmost windows.
    interface ITopmost
    {
        void BringTopmost();
    }

    // Slideshows and other topmost windows can cover HighPen. This raises its windows again, bottom to top
    // in the order they were added, every 1.5 seconds and whenever Reassert is called.
    class TopmostKeeper
    {
        readonly List<ITopmost> items = new List<ITopmost>();
        readonly DispatcherTimer timer = new DispatcherTimer { Interval = TimeSpan.FromSeconds(1.5) };
        // While set (the snipping overlay is up) nothing is raised, so HighPen does not fight it for the top.
        public bool Suspended;

        public TopmostKeeper()
        {
            timer.Tick += delegate { Reassert(); };
        }

        public void Start() { timer.Start(); }

        public void Add(ITopmost item) { items.Add(item); }

        // Kept on top until it closes.
        public void Track<T>(T w) where T : Window, ITopmost
        {
            items.Add(w);
            w.Closed += delegate { items.Remove(w); };
        }

        public void Reassert()
        {
            if (Suspended) return;
            foreach (ITopmost item in items) item.BringTopmost();
        }
    }
}
