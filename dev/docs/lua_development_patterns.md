# YGOPro Lua Development Patterns

## Core Development Principles

### 1. Always Reference Original Cards
- Must ask user for related original card IDs before implementation
- Study complete implementation in `ai/examples/script/c[cardid].lua`
- Copy and modify original patterns, never create from scratch

### 2. Strict API Compliance
- Every effect code has precise purpose and timing
- Never guess API usage - follow documentation and original implementations
- Avoid combining unverified effect codes

### 3. Correct Effect Types and Timing
```lua
-- ❌ Wrong: Using CONTINUOUS for trigger effects
SetType(EFFECT_TYPE_CONTINUOUS)

-- ✅ Correct: Reference original using TRIGGER_F
SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
SetCode(EVENT_DAMAGE_STEP_END)
SetCondition(aux.dsercon)
```

## Key Reference Cards
- `c7852878`: EVENT_DAMAGE_STEP_END + TRIGGER_F standard pattern
- `c36553319`: EFFECT_SELF_DESTROY auto-destroy best practice
- `c62892347`: EFFECT_CANNOT_CHANGE_POSITION position control
- `c7171149`: Summon turn attack restriction complete implementation
- `c36088082`: Conditional battle effect timing handling

## Core Technical Patterns

### Defense-as-HP System (Optimal Solution)
```lua
EVENT_DAMAGE_STEP_END + EFFECT_TYPE_TRIGGER_F + aux.dsercon
EFFECT_UPDATE_DEFENSE + negative values
EFFECT_SELF_DESTROY + condition function
```

### Conditional Continuous Effects
```lua
EFFECT_TYPE_SINGLE + SetCondition(condition_function)
-- For effects that need dynamic condition checking
```

### Multi-timing Unified Processing
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

## Development Resources
- API documentation: `ai/luatips/tips.json`
- Code snippets: `ai/luatips/snippets.json`
- Reference examples: `ai/examples/script/`
- Galaxy rules: `script/utility.lua`