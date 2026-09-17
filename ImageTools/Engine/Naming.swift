import Foundation

// Every file the app hands out is named image-tools-<tool>-<date>[-<n>].<ext>,
// so a user can tell in Files, Photos or a chat what produced it and when.
enum Naming {
    static func output(tool: String, ext: String, index: Int = 0, total: Int = 1) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        let suffix = total > 1 ? "-" + String(format: "%0\(String(total).count)d", index + 1) : ""
        return "image-tools-\(tool)-\(f.string(from: Date()))\(suffix).\(ext)"
    }
}
