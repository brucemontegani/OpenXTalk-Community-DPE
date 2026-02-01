# extensions - LCB Extensions
# Standard library modules written in LiveCode Builder

message(STATUS "Configuring extensions")

# Extensions are LCB files that need to be compiled by lc-compile
# The compiled bytecode is then embedded into the engine

# For now, this is a placeholder
# Full implementation would:
# 1. Find all .lcb files in the extensions directory
# 2. Use lc-compile to generate .lcm bytecode files
# 3. Use a tool to embed the bytecode into the engine

# List of extension libraries
set(EXTENSION_LIBRARIES
    # widgets/
    # libraries/
)

message(STATUS "Extensions configured (LCB compilation pending)")
