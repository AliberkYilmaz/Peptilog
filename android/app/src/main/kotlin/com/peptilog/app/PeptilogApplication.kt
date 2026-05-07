package com.peptilog.app

import android.content.ContentValues
import android.content.Context
import android.os.Environment
import android.provider.MediaStore
import java.io.PrintWriter
import java.io.StringWriter

class PeptilogApplication : android.app.Application() {

    override fun attachBaseContext(base: Context?) {
        // Stage 1 — must use base directly: super hasn't been called yet so
        // this.contentResolver is null at this point.
        if (BuildConfig.DEBUG) writeStageMarker("app-stage-1-attachBase.txt", base)
        super.attachBaseContext(base)
        Thread.setDefaultUncaughtExceptionHandler { _, t ->
            writeCrashFile("UncaughtException (pre-Application.onCreate or ContentProvider)", t)
        }
    }

    override fun onCreate() {
        if (BuildConfig.DEBUG) writeStageMarker("app-stage-2-appOnCreate.txt")
        try {
            super.onCreate()
        } catch (t: Throwable) {
            writeCrashFile("Application.onCreate", t)
            throw t
        }
    }

    private fun writeStageMarker(name: String, ctx: Context? = this) {
        val ts = "stage marker @ ${java.text.SimpleDateFormat("HH:mm:ss.SSS").format(java.util.Date())}\n"
        try {
            val resolver = ctx?.contentResolver ?: return
            val cv = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, name)
                put(MediaStore.MediaColumns.MIME_TYPE, "text/plain")
                put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
            }
            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, cv)
            uri?.let { resolver.openOutputStream(it)?.use { os -> os.write(ts.toByteArray()) } }
        } catch (_: Throwable) {}
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
        try {
            java.io.File(getExternalFilesDir(null), "peptilog-app-crash.txt").writeText(report)
        } catch (_: Throwable) {}
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
