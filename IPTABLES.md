# TPROXY правила для прозрачного прокси

```bash
iptables -t mangle -F PREROUTING 2>/dev/null
iptables -t mangle -A PREROUTING -i br-lan -p tcp --dport 22 -j RETURN
iptables -t mangle -A PREROUTING -i br-lan -p tcp -j TPROXY --tproxy-mark 0x1/0x1 --on-port 12345
ip rule add fwmark 1 lookup 100 2>/dev/null
ip route add local 0.0.0.0/0 dev lo table 100 2>/dev/null
```

Важно: TPROXY только в PREROUTING (FORWARD трафик).  
OUTPUT трафик не обрабатывается — для диагностики используй curl --socks5.
