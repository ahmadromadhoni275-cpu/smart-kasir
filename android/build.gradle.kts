buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.1")
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
}

// =========================================================
// MESIN PEMAKSA: Diletakkan SEBELUM evaluasi dimulai
// =========================================================
subprojects {
    afterEvaluate {
        val ext = project.extensions.findByName("android")
        if (ext != null) {
            try {
                ext.javaClass.getMethod("setCompileSdk", Int::class.javaPrimitiveType).invoke(ext, 34)
            } catch (e: Exception) {
                try {
                    ext.javaClass.getMethod("setCompileSdkVersion", Int::class.javaPrimitiveType).invoke(ext, 34)
                } catch (e2: Exception) { }
            }
        }
    }
}

// Baris pemicu evaluasi diletakkan di paling bawah
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
