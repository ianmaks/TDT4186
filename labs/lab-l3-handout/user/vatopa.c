#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(int argc, char *argv[])
{

    if (argc < 2)
    {
        printf("Usage: vatopa virtual_address [pid]\n");
        return -1;
    }
    
    int pid = 0;
    uint64 va = atoi(argv[1]);

    if (argc > 2) {
        pid = atoi(argv[2]);
    }

    printf("0x%x\n", va2pa(va, pid));
    return 0;
}