
#include "str.h"

// функции для работы с массивами

uint8_t strEquals (uint8_t *buff1, uint8_t *buff2, uint8_t start, uint8_t lenght) {
	uint8_t i;
	uint8_t equalsFLAG = 1;
	buff1 += start;
	for(i = 0; i < lenght; i++) {
		if(*buff1 != *buff2) equalsFLAG = 0;
		buff1 ++;
		buff2 ++;
	}
	return equalsFLAG;
}

int8_t strIndexOf(uint8_t *buff, char simbol) {
	uint8_t simbolCount = 0;
	while(*buff != 0x00) {
		if(*buff == simbol) return simbolCount;
		else {
				simbolCount ++;
				buff ++;
		}
	}
	return -1;
}

uint8_t strLenght(uint8_t *buff) {
	uint8_t simbolCount = 0;
	while(*buff != 0x00) {
		simbolCount++;
		buff++;
	}
	return simbolCount;
}


void strTrim (uint8_t *buff, uint8_t lenght) {
	buff += lenght;
	while(*buff != 0x00) {
		*buff = 0x00;
		buff ++;
	}
}

// возвращает символ из буфера по указанному адресу
char strCharAt (uint8_t *buff, uint8_t symbolNumber) {
	buff += symbolNumber;
	return *buff;
}

// преобразование строки в число
int32_t srtToInt (uint8_t *buff) {
	int8_t signMultiplier = 1;
	int32_t value = 0;
	uint8_t digitCounter = 0;
	
	if(*buff == '-') {
		signMultiplier = -1;
		buff ++;
	}
	
	while(*buff != 0x00) {
		value += (*buff-0x30);
		value = value*10;
		buff ++;
	}
	value = value/10;
	
	value = value * (uint32_t)signMultiplier;
	return value;
}