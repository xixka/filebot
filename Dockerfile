FROM  --platform=$BUILDPLATFORM jlesage/filebot
ENV LANG=zh_CN.UTF-8
RUN echo "installing CJK font..." && \
    if apk search --no-cache font-wqy-zenhei | grep -q font-wqy-zenhei; then \
        apk add --no-cache font-wqy-zenhei; \
    else \
        echo "${PACKAGES_MIRROR:-https://dl-cdn.alpinelinux.org/alpine}/v3.19/community" >> /etc/apk/repositories && \
        apk update --no-cache && \
        apk add --no-cache font-wqy-zenhei; \
    fi

