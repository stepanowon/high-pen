using System;
using System.Collections.Generic;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;

namespace HighPen
{
    // What the settings panel asks of the app. Colours and sizes are written to Settings before the *Changed calls.
    interface ISettingsActions
    {
        void PenStyleChanged();
        void SpotStyleChanged();
        void SetMonitor(int i);
        void TogglePressure();
        void ToggleClicks();
        void SetZoomFactor(double f);
        void SetBreakMinutes(int minutes);
        void SetLanguage(int i);
        void ShowHotkeyEditor();
        void ToggleUpdateCheck();
    }

    // The panel next to the toolbar: monitor, pen, highlighter, spot, zoom, break length, language and shortcuts.
    class SettingsPanel : Border
    {
        readonly Settings cfg;
        readonly HotkeyBindings bindings;
        readonly ISettingsActions actions;
        readonly List<Border> monitorBtns = new List<Border>();
        readonly List<Border> zoomFactorBtns = new List<Border>();
        readonly List<Border> breakBtns = new List<Border>();
        TextBlock breakTitle;
        Slider breakSlider;
        Panel penSwatches, highlightSwatches;
        Border pressureBtn, clicksBtn, updateBtn;
        TextBlock pressureText, clicksText, updateText, hotkeyWarn;

        public SettingsPanel(Settings cfg, HotkeyBindings bindings, ISettingsActions actions)
        {
            this.cfg = cfg;
            this.bindings = bindings;
            this.actions = actions;
            Background = Theme.PanelBg;
            BorderBrush = Theme.Line;
            BorderThickness = new Thickness(0, 1, 1, 1);
            VerticalAlignment = VerticalAlignment.Top;
            Child = Build();
        }

        public void MarkMonitor(int monitor)
        {
            for (int i = 0; i < monitorBtns.Count; i++) Theme.Highlight(monitorBtns[i], i == monitor);
        }

        public void MarkZoomFactor(double f)
        {
            for (int i = 0; i < zoomFactorBtns.Count; i++) Theme.Highlight(zoomFactorBtns[i], Zoomer.Factors[i] == f);
        }

        // Updates the title, the preset buttons and the slider.
        public void MarkBreakMinutes(int minutes)
        {
            breakTitle.Text = string.Format(Lang.T("BreakLength"), BreakTimes.Label(minutes));
            for (int i = 0; i < breakBtns.Count; i++) Theme.Highlight(breakBtns[i], BreakTimes.Presets[i] == minutes);
            if ((int)Math.Round(breakSlider.Value) != minutes) breakSlider.Value = minutes;
        }

        public void MarkPenColor(string color) { MarkSwatch(penSwatches, color); }
        public void MarkHighlightColor(string color) { MarkSwatch(highlightSwatches, color); }

        public void ShowPressure(bool on) { ShowSwitch(pressureBtn, pressureText, "Pressure", on); }
        public void ShowClicks(bool on) { ShowSwitch(clicksBtn, clicksText, "ClickShow", on); }
        // Not shown in the Store version, which the Store updates.
        public void ShowUpdateCheck(bool on) { if (updateBtn != null) ShowSwitch(updateBtn, updateText, "UpdateCheck", on); }

        // null hides the warning.
        public void ShowHotkeyWarning(string text)
        {
            hotkeyWarn.Text = text ?? "";
            hotkeyWarn.Visibility = text != null ? Visibility.Visible : Visibility.Collapsed;
        }

        UIElement Build()
        {
            StackPanel p = new StackPanel { Margin = new Thickness(10), Width = 190 };

            p.Children.Add(Theme.SectionTitle(Lang.T("Monitor")));
            WrapPanel mp = new WrapPanel();
            string cycle = bindings.Combo("Monitor");
            for (int i = 0; i < Monitors.Count; i++)
            {
                int idx = i;
                Border mb = Theme.TextButton((i + 1).ToString(), 34, 26, new Thickness(2));
                mb.ToolTip = string.Format(Lang.T("MonitorTip"), i + 1) + (cycle.Length == 0 ? "" : "  (" + Lang.T("Cycle") + ": " + cycle + ")");
                mb.MouseLeftButtonUp += delegate { actions.SetMonitor(idx); };
                monitorBtns.Add(mb);
                mp.Children.Add(mb);
            }
            p.Children.Add(mp);
            p.Children.Add(Divider());

            p.Children.Add(Theme.SectionTitle(Lang.T("PenColor")));
            penSwatches = Swatches(cfg.PenColor, delegate (string c) { cfg.PenColor = c; actions.PenStyleChanged(); }, true);
            p.Children.Add(penSwatches);
            p.Children.Add(Theme.SectionTitle(Lang.T("PenSize")));
            p.Children.Add(MakeSlider(1, 30, cfg.PenSize, delegate (double v) { cfg.PenSize = v; actions.PenStyleChanged(); }));
            p.Children.Add(Switch("Pressure", "Pressure", actions.TogglePressure, out pressureBtn, out pressureText));
            ShowPressure(cfg.Pressure);
            p.Children.Add(Divider());

            p.Children.Add(Theme.SectionTitle(Lang.T("HighlightColor")));
            highlightSwatches = Swatches(cfg.HighlightColor, delegate (string c) { cfg.HighlightColor = c; actions.PenStyleChanged(); }, true);
            p.Children.Add(highlightSwatches);
            p.Children.Add(Theme.SectionTitle(Lang.T("HighlightSize")));
            p.Children.Add(MakeSlider(5, 60, cfg.HighlightSize, delegate (double v) { cfg.HighlightSize = v; actions.PenStyleChanged(); }));
            p.Children.Add(Divider());

            p.Children.Add(Theme.SectionTitle(Lang.T("SpotColor")));
            p.Children.Add(Swatches(cfg.SpotColor, delegate (string c) { cfg.SpotColor = c; actions.SpotStyleChanged(); }, false));
            p.Children.Add(Theme.SectionTitle(Lang.T("SpotSize")));
            p.Children.Add(MakeSlider(20, 200, cfg.SpotSize, delegate (double v) { cfg.SpotSize = v; actions.SpotStyleChanged(); }));
            p.Children.Add(Switch("ClickShow", "Clicks", actions.ToggleClicks, out clicksBtn, out clicksText));
            ShowClicks(cfg.ShowClicks);
            p.Children.Add(Divider());

            p.Children.Add(Theme.SectionTitle(Lang.T("ZoomFactor")));
            WrapPanel zp = new WrapPanel();
            foreach (double f in Zoomer.Factors)
            {
                double fv = f;
                Border zb = Theme.TextButton(f.ToString(System.Globalization.CultureInfo.InvariantCulture) + "x", 58, 26, new Thickness(2));
                zb.MouseLeftButtonUp += delegate { actions.SetZoomFactor(fv); };
                zoomFactorBtns.Add(zb);
                zp.Children.Add(zb);
            }
            MarkZoomFactor(cfg.ZoomFactor);
            p.Children.Add(zp);
            p.Children.Add(Divider());

            breakTitle = Theme.SectionTitle("");
            p.Children.Add(breakTitle);
            WrapPanel bp = new WrapPanel();
            foreach (int m in BreakTimes.Presets)
            {
                int mv = m;
                Border bb = Theme.TextButton(BreakTimes.Label(m), 87, 26, new Thickness(2));
                ((TextBlock)bb.Child).FontSize = 11;
                bb.MouseLeftButtonUp += delegate { actions.SetBreakMinutes(mv); };
                breakBtns.Add(bb);
                bp.Children.Add(bb);
            }
            p.Children.Add(bp);
            breakSlider = MakeSlider(BreakTimes.Min, BreakTimes.Max, cfg.BreakMinutes, delegate (double v)
            {
                int m = BreakTimes.Clamp((int)Math.Round(v));
                if (m != cfg.BreakMinutes) actions.SetBreakMinutes(m);
            });
            breakSlider.Margin = new Thickness(0, 4, 0, 0);
            breakSlider.IsSnapToTickEnabled = true;
            breakSlider.TickFrequency = BreakTimes.Step;
            p.Children.Add(breakSlider);
            MarkBreakMinutes(cfg.BreakMinutes);
            p.Children.Add(Divider());

            p.Children.Add(Theme.SectionTitle(Lang.T("Language")));
            WrapPanel lp = new WrapPanel();
            for (int i = 0; i < Lang.Codes.Length; i++)
            {
                int idx = i;
                Border lb = Theme.TextButton(Lang.Names[i], 58, 26, new Thickness(2));
                ((TextBlock)lb.Child).FontSize = 11;
                Theme.Highlight(lb, i == Lang.Cur);
                lb.MouseLeftButtonUp += delegate { if (idx != Lang.Cur) actions.SetLanguage(idx); };
                lp.Children.Add(lb);
            }
            p.Children.Add(lp);
            p.Children.Add(Divider());

            Border hk = Theme.TextButton(Lang.T("Hotkeys"), double.NaN, 26, new Thickness(0, 2, 0, 0));
            hk.MouseLeftButtonUp += delegate { actions.ShowHotkeyEditor(); };
            p.Children.Add(hk);
            hotkeyWarn = new TextBlock { Foreground = Theme.Warning, FontSize = 11, TextWrapping = TextWrapping.Wrap, Margin = new Thickness(0, 8, 0, 0), Visibility = Visibility.Collapsed };
            p.Children.Add(hotkeyWarn);

            if (Updater.Supported)
            {
                p.Children.Add(Switch("UpdateCheck", "", actions.ToggleUpdateCheck, out updateBtn, out updateText));
                updateBtn.ToolTip = Lang.T("UpdateCheckTip");
                ShowUpdateCheck(cfg.CheckUpdates);
            }

            p.Children.Add(Divider());
            p.Children.Add(new TextBlock { Text = "HighPen v" + AppInfo.AppVersion, Foreground = Brushes.Gray, FontSize = 11, HorizontalAlignment = HorizontalAlignment.Center });
            return p;
        }

        static Separator Divider()
        {
            return new Separator { Margin = new Thickness(0, 8, 0, 4) };
        }

        // An on/off button whose label reads "<name>: on".
        Border Switch(string nameKey, string commandId, Action toggle, out Border button, out TextBlock text)
        {
            button = Theme.TextButton("", double.NaN, 26, new Thickness(0, 6, 0, 0));
            button.ToolTip = Lang.T(nameKey) + bindings.KeySuffix(commandId);
            button.MouseLeftButtonUp += delegate { toggle(); };
            text = (TextBlock)button.Child;
            return button;
        }

        static void ShowSwitch(Border button, TextBlock text, string nameKey, bool on)
        {
            text.Text = Lang.T(nameKey) + ": " + Lang.T(on ? "On" : "Off");
            Theme.Highlight(button, on);
        }

        // One round swatch per palette colour; the pen and highlighter ones show the colour shortcuts.
        Panel Swatches(string current, Action<string> onPick, bool withShortcuts)
        {
            WrapPanel wp = new WrapPanel();
            for (int i = 0; i < Palette.Hex.Length; i++)
            {
                string h = Palette.Hex[i];
                Border b = new Border { Width = 24, Height = 24, CornerRadius = new CornerRadius(12), Margin = new Thickness(2), Cursor = Cursors.Hand, Background = new SolidColorBrush(Theme.ParseColor(h)), Tag = h };
                b.ToolTip = Lang.T(Palette.Names[i]) + (withShortcuts ? bindings.KeySuffix("Color." + Palette.Names[i]) : "");
                b.MouseLeftButtonUp += delegate
                {
                    MarkSwatch(wp, h);
                    onPick(h);
                };
                wp.Children.Add(b);
            }
            MarkSwatch(wp, current);
            return wp;
        }

        static void MarkSwatch(Panel swatches, string color)
        {
            foreach (Border b in swatches.Children)
            {
                bool sel = string.Equals((string)b.Tag, color, StringComparison.OrdinalIgnoreCase);
                b.BorderBrush = sel ? Brushes.White : Brushes.Gray;
                b.BorderThickness = new Thickness(sel ? 3 : 1);
            }
        }

        static Slider MakeSlider(double min, double max, double val, Action<double> onChange)
        {
            Slider s = new Slider { Minimum = min, Maximum = max, Value = val, Width = 170, HorizontalAlignment = HorizontalAlignment.Left };
            s.ValueChanged += delegate { onChange(s.Value); };
            return s;
        }
    }
}
