plugins {
    id("com.android.library")
}

android {
    compileSdk = 35

    defaultConfig {
        minSdk = 23
        targetSdk = 35
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
    packaging {
        resources {
            excludes += "META-INF/versions/9/OSGI-INF/MANIFEST.MF"
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    namespace = "com.iiordanov.pubkeygenerator"
}

dependencies {
    api("org.connectbot:sshlib:2.2.23")
    implementation("org.bouncycastle:bcprov-jdk18on:1.80")
    implementation("org.bouncycastle:bcpkix-jdk18on:1.80")
    api("net.vrallev.ecc:ecc-25519-java:1.0.3")
    api("io.moatwel.crypto:eddsa:0.8.1")
    api("net.i2p.crypto:eddsa:0.3.0")
    implementation(project(":common"))
    implementation("com.google.android.material:material:1.13.0")
}
