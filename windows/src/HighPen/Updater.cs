using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Net;
using System.Reflection;
using System.Text;
using System.Web.Script.Serialization;

namespace HighPen
{
    // A newer Windows release.
    class UpdateInfo
    {
        public Version Version;
        public string PageUrl; // the release page (what's new)
    }

    // Finds newer versions among the GitHub releases. The update itself comes from the Microsoft Store,
    // whose package is signed (the files on GitHub are not). The Store version is kept up to date by the
    // Store and never checks.
    static class Updater
    {
        const string ReleasesApi = "https://api.github.com/repos/stepanowon/high-pen/releases?per_page=30";
        const string StoreProductId = "9PDG1QN5QSL3";
        // 1.8.0 replaced its own HighPen.exe with a new one from GitHub and started it with this argument,
        // so the new copy waits for it to quit. Kept so that update from 1.8.0 still starts cleanly.
        const string WaitArg = "/waitpid";

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

        // Asks GitHub for the releases and calls done on the calling thread: (newer release, null) when one is
        // out, (null, null) when this is the newest, (null, message) when the check failed (offline, rate limit).
        public static void Check(Action<UpdateInfo, string> done)
        {
            ServicePointManager.SecurityProtocol |= SecurityProtocolType.Tls12;
            WebClient wc = new WebClient { Encoding = Encoding.UTF8 };
            wc.Headers[HttpRequestHeader.UserAgent] = "HighPen/" + AppInfo.AppVersion;
            wc.Headers[HttpRequestHeader.Accept] = "application/vnd.github+json";
            wc.DownloadStringCompleted += delegate (object s, DownloadStringCompletedEventArgs e)
            {
                wc.Dispose();
                if (e.Error != null || e.Cancelled) { done(null, Lang.T("UpdateCheckFailed")); return; }
                UpdateInfo u;
                try { u = Pick(e.Result); }
                catch { done(null, Lang.T("UpdateCheckFailed")); return; }
                done(u, null);
            };
            try { wc.DownloadStringAsync(new Uri(ReleasesApi)); }
            catch { wc.Dispose(); done(null, Lang.T("UpdateCheckFailed")); }
        }

        // The newest published Windows release (tags "v1.2.3"; macOS releases are "macos-v…") above this version.
        static UpdateInfo Pick(string json)
        {
            object[] releases = new JavaScriptSerializer { MaxJsonLength = int.MaxValue }.DeserializeObject(json) as object[];
            if (releases == null) return null;
            Version current = Normalize(new Version(AppInfo.AppVersion));
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
                best = new UpdateInfo { Version = v, PageUrl = Get(r, "html_url") as string ?? AppInfo.RepoUrl + "/releases" };
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

        // Opens HighPen's page in the Microsoft Store app, or on the web when the Store app is not available.
        // mini: the compact install window (to install the Store version over a GitHub copy); otherwise the
        // full page, which offers Update when the installed Store version is behind.
        public static void OpenStore(bool mini)
        {
            try { Process.Start("ms-windows-store://pdp/?ProductId=" + StoreProductId + (mini ? "&mode=mini" : "")); }
            catch
            {
                try { Process.Start("https://apps.microsoft.com/detail/" + StoreProductId); } catch { }
            }
        }

        // At start-up, before taking the single-instance lock: when 1.8.0 replaced itself with this copy and
        // started it, waits for 1.8.0 to quit and release the lock.
        public static void WaitForPrevious(string[] args)
        {
            int i = Array.IndexOf(args, WaitArg);
            int pid;
            if (i < 0 || i + 1 >= args.Length || !int.TryParse(args[i + 1], out pid)) return;
            try { using (Process p = Process.GetProcessById(pid)) p.WaitForExit(10000); } catch { }
        }

        // Once this is the only copy running: removes what a 1.8.0 self-update left behind.
        public static void CleanUp()
        {
            TryDelete(ExePath + ".old");
            TryDelete(ExePath + ".new");
            try { foreach (string f in Directory.GetFiles(Path.GetTempPath(), "HighPen-Setup-*.exe")) TryDelete(f); } catch { }
        }

        static void TryDelete(string path)
        {
            try { if (File.Exists(path)) File.Delete(path); } catch { }
        }
    }
}
