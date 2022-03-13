ARG ALPINE_VER=3.15
FROM docker.io/alpine:$ALPINE_VER AS uboot-base

RUN apk add curl

COPY resources/scripts/gitlab_packages.sh /usr/local/bin/gitlab_packages

FROM uboot-base AS uboot

# Project ID for raspi-alpine/crosscompile-uboot
RUN PROJ_ID="32838267" \
&& gitlab_packages -p "$PROJ_ID" -a u-boot-blob -d uboot

FROM uboot-base as uboot_tool

# Project ID for raspi-alpine/crosscompile-uboot-tool
RUN PROJ_ID="33098050" \
&&  gitlab_packages -p "$PROJ_ID" -a uboot-tool

FROM docker.io/alpine:$ALPINE_VER as keys
RUN apk add alpine-keys

FROM docker.io/alpine:edge

RUN sed -E -e "s/^(.*community)/\1\n\1/" -e "s/(.*)community/\1testing/" -i /etc/apk/repositories

RUN apk add --upgrade dosfstools e2fsprogs-extra findutils \
	genimage git m4 mtools pigz u-boot-tools

ADD ./resources /resources
COPY --from=uboot /uboot/ /uboot/
COPY --from=uboot_tool /uboot_tool /uboot_tool
COPY --from=keys /usr/share/apk/keys /usr/share/apk/keys-stable

RUN install /resources/scripts/find-deps.sh /usr/local/bin/find-deps && \
    install /resources/scripts/find-mods.sh /usr/local/bin/find-mods 

WORKDIR /work

CMD ["/bin/sh", "/resources/build.sh"]
