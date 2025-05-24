# Project Architecture: FRP and NGINX with TLS

This project implements an architecture to expose internal services to a secure external network using [FRP (Fast Reverse Proxy)](https://github.com/fatedier/frp) and NGINX with TLS. The solution is based on Docker containers and organized into three main components: the server, the internal proxy, and the clients.

## Main Components

- **Server (server):** Runs only the FRP server (`frps`), which receives incoming connections from the proxy and redirects them according to the tunnel configuration. This server does not handle TLS or HTTP routes; it simply channels the traffic to the proxy.

  This server must be hosted on a machine (for example, a VPS or public server) accessible from the Internet, as it receives incoming connections from the outside and redirects them to the proxy on the internal network.

- **Internal Proxy:** Runs the FRP client (`frpc`), which establishes a connection with the FRP server to expose the defined services. Additionally, it is connected to a Docker network called `frp_shared`, which must be shared with the clients' containers to allow name resolution between them. It also runs an NGINX service that terminates the TLS connection and redirects traffic to the corresponding client according to the defined rules.

- **Clients (client1, client2, etc.):** Run only local web services. The proxy is the one that routes the traffic to them through FRP, facilitating the secure exposure of these internal services.

## Shared External Docker Network: `frp_shared`

For the internal proxy (NGINX on the server) to correctly resolve and route to the clients' containers, all components must be connected to a common external Docker network called in this example `frp_shared`. This network allows the service names defined in each client's  `docker-compose.yaml` files to work as internal DNS hostnames, enabling communication between distributed containers.

## Service Names as Hostnames

In the `docker-compose.yaml` files, the service names act as hostnames within the `frp_shared` network. For example, if a client defines a service called `web`, the internal proxy can access this service using `web` as the hostname.

## Use of Internal Ports

Internal services can use the same port without conflict because each one is isolated in its own container and accessed through different hostnames and routes in the proxy. This allows, for example, multiple services to use port `80` internally without interfering with each other.

## Route Rewriting (Rewrite)

When the public route exposed in the NGINX proxy differs from the internal service route, the `rewrite` directive is used to properly adjust the URL. This ensures that requests arriving at a specific public path are transformed to match the structure expected by the internal service, maintaining transparency for the end user.

---

## Project Structure

The `project_template.sh` script creates the entire project structure, facilitating the organization and initial configuration of the components. --domain1 and --domain2 options allow to customize the domains for client1, client2 separate from client3

The generated directory structure is as follows:

```
project_root/
├── server/
├── proxy/
├── client1/
├── client2/
└── client3/
```

- `server/`: Runs `frps` only.
- `proxy/`: Contains `frpc` and NGINX configuration.
- `client1/`, `client2/`, `client3/`: Each runs a separate internal web service.

---

## Getting Started

### Prerequisites

- Docker installed on your machine and on your server
- Registered domain names for `domain1` and `domain2` pointing to the server machine
- TLS certificates for your domains.

### Create the Docker Network

Create the shared Docker network `frp_shared` to enable communication between proxy and clients:

```bash
docker network create frp_shared
```

### Run the Project Template Script

Use the `project_template.sh` script to generate the project structure and configuration files, specifying your domains:

```bash
./project_template.sh --domain1 yourdomain1.com --domain2 yourdomain2.com
```

### Required Open Ports in the Server

- 7000 for FRP TCP
- 443 for HTTPS

### Start the FRP Server on the Public Machine

On the server machine, start the FRP server container:

```bash
docker-compose up -d
```

### Start the Proxy and Clients Locally

On your internal network machine, start the proxy and client containers:

```bash
docker-compose -f proxy/docker-compose.yaml up -d
docker-compose -f client1/docker-compose.yaml up -d
docker-compose -f client2/docker-compose.yaml up -d
docker-compose -f client3/docker-compose.yaml up -d
```

### Note

If your TLS certificates differ between `domain1` and `domain2`, you must modify the NGINX configuration to correctly associate each certificate with its respective domain.

---

This architecture facilitates the secure and organized exposure of multiple internal services through a single entry point with TLS, leveraging the flexibility of FRP and the power of NGINX as a reverse proxy.


### Tips for redirection

**Redirection for RStudio**

```
        location = /auth-sign-in {
            return 302 /rstudio/auth-sign-in;
        }

        location = /auth-sign-out {
            return 302 /rstudio/auth-sign-out;
        }

        location = / {
            if ($http_referer ~ "^https?://[^/]+/rstudio") {
                return 302 /rstudio;
            }

            return 200 'Nothing here';
            add_header Content-Type text/plain;
        }   

        location /rstudio/ {
            proxy_pass http://rstudio:8787/;
            proxy_redirect / /rstudio/;

            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";

            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-Host $host;
            proxy_set_header X-Forwarded-Server $host;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;

            rewrite ^/rstudio$ /rstudio/ permanent;
        }
````
**Redirection for guacamole**

```
        location /rdp {
            proxy_pass http://guacamole:8080/;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-Host $host;
            proxy_set_header X-Forwarded-Server $host;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;

            rewrite ^/rdp(/.*)?$ /guacamole$1 break;
        }

```




