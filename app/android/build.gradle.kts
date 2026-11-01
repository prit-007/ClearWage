buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.2")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    project.evaluationDependsOn(":app")
}
// Align Kotlin JVM target with Java (17) using freeCompilerArgs to avoid
// "Inconsistent JVM-target compatibility" errors in CI Android builds.
tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>()
    .configureEach {
        freeCompilerArgs.add("-jvm-target")
        freeCompilerArgs.add("17")
    }

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
