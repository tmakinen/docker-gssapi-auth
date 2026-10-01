#!/bin/sh

set -eu

if [ -z "${KERBEROS_REALM:-}" ]; then
    echo "ERR: Failed to start, missing \$KERBEROS_REALM" 1>&2
    exit 1
fi

if [ -z "${KERBEROS_KDC:-}" ]; then
    echo "ERR: Failed to start, missing \$KERBEROS_KDC" 1>&2
    exit 1
fi

# test keytab
su - "$APACHE_RUN_USER" -s /bin/sh -c "klist -k /etc/krb5.keytab" > /dev/null

cat <<EOF > "/run/gssapi-auth/krb5.conf"
[libdefaults]
    default_realm = ${KERBEROS_REALM}
    dns_lookup_realm = false
    dns_lookup_kdc = false
    rdns = false

[realms]
    ${KERBEROS_REALM} = {
        kdc = ${KERBEROS_KDC}
    }
EOF

exec "$@"
