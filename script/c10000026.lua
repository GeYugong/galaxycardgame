local s,id,o=GetID()
function s.initial_effect(c)
	if Galaxy and Galaxy.ApplyRulesToCard then
        Galaxy.ApplyRulesToCard(c)
    end
    --魔法卡，把1只水属性的，融合怪兽从额外卡组特殊召唤。支付那只怪兽等级的（补给）作为代价，如果补给不足，则送到墓地。
    local e1=Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
end

function s.filter(c,e,tp)
    return c:IsType(TYPE_FUSION) and c:IsAttribute(ATTRIBUTE_WATER)
        and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
        and Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_EXTRA,0,1,nil,e,tp) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,s.filter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp)
    local tc=g:GetFirst()
    if not tc then return end

    local cost=tc:GetLevel()
    --直接特殊召唤，不按融合处理
    if Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP_ATTACK)~=0 then
        --召唤成功后，检查并支付补给代价
        if Duel.CheckSupplyCost(tp,cost) then
            --补给足够，支付代价
            Duel.PaySupplyCost(tp,cost)
        else
            --补给不足，将怪兽送往墓地
            Duel.SendtoGrave(tc,REASON_EFFECT)
        end
    end
end
