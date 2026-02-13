# 1. 使用更现代、包含更多底层优化补丁的镜像
FROM python:3.10-slim-bookworm

# 2. 设置环境变量，防止 Python 产生 .pyc 文件并强制日志实时输出
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    # 设置 Camoufox 缓存路径，确保位置固定
    CAMOUFOX_CACHE_DIR=/root/.cache/camoufox \
    # 强制无头模式
    HEADLESS=true

# 3. 优化系统依赖安装 (合并层级，清理更彻底)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgtk-3-0 libnss3 libasound2 libxss1 libxtst6 libdbus-glib-1-2 \
    xvfb curl ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 4. 利用缓存机制安装 Python 依赖
COPY requirements.txt .
RUN pip install --no-cache-dir -U pip && \
    pip install --no-cache-dir -r requirements.txt

# 5. 预下载浏览器内核 (单独一层，利用 Zeabur 构建缓存)
# 这一步最吃空间，单独放这里可以避免因为修改代码而重新下载
RUN python -m camoufox fetch

# 6. 复制源码 (排除掉不必要的文件，建议配合 .dockerignore)
COPY src/ ./src/

# 7. 启动优化：增加 Xvfb 屏幕参数，防止某些网页检测显示异常
# 暴露端口
EXPOSE 8000

# 使用 xvfb-run 启动，并设置虚拟显示器参数
CMD ["xvfb-run", "--server-args=-screen 0 1280x1024x24", "python", "src/main.py"]
