# ============================================================
# Конфигурация роутера R01.LBN (Любляна)
# Лабораторная работа №3 — OSPF, MPLS, EoMPLS
# ============================================================
# Транзитный роутер в Любляне. Часть нижнего пути:
# LND → LBN → MSK → SPB.
# Просто пропускает через себя трафик и MPLS-метки.
#
# Интерфейсы:
#   ether1 — канал до Лондона (R01.LND)
#   ether2 — канал до Москвы (R01.MSK)
# ============================================================

# --- Установка имени ---
/system identity set name=R01.LBN

# --- Смена пароля ---
/user set [find name=admin] password=admin

# --- Loopback-интерфейс ---
/interface bridge add name=loopback
/ip address add address=10.10.10.3/32 interface=loopback

# --- IP-адреса ---
/ip address
add address=10.10.4.2/30 interface=ether1 comment="Канал до R01.LND"
add address=10.10.5.1/30 interface=ether2 comment="Канал до R01.MSK"

# --- OSPF ---
/routing ospf instance
set default router-id=10.10.10.3

/routing ospf network
add area=backbone network=10.10.4.0/30
add area=backbone network=10.10.5.0/30
add area=backbone network=10.10.10.3/32

# --- MPLS LDP ---
/mpls ldp
set enabled=yes transport-address=10.10.10.3 lsr-id=10.10.10.3

/mpls ldp interface
add interface=ether1
add interface=ether2
