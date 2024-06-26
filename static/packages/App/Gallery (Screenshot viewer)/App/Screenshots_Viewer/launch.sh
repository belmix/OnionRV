#!/bin/sh
echo ":: Галерея - Просмотр изображений ::"

infoPanel -d /mnt/SDCARD/Screenshots --show-theme-controls
ec=$?

# cancel or success from infoPanel
if [ $ec -eq 255 ] || [ $ec -eq 0 ]; then
    exit 0
elif [ $ec -eq 1 ]; then
    infoPanel -t Галерея -m "Изображения не найдены"
else
    # something went wrong
    infoPanel -t Галерея -m "An error occurred - code: $ec"
fi
