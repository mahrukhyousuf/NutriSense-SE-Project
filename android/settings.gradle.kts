pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    // Include Flutter's gradle tools for building Flutter apps.
    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    // Ensure repositories are set for plugin resolution.
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    // Flutter plugin loader
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    
    // Android plugin version compatibility
    id("com.android.application") version "8.7.0" apply false
    
    // Kotlin plugin version, make sure it's compatible with your setup
    id("org.jetbrains.kotlin.android") version "2.1.20" apply false
}

include(":app")
