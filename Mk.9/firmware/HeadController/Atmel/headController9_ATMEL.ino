#include <EEPROM.h>

// пин вывода данных
#define dataPORT  PORTB
#define dataPIN   2
#define dataON    dataPORT |= (1<<dataPIN)
#define dataOFF   dataPORT &=(~(1<<dataPIN))

// пины светодиодов
#define led1PORT  PORTB
#define led1PIN   0
#define led1ON    led1PORT |= (1<<led1PIN)
#define led1OFF   led1PORT &=(~(1<<led1PIN))

#define led2PORT  PORTD
#define led2PIN   4
#define led2ON    led2PORT |= (1<<led2PIN)
#define led2OFF   led2PORT &=(~(1<<led2PIN))

#define led3PORT  PORTD
#define led3PIN   3
#define led3ON    led3PORT |= (1<<led3PIN)
#define led3OFF   led3PORT &=(~(1<<led3PIN))

// управление питанием матрицы
#define matrixPORT  PORTC
#define matrixPIN   1
#define matrixON    matrixPORT |= (1<<matrixPIN)
#define matrixOFF   matrixPORT &=(~(1<<matrixPIN))

uint8_t SD1306_buffer [512];

// строка получаема от ПО верхнего уровня
String dataResive;

struct sequinsCounters {
  uint8_t delayCounter = 0;
  uint8_t currentStep = 0;  
  uint8_t bytePointer = 0;
  uint8_t bitPointer = 0;
  uint8_t sequinsCounter = 0;
};

struct matrixUpdateVariables {
  uint8_t timeLow = 0;
  uint8_t timeTotal = 0;
  uint8_t updateStart = 0;
  uint8_t updateComplite = 1;
  
  struct  sequinsCounters counters;
};

struct sequinsSerial {
  struct  sequinsCounters counters;
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
  struct sequinsCounters        counters;
  struct sequinsFLAGs           FLAG;
  struct matrixUpdateVariables  matrix;
  struct sequinsSerial          serial;
} sequins;

// системное время
uint16_t timeCounter = 0;
uint8_t timeCounterOverflowFLAG = 0;

uint8_t displayUpdate = 0;

void setup() {
  Serial.begin(9600);
  Serial.setTimeout(1000);
  sistemTimerSetup(); // системный таймер генерирует прерывания 1кГц
  SSD1306_setup();
  ReadParametrs(); // читаем параметры из EEPROM
  DDRD |=(1<<led2PIN)|(1<<led3PIN);
  DDRB |=(1<<led1PIN)|(1<<dataPIN);
  DDRC |=(1<<matrixPIN);
  
  dataOFF;
  led3ON;
  matrixON;
}

void loop() {

  if (Serial.available() > 0) {
    dataResive = Serial.readStringUntil('\n'); 
    uint8_t dataResiveLenght = dataResive.length();
    dataResiveLenght = dataResiveLenght - 1;
    dataResive = dataResive.substring(0,dataResiveLenght);
    serialExecute(dataResive);
    Serial.flush();

    displayUpdate = 1;
  }
  sequinsExecute(&sequins); 

  if(displayUpdate != 0) {
    displayUpdate = 0;
    
    SSD1306_clear();
    print_str8x8(0,0,"last request:");
    print_str8x8(1,0,&dataResive[0]);
    
    print_str8x8(2,0,"delay=");
    print_int(2,6,sequins.timeParametr);
    
    SSD1306_sendFramebuffer(&SD1306_buffer[0]);
    _delay_ms(100);
  }

  _delay_ms(2);

}

// управление функцией пайеток
void sequinsExecute (struct sequinsMatrix *matrixLoc) {
  if(matrixLoc->FLAG.change  == 0) return; // если ничего не изменилось, то и не делаем ничего
  led1ON;
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
        led1OFF;
        Serial.println("sequinsIsChange");   
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
  sequins.matrix.counters.currentStep = 0;
  timeCounter = 0;
}
