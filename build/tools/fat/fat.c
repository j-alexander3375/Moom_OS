#include <stdio.h>

int main(int argc, char** argv) {
	if (argc < 3) {
		printf("Syntax: %s <disk_image> <file_name>\n", argv);
		return -1;
	}
	return 0;
}
