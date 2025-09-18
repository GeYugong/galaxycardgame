--太阳系先锋
local s, id = Import()
function s.initial(c)
end
--[[
function s.initial_effect(c)
	if Galaxy and Galaxy.ApplyRulesToCard then
		--临时禁用召唤回合不能攻击限制
		local old_setting = Galaxy.SUMMON_TURN_CANNOT_ATTACK
		Galaxy.SUMMON_TURN_CANNOT_ATTACK = false
		Galaxy.ApplyRulesToCard(c)
		--恢复全局设置
		Galaxy.SUMMON_TURN_CANNOT_ATTACK = old_setting
	end
	--这个怪兽在特殊召唤的回合就可以直接发动攻击
end
--]]