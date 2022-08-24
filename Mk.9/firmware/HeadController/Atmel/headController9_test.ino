#define ledDDR  DDRC
#define ledPORT PORTC
#define ledPIN  2
#define ledON   ledPORT |= (1<<ledPIN)
#define ledOFF  ledPORT &=(~(1<<ledPIN))

#define strobPORT PORTC
#define strobPIN  0
#define strobON   strobPORT |= (1<<strobPIN)
#define strobOFF  strobPORT &=(~(1<<strobPIN))

#define strob1PORT PORTC
#define strob1PIN  1
#define strob1ON   strob1PORT |= (1<<strob1PIN)
#define strob1OFF  strob1PORT &=(~(1<<strob1PIN))

// пин данных
#define dataPORT PORTD
#define dataPIN  7
#define dataON   dataPORT |= (1<<dataPIN)
#define dataOFF  dataPORT &=(~(1<<dataPIN))

String dataResive;

struct matrixUpdateVariables {
  uint8_t timeLow = 0;
  uint8_t timeTotal = 0;
  uint8_t delayCounter = 0;
  uint8_t currentStep = 0;
  uint8_t bytePointer = 0;
  uint8_t bitPointer = 0;
  uint8_t sequinsCounter = 0;
  uint8_t updateStart = 0;
  uint8_t pdateComplite = 1;
};

struct sequinsCounters {
  uint8_t bytePointer = 0;
  uint8_t bitPointer = 0;
  uint8_t sequinsCounter = 0;
};

struct sequinsFLAGs {
  uint8_t change = 0;             // флаг начала смены цвета
  uint8_t changeComplite = 1;     // флаг окончания смены цвета
  uint8_t changeBreak = 0;        // флаг преждевременного завершения изменения состояния пайеток
  uint8_t stateResiveMode = 0;    // режим работы приёмника
  uint8_t matrixUpdateStart = 0;        // запуск механизма обновления матрицы
  uint8_t matrixUpdateComplite = 0;
};

struct sequinsMatrix {
  uint16_t quantity = 0;          // количество пайеток состояние которых нужно изменить на текущем этапе
  uint16_t timeParametr = 10;      // задержка между переключенями пайеток
  uint8_t state[10] = {0, };      // состояние пайеток (каждый бит - одна пайетка)
  uint8_t stateNew[10] = {0, };   // состояние пайеток, полученное по UART
  struct sequinsCounters counters;
  struct sequinsFLAGs FLAG;
  struct matrixUpdateVariables  matrix;
} sequins;



// системное время
uint16_t timeCounter = 0;
uint8_t timeCounterOverflowFLAG = 0;

void setup() {
  Serial.begin(9600);
  sistemTimerSetup(); // системный таймер генерирует прерывания 1кГц
  DDRC |=(1<<ledPIN)|(1<<strobPIN)|(1<<strob1PIN);
  DDRD |=(1<<dataPIN);
  dataOFF;
}

void loop() {
  
  if(Serial.available() != 0) {
    dataResive = Serial.readStringUntil('\n');                // читаем до конца строки, строка всегда заканчивается \r\n
    byte dataResiveLenght = dataResive.length();              // убираем лишние символы в конце строки
    dataResiveLenght = dataResiveLenght-1;
    dataResive = dataResive.substring(0,dataResiveLenght);
    serialExecute(dataResive);                                // запускаем обработчик команды
    Serial.flush();                                           // очищаем буфер
  }
  
  delay(2);
  sequinsExecute(&sequins);                                   // выполняем процедуры по управлению матрицей
}


// обработка запросов
void serialExecute (String request) {
  char temp = request.indexOf(':'); // ищем номер символа, отделяющего команду от данных, содержащихся в ней
  // обработка команд без данных
  if(temp < 0) {       
    //Serial.println(request);                
        if(request.equals("AT")) {
          Serial.println("OK");
          return;
        }
        if(request.equals("GetParametr")) {
          Serial.println("parametr:");
          return;
        }
        if(request.equals("GetData")) {
          Serial.println("data:");
          return;
        }
  }

  // обработка команд с данными
  else {
        //Serial.println(request);   
        String comand = request.substring(0,temp);
        //Serial.println (comand);
        String valueStr = request.substring(temp+1);
        //Serial.println (valueStr);
        //Serial.println("comand: " + comand + "; value: " + valueStr);  // цифра, которую нужно будет обрабатывать
        
        if(comand.equals("SetParametr")) {
          sequins.timeParametr = valueStr.toInt();
         // timeParametr = valueStr.toInt();
          //Serial.print(timeParametr);
          if(sequins.timeParametr == 10) ledON; else if(sequins.timeParametr == 13) ledOFF;
          Serial.println("OK");
          return;
        }
        if(comand.equals("SetSequins")) {
          // парсим состояния пайеток и помещаем в массив с состояними, которые необходимо установить
          uint8_t stateLenght = valueStr.length();
          sequins.quantity = stateLenght;           // запоминаем количество пайеток
          uint8_t bitPointer = 0;
          uint8_t bytePointer = 0;
          for(uint8_t i = 0; i <= stateLenght; i++) {
                char oneSimbol = valueStr.charAt(i);
                if(oneSimbol == '1') {
                      //Serial.print('1');
                      sequins.stateNew[bytePointer] |=(1<<bitPointer);
                }
                else if(oneSimbol == '0') {
                      //Serial.print('0');
                      sequins.stateNew[bytePointer] &=(~(1<<bitPointer));
                }
    
                // следим за указателями на массив
                bitPointer++;
                if(bitPointer > 7) {
                  bitPointer = 0;
                  bytePointer++;
                }
          }
          sequins.FLAG.change = 1;
          Serial.println("OK");
          
          //Serial.print("sequinsStateNew: ");
          //Serial.print(sequins.stateNew[0],BIN);
          //Serial.print(";");
          //Serial.println(sequins.stateNew[1],BIN);
          return;
        }
  }
}

// управление функцией пайеток
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
        Serial.println("sequinsIsSet");   
        return; 
  }
  
  if(timeCounterOverflowFLAG == 0) return; // если таймер запущен, а флага переполнения ещё нет, значит задержка ещё не отработана, ждём дальше...

  // как только завершили обновление матрицы, отрабатываем задержку между пайетками
  // задержка отрабатывается только передаче всего сообщения в матрицу
  // т.е. через N*3мС + 6мС,
  // где N - количество пайеток в сообщении, 3мС - время передачи пакета одной пайетке, 6мС - состояния линии в начале и конце посылки
  if(matrixLoc->FLAG.matrixUpdateComplite == 1) {      
    timeCounter = matrixLoc->timeParametr; // запускаем таймер
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

// прерывания процесса обновления матрицы
void sequinsBreakChange (struct sequinsMatrix *matrixLoc) {
  matrixLoc->FLAG.change = 0;
  matrixLoc->FLAG.changeComplite = 1;
  sequins.matrix.currentStep = 0;
  timeCounter = 0;
}
