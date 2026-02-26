# BlueWatch 改进计划

## 项目目标

将 BlueWatch 从单一蓝牙应用升级为**多源数据聚合平台**，支持蓝牙设备、Coros API、Garmin API 等多个数据源，提供统一的数据管理、分析和导出功能。

## 整体架构设计

### 新架构（推荐）

```
┌─────────────────────────────────────────────────────────────┐
│                    BlueWatch Flutter App                     │
│  (UI Layer - 心率、步数、睡眠、运动、数据分析、设置)         │
└────────────────────────┬────────────────────────────────────┘
                         │ HTTP/REST API
┌────────────────────────▼────────────────────────────────────┐
│              BlueWatch Backend Service (NestJS)              │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │           Data Aggregation Layer                     │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │  │
│  │  │ Bluetooth   │  │ Coros API   │  │ Garmin API  │  │  │
│  │  │ Service     │  │ Integration │  │ Integration │  │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  │  │
│  └──────────────────────────────────────────────────────┘  │
│                         │                                   │
│  ┌──────────────────────▼──────────────────────────────┐  │
│  │        Data Processing & Storage Layer              │  │
│  │  ┌─────────────────────────────────────────────┐   │  │
│  │  │  SQLite Database (Local Storage)            │   │  │
│  │  │  - Activities, Heart Rate, Steps, Sleep     │   │  │
│  │  │  - User Profiles, Sync Status               │   │  │
│  │  └─────────────────────────────────────────────┘   │  │
│  │  ┌─────────────────────────────────────────────┐   │  │
│  │  │  Data Sync & Conflict Resolution            │   │  │
│  │  │  - Merge data from multiple sources         │   │  │
│  │  │  - Handle duplicates and conflicts          │   │  │
│  │  └─────────────────────────────────────────────┘   │  │
│  └──────────────────────────────────────────────────────┘  │
│                         │                                   │
│  ┌──────────────────────▼──────────────────────────────┐  │
│  │        Business Logic Layer                         │  │
│  │  - Data Analysis & Statistics                      │  │
│  │  - Export (FIT, TCX, GPX, CSV)                     │  │
│  │  - Notifications & Alerts                          │  │
│  └──────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
```

## 实现阶段

### Phase 1: 基础设施建设（高优先级）

#### 1.1 创建 NestJS 后端服务

**目标：** 建立后端服务框架，支持数据聚合和存储

**文件结构：**
```
bluewatch-backend/
├── src/
│   ├── app.module.ts
│   ├── main.ts
│   ├── config/
│   │   ├── database.config.ts
│   │   └── app.config.ts
│   ├── database/
│   │   ├── entities/
│   │   │   ├── user.entity.ts
│   │   │   ├── device.entity.ts
│   │   │   ├── activity.entity.ts
│   │   │   ├── heart-rate.entity.ts
│   │   │   ├── step.entity.ts
│   │   │   └── sleep.entity.ts
│   │   ├── migrations/
│   │   └── database.module.ts
│   ├── auth/
│   │   ├── auth.service.ts
│   │   ├── auth.controller.ts
│   │   └── auth.module.ts
│   ├── data-sources/
│   │   ├── bluetooth/
│   │   ├── coros/
│   │   ├── garmin/
│   │   └── data-sources.module.ts
│   ├── sync/
│   │   ├── sync.service.ts
│   │   ├── conflict-resolver.ts
│   │   └── sync.module.ts
│   ├── api/
│   │   ├── activities/
│   │   ├── heart-rate/
│   │   ├── steps/
│   │   ├── sleep/
│   │   └── export/
│   └── common/
│       ├── filters/
│       ├── interceptors/
│       └── decorators/
├── package.json
├── tsconfig.json
└── docker-compose.yml
```

**技术栈：**
- NestJS 11.x
- TypeORM + SQLite
- Axios (HTTP 客户端)
- Zod (数据验证)
- Passport (认证)

**核心模块：**

1. **DatabaseModule** - 数据库配置和连接
   - 使用 TypeORM 管理 SQLite
   - 定义所有数据实体
   - 数据库迁移

2. **AuthModule** - 用户认证
   - JWT 令牌管理
   - 用户注册/登录
   - 设备授权

3. **DataSourcesModule** - 数据源集成
   - 蓝牙数据处理
   - Coros API 集成
   - Garmin API 集成

4. **SyncModule** - 数据同步
   - 多源数据合并
   - 冲突解决
   - 增量同步

5. **APIModule** - REST API 端点
   - 活动管理
   - 数据查询
   - 数据导出

#### 1.2 数据库设计

**核心表结构：**

```sql
-- 用户表
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  name TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 设备表
CREATE TABLE devices (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  device_type TEXT NOT NULL, -- 'bluetooth', 'coros', 'garmin'
  device_name TEXT,
  device_id TEXT,
  is_connected BOOLEAN DEFAULT FALSE,
  last_sync DATETIME,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

-- 活动表
CREATE TABLE activities (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  device_id TEXT,
  source TEXT NOT NULL, -- 'bluetooth', 'coros', 'garmin'
  activity_type TEXT NOT NULL, -- 'run', 'bike', 'swim', etc.
  start_time DATETIME NOT NULL,
  end_time DATETIME,
  duration INTEGER, -- 秒
  distance REAL, -- 米
  calories INTEGER,
  average_heart_rate INTEGER,
  max_heart_rate INTEGER,
  raw_data TEXT, -- JSON 格式的原始数据
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (device_id) REFERENCES devices(id)
);

-- 心率数据表
CREATE TABLE heart_rate_data (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  activity_id TEXT,
  device_id TEXT,
  heart_rate INTEGER NOT NULL,
  timestamp DATETIME NOT NULL,
  source TEXT NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (activity_id) REFERENCES activities(id),
  FOREIGN KEY (device_id) REFERENCES devices(id)
);

-- 步数数据表
CREATE TABLE step_data (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  device_id TEXT,
  steps INTEGER NOT NULL,
  calories INTEGER,
  distance REAL,
  timestamp DATETIME NOT NULL,
  source TEXT NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (device_id) REFERENCES devices(id)
);

-- 睡眠数据表
CREATE TABLE sleep_data (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  device_id TEXT,
  sleep_duration REAL NOT NULL, -- 小时
  deep_sleep INTEGER, -- 分钟
  light_sleep INTEGER, -- 分钟
  awake_time INTEGER, -- 分钟
  sleep_quality INTEGER, -- 0-100
  timestamp DATETIME NOT NULL,
  source TEXT NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (device_id) REFERENCES devices(id)
);

-- 同步状态表
CREATE TABLE sync_status (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  device_id TEXT,
  source TEXT NOT NULL,
  last_sync DATETIME,
  next_sync DATETIME,
  sync_status TEXT, -- 'pending', 'syncing', 'completed', 'failed'
  error_message TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (device_id) REFERENCES devices(id)
);
```

#### 1.3 REST API 端点设计

**认证相关：**
```
POST   /api/auth/register          # 用户注册
POST   /api/auth/login             # 用户登录
POST   /api/auth/refresh           # 刷新令牌
POST   /api/auth/logout            # 登出
```

**设备管理：**
```
GET    /api/devices                # 获取设备列表
POST   /api/devices                # 添加设备
GET    /api/devices/:id            # 获取设备详情
PUT    /api/devices/:id            # 更新设备
DELETE /api/devices/:id            # 删除设备
POST   /api/devices/:id/sync       # 手动同步设备数据
```

**活动管理：**
```
GET    /api/activities             # 获取活动列表（支持分页、筛选）
GET    /api/activities/:id         # 获取活动详情
POST   /api/activities             # 创建活动（蓝牙上传）
PUT    /api/activities/:id         # 更新活动
DELETE /api/activities/:id         # 删除活动
```

**数据查询：**
```
GET    /api/heart-rate             # 获取心率数据
GET    /api/steps                  # 获取步数数据
GET    /api/sleep                  # 获取睡眠数据
GET    /api/statistics             # 获取统计数据（日/周/月）
```

**数据导出：**
```
POST   /api/export/fit             # 导出为 FIT 格式
POST   /api/export/tcx             # 导出为 TCX 格式
POST   /api/export/gpx             # 导出为 GPX 格式
POST   /api/export/csv             # 导出为 CSV 格式
```

**同步管理：**
```
GET    /api/sync/status            # 获取同步状态
POST   /api/sync/start             # 启动全量同步
POST   /api/sync/stop              # 停止同步
```

#### 1.4 蓝牙数据处理模块

**目标：** 处理来自 Flutter 应用的蓝牙数据

**API 端点：**
```
POST   /api/bluetooth/heart-rate   # 上传心率数据
POST   /api/bluetooth/steps        # 上传步数数据
POST   /api/bluetooth/sleep        # 上传睡眠数据
POST   /api/bluetooth/activity     # 上传活动数据
```

**数据格式示例：**
```json
{
  "deviceId": "device-123",
  "timestamp": "2026-02-24T10:30:00Z",
  "heartRate": 75,
  "source": "bluetooth"
}
```

### Phase 2: 数据源集成（中优先级）

#### 2.1 Coros API 集成

**目标：** 集成 coros-api 项目，支持从 Coros 云导入数据

**实现方式：**

1. **集成 coros-api 库**
   ```bash
   npm install coros-api
   ```

2. **创建 CorosService**
   ```typescript
   // src/data-sources/coros/coros.service.ts

   @Injectable()
   export class CorosService {
     constructor(private corosAPI: CorosAPI) {}

     async login(email: string, password: string) {
       // 登录 Coros
     }

     async syncActivities(userId: string, from?: Date, to?: Date) {
       // 查询活动列表
       // 下载活动详情
       // 转换为标准格式
       // 保存到数据库
     }

     async syncTrainingSchedule(userId: string) {
       // 查询训练计划
       // 转换为标准格式
       // 保存到数据库
     }
   }
   ```

3. **数据转换**
   - Coros 数据格式 → 标准 Activity 格式
   - 处理不同的运动类型映射
   - 处理时区和时间戳

4. **同步策略**
   - 首次同步：全量导入
   - 增量同步：只导入新数据
   - 冲突解决：保留最新数据

#### 2.2 Garmin API 集成（可选）

**目标：** 支持 Garmin 设备数据导入

**实现方式：**
1. 集成 Garmin Connect API
2. OAuth 认证
3. 活动数据同步
4. 数据格式转换

### Phase 3: 功能完善（中优先级）

#### 3.1 完善蓝牙数据读取

**目标：** 在 Flutter 应用中实现步数、睡眠等数据读取

**BlueWatch Flutter 改进：**

1. **步数读取**
   - 实现步数特征值订阅
   - 解析步数数据
   - 上传到后端

2. **睡眠数据读取**
   - 实现睡眠特征值订阅
   - 解析睡眠数据
   - 上传到后端

3. **运动记录读取**
   - 实现运动特征值订阅
   - 解析运动数据
   - 上传到后端

#### 3.2 数据分析和统计

**后端实现：**

```typescript
// src/api/statistics/statistics.service.ts

@Injectable()
export class StatisticsService {
  // 日统计
  async getDailyStats(userId: string, date: Date) {
    // 计算日步数、卡路里、心率等
  }

  // 周统计
  async getWeeklyStats(userId: string, week: Date) {
    // 计算周数据趋势
  }

  // 月统计
  async getMonthlyStats(userId: string, month: Date) {
    // 计算月数据趋势
  }

  // 健康指数
  async getHealthScore(userId: string) {
    // 综合评分
  }
}
```

#### 3.3 数据导出功能

**支持格式：**
- FIT (Garmin 标准格式)
- TCX (Training Center XML)
- GPX (GPS Exchange Format)
- CSV (电子表格)

**实现方式：**
```typescript
// src/api/export/export.service.ts

@Injectable()
export class ExportService {
  async exportToFIT(userId: string, activityId: string): Promise<Buffer> {
    // 查询活动数据
    // 转换为 FIT 格式
    // 返回文件
  }

  async exportToTCX(userId: string, activityId: string): Promise<string> {
    // 查询活动数据
    // 转换为 TCX 格式
    // 返回 XML
  }

  async exportToGPX(userId: string, activityId: string): Promise<string> {
    // 查询活动数据
    // 转换为 GPX 格式
    // 返回 XML
  }

  async exportToCSV(userId: string, filters: any): Promise<string> {
    // 查询多个活动
    // 转换为 CSV 格式
    // 返回 CSV
  }
}
```

### Phase 4: Flutter 应用改进（中优先级）

#### 4.1 UI 改进

**新增页面：**

1. **首页（Dashboard）**
   - 今日统计卡片（步数、心率、睡眠）
   - 周趋势图表
   - 快速操作按钮

2. **活动列表页**
   - 所有活动列表（蓝牙 + Coros + Garmin）
   - 按日期、类型筛选
   - 活动详情页

3. **数据分析页**
   - 日/周/月统计
   - 健康指数
   - 趋势分析

4. **设备管理页**
   - 已连接设备列表
   - 添加新设备
   - 设备设置

5. **设置页**
   - 用户信息
   - 数据同步设置
   - 导出设置
   - 关于应用

#### 4.2 数据同步

**实现方式：**
```dart
// lib/services/sync_service.dart

class SyncService {
  // 后台同步
  Future<void> backgroundSync() async {
    // 定期同步数据
  }

  // 手动同步
  Future<void> manualSync() async {
    // 立即同步所有数据源
  }

  // 增量同步
  Future<void> incrementalSync() async {
    // 只同步新数据
  }
}
```

#### 4.3 离线支持

**实现方式：**
- 本地缓存最近 30 天数据
- 离线时显示缓存数据
- 恢复连接时自动同步

## 技术选型

### 后端

| 组件 | 选择 | 原因 |
|------|------|------|
| 框架 | NestJS | 企业级、模块化、类型安全 |
| 数据库 | SQLite | 轻量级、易于部署、适合初期 |
| ORM | TypeORM | 类型安全、支持迁移 |
| 认证 | JWT + Passport | 标准、安全、易于集成 |
| 验证 | Zod | 类型安全、运行时验证 |
| HTTP | Axios | 成熟、易用 |

### 前端

| 组件 | 选择 | 原因 |
|------|------|------|
| 框架 | Flutter | 跨平台、性能好 |
| 状态管理 | Provider | 简单、易学 |
| HTTP | Dio | Flutter 标准库 |
| 本地存储 | Hive | 快速、易用 |
| 图表 | fl_chart | 功能完整 |

## 实现时间表

| 阶段 | 任务 | 预计工作量 |
|------|------|----------|
| Phase 1.1 | 后端框架搭建 | 2-3 天 |
| Phase 1.2 | 数据库设计和实现 | 2-3 天 |
| Phase 1.3 | REST API 实现 | 3-4 天 |
| Phase 1.4 | 蓝牙数据处理 | 2-3 天 |
| Phase 2.1 | Coros API 集成 | 2-3 天 |
| Phase 2.2 | Garmin API 集成 | 2-3 天 |
| Phase 3.1 | 蓝牙数据完善 | 2-3 天 |
| Phase 3.2 | 数据分析功能 | 2-3 天 |
| Phase 3.3 | 数据导出功能 | 2-3 天 |
| Phase 4.1 | Flutter UI 改进 | 3-4 天 |
| Phase 4.2 | 数据同步实现 | 2-3 天 |
| Phase 4.3 | 离线支持 | 1-2 天 |
| 测试和优化 | 单元测试、集成测试、性能优化 | 3-5 天 |

**总计：** 约 30-40 天（假设全职开发）

## 关键决策点

### 1. 后端部署方式

**选项 A：** 云服务（推荐）
- AWS Lambda + RDS
- Google Cloud Run + Cloud SQL
- 优点：自动扩展、易于维护
- 缺点：成本较高

**选项 B：** 自托管
- VPS + Docker
- 优点：成本低、完全控制
- 缺点：需要运维

**选项 C：** 本地开发
- 用于开发和测试
- 优点：快速迭代
- 缺点：不适合生产

### 2. 数据库选择

**当前选择：** SQLite
- 优点：轻量级、易于部署、适合初期
- 缺点：并发性能有限

**未来升级：** PostgreSQL
- 优点：功能完整、性能好、支持复杂查询
- 缺点：需要额外的基础设施

### 3. 认证方式

**当前选择：** JWT + 邮箱/密码
- 优点：简单、标准
- 缺点：需要管理密码

**未来支持：** OAuth（Google、Apple）
- 优点：用户体验好、安全
- 缺点：需要第三方集成

## 风险和缓解措施

| 风险 | 影响 | 缓解措施 |
|------|------|---------|
| Coros API 变化 | 集成失败 | 定期测试、监控 API 变化 |
| 数据冲突 | 数据不一致 | 实现完善的冲突解决机制 |
| 性能问题 | 用户体验差 | 数据库优化、缓存策略 |
| 安全漏洞 | 数据泄露 | 代码审计、安全测试 |
| 用户隐私 | 法律风险 | 隐私政策、数据加密 |

## 成功指标

1. **功能完整性**
   - ✅ 支持蓝牙、Coros、Garmin 三个数据源
   - ✅ 支持心率、步数、睡眠、运动四种数据类型
   - ✅ 支持 FIT、TCX、GPX、CSV 四种导出格式

2. **性能指标**
   - API 响应时间 < 200ms
   - 数据同步时间 < 30 秒
   - 应用启动时间 < 2 秒

3. **用户体验**
   - 用户满意度 > 4.5/5
   - 日活跃用户增长 > 50%
   - 数据同步成功率 > 99%

4. **代码质量**
   - 测试覆盖率 > 80%
   - 代码审查通过率 100%
   - 零关键安全漏洞

## 后续维护计划

1. **定期更新**
   - 每月更新依赖库
   - 每季度发布新功能
   - 每年进行大版本升级

2. **监控和告警**
   - API 可用性监控
   - 错误率监控
   - 性能监控

3. **用户反馈**
   - 收集用户反馈
   - 定期改进功能
   - 发布更新日志

## 总结

这个计划将 BlueWatch 从一个演示项目升级为一个生产级的多源数据聚合平台。通过分阶段实现，可以逐步验证需求、降低风险、快速迭代。

**关键成功因素：**
1. 清晰的架构设计
2. 完善的数据库设计
3. 标准的 API 设计
4. 自动化测试
5. 持续监控和优化
