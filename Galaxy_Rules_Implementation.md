# Galaxy Card Game Rules - Lua脚本实现

## 概述

此实现通过**单张卡片脚本调用**的方式在原YGOPro引擎基础上实现Galaxy Card Game规则，无需修改核心引擎代码。所有规则变更通过Lua效果系统实现。

## 实现文件

- `script/utility.lua` - 集成了Galaxy规则的核心函数（底部）
- 各个卡片脚本 - 在`initial_effect`函数中调用`Galaxy.ApplyRulesToCard(c)`

## 已成功实现的规则 ✅

### 1. 禁用覆盖机制 
- **实现方式**: 通过单张卡片的 `EFFECT_CANNOT_MSET` 和 `EFFECT_CANNOT_SSET` 效果
- **功能**:
  - **怪兽卡**: 不能覆盖召唤（守备表示，背面放置）
  - **魔法卡**: 不能覆盖放置（背面放置）
  - **陷阱卡**: 不能覆盖放置（背面放置）
- **测试状态**: ✅ 已验证成功
- **测试卡片**: 
  - c82199284（霞の谷のファルコン）- 怪兽卡
  - c19613556（大嵐）- 魔法卡  
  - c44095762（聖なるバリア－ミラーフォース－）- 陷阱卡

## 待实现的规则 ⏳

### 2. 守备力作为生命值系统
- **计划实现方式**: 通过 `EVENT_BATTLE_DAMAGE_STEP` 事件监听器
- **功能目标**:
  - 怪兽战斗后，被攻击怪兽的守备力减去攻击力数值
  - 守备力归零或负数时怪兽被破坏
  - 使用 `EFFECT_SET_DEFENSE` 动态修改守备力
  - 通过 `EFFECT_INDESTRUCTIBLE_BATTLE` 防止传统战斗破坏

### 3. 战斗伤害重新定义
- **计划实现方式**: 通过 `EVENT_PRE_BATTLE_DAMAGE` 事件监听器
- **功能目标**:
  - 怪兽与怪兽战斗不对玩家造成伤害
  - 只有怪兽直接攻击玩家时才造成伤害

### 4. 强制目标攻击
- **计划实现方式**: 通过 `EFFECT_CANNOT_DIRECT_ATTACK` 场地效果
- **功能目标**:
  - 对方场上存在怪兽时，不能直接攻击玩家
  - 必须攻击对方的怪兽

## 关键技术突破 🚀

### **单张卡片调用模式**
经过测试发现，在`utility.lua`中注册全局效果会导致游戏崩溃，因此采用了更稳定的单张卡片调用模式：

```lua
--在每张卡片的脚本中添加
function cXXXXXXXX.initial_effect(c)
    --应用Galaxy规则
    if Galaxy and Galaxy.ApplyRulesToCard then
        Galaxy.ApplyRulesToCard(c)
    end
    
    --原有的卡片效果...
end
```

### **安全的效果注册**
- 使用 `EFFECT_TYPE_SINGLE` 而非 `EFFECT_TYPE_FIELD`
- 每张卡只为自己注册效果，避免全局冲突
- 添加安全检查确保API可用

### **自动类型识别**
```lua
function Galaxy.ApplyRulesToCard(c)
    if not c or not Galaxy.IsGalaxyDuel() then return end
    
    if c:IsType(TYPE_MONSTER) then
        Galaxy.AddNoCoverSummonToCard(c)
    elseif c:IsType(TYPE_SPELL) or c:IsType(TYPE_TRAP) then
        Galaxy.AddNoCoverSetToCard(c)
    end
end
```

## 实现的核心函数

### 控制函数
- `Galaxy.IsGalaxyDuel()` - 检查是否启用Galaxy规则
- `Galaxy.ApplyRulesToCard(c)` - 为单张卡片应用所有相关规则

### 禁止覆盖功能
- `Galaxy.AddNoCoverSummonToCard(c)` - 为怪兽添加禁止覆盖召唤
- `Galaxy.AddNoCoverSetToCard(c)` - 为魔法/陷阱添加禁止覆盖放置

## 使用方法

### 为现有卡片添加Galaxy规则
1. 打开卡片脚本文件（如`script/cXXXXXX.lua`）
2. 在`initial_effect`函数开头添加：
```lua
--应用Galaxy规则
if Galaxy and Galaxy.ApplyRulesToCard then
    Galaxy.ApplyRulesToCard(c)
end
```

### 启用/禁用Galaxy规则
修改 `utility.lua` 中的配置：
```lua
Galaxy.ENABLED = true                -- 总开关
Galaxy.NO_COVER_SUMMON = true        -- 禁止怪兽覆盖召唤
Galaxy.NO_SET_SPELL_TRAP = true      -- 禁止魔法陷阱覆盖放置
```

## 测试结果 📊

### ✅ 已验证功能
- **怪兽卡禁止覆盖召唤**: 无法从手牌覆盖召唤，但可以正常召唤和手动转换表示形式
- **魔法卡禁止覆盖放置**: 无法覆盖放置，只能直接发动
- **陷阱卡禁止覆盖放置**: 无法覆盖放置，只能在合适时机直接发动
- **系统稳定性**: 不会导致游戏崩溃，与原有卡片效果兼容

### 🎯 测试方法
1. 将测试卡片加入卡组
2. 尝试覆盖召唤/放置 - 应该被阻止
3. 正常召唤/发动 - 应该正常工作

## 下一步开发计划 📋

### 优先级1: 守备力作为生命值系统
- **目标**: 实现怪兽的守备力作为生命值机制
- **预计难度**: 中等（需要处理战斗事件）
- **实现方式**: 为每张怪兽卡添加战斗事件监听器

### 优先级2: 战斗伤害重新定义  
- **目标**: 怪兽战斗不对玩家造成伤害
- **预计难度**: 中等（需要处理伤害计算）
- **实现方式**: 全局伤害事件监听器

### 优先级3: 强制目标攻击
- **目标**: 存在怪兽时必须攻击怪兽
- **预计难度**: 中等（需要处理攻击限制）
- **实现方式**: 场地效果或单卡效果

### 优先级4: 批量应用
- **目标**: 为更多常用卡片添加Galaxy规则调用
- **预计难度**: 低（重复工作）
- **实现方式**: 逐个修改卡片脚本

## 技术特点

### 优势
- ✅ **稳定性高**: 不会导致游戏崩溃
- ✅ **兼容性好**: 与现有卡片效果完全兼容  
- ✅ **可维护性强**: 易于调试和修改
- ✅ **渐进式实现**: 可以逐步添加功能

### 限制
- ⚠️ **需要修改卡片脚本**: 每张卡都需要手动添加调用
- ⚠️ **覆盖范围**: 只对修改过的卡片生效
- ⚠️ **维护工作量**: 需要为大量卡片添加调用

## 兼容性说明

- **YGOPro版本**: 兼容标准YGOPro Lua API
- **卡牌脚本**: 与现有卡牌脚本完全兼容
- **多人游戏**: 支持2人对战模式
- **AI支持**: AI可以正常使用Galaxy规则

## 故障排除

### 常见问题
1. **某些卡片规则不生效**: 检查该卡片脚本是否添加了`Galaxy.ApplyRulesToCard(c)`调用
2. **游戏崩溃**: 当前单卡模式应该不会崩溃，如果出现请检查卡片脚本语法
3. **规则冲突**: Galaxy规则与特殊卡牌效果可能存在优先级问题

### 调试方法
- 检查`Galaxy.ENABLED`是否为true
- 确认卡片脚本中正确添加了Galaxy规则调用
- 测试时观察游戏行为是否符合预期

---

**注意**: 这是基于单张卡片脚本调用的安全实现方案，经过实际测试验证稳定可靠。当前禁止覆盖功能已完全实现，其他功能将逐步开发完善。

#### 以下是旧代码 （仅供参考）

```lua

## 新游戏规则

### 核心规则变更

1. 守备力作为生命值系统
   - 怪兽攻击后，被攻击怪兽的守备力减去攻击力数值
   - 守备力归零或负数时怪兽被破坏
   - 攻击力大于目标攻击力时目标不会被战斗破坏（原YGO会破坏）

2. 战斗伤害重新定义
   - 怪兽与怪兽战斗不对玩家造成伤害
   - 只有怪兽直接攻击玩家时才造成伤害

3. 强制目标攻击
   - 对方场上存在怪兽时，不能直接攻击玩家
   - 必须攻击对方的怪兽

4. 禁用覆盖机制
   - 禁止怪兽覆盖召唤（守备表示）
   - 禁止魔法陷阱卡覆盖放置
   - 所有卡牌必须正面放置


--Galaxy Card Game Rules Implementation
--Galaxy战报卡牌游戏规则实现

--初始化全局表
if not Galaxy then
	Galaxy = {}
end

--常量定义
Galaxy.DEFENSE_AS_HP = true  --守备力作为生命值
Galaxy.NO_MONSTER_BATTLE_DAMAGE = true  --怪兽战斗不对玩家造成伤害
Galaxy.FORCE_TARGET_ATTACK = true  --强制攻击目标存在的怪兽
Galaxy.NO_COVER_SUMMON = true  --禁止覆盖召唤
Galaxy.NO_SET_SPELL_TRAP = true  --禁止覆盖放置魔法陷阱

--=================================
--辅助函数
--=================================

--检查是否为Galaxy规则对战
function Galaxy.IsGalaxyDuel()
	--可以通过检查特定标记或配置来确定
	--这里默认为启用
	return true
end

--获取怪兽的当前防御力（生命值）
function Galaxy.GetMonsterHP(c)
	return c:GetDefense()
end

--设置怪兽的防御力（生命值）
function Galaxy.SetMonsterHP(c, hp)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_SET_DEFENSE)
	e1:SetValue(hp)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	c:RegisterEffect(e1)
	return hp
end

--=================================
--战斗伤害重新计算系统
--=================================

--重写战斗伤害计算
function Galaxy.BattleDamageCalculation(c1, c2, player)
	if not Galaxy.IsGalaxyDuel() then
		return nil --使用原始伤害计算
	end

	local atk1 = c1:GetAttack()
	local def2 = c2:GetDefense()

	--怪兽与怪兽战斗不对玩家造成伤害
	if Galaxy.NO_MONSTER_BATTLE_DAMAGE then
		--计算守备力减少
		local new_hp = def2 - atk1
		if new_hp <= 0 then
			--守备力归零，怪兽被破坏
			Galaxy.SetMonsterHP(c2, 0)
			return 0  --不对玩家造成伤害
		else
			--更新守备力（生命值）
			Galaxy.SetMonsterHP(c2, new_hp)
			return 0  --不对玩家造成伤害
		end
	end

	return nil --默认处理
end

--=================================
--战斗破坏系统重写
--=================================

--创建防御力作为生命值的效果
function Galaxy.CreateDefenseAsHPEffect(c)
	if not Galaxy.IsGalaxyDuel() then return end

	--战斗破坏替换效果
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_BATTLE_DAMAGE_STEP)
	e1:SetOperation(Galaxy.DefenseHPOperation)
	c:RegisterEffect(e1)

	--防止传统战斗破坏
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_INDESTRUCTIBLE_BATTLE)
	e2:SetValue(1)
	e2:SetCondition(Galaxy.DefenseHPCondition)
	c:RegisterEffect(e2)
end

function Galaxy.DefenseHPCondition(e)
	return Galaxy.IsGalaxyDuel() and e:GetHandler():GetDefense() > 0
end

function Galaxy.DefenseHPOperation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()

	if bc and bc:IsAttackable() then
		local atk = bc:GetAttack()
		local def = c:GetDefense()
		local new_hp = def - atk

		if new_hp <= 0 then
			--生命值归零，破坏怪兽
			Duel.Destroy(c,REASON_BATTLE)
		else
			--更新生命值（防御力）
			Galaxy.SetMonsterHP(c, new_hp)
		end
	end
end

--=================================
--禁用覆盖系统
--=================================

--禁止怪兽覆盖召唤
function Galaxy.PreventCoverSummon()
	if not Galaxy.IsGalaxyDuel() or not Galaxy.NO_COVER_SUMMON then return end

	--创建一个虚拟卡牌作为效果拥有者
	local dummy=Duel.CreateToken(0, 9999995)

	--全局效果禁止覆盖召唤
	local e1=Effect.CreateEffect(dummy)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_MSET)
	e1:SetTargetRange(LOCATION_HAND,LOCATION_HAND)
	e1:SetTarget(Galaxy.CoverSummonTarget)
	Duel.RegisterEffect(e1,0)
end

function Galaxy.CoverSummonTarget(e,c)
	--禁止守备表示和覆盖召唤
	return true
end

--禁止魔法陷阱卡覆盖放置
function Galaxy.PreventSetSpellTrap()
	if not Galaxy.IsGalaxyDuel() or not Galaxy.NO_SET_SPELL_TRAP then return end

	--创建一个虚拟卡牌作为效果拥有者
	local dummy=Duel.CreateToken(0, 9999999)

	--禁止魔法卡覆盖放置
	local e1=Effect.CreateEffect(dummy)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_SSET)
	e1:SetTargetRange(LOCATION_HAND,LOCATION_HAND)
	e1:SetTarget(aux.TargetBoolFunction(Card.IsType,TYPE_SPELL))
	Duel.RegisterEffect(e1,0)

	--禁止陷阱卡覆盖放置
	local e2=Effect.CreateEffect(dummy)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_SSET)
	e2:SetTargetRange(LOCATION_HAND,LOCATION_HAND)
	e2:SetTarget(aux.TargetBoolFunction(Card.IsType,TYPE_TRAP))
	Duel.RegisterEffect(e2,0)
end

--=================================
--强制目标攻击系统
--=================================

--禁止直接攻击（当对方场上有怪兽时）
function Galaxy.PreventDirectAttack()
	if not Galaxy.IsGalaxyDuel() or not Galaxy.FORCE_TARGET_ATTACK then return end

	--创建一个虚拟卡牌作为效果拥有者
	local dummy=Duel.CreateToken(0, 9999998)

	--全局效果：存在怪兽时不能直接攻击
	local e1=Effect.CreateEffect(dummy)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_DIRECT_ATTACK)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetCondition(Galaxy.DirectAttackCondition)
	Duel.RegisterEffect(e1,0)

	local e2=Effect.CreateEffect(dummy)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_DIRECT_ATTACK)
	e2:SetTargetRange(0,LOCATION_MZONE)
	e2:SetCondition(Galaxy.DirectAttackCondition2)
	Duel.RegisterEffect(e2,0)
end

function Galaxy.DirectAttackCondition(e)
	--对方场上存在怪兽时不能直接攻击
	return Duel.IsExistingMatchingCard(Card.IsType,1-e:GetHandlerPlayer(),LOCATION_MZONE,0,1,nil,TYPE_MONSTER)
end

function Galaxy.DirectAttackCondition2(e)
	--对方场上存在怪兽时不能直接攻击
	return Duel.IsExistingMatchingCard(Card.IsType,1-e:GetHandlerPlayer(),0,LOCATION_MZONE,1,nil,TYPE_MONSTER)
end

--=================================
--伤害系统重写
--=================================

--禁用怪兽战斗对玩家造成的伤害
function Galaxy.PreventBattleDamage()
	if not Galaxy.IsGalaxyDuel() or not Galaxy.NO_MONSTER_BATTLE_DAMAGE then return end

	--创建一个虚拟卡牌作为效果拥有者
	local dummy=Duel.CreateToken(0, 9999997)

	--全局效果：怪兽战斗不造成战斗伤害
	local e1=Effect.CreateEffect(dummy)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_PRE_BATTLE_DAMAGE)
	e1:SetOperation(Galaxy.BattleDamageReplace)
	Duel.RegisterEffect(e1,0)
end

function Galaxy.BattleDamageReplace(e,tp,eg,ep,ev,re,r,rp)
	--检查是否为怪兽间战斗
	local a=Duel.GetAttacker()
	local d=Duel.GetAttackTarget()

	if a and d and a:IsType(TYPE_MONSTER) and d:IsType(TYPE_MONSTER) then
		--怪兽间战斗，取消伤害
		Duel.ChangeBattleDamage(tp,0)
		Duel.ChangeBattleDamage(1-tp,0)
	end
	--直接攻击玩家的伤害保持不变
end

--=================================
--初始化和应用规则
--=================================

--为所有怪兽添加Galaxy规则效果
function Galaxy.ApplyToAllMonsters()
	if not Galaxy.IsGalaxyDuel() then return end

	--获取场上所有怪兽
	local g=Duel.GetMatchingGroup(Card.IsType,0,LOCATION_MZONE,LOCATION_MZONE,nil,TYPE_MONSTER)
	for tc in aux.Next(g) do
		Galaxy.CreateDefenseAsHPEffect(tc)
	end
end

--初始化Galaxy规则
function Galaxy.InitializeRules()
	if not Galaxy.IsGalaxyDuel() then return end

	--应用各项规则
	Galaxy.PreventCoverSummon()
	Galaxy.PreventSetSpellTrap()
	Galaxy.PreventDirectAttack()
	Galaxy.PreventBattleDamage()
	Galaxy.ApplyToAllMonsters()

	--创建一个虚拟卡牌作为效果拥有者
	local dummy=Duel.CreateToken(0, 9999996)

	--注册召唤时的效果应用
	local e1=Effect.CreateEffect(dummy)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetOperation(Galaxy.OnSummonSuccess)
	Duel.RegisterEffect(e1,0)

	local e2=Effect.CreateEffect(dummy)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetOperation(Galaxy.OnSummonSuccess)
	Duel.RegisterEffect(e2,0)
end

function Galaxy.OnSummonSuccess(e,tp,eg,ep,ev,re,r,rp)
	--为新召唤的怪兽应用Galaxy规则
	for tc in aux.Next(eg) do
		if tc:IsType(TYPE_MONSTER) then
			Galaxy.CreateDefenseAsHPEffect(tc)
		end
	end
end

--=================================
--自动初始化
--=================================

--立即初始化Galaxy规则
Galaxy.InitializeRules()

```