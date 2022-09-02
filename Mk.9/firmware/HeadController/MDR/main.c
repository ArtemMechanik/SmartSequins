//#include <MDR32FxQI_port.h>
//#include <MDR32FxQI_rst_clk.h>
#include "hardware.h"
#include "str.h"
#include "sequins.h"

#define dataON   MDR_PORTA->RXTX |=(PORT_Pin_6)
#define dataOFF  MDR_PORTA->RXTX &=(~(PORT_Pin_6))


// ��������� ������� 
 void Delay(int waitTicks);
 void Delay_ms (uint32_t DelayValue);
 void resetVariables (void);
 void protocolExecute (uint8_t *request);
 
 extern struct debugVariable	debug;
 extern struct UARTparam_t		uart2;
 extern struct sequinsMatrix 	sequins; 
 
 
 // ��������� �����
extern uint16_t timeCounter;
extern uint8_t 	timeCounterOverflowFLAG;
volatile uint32_t DelayMsGlobal = 0;


int main (void) {
	resetVariables();
	
	pinSetup();
	sysTickSetup();
	UART2_Setup(9600);
	UART2_readUntil('\n'); // ������ ����� ������
	
	NVIC_EnableIRQ(SysTick_IRQn); 	// ��������� ���������� �� ���������� �������	 
	NVIC_EnableIRQ (UART2_IRQn);		// ��������� ���������� �� �����/������������ UART2
	
	NVIC_SetPriority(SysTick_IRQn,0); // ������ ��������� ��� ���������� ���������� �������
	
	while(1) {
		if(UART2_dataAvailable()) {
			UART2_read();
			protocolExecute(&uart2.dataRx[0]);	// ���������� �������� ������ �� ���������
			UART2_flush();	
		}
		sequinsExecute(&sequins);
		//Delay(10);
	}
}

 // ������� �������� ����� ���������� ���������� �������
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
	 // ����������
	 debug.PA7state = 0;
	 debug.PA6state = 0;
	 
	 // ���������
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
	 
	 // ������� �������
	 sequinsStructReset();
 }
 
 // ��������� �������
 void protocolExecute (uint8_t *request) {
	 uint8_t stateLenght;	// ���������� ���� � �������� ����� ���������
	 uint8_t i;
	 uint8_t *pointerTemp;
	 
	 
	 int8_t temp = strLenght(request);				// ������� ������� ������ ����
	 temp -= 2; 														
	 strTrim(request,temp);										// ������� ������ �������� ������ � �������� �������
	 
	 temp = strIndexOf(request,':');					// ���� ������-����������� � �������� ������������������
	 
	 
	 
	 if(temp < 0) 														// ���� ����������� ���, �� ��� ������� ������
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
					
					if(strEquals(request,"SetSequins",0,10))  // �������� ��������� ���� ��������� �������
					{
                // ������ ��������� ������� � �������� � ������ � ����������, ������� ���������� ����������
                stateLenght = strLenght(request + temp + 1);
                sequins.quantity = stateLenght;           // ���������� ���������� �������
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
            
                        // ������ �� ����������� �� ������
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

					if(strEquals(request,"addSequins",0,10))  // ���������� ��������� ���� ��������� �������
					{
                // ������ ��������� ������� � �������� � ������ � ����������, ������� ���������� ����������
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
            
                        // ������ �� ����������� �� ������
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
 
   // ���������� ���������� �� ���������� ������� (1���)
 void SysTick_Handler (void) { 
	 // ��������� ���������� �������
	 //MDR_PORTA->RXTX |=(PORT_Pin_7);
	 //if(debug.PA7state == 0) MDR_PORTA->RXTX &=(~(PORT_Pin_7));	 else MDR_PORTA->RXTX |=(PORT_Pin_7);
	 //if(uart2.dataTxCompliteFLAG == 0)  MDR_PORTA->RXTX &=(~(PORT_Pin_7));	 else MDR_PORTA->RXTX |=(PORT_Pin_7);
	 if(debug.PA7state == 0) debug.PA7state = 1; else debug.PA7state = 0;	
	 
	 // ������� ������� ��� ������� ��������
	 if(DelayMsGlobal != 0) DelayMsGlobal--;	
	 
	   // ������� ������� ��� ������� �������
		if(timeCounter > 0) {
			  MDR_PORTA->RXTX |=(PORT_Pin_7);
				timeCounterOverflowFLAG = 0;
				timeCounter--;
		}
		else {
			timeCounterOverflowFLAG = 1;
			MDR_PORTA->RXTX &=(~(PORT_Pin_7));
		}
		
		// ���-�� ��� ��� ���������� �������...
		// ��� ������ ���������� ������� �� ��������� �� ����� �������, ���������� ������� ��� ���� �������, �� ����� ������� �� ���������
		if(sequins.matrix.counters.currentStep == 0) 
		{
      // ��������� ��������� ������ ����� ���� ��� ����������� ���������� ���������� � � ������� ����� �������� ���� ���������� ���������� �������
      if((sequins.FLAG.matrixUpdateStart == 1)&(sequins.FLAG.matrixUpdateComplite == 0)) {
        sequins.matrix.counters.currentStep = 1;
        sequins.matrix.counters.delayCounter = 0;        
      }
      
		}
    
		// ����� ���������� ������� �� ����� ������ �������
		switch(sequins.matrix.counters.currentStep) 
		{
					case 0: // �������� �� ������������, ����� ������� � �����
							dataOFF;
					break;

					case 1: // �������� ��������, ����������� ����� ������ � + �� 3 �����
							dataON;
							if(sequins.matrix.counters.delayCounter < 3) sequins.matrix.counters.delayCounter++;
							else {
								sequins.matrix.counters.delayCounter = 0;
								sequins.matrix.counters.sequinsCounter = 0;
								sequins.matrix.counters.bytePointer = 0;
								sequins.matrix.counters.bitPointer = 0;
								sequins.matrix.counters.currentStep = 2; // �������� ���������
								dataOFF;
							}
					break;

					case 2: // �������� ��������� ���������, ��������� ��� ������ ������� ��������� 3 ����� (1 - ������ LOW, 3 - ������ HIGH, 2 - ���������� ��������� �������)
						//MDR_PORTA->RXTX |=(PORT_Pin_7);
							if(sequins.matrix.counters.sequinsCounter < (sequins.counters.sequinsCounter+1)) // ������ ���� ����� ������� �������
							{ 
										if((sequins.state[sequins.matrix.counters.bytePointer] & (1<<sequins.matrix.counters.bitPointer)) != 0)   // ������ ��������� �������
										{
											sequins.matrix.timeLow = 2;   // � ����������� �� ��������� ��������� ������������ ��������� LOW �� ����� � ����� ������������ ��������� ��� ����� �������
											sequins.matrix.timeTotal = 3;
										}
										else 
										{
											sequins.matrix.timeLow = 1;
											sequins.matrix.timeTotal = 3;
										}
										
										sequins.matrix.counters.delayCounter++; // ������� ������� ��� ��������� ������
										if(sequins.matrix.counters.delayCounter < sequins.matrix.timeLow)        dataOFF;
										else if(sequins.matrix.counters.delayCounter < sequins.matrix.timeTotal) dataON;
										else 
																																								 {
																																										dataOFF;
																																										sequins.matrix.counters.delayCounter = 0;
																																										sequins.matrix.counters.bitPointer++;
																																												
																																										// ������ �� ����������� �� ������
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

					case 3:   // ����� ��������� ��� ������� ����������� �������� �� 4 ����� � ����� ������ ������
							dataOFF;  
					MDR_PORTA->RXTX |=(PORT_Pin_7);
							if(sequins.matrix.counters.delayCounter < 1) sequins.matrix.counters.delayCounter++;
							else {
								sequins.matrix.counters.delayCounter = 0;
								sequins.matrix.counters.currentStep = 0;
								
								sequins.FLAG.matrixUpdateComplite = 1;  // ���� ��������� ���������� �������
							}
					MDR_PORTA->RXTX &=(~(PORT_Pin_7));
					break;
		}
		
		//MDR_PORTA->RXTX &=(~(PORT_Pin_7));
 }
