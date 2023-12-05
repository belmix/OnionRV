#ifndef TWEAKS_MENUS_H__
#define TWEAKS_MENUS_H__

#include <SDL/SDL_image.h>
#include <dirent.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#include "components/list.h"
#include "system/device_model.h"
#include "system/display.h"
#include "utils/apps.h"

#include "./actions.h"
#include "./appstate.h"
#include "./diags.h"
#include "./formatters.h"
#include "./icons.h"
#include "./network.h"
#include "./reset.h"
#include "./tools.h"
#include "./values.h"

void menu_systemStartup(void *_)
{
    if (!_menu_system_startup._created) {
        _menu_system_startup = list_createWithTitle(3, LIST_SMALL, "Включение консоли");

        list_addItemWithInfoNote(&_menu_system_startup,
                                 (ListItem){
                                     .label = "Вернуться в игру",
                                     .item_type = TOGGLE,
                                     .value = (int)settings.startup_auto_resume,
                                     .action = action_setStartupAutoResume},
                                 "Автоматическое возобновление при выключении\n"
                                 "устройство включается с запущенной игры.\n"
                                 "При запуске система возобновит работу\n"
                                 "там где вы остановились в прошлый раз.");
        list_addItemWithInfoNote(&_menu_system_startup,
                                 (ListItem){
                                     .label = "Запускать приложение",
                                     .item_type = MULTIVALUE,
                                     .value_max = 3,
                                     .value_labels = {"Главное меню", "Быстрый доступ", "RetroArch", "Расширенное меню"},
                                     .value = settings.startup_application,
                                     .action = action_setStartupApplication},
                                 "С помощью этой опции вы можете выбрать,\n"
                                 "какой интерфейс показывать, при включении\n"
                                 "консоли.");
        list_addItemWithInfoNote(&_menu_system_startup,
                                 (ListItem){
                                     .label = "Запускать вкладку",
                                     .item_type = MULTIVALUE,
                                     .value_max = 5,
                                     .value_formatter = formatter_startupTab,
                                     .value = settings.startup_tab,
                                     .action = action_setStartupTab},
                                 "Здесь вы можете установить, какую\n"
                                 "вкладку вы хотите запусить при\n"
                                 "включении консоли.");
    }
    menu_stack[++menu_level] = &_menu_system_startup;
    header_changed = true;
}

void menu_systemDisplay(void *_)
{
    if (!_menu_system_display._created) {
        _menu_system_display = list_createWithTitle(1, LIST_SMALL, "Экран");
    }
    menu_stack[++menu_level] = &_menu_system_display;
    header_changed = true;
}

bool _writeDateString(char *label_out)
{
    char new_label[STR_MAX];
    time_t t = time(NULL);
    struct tm tm = *localtime(&t);
    strftime(new_label, STR_MAX - 1, "Текущее: %Y-%m-%d %H:%M:%S", &tm);
    if (strncmp(new_label, label_out, STR_MAX) != 0) {
        strcpy(label_out, new_label);
        return true;
    }
    return false;
}

void menu_datetime(void *_)
{
    if (!_menu_date_time._created) {
        _menu_date_time = list_create(6, LIST_SMALL);
        strcpy(_menu_date_time.title, "Дата и время");
        list_addItem(&_menu_date_time,
                     (ListItem){
                         .label = "[DATESTRING]",
                         .disabled = 1,
                         .action = NULL});

        network_loadState();

        if (DEVICE_ID == MIYOO354 || network_state.ntp) {
            list_addItemWithInfoNote(&_menu_date_time,
                                     (ListItem){
                                         .label = "Синхронизация по интернету",
                                         .item_type = TOGGLE,
                                         .value = (int)network_state.ntp,
                                         .action = network_setNtpState},
                                     "Use the internet connection to sync\n"
                                     "date and time on startup.");
        }
        if (DEVICE_ID == MIYOO354) {
            list_addItemWithInfoNote(&_menu_date_time,
                                     (ListItem){
                                         .label = "Синхронизировать при включении",
                                         .item_type = TOGGLE,
                                         .disabled = !network_state.ntp,
                                         .value = (int)network_state.ntp_wait,
                                         .action = network_setNtpWaitState},
                                     "Wait for date and time synchronization\n"
                                     "on system startup."
                                     " \n"
                                     "Ensures that time is synced before a game\n"
                                     "is launched.");
            list_addItemWithInfoNote(&_menu_date_time,
                                     (ListItem){
                                         .label = "Часовой пояс по IP адресу",
                                         .item_type = TOGGLE,
                                         .disabled = !network_state.ntp,
                                         .value = !network_state.manual_tz,
                                         .action = network_setTzManualState},
                                     "If this is enabled, the system will try\n"
                                     "to retrieve your time zone from your IP\n"
                                     "address."
                                     " \n"
                                     "It might be beneficial to disable this\n"
                                     "option if you're on a VPN.");
            list_addItemWithInfoNote(&_menu_date_time,
                                     (ListItem){
                                         .label = "Выбрать часовой пояс",
                                         .item_type = MULTIVALUE,
                                         .disabled = !network_state.ntp || !network_state.manual_tz,
                                         .value_max = 48,
                                         .value_formatter = formatter_timezone,
                                         .value = value_timezone(),
                                         .action = network_setTzSelectState},
                                     "Manually set your time zone.\n"
                                     "You need to adjust for DST as well.");
        }
        list_addItemWithInfoNote(&_menu_date_time,
                                 (ListItem){
                                     .label = "Эмулировать пропущ. вермя",
                                     .item_type = MULTIVALUE,
                                     .disabled = network_state.ntp,
                                     .value_max = 24,
                                     .value_formatter = formatter_timeSkip,
                                     .value = settings.time_skip,
                                     .action = action_setTimeSkip},
                                 "Without RTC the system time stands still\n"
                                 "while the device is off.\n"
                                 "This option lets you add a specific amount\n"
                                 "of hours at startup.");
    }
    _writeDateString(_menu_date_time.items[0].label);
    menu_stack[++menu_level] = &_menu_date_time;
    header_changed = true;
}

void menu_system(void *_)
{
    if (!_menu_system._created) {
        _menu_system = list_createWithTitle(6, LIST_SMALL, "Система");
        list_addItem(&_menu_system,
                     (ListItem){
                         .label = "Включение...",
                         .action = menu_systemStartup});
        // list_addItem(&_menu_system,
        //              (ListItem){
        //                  .label = "Display...",
        //                  .action = menu_systemDisplay});
        list_addItem(&_menu_system,
                     (ListItem){
                         .label = "Дата и время...",
                         .action = menu_datetime});
        list_addItemWithInfoNote(&_menu_system,
                                 (ListItem){
                                     .label = "Индик. низкого заряда",
                                     .item_type = MULTIVALUE,
                                     .value_max = 5,
                                     .value_formatter = formatter_battWarn,
                                     .value = settings.low_battery_warn_at / 5,
                                     .action = action_setLowBatteryWarnAt},
                                 "Отобразить предупреждение о красным значком батареи в\n"
                                 "верхнем правом углу, когда батарея разряжена или\n"
                                 "ниже заданого значения.");
        list_addItemWithInfoNote(&_menu_system,
                                 (ListItem){
                                     .label = "Авто выключение",
                                     .item_type = MULTIVALUE,
                                     .value_max = 5,
                                     .value_formatter = formatter_battExit,
                                     .value = settings.low_battery_autosave_at,
                                     .action = action_setLowBatteryAutoSave},
                                 "Установите процент заряда батареи, при котором\n"
                                 "система должна сохранить RetroArch и выключиться.");
        list_addItemWithInfoNote(&_menu_system,
                                 (ListItem){
                                     .label = "Вибрация",
                                     .item_type = MULTIVALUE,
                                     .value_max = 3,
                                     .value_labels = {"Выкл", "Слабая", "Норма", "Сильная"},
                                     .value = settings.vibration,
                                     .action = action_setVibration},
                                 "Установите силу вибрации для тактильного\n"
                                 "отклика при нажатии системных клавиш быстрого доступа.");
    }
    menu_stack[++menu_level] = &_menu_system;
    header_changed = true;
}

void menu_buttonActionMainUIMenu(void *_)
{
    if (!_menu_button_action_mainui_menu._created) {
        _menu_button_action_mainui_menu = list_create(3, LIST_SMALL);
        strcpy(_menu_button_action_mainui_menu.title, "Кнопка Меню в главном меню");
        list_addItemWithInfoNote(&_menu_button_action_mainui_menu,
                                 (ListItem){
                                     .label = "Быстрое нажатие",
                                     .item_type = MULTIVALUE,
                                     .value_max = 2,
                                     .value_labels = BUTTON_MAINUI_LABELS,
                                     .value = settings.mainui_single_press,
                                     .action_id = 0,
                                     .action = action_setMenuButtonKeymap},
                                 "Установите действие для однократного нажатия\n"
                                 "кнопки Меню в Главном меню.");
        list_addItemWithInfoNote(&_menu_button_action_mainui_menu,
                                 (ListItem){
                                     .label = "Долгое удержание",
                                     .item_type = MULTIVALUE,
                                     .value_max = 2,
                                     .value_labels = BUTTON_MAINUI_LABELS,
                                     .value = settings.mainui_long_press,
                                     .action_id = 1,
                                     .action = action_setMenuButtonKeymap},
                                 "Установите действие для долгого нажатия\n"
                                 "кнопки Меню в Главном меню.");
        list_addItemWithInfoNote(&_menu_button_action_mainui_menu,
                                 (ListItem){
                                     .label = "Двойное нажатие",
                                     .item_type = MULTIVALUE,
                                     .value_max = 2,
                                     .value_labels = BUTTON_MAINUI_LABELS,
                                     .value = settings.mainui_double_press,
                                     .action_id = 2,
                                     .action = action_setMenuButtonKeymap},
                                 "Установите действие для двойного нажатия\n"
                                 "кнопки Меню в Главном меню.");
    }
    menu_stack[++menu_level] = &_menu_button_action_mainui_menu;
    header_changed = true;
}

void menu_buttonActionInGameMenu(void *_)
{
    if (!_menu_button_action_ingame_menu._created) {
        _menu_button_action_ingame_menu = list_createWithTitle(3, LIST_SMALL, "Кнопка Меню в процессе игры");
        list_addItemWithInfoNote(&_menu_button_action_ingame_menu,
                                 (ListItem){
                                     .label = "Быстрое нажатие",
                                     .item_type = MULTIVALUE,
                                     .value_max = 3,
                                     .value_labels = BUTTON_INGAME_LABELS,
                                     .value = settings.ingame_single_press,
                                     .action_id = 3,
                                     .action = action_setMenuButtonKeymap},
                                 "Установите действие для однократного нажатия\n"
                                 "кнопки Меню в Игре.");
        list_addItemWithInfoNote(&_menu_button_action_ingame_menu,
                                 (ListItem){
                                     .label = "Долгое удержание",
                                     .item_type = MULTIVALUE,
                                     .value_max = 3,
                                     .value_labels = BUTTON_INGAME_LABELS,
                                     .value = settings.ingame_long_press,
                                     .action_id = 4,
                                     .action = action_setMenuButtonKeymap},
                                 "Установите действие для долгого нажатия\n"
                                 "кнопки Меню в Игре.");
        list_addItemWithInfoNote(&_menu_button_action_ingame_menu,
                                 (ListItem){
                                     .label = "Двойное нажатие",
                                     .item_type = MULTIVALUE,
                                     .value_max = 3,
                                     .value_labels = BUTTON_INGAME_LABELS,
                                     .value = settings.ingame_double_press,
                                     .action_id = 5,
                                     .action = action_setMenuButtonKeymap},
                                 "Установите действие для двойного нажатия\n"
                                 "кнопки Меню в Игре.");
    }
    menu_stack[++menu_level] = &_menu_button_action_ingame_menu;
    header_changed = true;
}

void menu_buttonAction(void *_)
{
    if (!_menu_button_action._created) {
        _menu_button_action = list_createWithTitle(6, LIST_SMALL, "Настройки кнопок");
        list_addItemWithInfoNote(&_menu_button_action,
                                 (ListItem){
                                     .label = "Вибрация при нажатии кнопки Меню",
                                     .item_type = TOGGLE,
                                     .value = (int)settings.menu_button_haptics,
                                     .action = action_setMenuButtonHaptics},
                                 "Включите тактильную обратную связь для кнопки меню\n"
                                 "при быстром и двойном нажатии.");
        list_addItem(&_menu_button_action,
                     (ListItem){
                         .label = "Кнопка Меню в процессе игры...",
                         .action = menu_buttonActionInGameMenu});
        list_addItem(&_menu_button_action,
                     (ListItem){
                         .label = "Кнопка Меню в главном меню...",
                         .action = menu_buttonActionMainUIMenu});

        getInstalledApps(true);
        list_addItemWithInfoNote(&_menu_button_action,
                                 (ListItem){
                                     .label = "Кнопка X в меню",
                                     .item_type = MULTIVALUE,
                                     .value_max = installed_apps_count + NUM_TOOLS,
                                     .value = value_appShortcut(0),
                                     .value_formatter = formatter_appShortcut,
                                     .action_id = 0,
                                     .action = action_setAppShortcut},
                                 "Установите действие кнопки X в Главном меню.");
        list_addItemWithInfoNote(&_menu_button_action,
                                 (ListItem){
                                     .label = "Кнопка Y в меню",
                                     .item_type = MULTIVALUE,
                                     .value_max = installed_apps_count + NUM_TOOLS + 1,
                                     .value = value_appShortcut(1),
                                     .value_formatter = formatter_appShortcut,
                                     .action_id = 1,
                                     .action = action_setAppShortcut},
                                 "Действие кнопки Y в Главном меню.");
        list_addItemWithInfoNote(&_menu_button_action,
                                 (ListItem){
                                     .label = "Кнопка Включения",
                                     .item_type = MULTIVALUE,
                                     .value_max = 1,
                                     .value_labels = {"Сон", "Выключение"},
                                     .value = (int)settings.disable_standby,
                                     .action = action_setDisableStandby},
                                 "Настройки кнопки питания при быстом нажатии\n"
                                 "действие режим ожидания, или режим выключения..");
    }
    menu_stack[++menu_level] = &_menu_button_action;
    header_changed = true;
}

void menu_batteryPercentage(void *_)
{
    if (!_menu_battery_percentage._created) {
        _menu_battery_percentage = list_createWithTitle(7, LIST_SMALL, "Процент заряда батареи");
        list_addItem(&_menu_battery_percentage,
                     (ListItem){
                         .label = "Скрыть",
                         .item_type = MULTIVALUE,
                         .value_max = 2,
                         .value_labels = THEME_TOGGLE_LABELS,
                         .value = value_batteryPercentageVisible(),
                         .action = action_batteryPercentageVisible});
        list_addItem(&_menu_battery_percentage,
                     (ListItem){
                         .label = "Шрифт",
                         .item_type = MULTIVALUE,
                         .value_max = num_font_families,
                         .value_formatter = formatter_fontFamily,
                         .value = value_batteryPercentageFontFamily(),
                         .action = action_batteryPercentageFontFamily});
        list_addItem(&_menu_battery_percentage,
                     (ListItem){
                         .label = "Размер шрифта",
                         .item_type = MULTIVALUE,
                         .value_max = num_font_sizes,
                         .value_formatter = formatter_fontSize,
                         .value = value_batteryPercentageFontSize(),
                         .action = action_batteryPercentageFontSize});
        list_addItem(&_menu_battery_percentage,
                     (ListItem){
                         .label = "Выравнивание текста",
                         .item_type = MULTIVALUE,
                         .value_max = 3,
                         .value_labels = {"-", "Слева", "По центру", "Справа"},
                         .value = value_batteryPercentagePosition(),
                         .action = action_batteryPercentagePosition});
        list_addItem(&_menu_battery_percentage,
                     (ListItem){
                         .label = "Фиксированное",
                         .item_type = MULTIVALUE,
                         .value_max = 2,
                         .value_labels = THEME_TOGGLE_LABELS,
                         .value = value_batteryPercentageFixed(),
                         .action = action_batteryPercentageFixed});
        list_addItem(&_menu_battery_percentage,
                     (ListItem){
                         .label = "Гориз. смещение",
                         .item_type = MULTIVALUE,
                         .value_max = BATTPERC_MAX_OFFSET * 2 + 1,
                         .value_formatter = formatter_positionOffset,
                         .value = value_batteryPercentageOffsetX(),
                         .action = action_batteryPercentageOffsetX});
        list_addItem(&_menu_battery_percentage,
                     (ListItem){
                         .label = "Верт. смещение",
                         .item_type = MULTIVALUE,
                         .value_max = BATTPERC_MAX_OFFSET * 2 + 1,
                         .value_formatter = formatter_positionOffset,
                         .value = value_batteryPercentageOffsetY(),
                         .action = action_batteryPercentageOffsetY});
    }
    menu_stack[++menu_level] = &_menu_battery_percentage;
    header_changed = true;
}

void menu_themeOverrides(void *_)
{
    if (!_menu_theme_overrides._created) {
        _menu_theme_overrides = list_create(7, LIST_SMALL);
        strcpy(_menu_theme_overrides.title, "Настройки оформления");
        list_addItem(&_menu_theme_overrides,
                     (ListItem){
                         .label = "Индикатор заряда...",
                         .action = menu_batteryPercentage});
		list_addItemWithInfoNote(&_menu_theme_overrides,
                     (ListItem){
                         .label = "Отключить фоновую музыку",
                         .item_type = TOGGLE,
                         .value = settings.bgm_mute,
                         .action = action_toggleBackgroundMusic},
                         "Отключить фоновую музыку для тем");
        list_addItemWithInfoNote(&_menu_theme_overrides,
                                 (ListItem){
                                     .label = "Названия меню",
                                     .item_type = MULTIVALUE,
                                     .value_max = 2,
                                     .value_labels = THEME_TOGGLE_LABELS,
                                     .value = value_hideLabelsIcons(),
                                     .action = action_hideLabelsIcons},
                                 "Скрыть подписи вкладок в главном меню.");
        list_addItemWithInfoNote(&_menu_theme_overrides,
                                 (ListItem){
                                     .label = "Названия кнопок",
                                     .item_type = MULTIVALUE,
                                     .value_max = 2,
                                     .value_labels = THEME_TOGGLE_LABELS,
                                     .value = value_hideLabelsHints(),
                                     .action = action_hideLabelsHints},
                                 "Скрыть названия кнопок на экране.");
        // list_addItem(&_menu_theme_overrides, (ListItem){
        // 	.label = "[Title] Font size", .item_type = MULTIVALUE,
        // .value_max = num_font_sizes, .value_formatter = formatter_fontSize
        // });
        // list_addItem(&_menu_theme_overrides, (ListItem){
        // 	.label = "[List] Font size", .item_type = MULTIVALUE, .value_max
        // = num_font_sizes, .value_formatter = formatter_fontSize
        // });
        // list_addItem(&_menu_theme_overrides, (ListItem){
        // 	.label = "[Hint] Font size", .item_type = MULTIVALUE, .value_max
        // = num_font_sizes, .value_formatter = formatter_fontSize
        // });
    }
    menu_stack[++menu_level] = &_menu_theme_overrides;
    header_changed = true;
}

void menu_userInterface(void *_)
{
    if (!_menu_user_interface._created) {
        _menu_user_interface = list_createWithTitle(5, LIST_SMALL, "Дополнительные настройки");
        list_addItemWithInfoNote(&_menu_user_interface,
                                 (ListItem){
                                     .label = "Вкладка Последние",
                                     .item_type = TOGGLE,
                                     .value = settings.show_recents,
                                     .action = action_setShowRecents},
                                 "Включить видимость вкладки Последние\n"
                                 "в главном меню.");
        list_addItemWithInfoNote(&_menu_user_interface,
                                 (ListItem){
                                     .label = "Вкладка Эксперт",
                                     .item_type = TOGGLE,
                                     .value = settings.show_expert,
                                     .action = action_setShowExpert},
                                 "Включить видимость вкладки Эксперт\n"
                                 "в главном меню.");
        display_init();
        list_addItemWithInfoNote(&_menu_user_interface,
                                 (ListItem){
                                     .label = "Индикатор +/-",
                                     .item_type = MULTIVALUE,
                                     .value_max = 15,
                                     .value_formatter = formatter_meterWidth,
                                     .value = value_meterWidth(),
                                     .action = action_meterWidth},
                                 "Установите ширину бегунка, расположеного\n"
                                 "в левой части дисплея, отображаемого\n"
                                 "при регулировки яркости или громкости.");
        list_addItem(&_menu_user_interface,
                     (ListItem){
                         .label = "Настройки оформления...",
                         .action = menu_themeOverrides});
        list_addItem(&_menu_user_interface,
                     (ListItem){
                         .label = "Настройки иконок...",
                         .action = menu_icons});
    }
    menu_stack[++menu_level] = &_menu_user_interface;
    header_changed = true;
}

void menu_resetSettings(void *_)
{
    if (!_menu_reset_settings._created) {
        _menu_reset_settings = list_createWithTitle(7, LIST_SMALL, "Сброс настроек");
        list_addItemWithInfoNote(&_menu_reset_settings,
                                 (ListItem){
                                     .label = "Сбросить настройки",
                                     .action = action_resetTweaks},
                                 "Сбросить все настройки системы Onion, \n"
                                 "включая настройку сети.");
        list_addItem(&_menu_reset_settings,
                     (ListItem){
                         .label = "Сброс оформления",
                         .action = action_resetThemeOverrides});
        list_addItemWithInfoNote(&_menu_reset_settings,
                                 (ListItem){
                                     .label = "Сброс настроек MainUI",
                                     .action = action_resetMainUI},
                                 "Сбрасить настройки, сохраненные на устройстве,\n"
                                 "оформление, параметры экрана, и громкость.\n"
                                 "Также сбрасывает конфигурацию Wi-Fi.");
        list_addItem(&_menu_reset_settings,
                     (ListItem){
                         .label = "Сброс конфигурации RetroArch",
                         .action = action_resetRAMain});
        list_addItem(&_menu_reset_settings,
                     (ListItem){
                         .label = "Сбросить настройки ядра RetroArch",
                         .action = action_resetRACores});
        list_addItem(&_menu_reset_settings,
                     (ListItem){
                         .label = "Сбросить Расширенное меню/MAME/MESS",
                         .action = action_resetAdvanceMENU});
        list_addItem(&_menu_reset_settings,
                     (ListItem){
                         .label = "Сбросить всё", .action = action_resetAll});
    }
    menu_stack[++menu_level] = &_menu_reset_settings;
    header_changed = true;
}

void menu_diagnostics(void *pt)
{
    if (!_menu_diagnostics._created) {
        diags_getEntries();

        _menu_diagnostics = list_createWithSticky(1 + diags_numScripts, "Диагностика");
        list_addItemWithInfoNote(&_menu_diagnostics,
                                 (ListItem){
                                     .label = "Включить логирование",
                                     .sticky_note = "Включить глобальный журнал",
                                     .item_type = TOGGLE,
                                     .value = (int)settings.enable_logging,
                                     .action = action_setEnableLogging},
                                 "Включить глобальный журнал, \n"
                                 "для системы и сети. \n \n"
                                 "Логи будут сохранены в , \n"
                                 "SD: /.tmp_update/logs.");
        for (int i = 0; i < diags_numScripts; i++) {
            ListItem diagItem = {
                .label = "",
                .payload_ptr = &scripts[i].filename,
                .action = action_runDiagnosticScript,
            };

            const char *prefix = "";
            if (strncmp(scripts[i].filename, "util", 4) == 0) {
                prefix = "Util: ";
            }
            else if (strncmp(scripts[i].filename, "fix", 3) == 0) {
                prefix = "Fix: ";
            }

            snprintf(diagItem.label, DIAG_MAX_LABEL_LENGTH - 1, "%s%.62s", prefix, scripts[i].label);
            strncpy(diagItem.sticky_note, "Инфо: Выбранный скрипт не запущен", STR_MAX - 1);

            char *parsed_Tooltip = diags_parseNewLines(scripts[i].tooltip);
            list_addItemWithInfoNote(&_menu_diagnostics, diagItem, parsed_Tooltip);
            free(parsed_Tooltip);
        }
    }

    menu_stack[++menu_level] = &_menu_diagnostics;
    header_changed = true;
}

void menu_advanced(void *_)
{
    if (!_menu_advanced._created) {
        _menu_advanced = list_createWithTitle(6, LIST_SMALL, "Расширенные");
        list_addItemWithInfoNote(&_menu_advanced,
                                 (ListItem){
                                     .label = "Замена тригеров (L<>L2, R<>R2)",
                                     .item_type = TOGGLE,
                                     .value = value_getSwapTriggers(),
                                     .action = action_advancedSetSwapTriggers},
                                 "Поменять действия L<>L2 и R<>R2\n"
                                 "(влияет только на действия в игре).");
        if (DEVICE_ID == MIYOO283) {
            list_addItemWithInfoNote(&_menu_advanced,
                                     (ListItem){
                                         .label = "Регулировка яркости",
                                         .item_type = MULTIVALUE,
                                         .value_max = 1,
                                         .value_labels = {"SELECT+R2/L2",
                                                          "MENU+UP/DOWN"},
                                         .value = config_flag_get(".altBrightness"),
                                         .action = action_setAltBrightness},
                                     "Изменить кнопки настройки яркости.");
        }
        list_addItemWithInfoNote(&_menu_advanced,
                                 (ListItem){
                                     .label = "Скорость игры",
                                     .item_type = MULTIVALUE,
                                     .value_max = 50,
                                     .value = value_getFrameThrottle(),
                                     .value_formatter = formatter_fastForward,
                                     .action = action_advancedSetFrameThrottle},
                                 "Установите максимальную скорость игры.");
        if (DEVICE_ID == MIYOO354) {
            list_addItemWithInfoNote(&_menu_advanced,
                                     (ListItem){
                                         .label = "Питание экрана",
                                         .item_type = MULTIVALUE,
                                         .value_max = 4,
                                         .value_labels = {"Выкл", "-0.1В", "-0.2В", "-0.3В", "-0.4В"},
                                         .value = value_getLcdVoltage(),
                                         .action = action_advancedSetLcdVoltage},
                                     "Используйте эту опцию, если вы видите\n"
                                     "небольшие артефакты на дисплее.");
        }
        if (exists(RESET_CONFIGS_PAK)) {
            list_addItem(&_menu_advanced,
                         (ListItem){
                             .label = "Сброс настроек...",
                             .action = menu_resetSettings});
        }
        list_addItem(&_menu_advanced,
                     (ListItem){
                         .label = "Диагностика...",
                         .action = menu_diagnostics});
    }
    menu_stack[++menu_level] = &_menu_advanced;
    header_changed = true;
}

void menu_screen_recorder(void *pt) {
    if (!_menu_screen_recorder._created) {
        _menu_screen_recorder = list_createWithSticky(7, "Запись экрана");
        list_addItemWithInfoNote(&_menu_screen_recorder,
                                 (ListItem){
                                     .label = "Вкл/Выкл запись",
                                     .sticky_note = "Статус:...",
                                     .action = tool_screenRecorder},
                                 "Запустить или остановить запись");
        list_addItemWithInfoNote(&_menu_screen_recorder,
                                 (ListItem){
                                     .label = "Индикатор записи",
                                     .sticky_note = "Показывать индикатор записи",
                                     .item_type = TOGGLE,
                                     .value = (int)settings.rec_indicator,
                                     .action = action_toggleScreenRecIndicator},
                                 "Toggles the display of a\n"
                                 "a flashing icon to remind you\n"
                                 "that you're still recording.");
        list_addItemWithInfoNote(&_menu_screen_recorder,
                                 (ListItem){
                                     .label = "Обратный отсчёт",
                                     .sticky_note = "Вкл/Выкл обратный отсчёт",
                                     .item_type = TOGGLE,
                                     .value = (int)settings.rec_countdown,
                                     .action = action_toggleScreenRecCountdown},
                                 "Обратный отсчёт начала записи. \n\n"
                                 "Индикатор мигает 3 раза сигнализируя\n"
                                 "Включение/Остановку процесса записи");
        list_addItemWithInfoNote(&_menu_screen_recorder,
                                 (ListItem){
                                     .label = "Горячие клавиши",
                                     .sticky_note = "Вкл/Выкл горячие кнопки (Меню+A) ",
                                     .item_type = TOGGLE,
                                     .value = (int)settings.rec_hotkey,
                                     .action = action_toggleScreenRecHotkey},
                                 "Включить горячие клавиши.\n\n"
                                 "Меню +  A запускает процесс записи,\n"
                                 "но их нужно удерживать в течение 2 секунд.");
        list_addItemWithInfoNote(&_menu_screen_recorder,
                                 (ListItem){
                                     .label = "Сбросить запись экрана",
                                     .sticky_note = "Принудительно завершить запись",
                                     .action = action_hardKillFFmpeg},
                                 "Принудительно завершить ffmpeg\n"
                                 "Внимание: При использовании\n"
                                 "записи, файл может быть потерян!");
        list_addItemWithInfoNote(&_menu_screen_recorder,
                                 (ListItem){
                                     .label = "Удалить все записи",
                                     .sticky_note = "Очистить каталог записей",
                                     .action = action_deleteAllRecordings},
                                 "Удаление всех записей в каталоге\n"
                                 "Внимание: Это действие\n"
                                 "не обратимо!");
    }
    int isRecordingActive = exists("/tmp/recorder_active");
    const char *recordingStatus = isRecordingActive ? "Статус: Запись..." : "Статус: Отключено.";
    strncpy(_menu_screen_recorder.items[0].sticky_note, recordingStatus, sizeof(_menu_screen_recorder.items[0].sticky_note) - 1);
    _menu_screen_recorder.items[0].sticky_note[sizeof(_menu_screen_recorder.items[0].sticky_note) - 1] = '\0';
    menu_stack[++menu_level] = &_menu_screen_recorder;
    header_changed = true;
}

void menu_tools(void *_)
{
    if (!_menu_tools._created) {
        _menu_tools = list_create(NUM_TOOLS, LIST_SMALL);
        strcpy(_menu_tools.title, "Утилиты");
        list_addItemWithInfoNote(&_menu_tools,
                                 (ListItem){
                                     .label = "Сгенерировать CUE файл для PSX игр",
                                     .action = tool_generateCueFiles},
                                 "PSX roms in '.bin' format needs a\n"
                                 "matching '.cue' file. Use this tool\n"
                                 "to automatically generate them.");
        list_addItemWithInfoNote(&_menu_tools,
                                 (ListItem){
                                     .label = "Создать список игр с короткими названиями",
                                     .action = tool_buildShortRomGameList},
                                 "This tool replaces the short names in\n"
                                 "game caches with their equivalent real\n"
                                 "names. This ensures the list is sorted\n"
                                 "correctly.");
        list_addItemWithInfoNote(&_menu_tools,
                                 (ListItem){
                                     .label = "Miyoogamelist с цифровыми именами",
                                     .action = tool_generateMiyoogamelists},
                                 "Use this tool to clean your game names\n"
                                 "without having to rename the rom files\n"
                                 "(removes parens, rankings, and much more).\n"
                                 "This generates a 'miyoogamelist.xml' file\n"
                                 "which comes with some limitations, such\n"
                                 "as no subfolder support.");
        list_addItemWithInfoNote(&_menu_tools,
                                 (ListItem){
                                     .label = "Обновить список переключения игр",
                                     .action = tool_generateGsList},
                                 "Utilize this tool to recreate your game\n"
                                 "switcher list using the RetroArch history,\n"
                                 "particularly in instances of corruption.\n"
                                 "Keep in mind that NDS games and certain\n"
                                 "ports may require manual addition.");
        list_addItemWithInfoNote(&_menu_tools,
                                 (ListItem){
                                     .label = "Сортировка списка приложений [A-Я]",
                                     .action = tool_sortAppsAZ},
                                 "Use this tool to sort your App list\n"
                                 "ascending from A to Z.\n");
        list_addItemWithInfoNote(&_menu_tools,
                                 (ListItem){
                                     .label = "Сортировка списка приложений [Я-A]",
                                     .action = tool_sortAppsZA},
                                 "Use this tool to sort your App list\n"
                                 "descending from Z to A.\n");
                    list_addItem(&_menu_tools,
                                 (ListItem){
                                     .label = "Запись экрана...",
                                     .action = menu_screen_recorder});
                                     
    }
    menu_stack[++menu_level] = &_menu_tools;
    header_changed = true;
}

void *_get_menu_icon(const char *name)
{
    char path[STR_MAX * 2] = {0};
    const char *config_path = "/mnt/SDCARD/App/Tweaks/config.json";

    if (is_file(config_path)) {
        cJSON *config = json_load(config_path);
        char icon_path[STR_MAX];
        if (json_getString(config, "icon", icon_path))
            snprintf(path, STR_MAX * 2 - 1, "%s/%s.png", dirname(icon_path),
                     name);
    }

    if (!is_file(path))
        snprintf(path, STR_MAX * 2 - 1, "res/%s.png", name);

    return (void *)IMG_Load(path);
}

void menu_main(void)
{
    if (!_menu_main._created) {
        _menu_main = list_createWithTitle(6, LIST_LARGE, "Настройки");
        list_addItem(&_menu_main,
                     (ListItem){
                         .label = "Система",
                         .description = "Включение, питание, дата...",
                         .action = menu_system,
                         .icon_ptr = _get_menu_icon("tweaks_system")});
        if (DEVICE_ID == MIYOO354) {
            list_addItem(&_menu_main,
                         (ListItem){
                             .label = "Сеть",
                             .description = "Настройки сети",
                             .action = menu_network,
                             .icon_ptr = _get_menu_icon("tweaks_network")});
        }
        list_addItem(&_menu_main,
                     (ListItem){
                         .label = "Кнопки",
                         .description = "Настройка действий кнопок",
                         .action = menu_buttonAction,
                         .icon_ptr = _get_menu_icon("tweaks_menu_button")});
        list_addItem(&_menu_main,
                     (ListItem){
                         .label = "Дополнительные настройки",
                         .description = "Настройки меню и оформления",
                         .action = menu_userInterface,
                         .icon_ptr = _get_menu_icon("tweaks_user_interface")});
        list_addItem(&_menu_main,
                     (ListItem){
                         .label = "Дополнительные",
                         .description = "Диагностика, сброс настроек",
                         .action = menu_advanced,
                         .icon_ptr = _get_menu_icon("tweaks_advanced")});
        list_addItem(&_menu_main,
                     (ListItem){
                         .label = "Утилиты",
                         .description = "Дополнительные инструменты",
                         .action = menu_tools,
                         .icon_ptr = _get_menu_icon("tweaks_tools")});
    }
    menu_level = 0;
    menu_stack[0] = &_menu_main;
    header_changed = true;
}

void menu_resetAll(void)
{
    int current_state[10][2];
    int current_level = menu_level;
    for (int i = 0; i <= current_level; i++) {
        current_state[i][0] = menu_stack[i]->active_pos;
        current_state[i][1] = menu_stack[i]->scroll_pos;
    }
    menu_free_all();
    menu_main();
    for (int i = 0; i <= current_level; i++) {
        menu_stack[i]->active_pos = current_state[i][0];
        menu_stack[i]->scroll_pos = current_state[i][1];
        if (i < current_level)
            list_activateItem(menu_stack[i]);
    }
    reset_menus = false;
}

#endif
