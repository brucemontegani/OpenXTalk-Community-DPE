# toolchain - LiveCode Builder (LCB) Compiler Toolchain
# Contains lc-compile, lc-run, and parser generators

message(STATUS "Configuring toolchain")

# Parser generator tools (gentle, reflex) - needed to build the compiler
# These are host tools used during the build process

# ============================================================================
# gentle - Parser generator
# ============================================================================
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/gentle/gentle/grts.c")
    # Gentle runtime support library
    # Note: grts.c uses pre-C99 style code, so we need to disable some warnings
    add_library(grts STATIC
        gentle/gentle/grts.c
    )
    target_include_directories(grts PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/gentle/gentle>
    )
    # Silence warnings for this old-style C code
    # This code uses K&R style without explicit return types, which requires gnu89
    target_compile_options(grts PRIVATE -w -std=gnu89)

    # Gentle parser generator executable (host tool)
    # This needs to be built as a host tool for cross-compilation scenarios
    add_executable(gentle
        gentle/gentle/main.c
        gentle/gentle/cyfront.c
        gentle/gentle/input.c
        gentle/gentle/output.c
        gentle/gentle/msg.c
        gentle/gentle/symtab.c
        gentle/gentle/yytab.c
    )
    target_link_libraries(gentle PRIVATE grts)
    target_include_directories(gentle PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/gentle/gentle)
    # Old K&R style C code - need to disable many warnings/errors
    target_compile_options(gentle PRIVATE -w -std=gnu89 -Wno-error=return-type -Wno-return-type)
endif()

# ============================================================================
# reflex - Lexer generator
# ============================================================================
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/gentle/reflex/reflex.c")
    # Reflex lexer generator executable (host tool)
    add_executable(reflex
        gentle/reflex/reflex.c
    )
    target_compile_options(reflex PRIVATE -w -std=gnu89)
endif()

# ============================================================================
# libcompile - Compiler support library
# ============================================================================
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/libcompile")
    add_subdirectory(libcompile)
endif()

# ============================================================================
# lc-compile - LCB Compiler
# ============================================================================
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/lc-compile")
    add_subdirectory(lc-compile)
endif()

message(STATUS "Toolchain configured")
