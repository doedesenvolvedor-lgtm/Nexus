allprojects {
    repositories {
        google()
        mavenCentral()
    }
    // Ensure all Android subprojects (plugins) use at least compileSdk 34
    afterEvaluate {
        extensions.findByType(com.android.build.gradle.BaseExtension::class.java)?.apply {
            val current = compileSdkVersion?.removePrefix("android-")?.toIntOrNull() ?: 0
            if (current in 1..33) {
                compileSdkVersion(34)
            }
        }
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
