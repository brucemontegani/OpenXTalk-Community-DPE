# revpdfprinter - PDF Printer External
# Provides PDF output functionality

message(STATUS "Configuring revpdfprinter")

if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/src")
    message(STATUS "revpdfprinter configured")
else()
    message(STATUS "revpdfprinter: source directory not found, skipping")
endif()
