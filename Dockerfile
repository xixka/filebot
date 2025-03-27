# 第一阶段：构建基础环境
FROM alpine:3.19 AS base

LABEL maintainer="Reinhard Pointner <rednoah@filebot.net>"

ENV FILEBOT_VERSION="5.1.7" \
    HOME="/data" \
    LANG="C.UTF-8" \
    PUID="1000" \
    PGID="1000" \
    PUSER="filebot" \
    PGROUP="filebot"

# 安装主要依赖
RUN apk add --no-cache \
    openjdk21-jre-headless \
    jna \
    mediainfo \
    chromaprint \
    unrar \
    p7zip \
    xz \
    ffmpeg \
    mkvtoolnix \
    atomicparsley \
    imagemagick \
    libwebp-tools \
    sudo \
    gnupg \
    curl \
    file \
    inotify-tools \
    rsync \
    jdupes \
    bash

# 安装FileBot
RUN set -eux; \
    curl -fsSL "https://raw.githubusercontent.com/filebot/plugins/master/gpg/maintainer.pub" | gpg --dearmor --output "/usr/share/keyrings/filebot.gpg"; \
    echo "https://get.filebot.net/alpine/" | tee -a /etc/apk/repositories; \
    apk add --no-cache filebot; \
    sed -i 's|APP_DATA=.*|APP_DATA="$HOME"|g; s|-Dapplication.deployment=deb|-Dapplication.deployment=docker -Duser.home="$HOME"|g' /usr/bin/filebot

COPY generic /

# 第二阶段：添加Projector支持
FROM base AS projector

# 安装OpenJDK 17用于Projector
RUN apk add --no-cache openjdk17-jre-headless

# 安装Projector
RUN set -eux; \
    curl -fsSL -o /tmp/projector-server.zip https://github.com/JetBrains/projector-server/releases/download/v1.8.1/projector-server-v1.8.1.zip; \
    unzip /tmp/projector-server.zip -d /opt; \
    mv -v /opt/projector-server-* /opt/projector-server; \
    rm -rf /opt/projector-server/lib/slf4j-* /opt/projector-server/bin /tmp/projector-server.zip; \
    sed -i 's|-jar "$FILEBOT_HOME/jar/filebot.jar"|-classpath "/opt/projector-server/lib/*:/usr/share/filebot/jar/*" -Dorg.jetbrains.projector.server.enable=true -Dorg.jetbrains.projector.server.classToLaunch=net.filebot.Main org.jetbrains.projector.server.ProjectorLauncher|g; s|-XX:SharedArchiveFile=/usr/share/filebot/jsa/classes.jsa||g; s|-XX:+DisableAttachMechanism|-XX:+EnableDynamicAgentLoading -Djdk.attach.allowAttachSelf=true -Dnet.filebot.UserFiles.fileChooser=Swing -Dnet.filebot.glass.effect=false --add-opens=java.desktop/sun.font=ALL-UNNAMED --add-opens=java.desktop/java.awt=ALL-UNNAMED --add-opens=java.desktop/sun.java2d=ALL-UNNAMED --add-opens=java.desktop/java.awt.peer=ALL-UNNAMED --add-opens=java.desktop/sun.awt.image=ALL-UNNAMED --add-opens=java.desktop/java.awt.dnd.peer=ALL-UNNAMED --add-opens=java.desktop/java.awt.image=ALL-UNNAMED|g' /usr/bin/filebot

COPY projector /

EXPOSE 8887

ENTRYPOINT ["/opt/bin/run-as-user", "/opt/bin/run", "/opt/filebot-projector/start"]
