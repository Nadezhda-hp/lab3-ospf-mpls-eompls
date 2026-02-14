# ============================================================
# Конфигурация роутера R01.HKI (Хельсинки)
# Лабораторная работа №3 — OSPF, MPLS, EoMPLS
# ============================================================
# Транзитный роутер в Хельсинки. Часть верхнего пути:
# NY → LND → HKI → SPB.
#
# Интерфейсы:
#   ether1 — канал до Лондона (R01.LND)
#   ether2 — канал до Санкт-Петербурга (R01.SPB)
# ============================================================

# --- Установка имени ---
/system identity set name=R01.HKI

# --- Смена пароля ---
/user set [find name=admin] password=admin

# --- Loopback-интерфейс ---
/interface bridge add name=loopback
/ip address add address=10.10.10.4/32 interface=loopback

# --- IP-адреса ---
/ip address
add address=10.10.2.2/30 interface=ether1 comment="Канал до R01.LND"
add address=10.10.3.1/30 interface=ether2 comment="Канал до R01.SPB"

# --- OSPF ---
/routing ospf instance
set default router-id=10.10.10.4

/routing ospf network
add area=backbone network=10.10.2.0/30
add area=backbone network=10.10.3.0/30
add area=backbone network=10.10.10.4/32

# --- MPLS LDP ---
/mpls ldp
set enabled=yes transport-address=10.10.10.4 lsr-id=10.10.10.4

/mpls ldp interface
add interface=ether1
add interface=ether2
