using System;
using System.Threading;
using System.Windows;

namespace HighPen
{
    class App : Application
    {
        // Composition root: builds the concrete services and windows and hands them to the controller.
        [STAThread]
        static void Main()
        {
            // One instance per user session: a second launch asks the running one to show its toolbar and exits.
            bool first;
            Mutex single = new Mutex(true, @"Local\HighPen.SingleInstance", out first);
            EventWaitHandle summon = new EventWaitHandle(false, EventResetMode.AutoReset, @"Local\HighPen.Summon");
            if (!first) { summon.Set(); return; }

            App app = new App();
            app.ShutdownMode = ShutdownMode.OnExplicitShutdown;
            ISettingsStore store = new SettingsFile();
            Settings cfg = store.Load();
            Lang.Cur = Lang.FromCode(cfg.Language);
            OverlayWindow overlay = new OverlayWindow();
            SpotWindow spot = new SpotWindow();
            Controller controller = new Controller(cfg, store, overlay, spot, new Zoomer(), new ClickHook(), new PngScreenCapture());
            overlay.Show();
            spot.Show();
            controller.Toolbar.Show();
            ThreadPool.RegisterWaitForSingleObject(summon, delegate
            {
                controller.Toolbar.Dispatcher.BeginInvoke(new Action(controller.Summon));
            }, null, Timeout.Infinite, false);
            app.Run();
            GC.KeepAlive(single);
        }
    }
}
