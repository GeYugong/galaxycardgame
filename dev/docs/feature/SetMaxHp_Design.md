# Duel.SetMaxHp 设计文档

> **状态**: 设计阶段 - 暂未实现
> **用途**: 提供设置单位最大HP的API，支持"最终基础值"语义

---

## 1. 设计目标

### 1.1 核心需求
- 提供 `Duel.SetMaxHp(c, value)` API，直接设置单位的基础最大HP
- **Final 语义**：SetMaxHp 设置的是最终的基础值，`EFFECT_UPDATE_HP` 在此基础上叠加
- **临时性**：效果重置后恢复到原始值（不修改数据库中的原始HP）
- **保持当前HP**：设置最大HP时，当前HP保持不变（除非超过新上限则自动钳制）

### 1.2 与现有系统的关系
| 功能 | 用途 | 触发HP事件 | 修改层级 |
|------|------|-----------|---------|
| `Duel.AddHp` | 立即增减当前HP | ✅ 触发 | 当前HP |
| `Duel.SetHp` | 直接设置当前HP | ❌ 不触发 | 当前HP |
| `EFFECT_UPDATE_HP` | 持续增减最大HP | ✅ 触发 | 最大HP（叠加） |
| `Duel.SetMaxHp` ⭐ | 设置基础最大HP | ❌ 不触发 | 最大HP（基础） |

---

## 2. HP 层级结构（新设计）

### 2.1 当前实现（3层）
```
原始最大HP (hp_max_ori) - 数据库中的守备力值
    ↓
当前最大HP (hp_max_now) = 原始最大HP + EFFECT_UPDATE_HP总和
    ↓
当前HP (now_hp) - 实际生命值
```

### 2.2 新设计（4层）
```
原始最大HP (hp_max_ori) - 数据库中的守备力值，永不改变
    ↓
基础最大HP (hp_max_base) - 可被 Duel.SetMaxHp 修改，默认 = hp_max_ori
    ↓
EFFECT_UPDATE_HP 叠加 - 持续效果增减
    ↓
最终最大HP (hp_max_now) = hp_max_base + EFFECT_UPDATE_HP总和
    ↓
当前HP (now_hp) - 实际生命值，≤ hp_max_now
```

### 2.3 示例场景
```lua
-- 单位原始HP: 5
-- 初始状态: 原始=5, 基础=5, 最终=5, 当前=5

-- 1. 受到伤害
Duel.AddHp(c, -2, REASON_EFFECT)
-- 结果: 原始=5, 基础=5, 最终=5, 当前=3

-- 2. 获得持续增益
local e = Effect.CreateEffect(c)
e:SetCode(EFFECT_UPDATE_HP)
e:SetValue(2)
-- 结果: 原始=5, 基础=5, 最终=7, 当前=3

-- 3. SetMaxHp 设置基础值为10
Duel.SetMaxHp(c, 10)
-- 结果: 原始=5, 基础=10, 最终=12 (10+2), 当前=3

-- 4. 增益效果消失
e:Reset()
-- 结果: 原始=5, 基础=10, 最终=10, 当前=3

-- 5. 效果重置（如离场再入场）
-- 结果: 原始=5, 基础=5, 最终=5, 当前=5 (重新初始化)
```

---

## 3. 实现方案

### 3.1 数据结构修改

#### 当前 Label 存储（utility.lua:2109）
```lua
e2:SetLabel(hp, hp, 0)
-- 参数: (原始最大HP, 当前最大HP, 上次EFFECT_UPDATE_HP总和)
```

#### 新 Label 存储
```lua
e2:SetLabel(hp, hp, 0, 0)
-- 参数: (原始最大HP, 基础最大HP, 上次EFFECT_UPDATE_HP总和, 保留字段)
```

**注意**: Lua 的 `SetLabel` 支持多返回值存储，但需要确认引擎是否支持4个参数。如果不支持，可以用字符串编码或额外的 Label 效果。

### 3.2 核心函数修改

#### A. `Galaxy.InitializeHp` (utility.lua:2091-2113)
```lua
function Galaxy.InitializeHp(e,tp,eg,ep,ev,re,r,rp)
    local c = e:GetHandler()
    if not c:IsLocation(LOCATION_MZONE) then return false end
    local hp = c:GetBaseHp()

    -- e1: EFFECT_SET_DEFENSE 存储当前HP
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_SET_DEFENSE)
    e1:SetValue(hp)
    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
    e1:SetReset(RESET_EVENT + RESETS_STANDARD)
    c:RegisterEffect(e1)

    -- e2: EVENT_ADJUST 计算HP
    local e2 = Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
    e2:SetCode(EVENT_ADJUST)
    e2:SetRange(LOCATION_MZONE)
    e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
    e2:SetOperation(Galaxy.CalculateHp)
    e2:SetReset(RESET_EVENT + RESETS_STANDARD)
    -- 修改: 添加 hp_max_base 参数
    e2:SetLabel(hp, hp, 0, 0) -- (原始, 基础, UPDATE_HP总和, 保留)
    e2:SetLabelObject(e1)
    c:RegisterEffect(e2)
    return false
end
```

#### B. `Galaxy.CalculateHp` (utility.lua:2116-2207)
```lua
function Galaxy.CalculateHp(e,tp,eg,ep,ev,re,r,rp)
    local c = e:GetHandler()
    local now_hp = c:GetHp()

    -- 修改: 获取4个值
    local hp_max_ori, hp_max_base, last_effect_total, _ = e:GetLabel()

    -- 处理 FLAG_ADD_HP_IMMEDIATELY (保持不变)
    local val = c:GetFlagEffectLabel(FLAG_ADD_HP_IMMEDIATELY_BATTLE)
    if val then
        -- 注意: 这里 hp_max_now 需要重新计算
        local hp_max_now = hp_max_base + last_effect_total
        now_hp = Galaxy.CalculateAddHpImmediately(c, val, now_hp, hp_max_now, REASON_BATTLE, 0)
        if now_hp <= 0 then
            Duel.Destroy(c, REASON_RULE)
            return
        end
        c:ResetFlagEffect(FLAG_ADD_HP_IMMEDIATELY_BATTLE)
    end

    -- ... (效果伤害处理，类似)

    -- 计算当前所有 EFFECT_UPDATE_HP 效果的总和
    local hp_adds = {c:IsHasEffect(EFFECT_UPDATE_HP)}
    local current_effect_total = 0
    if hp_adds[1] then
        for _, ei in ipairs(hp_adds) do
            val = ei:GetValue()
            if type(val) == "function" then
                val = val(ei, c)
            elseif not val then
                val = 0
            end
            current_effect_total = current_effect_total + val
        end
        -- 反转效果支持
        local rev = c:IsHasEffect(EFFECT_REVERSE_UPDATE)
        if rev then current_effect_total = -current_effect_total end
    end

    -- 计算最终最大HP: 基础 + 效果总和
    local hp_max_now = hp_max_base + current_effect_total

    -- 计算本次效果变化量
    local effect_delta = current_effect_total - last_effect_total

    if effect_delta ~= 0 then
        -- 效果增加时，当前HP也增加
        if effect_delta > 0 then
            now_hp = now_hp + effect_delta
        end
        -- 触发 EFFECT_UPDATE_HP 变化事件
        Galaxy.RaiseHpEvent(c, effect_delta, true, REASON_EFFECT, rp or 0)

        -- 保存新状态
        e:SetLabel(hp_max_ori, hp_max_base, current_effect_total, 0)
    end

    -- 三重安全检查
    if hp_max_now <= 0 then
        Duel.Destroy(c, REASON_RULE)
        return
    end
    if now_hp > hp_max_now then
        now_hp = hp_max_now
    end
    if now_hp <= 0 then
        Duel.Destroy(c, REASON_RULE)
        return
    end

    e:GetLabelObject():SetValue(now_hp)
end
```

#### C. `Card.GetMaxHp` (utility.lua:2550-2561)
```lua
function Card.GetMaxHp(c)
    local effects = {c:IsHasEffect(EVENT_ADJUST)}
    for _, eff in ipairs(effects) do
        if eff:GetOperation() == Galaxy.CalculateHp then
            -- 修改: 返回 基础HP + 效果总和
            local hp_max_ori, hp_max_base, last_effect_total, _ = eff:GetLabel()
            return hp_max_base + last_effect_total
        end
    end
    return c:GetOriginalHp()
end
```

### 3.3 新增 `Duel.SetMaxHp` 函数

```lua
--设置基础最大生命力（不触发HP事件）
---@param g_c Card|Group 要设置最大HP的卡片或卡片组
---@param max_hp number 要设置的基础最大HP值
function Duel.SetMaxHp(g_c, max_hp)
    local typ = aux.GetValueType(g_c)
    if typ == "Card" then
        g_c = Group.FromCards(g_c)
    elseif typ ~= "Group" then
        error("parameter 1 should be Card or Group", 2)
    end
    if aux.GetValueType(max_hp) ~= "number" then
        error("parameter 2 should be number", 2)
    end
    if max_hp <= 0 then
        error("parameter 2 should be > 0", 2)
    end

    for c in aux.Next(g_c) do
        if not c:IsLocation(LOCATION_MZONE) then
            error("card must be in monster zone", 2)
        end

        -- 查找HP系统的EVENT_ADJUST效果
        local effects = {c:IsHasEffect(EVENT_ADJUST)}
        local hp_system_found = false

        for _, eff in ipairs(effects) do
            if eff:GetOperation() == Galaxy.CalculateHp then
                -- 获取当前HP系统状态
                local hp_max_ori, hp_max_base, last_effect_total, _ = eff:GetLabel()

                -- 修改基础最大HP
                hp_max_base = max_hp

                -- 计算新的最终最大HP
                local hp_max_now = hp_max_base + last_effect_total

                -- 钳制当前HP
                local now_hp = c:GetHp()
                if now_hp > hp_max_now then
                    now_hp = hp_max_now
                    -- 直接修改当前HP（不触发事件）
                    local hp_effect = eff:GetLabelObject()
                    if hp_effect then
                        hp_effect:SetValue(now_hp)
                    end
                end

                -- 保存新状态
                eff:SetLabel(hp_max_ori, hp_max_base, last_effect_total, 0)

                hp_system_found = true
                break
            end
        end

        if not hp_system_found then
            error("HP system not initialized for this card", 2)
        end
    end
end
```

---

## 4. API 设计

### 4.1 函数签名
```lua
Duel.SetMaxHp(card_or_group, max_hp)
```

### 4.2 参数说明
| 参数 | 类型 | 说明 |
|------|------|------|
| card_or_group | Card \| Group | 要设置最大HP的单位 |
| max_hp | number | 新的基础最大HP值（必须 > 0） |

### 4.3 返回值
无返回值

### 4.4 异常处理
- `max_hp <= 0` → 抛出错误
- 卡片不在怪兽区 → 抛出错误
- HP系统未初始化 → 抛出错误

---

## 5. 使用示例

### 5.1 基础用法
```lua
-- 将单位的基础最大HP设置为10
Duel.SetMaxHp(c, 10)
```

### 5.2 配合 EFFECT_UPDATE_HP
```lua
-- 单位原始HP为5，当前3/5
local c = ...

-- 添加持续增益 +3
local e1 = Effect.CreateEffect(c)
e1:SetType(EFFECT_TYPE_SINGLE)
e1:SetCode(EFFECT_UPDATE_HP)
e1:SetValue(3)
e1:SetReset(RESET_EVENT+RESETS_STANDARD)
c:RegisterEffect(e1)
-- 状态: 3/8 (基础5 + 增益3)

-- 设置基础最大HP为10
Duel.SetMaxHp(c, 10)
-- 状态: 3/13 (基础10 + 增益3)

-- 增益消失
e1:Reset()
-- 状态: 3/10 (基础10)
```

### 5.3 变身效果示例
```lua
-- 单位"进化"，永久提升最大HP
function s.evolve_op(e,tp,eg,ep,ev,re,r,rp)
    local c = e:GetHandler()
    if c:IsFaceup() and c:IsRelateToEffect(e) then
        -- 基础最大HP翻倍
        local current_max = c:GetMaxHp()
        Duel.SetMaxHp(c, current_max * 2)

        -- 注意: 当前HP保持不变，不会满血
        -- 如果需要满血，需要额外调用:
        -- Duel.SetHp(c, c:GetMaxHp())
    end
end
```

### 5.4 复活效果（与当前实现对比）
```lua
-- 方案1: 使用 SetMaxHp（最大HP永久降低）
function s.revive_with_setmaxhp(e,tp,eg,ep,ev,re,r,rp)
    local c = e:GetHandler()
    if Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP_ATTACK)>0 then
        Duel.SetMaxHp(c, 1)  -- 最大HP变为1
        Duel.SetHp(c, 1)      -- 当前HP也变为1
    end
end

-- 方案2: 使用 SetHp（仅当前HP降低，最大HP不变）
function s.revive_with_sethp(e,tp,eg,ep,ev,re,r,rp)
    local c = e:GetHandler()
    if Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP_ATTACK)>0 then
        Duel.SetHp(c, 1)  -- 仅当前HP变为1，最大HP仍为5
    end
end
-- 区别: 方案1复活后如果获得治疗，最多只能恢复到1HP
--       方案2复活后如果获得治疗，可以恢复到5HP
```

---

## 6. 测试要点

### 6.1 基本功能测试
- [ ] 设置最大HP后，最大HP正确显示
- [ ] 当前HP超过新上限时自动钳制
- [ ] 当前HP未超过新上限时保持不变

### 6.2 与 EFFECT_UPDATE_HP 交互测试
- [ ] SetMaxHp 后添加 EFFECT_UPDATE_HP，正确叠加
- [ ] 先有 EFFECT_UPDATE_HP 再 SetMaxHp，基础值正确修改
- [ ] EFFECT_UPDATE_HP 消失后，最大HP降回基础值

### 6.3 边界情况测试
- [ ] 设置最大HP为1
- [ ] 设置最大HP大于原始值
- [ ] 设置最大HP小于当前HP
- [ ] 多次设置最大HP

### 6.4 重置行为测试
- [ ] 单位离场再入场，最大HP恢复原始值
- [ ] 效果被无效时，行为是否正确

### 6.5 不触发事件测试
- [ ] 确认 SetMaxHp 不触发任何 HP 事件
- [ ] 确认钳制当前HP时不触发事件

---

## 7. 兼容性注意事项

### 7.1 Label 参数数量
需要确认 Lua/引擎是否支持 `SetLabel(v1, v2, v3, v4)` 的4参数形式。如果不支持，备选方案：

**方案A**: 使用额外的 Label 效果
```lua
e2:SetLabel(hp_max_ori, hp_max_base, last_effect_total)
-- 创建额外效果存储第4个参数
local e3 = Effect.CreateEffect(c)
e3:SetType(EFFECT_TYPE_SINGLE)
e3:SetCode(EFFECT_FLAG_EFFECT)
e3:SetLabel(0) -- 保留字段
c:RegisterEffect(e3)
```

**方案B**: 使用字符串编码
```lua
e2:SetLabel(string.format("%d,%d,%d,%d", hp_max_ori, hp_max_base, last_effect_total, 0))
-- 读取时解析
local parts = {}
for v in string.gmatch(e:GetLabel(), "[^,]+") do
    table.insert(parts, tonumber(v))
end
```

### 7.2 现有卡片兼容
- 所有现有卡片无需修改（hp_max_base 默认等于 hp_max_ori）
- 只有使用 SetMaxHp 的新卡才会利用新机制

---

## 8. 真实案例：c10000062.lua 的限制

### 8.1 案例背景

**卡片**: 共振壳 (c10000062.lua)
**效果**: 永续魔法，场上的极光族大型单位变为 **1/4**（攻击力1，HP4）

### 8.2 当前实现（临时方案）

```lua
-- 攻击力设为1
local e3=Effect.CreateEffect(c)
e3:SetType(EFFECT_TYPE_FIELD)
e3:SetCode(EFFECT_SET_ATTACK)
e3:SetRange(LOCATION_SZONE)
e3:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
e3:SetTarget(s.atktg)
e3:SetValue(1)
c:RegisterEffect(e3)

-- HP设为4（使用 EFFECT_UPDATE_HP）
local e4=e3:Clone()
e4:SetCode(EFFECT_UPDATE_HP)
e4:SetValue(s.hpval)
c:RegisterEffect(e4)

-- 极光族大型单位目标
function s.atktg(e,c)
    return c:IsRace(GALAXY_CATEGORY_AURORA) and c:IsType(TYPE_FUSION)
end

-- HP修改值：将最大HP调整为4
function s.hpval(e,c)
    return 4 - c:GetBaseHp()
end
```

### 8.3 工作原理

通过动态计算差值来试图"强制"HP为4：
- 单位原始HP为 5 → 效果值为 `-1` → 最终HP为 `5 + (-1) = 4` ✅
- 单位原始HP为 3 → 效果值为 `+1` → 最终HP为 `3 + 1 = 4` ✅
- 单位原始HP为 4 → 效果值为 `0` → 最终HP为 `4 + 0 = 4` ✅

### 8.4 存在的问题

**问题**: `EFFECT_UPDATE_HP` 是**叠加式**的，多个效果会累加，导致"强制为4"的语义失效。

#### 失效场景示例

假设某个极光族单位同时受到以下效果：
1. 共振壳的效果: `4 - BaseHp`
2. 另一张卡的增益效果: `+3`

**预期结果**: HP应该为4（共振壳强制设为4）
**实际结果**:
```
BaseHp = 5
共振壳效果 = 4 - 5 = -1
其他增益 = +3
最终HP = 5 + (-1) + 3 = 7  ❌ 错误！
```

### 8.5 根本原因

`EFFECT_UPDATE_HP` 的语义是**增减**（delta），而非**设为**（set to）。当前实现尝试通过 `4 - BaseHp` 模拟"设为4"，但这个逻辑只在**单独作用**时成立，一旦有其他 UPDATE_HP 效果叠加，计算就会错误。

### 8.6 正确解决方案（需要 SetMaxHp）

使用 `Duel.SetMaxHp` 可以直接设置基础值，不受其他效果影响：

```lua
-- 方案A: 使用 EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS 持续设置
local e4=Effect.CreateEffect(c)
e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
e4:SetCode(EVENT_ADJUST)
e4:SetRange(LOCATION_SZONE)
e4:SetOperation(s.hpop)
c:RegisterEffect(e4)

function s.hpop(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetMatchingGroup(s.atktg,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
    for tc in aux.Next(g) do
        if tc:GetMaxHp() ~= 4 then
            Duel.SetMaxHp(tc, 4)
        end
    end
end
```

或者：

```lua
-- 方案B: 注册效果时初始化（适用于单次设置场景）
-- 需要配合进场监听
local e4=Effect.CreateEffect(c)
e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
e4:SetCode(EVENT_ADJUST)
e4:SetRange(LOCATION_SZONE)
e4:SetOperation(s.hpinit)
c:RegisterEffect(e4)

function s.hpinit(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetMatchingGroup(s.atktg,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
    for tc in aux.Next(g) do
        if tc:GetFlagEffect(id)==0 then
            Duel.SetMaxHp(tc, 4)
            tc:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,1)
        end
    end
end
```

### 8.7 临时应对建议

在 `Duel.SetMaxHp` 实现之前：
1. **接受限制**: 文档中明确说明当前实现在多效果叠加时可能失效
2. **避免冲突**: 设计新卡时避免给极光族单位添加其他 `EFFECT_UPDATE_HP` 效果
3. **测试场景**: 重点测试单一效果场景，复杂交互留待未来优化

### 8.8 案例总结

| 项目 | 说明 |
|------|------|
| **问题类型** | `EFFECT_UPDATE_HP` 无法实现"强制为特定值"语义 |
| **影响范围** | c10000062.lua 及任何尝试"强制HP为X"的卡片 |
| **当前状态** | 临时方案可用，但存在多效果叠加时的逻辑错误 |
| **根本解决** | 需要实现 `Duel.SetMaxHp` 提供基础值设置能力 |
| **优先级** | 中（当前可用但不完美，长期需要修复） |

---

## 9. 实现优先级

**当前状态**: ⏸️ 暂缓实现

**建议实现顺序**:
1. 先确认 Label 多参数支持
2. 修改 InitializeHp 和 CalculateHp
3. 实现 Duel.SetMaxHp 函数
4. 修改 Card.GetMaxHp 函数
5. 编写测试卡片验证功能

**预计工作量**: 中等（2-3小时）

---

## 10. 相关文件清单

需要修改的文件：
- `script/utility.lua` - 核心HP系统实现
  - `Galaxy.InitializeHp` (2091-2113行)
  - `Galaxy.CalculateHp` (2116-2207行)
  - `Card.GetMaxHp` (2550-2561行)
  - 新增 `Duel.SetMaxHp` 函数

测试用例建议：
- `script/c10000XXX.lua` - 测试卡片示例

---

**审阅状态**: 待审阅
**下次更新**: 实现完成后补充实际测试结果
