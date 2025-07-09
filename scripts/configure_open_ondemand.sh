#!/bin/bash

# start services
systemctl start httpd
systemctl enable httpd

#
# Authentication and Authorization
#


# OpenID Connect (OIDC) configuration
mkdir /etc/httpd/conf.d/ssl/
cd /etc/httpd/conf.d/ssl/

# Generate a self-signed SSL certificate for the OIDC server
openssl req -new -x509 -days 365 -nodes -out server.crt -keyout server.key -subj "/C=JP/ST=Tokyo/L=Tokyo/O=RCCS/CN=192.168.10.50"

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

#
# Cluster settings
#
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
    conf: "/etc/slurm/slurm.conf"
EOF

#
# Interactive Apps
#
cd /var/www/ood/apps/sys/bc_desktop

# overwrite form.yml
cat <<EOF > form.yml
---
attributes:
  desktop: "xfce"
  queue:
    widget: select
    label: Partition
    options:
      - [ "compute" ]
  hours:
    widget: "number_field"
    label: "Maximum run time (1 - 24 hours)"
    required: true
    value: 1
    min: 1
    max: 24
    step: 1
form:
  - desktop
  - queue
  - hours
EOF

# overwrite submit.yml.erb
cat <<'EOF' > submit.yml.erb
---
cluster: test-cluster
batch_connect:
  template: vnc
  websockify_cmd: '/usr/bin/websockify'
  script_wrapper: |
    cat << "CTRSCRIPT" > container.sh
    export PATH="$PATH:/opt/TurboVNC/bin"
    export LANG=C
    %s
    CTRSCRIPT
    singularity run ${HOME}/rocky95.sif bash ./container.sh

script:
  job_name: "ood_desktop"
  queue_name: <%= queue %>
  native:
    - "-t"
    - "<%= hours %>:00:00"
EOF

# allow reverse proxy
# append lines at the end of /etc/ood/config/ood_portal.yml
cat <<EOF >> /etc/ood/config/ood_portal.yml
host_regex: '^192\.168\.10\.(30|40|50|60)$'
node_uri: '/node'
rnode_uri: '/rnode'
EOF

# update apache configuration
/opt/ood/ood-portal-generator/sbin/update_ood_portal
# restart httpd service
systemctl restart httpd
