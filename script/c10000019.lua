local s,id,o=GetID()
function s.initial_effect(c)
	if Galaxy and Galaxy.ApplyRulesToCard then
        Galaxy.ApplyRulesToCard(c)
    end
    --标记为嘲讽怪兽
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE)
    e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e0:SetCode(EFFECT_FLAG_EFFECT+99999999) --通用嘲讽标记
    c:RegisterEffect(e0)

    --对方怪兽不能选择其他怪兽作为攻击对象
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetRange(LOCATION_MZONE)
    e1:SetTargetRange(0,LOCATION_MZONE)
    e1:SetCode(EFFECT_CANNOT_SELECT_BATTLE_TARGET)
    e1:SetValue(s.atlimit)
    c:RegisterEffect(e1)
end

function s.atlimit(e,c)
    --如果目标是嘲讽怪兽，可以攻击
    if s.istaunt(c) then
        return false
    end
    --如果目标不是嘲讽怪兽，且场上有嘲讽怪兽，则不能攻击
    local tp=e:GetHandlerPlayer()
    return Duel.IsExistingMatchingCard(s.istaunt,tp,LOCATION_MZONE,0,1,nil)
end

function s.istaunt(c)
    --检查是否为嘲讽怪兽（有嘲讽标记的怪兽）
    return c:IsFaceup() and c:IsHasEffect(EFFECT_FLAG_EFFECT+99999999)
end

