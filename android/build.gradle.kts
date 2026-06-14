import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile
import org.gradle.api.tasks.compile.JavaCompile

fun String.toKotlinJvmTarget(): JvmTarget =
    when (this) {
        "1.8", "8" -> JvmTarget.JVM_1_8
        "11" -> JvmTarget.JVM_11
        "17" -> JvmTarget.JVM_17
        "21" -> JvmTarget.JVM_21
        else -> JvmTarget.JVM_11
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
    tasks.withType<KotlinCompile>().configureEach {
        val javaCompileTaskName = name.replace("Kotlin", "JavaWithJavac")

        compilerOptions {
            jvmTarget.set(
                project.provider {
                    (project.tasks.findByName(javaCompileTaskName) as? JavaCompile)
                        ?.targetCompatibility
                        ?.toKotlinJvmTarget() ?: JvmTarget.JVM_11
                }
            )
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
