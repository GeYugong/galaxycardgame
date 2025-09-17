local s,id,o=GetID()
function s.initial_effect(c)
    --这张卡可以向对方全部怪兽各做一次攻击。
	--这张卡在自己补给8以上时才可以特殊召唤
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_ATTACK_ALL)
	e1:SetValue(1)
	c:RegisterEffect(e1)

	--设置额外特殊召唤条件
	if Galaxy and Galaxy.SetExtraSpCondition then
		Galaxy.SetExtraSpCondition(id, s.sp_extra_condition)
	end

	--应用Galaxy规则
	if Galaxy and Galaxy.ApplyRulesToCard then
        Galaxy.ApplyRulesToCard(c)
    end
end
function s.sp_extra_condition(e,c,tp)
	--额外条件：补给必须≥8
	return Duel.GetSupply(tp) >= 8
end
