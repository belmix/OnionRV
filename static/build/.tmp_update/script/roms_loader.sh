#!/bin/sh
# OTA updates for Onion.
cmd=$1
sysdir=/mnt/SDCARD/.tmp_update

# Colors
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

# Repository name :
GITHUB_REPOSITORY=belmix/OnionRV

# Define submenu items
submenu_indicator=('1')  # Indicates which items are submenus
submenu_items=('Dandy' 'Sega' 'Back')

# Define submenu2 items
submenu2_items=('Profile' 'Settings' 'Back')

# Define main menu items
selected_item=0
menu_items=('Main' 'Submenu' 'Submenu2' 'Exit')

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
      echo -e "\e[1;37;44m ${menu_items[i]}\e[0m"  # Highlighted text (white text on blue background)
    elif [ "${submenu_indicator[i]}" = "1" ]
    then
      echo -e "\e[1;33m ${menu_items[i]}\e[0m"  # Submenu text (bold yellow text)
    else
      echo -e "\e[1;37m ${menu_items[i]}\e[0m"  # Regular text (bold white text)
    fi
  done
}

main()  # selected_item, submenu_indicator, ...menu_items
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
      "c")  # Enter 'c' key (for "choose" submenu)
        if [ "${submenu_indicator[selected_item]}" = "1" ]
        then
          submenu_level=$((submenu_level + 1))
          submenu_indices+=("$selected_item")
          selected_item=0  # Select the first item of the submenu
          clear
          print_menu "$selected_item" "${submenu_indicator[@]}" "${menu_items[@]}"
        fi
        ;;
      "b")  # Enter 'b' key (for "back" from submenu)
        if [ "$submenu_level" -gt 0 ]
        then
          submenu_level=$((submenu_level - 1))
          selected_item=${submenu_indices[-1]}  # Pop the last index from stack
          unset 'submenu_indices[${#submenu_indices[@]}-1]'  # Remove the last index from stack
          clear
          print_menu "$selected_item" "${submenu_indicator[@]}" "${menu_items[@]}"
        fi
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

# Usage example:



# Main menu
main "$selected_item" "${submenu_indicator[@]}" "${menu_items[@]}"
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
    main "$submenu_selected_item" "${submenu_indicator[@]}" "${submenu_items[@]}"
    submenu_result="$?"
    
    # Process the submenu selection
    case "$submenu_result" 
	in
      0)
        echo 'Dandy item selected'
        # Implement your profile logic here
        ;;
      1)
        echo 'Sega item selected'
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
    main "$submenu_selected_item" "${submenu_indicator[@]}" "${submenu2_items[@]}"
    submenu_result="$?"
    
    # Process the submenu selection
    case "$submenu_result" 
	in
      0)
        echo 'Profile item selected'
        # Implement your profile logic here
        ;;
      1)
        echo 'Settings item selected'
        # Implement your settings logic here
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

