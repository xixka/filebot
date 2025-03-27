FROM eclipse-temurin:17-jre-alpine

LABEL maintainer="Reinhard Pointner <rednoah@filebot.net>"

ENV FILEBOT_VERSION="5.1.7"
ENV FILEBOT_URL="https://get.filebot.net/filebot/FileBot_$FILEBOT_VERSION/FileBot_$FILEBOT_VERSION-portable.tar.xz"
ENV FILEBOT_SHA256="1a98d6a36f80b13d210f708927c3dffcae536d6b46d19136b48a47fd41064f0b"
ENV FILEBOT_HOME="/opt/filebot"
ENV HOME="/data"
ENV LANG="C.UTF-8"
ENV FILEBOT_OPTS="-Dapplication.deployment=docker -Dnet.filebot.archive.extractor=ShellExecutables -Duser.home=$HOME"

# 安装基础依赖
RUN echo "https://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories \
    && apk add --no-cache \
    mediainfo \
    chromaprint \
    p7zip \
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

# install custom launcher scripts
COPY projector /

# 修改FileBot启动参数
RUN sed -i \
    -e 's|exec "$JAVA" |exec "$JAVA" -Dorg.jetbrains.projector.server.enable=true -Dorg.jetbrains.projector.server.classToLaunch=net.filebot.Main -cp "/opt/projector-server/lib/*:$FILEBOT_HOME/jar/*" org.jetbrains.projector.server.ProjectorLauncher |' \
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
