plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.restaurantapp"
    compileSdk = 34

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
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
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            isMinifyEnabled = false
            isShrinkResources = false
            isDebuggable = true
        }
    }

    packaging {
        pickFirst.addAll(listOf(
            "**/libc++_shared.so",
            "**/libjsc.so"
        ))
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