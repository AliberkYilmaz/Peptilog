package com.peptilog.app

import android.content.ContentValues
import android.content.Context
import android.os.Environment
import android.provider.MediaStore
import java.io.PrintWriter
import java.io.StringWriter

// DIAGNOSTIC: catches crashes that happen before MainActivity.onCreate —
// ContentProvider auto-init failures, static initializers, etc.
// The UncaughtExceptionHandler is installed in attachBaseContext so it is
// active during ContentProvider.onCreate() calls (which run between
// attachBaseContext and Application.onCreate). Remove once root cause is fixed.
class PeptilogApplication : android.app.Application() {

    override fun attachBaseContext(base: Context?) {
        super.attachBaseContext(base)
        Thread.setDefaultUncaughtExceptionHandler { _, t ->
            writeCrashFile("UncaughtException (pre-Application.onCreate or ContentProvider)", t)
        }
    }

    override fun onCreate() {
        try {
            super.onCreate()
        } catch (t: Throwable) {
            writeCrashFile("Application.onCreate", t)
            throw t
        }
    }

    private fun writeCrashFile(stage: String, t: Throwable) {
        val sw = StringWriter()
        t.printStackTrace(PrintWriter(sw))
        val report = buildString {
            appendLine("STAGE: $stage")
            appendLine("CLASS: ${t.javaClass.name}")
            appendLine("MESSAGE: ${t.message}")
            appendLine()
            appendLine("STACK:")
            append(sw)
        }
        // App-private external storage (Android/data/com.peptilog.app/files/)
        try {
            java.io.File(getExternalFilesDir(null), "peptilog-app-crash.txt").writeText(report)
        } catch (_: Throwable) {}
        // MediaStore Downloads — visible in Samsung My Files / Files app on all OEMs (API 29+)
        try {
            val cv = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, "peptilog-app-crash.txt")
                put(MediaStore.MediaColumns.MIME_TYPE, "text/plain")
                put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
            }
            val uri = contentResolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, cv)
            uri?.let { contentResolver.openOutputStream(it)?.use { os -> os.write(report.toByteArray()) } }
        } catch (_: Throwable) {}
    }
}
