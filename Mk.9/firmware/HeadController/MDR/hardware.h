#include <MDR32FxQI_port.h>
#include <MDR32FxQI_rst_clk.h>
#include "MDR32FxQI_uart.h"		

#define UARTbufferSize 100
 
 // ���������� ��� �������
 struct debugVariable {
	 uint8_t PA7state;
	 uint8_t PA6state;
 };
 
struct UARTparam_t {
	uint8_t dataTx[UARTbufferSize]; 		// ������ ��� ��������
	uint8_t dataRx[UARTbufferSize];			// ������ ��� �����
	uint8_t dataRxBuff[UARTbufferSize];	
	uint8_t	dataPointerTx;							// ��������� �� ������ ������� �����������
	uint8_t dataTxCounter;							// ������� ���� ��� ��������
	uint8_t dataRxCounter;							// ������� �������� ����
	uint8_t dataPointerRx;							// ��������� �� ������ ������� ��������
	uint8_t dataRxLenght;
	uint8_t dataTxFLAG;									// ���������������, ����� ���������� ��������� ������ �� ������
	uint8_t dataTxCompliteFLAG;					// ��������������� ����� �������� ���� ������� �� ������
	uint8_t dataRxFLAG;									// ��������������, ����� ������� ���� ������
	uint8_t dataRxCompliteFLAG;					// ��������������� ����� ����� ����� ��� ������
	char 		simbol;											// ������ �� �������� ������ �����
};

// ���������������� ���������� ������� �����������
void pinSetup (void);														// ��������� �����
void sysTickSetup (void); 											// ��������� ���������� �������
void UART2_Setup (unsigned int uartBaudRate); 	// ��������� UART2
void UART2_sendByte (unsigned char dataByte); 	// �������� ����� � ����������� ������
void UART2_startTransmitIRQ (void);

void UART2_write (uint8_t *buff, uint8_t buffLenght);
void UART2_print(uint8_t *buff);
void UART2_printInt (int32_t data);
void UART2_printBin (uint8_t *buff, uint8_t buffLenght);

void UART2_readUntil(char simbol);
uint8_t UART2_dataAvailable (void);
void UART2_read (void);
void UART2_flush (void);

