# 使用官方 Python 环境
FROM python:3.10-slim

# 安装系统底层依赖 (Firefox/Camoufox 运行必备)
RUN apt-get update && apt-get install -y \
    libgtk-3-0 \
    libnss3 \
    libasound2 \
    libxss1 \
    libxtst6 \
    libdbus-glib-1-2 \
    xvfb \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /app

# 复制依赖文件并安装
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 预下载 Camoufox 浏览器内核
RUN python -m camoufox fetch

# 复制所有源代码
COPY . .

# 暴露端口
EXPOSE 8000

# 环境变量默认值 (可以在 Zeabur 界面覆盖)
ENV PORT=8000
ENV HEADLESS=true

# 使用 xvfb-run 启动，解决服务器无显示器问题
CMD ["xvfb-run", "python", "src/main.py"]
