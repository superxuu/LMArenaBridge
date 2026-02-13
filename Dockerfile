# 使用更稳定且体积适中的 Python 基础镜像
FROM python:3.10-slim-bookworm

# 1. 设置环境变量
# 禁用 Python 缓存文件，确保日志实时输出到 Zeabur 控制台
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8000 \
    HEADLESS=true

# 2. 安装系统底层依赖
# 包含 Firefox/Camoufox 运行所需的图形库、授权工具 xauth 以及虚拟显示器 xvfb
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgtk-3-0 \
    libnss3 \
    libasound2 \
    libxss1 \
    libxtst6 \
    libdbus-glib-1-2 \
    xvfb \
    xauth \
    ca-certificates \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 3. 设置工作目录
WORKDIR /app

# 4. 安装 Python 依赖
# 先复制 requirements.txt 以利用镜像层缓存
COPY requirements.txt .
RUN pip install --no-cache-dir -U pip && \
    pip install --no-cache-dir -r requirements.txt

# 5. 预下载 Camoufox 浏览器内核
# 这样在容器启动时就不需要联网下载几百兆的内核，显著提高启动速度
RUN python -m camoufox fetch

# 6. 复制项目源代码
# 建议只复制必要的目录，避免把 .git 等无关文件打入镜像
COPY models.json .
COPY src/ ./src/

# 7. 暴露端口 (Zeabur 网关对接)
EXPOSE 8000

# 8. 启动命令
# 使用 xvfb-run -a 自动分配显示编号，并模拟标准显示器分辨率
# 注意：这里改用 uvicorn 命令行启动，以便通过 $PORT 环境变量动态绑定端口
CMD ["sh", "-c", "xvfb-run -a --server-args='-screen 0 1280x1024x24' uvicorn src.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
