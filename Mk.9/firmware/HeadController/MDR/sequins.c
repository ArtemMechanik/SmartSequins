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

// прерывания процесса обновления матрицы
void sequinsBreakChange (struct sequinsMatrix *matrixLoc) {
  matrixLoc->FLAG.change = 0;
  matrixLoc->FLAG.changeComplite = 1;
  sequins.matrix.counters.currentStep = 0;
  timeCounter = 0;
}

void sequinsExecute (struct sequinsMatrix *matrixLoc) {
  if(matrixLoc->FLAG.change  == 0) return; // если ничего не изменилось, то и не делаем ничего
  if(matrixLoc->FLAG.changeComplite == 1) {
      matrixLoc->FLAG.changeComplite = 0;
      
      // обнуляем основные элементы, отвечающие за перебор массива состояний пайеток
      matrixLoc->counters.bitPointer = 0;
      matrixLoc->counters.bytePointer = 0;
      matrixLoc->counters.sequinsCounter = 0;
    return;
  }

  // если обновили последнюю пайетку, то путь завершён, рапортуем об успешной смене цвета всей матрицей
  if(matrixLoc->counters.sequinsCounter == matrixLoc->quantity) {
        matrixLoc->FLAG.changeComplite = 1;
        matrixLoc->FLAG.change = 0;
        UART2_print("sequinsIsChange\r\n");   
        return; 
  }
  
  if(timeCounterOverflowFLAG == 0) return; // если таймер запущен, а флага переполнения ещё нет, значит задержка ещё не отработана, ждём дальше...

  // как только завершили обновление матрицы, отрабатываем задержку между пайетками
  // задержка отрабатывается только передаче всего сообщения в матрицу
  // т.е. через N*3мС + 6мС,
  // где N - количество пайеток в сообщении, 3мС - время передачи пакета одной пайетке, 6мС - состояния линии в начале и конце посылки
  if(matrixLoc->FLAG.matrixUpdateComplite == 1) {      
    timeCounter = matrixLoc->timeParametr; // запускаем таймер
		
		//if(matrixLoc->timeParametr == 11) MDR_PORTA->RXTX |=(PORT_Pin_7); else if(matrixLoc->timeParametr == 13) MDR_PORTA->RXTX &=(~(PORT_Pin_7));
    timeCounterOverflowFLAG = 0;
    
    matrixLoc->FLAG.matrixUpdateStart = 0;
    matrixLoc->FLAG.matrixUpdateComplite = 0;
    return; 
  }

  if(matrixLoc->FLAG.matrixUpdateStart == 1) return;  // если производится обновление матрицы, пропускаем следующие шаги, флаг сбрасывается где-то в другом месте
  
  // ищем отличия в текущем состоянии пайеток и том, которое нужно устновить
  while(matrixLoc->counters.sequinsCounter < matrixLoc->quantity) {
        // проверяем отличаются ли состояния пайеток в новом и старом массиве
        if((matrixLoc->stateNew[matrixLoc->counters.bytePointer] & (1<<matrixLoc->counters.bitPointer)) != (matrixLoc->state[matrixLoc->counters.bytePointer] & (1<<matrixLoc->counters.bitPointer)))
        {
             // если да, то даём команду на смену цвета одной пайетки
             matrixLoc->FLAG.matrixUpdateStart = 1; // устанавливаем флаг обновления матрицы
             matrixLoc->FLAG.matrixUpdateComplite = 0;

             // а также сохраняем изменения в массиве
             if((matrixLoc->stateNew[matrixLoc->counters.bytePointer] & (1<<matrixLoc->counters.bitPointer)) == 0)
                matrixLoc->state[matrixLoc->counters.bytePointer] &= (~(1<<matrixLoc->counters.bitPointer));
             else
                matrixLoc->state[matrixLoc->counters.bytePointer] |= (1<<matrixLoc->counters.bitPointer);
             return; // выходим из цикла, чтобы отработать задержку
        }
        
        // следим за указателями на массив
        matrixLoc->counters.bitPointer++;
        if(matrixLoc->counters.bitPointer > 7) {
              matrixLoc->counters.bitPointer = 0;
              matrixLoc->counters.bytePointer++;
        }

        matrixLoc->counters.sequinsCounter ++;
  }
}




