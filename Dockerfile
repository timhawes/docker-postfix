FROM debian:stretch

ENV POSTFIX_MIRROR http://cdn.postfix.johnriley.me/mirrors/postfix-release/official
ENV POSTFIX_VERSION 3.3.2

COPY wietse.pgp /usr/src/

RUN installDeps="gnupg ca-certificates libasan3 libatomic1 libcilkrts5 \
        libcloog-isl4 libffi6 libgdbm3 libgmp10 libgnutls30 libgomp1 \
        libhogweed4 libicu57 libldap-2.4-2 libidn11 libisl15 libitm1 liblsan0 \
        libmpc3 libmpfr4 libnettle6 libp11-kit0 libpsl5 libquadmath0 libsasl2-2 \
        libsasl2-modules libsasl2-modules-db libssl1.1 libtasn1-6 libtsan0 \
        libubsan0 netbase" \
    && buildDeps="build-essential wget libdb-dev libicu-dev libldap-dev libsasl2-dev libssl-dev" \
    && apt-get update \
    && apt-get install -y --no-install-recommends $installDeps $buildDeps \
    && cd /usr/src \
    && wget $POSTFIX_MIRROR/postfix-$POSTFIX_VERSION.tar.gz \
    && wget $POSTFIX_MIRROR/postfix-$POSTFIX_VERSION.tar.gz.gpg2 \
    && gpg --import wietse.pgp && gpg --verify postfix-$POSTFIX_VERSION.tar.gz.gpg2 postfix-$POSTFIX_VERSION.tar.gz \
    && tar xfz postfix-$POSTFIX_VERSION.tar.gz \
    && cd postfix-$POSTFIX_VERSION \
    && make makefiles \
        CCARGS="-DUSE_TLS -DHAS_LDAP -DUSE_LDAP_SASL -I/usr/include/sasl" \
        AUXLIBS="-lssl -lcrypto -lldap -llber" \
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
