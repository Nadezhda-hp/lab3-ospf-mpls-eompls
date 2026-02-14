# ============================================================
# Конфигурация роутера R01.MSK (Москва)
# Лабораторная работа №3 — OSPF, MPLS, EoMPLS
# ============================================================
# Транзитный роутер в Москве. Часть нижнего пути:
# LND → LBN → MSK → SPB.
#
# Интерфейсы:
#   ether1 — канал до Любляны (R01.LBN)
#   ether2 — канал до Санкт-Петербурга (R01.SPB)
# ============================================================

# --- Установка имени ---
/system identity set name=R01.MSK

# --- Смена пароля ---
/user set [find name=admin] password=admin

# --- Loopback-интерфейс ---
/interface bridge add name=loopback
/ip address add address=10.10.10.5/32 interface=loopback

# --- IP-адреса ---
/ip address
add address=10.10.5.2/30 interface=ether1 comment="Канал до R01.LBN"
add address=10.10.6.1/30 interface=ether2 comment="Канал до R01.SPB"

# --- OSPF ---
/routing ospf instance
set default router-id=10.10.10.5

/routing ospf network
add area=backbone network=10.10.5.0/30
add area=backbone network=10.10.6.0/30
add area=backbone network=10.10.10.5/32

# --- MPLS LDP ---
/mpls ldp
set enabled=yes transport-address=10.10.10.5 lsr-id=10.10.10.5

/mpls ldp interface
add interface=ether1
add interface=ether2
