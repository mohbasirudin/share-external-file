import Foundation
import UIKit
import AVFoundation
import UniformTypeIdentifiers

class FileUtils {
    
    // MARK: - File Info
    
    static func getMimeType(for url: URL) -> String? {
        // iOS 14+ - Modern API
        if #available(iOS 14.0, *) {
            if let utType = UTType(filenameExtension: url.pathExtension) {
                return utType.preferredMIMEType
            }
        }
        
        // Fallback - Manual mapping untuk iOS 13
        let ext = url.pathExtension.lowercased()
        return mimeTypeForExtension(ext)
    }
    
    private static func mimeTypeForExtension(_ ext: String) -> String? {
        let mimeTypes: [String: String] = [
            // Images
            "jpg": "image/jpeg",
            "jpeg": "image/jpeg",
            "png": "image/png",
            "gif": "image/gif",
            "bmp": "image/bmp",
            "webp": "image/webp",
            "heic": "image/heic",
            
            // Videos
            "mp4": "video/mp4",
            "mov": "video/quicktime",
            "avi": "video/x-msvideo",
            "mkv": "video/x-matroska",
            "m4v": "video/x-m4v",
            
            // Audio
            "mp3": "audio/mpeg",
            "m4a": "audio/mp4",
            "wav": "audio/wav",
            "aac": "audio/aac",
            
            // Documents
            "pdf": "application/pdf",
            "doc": "application/msword",
            "docx": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            "xls": "application/vnd.ms-excel",
            "xlsx": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            "ppt": "application/vnd.ms-powerpoint",
            "pptx": "application/vnd.openxmlformats-officedocument.presentationml.presentation",
            
            // Archives
            "zip": "application/zip",
            "rar": "application/x-rar-compressed",
            "7z": "application/x-7z-compressed",
            
            // Text
            "txt": "text/plain",
            "html": "text/html",
            "json": "application/json",
            "xml": "application/xml"
        ]
        
        return mimeTypes[ext]
    }
    
    static func getFileSize(at url: URL) -> Int64? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let size = attributes[.size] as? NSNumber {
                return size.int64Value
            }
        } catch {
            print("Error getting file size: \(error)")
        }
        return nil
    }
    
    static func formatFileSize(bytes: Int64) -> String {
        let kb = Double(bytes) / 1024.0
        let mb = kb / 1024.0
        let gb = mb / 1024.0
        
        if gb >= 1 {
            return String(format: "%.2f GB", gb)
        } else if mb >= 1 {
            return String(format: "%.2f MB", mb)
        } else if kb >= 1 {
            return String(format: "%.2f KB", kb)
        } else {
            return "\(bytes) B"
        }
    }
    
    // MARK: - Thumbnail Generation
    
    static func generateImageThumbnail(from url: URL, size: Int) -> String? {
        guard let image = UIImage(contentsOfFile: url.path) else {
            return nil
        }
        
        // Calculate thumbnail size
        let targetSize = CGSize(width: size, height: size)
        let scaledSize = calculateScaledSize(
            originalSize: image.size,
            targetSize: targetSize
        )
        
        // Create thumbnail
        let renderer = UIGraphicsImageRenderer(size: scaledSize)
        let thumbnail = renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: scaledSize))
        }
        
        // Save thumbnail
        return saveThumbnail(image: thumbnail, prefix: "thumb_img")
    }
    
    static func generateVideoThumbnail(from url: URL, size: Int) -> String? {
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        // Set maximum size
        imageGenerator.maximumSize = CGSize(width: size, height: size)
        
        do {
            let time = CMTime(seconds: 1.0, preferredTimescale: 600)
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            let thumbnail = UIImage(cgImage: cgImage)
            
            // Save thumbnail
            return saveThumbnail(image: thumbnail, prefix: "thumb_video")
        } catch {
            print("Error generating video thumbnail: \(error)")
            return nil
        }
    }
    
    // MARK: - Helper Methods
    
    private static func calculateScaledSize(
        originalSize: CGSize,
        targetSize: CGSize
    ) -> CGSize {
        let widthRatio = targetSize.width / originalSize.width
        let heightRatio = targetSize.height / originalSize.height
        let scaleFactor = min(widthRatio, heightRatio)
        
        return CGSize(
            width: originalSize.width * scaleFactor,
            height: originalSize.height * scaleFactor
        )
    }
    
    private static func saveThumbnail(image: UIImage, prefix: String) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.85) else {
            return nil
        }
        
        let fileName = "\(prefix)_\(Date().timeIntervalSince1970).jpg"
        let cacheDir = FileManager.default.temporaryDirectory
        let fileURL = cacheDir.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            return fileURL.path
        } catch {
            print("Error saving thumbnail: \(error)")
            return nil
        }
    }
    
    // MARK: - File Operations
    
    static func copyToCache(from url: URL) -> String? {
        let fileName = url.lastPathComponent
        let cacheDir = FileManager.default.temporaryDirectory
        let destinationURL = cacheDir.appendingPathComponent(fileName)
        
        do {
            // Remove if exists
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            // Copy file
            try FileManager.default.copyItem(at: url, to: destinationURL)
            return destinationURL.path
        } catch {
            print("Error copying file: \(error)")
            return nil
        }
    }
}
