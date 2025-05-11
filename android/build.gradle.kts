buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        // Correct classpath declaration in Kotlin DSL
        classpath("com.android.tools.build:gradle:7.0.4")  // or the latest stable version
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

