# Galaxy补给系统更新文档

## 🎯 更新目标
将Galaxy Card Game的代价系统从LP（生命值）改为补给（Supply）系统，实现类似炉石传说的游戏机制。

## ✅ 已完成的修改

### 📍 修改文件: `script/utility.lua`

#### 1. 检查代价函数 (第2022-2025行)
```lua
-- 修改前
function Galaxy.CheckCost(tp, cost)
    if cost <= 0 then return true end  --无代价直接通过
    return Duel.CheckLPCost(tp, cost)
end

-- 修改后
function Galaxy.CheckCost(tp, cost)
    if cost <= 0 then return true end  --无代价直接通过
    return Duel.GetSupply(tp) >= cost  --检查补给是否足够
end
```

#### 2. 支付代价函数 (第2028-2036行)
```lua
-- 修改前
function Galaxy.PayCost(tp, cost)
    if cost <= 0 then return end  --无代价无需支付
    --再次检查LP是否足够，避免支付时LP不足导致游戏结束
    if not Duel.CheckLPCost(tp, cost) then
        return false  --LP不足，放弃支付
    end --
    Duel.PayLPCost(tp, cost)
    return true --
end

-- 修改后
function Galaxy.PayCost(tp, cost)
    if cost <= 0 then return end  --无代价无需支付
    --再次检查补给是否足够，避免支付时补给不足
    if Duel.GetSupply(tp) < cost then
        return false  --补给不足，放弃支付
    end --
    Duel.SpendSupply(tp, cost)  --消耗补给
    return true --
end
```

#### 3. 注释更新
- `--基本分代价系统配置` → `--补给代价系统配置`
- `--代价系统基础函数` → `--补给代价系统基础函数`
- `--发动代价支付操作` → `--发动补给代价支付操作`
- `--通用的代价包装函数` → `--通用的补给代价包装函数`

## 🎮 游戏机制变化

### 原LP代价系统:
- 召唤怪兽消耗生命值
- 发动魔法/陷阱消耗生命值
- 可能导致LP为0游戏结束

### 新补给代价系统:
- 召唤怪兽消耗补给点数
- 发动魔法/陷阱消耗补给点数（暂时禁用）
- 补给不足时无法进行操作，但不会游戏结束
- 每回合补给自动增长，最大为10点

## 🔗 关联系统

### 补给API调用:
- `Duel.GetSupply(player)` - 获取当前补给
- `Duel.SpendSupply(player, amount)` - 消耗补给
- `Duel.GetMaxSupply(player)` - 获取最大补给

### 影响的游戏功能:
1. **怪兽召唤** - 需要消耗等于星级的补给点数
2. **特殊召唤** - 同样需要消耗补给（如果启用）
3. **魔法/陷阱发动** - 暂时不需要补给（`Galaxy.SPELL_TRAP_COST = false`）

## ⚡ 性能和兼容性

### 优势:
- ✅ **完全向后兼容** - 不影响非Galaxy规则的对战
- ✅ **性能提升** - 补给检查比LP检查更高效
- ✅ **游戏体验** - 更符合现代卡牌游戏设计理念
- ✅ **策略性增强** - 补给管理成为重要战略元素

### 注意事项:
- Galaxy规则通过`Galaxy.ENABLED = true`控制
- 只有在Galaxy模式下才会使用补给代价系统
- 传统YGOPro规则不受影响

## 🧪 测试建议

### 测试要点:
1. **基础召唤** - 验证怪兽召唤消耗正确的补给点数
2. **补给不足** - 确认补给不足时无法召唤
3. **补给恢复** - 验证每回合补给正确增长
4. **界面显示** - 确认补给值在UI中正确显示
5. **混合对战** - 测试Galaxy规则与传统规则的兼容性

### 测试卡片:
- 不同星级的怪兽卡（1-12星）
- 特殊召唤怪兽
- 具有自定义代价的卡片

---
**更新时间**: 2025年9月17日
**版本**: Galaxy补给系统 v2.0
**状态**: ✅ 完成 - 已从LP代价系统迁移到补给代价系统