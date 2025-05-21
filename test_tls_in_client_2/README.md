# Exposing Internal Services with FRP and NGINX + TLS Using Multiple External Domains

This is a demonstration project that shows how to expose two internal web servers to the internet using [Fast Reverse Proxy (FRP)](https://github.com/fatedier/frp), running behind an NGINX reverse proxy with TLS termination on a Virtual Private Server (VPS).
---

## 🔧 Project Overview

The project simulates two local clients (Client 1 and Client 2), each identified by its own domain name (e.g., `client1.example.com` and `client2.example.com`). These services are made publicly accessible through an FRP server running on a remote VPS. The VPS is also running NGINX to handle TLS and route traffic based on the domain name.

---

## 🔧 Configure DNS

You must set up two domain names (e.g., `yourdomain1.com` and `yourdomain2.com`) and point both of them to the same VPS IP address using A records:

```
yourdomain1.com.  IN  A  <your-vps-ip>
yourdomain2.com.  IN  A  <your-vps-ip>
```

This step must be completed at your domain registrar or DNS hosting provider.

---

## 🚀 Setup Instructions

### 1. Customize the Domain

The script uses placeholder domains `yourdomain1.com` and `yourdomain2.com`. You must replace these with real domains that both point to your VPS.

When executing the script, you can pass the domains as parameters:

```bash
./project_template.sh --domain1 yourdomain1.com --domain2 yourdomain2.com
```

---

### 2. TLS Certificates

You must provide valid TLS certificates for your domain and place them in the `certs/` directory located at:

```
server/nginx/certs/cert.pem
server/nginx/certs/key.pem
```

You can obtain free certificates using [Let's Encrypt](https://letsencrypt.org/) or any trusted CA.  
This setup assumes both domains are covered by the same TLS certificate (e.g., a SAN or wildcard certificate). If using separate certificates, adjust the NGINX configuration accordingly.

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

Each client has its own `docker-compose.yaml` file and can be run independently:

```bash
cd client1
docker compose up -d

cd ../client2
docker compose up -d
```

> ✅ Once both clients are running, you can test the setup by visiting:
>
> - `https://yourdomain1.com` → Should show Client 1's page
> - `https://yourdomain2.com` → Should show Client 2's page

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

Each client serves a simple HTML page, accessible securely over the internet via a TLS-protected NGINX reverse proxy and FRP tunnel routing.

---

## ⚠️ Disclaimer

This project is intended for demonstration and educational purposes only. It is not hardened for production. Use at your own risk.