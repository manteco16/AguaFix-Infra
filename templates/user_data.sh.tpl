#!/bin/bash
set -euo pipefail

exec > >(tee /var/log/aguafix-user-data.log | logger -t aguafix-user-data) 2>&1

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y ca-certificates curl gnupg nginx

# ---------------------------------------------------------------------------
# Docker
# ---------------------------------------------------------------------------
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" > /etc/apt/sources.list.d/docker.list

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

systemctl enable --now docker
usermod -aG docker ubuntu

# ---------------------------------------------------------------------------
# Swap para instancias pequenas (t3.micro)
# ---------------------------------------------------------------------------
if [ ! -f /swapfile ]; then
  fallocate -l 2G /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=2048
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

# ---------------------------------------------------------------------------
# Docker Compose de produccion
# ---------------------------------------------------------------------------
mkdir -p /opt/aguafix
echo "${compose_base64}" | base64 -d > /opt/aguafix/compose.yaml

cat > /opt/aguafix/.env <<'ENV'
API_IMAGE="${api_image}"
DB_NAME="${db_name}"
DB_USER="${db_user}"
DB_PASSWORD="${db_password}"
DB_TYPE=postgres
MAILER_SERVICE="${mailer_service}"
MAILER_USER="${mailer_user}"
MAILER_PASSWORD="${mailer_password}"
MAILER_TO="${mailer_to}"
MAPBOX_TOKEN="${mapbox_token}"
AWS_REGION="${aws_region}"
AWS_S3_BUCKET="${aws_s3_bucket}"
CORS_ORIGINS="${cors_origins}"
PORT=3000
ENV

chmod 600 /opt/aguafix/.env

# ---------------------------------------------------------------------------
# Front estatico
# ---------------------------------------------------------------------------
mkdir -p /var/www/aguafix/app

cat > /var/www/aguafix/app/index.html <<'HTML'
<!doctype html>
<html lang="es">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>AguaFix</title>
  </head>
  <body>
    <h1>AguaFix</h1>
    <p>El front todavía no ha sido desplegado.</p>
  </body>
</html>
HTML

chown -R ubuntu:ubuntu /var/www/aguafix

# ---------------------------------------------------------------------------
# Nginx: API en / y front en /app/
# ---------------------------------------------------------------------------
rm -f /etc/nginx/sites-enabled/default

cat > /etc/nginx/sites-available/aguafix <<'NGINX'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    root /var/www/aguafix;
    index index.html;

    client_max_body_size 10m;

    location = /app {
        return 301 /app/;
    }

    location /app/ {
        try_files $uri $uri/ /app/index.html;
    }

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 60s;
    }
}
NGINX

ln -sf /etc/nginx/sites-available/aguafix /etc/nginx/sites-enabled/aguafix
nginx -t
systemctl enable --now nginx

# ---------------------------------------------------------------------------
# No-IP: actualiza el hostname con la IP publica de la instancia
# ---------------------------------------------------------------------------
cat > /usr/local/bin/aguafix-noip-update <<'NOIP'
#!/bin/bash
set -euo pipefail

source /etc/aguafix/noip.env

TOKEN=$(curl -fsS -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
IP=$(curl -fsS -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4)

RESPONSE=$(curl -fsS -A "AguaFix/1.0" -u "$NOIP_USER:$NOIP_PASSWORD" "https://dynupdate.no-ip.com/nic/update?hostname=$NOIP_HOSTNAME&myip=$IP")

logger -t aguafix-noip "No-IP: $RESPONSE"
NOIP

chmod 700 /usr/local/bin/aguafix-noip-update

mkdir -p /etc/aguafix

cat > /etc/aguafix/noip.env <<'ENV'
NOIP_USER="${noip_username}"
NOIP_PASSWORD="${noip_password}"
NOIP_HOSTNAME="${noip_hostname}"
ENV

chmod 600 /etc/aguafix/noip.env

cat > /etc/cron.d/aguafix-noip <<'CRON'
*/5 * * * * root /usr/local/bin/aguafix-noip-update >/dev/null 2>&1
CRON

chmod 644 /etc/cron.d/aguafix-noip

/usr/local/bin/aguafix-noip-update || true

# ---------------------------------------------------------------------------
# Levanta la API
# ---------------------------------------------------------------------------
cd /opt/aguafix
docker compose pull || true
docker compose up -d || true
