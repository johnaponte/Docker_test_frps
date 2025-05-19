#!/bin/bash

set -e

# Default domain
DOMAIN="yourdomain.com"

# Parse arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --domain) DOMAIN="$2"; shift ;;
    *) echo "Unknown parameter passed: $1"; exit 1 ;;
  esac
  shift
done

# Create client1 directory structure ########################################
mkdir -p client1/html/test1
mkdir -p client1/frpc
mkdir -p client1/nginx

# Create server directory structure ########################################
mkdir -p server/nginx/certs
mkdir -p server/frps

# Create index.html in client1 ##############################################
cat > client1/html/test1/index.html <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>Test Page</title>
</head>
<body>
    <h1>Hello from client1/test1 ! </h1>
</body>
</html>
EOF

# Create client1 nginx.conf ##############################################
cat > client1/nginx/nginx.conf <<EOF
worker_processes  1;

events {
}

http {
    include       mime.types;
    default_type  application/octet-stream;

    sendfile        on;

    server {
        listen 80;
        location /test1/ {
            root /usr/share/nginx/html;
            index index.html;
        }
    }
}
EOF

# Create client1 docker-compose.yaml #####################################
cat > client1/docker-compose.yaml <<EOF
services:
  web:
    image: nginx:alpine
    volumes:
      - ./html:/usr/share/nginx/html:ro
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
    restart: always
    networks:
      - frpc_net

  frpc:
    image: snowdreamtech/frpc:0.61.0
    volumes:
      - ./frpc/frpc.toml:/etc/frp/frpc.toml
    restart: always
    networks:
      - frpc_net

networks:
  frpc_net:
EOF

# Create frpc config ########################################
cat > client1/frpc/frpc.toml <<EOF
serverAddr = "$DOMAIN"
serverPort = 7000

[auth]
method = "token"
token = "supersecret"

[[proxies]]
name = "test1"
type = "http"
localIP = "web"
localPort = 80
customDomains = ["$DOMAIN"]
locations = ["/test1/"]
EOF

# Create client2 directory structure ########################################
mkdir -p client2/html/test2
mkdir -p client2/frpc
mkdir -p client2/nginx

# Create index.html in client2 ##############################################
cat > client2/html/test2/index.html <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>Test Page</title>
</head>
<body>
    <h1>Hello from client2/test2 ! </h1>
</body>
</html>
EOF

# Create client2 nginx.conf ##############################################
cat > client2/nginx/nginx.conf <<EOF
worker_processes  1;

events {
}

http {
    include       mime.types;
    default_type  application/octet-stream;

    sendfile        on;

    server {
        listen 80;
        location /test2/ {
            root /usr/share/nginx/html;
            index index.html;
        }
    }
}
EOF

# Create client2 docker-compose.yaml #####################################
cat > client2/docker-compose.yaml <<EOF
services:
  web:
    image: nginx:alpine
    volumes:
      - ./html:/usr/share/nginx/html:ro
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
    restart: always
    networks:
      - frpc_net

  frpc:
    image: snowdreamtech/frpc:0.61.0
    volumes:
      - ./frpc/frpc.toml:/etc/frp/frpc.toml
    restart: always
    networks:
      - frpc_net

networks:
  frpc_net:
EOF

# Create frpc config ########################################
cat > client2/frpc/frpc.toml <<EOF
serverAddr = "$DOMAIN"
serverPort = 7000

[auth]
method = "token"
token = "supersecret"

[[proxies]]
name = "test2"
type = "http"
localIP = "web"
localPort = 80
customDomains = ["$DOMAIN"]
locations = ["/test2/"]
EOF

# Create server docker-compose.yaml #########################
cat > server/docker-compose.yaml <<EOF
services:
  nginx:
    image: nginx:alpine
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/conf.d/default.conf
      - ./nginx/certs:/etc/nginx/certs:ro
    ports:
      - "443:443"
    depends_on:
      - frps
    restart: always

  frps:
    image: snowdreamtech/frps:0.61.0
    volumes:
      - ./frps/frps.toml:/etc/frp/frps.toml
    ports:
      - "7000:7000"
      - "3000:3000"
    restart: always
EOF

# Create frps config #########################################
cat > server/frps/frps.toml <<EOF
# All ports defined in this configuration
# must also be exposed in docker-compose.yaml
# and allowed through the firewall

[common]
bindPort = 7000
token = "supersecret"
vhost_http_port = 3000
EOF

# Create server nginx config #######################################
cat > server/nginx/nginx.conf <<EOF
server {
    listen 443 ssl;
    server_name $DOMAIN;

    ssl_certificate /etc/nginx/certs/cert.pem;
    ssl_certificate_key /etc/nginx/certs/key.pem;

    location /test1/ {
        proxy_pass http://frps:3000/test1/;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

        location /test2/ {
        proxy_pass http://frps:3000/test2/;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

}
EOF
