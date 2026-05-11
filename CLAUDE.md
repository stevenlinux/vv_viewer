# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

vv_viewer is a Flutter Android application that opens .vv files and connects to PVE (Proxmox VE) SPICE consoles directly without requiring external aSPICE Pro purchase. The SPICE client is embedded using bVNC/remoteClientLib modules.

## Build Commands

```bash
cd /Users/steve/ClaudeProjects/vv_viewer

# Flutter commands
flutter analyze              # 代码分析
flutter test                # 运行测试
flutter build apk --debug   # 构建 debug APK

# Android only (faster for Kotlin/Java changes)
cd android
export JAVA_HOME="/Users/steve/Library/Java/JavaVirtualMachines/jbr-17.0.14/Contents/Home"
./gradlew assembleDebug     # 构建 APK
./gradlew clean             # 清理构建

# Install APK
adb install -r android/app/build/outputs/apk/debug/app-debug.apk

# View logs
adb logcat | grep -i "MainActivity\|SpiceLauncher\|RemoteCanvas"
```

## Architecture

### Key Modules

- **app** - Flutter application (com.vvviewer.vv_viewer)
- **bVNC** - UI components (com.undatech.remoteClientUi)
- **remoteClientLib** - SPICE protocol (com.undatech.remoteClientLib)
- **common** - Shared utilities (com.morpheusly.common)
- **pubkeyGenerator** - SSH key generation (com.iiordanov.pubkeygenerator)

### Module Dependency Graph

```
app
├── bVNC
│   ├── pubkeyGenerator
│   ├── remoteClientLib
│   └── common
├── remoteClientLib
├── common
└── pubkeyGenerator
    └── common
```

### Platform Channel

SPICE connection is launched via Android Intent from Flutter to the embedded bVNC activities:
- MainActivity.kt configures `MethodChannel` and `PlatformViewFactory`
- Uses `setClassName("com.iiordanov.bVNC", "com.iiordanov.bVNC.RemoteCanvasActivity")` to launch embedded SPICE

### Connection State Management

Two separate trackers prevent cross-contamination between external and Flutter-initiated connections:
- `externalCallUri` - tracks external PVE app calls (original URI string)
- `flutterCallPath` - tracks Flutter calls (resolved file path)

Key flow:
1. External call → `handleVirtViewerFile()` → uses `externalCallUri`
2. Flutter call → `launchEmbeddedSpiceWithFile()` → uses `flutterCallPath`
3. Same connection detection uses equality check against respective tracker
4. `SpiceCommunicator.close()` clears `savedContext` and unregisters BroadcastReceivers

**Auto-connect behavior**: When opening a .vv file or receiving a PVE app link, ViewerScreen automatically launches embedded SPICE without requiring manual button click. This is implemented in `_checkAspiceInstallation()` which calls `_autoLaunchEmbeddedSpice()` when embedded aSPICE is available.

### Logging

Uses `AppLogger` class with tag-based logging:
```dart
AppLogger.debug(LogTags.spiceLauncher, 'message');
AppLogger.info(LogTags.main, 'message');
AppLogger.error(LogTags.main, 'error', e, st);
```

Tags defined in `LogTags` class.

## Gradle Configuration

Working configuration:
- **AGP**: 8.9.1
- **Kotlin**: 1.9.22
- **Java**: 17
- **compileSdk**: 35 (app: 36)
- **minSdk**: 23

Key files:
- `android/settings.gradle.kts` - plugin versions and module includes
- `android/build.gradle.kts` - root build config, allprojects repositories
- `android/app/build.gradle.kts` - app module config

## Attempted Solutions (DO NOT REPEAT)

1. **Intent Jump (deprecated)**: Launch external aSPICE via Intent - requires separate app installation
2. **Exclude freeRDPCore**: FAILED - bVNC layouts and Java code have hard dependencies on freeRDPCore classes
3. **Copy Strings**: FAILED - RdpCommunicator.java imports freeRDPCore classes directly
4. **Downgrade Toolchain (AGP 7.4.2)**: FAILED - Flutter requires AGP 8.1.1 minimum
5. **AGP 8.1.4 + Kotlin 1.9.22**: FAILED - modern dependencies require AGP 8.9.1
6. **Remove freeRDPCore + Keep All Modules**: FAILED - RdpCommunicator.java.bak, RdpKeyboardMapper.java.bak, RemoteRdpConnection.kt.bak still caused class resolution failures

### Solution That Works: Partial Module Removal

**Approach**: Remove only the RDP-specific files that directly depend on freeRDPCore. Keep SPICE-only code intact.

**What was removed/moved**:
- `RdpCommunicator.java` → `RdpCommunicator.java.bak`
- `RdpKeyboardMapper.java` → `RdpKeyboardMapper.java.bak`
- `RemoteRdpConnection.kt` → `RemoteRdpConnection.kt.bak`
- `RemoteRdpKeyboard.java` → `RemoteRdpKeyboard.java.bak`

**What was changed**:
- `RemoteConnectionFactory.kt` - RDP branch redirects to SPICE connection
- `settings.gradle.kts` - freeRDPCore module excluded
- `remoteClientLib/build.gradle.kts` - freeRDPCore dependency removed, uses multidex 2.0.1
- `common/build.gradle.kts` - sqlcipher AAR published to mavenLocal, referenced via `api("com.undatech.sqlcipher:android-database-sqlcipher:4.5.4")`
- `bVNC/build.gradle.kts` - direct local .aar removed, multidex dependency removed
- `app/build.gradle.kts` - packaging exclusions for META-INF

**Why this works**: SPICE only needs `SpiceCommunicator.java` which has NO freeRDPCore dependencies. The RDP code (RdpCommunicator, LibFreeRDP, BookmarkBase, etc.) is what requires freeRDPCore.

## Common Build Issues

### "Could not find com.undatech.sqlcipher"
**Fix**: Publish sqlcipher AAR to maven local:
```bash
mkdir -p ~/.m2/repository/com/undatech/sqlcipher/android-database-sqlcipher/4.5.4
cp android/common/aars/android-database-sqlcipher-4.5.4.aar ~/.m2/repository/com/undatech/sqlcipher/android-database-sqlcipher/4.5.4/
```

### "Direct local .aar file dependencies are not supported"
**Fix**: Libraries cannot have direct local .aar deps. Publish to mavenLocal instead.

### "Inconsistent JVM-target compatibility"
**Fix**: Ensure all modules have matching Java/Kotlin versions:
```kotlin
compileOptions {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
}
kotlinOptions {
    jvmTarget = "17"
}
```

### "Invalid source release: 21"
**Fix**: JDK 17 doesn't support source/target 21. Use Java 17 throughout.

### Activity Task Affinity Issues
When launching RemoteCanvasActivity, avoid `FLAG_ACTIVITY_NEW_TASK` unless starting a genuinely new session. Using NEW_TASK creates new task instances which can cause:
- Connection state cross-contamination between launches
- Difficulty reusing existing Activity instances
- Race conditions in SpiceCommunicator singleton

RemoteCanvasActivity's `onNewIntent()` handles connection changes within the same task.

### Two SPICE Connection Paths

vv_viewer supports two ways to launch SPICE connections:

#### Path 1: PVE Link (spice+:// URL)
When PVE app invokes vv_viewer with a spice+ URL like `spice+https://192.168.1.100:8006/`:

```
PVE App → Intent (spice+https://...) 
       → MainActivity.handleVirtViewerFile() 
       → SpiceDisplay.java parses JSON 
       → writes temp .vv file 
       → startSessionFromVvFile() 
       → Native SPICE connection
```

Key classes:
- `MainActivity.kt:handleVirtViewerFile()` - handles the spice+ URL
- `SpiceDisplay.java` - parses PVE Intent JSON, writes temp .vv with CA certs combined

#### Path 2: .vv File Open
When user opens a .vv file directly (file manager association):

```
File Manager → content:// .vv URI 
            → MainActivity.handleVirtViewerFile() 
            → resolveContentUriSync() reads file 
            → startSessionFromVvFile() 
            → Native SPICE connection
```

Key classes:
- `MainActivity.kt:handleVirtViewerFile()` - handles content:// URI
- `AbstractConnectionBean.java:getOpaqueConnection()` - copies .vv to settings file

#### Common Endpoint
Both paths converge at:
```
Native: spice_session_setup_from_vv() → SpiceSession password set → spice_session_connect()
```

The `SpiceDisplay.java` class handles PVE-specific .vv file generation with combined CA certificates.

### Activity Task Affinity Issues
When launching RemoteCanvasActivity, avoid `FLAG_ACTIVITY_NEW_TASK` unless starting a genuinely new session. Using NEW_TASK creates new task instances which can cause:
- Connection state cross-contamination between launches
- Difficulty reusing existing Activity instances
- Race conditions in SpiceCommunicator singleton

RemoteCanvasActivity's `onNewIntent()` handles connection changes within the same task.

## Key Files

### Android (Native)
- `android/app/src/main/kotlin/com/vvviewer/vv_viewer/MainActivity.kt` - Platform channel, connection state management
- `android/remoteClientLib/src/main/java/com/undatech/opaque/SpiceCommunicator.java` - SPICE protocol, static singleton `myself`
- `android/bVNC/src/main/java/com/iiordanov/bVNC/RemoteCanvasActivity.java` - SPICE display Activity, onNewIntent handling
- `android/bVNC/src/main/java/com/iiordanov/bVNC/protocol/RemoteOpaqueConnection.kt` - Base connection, spiceComm lifecycle
- `android/bVNC/src/main/java/com/iiordanov/bVNC/protocol/RemoteSpiceConnection.kt` - SPICE connection implementation
- `android/bVNC/src/main/java/com/undatech/opaque/proxmox/pojo/SpiceDisplay.java` - .vv file parsing for PVE, outputs to temp .vv file

### Flutter
- `lib/main.dart` - App entry, URI handling, global error catch
- `lib/services/spice_launcher_service.dart` - Platform channel wrapper
- `lib/services/app_logger.dart` - Structured logging (AppLogger class)
- `lib/services/storage_service.dart` - Local storage
- `lib/parsers/vv_parser.dart` - .vv file parser
- `lib/models/vv_connection.dart` - Connection data model
- `lib/models/connection_type.dart` - Connection type enum
- `lib/screens/viewer_screen.dart` - Main viewer UI
- `lib/screens/home_screen.dart` - Home screen
- `lib/screens/connection_list_screen.dart` - Connection list

### Flutter State Management
Uses `hooks_riverpod` with `useState` for simple state. Key patterns:
- `ValueNotifier<T>` for reactive state in widgets
- Platform channel for native communication

## Native Layer Debugging

### Password Flow Debugging
The password flows through these layers:
1. Flutter parses .vv file → `vv_parser.dart`
2. MainActivity.kt launches RemoteCanvasActivity with `vv_file_path` extra
3. AbstractConnectionBean.java copies .vv content to default settings file
4. SpiceCommunicator.startSessionFromVvFile() reads via Native code
5. android-service.c `spice_session_setup_from_vv()` sets password on SpiceSession

To debug password issues, filter logs:
```bash
adb logcat | grep -E "spice_session_setup|password|StartSessionFromVvFile|virt-viewer-file"
```

### Key Native Files
- `android/remoteClientLib/jni/android/android-service.c` - JNI bridge, SPICE session setup from .vv files
- `android/remoteClientLib/jni/android/android-spicy.c` - Connection lifecycle, main channel event handling
- `android/remoteClientLib/jni/virt-viewer/virt-viewer-file.c` - .vv file parsing

### Common Native Errors
- `SPICE_CHANNEL_ERROR_AUTH (20)` - Authentication failed, password rejected
- `SPICE_CHANNEL_ERROR_CONNECT (108)` - Connection failed
- `SPICE_CHANNEL_ERROR_TLS (45)` - TLS handshake failed

## Testing

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/parsers/vv_parser_test.dart
```

Test directory structure:
```
test/
├── models/           # Model unit tests (VVConnection, ConnectionType)
├── parsers/         # Parser tests (VVParser)
├── services/        # Service tests
└── widget_test.dart # Widget tests
```

Current test count: 52 tests passing

## CI/CD

GitHub Actions workflow at `.github/workflows/flutter_ci.yml`:
- Lint check (flutter analyze)
- Unit tests
- Android debug APK build
- Artifact upload

## Documentation

- `docs/TEST_PLAN.md` - Manual test cases and acceptance criteria
- `docs/` - Architecture and integration docs
- `CHANGELOG.md` - Version history

## Monitoring (TODO)

Sentry integration planned:
- Add `sentry_flutter: ^8.0.0` to `pubspec.yaml`
- Requires Kotlin 2.1+ upgrade first
- Global error capture with stack traces
- Traces sample rate: 10%

## Code Quality

- Pre-commit hook at `.git/hooks/pre-commit` (runs flutter analyze)
- Strict type checking enabled (implicit-casts: false, implicit-dynamic: false)
- Analysis config at `analysis_options.yaml`
