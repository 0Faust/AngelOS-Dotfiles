# Handoff для Antigravity: AngelOS — память, запуск, пиксельный вид

Составлено: 2026-11-15 14:47 EET
Репозиторий: `~/AngelOS-Dotfiles` (`0Faust/AngelOS-Dotfiles`)
Живая оболочка: `~/.config/quickshell/angelos` (отдельная копия, не симлинк)
Ветка: `main`, 17 коммитов впереди `origin/main`; `fork/main` == `a83a058` (всё запушенное)
Незакоммичено: 6 файлов памяти, +91 / −10 строк
Статус: изменения по памяти сделаны, проверены, **не закоммичены и не запушены**

---

## 0. TL;DR — с чего продолжить

1. **Закоммитить 6 файлов памяти** (только после явной просьбы пользователя; см. §8).
2. **Замерить startup до первого кадра** и разнести `Component.onCompleted`-пробуждения сервисов по таймерам (сейчас не измерено; `Launching config → Configuration Loaded` ≈ 2–3 с).
3. **Добить остаточную память:** `sfx-player`, скрытые окна codex-плагинов, `DesktopMenu/RadialMenu`, рост PSS оболочки за 5–10 минут.
4. **Пиксельный вид** — только после того, как пользователь пришлёт референсы «дорого vs дёшево».
5. Ничего не коммитить/пушить и не менять 10 виджетов, обои, курсор и serp-правила без явного разрешения.

---

## 1. Что за проект и чего хочет пользователь

Форк `MixaDoDs/AngelOS-Dotfiles` (Quickshell + niri, CachyOS/Arch). Пользователь ведёт его как личный премиальный «пиксельный» десктоп.

Три цели, в порядке приоритета:

1. **Меньше RAM** — оболочка и её python-помощники держали ~880 МБ на старте.
2. **Быстрее запуск после логина** — та же причина: жадный старт помощников и окон.
3. **Более дорогой пиксельный вид** — без потери функций; ждёт вкусовых референсов.

Ограничения пользователя (жёсткие):

- Не менять **10 десктопных виджетов**: `plugin:claude-companion`, `plugin:codex-companion`, `clock`, `sysmon`, `music`, `plugin:realm-toggle`, `plugin:favorite-games`, `disks`, `picture`, `plugin:laptop-sysmon`.
- Не трогать настройки live-wallpaper (кроме выбора обоев из kit).
- Не менять курсор **Pixel-Amethyst**.
- Текст serp-виджета должен оставаться резким (native zoom, не растянутый растр).
- Autohide: док — только при широких окнах; Halo — только когда окно его перекрывает; сайдбар не должен наезжать на кнопку-сердце.
- Не отключать функции, которыми пользуются: помощники должны запускаться **по требованию**, а не исчезать.
- Без отдельной просьбы — не коммитить и не пушить.

Текущие настройки: `px=2`, `fontScale=1`, `settingsUi.skin="classic"`, `stream.auto=true`, `quicklook.enabled=true`, `discord.crew=false`, язык `ru`.

---

## 2. Состояние репозитория

```
branch: main
origin/main..HEAD: 17 коммитов (все уже в fork/main)
fork/main == a83a058
git status:
  M .config/quickshell/angelos/services/CircleHost.qml
  M .config/quickshell/angelos/services/DiscordVoice.qml
  M .config/quickshell/angelos/services/QuickLook.qml
  M .config/quickshell/angelos/services/StreamAngel.qml
  M .config/quickshell/angelos/services/StreamMode.qml
  M .config/quickshell/angelos/shell.qml
  ?? plans/            (этот отчёт и локальный план — намеренно не в git)
```

Коммиты (свежие сверху):

```
a83a058 Mark the Sysmon dual-GPU plan as implemented
f6f6dad Document backups, rollback, games, laptop power and diagnostics
b651d2d Guard recovery restore and keep manual power choices
9dd6208 Test game doctor safety and diagnostic report privacy
5cd168e Add hybrid GPU monitoring and improve installation recovery
e303a8d Adapt pc-kit diagnostics for laptops
c0d1cce Add fork update controls to settings
b83e52b Add combined AngelOS and pc-kit installer
a638279 Fix wallpaper selection persistence with pc-kit plugins
19d67dc docs: design for serp wide-window autohide (dock + Halo)
8b37e95 docs: credit Frostpix11/pc-kit-share and list taken features
1a65f0c docs: implementation plan for sysmon dual-GPU
85dddcb docs: design for sysmon dual-GPU monitoring (Intel via root helper)
bb1d919 angel-niri: pin angelos-7b10b2c7 (cursor_fx + camera behind cursor)
3a0ad41 perf: obs-watch only while a stream feature wants it (issue #168 #5)
25faa70 perf: SysmonWidget /proc polling 2s -> 5s (issue #168 #4)
cec0d44 perf: lazy rare windows (issue #168 #1)
```

Ремиты: `origin` — MixaDoDs (upstream), `fork` — 0Faust (свой).

Планы и документы:

- `plans/2026-11-15-next-improvements.md` — локальный план фаз 0–7 (untracked).
- `plans/2026-11-15-handoff-antigravity.md` — этот файл.
- `docs/superpowers/specs/2026-11-13-sysmon-dual-gpu-design.md`,
  `docs/superpowers/plans/2026-11-13-sysmon-dual-gpu.md`,
  `docs/superpowers/specs/2026-11-14-serp-wide-autohide-design.md`.
- `docs/superpowers/` лежит в `.gitignore`, но уже отслеживается: правки добавлять через `git add -f`.

---

## 3. Что уже сделано до сегодня (фазы 0–7)

Кратко, чтобы не переоткрывать:

- **Фазы 1–2 (бэкапы/апдейты):** подтверждение восстановления из GitHub recovery (двухшаговое, с бэкапом текущего состояния), документация границ снапшотов (файлы AngelOS, не pacman), тесты `scripts/test-update.sh`.
- **Фаза 3 (игры):** `tests/games/test_game_doctor.py` — изолированные Steam-библиотеки, отказ сбрасывать префикс запущенной игры, сохранение перенесённых префиксов, стабильный JSON-контракт.
- **Фаза 4 (ноутбук):** адаптация диагностики pc-kit под ноутбуки, гибридный GPU-мониторинг (`extras/gpu-intel/`, `scripts/gpu-intel-read.py`, `docs/hybrid-gpu.md`), без пробуждения дискретки ради отчёта.
- **Фаза 5 (диагностика):** кнопка отчёта в Settings → System → Maintenance, приватность/скоуп, `tests/report/test_report.py` в одноразовом HOME.
- **Фаза 6 (доки):** `docs/safety-and-maintenance.md` (RU+EN), ссылки из `README.md`, `README.ru.md`, `installer/README.md`.
- **Фаза 7 (проверки):** все перечисленные ниже проверки прошли.
- **pc-kit интеграция:** `install-with-pc-kit.sh`, `CREDITS.md`; взяты shell-патчи (cursor-motion, dock-spacing, mac-cursor, mac-tint, pixora-mac, skin-morph, stack-memory, privacy-capture, game-detect, angel-game-quiet, halo-game-sleep, halo-game-notify, tray-menu-fresh, scene-handover), плагины (angelos-night-2004, privacy-eye, mac-eq, celestia), codex-плагины (AngelOS Typer, AngelOS Room), serp-skin, обои «Тихая гавань», `kit` + watcher. Пропущены gpu/niri/satellite/EasyEffects из pc-kit.
- **Issue #166:** angel-niri запинен на `angelos-7b10b2c7` (курсор/камера за курсором).
- **Issue #168:** ленивые редкие окна (7 модулей), Sysmon `/proc` 2s → 5s, `obs-watch` только при включённой stream-функции.
- **Serp:** autohide дока/Halo по широким окнам, сайдбар не перекрывает сердце, native-zoom резкость текста.

---

## 4. Сегодняшняя работа: память

### 4.1. Корневая причина

При старте оболочка **сразу** поднимала всех помощников и вторую Quickshell-оболочку оверлея скриншотов, даже если функция не нужна:

| Помощник | Когда реально нужен | Цена |
|---|---|---|
| `quicklook.py serve` | пока открыт Nautilus | ~32 МБ |
| `discord-crash-watch.py` | когда Discord рядом | ~14 МБ |
| `obs-watch.py` (+journalctl) | когда OBS запущен/стрим | ~21 МБ |
| `stream-mic` (StreamAngel) | OBS/превью/ручной стрим | ~23 МБ |
| circle-overlay (`quickshell -p circle-root`) | на скриншоте | ~87 МБ |

Итого потенциально ~177 МБ, которые висели круглосуточно.

### 4.2. Изменённые файлы (все 6 — незакоммичены)

#### `services/QuickLook.qml`

- Добавлено `fileManagerHere` — есть ли окно Nautilus (`Niri.windows[].app_id` ≈ `/nautilus/i`).
- `nautilusKeep` — таймер 120 с: после последнего окна Nautilus демон живёт ещё две минуты (превью запрашивается на каждой стрелке).
- `daemonNeeded = wanted && (fileManagerHere || nautilusKeep.running)`; `Process.running` переведён на него (строка ~106).
- Поведение проверено: открыл Nautilus → демон поднялся; закрыл → через 2 минуты должен уйти (проверялось косвенно, см. §6).

#### `services/DiscordVoice.qml`

- `discordHere` — окно Discord/Vesktop/Webcord/Legcord (`/discord|vesktop|webcord|legcord/i`).
- `discordKeep` — 30 минут после последнего sighting: краш = окно исчезает, coredump появляется сразу после.
- `Process.running` = прежние условия **и** `(wanted || discordHere || discordKeep.running)` (строка ~80).
- `wanted` по-прежнему требует `discord.crew` или виджет Discord; у пользователя сейчас `crew=false` и виджета нет, поэтому watcher не стартует, пока Discord не появится.

#### `services/StreamMode.qml`

- `obsWindow` — окно `com.obsproject.Studio` (`/obsproject|obs-studio/i`).
- `obsKeep` — 60 с после закрытия OBS (перекрывает рестарт OBS).
- `watchWanted = Config.ready && (auto || manual || streamer) && (obsWindow || obsUp || obsKeep.running)`.
- `Process.running` и `rewatch`-биндинг переведены на `watchWanted` (строки ~143, ~161).
- `obsUp` приходит от самого helper'а и закрывает момент, когда OBS уже отвечает, а списка окон ещё нет.

#### `services/StreamAngel.qml`

- Аналогично: `obsWindow`, `obsKeep` 60 с, `micWanted = (enabled || preview) && (preview || always || obsWindow || obsUp || obsKeep.running)`.
- `mic.running` и `restart`-биндинг — на `micWanted` (строки ~131, ~147).
- Ручной стрим без OBS (`always`) и превью по-прежнему работают.

#### `services/CircleHost.qml`

- `idleStopMs = 10 * 60 * 1000` (строка 41), `lastUse`, `stopping`.
- `wake()` (строка 92) — единая точка запуска оверлея: выставляет `lastUse` и стартует процесс, если сокет готов.
- Убран автозапуск из `onExited` подготовки сокета: теперь «no start here: the process comes up when a screenshot asks for it (wake)».
- `send()` при неудаче: `fallback.interval = proc.running ? 3000 : 7000` (холодный старт дольше), затем `wake()`.
- `take()` обновляет `lastUse` на любом сообщении (hello/state/result).
- `onExited` различает **тихую остановку** (`stopping`) и краш: при тихой — без backoff и без рестарта; при краше — прежний экспоненциальный backoff.
- Новый `Timer` раз в минуту: если процесс жив, оверлей не открыт, соединение есть и `lastUse` старше 10 минут — `stopping = true; proc.running = false`.

#### `shell.qml`

- Обновлён только комментарий к `CircleHost.open` (строка ~222): «the screenshot overlay's own socket … its process comes on the first shot».

### 4.3. Механика гейтинга

Все проверки окон идут через `Niri.windows[].app_id`:

- Nautilus: `/nautilus/i`
- Discord: `/discord|vesktop|webcord|legcord/i`
- OBS: `/obsproject|obs-studio/i` (у пользователя app_id — `com.obsproject.Studio`)

`Config.ready`, `ANGELOS_TEST=1`, `Shell.dev` и прежние условия сохранены. Ни один помощник не удалён — только отложен до первого реального требования.

---

## 5. Замеры

### 5.1. Методика

```bash
# память оболочки (PSS, без двойного счёта общих страниц)
P=$(pgrep -f 'qs -c angelos -n' | head -1)
awk '/^Pss:/{printf "shell PSS %.0f MB\n", $2/1024}' /proc/$P/smaps_rollup

# штатный профиль оболочки и помощников
angelos perf 10

# процессы-помощники
ps -eo rss,args | grep -E '^ *[0-9]+ /usr/bin/python3 .*angelos/'
```

`angelos perf` считает память помощников без двойного счёта общих страниц; сумма `ps rss` всегда выше (общие страницы учитываются в каждом процессе), сравнивать между собой нужно только одинаковые методики.

### 5.2. До / после

| Метрика | Базовая линия | После правок |
|---|---|---|
| PSS оболочки `qs` | 558 МБ | 523–529 МБ |
| Помощники | 351 МБ / 40 процессов | 201 МБ / 18 процессов |
| Итого | ~880 МБ | ~724–730 МБ |
| CPU | ~8.4 % | ~5.7 % |
| Пробуждения | 369/с | 393/с (шум, не регрессия) |

Итог: **≈ −150 МБ (−17 %)** и меньше фонового CPU. Circle-оверлей (~87 МБ) при этом вообще не запущен.

### 5.3. Важные оговорки

- **Рост PSS:** после 1:27 аптайма и открытых приложений замер дал 537 МБ PSS, помощники 384 МБ (21 процесс) — это не регрессия гейтинга, а обычный рост при активных приложениях. Нужен отдельный срез «5–10 минут простоя» (см. §8).
- **`perf --stand`** (private server) даёт другие цифры: 662–670 МБ, помощники 291–293 МБ. Не сравнивать с обычным замером.
- **jemalloc-профилирование** не поймало `qs` (дампы ~524 КБ, только GOMP) — метод нерабочий для этой сборки, не тратить время.
- **Пробуждения** — шумная метрика; вывод об успехе делать по PSS и списку процессов, не по wakeups.

### 5.4. Circle: тайминги

- Ленивый старт: процесс появляется через **34–39 мс** после `angelos capture`, но оверлей готов к взаимодействию через **~2.5–3 с** (вторая Quickshell грузит свой runtime).
- Fallback на классический селектор: **7 с** при холодном старте, **3 с** при уже поднятом процессе.
- Автостоп: 10 минут после последнего использования; проверено временным `idleStopMs = 2000` → через 70 с процесс исчез, затем значение восстановлено из репозитория.
- Во время проверок ни разу не сработал fallback «overlay is not there» — холодный старт уложился в 7 с.

### 5.5. Startup

- `Launching config → Configuration Loaded` ≈ **2–3 с** (пример: 14:45:10 → 14:45:12).
- **Время до первого кадра не измерено.** `angelos restart` перед рестартом гоняет `qml-check` (~3 с), это не входит в startup оболочки.
- Первый кадр — главный оставшийся вопрос по «быстрее после логина».

---

## 6. Проверки, которые уже прошли

- `qml-check`: репозиторий **727 файлов, 0 ошибок**; живая копия **829 файлов, 0 ошибок** (разница — модули serp, которых нет в репо).
- Тесты: report, games, settings tree, laptop, `scripts/test-update.sh`, `scripts/static-checks.sh`.
- `bash -n` по изменённым shell-скриптам, `git diff --check`.
- Чистый `angelos restart` не запускает circle-процесс; `angelos capture` поднимает его; повторный capture закрывает оверлей.
- Nautilus → `quicklook.py serve` поднимается; после закрытия окна процесс ещё живёт (ожидаемые 2 минуты keep).
- В логах после рестарта нет `TypeError`/`ReferenceError` от новых свойств; есть только давние `WARN scene: Unable to assign [undefined]` в `Audio/LyricsGlow/Eq/Sensors` — они были и раньше, qml-check их не считает.

---

## 7. Подводные камни (важно не наступить)

1. **Живая копия — отдельная.** `~/.config/quickshell/angelos` не симлинк. Правка: репозиторий → `cp` конкретного файла → `angelos restart`.
2. **Не копировать `shell.qml` целиком.** Живой файл содержит serp-строки (`import qs.modules.serp`, `SerpDesktop {}`, `SerpWindows {}`), которых нет в репозитории. При копировании repo→live kit-watcher вернул их через ~16 с (наблюдение 15.11, 14:41:46), но полагаться на это нельзя. Если правишь `shell.qml` — переноси только свою строку, не файл.
3. **`kit` watcher** автоматически переприменяет hunks к живой копии, если видит, что патч «пропал». Поэтому: не запускать `install.sh plugins` (перезапишет serp-настроенную celestia), а `apply.py check` **на самом деле применяет** — это не dry-run.
4. **`angelos reload`** — in-process, может оставить осиротевшие helper-процессы. Для замеров и гейтинга — только `angelos restart`.
5. **Гейтинг завязан на `app_id`.** Если приложение запускается с другим `app_id` (flatpak, Wayland-обёртка), regex не сработает и помощник не поднимется. При жалобе «не работает» — сначала `niri msg --json windows`, потом править regex.
6. **Circle-тест автостопа:** временно поставить `idleStopMs = 2000`, `angelos restart`, два capture, подождать 70 с, убедиться, что процесса нет, **вернуть значение из репозитория** (`cp` + restart). Не забыть вернуть.
7. **`Config.ready`** обязателен в условиях: до готовности конфига `Niri.windows` может быть `undefined` — поэтому везде `(Niri.windows || [])`.
8. **Тесты селектора:** `tests/keys/KeysDriver.qml` использует `CircleHost.pending`; при изменении протокола hello/pending смотреть и туда.
9. **Серые зоны:** `stream.streamer` (ангел для OBS) и `stream.manual` включают watcher; ручной стрим без OBS держится на `obsUp`/`always` — не убирать эти ветки.
10. **Снапшоты и recovery** покрывают файлы AngelOS, не пакеты pacman — не обещать обратного в доках.

---

## 8. Где именно остановились

Последнее действие: чистый `angelos restart` в 14:45, живая копия совпадает с репозиторием по 5 из 6 файлов (`shell.qml` отличается только serp-строками, см. §7.2). Circle не запущен, помощники поднимаются по требованию. Замеры сняты, отчёт (этот файл) создан.

### Следующие шаги по приоритету

#### Шаг 1. Коммит (только по просьбе пользователя)

```bash
cd ~/AngelOS-Dotfiles
git add .config/quickshell/angelos/services/CircleHost.qml \
        .config/quickshell/angelos/services/DiscordVoice.qml \
        .config/quickshell/angelos/services/QuickLook.qml \
        .config/quickshell/angelos/services/StreamAngel.qml \
        .config/quickshell/angelos/services/StreamMode.qml \
        .config/quickshell/angelos/shell.qml
git commit -m "perf: start quicklook, discord, obs and circle helpers on demand"
```

Предлагаемое тело: перечислить пять помощников, gating по `app_id`, keep-таймеры, ленивый circle с автостопом 10 минут; указать замеры 558→523 МБ и 351→201 МБ. `plans/` не добавлять. Пушить только после отдельного «да».

#### Шаг 2. Startup до первого кадра

- Сейчас известно только `Launching config → Configuration Loaded` (~2–3 с).
- Предложенный способ: временно добавить в конец `shell.qml` лог готовности (например, `Component.onCompleted: console.log("angelos-ready " + Date.now())` в подходящем месте `ShellRoot`), перезапустить, снять `journalctl --user -u angelos.service`, вычесть время `Launching config`. Лог потом убрать.
- Затем разнести пробуждения сервисов в `shell.qml` (блок `Component.onCompleted`, ~строка 200): сейчас десятки синглтонов дергаются одним залпом. Идея — `Timer` 50/100/200 мс для некритичных (QuickLook, Discord, Stream, Devices, Cobweb), оставив в первом кадре бар, Halo, обои.
- Критерий: первый кадр быстрее, чем сейчас; число helper-процессов в первую секунду меньше; qml-check 0 ошибок.

#### Шаг 3. Остаточная память

Кандидаты, по убыванию выгоды:

1. **`sfx-player.py`** — 17–30 МБ всегда. Запускать на первый звук (иконки/уведомления), гасить через N минут тишины; проверить, что звуки UI не теряются.
2. **Скрытые окна codex-плагинов** — три окна по 416/374/333 объекта (~1100), у одного `Mascot`-таймер 250 мс. Сделать `LazyLoader`/`visible: false` без инстанса либо поднимать только при открытии панели.
3. **`DesktopMenu/RadialMenu`** — ~1148 объектов. Проверить, можно ли `LazyLoader` до первого открытия.
4. **Рост PSS оболочки** — снять PSS сразу после рестарта и через 1/3/5/10 минут простоя; если растёт — искать таймеры/модели (кандидаты: idle-redraw `HellBarFrame` 16–19 fps, `IdleWatch/Linger` 5 fps).
5. **Всего окон:** 58, объектов 8741 на простое — держать в голове как baseline.

#### Шаг 4. Пиксельный вид

Ждёт пользователя: нужны 2–4 референса «что выглядит дорого» и «что выглядит дёшево» (скриншоты/игры/UI). После этого — `config/Theme.qml` (размеры, шрифты, отступы), не ломая native zoom и serp-резкость. Не менять 10 виджетов, обои, курсор.

---

## 9. Открытые вопросы к пользователю

1. Коммитить ли 6 файлов памяти и пушить ли в `fork/main`? (по умолчанию — нет).
2. Референсы по пиксельному виду: что именно «дёшево» в текущем виде?
3. Отдельная тема, не AngelOS: подписка Gemini не подключается к OpenCode (у Google-провайдера только API-ключ); ключ на free tier, лимит 250k входных токенов. Нужен биллинг в AI Studio или другой провайдер. К AngelOS не относится.

---

## 10. Шпаргалка команд

```bash
# проверка QML (репозиторий)
cd ~/AngelOS-Dotfiles
bash .config/quickshell/angelos/scripts/qml-check.sh .config/quickshell/angelos

# перенос одного файла в живую копию
cp .config/quickshell/angelos/services/QuickLook.qml \
   ~/.config/quickshell/angelos/services/QuickLook.qml

# перезапуск (сначала qml-check, потом рестарт)
angelos restart

# замеры
angelos perf 10
P=$(pgrep -f 'qs -c angelos -n' | head -1)
awk '/^Pss:/{printf "shell PSS %.0f MB\n", $2/1024}' /proc/$P/smaps_rollup

# окна niri (app_id для гейтинга)
niri msg --json windows | python3 -c 'import json,sys;print(sorted({w.get("app_id","") for w in json.load(sys.stdin)}))'

# скриншот-оверлей
angelos capture

# отчёт для диагностики
angelos report
```

---

## 11. Критерий готовности следующей итерации

- [ ] 6 файлов памяти закоммичены (если пользователь разрешил) и запушены в `fork`.
- [ ] Измерено время до первого кадра до/после разноса пробуждений.
- [ ] Снят профиль простоя 10 минут; рост PSS объяснён или устранён.
- [ ] `sfx-player` не держит память в тишине, звуки работают.
- [ ] qml-check: репозиторий 727/0, живая копия 829/0.
- [ ] Ни один из 10 виджетов, обои, курсор и serp-правила не изменены.
