-- 补给系统测试脚本
-- 这个脚本用于测试Galaxy Card Game的补给系统功能

-- 测试1: 基本的补给获取和设置
function test_basic_supply()
    print("=== 测试基本补给功能 ===")

    -- 获取玩家0的当前补给
    local current_supply = Duel.GetSupply(0)
    local max_supply = Duel.GetMaxSupply(0)
    print("玩家0当前补给: " .. current_supply .. "/" .. max_supply)

    -- 设置补给为3/5
    Duel.SetSupply(0, 3, 5)
    print("设置玩家0补给为3/5")

    -- 验证设置是否成功
    current_supply = Duel.GetSupply(0)
    max_supply = Duel.GetMaxSupply(0)
    print("设置后玩家0补给: " .. current_supply .. "/" .. max_supply)
end

-- 测试2: 补给增加和消耗
function test_supply_operations()
    print("=== 测试补给操作 ===")

    -- 初始化补给
    Duel.SetSupply(0, 5, 8)
    print("初始化玩家0补给为5/8")

    -- 增加2点补给
    Duel.AddSupply(0, 2)
    local current = Duel.GetSupply(0)
    print("增加2点后补给: " .. current .. "/8")

    -- 消耗3点补给
    Duel.SpendSupply(0, 3)
    current = Duel.GetSupply(0)
    print("消耗3点后补给: " .. current .. "/8")
end

-- 测试3: 边界条件
function test_boundary_conditions()
    print("=== 测试边界条件 ===")

    -- 测试超出最大值
    Duel.SetSupply(0, 15, 20) -- 应该被限制为10
    local max_supply = Duel.GetMaxSupply(0)
    print("设置20最大补给，实际: " .. max_supply)

    -- 测试负数
    Duel.SetSupply(0, -5, 5) -- 当前补给应该为0
    local current = Duel.GetSupply(0)
    print("设置-5当前补给，实际: " .. current)

    -- 测试消耗超过当前值
    Duel.SetSupply(0, 3, 5)
    Duel.SpendSupply(0, 10) -- 应该变为0
    current = Duel.GetSupply(0)
    print("消耗10点补给（只有3点），实际: " .. current)
end

-- 运行所有测试
function run_all_tests()
    print("开始补给系统测试...")
    test_basic_supply()
    test_supply_operations()
    test_boundary_conditions()
    print("测试完成！")
end

-- 如果脚本被直接执行，运行测试
if Duel then
    run_all_tests()
else
    print("此脚本需要在YGOPro/Galaxy Card Game环境中运行")
end