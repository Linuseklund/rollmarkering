import Cocoa
import WebKit

// Rollmarkering – ett litet Mac-program runt webbsidan i Resources/web.
// Varje projekt sparas som <projekt-id>.roll.json i projektmappen, klippbilderna i <projekt-id>.bilder/.
// Sidan når bilderna via adressen bild://lokal/<sökväg i projektmappen>.

final class AppDelegate: NSObject, NSApplicationDelegate, WKScriptMessageHandler, WKUIDelegate, WKURLSchemeHandler {
    var window: NSWindow!
    var web: WKWebView!
    let defaultsKey = "projektmapp"

    var dataDir: URL {
        if let p = UserDefaults.standard.string(forKey: defaultsKey) { return URL(fileURLWithPath: p, isDirectory: true) }
        return FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop/ROLLMARKERING/Projekt", isDirectory: true)
    }

    func applicationDidFinishLaunching(_ n: Notification) {
        try? FileManager.default.createDirectory(at: dataDir, withIntermediateDirectories: true)
        buildMenu()
        let cfg = WKWebViewConfiguration()
        cfg.userContentController.add(self, name: "app")
        cfg.setURLSchemeHandler(self, forURLScheme: "bild")
        cfg.preferences.setValue(true, forKey: "developerExtrasEnabled")
        web = WKWebView(frame: .zero, configuration: cfg)
        web.uiDelegate = self
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1440, height: 900),
                          styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        window.title = "Rollmarkering"
        window.contentView = web
        window.center()
        window.setFrameAutosaveName("Rollmarkering")
        window.makeKeyAndOrderFront(nil)
        let webDir = Bundle.main.resourceURL!.appendingPathComponent("web", isDirectory: true)
        web.loadFileURL(webDir.appendingPathComponent("index.html"), allowingReadAccessTo: webDir)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ s: NSApplication) -> Bool { true }

    func buildMenu() {
        let main = NSMenu()
        let appItem = NSMenuItem(); main.addItem(appItem)
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Om Rollmarkering", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Göm Rollmarkering", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(withTitle: "Avsluta Rollmarkering", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu
        let editItem = NSMenuItem(); main.addItem(editItem)
        let edit = NSMenu(title: "Redigera")
        edit.addItem(withTitle: "Ångra", action: Selector(("undo:")), keyEquivalent: "z")
        edit.addItem(withTitle: "Gör om", action: Selector(("redo:")), keyEquivalent: "Z")
        edit.addItem(.separator())
        edit.addItem(withTitle: "Klipp ut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        edit.addItem(withTitle: "Kopiera", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        edit.addItem(withTitle: "Klistra in", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        edit.addItem(withTitle: "Markera allt", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editItem.submenu = edit
        let viewItem = NSMenuItem(); main.addItem(viewItem)
        let view = NSMenu(title: "Visa")
        view.addItem(withTitle: "Läs in igen", action: #selector(reload), keyEquivalent: "r")
        view.addItem(withTitle: "Visa projektmappen i Finder", action: #selector(openFolder), keyEquivalent: "")
        view.addItem(withTitle: "Helskärm", action: #selector(NSWindow.toggleFullScreen(_:)), keyEquivalent: "f").keyEquivalentModifierMask = [.command, .control]
        viewItem.submenu = view
        NSApp.mainMenu = main
    }

    @objc func reload() { web.reload() }
    @objc func openFolder() { NSWorkspace.shared.activateFileViewerSelecting([dataDir]) }

    func safeName(_ s: String) -> String {
        let ok = s.unicodeScalars.map { CharacterSet.alphanumerics.contains($0) || "-_".unicodeScalars.contains($0) ? Character($0) : "-" }
        let n = String(ok); return n.isEmpty ? "projekt" : n
    }

    func userContentController(_ c: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let m = message.body as? [String: Any], let id = m["id"] as? Int, let op = m["op"] as? String else { return }
        let reply: (Any?, String?) -> Void = { r, e in
            var o: [String: Any] = [:]
            if let e = e { o["e"] = e } else { o["r"] = r ?? NSNull() }
            let data = (try? JSONSerialization.data(withJSONObject: o, options: [.fragmentsAllowed])) ?? Data("{}".utf8)
            self.web.evaluateJavaScript("__appReply(\(id), \(String(data: data, encoding: .utf8)!))")
        }
        let fm = FileManager.default
        do {
            switch op {
            case "list":
                var all: [String: Any] = [:]
                let files = (try? fm.contentsOfDirectory(at: dataDir, includingPropertiesForKeys: nil)) ?? []
                for f in files where f.lastPathComponent.hasSuffix(".roll.json") {
                    if let d = try? Data(contentsOf: f), let j = try? JSONSerialization.jsonObject(with: d) {
                        all[String(f.lastPathComponent.dropLast(".roll.json".count))] = j
                    }
                }
                reply(all, nil)
            case "write":
                try fm.createDirectory(at: dataDir, withIntermediateDirectories: true)
                let url = dataDir.appendingPathComponent(safeName(m["name"] as? String ?? "") + ".roll.json")
                try Data((m["text"] as? String ?? "").utf8).write(to: url, options: .atomic)
                reply(true, nil)
            case "remove":
                let url = dataDir.appendingPathComponent(safeName(m["name"] as? String ?? "") + ".roll.json")
                if fm.fileExists(atPath: url.path) { try fm.trashItem(at: url, resultingItemURL: nil) }
                let pics = dataDir.appendingPathComponent(safeName(m["name"] as? String ?? "") + ".bilder")
                if fm.fileExists(atPath: pics.path) { try fm.trashItem(at: pics, resultingItemURL: nil) }
                reply(true, nil)
            case "writeImage":
                let folder = safeName(m["project"] as? String ?? "") + ".bilder"
                let dir = dataDir.appendingPathComponent(folder, isDirectory: true)
                try fm.createDirectory(at: dir, withIntermediateDirectories: true)
                let file = safeName(m["name"] as? String ?? "") + "." + safeName(m["ext"] as? String ?? "jpg")
                try (Data(base64Encoded: m["b64"] as? String ?? "") ?? Data()).write(to: dir.appendingPathComponent(file), options: .atomic)
                reply(folder + "/" + file, nil)
            case "readImage":
                let base = dataDir.standardizedFileURL
                let url = base.appendingPathComponent(m["path"] as? String ?? "").standardizedFileURL
                guard url.path.hasPrefix(base.path + "/") else { reply(nil, "Ogiltig sökväg"); return }
                let mime = url.pathExtension.lowercased() == "png" ? "image/png" : "image/jpeg"
                reply("data:\(mime);base64," + (try Data(contentsOf: url)).base64EncodedString(), nil)
            case "saveFile":
                let panel = NSSavePanel()
                panel.nameFieldStringValue = m["name"] as? String ?? "fil"
                panel.canCreateDirectories = true
                panel.beginSheetModal(for: window) { res in
                    guard res == .OK, let url = panel.url else { reply(false, nil); return }
                    let data: Data
                    if let b = m["b64"] as? String { data = Data(base64Encoded: b) ?? Data() } else { data = Data((m["text"] as? String ?? "").utf8) }
                    do { try data.write(to: url, options: .atomic); reply(true, nil) } catch { reply(nil, error.localizedDescription) }
                }
            case "copy":
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(m["text"] as? String ?? "", forType: .string)
                reply(true, nil)
            case "folder":
                reply(dataDir.path, nil)
            case "openFolder":
                openFolder(); reply(true, nil)
            case "chooseFolder":
                let panel = NSOpenPanel()
                panel.canChooseDirectories = true; panel.canChooseFiles = false; panel.canCreateDirectories = true
                panel.directoryURL = dataDir
                panel.prompt = "Använd mappen"
                panel.beginSheetModal(for: window) { res in
                    guard res == .OK, let url = panel.url else { reply(nil, nil); return }
                    UserDefaults.standard.set(url.path, forKey: self.defaultsKey)
                    reply(url.path, nil)
                }
            default:
                reply(nil, "Okänd åtgärd: \(op)")
            }
        } catch { reply(nil, error.localizedDescription) }
    }

    // bild://lokal/<projekt>.bilder/<klipp>.jpg → filen i projektmappen
    func webView(_ w: WKWebView, start task: WKURLSchemeTask) {
        let rel = (task.request.url?.path ?? "").removingPercentEncoding ?? ""
        let base = dataDir.standardizedFileURL
        let url = base.appendingPathComponent(rel).standardizedFileURL
        guard url.path.hasPrefix(base.path + "/"), let data = try? Data(contentsOf: url) else {
            task.didFailWithError(NSError(domain: NSURLErrorDomain, code: NSURLErrorFileDoesNotExist)); return
        }
        let types = ["png": "image/png", "gif": "image/gif", "webp": "image/webp", "heic": "image/heic"]
        let mime = types[url.pathExtension.lowercased()] ?? "image/jpeg"
        let resp = HTTPURLResponse(url: task.request.url!, statusCode: 200, httpVersion: "HTTP/1.1",
                                   headerFields: ["Content-Type": mime, "Content-Length": "\(data.count)", "Access-Control-Allow-Origin": "*"])!
        task.didReceive(resp); task.didReceive(data); task.didFinish()
    }
    func webView(_ w: WKWebView, stop task: WKURLSchemeTask) {}

    // <input type=file> i sidan
    func webView(_ w: WKWebView, runOpenPanelWith p: WKOpenPanelParameters, initiatedByFrame f: WKFrameInfo, completionHandler: @escaping ([URL]?) -> Void) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = p.allowsMultipleSelection
        panel.canChooseDirectories = false
        panel.beginSheetModal(for: window) { res in completionHandler(res == .OK ? panel.urls : nil) }
    }

    func webView(_ w: WKWebView, runJavaScriptAlertPanelWithMessage msg: String, initiatedByFrame f: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let a = NSAlert(); a.messageText = msg; a.addButton(withTitle: "OK")
        a.beginSheetModal(for: window) { _ in completionHandler() }
    }

    func webView(_ w: WKWebView, runJavaScriptConfirmPanelWithMessage msg: String, initiatedByFrame f: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let a = NSAlert(); a.messageText = msg; a.addButton(withTitle: "OK"); a.addButton(withTitle: "Avbryt")
        a.beginSheetModal(for: window) { r in completionHandler(r == .alertFirstButtonReturn) }
    }

    func webView(_ w: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame f: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let a = NSAlert(); a.messageText = prompt; a.addButton(withTitle: "OK"); a.addButton(withTitle: "Avbryt")
        let tf = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24)); tf.stringValue = defaultText ?? ""
        a.accessoryView = tf
        a.beginSheetModal(for: window) { r in completionHandler(r == .alertFirstButtonReturn ? tf.stringValue : nil) }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
