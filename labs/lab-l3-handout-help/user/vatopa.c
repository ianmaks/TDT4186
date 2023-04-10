// Create a zombie process that
// must be reparented at exit.

#include "kernel/types.h"
#include "user/user.h"
#include "kernel/fs.h"

int main(int argc, char *argv[])
{
    if (argc < 2)
    {
        printf("Usage: vatopa virtual_address [pid]\n");
        return -1;
    }

    uint64 vaddr = (uint64)atoi(argv[1]);
    int pid = 0;
    if (argc > 2)
    {
        pid = atoi(argv[2]);
    }
    uint64 paddr = va2pa(vaddr, pid);
    if (pid == 0)
    {
        pid = getpid();
    }
    printf("0x%x\n", paddr);
    return 0;
}