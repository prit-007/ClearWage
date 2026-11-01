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

    // file_picker 11.0.3 skips applying the Kotlin Gradle Plugin when built
    // with AGP 9+ (it expects AGP's built-in Kotlin), and the Flutter tool's
    // KGP auto-application misses it because its build script mentions KGP.
    // Apply it here so its Kotlin sources are compiled.
    if (name == "file_picker") {
        pluginManager.apply("org.jetbrains.kotlin.android")
    }

    // Align Kotlin JVM target with Java (17) to avoid
    // "Inconsistent JVM-target compatibility" errors in CI Android builds.
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
