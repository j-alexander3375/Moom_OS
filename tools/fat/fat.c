#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char** argv) {
    if (argc < 3) {
        printf("Syntax: %s <disk_image> <file_name>\n", argv[0]);
        return -1;
    }
    
    printf("FAT12 Tool - Reading file '%s' from disk image '%s'\n", argv[2], argv[1]);
    
    FILE *disk = fopen(argv[1], "rb");
    if (!disk) {
        printf("Error: Could not open disk image '%s'\n", argv[1]);
        return -1;
    }
    
    printf("Successfully opened disk image.\n");
    fclose(disk);
    
    return 0;
}