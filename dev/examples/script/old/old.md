## GCG - Galaxy Card Game

基于YGOPro引擎的银河卡牌游戏，包含独特的游戏机制和自定义API系统。

## 核心特性

### 🌌 Galaxy系统 (与YGOPro的核心差异)

**卡片分类系统**
- **Galaxy Category**: 替代原始种族系统，包含舰队、哺乳类、真菌类、死灵、极光等9种类别
- **Galaxy Type**: 扩展卡片类型，包含单位、建筑、法术等Galaxy专用类型
- **Galaxy Property**: 自定义属性系统，如舰队属性等

**游戏机制创新**
- **补给系统**: 用怪兽等级表示补给消耗，取代传统召唤机制
- **生命值系统**: 使用防御力作为单位生命值，生命值=防御力
- **护盾机制**: `EFFECT_SHIELD` - 免疫一次战斗伤害的独特防护系统
- **冲锋效果**: `EFFECT_RUSH` - Galaxy专属的战斗增强机制

### 🛡️ 安全数据库API

**Duel.QueryDatabase(sql)**
- **只读访问**: 严格限制为SELECT查询，防止数据修改
- **动态卡片生成**: 支持基于数据库查询的随机卡片选择
- **安全防护**: 多层安全检查，阻止SQL注入和恶意操作
- **随机性支持**: 内置SQLite PRNG，支持`ORDER BY RANDOM()`

### 🎮 游戏规则差异

| 机制 | YGOPro原版 | GCG Galaxy版本 |
|------|-----------|----------------|
| 召唤消耗 | 等级/阶级 | 补给系统 (怪兽等级) |
| 种族系统 | RACE_* | GALAXY_CATEGORY_* |
| 属性系统 | ATTRIBUTE_* | GALAXY_PROPERTY_* |
| 生命值 | 攻击力/守备力 | 防御力=生命值 |
| 军团单位 | 无 | 攻击力=防御力且地属性 |
| 护盾机制 | 无 | EFFECT_SHIELD免伤系统 |
| 冲锋机制 | 无 | EFFECT_RUSH战斗强化 |

### 🔧 技术创新

**Lua脚本系统**
- **GCG格式**: `local s, id = Import()` + `function s.initial(c)`
- **兼容性**: 保持YGOPro核心API，扩展Galaxy专用功能
- **数据库集成**: Lua脚本可直接查询cards.cdb数据库

**盾牌显示管理**
- **统一系统**: `Galaxy.AddShieldDisplay()` / `Galaxy.RemoveShieldDisplay()`
- **视觉反馈**: 自动显示"免疫1次战斗伤害"提示
- **效果同步**: 护盾效果与显示状态实时同步

**开发工具集成**
- **IDE支持**: 完整的tips.json和snippets.json开发辅助
- **代码片段**: 预设Galaxy常用效果模板
- **API文档**: 详细的函数说明和使用示例

## 项目结构

```
├── script/           # Lua卡片脚本 (GCG格式)
├── ocgcore/          # 游戏引擎核心 + 数据库API
├── gframe/           # GUI界面框架
├── dev/
│   ├── docs/         # 开发文档
│   ├── luatips/      # IDE集成工具
│   └── examples/     # 示例脚本
└── cards.cdb         # SQLite卡片数据库
```

## 快速开始

详细的构建和开发指南请参考 [CLAUDE.md](CLAUDE.md)。

---

**GCG (Galaxy Card Game)** - 在保持YGOPro稳定性的基础上，创造了独特的银河系卡牌游戏体验。
