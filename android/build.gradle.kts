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
}

// Workaround: AGP 8.x requires namespace in all library modules.
// isar_flutter_libs 3.1.0+1 predates this requirement and omits it.
subprojects {
    afterEvaluate {
        val lib = extensions.findByType<com.android.build.gradle.LibraryExtension>()
        if (lib != null && lib.namespace == null) {
            lib.namespace = project.name.replace("-", "_")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
