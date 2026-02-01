# OpenXTalk Community Edition - CMake Build System
# Minimum CMake version for modern features and Apple Silicon support
cmake_minimum_required(VERSION 3.21)

# Version information - parsed from version file
file(STRINGS "${CMAKE_CURRENT_SOURCE_DIR}/version" VERSION_LINES)
foreach(LINE ${VERSION_LINES})
    if(LINE MATCHES "^BUILD_MAJOR_VERSION = ([0-9]+)")
        set(OPENXTALK_VERSION_MAJOR ${CMAKE_MATCH_1})
    elseif(LINE MATCHES "^BUILD_MINOR_VERSION = ([0-9]+)")
        set(OPENXTALK_VERSION_MINOR ${CMAKE_MATCH_1})
    elseif(LINE MATCHES "^BUILD_POINT_VERSION = ([0-9]+)")
        set(OPENXTALK_VERSION_PATCH ${CMAKE_MATCH_1})
    elseif(LINE MATCHES "^BUILD_REVISION = ([0-9]+)")
        set(OPENXTALK_VERSION_BUILD ${CMAKE_MATCH_1})
    endif()
endforeach()

# Project definition
project(OpenXTalk
    VERSION ${OPENXTALK_VERSION_MAJOR}.${OPENXTALK_VERSION_MINOR}.${OPENXTALK_VERSION_PATCH}
    DESCRIPTION "OpenXTalk Community Edition - Cross-platform application development environment"
    LANGUAGES C CXX OBJC OBJCXX
)

# Git revision
execute_process(
    COMMAND git rev-parse HEAD
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    OUTPUT_VARIABLE OPENXTALK_GIT_REVISION
    OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_QUIET
)

message(STATUS "OpenXTalk version: ${PROJECT_VERSION} (build ${OPENXTALK_VERSION_BUILD})")
message(STATUS "Git revision: ${OPENXTALK_GIT_REVISION}")

# CMake module path for our custom find modules
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules")

# Build type defaults to Debug if not specified
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE "Debug" CACHE STRING "Build type" FORCE)
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release" "Fast")
endif()
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")

# C++ Standard - C++11 as per the original build system
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# C Standard
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Position Independent Code (required for shared libraries)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# Output directories
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

# Platform detection and configuration
if(APPLE)
    include(cmake/platforms/Darwin.cmake)
    if(IOS)
        include(cmake/platforms/iOS.cmake)
    else()
        include(cmake/platforms/macOS.cmake)
    endif()
elseif(WIN32)
    include(cmake/platforms/Windows.cmake)
elseif(UNIX AND NOT APPLE)
    if(ANDROID)
        include(cmake/platforms/Android.cmake)
    else()
        include(cmake/platforms/Linux.cmake)
    endif()
elseif(EMSCRIPTEN)
    include(cmake/platforms/Emscripten.cmake)
endif()

# Common compile definitions
add_compile_definitions(
    $<$<CONFIG:Debug>:_DEBUG>
    $<$<CONFIG:Release>:_RELEASE>
    $<$<CONFIG:Release>:NDEBUG>
    $<$<CONFIG:Fast>:_RELEASE>
    $<$<CONFIG:Fast>:NDEBUG>
)

# Build options
option(BUILD_TESTING "Build test targets" ON)
option(BUILD_IDE "Build the IDE (development) engine" ON)
option(BUILD_STANDALONE "Build the standalone engine" ON)
option(BUILD_SERVER "Build the server engine" ON)
option(BUILD_INSTALLER "Build the installer engine" ON)

# Engine mode definitions
set(OPENXTALK_ENGINE_MODES)
if(BUILD_IDE)
    list(APPEND OPENXTALK_ENGINE_MODES development)
endif()
if(BUILD_STANDALONE)
    list(APPEND OPENXTALK_ENGINE_MODES standalone)
endif()
if(BUILD_SERVER)
    list(APPEND OPENXTALK_ENGINE_MODES server)
endif()
if(BUILD_INSTALLER)
    list(APPEND OPENXTALK_ENGINE_MODES installer)
endif()

message(STATUS "Engine modes: ${OPENXTALK_ENGINE_MODES}")

# Prebuilt libraries location
set(OPENXTALK_PREBUILT_DIR "${CMAKE_SOURCE_DIR}/prebuilt")
message(STATUS "Prebuilt directory: ${OPENXTALK_PREBUILT_DIR}")

# Third-party libraries location
set(OPENXTALK_THIRDPARTY_DIR "${CMAKE_SOURCE_DIR}/thirdparty")
message(STATUS "Third-party directory: ${OPENXTALK_THIRDPARTY_DIR}")

# Find required prebuilt dependencies
# Note: These may not be found initially; the build will use thirdparty sources
find_package(ICU)
find_package(OpenSSL)
find_package(ZLIB)
find_package(CURL)

if(NOT ICU_FOUND)
    message(STATUS "ICU not found in prebuilt - will be provided by thirdparty or system")
endif()
if(NOT OPENSSL_FOUND)
    message(STATUS "OpenSSL not found in prebuilt - will be provided by thirdparty or system")
endif()
if(NOT ZLIB_FOUND)
    message(STATUS "ZLIB not found in prebuilt - will be built from thirdparty sources")
endif()
if(NOT CURL_FOUND)
    message(STATUS "CURL not found in prebuilt - will be provided by thirdparty or system")
endif()

# Third-party libraries (built from source)
# Must come before core libraries since they depend on these
add_subdirectory(thirdparty)

# Core libraries (in dependency order)
add_subdirectory(libcore)
add_subdirectory(libfoundation)
add_subdirectory(libgraphics)
add_subdirectory(libscript)

# Toolchain (LCB compiler)
add_subdirectory(toolchain)

# External libraries
add_subdirectory(libexternal)
add_subdirectory(libexternalv1)
add_subdirectory(libbrowser)

# Engine
add_subdirectory(engine)

# Extensions
add_subdirectory(extensions)

# Externals (runtime plugins)
add_subdirectory(revdb)
add_subdirectory(revxml)
add_subdirectory(revzip)
add_subdirectory(revpdfprinter)
if(NOT APPLE OR NOT IOS)
    add_subdirectory(revbrowser)
    add_subdirectory(revmobile)
    add_subdirectory(revspeech)
endif()

# lcidlc tool
add_subdirectory(lcidlc)

# Tests
if(BUILD_TESTING)
    enable_testing()
    add_subdirectory(libcpptest)
    # Test targets are defined in individual library CMakeLists.txt files
endif()

# Installation rules
include(GNUInstallDirs)

# Summary
message(STATUS "")
message(STATUS "OpenXTalk Configuration Summary:")
message(STATUS "  Version:        ${PROJECT_VERSION}")
message(STATUS "  Build type:     ${CMAKE_BUILD_TYPE}")
message(STATUS "  Platform:       ${CMAKE_SYSTEM_NAME}")
message(STATUS "  Architecture:   ${CMAKE_SYSTEM_PROCESSOR}")
if(APPLE)
    message(STATUS "  macOS SDK:      ${CMAKE_OSX_SYSROOT}")
    message(STATUS "  Deployment:     ${CMAKE_OSX_DEPLOYMENT_TARGET}")
    message(STATUS "  Architectures:  ${CMAKE_OSX_ARCHITECTURES}")
endif()
message(STATUS "  C Compiler:     ${CMAKE_C_COMPILER}")
message(STATUS "  CXX Compiler:   ${CMAKE_CXX_COMPILER}")
message(STATUS "")
