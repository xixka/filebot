FROM eclipse-temurin:17-jre-alpine

LABEL maintainer="Reinhard Pointner <rednoah@filebot.net>"

ENV FILEBOT_VERSION="5.1.7"
ENV FILEBOT_URL="https://get.filebot.net/filebot/FileBot_$FILEBOT_VERSION/FileBot_$FILEBOT_VERSION-portable.tar.xz"
ENV FILEBOT_SHA256="1a98d6a36f80b13d210f708927c3dffcae536d6b46d19136b48a47fd41064f0b"
ENV FILEBOT_HOME="/opt/filebot"
ENV HOME="/data"
ENV LANG="C.UTF-8"
ENV FILEBOT_OPTS="-Dapplication.deployment=docker -Dnet.filebot.archive.extractor=ShellExecutables -Duser.home=$HOME"
ENV PUID="1000"
ENV PGID="1000"
ENV PUSER="filebot"
ENV PGROUP="filebot"

# 安装基础依赖
RUN echo "https://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories \
    && apk add --no-cache \
    p7zip \
    curl \
    unzip \
    bash \
    sudo \
    shadow

COPY generic /

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
RUN set -eux \
 ## ** install projector
 && curl -fsSL -o /tmp/projector-server.zip https://github.com/JetBrains/projector-server/releases/download/v1.8.1/projector-server-v1.8.1.zip \
 && unzip /tmp/projector-server.zip -d /opt \
 && mv -v /opt/projector-server-* /opt/projector-server \
 && rm -rvf /opt/projector-server/lib/slf4j-* /opt/projector-server/bin /tmp/projector-server.zip \
  && sudo ln -sf "/opt/filebot/filebot.sh" /usr/bin/filebot  \
 && sed -i 's|APP_DATA=.*|APP_DATA="$HOME"|g; s|-Dapplication.deployment=deb|-Dapplication.deployment=docker -Duser.home="$HOME"|g' /usr/bin/filebot  \
 && sed -i 's|-jar "$FILEBOT_HOME/jar/filebot.jar"|-classpath "/opt/projector-server/lib/*:/usr/share/filebot/jar/*" -Dorg.jetbrains.projector.server.enable=true -Dorg.jetbrains.projector.server.classToLaunch=net.filebot.Main org.jetbrains.projector.server.ProjectorLauncher|g; s|-XX:SharedArchiveFile=/usr/share/filebot/jsa/classes.jsa||g; s|-XX:+DisableAttachMechanism|-XX:+EnableDynamicAgentLoading -Djdk.attach.allowAttachSelf=true -Dnet.filebot.UserFiles.fileChooser=Swing -Dnet.filebot.glass.effect=false --add-opens=java.desktop/sun.font=ALL-UNNAMED --add-opens=java.desktop/java.awt=ALL-UNNAMED --add-opens=java.desktop/sun.java2d=ALL-UNNAMED --add-opens=java.desktop/java.awt.peer=ALL-UNNAMED --add-opens=java.desktop/sun.awt.image=ALL-UNNAMED --add-opens=java.desktop/java.awt.dnd.peer=ALL-UNNAMED --add-opens=java.desktop/java.awt.image=ALL-UNNAMED|g' /usr/bin/filebot



# install custom launcher scripts
COPY projector /



# 配置用户和权限
RUN groupadd -g 1000 filebot \
    && useradd -u 1000 -g filebot -d /data filebot \
    && mkdir -p /data \
    && chown -R filebot:filebot /data \
    && chmod +x /opt/bin/run-as-user \
    && chmod +x /opt/bin/run  \
    && chmod +x /opt/filebot-projector/start  \
    && chmod +x /opt/share/activate.sh  

# 显式设置Java环境变量
ENV JAVA_HOME=/opt/java/openjdk
ENV PATH=$JAVA_HOME/bin:$PATH

EXPOSE 8887

ENTRYPOINT ["/opt/filebot-projector/start"]
