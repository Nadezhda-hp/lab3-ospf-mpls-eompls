# ============================================================
# Конфигурация роутера R01.SPB (Санкт-Петербург)
# Лабораторная работа №3 — OSPF, MPLS, EoMPLS
# ============================================================
# Роутер в Санкт-Петербурге. К нему подключён ПК инженеров (PC1).
# Через EoMPLS-туннель этот ПК соединяется с SGI Prism
# в Нью-Йорке (через R01.NY).
#
# Интерфейсы:
#   ether1 — канал до Хельсинки (R01.HKI), верхний путь
#   ether2 — канал до Москвы (R01.MSK), нижний путь
#   ether3 — подключение PC1 (пойдёт в EoMPLS-мост)
# ============================================================

# --- Установка имени ---
/system identity set name=R01.SPB

# --- Смена пароля ---
/user set [find name=admin] password=admin

# --- Loopback-интерфейс ---
/interface bridge add name=loopback
/ip address add address=10.10.10.6/32 interface=loopback

# --- IP-адреса на магистральных интерфейсах ---
# (на ether3 IP не ставим — он будет в EoMPLS-мосте)
/ip address
add address=10.10.3.2/30 interface=ether1 comment="Канал до R01.HKI (верхний путь)"
add address=10.10.6.2/30 interface=ether2 comment="Канал до R01.MSK (нижний путь)"

# --- OSPF ---
/routing ospf instance
set default router-id=10.10.10.6

/routing ospf network
add area=backbone network=10.10.3.0/30
add area=backbone network=10.10.6.0/30
add area=backbone network=10.10.10.6/32

# --- MPLS LDP ---
/mpls ldp
set enabled=yes transport-address=10.10.10.6 lsr-id=10.10.10.6

/mpls ldp interface
add interface=ether1
add interface=ether2

# --- Настройка EoMPLS ---
# Зеркальная настройка к R01.NY.
# Создаём VPLS-туннель до R01.NY и объединяем с ether3 (PC1) в мост.

# Шаг 1: VPLS-интерфейс до R01.NY
# remote-peer = loopback R01.NY, vpls-id должен совпадать с R01.NY
/interface vpls
add name=EoMPLS_to_NY remote-peer=10.10.10.1 vpls-id=42:0 disabled=no

# Шаг 2: Мост для EoMPLS
# Объединяем ether3 (к PC1) и VPLS-туннель в один broadcast-домен
/interface bridge add name=EoMPLS_bridge

/interface bridge port
add bridge=EoMPLS_bridge interface=ether3
add bridge=EoMPLS_bridge interface=EoMPLS_to_NY
