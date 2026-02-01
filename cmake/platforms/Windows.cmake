# OpenXTalk - Windows Platform Configuration
# Settings specific to Windows builds

message(STATUS "Configuring for Windows")

# Platform definitions
add_compile_definitions(
    TARGET_PLATFORM_WINDOWS
    _WINDOWS
    WIN32
    _WIN32
)

# Server mode definitions
set(OPENXTALK_SERVER_DEFINITIONS
    _SERVER
    _WINDOWS_SERVER
)

# MSVC-specific settings
if(MSVC)
    # Disable specific warnings
    add_compile_options(
        /W3
        /wd4996  # Deprecated functions
        /wd4244  # Conversion warnings
    )

    # Use static runtime
    set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
endif()

# Prebuilt library paths
set(OPENXTALK_PREBUILT_LIB_DIR "${OPENXTALK_PREBUILT_DIR}/lib/win32/${CMAKE_SYSTEM_PROCESSOR}")
set(OPENXTALK_PREBUILT_INCLUDE_DIR "${OPENXTALK_PREBUILT_DIR}/include")

message(STATUS "Windows platform configured")
