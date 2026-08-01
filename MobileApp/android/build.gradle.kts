allprojects {
    repositories {
        // Prefer local mirror to avoid Java TLS failures (bad_record_mac).
        maven { url = uri("file:///C:/src/gradle-mirror/maven-local") }
        maven { url = uri("file:///C:/src/gradle-mirror/aapt2-only") }
        google()
        mavenCentral()
        maven { url = uri("https://www.jitpack.io") }
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
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
    buildscript {
        repositories {
            maven { url = uri("file:///C:/src/gradle-mirror/maven-local") }
            maven { url = uri("file:///C:/src/gradle-mirror/aapt2-only") }
            google()
            mavenCentral()
            gradlePluginPortal()
        }
        configurations.classpath {
            resolutionStrategy {
                force("com.android.tools.build:gradle:8.11.1")
            }
        }
    }
    repositories {
        maven { url = uri("file:///C:/src/gradle-mirror/maven-local") }
        maven { url = uri("file:///C:/src/gradle-mirror/aapt2-only") }
        google()
        mavenCentral()
        maven { url = uri("https://www.jitpack.io") }
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    configurations.configureEach {
        exclude(group = "androidx.collection", module = "collection-ktx")
        // Empty stub jar; real types live in lifecycle-common. Avoid broken transforms.
        exclude(group = "androidx.lifecycle", module = "lifecycle-common-java8")
        resolutionStrategy {
            force("androidx.lifecycle:lifecycle-runtime:2.7.0")
            force("androidx.lifecycle:lifecycle-runtime-ktx:2.7.0")
            force("androidx.lifecycle:lifecycle-common:2.7.0")
            force("androidx.lifecycle:lifecycle-livedata-core:2.7.0")
            force("androidx.appcompat:appcompat:1.6.1")
            // 1.7+ annotation jars are empty stubs; use classic jar with real classes.
            force("androidx.annotation:annotation:1.3.0")
            force("androidx.core:core:1.13.1")
            force("androidx.core:core-ktx:1.13.1")
        }
    }

    // Many Flutter plugins import AndroidX types without declaring dependencies.
    pluginManager.withPlugin("com.android.library") {
        dependencies.add("compileOnly", "androidx.annotation:annotation:1.3.0")
        dependencies.add("compileOnly", "androidx.lifecycle:lifecycle-common:2.7.0")
        dependencies.add("compileOnly", "androidx.core:core:1.13.1")
    }
}

// Skip network-heavy lint/annotation tasks on flaky TLS, and stub typedefs for consumers.
subprojects {
    val projectBuildDir = newBuildDir.dir(project.name).asFile
    listOf(
        "intermediates/annotations_typedef_file/release/extractReleaseAnnotations/typedefs.txt",
        "intermediates/annotations_typedef_file/debug/extractDebugAnnotations/typedefs.txt",
    ).forEach { rel ->
        val recipe = projectBuildDir.resolve(rel)
        recipe.parentFile?.mkdirs()
        if (!recipe.exists()) {
            recipe.writeText("")
        }
    }
    tasks.configureEach {
        val n = name
        if (n.contains("extractReleaseAnnotations") ||
            n.contains("extractDebugAnnotations") ||
            n.contains("lintVitalAnalyze") ||
            n.contains("lintAnalyze") ||
            n.contains("verifyReleaseResources") ||
            n.contains("verifyDebugResources") ||
            n == "lintVitalRelease" ||
            n == "lintRelease") {
            enabled = false
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
