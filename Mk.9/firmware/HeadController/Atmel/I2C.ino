// функции для работы с I2C взял здесь: https://github.com/tibounise/SSD1306-AVR
#include <util/twi.h>

#define SCL_CLOCK  100000L

int8_t twi_status_register;

void I2Csetup (void) {
  TWSR = 0;
  TWBR = ((F_CPU/SCL_CLOCK)-16)/2;
}

uint8_t I2Cstart(uint8_t address) {
  TWCR = (1<<TWINT) | (1<<TWSTA) | (1<<TWEN);
  while(!(TWCR & (1<<TWINT)));

  twi_status_register = TW_STATUS & 0xF8;
  if ((twi_status_register != TW_START) && (twi_status_register != TW_REP_START)) {
    //return 1;
  }

  TWDR = address;
  TWCR = (1<<TWINT) | (1<<TWEN);

  while(!(TWCR & (1<<TWINT)));

  twi_status_register = TW_STATUS & 0xF8;
  if ((twi_status_register != TW_MT_SLA_ACK) && (twi_status_register != TW_MR_SLA_ACK)) {
    //return 1;
  }
  //else return 0;
}

void I2Cwrite(uint8_t data) {
  TWDR = data;
  TWCR = (1<<TWINT) | (1<<TWEN);

  while(!(TWCR & (1<<TWINT)));

  twi_status_register = TW_STATUS & 0xF8;
  if (twi_status_register != TW_MT_DATA_ACK) {
    //return 1;
    } else {
    //return 0;
  }
}

void I2Cstop(void) {
  TWCR = (1<<TWINT) | (1<<TWEN) | (1<<TWSTO);
  while(TWCR & (1<<TWSTO));
}
