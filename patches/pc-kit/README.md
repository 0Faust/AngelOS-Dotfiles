# pc-kit: сохранение выбранных обоев

Патч исправляет плагины Night 2004 и AngelOS Room из [Frostpix11/pc-kit-share](https://github.com/Frostpix11/pc-kit-share): при запуске оболочки они сохраняют обои, выбранные пользователем. Явный выбор сцены в настройках плагина продолжает работать.

Патч подготовлен для локальной копии pc-kit на основе снимка `2d3a820`. Проверьте совместимость и примените его из каталога pc-kit:

```sh
cd ~/pc-kit
git apply --check ~/AngelOS-Dotfiles/patches/pc-kit/preserve-selected-wallpaper.patch
git apply ~/AngelOS-Dotfiles/patches/pc-kit/preserve-selected-wallpaper.patch
```

Затем обновите только изменённые файлы установленных плагинов и перезапустите оболочку:

```sh
cp files/plugins/angelos-night-2004/NightService.qml ~/.config/angelos/plugins/angelos-night-2004/
cp files/codex-plugins/AngelOS-Room/plugin/RoomService.qml ~/.config/angelos/plugins/angelos-room/
angelos restart
```

Сам pc-kit хранится отдельно от этого репозитория; патч не устанавливается автоматически установщиком AngelOS.
