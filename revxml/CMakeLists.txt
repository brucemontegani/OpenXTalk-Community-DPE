# revxml - XML External
# Provides XML parsing and generation functionality

message(STATUS "Configuring revxml")

if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/src")
    message(STATUS "revxml configured")
else()
    message(STATUS "revxml: source directory not found, skipping")
endif()
