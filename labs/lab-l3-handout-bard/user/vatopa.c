#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(int argc, char const *argv[])
{
    uint64 va = atoi(argv[1]);
    int pid = 0;

    if(argc > 2)
        pid = atoi(argv[2]);
    
    
    printf("0x%x\n",va2pa(va, pid));

    return 0;
}
