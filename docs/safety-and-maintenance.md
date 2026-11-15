# Safety and maintenance · Безопасность и обслуживание

A short guide to what angelOS saves before it changes anything, how to get back, what a snapshot
does **not** cover, and where diagnostic archives land. Every action is in Settings; the commands
are for the terminal.

Краткий справочник: что angelOS сохраняет перед изменениями, как вернуть, чего снимок **не**
покрывает и куда попадают диагностические архивы. Всё есть в Настройках; команды — для терминала.

---

## Русский

### 1. Резервные копии и восстановление

**Настройки → Аккаунт → Восстановление.**

- **Сохранить** — настройки и прогресс игры уходят в ваш приватный репозиторий GitHub.
  **Сохранять каждый день** делает это само, раз в сутки, пока есть вход в GitHub.
- Без GitHub: **В файл** (в `~/Documents`) и **Из файла…**.
- **Восстановить** не срабатывает с одного клика: первый клик только взводит кнопку
  («Точно заменить?») на пять секунд, второй — заменяет. Перед заменой текущие настройки и
  прогресс сохраняются в резервную копию, так что отменить можно и это.
- В копию входят настройки angelOS и прогресс игры. Личные файлы, установленные пакеты и
  конфиги вне angelOS она не затрагивает.

### 2. Обновления и откат

**Настройки → Обновления** (или `angelos updates`, или `git pull && ./install.sh`).

- Сначала обновляется система (`pacman -Syu`), потом файлы angelOS — новая оболочка на старом
  Quickshell оставила бы вас без рабочего стола.
- Перед изменением файлов каждый файл, который может записать установщик, копируется в
  `~/.local/state/angelos/backups/<дата>-update/` и читается обратно. Без этой копии ничего не
  меняется.
- Обновление засчитывается, только если прошли установщик, проводка niri и `niri validate`.
  Иначе страница предлагает вернуть как было.
- **Вернуть как было** откатывает только то, что изменило это обновление. Файлы, которые вы
  или angelOS изменили после него, остаются на месте и показываются как конфликты; созданные
  обновлением файлы удаляются; репозиторий возвращается на прежний коммит.
- **Чего снимок не покрывает: системных пакетов.** Если снимок не создался, файлы angelOS не
  менялись, но пакеты могли уже обновиться — возврат файлов их не откатывает. Для пакетов
  пользуйтесь обычными средствами системы (кэш пакетов, снапшоты файловой системы).
- Ваши строки в `~/.config/fish/user.fish` и `~/.config/niri/cfg/user.kdl` не трогаются никогда.
  Файлы, которые angelOS генерирует сама, остаются вашими; новые версии ждут в
  `~/.local/state/angelos/kept-updates/`.
- Оболочка не запускается? `angelos rescue` покажет причину, попробует ещё раз и предложит путь
  назад; после пяти неудачных стартов за минуту он открывается сам.

### 3. Игры

**Настройки → Обслуживание → Игры** (`scripts/game-doctor.py`).

- **Сброс префикса** переносит `steamapps/compatdata/<ID>` в
  `steamapps/angelos-prefix-backups/` и ничего не удаляет: сохранения внутри перенесённого
  префикса остаются, а Steam создаст чистый префикс при следующем запуске.
- **Очистка кэша шейдеров** — для одной игры или для всех (Steam и кэши NVIDIA/Mesa). Первый
  запуск после неё дольше: шейдеры компилируются заново.
- Обе операции отказываются работать, пока игра запущена, и ничего не меняют в этом случае.
- Версия Proton и параметры запуска игры здесь не меняются — это ваш выбор в Steam.

### 4. Питание ноутбука

**Настройки → Батарея** и **Настройки → Ноутбук**; из терминала — `angelos laptop …`.

- Эко-режим включается вручную, при батарее не выше порога или при профиле «Экономия». Он
  переводит профиль на `power-saver` и возвращает прежний, когда заканчивается.
- Если во время эко выбрать профиль вручную, ваш выбор главнее: эко не вернёт старый профиль
  и не перезапишет новый.
- Предел заряда, подсветка клавиатуры и некоторые клавиши зависят от железа: если оно этого не
  умеет, соответствующий пункт не показывается.
- Клавиши яркости и подсветки записываются в конфиг niri и проверяются `niri validate`. Если
  проверка не прошла, конфиг откатывается и остаётся прежним.

### 5. Диагностика

**Настройки → Обслуживание → Состояние → Отчёт для диагностики → Создать и открыть.**
Из терминала: `angelos report [--out КАТАЛОГ] [--open] [--json]`.

- Архив `angelos-report-<дата>-<время>.tar.gz` пишется в домашний каталог (или в `--out`) с
  правами `0600`.
- **Ничего не отправляется автоматически.** Имя пользователя и домашний путь заменяются на
  `<user>` и `~`; история лаунчера, имена рабочих столов, данные плагинов и свободные тексты не
  попадают в архив.
- Логи всё же могут содержать названия окон или треков — просмотрите архив перед отправкой.
- Рядом с путём к архиву печатается ссылка на форму нового issue: приложите архив туда.

---

## English

### 1. Backups and recovery

**Settings → Account → Recovery.**

- **Save** puts your settings and game progress into your private GitHub repository.
  **Save every day** does it by itself once a day while you are logged in to GitHub.
- Without GitHub: **To a file** (into `~/Documents`) and **From a file…**.
- **Restore** never fires on the first click: the first click only arms the button
  ("Replace settings?") for five seconds, the second replaces. Before replacing, the current
  settings and progress are backed up, so even that step can be undone.
- The copy holds angelOS settings and game progress. It does not touch your personal files,
  installed packages, or configs outside angelOS.

### 2. Updates and rollback

**Settings → Updates** (or `angelos updates`, or `git pull && ./install.sh`).

- The system updates first (`pacman -Syu`), the angelOS files second — a new shell on an old
  Quickshell would leave you without a desktop.
- Before any file changes, every file the installer may write is copied to
  `~/.local/state/angelos/backups/<date>-update/` and read back. Without that copy nothing
  changes.
- An update counts only when the installer, the niri wiring and `niri validate` all pass.
  Otherwise the page offers the restore.
- **Restore** puts back only what this update changed. Files you or angelOS changed afterwards
  stay as they are and are reported as conflicts; files the update created are removed; the
  repository goes back to the old commit.
- **What the snapshot does not cover: system packages.** If the snapshot could not be taken,
  angelOS files were left unchanged, but packages may already have updated — restoring files
  does not downgrade them. For packages use the system's own means (the package cache,
  filesystem snapshots).
- Your lines in `~/.config/fish/user.fish` and `~/.config/niri/cfg/user.kdl` are never touched.
  Files angelOS generates stay yours; new versions wait in
  `~/.local/state/angelos/kept-updates/`.
- Shell will not start? `angelos rescue` shows why, tries again and offers the way back; it opens
  by itself after five failed starts in a minute.

### 3. Games

**Settings → Maintenance → Games** (`scripts/game-doctor.py`).

- **Reset prefix** moves `steamapps/compatdata/<ID>` to `steamapps/angelos-prefix-backups/` and
  deletes nothing: saves inside the moved prefix stay there, and Steam makes a clean prefix on
  the next start.
- **Clear shader cache** works for one game or for all of them (Steam's cache plus NVIDIA/Mesa).
  The first start afterwards takes longer: shaders are compiled again.
- Both actions refuse to run while a game is running, and change nothing in that case.
- The game's Proton version and launch options are not touched here — that is your pick in Steam.

### 4. Laptop power

**Settings → Battery** and **Settings → Laptop**; from the terminal — `angelos laptop …`.

- Eco mode turns on by hand, on battery at or below its threshold, or while the profile is
  "Power saver". It switches the profile to `power-saver` and gives the previous one back when it
  ends.
- If you pick a profile by hand during eco, your choice wins: eco will not restore the old
  profile over it.
- The charge limit, the keyboard backlight and some keys depend on the hardware: when it cannot
  do it, the row is not shown.
- The brightness and backlight keys are written into the niri config and checked with
  `niri validate`. If the check fails, the config is rolled back and left as it was.

### 5. Diagnostics

**Settings → Maintenance → Condition → Diagnostic report → Create and open.**
From the terminal: `angelos report [--out DIR] [--open] [--json]`.

- The archive `angelos-report-<date>-<time>.tar.gz` is written to your home directory (or to
  `--out`) with mode `0600`.
- **Nothing is sent automatically.** Your user name and home path become `<user>` and `~`;
  launcher history, workspace names, plugin data and free texts are left out.
- Logs can still mention window or track titles — look the archive over before sharing it.
- The path is printed together with a link to the new-issue form: attach the archive there.
