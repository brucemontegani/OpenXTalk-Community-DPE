# lcidlc - IDL Compiler
# Compiles interface definition files for externals

message(STATUS "Configuring lcidlc")

if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/src")
    message(STATUS "lcidlc configured")
else()
    message(STATUS "lcidlc: source directory not found, skipping")
endif()
