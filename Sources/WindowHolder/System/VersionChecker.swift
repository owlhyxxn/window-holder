import Foundation

private struct GitHubRelease: Decodable {
    let tag_name: String
    let html_url: String
}

final class VersionChecker {
    static let shared = VersionChecker()

    private let repo = "owlhyxxn/window-holder"

    private(set) var latestVersion: String?
    private(set) var latestReleaseURL: URL?

    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0"
    }

    func checkForUpdate(completion: @escaping (_ isNewerAvailable: Bool) -> Void) {
        guard let url = URL(string: "https://api.github.com/repos/\(repo)/releases/latest") else {
            completion(false)
            return
        }
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let self, let data, error == nil,
                  let release = try? JSONDecoder().decode(GitHubRelease.self, from: data) else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            let tag = release.tag_name.hasPrefix("v") ? String(release.tag_name.dropFirst()) : release.tag_name
            self.latestVersion = tag
            self.latestReleaseURL = URL(string: release.html_url)
            let isNewer = Self.isVersion(tag, newerThan: self.currentVersion)
            DispatchQueue.main.async { completion(isNewer) }
        }.resume()
    }

    static func isVersion(_ a: String, newerThan b: String) -> Bool {
        let aParts = a.split(separator: ".").compactMap { Int($0) }
        let bParts = b.split(separator: ".").compactMap { Int($0) }
        let count = max(aParts.count, bParts.count)
        for i in 0..<count {
            let x = i < aParts.count ? aParts[i] : 0
            let y = i < bParts.count ? bParts[i] : 0
            if x != y { return x > y }
        }
        return false
    }
}
