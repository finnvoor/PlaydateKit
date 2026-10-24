import Foundation

/// Keeps the compiled output of whole top-level resource directories between builds, so an unchanged
/// directory is neither copied into the `pdc` input nor compiled again.
///
/// `pdc` empties its output pdx before writing, so a skipped directory has to be put back afterwards.
struct ResourceCache {
    // MARK: Lifecycle

    init(directory: URL, pdc: URL, resourcesIgnore: URL) {
        self.directory = directory
        let pdcAttributes = try? FileManager.default.attributesOfItem(atPath: pdc.path(percentEncoded: false))
        let ignore = (try? String(contentsOf: resourcesIgnore, encoding: .utf8)) ?? ""
        salt = "\(pdcAttributes?[.size] ?? 0) \(pdcAttributes?[.modificationDate] ?? 0) \(ignore)"
    }

    // MARK: Internal

    /// A top-level resource directory that has to be copied and compiled this build.
    struct Pending {
        let name: String
        let stamp: String
    }

    /// A top-level resource directory whose compiled output is in the cache.
    struct Reused {
        let name: String
        let compiled: URL
    }

    let directory: URL
    /// Everything outside the directories that changes what `pdc` makes of them.
    let salt: String

    /// Hashes the path, size and modification time of every file, which is what a rebuild would notice too.
    func stamp(of directory: URL) -> String {
        let keys: [URLResourceKey] = [.fileSizeKey, .contentModificationDateKey]
        let enumerator = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: keys)
        var entries: [String] = []
        while let url = enumerator?.nextObject() as? URL {
            guard url.lastPathComponent != ".DS_Store" else { continue }
            let values = try? url.resourceValues(forKeys: Set(keys))
            let modified = values?.contentModificationDate?.timeIntervalSinceReferenceDate ?? 0
            entries.append("\(url.path(percentEncoded: false)) \(values?.fileSize ?? 0) \(modified)")
        }
        entries.sort()

        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in ([salt] + entries).joined(separator: "\n").utf8 {
            hash = (hash ^ UInt64(byte)) &* 0x100_0000_01b3
        }
        return "\(entries.count)-\(String(hash, radix: 16))"
    }

    func compiled(name: String, stamp: String) -> URL? {
        let entry = directory.appending(component: name)
        guard let stored = try? String(contentsOf: entry.appending(component: "stamp"), encoding: .utf8),
              stored == stamp else { return nil }
        let compiled = entry.appending(component: "compiled")
        return FileManager.default.fileExists(atPath: compiled.path(percentEncoded: false)) ? compiled : nil
    }

    /// Writes the stamp last, so an interrupted store reads as a miss.
    func store(_ pending: Pending, compiledFrom pdx: URL) throws {
        let fileManager = FileManager.default
        let source = pdx.appending(component: pending.name)
        let entry = directory.appending(component: pending.name)
        if fileManager.fileExists(atPath: entry.path(percentEncoded: false)) {
            try fileManager.removeItem(at: entry)
        }
        // A directory pdc compiled to nothing (everything in it ignored) has nothing to reuse.
        guard fileManager.fileExists(atPath: source.path(percentEncoded: false)) else { return }
        try fileManager.createDirectory(at: entry, withIntermediateDirectories: true)
        try fileManager.copyItem(at: source, to: entry.appending(component: "compiled"))
        try pending.stamp.write(to: entry.appending(component: "stamp"), atomically: true, encoding: .utf8)
    }

    func restore(_ reused: Reused, into pdx: URL) throws {
        let fileManager = FileManager.default
        let destination = pdx.appending(component: reused.name)
        if fileManager.fileExists(atPath: destination.path(percentEncoded: false)) {
            try fileManager.removeItem(at: destination)
        }
        try fileManager.copyItem(at: reused.compiled, to: destination)
    }

    /// Drops entries for directories that no longer exist.
    func prune(keeping names: Set<String>) {
        let fileManager = FileManager.default
        let entries = (try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        for entry in entries where !names.contains(entry.lastPathComponent) {
            try? fileManager.removeItem(at: entry)
        }
    }
}
