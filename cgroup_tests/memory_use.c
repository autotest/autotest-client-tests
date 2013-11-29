#include <malloc.h>
#include <string.h>
#include <stdlib.h>
int main(int argc, char *argv[]) {
    if (argc != 2){
        exit(0);
    }
    unsigned int use_memory;
    unsigned int max_memory;
    use_memory = strtoul(argv[1], NULL, 10);
    max_memory = use_memory * 1024 * 1024 / 2;
    int *a;
    a = (int *)malloc(max_memory);
    int *c;
    c = (int *)malloc(max_memory);
    while(1){
        memcpy(c, a, max_memory);
        memcpy(a, c, max_memory);
        sleep(2);
        free(a);
        free(c);
        a = (int *)malloc(max_memory);
        c = (int *)malloc(max_memory);
    }
    return 0;
}
