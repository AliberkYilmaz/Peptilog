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

// Workaround: AGP 8.x requires namespace in all library modules.
// isar_flutter_libs 3.1.0+1 predates this requirement and omits namespace.
// Workaround: Kotlin 2.1+ removed language version 1.6; sentry_flutter 8.x
// still declares it. Bump any sub-1.8 language/api version to 1.8.
gradle.allprojects {
    afterEvaluate {
        val lib = extensions.findByType<com.android.build.gradle.LibraryExtension>()
        if (lib != null && lib.namespace == null) {
            lib.namespace = project.name.replace("-", "_")
        }

        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinJvmCompile>().configureEach {
            val lv = kotlinOptions.languageVersion
            if (lv != null && lv < "1.8") {
                kotlinOptions.languageVersion = "1.8"
                kotlinOptions.apiVersion = "1.8"
            }
        }
    }
}
