# Galaxy Card Game Development Instructions

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Project Overview

Galaxy Card Game (GCG) is a cross-platform trading card game client built with C++ and Irrlicht engine, based on YGOPro but modified to create a custom galaxy-themed card game. The project contains 70 custom cards with Chinese names and extensive Lua scripting (8,000+ lines of Lua code).

## Working Effectively

### Bootstrap and Dependencies
- Install system dependencies:
  ```bash
  sudo apt update && sudo apt install -y build-essential cmake git sqlite3 libsqlite3-dev libevent-dev libfreetype6-dev lua5.3 liblua5.3-dev pkg-config libirrlicht-dev libvorbis-dev libogg-dev libopus-dev
  ```
  **TIMING**: 5-8 minutes. NEVER CANCEL. Set timeout to 15+ minutes.

- Install Premake5 build tool:
  ```bash
  wget -O /tmp/premake5.tar.gz https://github.com/premake/premake-core/releases/download/v5.0.0-beta2/premake-5.0.0-beta2-linux.tar.gz
  cd /tmp && tar --wildcards -xzf premake5.tar.gz "./premake5"
  sudo cp premake5 /usr/local/bin/ && sudo chmod +x /usr/local/bin/premake5
  ```

### Critical Build Setup Requirements
- **COMPATIBILITY FIX REQUIRED**: The premake5.lua file contains a compatibility issue with older premake5 versions:
  ```bash
  # Comment out line 439 in premake5.lua:
  # linktimeoptimization "On"  # Replace with comment for compatibility
  ```

- **DEPENDENCY SYMLINKS**: Create required symlinks for premake build system:
  ```bash
  cd [repository-root]
  for dir in premake/*/; do ln -sf "$dir" "$(basename "$dir")"; done
  ```

### External Dependencies Warning
**CRITICAL LIMITATION**: The project requires external dependency repositories that may not be publicly accessible:
- `https://code.moenext.com/mycard/irrlicht-new.git` (modified Irrlicht engine)
- `https://code.moenext.com/mycard/miniaudio.git` (audio system)

**DEPENDENCY PREPARATION SCRIPTS** (may fail due to network access):
```bash
./.ci/prepare-irrlicht.sh    # Prepares modified Irrlicht - may fail
./.ci/prepare-miniaudio.sh   # Prepares audio system - may fail
```

### Build Process
- Generate build files:
  ```bash
  ./premake5 gmake2  # or premake5 gmake2 if installed globally
  ```
  **TIMING**: <1 second under normal conditions.

- Build with minimal dependencies (if external repos unavailable):
  ```bash
  ./premake5 gmake2 --no-build-lua --no-build-freetype --no-build-sqlite --no-build-event --no-audio
  make -C build config=release -j$(nproc)
  ```
  **EXPECTED RESULT**: Build will likely fail due to missing external dependencies. This is NORMAL.

- **FULL BUILD WARNING**: Complete builds require access to private repositories and may take 15-30 minutes. NEVER CANCEL. Set timeout to 60+ minutes.

### Running the Application
**IMPORTANT**: Per project documentation (CLAUDE.md), developers should NOT attempt to compile during development. Build and run testing should be left to users with proper environment setup.

Command line options when application is available:
```bash
./bin/release/YGOPro [options]
# Options:
# -e foo.cdb          Load additional database
# -n nickname         Set nickname  
# -h ip -p port -w password  Connect to server
# -d [deck]           Deck edit mode
# -r [replay.yrp]     Replay mode
# -s [puzzle.lua]     Single/puzzle mode
# -c                  Create host
# -j                  Join host
# -k                  Keep application open when finished
```

## Validation

### Build Environment Validation
- Always run dependency installation commands before attempting builds
- Verify premake5 installation: `premake5 --version`
- Check symlink creation: `ls -la lua irrlicht` should show symlinks to premake/ subdirectories
- Validate database: `sqlite3 cards.cdb "SELECT COUNT(*) FROM datas;"` (should return 70)
- Check Lua scripts: `wc -l script/*.lua | tail -1` (should show ~8,287 total lines)

### Manual Validation Scenarios
**CRITICAL**: After any code changes, test these scenarios manually:

1. **Database Integrity Check**:
   ```bash
   sqlite3 cards.cdb ".schema"
   sqlite3 cards.cdb "SELECT COUNT(*) FROM datas, texts;"
   ```

2. **Lua Script Validation**:
   ```bash
   # Check for basic syntax errors (note: scripts depend on game engine context)
   # Basic file integrity check
   find script/ -name "*.lua" -exec wc -l {} \; | tail -5
   # Check core script files exist and are non-empty
   ls -la script/utility.lua script/constant.lua script/procedure.lua
   ```

3. **Configuration File Validation**:
   ```bash
   # Verify config files are present and properly sized
   wc -l *.conf  # Should show: strings.conf(577), system.conf(64)
   ```

### Known Build Limitations
- **DO NOT expect successful builds** without access to private dependency repositories
- External dependencies from `code.moenext.com` are required but may not be accessible
- System library alternatives exist but require configuration modifications
- Build process is designed for internal development environment

### Critical Development Rules
- **NEVER attempt compilation verification** during code development (per CLAUDE.md)
- Focus on code analysis and modification rather than build verification
- Leave testing and debugging to users with proper environment setup
- Always document any changes that might affect build process

## Common Tasks

### Lua Script Development
- **Location**: `script/` directory contains 70 card scripts plus core files
- **Core Scripts**: 
  - `utility.lua` (2,350 lines) - Galaxy system utilities and global rules
  - `constant.lua` (951 lines) - Game constants and definitions  
  - `procedure.lua` (2,268 lines) - Card procedures and mechanics
  - `c[cardid].lua` - Individual card implementations (c10000000.lua to c10000069.lua, c99999999.lua)
- **API Reference**: `ai/luatips/tips.json`
- **Code Examples**: `ai/examples/script/`
- **Development Guide**: `dev/docs/lua_development_guide.md`
- **Validation**: Lua scripts depend on game engine context and cannot be validated standalone

### Database Management
- **Primary Database**: `cards.cdb` (SQLite, 70 cards)
- **Schema**: Tables `datas` (card data) and `texts` (card names/descriptions)
- **Validation**: `sqlite3 cards.cdb "SELECT COUNT(*) FROM datas;"` should return 70
- **Card Names**: Chinese language (e.g., "星火斥候", "曙光突击兵", "星际游骑兵")

### Galaxy System
- **Complete Documentation**: `dev/docs/galaxy_system_complete.md`
- **Status**: 100% complete, stable, production-ready

### Project Structure
```
Repository root contents:
├── gframe/          # Main GUI application framework
├── ocgcore/         # Galaxy card game core logic (C++)
├── script/          # Lua card scripts
├── premake5.lua     # Build configuration
├── cards.cdb        # Main card database (SQLite)
├── textures/        # Image resources
├── sound/           # Audio files
├── cmake/           # Alternative CMake build system
├── .ci/             # CI/CD scripts and preparation tools
└── dev/docs/        # Development documentation
```

### File Patterns to Remember
- Card scripts: `script/c[cardid].lua`
- Database files: `*.cdb` (SQLite format)
- Deck files: `deck/*.ydk`
- Replay files: `replay/*.yrp`
- Configuration: `system.conf`, `strings.conf`, `lflist.conf`

## Important Notes

### Build System Architecture
- **Primary**: Premake5 (premake5.lua)
- **Alternative**: CMake (cmake/ directory)
- **Dependencies**: Mix of system packages and source builds
- **Platforms**: Windows, Linux, macOS support

### Development Workflow Expectations
- Builds are complex and may require internal environment setup
- External repository access may be limited
- Focus on code modifications rather than build verification
- Use documentation and examples for reference rather than live testing

### Timing Expectations
- Dependency installation: 5-8 minutes (NEVER CANCEL)
- Build file generation: <1 second
- Full compilation: 15-30 minutes when successful (NEVER CANCEL)
- Most builds will fail without proper environment setup - this is expected

### Quick Development Commands
```bash
# Repository status check
git status
wc -l script/*.lua | tail -5  # Check Lua script sizes (should show ~8,287 total)
sqlite3 cards.cdb "SELECT COUNT(*) FROM datas;"  # Verify 70 cards

# Syntax validation (note: Lua scripts require game engine context)
find script/ -name "*.lua" -exec wc -l {} \; | tail -5
ls -la script/utility.lua script/constant.lua script/procedure.lua

# Configuration check
ls -la *.conf && wc -l *.conf  # Should show strings.conf(577), system.conf(64)
```

## Summary for Effective Development

This project is a complex C++ card game with extensive Lua scripting. The build process requires private repositories that may not be accessible, which is normal and expected. Focus on:

1. **Code Analysis**: Use the comprehensive documentation in `dev/docs/`
2. **Lua Development**: Work with the 8,000+ lines of card scripts in `script/`
3. **Database Work**: 70 custom galaxy-themed cards in SQLite format
4. **Configuration**: System and string configurations for game mechanics

**Remember**: Per project guidelines, avoid attempting builds during development. Leave compilation and testing to users with proper environment setup.