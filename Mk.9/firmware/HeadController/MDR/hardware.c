#include <math.h>
#include "hardware.h"

struct debugVariable	debug;
struct UARTparam_t		uart2;

void pinSetup (void) {
	RST_CLK_PCLKcmd (RST_CLK_PCLK_PORTA, ENABLE); // // тактирование порта
	
	// стробирующий пин для отладки системного таймера (PA7)
	MDR_PORTA->OE |= (PORT_Pin_7);		// настраиваем на выход
	MDR_PORTA->ANALOG |=(PORT_Pin_7);	// цифровой пин
	MDR_PORTA->PWR |= PORT_PWR7_Msk;	// скоростной режим (с короткими фронтами)
	MDR_PORTA->RXTX &=(~(PORT_Pin_7));	// начальное значение
	
	// стробирующий пин для отладки UART2 (PA6)
	MDR_PORTA->OE |= (PORT_Pin_6);																			
	MDR_PORTA->ANALOG |=(PORT_Pin_6);																		
	MDR_PORTA->PWR |= PORT_PWR6_Msk;	      
	MDR_PORTA->RXTX &=(~(PORT_Pin_6));
}

void sysTickSetup (void) {
	// системный таймер генерирует прерывание каждую миллисекунду
	SysTick->LOAD = (8000000/1000)+200; // 200 - поправка на частоту тактового генератора
	SysTick->CTRL |=(1<<SysTick_CTRL_CLKSOURCE_Pos)|(1<<SysTick_CTRL_TICKINT_Pos)|(1<<SysTick_CTRL_ENABLE_Pos);
}

// инициализация аппаратного UART2 и его пинов
void UART2_Setup (unsigned int uartBaudRate) {
	UART_InitTypeDef UARTInitStruct;
	
	// настраиваем пины для работы с UART2
	// PF0 - RX, PF1 - TX
	RST_CLK_PCLKcmd (RST_CLK_PCLK_PORTF, ENABLE); // тактирование порта F включено
	
	// TX
	MDR_PORTF->OE |= (PORT_Pin_1);			 		
	MDR_PORTF->ANALOG |=(PORT_Pin_1);		 		
	MDR_PORTF->PWR |= PORT_PWR1_Msk;	   		
  	MDR_PORTF->FUNC |= PORT_FUNC_MODE1_Msk; 
	
	// RX
	MDR_PORTF->OE &=(~(PORT_Pin_0));			 	
	MDR_PORTF->ANALOG |=(PORT_Pin_0);		 		
	MDR_PORTF->PWR |= PORT_PWR0_Msk;	   		
	MDR_PORTF->FUNC |= PORT_FUNC_MODE0_Msk;
	
	// тактирование UART2
	RST_CLK_PCLKcmd(RST_CLK_PCLK_UART2, ENABLE);
	
	UARTInitStruct.UART_BaudRate = 						uartBaudRate; 		// Скорость передачи данных
  	UARTInitStruct.UART_WordLength = 					UART_WordLength8b; 	// Количество битов данных в сообщении
  	UARTInitStruct.UART_StopBits = 						UART_StopBits1; 	// Количество STOP-битов
  	UARTInitStruct.UART_Parity = 						UART_Parity_No; 	// Контроль четности
  	UARTInitStruct.UART_FIFOMode = 						UART_FIFO_OFF; 		// Включение/отключение буфера
  	UARTInitStruct.UART_HardwareFlowControl = UART_HardwareFlowControl_RXE 				// Аппаратный контроль за передачей и приемом данных
                                             | UART_HardwareFlowControl_TXE;																 
	//Инициализация модуля UART
  UART_Init (MDR_UART2, &UARTInitStruct);

  // Выбор предделителя тактовой частоты модуля UART
  UART_BRGInit (MDR_UART2, UART_HCLKdiv1);

  // Выбор источников прерываний (прием и передача данных)
  UART_ITConfig (MDR_UART2, UART_IT_RX, ENABLE);		// приём данных
	UART_ITConfig (MDR_UART2, UART_IT_TX, ENABLE);	// передача данных
	UART_ITConfig (MDR_UART2, UART_IT_OE, ENABLE);		// переполнение буфера

  // Разрешение работы модуля UART
  UART_Cmd (MDR_UART2, ENABLE);
}

// обработчик прерывания UART2
void UART2_IRQHandler (void) {
	uint16_t receivedData;
	char receivedByte;
  
  if (UART_GetITStatusMasked (MDR_UART2, UART_IT_RX) == SET)	// по приёму байта
  {
    UART_ClearITPendingBit (MDR_UART2, UART_IT_RX);	// очищаем флаг прерываний

    // всегда необходимо читать регистр, иначе при повторном приёме байта не генерируется прерывание
		receivedData = (uint16_t)(MDR_UART2->DR);	
		receivedByte = (uint8_t)receivedData;
		
		if(uart2.dataRxCompliteFLAG == 0) {
			uart2.dataRxBuff[uart2.dataPointerRx] = receivedByte;
			uart2.dataPointerRx ++;
		}
		
		if(receivedByte == uart2.simbol) {
			uart2.dataRxLenght = uart2.dataPointerRx;
			uart2.dataRxCompliteFLAG = 1;
			uart2.dataPointerRx = 0;
		}
	}
	
	if(UART_GetITStatusMasked(MDR_UART2,UART_IT_TX) == SET) 	// по отправке байта
	{
		UART_ClearITPendingBit (MDR_UART2, UART_IT_TX);	
		
		// грузим следующий байт
		if(uart2.dataPointerTx < uart2.dataTxCounter) 
			MDR_UART2->DR = uart2.dataTx[uart2.dataPointerTx];
		else // если следующий байт уже конец сообщения, то устанавливаем флаг окончания передачи сообщения
		{
			uart2.dataTxCompliteFLAG = 1;
			uart2.dataTxCounter = 0;
		}
		
		uart2.dataPointerTx ++;

	}
	
	if (UART_GetITStatusMasked(MDR_UART2, UART_IT_OE) == SET) // по переполнению буфера
	{
		UART_ClearITPendingBit (MDR_UART2, UART_IT_OE);
		
	}
}

//  функции для передачи данных

void UART2_startTransmitIRQ (void) {
	if(uart2.dataTxCompliteFLAG == 0) return;	// если передача уже начата, то продолжаем её
	uart2.dataPointerTx = 1;
	uart2.dataTxCompliteFLAG = 0;
	while((MDR_UART2->FR & (UART_FR_TXFF)) != 0) __NOP(); 
	MDR_UART2->DR = uart2.dataTx[0];	// первый байт кладём вручную
}

void UART2_write (uint8_t *buff, uint8_t buffLenght) {
	uint8_t i;
	for(i = 0; i < buffLenght; i++) {
		uart2.dataTx[uart2.dataTxCounter] = *buff;	
		buff ++;
		uart2.dataTxCounter ++;
	}
	UART2_startTransmitIRQ();
}

void UART2_print(uint8_t *buff) {
	while((*buff != 0x00)) {
		uart2.dataTx[uart2.dataTxCounter] = *buff;
		buff += 1;
		uart2.dataTxCounter ++;
	}
	UART2_startTransmitIRQ();
}

// вывод чисел

void UART2_printInt (int32_t data) {
	unsigned char lowNumber;	
	unsigned char n_digit = 0;
	char string_format[10];
	
	if(data < 0) {
		uart2.dataTx[uart2.dataTxCounter] = '-';
		uart2.dataTxCounter ++;
		data = abs(data);
	}
	if(data == 0) {
		uart2.dataTx[uart2.dataTxCounter] = '0';
	}
	else {
		while(data > 0) {					
			lowNumber = data%10;
			string_format[n_digit] = 0x30+lowNumber;
			data = (data-lowNumber)/10;
			n_digit ++;
		}

		do {
			n_digit--;
			uart2.dataTx[uart2.dataTxCounter] = string_format[n_digit];
			uart2.dataTxCounter++;
		} while(n_digit > 0); 
		
	}
	UART2_startTransmitIRQ();
}

void UART2_printBin (uint8_t *buff, uint8_t buffLenght) {
	uint8_t bytePointer;
	uint8_t bitPointer;
	
	for(bytePointer = 0; bytePointer < buffLenght; bytePointer++) 
  {
    for(bitPointer = 0; bitPointer < 8; bitPointer++) 
    {
      if((buff[bytePointer] & (1<<bitPointer)) != 0) 
        UART2_print("1");
      else
        UART2_print("0");
    }
  }
  UART2_print("\r\n");
}

// функции для приёма данных

void UART2_readUntil(char simbol) {
	uart2.simbol = simbol;
}

uint8_t UART2_dataAvailable (void) {
	return uart2.dataRxCompliteFLAG;
}

void UART2_read (void) {
	uint8_t i;
	for(i = 0; i < UARTbufferSize; i++) {
		uart2.dataRx[i] = 0x00;
	}
	for(i = 0; i < uart2.dataRxLenght; i++) {
		uart2.dataRx[i] = uart2.dataRxBuff[i];
		uart2.dataRxBuff[i] = 0x00;
	}
	uart2.dataRxLenght = 0;
	uart2.dataRxCompliteFLAG = 0;
}

void UART2_flush (void) {
	uint8_t i;
	for(i = 0; i < UARTbufferSize; i++) {
		uart2.dataRxBuff[i] = 0x00;
	}
}











