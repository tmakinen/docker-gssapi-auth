FROM docker.io/library/debian:trixie-20260918-slim

RUN set -eux ; \
    apt-get update ; \
    apt-get -y upgrade ; \
    apt-get -y install --no-install-recommends \
        apache2 \
        krb5-user \
        libapache2-mod-auth-gssapi \
    ; \
    apt-get clean ; \
    rm -rf /var/lib/apt/lists/*

RUN set -eux ; \
    find / \! \( -path /proc -prune -o -path /sys -prune \) -perm /06000 -type f -exec chmod -v a-s {} \;

RUN set -eux ; \
    a2enmod auth_gssapi headers rewrite

RUN set -eux ; \
    ln -sf /dev/stdout /var/log/apache2/access.log ; \
    ln -sf /dev/stderr /var/log/apache2/error.log ; \
    sed -i -e 's/Listen 80/Listen 8000/' /etc/apache2/ports.conf ; \
    mkdir -p /run/gssapi-auth ; \
    rm -rf /var/www/html/* ; \
    touch /var/www/html/index.html

RUN set -eux ; \
    a2dismod -q -f \* ; \
    for mod in \
        auth_gssapi \
        authn_core \
        authz_user \
        dir \
        headers \
        mpm_event \
        rewrite \
    ; do \
        a2enmod -q "$mod" ; \
    done

COPY httpd-gssapi.conf /etc/apache2/sites-available/000-default.conf
COPY entrypoint.sh /

ENV APACHE_LOG_DIR=/var/log/apache2
ENV APACHE_PID_FILE=/run/gssapi-auth/apache2.pid
ENV APACHE_RUN_DIR=/run/gssapi-auth
ENV APACHE_RUN_GROUP=www-data
ENV APACHE_RUN_USER=www-data

EXPOSE 8000

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/sbin/apache2", "-D", "FOREGROUND"]
