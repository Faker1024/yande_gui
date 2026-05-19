package io.github.normalllll.yande_gui


import android.content.ContentValues
import android.content.Context
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.webkit.MimeTypeMap
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL
import java.util.Locale

class ImageSaverPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "image_saver")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "saveImage" -> {
                val filePath: String = call.argument<String>("filePath") ?: run {
                    result.error("ARG", "filePath is null", null); return
                }
                val fileName: String = call.argument<String>("fileName") ?: run {
                    result.error("ARG", "fileName is null", null); return
                }

                scope.launch {
                    val ok = withContext(Dispatchers.IO) {
                        context.saveImage(filePath, fileName)
                    }
                    result.success(ok)
                }
            }

            "existImage" -> {
                val fileName: String = call.argument<String>("fileName") ?: run {
                    result.error("ARG", "fileName is null", null); return
                }

                scope.launch {
                    val ok = withContext(Dispatchers.IO) {
                        context.imageIsExist(fileName, null)
                    }
                    result.success(ok)
                }
            }

            "downloadFile" -> {
                val url: String = call.argument<String>("url") ?: run {
                    result.error("ARG", "url is null", null); return
                }
                val filePath: String = call.argument<String>("filePath") ?: run {
                    result.error("ARG", "filePath is null", null); return
                }

                scope.launch {
                    try {
                        val size = withContext(Dispatchers.IO) {
                            downloadFile(url, filePath)
                        }
                        result.success(size)
                    } catch (e: Exception) {
                        result.error("DOWNLOAD", e.message, null)
                    }
                }
            }

            else -> result.notImplemented()
        }
    }

    private suspend fun downloadFile(url: String, filePath: String): Long =
        withContext(Dispatchers.IO) {
            val targetFile = File(filePath)
            targetFile.parentFile?.mkdirs()

            val tempFile = File("$filePath.native")
            if (tempFile.exists()) tempFile.delete()

            var connection: HttpURLConnection? = null

            try {
                connection = (URL(url).openConnection() as HttpURLConnection).apply {
                    instanceFollowRedirects = true
                    connectTimeout = 20_000
                    readTimeout = 60_000
                    requestMethod = "GET"
                    setRequestProperty(
                        "User-Agent",
                        "Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36"
                    )
                    setRequestProperty(
                        "Accept",
                        "image/avif,image/webp,image/apng,image/svg+xml,image/*,video/*,*/*;q=0.8"
                    )
                    setRequestProperty("Accept-Language", "en-US,en;q=0.9")
                    setRequestProperty("Referer", "https://danbooru.donmai.us/")
                    setRequestProperty("Connection", "close")
                }

                val statusCode = connection.responseCode
                if (statusCode !in 200..299) {
                    throw IOException("Native download failed with HTTP $statusCode.")
                }

                val contentType = connection.contentType
                if (contentType.isBlockedDownloadContentType()) {
                    throw IOException(
                        "Native download returned $contentType, not a media file."
                    )
                }

                connection.inputStream.use { input ->
                    tempFile.outputStream().use { output ->
                        val firstChunk = ByteArray(512)
                        val firstRead = input.read(firstChunk)
                        if (firstRead <= 0) {
                            throw IOException("Downloaded file is empty.")
                        }

                        if (firstChunk.looksLikeHtml(firstRead)) {
                            throw IOException(
                                "Downloaded response is not an image/video file. The site may require browser verification."
                            )
                        }

                        output.write(firstChunk, 0, firstRead)
                        input.copyTo(output)
                    }
                }

                if (targetFile.exists()) targetFile.delete()
                if (!tempFile.renameTo(targetFile)) {
                    tempFile.copyTo(targetFile, overwrite = true)
                    tempFile.delete()
                }

                targetFile.length()
            } catch (e: Exception) {
                if (tempFile.exists()) tempFile.delete()
                throw e
            } finally {
                connection?.disconnect()
            }
        }

    private suspend fun Context.saveImage(filePath: String, fileName: String): Boolean =
        withContext(Dispatchers.IO) {

            val srcFile = File(filePath)
            if (!srcFile.exists()) return@withContext false

            if (imageIsExist(fileName, null)) {
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                    val old =
                        File(
                            Environment.getExternalStoragePublicDirectory(
                                Environment.DIRECTORY_PICTURES
                            ), "Yande/$fileName"
                        )
                    if (old.exists()) old.delete()
                } else {
                    val where =
                        "${MediaStore.Images.Media.RELATIVE_PATH}=? AND ${MediaStore.Images.Media.DISPLAY_NAME}=?"
                    val args = arrayOf("${Environment.DIRECTORY_PICTURES}/Yande/", fileName)
                    contentResolver.delete(
                        MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                        where,
                        args
                    )
                }
            }

            /* --------- Android 9‑ (API‑28) File I/O --------- */
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                val targetDir =
                    File(
                        Environment.getExternalStoragePublicDirectory(
                            Environment.DIRECTORY_PICTURES
                        ), "Yande"
                    )
                if (!targetDir.exists() && !targetDir.mkdirs()) return@withContext false

                val dest = File(targetDir, fileName)
                srcFile.copyTo(dest, overwrite = true)

                MediaScannerConnection.scanFile(
                    this@saveImage,
                    arrayOf(dest.absolutePath),
                    arrayOf(
                        MimeTypeMap.getSingleton()
                            .getMimeTypeFromExtension(dest.extension)
                    )
                ) { _, _ -> }

                return@withContext true
            }

            /* --------- Android 10+ (Scoped Storage) MediaStore --------- */
            val mime = MimeTypeMap.getSingleton()
                .getMimeTypeFromExtension(fileName.substringAfterLast('.', "")) ?: "image/*"

            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(MediaStore.MediaColumns.MIME_TYPE, mime)
                put(
                    MediaStore.MediaColumns.RELATIVE_PATH,
                    "${Environment.DIRECTORY_PICTURES}/Yande/"
                )
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }

            val uri = contentResolver.insert(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                values
            ) ?: return@withContext false

            try {
                contentResolver.openOutputStream(uri)?.use { out ->
                    srcFile.inputStream().use { it.copyTo(out) }
                } ?: return@withContext false


                values.clear()
                values.put(MediaStore.MediaColumns.IS_PENDING, 0)
                contentResolver.update(uri, values, null, null)
                true
            } catch (e: Exception) {
                contentResolver.delete(uri, null, null)             // rollback
                false
            }
        }


    suspend fun Context.imageIsExist(fileName: String, fileSize: Long?): Boolean =
        withContext(Dispatchers.IO) {

            /* --------- Android 9‑ (API‑28) --------- */
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                val dir = File(
                    Environment.getExternalStoragePublicDirectory(
                        Environment.DIRECTORY_PICTURES
                    ), "Yande"
                )
                val file = File(dir, fileName)
                if (!dir.exists() || !file.exists()) return@withContext false
                return@withContext fileSize?.let { file.length() == it } ?: true
            }

            /* --------- Android 10+ (Scoped Storage) --------- */
            val where =
                "${MediaStore.Images.Media.RELATIVE_PATH}=? AND ${MediaStore.Images.Media.DISPLAY_NAME}=?"
            val args = arrayOf("${Environment.DIRECTORY_PICTURES}/Yande/", fileName)

            contentResolver.query(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                arrayOf(MediaStore.Images.Media.SIZE),
                where,
                args,
                null
            )?.use { cursor ->
                if (!cursor.moveToFirst()) return@withContext false
                val size = cursor.getLong(
                    cursor.getColumnIndexOrThrow(MediaStore.Images.Media.SIZE)
                )
                return@withContext fileSize?.let { size == it } ?: true
            } ?: false
        }
}

private fun String?.isBlockedDownloadContentType(): Boolean {
    if (this == null) return false

    val mediaType = lowercase(Locale.US).substringBefore(';').trim()
    if (mediaType.startsWith("image/") ||
        mediaType.startsWith("video/") ||
        mediaType == "application/octet-stream" ||
        mediaType == "binary/octet-stream"
    ) {
        return false
    }

    return mediaType.contains("html") ||
            mediaType.startsWith("text/") ||
            mediaType.contains("json") ||
            mediaType.contains("xml")
}

private fun ByteArray.looksLikeHtml(length: Int): Boolean {
    val prefix =
        String(this, 0, length.coerceAtMost(size), Charsets.UTF_8)
            .trimStart()
            .lowercase(Locale.US)

    return prefix.startsWith("<!doctype html") ||
            prefix.startsWith("<html") ||
            prefix.startsWith("<head") ||
            prefix.startsWith("<body") ||
            prefix.startsWith("<script")
}
