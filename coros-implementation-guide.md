# Coros API 集成 - 快速实现指南

## 第一步：项目初始化

```bash
# 创建项目目录
mkdir bluewatch-coros-cli
cd bluewatch-coros-cli

# 初始化 npm 项目
npm init -y

# 安装依赖
npm install \
  @nestjs/common \
  @nestjs/core \
  axios \
  dotenv \
  dayjs \
  zod \
  commander \
  chalk \
  table

npm install -D \
  typescript \
  @types/node \
  ts-node \
  tsx

# 创建 TypeScript 配置
npx tsc --init
```

## 第二步：环境配置

**创建 .env.example：**
```env
# Coros 账户
COROS_EMAIL=your-email@example.com
COROS_PASSWORD=your-password

# 本地存储路径
DATA_DIR=./data

# 日志级别
LOG_LEVEL=info
```

**创建 .env（本地使用）：**
```env
COROS_EMAIL=test@example.com
COROS_PASSWORD=test-password
DATA_DIR=./data
LOG_LEVEL=debug
```

## 第三步：核心服务实现

### 3.1 Coros 服务包装

**src/services/coros.service.ts：**
```typescript
import axios, { AxiosInstance } from 'axios';
import { CorosAPI } from 'coros-api'; // 使用现有的 coros-api 库

export class CorosService {
  private corosApi: CorosAPI;
  private token: string | null = null;

  constructor() {
    // 初始化 coros-api
    this.corosApi = new CorosAPI({
      email: process.env.COROS_EMAIL,
      password: process.env.COROS_PASSWORD,
    });
  }

  async login(email: string, password: string): Promise<string> {
    try {
      const result = await this.corosApi.login();
      this.token = result.token;
      return this.token;
    } catch (error) {
      throw new Error(`Coros 登录失败: ${error.message}`);
    }
  }

  async queryActivities(options: {
    from?: Date;
    to?: Date;
    sportTypes?: string[];
    page?: number;
    size?: number;
  }) {
    try {
      const result = await this.corosApi.queryActivities({
        from: options.from,
        to: options.to,
        sportTypes: options.sportTypes || ['all'],
        page: options.page || 1,
        size: options.size || 50,
      });
      return result.activities || [];
    } catch (error) {
      throw new Error(`查询活动失败: ${error.message}`);
    }
  }

  async downloadActivityDetail(options: {
    sportType: number;
    fileType: string;
    labelId: string;
  }) {
    try {
      const result = await this.corosApi.downloadActivityDetail({
        sportType: options.sportType,
        fileType: options.fileType,
        labelId: options.labelId,
      });
      return result;
    } catch (error) {
      throw new Error(`下载活动详情失败: ${error.message}`);
    }
  }

  async queryTrainingSchedule(options: {
    startDate: Date;
    endDate: Date;
  }) {
    try {
      const result = await this.corosApi.queryTrainingSchedule({
        startDate: options.startDate,
        endDate: options.endDate,
      });
      return result;
    } catch (error) {
      throw new Error(`查询训练计划失败: ${error.message}`);
    }
  }
}
```

### 3.2 本地存储服务

**src/services/storage.service.ts：**
```typescript
import fs from 'fs';
import path from 'path';

export class StorageService {
  private dataDir: string;

  constructor() {
    this.dataDir = process.env.DATA_DIR || './data';
    this.ensureDataDir();
  }

  private ensureDataDir() {
    if (!fs.existsSync(this.dataDir)) {
      fs.mkdirSync(this.dataDir, { recursive: true });
    }
  }

  private getFilePath(filename: string): string {
    return path.join(this.dataDir, filename);
  }

  // 用户信息
  saveUser(user: any) {
    const filepath = this.getFilePath('user.json');
    fs.writeFileSync(filepath, JSON.stringify(user, null, 2));
  }

  getUser(): any {
    const filepath = this.getFilePath('user.json');
    if (!fs.existsSync(filepath)) return null;
    return JSON.parse(fs.readFileSync(filepath, 'utf-8'));
  }

  // 活动数据
  saveActivities(activities: any[]) {
    const filepath = this.getFilePath('activities.json');
    fs.writeFileSync(filepath, JSON.stringify(activities, null, 2));
  }

  getActivities(): any[] {
    const filepath = this.getFilePath('activities.json');
    if (!fs.existsSync(filepath)) return [];
    return JSON.parse(fs.readFileSync(filepath, 'utf-8'));
  }

  // 同步日志
  saveSyncLog(log: any) {
    const filepath = this.getFilePath('sync-logs.json');
    let logs = [];
    if (fs.existsSync(filepath)) {
      logs = JSON.parse(fs.readFileSync(filepath, 'utf-8'));
    }
    logs.push({
      ...log,
      timestamp: new Date().toISOString(),
    });
    fs.writeFileSync(filepath, JSON.stringify(logs, null, 2));
  }

  getSyncLogs(): any[] {
    const filepath = this.getFilePath('sync-logs.json');
    if (!fs.existsSync(filepath)) return [];
    return JSON.parse(fs.readFileSync(filepath, 'utf-8'));
  }
}
```

### 3.3 数据转换服务

**src/services/converter.service.ts：**
```typescript
export class ConverterService {
  // Coros 格式转换为统一格式
  corosToUnified(corosActivity: any) {
    return {
      id: corosActivity.labelId,
      source: 'coros',
      activityType: this.mapSportType(corosActivity.sportType),
      startTime: new Date(corosActivity.startTime),
      endTime: new Date(corosActivity.endTime),
      duration: Math.floor((corosActivity.endTime - corosActivity.startTime) / 1000),
      distance: corosActivity.distance,
      calories: corosActivity.calories,
      averageHeartRate: corosActivity.avgHeartRate,
      maxHeartRate: corosActivity.maxHeartRate,
      rawData: corosActivity,
    };
  }

  // 运动类型映射
  private mapSportType(sportType: number): string {
    const typeMap: Record<number, string> = {
      1: 'run',
      2: 'bike',
      3: 'swim',
      4: 'hike',
      // ... 更多类型
    };
    return typeMap[sportType] || 'unknown';
  }

  // 转换为 CSV 格式
  toCSV(activities: any[]): string {
    const headers = ['ID', '类型', '开始时间', '结束时间', '距离(km)', '卡路里', '平均心率', '最高心率'];
    const rows = activities.map(a => [
      a.id,
      a.activityType,
      new Date(a.startTime).toISOString(),
      new Date(a.endTime).toISOString(),
      (a.distance / 1000).toFixed(2),
      a.calories,
      a.averageHeartRate,
      a.maxHeartRate,
    ]);

    const csv = [
      headers.join(','),
      ...rows.map(row => row.map(cell => `"${cell}"`).join(',')),
    ].join('\n');

    return csv;
  }

  // 转换为 JSON 格式
  toJSON(activities: any[]): string {
    return JSON.stringify(activities, null, 2);
  }
}
```

## 第四步：CLI 命令实现

**src/index.ts：**
```typescript
import { program } from 'commander';
import chalk from 'chalk';
import { CorosService } from './services/coros.service';
import { StorageService } from './services/storage.service';
import { ConverterService } from './services/converter.service';

const coros = new CorosService();
const storage = new StorageService();
const converter = new ConverterService();

program
  .name('bluewatch-coros')
  .description('BlueWatch Coros API 集成工具')
  .version('1.0.0');

// 登录命令
program
  .command('login')
  .description('登录 Coros 账户')
  .option('-e, --email <email>', 'Coros 邮箱')
  .option('-p, --password <password>', 'Coros 密码')
  .action(async (options) => {
    try {
      const email = options.email || process.env.COROS_EMAIL;
      const password = options.password || process.env.COROS_PASSWORD;

      if (!email || !password) {
        console.error(chalk.red('❌ 请提供邮箱和密码'));
        return;
      }

      console.log(chalk.blue('🔐 正在登录...'));
      const token = await coros.login(email, password);
      storage.saveUser({ email, token, loginTime: new Date() });
      console.log(chalk.green('✅ 登录成功'));
    } catch (error) {
      console.error(chalk.red(`❌ 登录失败: ${error.message}`));
    }
  });

// 同步命令
program
  .command('sync')
  .description('同步 Coros 活动')
  .option('--from <date>', '开始日期 (YYYY-MM-DD)')
  .option('--to <date>', '结束日期 (YYYY-MM-DD)')
  .option('--types <types>', '运动类型，逗号分隔')
  .action(async (options) => {
    try {
      const user = storage.getUser();
      if (!user) {
        console.error(chalk.red('❌ 请先登录'));
        return;
      }

      console.log(chalk.blue('📥 正在查询活动...'));
      const activities = await coros.queryActivities({
        from: options.from ? new Date(options.from) : undefined,
        to: options.to ? new Date(options.to) : undefined,
        sportTypes: options.types ? options.types.split(',') : undefined,
      });

      console.log(chalk.green(`✅ 找到 ${activities.length} 个活动`));

      // 下载详情并转换
      const detailed = [];
      for (const activity of activities) {
        const detail = await coros.downloadActivityDetail({
          sportType: activity.sportType,
          fileType: 'fit',
          labelId: activity.labelId,
        });
        detailed.push(converter.corosToUnified(detail));
      }

      storage.saveActivities(detailed);
      storage.saveSyncLog({
        status: 'success',
        recordsCount: detailed.length,
      });

      console.log(chalk.green('✅ 同步完成'));
    } catch (error) {
      console.error(chalk.red(`❌ 同步失败: ${error.message}`));
    }
  });

// 列表命令
program
  .command('list')
  .description('列出本地活动')
  .option('-l, --limit <number>', '显示数量', '10')
  .action((options) => {
    const activities = storage.getActivities();
    const limited = activities.slice(0, parseInt(options.limit));

    console.log(chalk.blue(`\n📋 本地活动 (共 ${activities.length} 个)\n`));
    console.table(limited.map(a => ({
      ID: a.id.substring(0, 8),
      类型: a.activityType,
      开始时间: new Date(a.startTime).toLocaleString(),
      距离: `${(a.distance / 1000).toFixed(2)} km`,
      卡路里: a.calories,
    })));
  });

// 导出命令
program
  .command('export')
  .description('导出活动数据')
  .option('-f, --format <format>', '导出格式 (json|csv)', 'json')
  .option('-o, --output <path>', '输出路径', './export')
  .action((options) => {
    try {
      const activities = storage.getActivities();
      let content: string;

      if (options.format === 'csv') {
        content = converter.toCSV(activities);
      } else {
        content = converter.toJSON(activities);
      }

      const fs = require('fs');
      const path = require('path');

      if (!fs.existsSync(options.output)) {
        fs.mkdirSync(options.output, { recursive: true });
      }

      const filename = `activities-${Date.now()}.${options.format}`;
      const filepath = path.join(options.output, filename);
      fs.writeFileSync(filepath, content);

      console.log(chalk.green(`✅ 导出完成: ${filepath}`));
    } catch (error) {
      console.error(chalk.red(`❌ 导出失败: ${error.message}`));
    }
  });

program.parse(process.argv);
```

## 第五步：package.json 脚本

```json
{
  "scripts": {
    "build": "tsc",
    "dev": "tsx src/index.ts",
    "cli": "tsx src/index.ts",
    "login": "tsx src/index.ts login",
    "sync": "tsx src/index.ts sync",
    "list": "tsx src/index.ts list",
    "export": "tsx src/index.ts export"
  }
}
```

## 第六步：快速测试

```bash
# 1. 登录
npm run login -- --email your-email@example.com --password your-password

# 2. 同步活动
npm run sync

# 3. 列出活动
npm run list

# 4. 导出为 CSV
npm run export -- --format csv --output ./export

# 5. 导出为 JSON
npm run export -- --format json --output ./export
```

## 预期结果

**成功后的目录结构：**
```
bluewatch-coros-cli/
├── data/
│   ├── user.json              # 用户信息
│   ├── activities.json        # 同步的活动
│   └── sync-logs.json         # 同步日志
├── export/
│   ├── activities-1708...csv  # 导出的 CSV
│   └── activities-1708...json # 导出的 JSON
└── src/
    └── ...
```

**user.json 示例：**
```json
{
  "email": "user@example.com",
  "token": "xxx-token-xxx",
  "loginTime": "2025-02-24T10:00:00.000Z"
}
```

**activities.json 示例：**
```json
[
  {
    "id": "activity-123",
    "source": "coros",
    "activityType": "run",
    "startTime": "2025-02-20T08:00:00.000Z",
    "endTime": "2025-02-20T08:45:00.000Z",
    "duration": 2700,
    "distance": 5000,
    "calories": 450,
    "averageHeartRate": 145,
    "maxHeartRate": 165
  }
]
```

## 下一步

一旦验证 Coros API 集成可行，可以：

1. **集成到 Flutter 应用** - 通过 HTTP 调用这个 CLI 工具
2. **升级为后端服务** - 将 CLI 转换为 NestJS 后端服务
3. **添加数据库** - 使用 SQLite 替代 JSON 文件存储
4. **支持更多功能** - 数据分析、导出、多用户等

## 故障排除

**问题 1：Coros 登录失败**
- 检查邮箱和密码是否正确
- 检查网络连接
- 查看 Coros API 是否有变化

**问题 2：活动查询返回空**
- 确保 Coros 账户中有活动
- 检查日期范围是否正确
- 查看运动类型是否支持

**问题 3：数据转换错误**
- 检查 Coros 返回的数据格式
- 更新 mapSportType 映射表
- 添加日志输出调试

## 总结

这个快速方案提供了一个最小化的、可测试的 Coros API 集成。通过这个工具，你可以：

✅ 验证 Coros API 是否可用
✅ 测试数据同步流程
✅ 验证数据格式转换
✅ 快速迭代和改进
✅ 为后续的完整集成奠定基础
