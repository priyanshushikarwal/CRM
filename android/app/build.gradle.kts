plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.dooninfra.dooninfra_app"
    compileSdk = flutter.compileSdkVersion
    buildToolsVersion = "35.0.0"
    ndkVersion = flutter.ndkVersion
    flavorDimensions += "app"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.dooninfra.dooninfra_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    productFlavors {
        create("full") {
            dimension = "app"
            resValue("string", "app_name", "DoonInfra Solar Manager")
        }
        create("inventory") {
            dimension = "app"
            applicationIdSuffix = ".inventory"
            versionNameSuffix = "-inventory"
            resValue("string", "app_name", "DoonInfra Inventory")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
