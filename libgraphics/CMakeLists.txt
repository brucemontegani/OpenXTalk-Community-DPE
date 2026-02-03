# libgraphics - OpenXTalk Graphics Library
# Depends on libfoundation, skia, image libraries

# Header files
set(LIBGRAPHICS_HEADERS
    include/graphics.h
)

# Private header files
set(LIBGRAPHICS_PRIVATE_HEADERS
    src/graphics-internal.h
)

# Core source files (all platforms)
set(LIBGRAPHICS_SOURCES
    src/blur.cpp
    src/cachetable.cpp
    src/context.cpp
    src/drawing.cpp
    src/image.cpp
    src/legacygradients.cpp
    src/path.cpp
    src/region.cpp
    src/spread.cpp
    src/utils.cpp
    src/SkStippleMaskFilter.cpp
)

# Platform-specific text rendering sources
if(APPLE)
    # macOS and iOS use CoreText
    list(APPEND LIBGRAPHICS_SOURCES
        src/coretext-skia.cpp
    )
endif()

if(WIN32)
    # Windows uses DirectWrite
    list(APPEND LIBGRAPHICS_SOURCES
        src/directwrite-skia.cpp
    )
endif()

if(UNIX AND NOT APPLE AND NOT ANDROID AND NOT EMSCRIPTEN)
    # Linux uses Pango
    list(APPEND LIBGRAPHICS_SOURCES
        src/lnxtext.cpp
    )
endif()

if(ANDROID OR EMSCRIPTEN)
    # Android and Emscripten use HarfBuzz
    list(APPEND LIBGRAPHICS_SOURCES
        src/harfbuzztext.cpp
        src/hb-sk.cpp
    )
endif()

# Create the library
add_library(libGraphics STATIC
    ${LIBGRAPHICS_HEADERS}
    ${LIBGRAPHICS_PRIVATE_HEADERS}
    ${LIBGRAPHICS_SOURCES}
)

# Set the library output name
set_target_properties(libGraphics PROPERTIES
    OUTPUT_NAME "Graphics"
    PREFIX "lib"
)

# Include directories
# Skia includes and defines are propagated via the libskia target's PUBLIC interface
target_include_directories(libGraphics
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src
        # Additional Skia internal dirs needed by libGraphics
        ${OPENXTALK_THIRDPARTY_DIR}/libskia/src/image
        ${OPENXTALK_THIRDPARTY_DIR}/libskia/src/opts
        ${OPENXTALK_THIRDPARTY_DIR}/libskia/src/utils
)

# Dependencies
target_link_libraries(libGraphics
    PUBLIC
        libFoundation
)

# Third-party image libraries (from thirdparty directory)
if(TARGET libgif)
    target_link_libraries(libGraphics PRIVATE libgif)
endif()
if(TARGET libpng)
    target_link_libraries(libGraphics PRIVATE libpng)
endif()
if(TARGET libjpeg)
    target_link_libraries(libGraphics PRIVATE libjpeg)
endif()
if(TARGET libskia)
    target_link_libraries(libGraphics PRIVATE libskia)
endif()

# HarfBuzz and FreeType for Android/Emscripten
if(ANDROID OR EMSCRIPTEN)
    if(TARGET libfreetype)
        target_link_libraries(libGraphics PRIVATE libfreetype)
    endif()
    if(TARGET libharfbuzz)
        target_link_libraries(libGraphics PRIVATE libharfbuzz)
    endif()
    target_link_libraries(libGraphics PRIVATE ICU::ICU)
endif()

# Platform-specific link libraries
if(APPLE)
    target_link_libraries(libGraphics
        PRIVATE
            "-framework CoreGraphics"
            "-framework CoreText"
    )
endif()

# Create an alias for consistent naming
add_library(OpenXTalk::Graphics ALIAS libGraphics)
