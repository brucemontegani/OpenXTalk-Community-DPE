# extensions - LCB Extensions
# Standard library modules written in LiveCode Builder
#
# Compiles .lcb source files into .lcm bytecode modules using lc-compile,
# then packages them into packaged_extensions/ for the IDE to discover.

message(STATUS "Configuring extensions")

# ============================================================================
# Extension source list (matching extensions.gyp lcb-extensions sources)
# ============================================================================

set(LCB_EXTENSION_SOURCES
    # Modules
    modules/widget-utils/widget-utils.lcb
    modules/scriptitems/scriptitems.lcb
    # Libraries
    libraries/canvas/canvas.lcb
    libraries/iconsvg/iconsvg.lcb
    libraries/json/json.lcb
    libraries/objectrepository/objectrepository.lcb
    libraries/ini/ini.lcb
    libraries/timezone/timezone.lcb
    # Widgets
    widgets/svgpath/svgpath.lcb
    widgets/clock/clock.lcb
    widgets/graph/graph.lcb
    widgets/header/header.lcb
    widgets/iconpicker/iconpicker.lcb
    widgets/navbar/navbar.lcb
    widgets/paletteactions/paletteactions.lcb
    widgets/segmented/segmented.lcb
    widgets/switchbutton/switchbutton.lcb
    widgets/treeview/treeview.lcb
    widgets/colorswatch/colorswatch.lcb
    widgets/gradientrampeditor/gradientrampeditor.lcb
    widgets/tile/tile.lcb
    widgets/spinner/spinner.lcb
    widgets/browser/browser.lcb
)

# Platform-specific extensions
if(APPLE AND NOT IOS)
    list(APPEND LCB_EXTENSION_SOURCES
        libraries/macstatusmenu/macstatusmenu.lcb
        widgets/macbutton/macbutton.lcb
        widgets/mactextfield/mactextfield.lcb
    )
endif()

# ============================================================================
# Script library extensions (matching extensions.gyp lcs-extensions sources)
# ============================================================================
# These are .livecodescript files that need to be copied into packaged_extensions/
# with a minimal manifest.xml. The extension-utils library is critical - without it,
# the IDE's extension loading system cannot initialize and no extensions load at all.

set(LCS_EXTENSION_SOURCES
    script-libraries/extension-utils/extension-utils.livecodescript
    script-libraries/oauth2/oauth2.livecodescript
    script-libraries/getopt/getopt.livecodescript
    script-libraries/mime/mime.livecodescript
    script-libraries/drawing/drawing.livecodescript
    script-libraries/dropbox/dropbox.livecodescript
    script-libraries/diff/diff.livecodescript
    script-libraries/messageauthentication/messageauthentication.livecodescript
    script-libraries/httpd/httpd.livecodescript
    script-libraries/qr/qr.livecodescript
)

# ============================================================================
# Compile LCB extensions
# ============================================================================

# Engine LCI modules directory (built-in module interfaces from engine bootstrap)
set(ENGINE_LCI_DIR "${CMAKE_BINARY_DIR}/engine/lcb-modules/modules/lci")

# Output directories
set(PACKAGED_EXTENSIONS_DIR "${CMAKE_BINARY_DIR}/packaged_extensions")
set(EXTENSIONS_LCI_DIR "${CMAKE_BINARY_DIR}/extensions_lci")

if(TARGET lc-compile-stage3)
    # Build absolute paths for the source files
    set(LCB_EXTENSION_ABSOLUTE_SOURCES "")
    foreach(_src ${LCB_EXTENSION_SOURCES})
        list(APPEND LCB_EXTENSION_ABSOLUTE_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/${_src}")
    endforeach()

    set(LCS_EXTENSION_ABSOLUTE_SOURCES "")
    foreach(_src ${LCS_EXTENSION_SOURCES})
        list(APPEND LCS_EXTENSION_ABSOLUTE_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/${_src}")
    endforeach()

    # Create the compile-extensions shell script at configure time.
    # This script:
    #   1. Packages script library extensions (.livecodescript) with minimal manifests
    #   2. Runs lc-compile --deps order to get correct LCB compilation order
    #   3. Compiles each LCB extension, extracting its module ID
    #   4. Places output in packaged_extensions/<module_id>/
    #   5. Copies support/ files if present
    set(COMPILE_SCRIPT "${CMAKE_CURRENT_BINARY_DIR}/compile-extensions.sh")
    file(WRITE "${COMPILE_SCRIPT}" "#!/bin/bash
set -e

LC_COMPILE=\"$1\"
ENGINE_LCI_DIR=\"$2\"
PACKAGED_DIR=\"$3\"
LCI_DIR=\"$4\"
LCS_SEPARATOR=\"$5\"
shift 5

mkdir -p \"$PACKAGED_DIR\"
mkdir -p \"$LCI_DIR\"

# Split args into LCS sources (before separator) and LCB sources (after separator)
LCS_SOURCES=()
LCB_SOURCES=()
PAST_SEPARATOR=false
for ARG in \"$@\"; do
    if [ \"$ARG\" = \"$LCS_SEPARATOR\" ]; then
        PAST_SEPARATOR=true
        continue
    fi
    if [ \"$PAST_SEPARATOR\" = true ]; then
        LCB_SOURCES+=(\"$ARG\")
    else
        LCS_SOURCES+=(\"$ARG\")
    fi
done

# ---- Package script library extensions ----
for SRC in \"\${LCS_SOURCES[@]}\"; do
    # Extract module ID from script declaration: script \"com.livecode.library.xxx\"
    # Some files have a UTF-8 BOM before the script declaration
    MODULE_ID=$(grep -m1 -oE 'script \"com\\.[^\"]+' \"$SRC\" | sed 's/script \"//')
    if [ -z \"$MODULE_ID\" ]; then
        echo \"WARNING: Could not extract module ID from $SRC, skipping\"
        continue
    fi

    OUTDIR=\"$PACKAGED_DIR/$MODULE_ID\"
    mkdir -p \"$OUTDIR\"

    BASENAME=$(basename \"$SRC\")
    echo \"Packaging script library $MODULE_ID\"
    cp \"$SRC\" \"$OUTDIR/$BASENAME\"

    # Copy support/ and resources/ directories if present
    SRC_DIR=$(dirname \"$SRC\")
    if [ -d \"$SRC_DIR/support\" ]; then
        cp -R \"$SRC_DIR/support\" \"$OUTDIR/\"
    fi
    if [ -d \"$SRC_DIR/resources\" ]; then
        cp -R \"$SRC_DIR/resources\" \"$OUTDIR/\"
    fi

    # Generate minimal manifest.xml for development builds
    # The type is always 'library' for script libraries
    LIB_NAME=$(echo \"$BASENAME\" | sed 's/\\.livecodescript$//')
    cat > \"$OUTDIR/manifest.xml\" << MANIFEST_EOF
<package version=\"0.0\">
  <name>$MODULE_ID</name>
  <type>library</type>
  <title>$LIB_NAME</title>
  <version>0.0.0</version>
  <author>LiveCode Ltd.</author>
  <license>community</license>
</package>
MANIFEST_EOF
done

# ---- Compile LCB extensions ----
if [ \${#LCB_SOURCES[@]} -gt 0 ]; then
    # Get compilation order
    ORDERED=($( \"$LC_COMPILE\" --deps order --modulepath \"$LCI_DIR\" --modulepath \"$ENGINE_LCI_DIR\" \"\${LCB_SOURCES[@]}\" ))

    for SRC in \"\${ORDERED[@]}\"; do
        # Extract module ID: first line matching ^(widget|library|module) com.
        MODULE_ID=$(grep -m1 -E '^(widget|library|module) com\\.' \"$SRC\" | awk '{print \$2}')
        if [ -z \"$MODULE_ID\" ]; then
            echo \"WARNING: Could not extract module ID from $SRC, skipping\"
            continue
        fi

        OUTDIR=\"$PACKAGED_DIR/$MODULE_ID\"
        mkdir -p \"$OUTDIR\"

        echo \"Compiling $MODULE_ID from $SRC\"
        \"$LC_COMPILE\" \\
            --modulepath \"$LCI_DIR\" \\
            --modulepath \"$ENGINE_LCI_DIR\" \\
            --manifest \"$OUTDIR/manifest.xml\" \\
            --output \"$OUTDIR/module.lcm\" \\
            \"$SRC\"

        # Copy support/ directory if present
        SRC_DIR=$(dirname \"$SRC\")
        if [ -d \"$SRC_DIR/support\" ]; then
            cp -R \"$SRC_DIR/support\" \"$OUTDIR/\"
        fi
    done
fi

echo \"All extensions compiled successfully.\"
")

    # Create a stamp file to track when extensions were last built
    set(EXTENSIONS_STAMP "${CMAKE_CURRENT_BINARY_DIR}/extensions.stamp")

    add_custom_command(
        OUTPUT "${EXTENSIONS_STAMP}"
        COMMAND bash "${COMPILE_SCRIPT}"
            "$<TARGET_FILE:lc-compile-stage3>"
            "${ENGINE_LCI_DIR}"
            "${PACKAGED_EXTENSIONS_DIR}"
            "${EXTENSIONS_LCI_DIR}"
            "---LCB---"
            ${LCS_EXTENSION_ABSOLUTE_SOURCES}
            "---LCB---"
            ${LCB_EXTENSION_ABSOLUTE_SOURCES}
        COMMAND ${CMAKE_COMMAND} -E touch "${EXTENSIONS_STAMP}"
        DEPENDS
            lc-compile-stage3
            generate-engine-lcb-modules
            ${LCB_EXTENSION_ABSOLUTE_SOURCES}
            ${LCS_EXTENSION_ABSOLUTE_SOURCES}
        WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
        COMMENT "Compiling LCB extensions and packaging script libraries"
    )

    add_custom_target(lcb-extensions ALL
        DEPENDS "${EXTENSIONS_STAMP}"
    )

    # Copy packaged_extensions into the IDE app bundle output directory
    # The IDE looks for extensions at <binaries_path>/packaged_extensions/
    set(IDE_OUTPUT_DIR "${CMAKE_BINARY_DIR}/$<CONFIG>/bin/packaged_extensions")
    add_custom_command(TARGET lcb-extensions POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory
            "${PACKAGED_EXTENSIONS_DIR}"
            "${IDE_OUTPUT_DIR}"
        COMMENT "Copying packaged extensions to IDE output directory"
    )

    message(STATUS "LCB extensions will be compiled by lc-compile")
else()
    message(WARNING "lc-compile not available - LCB extensions will not be compiled")
endif()
