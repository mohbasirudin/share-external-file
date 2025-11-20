import Foundation
import Flutter
import UIKit

class ShareHandler {
    private var methodChannel: FlutterMethodChannel?
    private var initialShareData: [String: Any?]?
    
    init(methodChannel: FlutterMethodChannel?) {
        self.methodChannel = methodChannel
    }
    
    func getInitialShareData() -> [String: Any?] {
        let data = initialShareData ?? [:]
        initialShareData = nil // Clear setelah diambil
        return data
    }
    
    func handleSharedContent(url: URL) {
        // Handle URL dari share extension atau file
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: url.path) {
            let fileInfo = processFile(at: url)
            
            let data: [String: Any?] = [
                "type": "file",
                "text": nil,
                "subject": nil,
                "files": [fileInfo]
            ]
            
            sendToFlutter(data: data)
        }
    }
    
    private func processFile(at url: URL) -> [String: Any?] {
        let fileName = url.lastPathComponent
        let filePath = url.path
        
        // Get MIME type
        let mimeType = FileUtils.getMimeType(for: url)
        let fileType = categorizeFileType(mimeType: mimeType)
        
        // Get file size
        let fileSize = FileUtils.getFileSize(at: url)
        let sizeFormatted = fileSize != nil ? FileUtils.formatFileSize(bytes: fileSize!) : nil
        
        // Generate thumbnail
        var thumbnailPath: String?
        switch fileType {
        case "image":
            thumbnailPath = FileUtils.generateImageThumbnail(from: url, size: 512)
        case "video":
            thumbnailPath = FileUtils.generateVideoThumbnail(from: url, size: 512)
        default:
            thumbnailPath = nil
        }
        
        return [
            "path": filePath,
            "uri": url.absoluteString,
            "name": fileName,
            "type": fileType,
            "mimeType": mimeType as Any,
            "thumbnail": thumbnailPath as Any,
            "size": fileSize as Any,
            "sizeFormatted": sizeFormatted as Any
        ]
    }
    
    private func categorizeFileType(mimeType: String?) -> String {
        guard let mimeType = mimeType else { return "file" }
        
        switch true {
        case mimeType.hasPrefix("image/"):
            return "image"
        case mimeType.hasPrefix("video/"):
            return "video"
        case mimeType.hasPrefix("audio/"):
            return "audio"
        case mimeType == "application/pdf":
            return "pdf"
        case mimeType.contains("wordprocessing") || mimeType.contains("msword"):
            return "document"
        case mimeType.contains("spreadsheet") || mimeType.contains("excel"):
            return "spreadsheet"
        case mimeType.contains("presentation") || mimeType.contains("powerpoint"):
            return "presentation"
        case mimeType.contains("zip") || mimeType.contains("compressed"):
            return "archive"
        case mimeType.hasPrefix("text/"):
            return "text"
        default:
            return "file"
        }
    }
    
    private func sendToFlutter(data: [String: Any?]) {
        if let channel = methodChannel {
            // App sudah running, kirim langsung
            channel.invokeMethod("onShareReceived", arguments: data)
        } else {
            // App baru dibuka, simpan untuk nanti
            initialShareData = data
        }
    }
}
