# revzip - ZIP Archive External
# Provides ZIP archive creation and extraction

message(STATUS "Configuring revzip")

if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/src")
    message(STATUS "revzip configured")
else()
    message(STATUS "revzip: source directory not found, skipping")
endif()
