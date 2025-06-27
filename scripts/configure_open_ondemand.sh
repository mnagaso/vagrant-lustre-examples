#!/bin/bash

# start services
systemctl start httpd
systemctl enable httpd

# OpenID Connect (OIDC) configuration
mkdir /etc/httpd/conf.d/ssl/
cd /etc/httpd/conf.d/ssl/


# Generate a self-signed SSL certificate for the OIDC server
openssl req -new -x509 -days 365 -nodes -out server.crt -keyout server.key -subj "/C=US/ST=State/L=City/O=Organization/CN=192.168.10.50"

# overwrite /etc/ood/config/ood_portal.yml
cat <<EOF > /etc/ood/config/ood_portal.yml
ssl:
  - 'SSLCertificateFile "/etc/httpd/conf.d/ssl/server.crt"'
  - 'SSLCertificateKeyFile "/etc/httpd/conf.d/ssl/server.key"'
auth:
  - 'AuthType openid-connect'
  - 'Require valid-user'
logout_redirect: '/oidc?logout=https%3A%2F%2F192.168.10.50%2F'
oidc_uri: '/oidc'
EOF

# create apatch file
/opt/ood/ood-portal-generator/sbin/update_ood_portal

# create OIDCCryptoPassphrase
OIDC_CRYPTO_PASSPHRASE=$(openssl rand -hex 40)

# overwrite /etc/httpd/conf.d/auth_openidc.conf
cat <<EOF > /etc/httpd/conf.d/auth_openidc.conf
ServerName ood-test
OIDCProviderMetadataURL "http://192.168.10.60:8080/realms/ood/.well-known/openid-configuration"
OIDCClientID "ood-test"
OIDCClientSecret "4eb876cd-acdb-4355-ba6e-3cefbb54f420"
OIDCRedirectURI https://192.168.10.50/oidc
OIDCCryptoPassphrase $OIDC_CRYPTO_PASSPHRASE

OIDCSessionInactivityTimeout 28800
OIDCSessionMaxDuration 28800
OIDCRemoteUserClaim preferred_username
OIDCPassClaimsAs environment
OIDCStripCookies mod_auth_openidc_session mod_auth_openidc_session_chunks mod_auth_openidc_session_0 mod_auth_openidc_session_1
EOF

systemctl restart httpd

# Cluster settings
mkdir -p /etc/ood/config/clusters.d
# overwrite /etc/ood/config/clusters.d/test-cluster.yml
cat <<EOF > /etc/ood/config/clusters.d/test-cluster.yml
v2:
  metadata:
    title: "Test Cluster"
  login:
    host: "192.168.10.30"
  job:
    adapter: "slurm"
    conf: "/var/spool/slurm/conf-cache/slurm.conf"
EOF
