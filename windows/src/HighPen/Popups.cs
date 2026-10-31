using System;
using System.Collections.Generic;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Threading;

namespace HighPen
{
    // Borderless topmost HighPen popup, placed on the selected monitor once its size is known.
    abstract class PopupWindow : Window, ITopmost
    {
        protected PopupWindow()
        {
            WindowStyle = WindowStyle.None;
            ResizeMode = ResizeMode.NoResize;
            SizeToContent = SizeToContent.WidthAndHeight;
            ShowInTaskbar = false;
            Topmost = true;
            Title = "HighPen";
            Background = Brushes.Transparent;
            AllowsTransparency = true;
        }

        public void BringTopmost()
        {
            WindowUtil.BringTopmost(this);
        }

        // The dark panel with an accent border that dialogs sit in.
        protected static Border Frame(UIElement child)
        {
            return new Border { Background = Theme.PanelBg, BorderBrush = Theme.Active, BorderThickness = new Thickness(1), Child = child };
        }

        protected void CenterOnLoad(System.Drawing.Rectangle workArea)
        {
            Loaded += delegate
            {
                System.Drawing.Size s = WindowUtil.PixelSize(this);
                WindowUtil.PlaceRect(this, workArea.Left + (workArea.Width - s.Width) / 2, workArea.Top + (workArea.Height - s.Height) / 2, 0, 0, false);
            };
        }
    }

    // Version, author and license. Esc, Enter or Close dismiss it.
    class AboutWindow : PopupWindow
    {
        public AboutWindow(System.Drawing.Rectangle workArea)
        {
            StackPanel p = new StackPanel { Margin = new Thickness(20, 16, 20, 16), Width = 300 };
            p.Children.Add(new TextBlock { Text = "HighPen v" + AppInfo.AppVersion, Foreground = Brushes.White, FontSize = 18, FontWeight = FontWeights.SemiBold });
            p.Children.Add(new TextBlock { Text = Lang.T("Tagline"), Foreground = Brushes.Gray, FontSize = 12, Margin = new Thickness(0, 2, 0, 12), TextWrapping = TextWrapping.Wrap });
            p.Children.Add(Row(Lang.T("Author"), AppInfo.AuthorName, null));
            p.Children.Add(Row(Lang.T("Email"), AppInfo.AuthorEmail, "mailto:" + AppInfo.AuthorEmail));
            p.Children.Add(Row(Lang.T("Website"), AppInfo.RepoUrl.Replace("https://", ""), AppInfo.RepoUrl));
            p.Children.Add(Row(Lang.T("License"), "MIT License", AppInfo.RepoUrl + "/blob/main/LICENSE"));
            p.Children.Add(new TextBlock { Text = "Copyright (c) 2026 " + AppInfo.AuthorName, Foreground = Brushes.Gray, FontSize = 11, Margin = new Thickness(0, 10, 0, 0) });

            Border close = Theme.TextButton(Lang.T("Close"), double.NaN, 28, new Thickness(0, 14, 0, 0));
            p.Children.Add(close);
            Content = Frame(p);

            close.MouseLeftButtonUp += delegate { Close(); };
            KeyDown += delegate (object o, KeyEventArgs e) { if (e.Key == Key.Escape || e.Key == Key.Enter) Close(); };
            CenterOnLoad(workArea);
        }

        static FrameworkElement Row(string label, string value, string url)
        {
            Grid g = new Grid { Margin = new Thickness(0, 3, 0, 3) };
            g.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(80) });
            g.ColumnDefinitions.Add(new ColumnDefinition());
            g.Children.Add(new TextBlock { Text = label, Foreground = Brushes.Gray, FontSize = 12 });
            TextBlock v = new TextBlock { Foreground = Brushes.White, FontSize = 12, TextWrapping = TextWrapping.Wrap };
            if (url == null) v.Text = value;
            else
            {
                System.Windows.Documents.Hyperlink link = new System.Windows.Documents.Hyperlink(new System.Windows.Documents.Run(value));
                link.Foreground = Theme.Link;
                link.Click += delegate { try { System.Diagnostics.Process.Start(url); } catch { } };
                v.Inlines.Add(link);
            }
            Grid.SetColumn(v, 1);
            g.Children.Add(v);
            return g;
        }
    }

    // Short message at the bottom centre of the selected monitor that closes itself after a while.
    // Clicking it closes it; when selectPath is set, Explorer opens with that file selected.
    class ToastWindow : PopupWindow
    {
        public ToastWindow(string text, string selectPath, double seconds, System.Drawing.Rectangle workArea)
        {
            ShowActivated = false;
            Border box = new Border { Background = Theme.PanelBg, BorderBrush = Theme.Active, BorderThickness = new Thickness(1), Padding = new Thickness(14, 10, 14, 10), Cursor = Cursors.Hand };
            box.Child = new TextBlock { Text = text, Foreground = Brushes.White, FontSize = 13, TextWrapping = TextWrapping.Wrap, MaxWidth = 560 };
            Content = box;

            SourceInitialized += delegate { WindowUtil.AddExStyle(this, Native.WS_EX_NOACTIVATE | Native.WS_EX_TOOLWINDOW); };
            box.MouseLeftButtonUp += delegate
            {
                if (selectPath != null) try { System.Diagnostics.Process.Start("explorer.exe", "/select,\"" + selectPath + "\""); } catch { }
                Close();
            };
            Loaded += delegate
            {
                System.Drawing.Size s = WindowUtil.PixelSize(this);
                WindowUtil.PlaceRect(this, workArea.Left + (workArea.Width - s.Width) / 2, workArea.Bottom - s.Height - 40, 0, 0, false);
            };
            DispatcherTimer t = new DispatcherTimer { Interval = TimeSpan.FromSeconds(seconds) };
            t.Tick += delegate { t.Stop(); Close(); };
            Closed += delegate { t.Stop(); };
            t.Start();
        }
    }

    // Offers a newer version found at start-up. Update asks the app to download and install it (Updating),
    // Later closes; while downloading the progress is shown and Later cancels.
    class UpdateWindow : PopupWindow
    {
        public Action Updating;
        readonly TextBlock status = new TextBlock { Foreground = Brushes.Gray, FontSize = 12, TextWrapping = TextWrapping.Wrap, Margin = new Thickness(0, 8, 0, 0), Visibility = Visibility.Collapsed };
        readonly Border update;
        bool busy;

        public UpdateWindow(UpdateInfo u, System.Drawing.Rectangle workArea)
        {
            ShowActivated = false; // do not take the keyboard from the presentation
            StackPanel p = new StackPanel { Margin = new Thickness(20, 16, 20, 16), Width = 320 };
            p.Children.Add(new TextBlock { Text = Lang.T("UpdateTitle"), Foreground = Brushes.White, FontSize = 18, FontWeight = FontWeights.SemiBold });
            p.Children.Add(new TextBlock { Text = string.Format(Lang.T("UpdateText"), u.Version, AppInfo.AppVersion), Foreground = Brushes.White, FontSize = 12, Margin = new Thickness(0, 8, 0, 0), TextWrapping = TextWrapping.Wrap });
            p.Children.Add(new TextBlock { Text = Lang.T("UpdateHint"), Foreground = Brushes.Gray, FontSize = 12, Margin = new Thickness(0, 4, 0, 0), TextWrapping = TextWrapping.Wrap });

            TextBlock notes = new TextBlock { FontSize = 12, Margin = new Thickness(0, 8, 0, 0) };
            System.Windows.Documents.Hyperlink link = new System.Windows.Documents.Hyperlink(new System.Windows.Documents.Run(Lang.T("UpdateNotes")));
            link.Foreground = Theme.Link;
            link.Click += delegate { try { System.Diagnostics.Process.Start(u.PageUrl); } catch { } };
            notes.Inlines.Add(link);
            p.Children.Add(notes);
            p.Children.Add(status);

            Grid btns = new Grid { Margin = new Thickness(0, 14, 0, 0) };
            btns.ColumnDefinitions.Add(new ColumnDefinition());
            btns.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(8) });
            btns.ColumnDefinitions.Add(new ColumnDefinition());
            update = Theme.TextButton(Lang.T("UpdateNow"), double.NaN, 28, new Thickness(0));
            update.Background = Theme.Active;
            Border later = Theme.TextButton(Lang.T("UpdateLater"), double.NaN, 28, new Thickness(0));
            Grid.SetColumn(later, 2);
            btns.Children.Add(update);
            btns.Children.Add(later);
            p.Children.Add(btns);
            Content = Frame(p);

            update.MouseLeftButtonUp += delegate { if (!busy && Updating != null) Updating(); };
            later.MouseLeftButtonUp += delegate { Close(); };
            CenterOnLoad(workArea);
        }

        public void ShowProgress(int percent)
        {
            busy = true;
            update.Opacity = 0.5;
            status.Foreground = Brushes.Gray;
            status.Text = string.Format(Lang.T("UpdateDownloading"), percent);
            status.Visibility = Visibility.Visible;
        }

        public void ShowError(string text)
        {
            busy = false;
            update.Opacity = 1;
            status.Foreground = Theme.Warning;
            status.Text = text;
            status.Visibility = Visibility.Visible;
        }
    }

    // Lists every command with its shortcut. Click one, then press the new combination.
    // The app releases its own shortcuts while this is open so pressing them reaches it.
    class HotkeyEditorWindow : PopupWindow
    {
        readonly HotkeyBindings bindings;
        readonly IHotkeyProbe probe;
        readonly TextBlock status = new TextBlock { FontSize = 12, TextWrapping = TextWrapping.Wrap, Margin = new Thickness(0, 8, 0, 0) };
        readonly Dictionary<AppCommand, TextBlock> keyTexts = new Dictionary<AppCommand, TextBlock>();
        readonly Dictionary<AppCommand, Border> keyBoxes = new Dictionary<AppCommand, Border>();
        AppCommand waiting; // the command whose new shortcut is being typed

        public HotkeyEditorWindow(HotkeyBindings bindings, IHotkeyProbe probe, System.Drawing.Rectangle workArea)
        {
            this.bindings = bindings;
            this.probe = probe;

            StackPanel p = new StackPanel { Margin = new Thickness(20, 16, 20, 16), Width = 360 };
            p.Children.Add(new TextBlock { Text = Lang.T("Hotkeys"), Foreground = Brushes.White, FontSize = 18, FontWeight = FontWeights.SemiBold });
            p.Children.Add(new TextBlock { Text = Lang.T("HotkeyHint"), Foreground = Brushes.Gray, FontSize = 12, Margin = new Thickness(0, 4, 0, 10), TextWrapping = TextWrapping.Wrap });

            StackPanel rows = new StackPanel();
            p.Children.Add(new ScrollViewer { Content = rows, MaxHeight = 440, VerticalScrollBarVisibility = ScrollBarVisibility.Auto });
            p.Children.Add(status);

            Grid btns = new Grid { Margin = new Thickness(0, 12, 0, 0) };
            btns.ColumnDefinitions.Add(new ColumnDefinition());
            btns.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(8) });
            btns.ColumnDefinitions.Add(new ColumnDefinition());
            Border reset = Theme.TextButton(Lang.T("ResetDefaults"), double.NaN, 28, new Thickness(0));
            Border close = Theme.TextButton(Lang.T("Close"), double.NaN, 28, new Thickness(0));
            Grid.SetColumn(close, 2);
            btns.Children.Add(reset);
            btns.Children.Add(close);
            p.Children.Add(btns);
            Content = Frame(p);

            foreach (AppCommand a in bindings.Commands)
            {
                AppCommand act = a;
                Grid g = new Grid { Margin = new Thickness(0, 2, 0, 2) };
                g.ColumnDefinitions.Add(new ColumnDefinition());
                g.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(150) });
                g.Children.Add(new TextBlock { Text = a.Name(), Foreground = Brushes.White, FontSize = 12, VerticalAlignment = VerticalAlignment.Center, TextWrapping = TextWrapping.Wrap });
                Border box = new Border { Height = 26, Cursor = Cursors.Hand };
                TextBlock kt = new TextBlock { FontSize = 12, HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Center };
                box.Child = kt;
                box.MouseLeftButtonUp += delegate { waiting = act; status.Foreground = Brushes.Gray; status.Text = Lang.T("HotkeyWaitHint"); Refresh(); };
                Grid.SetColumn(box, 1);
                g.Children.Add(box);
                keyTexts[a] = kt;
                keyBoxes[a] = box;
                rows.Children.Add(g);
            }
            Refresh();

            reset.MouseLeftButtonUp += delegate { bindings.ResetAll(); waiting = null; status.Text = ""; Refresh(); };
            close.MouseLeftButtonUp += delegate { Close(); };
            PreviewKeyDown += OnKey;
            CenterOnLoad(workArea);
            Loaded += delegate { Activate(); };
        }

        void Refresh()
        {
            foreach (AppCommand a in bindings.Commands)
            {
                string c = bindings.Combo(a.Id);
                keyTexts[a].Text = a == waiting ? Lang.T("PressKeys") : (c.Length == 0 ? Lang.T("NoKey") : c);
                keyTexts[a].Foreground = c.Length == 0 && a != waiting ? Brushes.Gray : Brushes.White;
                keyBoxes[a].Background = a == waiting ? Theme.Active : Theme.Idle;
            }
        }

        void Warn(string s)
        {
            status.Foreground = Theme.Warning;
            status.Text = s;
        }

        void Assign(string combo)
        {
            bindings.Assign(waiting, combo);
            waiting = null;
            Refresh();
        }

        static bool IsModifier(Key k)
        {
            return k == Key.LeftCtrl || k == Key.RightCtrl || k == Key.LeftAlt || k == Key.RightAlt || k == Key.LeftShift || k == Key.RightShift || k == Key.LWin || k == Key.RWin;
        }

        void OnKey(object sender, KeyEventArgs e)
        {
            e.Handled = true; // also keeps Alt+F4 and friends from acting on the editor while choosing
            Key k = e.Key == Key.System ? e.SystemKey : (e.Key == Key.ImeProcessed ? e.ImeProcessedKey : e.Key);
            ModifierKeys m = Keyboard.Modifiers;
            if (waiting == null)
            {
                if (m == ModifierKeys.None && (k == Key.Escape || k == Key.Enter)) Close();
                return;
            }
            if (IsModifier(k)) return; // wait for the rest of the combination
            if (m == ModifierKeys.None && k == Key.Escape) { waiting = null; status.Text = ""; Refresh(); return; }
            if (m == ModifierKeys.None && (k == Key.Delete || k == Key.Back)) { status.Text = ""; Assign(""); return; }
            uint mods = HotkeyText.FromModifiers(m);
            if ((mods & (HotkeyText.Ctrl | HotkeyText.Alt)) == 0 && !(k >= Key.F1 && k <= Key.F24)) { Warn(Lang.T("HotkeyNeedMod")); return; }
            string c = HotkeyText.Format(mods, k);
            AppCommand other = bindings.UsedBy(c, waiting);
            if (other != null) { Warn(string.Format(Lang.T("HotkeyDup"), other.Name())); return; }
            if (!probe.IsFree(mods, k)) { Warn(Lang.T("HotkeyTaken")); return; }
            status.Text = "";
            Assign(c);
        }
    }
}
