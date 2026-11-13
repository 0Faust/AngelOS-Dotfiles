# Дизайн: sysmon следит за обеими видеокартами (2026-11-13)

## Зачем

Ноутбук пользователя: Intel UHD (i915) + NVIDIA RTX 4060 Max-Q. Виджет
«Системный монитор» показывает одну карту — `scripts/gpu-stats.sh` берёт карту
с наибольшим VRAM (NVIDIA). Пользователь хочет видеть обе.

## Цели

- Две строки в виджете при обнаружении 2+ карт: «GPU NV» (точно, с темпом/VRAM,
  как сейчас) и «GPU Intel» (точно, от root-помощника).
- Одна карта — ровно как сегодня (регрессии исключить).
- Управление: Settings → Виджеты → выбор «Авто / Вкл / Выкл» (`Config.desktop.sysmonGpus`,
  дефолт `auto` — по числу карт).

## Не цели / анти-цели

- **Не будить спящую NVIDIA** (issue #60): логику сна gpu-stats.sh не менять.
  Root-помощник только для Intel; intel_gpu_top и i915 NVIDIA не будят.
- История-график (колонка L-размера) остаётся только у NVIDIA.
- AMD оставляем как есть: вторая строка для AMD делается sysfs-путём gpu-stats.sh
  (без root), если вторая карта AMD — но у пользователя Intel+NVIDIA, это главный путь.

## Подход (выбран: Б)

Точная загрузка Intel требует root (`intel_gpu_top`, perf). Решение: systemd
system-служба, запускаемая при загрузке от root, читает `intel_gpu_top` и пишет
в `/run/angelos-gpu-intel.json` одну строку JSON
`{"load": 34.2, "temp": 45, "freq": 650, "maxFreq": 1300}`. Виджет читает файл
FileView'ом раз в 5 с (совпадает с новым опросом sysmon, patch #4).

Отвергнутое: частотная оценка без root (вариант А — неточность ±15%);
чтение sysfs для Intel (нечего читать: у i915 нет gpu_busy_percent).

## Состав работ

1. `scripts/gpu-intel-helper.py` (в форке): цикл — раз в 2 с parses stdout
   `intel_gpu_top -J -s 2000`, пишет плоскую строку в `/run/angelos-gpu-intel.json`
   (tmpfs, chmod 644). Столится: служба падает → файл устарел → виджет
   показывает «—» (по mtime > 10 с). Права: root нужен только для perf.
2. `scripts/gpu-intel-install.sh` (в форке, единственный шаг с sudo):
   ставит `intel-gpu-tools` (если нет), копирует юнит
   `angelos-gpu-intel.service`, `systemctl enable --now`. Юнит:
   `ExecStart=/usr/bin/python3 …/gpu-intel-helper.py`, `Restart=on-failure`.
3. `SysmonWidget.qml`: вторая строка. Файл помощника читается FileView'ом;
   «—» при устаревших данных или выключенном тумблере. Источник второй
   карты — автодетект: NVIDIA от nvidia-smi (есть), Intel от помощника,
   AMD из sysfs второй карты.
4. `SettingsSchema.qml`: `Config.desktop.sysmonGpus: "auto"|"on"|"off"` (дефолт auto).
5. `catalog/Widgets.qml`: CatChoice «Обе видеокарты» (по образцу соседних).
6. Тумблер прячет/показывает строку; служба не управляется из QML
   (останавливается только вручную `systemctl disable --now` — сказать в UI-подсказке).

## Осталось исполнителю

- Точный разбор вывода `intel_gpu_top -J` (имена полей Render/3D pipe busy).
- Поведение L-размера при двух строках (вторая строка без гистограммы).
- Что показывать при отсутствии термо-датчика Intel (обычно нет hwmon — «—»).

## Проверка

- `scripts/qml-check.sh` — 0 ошибок после правок QML.
- Ручная: виджет показывает обе строки; сон NVIDIA не нарушен
  (карта спит → `0 %`, не просыпается); тумблер прячет/показывает Intel.
- Коммит(ы) в форк `0Faust/AngelOS-Dotfiles`, push.
