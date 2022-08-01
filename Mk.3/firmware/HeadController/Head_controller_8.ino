#define LED_PIN PB5 // пин штатного светодиода D13
#define LED_OFF PORTB &=(~(1<<LED_PIN))
#define LED_ON PORTB |=(1<<LED_PIN)

#define strob_PIN PB2 // пин тактовых импульсов (для тестирования)
#define strob_ON PORTB |=(1<<strob_PIN)
#define strob_OFF PORTB &=(~(1<<strob_PIN))

#define DATA_PIN PB1 // выход данных
#define DATA_PIN_OFF PORTB |=(1<<DATA_PIN)
#define DATA_PIN_ON PORTB &=(~(1<<DATA_PIN))

unsigned int strob_counter = 0; // счётчик стробирующих импульсов
byte current_step = 0; // текущий шаг передачи посылки 
byte bit_counter = 0;
byte time_1; // временные задержки при формировании битовой последовательности
byte time_2;
/* 0 - нет передачи, линия подтянута к 5В
 * 1 - начинаем передачу, прижимаем линию к GND на 3 такта
 * 2- отправка 1 бита (0 - поднимаем к 5В на 1 такт, 1 - поднимаем к 5В на 2 такта)
 * ...
 * N - отправка N-го бита
 * N+1 - завершаем передачу, прижимаем линию к GND на 3 такта, затем поднимаем к 5В
 */

char UART_data_recive [20]; // данные принятые по UART
char sequins_data [20]; // значения пайеток
byte UART_byte_counter =  0; // счётчик принятых байт по UART

byte Scale_sequence_bit = 0b00000000; // последоватльеность бит для управления чешуйками (1 бит - одна чешуйка)

String UART_data;

// обработчик прерывания по переволнению таймера
ISR(TIMER1_OVF_vect) {
  cli(); //запрет прерываний на время обработки прерывания
  strob_ON;
  switch(current_step) {
    case 0: // нет передачи, линия подтянута к 5В
      DATA_PIN_OFF; // поднимаем линию к 5В
    break;
    case 1: // начинаем передачу, прижимаем линию к GND на 3 такта
      DATA_PIN_ON; // прижимаем к GND
      if(strob_counter<4) { strob_counter++; }
      else {  
        strob_counter = 0;
        current_step = 2; // переходим к передаче сообщения
      }
    break;
    case 2: // отправка бит (0 - поднимаем к 5В на 1 такт, 1 - поднимаем к 5В на 2 такта)
      if(bit_counter<16) { // проверяем чему равен счётчик бит
        if(sequins_data[bit_counter]=='1') { // если текущий бит передменной для передачи равен 1, то отправляем 1
          time_1 = 2;
          time_2 = 4;
        }
        else { // если равен нулю
          time_1 = 1;
          time_2 = 4;
        }
        if(strob_counter<time_1) { // отсчитываем нужное время
          DATA_PIN_OFF;
          strob_counter++; 
        } 
        else if(strob_counter<time_2) {  
          DATA_PIN_ON; // прижимаем линию обратно и отсчитываем время ещё раз 
          strob_counter++;
        }
        else {
          DATA_PIN_ON;
          strob_counter = 0;
          bit_counter++;

          //current_step = 1;
        }
        
      }
      else { // если все биты для передачи закончились, то переходим к завершению передачи
        current_step = 3;
      }
    break;
    case 3:
      DATA_PIN_ON; // прижимаем к GND
      if(strob_counter<3) { strob_counter++; }
      else {  
        strob_counter = 0;
        current_step = 0; // к началу цикла
      }
    break;
  }
  _delay_us(100);
  strob_OFF;
  sei(); //разрешение прерываний
}

// настройка таймера на генерирование прерываний через данные промежутки времени
void Timer_1_setup (void) {
  DDRB |=(1<<strob_PIN);
  TCCR1A = (0<<COM1A1)|(0<<COM1A0)|(0<<COM1B1)|(0<<COM1B0)|(1<<WGM11)|(0<<WGM10); // режим Fast PWM, пины отключены от таймера, верхний предел задаётся ICR1
  TCCR1B = (0<<CS10)|(1<<CS11)|(0<<CS12)|(1<<WGM13)|(1<<WGM12); // предделитель 8
  ICR1 = 1999; // верхний предел счёта = 16000000/(8*F)-1
  TIMSK1 |= (1<<TOIE1); // разрешение прерывания по переполнению
}


void setup() {
 Serial.begin(9600); // инициализация UART
 DDRB |=(1<<LED_PIN); // настраиваем пины
 DDRB |=(1<<DATA_PIN);
 DATA_PIN_ON;
 for(byte i=0; i<20; i++) UART_data_recive[i] = '0'; // заполняем массив данными, чтобы не было ложных срабатываний чешуек при пуске
 Timer_1_setup(); // инициализация таймера
 Serial.println("Hello world!"); // к работе готовы


/*
  //инициализация
 for(byte i=0; i<20; i++) UART_data_recive[i] = '1';
 //current_step = 1;
 bit_counter = 1;
 delay(400);
 for(byte i=0; i<20; i++) UART_data_recive[i] = '0';
 current_step = 1;
 bit_counter = 1;
 */
  for(byte i=0; i<16; i++) sequins_data[i] = UART_data_recive[i];
  delay(500);
  sei(); // глобальное разрешение прерываний
}

void loop() {
  if (Serial.available()) { 
    Serial.readBytes(UART_data_recive,17);
    Serial.flush();
    if(UART_data_recive[0] == 'S') {
      for(byte i=1; i<16; i++) { // выводим принятую строку
          Serial.print(UART_data_recive[i]);
        }
      Serial.println(' ');
    
      // полученную последовательность сразу направляем к чешуйкам
      for(byte i=0; i<16; i++) {
        if(UART_data_recive[i] != sequins_data[i]) {
          sequins_data[i] = UART_data_recive[i];
          current_step = 1;
          bit_counter = 1;
          _delay_ms(100);
        }
      }
      
      // в завивисмоти от принятого значени строки меняем состояние чешуек
      if(UART_data_recive[1]=='0') LED_OFF;
      if(UART_data_recive[1]=='1') LED_ON;
    }    
  }
  
}
