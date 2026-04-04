import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keyPropertiesFile = file("${rootDir}/key.properties")
val keyProperties = Properties()

if (keyPropertiesFile.exists()) {
    keyProperties.load(FileInputStream(keyPropertiesFile))
} else {
    throw GradleException("key.properties file not found at: ${keyPropertiesFile.absolutePath}")
}

android {
    namespace = "com.gulfamali.smartpos"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.gulfamali.smartpos"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            val storeFilePath = keyProperties.getProperty("storeFile")
            val storePass = keyProperties.getProperty("storePassword")
            val keyAliasVal = keyProperties.getProperty("keyAlias")
            val keyPass = keyProperties.getProperty("keyPassword")

            println("DEBUG: storeFilePath = $storeFilePath")
            println("DEBUG: storePass = $storePass")
            println("DEBUG: keyAlias = $keyAliasVal")
            println("DEBUG: keyPassword = $keyPass")

            storeFile = File(storeFilePath)
            storePassword = storePass
            keyAlias = keyAliasVal
            keyPassword = keyPass
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
