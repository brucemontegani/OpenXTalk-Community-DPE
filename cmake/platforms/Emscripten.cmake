# OpenXTalk - Emscripten Platform Configuration
# Settings specific to WebAssembly/Emscripten builds

message(STATUS "Configuring for Emscripten/WebAssembly")

# Platform definitions
add_compile_definitions(
    TARGET_PLATFORM_EMSCRIPTEN
    _EMSCRIPTEN
    EMSCRIPTEN
)

# Prebuilt library paths
set(OPENXTALK_PREBUILT_LIB_DIR "${OPENXTALK_PREBUILT_DIR}/lib/emscripten/js")
set(OPENXTALK_PREBUILT_INCLUDE_DIR "${OPENXTALK_PREBUILT_DIR}/include")

message(STATUS "Emscripten platform configured")
