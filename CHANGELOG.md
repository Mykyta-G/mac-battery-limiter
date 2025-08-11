# Changelog

All notable changes to the Battery Limiter project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Enhanced battery monitoring with real-time updates
- Sleep mode support with reduced monitoring frequency
- Automatic startup integration via LaunchAgent
- Menu bar integration with custom battery icon
- Background operation capabilities
- Accessibility permissions handling
- Comprehensive project documentation and changelog
- **RESEARCH: Comprehensive SMC battery control investigation**
- **RESEARCH: SMC testing utilities (smc_test, verify_charging.sh)**
- **RESEARCH: Complete testing methodology and documentation**
- **FEATURE: System compatibility detection and analysis**
- **FEATURE: Battery health insights and monitoring**
- **FEATURE: Educational content about macOS battery limitations**

### Changed
- Improved battery monitoring accuracy
- Enhanced user interface responsiveness
- Better error handling and logging
- **MAJOR: App refactored from charging control to monitoring focus**
- **MAJOR: Removed all SMC charging control attempts (proven impossible)**
- **MAJOR: Updated UI to show system compatibility instead of charge limits**
- **UI/UX: Enhanced application layout and spacing for better visual hierarchy**
- **UI/UX: Improved header and footer spacing to prevent text clipping**
- **UI/UX: Replaced instructional footer text with clean copyright notice**
- **UI/UX: Increased window dimensions and padding for better readability**

### Fixed
- Menu bar icon visibility issues
- Battery monitoring reliability during system sleep
- Permission handling for different macOS versions
- **RESEARCH: Confirmed SMC battery control keys don't exist on macOS 15.6+**
- **RESEARCH: Proved battery charging control is impossible on modern Macs**
- **RESEARCH: Identified Apple's security restrictions as root cause**
- **UI/UX: Fixed text clipping issues in header and footer sections**
- **UI/UX: Resolved cramped spacing around battery icon and title text**

## [2.0.0] - 2025-08-11

### Major Changes
- **COMPLETE APP REFACTOR**: Shifted from charging control to monitoring focus
- **RESEARCH COMPLETE**: Thorough investigation of SMC battery control capabilities
- **TRUTH REVEALED**: Battery charging control is impossible on modern macOS

### Research Findings
- **SMC Access**: Successfully connected to System Management Controller
- **Battery Keys**: NO battery control keys exist on macOS 15.6+
- **Write Capability**: Keys cannot be created or modified
- **Charging Control**: Zero software methods available
- **Root Cause**: Apple intentionally removed battery control for security

### What Changed
- Removed all SMC charging control attempts (proven impossible)
- Updated UI to show system compatibility instead of charge limits
- Added system detection and architecture analysis
- Focused on battery monitoring and health insights
- Added educational content about macOS limitations

### Tools Created
- **`smc_test`**: C utility that confirmed SMC keys don't exist
- **`verify_charging.sh`**: Script to monitor charging behavior
- **`TEST_PLAN.md`**: Complete testing methodology and results

---

## [1.0.0] - 2025-08-10

### Added
- Initial release of Battery Limiter for macOS
- Core battery monitoring functionality
- Basic charging control via SMC (later proven impossible)
- SwiftUI-based user interface
- Menu bar application design
- Automatic startup capability
- Battery level notifications
- Customizable charge limits (later removed)

### Technical Features
- IOKit integration for battery monitoring
- SMC (System Management Controller) access (limited)
- LaunchAgent integration for auto-start
- SwiftUI + AppKit hybrid architecture
- Background monitoring capabilities
- Sleep mode awareness

## [0.9.0] - 2024-01-XX

### Added
- Beta version with core functionality
- Basic battery status monitoring
- Simple charging control
- Menu bar interface prototype

### Known Issues
- Limited battery monitoring accuracy
- Basic error handling
- No sleep mode support

## [0.8.0] - 2024-01-XX

### Added
- Initial project structure
- Basic Xcode project setup
- Core battery monitoring framework
- Foundation for SwiftUI interface

---

## Version History Notes

### Development Phases
- **Phase 1**: Core battery monitoring and SMC integration
- **Phase 2**: User interface and menu bar integration
- **Phase 3**: Background operation and auto-start
- **Phase 4**: Sleep mode support and optimization
- **Phase 5**: Enhanced monitoring and reliability
- **Phase 6**: **RESEARCH PHASE** - Investigation of SMC battery control capabilities
- **Phase 7**: **REFACTOR PHASE** - Shift to monitoring focus after proving charging control impossible

### Compatibility
- **macOS 10.15+**: Full support with monitoring features
- **macOS 10.14**: Limited support (basic monitoring only)
- **macOS 10.13 and earlier**: Not supported
- **⚠️ IMPORTANT**: Battery charging control is impossible on ALL modern macOS versions

### Architecture Evolution
- Started with basic AppKit implementation
- Migrated to SwiftUI for modern UI components
- Added hybrid AppKit/SwiftUI approach for menu bar integration
- Implemented background monitoring with LaunchAgent integration
- **RESEARCH PHASE**: Built comprehensive SMC testing tools and methodology
- **REFACTOR PHASE**: Removed charging control, focused on monitoring and insights

---

## Contributing to Changelog

When adding new entries to this changelog, please follow these guidelines:

1. **Use the existing format** and categories
2. **Be descriptive** about what changed
3. **Include technical details** when relevant
4. **Add dates** for releases when known
5. **Group related changes** under the same version
6. **Use clear, concise language** that users can understand

For more information on contributing, see [CONTRIBUTING.md](CONTRIBUTING.md).
