package id.bee.sharemanual

import android.content.ContentResolver
import android.content.Intent
import android.net.Uri
import io.flutter.plugin.common.MethodChannel
import java.io.File

class ShareHandler(
    private val contentResolver: ContentResolver,
    private val cacheDir: File,
    private val methodChannel: MethodChannel?
) {
    
    private var initialShareData: HashMap<String, Any?>? = null
    
    fun handleIntent(intent: Intent?) {
        if (intent == null) return

        val action = intent.action
        val type = intent.type

        when (action) {
            Intent.ACTION_SEND -> {
                if (type != null) {
                    when {
                        type.startsWith("text/") -> handleSendText(intent)
                        else -> handleSendFile(intent, "file")
                    }
                }
            }
            Intent.ACTION_SEND_MULTIPLE -> {
                if (type != null) {
                    handleSendMultipleFiles(intent, type)
                }
            }
        }
    }
    
    fun getInitialShareData(): HashMap<String, Any?> {
        val data = initialShareData ?: hashMapOf()
        initialShareData = null
        return data
    }
    
    private fun handleSendText(intent: Intent) {
        val sharedText = intent.getStringExtra(Intent.EXTRA_TEXT)
        val sharedSubject = intent.getStringExtra(Intent.EXTRA_SUBJECT)
        
        val data = hashMapOf<String, Any?>(
            "type" to "text",
            "text" to sharedText,
            "subject" to sharedSubject,
            "files" to null
        )
        
        sendToFlutter(data)
    }
    
    private fun handleSendFile(intent: Intent, fileType: String) {
        val fileUri: Uri? = intent.getParcelableExtra(Intent.EXTRA_STREAM)
        
        if (fileUri != null) {
            val filePath = FileUtils.copyUriToCache(fileUri, cacheDir, contentResolver)
            val fileName = FileUtils.getFileName(fileUri, contentResolver)
            val fileSize = FileUtils.getFileSize(fileUri, contentResolver)
            
            val actualMimeType = FileUtils.getMimeType(fileUri, contentResolver)
            val detectedType = categorizeFileType(actualMimeType)
            
            // Generate thumbnail
            val thumbnailPath = when (detectedType) {
                "image" -> FileUtils.generateImageThumbnail(
                    fileUri, 
                    cacheDir, 
                    contentResolver,
                    512
                )
                "video" -> {
                    if (filePath != null) {
                        FileUtils.generateVideoThumbnail(filePath, cacheDir, 512)
                    } else {
                        null
                    }
                }
                else -> null
            }
            
            // Format file size dengan null check
            val sizeFormatted = fileSize?.let { FileUtils.formatFileSize(it) }
            
            val fileInfo = hashMapOf<String, Any?>(
                "path" to filePath,
                "uri" to fileUri.toString(),
                "name" to fileName,
                "type" to detectedType,
                "mimeType" to actualMimeType,
                "thumbnail" to thumbnailPath,
                "size" to fileSize,
                "sizeFormatted" to sizeFormatted
            )
            
            val data = hashMapOf<String, Any?>(
                "type" to "file",
                "text" to null,
                "files" to listOf(fileInfo)
            )
            
            sendToFlutter(data)
        }
    }
    
    private fun handleSendMultipleFiles(intent: Intent, mimeType: String) {
        val fileUris: ArrayList<Uri>? = intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM)
        
        if (fileUris != null && fileUris.isNotEmpty()) {
            val files = fileUris.mapNotNull { uri ->
                val filePath = FileUtils.copyUriToCache(uri, cacheDir, contentResolver)
                if (filePath != null) {
                    val actualMimeType = FileUtils.getMimeType(uri, contentResolver)
                    val fileType = categorizeFileType(actualMimeType)
                    val fileSize = FileUtils.getFileSize(uri, contentResolver)
                    
                    // Generate thumbnail
                    val thumbnailPath = when (fileType) {
                        "image" -> FileUtils.generateImageThumbnail(
                            uri,
                            cacheDir,
                            contentResolver,
                            512
                        )
                        "video" -> FileUtils.generateVideoThumbnail(
                            filePath,
                            cacheDir,
                            512
                        )
                        else -> null
                    }
                    
                    // Format file size dengan null check
                    val sizeFormatted = fileSize?.let { FileUtils.formatFileSize(it) }
                    
                    hashMapOf<String, Any?>(
                        "path" to filePath,
                        "uri" to uri.toString(),
                        "name" to FileUtils.getFileName(uri, contentResolver),
                        "type" to fileType,
                        "mimeType" to actualMimeType,
                        "thumbnail" to thumbnailPath,
                        "size" to fileSize,
                        "sizeFormatted" to sizeFormatted
                    )
                } else {
                    null
                }
            }
            
            val data = hashMapOf<String, Any?>(
                "type" to "files",
                "text" to null,
                "files" to files
            )
            
            sendToFlutter(data)
        }
    }
    
    private fun categorizeFileType(mimeType: String?): String {
        return when {
            mimeType == null -> "file"
            mimeType.startsWith("image/") -> "image"
            mimeType.startsWith("video/") -> "video"
            mimeType.startsWith("audio/") -> "audio"
            mimeType == "application/pdf" -> "pdf"
            mimeType == "application/msword" -> "document"
            mimeType == "application/vnd.openxmlformats-officedocument.wordprocessingml.document" -> "document"
            mimeType == "application/vnd.ms-excel" -> "spreadsheet"
            mimeType == "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" -> "spreadsheet"
            mimeType == "application/vnd.ms-powerpoint" -> "presentation"
            mimeType == "application/vnd.openxmlformats-officedocument.presentationml.presentation" -> "presentation"
            mimeType == "application/zip" -> "archive"
            mimeType == "application/x-rar-compressed" -> "archive"
            mimeType == "application/x-7z-compressed" -> "archive"
            mimeType == "application/vnd.android.package-archive" -> "apk"
            mimeType.startsWith("text/") -> "text"
            mimeType.startsWith("application/") -> "file"
            else -> "file"
        }
    }
    
    private fun sendToFlutter(data: HashMap<String, Any?>) {
        if (methodChannel != null) {
            methodChannel.invokeMethod("onShareReceived", data)
        } else {
            initialShareData = data
        }
    }
}