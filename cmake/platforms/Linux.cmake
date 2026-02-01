# OpenXTalk - Linux Platform Configuration
# Settings specific to Linux builds

message(STATUS "Configuring for Linux")

# Platform definitions
add_compile_definitions(
    TARGET_PLATFORM_LINUX
    _LINUX
)

# Server mode definitions
set(OPENXTALK_SERVER_DEFINITIONS
    _SERVER
    _LINUX_SERVER
)

# Compiler flags
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fno-exceptions")

# Warning flags
add_compile_options(
    -Wall
    -Wextra
    -Wno-unused-parameter
)

# Prebuilt library paths
set(OPENXTALK_PREBUILT_LIB_DIR "${OPENXTALK_PREBUILT_DIR}/lib/linux/${CMAKE_SYSTEM_PROCESSOR}")
set(OPENXTALK_PREBUILT_INCLUDE_DIR "${OPENXTALK_PREBUILT_DIR}/include")

# Required system libraries
find_package(X11 REQUIRED)
find_package(Threads REQUIRED)

message(STATUS "Linux platform configured")
