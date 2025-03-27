FROM openjdk:17-alpine

LABEL maintainer="Reinhard Pointner <rednoah@filebot.net>"

ENV FILEBOT_VERSION="5.1.7"
ENV FILEBOT_URL="https://get.filebot.net/filebot/FileBot_$FILEBOT_VERSION/FileBot_$FILEBOT_VERSION-portable.tar.xz"
ENV FILEBOT_SHA256="1a98d6a36f80b13d210f708927c3dffcae536d6b46d19136b48a47fd41064f0b"
ENV FILEBOT_HOME="/opt/filebot"
ENV HOME="/data"
ENV LANG="C.UTF-8"
ENV FILEBOT_OPTS="-Dapplication.deployment=docker -Dnet.filebot.archive.extractor=ShellExecutables -Duser.home=$HOME"

# 安装基础依赖和工具
RUN apk add --no-cache \
    mediainfo \
    chromaprint \
    p7zip \
    unrar \
    curl \
    unzip \
    bash

# 安装FileBot
RUN set -eux; \
    wget -O /tmp/filebot.tar.xz "$FILEBOT_URL"; \
    echo "$FILEBOT_SHA256  /tmp/filebot.tar.xz" | sha256sum -c -; \
    mkdir -p "$FILEBOT_HOME"; \
    tar -xf /tmp/filebot.tar.xz -C "$FILEBOT_HOME"; \
    rm /tmp/filebot.tar.xz; \
    find "$FILEBOT_HOME/lib" -type f ! -name 'libjnidispatch.so' -delete; \
    ln -s /data "$FILEBOT_HOME/data"

# 安装Projector Server
RUN set -eux; \
    curl -fsSL -o /tmp/projector-server.zip \
    https://github.com/JetBrains/projector-server/releases/download/v1.8.1/projector-server-v1.8.1.zip; \
    unzip /tmp/projector-server.zip -d /opt; \
    mv /opt/projector-server-* /opt/projector-server; \
    rm -rf /tmp/projector-server.zip /opt/projector-server/bin; \
    find /opt/projector-server/lib -name "slf4j-*" -delete

# 修改FileBot启动参数
RUN sed -i \
    -e 's|-jar "$FILEBOT_HOME/jar/filebot.jar"|-classpath "/opt/projector-server/lib/*:'"$FILEBOT_HOME"'/jar/*"|' \
    -e 's|-XX:SharedArchiveFile=/usr/share/filebot/jsa/classes.jsa||' \
    -e 's|-XX:+DisableAttachMechanism|-XX:+EnableDynamicAgentLoading -Djdk.attach.allowAttachSelf=true|' \
    -e 's|^exec "$JAVA" |& -Dorg.jetbrains.projector.server.enable=true -Dorg.jetbrains.projector.server.classToLaunch=net.filebot.Main org.jetbrains.projector.server.ProjectorLauncher |' \
    "$FILEBOT_HOME/filebot.sh"

# 创建启动脚本目录并复制自定义脚本
RUN mkdir -p /opt/bin /opt/filebot-projector
COPY projector/run-as-user /opt/bin/run-as-user
COPY projector/run /opt/bin/run
COPY projector/start /opt/filebot-projector/start

# 设置权限
RUN chmod +x \
    /opt/bin/run-as-user \
    /opt/bin/run \
    /opt/filebot-projector/start \
    "$FILEBOT_HOME/filebot.sh"

EXPOSE 8887

ENTRYPOINT ["/opt/bin/run-as-user", "/opt/bin/run", "/opt/filebot-projector/start"]
