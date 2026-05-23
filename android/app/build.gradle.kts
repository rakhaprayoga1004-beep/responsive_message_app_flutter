plugins {
    id("com.android.application")
    // ✅ id("kotlin-android") - SUDAH DIHAPUS
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.responsive_message_app_flutter"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // AKTIFKAN desugaring (ini WAJIB untuk flutter_local_notifications)
        isCoreLibraryDesugaringEnabled = true
        
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    // ✅ kotlinOptions { jvmTarget = "11" } - SUDAH DIHAPUS

    defaultConfig {
        applicationId = "com.example.responsive_message_app_flutter"
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // ✅ Konfigurasi untuk fix error ekstraksi native libraries
    packagingOptions {
        jniLibs {
            useLegacyPackaging = true
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

// ✅ TAMBAHKAN BLOK KOTLIN INI (Built-in Kotlin)
kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11
    }
}

flutter {
    source = "../.."
}

dependencies {
    // WAJIB: Dependency desugaring
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}