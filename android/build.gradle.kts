// Top-level build file where you can add configuration options common to all sub-projects/modules.
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.9.1")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.22")
    }
}

allprojects {
    repositories {
        mavenLocal()
        mavenCentral()
        google()
    }
}

extra["toolsVersion"] = "35.0.0"
extra["compileApi"] = 35
extra["targetApi"] = 35
extra["minApi"] = 23

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
