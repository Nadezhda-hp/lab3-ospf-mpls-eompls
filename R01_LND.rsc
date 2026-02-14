# ============================================================
# Конфигурация роутера R01.LND (Лондон)
# Лабораторная работа №3 — OSPF, MPLS, EoMPLS
# ============================================================
# Транзитный роутер в Лондоне. Через него проходит трафик
# по двум путям: верхнему (LND → HKI) и нижнему (LND → LBN).
# Это ключевой узел — он связывает Нью-Йорк с остальной сетью.
#
# Интерфейсы:
#   ether1 — канал до Нью-Йорка (R01.NY)
#   ether2 — канал до Хельсинки (R01.HKI), верхний путь
#   ether3 — канал до Любляны (R01.LBN), нижний путь
# ============================================================

# --- Установка имени ---
/system identity set name=R01.LND

# --- Смена пароля ---
/user set [find name=admin] password=admin

# --- Loopback-интерфейс ---
/interface bridge add name=loopback
/ip address add address=10.10.10.2/32 interface=loopback

# --- IP-адреса на интерфейсах ---
/ip address
add address=10.10.1.2/30 interface=ether1 comment="Канал до R01.NY"
add address=10.10.2.1/30 interface=ether2 comment="Канал до R01.HKI (верхний путь)"
add address=10.10.4.1/30 interface=ether3 comment="Канал до R01.LBN (нижний путь)"

# --- OSPF ---
# Объявляем все подключённые сети в backbone area.
# OSPF сам построит маршруты ко всем удалённым сетям.
/routing ospf instance
set default router-id=10.10.10.2

/routing ospf network
add area=backbone network=10.10.1.0/30
add area=backbone network=10.10.2.0/30
add area=backbone network=10.10.4.0/30
add area=backbone network=10.10.10.2/32

# --- MPLS LDP ---
# Включаем LDP на всех магистральных интерфейсах.
# Через эти интерфейсы будут распространяться MPLS-метки.
/mpls ldp
set enabled=yes transport-address=10.10.10.2 lsr-id=10.10.10.2

/mpls ldp interface
add interface=ether1
add interface=ether2
add interface=ether3
