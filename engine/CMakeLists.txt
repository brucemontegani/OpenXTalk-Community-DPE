# engine - OpenXTalk Engine
# Main execution engine for the IDE, standalone, server, and installer

message(STATUS "Configuring engine")

# ============================================================================
# Generated files
# ============================================================================
# hashedstrings.cpp is generated from lextable.cpp using util/hash_strings.pl
# For now, copy the existing generated file from the cache if available
set(ENGINE_GENERATED_DIR "${CMAKE_CURRENT_BINARY_DIR}/generated")
file(MAKE_DIRECTORY "${ENGINE_GENERATED_DIR}")

set(HASHEDSTRINGS_SRC "${CMAKE_CURRENT_SOURCE_DIR}/../_cache/mac/kernel-standalone.build/DerivedSources/Debug/src/hashedstrings.cpp")
set(HASHEDSTRINGS_DST "${ENGINE_GENERATED_DIR}/hashedstrings.cpp")

if(EXISTS "${HASHEDSTRINGS_SRC}")
    configure_file("${HASHEDSTRINGS_SRC}" "${HASHEDSTRINGS_DST}" COPYONLY)
    message(STATUS "Copied hashedstrings.cpp from cache")
else()
    # Create a stub file if the cached version doesn't exist
    message(WARNING "hashedstrings.cpp not found in cache - IDE colorization may not work")
    file(WRITE "${HASHEDSTRINGS_DST}" "// Stub hashedstrings.cpp - needs to be generated\n")
endif()

# OpenSSL weak-link stubs - these provide runtime-loadable SSL support
set(SSL_STUBS_SRC "${CMAKE_SOURCE_DIR}/_cache/mac/libopenssl.build/DerivedSources/Debug/src/ssl.mac.stubs.cpp")
set(SSL_STUBS_DST "${ENGINE_GENERATED_DIR}/ssl.mac.stubs.cpp")
if(EXISTS "${SSL_STUBS_SRC}" AND APPLE AND NOT IOS)
    configure_file("${SSL_STUBS_SRC}" "${SSL_STUBS_DST}" COPYONLY)
    set(ENGINE_SSL_STUBS_SOURCE "${SSL_STUBS_DST}")
    message(STATUS "Copied SSL stubs from cache")
else()
    set(ENGINE_SSL_STUBS_SOURCE "")
endif()

# ============================================================================
# Gather engine source files
# ============================================================================

# Get all C++ source files
file(GLOB ENGINE_ALL_CPP "${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp")
file(GLOB ENGINE_ALL_MM "${CMAKE_CURRENT_SOURCE_DIR}/src/*.mm")

# Filter out platform-specific sources by pattern
set(ENGINE_COMMON_SOURCES)
set(ENGINE_MACOS_SOURCES)
set(ENGINE_LINUX_SOURCES)
set(ENGINE_WINDOWS_SOURCES)
set(ENGINE_IOS_SOURCES)
set(ENGINE_ANDROID_SOURCES)

foreach(SOURCE_FILE ${ENGINE_ALL_CPP})
    get_filename_component(FILENAME ${SOURCE_FILE} NAME)

    # Categorize by filename prefix and patterns
    # Order matters: more specific patterns first
    if(FILENAME MATCHES "^(lnx|linux|syslnx|native-layer-x11|dsklnx)")
        list(APPEND ENGINE_LINUX_SOURCES ${SOURCE_FILE})
    elseif(FILENAME MATCHES "^(w32|win|sysw32|srvwindows|native-layer-win32|dskw32)")
        list(APPEND ENGINE_WINDOWS_SOURCES ${SOURCE_FILE})
    elseif(FILENAME MATCHES "^(osx|mac-|sysosx|syscfdate|native-layer-mac|dskmac)")
        list(APPEND ENGINE_MACOS_SOURCES ${SOURCE_FILE})
    elseif(FILENAME MATCHES "^(ios-|iphone|mbliphone|native-layer-ios)")
        # iOS-specific files (check mbliphone before generic mbl)
        list(APPEND ENGINE_IOS_SOURCES ${SOURCE_FILE})
    elseif(FILENAME MATCHES "^(android|mblandroid|native-layer-android)")
        # Android-specific files (check mblandroid before generic mbl)
        list(APPEND ENGINE_ANDROID_SOURCES ${SOURCE_FILE})
    elseif(FILENAME MATCHES "^mbl")
        # Generic mobile files (mbldc, mblcontrol, mblstore, etc.)
        # These are for iOS and Android, not desktop
        list(APPEND ENGINE_IOS_SOURCES ${SOURCE_FILE})
        list(APPEND ENGINE_ANDROID_SOURCES ${SOURCE_FILE})
    elseif(FILENAME MATCHES "^(em-|emscripten)")
        # Skip emscripten sources
    elseif(FILENAME MATCHES "^(sysunx)")
        # sysunx sources are shared POSIX code used on macOS and Linux
        # Specific files excluded per-platform below
        list(APPEND ENGINE_COMMON_SOURCES ${SOURCE_FILE})
    elseif(FILENAME MATCHES "_lnx\\.cpp$|_linux\\.cpp$")
        # Files ending with _lnx or _linux are Linux-specific
        list(APPEND ENGINE_LINUX_SOURCES ${SOURCE_FILE})
    elseif(FILENAME MATCHES "_w32\\.cpp$|_win\\.cpp$|_win32\\.cpp$")
        # Files ending with _w32 or _win are Windows-specific
        list(APPEND ENGINE_WINDOWS_SOURCES ${SOURCE_FILE})
    elseif(FILENAME MATCHES "_mac\\.cpp$|_osx\\.cpp$")
        # Files ending with _mac or _osx are macOS-specific
        list(APPEND ENGINE_MACOS_SOURCES ${SOURCE_FILE})
    else()
        list(APPEND ENGINE_COMMON_SOURCES ${SOURCE_FILE})
    endif()
endforeach()

# Filter .mm files by platform (macOS vs iOS)
foreach(SOURCE_FILE ${ENGINE_ALL_MM})
    get_filename_component(FILENAME ${SOURCE_FILE} NAME)
    # iOS-specific .mm files: ios-*, iphone*, mbliphone*, native-layer-ios*
    if(FILENAME MATCHES "^(ios-|iphone|mbliphone|native-layer-ios)")
        list(APPEND ENGINE_IOS_SOURCES ${SOURCE_FILE})
    else()
        list(APPEND ENGINE_MACOS_SOURCES ${SOURCE_FILE})
    endif()
endforeach()

# Build the appropriate source list for this platform
set(ENGINE_PLATFORM_SOURCES)
if(APPLE AND NOT IOS)
    set(ENGINE_PLATFORM_SOURCES ${ENGINE_MACOS_SOURCES})
elseif(IOS)
    set(ENGINE_PLATFORM_SOURCES ${ENGINE_IOS_SOURCES})
elseif(UNIX AND NOT APPLE)
    set(ENGINE_PLATFORM_SOURCES ${ENGINE_LINUX_SOURCES})
elseif(WIN32)
    set(ENGINE_PLATFORM_SOURCES ${ENGINE_WINDOWS_SOURCES})
endif()

# Exclude files that have platform-specific #error directives
# These files are only for specific platforms (iOS, Android, etc.)
set(ENGINE_EXCLUDE_MACOS
    tilecachegl.cpp     # iOS/Android only (OpenGL ES)
    mbldc.cpp           # Mobile only
    mbliphoneapp.cpp    # iOS only
    mblcontrol.cpp      # Mobile only
    mblstore.cpp        # Mobile only
    mblsensor.cpp       # Mobile only
    mblcalendar.cpp     # Mobile only
    mblcontact.cpp      # Mobile only
    mblandroid*.cpp     # Android only
    # deploy.cpp is needed for the IDE (MCIdeDiet, MCIdeSign classes)
    mode_development.cpp  # Needs MODE_DEVELOPMENT defined
    mode_standalone.cpp   # Needs MODE_STANDALONE defined
    mode_server.cpp       # Needs MODE_SERVER defined
    mode_installer.cpp    # Needs MODE_INSTALLER defined
    internal_development.cpp  # Needs MODE_DEVELOPMENT defined
    # Deploy files are only for development (IDE) mode
    deploy.cpp
    deploy_capsule.cpp
    deploy_dmg.cpp
    deploy_emscripten.cpp
    deploy_file.cpp
    deploy_linux.cpp
    deploy_macosx.cpp
    deploy_sign.cpp
    deploy_windows.cpp
    deploysecurity.cpp
    bsdiff_build.cpp
    ide.cpp
    lextable.cpp          # Compiled in mode targets, not common
    # Server-only files (conflict with desktop player code)
    player-srv-stubs.cpp
    native-layer-srv.cpp
    srvspec.cpp
    srvstack.cpp
    srvtheme.cpp
    # sysunx files excluded on macOS (have macOS-specific equivalents)
    sysunxdate.cpp
    sysunxrandom.cpp
    sysunxregion.cpp
    # Files on disk but NOT in GYP build (legacy/unused/test files)
    test.cpp
    mode_test.cpp
    paragraph.cpp        # Old unused file
    prefix.cpp           # Precompiled header
    stacktile.cpp        # Not in GYP
    sysunxthreads.cpp    # Not in GYP (different threading API)
    dummystartupstack.cpp
    mblandroidad.cpp     # Android only
    main.cpp             # Handled separately
    # Files included by other files (not compiled separately)
    rgb.cpp              # Included by uidc.cpp
    ports.cpp            # Included by socket files
    props.cpp            # Included by property files
    icondata.cpp         # Included by icon files
    hashedstrings.cpp    # Included by hashed string files
    # Experimental/WIP text system (commented out in GYP)
    text-pane.cpp
    text-paragraph.cpp
    text-line.cpp
    text-segment.cpp
    text-run.cpp
    text-block.cpp
    text-cell.cpp
    text-breakblock.cpp
    text-simplebreakingengine.cpp
)

if(APPLE AND NOT IOS)
    foreach(EXCLUDE_PATTERN ${ENGINE_EXCLUDE_MACOS})
        list(FILTER ENGINE_COMMON_SOURCES EXCLUDE REGEX ".*/${EXCLUDE_PATTERN}$")
    endforeach()
endif()

# Combined sources for this platform
set(ENGINE_SOURCES ${ENGINE_COMMON_SOURCES} ${ENGINE_PLATFORM_SOURCES})

# Debug output
list(LENGTH ENGINE_COMMON_SOURCES COMMON_COUNT)
list(LENGTH ENGINE_PLATFORM_SOURCES PLATFORM_COUNT)
message(STATUS "Engine: ${COMMON_COUNT} common sources, ${PLATFORM_COUNT} platform sources")

# ============================================================================
# Engine common library (shared code)
# ============================================================================
# Add SSL stubs if available
set(ENGINE_ADDITIONAL_SOURCES)
if(ENGINE_SSL_STUBS_SOURCE)
    list(APPEND ENGINE_ADDITIONAL_SOURCES ${ENGINE_SSL_STUBS_SOURCE})
endif()

add_library(engine-common STATIC ${ENGINE_SOURCES} ${ENGINE_ADDITIONAL_SOURCES})

target_include_directories(engine-common
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<BUILD_INTERFACE:${CMAKE_BINARY_DIR}/include>
    PRIVATE
        # Generated files (hashedstrings.cpp, etc.)
        ${ENGINE_GENERATED_DIR}
        ${OPENXTALK_THIRDPARTY_DIR}/libpcre/include
        ${OPENXTALK_THIRDPARTY_DIR}/libpcre/src
        # Image library includes
        ${OPENXTALK_THIRDPARTY_DIR}/libpng/include
        ${OPENXTALK_THIRDPARTY_DIR}/libpng/src
        ${OPENXTALK_THIRDPARTY_DIR}/libjpeg/include
        ${OPENXTALK_THIRDPARTY_DIR}/libjpeg/src
        ${OPENXTALK_THIRDPARTY_DIR}/libgif/include
        ${OPENXTALK_THIRDPARTY_DIR}/libgif/src
        # Font/text rendering includes
        ${OPENXTALK_THIRDPARTY_DIR}/libfreetype/include
        ${OPENXTALK_THIRDPARTY_DIR}/libfreetype/include/freetype
        ${OPENXTALK_THIRDPARTY_DIR}/libharfbuzz/src
        # Other library includes
        ${CMAKE_SOURCE_DIR}/libbrowser/include
        ${CMAKE_SOURCE_DIR}/libexternal/include
)

target_compile_definitions(engine-common
    PRIVATE
        # Platform settings
        $<$<PLATFORM_ID:Darwin>:TARGET_PLATFORM_MACOS_X>
        $<$<PLATFORM_ID:Darwin>:_MACOSX>
        $<$<PLATFORM_ID:Darwin>:_MAC_DESKTOP>
        $<$<PLATFORM_ID:Darwin>:_MAC_SERVER>
        $<$<PLATFORM_ID:Darwin>:_DARWIN_SERVER>
        # Feature flags that must be defined before prefix.h is included
        $<$<PLATFORM_ID:Darwin>:FEATURE_PLATFORM_PLAYER>
        $<$<PLATFORM_ID:Darwin>:FEATURE_PLATFORM_APPLICATION>
        $<$<PLATFORM_ID:Darwin>:FEATURE_PLATFORM_WINDOW>
        $<$<PLATFORM_ID:Darwin>:FEATURE_PLATFORM_RECORDER>
        $<$<PLATFORM_ID:Darwin>:FEATURE_PLATFORM_AUDIO>
        $<$<PLATFORM_ID:Linux>:TARGET_PLATFORM_LINUX>
        $<$<PLATFORM_ID:Linux>:_LINUX>
        $<$<PLATFORM_ID:Linux>:_LINUX_DESKTOP>
        $<$<PLATFORM_ID:Linux>:_LINUX_SERVER>
        $<$<PLATFORM_ID:Windows>:TARGET_PLATFORM_WINDOWS>
        $<$<PLATFORM_ID:Windows>:_WINDOWS>
)

target_link_libraries(engine-common
    PUBLIC
        libFoundation
        libGraphics
        libScript
    PRIVATE
        libpng
        libjpeg
        libgif
        libpcre
)

# macOS-specific link libraries
if(APPLE AND NOT IOS)
    target_link_libraries(engine-common
        PRIVATE
            "-framework AppKit"
            "-framework Cocoa"
            "-framework Carbon"
            "-framework Security"
            "-framework SystemConfiguration"
            "-framework IOKit"
            "-framework CoreServices"
            "-framework CoreGraphics"
            "-framework CoreText"
            "-framework ImageIO"
            "-framework AudioToolbox"
            "-framework AudioUnit"
            "-framework AVFoundation"
            "-framework CoreMedia"
            "-framework CoreVideo"
            "-framework QuartzCore"
            "-framework WebKit"
            "-framework Accelerate"
            "-framework CoreFoundation"
            "-framework Foundation"
            "-framework MediaToolbox"
    )
    # CUPS for printing
    if(OPENXTALK_CUPS_LIBRARY)
        target_link_libraries(engine-common PRIVATE ${OPENXTALK_CUPS_LIBRARY})
    endif()

    # Skia graphics library (built from source)
    if(TARGET libskia)
        target_link_libraries(engine-common PRIVATE libskia)
    endif()

    # OpenSSL (custom build for weak linking)
    if(EXISTS "${CMAKE_SOURCE_DIR}/prebuilt/lib/mac/libcustomssl.a")
        target_link_libraries(engine-common PRIVATE
            "${CMAKE_SOURCE_DIR}/prebuilt/lib/mac/libcustomssl.a"
            "${CMAKE_SOURCE_DIR}/prebuilt/lib/mac/libcustomcrypto.a"
        )
    endif()
endif()

# Silence warnings for engine code (lots of legacy code)
if(CMAKE_CXX_COMPILER_ID MATCHES "Clang|GNU")
    target_compile_options(engine-common PRIVATE
        -Wno-deprecated-declarations
        -Wno-unused-variable
        -Wno-unused-function
        -Wno-sign-compare
        -Wno-switch
    )
endif()

# ============================================================================
# Kernel library (core engine functionality)
# ============================================================================
add_library(kernel STATIC
    ${CMAKE_CURRENT_SOURCE_DIR}/src/dummy.cpp
)

if(NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/src/dummy.cpp")
    file(WRITE "${CMAKE_CURRENT_SOURCE_DIR}/src/dummy.cpp" "// Placeholder for kernel-specific code\n")
endif()

target_link_libraries(kernel
    PUBLIC
        engine-common
)

# ============================================================================
# Engine variants
# ============================================================================

# Development engine (IDE)
# Generate encodederrors.cpp from error header files
# The Perl script encode_errors.pl produces this from executionerrors.h and parseerrors.h
set(ENCODEDERRORS_SRC "${ENGINE_GENERATED_DIR}/encodederrors.cpp")
set(ENCODEDERRORS_CACHE "${CMAKE_SOURCE_DIR}/_cache/mac/kernel-standalone.build/DerivedSources/Debug/src/encodederrors.cpp")

if(NOT EXISTS "${ENCODEDERRORS_SRC}")
    # Try to generate with Perl script
    find_program(PERL_EXECUTABLE perl)
    if(PERL_EXECUTABLE AND EXISTS "${CMAKE_SOURCE_DIR}/util/encode_errors.pl")
        execute_process(
            COMMAND ${PERL_EXECUTABLE} "${CMAKE_SOURCE_DIR}/util/encode_errors.pl"
                    "${CMAKE_CURRENT_SOURCE_DIR}/src" "${ENCODEDERRORS_SRC}"
            RESULT_VARIABLE ENCODE_ERRORS_RESULT
        )
        if(NOT ENCODE_ERRORS_RESULT EQUAL 0)
            # Fall back to cached version
            if(EXISTS "${ENCODEDERRORS_CACHE}")
                configure_file("${ENCODEDERRORS_CACHE}" "${ENCODEDERRORS_SRC}" COPYONLY)
                message(STATUS "Using cached encodederrors.cpp")
            else()
                message(WARNING "encodederrors.cpp not available - error messages will be empty")
            endif()
        else()
            message(STATUS "Generated encodederrors.cpp from error headers")
        endif()
    elseif(EXISTS "${ENCODEDERRORS_CACHE}")
        configure_file("${ENCODEDERRORS_CACHE}" "${ENCODEDERRORS_SRC}" COPYONLY)
        message(STATUS "Using cached encodederrors.cpp")
    else()
        message(WARNING "encodederrors.cpp not available - error messages will be empty")
    endif()
endif()

# Mode-dependent files needed by ALL engine targets (development, standalone, server, installer)
# In GYP, kernel-mode-template.gypi adds these to every mode target
set(ENGINE_MODE_DEPENDENT_FILES
    ${CMAKE_CURRENT_SOURCE_DIR}/src/lextable.cpp
)
# encodederrors.cpp provides MCexecutionerrors/MCparsingerrors with real error strings.
# Standalone and installer modes define their own empty stubs in their mode_*.cpp files,
# so encodederrors.cpp must NOT be added to those targets (the GYP standalone build
# explicitly excludes it via sources!). Development and server modes need it.
set(ENGINE_ENCODEDERRORS_FILE)
if(EXISTS "${ENCODEDERRORS_SRC}")
    set(ENGINE_ENCODEDERRORS_FILE "${ENCODEDERRORS_SRC}")
endif()

if(BUILD_IDE AND NOT IOS AND NOT ANDROID)
    # Development mode sources (from engine_development_mode_source_files in GYP)
    set(DEV_MODE_SOURCES
        ${CMAKE_CURRENT_SOURCE_DIR}/src/main.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/src/mode_development.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/src/internal_development.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/src/dummystartupstack.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/src/deploy.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/src/deploy_capsule.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/src/deploy_dmg.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/src/deploy_emscripten.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/src/deploy_file.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/src/deploy_linux.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/src/deploy_macosx.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/src/deploy_sign.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/src/deploy_windows.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/src/deploysecurity.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/src/ide.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/src/bsdiff_build.cpp
        ${ENGINE_MODE_DEPENDENT_FILES}
        ${ENGINE_ENCODEDERRORS_FILE}
    )

    add_executable(development ${DEV_MODE_SOURCES})
    target_link_libraries(development PRIVATE kernel)

    target_compile_definitions(development PRIVATE
        MODE_DEVELOPMENT
        FEATURE_RELAUNCH_SUPPORT
    )

    # Include directories for mode files
    target_include_directories(development PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src
        ${ENGINE_GENERATED_DIR}
    )

    if(APPLE AND NOT IOS)
        set_target_properties(development PROPERTIES
            OUTPUT_NAME "LiveCode-Community"
        )
        openxtalk_configure_macos_app(development
            BUNDLE_ID "org.openxtalk.development"
            BUNDLE_NAME "LiveCode-Community"
            FRAMEWORKS ${OPENXTALK_MACOS_FRAMEWORKS}
        )
    endif()
endif()

# Standalone engine
if(BUILD_STANDALONE)
    add_executable(standalone
        ${CMAKE_CURRENT_SOURCE_DIR}/src/main.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/src/mode_standalone.cpp
        ${ENGINE_MODE_DEPENDENT_FILES}
    )
    target_link_libraries(standalone PRIVATE kernel)

    # Include directories for mode file
    target_include_directories(standalone PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src
        ${ENGINE_GENERATED_DIR}
    )

    target_compile_definitions(standalone PRIVATE
        MODE_STANDALONE
    )

    set_target_properties(standalone PROPERTIES
        OUTPUT_NAME "Standalone-Community"
    )

    if(APPLE AND NOT IOS)
        openxtalk_configure_macos_app(standalone
            BUNDLE_ID "org.openxtalk.standalone"
            BUNDLE_NAME "Standalone-Community"
            FRAMEWORKS ${OPENXTALK_MACOS_FRAMEWORKS}
        )
    endif()
endif()

# Server engine
if(BUILD_SERVER AND NOT IOS AND NOT ANDROID)
    add_executable(server
        ${CMAKE_CURRENT_SOURCE_DIR}/src/dummy.cpp
        ${ENGINE_MODE_DEPENDENT_FILES}
        ${ENGINE_ENCODEDERRORS_FILE}
    )
    target_link_libraries(server PRIVATE kernel)

    target_include_directories(server PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src
        ${ENGINE_GENERATED_DIR}
    )

    target_compile_definitions(server PRIVATE
        _SERVER
        MODE_SERVER
        $<$<PLATFORM_ID:Darwin>:_MAC_SERVER>
        $<$<PLATFORM_ID:Linux>:_LINUX_SERVER>
        $<$<PLATFORM_ID:Windows>:_WINDOWS_SERVER>
    )
endif()

# Installer engine
if(BUILD_INSTALLER AND NOT IOS AND NOT ANDROID)
    add_executable(installer
        ${CMAKE_CURRENT_SOURCE_DIR}/src/dummy.cpp
        ${ENGINE_MODE_DEPENDENT_FILES}
    )
    target_link_libraries(installer PRIVATE kernel)

    target_include_directories(installer PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src
        ${ENGINE_GENERATED_DIR}
    )

    target_compile_definitions(installer PRIVATE
        MODE_INSTALLER
    )
endif()

message(STATUS "Engine configured")
