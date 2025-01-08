# 使用官方的 Node 镜像作为基础镜像
FROM docker.jintiku.com/node:20.12.2

# 设置工作目录
WORKDIR /usr/src/app

ENV NODE_TLS_REJECT_UNAUTHORIZED=0


# 切换 npm 源到阿里云源
RUN npm config set registry https://registry.npm.taobao.org/ 

# 切换到根用户（如果当前不是）
USER root

# 更新并清理 APT 缓存（仅适用于基于 Debian/Ubuntu 的镜像）
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        # 安装其他必要的系统级依赖（如果有）
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 使用官方提供的安装脚本来安装 pnpm
RUN curl -fsSL https://get.pnpm.io/install.sh | sh -

# 确认 pnpm 已正确安装
RUN pnpm --version

# 复制应用代码到容器
COPY . .

# 安装依赖
RUN pnpm install --verbose

# 执行 Vite 构建命令，生成 dist 目录
RUN pnpm build

# 使用 Nginx 镜像作为运行时镜像
FROM docker.jintiku.com/nginx:1.26

# 修改nginx配置
# 向 #error_page 前添加内容
# location /log-lottery {
#           alias /usr/share/nginx/log-lottery;
#           index index.html index.htm;
#           try_files $uri $uri/ /log-lottery/index.html;
#         }
RUN sed -i 's/#error_page/location \/log-lottery {\n          alias \/usr\/share\/nginx\/log-lottery;\n          index index.html index.htm;\n          try_files $uri $uri\/ \/log-lottery\/index.html;\n        }\n#error_page/' /etc/nginx/conf.d/default.conf

# 将 Vite 项目的 dist 目录复制到 Nginx 的默认静态文件目录
COPY --from=0 /usr/src/app/dist /usr/share/nginx/log-lottery

# 暴露容器的 80 端口
EXPOSE 80

# Nginx 会在容器启动时自动运行，无需手动设置 CMD