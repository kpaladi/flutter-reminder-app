plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin") // Must be after Android and Kotlin
    id("com.google.gms.google-services") // Firebase plugin
}

android {
    namespace = "com.darahaas.reminderapp"
    compileSdk = 35  // Stable version
    buildFeatures {
        buildConfig = true
    }
    defaultConfig {
        applicationId = "com.darahaas.reminderapp"
        minSdk = 26  // Better device compatibility
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a")
        }

        val senderEmail: String = System.getenv("SENDER_EMAIL") ?: ""
        val senderPassword: String = System.getenv("SENDER_PASSWORD") ?: ""
        buildConfigField("String", "SENDER_EMAIL", "\"$senderEmail\"")
        buildConfigField("String", "SENDER_PASSWORD", "\"$senderPassword\"")
    }
    buildFeatures {
        buildConfig = true
    }

//    flavorDimensions.add("default") // Simplified

/*    productFlavors {
        create("dev") {
            dimension = "default"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            resValue("string", "app_name", "ReminderApp Dev")
        }
        create("prod") {
            dimension = "default"
            resValue("string", "app_name", "ReminderApp")
        }
    }*/

    signingConfigs {
        create("release") {
            storeFile = file("key.jks")
            storePassword = System.getenv("SIGNING_STORE_PASSWORD")  // Secure handling
            keyAlias = "keyAlias"
            keyPassword = System.getenv("SIGNING_KEY_PASSWORD")  // Secure handling
        }
    }

    buildTypes {
        debug {
            isDebuggable = true
        }
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:32.7.1"))
    implementation("com.google.firebase:firebase-messaging")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.gms:google-services:4.4.2")

    implementation("androidx.work:work-runtime-ktx:2.9.0")
    implementation("androidx.core:core-ktx:1.12.0")

    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // Unit Testing
    implementation("androidx.test.ext:junit:1.1.5")
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.robolectric:robolectric:4.11.1")
    testImplementation("org.mockito:mockito-core:5.7.0")

    // Google Play Services
    implementation("com.google.android.gms:play-services-location:21.3.0")
    implementation("com.google.android.gms:play-services-basement:18.5.0")
    implementation("com.google.android.gms:play-services-auth:20.7.0")
    implementation("com.google.android.gms:play-services-base:18.5.0")

    // Email handling
    implementation("com.sun.mail:android-mail:1.6.2")
    implementation("com.sun.mail:android-activation:1.6.2")
}

// Disable running unnecessary tests automatically
tasks.withType<Test>().configureEach {
    enabled = false
}

// Flutter configuration
flutter {
    source = "../.."
}