-- 基础补给系统测试脚本
-- 简单测试 - 只进行最基本的功能验证

function basic_supply_test()
    print("=== 基础补给测试开始 ===")

    -- 测试获取补给（应该返回初始值1）
    if Duel then
        local supply = Duel.GetSupply(0)
        print("玩家0当前补给: " .. tostring(supply))

        local max_supply = Duel.GetMaxSupply(0)
        print("玩家0最大补给: " .. tostring(max_supply))

        -- 简单设置测试
        Duel.SetSupply(0, 2, 3)
        print("设置补给为2/3")

        local new_supply = Duel.GetSupply(0)
        local new_max = Duel.GetMaxSupply(0)
        print("设置后补给: " .. tostring(new_supply) .. "/" .. tostring(new_max))

        print("基础测试完成")
    else
        print("Duel对象不可用，请在游戏环境中运行")
    end
end

-- 如果在游戏环境中运行测试
basic_supply_test()