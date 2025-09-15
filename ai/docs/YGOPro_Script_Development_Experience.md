# YGOPro Lua脚本开发经验总结

## 本次会话成果概览

本次对话完成了多张Galaxy规则卡片的实现，涵盖了各种常见的YGOPro效果类型，并修复了关键的系统bug。

## 完成的卡片实现

### 1. c10000014.lua - 永续魔法卡（LP回复）
**效果**: 1回合1次，自己准备阶段开始时必发，回复2LP
**关键经验**:
- 永续魔法卡必须先有`EFFECT_TYPE_ACTIVATE`基础发动效果
- 准备阶段触发使用`EVENT_PHASE_START+PHASE_STANDBY`
- 强制效果使用`EFFECT_TYPE_TRIGGER_F`

### 2. c10000015.lua - 场地魔法卡（攻守提升）
**效果**: 场上的战士族怪兽攻击力守备力上升1
**关键经验**:
- 参考c86318356（草原）的标准实现模式
- 使用`EFFECT_TYPE_FIELD`影响场上怪兽
- 攻击力和守备力效果可以通过`Clone()`复用

### 3. c10000017.lua - 怪兽卡（战斗伤害回复）
**效果**: 这个怪兽对对方造成LP伤害时发动，自己回复造成的LP伤害值
**关键经验**:
- 使用`EVENT_BATTLE_DAMAGE`触发战斗伤害事件
- 通过`ev`参数获取伤害数值
- 条件检查`ep~=tp`确保是对对方造成伤害

### 4. c10000018.lua - 特殊召唤回合可攻击怪兽
**效果**: 这个怪兽在特殊召唤的回合就可以直接发动攻击
**关键经验**:
- 通过配置`Galaxy.SUMMON_TURN_CANNOT_ATTACK = false`临时禁用攻击限制
- 在`Galaxy.ApplyRulesToCard(c)`前后保存和恢复全局设置
- 这种方法比后续移除效果更优雅

### 5. c10000019.lua - 嘲讽怪兽
**效果**: 对方怪兽不能选择其他怪兽作为攻击对象
**关键经验**:
- 使用`EFFECT_CANNOT_SELECT_BATTLE_TARGET`限制攻击目标选择
- 多个嘲讽怪兽共存问题：使用统一标记`EFFECT_FLAG_EFFECT+99999999`
- 智能限制逻辑：允许攻击任意嘲讽怪兽，禁止攻击非嘲讽怪兽

### 6. c10000021.lua - 攻击宣言时守备力提升
**效果**: 这个怪兽攻击宣言时发动增加1def
**关键经验**:
- 使用`EVENT_ATTACK_ANNOUNCE`触发攻击宣言
- 守备力提升使用`EFFECT_UPDATE_DEFENSE`
- 效果持续时间用`RESET_EVENT+RESETS_STANDARD`

### 7. c10000022.lua - 等级限制破坏魔法
**效果**: 以场上1个等级5以上的怪兽为对象才能发动，将其破坏
**关键经验**:
- 参考c5318639（旋风）的目标破坏模式
- 使用`IsLevelAbove(5)`筛选等级条件
- `EFFECT_FLAG_CARD_TARGET`实现目标选择

### 8. c10000023.lua - 连续效果魔法
**效果**: 减少对方全部怪兽1点def，那之后，可以再消耗3点lp，再减少对方全部怪兽1点def
**关键经验**:
- 使用`Duel.BreakEffect()`分隔两个效果
- `Duel.SelectYesNo()`让玩家选择是否发动追加效果
- 追加效果的LP检查和支付模式

### 9. c10000024.lua - 临时强化+回合结束破坏
**效果**: 支付2lp作为代价，选自己场上1个怪兽攻击力上升4点，回合结束时破坏
**关键经验**:
- 参考c1845204（简易融合）的回合结束破坏模式
- 使用`RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,1)`标记目标
- 破坏效果注册到场地而非怪兽，提高稳定性

### 10. c10000026.lua - 特殊召唤融合怪兽
**效果**: 把1只水属性的融合怪兽从额外卡组特殊召唤，支付那只怪兽等级的lp作为代价
**关键经验**:
- 参考c69015963（恶魔·弗兰肯）的直接特殊召唤模式
- 不按融合处理：使用`Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)`
- 等级动态代价：`local cost=tc:GetLevel(); Duel.PayLPCost(tp,cost)`

## 重要技术发现与修复

### Galaxy攻击限制系统的配置化改进
**问题**: 原有系统无法为个别怪兽禁用召唤回合攻击限制
**解决方案**:
1. 添加配置选项`Galaxy.SUMMON_TURN_CANNOT_ATTACK = true`
2. 修改`Galaxy.ApplyRulesToCard()`添加条件检查
3. 个别卡片可临时修改配置来覆盖全局设置

### Galaxy代价系统的LP安全问题修复
**问题**: LP不足时仍能支付代价，导致玩家直接败北
**根本原因**: `SpecialSummonCondition`检查时LP足够，但`SpecialSummonOperation`支付时LP可能已不足
**解决方案**:
1. 在`Galaxy.PayCost()`中添加二次LP检查
2. LP不足时返回false，避免强制支付
3. `SpecialSummonOperation`处理支付失败情况

## 核心开发模式总结

### 1. 参考驱动开发
- **必须先找参考卡片**: 每个效果都有成熟的原版实现
- **深入学习参考实现**: 理解API用法、代码结构、错误处理
- **基于参考修改**: 在原版基础上修改，避免从零自创

### 2. 效果类型与时机的准确使用
```lua
-- 强制触发效果
EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F
-- 场地影响效果
EFFECT_TYPE_FIELD
-- 目标选择魔法
EFFECT_FLAG_CARD_TARGET
-- 回合结束时机
EVENT_PHASE+PHASE_END
```

### 3. 常用效果模式
- **攻守修改**: `EFFECT_UPDATE_ATTACK/DEFENSE + SetValue()`
- **LP操作**: `Duel.CheckLPCost() + Duel.PayLPCost()`
- **目标破坏**: `SelectTarget() + Duel.Destroy()`
- **特殊召唤**: `IsCanBeSpecialSummoned() + Duel.SpecialSummon()`

### 4. 稳定性保证措施
- **效果关联性**: 使用`IsRelateToEffect(e)`检查目标有效性
- **状态检查**: 使用`IsFaceup()`等检查卡片状态
- **标记系统**: 使用`RegisterFlagEffect()`跟踪复杂效果
- **重置管理**: 合理使用`RESET_EVENT+RESETS_STANDARD`

## 调试与测试策略

### 1. 渐进式开发
- 每实现一个效果立即测试
- 不要积累多个问题
- 发现问题时优先查找类似的原版卡片

### 2. 边界条件测试
- 测试LP不足、场地满等极端情况
- 验证多张相同卡片共存的情况
- 检查效果的时机和优先级

### 3. 参照物对比
- 在相同场景下比较原版卡片和自实现的行为差异
- 用户反馈是最宝贵的指导来源

## 最佳实践总结

1. **永远以原版为准**: YGOPro的API经过十多年验证，遵循既定模式最可靠
2. **谦逊学习**: 重用成熟实践比重新发明更稳定
3. **质量优于创新**: 稳定可靠比独创性更重要
4. **系统性思考**: 考虑效果对整个游戏系统的影响
5. **防御性编程**: 添加必要的安全检查和错误处理

## 待改进方向

1. **更完善的代价系统**: 考虑更复杂的代价类型和检查机制
2. **效果冲突处理**: 建立更好的效果优先级和冲突解决机制
3. **性能优化**: 对于复杂效果的性能影响评估
4. **文档完善**: 建立更详细的API使用指南和最佳实践文档

---
*文档创建时间: 2025-09-15*
*基于Claude Code对话总结生成*