#include <unistd.h>
#define USAGE "Usage: sucurvecpWRITE buffer prog [args]\n"
int main (int argc, char **argv) {

if (argc>2){
  write(1,argv[1],strlen(argv[1]));
  execvp(argv[2],argv+2);}

write(2,USAGE,strlen(USAGE));
exit(64);}
