plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // 1. 주소 설정 (AndroidManifest.xml과 일치해야 함)
    namespace = "com.needsfine.needsfine_app"
    compileSdk = 34

    // 2. 이미 설치되어 있는 27 버전을 사용하도록 고정
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.needsfine.needsfine_app"
        minSdk = flutter.minSdkVersion
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
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

dependencies {
    // 추가적인 라이브러리가 필요하다면 여기에 적습니다.
}
