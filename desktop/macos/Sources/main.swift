import Cocoa
import WebKit

let appURL = URL(string: "http://localhost:3000")!

// This launcher lives at <repo>/desktop/macos/OpenStock.app once built,
// so the repo root is three levels above the .app bundle.
let appDir: String = {
    let bundleURL = Bundle.main.bundleURL // .../desktop/macos/OpenStock.app
    let repoRoot = bundleURL
        .deletingLastPathComponent() // desktop/macos
        .deletingLastPathComponent() // desktop
        .deletingLastPathComponent() // repo root
    return repoRoot.path
}()

final class AppDelegate: NSObject, NSApplicationDelegate, WKNavigationDelegate {
    var window: NSWindow!
    var webView: WKWebView!
    var statusLabel: NSTextField!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        buildMenuBar()

        let screenSize = NSScreen.main?.frame.size ?? NSSize(width: 1440, height: 900)
        let winSize = NSSize(width: min(1280, screenSize.width - 120), height: min(860, screenSize.height - 120))
        window = NSWindow(
            contentRect: NSRect(origin: .zero, size: winSize),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "OpenStock"
        window.center()
        window.minSize = NSSize(width: 720, height: 480)

        let config = WKWebViewConfiguration()
        webView = WKWebView(frame: NSRect(origin: .zero, size: winSize), configuration: config)
        webView.navigationDelegate = self
        webView.autoresizingMask = [.width, .height]
        window.contentView = webView

        statusLabel = NSTextField(labelWithString: "正在启动 OpenStock…")
        statusLabel.font = NSFont.systemFont(ofSize: 15, weight: .medium)
        statusLabel.textColor = .white
        statusLabel.alignment = .center
        statusLabel.frame = NSRect(x: 0, y: winSize.height / 2 - 10, width: winSize.width, height: 24)
        statusLabel.autoresizingMask = [.width, .minYMargin, .maxYMargin]
        webView.addSubview(statusLabel)

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        ensureServerRunning { [weak self] in
            DispatchQueue.main.async {
                self?.webView.load(URLRequest(url: appURL))
            }
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        statusLabel.removeFromSuperview()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    private func buildMenuBar() {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "关于 OpenStock", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "退出 OpenStock", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "撤销", action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(withTitle: "重做", action: Selector(("redo:")), keyEquivalent: "Z")
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(withTitle: "剪切", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "拷贝", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "粘贴", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "全选", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        let viewMenuItem = NSMenuItem()
        let viewMenu = NSMenu(title: "View")
        viewMenu.addItem(withTitle: "刷新", action: #selector(reload), keyEquivalent: "r")
        viewMenuItem.submenu = viewMenu
        mainMenu.addItem(viewMenuItem)

        let windowMenuItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(withTitle: "最小化", action: #selector(NSWindow.miniaturize(_:)), keyEquivalent: "m")
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)

        NSApp.mainMenu = mainMenu
    }

    @objc private func reload() {
        webView.reload()
    }

    private func ensureServerRunning(completion: @escaping () -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            if Self.isServerUp() {
                completion()
                return
            }
            Self.startServer()
            for _ in 0..<30 {
                if Self.isServerUp() {
                    break
                }
                Thread.sleep(forTimeInterval: 1)
            }
            completion()
        }
    }

    private static func isServerUp() -> Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/curl")
        task.arguments = ["-s", "-o", "/dev/null", "-m", "2", "-w", "%{http_code}", "http://localhost:3000"]
        let pipe = Pipe()
        task.standardOutput = pipe
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let code = String(data: data, encoding: .utf8) ?? ""
            return !code.isEmpty && code != "000"
        } catch {
            return false
        }
    }

    private static func startServer() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/bash")
        task.arguments = ["-lc", "export PATH=/opt/homebrew/bin:$PATH; cd '\(appDir)' && nohup pnpm start >> \"$HOME/Library/Logs/OpenStock.log\" 2>&1 &"]
        try? task.run()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
