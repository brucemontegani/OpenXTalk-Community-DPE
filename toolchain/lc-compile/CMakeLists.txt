# lc-compile - LiveCode Builder Compiler
message(STATUS "Configuring lc-compile")

set(LC_COMPILE_SRC_DIR "${CMAKE_CURRENT_SOURCE_DIR}/src")

# ============================================================================
# LCB syntax files needed for --bootstrap
# ============================================================================

# Engine syntax files (from engine/src/)
set(ENGINE_SYNTAX_LCB_FILES
    "${CMAKE_SOURCE_DIR}/engine/src/canvas.lcb"
    "${CMAKE_SOURCE_DIR}/engine/src/engine.lcb"
    "${CMAKE_SOURCE_DIR}/engine/src/widget.lcb"
)

# Engine syntax-only files (contain syntax but not compiled into engine)
set(ENGINE_SYNTAX_ONLY_LCB_FILES
    "${CMAKE_SOURCE_DIR}/engine/src/license.lcb"
)

# All engine syntax files for bootstrap
set(ALL_ENGINE_SYNTAX_FILES
    ${ENGINE_SYNTAX_LCB_FILES}
    ${ENGINE_SYNTAX_ONLY_LCB_FILES}
)

# Stdscript syntax files (from libscript/src/)
set(STDSCRIPT_SYNTAX_LCB_FILES
    "${CMAKE_SOURCE_DIR}/libscript/src/arithmetic.lcb"
    "${CMAKE_SOURCE_DIR}/libscript/src/array.lcb"
    "${CMAKE_SOURCE_DIR}/libscript/src/assert.lcb"
    "${CMAKE_SOURCE_DIR}/libscript/src/binary.lcb"
    "${CMAKE_SOURCE_DIR}/libscript/src/bitwise.lcb"
    "${CMAKE_SOURCE_DIR}/libscript/src/byte.lcb"
    "${CMAKE_SOURCE_DIR}/libscript/src/char.lcb"
    "${CMAKE_SOURCE_DIR}/libscript/src/codeunit.lcb"
    "${CMAKE_SOURCE_DIR}/libscript/src/date.lcb"
    "${CMAKE_SOURCE_DIR}/libscript/src/file.lcb"
    "${CMAKE_SOURCE_DIR}/libscript/src/foreign.lcb"
    "${CMAKE_SOURCE_DIR}/libscript/src/java.lcb"
    "${CMAKE_SOURCE_DIR}/libscript/src/list.lcb"
    "${CMAKE_SOURCE_DIR}/libscript/src/logic.lcb"
    "${CMAKE_SOURCE_DIR}/libscript/src/math.lcb"
    "${CMAKE_SOURCE_DIR}/libscript/src/math-foundation.lcb"
    "${CMAKE_SOURCE_DIR}/libscript/src/sort.lcb"
    "${CMAKE_SOURCE_DIR}/libscript/src/stream.lcb"
    "${CMAKE_SOURCE_DIR}/libscript/src/string.lcb"
    "${CMAKE_SOURCE_DIR}/libscript/src/system.lcb"
    "${CMAKE_SOURCE_DIR}/libscript/src/type.lcb"
    "${CMAKE_SOURCE_DIR}/libscript/src/type-convert.lcb"
    "${CMAKE_SOURCE_DIR}/libscript/src/unittest.lcb"
)

# Stdscript other files (for lc-run)
set(STDSCRIPT_OTHER_LCB_FILES
    "${CMAKE_SOURCE_DIR}/libscript/src/objc.lcb"
    "${CMAKE_SOURCE_DIR}/libscript/src/unittest-impl.lcb"
)

# All syntax files for bootstrap (engine + stdscript)
set(ALL_SYNTAX_FILES
    ${ALL_ENGINE_SYNTAX_FILES}
    ${STDSCRIPT_SYNTAX_LCB_FILES}
)

# ============================================================================
# Auxiliary grammar files, reflex sources
# ============================================================================

set(GENTLE_AUXILIARY_GRAMMARS
    "${LC_COMPILE_SRC_DIR}/bind.g"
    "${LC_COMPILE_SRC_DIR}/check.g"
    "${LC_COMPILE_SRC_DIR}/generate.g"
    "${LC_COMPILE_SRC_DIR}/support.g"
    "${LC_COMPILE_SRC_DIR}/syntax.g"
    "${LC_COMPILE_SRC_DIR}/types.g"
)

set(REFLEX_SOURCE_FILES
    "${LC_COMPILE_SRC_DIR}/COMMENTS.b"
    "${LC_COMPILE_SRC_DIR}/DOUBLE_LITERAL.t"
    "${LC_COMPILE_SRC_DIR}/END_OF_UNIT.t"
    "${LC_COMPILE_SRC_DIR}/ILLEGAL.b"
    "${LC_COMPILE_SRC_DIR}/INTEGER_LITERAL.t"
    "${LC_COMPILE_SRC_DIR}/LAYOUT.b"
    "${LC_COMPILE_SRC_DIR}/LEXDEF.b"
    "${LC_COMPILE_SRC_DIR}/LEXFUNC.b"
    "${LC_COMPILE_SRC_DIR}/LITBLOCK.b"
    "${LC_COMPILE_SRC_DIR}/NAME_LITERAL.t"
    "${LC_COMPILE_SRC_DIR}/NEXT_UNIT.t"
    "${LC_COMPILE_SRC_DIR}/SEPARATOR.t"
    "${LC_COMPILE_SRC_DIR}/SETPOS.b"
    "${LC_COMPILE_SRC_DIR}/STRING_LITERAL.t"
    "${LC_COMPILE_SRC_DIR}/YYSTYPE.b"
    "${LC_COMPILE_SRC_DIR}/YYWRAP.b"
)

# ============================================================================
# lc-compile-lib - Static library with compiler source files
# ============================================================================

add_library(lc-compile-lib STATIC
    src/main.c
    src/operator.c
    src/outputfile.c
    src/set.c
    src/syntax-gen.c
    src/emit.cpp
)

target_include_directories(lc-compile-lib PUBLIC
    "${LC_COMPILE_SRC_DIR}"
)

target_link_libraries(lc-compile-lib PUBLIC
    libFoundation
    libScript
    libcompile
    libffi
)

# ============================================================================
# Three-stage bootstrap compiler
# ============================================================================
#
# Stage 1 (lc-bootstrap-compile): Uses grammar.g directly, defines BOOTSTRAP
# Stage 2 (lc-compile-stage2): Uses stage 1 to bootstrap grammar_full.g
# Stage 3 (lc-compile-stage3): Uses stage 2 to bootstrap grammar_full.g -> final lc-compile
#
# Each stage runs:
#   1. (Stages 2-3) Previous stage's compiler with --bootstrap to generate grammar_full.g
#   2. gentle on the grammar -> gen.lit, gen.tkn, grammar[_full].c, gen.h, gen.y
#   3. gentle on 6 auxiliary grammars -> 6 .c files
#   4. reflex on lexer definitions + gen.lit/gen.tkn -> gen.l
#   5. flex on gen.l -> gen.l.c
#   6. bison on gen.y -> gen.y.c
#   7. Compile all generated .c files + dummy.cpp, link with lc-compile-lib

function(lc_compile_add_stage STAGE_NAME STAGE_OUTPUT_DIR)
    # Parse arguments
    cmake_parse_arguments(STAGE "IS_BOOTSTRAP" "PREV_STAGE_TARGET;GRAMMAR_FILE" "" ${ARGN})

    set(STAGE_DIR "${CMAKE_CURRENT_BINARY_DIR}/${STAGE_OUTPUT_DIR}")
    file(MAKE_DIRECTORY "${STAGE_DIR}")

    # Determine grammar file name (grammar.g for bootstrap, grammar_full.g for others)
    if(STAGE_IS_BOOTSTRAP)
        set(GRAMMAR_BASENAME "grammar")
    else()
        set(GRAMMAR_BASENAME "grammar_full")
    endif()

    # ---- Step 1: Bootstrap (stages 2-3 only) ----
    if(NOT STAGE_IS_BOOTSTRAP)
        add_custom_command(
            OUTPUT
                "${STAGE_DIR}/${GRAMMAR_BASENAME}.g"
                "${STAGE_DIR}/modules/lci/com.livecode.type.lci"
            COMMAND ${CMAKE_COMMAND} -E make_directory "${STAGE_DIR}/modules/lci"
            COMMAND $<TARGET_FILE:${STAGE_PREV_STAGE_TARGET}>
                --bootstrap
                --inputg "${LC_COMPILE_SRC_DIR}/grammar.g"
                --outputi "${STAGE_DIR}/modules/lci"
                --outputg "${STAGE_DIR}/${GRAMMAR_BASENAME}.g"
                ${ALL_SYNTAX_FILES}
            DEPENDS
                ${STAGE_PREV_STAGE_TARGET}
                "${LC_COMPILE_SRC_DIR}/grammar.g"
                ${ALL_SYNTAX_FILES}
            WORKING_DIRECTORY "${LC_COMPILE_SRC_DIR}"
            COMMENT "${STAGE_NAME}: Generating full grammar via bootstrap"
        )
        set(GRAMMAR_INPUT "${STAGE_DIR}/${GRAMMAR_BASENAME}.g")
    else()
        set(GRAMMAR_INPUT "${LC_COMPILE_SRC_DIR}/grammar.g")
    endif()

    # ---- Step 2: Run gentle on the main grammar ----
    add_custom_command(
        OUTPUT
            "${STAGE_DIR}/gen.lit"
            "${STAGE_DIR}/gen.tkn"
            "${STAGE_DIR}/${GRAMMAR_BASENAME}.c"
            "${STAGE_DIR}/gen.h"
            "${STAGE_DIR}/gen.y"
        COMMAND $<TARGET_FILE:gentle>
            -inputdir .
            "${GRAMMAR_INPUT}"
            "gen.lit=${STAGE_DIR}/gen.lit"
            "gen.tkn=${STAGE_DIR}/gen.tkn"
            "${GRAMMAR_BASENAME}.c=${STAGE_DIR}/${GRAMMAR_BASENAME}.c"
            "gen.h=${STAGE_DIR}/gen.h"
            "gen.y=${STAGE_DIR}/gen.y"
        DEPENDS
            gentle
            "${GRAMMAR_INPUT}"
        WORKING_DIRECTORY "${LC_COMPILE_SRC_DIR}"
        COMMENT "${STAGE_NAME}: Running gentle on ${GRAMMAR_BASENAME}.g"
    )

    # ---- Step 3: Run gentle on auxiliary grammars ----
    set(AUX_GENERATED_C_FILES)
    foreach(AUX_GRAMMAR ${GENTLE_AUXILIARY_GRAMMARS})
        get_filename_component(AUX_NAME "${AUX_GRAMMAR}" NAME_WE)
        set(AUX_OUTPUT "${STAGE_DIR}/${AUX_NAME}.c")
        list(APPEND AUX_GENERATED_C_FILES "${AUX_OUTPUT}")

        add_custom_command(
            OUTPUT "${AUX_OUTPUT}"
            COMMAND $<TARGET_FILE:gentle>
                -inputdir .
                "${AUX_NAME}.c=${AUX_OUTPUT}"
                "${AUX_GRAMMAR}"
            DEPENDS
                gentle
                "${AUX_GRAMMAR}"
                "${STAGE_DIR}/gen.lit"
                "${STAGE_DIR}/gen.tkn"
            WORKING_DIRECTORY "${LC_COMPILE_SRC_DIR}"
            COMMENT "${STAGE_NAME}: Running gentle on ${AUX_NAME}.g"
        )
    endforeach()

    # ---- Step 4: Run reflex on lexer definitions ----
    add_custom_command(
        OUTPUT "${STAGE_DIR}/gen.l"
        COMMAND $<TARGET_FILE:reflex>
            ${REFLEX_SOURCE_FILES}
            "gen.lit=${STAGE_DIR}/gen.lit"
            "gen.tkn=${STAGE_DIR}/gen.tkn"
            "gen.l=${STAGE_DIR}/gen.l"
        DEPENDS
            reflex
            ${REFLEX_SOURCE_FILES}
            "${STAGE_DIR}/gen.lit"
            "${STAGE_DIR}/gen.tkn"
        WORKING_DIRECTORY "${LC_COMPILE_SRC_DIR}"
        COMMENT "${STAGE_NAME}: Running reflex"
    )

    # ---- Step 5: Run flex on gen.l ----
    add_custom_command(
        OUTPUT "${STAGE_DIR}/gen.l.c"
        COMMAND flex -o "${STAGE_DIR}/gen.l.c" -w "${STAGE_DIR}/gen.l"
        DEPENDS "${STAGE_DIR}/gen.l"
        COMMENT "${STAGE_NAME}: Running flex"
    )

    # ---- Step 6: Run bison on gen.y ----
    add_custom_command(
        OUTPUT "${STAGE_DIR}/gen.y.c"
        COMMAND bison -o "${STAGE_DIR}/gen.y.c" "${STAGE_DIR}/gen.y"
        DEPENDS "${STAGE_DIR}/gen.y"
        COMMENT "${STAGE_NAME}: Running bison"
    )

    # ---- Step 7: Compile and link the stage executable ----
    set(ALL_GENERATED_C_FILES
        "${STAGE_DIR}/${GRAMMAR_BASENAME}.c"
        ${AUX_GENERATED_C_FILES}
        "${STAGE_DIR}/gen.l.c"
        "${STAGE_DIR}/gen.y.c"
    )

    add_executable(${STAGE_NAME}
        "${LC_COMPILE_SRC_DIR}/dummy.cpp"
        ${ALL_GENERATED_C_FILES}
    )

    # Generated C files need gnu89 and all warnings/errors suppressed
    # (K&R style code from gentle/flex/bison).
    # Apple Clang requires explicit -Wno-error=X for each -Werror=X set
    # via add_compile_options(), because -w alone does not suppress
    # warnings that have been promoted to errors.
    set_source_files_properties(
        ${ALL_GENERATED_C_FILES}
        PROPERTIES
            COMPILE_FLAGS
            "-std=gnu89 -w -Wno-error=return-type -Wno-error=declaration-after-statement -Wno-error=missing-declarations -Wno-error=shadow -Wno-error=unused-variable -Wno-error=missing-field-initializers -Wno-error=switch -Wno-error=parentheses -Wno-error=unreachable-code -Wno-error=uninitialized -Wno-error=tautological-compare -Wno-error=logical-not-parentheses -Wno-error=constant-logical-operand -Wno-error=enum-compare"
    )

    # gen.h must be on the include path
    target_include_directories(${STAGE_NAME} PRIVATE
        "${STAGE_DIR}"
        "${LC_COMPILE_SRC_DIR}"
    )

    target_link_libraries(${STAGE_NAME} PRIVATE
        lc-compile-lib
        libcompile
        grts
    )

    if(STAGE_IS_BOOTSTRAP)
        target_compile_definitions(${STAGE_NAME} PRIVATE BOOTSTRAP)
    endif()
endfunction()

# Stage 1: Bootstrap compiler (uses grammar.g directly)
lc_compile_add_stage(lc-bootstrap-compile stage1
    IS_BOOTSTRAP
)

# Stage 2: Uses stage 1 to bootstrap grammar_full.g
lc_compile_add_stage(lc-compile-stage2 stage2
    PREV_STAGE_TARGET lc-bootstrap-compile
)

# Stage 3: Uses stage 2 to bootstrap grammar_full.g -> final lc-compile
lc_compile_add_stage(lc-compile-stage3 stage3
    PREV_STAGE_TARGET lc-compile-stage2
)

# Set the final compiler output name to lc-compile
set_target_properties(lc-compile-stage3 PROPERTIES
    OUTPUT_NAME lc-compile
)

# ============================================================================
# lc-run - LCB module runner
# ============================================================================

set(LC_RUN_DIR "${CMAKE_CURRENT_BINARY_DIR}/lc-run")
file(MAKE_DIRECTORY "${LC_RUN_DIR}")

# All LCB files for lc-run (syntax + other)
set(LC_RUN_LCB_FILES
    ${STDSCRIPT_SYNTAX_LCB_FILES}
    ${STDSCRIPT_OTHER_LCB_FILES}
)

# Generate lc-run_lcb_modules.cpp using lc-compile-stage3 --bootstrap
add_custom_command(
    OUTPUT
        "${LC_RUN_DIR}/lc-run_lcb_modules.cpp"
        "${LC_RUN_DIR}/modules/lci/com.livecode.type.lci"
    COMMAND ${CMAKE_COMMAND} -E make_directory "${LC_RUN_DIR}/modules/lci"
    COMMAND $<TARGET_FILE:lc-compile-stage3>
        --bootstrap
        --inputg "${LC_COMPILE_SRC_DIR}/grammar.g"
        --outputi "${LC_RUN_DIR}/modules/lci"
        --outputc "${LC_RUN_DIR}/lc-run_lcb_modules.cpp"
        ${LC_RUN_LCB_FILES}
    DEPENDS
        lc-compile-stage3
        "${LC_COMPILE_SRC_DIR}/grammar.g"
        ${LC_RUN_LCB_FILES}
    WORKING_DIRECTORY "${LC_COMPILE_SRC_DIR}"
    COMMENT "Generating lc-run module list"
)

add_executable(lc-run
    src/lc-run.cpp
    "${LC_RUN_DIR}/lc-run_lcb_modules.cpp"
)

target_include_directories(lc-run PRIVATE
    "${LC_RUN_DIR}"
)

target_link_libraries(lc-run PRIVATE
    libFoundation
    libScript
    stdscript
    libffi
)
