# 补给系统热修复文档

## 问题描述
用户在进入战斗后遇到了 `abort()` 报错，怀疑与新添加的补给系统有关。

## 已实施的修复措施

### 1. 增强Lua函数的空指针检查 ✅

**修改文件**: `ocgcore/libduel.cpp`

为所有补给相关的Lua函数添加了严格的空指针检查：

```cpp
// 修复前
duel* pduel = interpreter::get_duel_info(L);
lua_pushinteger(L, pduel->game_field->player[p].supply);

// 修复后
duel* pduel = interpreter::get_duel_info(L);
if(!pduel || !pduel->game_field)
    return 0;
lua_pushinteger(L, pduel->game_field->player[p].supply);
```

**影响的函数**:
- `duel_get_supply()`
- `duel_set_supply()`
- `duel_add_supply()`
- `duel_spend_supply()`
- `duel_get_max_supply()`

### 2. 暂时禁用自动补给增长 ✅

**修改文件**: `gframe/duelclient.cpp`

暂时注释了MSG_NEW_TURN中的自动补给增长调用，以排除时机问题：

```cpp
// 修复前
case MSG_NEW_TURN: {
    // ...
    mainGame->IncrementMaxSupply(player);

// 修复后
case MSG_NEW_TURN: {
    // ...
    // mainGame->IncrementMaxSupply(player); // 暂时注释
```

### 3. 创建简化测试脚本 ✅

创建了 `test_supply_basic.lua` 用于安全的功能验证，避免复杂脚本可能引起的问题。

## 测试建议

### 阶段1: 基础功能测试
1. 启动游戏，进入战斗
2. 验证没有abort()错误
3. 在控制台或脚本中测试基础Lua API

### 阶段2: 逐步启用功能
如果基础测试通过：
1. 重新启用自动补给增长功能
2. 测试完整的补给系统

### 阶段3: 完整验证
1. 测试所有Lua API函数
2. 验证UI显示功能
3. 测试边界条件

## 安全回滚方案

如果问题仍然存在，可以通过以下步骤完全禁用补给系统：

1. **临时禁用Lua函数注册**:
   ```cpp
   // 在libduel.cpp中注释这些行
   // { "GetSupply", scriptlib::duel_get_supply },
   // { "SetSupply", scriptlib::duel_set_supply },
   // { "AddSupply", scriptlib::duel_add_supply },
   // { "SpendSupply", scriptlib::duel_spend_supply },
   // { "GetMaxSupply", scriptlib::duel_get_max_supply },
   ```

2. **禁用UI显示**:
   ```cpp
   // 在drawing.cpp中注释补给显示代码
   // DrawShadowText(numFont, dInfo.str_supply[0], ...);
   // DrawShadowText(numFont, dInfo.str_supply[1], ...);
   ```

## 根本原因分析

可能的原因包括：
1. **时机问题**: 在游戏状态未完全初始化时调用了补给函数
2. **空指针访问**: 某些情况下game_field或player数据未正确初始化
3. **内存越界**: 数组访问越界（已通过边界检查修复）

## 后续计划

1. 在确认基础修复有效后，逐步重新启用完整功能
2. 添加更完善的调试日志来追踪问题
3. 考虑将补给初始化移到更安全的时机

## ✅ 问题已解决！

### 成功的解决方案
经过测试验证，问题已通过以下方案完全解决：

**根本解决方案: 完全照搬LP系统实现模式**

1. **移除`UpdateSupplyDisplay`函数** - 这是导致abort()的主要原因
2. **直接使用`myswprintf`** - 在每个补给函数中直接更新字符串
3. **移除线程互斥锁** - LP系统也没有使用，简化实现
4. **简化调用链** - 减少函数调用层次，提高稳定性

### 最终工作状态
- ✅ **无abort()错误** - 程序稳定运行
- ✅ **完整Lua接口** - 所有5个补给API函数正常工作
- ✅ **UI显示正常** - 补给值正确显示在界面上
- ✅ **自动增长机制** - 每回合补给正确增长
- ✅ **UI位置优化** - 补给显示更靠近用户名区域

### 核心经验
**"不要重新发明轮子"** - 直接照搬LP系统的成熟实现比自创新方案更可靠。

---
**创建时间**: 2025年9月17日
**解决时间**: 2025年9月17日
**状态**: ✅ 问题已完全解决，系统稳定运行