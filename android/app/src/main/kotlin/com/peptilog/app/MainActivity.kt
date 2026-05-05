package com.peptilog.app

import android.content.ContentValues
import android.os.Bundle
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import java.io.File
import java.io.PrintWriter
import java.io.StringWriter

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        writeStageMarker("app-stage-3-mainOnCreate.txt")
        try {
            super.onCreate(savedInstanceState)
        } catch (t: Throwable) {
            val sw = StringWriter()
            t.printStackTrace(PrintWriter(sw))
            val report = buildString {
                appendLine("STAGE: MainActivity.onCreate (pre-Dart JVM crash)")
                appendLine("CLASS: ${t.javaClass.name}")
                appendLine("MESSAGE: ${t.message}")
                appendLine()
                appendLine("STACK:")
                append(sw)
            }
            try {
                File(getExternalFilesDir(null), "peptilog-crash.txt").writeText(report)
            } catch (_: Exception) {
                try { File(filesDir, "peptilog-crash.txt").writeText(report) } catch (_: Exception) {}
            }
            android.widget.Toast.makeText(
                this,
                "Boot crash logged — share peptilog-crash.txt via Files app",
                android.widget.Toast.LENGTH_LONG,
            ).show()
            finish()
        }
    }

    private fun writeStageMarker(name: String) {
        val ts = "stage marker @ ${java.text.SimpleDateFormat("HH:mm:ss.SSS").format(java.util.Date())}\n"
        try {
            val cv = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, name)
                put(MediaStore.MediaColumns.MIME_TYPE, "text/plain")
                put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
            }
            val uri = contentResolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, cv)
            uri?.let { contentResolver.openOutputStream(it)?.use { os -> os.write(ts.toByteArray()) } }
        } catch (_: Throwable) {}
    }
}
