# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is Galaxy Card Game (GCG), a cross-platform trading card game client built with C++ and Irrlicht engine. This project is based on YGOPro but has been modified to create a custom galaxy-themed card game. The project supports Windows, Linux, and macOS platforms.

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

**ocgcore/**: Galaxy card game core logic
- Card game rules engine written in C++ (based on YGOPro engine)
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

## YGOPro Lua 脚本开发最佳实践 🎯

### 📚 Lua开发资源

**必读资料**: `.\ai\luatips\` 目录下的json文件
- `tips.json`: 完整的API文档和使用说明
- `snippets.json`: 常用代码片段和实现模式

### 🎯 核心开发原则

**1. 始终以原版卡片为参考**
- 实现任何效果前，必须先询问用户相关的原版卡片ID
- 深入研究参考卡片的完整实现（`.\ai\examples\script\c[cardid].lua`）
- 学习并复制原版的API用法、代码结构和实现模式
- 在原版基础上修改，绝不从零自创

**2. 严格遵循YGOPro API规范**
- YGOPro的每个效果代码都有精确的用途和时机
- 禁止猜测API用法，一切以文档和原版实现为准
- 避免组合未经验证的效果代码
- 遵循既定的代码结构和命名规范

**3. 使用正确的效果类型和时机**
```lua
// 错误示例：使用CONTINUOUS处理触发效果
SetType(EFFECT_TYPE_CONTINUOUS)

// 正确示例：参考原版使用TRIGGER_F
SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
SetCode(EVENT_DAMAGE_STEP_END)
SetCondition(aux.dsercon)
```

### 🛠️ 开发流程

**步骤1: 需求分析**
- 明确要实现的游戏机制
- 寻找具有类似效果的原版卡片
- 分析原版卡片的实现方式

**步骤2: API查询**
- 查阅`ai/luatips/tips.json`了解相关API
- 确认正确的效果代码和参数
- 理解API的触发时机和作用范围

**步骤3: 参考实现**
- 复制原版卡片的代码结构
- 替换具体的数值和条件判断
- 保持原版的错误处理和边界检查

**步骤4: 测试验证**
- 在相同条件下对比原版卡片行为
- 使用最简化的测试场景验证核心功能
- 确认效果在正确的游戏时机触发

### ⚠️ 常见错误与避免

**时机错误**:
```lua
// ❌ 错误：使用EVENT_BATTLED
SetCode(EVENT_BATTLED)

// ✅ 正确：使用EVENT_DAMAGE_STEP_END
SetCode(EVENT_DAMAGE_STEP_END)
```

**效果类型错误**:
```lua
// ❌ 错误：强制效果用CONTINUOUS
SetType(EFFECT_TYPE_CONTINUOUS)

// ✅ 正确：强制效果用TRIGGER_F
SetType(EFFECT_TYPE_TRIGGER_F)
```

**破坏机制错误**:
```lua
// ❌ 错误：手动调用Duel.Destroy
Duel.Destroy(c, REASON_EFFECT)

// ✅ 正确：使用EFFECT_SELF_DESTROY
SetCode(EFFECT_SELF_DESTROY)
SetCondition(condition_function)
```

### 🔍 调试策略

1. **渐进式测试**: 每实现一个效果立即测试，不要积累问题
2. **参照物对比**: 在相同场景下比较原版卡片和自实现的行为差异
3. **日志追踪**: 适当添加调试输出，跟踪效果的触发时机
4. **边界测试**: 测试极端情况下的效果表现

### 💡 开发心得

**谦逊学习的重要性**:
- YGOPro经过十多年发展，积累了大量最佳实践
- 原版开发者已经解决了绝大多数复杂问题
- 每个API都经过无数次测试和验证
- 基于成熟实践比重新发明更可靠

**质量优于创新**:
- 稳定可靠的实现比独创性更重要
- 遵循既定模式能避免大量潜在问题
- 代码的可维护性和兼容性是长期价值

**持续学习**:
- 定期研究新的原版卡片实现
- 关注API的使用趋势和最佳实践
- 从测试反馈中不断改进实现质量

### 🎯 Galaxy规则开发经验总结

**关键参考卡片库**:
- `c7852878`: EVENT_DAMAGE_STEP_END + TRIGGER_F的标准模式
- `c36553319`: EFFECT_SELF_DESTROY自动破坏的最佳实践
- `c62892347`: EFFECT_CANNOT_CHANGE_POSITION表示形式控制
- `c7171149`: 召唤回合攻击限制的完整实现
- `c36088082`: 条件性战斗效果的时机处理

**核心技术模式**:
```lua
-- 守备力生命值系统最优方案
EVENT_DAMAGE_STEP_END + EFFECT_TYPE_TRIGGER_F + aux.dsercon
EFFECT_UPDATE_DEFENSE + 负数值
EFFECT_SELF_DESTROY + 条件函数

-- 条件性永续效果模式
EFFECT_TYPE_SINGLE + SetCondition(condition_function)
适用于需要动态判断是否生效的永续效果

-- 多时机统一处理模式
基础效果 + Clone() + 修改SetCode()
适用于多个相似时机的效果注册
```

**重要的API使用要点**:
- `EFFECT_UPDATE_DEFENSE`用于守备力修改，支持负数减少
- `EVENT_DAMAGE_STEP_END`是战斗后处理的正确时机
- `aux.dsercon`是伤害步骤结束的标准条件检查
- `EFFECT_SELF_DESTROY`实现自动破坏，不入连锁
- 条件函数应检查`Duel.GetAttackTarget()`区分直接攻击与怪兽战斗

**测试驱动的迭代开发**:
- 每个功能实现后立即测试，不要积累问题
- 发现问题时优先查找类似功能的原版卡片
- 用户反馈是最宝贵的指导，快速响应和修复
- 边界条件测试至关重要（如直接攻击 vs 怪兽战斗）