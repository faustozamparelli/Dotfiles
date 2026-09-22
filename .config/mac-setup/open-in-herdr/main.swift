import AppKit
import CoreServices
import UniformTypeIdentifiers

private let bundleID = "com.fausto.open-in-herdr" as CFString
private let extensions = [
    "txt", "text", "md", "markdown", "rst", "org", "tex", "log",
    "json", "jsonc", "jsonl", "yaml", "yml", "toml", "xml", "plist",
    "ini", "cfg", "conf", "properties", "env",
    "sh", "bash", "zsh", "fish", "py", "pyi", "js", "jsx", "mjs", "cjs",
    "ts", "tsx", "mts", "cts", "css", "scss", "sass", "html", "htm",
    "c", "h", "cc", "cpp", "cxx", "hpp", "rs", "go", "java", "kt",
    "kts", "swift", "rb", "php", "lua", "vim", "sql", "r", "R"
]

func setDefaults() -> Int32 {
    var failed = false
    let types = Set(extensions.compactMap { UTType(filenameExtension: $0)?.identifier } + [
        UTType.plainText.identifier,
        UTType.sourceCode.identifier
    ])

    for type in types.sorted() {
        let current = LSCopyDefaultRoleHandlerForContentType(type as CFString, .all)?.takeRetainedValue()
        if current as String? == bundleID as String { continue }
        let status = LSSetDefaultRoleHandlerForContentType(type as CFString, .all, bundleID)
        if status != noErr {
            fputs("Could not set default editor for \(type): \(status)\n", stderr)
            failed = true
        }
    }
    return failed ? 1 : 0
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        let worker = Process()
        worker.executableURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/mac-setup/open-in-herdr/open-files")
        worker.arguments = filenames
        do {
            try worker.run()
            sender.reply(toOpenOrPrint: .success)
        } catch {
            NSLog("Open in Herdr: %@", error.localizedDescription)
            sender.reply(toOpenOrPrint: .failure)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}

if CommandLine.arguments.dropFirst().first == "--set-defaults" {
    exit(setDefaults())
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.setActivationPolicy(.prohibited)
app.delegate = delegate
app.run()
