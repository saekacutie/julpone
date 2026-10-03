# julpone — 4-Protocol Proxy + VM Provisioners (GCP)

Two parts:

1. **Cloud Run image** — Xray serving **Trojan / VMess / VLESS / Shadowsocks**,
   each over WebSocket, HTTPUpgrade, and XHTTP (12 inbounds), behind OpenResty with
   a decoy `index.html`.
2. **GCP helpers** — `deployer.sh` menu, `ssh-vm.sh` (SSH VM), `ovpn-vm.sh` (OpenVPN VM).

```
client ──TLS──> :8080 (openresty) ──/saeka-tojirp*|/vmess-saeka*|/vless-saeka*|/ss-saeka*──> 127.0.0.1:10000-10011 (xray)
```

## Files

| File | Purpose |
|---|---|
| `Dockerfile` | openresty + pinned Xray (`ARG XRAY_VERSION`) |
| `config.json` | 12 xray inbounds (ports 10000–10011) |
| `nginx.conf` | 12 matching `location` blocks → xray |
| `index.html` | Decoy landing page |
| `deploy.sh` | Cloud Run deployer |
| `deployer.sh` | Interactive menu (4 protocols / SSH / OVPN / all) |
| `ssh-vm.sh` / `ovpn-vm.sh` | Compute Engine VM provisioners |
| `ws-bridge.py` | Standalone WS→TCP bridge helper (port 2223 → target) |
| `requirements.txt` | `websockets>=13` (for `ws-bridge.py`) |

## Deploy the Cloud Run image

```bash
chmod +x deploy.sh
./deploy.sh
```

## Security notes

- `ssh-vm.sh` / `ovpn-vm.sh` generate strong passwords at runtime (override with
  `PASSWORD` / `OVPN_PASSWORD` env vars) — never commit credentials.
- The bundled Xray version is pinned via `ARG XRAY_VERSION`; bump it deliberately.
