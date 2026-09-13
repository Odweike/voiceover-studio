import Foundation
import Darwin

/// Prevent two copies of the app from overwriting the same project's manifest.
final class ProjectLease {
    private let descriptor: Int32

    init(root: URL) throws {
        let path = root.appendingPathComponent(".voiceover.lock").path
        let fd = Darwin.open(path, O_CREAT | O_RDWR | O_NOFOLLOW, S_IRUSR | S_IWUSR)
        guard fd >= 0 else { throw StudioError(message: Strings.current.errNoFolderAccess) }
        guard flock(fd, LOCK_EX | LOCK_NB) == 0 else {
            Darwin.close(fd)
            throw StudioError(message: Strings.current.errProjectAlreadyOpen)
        }
        descriptor = fd
    }

    deinit { Darwin.close(descriptor) }
}
