import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties().apply {
    val propertiesFile = rootProject.file("local.properties")
    if (propertiesFile.exists()) {
        propertiesFile.inputStream().use { load(it) }
    }
}

fun quoted(value: String): String = "\"${value.replace("\\", "\\\\").replace("\"", "\\\"")}\""

val googleServicesFile = file("google-services.json")
val googleServerClientId = localProperties.getProperty("google.serverClientId", "").trim()
val naverClientId = localProperties.getProperty("naver.clientId", "")
val naverClientSecret = localProperties.getProperty("naver.clientSecret", "")
val naverClientName = localProperties.getProperty("naver.clientName", "BusETA")
val googleConfigured = true
val naverConfigured = naverClientId.isNotBlank() && naverClientSecret.isNotBlank()

if (googleServicesFile.exists()) {
    apply(plugin = "com.google.gms.google-services")
}

android {
    namespace = "com.example.mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    buildFeatures {
        buildConfig = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        buildConfigField("boolean", "GOOGLE_AUTH_CONFIGURED", googleConfigured.toString())
        buildConfigField("String", "GOOGLE_SERVER_CLIENT_ID", quoted(googleServerClientId))
        buildConfigField("boolean", "NAVER_AUTH_CONFIGURED", naverConfigured.toString())
        resValue("string", "client_id", quoted(naverClientId))
        resValue("string", "client_secret", quoted(naverClientSecret))
        resValue("string", "client_name", quoted(naverClientName))
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
