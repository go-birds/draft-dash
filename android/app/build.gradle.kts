import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        FileInputStream(keystorePropertiesFile).use { load(it) }
    }
}

fun propertyOrEnv(propertyName: String, envName: String): String? =
    (keystoreProperties[propertyName] as? String)?.takeIf { it.isNotBlank() }
        ?: System.getenv(envName)?.takeIf { it.isNotBlank() }

val releaseStoreFilePath = propertyOrEnv("storeFile", "DRAFT_RACE_ANDROID_STORE_FILE")
val releaseStorePassword = propertyOrEnv("storePassword", "DRAFT_RACE_ANDROID_STORE_PASSWORD")
val releaseKeyAlias = propertyOrEnv("keyAlias", "DRAFT_RACE_ANDROID_KEY_ALIAS")
val releaseKeyPassword = propertyOrEnv("keyPassword", "DRAFT_RACE_ANDROID_KEY_PASSWORD")
val releaseSigningConfigured =
    listOf(releaseStoreFilePath, releaseStorePassword, releaseKeyAlias, releaseKeyPassword)
        .all { !it.isNullOrBlank() }

android {
    namespace = "com.gobirds.draftdash"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        if (releaseSigningConfigured) {
            create("release") {
                storeFile = file(releaseStoreFilePath!!)
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    defaultConfig {
        applicationId = "com.gobirds.draftdash"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Falls back to the debug key for local release smoke tests.
            // Set android/key.properties or DRAFT_RACE_ANDROID_* for production builds.
            signingConfig =
                if (releaseSigningConfigured) signingConfigs.getByName("release")
                else signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
