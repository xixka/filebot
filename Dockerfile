# 第一阶段：最小化基础环境
FROM alpine:3.19 AS base

LABEL maintainer="Reinhard Pointner <rednoah@filebot.net>"

ENV FILEBOT_VERSION="5.1.7" \
    HOME="/data" \
    LANG="C.UTF-8" \
    PUID="1000" \
    PGID="1000" \
    PUSER="filebot" \
    PGROUP="filebot"

# 安装核心依赖
RUN apk add --no-cache \
    openjdk21-jre-headless \
    jna \
    unrar \
    p7zip \
    xz \
    bash \
    su-exec

# 安装FileBot
RUN set -eux; \
    curl -fsSL "https://raw.githubusercontent.com/filebot/plugins/master/gpg/maintainer.pub" | gpg --dearmor --output "/usr/share/keyrings/filebot.gpg"; \
    echo "https://get.filebot.net/alpine/" >> /etc/apk/repositories; \
    apk add --no-cache filebot; \
    sed -i 's|APP_DATA=.*|APP_DATA="$HOME"|g; s|-Dapplication.deployment=deb|-Dapplication.deployment=docker -Duser.home="$HOME"|g' /usr/bin/filebot

COPY generic /

# 第二阶段：精简版Projector支持
FROM base AS projector

# 安装最小化Java环境
RUN apk add --no-cache openjdk17-jre-headless

# 安装Projector核心组件
RUN set -eux; \
    curl -fsSL -o /tmp/projector.zip https://github.com/JetBrains/projector-server/releases/download/v1.8.1/projector-server-v1.8.1.zip; \
    unzip /tmp/projector.zip -d /opt/projector-server; \
    rm -rf /tmp/projector.zip /opt/projector-server/bin; \
    sed -i 's|-jar "$FILEBOT_HOME/jar/filebot.jar"|-classpath "/opt/projector-server/*:/usr/share/filebot/jar/*" -Dorg.jetbrains.projector.server.enable=true|g' /usr/bin/filebot

COPY projector /

EXPOSE 8887

ENTRYPOINT ["/opt/bin/run-as-user", "/opt/bin/run", "/opt/filebot-projector/start"]
