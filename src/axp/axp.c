#include "system/axp.h"

int main(int argc, char **argv)
{
    unsigned int reg_address, i, j;
    int w_val, val, ret;

    if (argc < 2) {
        printf("Инфо: %s reg_addr [+][write_val]\n\nRegisters:\n", argv[0]);
        for (i = 0; i < 0x100; i += 0x10) {
            printf("%02X :", i);
            for (j = i; j < i + 0x10; j++) {
                val = axp_read(j);
                if (val < 0)
                    printf(" --");
                else
                    printf(" %02X", val);
            }
            printf("\n");
        }
        return 0;
    }

    sscanf(argv[1], "%x", &reg_address);

    if (argc == 2) {
        val = axp_read(reg_address);
        if (val < 0) {
            fprintf(stderr, "axp ошибка чтения: %d %s\n", val, strerror(errno));
            return 1;
        }
        printf("Чтение %s-%x reg %x, чтение занчения:%x\n", AXPDEV, AXPID, reg_address,
               val);
    }
    else {
        sscanf(argv[2], "%x", &w_val);
        if ((w_val & ~0xff) != 0)
            fprintf(stderr, "Ошибка при записи значения %s\n", argv[2]);
        if (argv[2][0] == '+') {
            val = axp_read(reg_address);
            val |= w_val;
            printf("Bit ");
        }
        else
            val = w_val;
        ret = axp_write(reg_address, val);
        if (ret < 0) {
            fprintf(stderr, "axp ошибка записи: %d %s\n", ret, strerror(errno));
            return 1;
        }
        printf("Запись %s-%x reg %x, write value:%x\n", AXPDEV, AXPID,
               reg_address, val);
    }

    return 0;
}
