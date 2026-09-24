#!/usr/bin/env bash
# ============================================================
# AICOS Xray Reality setup for RackNerd (Ubuntu 22.04/24.04)
# One-shot: installs Xray, Reality VLESS on 443, autostart, UFW
# Outputs VLESS string ready for Podkop (router)
# ============================================================
set -euo pipefail

IP="${1:-$(curl -4 -s ifconfig.me)}"
CAMO_DOMAIN="${2:-www.microsoft.com}"   # SNI / fallback domain (must be alive, TLS1.3, reachable from RU)

log() { echo -e "\n\033[1;36m[+] $*\033[0m"; }
die() { echo -e "\033[1;31m[!] $*\033[0m" >&2; exit 1; }

# ---------- sanity ----------
[ "$(id -u)" = "0" ] || die "Run as root (sudo su -)"
command -v curl >/dev/null || die "curl required"

log "Target IP: $IP | SNI: $CAMO_DOMAIN"

# ---------- 1. system update + tools ----------
log "Updating system..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y -qq
apt-get install -y -qq curl wget openssl jq unzip ufw >/dev/null

# ---------- 2. install Xray (official script) ----------
log "Installing Xray-core (official)..."
bash -c "$(curl -L -s https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install >/dev/null 2>&1 \
  || bash -c "$(curl -L -s https://raw.githubusercontent.com/XTLS/Xray-install/main/install-release.sh)" @ install >/dev/null
command -v xray || xray="/usr/local/bin/xray"
xray version | head -2

# ---------- 3. generate keys ----------
log "Generating Reality keys..."
UUID=$(cat /proc/sys/kernel/random/uuid)
KEYS=$(xray x25519)
PRIV=$(echo "$KEYS" | awk -F': ' '/Private/{print $2}')
PUB=$(echo "$KEYS" | awk -F': ' '/Public/{print $2}')
SHORT_ID=$(openssl rand -hex 8)

# ---------- 4. write config ----------
log "Writing /usr/local/etc/xray/config.json ..."
cat > /usr/local/etc/xray/config.json <<EOF
{
  "log": { "loglevel": "warning" },
  "inbounds": [
    {
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [
          { "id": "${UUID}", "flow": "xtls-rprx-vision" }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "dest": "${CAMO_DOMAIN}:443",
          "serverNames": [ "${CAMO_DOMAIN}" ],
          "privateKey": "${PRIV}",
          "shortIds": [ "${SHORT_ID}" ]
        }
      },
      "sniffing": { "enabled": true, "destOverride": ["http", "tls"] }
    }
  ],
  "outbounds": [
    { "protocol": "freedom", "tag": "direct" },
    { "protocol": "blackhole", "tag": "block" }
  ]
}
EOF

# ---------- 5. systemd autostart + auto-restart ----------
log "Enabling systemd service with Restart=always..."
systemctl enable xray >/dev/null 2>&1 || true
mkdir -p /etc/systemd/system/xray.service.d
cat > /etc/systemd/system/xray.service.d/restart.conf <<EOF
[Service]
Restart=always
RestartSec=5
EOF
systemctl daemon-reload
systemctl restart xray
sleep 2
systemctl is-active xray || die "xray failed to start — check /usr/local/etc/xray/config.json"

# ---------- 6. firewall ----------
log "Configuring UFW (22 + 443 only)..."
ufw allow 22/tcp >/dev/null 2>&1
ufw allow 443/tcp >/dev/null 2>&1
ufw --force enable >/dev/null 2>&1 || true
ufw status | grep -E '22|443' || true

# ---------- 7. verify + VLESS link ----------
log "Verifying TLS handshake to ${CAMO_DOMAIN}..."
curl -s -o /dev/null --max-time 8 "https://${CAMO_DOMAIN}" && echo "SNI domain OK" || echo "SNI domain NOT reachable from server — pick another one!"

VLESS="vless://${UUID}@${IP}:443?encryption=none&security=reality&sni=${CAMO_DOMAIN}&fp=chrome&type=tcp&flow=xtls-rprx-vision&pbk=${PUB}&sid=${SHORT_ID}&spx=%2F#RackNerd-US"

echo ""
echo "============================================================"
echo "  XRAY REALITY IS LIVE"
echo "============================================================"
echo "  Server IP : ${IP}"
echo "  Port      : 443 (TCP)"
echo "  SNI/Camo  : ${CAMO_DOMAIN}"
echo "  UUID      : ${UUID}"
echo "  PublicKey : ${PUB}"
echo "  ShortId   : ${SHORT_ID}"
echo "  VLESS string for Podkop:"
echo ""
echo "  ${VLESS}"
echo ""
echo "  Test on PC (v2rayN/Nekoray/v2rayNG):"
echo "  ${VLESS}"
echo "============================================================"