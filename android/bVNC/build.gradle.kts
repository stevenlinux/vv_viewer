plugins {
    id("com.android.library")
    id("kotlin-android")
}

android {
    compileSdk = 35

    defaultConfig {
        minSdk = 23
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
    }

    packaging {
        resources {
            excludes += listOf(
                "lib/armeabi/libsqlcipher.so",
                "lib/mips64/libsqlcipher.so",
                "lib/mips/libsqlcipher.so",
                "META-INF/versions/9/OSGI-INF/MANIFEST.MF"
            )
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }
    namespace = "com.undatech.remoteClientUi"
}

dependencies {
    implementation(project(":pubkeyGenerator"))
    implementation(project(":remoteClientLib"))
    // FreeRDP disabled - only needed for RDP, not SPICE
    // implementation(project(":remoteClientLib:jni:libs:deps:FreeRDP:client:Android:Studio:freeRDPCore"))
    implementation("org.bouncycastle:bctls-jdk18on:1.80")
    implementation("androidx.appcompat:appcompat:1.7.1")
    implementation("com.google.android.material:material:1.13.0")
    implementation("androidx.legacy:legacy-support-v4:1.0.0")
    implementation("androidx.vectordrawable:vectordrawable:1.1.0")
    implementation("androidx.preference:preference-ktx:1.2.0")
    implementation("androidx.sqlite:sqlite-ktx:2.2.0")
    implementation("org.yaml:snakeyaml:2.4")
    implementation("org.apache.httpcomponents:httpcore:4.4.10")
    implementation("com.github.luben:zstd-jni:1.5.7-4@aar")
    implementation("androidx.core:core-ktx:1.7.0")
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk7:1.9.22")

    implementation("com.google.android.play:review:2.0.1")
    implementation("com.google.android.play:review-ktx:2.0.1")
    implementation(project(":common"))
    implementation("com.google.android.gms:play-services-base:18.0.1")
    implementation("jcifs:jcifs:1.3.17")
}

repositories {
    google()
    mavenCentral()
}
