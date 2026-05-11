plugins {
    id("com.android.library")
    id("kotlin-android")
}

android {
    compileSdk = 35

    defaultConfig {
        targetSdk = 35
        minSdk = 23
        ndk {
            abiFilters.addAll(listOf("armeabi-v7a", "arm64-v8a", "x86", "x86_64"))
        }
        multiDexEnabled = true
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android.txt"),
                "proguard-rules.txt"
            )
        }
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/java", "java")
            jniLibs.srcDirs("src/main/jniLibs")
        }
    }

    packaging {
        resources {
            excludes += "META-INF/DEPENDENCIES"
        }
    }
    namespace = "com.undatech.remoteClientLib"
    /*
    externalNativeBuild {
        ndkBuild {
            path("jni/Application.mk")
            path("jni/Android.mk")
        }
    }
    */
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }
}

tasks.all {
    if (name.startsWith("compile") && name.endsWith("Ndk")) {
        enabled = false
    }
}

dependencies {
    api("androidx.multidex:multidex:2.0.1")
    implementation("androidx.appcompat:appcompat:1.7.1")
    implementation("org.apache.httpcomponents:httpcore:4.4.10")
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk7:1.9.22")
    implementation("commons-validator:commons-validator:1.7")
}
