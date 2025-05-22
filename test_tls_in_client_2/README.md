# Exposing Internal Services with FRP and Per-Client NGINX + TLS Using Multiple External Domains

This project demonstrates how to expose two internal web servers (clients) to the internet using [Fast Reverse Proxy (FRP)](https://github.com/fatedier/frp). Each client terminates TLS traffic using its own NGINX container and domain name. The FRP server runs on a remote VPS and simply forwards traffic based on domain routing.

---

## 🔧 Project Overview

This project simulates two local clients (Client 1 and Client 2), each identified by its own domain name (e.g., `yourdomain1.com` and `yourdomain2.com`). These services are made publicly accessible through an FRP server running on a remote VPS. Each client includes its own NGINX reverse proxy configured for TLS termination, isolating TLS handling from the central server.

---

## 🔧 Configure DNS

You must set up two domain names and point both to the same VPS IP address:

```
yourdomain1.com.  IN  A  <your-vps-ip>
yourdomain2.com.  IN  A  <your-vps-ip>
```

---

## 🚀 Setup Instructions

### 1. Customize the Domain

Run the setup script and provide your two domain names:

```bash
./project_template.sh --domain1 yourdomain1.com --domain2 yourdomain2.com
```

---

### 2. TLS Certificates

Each client has its own TLS-terminating NGINX proxy. You must place valid TLS certificates in the appropriate directory:

```
client1/nginx_tls/certs/cert.pem
client1/nginx_tls/certs/key.pem

client2/nginx_tls/certs/cert.pem
client2/nginx_tls/certs/key.pem
```

Certificates can be obtained from Let's Encrypt or another Certificate Authority.

---

### 3. Deploy the FRP Server to VPS

Upload the `server/` directory to your VPS and start the FRP server:

```bash
rsync -avz server/ user@your-vps-ip:/path/on/vps
ssh user@your-vps-ip
cd /path/on/vps/server
docker compose up -d
```

Ensure the following ports are reachable on the VPS:
- `7000` for FRP communication
- `443` for HTTPS access

---

### 4. Run Local Clients

Each client has its own Docker Compose setup:

```bash
cd client1
docker compose up -d

cd ../client2
docker compose up -d
```

---

## ✅ Test the Setup

- `https://yourdomain1.com` → Should serve Client 1's HTML page.
- `https://yourdomain2.com` → Should serve Client 2's HTML page.

---

## 🔐 Security Notes

- TLS is terminated individually by each client's NGINX.
- FRP uses token authentication (`supersecret` by default).
- Update the token in both server and clients for production deployments.
- No TLS encryption is enforced between the FRP server and clients beyond the client's own TLS layer.

---

## 📚 Technologies Used

- [FRP](https://github.com/fatedier/frp)
- [NGINX](https://nginx.org/)
- [Docker Compose](https://docs.docker.com/compose/)
- TLS certificates (user-provided)

---

## 🧪 Demo Behavior

Each client serves a standalone HTML page over HTTPS using its own NGINX TLS proxy. FRP routes public traffic based on the domain name to the correct client.

---

## ⚠️ Disclaimer

This setup is intended for development or demo purposes. It is not hardened for production use.