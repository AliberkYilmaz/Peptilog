allprojects {
    repositories {
        google()
        mavenCentral()
    }
    // Force androidx.browser to 1.8.0: the 1.9.0 release requires AGP >= 8.9.1
    // but we're using AGP 7.4.2 (required for isar_flutter_libs 3.x compat).
    configurations.all {
        resolutionStrategy.force("androidx.browser:browser:1.8.0")
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
