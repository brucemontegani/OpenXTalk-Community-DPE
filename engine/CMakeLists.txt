# engine - OpenXTalk Engine
# Main execution engine for the IDE, standalone, server, and installer

message(STATUS "Configuring engine")

# Engine source files are extensive (~735 C++ files)
# They are organized by the engine-sources.gypi file

# For now, create placeholder targets
# Full implementation would parse engine-sources.gypi

# ============================================================================
# Engine common library (shared code)
# ============================================================================
add_library(engine-common STATIC
    # Placeholder - actual sources from engine-sources.gypi
    src/dummy.cpp
)

if(NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/src/dummy.cpp")
    file(WRITE "${CMAKE_CURRENT_SOURCE_DIR}/src/dummy.cpp" "// Placeholder\n")
endif()

target_include_directories(engine-common
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
)

target_link_libraries(engine-common
    PUBLIC
        libFoundation
        libGraphics
        libScript
)

# ============================================================================
# Kernel library (core engine functionality)
# ============================================================================
add_library(kernel STATIC
    # Placeholder - actual sources from kernel.gyp
    src/dummy.cpp
)

target_link_libraries(kernel
    PUBLIC
        engine-common
)

# ============================================================================
# Engine variants
# ============================================================================

# Development engine (IDE)
if(BUILD_IDE AND NOT IOS AND NOT ANDROID)
    add_executable(development
        # Placeholder - actual sources from kernel-development.gyp
        src/dummy.cpp
    )
    target_link_libraries(development PRIVATE kernel)

    if(APPLE AND NOT IOS)
        openxtalk_configure_macos_app(development
            BUNDLE_ID "org.openxtalk.development"
            BUNDLE_NAME "OpenXTalk"
            FRAMEWORKS ${OPENXTALK_MACOS_FRAMEWORKS}
        )
    endif()
endif()

# Standalone engine
if(BUILD_STANDALONE)
    add_executable(standalone
        # Placeholder - actual sources from kernel-standalone.gyp
        src/dummy.cpp
    )
    target_link_libraries(standalone PRIVATE kernel)

    if(APPLE AND NOT IOS)
        openxtalk_configure_macos_app(standalone
            BUNDLE_ID "org.openxtalk.standalone"
            BUNDLE_NAME "OpenXTalk Standalone"
            FRAMEWORKS ${OPENXTALK_MACOS_FRAMEWORKS}
        )
    endif()
endif()

# Server engine
if(BUILD_SERVER AND NOT IOS AND NOT ANDROID)
    add_executable(server
        # Placeholder - actual sources from kernel-server.gyp
        src/dummy.cpp
    )
    target_link_libraries(server PRIVATE kernel)

    # Server has special definitions
    target_compile_definitions(server PRIVATE
        _SERVER
        $<$<PLATFORM_ID:Darwin>:_MAC_SERVER>
        $<$<PLATFORM_ID:Linux>:_LINUX_SERVER>
        $<$<PLATFORM_ID:Windows>:_WINDOWS_SERVER>
    )
endif()

# Installer engine
if(BUILD_INSTALLER AND NOT IOS AND NOT ANDROID)
    add_executable(installer
        # Placeholder - actual sources from kernel-installer.gyp
        src/dummy.cpp
    )
    target_link_libraries(installer PRIVATE kernel)
endif()

message(STATUS "Engine configured")
