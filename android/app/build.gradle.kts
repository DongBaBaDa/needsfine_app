plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// 자바 유틸리티 임포트
import java.util.Properties
        import java.io.FileInputStream

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { stream ->
        localProperties.load(stream)
    }
}

val flutterVersionCode = localProperties.getProperty("flutter.versionCode") ?: "1"
val flutterVersionName = localProperties.getProperty("flutter.versionName") ?: "1.0"

android {
    // ✅ [수정 1] 패키지 이름 일치시키기 (example 제거)
    namespace = "com.needsfine.needsfine_app"

    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    sourceSets {
        getByName("main").java.srcDirs("src/main/kotlin")
    }

    defaultConfig {
        // ✅ [수정 2] Application ID도 일치시키기
        applicationId = "com.needsfine.needsfine_app"

        // ✅ [수정 3] 네이버 지도 SDK는 최소 21 이상 필요합니다.
        // (flutter.minSdkVersion은 보통 16이나 19라서 충돌 날 수 있음)
        minSdk = flutter.minSdkVersion

        targetSdk = flutter.targetSdkVersion
        versionCode = flutterVersionCode.toInt()
        versionName = flutterVersionName
    }

    // ⭐ 기존 서명 설정 유지
    signingConfigs {
        create("release") {
            keyAlias = "upload"
            keyPassword = "니즈파인2953"
            storeFile = file("c:/Users/a/upload-keystore.jks")
            storePassword = "니즈파인2953"
        }
    }

    buildTypes {
        getByName("release") {
            // ⭐ 서명 적용
            signingConfig = signingConfigs.getByName("release")

            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}
