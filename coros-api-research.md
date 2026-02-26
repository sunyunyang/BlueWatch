# Coros API 项目研究报告

## 项目概述

**coros-api** 是一个 TypeScript/Node.js 项目，用于批量导出 Coros 运动手表的活动数据到多种格式（FIT、TCX、GPX、KML、CSV）。

**关键特性：**
- 使用 Coros Training Hub 的非公开 API
- 支持多种导出格式（FIT、TCX、GPX、KML、CSV）
- 支持按日期范围和运动类型筛选
- 支持导出训练计划（ICS 格式）
- 命令行工具

**技术栈：**
- 框架：NestJS
- 语言：TypeScript
- HTTP 客户端：Axios
- 命令行：nest-commander
- 验证：Zod
- 时间处理：dayjs
- 测试：Vitest
- 代码质量：Biome

## 架构分析

### 1. 项目结构

```
src/
├── app.module.ts              # 主模块
├── main.ts                    # 入口点
├── command-runner/            # 命令行处理
├── core/                      # 核心功能
└── coros/                     # Coros API 实现
    ├── account/               # 账户相关（登录）
    ├── activity/              # 活动相关（查询、下载）
    ├── training-schedule/     # 训练计划
    ├── coros-api.ts           # 主 API 类
    ├── coros-authentication.service.ts  # 认证服务
    ├── base-request.ts        # 基础请求类
    ├── common.ts              # 通用工具
    ├── sport-type.ts          # 运动类型定义
    └── file-type.ts           # 文件类型定义
```

### 2. 核心组件

#### 2.1 CorosAPI 类 (coros-api.ts)

主要 API 接口，提供以下方法：

1. **login()** - 用户登录
   - 使用邮箱和密码认证
   - 返回认证令牌

2. **queryActivities()** - 查询活动列表
   - 参数：
     - from: 开始日期
     - to: 结束日期
     - page: 页码
     - size: 每页数量
     - sportTypes: 运动类型数组
   - 返回：活动列表

3. **downloadActivityDetail()** - 下载活动详情
   - 参数：
     - sportType: 运动类型
     - fileType: 导出格式（fit、tcx、gpx、kml、csv）
     - labelId: 活动 ID
   - 返回：文件数据

4. **queryTrainingSchedule()** - 查询训练计划
   - 参数：
     - startDate: 开始日期
     - endDate: 结束日期
     - supportRestExercise: 是否包含休息日
   - 返回：训练计划列表

#### 2.2 认证服务 (coros-authentication.service.ts)

- 处理用户登录
- 管理认证令牌
- 处理会话管理

#### 2.3 基础请求类 (base-request.ts)

- 封装 HTTP 请求逻辑
- 处理错误和重试
- 管理请求头和参数

#### 2.4 命令行处理 (command-runner/)

- export-activities: 导出活动
- export-training-schedule: 导出训练计划
- 支持多种选项和过滤

### 3. 支持的运动类型

根据 README，支持 30+ 种运动类型：
- 跑步：run, indoorRun, trailRun, trackRun
- 骑行：bike, indoorBike, roadEbike, gravelRoadBike, mountainRiding, mountainEbike, helmetBike
- 游泳：poolSwim, openWater
- 其他：hike, mtnClimb, triathlon, strength, gymCardio, gpsCardio, ski, snowboard, xcSki, skiTouring, multiSport, speedsurfing, windsurfing, row, indoorRow, whitewater, flatwater, multiPitch, climb, indoorClimb, bouldering, walk, jumpRope, climbStairs, customSport

### 4. 支持的导出格式

- **FIT** - Garmin 标准格式（默认）
- **TCX** - Training Center XML
- **GPX** - GPS Exchange Format
- **KML** - Keyhole Markup Language
- **CSV** - 逗号分隔值

## 关键特性分析

### ✅ 优势

1. **完整的 API 覆盖**
   - 支持登录、查询、下载等核心功能
   - 支持多种导出格式
   - 支持日期范围和运动类型筛选

2. **良好的代码组织**
   - 使用 NestJS 框架，模块化设计
   - 清晰的职责分离
   - 使用依赖注入

3. **命令行工具**
   - 易于使用的 CLI 接口
   - 支持多种选项
   - 提供示例用法

4. **现代技术栈**
   - TypeScript 类型安全
   - Zod 数据验证
   - Vitest 单元测试
   - Biome 代码质量检查

5. **文档完善**
   - README 清晰
   - API 文档使用 Bruno
   - 提供使用示例

### ⚠️ 限制和风险

1. **使用非公开 API**
   - 可能随时被 Coros 破坏
   - 没有官方支持
   - 可能违反服务条款

2. **功能有限**
   - 只支持导出，不支持上传
   - 不支持实时数据流
   - 不支持设备控制

3. **缺少实时监测**
   - 不支持心率、步数等实时数据
   - 只能导出历史活动
   - 不支持设备同步

## 与 BlueWatch 的集成机会

### 1. 数据导入

BlueWatch 可以集成 coros-api 来：
- 从 Coros 云端导入历史活动数据
- 支持多种运动类型的数据
- 丰富应用的数据来源

### 2. 多源数据聚合

支持多个数据源：
- 蓝牙设备（当前 BlueWatch 实现）
- Coros 云 API（通过 coros-api）
- Garmin API（类似实现）
- Apple HealthKit / Google Fit

### 3. 数据同步

- 定期从 Coros 同步新活动
- 本地缓存和离线访问
- 数据冲突解决

### 4. 导出功能

- 支持导出到 FIT、TCX、GPX 等格式
- 与其他应用集成
- 数据备份

## 技术实现细节

### 1. 认证流程

```
用户输入邮箱/密码
    ↓
调用 login() API
    ↓
获取认证令牌
    ↓
存储令牌用于后续请求
```

### 2. 活动查询流程

```
调用 queryActivities()
    ↓
发送 HTTP 请求到 Coros API
    ↓
解析响应数据
    ↓
返回活动列表
```

### 3. 活动下载流程

```
调用 downloadActivityDetail()
    ↓
指定运动类型、文件格式、活动 ID
    ↓
发送下载请求
    ↓
接收文件数据
    ↓
保存到本地
```

## 代码质量评估

### ✅ 好的做法

1. 使用 TypeScript 类型安全
2. 使用 Zod 进行数据验证
3. 模块化设计
4. 依赖注入
5. 单元测试
6. 代码格式化和 linting

### 🚧 可改进的地方

1. 缺少错误处理文档
2. 缺少重试机制说明
3. 缺少速率限制处理
4. 缺少日志系统
5. 缺少国际化支持

## 集成 BlueWatch 的建议方案

### 方案 1：直接集成（推荐）

在 BlueWatch 中添加 Coros 数据源：

```
BlueWatch
├── 蓝牙数据源（当前）
├── Coros API 数据源（新增）
└── 其他 API 数据源（未来）
```

**优点：**
- 用户可以在一个应用中查看所有数据
- 统一的 UI/UX
- 本地数据管理

**缺点：**
- 需要在 Flutter 中集成 TypeScript/Node.js 代码
- 增加应用复杂度

### 方案 2：后端服务（更好）

创建一个后端服务来聚合多个数据源：

```
BlueWatch (Flutter)
    ↓
Backend Service (Node.js/NestJS)
    ├── Coros API 集成
    ├── Garmin API 集成
    ├── 蓝牙数据处理
    └── 数据存储和同步
```

**优点：**
- 清晰的架构分离
- 易于扩展
- 支持多个客户端
- 可以添加更多功能（分析、推荐等）

**缺点：**
- 需要部署后端服务
- 增加基础设施成本

### 方案 3：独立工具

保持 coros-api 作为独立工具，BlueWatch 通过导入导出集成：

```
coros-api (导出 FIT/TCX/GPX)
    ↓
BlueWatch (导入这些格式)
```

**优点：**
- 最小化改动
- 保持独立性
- 用户可以选择

**缺点：**
- 用户体验不够流畅
- 需要手动导入

## 总结

**coros-api** 是一个成熟的、设计良好的项目，提供了访问 Coros 云 API 的完整解决方案。虽然使用非公开 API 存在风险，但它为 BlueWatch 提供了以下机会：

1. **数据源扩展** - 支持 Coros 设备的用户
2. **功能增强** - 导入历史数据、多源聚合
3. **生态集成** - 与其他运动应用的互操作性

**建议的集成方式：**
- 短期：创建后端服务集成 coros-api
- 中期：在 BlueWatch 中添加 Coros 数据源
- 长期：支持 Garmin、Apple HealthKit 等多个数据源

这将使 BlueWatch 从单一蓝牙应用升级为多源数据聚合平台。
