import UIKit
import Social
import MobileCoreServices
import UniformTypeIdentifiers

class ShareViewController: SLComposeServiceViewController {
    
    let groupIdentifier = "group.id.bee.sharemanual"
    let sharedKey = "ShareKey"
    
    override func isContentValid() -> Bool {
        return true
    }
    
    override func didSelectPost() {
        // Handle the shared content
        if let content = extensionContext!.inputItems[0] as? NSExtensionItem {
            if let contents = content.attachments {
                handleSharedContent(contents: contents)
            }
        }
    }
    
    private func handleSharedContent(contents: [NSItemProvider]) {
        var sharedData: [String: Any] = [:]
        var files: [[String: String]] = []
        
        let group = DispatchGroup()
        
        for attachment in contents {
            // Handle Text/URL
            if attachment.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                group.enter()
                attachment.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { (data, error) in
                    if let text = data as? String {
                        sharedData["text"] = text
                        sharedData["type"] = "text"
                    }
                    group.leave()
                }
            }
            else if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                group.enter()
                attachment.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { (data, error) in
                    if let url = data as? URL {
                        sharedData["text"] = url.absoluteString
                        sharedData["type"] = "text"
                    }
                    group.leave()
                }
            }
            // Handle Images
            else if attachment.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                group.enter()
                attachment.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { (data, error) in
                    if let url = data as? URL {
                        let fileInfo: [String: String] = [
                            "path": url.path,
                            "type": "image",
                            "name": url.lastPathComponent
                        ]
                        files.append(fileInfo)
                    }
                    group.leave()
                }
            }
            // Handle Videos
            else if attachment.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                group.enter()
                attachment.loadItem(forTypeIdentifier: UTType.movie.identifier, options: nil) { (data, error) in
                    if let url = data as? URL {
                        let fileInfo: [String: String] = [
                            "path": url.path,
                            "type": "video",
                            "name": url.lastPathComponent
                        ]
                        files.append(fileInfo)
                    }
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            if !files.isEmpty {
                sharedData["files"] = files
                sharedData["type"] = files.count > 1 ? "files" : "file"
            }
            
            // Save to UserDefaults shared dengan main app
            if let userDefaults = UserDefaults(suiteName: self.groupIdentifier) {
                userDefaults.set(sharedData, forKey: self.sharedKey)
                userDefaults.synchronize()
            }
            
            // Open main app
            self.openMainApp()
        }
    }
    
    private func openMainApp() {
        let url = URL(string: "ShareManualApp://share")!
        var responder = self as UIResponder?
        let selectorOpenURL = sel_registerName("openURL:")
        
        while (responder != nil) {
            if responder?.responds(to: selectorOpenURL) == true {
                responder?.perform(selectorOpenURL, with: url)
            }
            responder = responder!.next
        }
        
        extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }
    
    override func configurationItems() -> [Any]! {
        return []
    }
}
