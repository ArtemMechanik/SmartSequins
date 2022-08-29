// выводим число в двоичном формате
void printBIN (uint8_t *buff, uint8_t buffLenght) {
  for(uint8_t bytePointer = 0; bytePointer < buffLenght; bytePointer++) 
  {
    for(uint8_t bitPointer = 0; bitPointer < 8; bitPointer++) 
    {
      if((buff[bytePointer] & (1<<bitPointer)) != 0) 
        Serial.print('1');
      else
        Serial.print('0');
    }
  }
  Serial.println(';');
}
