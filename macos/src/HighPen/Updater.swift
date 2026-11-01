import Cocoa

// ---------- update check ----------

// A newer macOS release.
struct UpdateInfo {
    let version: String
    let page: URL // the release page (what's new, and the DMG)
}

// Finds newer versions among the GitHub releases. Nothing is downloaded: the update window opens the release
// page, where the user gets the new DMG.
enum Updater {
    static let releasesApi = URL(string: "https://api.github.com/repos/stepanowon/high-pen/releases?per_page=30")!

    // Asks GitHub for the releases and calls done: (newer release, nil) when one is out, (nil, nil) when this is
    // the newest, (nil, message) when the check failed (offline, rate limit).
    @MainActor
    static func check(_ done: @escaping @MainActor (UpdateInfo?, String?) -> Void) {
        var req = URLRequest(url: releasesApi, timeoutInterval: 15)
        req.setValue("HighPen-macOS/" + appVersion, forHTTPHeaderField: "User-Agent")
        req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        Task { @MainActor in
            do {
                let (data, resp) = try await URLSession.shared.data(for: req)
                guard (resp as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
                done(try pick(data, current: appVersion), nil)
            } catch {
                done(nil, Lang.t("UpdateCheckFailed"))
            }
        }
    }

    // The newest published macOS release (tags "macos-v1.2.3"; Windows releases are "v…") above current.
    static func pick(_ json: Data, current: String) throws -> UpdateInfo? {
        guard let releases = try JSONSerialization.jsonObject(with: json) as? [[String: Any]],
              let cur = version(current) else { return nil }
        var best: (v: [Int], info: UpdateInfo)?
        for r in releases where r["draft"] as? Bool != true && r["prerelease"] as? Bool != true {
            guard let tag = r["tag_name"] as? String, tag.hasPrefix("macos-v"),
                  let v = version(String(tag.dropFirst(7))), cur.lexicographicallyPrecedes(v),
                  best.map({ $0.v.lexicographicallyPrecedes(v) }) ?? true else { continue }
            let page = (r["html_url"] as? String).flatMap(URL.init(string:)) ?? URL(string: "https://github.com/stepanowon/high-pen/releases")!
            best = (v, UpdateInfo(version: v.map(String.init).joined(separator: "."), page: page))
        }
        return best?.info
    }

    // "1.4" and "1.4.0" are the same version; nil for anything else ("dev" when run unbundled).
    static func version(_ s: String) -> [Int]? {
        let parts = s.split(separator: ".").map { Int($0) }
        guard (1...3).contains(parts.count), !parts.contains(nil) else { return nil }
        return parts.map { $0! } + Array(repeating: 0, count: 3 - parts.count)
    }
}
