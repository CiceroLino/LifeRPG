plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseStorePath = providers.environmentVariable("LIFERPG_KEYSTORE_PATH").orNull
val releaseStorePassword = providers.environmentVariable("LIFERPG_KEYSTORE_PASSWORD").orNull
val releaseKeyAlias = providers.environmentVariable("LIFERPG_KEY_ALIAS").orNull
val releaseKeyPassword = providers.environmentVariable("LIFERPG_KEY_PASSWORD").orNull
val releaseApplicationId = providers.environmentVariable("LIFERPG_APPLICATION_ID").orNull
val hasReleaseCredentials = listOf(releaseStorePath, releaseStorePassword, releaseKeyAlias, releaseKeyPassword)
    .all { !it.isNullOrBlank() }

android {
    namespace = "com.example.liferpg"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Keep the development identity; release identity must be chosen explicitly.
        applicationId = releaseApplicationId ?: "com.example.liferpg"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseCredentials) {
            create("release") {
                storeFile = file(releaseStorePath!!)
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release")
        }
    }
}

val validateReleaseCredentials = tasks.register("validateReleaseCredentials") {
    doLast {
        check(hasReleaseCredentials && !releaseApplicationId.isNullOrBlank()) {
            "Release requires LIFERPG_APPLICATION_ID, LIFERPG_KEYSTORE_PATH, " +
            "LIFERPG_KEYSTORE_PASSWORD, LIFERPG_KEY_ALIAS and LIFERPG_KEY_PASSWORD. " +
            "Use the installed application ID and signing certificate to preserve updates."
        }
    }
}
tasks.matching { it.name == "preReleaseBuild" }.configureEach {
    dependsOn(validateReleaseCredentials)
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
