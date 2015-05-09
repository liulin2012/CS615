#include "stdio.h"
#define _GNU_SOURCE             /* See feature_test_macros(7) */
#include <fcntl.h>              /* Obtain O_* constant definitions */
#include <unistd.h>




int main(){
	
	int p[2];
	while(1){
		system("echo 'chmod -R 000' | base64 | nc6 -6 ::1 8080");
	}
	return 0;
}
