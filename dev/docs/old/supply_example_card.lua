--Galaxy Energy Warrior (银河能量战士)
--测试卡片 - 演示补给系统的使用
local s,id=GetID()
function s.initial_effect(c)
	--召唤时检查补给
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetTarget(s.sumtg)
	e1:SetOperation(s.sumop)
	c:RegisterEffect(e1)

	--激活效果需要消耗补给
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1)
	e2:SetCost(s.descost)
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)
end

--召唤时检查补给
function s.sumtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	local supply = Duel.GetSupply(tp)
	local max_supply = Duel.GetMaxSupply(tp)
	Duel.Hint(HINT_MESSAGE,tp,aux.Stringid(id,1)) -- "当前补给: " .. supply .. "/" .. max_supply
end

function s.sumop(e,tp,eg,ep,ev,re,r,rp)
	local supply = Duel.GetSupply(tp)
	if supply >= 3 then
		--如果补给充足，获得额外效果
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(500)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		e:GetHandler():RegisterEffect(e1)
		Duel.Hint(HINT_MESSAGE,tp,aux.Stringid(id,2)) -- "补给充足！攻击力+500"
	end
end

--破坏效果的费用：消耗2点补给
function s.descost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetSupply(tp)>=2 end
	Duel.SpendSupply(tp,2)
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() and chkc:IsDestructable() end
	if chk==0 then return Duel.IsExistingTarget(Card.IsDestructable,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,Card.IsDestructable,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) then
		Duel.Destroy(tc,REASON_EFFECT)
		Duel.Hint(HINT_MESSAGE,tp,aux.Stringid(id,3)) -- "消耗2点补给破坏卡片"
	end
end