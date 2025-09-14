plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.restaurantapp"
    compileSdk = 34

    compileOptions {
        coreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.restaurantapp"
        minSdk = 21  // Set minimum to 21 for better compatibility
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
        multiDexEnabled = true

        // Add proguard rules for release builds
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        release {
            minifyEnabled = false
            shrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            minifyEnabled = false
            shrinkResources = false
            debuggable = true
        }
    }

    packagingOptions {
        pickFirst = mutableSetOf(
            "**/libc++_shared.so",
            "**/libjsc.so"
        )
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Core library desugaring untuk compatibility
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")

    // Multidex support
    implementation("androidx.multidex:multidex:2.0.1")

    // AndroidX core untuk compatibility
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.7.0")
}