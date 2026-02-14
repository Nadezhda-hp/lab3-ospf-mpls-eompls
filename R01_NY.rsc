# ============================================================
# Конфигурация роутера R01.NY (Нью-Йорк)
# Лабораторная работа №3 — OSPF, MPLS, EoMPLS
# ============================================================
# Роутер в Нью-Йоркском офисе. К нему подключён сервер
# "SGI Prism" с исходниками компьютерной графики.
# Через EoMPLS-туннель этот сервер соединяется с ПК
# инженеров в Санкт-Петербурге (через R01.SPB).
#
# Интерфейсы:
#   ether1 — канал до Лондона (R01.LND), IP/MPLS магистраль
#   ether2 — подключение SGI Prism (пойдёт в EoMPLS-мост)
#   loopback — виртуальный интерфейс для OSPF и MPLS
# ============================================================

# --- Установка имени устройства ---
/system identity set name=R01.NY

# --- Смена пароля ---
/user set [find name=admin] password=admin

# --- Создание loopback-интерфейса ---
# Loopback — это виртуальный интерфейс, который всегда "поднят".
# Он используется как Router-ID для OSPF и как transport-address для MPLS LDP.
# Создаём его как bridge без портов (стандартный приём в MikroTik).
/interface bridge add name=loopback
/ip address add address=10.10.10.1/32 interface=loopback

# --- Настройка IP-адресов на физических интерфейсах ---
# ether1 — магистральный канал до R01.LND
# (на ether2 IP не ставим — он будет в EoMPLS-мосте)
/ip address
add address=10.10.1.1/30 interface=ether1 comment="Магистраль до R01.LND"

# --- Настройка OSPF ---
# OSPF — протокол динамической маршрутизации. Он автоматически
# находит соседей и строит таблицу маршрутов ко всем сетям.
# Все сети объявляем в area backbone (area 0) — основную зону OSPF.
/routing ospf instance
set default router-id=10.10.10.1

/routing ospf network
add area=backbone network=10.10.1.0/30
add area=backbone network=10.10.10.1/32

# --- Настройка MPLS LDP ---
# MPLS — технология быстрой коммутации пакетов по меткам.
# LDP (Label Distribution Protocol) — протокол, который
# автоматически раздаёт метки между соседними роутерами.
# transport-address — адрес, с которого устанавливаются LDP-сессии.
# lsr-id — уникальный идентификатор роутера в MPLS-домене.
/mpls ldp
set enabled=yes transport-address=10.10.10.1 lsr-id=10.10.10.1

# Включаем LDP на магистральном интерфейсе
/mpls ldp interface
add interface=ether1

# --- Настройка EoMPLS ---
# EoMPLS (Ethernet over MPLS) — туннель, который прозрачно
# передаёт Ethernet-кадры через MPLS-сеть. Это позволяет
# SGI Prism и PC1 в Петербурге "видеть" друг друга,
# как будто они подключены к одному коммутатору.

# Шаг 1: Создаём VPLS-интерфейс (виртуальный провод до R01.SPB)
# remote-peer — loopback-адрес удалённого роутера R01.SPB
# vpls-id — уникальный идентификатор туннеля (должен совпадать на обоих концах)
/interface vpls
add name=EoMPLS_to_SPB remote-peer=10.10.10.6 vpls-id=42:0 disabled=no

# Шаг 2: Создаём мост (bridge) для объединения SGI Prism с туннелем
# В этот мост добавляем: ether2 (к SGI Prism) + VPLS-интерфейс
/interface bridge add name=EoMPLS_bridge

/interface bridge port
add bridge=EoMPLS_bridge interface=ether2
add bridge=EoMPLS_bridge interface=EoMPLS_to_SPB
