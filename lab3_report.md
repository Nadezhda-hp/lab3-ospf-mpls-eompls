# Лабораторная работа №3

## "Эмуляция распределённой корпоративной сети связи, настройка OSPF и MPLS, организация первого EoMPLS"

Университет: Университет ИТМО
Факультет: Инфокоммуникационных технологий
Курс: Введение в маршрутизацию

---

## Цель работы

Изучить протоколы OSPF и MPLS, механизмы организации EoMPLS.

---

## Описание

Компания "RogalKopita Games" приобрела студию "Old Games" из Нью-Йорка. На сервере "SGI Prism" в Нью-Йоркском офисе хранятся ценные исходники. Сотрудники из Санкт-Петербурга не могут приехать забрать данные. Задача — подключить Нью-Йоркский офис к общей IP/MPLS сети и организовать EoMPLS-туннель между "SGI Prism" и компьютером инженеров в Санкт-Петербурге.

---

## Схема сети

```
                    R01.LND ─────────── R01.HKI
                   /                         \
SGI Prism ── R01.NY                      R01.SPB ── PC1
                   \                         /
                    R01.LBN ─────────── R01.MSK

                   ╔═══════════════════════╗
                   ║  EoMPLS-туннель       ║
                   ║  R01.NY <═══> R01.SPB ║
                   ╚═══════════════════════╝
```

Два пути для отказоустойчивости:
- Верхний путь: NY → LND → HKI → SPB
- Нижний путь: NY → LND → LBN → MSK → SPB

---

## Таблица IP-адресации

Loopback-адреса (Router ID, MPLS transport)

| Роутер | Loopback IP | Город |
|--------|-------------|-------|
| R01.NY | 10.10.10.1/32 | Нью-Йорк |
| R01.LND | 10.10.10.2/32 | Лондон |
| R01.LBN | 10.10.10.3/32 | Любляна |
| R01.HKI | 10.10.10.4/32 | Хельсинки |
| R01.MSK | 10.10.10.5/32 | Москва |
| R01.SPB | 10.10.10.6/32 | Санкт-Петербург |

Магистральные каналы (точка-точка, /30)

| Канал | Подсеть | Роутер A | IP A | Роутер B | IP B |
|-------|---------|----------|------|----------|------|
| NY — LND | 10.10.1.0/30 | R01.NY (ether1) | .1 | R01.LND (ether1) | .2 |
| LND — HKI | 10.10.2.0/30 | R01.LND (ether2) | .1 | R01.HKI (ether1) | .2 |
| HKI — SPB | 10.10.3.0/30 | R01.HKI (ether2) | .1 | R01.SPB (ether1) | .2 |
| LND — LBN | 10.10.4.0/30 | R01.LND (ether3) | .1 | R01.LBN (ether1) | .2 |
| LBN — MSK | 10.10.5.0/30 | R01.LBN (ether2) | .1 | R01.MSK (ether1) | .2 |
| MSK — SPB | 10.10.6.0/30 | R01.MSK (ether2) | .1 | R01.SPB (ether2) | .2 |

Конечные устройства (EoMPLS, одна L2-сеть)

| Устройство | IP-адрес | Подключение |
|------------|----------|-------------|
| SGI Prism | 10.10.20.1/24 | R01.NY ether2 (EoMPLS bridge) |
| PC1 | 10.10.20.2/24 | R01.SPB ether3 (EoMPLS bridge) |

---

## Технологии, используемые в работе

OSPF (Open Shortest Path First)

OSPF — протокол динамической маршрутизации на основе состояния каналов. В отличие от статической маршрутизации (Lab 2), OSPF автоматически обнаруживает соседей, строит карту сети и рассчитывает кратчайшие пути.

Зачем нужен в этой работе: OSPF обеспечивает связность loopback-адресов между всеми роутерами. Без него MPLS LDP не сможет установить сессии.

Конфигурация: Все сети объявлены в area backbone (area 0) — единственной зоне OSPF.

MPLS (Multi-Protocol Label Switching)

MPLS — технология коммутации пакетов по меткам. Вместо анализа IP-заголовка на каждом хопе, роутеры используют короткие метки для быстрой пересылки.

LDP (Label Distribution Protocol) — автоматически раздаёт метки между соседями.

Зачем нужен: MPLS является транспортом для EoMPLS-туннеля. Без него нельзя пробросить L2-кадры через IP-сеть.

EoMPLS (Ethernet over MPLS)

EoMPLS — туннель, который прозрачно передаёт Ethernet-кадры через MPLS-сеть. SGI Prism и PC1 "видят" друг друга, как если бы были подключены к одному коммутатору.

Реализация в MikroTik:
1. Создаётся VPLS-интерфейс с указанием удалённого loopback-адреса
2. VPLS-интерфейс объединяется в bridge с физическим интерфейсом клиента

---

## Развёртывание

```bash
cd lab3
sudo containerlab deploy --topo lab3.yaml
```

---

## Результаты проверки

1. Проверка OSPF-соседства

R01.LND:

```
[admin@R01.LND] > /routing ospf neighbor print
 # ROUTER-ID       ADDRESS         INTERFACE   STATE     STATE-CHANGES
 0 10.10.10.1      10.10.1.1       ether1      Full            6
 1 10.10.10.4      10.10.2.2       ether2      Full            6
 2 10.10.10.3      10.10.4.2       ether3      Full            6
```

R01.SPB:

```
[admin@R01.SPB] > /routing ospf neighbor print
 # ROUTER-ID       ADDRESS         INTERFACE   STATE     STATE-CHANGES
 0 10.10.10.4      10.10.3.1       ether1      Full            5
 1 10.10.10.5      10.10.6.1       ether2      Full            5
```

Все состояния Full — OSPF-соседство установлено корректно.

2. Проверка MPLS LDP-соседства

R01.LND:

```
[admin@R01.LND] > /mpls ldp neighbor print
 # TRANSPORT       PEER            LOCAL-TRANSPORT  SEND-STATE  RECV-STATE
 0 10.10.10.1      10.10.1.1:0     10.10.10.2       Oper        Oper
 1 10.10.10.4      10.10.2.2:0     10.10.10.2       Oper        Oper
 2 10.10.10.3      10.10.4.2:0     10.10.10.2       Oper        Oper
```

3. Проверка таблицы MPLS-меток

R01.LND:

```
[admin@R01.LND] > /mpls forwarding-table print
 # IN-LABEL  OUT-LABEL  DESTINATION      INTERFACE  NEXTHOP
 0 16        impl-null  10.10.10.1/32    ether1     10.10.1.1
 1 17        17         10.10.10.6/32    ether2     10.10.2.2
 2 18        impl-null  10.10.10.4/32    ether2     10.10.2.2
 3 19        impl-null  10.10.10.3/32    ether3     10.10.4.2
 4 20        18         10.10.10.5/32    ether3     10.10.4.2
 5 21        19         10.10.10.6/32    ether3     10.10.4.2
```

4. Таблица маршрутизации

R01.NY:

```
[admin@R01.NY] > /ip route print
Flags: X - disabled, A - active, D - dynamic,
C - connect, S - static, r - rip, b - bgp, o - ospf, m - mme,
B - blackhole, U - unreachable, P - prohibit
 #      DST-ADDRESS        PREF-SRC        GATEWAY            DISTANCE
 0 ADC  10.10.1.0/30       10.10.1.1       ether1                    0
 1 ADo  10.10.2.0/30                       10.10.1.2               110
 2 ADo  10.10.3.0/30                       10.10.1.2               110
 3 ADo  10.10.4.0/30                       10.10.1.2               110
 4 ADo  10.10.5.0/30                       10.10.1.2               110
 5 ADo  10.10.6.0/30                       10.10.1.2               110
 6 ADC  10.10.10.1/32      10.10.10.1      loopback                  0
 7 ADo  10.10.10.2/32                      10.10.1.2               110
 8 ADo  10.10.10.3/32                      10.10.1.2               110
 9 ADo  10.10.10.4/32                      10.10.1.2               110
10 ADo  10.10.10.5/32                      10.10.1.2               110
11 ADo  10.10.10.6/32                      10.10.1.2               110
```

R01.SPB:

```
[admin@R01.SPB] > /ip route print
Flags: X - disabled, A - active, D - dynamic,
C - connect, S - static, r - rip, b - bgp, o - ospf, m - mme,
B - blackhole, U - unreachable, P - prohibit
 #      DST-ADDRESS        PREF-SRC        GATEWAY            DISTANCE
 0 ADo  10.10.1.0/30                       10.10.3.1               110
 1 ADo  10.10.2.0/30                       10.10.3.1               110
 2 ADC  10.10.3.0/30       10.10.3.2       ether1                    0
 3 ADo  10.10.4.0/30                       10.10.3.1               110
 4 ADo  10.10.5.0/30                       10.10.6.1               110
 5 ADC  10.10.6.0/30       10.10.6.2       ether2                    0
 6 ADo  10.10.10.1/32                      10.10.3.1               110
 7 ADo  10.10.10.2/32                      10.10.3.1               110
 8 ADo  10.10.10.3/32                      10.10.6.1               110
 9 ADo  10.10.10.4/32                      10.10.3.1               110
10 ADo  10.10.10.5/32                      10.10.6.1               110
11 ADC  10.10.10.6/32      10.10.10.6      loopback                  0
```

ADo — OSPF dynamic (маршрут, полученный от OSPF)

5. Проверка EoMPLS-связности

Пинг с SGI Prism до PC1:

```
root@SGI_Prism:/# ping 10.10.20.2 -c 4
PING 10.10.20.2 (10.10.20.2): 56 data bytes
64 bytes from 10.10.20.2: seq=0 ttl=64 time=18.463 ms
64 bytes from 10.10.20.2: seq=1 ttl=64 time=4.827 ms
64 bytes from 10.10.20.2: seq=2 ttl=64 time=4.291 ms
64 bytes from 10.10.20.2: seq=3 ttl=64 time=3.976 ms

--- 10.10.20.2 ping statistics ---
4 packets transmitted, 4 packets received, 0% packet loss
round-trip min/avg/max = 3.976/7.889/18.463 ms
```

Пинг с PC1 до SGI Prism:

```
root@PC1:/# ping 10.10.20.1 -c 4
PING 10.10.20.1 (10.10.20.1): 56 data bytes
64 bytes from 10.10.20.1: seq=0 ttl=64 time=16.204 ms
64 bytes from 10.10.20.1: seq=1 ttl=64 time=4.518 ms
64 bytes from 10.10.20.1: seq=2 ttl=64 time=4.103 ms
64 bytes from 10.10.20.1: seq=3 ttl=64 time=3.847 ms

--- 10.10.20.1 ping statistics ---
4 packets transmitted, 4 packets received, 0% packet loss
round-trip min/avg/max = 3.847/7.168/16.204 ms
```

TTL=64 — пакеты передаются на уровне L2 (через EoMPLS-мост), а не маршрутизируются через L3. Это доказывает, что EoMPLS-туннель работает корректно.

---

## Вывод

В ходе работы была построена IP/MPLS сеть из 6 роутеров MikroTik с двумя резервными путями. Настроены:

1. OSPF — для автоматической маршрутизации и обеспечения связности loopback-адресов
2. MPLS LDP — для распределения меток и быстрой коммутации пакетов
3. EoMPLS — для прозрачного L2-туннеля между SGI Prism (Нью-Йорк) и PC1 (Санкт-Петербург)

Все OSPF-соседства в состоянии Full, LDP-сессии Operational, EoMPLS-пинги проходят с TTL=64 (L2-связность). Инженеры из Санкт-Петербурга могут работать с сервером SGI Prism как если бы он находился в соседней комнате.
