plugins {
    id("com.android.library")
}

android {
    compileSdk = 35

    defaultConfig {
        minSdk = 21
        targetSdk = 35
        vectorDrawables.useSupportLibrary = true
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android.txt"),
                "proguard-rules.txt"
            )
        }
        debug {
            isJniDebuggable = true
            isRenderscriptDebuggable = true
        }
    }
    namespace = "com.freerdp.freerdpcore"
}

dependencies {
    implementation("androidx.legacy:legacy-support-v4:1.0.0")
    implementation("androidx.vectordrawable:vectordrawable:1.1.0")
    implementation("androidx.appcompat:appcompat:1.7.1")
}
