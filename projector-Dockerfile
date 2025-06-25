FROM debian:bookworm-slim

LABEL maintainer="Reinhard Pointner <rednoah@filebot.net>"

ENV FILEBOT_VERSION="5.1.7"

# Install core dependencies with bookworm sources
RUN set -eux \
 && echo "deb http://deb.debian.org/debian bookworm main non-free non-free-firmware" > /etc/apt/sources.list \
 && echo "deb http://deb.debian.org/debian bookworm-updates main non-free non-free-firmware" >> /etc/apt/sources.list \
 && echo "deb http://security.debian.org/debian-security bookworm-security main non-free non-free-firmware" >> /etc/apt/sources.list \
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    openjdk-17-jre \
    libjna-java \
    mediainfo \
    libchromaprint-tools \
    trash-cli \
    unzip \
    unrar \
    p7zip-full \
    p7zip-rar \
    xz-utils \
    atomicparsley \
    imagemagick \
    webp \
    libjxl-tools  \
    sudo \
    gnupg \
    curl \
    file \
    inotify-tools \
    rsync \
    jdupes \
    duperemove \
    ca-certificates \
    locales \
 # Set locale
 && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
 && locale-gen en_US.UTF-8 \
 # Clean up
 && rm -rf /var/lib/apt/lists/* \
 # Fix libjna symlink
 && ln -svf /usr/lib/*-linux-gnu*/jni /usr/lib/jni

RUN set -eux \
 ## ** install filebot
 && curl -fsSL "https://raw.githubusercontent.com/filebot/plugins/master/gpg/maintainer.pub" | gpg --dearmor --output "/usr/share/keyrings/filebot.gpg"  \
 && echo "deb [arch=all signed-by=/usr/share/keyrings/filebot.gpg] https://get.filebot.net/deb/ universal main" > /etc/apt/sources.list.d/filebot.list \
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends filebot \
 && rm -rvf /var/lib/apt/lists/* \
 ## BROKEN (https://github.com/adoptium/adoptium-support/issues/1185) ** generate CDS archive
 ## && java -Xshare:dump -XX:SharedClassListFile="/usr/share/filebot/jsa/classes.jsa.lst" -XX:SharedArchiveFile="/usr/share/filebot/jsa/classes.jsa" -jar "/usr/share/filebot/jar/filebot.jar" \
 ## BROKEN (https://github.com/adoptium/adoptium-support/issues/1185) ** apply custom application configuration
 ## && sed -i 's|APP_DATA=.*|APP_DATA="$HOME"|g; s|-Dapplication.deployment=deb|-Dapplication.deployment=docker -Duser.home="$HOME" -Dnet.filebot.UserFiles.trash=XDG -XX:SharedArchiveFile=/usr/share/filebot/jsa/classes.jsa|g' /usr/bin/filebot
 ## ** apply custom application configuration
 && sed -i 's|APP_DATA=.*|APP_DATA="$HOME"|g; s|-Dapplication.deployment=deb|-Dapplication.deployment=docker -Duser.home="$HOME" -Dnet.filebot.UserFiles.trash=XDG|g' /usr/bin/filebot


# install custom launcher scripts
COPY generic /


ENV HOME="/data"
ENV LANG="C.UTF-8"

ENV PUID="1000"
ENV PGID="1000"
ENV PUSER="filebot"
ENV PGROUP="filebot"


RUN set -eux \
 ## ** install projector
 && curl -fsSL -o /tmp/projector-server.zip https://github.com/JetBrains/projector-server/releases/download/v1.8.1/projector-server-v1.8.1.zip \
 && unzip /tmp/projector-server.zip -d /opt \
 && mv -v /opt/projector-server-* /opt/projector-server \
 && rm -rvf /opt/projector-server/lib/slf4j-* /opt/projector-server/bin /tmp/projector-server.zip \
 ## ** apply custom application configuration
 && sed -i 's|-jar "$FILEBOT_HOME/jar/filebot.jar"|-classpath "/opt/projector-server/lib/*:/usr/share/filebot/jar/*" -Dorg.jetbrains.projector.server.enable=true -Dorg.jetbrains.projector.server.classToLaunch=net.filebot.Main org.jetbrains.projector.server.ProjectorLauncher|g; s|-XX:SharedArchiveFile=/usr/share/filebot/jsa/classes.jsa||g; s|-XX:+DisableAttachMechanism|-XX:+EnableDynamicAgentLoading -Djdk.attach.allowAttachSelf=true -Dnet.filebot.UserFiles.fileChooser=Swing -Dnet.filebot.glass.effect=false --add-opens=java.desktop/sun.font=ALL-UNNAMED --add-opens=java.desktop/java.awt=ALL-UNNAMED --add-opens=java.desktop/sun.java2d=ALL-UNNAMED --add-opens=java.desktop/java.awt.peer=ALL-UNNAMED --add-opens=java.desktop/sun.awt.image=ALL-UNNAMED --add-opens=java.desktop/java.awt.dnd.peer=ALL-UNNAMED --add-opens=java.desktop/java.awt.image=ALL-UNNAMED|g' /usr/bin/filebot


# install custom launcher scripts
COPY projector /


EXPOSE 8887

ENTRYPOINT ["/opt/bin/run-as-user", "/opt/bin/run", "/opt/filebot-projector/start"]
