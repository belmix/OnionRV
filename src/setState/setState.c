#include <stdio.h>
#include <stdlib.h>

#include "system/state.h"
#include "utils/apps.h"

int main(int argc, char *argv[])
{
    if (argc < 2) {
        printf("Используется: setState [N]\nN: 0 - Главное Меню, 1 - Последние, 2 - "
               "Избранное, 3 - Игры, 4 - Эксперт, 5 - Приложения\n");
        return 1;
    }

    MainUIState state = atoi(argv[1]);
    int currpos = 0, total = 10;

    if (argc == 3)
        getAppPosition(argv[2], &currpos, &total);

    write_mainui_state(state, currpos, total);

    return 0;
}
