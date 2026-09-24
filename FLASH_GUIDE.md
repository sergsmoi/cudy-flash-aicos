# Полный гайд прошивки Cudy WR3000S на OpenWrt 24.10.8

## Этап 0. Подготовка

1. Проверь ревизию (наклейка снизу). SN 2543+ — только 24.10.5+.
2. Скачай файлы (см. README — источники)
3. Подготовь VPS (см. scripts/server-setup-xray.sh)

## Этап 1. Сток Cudy → Переходная OpenWrt

**Сток:** 192.168.10.1 (user admin, пароль Admin12345)  
**Для Cudy 2.5.30+:** RSA-OAEP логин (nonce + salt + публичный ключ)  
**Upload:** поле `cbid.upgrade.1.firmware.upload=true`, файл `cudy_wr3000s-v1-sysupgrade_20251119.bin`  
**Confirm:** кнопка `cbid.upgrade.1.proceed`  
**Apply:** GET `/cgi-bin/luci/admin/system/reboot/apply?upgrade=true`

## Этап 2. Переходная (OpenWrt 23.05) → Финальная 24.10.8

**IP:** 192.168.1.1 (может конфликтовать с другим роутером)  
**Логин:** root / пустой (через веб, не SSH)  
**Flash:** System → Backup/Flash Firmware → upload `openwrt-24.10.8-squashfs-sysupgrade.bin`  
Сними галочку "Keep settings".

## Этап 3. Настройка Xray + прозрачное прокси

После первой загрузки OpenWrt 24.10.8:
1. Смени LAN подсеть (uci set network.lan.ipaddr='192.168.55.1')
2. Установи Xray (opkg install xray-core) и обнови до 26.3.27
3. Настрой конфиг (config/xray-router.json)
4. Настрой iptables TPROXY (IPTABLES.md)
5. Настрой Wi-Fi

## Важно!
- TPROXY только для FORWARD (клиентские устройства). OUTPUT трафик не обрабатывается.
- TUN-режим Xray НЕ ИСПОЛЬЗУЙ — отрезает SSH.
- Xray на OpenWrt слушает IPv6 по умолчанию — добавь "listen":"0.0.0.0".
- RackNerd 443 проходит, 8443 блокируется Ростелекомом.
