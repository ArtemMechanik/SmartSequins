#include "sequins.h"

uint16_t timeCounter = 0;
uint8_t timeCounterOverflowFLAG = 0;

struct sequinsMatrix sequins;

void sequinsStructReset (void) {
	sequins.quantity = 0;
	sequins.timeParametr = 5;
	sequins.FLAG.changeComplite = 1;
	sequins.matrix.updateComplite = 1;
}

// ���������� �������� ���������� �������
void sequinsBreakChange (struct sequinsMatrix *matrixLoc) {
  matrixLoc->FLAG.change = 0;
  matrixLoc->FLAG.changeComplite = 1;
  sequins.matrix.counters.currentStep = 0;
  timeCounter = 0;
}

void sequinsExecute (struct sequinsMatrix *matrixLoc) {
  if(matrixLoc->FLAG.change  == 0) return; // ���� ������ �� ����������, �� � �� ������ ������
  if(matrixLoc->FLAG.changeComplite == 1) {
      matrixLoc->FLAG.changeComplite = 0;
      
      // �������� �������� ��������, ���������� �� ������� ������� ��������� �������
      matrixLoc->counters.bitPointer = 0;
      matrixLoc->counters.bytePointer = 0;
      matrixLoc->counters.sequinsCounter = 0;
    return;
  }

  // ���� �������� ��������� �������, �� ���� ��������, ��������� �� �������� ����� ����� ���� ��������
  if(matrixLoc->counters.sequinsCounter == matrixLoc->quantity) {
        matrixLoc->FLAG.changeComplite = 1;
        matrixLoc->FLAG.change = 0;
        UART2_print("sequinsIsChange\r\n");   
        return; 
  }
  
  if(timeCounterOverflowFLAG == 0) return; // ���� ������ �������, � ����� ������������ ��� ���, ������ �������� ��� �� ����������, ��� ������...

  // ��� ������ ��������� ���������� �������, ������������ �������� ����� ���������
  // �������� �������������� ������ �������� ����� ��������� � �������
  // �.�. ����� N*3�� + 6��,
  // ��� N - ���������� ������� � ���������, 3�� - ����� �������� ������ ����� �������, 6�� - ��������� ����� � ������ � ����� �������
  if(matrixLoc->FLAG.matrixUpdateComplite == 1) {      
    timeCounter = matrixLoc->timeParametr; // ��������� ������
		
		//if(matrixLoc->timeParametr == 11) MDR_PORTA->RXTX |=(PORT_Pin_7); else if(matrixLoc->timeParametr == 13) MDR_PORTA->RXTX &=(~(PORT_Pin_7));
    timeCounterOverflowFLAG = 0;
    
    matrixLoc->FLAG.matrixUpdateStart = 0;
    matrixLoc->FLAG.matrixUpdateComplite = 0;
    return; 
  }

  if(matrixLoc->FLAG.matrixUpdateStart == 1) return;  // ���� ������������ ���������� �������, ���������� ��������� ����, ���� ������������ ���-�� � ������ �����
  
  // ���� ������� � ������� ��������� ������� � ���, ������� ����� ���������
  while(matrixLoc->counters.sequinsCounter < matrixLoc->quantity) {
        // ��������� ���������� �� ��������� ������� � ����� � ������ �������
        if((matrixLoc->stateNew[matrixLoc->counters.bytePointer] & (1<<matrixLoc->counters.bitPointer)) != (matrixLoc->state[matrixLoc->counters.bytePointer] & (1<<matrixLoc->counters.bitPointer)))
        {
             // ���� ��, �� ��� ������� �� ����� ����� ����� �������
             matrixLoc->FLAG.matrixUpdateStart = 1; // ������������� ���� ���������� �������
             matrixLoc->FLAG.matrixUpdateComplite = 0;

             // � ����� ��������� ��������� � �������
             if((matrixLoc->stateNew[matrixLoc->counters.bytePointer] & (1<<matrixLoc->counters.bitPointer)) == 0)
                matrixLoc->state[matrixLoc->counters.bytePointer] &= (~(1<<matrixLoc->counters.bitPointer));
             else
                matrixLoc->state[matrixLoc->counters.bytePointer] |= (1<<matrixLoc->counters.bitPointer);
             return; // ������� �� �����, ����� ���������� ��������
        }
        
        // ������ �� ����������� �� ������
        matrixLoc->counters.bitPointer++;
        if(matrixLoc->counters.bitPointer > 7) {
              matrixLoc->counters.bitPointer = 0;
              matrixLoc->counters.bytePointer++;
        }

        matrixLoc->counters.sequinsCounter ++;
  }
}




