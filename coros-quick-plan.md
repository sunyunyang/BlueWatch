# Coros API 快速集成方案

## 目标

快速验证 Coros API 集成的可行性，建立最小化的测试环境，尽早发现问题。

## 快速方案（推荐用于测试）

### 方案概述

不构建完整的后端服务，而是创建一个**轻量级的 Node.js CLI 工具**，直接集成 coros-api，用于测试和验证。

```
┌─────────────────────────────────────────┐
│   BlueWatch Coros Integration CLI       │
│   (Node.js + coros-api)                 │
│                                         │
│  ├── 用户认证                           │
│  ├── 活动查询                           │
│  ├── 数据下载                           │
│  ├── 格式转换                           │
│  └── 本地存储 (JSON)                    │
└─────────────────────────────────────────┘
```

### 项目结构

```
bluewatch-coros-cli/
├── src/
│   ├── index.ts                    # 主入口
│   ├── commands/
│   │   ├── login.ts                # 登录命令
│   │   ├── sync.ts                 # 同步命令
│   │   ├── export.ts               # 导出命令
│   │   └── list.ts                 # 列表命令
│   ├── services/
│   │   ├── coros.service.ts        # Coros API 包装
│   │   ├── storage.service.ts      # 本地存储
│   │   └── converter.service.ts    # 数据转换
│   ├── models/
│   │   ├── activity.ts
│   │   ├── user.ts
│   │   └── sync-status.ts
│   └── utils/
│       ├── logger.ts
│       └── config.ts
├── data/                           # 本地数据存储
│   ├── users.json
│   ├── activities.json
│   └── sync-logs.json
├── package.json
├── tsconfig.json
└── .env.example
```

### 核心功能

#### 1. 用户认证

```typescript
// src/commands/login.ts
import { CorosService } from '../services/coros.service';
import { StorageService } from '../services/storage.service';

export async function login(email: string, password: string) {
  const coros = new CorosService();

  try {
    // 登录到 Coros
    const token = await coros.login(email, password);

    // 保存凭证到本地
    const storage = new StorageService();
    storage.saveUser({
      email,
      token,
      loginTime: new Date(),
    });

    console.log('✅ 登录成功');
    return token;
  } catch (error) {
    console.error('❌ 登录失败:', error.message);
    throw error;
  }
}
```

**使用方式：**
```bash
npm run cli -- login --email user@example.com --password password
```

#### 2. 活动同步

```typescript
// src/commands/sync.ts
export async function sync(options: {
  fromDate?: string;
  toDate?: string;
  sportTypes?: string[];
}) {
  const coros = new CorosService();
  const storage = new StorageService();
  const converter = new ConverterService();

  try {
    // 获取用户信息
    const user = storage.getUser();
    if (!user) throw new Error('未登录');

    // 查询活动
    console.log('📥 正在查询 Coros 活动...');
    const activities = await coros.queryActivities({
      from: options.fromDate ? new Date(options.fromDate) : undefined,
      to: options.toDate ? new Date(options.toDate) : undefined,
      sportTypes: options.sportTypes || ['all'],
    });

    console.log(`✅ 找到 ${activities.length} 个活动`);

    // 下载活动详情
    console.log('📥 正在下载活动详情...');
    const detailedActivities = [];
    for (const activity of activities) {
      const detail = await coros.downloadActivityDetail({
        sportType: activity.sportType,
        fileType: 'fit',
        labelId: activity.labelId,
      });

      // 转换格式
      const converted = converter.corosToUnified(detail);
      detailedActivities.push(converted);

      console.log(`  ✓ ${activity.name} (${activity.startTime})`);
    }

    // 保存到本地
    storage.saveActivities(detailedActivities);
    storage.saveSyncLog({
      timestamp: new Date(),
      status: 'success',
      recordsCount: detailedActivities.length,
    });

    console.log('✅ 同步完成');
    return detailedActivities;
  } catch (error) {
    storage.saveSyncLog({
      timestamp: new Date(),
      status: 'failed',
      error: error.message,
    });
    console.error('❌ 同步失败:', error.message);
    throw error;
  }
}
```

**使用方式：**
```bash
# 同步所有活动
npm run cli -- sync

# 同步特定日期范围
npm run cli -- sync --fromDate 2025-01-01 --toDate 2025-02-01

# 同步特定运动类型
npm run cli -- sync --sportTypes run,bike
```

#### 3. 数据导出

```typescript
// src/commands/export.ts
export async function exportData(options: {
  format: 'fit' | 'tcx' | 'gpx' | 'csv' | 'json';
  output: string;
  activityIds?: string[];
}) {
  const storage = new StorageService();
  const converter = new ConverterService();

  try {
    // 获取活动
    let activities = storage.getActivities();
    if (options.activityIds) {
      activities = activities.filter(a => options.activityIds.includes(a.id));
    }

    console.log(`📤 正在导出 ${activities.length} 个活动为 ${options.format} 格式...`);

    // 转换格式
    const exported = converter.toFormat(activities, options.format);

    // 保存文件
    const filename = `activities-${Date.now()}.${options.format}`;
    const filepath = path.join(options.output, filename);
    fs.writeFileSync(filepath, exported);

    console.log(`✅ 导出完成: ${filepath}`);
    return filepath;
  } catch (error) {
    console.error('❌ 导出失败:', error.message);
    throw error;
  }
}
```

**使用方式：**
```bash
# 导出为 JSON
npm run cli -- export --format json --output ./data

# 导出为 FIT
npm run cli -- export --format fit --output ./data

# 导出特定活动
npm run cli -- export --format csv --output ./data --activityIds id1,id2,id3
```

#### 4. 活动列表

```typescript
// src/commands/list.ts
export async function listActivities(options: {
  limit?: number;
  offset?: number;
  sortBy?: 'date' | 'distance' | 'duration';
}) {
  const storage = new StorageService();

  try {
    let activities = storage.getActivities();

    // 排序
    if (options.sortBy === 'distance') {
      activities.sort((a, b) => b.distance - a.distance);
    } else if (options.sortBy === 'duration') {
      activities.sort((a, b) => b.duration - a.duration);
    } else {
      activities.sort((a, b) => new Date(b.startTime).getTime() - new Date(a.startTime).getTime());
    }

    // 分页
    const limit = options.limit || 10;
    const offset = options.offset || 0;
    const paginated = activities.slice(offset, offset + limit);

    // 显示表格
    console.table(paginated.map(a => ({
      ID: a.id.substring(0, 8),
      类型: a.activityType,
      日期: new Date(a.startTime).toLocaleDateString('zh-CN'),
      距离: `${(a.distance / 1000).toFixed(2)} km`,
      时长: `${Math.floor(a.duration / 60)} min`,
      卡路里: a.calories,
      平均心率: a.averageHeartRate,
    })));

    console.log(`\n总计: ${activities.length} 个活动 (显示 ${offset + 1}-${offset + paginated.length})`);
  } catch (error) {
    console.error('❌ 列表查询失败:', error.message);
    throw error;
  }
}
```

**使用方式：**
```bash
# 列出最近 10 个活动
npm run cli -- list

# 列出按距离排序的活动
npm run cli -- list --sortBy distance --limit 20
```

### 数据格式转换

```typescript
// src/services/converter.service.ts
export class ConverterService {
  // Coros 格式 → 统一格式
  corosToUnified(corosActivity: any) {
    return {
      id: corosActivity.labelId,
      source: 'coros',
      activityType: this.mapSportType(corosActivity.sportType),
      startTime: new Date(corosActivity.startTime),
      endTime: new Date(corosActivity.endTime),
      duration: (corosActivity.endTime - corosActivity.startTime) / 1000,
      distance: corosActivity.distance,
      calories: corosActivity.calories,
      averageHeartRate: corosActivity.avgHeartRate,
      maxHeartRate: corosActivity.maxHeartRate,
      rawData: corosActivity,
    };
  }

  // 统一格式 → FIT 格式
  toFit(activities: any[]) {
    // 使用 fit-file-writer 库
    // 实现 FIT 格式转换
  }

  // 统一格式 → TCX 格式
  toTcx(activities: any[]) {
    // 实现 TCX 格式转换
  }

  // 统一格式 → GPX 格式
  toGpx(activities: any[]) {
    // 实现 GPX 格式转换
  }

  // 统一格式 → CSV 格式
  toCsv(activities: any[]) {
    const headers = ['ID', '类型', '开始时间', '结束时间', '距离(km)', '时长(分)', '卡路里', '平均心率'];
    const rows = activities.map(a => [
      a.id,
      a.activityType,
      new Date(a.startTime).toISOString(),
      new Date(a.endTime).toISOString(),
      (a.distance / 1000).toFixed(2),
      Math.floor(a.duration / 60),
      a.calories,
      a.averageHeartRate,
    ]);

    return [headers, ...rows]
      .map(row => row.join(','))
      .join('\n');
  }
}
```

### 本地存储

```typescript
// src/services/storage.service.ts
export class StorageService {
  private dataDir = './data';

  constructor() {
    if (!fs.existsSync(this.dataDir)) {
      fs.mkdirSync(this.dataDir, { recursive: true });
    }
  }

  saveUser(user: any) {
    const filepath = path.join(this.dataDir, 'users.json');
    fs.writeFileSync(filepath, JSON.stringify(user, null, 2));
  }

  getUser() {
    const filepath = path.join(this.dataDir, 'users.json');
    if (!fs.existsSync(filepath)) return null;
    return JSON.parse(fs.readFileSync(filepath, 'utf-8'));
  }

  saveActivities(activities: any[]) {
    const filepath = path.join(this.dataDir, 'activities.json');
    fs.writeFileSync(filepath, JSON.stringify(activities, null, 2));
  }

  getActivities() {
    const filepath = path.join(this.dataDir, 'activities.json');
    if (!fs.existsSync(filepath)) return [];
    return JSON.parse(fs.readFileSync(filepath, 'utf-8'));
  }

  saveSyncLog(log: any) {
    const filepath = path.join(this.dataDir, 'sync-logs.json');
    let logs = [];
    if (fs.existsSync(filepath)) {
      logs = JSON.parse(fs.readFileSync(filepath, 'utf-8'));
    }
    logs.push(log);
    fs.writeFileSync(filepath, JSON.stringify(logs, null, 2));
  }
}
```

## 实现步骤

### Step 1: 项目初始化

```bash
# 创建项目
mkdir bluewatch-coros-cli
cd bluewatch-coros-cli

# 初始化 npm
npm init -y

# 安装依赖
npm install \
  @nestjs/common \
  @nestjs/core \
  axios \
  dotenv \
  zod \
  commander \
  chalk \
  table

npm install -D \
  typescript \
  @types/node \
  ts-node \
  tsx

# 创建 tsconfig.json
npx tsc --init
```

### Step 2: 集成 coros-api

```bash
# 方式 1: 直接复制 coros-api 代码
# 从 https://github.com/xballoy/coros-api 复制 src/coros 目录

# 方式 2: 作为 npm 包（如果发布）
npm install coros-api

# 方式 3: 从 GitHub 直接安装
npm install github:xballoy/coros-api
```

### Step 3: 实现核心服务

按照上面的代码实现：
- CorosService（Coros API 包装）
- StorageService（本地存储）
- ConverterService（数据转换）

### Step 4: 实现 CLI 命令

实现四个主要命令：
- login
- sync
- export
- list

### Step 5: 测试

```bash
# 编译
npm run build

# 测试登录
npm run cli -- login --email your-email@example.com --password your-password

# 测试同步
npm run cli -- sync

# 测试列表
npm run cli -- list

# 测试导出
npm run cli -- export --format json --output ./output
```

## 预期输出

### 登录成功
```
✅ 登录成功
Token: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### 同步成功
```
📥 正在查询 Coros 活动...
✅ 找到 42 个活动
📥 正在下载活动详情...
  ✓ Morning Run (2025-02-23 06:30)
  ✓ Evening Bike (2025-02-22 18:45)
  ... (40 more)
✅ 同步完成
```

### 列表显示
```
┌────────┬────────┬────────────┬──────────┬────────┬────────┬──────────┐
│ ID     │ 类型   │ 日期       │ 距离     │ 时长   │ 卡路里 │ 平均心率 │
├────────┼────────┼────────────┼──────────┼────────┼────────┼──────────┤
│ abc123 │ run    │ 2025-02-23 │ 10.50 km │ 65 min │ 650    │ 145      │
│ def456 │ bike   │ 2025-02-22 │ 25.30 km │ 90 min │ 800    │ 135      │
└────────┴────────┴────────────┴──────────┴────────┴────────┴──────────┘

总计: 42 个活动 (显示 1-10)
```

## 优势

1. **快速验证** - 无需构建完整后端，快速测试 Coros API
2. **最小化依赖** - 只依赖 coros-api 和基础库
3. **易于调试** - CLI 工具便于调试和测试
4. **本地存储** - JSON 文件存储，易于查看和修改
5. **易于扩展** - 后续可以轻松升级为完整后端服务

## 后续升级路径

一旦验证 Coros API 集成可行，可以：

1. **集成到 Flutter 应用** - 通过 HTTP 调用 CLI 工具
2. **升级为后端服务** - 将 CLI 工具转换为 NestJS 服务
3. **添加数据库** - 从 JSON 升级为 SQLite/PostgreSQL
4. **支持多用户** - 添加用户认证和隔离
5. **集成其他数据源** - 添加 Garmin、Apple HealthKit 等

## 风险和注意事项

1. **Coros API 变化** - 非公开 API，可能随时变化
   - 缓解：定期测试，监控 API 变化

2. **认证失败** - 邮箱/密码可能过期
   - 缓解：实现令牌刷新机制

3. **数据冲突** - 多次同步可能产生重复
   - 缓解：实现去重逻辑

4. **性能问题** - 大量活动下载可能很慢
   - 缓解：实现增量同步、并发下载

## 总结

这个快速方案允许你在 **1-2 天内** 验证 Coros API 集成的可行性，而不需要构建完整的后端基础设施。一旦验证成功，可以逐步升级为生产级系统。
