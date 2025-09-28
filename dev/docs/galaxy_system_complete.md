# Galaxy Card Game System Complete Guide

## Overview
Galaxy Card Game implements a Hearthstone-like supply (mana) system and complete rule modifications based on YGOPro engine through Lua scripting.

## Supply System

### Core Mechanics
- **Start**: 0/0 supply
- **Growth**: +1 max supply at draw phase start (cap 10, script can exceed)
- **Recovery**: Full restore at draw phase start
- **Temporary exceed**: Cards can grant supply above max, auto-clamp next turn
- **Cost system**: Replaces LP costs for summoning

### API Reference

#### Core Lua APIs
```lua
-- Basic Operations
Duel.GetSupply(player)              -- Get current supply
Duel.GetMaxSupply(player)           -- Get max supply
Duel.SetSupply(player, current, max) -- Set supply values
Duel.AddSupply(player, amount)      -- Add supply (can exceed max)
Duel.SpendSupply(player, amount)    -- Spend supply
Duel.AddMaxSupply(player, amount)   -- Increase max supply
Duel.ClampSupply(player)            -- Clamp to max limit

-- Cost System
Duel.CheckSupplyCost(player, cost)  -- Check if enough supply
Duel.PaySupplyCost(player, cost)    -- Pay supply cost
```

#### Galaxy APIs (Updated)
```lua
-- New direct API (recommended)
Duel.CheckSupplyCost(tp, cost)  -- Check if enough supply
Duel.PaySupplyCost(tp, cost)    -- Pay supply cost

-- Legacy Galaxy wrapper (deprecated)
Galaxy.CheckCost(tp, cost)  -- Calls Duel.CheckSupplyCost
Galaxy.PayCost(tp, cost)    -- Calls Duel.PaySupplyCost
```

### Cost Check Pattern (chk parameter)
```lua
function card_cost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        -- chk==0: Check phase - verify conditions only
        return Duel.CheckSupplyCost(tp, 3)
    end
    -- chk!=0: Execute phase - actually pay the cost
    Duel.PaySupplyCost(tp, 3)
end
```

### Technical Implementation
- **Network sync**: MSG_SUPPLY_UPDATE (98)
- **UI display**: Below LP bar (Y: 50-68), format "{current}/{max}"
- **Colors**: Green when full, yellow when partial
- **Data storage**: Client (DuelInfo) + Server (player_info) structures

## Galaxy Rules System

### Implemented Rules ✅

#### 1. No Cover Summon/Set
- **Monsters**: Cannot be summoned face-down
- **Spells/Traps**: Cannot be set face-down
- **Implementation**: `EFFECT_CANNOT_MSET` / `EFFECT_CANNOT_SSET` per card

#### 2. Defense as HP System
- **Mechanics**: Battle reduces DEF instead of destroying, auto-destroy when DEF ≤ 0
- **Implementation**:
  ```lua
  EVENT_DAMAGE_STEP_END + EFFECT_TYPE_TRIGGER_F + aux.dsercon
  EFFECT_UPDATE_DEFENSE + negative values
  EFFECT_SELF_DESTROY + condition function
  ```

#### 3. Battle Damage Redefined
- **Mechanics**: Monster vs monster battle causes no LP damage, direct attacks do
- **Implementation**: Conditional `EFFECT_AVOID_BATTLE_DAMAGE`

#### 4. Attack Position Lock
- **Mechanics**: Monsters in attack position cannot change to defense
- **Implementation**: `EFFECT_CANNOT_CHANGE_POSITION` with condition

#### 5. Summon Turn Attack Restriction
- **Mechanics**: Summoned monsters cannot attack same turn
- **Implementation**: `EFFECT_CANNOT_ATTACK` + `RESET_PHASE+PHASE_END`

#### 6. Supply Cost System
- **Monster summoning**: Costs supply = level (configurable)
- **Spell/Trap activation**: ⚠️ Temporarily disabled
- **Implementation**: Based on complete supply system above

#### 7. Special Summon Only System
- **Mechanics**: No normal summon, unlimited special summons from hand
- **Implementation**: `EFFECT_SPSUMMON_PROC` replaces normal summon

#### 8. Trap Card Rules
- **Opponent Turn Only**: Trap cards can only be activated during opponent's turn
- **Hand Activation**: All trap cards can be activated directly from hand
- **Implementation**:
  ```lua
  EFFECT_CANNOT_TRIGGER + condition check (Duel.GetTurnPlayer() == tp)
  EFFECT_TRAP_ACT_IN_HAND for all trap cards
  ```

#### 9. Protection System
- **Mechanics**: Units with protection effect must be attacked first by opponents
- **System-level**: Globally enforced through `Galaxy.BattleSystem()`
- **Implementation**:
  ```lua
  -- Mark unit with protection
  local e1=Effect.CreateEffect(c)
  e1:SetType(EFFECT_TYPE_SINGLE)
  e1:SetCode(EFFECT_PROTECT) -- Custom effect code 501
  c:RegisterEffect(e1)

  -- Global attack restriction (handled by Galaxy.BattleSystem)
  EFFECT_CANNOT_SELECT_BATTLE_TARGET + Galaxy.ProtectAttackLimit
  ```

#### 10. Rush System
- **Mechanics**: Units with rush effect can attack in the same turn they are deployed
- **Implementation**:
  ```lua
  -- Mark unit with rush
  local e1=Effect.CreateEffect(c)
  e1:SetType(EFFECT_TYPE_SINGLE)
  e1:SetCode(EFFECT_RUSH) -- Custom effect code 500
  c:RegisterEffect(e1)

  -- Overrides global summon turn attack restriction
  ```

#### 11. Lethal System
- **Mechanics**: Units with lethal effect destroy any target they damage in battle (similar to Hearthstone's Poisonous)
- **Shield Interaction**: Shield completely blocks lethal effect
- **Implementation**:
  ```lua
  -- Mark unit with lethal
  local e1=Effect.CreateEffect(c)
  e1:SetType(EFFECT_TYPE_SINGLE)
  e1:SetCode(EFFECT_LETHAL) -- Custom effect code 506
  c:RegisterEffect(e1)

  -- Damage calculation: attack + target's current HP (ensures kill)
  -- Processed through Galaxy.ReduceHP battle system
  ```

#### 12. Stealth System
- **Mechanics**: Units with stealth cannot be targeted by attacks or effects (similar to Hearthstone)
- **Attack Reveal**: Stealth is removed after the unit attacks
- **Implementation**:
  ```lua
  -- Mark unit with stealth
  local e1=Effect.CreateEffect(c)
  e1:SetType(EFFECT_TYPE_SINGLE)
  e1:SetCode(EFFECT_STEALTH) -- Custom effect code 507
  c:RegisterEffect(e1)

  -- System handles: CANNOT_SELECT_BATTLE_TARGET + CANNOT_BE_EFFECT_TARGET
  -- Auto-removal on EVENT_ATTACK_ANNOUNCE
  ```

### Usage Pattern
```lua
local s, id = Import()
function s.initial(c)
    -- Card effects implementation
    -- Note: Galaxy rules are applied automatically
    -- No need for manual Galaxy.ApplyRulesToCard calls
end
```

### Configuration
```lua
Galaxy.ENABLED = true
Galaxy.NO_COVER_SUMMON = true
Galaxy.DEFENSE_AS_HP = true
Galaxy.NO_MONSTER_BATTLE_DAMAGE = true
Galaxy.SUMMON_TURN_CANNOT_ATTACK = true
Galaxy.TRAP_OPPONENT_TURN_ONLY = true  -- Trap cards opponent turn only
Galaxy.TRAP_HAND_ACTIVATE = true       -- Trap cards hand activation
Galaxy.USE_COST_SYSTEM = true
Galaxy.MONSTER_SUMMON_COST = true
Galaxy.SPELL_TRAP_COST = false  -- Temporarily disabled
Galaxy.SPECIAL_SUMMON_ONLY = true
Galaxy.PROTECTION_SYSTEM = true         -- Protection effect system
Galaxy.PROTECT_ATTACK_PRIORITY = true   -- Force attack protected units first
```

## Common Templates

### Monster Summon Cost
```lua
function c12345678.spsummon_condition(e,c)
    if c==nil then return true end
    local tp=c:GetControler()
    return Duel.CheckSupplyCost(tp, c:GetLevel())
end

function c12345678.spsummon_cost(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return Duel.CheckSupplyCost(tp, c:GetLevel()) end
    Duel.PaySupplyCost(tp, c:GetLevel())
end
```

### Effect Activation Cost
```lua
function c12345678.activate_cost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.CheckSupplyCost(tp, 2) end
    Duel.PaySupplyCost(tp, 2)
end
```

### Supply Manipulation
```lua
-- Temporary supply boost
Duel.AddSupply(tp, 3)  -- Can exceed max

-- Permanent max increase
Duel.AddMaxSupply(tp, 1)
```

### Protection Effect Implementation
```lua
local s, id = Import()
function s.initial(c)
    -- Add protection effect
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_PROTECT) -- Mark as protection unit (code 501)
    c:RegisterEffect(e1)

    -- Add rush effect (optional - allows attack in deployment turn)
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_RUSH) -- Mark as rush unit (code 500)
    c:RegisterEffect(e2)

    -- Other card effects...
end
```

## Galaxy Function Aliases

Galaxy provides semantic aliases for YGO Lua functions to better match the game rules and improve code readability.

### Card HP System (Defense → HP)
```lua
card:GetMaxHp()
-- Original YGO functions → Galaxy aliases
card:GetDefense()       → card:GetHp()          -- Current HP
card:GetBaseDefense()   → card:GetBaseHp()       -- Base HP
card:SetDefense(val)    → card:SetHp(val)       -- Set HP
card:IsDefense(val)     → card:IsHp(val)        -- Check HP
card:GetTextDefense() → card:GetOriginalHp() -- Original max HP
```

### Card Supply Cost System (Level → Cost)
```lua
-- Original YGO functions → Galaxy aliases
card:GetLevel()         → card:GetSupplyCost()     -- Summon cost
card:IsLevel(val)       → card:IsSupplyCost(val)   -- Check cost
card:IsLevelAbove(val)  → card:IsSupplyCostAbove(val) -- Cost range
card:IsLevelBelow(val)  → card:IsSupplyCostBelow(val) -- Cost range
```

### Galaxy Semantic Functions
```lua
-- Semantic card checks (aliases for original functions)
card:IsGalaxyProperty(property)     -- Check property (原IsAttribute)
card:IsGalaxyCategory(category)     -- Check category (原IsRace)
```

### Usage Examples
```lua
function c12345678.cost(e,tp,eg,ep,ev,re,r,rp,chk)
    local c = e:GetHandler()
    if chk==0 then
        -- Using Galaxy aliases for better readability
        return Galaxy.CheckCost(tp, c:GetSupplyCost()) and
               Duel.GetTurnPlayer() ~= tp
    end
    Galaxy.PayCost(tp, c:GetSupplyCost())
end

function c12345678.condition(e,tp,eg,ep,ev,re,r,rp)
    local c = e:GetHandler()
    -- Check card properties using Galaxy terminology
    return c:IsGalaxyCategory(GALAXY_CATEGORY_HUMAN) and
           c:IsGalaxyProperty(GALAXY_PROPERTY_LEGION)
end
```

## Galaxy Terminology Mapping

Galaxy provides semantic constants and functions using GCG (Galaxy Card Game) terminology to improve code readability and match the game's theme.

### Constants Mapping

#### Phase Constants
```lua
-- Original YGO phases → Galaxy terminology
GALAXY_PHASE_SUPPLY = PHASE_DRAW        -- 补给阶段(抽卡阶段)
GALAXY_PHASE_PREPARATION = PHASE_STANDBY -- 战备阶段(准备阶段)
GALAXY_PHASE_DEPLOY = PHASE_MAIN1        -- 部署阶段(主要阶段1)
GALAXY_PHASE_COMBAT = PHASE_BATTLE       -- 交战阶段(战斗阶段)
GALAXY_PHASE_ORGANIZE = PHASE_MAIN2      -- 整备阶段(主要阶段2)
GALAXY_PHASE_REST = PHASE_END            -- 休整阶段(结束阶段)
```

#### Location Constants
```lua
-- Original YGO locations → Galaxy terminology
GALAXY_LOCATION_BASIC_DECK = LOCATION_DECK     -- 基本卡组(主卡组)
GALAXY_LOCATION_UNIT_ZONE = LOCATION_MZONE     -- 单位区(怪兽区)
GALAXY_LOCATION_SUPPORT_ZONE = LOCATION_SZONE  -- 支援区(魔陷区)
GALAXY_LOCATION_DISCARD = LOCATION_GRAVE       -- 弃牌区(墓地)
GALAXY_LOCATION_EXILED = LOCATION_REMOVED      -- 游戏外(除外区)
GALAXY_LOCATION_SPECIAL_DECK = LOCATION_EXTRA  -- 特殊卡组(额外卡组)
```

#### Type Constants
```lua
-- Original YGO types → Galaxy terminology
GALAXY_TYPE_UNIT = TYPE_MONSTER      -- 单位(怪兽)
GALAXY_TYPE_SUPPORT = TYPE_SPELL     -- 支援(魔法)
GALAXY_TYPE_TACTICS = TYPE_TRAP      -- 战术(陷阱)
GALAXY_TYPE_FORCES = TYPE_EFFECT     -- 部队(效果)
GALAXY_TYPE_LARGE = TYPE_FUSION      -- 大型(融合)
GALAXY_TYPE_FACILITY = TYPE_CONTINUOUS -- 设施(永续)
GALAXY_TYPE_AREA = TYPE_FIELD        -- 区域(场地)
GALAXY_TYPE_ENHANCEMENT = TYPE_EQUIP -- 强化(装备)
```

#### Property (Attribute) Constants
```lua
-- Original YGO attributes → Galaxy terminology
GALAXY_PROPERTY_LEGION = ATTRIBUTE_EARTH    -- 军团(地)
GALAXY_PROPERTY_FLEET = ATTRIBUTE_WATER     -- 舰队(水)
GALAXY_PROPERTY_STATION = ATTRIBUTE_FIRE    -- 空间站(炎)
GALAXY_PROPERTY_STARPORT = ATTRIBUTE_WIND   -- 星港(风)
GALAXY_PROPERTY_COMMANDER = ATTRIBUTE_LIGHT -- 指挥官(光)
```

#### Category (Race) Constants
```lua
-- Original YGO races → Galaxy terminology (only mapped terms from glossary)
GALAXY_CATEGORY_HUMAN = RACE_WARRIOR        -- 人类(战士)
GALAXY_CATEGORY_MAMMAL = RACE_BEAST         -- 哺乳类(兽)
GALAXY_CATEGORY_REPTILE = RACE_DINOSAUR     -- 爬行类(恐龙)
GALAXY_CATEGORY_AVIAN = RACE_WINDBEAST      -- 鸟类(鸟兽)
GALAXY_CATEGORY_ARTHROPOD = RACE_INSECT     -- 节肢类(昆虫)
GALAXY_CATEGORY_MOLLUSK = RACE_SEASERPENT   -- 软体类(海龙)
GALAXY_CATEGORY_FUNGAL = RACE_REPTILE       -- 真菌类(爬虫类)
GALAXY_CATEGORY_UNDEAD = RACE_ZOMBIE        -- 死灵(不死)
GALAXY_CATEGORY_AURORA = RACE_THUNDER       -- 极光(雷)
```

### Semantic Functions

#### Card Checks
```lua
-- Property and Category checks (Galaxy terminology aliases)
card:IsGalaxyProperty(prop)   -- 检查特性 (原IsAttribute)
card:IsGalaxyCategory(cat)    -- 检查类别 (原IsRace)
```

### Usage Examples
```lua
function c12345678.condition(e,tp,eg,ep,ev,re,r,rp)
    local c = e:GetHandler()
    -- Using GCG terminology for better game immersion
    return c:IsType(TYPE_TRAP) and c:IsLocation(LOCATION_GRAVE) and
           Duel.GetCurrentPhase() == PHASE_MAIN1
end

function c12345678.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(GALAXY_LOCATION_UNIT_ZONE) and
                        chkc:IsType(GALAXY_TYPE_UNIT) end
    if chk==0 then return Duel.IsExistingTarget(Card.IsType,tp,
                                               GALAXY_LOCATION_UNIT_ZONE,
                                               GALAXY_LOCATION_UNIT_ZONE,1,nil,TYPE_MONSTER) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
    Duel.SelectTarget(tp,Card.IsType,tp,
                     GALAXY_LOCATION_UNIT_ZONE,
                     GALAXY_LOCATION_UNIT_ZONE,1,1,nil,TYPE_MONSTER)
end
```

## Galaxy HP Event System

### Overview
The Galaxy HP Event System provides a standardized way to monitor and respond to HP changes in Galaxy Card Game monsters. This system enables cards to react to damage, healing, and effect applications/removals.

### Event Types

#### GALAXY_EVENT_HP_DAMAGE
- **Trigger**: When a monster receives immediate damage (AddHp with negative value)
- **Use Case**: Monitor damage from spells, battle, or abilities
- **Blocked by**: Shield effects
- **Event Code**: `EVENT_CUSTOM + 99000001`

#### GALAXY_EVENT_HP_RECOVER
- **Trigger**: When a monster immediately recovers HP (AddHp with positive value)
- **Use Case**: Monitor healing effects
- **Blocked by**: Nothing (healing always works)
- **Event Code**: `EVENT_CUSTOM + 99000002`

#### GALAXY_EVENT_HP_EFFECT_CHANGE
- **Trigger**: When HP effects are applied or removed (EFFECT_UPDATE_HP changes)
- **Use Case**: Monitor equipment, buffs, debuffs
- **Blocked by**: Nothing (effects bypass shields)
- **Event Code**: `EVENT_CUSTOM + 99000003`

### Implementation Pattern

```lua
-- Monitor damage to opponent monsters
local e1 = Effect.CreateEffect(c)
e1:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
e1:SetCode(GALAXY_EVENT_HP_DAMAGE)
e1:SetRange(LOCATION_MZONE)
e1:SetCondition(function(e, tp, eg, ep, ev, re, r, rp)
    return eg:IsExists(Card.IsControler, 1, nil, 1-tp)
end)
e1:SetOperation(function(e, tp, eg, ep, ev, re, r, rp)
    -- React to opponent taking damage
    Duel.AddSupply(tp, 1)
end)
c:RegisterEffect(e1)
```

### Event Parameters
- **eg**: Group of monsters that experienced HP changes
- **ep**: Event player (usually same as rp)
- **ev**: Absolute value of HP change (always positive)
- **re**: Source effect (may be nil)
- **r**: Reason type (REASON_BATTLE or REASON_EFFECT)
- **rp**: Responsible player

### Key Distinctions

#### AddHp vs EFFECT_UPDATE_HP
- **AddHp Events** (`DAMAGE`/`RECOVER`): Immediate, permanent changes
  - Cannot be dispelled
  - Can be blocked by shields (damage only)
  - Trigger immediately when HP actually changes

- **Effect Events** (`EFFECT_CHANGE`): Continuous effect modifications
  - Can be dispelled/removed
  - Not blocked by shields
  - Trigger when buffs/debuffs are applied or removed

#### Shield Interaction
- Shield effects only block `GALAXY_EVENT_HP_DAMAGE` events
- When damage is blocked by shield, no damage event is triggered
- Shields do not affect `GALAXY_EVENT_HP_EFFECT_CHANGE` events
- Healing (`GALAXY_EVENT_HP_RECOVER`) is never blocked

### Usage Examples

#### Damage Counter
```lua
-- Count damage taken by your monsters
local e1 = Effect.CreateEffect(c)
e1:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_F)
e1:SetCode(GALAXY_EVENT_HP_DAMAGE)
e1:SetRange(LOCATION_MZONE)
e1:SetCondition(function(e, tp, eg, ep, ev, re, r, rp)
    return eg:IsExists(Card.IsControler, 1, nil, tp)
end)
e1:SetOperation(function(e, tp, eg, ep, ev, re, r, rp)
    e:GetHandler():AddCounter(0x1, ev)  -- Add damage counters
end)
c:RegisterEffect(e1)
```

#### Healing Amplifier
```lua
-- Double healing effects on your monsters
local e2 = Effect.CreateEffect(c)
e2:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
e2:SetCode(GALAXY_EVENT_HP_RECOVER)
e2:SetRange(LOCATION_MZONE)
e2:SetCondition(function(e, tp, eg, ep, ev, re, r, rp)
    return eg:IsExists(Card.IsControler, 1, nil, tp) and r & REASON_EFFECT > 0
end)
e2:SetOperation(function(e, tp, eg, ep, ev, re, r, rp)
    for tc in aux.Next(eg:Filter(Card.IsControler, nil, tp)) do
        Duel.AddHp(tc, ev, REASON_EFFECT)  -- Additional healing
    end
end)
c:RegisterEffect(e2)
```

#### Buff/Debuff Monitor
```lua
-- React to equipment/aura changes
local e3 = Effect.CreateEffect(c)
e3:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
e3:SetCode(GALAXY_EVENT_HP_EFFECT_CHANGE)
e3:SetRange(LOCATION_MZONE)
e3:SetOperation(function(e, tp, eg, ep, ev, re, r, rp)
    if ev > 0 then
        -- Gained HP effect - draw card
        Duel.Draw(tp, 1, REASON_EFFECT)
    else
        -- Lost HP effect - gain supply
        Duel.AddSupply(tp, 1)
    end
end)
c:RegisterEffect(e3)
```

### Technical Implementation
The HP event system is integrated into the core Galaxy HP calculation functions:
- `Galaxy.CalculateAddHpImmediately()`: Triggers AddHp events
- `Galaxy.CalculateHp()`: Triggers EFFECT_UPDATE_HP events
- Events are raised immediately when HP changes occur
- Unified event function: `Galaxy.RaiseHpEvent(card, change, is_effect, reason, player)`

## System Status
- **Completion**: 100% - All core features implemented and tested
- **HP Event System**: ✅ Fully integrated with comprehensive event monitoring
- **Stability**: Production ready, no known crashes
- **Compatibility**: Fully backward compatible
- **Performance**: More efficient than LP system, optimized event handling
- **Network**: Full multiplayer/replay support

## Key Reference Cards
- `c7852878`: EVENT_DAMAGE_STEP_END + TRIGGER_F pattern
- `c36553319`: EFFECT_SELF_DESTROY best practice
- `c7171149`: Summon turn attack restriction
- `c4408198`: Opponent turn only condition pattern (`Duel.GetTurnPlayer()~=tp`)
- `c10000034`, `c10000035`: Trap hand activation examples (now using global rules)