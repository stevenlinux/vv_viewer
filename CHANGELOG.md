# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- CI/CD workflow (GitHub Actions)
- Structured logging with AppLogger class
- Global error handler with runZonedGuarded
- Comprehensive unit tests for VVParser

### Fixed
- Connection state cross-contamination between external and Flutter calls
- BroadcastReceiver not unregistered in SpiceCommunicator.close()
- Memory leak from savedContext not being cleared
- spiceComm not closed before reconnecting
- onNewIntent not handling new connections properly

## [0.1.0] - 2026-04-26

### Added
- Flutter Android app with embedded SPICE client
- Platform channel integration (MainActivity.kt)
- .vv file parsing (vv_parser.dart)
- RemoteCanvasActivity for SPICE display
- Connection state management with externalCallUri and flutterCallPath
- RemoteOpaqueConnection with spiceComm lifecycle management
- SpiceCommunicator with proper close() and cleanup
- AppLogger for structured logging
- Unit tests for VVParser

### Features
- Open .vv files directly from PVE app
- Embedded SPICE connection (no external aSPICE required)
- Support for SPICE protocol connections
- Content URI resolution for external file access
- Connection deduplication (same file → CLEAR_TOP)
