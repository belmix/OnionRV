#!/bin/sh
echo ":: Галерея - Просмотр изображений ::"

/mnt/SDCARD/.tmp_update/bin/infoPanel -d /mnt/SDCARD/Screenshots --show-theme-controls
ec=$?

if [ $ec -ne 0 ]; then
    /mnt/SDCARD/.tmp_update/bin/infoPanel -t Gallery -m "Изображения не найдены"
fi
