import java.io.FileInputStream
import java.util.Properties
import org.gradle.api.GradleException

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
            if (!releaseSigningConfigured) {
                throw GradleException(
                    "Release signing is not configured. Create android/key.properties or set DRAFT_RACE_ANDROID_* env vars."
                )
            }
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
