package com.example.makking_app

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.InputStreamReader

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
        try {
            val processBuilder = ProcessBuilder("/data/user/0/com.example.makking_app/files/ffmpeg", *command.split(" ").toTypedArray())
            processBuilder.redirectErrorStream(true)
            val process = processBuilder.start()
            val reader = BufferedReader(InputStreamReader(process.inputStream))
            var line: String?
            while (reader.readLine().also { line = it } != null) {
                println(line)
            }
            process.waitFor()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
