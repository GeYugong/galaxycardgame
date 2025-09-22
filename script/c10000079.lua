--免疫1次战斗伤害，该效果失去后，获得嘲讽。
local s, id = Import()
function s.initial(c)
    --免疫1次战斗伤害（护盾效果）
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_SHIELD)
	c:RegisterEffect(e1)
	Galaxy.AddShieldDisplay(c)
	--护盾失去后获得保护效果的监控
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EVENT_PROTECT)
	e2:SetRange(GALAXY_LOCATION_UNIT_ZONE)
	e2:SetCondition(s.protectcon)
	c:RegisterEffect(e2)
end

--检查是否应该获得保护效果
function s.protectcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsHasEffect(EFFECT_SHIELD) and not c:IsHasEffect(EFFECT_PROTECT) then
		if c:IsFaceup() and c:IsRelateToEffect(e) then
			--显示保护效果提示
			local e2=Effect.CreateEffect(c)
			e2:SetDescription(aux.Stringid(id,0))
			e2:SetType(EFFECT_TYPE_SINGLE)
			e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CLIENT_HINT)
			e2:SetRange(GALAXY_LOCATION_UNIT_ZONE)
			e2:SetReset(RESET_EVENT+RESETS_STANDARD)
			c:RegisterEffect(e2)
		end
		return true
	else
		return false
	end
end