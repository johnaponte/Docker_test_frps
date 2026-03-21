# Docker_test_frps
Tests for Fast Reverse Proxy (FRP) configurations.

## test_tls_in_vps_1
Configuration where TLS termination occurs on the VPS, and routes are redirected to internal clients.

## test_tls_in_vps_2
Configuration where TLS termination occurs on the VPS, and domain-based redirection is used to route traffic to internal clients.

## test_tls_in_client_1
Configuration where TLS termination occurs on each client. Each client must have a unique domain pointing to the VPS.

## test_tls_in_client_2
Configuration where TLS termination occurs on a single internal proxy, which redirects both domains and routes to the internal clients.
