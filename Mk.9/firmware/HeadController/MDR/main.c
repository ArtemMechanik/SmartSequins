//#include <MDR32FxQI_port.h>
//#include <MDR32FxQI_rst_clk.h>
#include "hardware.h"
#include "str.h"
#include "sequins.h"

#define dataON   MDR_PORTA->RXTX |=(PORT_Pin_6)
#define dataOFF  MDR_PORTA->RXTX &=(~(PORT_Pin_6))


// прототипы функций 
 void Delay(int waitTicks);
 void Delay_ms (uint32_t DelayValue);
 void resetVariables (void);
 void protocolExecute (uint8_t *request);
 
 extern struct debugVariable	debug;
 extern struct UARTparam_t		uart2;
 extern struct sequinsMatrix 	sequins; 
 
 
 // системное время
extern uint16_t timeCounter;
extern uint8_t 	timeCounterOverflowFLAG;
volatile uint32_t DelayMsGlobal = 0;


int main (void) {
	resetVariables();
	
	pinSetup();
	sysTickSetup();
	UART2_Setup(9600);
	UART2_readUntil('\n'); // символ конца строки
	
	NVIC_EnableIRQ(SysTick_IRQn); 	// разрешаем прерывания от системного таймера	 
	NVIC_EnableIRQ (UART2_IRQn);		// разрешаем прерывание по приёму/переполнению UART2
	
	NVIC_SetPriority(SysTick_IRQn,0); // высший приоритет для прерываний системного таймера
	
	while(1) {
		if(UART2_dataAvailable()) {
			UART2_read();
			protocolExecute(&uart2.dataRx[0]);	// отправляем принятый запрос на обработку
			UART2_flush();	
		}
		sequinsExecute(&sequins);
		//Delay(10);
	}
}

 // функция задержки через прерывания системного таймера
 void Delay_ms (uint32_t DelayValue) {
	 DelayMsGlobal = DelayValue;
	 while(DelayMsGlobal != 0) {};
 }

 void Delay(int waitTicks)
 {
   int i;
   for (i = 0; i < waitTicks; i++)
  {
   __NOP();
  }
 } 
 
 void resetVariables (void) {
	 // отладочные
	 debug.PA7state = 0;
	 debug.PA6state = 0;
	 
	 // системные
	 DelayMsGlobal = 0;
	 
	 // UART
	 uart2.dataPointerTx = 0;
	 uart2.dataPointerRx = 0;
	 uart2.dataTxFLAG = 0;
	 uart2.dataTxCompliteFLAG = 1;
	 uart2.dataRxFLAG = 0;
	 uart2.dataRxCompliteFLAG = 0;
	 uart2.dataTxCounter = 0;
	 uart2.dataRxCounter = 0;
	 uart2.simbol = 0x00;
	 uart2.dataRxLenght = 0;
	 
	 // матрица пайеток
	 sequinsStructReset();
 }
 
 // обработка запроса
 void protocolExecute (uint8_t *request) {
	 uint8_t stateLenght;	// количество байт в цифровой части сообщения
	 uint8_t i;
	 uint8_t *pointerTemp;
	 
	 
	 int8_t temp = strLenght(request);				// смотрим сколько пришло байт
	 temp -= 2; 														
	 strTrim(request,temp);										// удаляем символ переноса строки и возврата каретки
	 
	 temp = strIndexOf(request,':');					// ищем символ-разделитель в принятой последовательности
	 
	 
	 
	 if(temp < 0) 														// если разделителя нет, то это простой запрос
	 {	
				 if(strEquals(request,"AT",0,2)) {
						 UART2_print("OK\r\n");
							return;
				 }
				 if(strEquals(request,"GetParametr",0,11)) {
						 UART2_print("parametr:\r\n");
							return;
				 }
				 if(strEquals(request,"ChangeSequins",0,13)) {
						 UART2_print("OK\r\n");
						 sequins.FLAG.change = 1;
						  return;
				 }
	 }
	 else 
	 {
					if(strEquals(request,"SetParametr",0,11)) 
					{
						sequins.timeParametr = srtToInt(request + temp + 1);
						//pointerTemp = (uint8_t*)&sequins.timeParametr;
						//UART2_printBin(pointerTemp,2);
						//if(sequins.timeParametr == 11) MDR_PORTA->RXTX |=(PORT_Pin_7); else if(sequins.timeParametr == 13) MDR_PORTA->RXTX &=(~(PORT_Pin_7));
						//UART2_printInt(sequins.timeParametr);
						UART2_print("OK\r\n");
					}
					
					if(strEquals(request,"SetSequins",0,10))  // начинаем обновлять лист состояний пайеток
					{
                // парсим состояния пайеток и помещаем в массив с состояними, которые необходимо установить
                stateLenght = strLenght(request + temp + 1);
                sequins.quantity = stateLenght;           // запоминаем количество пайеток
                sequins.serial.counters.bitPointer = 0;
                sequins.serial.counters.bytePointer = 0;
						
								//UART2_print("Sequins state: ");
                for(i = 0; i <= stateLenght; i++) 
                {
                        char oneSimbol = strCharAt(request,temp + 1 + i);
                        if(oneSimbol == '1') {
															//UART2_print("1");
                              sequins.stateNew[sequins.serial.counters.bytePointer] |=(1<<sequins.serial.counters.bitPointer);
                        }
                        else if(oneSimbol == '0') {
                              //UART2_print("0");
                              sequins.stateNew[sequins.serial.counters.bytePointer] &=(~(1<<sequins.serial.counters.bitPointer));
                        }
            
                        // следим за указателями на массив
                        sequins.serial.counters.bitPointer++;
                        if(sequins.serial.counters.bitPointer > 7) 
												{
                          sequins.serial.counters.bitPointer = 0;
                          sequins.serial.counters.bytePointer++;
                        }
                }
								//UART2_printBin(&sequins.stateNew[0],3);
                UART2_print("OK\r\n");
                return;
					}

					if(strEquals(request,"addSequins",0,10))  // продолжаем заполнять лист состояния пайеток
					{
                // парсим состояния пайеток и помещаем в массив с состояними, которые необходимо установить
                stateLenght = strLenght(request + temp + 1);
                sequins.quantity += stateLenght;          
                sequins.serial.counters.bitPointer--;
						
								//UART2_print("Sequins state: ");
                for(i = 0; i <= stateLenght; i++) 
                {
                        char oneSimbol = strCharAt(request,temp + 1 + i);
                        if(oneSimbol == '1') {
															//UART2_print("1");
                              sequins.stateNew[sequins.serial.counters.bytePointer] |=(1<<sequins.serial.counters.bitPointer);
                        }
                        else if(oneSimbol == '0') {
                              //UART2_print("0");
                              sequins.stateNew[sequins.serial.counters.bytePointer] &=(~(1<<sequins.serial.counters.bitPointer));
                        }
            
                        // следим за указателями на массив
                        sequins.serial.counters.bitPointer++;
                        if(sequins.serial.counters.bitPointer > 7) 
												{
                          sequins.serial.counters.bitPointer = 0;
                          sequins.serial.counters.bytePointer++;
                        }
                }
								//UART2_printBin(&sequins.stateNew[0],3);
                UART2_print("OK\r\n");
                return;
					}					
		}
 }
 
   // обработчик прерывания от системного таймера (1кГц)
 void SysTick_Handler (void) { 
	 // состояние отладочных выводов
	 //MDR_PORTA->RXTX |=(PORT_Pin_7);
	 //if(debug.PA7state == 0) MDR_PORTA->RXTX &=(~(PORT_Pin_7));	 else MDR_PORTA->RXTX |=(PORT_Pin_7);
	 //if(uart2.dataTxCompliteFLAG == 0)  MDR_PORTA->RXTX &=(~(PORT_Pin_7));	 else MDR_PORTA->RXTX |=(PORT_Pin_7);
	 if(debug.PA7state == 0) debug.PA7state = 1; else debug.PA7state = 0;	
	 
	 // счётчик времени для функции задержки
	 if(DelayMsGlobal != 0) DelayMsGlobal--;	
	 
	   // счётчик времени для матрицы пайеток
		if(timeCounter > 0) {
			  MDR_PORTA->RXTX |=(PORT_Pin_7);
				timeCounterOverflowFLAG = 0;
				timeCounter--;
		}
		else {
			timeCounterOverflowFLAG = 1;
			MDR_PORTA->RXTX &=(~(PORT_Pin_7));
		}
		
		// что-то там про обновление матрицы...
		// при каждом обновлении матрицы мы запускаем на выход посылку, содержащую команды для всех пайеток, по левую сторону от указателя
		if(sequins.matrix.counters.currentStep == 0) 
		{
      // процедуру запускаем только после того как завершилось предыдущее обносление и в главном цикле сбросили флаг завершения обновления матрицы
      if((sequins.FLAG.matrixUpdateStart == 1)&(sequins.FLAG.matrixUpdateComplite == 0)) {
        sequins.matrix.counters.currentStep = 1;
        sequins.matrix.counters.delayCounter = 0;        
      }
      
		}
    
		// смена логических уровней на линии данных пайеток
		switch(sequins.matrix.counters.currentStep) 
		{
					case 0: // передача не производится, линия прижата к земле
							dataOFF;
					break;

					case 1: // начинаем передачу, подтягиваем линию данных к + на 3 такта
							dataON;
							if(sequins.matrix.counters.delayCounter < 3) sequins.matrix.counters.delayCounter++;
							else {
								sequins.matrix.counters.delayCounter = 0;
								sequins.matrix.counters.sequinsCounter = 0;
								sequins.matrix.counters.bytePointer = 0;
								sequins.matrix.counters.bitPointer = 0;
								sequins.matrix.counters.currentStep = 2; // передача сообщения
								dataOFF;
							}
					break;

					case 2: // передача основного сообщения, сообщение для каждой пайетки передаётся 3 такта (1 - всегда LOW, 3 - всегда HIGH, 2 - определяет состояние пайетки)
						//MDR_PORTA->RXTX |=(PORT_Pin_7);
							if(sequins.matrix.counters.sequinsCounter < (sequins.counters.sequinsCounter+1)) // следим чему равен счётчик пайеток
							{ 
										if((sequins.state[sequins.matrix.counters.bytePointer] & (1<<sequins.matrix.counters.bitPointer)) != 0)   // читаем состояние пайетки
										{
											sequins.matrix.timeLow = 2;   // в завивисомти от состояния указываем длительность состояния LOW на линии и общую длительность сообщения для одной пайетки
											sequins.matrix.timeTotal = 3;
										}
										else 
										{
											sequins.matrix.timeLow = 1;
											sequins.matrix.timeTotal = 3;
										}
										
										sequins.matrix.counters.delayCounter++; // счётчик времени для сообщения пайтки
										if(sequins.matrix.counters.delayCounter < sequins.matrix.timeLow)        dataOFF;
										else if(sequins.matrix.counters.delayCounter < sequins.matrix.timeTotal) dataON;
										else 
																																								 {
																																										dataOFF;
																																										sequins.matrix.counters.delayCounter = 0;
																																										sequins.matrix.counters.bitPointer++;
																																												
																																										// сдедим за указателями на массив
																																										if(sequins.matrix.counters.bitPointer > 7) {
																																												sequins.matrix.counters.bitPointer = 0;
																																												sequins.matrix.counters.bytePointer++;
																																										}
																																												
																																										sequins.matrix.counters.sequinsCounter ++;
																																								}
										

							}
							else {
								dataOFF; 
								sequins.matrix.counters.currentStep = 3;
								sequins.matrix.counters.delayCounter = 0;
							}
								//MDR_PORTA->RXTX &=(~(PORT_Pin_7));
					break;

					case 3:   // конец сообщения для матрицы обрамляется прижатой на 4 такта к земле линией данных
							dataOFF;  
					MDR_PORTA->RXTX |=(PORT_Pin_7);
							if(sequins.matrix.counters.delayCounter < 1) sequins.matrix.counters.delayCounter++;
							else {
								sequins.matrix.counters.delayCounter = 0;
								sequins.matrix.counters.currentStep = 0;
								
								sequins.FLAG.matrixUpdateComplite = 1;  // флаг окончания обновления матрицы
							}
					MDR_PORTA->RXTX &=(~(PORT_Pin_7));
					break;
		}
		
		//MDR_PORTA->RXTX &=(~(PORT_Pin_7));
 }
