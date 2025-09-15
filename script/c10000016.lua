local s,id,o=GetID()
function s.initial_effect(c)
	if Galaxy and Galaxy.ApplyRulesToCard then
        Galaxy.ApplyRulesToCard(c)
    end
    --这个怪兽可以直接攻击对方玩家
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_DIRECT_ATTACK)
    c:RegisterEffect(e1)
end
