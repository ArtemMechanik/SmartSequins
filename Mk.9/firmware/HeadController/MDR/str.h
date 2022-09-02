#include <MDR32FxQI_port.h>
#include <MDR32FxQI_rst_clk.h>

uint8_t strEquals (uint8_t *buff1, uint8_t *buff2, uint8_t start, uint8_t end);
int8_t strIndexOf(uint8_t *buff, char simbol);
uint8_t strLenght(uint8_t *buff);
char strCharAt (uint8_t *buff, uint8_t symbolNumber);
void strTrim (uint8_t *buff, uint8_t lenght);	// заменяет все символы правее lenght на 0x00, обрезает строку до нужного размера

int32_t srtToInt (uint8_t *buff);