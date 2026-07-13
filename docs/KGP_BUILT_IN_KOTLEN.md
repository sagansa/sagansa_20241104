# Kotlin Gradle Plugin (KGP) & Built-in Kotlin Migration

## Status (Last Reviewed: 2026-06-21)

| Plugin | Current Version | Latest Available | KGP-Free? |
|--------|----------------|------------------|-----------|
| `image_picker_android` | 0.8.13+19 | 0.8.13+19 | ❌ No |
| `package_info_plus` | 10.1.0 | 10.1.0 | ❌ No |
| `shared_preferences_android` | 2.4.26 | 2.4.26 | ❌ No |
| `url_launcher_android` | 6.3.32 | 6.3.32 | ❌ No |

## Background

Flutter 3.44+ introduced **Built-in Kotlin** support and emits a warning when plugins still apply the Kotlin Gradle Plugin (KGP) via `apply plugin: 'kotlin-android'` or the `org.jetbrains.kotlin:kotlin-gradle-plugin` classpath.

> Future versions of Flutter will fail to build if your app uses plugins that apply KGP.

## Investigation Result

As of 2026-06-21, **none of the flagged plugins have released a version that supports Built-in Kotlin**. All four plugins — including their **latest** published versions — still apply KGP in their `android/build.gradle(.kts)`:

### Evidence

**`image_picker_android` 0.8.13+19** (`android/build.gradle.kts`):
```kotlin
val kotlinVersion = "2.3.20"
classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
plugins { id("kotlin-android") }
```

**`shared_preferences_android` 2.4.26** (`android/build.gradle.kts`):
```kotlin
val kotlinVersion = "2.3.0"
classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
plugins { id("kotlin-android") }
```

**`url_launcher_android` 6.3.32** (`android/build.gradle.kts`):
```kotlin
val kotlinVersion = "2.3.0"
classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
plugins { id("kotlin-android") }
```

**`package_info_plus` 10.1.0** (`android/build.gradle`):
```groovy
ext.kotlin_version = '2.2.0'
classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
apply plugin: 'kotlin-android'
```

## Current Mitigation

1. **All plugins upgraded to latest versions** — Done ✅
   - This ensures the project is ready the moment Built-in Kotlin-compatible versions are released.
   - `package_info_plus` upgraded from `9.0.1` → `10.1.0` (major version, verified API compatibility with `PackageInfo.fromPlatform()`).

2. **App-side Android config already migrated** — Done ✅
   - `android/gradle.properties` has `android.builtInKotlin=true` and `android.newDsl=true` (added by Flutter migrator).
   - `android/settings.gradle` declares the Kotlin plugin via the `plugins {}` block (Built-in Kotlin compatible style).

3. **The warning is currently unavoidable** — It will persist until plugin authors publish Built-in Kotlin-compatible versions.

## Recommended Follow-up Actions

### Short-term (Monitor)
- Watch these repositories/CHANGELOGs for Built-in Kotlin migration releases:
  - Flutter team plugins: https://github.com/flutter/packages
  - plus_plugins (package_info_plus): https://github.com/fluttercommunity/plus_plugins
- Once a KGP-free version is available, update `pubspec.yaml` and re-run `flutter pub upgrade`.

### When KGP-free versions are released
```bash
cd mobiles/sagansa
flutter pub upgrade --major-versions
flutter clean && flutter pub get
flutter build apk  # verify the warning is gone
```

### If Flutter forces the migration before plugins are updated
Per the official guide, report the issue to plugin authors:
- https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers#report-incompatible-kotlin-gradle-plugin-usage-to-plugin-authors

## Verification Commands
```bash
# Check current plugin versions
grep -A5 "^  \(image_picker_android\|package_info_plus\|shared_preferences_android\|url_launcher_android\):" pubspec.lock | grep version

# Verify pub cache build.gradle files for KGP usage
grep -rE "kotlin-gradle-plugin|kotlin-android" \
  ~/.pub-cache/hosted/pub.dev/{image_picker_android-*,package_info_plus-*,shared_preferences_android-*,url_launcher_android-*}/android/build.gradle*