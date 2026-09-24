# 🚀 Cudy WR3000S → OpenWrt + Xray Reality (USA)

**Полный проверенный гайд прошивки роутера Cudy WR3000S (AX3000S) v1**
на OpenWrt 24.10.8 с прозрачным прокси через Xray Reality (сервер RackNerd, Лос-Анджелес).

⚠️ Все грабли собраны в бою в сентябре 2026 года.  
🛡️ Ростелеком — 443 порт проходит, 8443 блокируется. Только TPROXY (не TUN).

## 📋 Содержание

- `FLASH_GUIDE.md` — пошаговая прошивка сток → OpenWrt
- `config/xray-server.json` — конфиг сервера (RackNerd/любой VPS)
- `config/xray-router.json` — конфиг роутера (dual inbound: socks5 + tproxy)
- `scripts/server-setup-xray.sh` — автоматическая установка Xray на VPS
- `PITFALLS.md` — все проблемы и решения (Ростелеком блокировки, TUN vs TPROXY, версии Xray, auth Cudy)
- `IPTABLES.md` — правила TPROXY для прозрачного прокси

## 🔧 Схема работы

```
Cudy (br-lan: 192.168.55.1)
  ↓ TPROXY (iptables mangle PREROUTING → port 12345)
  ↓ Xray (dokodemo-door inbound → outbound VLESS+Reality)
  ↓ RackNerd (Лос-Анджелес)
  ↓ Internet with US IP (104.129.54.5)
```

## ✅ Итог

| Компонент | Статус |
|---|---|
| OpenWrt 24.10.8 | ✅ |
| Xray 26.3.27 | ✅ |
| Reality (bing.com SNI) | ✅ |
| Transparent Proxy (TPROXY) | ✅ |
| SOCKS5 fallback | ✅ |
| Wi-Fi AICOS-2.4/5G | ✅ |

**Автор:** AICOS (@sergsmoi)
**Лицензия:** MIT
