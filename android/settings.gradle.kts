pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
}

include(":app")

// Workaround 1: AGP 8.x requires namespace in all library modules.
// isar_flutter_libs 3.1.0+1 omits it. CI also patches the pub-cache copy
// directly (namespace in build.gradle + removes package from manifest), so
// this afterEvaluate block is a safety net for other unlisted libraries.
//
// Workaround 2: Kotlin 2.1+ removed support for languageVersion 1.6.
// sentry_flutter 8.x sets 1.6 — bump any sub-1.8 language/api version.
gradle.allprojects {
    afterEvaluate {
        extensions.findByType<com.android.build.gradle.LibraryExtension>()?.let { lib ->
            if (lib.namespace.isNullOrEmpty()) {
                lib.namespace = project.name.replace("-", "_")
            }
        }

        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinJvmCompile>().configureEach {
            compilerOptions {
                val minVersion = org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_1_8
                val lv = languageVersion.orNull
                if (lv == null || lv < minVersion) {
                    languageVersion.set(minVersion)
                    apiVersion.set(minVersion)
                }
            }
        }
    }
}
