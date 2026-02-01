# libcore - OpenXTalk Core Library
# Foundation library with no dependencies

# Public header files
set(LIBCORE_HEADERS
    include/atlsubset.h
    include/core.h
    include/filesystem.h
    include/thread.h
    include/thunk.h
)

# Source files
set(LIBCORE_SOURCES
    src/core.cpp
    src/filesystem.cpp
    src/thread.cpp
)

# Windows-only sources
if(WIN32)
    list(APPEND LIBCORE_SOURCES
        src/thunk.cpp
    )
endif()

# Create the library
add_library(libCore STATIC
    ${LIBCORE_HEADERS}
    ${LIBCORE_SOURCES}
)

# Set the library output name (without 'lib' prefix on Unix)
set_target_properties(libCore PROPERTIES
    OUTPUT_NAME "Core"
    PREFIX "lib"
)

# Include directories
target_include_directories(libCore
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src
)

# Windows-specific link libraries
if(WIN32)
    target_link_libraries(libCore
        PRIVATE
            oleaut32
    )
endif()

# Create an alias for consistent naming in the project
add_library(OpenXTalk::Core ALIAS libCore)
