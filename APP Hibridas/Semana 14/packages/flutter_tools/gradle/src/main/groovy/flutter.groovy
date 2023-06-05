// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import static groovy.io.FileType.FILES

import com.android.build.OutputFile
import groovy.json.JsonSlurper
import java.nio.file.Path
import java.nio.file.Paths
import java.util.regex.Matcher
import java.util.regex.Pattern
import org.apache.tools.ant.taskdefs.condition.Os
import org.gradle.api.DefaultTask
import org.gradle.api.GradleException
import org.gradle.api.JavaVersion
import org.gradle.api.Project
import org.gradle.api.Plugin
import org.gradle.api.Task
import org.gradle.api.file.CopySpec
import org.gradle.api.file.FileCollection
import org.gradle.api.logging.LogLevel
import org.gradle.api.tasks.Copy
import org.gradle.api.tasks.InputFiles
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.Internal
import org.gradle.api.tasks.OutputDirectory
import org.gradle.api.tasks.OutputFiles
import org.gradle.api.tasks.Optional
import org.gradle.api.tasks.TaskAction
import org.gradle.api.tasks.bundling.Jar
import org.gradle.internal.os.OperatingSystem
import org.gradle.util.VersionNumber

/**
 * For apps only. Provides the flutter extension used in app/build.gradle.
 *
 * The versions specified here should match the values in
 * packages/flutter_tools/lib/src/android/gradle_utils.dart, so when bumping,
 * make sure to update the versions specified there.
 *
 * Learn more about extensions in Gradle:
 *  * https://docs.gradle.org/8.0.2/userguide/custom_plugins.html#sec:getting_input_from_the_build
*/
class FlutterExtension {
    /** Sets the compileSdkVersion used by default in Flutter app projects. */
    static int compileSdkVersion = 33

    /** Sets the minSdkVersion used by default in Flutter app projects. */
    static int minSdkVersion = 19

    /** Sets the targetSdkVersion used by default in Flutter app projects. */
    static int targetSdkVersion = 33

    /**
     * Sets the ndkVersion used by default in Flutter app projects.
     * Chosen as default version of the AGP version below as found in
     * https://developer.android.com/studio/projects/install-ndk#default-ndk-per-agp
     */
    static String ndkVersion = "23.1.7779620"

    /**
     * Specifies the relative directory to the Flutter project directory.
     * In an app project, this is ../.. since the app's build.gradle is under android/app.
     */
    String source

    /** Allows to override the target file. Otherwise, the target is lib/main.dart. */
    String target
}

// This buildscript block supplies dependencies for this file's own import
// declarations above. It exists solely for compatibility with projects that
// have not migrated to declaratively apply the Flutter Gradle Plugin;
// for those that have, FGP's `build.gradle.kts`  takes care of this.
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // When bumping, also update:
        //  * ndkVersion in FlutterExtension in packages/flutter_tools/gradle/src/main/flutter.groovy
        //  * AGP version constants in packages/flutter_tools/lib/src/android/gradle_utils.dart
        //  * AGP version in dependencies block in packages/flutter_tools/gradle/build.gradle.kts
        classpath 'com.android.tools.build:gradle:7.3.0'
    }
}

/**
 * Some apps don't set default compile options.
 * Apps can change these values in android/app/build.gradle.
 * This just ensures that default values are set.
 */
android {
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }
}

apply plugin: FlutterPlugin

class FlutterPlugin implements Plugin<Project> {
    private static final String DEFAULT_MAVEN_HOST = "https://storage.googleapis.com";

    /** The platforms that can be passed to the `--Ptarget-platform` flag. */
    private static final String PLATFORM_ARM32  = "android-arm";
    private static final String PLATFORM_ARM64  = "android-arm64";
    private static final String PLATFORM_X86    = "android-x86";
    private static final String PLATFORM_X86_64 = "android-x64";

    /** The ABI architectures supported by Flutter. */
    private static final String ARCH_ARM32      = "armeabi-v7a";
    private static final String ARCH_ARM64      = "arm64-v8a";
    private static final String ARCH_X86        = "x86";
    private static final String ARCH_X86_64     = "x86_64";

    private static final String INTERMEDIATES_DIR = "intermediates";

    /** Maps platforms to ABI architectures. */
    private static final Map PLATFORM_ARCH_MAP = [
        (PLATFORM_ARM32)    : ARCH_ARM32,
        (PLATFORM_ARM64)    : ARCH_ARM64,
        (PLATFORM_X86)      : ARCH_X86,
        (PLATFORM_X86_64)   : ARCH_X86_64,
    ]

    /**
     * The version code that gives each ABI a value.
     * For each APK variant, use the following versions to override the version of the Universal APK.
     * Otherwise, the Play Store will complain that the APK variants have the same version.
     */
    private static final Map ABI_VERSION = [
        (ARCH_ARM32)        : 1,
        (ARCH_ARM64)        : 2,
        (ARCH_X86)          : 3,
        (ARCH_X86_64)       : 4,
    ]

    /** When split is enabled, multiple APKs are generated per each ABI. */
    private static final List DEFAULT_PLATFORMS = [
        PLATFORM_ARM32,
        PLATFORM_ARM64,
        PLATFORM_X86_64,
    ]

    /**
     * The name prefix for flutter builds. This is used to identify gradle tasks
     * where we expect the flutter tool to provide any error output, and skip the
     * standard Gradle error output in the FlutterEventLogger. If you change this,
     * be sure to change any instances of this string in symbols in the code below
     * to match.
     */
    static final String FLUTTER_BUILD_PREFIX = "flutterBuild"

    private Project project
    private Map baseJar = [:]
    private File flutterRoot
    private File flutterExecutable
    private String localEngine
    private String localEngineSrcPath
    private Properties localProperties
    private String engineVersion

    /**
     * Flutter Docs Website URLs for help messages.
     */
    private final String kWebsiteDeploymentAndroidBuildConfig = 'https://docs.flutter.dev/deployment/android#reviewing-the-gradle-build-configuration'

    @Override
    void apply(Project project) {
        this.project = project

        def rootProject = project.rootProject
        if (isFlutterAppProject()) {
            rootProject.tasks.register('generateLockfiles') {
                rootProject.subprojects.each { subproject ->
                    def gradlew = (OperatingSystem.current().isWindows()) ?
                        "${rootProject.projectDir}/gradlew.bat" : "${rootProject.projectDir}/gradlew"
                    rootProject.exec {
                        workingDir rootProject.projectDir
                        executable gradlew
                        args ":${subproject.name}:dependencies", "--write-locks"
                    }
                }
            }
        }

        // Configure the Maven repository.
        String hostedRepository = System.env.FLUTTER_STORAGE_BASE_URL ?: DEFAULT_MAVEN_HOST
        String repository = useLocalEngine()
            ? project.property('local-engine-repo')
            : "$hostedRepository/download.flutter.io"
        rootProject.allprojects {
            repositories {
                maven {
                    url repository
                }
            }
        }

        project.extensions.create("flutter", FlutterExtension)
        this.addFlutterTasks(project)

        // By default, assembling APKs generates fat APKs if multiple platforms are passed.
        // Configuring split per ABI allows to generate separate APKs for each abi.
        // This is a noop when building a bundle.
        if (shouldSplitPerAbi()) {
            project.android {
                splits {
                    abi {
                        // Enables building multiple APKs per ABI.
                        enable true
                        // Resets the list of ABIs that Gradle should create APKs for to none.
                        reset()
                        // Specifies that we do not want to also generate a universal APK that includes all ABIs.
                        universalApk false
                    }
                }
            }
        }

        if (project.hasProperty('deferred-component-names')) {
            String[] componentNames = project.property('deferred-component-names').split(',').collect {":${it}"}
            project.android {
                dynamicFeatures = componentNames
            }
        }

        getTargetPlatforms().each { targetArch ->
            String abiValue = PLATFORM_ARCH_MAP[targetArch]
            project.android {
                if (shouldSplitPerAbi()) {
                    splits {
                        abi {
                            include abiValue
                        }
                    }
                }
            }
        }

        String flutterRootPath = resolveProperty("flutter.sdk", System.env.FLUTTER_ROOT)
        if (flutterRootPath == null) {
            throw new GradleException("Flutter SDK not found. Define location with flutter.sdk in the local.properties file or with a FLUTTER_ROOT environment variable.")
        }
        flutterRoot = project.file(flutterRootPath)
        if (!flutterRoot.isDirectory()) {
            throw new GradleException("flutter.sdk must point to the Flutter SDK directory")
        }

        engineVersion = useLocalEngine()
            ? "+" // Match any version since there's only one.
            : "1.0.0-" + Paths.get(flutterRoot.absolutePath, "bin", "internal", "engine.version").toFile().text.trim()

        String flutterExecutableName = Os.isFamily(Os.FAMILY_WINDOWS) ? "flutter.bat" : "flutter"
        flutterExecutable = Paths.get(flutterRoot.absolutePath, "bin", flutterExecutableName).toFile();

        if (project.hasProperty("multidex-enabled") &&
            project.property("multidex-enabled").toBoolean()) {
            String flutterMultidexKeepfile = Paths.get(flutterRoot.absolutePath, "packages", "flutter_tools",
                "gradle", "flutter_multidex_keepfile.txt")
            project.android {
                buildTypes {
                    release {
                        multiDexKeepFile project.file(flutterMultidexKeepfile)
                    }
                }
            }
            project.dependencies {
                implementation "androidx.multidex:multidex:2.0.1"
            }
        }
        // Use Kotlin DSL to handle baseApplicationName logic due to Groovy dynamic dispatch bug.
        project.apply from: Paths.get(flutterRoot.absolutePath, "packages", "flutter_tools", "gradle", "src", "main", "kotlin", "flutter.gradle.kts")

        String flutterProguardRules = Paths.get(flutterRoot.absolutePath, "packages", "flutter_tools",
                "gradle", "flutter_proguard_rules.pro")
        project.android.buildTypes {
            // Add profile build type.
            profile {
                initWith debug
                if (it.hasProperty("matchingFallbacks")) {
                    matchingFallbacks = ["debug", "release"]
                }
            }
            // TODO(garyq): Shrinking is only false for multi apk split aot builds, where shrinking is not allowed yet.
            // This limitation has been removed experimentally in gradle plugin version 4.2, so we can remove
            // this check when we upgrade to 4.2+ gradle. Currently, deferred components apps may see
            // increased app size due to this.
            if (shouldShrinkResources(project)) {
                release {
                    // Enables code shrinking, obfuscation, and optimization for only
                    // your project's release build type.
                    minifyEnabled true
                    // Enables resource shrinking, which is performed by the Android Gradle plugin.
                    // The resource shrinker can't be used for libraries.
                    shrinkResources isBuiltAsApp(project)
                    // Fallback to `android/app/proguard-rules.pro`.
                    // This way, custom Proguard rules can be configured as needed.
                    proguardFiles project.android.getDefaultProguardFile("proguard-android.txt"), flutterProguardRules, "proguard-rules.pro"
                }
            }
        }

        if (useLocalEngine()) {
            // This is required to pass the local engine to flutter build aot.
            String engineOutPath = project.property('local-engine-out')
            File engineOut = project.file(engineOutPath)
            if (!engineOut.isDirectory()) {
                throw new GradleException('local-engine-out must point to a local engine build')
            }
            localEngine = engineOut.name
            localEngineSrcPath = engineOut.parentFile.parent
        }
        project.android.buildTypes.all this.&addFlutterDependencies
    }

    private static Boolean shouldShrinkResources(Project project) {
        if (project.hasProperty("shrink")) {
            return project.property("shrink").toBoolean()
        }
        return true
    }

    /**
     * Adds the dependencies required by the Flutter project.
     * This includes:
     *    1. The embedding
     *    2. libflutter.so
     */
    void addFlutterDependencies(buildType) {
        String flutterBuildMode = buildModeFor(buildType)
        if (!supportsBuildMode(flutterBuildMode)) {
            return
        }
        // The embedding is set as an API dependency in a Flutter plugin.
        // Therefore, don't make the app project depend on the embedding if there are Flutter
        // plugins.
        // This prevents duplicated classes when using custom build types. That is, a custom build
        // type like profile is used, and the plugin and app projects have API dependencies on the
        // embedding.
        if (!isFlutterAppProject() || getPluginList().size() == 0) {
            addApiDependencies(project, buildType.name,
                    "io.flutter:flutter_embedding_$flutterBuildMode:$engineVersion")
        }
        List<String> platforms = getTargetPlatforms().collect()
        // Debug mode includes x86 and x64, which are commonly used in emulators.
        if (flutterBuildMode == "debug" && !useLocalEngine()) {
            platforms.add("android-x86")
            platforms.add("android-x64")
        }
        platforms.each { platform ->
            String arch = PLATFORM_ARCH_MAP[platform].replace("-", "_")
            // Add the `libflutter.so` dependency.
            addApiDependencies(project, buildType.name,
                    "io.flutter:${arch}_$flutterBuildMode:$engineVersion")
        }
    }

    /**
     * Returns the directory where the plugins are built.
     */
    private File getPluginBuildDir() {
        // Module projects specify this flag to include plugins in the same repo as the module project.
        if (project.ext.has("pluginBuildDir")) {
            return project.ext.get("pluginBuildDir")
        }
        return project.buildDir
    }

    /**
     * Configures the Flutter plugin dependencies.
     *
     * The plugins are added to pubspec.yaml. Then, upon running `flutter pub get`,
     * the tool generates a `.flutter-plugins` file, which contains a 1:1 map to each plugin location.
     * Finally, the project's `settings.gradle` loads each plugin's android directory as a subproject.
     */
    private void configurePlugins() {
        getPluginList().each this.&configurePluginProject
        getPluginDependencies().each this.&configurePluginDependencies
    }

    /** Adds the plugin project dependency to the app project. */
    private void configurePluginProject(String pluginName, String _) {
        Project pluginProject = project.rootProject.findProject(":$pluginName")
        if (pluginProject == null) {
            project.logger.error("Plugin project :$pluginName not found. Please update settings.gradle.")
            return
        }
        // Add plugin dependency to the app project.
        project.dependencies {
            api pluginProject
        }
        Closure addEmbeddingDependencyToPlugin = { buildType ->
            String flutterBuildMode = buildModeFor(buildType)
            // In AGP 3.5, the embedding must be added as an API implementation,
            // so java8 features are desugared against the runtime classpath.
            // For more, see https://github.com/flutter/flutter/issues/40126
            if (!supportsBuildMode(flutterBuildMode)) {
                return
            }
            if (!pluginProject.hasProperty('android')) {
                return
            }
            // Copy build types from the app to the plugin.
            // This allows to build apps with plugins and custom build types or flavors.
            pluginProject.android.buildTypes {
                "${buildType.name}" {}
            }
            // The embedding is API dependency of the plugin, so the AGP is able to desugar
            // default method implementations when the interface is implemented by a plugin.
            //
            // See https://issuetracker.google.com/139821726, and
            // https://github.com/flutter/flutter/issues/72185 for more details.
            addApiDependencies(
              pluginProject,
              buildType.name,
              "io.flutter:flutter_embedding_$flutterBuildMode:$engineVersion"
            )
        }

        // Wait until the Android plugin loaded.
        pluginProject.afterEvaluate {
            // Checks if there is a mismatch between the plugin compileSdkVersion and the project compileSdkVersion.
            if (pluginProject.android.compileSdkVersion > project.android.compileSdkVersion) {
                project.logger.quiet("Warning: The plugin ${pluginName} requires Android SDK version ${pluginProject.android.compileSdkVersion.substring(8)}.")
                project.logger.quiet("For more information about build configuration, see $kWebsiteDeploymentAndroidBuildConfig.")
            }

            project.android.buildTypes.all addEmbeddingDependencyToPlugin
        }
    }

    /**
     * Compares semantic versions ignoring labels.
     *
     * If the versions are equal (ignoring labels), returns one of the two strings arbitrarily.
     *
     * If minor or patch are omitted (non-conformant to semantic versioning), they are considered zero.
     * If the provided versions in both are equal, the longest version string is returned.
     * For example, "2.8.0" vs "2.8" will always consider "2.8.0" to be the most recent version.
     */
    static String mostRecentSemanticVersion(String version1, String version2) {
        List version1Tokenized = version1.tokenize('.')
        List version2Tokenized = version2.tokenize('.')
        def version1numTokens = version1Tokenized.size()
        def version2numTokens = version2Tokenized.size()
        def minNumTokens = Math.min(version1numTokens, version2numTokens)
        for (int i = 0; i < minNumTokens; i++) {
            def num1 = version1Tokenized[i].toInteger()
            def num2 = version2Tokenized[i].toInteger()
            if (num1 > num2) {
                return version1
            }
            if (num2 > num1) {
                return version2
            }
        }
        if (version1numTokens > version2numTokens) {
            return version1
        }
        return version2
    }

    /** Prints error message and fix for any plugin compileSdkVersion or ndkVersion that are higher than the project. */
    private void detectLowCompileSdkVersionOrNdkVersion() {
        project.afterEvaluate {
            int projectCompileSdkVersion = Integer.MAX_VALUE // Default to int max if using a preview version to skip the sdk check.
            if (project.android.compileSdkVersion.substring(8).isInteger()) { // Stable versions use ints, legacy preview uses string.
                projectCompileSdkVersion = project.android.compileSdkVersion.substring(8) as int
            }
            int maxPluginCompileSdkVersion = projectCompileSdkVersion
            String ndkVersionIfUnspecified = "21.1.6352462" /* The default for AGP 4.1.0 used in old templates. */
            String projectNdkVersion = project.android.ndkVersion ?: ndkVersionIfUnspecified
            String maxPluginNdkVersion = projectNdkVersion
            int numProcessedPlugins = getPluginList().size()

            getPluginList().each { plugin ->
                Project pluginProject = project.rootProject.findProject(plugin.key)
                pluginProject.afterEvaluate {
                    int pluginCompileSdkVersion = pluginProject.android.compileSdkVersion.substring(8) as int
                    maxPluginCompileSdkVersion = Math.max(pluginCompileSdkVersion, maxPluginCompileSdkVersion)
                    String pluginNdkVersion = pluginProject.android.ndkVersion ?: ndkVersionIfUnspecified
                    maxPluginNdkVersion = mostRecentSemanticVersion(pluginNdkVersion, maxPluginNdkVersion)

                    numProcessedPlugins--
                    if (numProcessedPlugins == 0) {
                        if (maxPluginCompileSdkVersion > projectCompileSdkVersion) {
                            project.logger.error("One or more plugins require a higher Android SDK version.\nFix this issue by adding the following to ${project.projectDir}${File.separator}build.gradle:\nandroid {\n  compileSdkVersion ${maxPluginCompileSdkVersion}\n  ...\n}\n")
                        }
                        if (maxPluginNdkVersion != projectNdkVersion) {
                            project.logger.error("One or more plugins require a higher Android NDK version.\nFix this issue by adding the following to ${project.projectDir}${File.separator}build.gradle:\nandroid {\n  ndkVersion \"${maxPluginNdkVersion}\"\n  ...\n}\n")
                        }
                    }
                }
            }
        }
    }

    /**
     * Returns `true` if the given path contains an `android/build.gradle` file.
     */
    private Boolean doesSupportAndroidPlatform(String path) {
        File editableAndroidProject = new File(path, 'android' + File.separator + 'build.gradle')
        return editableAndroidProject.exists()
    }

    /**
     * Add the dependencies on other plugin projects to the plugin project.
     * A plugin A can depend on plugin B. As a result, this dependency must be surfaced by
     * making the Gradle plugin project A depend on the Gradle plugin project B.
     */
    private void configurePluginDependencies(Object dependencyObject) {
        assert dependencyObject.name instanceof String
        Project pluginProject = project.rootProject.findProject(":${dependencyObject.name}")
        if (pluginProject == null ||
            !doesSupportAndroidPlatform(pluginProject.projectDir.parentFile.path)) {
            return
        }
        assert dependencyObject.dependencies instanceof List
        dependencyObject.dependencies.each { pluginDependencyName ->
            assert pluginDependencyName instanceof String
            if (pluginDependencyName.empty) {
                return
            }
            Project dependencyProject = project.rootProject.findProject(":$pluginDependencyName")
            if (dependencyProject == null ||
                !doesSupportAndroidPlatform(dependencyProject.projectDir.parentFile.path)) {
                return
            }
            // Wait for the Android plugin to load and add the dependency to the plugin project.
            pluginProject.afterEvaluate {
                pluginProject.dependencies {
                    implementation dependencyProject
                }
            }
        }
    }

    private Properties getPluginList() {
        File pluginsFile = new File(project.projectDir.parentFile.parentFile, '.flutter-plugins')
        Properties allPlugins = readPropertiesIfExist(pluginsFile)
        Properties androidPlugins = new Properties()
        allPlugins.each { name, path ->
            if (doesSupportAndroidPlatform(path)) {
                androidPlugins.setProperty(name, path)
            }
            // TODO(amirh): log an error if this plugin was specified to be an Android
            // plugin according to the new schema, and was missing a build.gradle file.
            // https://github.com/flutter/flutter/issues/40784
        }
        return androidPlugins
    }

    /** Gets the plugins dependencies from `.flutter-plugins-dependencies`. */
    private List getPluginDependencies() {
        // Consider a `.flutter-plugins-dependencies` file with the following content:
        // {
        //     "dependencyGraph": [
        //       {
        //         "name": "plugin-a",
        //         "dependencies": ["plugin-b","plugin-c"]
        //       },
        //       {
        //         "name": "plugin-b",
        //         "dependencies": ["plugin-c"]
        //       },
        //       {
        //         "name": "plugin-c",
        //         "dependencies": []'
        //       }
        //     ]
        //  }
        //
        // This means, `plugin-a` depends on `plugin-b` and `plugin-c`.
        // `plugin-b` depends on `plugin-c`.
        // `plugin-c` doesn't depend on anything.
        File pluginsDependencyFile = new File(project.projectDir.parentFile.parentFile, '.flutter-plugins-dependencies')
        if (pluginsDependencyFile.exists()) {
            def object = new JsonSlurper().parseText(pluginsDependencyFile.text)
            assert object instanceof Map
            assert object.dependencyGraph instanceof List
            return object.dependencyGraph
        }
        return []
    }

    private static String toCamelCase(List<String> parts) {
        if (parts.empty) {
            return ""
        }
        return "${parts[0]}${parts[1..-1].collect { it.capitalize() }.join('')}"
    }

    private String resolveProperty(String name, String defaultValue) {
        if (localProperties == null) {
            localProperties = readPropertiesIfExist(new File(project.projectDir.parentFile, "local.properties"))
        }
        String result
        if (project.hasProperty(name)) {
            result = project.property(name)
        }
        if (result == null) {
            result = localProperties.getProperty(name)
        }
        if (result == null) {
            result = defaultValue
        }
        return result
    }

    private static Properties readPropertiesIfExist(File propertiesFile) {
        Properties result = new Properties()
        if (propertiesFile.exists()) {
            propertiesFile.withReader('UTF-8') { reader -> result.load(reader) }
        }
        return result
    }

    private List<String> getTargetPlatforms() {
        if (!project.hasProperty('target-platform')) {
            return DEFAULT_PLATFORMS
        }
        return project.property('target-platform').split(',').collect {
            if (!PLATFORM_ARCH_MAP[it]) {
                throw new GradleException("Invalid platform: $it.")
            }
            return it
        }
    }

    private Boolean shouldSplitPerAbi() {
        return project.findProperty('split-per-abi')?.toBoolean() ?: false;
    }

    private Boolean useLocalEngine() {
        return project.hasProperty('local-engine-repo')
    }

    private Boolean isVerbose() {
        return project.findProperty('verbose')?.toBoolean() ?: false;
    }

    /** Whether to build the debug app in "fast-start" mode. */
    private Boolean isFastStart() {
        return project.findProperty("fast-start")?.toBoolean() ?: false;
    }

    private static Boolean isBuiltAsApp(Project project) {
        // Projects are built as applications when the they use the `com.android.application`
        // plugin.
        return project.plugins.hasPlugin("com.android.application");
    }

    /**
     * Returns true if the build mode is supported by the current call to Gradle.
     * This only relevant when using a local engine. Because the engine
     * is built for a specific mode, the call to Gradle must match that mode.
     */
    private Boolean supportsBuildMode(String flutterBuildMode) {
        if (!useLocalEngine()) {
            return true;
        }
        assert project.hasProperty('local-engine-build-mode')
        // Don't configure dependencies for a build mode that the local engine
        // doesn't support.
        return project.property('local-engine-build-mode') == flutterBuildMode
    }

    private void addCompileOnlyDependency(Project project, String variantName, Object dependency, Closure config = null) {
        if (project.state.failure) {
            return
        }
        String configuration;
        if (project.getConfigurations().findByName("compileOnly")) {
            configuration = "${variantName}CompileOnly";
        } else {
            configuration = "${variantName}Provided";
        }
        project.dependencies.add(configuration, dependency, config)
    }

    private static void addApiDependencies(Project project, String variantName, Object dependency, Closure config = null) {
        String configuration;
        // `compile` dependencies are now `api` dependencies.
        if (project.getConfigurations().findByName("api")) {
            configuration = "${variantName}Api";
        } else {
            configuration = "${variantName}Compile";
        }
        project.dependencies.add(configuration, dependency, config)
    }

    // Add a task that can be called on flutter projects that prints the Java version used in Gradle.
    //
    // Format of the output of this task can be used in debugging what version of Java Gradle is using.
    // Not recomended for use in time sensitive commands like `flutter run` or `flutter build` as
    // Gradle is slower than we want. Particularly in light of https://github.com/flutter/flutter/issues/119196.
    private static void addTaskForJavaVersion(Project project) {
        // Warning: the name of this task is used by other code. Change with caution.
        project.tasks.register('javaVersion') {
            description 'Print the current java version used by gradle. '
                'see: https://docs.gradle.org/current/javadoc/org/gradle/api/JavaVersion.html'
            doLast {
                println(JavaVersion.current())
            }
        }
    }

    // Add a task that can be called on Flutter projects that prints the available build variants
    // in Gradle.
    //
    // This task prints variants in this format:
    //
    // BuildVariant: debug
    // BuildVariant: release
    // BuildVariant: profile
    //
    // Format of the output of this task is used by `AndroidProject.getBuildVariants`.
    private static void addTaskForPrintBuildVariants(Project project) {
        // Warning: The name of this task is used by `AndroidProject.getBuildVariants`.
        project.tasks.register("printBuildVariants") {
            description "Prints out all build variants for this Android project"
            doLast {
                project.android.applicationVariants.all { variant ->
                    println "BuildVariant: ${variant.name}";
                }
            }
        }
    }

    /**
     * Returns a Flutter build mode suitable for the specified Android buildType.
     *
     * The BuildType DSL type is not public, and is therefore omitted from the signature.
     *
     * @return "debug", "profile", or "release" (fall-back).
     */
    private static String buildModeFor(buildType) {
        if (buildType.name == "profile") {
            return "profile"
        } else if (buildType.debuggable) {
            return "debug"
        }
        return "release"
    }

    private static String getEngineArtifactDirName(buildType, targetArch) {
        if (buildType.name == "profile") {
            return "${targetArch}-profile"
        } else if (buildType.debuggable) {
            return "${targetArch}"
        }
        return "${targetArch}-release"
    }

    /**
     * Gets the directory that contains the Flutter source code.
     * This is the directory containing the `android/` directory.
     */
    private File getFlutterSourceDirectory() {
        if (project.flutter.source == null) {
            throw new GradleException("Must provide Flutter source directory")
        }
        return project.file(project.flutter.source)
    }

    /**
     * Gets the target file. This is typically `lib/main.dart`.
     */
    private String getFlutterTarget() {
        String target = project.flutter.target
        if (target == null) {
            target = 'lib/main.dart'
        }
        if (project.hasProperty('target')) {
            target = project.property('target')
        }
        return target
    }

    // TODO: Remove this AGP hack. https://github.com/flutter/flutter/issues/109560
    /**
     * In AGP 4.0, the Android linter task depends on the JAR tasks that generate `libapp.so`.
     * When building APKs, this causes an issue where building release requires the debug JAR,
     * but Gradle won't build debug.
     *
     * To workaround this issue, only configure the JAR task that is required given the task
     * from the command line.
     *
     * The AGP team said that this issue is fixed in Gradle 7.0, which isn't released at the
     * time of adding this code. Once released, this can be removed. However, after updating to
     * AGP/Gradle 7.2.0/7.5, removing this hack still causes build failures. Futher
     * investigation necessary to remove this.
     *
     * Tested cases:
     * * `./gradlew assembleRelease`
     * * `./gradlew app:assembleRelease.`
     * * `./gradlew assemble{flavorName}Release`
     * * `./gradlew app:assemble{flavorName}Release`
     * * `./gradlew assemble.`
     * * `./gradlew app:assemble.`
     * * `./gradlew bundle.`
     * * `./gradlew bundleRelease.`
     * * `./gradlew app:bundleRelease.`
     *
     * Related issues:
     * https://issuetracker.google.com/issues/158060799
     * https://issuetracker.google.com/issues/158753935
     */
    private boolean shouldConfigureFlutterTask(Task assembleTask) {
        def cliTasksNames = project.gradle.startParameter.taskNames
        if (cliTasksNames.size() != 1 || !cliTasksNames.first().contains("assemble")) {
            return true
        }
        def taskName = cliTasksNames.first().split(":").last()
        if (taskName == "assemble") {
            return true
        }
        if (taskName == assembleTask.name) {
            return true
        }
        if (taskName.endsWith("Release") && assembleTask.name.endsWith("Release")) {
            return true
        }
        if (taskName.endsWith("Debug") && assembleTask.name.endsWith("Debug")) {
            return true
        }
        if (taskName.endsWith("Profile") && assembleTask.name.endsWith("Profile")) {
            return true
        }
        return false
    }

    private Task getAssembleTask(variant) {
        // `assemble` became `assembleProvider` in AGP 3.3.0.
        return variant.hasProperty("assembleProvider") ? variant.assembleProvider.get() : variant.assemble
    }

    private boolean isFlutterAppProject() {
        return project.android.hasProperty("applicationVariants")
    }

    private void addFlutterTasks(Project project) {
        if (project.state.failure) {
            return
        }
        String[] fileSystemRootsValue = null
        if (project.hasProperty('filesystem-roots')) {
            fileSystemRootsValue = project.property('filesystem-roots').split('\\|')
        }
        String fileSystemSchemeValue = null
        if (project.hasProperty('filesystem-scheme')) {
            fileSystemSchemeValue = project.property('filesystem-scheme')
        }
        Boolean trackWidgetCreationValue = true
        if (project.hasProperty('track-widget-creation')) {
            trackWidgetCreationValue = project.property('track-widget-creation').toBoolean()
        }
        String extraFrontEndOptionsValue = null
        if (project.hasProperty('extra-front-end-options')) {
            extraFrontEndOptionsValue = project.property('extra-front-end-options')
        }
        String extraGenSnapshotOptionsValue = null
        if (project.hasProperty('extra-gen-snapshot-options')) {
            extraGenSnapshotOptionsValue = project.property('extra-gen-snapshot-options')
        }
        String splitDebugInfoValue = null
        if (project.hasProperty('split-debug-info')) {
            splitDebugInfoValue = project.property('split-debug-info')
        }
        Boolean dartObfuscationValue = false
        if (project.hasProperty('dart-obfuscation')) {
            dartObfuscationValue = project.property('dart-obfuscation').toBoolean();
        }
        Boolean treeShakeIconsOptionsValue = false
        if (project.hasProperty('tree-shake-icons')) {
            treeShakeIconsOptionsValue = project.property('tree-shake-icons').toBoolean()
        }
        String dartDefinesValue = null
        if (project.hasProperty('dart-defines')) {
            dartDefinesValue = project.property('dart-defines')
        }
        String bundleSkSLPathValue;
        if (project.hasProperty('bundle-sksl-path')) {
            bundleSkSLPathValue = project.property('bundle-sksl-path')
        }
        String performanceMeasurementFileValue;
        if (project.hasProperty('performance-measurement-file')) {
            performanceMeasurementFileValue = project.property('performance-measurement-file')
        }
        String codeSizeDirectoryValue;
        if (project.hasProperty('code-size-directory')) {
            codeSizeDirectoryValue = project.property('code-size-directory')
        }
        Boolean deferredComponentsValue = false
        if (project.hasProperty('deferred-components')) {
            deferredComponentsValue = project.property('deferred-components').toBoolean()
        }
        Boolean validateDeferredComponentsValue = true
        if (project.hasProperty('validate-deferred-components')) {
            validateDeferredComponentsValue = project.property('validate-deferred-components').toBoolean()
        }
        addTaskForJavaVersion(project)
        addTaskForPrintBuildVariants(project)
        def targetPlatforms = getTargetPlatforms()
        def addFlutterDeps = { variant ->
            if (shouldSplitPerAbi()) {
                variant.outputs.each { output ->
                    // Assigns the new version code to versionCodeOverride, which changes the version code
                    // for only the output APK, not for the variant itself. Skipping this step simply
                    // causes Gradle to use the value of variant.versionCode for the APK.
                    // For more, see https://developer.android.com/studio/build/configure-apk-splits
                    def abiVersionCode = ABI_VERSION.get(output.getFilter(OutputFile.ABI))
                    if (abiVersionCode != null) {
                        output.versionCodeOverride =
                            abiVersionCode * 1000 + variant.versionCode
                    }
                }
            }
            String variantBuildMode = buildModeFor(variant.buildType)
            String taskName = toCamelCase(["compile", FLUTTER_BUILD_PREFIX, variant.name])
            // Be careful when configuring task below, Groovy has bizarre
            // scoping rules: writing `verbose isVerbose()` means calling
            // `isVerbose` on the task itself - which would return `verbose`
            // original value. You either need to hoist the value
            // into a separate variable `verbose verboseValue` or prefix with
            // `this` (`verbose this.isVerbose()`).
            FlutterTask compileTask = project.tasks.create(name: taskName, type: FlutterTask) {
                flutterRoot this.flutterRoot
                flutterExecutable this.flutterExecutable
                buildMode variantBuildMode
                localEngine this.localEngine
                localEngineSrcPath this.localEngineSrcPath
                targetPath getFlutterTarget()
                verbose this.isVerbose()
                fastStart this.isFastStart()
                fileSystemRoots fileSystemRootsValue
                fileSystemScheme fileSystemSchemeValue
                trackWidgetCreation trackWidgetCreationValue
                targetPlatformValues = targetPlatforms
                sourceDir getFlutterSourceDirectory()
                intermediateDir project.file("${project.buildDir}/$INTERMEDIATES_DIR/flutter/${variant.name}/")
                extraFrontEndOptions extraFrontEndOptionsValue
                extraGenSnapshotOptions extraGenSnapshotOptionsValue
                splitDebugInfo splitDebugInfoValue
                treeShakeIcons treeShakeIconsOptionsValue
                dartObfuscation dartObfuscationValue
                dartDefines dartDefinesValue
                bundleSkSLPath bundleSkSLPathValue
                performanceMeasurementFile performanceMeasurementFileValue
                codeSizeDirectory codeSizeDirectoryValue
                deferredComponents deferredComponentsValue
                validateDeferredComponents validateDeferredComponentsValue
                doLast {
                    project.exec {
                        if (Os.isFamily(Os.FAMILY_WINDOWS)) {
                            commandLine('cmd', '/c', "attrib -r ${assetsDirectory}/* /s")
                        } else {
                            commandLine('chmod', '-R', 'u+w', assetsDirectory)
                        }
                    }
                }
            }
            File libJar = project.file("${project.buildDir}/$INTERMEDIATES_DIR/flutter/${variant.name}/libs.jar")
            Task packFlutterAppAotTask = project.tasks.create(name: "packLibs${FLUTTER_BUILD_PREFIX}${variant.name.capitalize()}", type: Jar) {
                destinationDirectory = libJar.parentFile
                archiveFileName = libJar.name
                dependsOn compileTask
                targetPlatforms.each { targetPlatform ->
                    String abi = PLATFORM_ARCH_MAP[targetPlatform]
                    from("${compileTask.intermediateDir}/${abi}") {
                        include "*.so"
                        // Move `app.so` to `lib/<abi>/libapp.so`
                        rename { String filename ->
                            return "lib/${abi}/lib${filename}"
                        }
                    }
                }
            }
            addApiDependencies(project, variant.name, project.files {
                packFlutterAppAotTask
            })
            // We build an AAR when this property is defined.
            boolean isBuildingAar = project.hasProperty('is-plugin')
            // In add to app scenarios, a Gradle project contains a `:flutter` and `:app` project.
            // We know that `:flutter` is used as a subproject when these tasks exists and we aren't building an AAR.
            Task packageAssets = project.tasks.findByPath(":flutter:package${variant.name.capitalize()}Assets")
            Task cleanPackageAssets = project.tasks.findByPath(":flutter:cleanPackage${variant.name.capitalize()}Assets")
            boolean isUsedAsSubproject = packageAssets && cleanPackageAssets && !isBuildingAar
            Task copyFlutterAssetsTask = project.tasks.create(
                name: "copyFlutterAssets${variant.name.capitalize()}",
                type: Copy,
            ) {
                dependsOn compileTask
                with compileTask.assets
                if (isUsedAsSubproject) {
                    dependsOn packageAssets
                    dependsOn cleanPackageAssets
                    into packageAssets.outputDir
                    return
                }
                // `variant.mergeAssets` will be removed at the end of 2019.
                def mergeAssets = variant.hasProperty("mergeAssetsProvider") ?
                    variant.mergeAssetsProvider.get() : variant.mergeAssets
                dependsOn mergeAssets
                dependsOn "clean${mergeAssets.name.capitalize()}"
                mergeAssets.mustRunAfter("clean${mergeAssets.name.capitalize()}")
                into mergeAssets.outputDir
            }
            if (!isUsedAsSubproject) {
                def variantOutput = variant.outputs.first()
                def processResources = variantOutput.hasProperty("processResourcesProvider") ?
                    variantOutput.processResourcesProvider.get() : variantOutput.processResources
                processResources.dependsOn(copyFlutterAssetsTask)
            }
            // Task compressAssets uses the output of copyFlutterAssetsTask,
            // so it's necessary to declare it as an dependency.
            def compressAssetsTask = project.tasks.findByName("compress${variant.name.capitalize()}Assets")
            if (compressAssetsTask) {
                compressAssetsTask.dependsOn copyFlutterAssetsTask
            }
            return copyFlutterAssetsTask
        } // end def addFlutterDeps

        if (isFlutterAppProject()) {
            project.android.applicationVariants.all { variant ->
                Task assembleTask = getAssembleTask(variant)
                if (!shouldConfigureFlutterTask(assembleTask)) {
                  return
                }
                Task copyFlutterAssetsTask = addFlutterDeps(variant)
                def variantOutput = variant.outputs.first()
                def processResources = variantOutput.hasProperty("processResourcesProvider") ?
                    variantOutput.processResourcesProvider.get() : variantOutput.processResources
                processResources.dependsOn(copyFlutterAssetsTask)

                // Copy the output APKs into a known location, so `flutter run` or `flutter build apk`
                // can discover them. By default, this is `<app-dir>/build/app/outputs/flutter-apk/<filename>.apk`.
                //
                // The filename consists of `app<-abi>?<-flavor-name>?-<build-mode>.apk`.
                // Where:
                //   * `abi` can be `armeabi-v7a|arm64-v8a|x86|x86_64` only if the flag `split-per-abi` is set.
                //   * `flavor-name` is the flavor used to build the app in lower case if the assemble task is called.
                //   * `build-mode` can be `release|debug|profile`.
                variant.outputs.all { output ->
                    assembleTask.doLast {
                        // `packageApplication` became `packageApplicationProvider` in AGP 3.3.0.
                        def outputDirectory = variant.hasProperty("packageApplicationProvider")
                            ? variant.packageApplicationProvider.get().outputDirectory
                            : variant.packageApplication.outputDirectory
                        //  `outputDirectory` is a `DirectoryProperty` in AGP 4.1.
                        String outputDirectoryStr = outputDirectory.metaClass.respondsTo(outputDirectory, "get")
                            ? outputDirectory.get()
                            : outputDirectory
                        String filename = "app"
                        String abi = output.getFilter(OutputFile.ABI)
                        if (abi != null && !abi.isEmpty()) {
                            filename += "-${abi}"
                        }
                        if (variant.flavorName != null && !variant.flavorName.isEmpty()) {
                            filename += "-${variant.flavorName.toLowerCase()}"
                        }
                        filename += "-${buildModeFor(variant.buildType)}"
                        project.copy {
                            from new File("$outputDirectoryStr/${output.outputFileName}")
                            into new File("${project.buildDir}/outputs/flutter-apk");
                            rename {
                                return "${filename}.apk"
                            }
                        }
                    }
                }
            }
            configurePlugins()
            detectLowCompileSdkVersionOrNdkVersion()
            return
        }
        // Flutter host module project (Add-to-app).
        String hostAppProjectName = project.rootProject.hasProperty('flutter.hostAppProjectName') ? project.rootProject.property('flutter.hostAppProjectName') : "app"
        Project appProject = project.rootProject.findProject(":${hostAppProjectName}")
        assert appProject != null : "Project :${hostAppProjectName} doesn't exist. To customize the host app project name, set `flutter.hostAppProjectName=<project-name>` in gradle.properties."
        // Wait for the host app project configuration.
        appProject.afterEvaluate {
            assert appProject.android != null
            project.android.libraryVariants.all { libraryVariant ->
                Task copyFlutterAssetsTask
                appProject.android.applicationVariants.all { appProjectVariant ->
                    Task appAssembleTask = getAssembleTask(appProjectVariant)
                    if (!shouldConfigureFlutterTask(appAssembleTask)) {
                        return
                    }
                    // Find a compatible application variant in the host app.
                    //
                    // For example, consider a host app that defines the following variants:
                    // | ----------------- | ----------------------------- |
                    // |   Build Variant   |   Flutter Equivalent Variant  |
                    // | ----------------- | ----------------------------- |
                    // |   freeRelease     |   release                      |
                    // |   freeDebug       |   debug                       |
                    // |   freeDevelop     |   debug                       |
                    // |   profile         |   profile                     |
                    // | ----------------- | ----------------------------- |
                    //
                    // This mapping is based on the following rules:
                    // 1. If the host app build variant name is `profile` then the equivalent
                    //    Flutter variant is `profile`.
                    // 2. If the host app build variant is debuggable
                    //    (e.g. `buildType.debuggable = true`), then the equivalent Flutter
                    //    variant is `debug`.
                    // 3. Otherwise, the equivalent Flutter variant is `release`.
                    String variantBuildMode = buildModeFor(libraryVariant.buildType)
                    if (buildModeFor(appProjectVariant.buildType) != variantBuildMode) {
                        return
                    }
                    if (copyFlutterAssetsTask == null) {
                        copyFlutterAssetsTask = addFlutterDeps(libraryVariant)
                    }
                    Task mergeAssets = project
                        .tasks
                        .findByPath(":${hostAppProjectName}:merge${appProjectVariant.name.capitalize()}Assets")
                    assert mergeAssets
                    mergeAssets.dependsOn(copyFlutterAssetsTask)
                }
            }
        }
        configurePlugins()
        detectLowCompileSdkVersionOrNdkVersion()
    }
}

abstract class BaseFlutterTask extends DefaultTask {
    @Internal
    File flutterRoot
    @Internal
    File flutterExecutable
    @Input
    String buildMode
    @Optional @Input
    String localEngine
    @Optional @Input
    String localEngineSrcPath
    @Optional @Input
    Boolean fastStart
    @Input
    String targetPath
    @Optional @Input
    Boolean verbose
    @Optional @Input
    String[] fileSystemRoots
    @Optional @Input
    String fileSystemScheme
    @Input
    Boolean trackWidgetCreation
    @Optional @Input
    List<String> targetPlatformValues
    @Internal
    File sourceDir
    @Internal
    File intermediateDir
    @Optional @Input
    String extraFrontEndOptions
    @Optional @Input
    String extraGenSnapshotOptions
    @Optional @Input
    String splitDebugInfo
    @Optional @Input
    Boolean treeShakeIcons
    @Optional @Input
    Boolean dartObfuscation
    @Optional @Input
    String dartDefines
    @Optional @Input
    String bundleSkSLPath
    @Optional @Input
    String codeSizeDirectory;
    @Optional @Input
    String performanceMeasurementFile;
    @Optional @Input
    Boolean deferredComponents
    @Optional @Input
    Boolean validateDeferredComponents

    @OutputFiles
    FileCollection getDependenciesFiles() {
        FileCollection depfiles = project.files()

        // Includes all sources used in the flutter compilation.
        depfiles += project.files("${intermediateDir}/flutter_build.d")
        return depfiles
    }

    void buildBundle() {
        if (!sourceDir.isDirectory()) {
            throw new GradleException("Invalid Flutter source directory: ${sourceDir}")
        }

        intermediateDir.mkdirs()

        // Compute the rule name for flutter assemble. To speed up builds that contain
        // multiple ABIs, the target name is used to communicate which ones are required
        // rather than the TargetPlatform. This allows multiple builds to share the same
        // cache.
        String[] ruleNames;
        if (buildMode == "debug") {
            ruleNames = ["debug_android_application"]
        } else if (deferredComponents) {
            ruleNames = targetPlatformValues.collect { "android_aot_deferred_components_bundle_${buildMode}_$it" }
        } else {
            ruleNames = targetPlatformValues.collect { "android_aot_bundle_${buildMode}_$it" }
        }
        project.exec {
            logging.captureStandardError LogLevel.ERROR
            executable flutterExecutable.absolutePath
            workingDir sourceDir
            if (localEngine != null) {
                args "--local-engine", localEngine
                args "--local-engine-src-path", localEngineSrcPath
            }
            if (verbose) {
                args "--verbose"
            } else {
                args "--quiet"
            }
            args "assemble"
            args "--no-version-check"
            args "--depfile", "${intermediateDir}/flutter_build.d"
            args "--output", "${intermediateDir}"
            if (performanceMeasurementFile != null) {
                args "--performance-measurement-file=${performanceMeasurementFile}"
            }
            if (!fastStart || buildMode != "debug") {
                args "-dTargetFile=${targetPath}"
            } else {
                args "-dTargetFile=${Paths.get(flutterRoot.absolutePath, "examples", "splash", "lib", "main.dart")}"
            }
            args "-dTargetPlatform=android"
            args "-dBuildMode=${buildMode}"
            if (trackWidgetCreation != null) {
                args "-dTrackWidgetCreation=${trackWidgetCreation}"
            }
            if (splitDebugInfo != null) {
                args "-dSplitDebugInfo=${splitDebugInfo}"
            }
            if (treeShakeIcons == true) {
                args "-dTreeShakeIcons=true"
            }
            if (dartObfuscation == true) {
                args "-dDartObfuscation=true"
            }
            if (dartDefines != null) {
                args "--DartDefines=${dartDefines}"
            }
            if (bundleSkSLPath != null) {
                args "-dBundleSkSLPath=${bundleSkSLPath}"
            }
            if (codeSizeDirectory != null) {
                args "-dCodeSizeDirectory=${codeSizeDirectory}"
            }
            if (extraGenSnapshotOptions != null) {
                args "--ExtraGenSnapshotOptions=${extraGenSnapshotOptions}"
            }
            if (extraFrontEndOptions != null) {
                args "--ExtraFrontEndOptions=${extraFrontEndOptions}"
            }
            args ruleNames
        }
    }
}

class FlutterTask extends BaseFlutterTask {
    @OutputDirectory
    File getOutputDirectory() {
        return intermediateDir
    }

    @Internal
    String getAssetsDirectory() {
        return "${outputDirectory}/flutter_assets"
    }

    @Internal
    CopySpec getAssets() {
        return project.copySpec {
            from "${intermediateDir}"
            include "flutter_assets/**" // the working dir and its files
        }
    }

    @Internal
    CopySpec getSnapshots() {
        return project.copySpec {
            from "${intermediateDir}"

            if (buildMode == 'release' || buildMode == 'profile') {
                targetPlatformValues.each {
                    include "${PLATFORM_ARCH_MAP[targetArch]}/app.so"
                }
            }
        }
    }

    FileCollection readDependencies(File dependenciesFile, Boolean inputs) {
      if (dependenciesFile.exists()) {
        // Dependencies file has Makefile syntax:
        //   <target> <files>: <source> <files> <separated> <by> <non-escaped space>
        String depText = dependenciesFile.text
        // So we split list of files by non-escaped(by backslash) space,
        def matcher = depText.split(': ')[inputs ? 1 : 0] =~ /(\\ |[^\s])+/
        // then we replace all escaped spaces with regular spaces
        def depList = matcher.collect{it[0].replaceAll("\\\\ ", " ")}
        return project.files(depList)
      }
      return project.files();
    }

    @InputFiles
    FileCollection getSourceFiles() {
        FileCollection sources = project.files()
        for (File depfile in getDependenciesFiles()) {
          sources += readDependencies(depfile, true)
        }
        return sources + project.files('pubspec.yaml')
    }

    @OutputFiles
    FileCollection getOutputFiles() {
        FileCollection sources = project.files()
        for (File depfile in getDependenciesFiles()) {
          sources += readDependencies(depfile, false)
        }
        return sources
    }

    @TaskAction
    void build() {
        buildBundle()
    }
}
