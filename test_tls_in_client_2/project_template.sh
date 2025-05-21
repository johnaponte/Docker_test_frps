#!/bin/bash

set -e

# Default domains
DOMAIN1="yourdomain1.com"
DOMAIN2="yourdomain2.com"

# Parse arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --domain1) DOMAIN1="$2"; shift ;;
    --domain2) DOMAIN2="$2"; shift ;;
    *) echo "Unknown parameter passed: $1"; exit 1 ;;
  esac
  shift
done

# Set up server ################################################################

# Create server directory structure ################################################
mkdir -p server/frps

# Create server docker-compose.yaml ################################################
cat > server/docker-compose.yaml <<EOF
services:
  frps:
    image: snowdreamtech/frps:0.61.0
    volumes:
      - ./frps/frps.toml:/etc/frp/frps.toml
    ports:
      - "7000:7000"
      - "3000:3000"
      - "443:443"
    restart: always
EOF

# Create server frps config ########################################################
cat > server/frps/frps.toml <<EOF
# All ports defined in this configuration
# must also be exposed in docker-compose.yaml
# and allowed through the firewall

[common]
bindPort = 7000
token = "supersecret"
vhost_https_port = 443
EOF

# Set up client1 ###############################################################

# Create client1 directory structure ###############################################
mkdir -p client1/web/html
mkdir -p client1/frpc
mkdir -p client1/web
mkdir -p client1/nginx_tls
mkdir -p client1/nginx_tls/certs

# Create client1 index.html in client1 ####################################################
cat > client1/web/html/index.html <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>Test Page</title>
</head>
<body>
    <h1>Hello from client1/ ! </h1>
</body>
</html>
EOF

 # Create client1 web nginx.conf ####################################################
cat > client1/web/nginx.conf <<EOF
worker_processes  1;

events {
}

http {
    include       mime.types;
    default_type  application/octet-stream;

    sendfile        on;

    server {
        listen 80;
        location / {
            root /usr/share/nginx/html/;
            index index.html;
        }
    }
}
EOF

 # Create client1 nginx_tls/nginx.conf #############################################
cat > client1/nginx_tls/nginx.conf <<EOF
worker_processes  1;

events {
}

http {
    include       mime.types;
    default_type  application/octet-stream;

    sendfile        on;

    server {
        listen 8443 ssl;
        server_name $DOMAIN1;

        ssl_certificate /etc/nginx/certs/cert.pem;
        ssl_certificate_key /etc/nginx/certs/key.pem;

        location / {
            proxy_pass http://web/;
            proxy_http_version 1.1;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }
}
EOF

 # Create client1 docker-compose.yaml ##############################################
cat > client1/docker-compose.yaml <<EOF
services:
  web:
    image: nginx:alpine
    volumes:
      - ./web/html:/usr/share/nginx/html:ro
      - ./web/nginx.conf:/etc/nginx/nginx.conf:ro
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

  nginx_tls:
    image: nginx:alpine
    volumes:
      - ./nginx_tls/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx_tls/certs:/etc/nginx/certs:ro
    ports:
      - "8443:8443"
    restart: always
    networks:
      - frpc_net

networks:
  frpc_net:
EOF

 # Create client1 frpc config ##############################################################
cat > client1/frpc/frpc.toml <<EOF
serverAddr = "$DOMAIN1"
serverPort = 7000

[auth]
method = "token"
token = "supersecret"

[[proxies]]
name = "test1"
type = "https"
localIP = "nginx_tls"
localPort = 8443
customDomains = ["$DOMAIN1"]
EOF

# Set up client2 ###############################################################

# Create client2 directory structure ##############################################
mkdir -p client2/web/html
mkdir -p client2/frpc
mkdir -p client2/web
mkdir -p client2/nginx_tls
mkdir -p client2/nginx_tls/certs

# Create index.html in client2 ####################################################
cat > client2/web/html/index.html <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>Test Page</title>
</head>
<body>
    <h1>Hello from client2/ ! </h1>
</body>
</html>
EOF

 # Create client2 web nginx.conf ####################################################
cat > client2/web/nginx.conf <<EOF
worker_processes  1;

events {
}

http {
    include       mime.types;
    default_type  application/octet-stream;

    sendfile        on;

    server {
        listen 80;
        location / {
            root /usr/share/nginx/html;
            index index.html;
        }
    }
}
EOF

 # Create client2 nginx_tls/nginx.conf #############################################
cat > client2/nginx_tls/nginx.conf <<EOF
worker_processes  1;

events {
}

http {
    include       mime.types;
    default_type  application/octet-stream;

    sendfile        on;

    server {
        listen 8444 ssl;
        server_name $DOMAIN2;

        ssl_certificate /etc/nginx/certs/cert.pem;
        ssl_certificate_key /etc/nginx/certs/key.pem;

        location / {
            proxy_pass http://web/;
            proxy_http_version 1.1;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }
}
EOF

 # Create client2 docker-compose.yaml ##############################################
cat > client2/docker-compose.yaml <<EOF
services:
  web:
    image: nginx:alpine
    volumes:
      - ./web/html:/usr/share/nginx/html:ro
      - ./web/nginx.conf:/etc/nginx/nginx.conf:ro
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

  nginx_tls:
    image: nginx:alpine
    volumes:
      - ./nginx_tls/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx_tls/certs:/etc/nginx/certs:ro
    ports:
      - "8444:8444"
    restart: always
    networks:
      - frpc_net

networks:
  frpc_net:
EOF

 # Create client2 frpc config ##############################################################

cat > client2/frpc/frpc.toml <<EOF
serverAddr = "$DOMAIN2"
serverPort = 7000

[auth]
method = "token"
token = "supersecret"

[[proxies]]
name = "test2"
type = "https"
localIP = "nginx_tls"
localPort = 8444
customDomains = ["$DOMAIN2"]

EOF

echo "✅ Project successfully created for domains: $DOMAIN1 and $DOMAIN2"
echo "🔐 Remember to place your TLS certificates (cert.pem and key.pem) in:"
echo "  - client1/nginx_tls/certs/ for $DOMAIN1"
echo "  - client2/nginx_tls/certs/ for $DOMAIN2"
