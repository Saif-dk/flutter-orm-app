package com.example.orm_risk_assessment

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.media.MediaPlayer
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.yourapp.export/mediastore"
    private val AUDIO_CHANNEL = "orm_risk_assessment/launch_audio"
    private var mediaPlayer: MediaPlayer? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Existing downloads channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveToDownloads" -> {
                    val fileName = call.argument<String>("fileName")
                    val fileBytes = call.argument<ByteArray>("fileBytes")
                    val mimeType = call.argument<String>("mimeType")

                    if (fileName != null && fileBytes != null && mimeType != null) {
                        try {
                            val uri = saveToDownloads(fileName, fileBytes, mimeType)
                            result.success(uri?.toString() ?: "File saved successfully")
                        } catch (e: Exception) {
                            result.error("SAVE_ERROR", "Failed to save file: ${e.message}", null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENTS", "Missing required arguments", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Audio channel for play/dispose
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUDIO_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "play" -> {
                    try {
                        if (mediaPlayer == null) {
                            // Copy asset to cache dir to ensure it's available (works even if asset is compressed in APK)
                            val assetName = "assets/sounds/helicopter.mp3"
                            val outFile = java.io.File(cacheDir, "helicopter.mp3")
                            if (!outFile.exists()) {
                                this.assets.open(assetName).use { input ->
                                    outFile.outputStream().use { output ->
                                        input.copyTo(output)
                                    }
                                }
                            }
                            mediaPlayer = MediaPlayer()
                            mediaPlayer?.setDataSource(outFile.absolutePath)
                            mediaPlayer?.isLooping = false
                            mediaPlayer?.prepare()
                        }
                        mediaPlayer?.start()
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("PLAY_ERROR", "Failed to play audio: ${e.message}", null)
                    }
                }
                "dispose" -> {
                    try {
                        mediaPlayer?.stop()
                        mediaPlayer?.release()
                        mediaPlayer = null
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("DISPOSE_ERROR", "Failed to dispose audio: ${e.message}", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun saveToDownloads(fileName: String, fileBytes: ByteArray, mimeType: String): android.net.Uri? {
        val resolver = contentResolver

        // Determine the collection based on Android version
        val collection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            // Android 10+ - Use MediaStore.Downloads
            MediaStore.Downloads.EXTERNAL_CONTENT_URI
        } else {
            // Android 9 and below - Use Files collection
            MediaStore.Files.getContentUri("external")
        }

        val contentValues = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
            put(MediaStore.MediaColumns.MIME_TYPE, mimeType)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
        }

        // Insert the file into MediaStore
        val uri = resolver.insert(collection, contentValues)

        uri?.let {
            resolver.openOutputStream(it)?.use { outputStream ->
                outputStream.write(fileBytes)
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                // Clear the IS_PENDING flag to make the file visible
                contentValues.clear()
                contentValues.put(MediaStore.MediaColumns.IS_PENDING, 0)
                resolver.update(it, contentValues, null, null)
            }
        }

        return uri
    }
}