package id.bee.sharemanual

import android.content.ContentResolver
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.ThumbnailUtils
import android.net.Uri
import android.provider.MediaStore
import android.provider.OpenableColumns
import android.util.Size
import java.io.File
import java.io.FileOutputStream

object FileUtils {
    
    /**
     * Get filename from URI
     */
    fun getFileName(uri: Uri, contentResolver: ContentResolver): String? {
        var fileName: String? = null
        
        // Try to get filename from content resolver
        if (uri.scheme == "content") {
            contentResolver.query(uri, null, null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    if (nameIndex >= 0) {
                        fileName = cursor.getString(nameIndex)
                    }
                }
            }
        }
        
        // Fallback to last path segment
        if (fileName == null) {
            fileName = uri.lastPathSegment
        }
        
        return fileName
    }
    
    /**
     * Copy file dari content:// URI ke cache directory
     * Return: absolute path dari file yang sudah di-copy
     */
    fun copyUriToCache(uri: Uri, cacheDir: File, contentResolver: ContentResolver): String? {
        try {
            val fileName = getFileName(uri, contentResolver) 
                ?: "shared_file_${System.currentTimeMillis()}"
            
            val file = File(cacheDir, fileName)
            
            // Copy file content
            contentResolver.openInputStream(uri)?.use { input ->
                file.outputStream().use { output ->
                    input.copyTo(output)
                }
            }
            
            return file.absolutePath
        } catch (e: Exception) {
            e.printStackTrace()
            return null
        }
    }
    
    /**
     * Get MIME type dari URI
     */
    fun getMimeType(uri: Uri, contentResolver: ContentResolver): String? {
        return if (uri.scheme == "content") {
            contentResolver.getType(uri)
        } else {
            val fileExtension = uri.path?.substringAfterLast('.', "")
            android.webkit.MimeTypeMap.getSingleton()
                .getMimeTypeFromExtension(fileExtension?.lowercase())
        }
    }
    
    /**
     * Generate thumbnail untuk image
     * Return: path ke thumbnail file
     */
    fun generateImageThumbnail(
        uri: Uri,
        cacheDir: File,
        contentResolver: ContentResolver,
        size: Int = 512
    ): String? {
        try {
            val thumbnailFile = File(cacheDir, "thumb_${System.currentTimeMillis()}.jpg")
            
            // Load dan resize image
            contentResolver.openInputStream(uri)?.use { input ->
                val originalBitmap = BitmapFactory.decodeStream(input)
                
                if (originalBitmap != null) {
                    // Calculate scaled dimensions
                    val scaleFactor = size.toFloat() / maxOf(
                        originalBitmap.width,
                        originalBitmap.height
                    )
                    
                    val scaledWidth = (originalBitmap.width * scaleFactor).toInt()
                    val scaledHeight = (originalBitmap.height * scaleFactor).toInt()
                    
                    // Create thumbnail
                    val thumbnail = Bitmap.createScaledBitmap(
                        originalBitmap,
                        scaledWidth,
                        scaledHeight,
                        true
                    )
                    
                    // Save thumbnail
                    FileOutputStream(thumbnailFile).use { out ->
                        thumbnail.compress(Bitmap.CompressFormat.JPEG, 85, out)
                    }
                    
                    // Cleanup
                    thumbnail.recycle()
                    originalBitmap.recycle()
                    
                    return thumbnailFile.absolutePath
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        
        return null
    }
    
    /**
     * Generate thumbnail untuk video
     * Return: path ke thumbnail file
     */
    fun generateVideoThumbnail(
        filePath: String,
        cacheDir: File,
        size: Int = 512
    ): String? {
        try {
            val thumbnailFile = File(cacheDir, "thumb_video_${System.currentTimeMillis()}.jpg")
            
            // Extract frame dari video (Android 10+)
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
                val thumbnail = ThumbnailUtils.createVideoThumbnail(
                    File(filePath),
                    Size(size, size),
                    null
                )
                
                if (thumbnail != null) {
                    FileOutputStream(thumbnailFile).use { out ->
                        thumbnail.compress(Bitmap.CompressFormat.JPEG, 85, out)
                    }
                    thumbnail.recycle()
                    
                    return thumbnailFile.absolutePath
                }
            } else {
                // Fallback untuk Android 9 ke bawah
                @Suppress("DEPRECATION")
                val thumbnail = ThumbnailUtils.createVideoThumbnail(
                    filePath,
                    MediaStore.Video.Thumbnails.MINI_KIND
                )
                
                if (thumbnail != null) {
                    // Resize jika perlu
                    val scaleFactor = size.toFloat() / maxOf(
                        thumbnail.width,
                        thumbnail.height
                    )
                    
                    val scaledWidth = (thumbnail.width * scaleFactor).toInt()
                    val scaledHeight = (thumbnail.height * scaleFactor).toInt()
                    
                    val resized = Bitmap.createScaledBitmap(
                        thumbnail,
                        scaledWidth,
                        scaledHeight,
                        true
                    )
                    
                    FileOutputStream(thumbnailFile).use { out ->
                        resized.compress(Bitmap.CompressFormat.JPEG, 85, out)
                    }
                    
                    resized.recycle()
                    thumbnail.recycle()
                    
                    return thumbnailFile.absolutePath
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        
        return null
    }
    
    /**
     * Get file size dalam bytes
     */
    fun getFileSize(uri: Uri, contentResolver: ContentResolver): Long? {
        try {
            if (uri.scheme == "content") {
                contentResolver.query(uri, null, null, null, null)?.use { cursor ->
                    if (cursor.moveToFirst()) {
                        val sizeIndex = cursor.getColumnIndex(OpenableColumns.SIZE)
                        if (sizeIndex >= 0) {
                            return cursor.getLong(sizeIndex)
                        }
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return null
    }
    
    /**
     * Format file size ke human readable string
     */
    fun formatFileSize(bytes: Long): String {
        val kb = bytes / 1024.0
        val mb = kb / 1024.0
        val gb = mb / 1024.0
        
        return when {
            gb >= 1 -> String.format("%.2f GB", gb)
            mb >= 1 -> String.format("%.2f MB", mb)
            kb >= 1 -> String.format("%.2f KB", kb)
            else -> "$bytes B"
        }
    }
}