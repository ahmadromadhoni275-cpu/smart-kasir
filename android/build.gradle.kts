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

subprojects {
    project.evaluationDependsOn(":app")
    
    // =========================================================
    // MESIN PEMAKSA: Memaksa semua plugin (termasuk :printing) 
    // agar menggunakan standar Android versi 34.
    // =========================================================
    afterEvaluate {
        project.extensions.findByName("android")?.let { ext ->
            try {
                // Mencoba metode versi terbaru (AGP 8+)
                ext.javaClass.getMethod("setCompileSdk", Int::class.javaPrimitiveType).invoke(ext, 34)
            } catch (e: Exception) {
                try {
                    // Mencoba metode versi lama
                    ext.javaClass.getMethod("setCompileSdkVersion", Int::class.javaPrimitiveType).invoke(ext, 34)
                } catch (e2: Exception) {
                    // Abaikan jika bukan plugin Android
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
