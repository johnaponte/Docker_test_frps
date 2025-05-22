#!/bin/bash

set -e

# ------------------------- Ensure shared Docker network exists -------------------------
docker network inspect frp_shared >/dev/null 2>&1 || docker network create frp_shared

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

# ------------------------------ Set up server ------------------------------------------
# Create server directory structure
mkdir -p server/frps

# Create server docker-compose.yaml
cat > server/docker-compose.yaml <<EOF
services:
  frps:
    image: snowdreamtech/frps:0.61.0
    volumes:
      - ./frps/frps.toml:/etc/frp/frps.toml
    ports:
      - "7000:7000"
      - "443:443"
    restart: always
EOF

# Create server frps config
cat > server/frps/frps.toml <<EOF
# All ports defined in this configuration
# must also be exposed in docker-compose.yaml
# and allowed through the firewall

[common]
bindPort = 7000
token = "supersecret"
vhost_https_port = 443
EOF

# --------------------------- Set up proxy container -------------------------------------
# Create proxy directory structure
mkdir -p proxy/frpc
mkdir -p proxy/nginx_tls
mkdir -p proxy/nginx_tls/certs

# Create proxy docker-compose.yaml
cat > proxy/docker-compose.yaml <<EOF
services:
  frpc:
    image: snowdreamtech/frpc:0.61.0
    volumes:
      - ./frpc/frpc.toml:/etc/frp/frpc.toml
    restart: always
    networks:
      frpc_net:

  nginx_tls:
    image: nginx:alpine
    volumes:
      - ./nginx_tls/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx_tls/certs:/etc/nginx/certs:ro
    ports:
      - "443:443"
    restart: always
    networks:
      frpc_net:

networks:
  frpc_net:
    external: true
    name: frp_shared
EOF

# Create proxy frpc config
cat > proxy/frpc/frpc.toml <<EOF
serverAddr = "$DOMAIN1"
serverPort = 7000

[auth]
method = "token"
token = "supersecret"

[[proxies]]
name = "Domain1"
type = "https"
localIP = "nginx_tls"
localPort = 443
customDomains = ["$DOMAIN1"]

[[proxies]]
name = "Domain2"
type = "https"
localIP = "nginx_tls"
localPort = 443
customDomains = ["$DOMAIN2"]
EOF

# Create proxy nginx_tls/nginx.conf
cat > proxy/nginx_tls/nginx.conf <<EOF
worker_processes  1;

events {
}

http {
    include       mime.types;
    default_type  application/octet-stream;

    sendfile        on;

    server {
        listen 443 ssl;
        server_name $DOMAIN1;

        ssl_certificate /etc/nginx/certs/cert.pem;
        ssl_certificate_key /etc/nginx/certs/key.pem;

        location /test1/ {
            # With redirection to client1/
            proxy_pass http://client1/;
            proxy_http_version 1.1;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
            rewrite ^/test1/(.*)\$ /\$1 break;
        }

        location /test2/ {
            # Without redirection. Client2 should match test2 directory
            proxy_pass http://client2/test2/;
            proxy_http_version 1.1;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }

    server {
        listen 443 ssl;
        server_name $DOMAIN2;

        ssl_certificate /etc/nginx/certs/cert.pem;
        ssl_certificate_key /etc/nginx/certs/key.pem;

        location / {
            # A different domain
            proxy_pass http://client3/;
            proxy_http_version 1.1;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }
}
EOF

# ----------------------------- Set up client1 ------------------------------------------
# Create client1 directory structure
mkdir -p client1/web/html

# Create client1 index.html
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

# Create client1 web nginx.conf
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

# Create client1 docker-compose.yaml
cat > client1/docker-compose.yaml <<EOF
services:
  client1:
    image: nginx:alpine
    volumes:
      - ./web/html:/usr/share/nginx/html:ro
      - ./web/nginx.conf:/etc/nginx/nginx.conf:ro
    restart: always
    networks:
      frpc_net:

networks:
  frpc_net:
    external: true
    name: frp_shared
EOF

# ----------------------------- Set up client2 ------------------------------------------
# Create client2 directory structure
mkdir -p client2/web/html/test2

# Create index.html in client2
cat > client2/web/html/test2/index.html <<EOF
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

# Create client2 web nginx.conf
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

# Create client2 docker-compose.yaml
cat > client2/docker-compose.yaml <<EOF
services:
  client2:
    image: nginx:alpine
    volumes:
      - ./web/html:/usr/share/nginx/html:ro
      - ./web/nginx.conf:/etc/nginx/nginx.conf:ro
    restart: always
    networks:
      frpc_net:

networks:
  frpc_net:
    external: true
    name: frp_shared
EOF

# ----------------------------- Set up client3 ------------------------------------------
# Create client3 directory structure
mkdir -p client3/web/html

# Create index.html in client3
cat > client3/web/html/index.html <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>Test Page</title>
</head>
<body>
    <h1>Hello from client3/ ! </h1>
</body>
</html>
EOF

# Create client3 web nginx.conf
cat > client3/web/nginx.conf <<EOF
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

# Create client3 docker-compose.yaml
cat > client3/docker-compose.yaml <<EOF
services:
  client3:
    image: nginx:alpine
    volumes:
      - ./web/html:/usr/share/nginx/html:ro
      - ./web/nginx.conf:/etc/nginx/nginx.conf:ro
    restart: always
    networks:
      frpc_net:

networks:
  frpc_net:
    external: true
    name: frp_shared
EOF

echo "✅ Project successfully created for domains: $DOMAIN1 and $DOMAIN2"
echo "🔐 Remember to place your TLS certificates (cert.pem and key.pem) in:"
echo "  - proxy/nginx_tls/certs/ for both $DOMAIN1 and $DOMAIN2"
