--铁锤团
local s, id = Import()
function s.initial(c)
	--这张卡可以向对方全部怪兽各做一次攻击。
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_ATTACK_ALL)
	e1:SetValue(1)
	c:RegisterEffect(e1)
	--这张卡在自己补给8以上时才可以特殊召唤
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_SPSUMMON_CONDITION)
	e1:SetValue(s.splimit)
	c:RegisterEffect(e1)
end
--额外条件：补给必须≥8
function s.splimit(e,se,sp,st)
	return Duel.GetSupply(e:GetHandlerPlayer()) >= 8
end
