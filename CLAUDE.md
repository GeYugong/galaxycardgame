# CLAUDE.md

为协助智能体在本仓库中高效、安全地开发，这份指南总结了 Galaxy Card Game（GCG）的核心信息、工作流程与注意事项。请务必先阅读再开展工作。

## 1. 项目速览
- 本仓库改造自 YGOPro，引擎使用 C++/Irrlicht，卡片效果通过 Lua 实现。
- 游戏规则已全面换装为 Galaxy 机制（补给=费用、HP=守备力等）。
- 主要关注点：`script/` 目录下的卡片脚本与 `dev/docs/` 中的开发文档。

## 2. 工作准则（务必遵守）
1. **不要尝试自行编译或启动客户端**：构建流程复杂，统一由用户负责。
2. **优先查阅官方示例**：修改脚本前参考 `dev/examples/script/` 和已存在的 `script/c[ID].lua`。
3. **引用最新文档**：所有 Galaxy 规则资料整合在 `dev/docs/gcg_lua_guide.md`。
4. **保持命名一致**：代码和描述统一使用 Galaxy 术语与常量（`GALAXY_LOCATION_*`、`GALAXY_EVENT_*` 等）。
5. **操作谨慎**：避免改动与需求无关的资源；发现仓库已有脏改动时先与用户确认处理方式。

## 3. 常见任务：编写 / 修改 Lua 卡片脚本
按照下列步骤执行，可大幅降低出错率：

1. **理解需求**：收集卡片类型、补给成本、关键词效果、触发时点、目标等要素。
2. **寻找模板**：
   - 入口写法固定为 `local s,id = Import()` + `function s.initial(c)`。
   - 使用最新指南中的示例片段（章节 5.1～5.4）。
3. **实现效果**：
   - 费用一律用 `Duel.CheckSupplyCost` / `Duel.PaySupplyCost`。
   - HP 变化用 `Duel.AddHp`，满血增益改写为 `EFFECT_UPDATE_DEFENSE`。
   - Trap/战术卡的发动限制由系统全局处理，无需重复实现。
4. **条件与校验**：激活前先 `Duel.IsExistingMatchingCard` 或 `Duel.IsExistingTarget` 检查目标；缺少目标时拒绝发动。
5. **事件监听**：需要响应生命变化时使用 `GALAXY_EVENT_HP_DAMAGE` / `RECOVER` / `EFFECT_CHANGE`，注意 `eg`、`ev` 的含义。
6. **数据库查询**：
   - 仅允许单条 `SELECT` 语句，禁止包含 `;`、`INSERT`、`UPDATE` 等关键字。
   - 返回值需检查 `results` 是否为 `nil` 或存在 `results.error`。
7. **自测方法**：在回答中描述如何在游戏内验证（如召唤 / 触发路径、补给扣除、护盾交互等），用户据此执行实测。

## 4. Galaxy 关键机制速查
- **补给系统**：回合开始补给全满并 +1 上限；费用 = 卡等级，可通过 `EFFECT_FREE_DEPLOY` 免除。
- **HP 系统**：守备即 HP，战斗改为互相扣 HP；护盾 `EFFECT_SHIELD` 抵挡一次伤害，隐身 `EFFECT_STEALTH` 被打/发动后自动移除。
- **关键词效果码**：`EFFECT_RUSH`（速攻）、`EFFECT_PROTECT`（嘲讽）、`EFFECT_STEALTH`（隐身）、`EFFECT_LETHAL`（致命）等，具体列表见 `script/constant.lua`。
- **全局规则**：
  - 所有单位自动注册召唤限制、护盾/隐身提示、战斗伤害改写等；无需重复编码。
  - 战术卡强制对方回合、可手牌发动；单位召唤回合默认不能攻击。

## 5. 参考资料
- **Galaxy Lua 指南**：`dev/docs/gcg_lua_guide.md`（唯一权威文档，已涵盖流程、示例、常量说明）。
- **术语表**：`dev/docs/gcg_Glossary.md`。
- **API 速查**：`dev/luatips/tips.json`；常用片段在 `dev/luatips/snippets.json`。
- **完整常量定义**：`script/constant.lua`。
- **实战样例**：`script/` 与 `dev/examples/script/`。

## 6. 构建与平台（仅供参考）
- 主构建系统为 Premake5，备用 CMake；具体参数见 `premake5.lua`。
- Windows 默认编译所有依赖；Linux/macOS 更依赖系统包。
- 如需为用户提供构建建议，仅提醒其使用 `premake5` 或 `cmake`，不要在自动化流程中尝试执行。

---

如对规则或接口有疑问，优先查阅《GCG Lua 开发指南》；若仍不确定，请在回复中提出并等待用户确认，再做后续修改。
