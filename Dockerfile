FROM debian:jessie

ENV POSTFIX_MIRROR http://cdn.postfix.johnriley.me/mirrors/postfix-release/official
ENV POSTFIX_VERSION 3.1.3

COPY wietse.pgp /usr/src/

RUN installDeps="gnupg ca-certificates libasan1 libatomic1 libcilkrts5 \
        libcloog-isl4 libffi6 libgdbm3 libgmp10 libgnutls-deb0-28 libgomp1 \
        libhogweed2 libicu52 libidn11 libisl10 libitm1 liblsan0 libmpc3 \
        libmpfr4 libnettle4 libp11-kit0 libpsl0 libquadmath0 libssl1.0.0 \
        libtasn1-6 libtsan0 libubsan0" \
    && buildDeps="build-essential wget libdb-dev libicu-dev libssl-dev" \
    && apt-get update \
    && apt-get install -y --no-install-recommends $installDeps $buildDeps \
    && cd /usr/src \
    && wget $POSTFIX_MIRROR/postfix-$POSTFIX_VERSION.tar.gz \
    && wget $POSTFIX_MIRROR/postfix-$POSTFIX_VERSION.tar.gz.sig \
    && gpg --import wietse.pgp && gpg --verify postfix-$POSTFIX_VERSION.tar.gz.sig \
    && tar xfz postfix-$POSTFIX_VERSION.tar.gz \
    && cd postfix-$POSTFIX_VERSION \
    && make makefiles CCARGS="-DUSE_TLS" AUXLIBS="-lssl -lcrypto" \
    && make -j$(nproc) \
    && mkdir -p /etc/postfix \
    && groupadd -r postfix \
    && groupadd -r postdrop \
    && useradd -r -g postfix -d /nonexistant -s /noshell postfix \
    && sh postfix-install -non-interactive \
    && cd .. \
    && rm -rf postfix-$POSTFIX_VERSION.tar.gz \
        postfix-$POSTFIX_VERSION.tar.gz.sig \
        /usr/src/postfix-$POSTFIX_VERSION \
    && apt-get purge -y --auto-remove $buildDeps \
    && rm -r /var/lib/apt/lists/*

COPY syslogd /usr/local/sbin/syslogd
COPY entrypoint.sh /entrypoint.sh

EXPOSE 25 587
VOLUME /var/spool/postfix
CMD ["/entrypoint.sh"]
