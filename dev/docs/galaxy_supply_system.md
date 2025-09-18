# Galaxy Supply System Quick Reference

## API Overview

### Core Lua APIs (libduel.cpp)
```lua
-- Basic Operations
Duel.GetSupply(player)              -- Get current supply
Duel.GetMaxSupply(player)           -- Get max supply
Duel.SetSupply(player, current, max) -- Set supply values
Duel.AddSupply(player, amount)      -- Add supply (can exceed max)
Duel.SpendSupply(player, amount)    -- Spend supply
Duel.AddMaxSupply(player, amount)   -- Increase max supply
Duel.ClampSupply(player)            -- Clamp to max limit

-- Cost System (replaces LP system)
Duel.CheckSupplyCost(player, cost)  -- Check if enough supply
Duel.PaySupplyCost(player, cost)    -- Pay supply cost
```

### Galaxy Simplified APIs (script/utility.lua)
```lua
Galaxy.CheckCost(tp, cost)  -- Calls Duel.CheckSupplyCost
Galaxy.PayCost(tp, cost)    -- Calls Duel.PaySupplyCost
```

## Cost Check Pattern (chk parameter)
```lua
function card_cost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        -- chk==0: Check phase - verify conditions only, no resource consumption
        return Galaxy.CheckCost(tp, 3)
    end
    -- chk!=0: Execute phase - actually pay the cost
    Galaxy.PayCost(tp, 3)
end
```

## Common Templates

### Monster Summon Cost
```lua
function c12345678.spsummon_condition(e,c)
    if c==nil then return true end
    local tp=c:GetControler()
    return Galaxy.CheckCost(tp, c:GetLevel()) -- Level as cost
end

function c12345678.spsummon_cost(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return Galaxy.CheckCost(tp, c:GetLevel()) end
    Galaxy.PayCost(tp, c:GetLevel())
end
```

### Effect Activation Cost
```lua
function c12345678.activate_cost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Galaxy.CheckCost(tp, 2) end
    Galaxy.PayCost(tp, 2)
end
```

## Key Reference Cards
- `c7852878`: EVENT_DAMAGE_STEP_END + TRIGGER_F pattern
- `c36553319`: EFFECT_SELF_DESTROY best practice
- `c7171149`: Summon turn attack restriction

## Game Mechanics
- **Start**: 0/0 supply
- **Each turn**: +1 max supply at draw phase start (max 10)
- **Recovery**: Full restore at draw phase start
- **Temporary exceed**: Cards can grant supply above max, auto-clamp next turn

## Development Resources
- Full docs: `ai/docs/Galaxy_Supply_System_Complete.md`
- API reference: `ai/luatips/tips.json`
- Code snippets: `ai/luatips/snippets.json`
- Examples: `ai/examples/script/`