#include "./playActivity.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void printUsage()
{
    printf("Usage: playActivity list             -> Все игровые действия\n"
           "       playActivity start [rom_path] -> Запуск счетчика для игры\n"
           "       playActivity resume           -> Вернуться к последней игре\n"
           "       playActivity stop [rom_path]  -> Остановить счётчик для игры\n"
           "       playActivity stop_all         -> Остановить счётчик для всех игры\n"
           "       playActivity migrate          -> Перенесите старую базу данных (до Onion 4.2.0) в SQLite\n"
           "       playActivity fix_paths        -> Изменить все абсолютные пути на относительные\n");
}

int main(int argc, char *argv[])
{
    log_setName("play_activity");

    if (argc <= 1) {
        printUsage();
        return EXIT_SUCCESS;
    }

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "start") == 0) {
            if (i + 1 < argc) {
                play_activity_start(argv[++i]);
            }
            else {
                printf("Ошибка: Missing rom_path argument\n");
                printUsage();
                return EXIT_FAILURE;
            }
        }
        else if (strcmp(argv[i], "resume") == 0) {
            play_activity_resume();
        }
        else if (strcmp(argv[i], "stop") == 0) {
            if (i + 1 < argc) {
                play_activity_stop(argv[++i]);
            }
            else {
                printf("Ошибка: Missing rom_path argument\n");
                printUsage();
                return EXIT_FAILURE;
            }
        }
        else if (strcmp(argv[i], "stop_all") == 0) {
            play_activity_stop_all();
        }
        else if (strcmp(argv[i], "migrate") == 0) {
            migrateDB();
        }
        else if (strcmp(argv[i], "fix_paths") == 0) {
            play_activity_fix_paths();
        }
        else if (strcmp(argv[i], "list") == 0) {
            play_activity_list_all();
        }
        else {
            printf("Ошибка: Invalid argument '%s'\n", argv[1]);
            printUsage();
            return EXIT_FAILURE;
        }
    }

    return EXIT_SUCCESS;
}
