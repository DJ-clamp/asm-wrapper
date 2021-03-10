FROM alpine
LABEL maintainer="clamp <imclamp@foxmail.com>"

ENV ASM_DIR=/AutoSignMachine \
    ASM_WRAPPER_URL=https://github.com/DJ-clamp/asm-wrapper \
    ASM_WRAPPER_BRANCH=main \
    enable_unicom=true

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories \
    && apk --no-cache add -f git tzdata openssl \
    && rm -rf /var/cache/apk/* \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone \
    && git clone -b ${ASM_WRAPPER_BRANCH} ${ASM_WRAPPER_URL} ${ASM_DIR} \
    && mkdir ${ASM_DIR}/logs \
    && mkdir ${ASM_DIR}/scripts \
    && cp -f ${ASM_DIR}/docker/entrypoint_less.sh /usr/local/bin/entrypoint_less.sh \
    && chmod 777 /usr/local/bin/entrypoint_less.sh

WORKDIR ${ASM_DIR}

ENTRYPOINT ["entrypoint_less.sh"]

# 增加一个CMD启动指令给 entrypoint_less.sh 作为判断参数
CMD [ "crond" ]