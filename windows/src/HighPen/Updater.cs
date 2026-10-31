using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using System.IO;
using System.Net;
using System.Reflection;
using System.Security.Cryptography;
using System.Text;
using System.Web.Script.Serialization;

namespace HighPen
{
    // A newer Windows release and the file that updates this copy.
    class UpdateInfo
    {
        public Version Version;
        public string PageUrl;   // the release page (what's new)
        public string AssetName; // HighPen-Setup.exe or HighPen.exe
        public string AssetUrl;
        public string SumsUrl;   // SHA256SUMS.txt of the same release
    }

    // Finds newer versions among the GitHub releases and installs them the way this copy was installed:
    // an installed copy runs the new installer, a copy run straight from HighPen.exe replaces that file.
    // The Store version is kept up to date by the Store and never checks.
    static class Updater
    {
        const string ReleasesApi = "https://api.github.com/repos/stepanowon/high-pen/releases?per_page=30";
        const string SetupName = "HighPen-Setup.exe", ExeName = "HighPen.exe", SumsName = "SHA256SUMS.txt";
        // Passed to the new HighPen.exe so it waits for this one to quit before starting.
        public const string WaitArg = "/waitpid";

        static readonly string ExePath = Assembly.GetExecutingAssembly().Location;

        public static bool Supported { get { return !IsPackaged; } }

        static bool IsPackaged
        {
            get
            {
                try
                {
                    int len = 0;
                    return Native.GetCurrentPackageFullName(ref len, null) != Native.APPMODEL_ERROR_NO_PACKAGE;
                }
                catch { return false; }
            }
        }

        // Installed by HighPen-Setup.exe (its folder also holds Uninstall.exe).
        static bool Installed
        {
            get
            {
                string installDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Programs", "HighPen");
                string dir = Path.GetDirectoryName(ExePath);
                return string.Equals(dir.TrimEnd('\\'), installDir, StringComparison.OrdinalIgnoreCase) && File.Exists(Path.Combine(dir, "Uninstall.exe"));
            }
        }

        static string AssetName { get { return Installed ? SetupName : ExeName; } }

        public static WebClient Client()
        {
            ServicePointManager.SecurityProtocol |= SecurityProtocolType.Tls12;
            WebClient wc = new WebClient { Encoding = Encoding.UTF8 };
            wc.Headers[HttpRequestHeader.UserAgent] = "HighPen/" + AppInfo.AppVersion;
            return wc;
        }

        // Asks GitHub for the releases and calls found (on the calling thread) when a newer one has the file
        // this copy needs and its checksums. Errors (offline, rate limit) are silent.
        public static void Check(Action<UpdateInfo> found)
        {
            WebClient wc = Client();
            wc.Headers[HttpRequestHeader.Accept] = "application/vnd.github+json";
            wc.DownloadStringCompleted += delegate (object s, DownloadStringCompletedEventArgs e)
            {
                wc.Dispose();
                if (e.Error != null || e.Cancelled) return;
                UpdateInfo u = null;
                try { u = Pick(e.Result); } catch { }
                if (u != null) found(u);
            };
            try { wc.DownloadStringAsync(new Uri(ReleasesApi)); } catch { wc.Dispose(); }
        }

        // The newest published Windows release (tags "v1.2.3"; macOS releases are "macos-v…") above this version.
        static UpdateInfo Pick(string json)
        {
            object[] releases = new JavaScriptSerializer { MaxJsonLength = int.MaxValue }.DeserializeObject(json) as object[];
            if (releases == null) return null;
            Version current = Normalize(new Version(AppInfo.AppVersion));
            string asset = AssetName;
            UpdateInfo best = null;
            foreach (object o in releases)
            {
                Dictionary<string, object> r = o as Dictionary<string, object>;
                if (r == null || true.Equals(Get(r, "draft")) || true.Equals(Get(r, "prerelease"))) continue;
                string tag = Get(r, "tag_name") as string;
                Version v;
                if (tag == null || !tag.StartsWith("v") || !Version.TryParse(tag.Substring(1), out v)) continue;
                v = Normalize(v);
                if (v <= current || (best != null && v <= best.Version)) continue;
                string assetUrl = AssetUrl(r, asset), sumsUrl = AssetUrl(r, SumsName);
                if (assetUrl == null || sumsUrl == null) continue;
                best = new UpdateInfo { Version = v, PageUrl = Get(r, "html_url") as string ?? AppInfo.RepoUrl + "/releases", AssetName = asset, AssetUrl = assetUrl, SumsUrl = sumsUrl };
            }
            return best;
        }

        // "1.8" and "1.8.0" are the same version.
        static Version Normalize(Version v) { return new Version(v.Major, v.Minor, Math.Max(v.Build, 0)); }

        static object Get(Dictionary<string, object> d, string key)
        {
            object v;
            return d.TryGetValue(key, out v) ? v : null;
        }

        static string AssetUrl(Dictionary<string, object> release, string name)
        {
            object[] assets = Get(release, "assets") as object[];
            if (assets == null) return null;
            foreach (object o in assets)
            {
                Dictionary<string, object> a = o as Dictionary<string, object>;
                if (a != null && (Get(a, "name") as string) == name) return Get(a, "browser_download_url") as string;
            }
            return null;
        }

        // The hash listed for name in a sha256sum-style file, or null.
        public static string ExpectedHash(string sums, string name)
        {
            foreach (string line in sums.Split('\n'))
            {
                string[] parts = line.Trim().Split(new[] { ' ', '\t', '*' }, StringSplitOptions.RemoveEmptyEntries);
                if (parts.Length == 2 && parts[1] == name && parts[0].Length == 64) return parts[0].ToLowerInvariant();
            }
            return null;
        }

        public static string FileHash(string path)
        {
            using (SHA256 sha = SHA256.Create())
            using (FileStream f = File.OpenRead(path))
                return BitConverter.ToString(sha.ComputeHash(f)).Replace("-", "").ToLowerInvariant();
        }

        // Where the downloaded file goes: the installer to the temp folder, a new HighPen.exe next to this one.
        public static string DownloadPath(UpdateInfo u)
        {
            return u.AssetName == SetupName ? Path.Combine(Path.GetTempPath(), "HighPen-Setup-" + u.Version + ".exe") : ExePath + ".new";
        }

        // Starts the verified download. Returns null when the new version is on its way and HighPen should
        // quit, otherwise the error to show.
        public static string Launch(UpdateInfo u, string file)
        {
            try
            {
                if (u.AssetName == SetupName)
                {
                    Process.Start(file, "/S /run");
                    return null;
                }
                // a running exe cannot be overwritten but can be renamed
                string old = ExePath + ".old";
                TryDelete(old);
                File.Move(ExePath, old);
                try { File.Move(file, ExePath); }
                catch { File.Move(old, ExePath); throw; }
                Process.Start(ExePath, WaitArg + " " + Process.GetCurrentProcess().Id);
                return null;
            }
            catch (Exception ex) { return Failed(ex); }
        }

        public static string Failed(Exception ex)
        {
            return Lang.T("UpdateFailed") + (ex == null ? "" : "\n" + ex.Message);
        }

        // At start-up, before taking the single-instance lock: when the copy that was just replaced started
        // this one, waits for it to quit and release the lock.
        public static void WaitForPrevious(string[] args)
        {
            int i = Array.IndexOf(args, WaitArg);
            int pid;
            if (i < 0 || i + 1 >= args.Length || !int.TryParse(args[i + 1], out pid)) return;
            try { using (Process p = Process.GetProcessById(pid)) p.WaitForExit(10000); } catch { }
        }

        // Once this is the only copy running: removes what an earlier update left behind.
        public static void CleanUp()
        {
            TryDelete(ExePath + ".old");
            TryDelete(ExePath + ".new");
            try { foreach (string f in Directory.GetFiles(Path.GetTempPath(), "HighPen-Setup-*.exe")) TryDelete(f); } catch { }
        }

        public static void TryDelete(string path)
        {
            try { if (File.Exists(path)) File.Delete(path); } catch { }
        }
    }

    // One update download: the release's checksums, then the file, which is checked against them and started.
    // Calls progress and done on the thread that created it.
    class UpdateDownload
    {
        readonly UpdateInfo u;
        readonly Action<int> progress;
        readonly Action<string> done; // null = the new version is starting; HighPen should quit
        readonly string file;
        WebClient wc;
        bool cancelled;

        public UpdateDownload(UpdateInfo u, Action<int> progress, Action<string> done)
        {
            this.u = u;
            this.progress = progress;
            this.done = done;
            file = Updater.DownloadPath(u);
            wc = Updater.Client();
            wc.DownloadStringCompleted += OnSums;
            try { wc.DownloadStringAsync(new Uri(u.SumsUrl)); }
            catch (Exception ex) { Finish(Updater.Failed(ex)); }
        }

        // Stops before anything is installed; done is not called.
        public void Cancel()
        {
            cancelled = true;
            if (wc != null) wc.CancelAsync();
        }

        void OnSums(object s, DownloadStringCompletedEventArgs e)
        {
            wc.Dispose();
            if (cancelled) return;
            string hash = e.Error == null && !e.Cancelled ? Updater.ExpectedHash(e.Result, u.AssetName) : null;
            if (hash == null) { Finish(Updater.Failed(e.Error)); return; }
            wc = Updater.Client();
            wc.DownloadProgressChanged += delegate (object o, DownloadProgressChangedEventArgs p) { if (!cancelled) progress(p.ProgressPercentage); };
            wc.DownloadFileCompleted += delegate (object o, AsyncCompletedEventArgs f)
            {
                wc.Dispose();
                if (cancelled || f.Cancelled) { Updater.TryDelete(file); return; }
                if (f.Error != null) { Updater.TryDelete(file); Finish(Updater.Failed(f.Error)); return; }
                string actual;
                try { actual = Updater.FileHash(file); }
                catch (Exception ex) { Updater.TryDelete(file); Finish(Updater.Failed(ex)); return; }
                if (actual != hash) { Updater.TryDelete(file); Finish(Lang.T("UpdateBadHash")); return; }
                string error = Updater.Launch(u, file);
                if (error != null) Updater.TryDelete(file);
                Finish(error);
            };
            try { wc.DownloadFileAsync(new Uri(u.AssetUrl), file); }
            catch (Exception ex) { Finish(Updater.Failed(ex)); }
        }

        void Finish(string error)
        {
            wc = null;
            if (!cancelled) done(error);
        }
    }
}
