#!/bin/sh
echo "> randomGamePicker $*"
sysdir=/mnt/SDCARD/.tmp_update

result=`randomGamePicker $*`

if [ $? -eq 99 ]; then
    infoPanel --title "СЛУЧАЙНАЯ ИГРА" --message "Игры не найдены\n \nПроверьте каталог roms\nна наличие игр." --auto
    exit 1
fi

get_info_value() {
    echo "$1" | grep "$2\b" | awk '{split($0,a,"="); print a[2]}'
}

echo "$result"

emuname=`get_info_value "$result" emu`
label=`get_info_value "$result" label`
rompath=`get_info_value "$result" path`
imgpath=`get_info_value "$result" img`
launchpath=`get_info_value "$result" launch`

infoPanel -t "СЛУЧАЙНАЯ ИГРА" -i "$imgpath" -m "$(echo "$label" | fold -s -w 35)\n \n$emuname"
retcode=$?

echo "retcode: $retcode"

if [ $retcode -ne 0 ]; then
    echo "отмена случайной игры..."
    rm -f $sysdir/cmd_to_run.sh 2> /dev/null
    exit 1
fi

# Build recent list entry 
recentlist=/mnt/SDCARD/Roms/recentlist.json
recentlist_hidden=/mnt/SDCARD/Roms/recentlist-hidden.json
recentlist_temp=/tmp/recentlist-temp.json

if [ ! -f $sysdir/config/.showRecents ]; then
    currentrecentlist=$recentlist_hidden
else
    currentrecentlist=$recentlist
fi

if [ -e "$imgpath" ]; then
    recentFileLine="{\"label\":\"$label\",\"rompath\":\"$rompath\",\"imgpath\":\"$imgpath\",\"launch\":\"$launchpath\",\"type\":5}"
else
    recentFileLine="{\"label\":\"$label\",\"rompath\":\"$rompath\",\"launch\":\"$launchpath\",\"type\":5}"
fi

echo "$recentFileLine" | cat - $currentrecentlist > $recentlist_temp && mv $recentlist_temp $currentrecentlist
