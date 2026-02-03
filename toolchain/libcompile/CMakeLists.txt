# libcompile - Compiler support library for LCB compiler
message(STATUS "Configuring libcompile")

add_library(libcompile STATIC
    src/allocate.cpp
    src/literal.c
    src/output.cpp
    src/position.c
    src/report.c
)

target_include_directories(libcompile
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
)

target_link_libraries(libcompile
    PUBLIC
        libFoundation
        libScript
        libffi
)
