#!/bin/bash

cmd=$1
# Colors
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

# SD Card Folder :
sysdir=/mnt/SDCARD/.tmp_update

# Repository name :
GITHUB_REPOSITORY=belmix/OnionRV
selected_size=1000
dandyroms_size_unzip=377966157
dandyroms_size_zip=174724730

print_menu()  # selected_item, submenu_indicator, ...menu_items
{
  local function_arguments=($@)

  local selected_item="$1"
  local submenu_indicator=(${function_arguments[1]})
  local menu_items=(${function_arguments[@]:2})
  local menu_size="${#menu_items[@]}"

  for (( i = 0; i < $menu_size; ++i ))
  do
    if [ $i -eq $selected_item ]
    then
      echo -e "\e[1;37;44m${menu_items[i]}\e[0m"  # Highlighted text (white text on blue background)
    elif [ "${submenu_indicator[i]}" = "1" ]
    then
      echo -e "\e[1;37m${menu_items[i]}\e[0m"  # Submenu text (bold yellow text)
    else
      echo -e "\e[1;37m${menu_items[i]}\e[0m"  # Regular text (bold white text)
    fi
  done
}



run_menu()  # selected_item, submenu_indicator, ...menu_items
{
  local function_arguments=($@)

  local selected_item="$1"
  local submenu_indicator=(${function_arguments[1]})
  local menu_items=(${function_arguments[@]:2})
  local menu_size="${#menu_items[@]}"
  local menu_limit=$((menu_size - 1))

  local submenu_level=0
  local submenu_indices=()  # Stack to keep track of submenu indices

  clear

  print_menu "$selected_item" "${submenu_indicator[@]}" "${menu_items[@]}"
    	
  while read -rsn1 input
  do
    case "$input"
    in
      $'\x1B')  # ESC ASCII code
        read -rsn1 -t 0.1 input
        if [ "$input" = "[" ]  # occurs before arrow code
        then
          read -rsn1 -t 0.1 input
          case "$input"
          in
            A)  # Up Arrow
              if [ "$submenu_level" -eq 0 ] && [ "$selected_item" -ge 1 ]
              then
                selected_item=$((selected_item - 1))
                clear
                print_menu "$selected_item" "${submenu_indicator[@]}" "${menu_items[@]}"
              fi
              ;;
            B)  # Down Arrow
              if [ "$submenu_level" -eq 0 ] && [ "$selected_item" -lt "$menu_limit" ]
              then
                selected_item=$((selected_item + 1))
                clear
                print_menu "$selected_item" "${submenu_indicator[@]}" "${menu_items[@]}"
              fi
              ;;
          esac
        fi
        read -rsn5 -t 0.1  # flushing stdin
        ;;
      "")  # Enter key
        if [ "$submenu_level" -eq 0 ]
        then
          return "$selected_item"
        else
          if [ "${menu_items[selected_item]}" = "Back" ]
          then
            submenu_level=$((submenu_level - 1))
            selected_item=${submenu_indices[-1]}  # Pop the last index from stack
            unset 'submenu_indices[${#submenu_indices[@]}-1]'  # Remove the last index from stack
            clear
            print_menu "${selected_item}" "${submenu_indicator[@]}" "${menu_items[@]}"
          else
            # Implement your submenu item selection logic here
            echo "Selected submenu item: ${menu_items[selected_item]}"
          fi
        fi
        ;;
    esac
  done
}

check_available_space() {
	clear
	# Available space in MB on SDCARD
	echo -ne "\n${GREEN}Check available space... ${NC}\n"
	local selected_size="$1"
	mount_point=$(mount | grep -m 1 '/mnt/SDCARD' | awk '{print $1}') # it could be /dev/mmcblk0p1 or /dev/mmcblk0
	# mount_point=$(mount | grep -m 1 '/media/ubuntu/MM' | awk '{print $1}') # for test
	available_space=$(df -m $mount_point | awk 'NR==2{print $4}')
	# Check available space
	if [ "$available_space" -lt $selected_size ]; then
		echo -ne "\n${BLUE}Need space ${GREEN}$((($selected_size / 1024) / 1024)) MB${BLUE} on SD card.${NC}"
		echo -ne "\n${BLUE}Free space ${RED}$available_space MB${BLUE} on SD card.${NC}\n"
		# echo -e "\e[1;33;44m Free space $available_space Mb space is insufficient on SD card\e[0m\n"
		echo -ne "${YELLOW}"
		read -n 1 -s -r -p "Press A to Back"
		exec "$0"
	else
		echo -ne "\n${BLUE}Available space: $available_space Mb...${GREEN} OK\n"
		
	fi
}

enable_wifi() {
	# Enable wifi if necessary
	IP=$(ip route get 1 | awk '{print $NF;exit}')
	if [ "$IP" = "" ]; then
		echo "Wifi is disabled - trying to enable it..."
		insmod /mnt/SDCARD/8188fu.ko
		ifconfig lo up
		/customer/app/axp_test wifion
		sleep 2
		ifconfig wlan0 up
		wpa_supplicant -B -D nl80211 -iwlan0 -c /appconfigs/wpa_supplicant.conf
		udhcpc -i wlan0 -s /etc/init.d/udhcpc.script
		sleep 3
		clear
	fi
}

check_connection() {
	echo -ne "${BLUE}Checking Internet connection..."
	if wget -q --spider https://github.com > /dev/null; then
		echo -e "${GREEN}OK${NC}"
	else
		echo -e "${RED}FAIL${NC}\nError: https://github.com not reachable. Check your wifi connection."
		echo -ne "${YELLOW}"
		read -n 1 -s -r -p "Нажмите A для выхода"
		exit 2
	fi
}


download_dandy() {
	echo -ne "${YELLOW}"
	echo -ne "Size Roms [After Unpack]:    ($((($dandyroms_size_unzip / 1024) / 1024))MB) \n"
	echo -ne "Size Roms [Download]:    ($((($dandyroms_size_zip / 1024) / 1024))MB) \n"
	
	# Confirm downloading
	Mychoice=$(echo -e "No\nYes" | $sysdir/script/shellect.sh -t "Download?" -b "Press A to validate your choice.")
	clear
	
		if [ "$Mychoice" = "Yes" ]; then
			echo -ne "${NC}"
			Release_url='https://a7.androeed.ru/files/2024/01/04/polniisbornikigrnesdendy-1637245061-www.androeed.ru.zip'
			#clear
			mkdir -p /home/ubuntu/Desktop/download/
			echo -e "\n\n" \
			echo -e "${GREEN}================== Downloading Dandy Roms ================== ${NC}"
			sync
			
			wget --no-check-certificate $Release_url -O "$sysdir/download/Dandy.zip"
			#wget --no-check-certificate $Release_url -O "/home/ubuntu/Desktop/download/Dandy.zip"  # for test
			
			echo -ne "\n\n" \
			"${GREEN}================== Download done ==================${NC}\n"
			sync
			sleep 2
			Release_size=174724730
			
			#Downloaded_size=$(stat -c %s "/home/ubuntu/Desktop/download/Dandy.zip")
			Downloaded_size=$(stat -c %s "$sysdir/download/Dandy.zip")
			
		else
			exec "$0"
		fi		
		# Check downloading
		if [ "$Downloaded_size" -eq "$Release_size" ]; then
			echo -e "${GREEN}File size OK!${NC} ($Downloaded_size)"
			sleep 3
		else
			echo -ne "\n\n" \
			"${RED}Error: Wrong download size${NC} ($Downloaded_size instead of $Release_size)\n"
			echo -ne "${YELLOW}"
			read -n 1 -s -r -p "Press A to exit"
			exit 5
		fi
		# Unzip downloading
		#7z x -aoa -o"/home/ubuntu/Desktop/download/ROMS/FC" "/home/ubuntu/Desktop/download/Dandy.zip"
		7z x -aoa -o"/mnt/SDCARD/Roms/FC" "$sysdir/download/Dandy.zip"
		if [ $? -eq 0 ]; then
			echo -e "${GREEN}Decompression successful.${NC}"
			sync
			sleep 3
			echo -ne "\n\n" \
				"Dandy Roms Installed.\n" \
				"Back to menu or Exit...\n"
			echo -ne "${YELLOW}"
			read -n 1 -s -r -p "Press A to Main Menu"
			sleep 1
			exec "$0"
		else
			echo -ne "\n\n" \
				"${RED}Error: Something wrong happened during decompression.${NC}\n" \
				"Try to run again or do a manual.\n"
			echo -ne "${YELLOW}"
			read -n 1 -s -r -p "Press A to exit"
			exit 6
		fi

}

download_dandy_imgs() {
	echo -ne "${YELLOW}"
	read -n 1 -s -r -p "Press A to continue"
	echo -ne "${NC}"
	Release_url='https://s176vlx.storage.yandex.net/rdisk/181ad03358ba2530d138bf8584bb16ae4556efd479e9894cce1be88aa2ecd02f/65a70c73/AcWJeyTZh5u3Ljdv1LSiqAdpHm8QoKZRCs3kkzlDCZScvARCv2OmfWaFM5vQx-ADlX4PnS5ZheqP1rbSc8Focw==?uid=0&filename=FC.zip&disposition=attachment&hash=FJaYCvCSPEkgGoWfxcFAMFN7crbrGkiIOHOCs830O73Hb%2B/AMXIpobW3KkZ3Rnsdq/J6bpmRyOJonT3VoXnDag%3D%3D&limit=0&content_type=application%2Fzip&owner_uid=13891016&fsize=231199271&hid=8a21814378614406e9661568e867588a&media_type=compressed&tknv=v2&rtoken=XQsa9poDPp75&force_default=no&ycrid=na-242b9caf5930d99c16e68f8ead10b094-downloader11e&ts=60f1835b5c2c0&s=9614bc78cc0cc057191a789adf47296e330936fffdb581b48762cd69614318ce&pb=U2FsdGVkX1-FhR7Qel1w599TvORYj-NlQmcK0YEZltBOYJ9FsOxJoxeLKVeqg45ZvNNEmj4mJx_0NJESMbCkwYYuEHP42NqYKNLVClkOYxM'
	# Mychoice=$(echo -e "No\nYes" | $sysdir/script/shellect.sh -t "Download $Release_Version ($((($Release_size / 1024) / 1024))MB) ?" -b "Press A to validate your choice.")
	clear
	#if [ "$Mychoice" = "Yes" ]; then

		#echo -ne "\n${BLUE}================== CHECKDISK ==================${NC}\n"
		#/mnt/SDCARD/.tmp_update/script/stop_audioserver.sh > nul 2> nul # we need a maximum of memory available to run fsck.fat
		#/mnt/SDCARD/.tmp_update/bin/freemma > NUL
		#echo -ne "\n" \
		#	"Please wait during FAT file system integrity check.\n" \
		#	"Issues should be fixed automatically.\n" \
		#	"The process can be long:\n" \
		#	"about 2 minutes for 128GB SD card\n\n\n"
		#fsck.fat -a $mount_point

		mkdir -p $sysdir/download/
		#mkdir -p /home/ubuntu/Desktop/download/
		
		echo -e "\n\n" \
			# "${BLUE}== Downloading Onion $Release_Version ($channel channel) ==${NC}\n"
			echo -e "${GREEN}================== Downloading Dandy Imgs ================== ${NC}"
		#/mnt/SDCARD/.tmp_update/bin/freemma > NUL
		sync
		wget --no-check-certificate $Release_url -O "$sysdir/download/DandyImgs.zip"
		#wget --no-check-certificate $Release_url -O "/home/ubuntu/Desktop/download/DandyImgs.zip"
		echo -ne "\n\n" \
			"${GREEN}================== Download done ==================${NC}\n"
		sync
		sleep 2
	# else
		#exit 4
	# fi
	Release_size=231199271
	Downloaded_size=$(stat -c %s "$sysdir/download/DandyImgs.zip")
	#Downloaded_size=$(stat -c %s "/home/ubuntu/Desktop/download/DandyImgs.zip")

	if [ "$Downloaded_size" -eq "$Release_size" ]; then
		echo -e "${GREEN}File size OK!${NC} ($Downloaded_size)"
		sleep 3
	else
		echo -ne "\n\n" \
			"${RED}Error: Wrong download size${NC} ($Downloaded_size instead of $Release_size)\n"
		echo -ne "${YELLOW}"
		read -n 1 -s -r -p "Press A to exit"
		exit 5
	fi

	# unzip -o "$sysdir/download/$Release_Version.zip" -d "/mnt/SDCARD"
	7z x -aoa -o"/mnt/SDCARD/Roms/FC/Imgs" "$sysdir/download/DandyImgs.zip"
	#7z x -aoa -o"/home/ubuntu/Desktop/download/ROMS" "/home/ubuntu/Desktop/download/DandyImgs.zip"

	if [ $? -eq 0 ]; then
			echo -e "${GREEN}Decompression successful.${NC}"
			sync
			sleep 3
			echo -ne "\n\n" \
				"Dandy Imgs Installed.\n" \
				"Back to menu or Exit...\n"
			echo -ne "${YELLOW}"
			read -n 1 -s -r -p "Press A to Main Menu"
			sleep 1
			exec "$0"
		else
			echo -ne "\n\n" \
				"${RED}Error: Something wrong happened during decompression.${NC}\n" \
				"Try to run again or do a manual.\n"
			echo -ne "${YELLOW}"
			read -n 1 -s -r -p "Press A to exit"
			exit 6
		fi
}

# Usage example:

# Define submenu items
submenu_indicator=('1')  # Indicates which items are submenus
submenu_items=('Dandy' 'Sega' 'Back')

# Define submenu2 items
submenu2_items=('Dandy' 'Sega' 'Back')

# Define main menu items
selected_item=0
menu_items=('Main' 'Roms' 'Imgs' 'Exit')

# Main menu

run_menu "$selected_item" "${submenu_indicator[@]}" "${menu_items[@]}"
menu_result="$?"

# Process the main menu selection
case "$menu_result" 
in
  0)
		echo 'Main item selected'
		;;
  1)
    # Submenu
    submenu_selected_item=0
    run_menu "$submenu_selected_item" "${submenu_indicator[@]}" "${submenu_items[@]}"
    submenu_result="$?"
    
    # Process the submenu selection
    case "$submenu_result" 
	in
      0)
        echo -ne "\n${BLUE}================== DANDY ROMS LOADING ==================${NC}\n"
        check_available_space "$selected_size"
	check_connection
	download_dandy
        # Implement your profile logic here
        ;;
      1)
        echo -ne "\n${BLUE}================== SEGA ROMS LOADING ==================${NC}\n"
        check_available_space
	check_connection
        # Implement your settings logic here
        ;;
      2)
        # Back selected
         exec "$0"
         ;;
    esac
    ;;
  2)
    # Submenu2
    submenu_selected_item=0
    run_menu "$submenu_selected_item" "${submenu_indicator[@]}" "${submenu2_items[@]}"
    submenu_result="$?"
    
    # Process the submenu selection
    case "$submenu_result" 
	in
      0)
        echo -ne "\n${BLUE}================== DANDY IMGS LOADING ==================${NC}\n"
        check_available_space
	check_connection
	download_dandy_imgs
        # Implement your profile logic here
        ;;
      1)
        echo -ne "\n${BLUE}================== SEGA IMGS LOADING ==================${NC}\n"
        check_available_space
	check_connection
        # Implement your settings logic here
        exec "$0"
        ;;
      2)
        # Back selected
         exec "$0"
         ;;
    esac
    ;;
  3)
    echo 'Exit item selected'
    # Implement your exit logic here
    ;;
esac
