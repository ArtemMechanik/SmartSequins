#define F_CPU   16000000
#define F_tics  1000

void sistemTimerSetup () {
  // системный таймер генерирует отсчёты времени с заданной частотой
  TCCR1A = (1<<WGM11)|(0<<WGM10); // режим FastPWM, предделитель на 8
  TCCR1B = (1<<WGM13)|(1<<WGM12)|(0<<CS12)|(1<<CS11)|(0<<CS10);
  ICR1 = (F_CPU/(8*F_tics)) - 20;
  TIMSK1 = (1<<TOIE1);  // прерывание по переполнению
}

uint8_t strobeTimeCounter = 0;

// обработчик прерывания от системного таймера
ISR(TIMER1_OVF_vect) {
  strob1ON;

  // счётчик времени
  if(timeCounter > 0) {
    timeCounterOverflowFLAG = 0;
    timeCounter--;
  }
  else timeCounterOverflowFLAG = 1;

  // что-то там про обновление матрицы...
  // при каждом обновлении матрицы мы запускаем на выход посылку, содержащую команды для всех пайеток, по левую сторону от указателя
  if(sequins.matrix.currentStep == 0) {
      // процедуру запускаем только после того как завершилось предыдущее обносление и в главном цикле сбросили флаг завершения обновления матрицы
      if((sequins.FLAG.matrixUpdateStart == 1)&(sequins.FLAG.matrixUpdateComplite == 0)) {
        strobON;
        strobeTimeCounter = 1;
        sequins.matrix.currentStep = 1;
        sequins.matrix.delayCounter = 0;        
      }
      
  }
    
  switch(sequins.matrix.currentStep) {
    case 0: // передача не производится, линия прижата к земле
        dataOFF;
    break;

    case 1: // начинаем передачу, подтягиваем линию данных к + на 3 такта
        dataON;
        if(sequins.matrix.delayCounter < 3) sequins.matrix.delayCounter++;
        else {
          sequins.matrix.delayCounter = 0;
          sequins.matrix.sequinsCounter = 0;
          sequins.matrix.bytePointer = 0;
          sequins.matrix.bitPointer = 0;
          sequins.matrix.currentStep = 2; // передача сообщения
          dataOFF;
        }
    break;

    case 2: // передача основного сообщения, сообщение для каждой пайетки передаётся 3 такта (1 - всегда LOW, 3 - всегда HIGH, 2 - определяет состояние пайетки)
        if(sequins.matrix.sequinsCounter < (sequins.counters.sequinsCounter+1)) // следим чему равен счётчик пайеток
        { 
              if((sequins.state[sequins.matrix.bytePointer] & (1<<sequins.matrix.bitPointer)) != 0)   // читаем состояние пайетки
              {
                sequins.matrix.timeLow = 2;   // в завивисомти от состояния указываем длительность состояния LOW на линии и общую длительность сообщения для одной пайетки
                sequins.matrix.timeTotal = 3;
              }
              else 
              {
                sequins.matrix.timeLow = 1;
                sequins.matrix.timeTotal = 3;
              }
              
              sequins.matrix.delayCounter++; // счётчик времени для сообщения пайтки
              if(sequins.matrix.delayCounter < sequins.matrix.timeLow)        dataOFF;
              else if(sequins.matrix.delayCounter < sequins.matrix.timeTotal) dataON;
              else 
                                                                           {
                                                                              dataOFF;
                                                                              sequins.matrix.delayCounter = 0;
                                                                              sequins.matrix.bitPointer++;
                                                                                  
                                                                              // сдедим за указателями на массив
                                                                              if(sequins.matrix.bitPointer > 7) {
                                                                                  sequins.matrix.bitPointer = 0;
                                                                                  sequins.matrix.bytePointer++;
                                                                              }
                                                                                  
                                                                              sequins.matrix.sequinsCounter ++;
                                                                          }
              

        }
        else {
          sequins.matrix.currentStep = 3;
          sequins.matrix.delayCounter = 0;
        }
          
    break;

    case 3:   // конец сообщения для матрицы обрамляется прижатой на 3 такта к земле линией данных
        dataOFF;  
        if(sequins.matrix.delayCounter < 3) sequins.matrix.delayCounter++;
        else {
          sequins.matrix.delayCounter = 0;
          sequins.matrix.currentStep = 0;
          
          sequins.FLAG.matrixUpdateComplite = 1;  // флаг окончания обновления матрицы
        }
    break;
  }

    // контроллируем импульсы
    if(strobeTimeCounter > 0) strobeTimeCounter--;
    else {
        strobOFF;
    }
    
    strob1OFF;
}

// текущее время
uint16_t getTime () {
  return timeCounter;
}
