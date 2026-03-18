# 部署与迁移文档

## 目录

- [环境要求](#环境要求)
- [目录结构](#目录结构)
- [首次部署](#首次部署)
- [更新部署](#更新部署)
- [迁移到新机器](#迁移到新机器)
- [常用命令](#常用命令)
- [故障排查](#故障排查)

---

## 环境要求

- Docker >= 20.10
- Docker Compose >= 2.0
- 开放 80 端口

---

## 目录结构

```
2025-blog-public/
├── data/
│   └── blogs/              # 博客数据（持久化目录，重要）
│       ├── index.json      # 博客索引
│       └── <slug>/         # 每篇博客一个目录
│           ├── config.json # 标题、标签、日期等元信息
│           ├── index.md    # 正文 Markdown
│           └── *.webp      # 图片资源
├── .env.local              # 环境变量（本地，不提交 git）
├── Dockerfile
├── docker-compose.yml
└── docker-entrypoint.sh
```

> `data/blogs/` 是唯一需要备份和迁移的目录，其余内容均可从代码重新构建。

---

## 首次部署

### 第一步：克隆代码

```bash
git clone <your-repo-url>
cd 2025-blog-public
```

### 第二步：配置环境变量

```bash
cp .env.local.example .env.local
```

编辑 `.env.local`，按需填写：

```env
NEXT_PUBLIC_GITHUB_OWNER=你的GitHub用户名
NEXT_PUBLIC_GITHUB_REPO=2025-blog-public
NEXT_PUBLIC_GITHUB_BRANCH=main
NEXT_PUBLIC_GITHUB_APP_ID=你的AppID
```

> 如果只是本地浏览，不需要通过前端写博客，可以暂时留空。

### 第三步：构建并启动

```bash
docker compose up -d --build
```

构建过程大约需要 2~5 分钟（取决于网络和机器性能）。

### 第四步：验证

```bash
# 查看容器状态
docker compose ps

# 查看启动日志
docker compose logs -f
```

看到以下输出表示启动成功：

```
blog-1  | ▲ Next.js 16.x.x
blog-1  | - Local: http://localhost:3000
blog-1  | ✓ Ready in Xs
```

打开浏览器访问 `http://localhost`（或服务器 IP）即可。

**首次启动说明**：`data/blogs/` 目录为空时，容器会自动将内置的示例博客数据复制到该目录。后续所有博客的新增、编辑、删除都会同步到这个目录。

---

## 更新部署

当代码有更新（如升级依赖、修改页面样式）时：

```bash
# 拉取最新代码
git pull

# 重新构建并重启（数据不受影响）
docker compose up -d --build
```

> 注意：重新构建不会影响 `data/blogs/` 中的博客数据，挂载卷是独立的。

---

## 迁移到新机器

### 第一步：在旧机器上备份数据

```bash
# 打包博客数据
tar -czf blogs-backup.tar.gz data/blogs/

# 或者直接打包整个项目（含数据）
tar -czf blog-full-backup.tar.gz --exclude='.git' --exclude='node_modules' --exclude='.next' .
```

### 第二步：将文件传输到新机器

```bash
# 使用 scp 传输
scp blogs-backup.tar.gz user@new-server:/path/to/destination/

# 或使用 rsync（推荐，支持断点续传）
rsync -avz blogs-backup.tar.gz user@new-server:/path/to/destination/
```

### 第三步：在新机器上恢复

```bash
# 克隆代码到新机器
git clone <your-repo-url>
cd 2025-blog-public

# 还原博客数据
mkdir -p data
tar -xzf blogs-backup.tar.gz

# 配置环境变量
cp .env.local.example .env.local
# 编辑 .env.local ...

# 构建并启动
docker compose up -d --build
```

---

## 常用命令

```bash
# 启动（后台运行）
docker compose up -d

# 停止
docker compose down

# 构建并启动（代码有更新时）
docker compose up -d --build

# 查看运行状态
docker compose ps

# 查看实时日志
docker compose logs -f

# 进入容器内部（排查问题用）
docker compose exec blog sh

# 查看博客数据目录
ls data/blogs/
```

---

## 故障排查

### 容器启动后立即退出

```bash
docker compose logs blog
```

查看错误信息，常见原因：
- `.env.local` 文件不存在 → 执行 `cp .env.local.example .env.local`
- 80 端口被占用 → 修改 `docker-compose.yml` 中的端口，如 `"8080:3000"`

### 页面空白或 404

```bash
# 确认容器正在运行
docker compose ps

# 检查日志是否有报错
docker compose logs -f
```

### 博客数据不见了

检查 `data/blogs/` 目录是否存在且有内容：

```bash
ls -la data/blogs/
```

如果为空，说明挂载卷丢失，从备份恢复：

```bash
tar -xzf blogs-backup.tar.gz
docker compose restart
```

### 修改端口

编辑 `docker-compose.yml`：

```yaml
ports:
  - "8080:3000"  # 改为你想要的端口
```

```yaml
ports:
    - "80:3000"
```

然后重启：

```bash
docker compose up -d
```
