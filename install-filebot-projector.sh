#!/bin/bash
apt autoremove filebot --purge
rm /opt/projector-server -r
curl -fsSL "https://raw.githubusercontent.com/filebot/plugins/master/gpg/maintainer.pub" | gpg --dearmor --output "/usr/share/keyrings/filebot.gpg"  
echo "deb [arch=all signed-by=/usr/share/keyrings/filebot.gpg] https://get.filebot.net/deb/ universal main" > /etc/apt/sources.list.d/filebot.list 
apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y openjdk-21-jre-headless libjna-java mediainfo libchromaprint-tools trash-cli unzip unrar p7zip-full p7zip-rar xz-utils ffmpeg mkvtoolnix atomicparsley imagemagick webp libjxl-tools sudo gnupg curl file inotify-tools rsync jdupes duperemove \
 && ln -s /usr/lib/*-linux-gnu*/jni /usr/lib/jni
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends filebot
sed -i 's|APP_DATA=.*|APP_DATA="/opt/filebot"|g; s|-Dapplication.deployment=deb|-Dapplication.deployment=deb -Duser.home="/opt/filebot" |g' /usr/bin/filebot
curl -fsSL -o /tmp/projector-server.zip https://github.com/JetBrains/projector-server/releases/download/v1.8.1/projector-server-v1.8.1.zip
unzip /tmp/projector-server.zip -d /opt
mv -v /opt/projector-server-* /opt/projector-server
rm -rvf /opt/projector-server/lib/slf4j-* /opt/projector-server/bin /tmp/projector-server.zip
sed -i 's|-jar "$FILEBOT_HOME/jar/filebot.jar"|-classpath "/opt/projector-server/lib/*:/usr/share/filebot/jar/*" -Dorg.jetbrains.projector.server.enable=true -Dorg.jetbrains.projector.server.classToLaunch=net.filebot.Main org.jetbrains.projector.server.ProjectorLauncher|g; s|-XX:SharedArchiveFile=/usr/share/filebot/jsa/classes.jsa||g; s|-XX:+DisableAttachMechanism|-XX:+EnableDynamicAgentLoading -Djdk.attach.allowAttachSelf=true -Dnet.filebot.UserFiles.fileChooser=Swing -Dnet.filebot.glass.effect=false --add-opens=java.desktop/sun.font=ALL-UNNAMED --add-opens=java.desktop/java.awt=ALL-UNNAMED --add-opens=java.desktop/sun.java2d=ALL-UNNAMED --add-opens=java.desktop/java.awt.peer=ALL-UNNAMED --add-opens=java.desktop/sun.awt.image=ALL-UNNAMED --add-opens=java.desktop/java.awt.dnd.peer=ALL-UNNAMED --add-opens=java.desktop/java.awt.image=ALL-UNNAMED|g' /usr/bin/filebot
sudo useradd -r -s /usr/sbin/nologin filebot
chown -R filebot:filebot /opt/filebot
cat <<EOF > /etc/systemd/system/filebot.service
[Unit]
Description=FileBot Processing Service
After=network.target
[Service]
Type=simple
User=filebot
ExecStart=/bin/sh -c '/usr/bin/filebot "$@" -no-xattr -no-probe '
Restart=on-failure
RestartSec=5
SyslogIdentifier=filebot
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable filebot
systemctl restart filebot
systemctl status filebot
