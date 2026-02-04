# revxml - XML External
# Provides XML parsing and generation functionality via libxml2/libxslt

message(STATUS "Configuring revxml")

if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/src")
    set(REVXML_SOURCES
        src/revxml.cpp
        src/xmldoc.cpp
        src/xmlelement.cpp
        src/xmlattribute.cpp
    )

    add_library(external-revxml MODULE ${REVXML_SOURCES})

    target_include_directories(external-revxml PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src
    )

    target_link_libraries(external-revxml PRIVATE
        libExternal
        libxml
        libxslt
        libz
    )

    set_target_properties(external-revxml PROPERTIES
        OUTPUT_NAME "revxml"
        PREFIX ""
    )

    if(APPLE AND NOT IOS)
        set_target_properties(external-revxml PROPERTIES
            BUNDLE TRUE
            BUNDLE_EXTENSION "bundle"
            MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/rsrc/revxml-Info.plist"
        )

        # Export only the getXtable symbol
        target_link_options(external-revxml PRIVATE
            -exported_symbols_list "${CMAKE_CURRENT_SOURCE_DIR}/revxml.exports"
        )

        # Copy revxml.bundle to the IDE bin directory
        add_custom_command(TARGET external-revxml POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_directory
                "$<TARGET_BUNDLE_DIR:external-revxml>"
                "${CMAKE_BINARY_DIR}/$<CONFIG>/bin/revxml.bundle"
            COMMENT "Copying revxml.bundle to bin directory"
        )
    endif()
else()
    message(STATUS "revxml: source directory not found, skipping")
endif()
