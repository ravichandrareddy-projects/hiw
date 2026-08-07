package com.valtooy.hiw

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val LENS_CHANNEL = "com.valtooy.hiw/lens"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LENS_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "openWithGoogleLens") {
                    val path = call.argument<String>("path")
                    if (path == null) {
                        result.error("INVALID_ARG", "No path provided", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val file = File(path)
                        val uri: Uri = FileProvider.getUriForFile(
                            this,
                            "$packageName.provider",
                            file
                        )

                        // Try Google Lens directly (Google app activity)
                        val lensIntent = Intent(Intent.ACTION_VIEW).apply {
                            setDataAndType(uri, "image/*")
                            setPackage("com.google.android.googlequicksearchbox")
                            putExtra("from_voice_search", false)
                            flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or
                                    Intent.FLAG_ACTIVITY_NEW_TASK
                        }

                        try {
                            startActivity(lensIntent)
                            result.success("lens_opened")
                        } catch (e: ActivityNotFoundException) {
                            // Fallback: standard image share picker (user picks Lens)
                            val shareIntent = Intent(Intent.ACTION_SEND).apply {
                                type = "image/*"
                                putExtra(Intent.EXTRA_STREAM, uri)
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            val chooser = Intent.createChooser(shareIntent, "Open with Google Lens").apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(chooser)
                            result.success("share_opened")
                        }

                    } catch (e: Exception) {
                        result.error("LENS_ERROR", e.message, null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }
}
