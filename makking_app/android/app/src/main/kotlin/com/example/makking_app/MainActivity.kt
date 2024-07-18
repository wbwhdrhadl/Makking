package com.example.makking_app

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.InputStreamReader
import com.arthenica.mobileffmpeg.FFmpeg
import android.util.Log
import com.arthenica.mobileffmpeg.Config.RETURN_CODE_SUCCESS
import com.arthenica.mobileffmpeg.Config.RETURN_CODE_CANCEL


class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.makking_app/ffmpeg"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "startFFmpeg") {
                val command = call.argument<String>("command")
                if (command != null) {
                    startFFmpeg(command)
                    result.success("FFmpeg started")
                } else {
                    result.error("UNAVAILABLE", "Command not available.", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun startFFmpeg(command: String) {
        FFmpeg.executeAsync(command) { _, returnCode ->
            if (returnCode == RETURN_CODE_SUCCESS) {
                Log.i("FFmpeg", "Command execution completed successfully.")
            } else if (returnCode == RETURN_CODE_CANCEL) {
                Log.i("FFmpeg", "Command execution cancelled by user.")
            } else {
                Log.i("FFmpeg", "Command execution failed with rc=$returnCode.")
            }
        }
    }
}
