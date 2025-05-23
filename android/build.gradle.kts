buildscript {
    repositories {
        google()   // ✅ Add Google repository
        mavenCentral()  // ✅ Add Maven Central repository
        maven("https://storage.googleapis.com/download.flutter.io")
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.2") // ✅ Google Services Plugin
        classpath("com.android.tools.build:gradle:8.9.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.22")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
        maven("https://storage.googleapis.com/download.flutter.io")
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
