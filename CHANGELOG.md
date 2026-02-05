# Changelog

All notable changes to OpenXTalk Community Edition will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased] - 2025-02-04

### Added

#### CMake Build System
- **New CMake build system** replacing the legacy GYP-based build (`b7d1d0386`)
  - Modern, maintainable build configuration
  - Native Xcode project generation
  - Support for Debug, Release, and Fast build types
- **LCB compiler toolchain** ported to CMake (`65e4815dc`)
  - `lc-compile` stages 1-3 bootstrap compilation
  - `lc-run` bytecode interpreter
  - Parser generators (gentle, reflex)
- **Skia graphics library** built from source (`e357fac86`)
  - Replaces prebuilt Skia dependency
  - Properly configured for macOS arm64 and x86_64
- **LCB extension compilation** (`d85f486fd`)
  - Compiles widget and library extensions (.lcb → .lcm)
  - Packages script libraries with manifest.xml
  - Output to `packaged_extensions/` for IDE discovery
- **Prebuilt universal libraries** for macOS (`9d95dd49b`)
  - ICU 58.2 (arm64 + x86_64 universal)
  - OpenSSL 1.1.1g (arm64 + x86_64 universal)
  - Committed to repo for out-of-box builds

#### External Plugins
- **revxml external** built from source (`33f41399b`)
  - libxml2 and libxslt compiled from thirdparty sources
  - Required for extension manifest parsing
- **revzip external** built from source (`33f41399b`)
  - libzip compiled from thirdparty sources
- **Ad-hoc code signing** for externals (`b757d0969`)
  - Required by macOS to load bundles via dlopen()

#### macOS Application Bundle
- **App bundle resources** and Info.plist (`41f7ae4df`)
  - Proper bundle structure with icons
  - Document type associations
- **Generated files** for engine startup (`c4aac4247`)
  - hashedstrings for localization
  - SSL stubs for OpenSSL integration
  - Startup stack compilation
- **LCB built-in modules** generation (`b42b5cd5a`)
  - Module interfaces (.lci) for engine bootstrap
  - Required for IDE startup

### Fixed

- **IDE menu initialization crash** on startup (`de6fdc452`)
- **Versioned stack file filtering** in Open Recent menu (`de6fdc452`)
- **Standalone/server/installer undefined symbol** link errors (`1080f98d7`)
- **Start Center blank screen** - extensions now load correctly (`33f41399b`)
- **Development target linking** issues (`e357fac86`)
- **Missing gzip functions** in zlib build (`33f41399b`)
  - Added gzclose.c, gzlib.c, gzread.c, gzwrite.c
- **CoreServices framework** linking for externals (`33f41399b`)
  - Required for Carbon text conversion APIs

### Changed

- **macOS deployment target** set to 12.0 (Monterey)
- **Disable dark mode** via NSRequiresAquaSystemAppearance (`d85f486fd`)
  - IDE doesn't fully support dark mode yet
- **Makefile targets** switched from GYP/xcodebuild to CMake (`5d6f64c94`)
  - `make config-mac` / `make compile-mac` now use CMake

### Build System Modernization (Pre-CMake)

- **Python 3 support** via gyp-next submodule (`51b3eabd9`)
- **Apple Silicon support** (`473f24d27`, `f9d220f95`)
- **Automatic SDK detection** (`63bdeb9ef`)
- **Universal Binary configurations** (`f9d220f95`)
- **Modern Xcode compatibility** (`437dc5960`)

---

## Version History

For changes prior to the CMake migration, see the git history.
