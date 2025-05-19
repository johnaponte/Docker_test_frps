# Exposing Internal Services with FRP and NGINX + TLS

This is a demonstration project that shows how to expose two internal web servers to the internet using [Fast Reverse Proxy (FRP)](https://github.com/fatedier/frp), running behind an NGINX reverse proxy with TLS termination on a VPS.

---

## 🔧 Project Overview

The project simulates two local clients (`client1` and `client2`), each running a web service (`/test1/` and `/test2/` respectively). These services are made publicly accessible via a FRP server running in a remote VPS. The VPS is also running NGINX to handle TLS and route traffic based on path.

---

## 🗂 Structure

After running the provided script, the following structure will be created:

```
.
├── client1/
│   ├── docker-compose.yaml
│   ├── frpc/
│   │   └── frpc.toml
│   ├── html/
│   │   └── test1/index.html
│   └── nginx/
│       └── nginx.conf
├── client2/
│   ├── docker-compose.yaml
│   ├── frpc/
│   │   └── frpc.toml
│   ├── html/
│   │   └── test2/index.html
│   └── nginx/
│       └── nginx.conf
├── server/
│   ├── docker-compose.yaml
│   ├── frps/
│   │   └── frps.toml
│   └── nginx/
│       ├── nginx.conf
│       └── certs/
│           ├── cert.pem
│           └── key.pem
└── project_template.sh
```

---

## 🚀 Setup Instructions

### 1. Customize the Domain

The script uses a placeholder domain `yourdomain.com`. You must replace this with a real domain that points to your VPS.

When executing the script, you can pass the domain as a parameter:

```bash
./project_template.sh --domain yourdomain.com
```

---

### 2. TLS Certificates

You must provide valid TLS certificates for your domain and place them in:

```
server/nginx/certs/cert.pem
server/nginx/certs/key.pem
```

You can obtain free certificates using [Let's Encrypt](https://letsencrypt.org/) or any trusted CA.

---

### 3. Deploy the Server to VPS

Upload the `server/` directory to your VPS. You can use `scp` or `rsync` for this:

```bash
rsync -avz server/ user@your-vps-ip:/path/on/vps
```

> Ensure the VPS has the following ports **open and reachable**:
> - `7000` for FRP
> - `443` for HTTPS

Then, SSH into the VPS and run the server:

```bash
cd /path/on/vps/server
docker compose up -d
```

---

### 4. Run Local Clients

Each client has its own `docker-compose.yaml`. You can run them independently:

```bash
cd client1
docker compose up -d

cd ../client2
docker compose up -d
```

Each client will register a tunnel with the FRP server, exposing:

- `http://yourdomain.com/test1/` → client1
- `http://yourdomain.com/test2/` → client2

---

## 🔐 Security Notes

- All traffic is encrypted via TLS by NGINX in the VPS.
- FRP uses token authentication (`supersecret` by default in `frps.toml` and `frpc.toml`).
- Change the token in both client and server before deploying in production.
- The connection between the VPS and the clients is not encrypted.

---

## 📚 Technologies Used

- [FRP](https://github.com/fatedier/frp)
- [NGINX](https://nginx.org/)
- [Docker Compose](https://docs.docker.com/compose/)
- TLS certificates (user-provided)

---

## 🧪 Demo Behavior

Each client serves a simple HTML page, which can be accessed securely over the internet through the public domain using a TLS-protected NGINX proxy combined with FRP tunnel routing.

---

## ⚠️ Disclaimer

This project is intended for demonstration and educational purposes only. It is not hardened for production. Use at your own risk.