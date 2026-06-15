//
//  ConfigFileWatcher.swift
//  hypetype
//
//  Следит за папкой с config.ini и сообщает об изменениях (авто-reload при внешней подмене).
//  Watch именно папки, а не файла: atomic-запись заменяет inode, и watch по файлу бы «отвалился».
//

import Foundation
import OSLog

private let log = Logger(subsystem: "hypetype", category: "ConfigWatcher")

final class ConfigFileWatcher {
    private let folder: URL
    private let onChange: () -> Void
    private var source: DispatchSourceFileSystemObject?
    private var fd: Int32 = -1
    private var debounce: DispatchWorkItem?

    init(folder: URL, onChange: @escaping () -> Void) {
        self.folder = folder
        self.onChange = onChange
    }

    func start() {
        stop()
        fd = open(folder.path, O_EVTONLY)
        guard fd >= 0 else {
            log.error("Cannot open folder for watching: \(self.folder.path)")
            return
        }
        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .rename, .delete],
            queue: .main
        )
        src.setEventHandler { [weak self] in self?.scheduleFire() }
        src.setCancelHandler { [weak self] in
            if let fd = self?.fd, fd >= 0 { close(fd) }
            self?.fd = -1
        }
        source = src
        src.resume()
        log.info("Watching config folder: \(self.folder.lastPathComponent)")
    }

    func stop() {
        source?.cancel()
        source = nil
    }

    deinit { stop() }

    /// Дебаунс: atomic-запись поднимает несколько событий подряд — схлопываем в одно.
    private func scheduleFire() {
        debounce?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.onChange() }
        debounce = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: work)
    }
}
