package com.peptilog.app

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import java.io.File
import java.io.PrintWriter
import java.io.StringWriter

class MainActivity : FlutterActivity() {
    // DIAGNOSTIC: JVM-side catch around Flutter engine bootstrap. Catches
    // UnsatisfiedLinkError and other Errors/Exceptions thrown during native
    // library loading — these bypass the Dart try/catch entirely. Remove once
    // the root cause is identified and fixed.
    override fun onCreate(savedInstanceState: Bundle?) {
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
}
