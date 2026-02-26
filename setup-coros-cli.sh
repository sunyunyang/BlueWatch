#!/bin/bash

# BlueWatch Coros CLI - 快速启动脚本

set -e

echo "🚀 BlueWatch Coros CLI 快速启动"
echo "================================"

# 检查 Node.js
if ! command -v node &> /dev/null; then
    echo "❌ 未找到 Node.js，请先安装 Node.js 18+"
    exit 1
fi

echo "✅ Node.js 版本: $(node --version)"

# 创建项目目录
PROJECT_DIR="bluewatch-coros-cli"
if [ -d "$PROJECT_DIR" ]; then
    echo "⚠️  目录 $PROJECT_DIR 已存在，跳过创建"
else
    echo "📁 创建项目目录: $PROJECT_DIR"
    mkdir -p "$PROJECT_DIR"
fi

cd "$PROJECT_DIR"

# 初始化 npm 项目
if [ ! -f "package.json" ]; then
    echo "📦 初始化 npm 项目..."
    npm init -y > /dev/null
fi

# 安装依赖
echo "📥 安装依赖..."
npm install \
    axios \
    dotenv \
    dayjs \
    zod \
    commander \
    chalk \
    table \
    --save > /dev/null 2>&1

npm install \
    typescript \
    @types/node \
    ts-node \
    tsx \
    --save-dev > /dev/null 2>&1

# 创建 TypeScript 配置
if [ ! -f "tsconfig.json" ]; then
    echo "⚙️  创建 TypeScript 配置..."
    cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "lib": ["ES2020"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
EOF
fi

# 创建 .env 文件
if [ ! -f ".env" ]; then
    echo "🔐 创建 .env 文件..."
    cat > .env << 'EOF'
# Coros 账户
COROS_EMAIL=your-email@example.com
COROS_PASSWORD=your-password

# 本地存储路径
DATA_DIR=./data

# 日志级别
LOG_LEVEL=info
EOF
    echo "⚠️  请编辑 .env 文件，填入你的 Coros 账户信息"
fi

# 创建源代码目录
mkdir -p src/{commands,services,models,utils}
mkdir -p data

# 创建 package.json 脚本
echo "📝 更新 package.json 脚本..."
npm pkg set scripts.cli="tsx src/index.ts"
npm pkg set scripts.build="tsc"
npm pkg set scripts.dev="tsx --watch src/index.ts"

echo ""
echo "✅ 项目初始化完成！"
echo ""
echo "📋 后续步骤："
echo "1. 编辑 .env 文件，填入 Coros 账户信息"
echo "2. 实现 src/services/coros.service.ts"
echo "3. 实现 src/services/storage.service.ts"
echo "4. 实现 src/commands/login.ts"
echo "5. 运行: npm run cli -- login"
echo ""
echo "📚 参考文档："
echo "- coros-quick-plan.md - 快速方案概述"
echo "- coros-implementation-guide.md - 实现指南"
echo "- coros-test-plan.md - 测试计划"
echo ""
