# YGOPro Lua Development Complete Guide

## Core Development Principles

### 1. Always Reference Original Cards
- **Must ask user** for related original card IDs before implementation
- Study complete implementation in `ai/examples/script/c[cardid].lua`
- Copy and modify original patterns, never create from scratch
- YGOPro has 10+ years of verified implementations

### 2. Strict API Compliance
- Every effect code has precise purpose and timing
- Never guess API usage - follow documentation and original implementations
- Avoid combining unverified effect codes
- Reference `ai/luatips/tips.json` for complete API documentation

### 3. Correct Effect Types and Timing
```lua
// ❌ Wrong: Using CONTINUOUS for trigger effects
SetType(EFFECT_TYPE_CONTINUOUS)

// ✅ Correct: Reference original using TRIGGER_F
SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
SetCode(EVENT_DAMAGE_STEP_END)
SetCondition(aux.dsercon)
```

## Key Reference Cards & Patterns

### Essential Reference Cards
- `c7852878`: EVENT_DAMAGE_STEP_END + TRIGGER_F standard pattern
- `c36553319`: EFFECT_SELF_DESTROY auto-destroy best practice
- `c62892347`: EFFECT_CANNOT_CHANGE_POSITION position control
- `c7171149`: Summon turn attack restriction complete implementation
- `c36088082`: Conditional battle effect timing handling

### Core Technical Patterns

#### Defense-as-HP System (Optimal Solution)
```lua
EVENT_DAMAGE_STEP_END + EFFECT_TYPE_TRIGGER_F + aux.dsercon
EFFECT_UPDATE_DEFENSE + negative values
EFFECT_SELF_DESTROY + condition function
```

#### Conditional Continuous Effects
```lua
EFFECT_TYPE_SINGLE + SetCondition(condition_function)
-- For effects that need dynamic condition checking
```

#### Multi-timing Unified Processing
```lua
-- Base effect + Clone() + modify SetCode()
-- For multiple similar timing effect registration
```

## Important API Usage Points

- `EFFECT_UPDATE_DEFENSE`: For defense modification, supports negative values
- `EVENT_DAMAGE_STEP_END`: Correct timing for post-battle processing
- `aux.dsercon`: Standard condition check for damage step end
- `EFFECT_SELF_DESTROY`: Implements auto-destroy, doesn't enter chain
- Condition functions should check `Duel.GetAttackTarget()` to distinguish direct attack vs monster battle

## Common Effect Implementations

### Permanent Stat Modification
```lua
-- ATK/DEF boost (reference: c86318356 Prairie)
local e1=Effect.CreateEffect(c)
e1:SetType(EFFECT_TYPE_FIELD)
e1:SetCode(EFFECT_UPDATE_ATTACK)
e1:SetRange(LOCATION_FZONE)
e1:SetTargetRange(LOCATION_MZONE,0)
e1:SetTarget(aux.TargetBoolFunction(Card.IsRace,RACE_WARRIOR))
e1:SetValue(1)
c:RegisterEffect(e1)
```

### Trigger Effects
```lua
-- Mandatory trigger (reference: c82685480)
local e1=Effect.CreateEffect(c)
e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
e1:SetCode(EVENT_SPSUMMON_SUCCESS)
e1:SetTarget(target_function)
e1:SetOperation(operation_function)
c:RegisterEffect(e1)
```

### Target Destruction
```lua
-- Target and destroy (reference: c5318639 Mystical Space Typhoon)
function card.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsOnField() and chkc:IsType(TYPE_SPELL+TYPE_TRAP) end
    if chk==0 then return Duel.IsExistingTarget(Card.IsType,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil,TYPE_SPELL+TYPE_TRAP) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
    local g=Duel.SelectTarget(tp,Card.IsType,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil,TYPE_SPELL+TYPE_TRAP)
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end
```

### Cost Check Pattern (chk parameter)
```lua
function card_cost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        -- chk==0: Check phase - verify conditions only, no resource consumption
        return Duel.CheckLPCost(tp, 1000)
    end
    -- chk!=0: Execute phase - actually pay the cost
    Duel.PayLPCost(tp, 1000)
end
```

### Hand Trap Implementation
```lua
-- Hand trap activation (reference: c10045474)
local e1=Effect.CreateEffect(c)
e1:SetType(EFFECT_TYPE_QUICK_O)
e1:SetCode(EVENT_FREE_CHAIN)
e1:SetRange(LOCATION_HAND)
e1:SetCondition(condition_function)
e1:SetCost(cost_function)
e1:SetTarget(target_function)
e1:SetOperation(operation_function)
c:RegisterEffect(e1)
```

## Completed Card Examples

### Continuous Spell (LP Recovery)
```lua
-- c10000014: Once per turn, mandatory LP recovery
local e2=Effect.CreateEffect(c)
e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
e2:SetCode(EVENT_PHASE_START+PHASE_STANDBY)
e2:SetRange(LOCATION_SZONE)
e2:SetCountLimit(1)
e2:SetCondition(function(e,tp) return Duel.GetTurnPlayer()==tp end)
e2:SetOperation(function(e,tp) Duel.Recover(tp,2,REASON_EFFECT) end)
c:RegisterEffect(e2)
```

### Field Spell (Stat Boost)
```lua
-- c10000015: Warrior ATK/DEF +1 (reference: c86318356)
local e1=Effect.CreateEffect(c)
e1:SetType(EFFECT_TYPE_FIELD)
e1:SetCode(EFFECT_UPDATE_ATTACK)
e1:SetRange(LOCATION_FZONE)
e1:SetTargetRange(LOCATION_MZONE,0)
e1:SetTarget(aux.TargetBoolFunction(Card.IsRace,RACE_WARRIOR))
e1:SetValue(1)
c:RegisterEffect(e1)
-- Clone for DEF
local e2=e1:Clone()
e2:SetCode(EFFECT_UPDATE_DEFENSE)
c:RegisterEffect(e2)
```

### Protect Monster (Protection Effect)
```lua
-- c10000019: Protection effect - forces opponents to attack this monster first
local e1=Effect.CreateEffect(c)
e1:SetType(EFFECT_TYPE_SINGLE)
e1:SetCode(EFFECT_PROTECT) -- Mark as protection monster (code 501)
c:RegisterEffect(e1)
-- Note: Attack targeting restriction is handled globally by Galaxy.BattleSystem()
```

### Rush Monster (Rush Effect)
```lua
-- c10000018: Rush effect - can attack in the same turn it's deployed
local e1=Effect.CreateEffect(c)
e1:SetType(EFFECT_TYPE_SINGLE)
e1:SetCode(EFFECT_RUSH) -- Mark as rush monster (code 500)
c:RegisterEffect(e1)
-- Note: Overrides Galaxy.SUMMON_TURN_CANNOT_ATTACK global restriction
```

### Legacy Taunt Monster (Pre-protection system)
```lua
-- c10000019: Force opponents to attack this monster
local e1=Effect.CreateEffect(c)
e1:SetType(EFFECT_TYPE_FIELD)
e1:SetCode(EFFECT_CANNOT_SELECT_BATTLE_TARGET)
e1:SetRange(LOCATION_MZONE)
e1:SetTargetRange(0,LOCATION_MZONE)
e1:SetValue(function(e,c) return c~=e:GetHandler() and not c:GetFlagEffect(99999999) end)
c:RegisterEffect(e1)
-- Mark as taunt
c:RegisterFlagEffect(99999999,RESET_EVENT+RESETS_STANDARD,EFFECT_FLAG_EFFECT,1)
```

## Development Workflow

### Step 1: Requirement Analysis
- Clarify the game mechanics to implement
- Find original cards with similar effects
- Analyze original card implementation

### Step 2: API Research
- Check `ai/luatips/tips.json` for relevant APIs
- Confirm correct effect codes and parameters
- Understand API timing and scope

### Step 3: Reference Implementation
- Copy original card code structure
- Replace specific values and conditions
- Maintain original error handling and boundary checks

### Step 4: Testing & Verification
- Compare behavior with original cards under same conditions
- Use minimal test scenarios to verify core functionality
- Confirm effects trigger at correct timing

## Common Mistakes & Solutions

### Timing Errors
```lua
// ❌ Wrong: Using EVENT_BATTLED
SetCode(EVENT_BATTLED)

// ✅ Correct: Using EVENT_DAMAGE_STEP_END
SetCode(EVENT_DAMAGE_STEP_END)
```

### Effect Type Errors
```lua
// ❌ Wrong: Mandatory effect using CONTINUOUS
SetType(EFFECT_TYPE_CONTINUOUS)

// ✅ Correct: Mandatory effect using TRIGGER_F
SetType(EFFECT_TYPE_TRIGGER_F)
```

### Destruction Mechanism Errors
```lua
// ❌ Wrong: Manual Duel.Destroy call
Duel.Destroy(c, REASON_EFFECT)

// ✅ Correct: Using EFFECT_SELF_DESTROY
SetCode(EFFECT_SELF_DESTROY)
SetCondition(condition_function)
```

## Important Technical Fixes

### Galaxy Protection System (Latest Update)
- **EFFECT_PROTECT constant**: New effect code `501` for protection marking
- **EFFECT_RUSH constant**: New effect code `500` for deployment turn attack ability
- **System-level implementation**: Protection handled globally by `Galaxy.BattleSystem()`
- **Attack priority logic**: `Galaxy.ProtectAttackLimit()` forces opponents to attack protected units first
- **API changes**: `Galaxy.CheckCost/PayCost` replaced with `Duel.CheckSupplyCost/PaySupplyCost`
- **Bug fix**: Corrected player detection in protection logic (`c:GetControler()` vs `e:GetHandlerPlayer()`)

### Galaxy Attack Restriction Configuration
- Added `Galaxy.SUMMON_TURN_CANNOT_ATTACK` toggle
- Individual cards can override global setting
- Prevents conflicts with special effect monsters

### Galaxy Cost System LP Safety
- Added double LP check in `Galaxy.PayCost()`
- Prevents bankruptcy from insufficient LP during payment
- Graceful handling of payment failures

### Special Summon Condition Extension Interface
```lua
Galaxy.SetExtraSpCondition(id, function(e,c,tp)
    return Duel.GetLP(tp) >= 20  -- Additional condition
end)
```

## Quality Assurance

### Debugging Strategies
1. **Incremental testing**: Test each effect immediately after implementation
2. **Reference comparison**: Compare behavior with original cards in same scenarios
3. **Boundary testing**: Test extreme conditions (LP shortage, field full, etc.)
4. **User feedback**: Most valuable guidance source

### Best Practices
1. **Original cards first**: YGOPro API has 10+ years of verification
2. **Humble learning**: Reusing mature practices more reliable than innovation
3. **Quality over creativity**: Stable implementation more important than uniqueness
4. **Systematic thinking**: Consider effect impact on entire game system
5. **Defensive programming**: Add necessary safety checks and error handling

## Galaxy Semantic Programming Guidelines

### Core Principle
When writing GCG card scripts, prioritize Galaxy semantic terms over original YGO terms to improve code readability and game immersion.

### Term Mapping Table

#### Basic Types
```lua
TYPE_MONSTER → GALAXY_TYPE_UNIT       // 单位
TYPE_SPELL   → GALAXY_TYPE_SUPPORT    // 支援
TYPE_TRAP    → GALAXY_TYPE_TACTICS    // 战术
```

#### Location Areas
```lua
LOCATION_HAND   → GALAXY_LOCATION_HAND_CARDS   // 手牌区
LOCATION_MZONE  → GALAXY_LOCATION_UNIT_ZONE    // 单位区
LOCATION_SZONE  → GALAXY_LOCATION_SUPPORT_ZONE // 支援区
LOCATION_GRAVE  → GALAXY_LOCATION_DISCARD      // 弃牌区
LOCATION_DECK   → GALAXY_LOCATION_BASIC_DECK   // 基本卡组
```

#### Race/Categories
```lua
RACE_INSECT   → GALAXY_CATEGORY_ARTHROPOD  // 节肢类
RACE_WARRIOR  → GALAXY_CATEGORY_HUMAN      // 人类
RACE_BEAST    → GALAXY_CATEGORY_MAMMAL     // 哺乳类
RACE_WINDBEAST → GALAXY_CATEGORY_AVIAN     // 鸟类
```

#### Function Calls
```lua
c:IsRace()      → c:IsGalaxyCategory()    // 检查类别
c:IsAttribute() → c:IsGalaxyProperty()    // 检查特性
```

### Practical Examples
```lua
// ✅ Recommended: Using Galaxy semantic terms
function s.filter(c)
    return c:IsGalaxyCategory(GALAXY_CATEGORY_ARTHROPOD) and c:IsType(GALAXY_TYPE_UNIT)
end

function s.condition(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsExistingMatchingCard(s.filter,tp,GALAXY_LOCATION_HAND_CARDS,0,1,nil)
end

// ❌ Avoid: Direct use of original YGO terms
function s.filter(c)
    return c:IsRace(RACE_INSECT) and c:IsType(TYPE_MONSTER)
end
```

### Comment Terminology
- 特殊召唤 → 部署 (Deployment)
- 攻击力 → 战斗力 (Combat Power)
- 守备力 → 生命值 (HP/Life Points)
- 怪兽 → 单位 (Unit)
- 魔法 → 支援 (Support)
- 陷阱 → 战术 (Tactics)

### Implementation Example
```lua
--幼虫工兵 (Larva Engineer)
--部署时如果手牌中有其他节肢类单位，这张卡获得+1/+2（战斗力/生命值）
local s, id = Import()
function s.initial(c)
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetCondition(s.condition)
    e1:SetOperation(s.operation)
    c:RegisterEffect(e1)
end

function s.filter(c)
    return c:IsGalaxyCategory(GALAXY_CATEGORY_ARTHROPOD) and c:IsType(GALAXY_TYPE_UNIT)
end

function s.condition(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    return Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_HAND,0,1,c)
end
```

This semantic system maintains YGOPro technical compatibility while creating a unique galaxy-themed gaming experience.

## Galaxy Card Development Patterns

### Advanced Implementation Techniques

#### Synergy-Based Card Design
- **Field monitoring**: Use `EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F` for cross-card interactions
- **Token ecosystem**: Central units spawn and manage related tokens (eggs→warriors)
- **Dynamic scaling**: Stats based on other units present (`EFFECT_FLAG_SINGLE_RANGE`)

#### Cost-Benefit Mechanics
- **Risk-reward summoning**: Allow deployment with insufficient resources, apply penalties
- **Resource conversion**: Transform HP to cards, supply to units
- **Delayed consequences**: Use phase-based removal with `RESET_SELF_TURN,1`

#### Battle Enhancement Systems
- **Compound effects**: Combine stat boosts with triggered battle abilities
- **HP manipulation**: Use `EFFECT_UPDATE_DEFENSE` with negative values for damage
- **Complete lockdown**: Layer multiple disable effects for total control

### Best Practices

1. **Galaxy semantics**: Always use `GALAXY_*` constants for consistency
2. **Synergy design**: Create meaningful interactions between related cards
3. **Balanced costs**: Match powerful effects with appropriate supply requirements
4. **Effect duration**: Choose permanent vs temporary effects appropriately
5. **Safety checks**: Validate targets and conditions before applying effects

## Development Resources
- **API documentation**: `ai/luatips/tips.json`
- **Code snippets**: `ai/luatips/snippets.json`
- **Reference examples**: `ai/examples/script/`
- **Galaxy rules**: `script/utility.lua`