# Coros API 集成 - 测试计划

## 测试目标

验证以下功能的可行性：
1. ✅ Coros 用户认证
2. ✅ 活动查询和下载
3. ✅ 数据格式转换
4. ✅ 本地存储
5. ✅ 数据导出

## 测试环境准备

### 前置条件

1. **Coros 账户**
   - 需要一个有效的 Coros 账户
   - 账户中至少有几个活动记录
   - 获取邮箱和密码

2. **开发环境**
   - Node.js 18+
   - npm 或 pnpm
   - TypeScript 5.x

3. **依赖库**
   - coros-api（已验证可用）
   - axios
   - dotenv
   - commander（CLI）

## 测试步骤

### 第一阶段：基础功能测试

#### 测试 1.1：用户认证

**目标：** 验证能否成功登录 Coros

**步骤：**
```bash
# 1. 创建 .env 文件
cp .env.example .env
# 编辑 .env，填入真实的 Coros 账户信息

# 2. 运行登录测试
npm run cli -- login --email your-email@example.com --password your-password

# 3. 预期结果
# ✅ 登录成功
# 用户信息已保存到 data/user.json
```

**验证点：**
- [ ] 能否成功连接到 Coros API
- [ ] 是否返回有效的认证令牌
- [ ] 用户信息是否正确保存

**可能的问题：**
- 网络连接问题 → 检查网络和代理
- 账户信息错误 → 验证邮箱和密码
- API 变化 → 检查 coros-api 库是否需要更新

#### 测试 1.2：活动查询

**目标：** 验证能否查询用户的活动列表

**步骤：**
```bash
# 1. 查询所有活动
npm run cli -- list

# 2. 预期结果
# 显示活动列表，包括：
# - 活动 ID
# - 活动类型（跑步、骑行等）
# - 开始时间
# - 距离
# - 卡路里
# - 平均心率

# 3. 查询特定日期范围的活动
npm run cli -- sync --fromDate 2025-01-01 --toDate 2025-02-01
```

**验证点：**
- [ ] 能否成功查询活动列表
- [ ] 返回的活动数据是否完整
- [ ] 日期筛选是否正确
- [ ] 运动类型筛选是否正确

**可能的问题：**
- 账户中没有活动 → 在 Coros 应用中添加测试活动
- API 返回格式不同 → 检查 coros-api 文档
- 数据不完整 → 检查 Coros 云端数据

#### 测试 1.3：活动详情下载

**目标：** 验证能否下载单个活动的详细数据

**步骤：**
```bash
# 1. 同步活动（下载详细数据）
npm run cli -- sync

# 2. 预期结果
# 📥 正在查询 Coros 活动...
# ✅ 找到 X 个活动
# 📥 正在下载活动详情...
#   ✓ 活动1 (2025-02-20)
#   ✓ 活动2 (2025-02-19)
# ✅ 同步完成

# 3. 检查本地数据
cat data/activities.json
```

**验证点：**
- [ ] 能否成功下载活动详情
- [ ] 详情数据是否包含心率、步数等
- [ ] 数据是否正确保存到本地
- [ ] 是否处理了重复活动

**可能的问题：**
- 下载超时 → 增加超时时间
- 数据格式不同 → 更新转换逻辑
- 内存不足 → 实现分页下载

### 第二阶段：数据转换测试

#### 测试 2.1：格式转换

**目标：** 验证能否将 Coros 数据转换为标准格式

**步骤：**
```bash
# 1. 导出为 JSON
npm run cli -- export --format json --output ./exports

# 2. 导出为 CSV
npm run cli -- export --format csv --output ./exports

# 3. 检查导出文件
ls -la exports/
cat exports/activities-*.json | head -20
cat exports/activities-*.csv | head -5
```

**验证点：**
- [ ] JSON 格式是否正确
- [ ] CSV 格式是否正确
- [ ] 数据是否完整
- [ ] 是否处理了特殊字符

**可能的问题：**
- 格式不符合预期 → 检查转换逻辑
- 数据丢失 → 检查字段映射
- 文件编码问题 → 使用 UTF-8 编码

#### 测试 2.2：FIT 格式转换

**目标：** 验证能否转换为 FIT 格式（Garmin 标准）

**步骤：**
```bash
# 1. 导出为 FIT
npm run cli -- export --format fit --output ./exports

# 2. 验证 FIT 文件
# 使用 Garmin 工具或在线验证器检查 FIT 文件
# https://www.fitfileviewer.com/

# 3. 在 Garmin Connect 中导入
# 检查数据是否正确显示
```

**验证点：**
- [ ] FIT 文件是否有效
- [ ] 能否在 Garmin Connect 中导入
- [ ] 数据是否正确显示
- [ ] 是否保留了所有关键数据

**可能的问题：**
- FIT 文件无效 → 使用 coros-api 的 FIT 导出功能
- 数据不完整 → 检查 FIT 规范
- 兼容性问题 → 测试不同的 Garmin 设备

### 第三阶段：集成测试

#### 测试 3.1：完整工作流

**目标：** 验证完整的登录→查询→下载→导出流程

**步骤：**
```bash
# 1. 清空本地数据
rm -rf data/

# 2. 完整流程
npm run cli -- login --email your-email@example.com --password your-password
npm run cli -- sync --fromDate 2025-01-01 --toDate 2025-02-28
npm run cli -- export --format csv --output ./exports
npm run cli -- export --format fit --output ./exports

# 3. 验证结果
ls -la data/
ls -la exports/
```

**验证点：**
- [ ] 完整流程是否无错误
- [ ] 数据是否正确流转
- [ ] 导出文件是否有效
- [ ] 性能是否可接受

#### 测试 3.2：错误处理

**目标：** 验证错误处理机制

**步骤：**
```bash
# 1. 测试错误的凭证
npm run cli -- login --email wrong@example.com --password wrong

# 2. 测试网络错误
# 断开网络后运行同步
npm run cli -- sync

# 3. 测试无效的日期范围
npm run cli -- sync --fromDate 2099-01-01 --toDate 2099-02-01

# 4. 测试无效的运动类型
npm run cli -- sync --sportTypes invalid-type
```

**验证点：**
- [ ] 错误信息是否清晰
- [ ] 是否正确处理了异常
- [ ] 是否记录了错误日志
- [ ] 是否允许重试

### 第四阶段：性能测试

#### 测试 4.1：大数据量处理

**目标：** 验证能否处理大量活动数据

**步骤：**
```bash
# 1. 同步一年的数据
npm run cli -- sync --fromDate 2024-01-01 --toDate 2024-12-31

# 2. 监控性能
# - 内存使用
# - CPU 使用
# - 执行时间

# 3. 导出大数据集
npm run cli -- export --format csv --output ./exports
```

**验证点：**
- [ ] 能否处理 1000+ 个活动
- [ ] 内存使用是否合理
- [ ] 执行时间是否可接受
- [ ] 是否需要分页处理

#### 测试 4.2：并发处理

**目标：** 验证能否处理并发请求

**步骤：**
```bash
# 1. 同时运行多个同步任务
npm run cli -- sync &
npm run cli -- sync &
npm run cli -- sync &

# 2. 检查是否有冲突
cat data/sync-logs.json
```

**验证点：**
- [ ] 是否正确处理了并发
- [ ] 数据是否一致
- [ ] 是否有竞态条件

## 测试结果记录

### 成功标准

| 测试项 | 预期结果 | 实际结果 | 状态 |
|--------|---------|---------|------|
| 用户认证 | ✅ 成功登录 | | |
| 活动查询 | ✅ 返回活动列表 | | |
| 活动下载 | ✅ 下载详细数据 | | |
| JSON 导出 | ✅ 生成有效 JSON | | |
| CSV 导出 | ✅ 生成有效 CSV | | |
| FIT 导出 | ✅ 生成有效 FIT | | |
| 错误处理 | ✅ 正确处理错误 | | |
| 性能 | ✅ 处理 1000+ 活动 | | |

### 问题记录

| 问题 | 严重程度 | 解决方案 | 状态 |
|------|---------|---------|------|
| | | | |

## 下一步行动

根据测试结果：

1. **如果所有测试通过**
   - ✅ Coros API 集成可行
   - 开始实现完整的后端服务
   - 集成到 Flutter 应用

2. **如果部分测试失败**
   - 分析失败原因
   - 调整实现方案
   - 重新测试

3. **如果测试无法进行**
   - 检查 Coros API 是否可用
   - 验证账户权限
   - 联系 Coros 支持

## 参考资源

- [coros-api GitHub](https://github.com/xballoy/coros-api)
- [Coros Training Hub](https://t.coros.com/)
- [FIT 文件格式](https://developer.garmin.com/fit/overview/)
- [CSV 标准](https://tools.ietf.org/html/rfc4180)
