# revzip - ZIP Archive External
# Provides ZIP archive creation and extraction

message(STATUS "Configuring revzip")

if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/src")
    set(REVZIP_SOURCES
        src/revzip.cpp
    )

    add_library(external-revzip MODULE ${REVZIP_SOURCES})

    target_link_libraries(external-revzip PRIVATE
        libExternal
        libzip
        libz
    )

    set_target_properties(external-revzip PROPERTIES
        OUTPUT_NAME "revzip"
        PREFIX ""
    )

    if(APPLE AND NOT IOS)
        set_target_properties(external-revzip PROPERTIES
            BUNDLE TRUE
            BUNDLE_EXTENSION "bundle"
            MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/rsrc/revzip-Info.plist"
        )

        target_link_libraries(external-revzip PRIVATE
            "-framework CoreFoundation"
        )

        # Copy revzip.bundle to the IDE bin directory
        add_custom_command(TARGET external-revzip POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_directory
                "$<TARGET_BUNDLE_DIR:external-revzip>"
                "${CMAKE_BINARY_DIR}/$<CONFIG>/bin/revzip.bundle"
            COMMENT "Copying revzip.bundle to bin directory"
        )
    endif()
else()
    message(STATUS "revzip: source directory not found, skipping")
endif()
