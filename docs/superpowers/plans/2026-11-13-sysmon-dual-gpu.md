# Sysmon: обе видеокарты (Intel через root-помощника) — план

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Виджет «Системный монитор» показывает обе карты ноутбука (NVIDIA точно, Intel точно через root-службу), вторая строка управляется настройкой «Авто/Вкл/Выкл» с автодетектом.

**Architecture:** Root-служба пишет `/run/angelos-gpu-intel.state` (плоская строка); `gpu-stats.sh` добавляет вторую строку вывода `intel,…` только когда файл помощника существует; SysmonWidget рисует вторую строку по флагу. Логика сна NVIDIA (issue #60) не трогается.

**Tech Stack:** QML/Quickshell (SysmonWidget), sh (gpu-stats.sh), Python 3 (helper), systemd system-юнит, intel-gpu-tools.

**Spec:** `docs/superpowers/specs/2026-11-13-sysmon-dual-gpu-design.md`

## Global Constraints

- Рабочие копии: править в `~/AngelOS-Dotfiles`, затем `cp` в `~/.config/quickshell/angelos/` (файлы без плейсхолдеров).
- После правок QML: `scripts/qml-check.sh ~/.config/quickshell/angelos` → «727 files, 0 with errors».
- Спящая NVIDIA не будится: в gpu-stats.sh менять только добавление intel-строки, ветку nvidia-smi/pm не трогать.
- QML-стиль репо: комментарии по-английски, строки UI через `I18n.t("Рус", "Eng")`.
- Коммиты в `~/AngelOS-Dotfiles` (ветка main), в конце push в `fork`.

## Review Focus

- Помощник не запущен/упал → у виджета строка Intel показывает «—», а не зависшие цифры (тест: свежесть ts в Task A/B).
- intel_gpu_top отсутствует → служба падает, `Restart=on-failure` с интервалом, файл не пишется (шаг в Task A).
- Файл состояния world-readable (644), в tmpfs /run (юнит RuntimeDirectory) — иначе виджет не прочитает (Task A).
- Прогрев: первая строка intel приходит до первых данных — «—» вместо 0% (Task C, parse -1).
- macOS-стиль (macReadings) не трогаем: там остаётся одно кольцо GPU (NV) — дешёвое решение, чужой стиль; S-размер тоже без второй строки (Task C).

---

### Task A: root-помощник Intel + systemd-юнит + установщик

**Files:**
- Create: `.config/quickshell/angelos/scripts/gpu-intel-helper.py` (и копия в `~/AngelOS-Dotfiles/...`)
- Create: `.config/quickshell/angelos/scripts/gpu-intel-install.sh`
- (создаётся инсталлером): `/etc/systemd/system/angelos-gpu-intel.service`, `/run/angelos-gpu-intel.state`

**Interfaces:**
- Produces: `/run/angelos-gpu-intel.state` — одна строка текста `<load> <temp> <ts>` (load: 0–100 или -1, temp: °C или -1, ts: unix-секунды записи), обновление каждые 2 с, файл 644. Потребитель — Task B.

- [ ] **Step 1: Написать `gpu-intel-helper.py`**

Сигнатура: без аргументов; бесконечный цикл. Алгоритм:
1. Найти карту i915: первый `/sys/class/drm/card[0-9]*/device`, у которого `readlink device/driver` заканчивается на `i915`; temp — первый читаемый `hwmon/hwmon*/temp1_input` этой карты (часто нет → -1).
2. Запустить `intel_gpu_top -J -s 2000` (у одного iGPU путь не нужен). Читать stdout инкрементально: накапливать буфер, доставать полные JSON-объекты через `json.JSONDecoder().raw_decode(buf, idx)` в цикле (формат intel_gpu_top -J: подряд идущие JSON-объекты; поля: `engines: {"Render/3D/0": {"busy": 34.2, …}, …}`, `freq: {"actual": 650, "requested": …}`). Load = busy первого ключа `engines`, содержащего `Render` или `3D`; если полей нет — писать -1 -1 и продолжать.
3. Каждые 2 с (или по каждому полному объекту — whichever чаще) перезаписывать файл целиком: `open("/run/angelos-gpu-intel.state","w").write(f"{load:.1f} {temp} {int(time.time())}\n")` + `os.chmod(0o644)`.
4. Если `intel_gpu_top` не найден — печатать в stderr и выходить 1 (systemd перезапустит по Restart=on-failure).

- [ ] **Step 2: Написать `gpu-intel-install.sh`**

Sudo-скрипт: 1) `pacman -S --needed intel-gpu-tools`; 2) определить каталог скриптов рядом с собой (`$(dirname "$0")`), подставить его в юнит-шаблон heredoc:

```ini
[Unit]
Description=angelOS: Intel GPU load for the System monitor widget
[Service]
Type=simple
ExecStart=/usr/bin/python3 <SCRIPTDIR>/gpu-intel-helper.py
Restart=on-failure
RestartSec=5
[Install]
WantedBy=multi-user.target
```

3) записать `/etc/systemd/system/angelos-gpu-intel.service`, `systemctl daemon-reload && systemctl enable --now angelos-gpu-intel.service`.

- [ ] **Step 3: Попросить пользователя выполнить sudo-команду и проверить**

Команда для пользователя (одной строкой):
`sudo bash ~/.config/quickshell/angelos/scripts/gpu-intel-install.sh`
Проверка агентом после: `systemctl is-active angelos-gpu-intel.service` → active; `cat /run/angelos-gpu-intel.state` → три числа, ts обновляется при повторном чтении через 3 с. Если у пользователя файл не появился — стоп, разобраться (обычно имена полей JSON: поправить parse по реальному выводу `intel_gpu_top -J`).

- [ ] **Step 4: Commit**

```bash
git add .config/quickshell/angelos/scripts/gpu-intel-helper.py .config/quickshell/angelos/scripts/gpu-intel-install.sh
git commit -m "feat: Intel GPU root helper + systemd unit (sysmon dual-GPU)"
```

### Task B: gpu-stats.sh — вторая строка intel

**Files:**
- Modify: `.config/quickshell/angelos/scripts/gpu-stats.sh` (и копия в `~/AngelOS-Dotfiles/...`)

**Interfaces:**
- Consumes: `/run/angelos-gpu-intel.state` (Task A).
- Produces: протокол вывода для `--watch`: строка 1 — прежняя `load,temp,used,total`; строка 2 (только при установленном помощнике и наличии i915) — `intel,<load>,<temp>` каждые `every` секунд; значения -1 при устаревших данных (ts старше 10 с). Потребитель — Task C (парсинг в SysmonWidget).

- [ ] **Step 1: Добавить в конец цикла `--watch` вывод intel-строки**

В обоих циклах скрипта (nvidia-pm-loop и sysfs-цикл — см. текущий текст) после `echo` основной строки добавить вызов функции `intel_line`, определённой рядом с шапкой:

```sh
# The Intel card, when the root helper (gpu-intel-helper.py) runs: one line
# "intel,load,temp"; stale or missing file → "intel,-1,-1" (the widget shows "—")
intel_line() {
  f=/run/angelos-gpu-intel.state
  [ -r "$f" ] || return 1
  read -r load temp ts <"$f"
  now=$(date +%s)
  [ "${ts:-0}" -lt $((now - 10)) ] && { echo "intel,-1,-1"; return 0; }
  echo "intel,$load,$temp"
}
```

И условие наличия карты: функция вызывается только если есть карточка с драйвером i915 — детект в шапке (`for dev in /sys/class/drm/card[0-9]*/device; case "$(basename "$(readlink -f "$dev/driver" 2>/dev/null)")" in i915) has_intel=1;; esac; done`).

Ветку nvidia-smi/pm не менять. Одноразовый режим (без `--watch`) оставить без intel-строки — виджет её не читает.

- [ ] **Step 2: Прогнать 6 с и проверить обе строки**

Run: `timeout 6 sh ~/.config/quickshell/angelos/scripts/gpu-stats.sh --watch 2 | head -6`
Expected: попеременно строки вида `0,-1,0,8192` (NVIDIA спит) и `intel,34.2,45`; без помощника — только NVIDIA-строки. Если строка intel `intel,-1,-1` при живом помощнике — проверить свежесть ts.

- [ ] **Step 3: Commit**

```bash
git add .config/quickshell/angelos/scripts/gpu-stats.sh
git commit -m "feat: gpu-stats.sh emits an intel line from the root helper"
```

### Task C: SysmonWidget — вторая строка

**Files:**
- Modify: `.config/quickshell/angelos/modules/desktop/widgets/SysmonWidget.qml` (и копия в репо)

**Interfaces:**
- Consumes: протокол Task B; настройка `Config.desktop.sysmonGpus` (Task D — появится позже, до неё флаг читается через `Config.desktop.sysmonGpus ?? "auto"` и работает как auto).
- Produces: свойства `root.gpu2` (0–1 или -1), `root.gpu2Temp`, `root.hasIntel` (bool, true после первой intel-строки), `root.showIntel` (bool: hasIntel && настройка не off и (auto ⇒ true)); строка в `readings` c `"id": "gpu2"`, без `"hist"`.

- [ ] **Step 1: Парсинг intel-строки и флаги**

В `gpuProc.stdout.SplitParser.onRead`: если `text.startsWith("intel,")` — `v[1]>=0` → `root.gpu2 = v[1]/100; root.gpu2Temp = v[2]`, иначе `root.gpu2 = -1; root.gpu2Temp = -1`; и `root.hasIntel = true` в любом случае. Прочие строки — прежний парс. Свойства объявить рядом с `root.gpu` (строка ~47): `property real gpu2: -1`, `property real gpu2Temp: -1`, `property bool hasIntel: false`, и уже здесь `readonly property bool showIntel: root.hasIntel` (в Task D Step 2 условие уточнится настройкой).

- [ ] **Step 2: Смена интервала --watch 2 → 5**

В `gpuProc.command`: `"--watch", "2"` → `"--watch", "5"` (единый темп с опросом /proc из patch #4; helper пишет каждые 2 с, окно свежести 10 с — данные не протухают).

- [ ] **Step 3: Строки readings и sReadings**

В `readings` (строка ~305): метка первой GPU-строки `"k": root.showIntel ? I18n.t("GPU NV", "GPU NV") : "GPU"`; после неё вставить условный элемент (как элемент массива):

```qml
...(root.showIntel ? [{
    "k": I18n.t("GPU Intel", "GPU Intel"),
    "id": "gpu2",
    "v": Math.max(0, root.gpu2),
    "t": root.gpu2 < 0 ? "—" : Math.round(root.gpu2 * 100) + "%" + (root.gpu2Temp > 0 ? "  " + Math.round(root.gpu2Temp) + "°" : ""),
    "c": Theme.accent3
}] : [])...
```

(`Theme.accent3` существует — зелёно-жёлтая пара в Theme.qml:466/479.)

`sReadings` заменить выбор по id вместо индексов: `[...root.readings.filter(r => r.id === "cpu" || r.id === "gpu" || r.id === "ram"), {…net}]` — S-размер не показывает gpu2 (объект net оставить как есть). `macReadings` не менять (Review Focus).

- [ ] **Step 4: Проверки и деплой**

`cp` в live; `qml-check.sh` → 0 ошибок; `angelos restart` (медленно, это норма); через 30 с `systemctl --user is-active angelos.service` → active. Визуально виджет на столе: строки «GPU NV» и «GPU Intel».

- [ ] **Step 5: Commit**

```bash
git add .config/quickshell/angelos/modules/desktop/widgets/SysmonWidget.qml
git commit -m "feat: sysmon shows the second GPU (Intel) when the helper runs"
```

### Task D: настройка «Авто/Вкл/Выкл»

**Files:**
- Modify: `.config/quickshell/angelos/config/SettingsSchema.qml` (блок `desktop`, строка ~299)
- Modify: `.config/quickshell/angelos/modules/settings/catalog/Widgets.qml`
- Обе копии — в репо и в live.

**Interfaces:**
- Produces: `Config.desktop.sysmonGpus: string` — `"auto" | "on" | "off"`, дефолт `"auto"`. Потребитель — `root.showIntel` в SysmonWidget (Task C Step 1/3).

- [ ] **Step 1: SettingsSchema.qml**

В JsonObject `desktop` после `widgetStyle`:
```qml
property string sysmonGpus: "auto"  // sysmon widget: auto (a row per card when 2+) | on | off
```

- [ ] **Step 2: Widget flag**

В SysmonWidget заменить `showIntel` из Task C: `readonly property string gpuMode: Config.desktop.sysmonGpus || "auto"`; `readonly property bool showIntel: root.hasIntel && root.gpuMode !== "off"` (при auto — показывать, карта одна не даст hasIntel).

- [ ] **Step 3: Widgets.qml CatChoice**

По образцу соседних CatChoice (дискорд «Размер человечков»):
```qml
CatChoice {
    label: I18n.t("Видеокарты в мониторе", "GPUs in the monitor")
    hint: I18n.t("Вторая строка «Системного монитора». Авто — по числу карт; служба Intel включается scripts/gpu-intel-install.sh", "The System monitor's second row. Auto — by the card count; the Intel service is enabled by scripts/gpu-intel-install.sh")
    combo: true
    model: [{"label": I18n.t("Авто", "Auto"), "value": "auto"}, {"label": I18n.t("Включить", "On"), "value": "on"}, {"label": I18n.t("Выключить", "Off"), "value": "off"}]
    currentValue: Config.desktop.sysmonGpus
    onActivated: v => Config.desktop.sysmonGpus = v
}
```

- [ ] **Step 4: Проверка, деплой, коммит, push**

qml-check → 0 ошибок; `angelos restart`; в Settings → Виджеты переключить «Выкл» → строка Intel пропала; вернуть «Авто». Коммит + `git push fork main`.

```bash
git add .config/quickshell/angelos/config/SettingsSchema.qml .config/quickshell/angelos/modules/settings/catalog/Widgets.qml .config/quickshell/angelos/modules/desktop/widgets/SysmonWidget.qml
git commit -m "feat: sysmon dual-GPU setting (auto/on/off)"
```

---

## Итоговая проверка

- Виджет: две строки, NVIDIA спит → `0 %`, Intel живая → цифры; тумблер «Выкл» прячет Intel.
- `systemctl is-active angelos-gpu-intel.service` → active.
- Память помощника: `ps -o rss= -C python3 | sort` — проверить, что помощник ~10 МБ.
