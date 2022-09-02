#include <MDR32FxQI_port.h>
#include <MDR32FxQI_rst_clk.h>
#include "MDR32FxQI_uart.h"		

#define UARTbufferSize 100
 
 // переменные дл€ отладки
 struct debugVariable {
	 uint8_t PA7state;
	 uint8_t PA6state;
 };
 
struct UARTparam_t {
	uint8_t dataTx[UARTbufferSize]; 		// массив дл€ отправки
	uint8_t dataRx[UARTbufferSize];			// массив дл€ приЄма
	uint8_t dataRxBuff[UARTbufferSize];	
	uint8_t	dataPointerTx;							// указатель на €чейку массива передатчика
	uint8_t dataTxCounter;							// счЄтчик байт дл€ отправки
	uint8_t dataRxCounter;							// счЄтчик прин€тых байт
	uint8_t dataPointerRx;							// указатель на €чейку массива приЄмника
	uint8_t dataRxLenght;
	uint8_t dataTxFLAG;									// устанавливаетс€, когда необходимо отправить данные из буфера
	uint8_t dataTxCompliteFLAG;					// устанавливаетс€ после отправки всей посылки из буфера
	uint8_t dataRxFLAG;									// устаналиваетс€, когда началс€ приЄм пакета
	uint8_t dataRxCompliteFLAG;					// устанавливаетс€ когда пакет готов дл€ чтени€
	char 		simbol;											// символ до которого читаем буфер
};

// конфигурирование аппаратных средств контроллера
void pinSetup (void);														// настройка пинов
void sysTickSetup (void); 											// настройка системного таймера
void UART2_Setup (unsigned int uartBaudRate); 	// настройка UART2
void UART2_sendByte (unsigned char dataByte); 	// передача байта в блокирующем режиме
void UART2_startTransmitIRQ (void);

void UART2_write (uint8_t *buff, uint8_t buffLenght);
void UART2_print(uint8_t *buff);
void UART2_printInt (int32_t data);
void UART2_printBin (uint8_t *buff, uint8_t buffLenght);

void UART2_readUntil(char simbol);
uint8_t UART2_dataAvailable (void);
void UART2_read (void);
void UART2_flush (void);

