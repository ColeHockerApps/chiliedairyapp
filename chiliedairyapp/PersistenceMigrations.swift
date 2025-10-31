import Combine
import SwiftUI
import Foundation
import UniformTypeIdentifiers

@MainActor
public final class PersistenceMigrations: ObservableObject {
    public static let shared = PersistenceMigrations()

    private let filename = "chilie_diary_store.json"
    private let targetDirName = "ChilieDiary"
    private let backupDirName = "ChilieDiary_Backups"

    private init() {}

    // MARK: - Entry point

    public func performMigrationsIfNeeded() {
        moveLegacyFileIfNeeded()
        cleanupLegacyPaths()
    }

    // MARK: - Move legacy data

    private func moveLegacyFileIfNeeded() {
        let fm = FileManager.default
        let legacyPaths = possibleLegacyPaths()

        for legacyURL in legacyPaths {
            guard fm.fileExists(atPath: legacyURL.path) else { continue }

            let targetURL = storeURL()
            do {
                try ensureDirectory(targetURL.deletingLastPathComponent())

                if fm.fileExists(atPath: targetURL.path) {
                    try backupExistingFile(at: targetURL)
                    try fm.removeItem(at: targetURL)
                }

                try fm.moveItem(at: legacyURL, to: targetURL)
                print("✅ Migrated data file: \(legacyURL.lastPathComponent)")
                break
            } catch {
                print("⚠️ Migration error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Cleanup legacy files

    private func cleanupLegacyPaths() {
        let fm = FileManager.default
        let legacyPaths = possibleLegacyPaths()

        for legacyURL in legacyPaths {
            if fm.fileExists(atPath: legacyURL.path) {
                do {
                    try fm.removeItem(at: legacyURL)
                    print("🧹 Removed old file: \(legacyURL.lastPathComponent)")
                } catch {
                    print("⚠️ Failed to remove old file: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Backup existing file

    private func backupExistingFile(at url: URL) throws {
        let fm = FileManager.default
        let dir = url.deletingLastPathComponent()
        let backupDir = dir.deletingLastPathComponent().appendingPathComponent(backupDirName, isDirectory: true)

        try ensureDirectory(backupDir)
        let backupURL = backupDir.appendingPathComponent("backup_\(Date().timeIntervalSince1970).json")
        try fm.copyItem(at: url, to: backupURL)
        print("💾 Backup created: \(backupURL.lastPathComponent)")
    }

    // MARK: - Helpers

    private func possibleLegacyPaths() -> [URL] {
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let appSup = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]

        return [
            docs.appendingPathComponent(filename),
            docs.appendingPathComponent("data.json"),
            appSup.appendingPathComponent(filename)
        ]
    }

    private func storeURL() -> URL {
        let dir = applicationSupportDirectory().appendingPathComponent(targetDirName, isDirectory: true)
        return dir.appendingPathComponent(filename, conformingTo: UTType.json)
    }

    private func applicationSupportDirectory() -> URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    }

    private func ensureDirectory(_ dir: URL) throws {
        var isDir: ObjCBool = false
        if !FileManager.default.fileExists(atPath: dir.path, isDirectory: &isDir) || !isDir.boolValue {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
    }
}
