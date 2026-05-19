import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "io.github.normalllll.yande_gui"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "io.github.normalllll.yande_gui"
        minSdk = 26
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    packagingOptions {
        dex {
            useLegacyPackaging = true
        }
        jniLibs {
            useLegacyPackaging = true
        }
    }

    val keystoreProperties = Properties()
    val keystorePropertiesFile = rootProject.file("key.properties")
    if (keystorePropertiesFile.exists()) {
        keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
    }

    fun signingProperty(name: String): String? {
        return (keystoreProperties.getProperty(name) ?: System.getenv(name))
            ?: if (project.hasProperty(name)) project.property(name).toString() else null
    }

    signingConfigs {
        create("release") {
            val keystoreFile = signingProperty("KEYSTORE_FILE")
            val keystorePassword = signingProperty("KEYSTORE_PASSWORD")
            val alias = signingProperty("KEY_ALIAS")
            val keyPassword = signingProperty("KEY_PASSWORD")

            if (
                keystoreFile.isNullOrBlank() ||
                    keystorePassword.isNullOrBlank() ||
                    alias.isNullOrBlank() ||
                    keyPassword.isNullOrBlank()
            ) {
                throw GradleException(
                    "Missing release signing config. Create android/key.properties or set KEYSTORE_FILE, KEYSTORE_PASSWORD, KEY_ALIAS, and KEY_PASSWORD.",
                )
            }

            storeFile = file(keystoreFile)
            storePassword = keystorePassword
            keyAlias = alias
            this.keyPassword = keyPassword
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

}

flutter {
    source = "../.."
}
