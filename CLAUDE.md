# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is GCG (Yu-Gi-Oh! game client), a cross-platform Yu-Gi-Oh! trading card game simulator built with C++ and Irrlicht engine. The project supports Windows, Linux, and macOS platforms.

## Build System

The project uses Premake5 as the primary build system with CMake support available. The main build configuration is in `premake5.lua`.

### Building the Project

**Using Premake5 (Primary):**
```bash
# Generate build files
premake5 [vs2022|gmake2|xcode4]

# On Windows with Visual Studio
premake5 vs2022
# Then build with VS or:
msbuild build/YGOPro.sln

# On Linux/Mac
premake5 gmake2
make -C build
```

**Using CMake (Alternative):**
```bash
mkdir build && cd build
cmake ../cmake
make
```

### Build Configuration Options

Key premake5 options (can be set via command line or environment variables):
- `--build-lua` / `--no-build-lua`: Build Lua from source (default: true)
- `--build-event` / `--no-build-event`: Build libevent (default: Windows only)
- `--build-freetype` / `--no-build-freetype`: Build FreeType (default: Windows only)
- `--build-sqlite` / `--no-build-sqlite`: Build SQLite (default: Windows only)
- `--audio-lib=[miniaudio|irrklang]`: Audio library choice (default: miniaudio)
- `--no-audio`: Disable audio support
- `--mac-arm` / `--mac-intel`: Target specific Mac architecture

### Dependencies

**Built from Source (configurable):**
- Lua 5.3+ (required, built by default)
- Irrlicht engine (modified version, always built from source)
- libevent (Windows: built, Unix: system package)
- FreeType (Windows: built, Unix: system package)  
- SQLite (Windows: built, Unix: system package)
- miniaudio (audio support)

## Architecture

### Core Components

**ocgcore/**: Yu-Gi-Oh! card game core logic
- Card game rules engine written in C++
- Lua scripting for card effects (script/ directory)
- Database operations for card data

**gframe/**: Main GUI application framework  
- Irrlicht-based 3D graphics and UI
- Network client/server functionality  
- Game state management and user interface
- Audio system integration

**script/**: Lua card scripts
- Individual card effect implementations (c[cardid].lua)
- Card behavior and interaction logic

### Key Directories

- `gframe/`: Main application code and GUI
- `ocgcore/`: Game engine core
- `script/`: Lua card scripts  
- `textures/`: Image resources
- `deck/`: Deck files (.ydk format)
- `replay/`: Replay files (.yrp format)
- `expansions/`: Additional card database files (.cdb)
- `sound/`: Audio files
- `skin/`: UI skin resources

### Data Files

- `cards.cdb`: Main card database (SQLite)
- `lflist.conf`: Ban/limit list configuration
- `system.conf`: Main configuration file
- `strings.conf`: Localization strings

## Development Workflow

### Running the Application

**Command Line Options:**
- `-e foo.cdb`: Load additional database
- `-n nickname`: Set nickname
- `-h ip -p port -w password`: Connect to server
- `-d [deck]`: Deck edit mode
- `-r [replay.yrp]`: Replay mode  
- `-s [puzzle.lua]`: Single/puzzle mode
- `-c`: Create host
- `-j`: Join host
- `-k`: Keep application open when finished

### Testing and Debugging

The project includes automated CI builds for Windows, Linux, and macOS via GitHub Actions (`.github/workflows/build.yml`).

**Important Development Rule:**
- Claude should NOT attempt to compile or build the project during development
- All code modifications should be made without compilation verification
- Testing and debugging should be left to the user to perform
- Focus on code analysis, modification, and providing guidance rather than build verification

### Platform-Specific Notes

**Windows:**
- Requires Windows 10 SDK version 1803+ for proper Unicode support
- DirectX SDK support available (controlled by `USE_DXSDK`)
- Default build includes all dependencies from source

**Linux/macOS:**  
- System packages preferred for common libraries (libevent, freetype, sqlite)
- Package manager integration (apt/homebrew)
- ARM architecture support available

## File Structure Patterns

- Premake5 build files: `*/premake5.lua`
- CMake files: `cmake/` directory with platform-specific configurations
- Platform-specific code organized in `cmake/platform/` and `cmake/compiler/`
- Resource organization: separate directories for different asset types (textures, sounds, scripts)