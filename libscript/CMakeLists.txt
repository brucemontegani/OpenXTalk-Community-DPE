# libscript - OpenXTalk Script Library
# Depends on libfoundation, libffi

# Public header files
set(LIBSCRIPT_PUBLIC_HEADERS
    include/libscript/script.h
    include/libscript/script-auto.h
)

# Private header files
set(LIBSCRIPT_PRIVATE_HEADERS
    src/script-private.h
    src/script-bytecode.hpp
    src/script-execute.hpp
    src/script-validate.hpp
)

# Core source files
set(LIBSCRIPT_SOURCES
    src/script-builder.cpp
    src/script-instance.cpp
    src/script-module.cpp
    src/script-object.cpp
    src/script-package.cpp
    src/script-execute.cpp
    src/script-error.cpp
)

# Apple-specific Objective-C source
if(APPLE)
    list(APPEND LIBSCRIPT_SOURCES
        src/script-execute-objc.mm
    )
endif()

# Create the library
add_library(libScript STATIC
    ${LIBSCRIPT_PUBLIC_HEADERS}
    ${LIBSCRIPT_PRIVATE_HEADERS}
    ${LIBSCRIPT_SOURCES}
)

# Set the library output name
set_target_properties(libScript PROPERTIES
    OUTPUT_NAME "Script"
    PREFIX "lib"
)

# Include directories
target_include_directories(libScript
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src
)

# Dependencies
target_link_libraries(libScript
    PUBLIC
        libFoundation
)

# Link libffi from thirdparty if available
if(TARGET libffi)
    target_link_libraries(libScript PRIVATE libffi)
else()
    find_library(FFI_LIBRARY ffi)
    if(FFI_LIBRARY)
        target_link_libraries(libScript PRIVATE ${FFI_LIBRARY})
    endif()
endif()

# Platform-specific link libraries
if(UNIX AND NOT APPLE)
    target_link_libraries(libScript PRIVATE dl)
endif()

# Create an alias for consistent naming
add_library(OpenXTalk::Script ALIAS libScript)

# ============================================================================
# stdscript - Standard Script Library
# ============================================================================

# stdscript source files (module implementations)
set(STDSCRIPT_SOURCES
    src/module-arithmetic.cpp
    src/module-array.cpp
    src/module-assert.cpp
    src/module-binary.cpp
    src/module-bitwise.cpp
    src/module-byte.cpp
    src/module-char.cpp
    src/module-codeunit.cpp
    src/module-date.cpp
    src/module-encoding.cpp
    src/module-file.cpp
    src/module-foreign.cpp
    src/module-java.cpp
    src/module-list.cpp
    src/module-logic.cpp
    src/module-math_foundation.cpp
    src/module-math.cpp
    src/module-sort.cpp
    src/module-stream.cpp
    src/module-string.cpp
    src/module-system.cpp
    src/module-type_convert.cpp
    src/module-type.cpp
    src/module-unittest.cpp
    src/module-unittest_IMPL.cpp
    src/module-url.cpp
)

# LCB source files (for reference - these need to be compiled by lc-compile)
set(STDSCRIPT_SYNTAX_LCB_FILES
    src/arithmetic.lcb
    src/array.lcb
    src/assert.lcb
    src/binary.lcb
    src/bitwise.lcb
    src/byte.lcb
    src/char.lcb
    src/codeunit.lcb
    src/date.lcb
    src/file.lcb
    src/foreign.lcb
    src/java.lcb
    src/list.lcb
    src/logic.lcb
    src/math.lcb
    src/math-foundation.lcb
    src/sort.lcb
    src/stream.lcb
    src/string.lcb
    src/system.lcb
    src/type.lcb
    src/type-convert.lcb
    src/unittest.lcb
)

set(STDSCRIPT_OTHER_LCB_FILES
    src/objc.lcb
    src/unittest-impl.lcb
)

# Create the stdscript library
add_library(stdscript STATIC
    ${STDSCRIPT_SOURCES}
)

# Set the library output name
set_target_properties(stdscript PROPERTIES
    OUTPUT_NAME "stdscript"
)

# Include directories
target_include_directories(stdscript
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/include
        ${CMAKE_CURRENT_SOURCE_DIR}/src
)

# Dependencies
target_link_libraries(stdscript
    PUBLIC
        libScript
        libFoundation
)

# Create an alias for consistent naming
add_library(OpenXTalk::StdScript ALIAS stdscript)
