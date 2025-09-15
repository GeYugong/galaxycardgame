local s,id,o=GetID()
function s.initial_effect(c)
	if Galaxy and Galaxy.ApplyRulesToCard then
        Galaxy.ApplyRulesToCard(c)
    end
    --Activate
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    c:RegisterEffect(e1)
    --永续魔法卡，1回合1次，自己准备阶段开始时必发，回复2lp
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetCategory(CATEGORY_RECOVER)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e2:SetRange(LOCATION_SZONE)
    e2:SetCode(EVENT_PHASE+PHASE_DRAW)
    e2:SetCountLimit(1)
    e2:SetCondition(s.reccon)
    e2:SetOperation(s.recop)
    c:RegisterEffect(e2)
end

function s.reccon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.GetTurnPlayer()==tp
end

function s.recop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Recover(tp,2,REASON_EFFECT)
end
