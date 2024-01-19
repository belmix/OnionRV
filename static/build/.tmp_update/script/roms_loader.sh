#!/bin/sh
# ROMS AND IMAGES LOADER.

cmd=$1

sysdir=/mnt/SDCARD/.tmp_update
romdir=/mnt/SDCARD/Roms
maindir=/mnt/SDCARD
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

MDROMS_ZIP=883618987
MDROMS_UNZIP=886683570
FCROMS_ZIP=168866352
FCROMS_UNZIP=378236539
FCIMGS_ZIP=233087854
FCIMGS_UNZIP=235316350
MDIMGS_ZIP=258982930
MDIMGS_UNZIP=259391146

main() {
	check_available_space
	clean_temp
	# check_connection
	run_bootstrap
	sleep 2
	main_menu
}

clean_temp() {
  echo -e "${GREEN}Check old Roms and Imgs Zip archives${NC}"

  rom_files="FC/FCRoms.zip FC/FCROMS.zip MD/MDRoms.zip MD/MDROMS.zip FC/FCIMGS.zip FC/FCImgs.zip MD/MDIMGS.zip MD/MDImgs.zip"

  removal_failed=false

  for file in $rom_files; do
    if [ -f "$romdir/$file" ]; then
      if ! rm "$romdir/$file"; then
        removal_failed=true
      fi
    fi
  done

  if [ "$removal_failed" = true ]; then
    echo -e "${YELLOW}Check...${GREEN} OK${NC}\n"
  else
    echo -e "${YELLOW}Check...${GREEN} OK${NC}\n"
  fi
  sleep 1
}

clean_refresh() {
  echo -e "${GREEN}Fix Refresh Roms${NC}"

  rom_files="FC/miyoogamelist.xml FC/miyoogamelist.xml.bak MD/miyoogamelist.xml MD/miyoogamelist.xml.bak"

  removal_failed=false

  for file in $rom_files; do
    if [ -f "$romdir/$file" ]; then
      if ! rm "$romdir/$file"; then
        removal_failed=true
      fi
    fi
  done

  if [ "$removal_failed" = true ]; then
    echo -e "${YELLOW}Delete miyoogamelist.xml for MD and FC...${GREEN} OK${NC}\n"
  else
    echo -e "${YELLOW}Delete miyoogamelist.xml for MD and FC...${GREEN} OK${NC}\n"
  fi
  sleep 1
}

run_bootstrap() {
	curl -k -s https://raw.githubusercontent.com/belmix/OnionRV/main/static/build/.tmp_update/script/ota_bootstrap.sh | sh
}

check_available_space() {
  # Available space in MB
  mount_point=$(mount | grep -m 1 '/mnt/SDCARD' | awk '{print $1}') # it could be /dev/mmcblk0p1 or /dev/mmcblk0
  available_space=$(df -m "$mount_point" | awk 'NR==2{print $4}')

  if [ "$available_space" -lt "1000" ]; then
    echo -e "${RED}Available space is insufficient on the SD card${NC}\n"
    read -n 1 -s -r -p "${YELLOW}Press any key to exit"
    exit 1
  else
    echo "Sufficient space available on the SD card. ($available_space)"
  fi
}


check_connection() {
	echo -n "Checking Internet connection... "
	if wget -q --spider http://beluc.ru > /dev/null; then
		echo -e "${GREEN}OK${NC}"
	else
		echo -e "${RED}FAIL${NC}\nError: Internet not reachable. Check your wifi connection."
		echo -ne "${YELLOW}"
		read -n 1 -s -r -p "Press A for exit"
		exit 2
	fi
}

# main menu
main_menu() {
  clear
  choice=$(echo -e "Manage Roms\nManage Imgs\nManage Themes\nExit" | $sysdir/script/shellect.sh -t "Roms and Imgs for OnionRV:" -b "Press A to validate your choice.")
  clear
  if [ "$choice" = "Manage Roms" ]; then
    roms_menu
  elif [ "$choice" = "Manage Imgs" ]; then
    img_menu
  elif [ "$choice" = "Manage Themes" ]; then
    themes_menu
  else
    exit 3
  fi
}

# roms menu
roms_menu() {
  roms_choice=$(echo -e "Dandy Roms\nSega Roms\nBack" | $sysdir/script/shellect.sh -t "Roms Menu:" -b "Press A to validate your choice.")
  clear
  
  if [ "$roms_choice" = "Dandy Roms" ]; then
    echo -ne "${BLUE}===== Downloading $roms_choice (1634 Roms) =====${NC}\n"
		/mnt/SDCARD/.tmp_update/script/stop_audioserver.sh > nul 2> nul # we need a maximum of memory available to run fsck.fat
		/mnt/SDCARD/.tmp_update/bin/freemma > NUL
		mount_point=$(mount | grep -m 1 '/mnt/SDCARD' | awk '{print $1}') # it could be /dev/mmcblk0p1 or /dev/mmcblk0
		available_space=$(df -m "$mount_point" | awk 'NR==2{print $4}')
		if [ "$available_space" -lt "521" ]; then
			echo -e "${RED}Free space available $available_space MB on the SD card${NC}\n"
			echo -e "${YELLOW}At least ($(((547102891 / 1024) / 1024)) MB) is required\nfor temporary files and unpacking!${NC}\n"
			echo -ne "${YELLOW}"
			read -n 1 -s -r -p "Press A to Main Menu"
			main_menu
		else
			echo -e "${YELLOW}Need place - ${GREEN}($(((547102891 / 1024) / 1024))MB)\n${YELLOW}Available space - ${GREEN}($available_space MB)${NC}\n"
			echo -e "${GREEN}OK${NC}"
			sleep 1
			mkdir -p $romdir/FC/
			echo -ne "\n\n" \
			"${BLUE}===== Downloading ($roms_choice) =====${NC}\n"
			/mnt/SDCARD/.tmp_update/bin/freemma > NUL
			Release_url='http://beluc.ru/FCRoms.zip'
			# rm "$romdir/FC/FCRoms.zip"
			sync
			
			wget --no-check-certificate $Release_url -O "$romdir/FC/FCRoms.zip"
				wget_exit_status=$?
				if [ $wget_exit_status -ne 0 ]; then
					echo -e "${RED}Error: Failed to download $roms_choice. Please try again.${NC}"
					echo -ne "${YELLOW}"
					read -n 1 -s -r -p "Press A to Main Menu"
					main_menu
				else
					echo -ne "\n\n" \
					"${GREEN}================== Download done ==================${NC}\n"
					sync
					sleep 2
					apply_romsfc
				fi			
		fi

  elif [ "$roms_choice" = "Sega Roms" ]; then
	echo -ne "${BLUE}===== Downloading $roms_choice (1247 Roms) =====${NC}\n"
		/mnt/SDCARD/.tmp_update/script/stop_audioserver.sh > nul 2> nul # we need a maximum of memory available to run fsck.fat
		/mnt/SDCARD/.tmp_update/bin/freemma > NUL
		
		mount_point=$(mount | grep -m 1 '/mnt/SDCARD' | awk '{print $1}') # it could be /dev/mmcblk0p1 or /dev/mmcblk0
		available_space=$(df -m "$mount_point" | awk 'NR==2{print $4}')
		if [ "$available_space" -lt "1688" ]; then
			echo -e "${RED}Free space available $available_space MB on the SD card${NC}\n"
			echo -e "${YELLOW}At least ($(((1770302557 / 1024) / 1024)) MB) is required\nfor temporary files and unpacking!${NC}\n"
			echo -ne "${YELLOW}"
			read -n 1 -s -r -p "Press A to Main Menu"
			main_menu
		else
			echo -e "${YELLOW}Need place - ${GREEN}($(((1770302557 / 1024) / 1024))MB)\n${YELLOW}Available space - ${GREEN}($available_space MB)${NC}\n"
			echo -e "${GREEN}OK${NC}"
			sleep 1
			mkdir -p $romdir/MD/
			echo -ne "\n\n" \
			"${BLUE}===== Downloading ($roms_choice) =====${NC}\n"
			/mnt/SDCARD/.tmp_update/bin/freemma > NUL
			Release_url='http://beluc.ru/MDRoms.zip'
			sync
			wget --no-check-certificate $Release_url -O "$romdir/MD/MDRoms.zip"
				wget_exit_status=$?
				if [ $wget_exit_status -ne 0 ]; then
					echo -e "${RED}Error: Failed to download $roms_choice. Please try again.${NC}"
					echo -ne "${YELLOW}"
					read -n 1 -s -r -p "Press A to Main Menu"
					main_menu
				else
					echo -ne "\n\n" \
					"${GREEN}================== Download done ==================${NC}\n"
					sync
					sleep 2
					apply_romsmd
				fi
		fi
  elif [ "$roms_choice" = "Back" ]; then
    main_menu  # Return to the main menu
  fi
}

# images menu
img_menu() {
  img_choice=$(echo -e "Dandy Imgs\nSega Imgs\nBack" | $sysdir/script/shellect.sh -t "Images Menu:" -b "Press A to validate your choice.")
  clear
  if [ "$img_choice" = "Dandy Imgs" ]; then
	echo -ne "${BLUE}===== $img_choice (4552 Imgs) =====${NC}\n"
		/mnt/SDCARD/.tmp_update/script/stop_audioserver.sh > nul 2> nul # we need a maximum of memory available to run fsck.fat
		/mnt/SDCARD/.tmp_update/bin/freemma > NUL
		mount_point=$(mount | grep -m 1 '/mnt/SDCARD' | awk '{print $1}') # it could be /dev/mmcblk0p1 or /dev/mmcblk0
		available_space=$(df -m "$mount_point" | awk 'NR==2{print $4}')
		if [ "$available_space" -lt "446" ]; then
			echo -e "${RED}Free space available $available_space MB on the SD card${NC}\n"
			echo -e "${YELLOW}At least ($(((468404204 / 1024) / 1024)) MB) is required\nfor temporary files and unpacking!${NC}\n"
			echo -ne "${YELLOW}"
			read -n 1 -s -r -p "Press A to Main Menu"
			main_menu
		else
			echo -e "${YELLOW}Need place - ${GREEN}($(((468404204 / 1024) / 1024)) MB)\n${YELLOW}Available space - ${GREEN}($available_space MB)${NC}\n"
			echo -e "${GREEN}OK${NC}"
			sleep 1
			mkdir -p $romdir/FC/
			echo -ne "\n\n" \
				"${BLUE}===== Downloading ($img_choice) =====${NC}\n"
			/mnt/SDCARD/.tmp_update/bin/freemma > NUL
			Release_url='http://beluc.ru/FCImgs.zip'
			sync
			wget --no-check-certificate $Release_url -O "$romdir/FC/FCImgs.zip"
				wget_exit_status=$?
				if [ $wget_exit_status -ne 0 ]; then
					echo -e "${RED}Error: Failed to download $img_choice. Please try again.${NC}"
					echo -ne "${YELLOW}"
					read -n 1 -s -r -p "Press A to Main Menu"
					main_menu
				else
					echo -ne "\n\n" \
					"${GREEN}================== Download done ==================${NC}\n"
					sync
					sleep 2
					apply_imgfc
				fi	
		fi
  elif [ "$img_choice" = "Sega Imgs" ]; then
		echo -ne "${BLUE}===== $img_choice (2694 Imgs) =====${NC}\n"
		/mnt/SDCARD/.tmp_update/script/stop_audioserver.sh > nul 2> nul # we need a maximum of memory available to run fsck.fat
		/mnt/SDCARD/.tmp_update/bin/freemma > NUL
		mount_point=$(mount | grep -m 1 '/mnt/SDCARD' | awk '{print $1}') # it could be /dev/mmcblk0p1 or /dev/mmcblk0
		available_space=$(df -m "$mount_point" | awk 'NR==2{print $4}')
		if [ "$available_space" -lt "494" ]; then
			echo -e "${RED}Free space available $available_space MB on the SD card${NC}\n"
			echo -e "${YELLOW}At least ($(((518374076 / 1024) / 1024)) MB) is required\nfor temporary files and unpacking!${NC}\n"
			echo -ne "${YELLOW}"
			read -n 1 -s -r -p "Press A to Main Menu"
			main_menu
		else
			echo -e "${YELLOW}Need place - ${GREEN}($(((518374076 / 1024) / 1024)) MB)\n${YELLOW}Available space - ${GREEN}($available_space MB)${NC}\n"
			echo -e "${GREEN}OK${NC}"
			sleep 1
			mkdir -p $romdir/MD/
			echo -ne "\n\n" \
			"${BLUE}===== Downloading ($img_choice) =====${NC}\n"
			/mnt/SDCARD/.tmp_update/bin/freemma > NUL
			Release_url='http://beluc.ru/MDImgs.zip'
			sync
			wget --no-check-certificate $Release_url -O "$romdir/MD/MDImgs.zip"
				wget_exit_status=$?
				if [ $wget_exit_status -ne 0 ]; then
					echo -e "${RED}Error: Failed to download $img_choice. Please try again.${NC}"
					echo -ne "${YELLOW}"
					read -n 1 -s -r -p "Press A to Main Menu"
					main_menu
				else
					echo -ne "\n\n" \
					"${GREEN}================== Download done ==================${NC}\n"
					sync
					sleep 2
					apply_imgmd
				fi	
		fi
  elif [ "$img_choice" = "Back" ]; then
    main_menu  # Return to the main menu
  fi
}

themes_menu() {
  themes_choice=$(echo -e "Themes Onion RV 2024\nBack" | $sysdir/script/shellect.sh -t "Themes Menu:" -b "Press A to validate your choice.")
  clear
  if [ "$themes_choice" = "Themes Onion RV 2024" ]; then
	echo -ne "${BLUE}===== $themes_choice  =====${NC}\n"
		/mnt/SDCARD/.tmp_update/script/stop_audioserver.sh > nul 2> nul # we need a maximum of memory available to run fsck.fat
		/mnt/SDCARD/.tmp_update/bin/freemma > NUL
		mkdir -p $maindir/Themes/
		echo -ne "\n\n" \
			"${BLUE}===== Downloading ($themes_choice)  =====${NC}\n"
		/mnt/SDCARD/.tmp_update/bin/freemma > NUL
		Release_url='http://beluc.ru/OnionRV2024.zip'
		rm "$maindir/Themes/OnionRV2024.zip"
		sync
		
		wget --no-check-certificate $Release_url -O "$maindir/Themes/OnionRV2024.zip"
				wget_exit_status=$?
				if [ $wget_exit_status -ne 0 ]; then
					echo -e "${RED}Error: Failed to download $themes_choice. Please try again.${NC}"
					echo -ne "${YELLOW}"
					read -n 1 -s -r -p "Press A to Main Menu"
					main_menu
				else
					"${GREEN}================== Download done ==================${NC}\n"
					sync
					echo -ne "\n\n" \
						"Theme install.\n" \
						"Select theme in Menu Design.\n"
					echo -ne "${YELLOW}"
					read -n 1 -s -r -p "Press A to Main Menu"
					sleep 2
					main_menu
				fi			
  elif [ "$themes_choice" = "Back" ]; then
    main_menu  # Return to the main menu
  fi
}



apply_romsfc() {
	Mychoice=$(echo -e "No\nYes" | $sysdir/script/shellect.sh -t "Install Roms ?" -b "Press A to validate your choice.")
	clear
	
	if [ "$Mychoice" = "Yes" ]; then
		echo "Unpack Roms..."

		umount /mnt/SDCARD/miyoo/app/MainUI 2> /dev/null
		/mnt/SDCARD/.tmp_update/bin/freemma > NUL

		7z x -aoa -o"/mnt/SDCARD/Roms/FC" "$romdir/FC/FCRoms.zip"

		if [ $? -eq 0 ]; then
			echo -e "${GREEN}Decompression successful.${NC}"
			sync
			sleep 3
			echo -e "${GREEN}Delete temp file.${NC}"
			rm "$romdir/FC/FCRoms.zip"
			echo -e "${GREEN}Fix FC Roms refresh.${NC}"
			clean_refresh
			sleep 1
			echo -ne "\n\n" \
				"Unpack Roms complite.\n" \
				"Refresh Roms in Menu.\n"
			echo -ne "${YELLOW}"
			read -n 1 -s -r -p "Press A to Main Menu"
			sleep 1
			main_menu
		else
			echo -ne "\n\n" \
				"${RED}Error: Something wrong happened during decompression.${NC}\n" \
				"Try to run again or do a manual.\n"
			echo -ne "${YELLOW}"
			read -n 1 -s -r -p "Press A to Main Menu"
			main_menu
		fi
	else
		main_menu
	fi
}

apply_romsmd() {
	Mychoice=$(echo -e "No\nYes" | $sysdir/script/shellect.sh -t "Install Roms ?" -b "Press A to validate your choice.")
	clear
	
	if [ "$Mychoice" = "Yes" ]; then
		echo "Unpack Roms..."

		umount /mnt/SDCARD/miyoo/app/MainUI 2> /dev/null
		/mnt/SDCARD/.tmp_update/bin/freemma > NUL

		7z x -aoa -o"/mnt/SDCARD/Roms/MD" "$romdir/MD/MDRoms.zip"

		if [ $? -eq 0 ]; then
			echo -e "${GREEN}Decompression successful.${NC}"
			sync
			sleep 3
			echo -e "${GREEN}Delete temp file.${NC}"
			rm "$romdir/MD/MDRoms.zip"
			echo -e "${GREEN}Fix MD Roms refresh.${NC}"
			clean_refresh
			sleep 1
			echo -ne "\n\n" \
				"Unpack Roms complite.\n" \
				"Refresh Roms in Menu.\n"
			echo -ne "${YELLOW}"
			read -n 1 -s -r -p "Press A to Main Menu"
			sleep 1
			main_menu
		else
			echo -ne "\n\n" \
				"${RED}Error: Something wrong happened during decompression.${NC}\n" \
				"Try to run again or do a manual.\n"
			echo -ne "${YELLOW}"
			read -n 1 -s -r -p "Press A to Main Menu"
			main_menu
		fi
	else
		main_menu
	fi
}


apply_imgfc() {
	Mychoice=$(echo -e "No\nYes" | $sysdir/script/shellect.sh -t "Install Imgs ?" -b "Press A to validate your choice.")
	clear
	
	if [ "$Mychoice" = "Yes" ]; then
		echo "Unpack Imgs..."

		umount /mnt/SDCARD/miyoo/app/MainUI 2> /dev/null
		/mnt/SDCARD/.tmp_update/bin/freemma > NUL





		7z x -aoa -o"/mnt/SDCARD/Roms/FC" "$romdir/FC/FCImgs.zip"

		if [ $? -eq 0 ]; then
			echo -e "${GREEN}Decompression successful.${NC}"
			sync
			sleep 3
			echo -e "${GREEN}Delete temp file.${NC}"
			rm "$romdir/FC/FCImgs.zip"
			sleep 1
			echo -ne "\n\n" \
				"Unpack Imgs complite.\n" \
				"Done.\n"
			echo -ne "${YELLOW}"
			read -n 1 -s -r -p "Press A to Main Menu"
			sleep 1
			main_menu
		else
			echo -ne "\n\n" \
				"${RED}Error: Something wrong happened during decompression.${NC}\n" \
				"Try to run again or do a manual.\n"
			echo -ne "${YELLOW}"
			read -n 1 -s -r -p "Press A to Main Menu"
			main_menu
		fi
		
		
		
	else
		main_menu
	fi
}

apply_imgmd() {
	Mychoice=$(echo -e "No\nYes" | $sysdir/script/shellect.sh -t "Install Imgs ?" -b "Press A to validate your choice.")
	clear
	
	if [ "$Mychoice" = "Yes" ]; then
		echo "Unpack Imgs..."

		umount /mnt/SDCARD/miyoo/app/MainUI 2> /dev/null
		/mnt/SDCARD/.tmp_update/bin/freemma > NUL

		7z x -aoa -o"/mnt/SDCARD/Roms/MD" "$romdir/MD/MDImgs.zip"

		if [ $? -eq 0 ]; then
			echo -e "${GREEN}Decompression successful.${NC}"
			sync
			sleep 3
			echo -e "${GREEN}Delete temp file.${NC}"
			rm "$romdir/MD/MDImgs.zip"
			sleep 1
			echo -ne "\n\n" \
				"Unpack Imgs complite.\n" \
				"Done.\n"
			echo -ne "${YELLOW}"
			sleep 1
			read -n 1 -s -r -p "Press A to Main Menu"
			main_menu
		else
			echo -ne "\n\n" \
				"${RED}Error: Something wrong happened during decompression.${NC}\n" \
				"Try to run again or do a manual.\n"
			echo -ne "${YELLOW}"
			read -n 1 -s -r -p "Press A to Main Menu"
			main_menu
		fi
	else
		main_menu
	fi
}

main
