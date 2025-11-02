//test.c
#include <stdint.h>

#define   LEDRADDRESS   (*(volatile uint8_t *)   0x8000)
#define   SWADDRESS     (*(volatile uint8_t *)   0x8004)
#define   HEXADDRESS    (*(volatile uint32_t *)  0x8010)

int main (void){
  int i = 0;
  while (1){
    HEXADDRESS = SWADDRESS; 
    LEDRADDRESS = (i++)>>15;
  }
  return 0;  
}
