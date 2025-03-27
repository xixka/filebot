FROM openjdk:17-alpine

LABEL maintainer="Reinhard Pointner <rednoah@filebot.net>"

ENV FILEBOT_VERSION="5.1.7"
ENV FILEBOT_URL="https://get.filebot.net/filebot/FileBot_$FILEBOT_VERSION/FileBot_$FILEBOT_VERSION-portable.tar.xz"
ENV FILEBOT_SHA256="1a98d6a36f80b13d210f708927c3dffcae536d6b46d19136b48a47fd41064f0b"
ENV FILEBOT_HOME="/opt/filebot"
ENV HOME="/data"
ENV LANG="C.UTF-8"
ENV FILEBOT_OPTS="-Dapplication.deployment=docker -Dnet.filebot.archive.extractor=ShellExecutables -Duser.home=$HOME"

# 安装基础依赖
RUN apk add --no-cache \
    mediainfo \
    chromaprint \
    p7zip \
    unrar \
    curl \
    unzip \
    bash \
    shadow

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

# 下载并配置projector启动脚本
RUN mkdir -p /opt/bin /opt/filebot-projector \
    && curl -fsSL -o /opt/bin/run-as-user \
    https://raw.githubusercontent.com/filebot/filebot-docker/master/projector/run-as-user \
    && curl -fsSL -o /opt/bin/run \
    https://raw.githubusercontent.com/filebot/filebot-docker/master/projector/run \
    && curl -fsSL -o /opt/filebot-projector/start \
    https://raw.githubusercontent.com/filebot/filebot-docker/master/projector/start \
    && chmod +x /opt/bin/run-as-user /opt/bin/run /opt/filebot-projector/start

# 修改FileBot启动参数
RUN sed -i \
    -e 's|exec "$JAVA" |exec "$JAVA" -Dorg.jetbrains.projector.server.enable=true \\\n  -Dorg.jetbrains.projector.server.classToLaunch=net.filebot.Main \\\n  -cp "/opt/projector-server/lib/*:$FILEBOT_HOME/jar/*" \\\n  org.jetbrains.projector.server.ProjectorLauncher \\\n  |' \
    -e 's|-XX:SharedArchiveFile=/usr/share/filebot/jsa/classes.jsa||' \
    -e 's|-XX:+DisableAttachMechanism|-XX:+EnableDynamicAgentLoading -Djdk.attach.allowAttachSelf=true|' \
    "$FILEBOT_HOME/filebot.sh"

# 配置用户和权限
RUN groupadd -g 1000 filebot \
    && useradd -u 1000 -g filebot -d /data filebot \
    && mkdir -p /data \
    && chown -R filebot:filebot /data

EXPOSE 8887

ENTRYPOINT ["/opt/bin/run-as-user", "/opt/bin/run", "/opt/filebot-projector/start"]
