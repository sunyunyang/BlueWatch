# Coros API 集成 - 快速启动指南

## 📌 概述

这是一个**快速验证 Coros API 集成可行性**的方案。不构建完整的后端服务，而是创建一个轻量级的 CLI 工具，用于快速测试和验证。

## 🎯 目标

在 **1-2 周内** 验证以下功能：
- ✅ Coros 用户认证
- ✅ 活动查询和下载
- ✅ 数据格式转换
- ✅ 本地存储
- ✅ 数据导出（JSON、CSV、FIT）

## 📂 文档结构

| 文件 | 说明 |
|------|------|
| `coros-quick-plan.md` | 快速方案概述和核心功能设计 |
| `coros-implementation-guide.md` | 详细的实现指南和代码示例 |
| `coros-test-plan.md` | 完整的测试计划和验证步骤 |
| `setup-coros-cli.sh` | 项目初始化脚本 |

## 🚀 快速开始

### 第一步：初始化项目

```bash
# 进入 BlueWatch 目录
cd /Users/williamsun/Downloads/documents/01_主题验证/BlueWatch

# 运行初始化脚本
bash setup-coros-cli.sh

# 进入项目目录
cd bluewatch-coros-cli
```

### 第二步：配置 Coros 账户

```bash
# 编辑 .env 文件
nano .env

# 填入你的 Coros 账户信息
COROS_EMAIL=your-email@example.com
COROS_PASSWORD=your-password
```

### 第三步：实现核心服务

按照 `coros-implementation-guide.md` 中的代码示例，实现：

1. **src/services/coros.service.ts** - Coros API 包装
2. **src/services/storage.service.ts** - 本地存储
3. **src/services/converter.service.ts** - 数据转换
4. **src/commands/login.ts** - 登录命令
5. **src/commands/sync.ts** - 同步命令
6. **src/commands/export.ts** - 导出命令
7. **src/index.ts** - 主入口

### 第四步：测试功能

```bash
# 测试登录
npm run cli -- login --email your-email@example.com --password your-password

# 测试查询活动
npm run cli -- list

# 测试同步
npm run cli -- sync

# 测试导出
npm run cli -- export --format csv --output ./exports
```

## 📊 项目结构

```
bluewatch-coros-cli/
├── src/
│   ├── index.ts                    # 主入口
│   ├── commands/
│   │   ├── login.ts                # 登录
│   │   ├── sync.ts                 # 同步
│   │   ├── export.ts               # 导出
│   │   └── list.ts                 # 列表
│   ├── services/
│   │   ├── coros.service.ts        # Coros API
│   │   ├── storage.service.ts      # 本地存储
│   │   └── converter.service.ts    # 数据转换
│   ├── models/
│   │   ├── activity.ts
│   │   ├── user.ts
│   │   └── sync-status.ts
│   └── utils/
│       ├── logger.ts
│       └── config.ts
├── data/                           # 本地数据
│   ├── user.json
│   ├── activities.json
│   └── sync-logs.json
├── exports/                        # 导出文件
├── package.json
├── tsconfig.json
└── .env
```

## 🔑 关键功能

### 1. 用户认证

```bash
npm run cli -- login --email user@example.com --password password
```

**输出：**
```
✅ 登录成功
用户信息已保存到 data/user.json
```

### 2. 活动查询

```bash
npm run cli -- list
```

**输出：**
```
┌────────┬────────┬──────────────────┬──────────┬────────┬────────┐
│ ID     │ 类型   │ 开始时间         │ 距离(km) │ 卡路里 │ 心率   │
├────────┼────────┼──────────────────┼──────────┼────────┼────────┤
│ abc123 │ run    │ 2025-02-20 08:00 │ 5.2      │ 450    │ 145    │
│ def456 │ bike   │ 2025-02-19 18:30 │ 15.8     │ 680    │ 135    │
└────────┴────────┴──────────────────┴──────────┴────────┴────────┘
```

### 3. 活动同步

```bash
npm run cli -- sync --fromDate 2025-01-01 --toDate 2025-02-28
```

**输出：**
```
📥 正在查询 Coros 活动...
✅ 找到 42 个活动
📥 正在下载活动详情...
  ✓ 跑步 (2025-02-20)
  ✓ 骑行 (2025-02-19)
  ...
✅ 同步完成
```

### 4. 数据导出

```bash
# 导出为 CSV
npm run cli -- export --format csv --output ./exports

# 导出为 JSON
npm run cli -- export --format json --output ./exports

# 导出为 FIT
npm run cli -- export --format fit --output ./exports
```

## 📈 预期时间表

| 阶段 | 任务 | 预计时间 |
|------|------|---------|
| 1 | 项目初始化和环境配置 | 1 天 |
| 2 | 实现核心服务 | 2-3 天 |
| 3 | 实现 CLI 命令 | 1-2 天 |
| 4 | 基础功能测试 | 1-2 天 |
| 5 | 数据转换和导出测试 | 1-2 天 |
| 6 | 集成测试和优化 | 1-2 天 |
| **总计** | | **1-2 周** |

## ✅ 成功标准

- [ ] 能够成功登录 Coros
- [ ] 能够查询活动列表
- [ ] 能够下载活动详情
- [ ] 能够导出为 CSV 格式
- [ ] 能够导出为 JSON 格式
- [ ] 能够导出为 FIT 格式
- [ ] 错误处理完善
- [ ] 性能可接受（处理 100+ 活动）

## 🐛 常见问题

### Q: 如何获取 Coros 账户？
A: 访问 https://www.coros.com/ 注册账户，然后在 Coros 应用中记录一些活动。

### Q: 如何验证 FIT 文件是否有效？
A: 使用在线工具 https://www.fitfileviewer.com/ 或在 Garmin Connect 中导入。

### Q: 如果 Coros API 变化怎么办？
A: 检查 coros-api 库的最新版本，或查看 GitHub 上的 issue。

### Q: 能否支持其他运动类型？
A: 可以，在 `converter.service.ts` 中添加运动类型映射。

## 📚 参考资源

- [coros-api GitHub](https://github.com/xballoy/coros-api)
- [Coros Training Hub](https://t.coros.com/)
- [FIT 文件格式](https://developer.garmin.com/fit/overview/)
- [Commander.js 文档](https://github.com/tj/commander.js)
- [TypeScript 文档](https://www.typescriptlang.org/)

## 🎓 学习路径

1. **理解 Coros API**
   - 阅读 coros-api 的 README
   - 查看 API 文档（Bruno 格式）
   - 理解认证流程

2. **实现基础功能**
   - 实现登录功能
   - 实现活动查询
   - 实现本地存储

3. **实现高级功能**
   - 实现数据转换
   - 实现导出功能
   - 实现错误处理

4. **测试和优化**
   - 运行测试计划
   - 修复问题
   - 性能优化

## 🔄 后续步骤

### 如果测试成功 ✅

1. 创建完整的 NestJS 后端服务
2. 集成到 Flutter 应用
3. 添加 Garmin API 支持
4. 实现数据分析功能

### 如果测试失败 ❌

1. 分析失败原因
2. 检查 Coros API 是否可用
3. 调整实现方案
4. 重新测试

## 💡 建议

1. **从小开始** - 先测试单个功能，再组合
2. **记录问题** - 使用 `coros-test-plan.md` 中的表格记录
3. **定期提交** - 使用 git 保存进度
4. **寻求帮助** - 查看 coros-api 的 GitHub issues
5. **保持灵活** - 根据实际情况调整计划

## 📞 支持

如有问题，请：
1. 查看 `coros-test-plan.md` 中的常见问题
2. 检查 coros-api 的 GitHub issues
3. 查看 Coros 官方文档
4. 在 BlueWatch 项目中记录 issue

---

**准备好开始了吗？** 🚀

运行以下命令开始：
```bash
bash setup-coros-cli.sh
```

祝你测试顺利！
