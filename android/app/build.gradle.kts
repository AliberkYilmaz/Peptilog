import java.util.Base64
import java.util.Properties
import java.io.File

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// key.properties fallback for local development
val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
if (keyPropertiesFile.exists()) {
    keyPropertiesFile.inputStream().use { keyProperties.load(it) }
}

// In CI, KEYSTORE_FILE is a base64-encoded .jks written to a temp file.
// Locally, key.properties points to the file on disk.
fun resolveKeystore(): File? {
    val b64 = System.getenv("KEYSTORE_FILE")
    return if (!b64.isNullOrBlank()) {
        val tmp = File(layout.buildDirectory.asFile.get(), "signing/peptilog-release.jks")
        tmp.parentFile.mkdirs()
        tmp.writeBytes(Base64.getDecoder().decode(b64))
        tmp
    } else {
        // key.properties storeFile is relative to android/app/ (the module dir)
        keyProperties["storeFile"]?.let { file(it as String) }
    }
}

fun envOrProp(envKey: String, propKey: String): String? =
    System.getenv(envKey)?.takeIf { it.isNotBlank() }
        ?: keyProperties[propKey] as String?

android {
    namespace = "com.peptilog.app"
    compileSdk = 34
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.peptilog.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val ksFile = resolveKeystore()
            val storePass = envOrProp("KEYSTORE_PASSWORD", "storePassword")
            val alias = envOrProp("KEY_ALIAS", "keyAlias") ?: "peptilog-release"
            val keyPass = envOrProp("KEY_PASSWORD", "keyPassword") ?: storePass

            if (ksFile != null && ksFile.exists() && storePass != null) {
                storeFile = ksFile
                storePassword = storePass
                keyAlias = alias
                keyPassword = keyPass
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
