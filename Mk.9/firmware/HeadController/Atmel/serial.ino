extern sequinsMatrix sequins;

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
          Serial.print("parametr:");
          Serial.println(sequins.timeParametr);
          return;
        }
        if(request.equals("GetData")) {
          Serial.println("data:");
          return;
        }
        if(request.equals("ChangeSequins")) {
          Serial.println("OK");
          
          // вывоим состояние всех пайеток
          //Serial.print("sequinsStateNew: ");
          //printBIN(&sequins.stateNew[0],2);

          sequins.FLAG.change = 1;
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
        
        if(comand.equals("SetParametr")) // установка параметра задержки
        {
                sequins.timeParametr = valueStr.toInt();
                WriteParametrs();
                //Serial.print(timeParametr);
                //if(sequins.timeParametr == 10) ledON; else if(sequins.timeParametr == 13) ledOFF;
                Serial.println("OK");
                return;
        }
        
        if(comand.equals("SetSequins"))  // начинаем обновлять лист состояний пайеток
        {
                // парсим состояния пайеток и помещаем в массив с состояними, которые необходимо установить
                uint8_t stateLenght = valueStr.length();
                sequins.quantity = stateLenght;           // запоминаем количество пайеток
                sequins.serial.counters.bitPointer = 0;//uint8_t bitPointer = 0;
                sequins.serial.counters.bytePointer = 0;//uint8_t bytePointer = 0;
                for(uint8_t i = 0; i <= stateLenght; i++) 
                {
                        char oneSimbol = valueStr.charAt(i);
                        if(oneSimbol == '1') {
                              //Serial.print('1');
                              sequins.stateNew[sequins.serial.counters.bytePointer] |=(1<<sequins.serial.counters.bitPointer);
                        }
                        else if(oneSimbol == '0') {
                              //Serial.print('0');
                              sequins.stateNew[sequins.serial.counters.bytePointer] &=(~(1<<sequins.serial.counters.bitPointer));
                        }
            
                        // следим за указателями на массив
                        sequins.serial.counters.bitPointer++;
                        if(sequins.serial.counters.bitPointer > 7) {
                          sequins.serial.counters.bitPointer = 0;
                          sequins.serial.counters.bytePointer++;
                        }
                }
                //sequins.FLAG.change = 1;
                Serial.println("OK");
                
                //Serial.print("sequinsStateNew: ");
                //Serial.print(sequins.stateNew[0],BIN);
                //Serial.print(";");
                //Serial.println(sequins.stateNew[1],BIN);
                return;
        }

        if(comand.equals("addSequins")) // продолжаем заполнять лист состояния пайеток
        {
                uint8_t stateLenght = valueStr.length();
                sequins.quantity += stateLenght;
                sequins.serial.counters.bitPointer--;
                for(uint8_t i = 0; i <= stateLenght; i++) 
                {
                      char oneSimbol = valueStr.charAt(i);
                      if(oneSimbol == '1') 
                      {
                            //Serial.print('1');
                            sequins.stateNew[sequins.serial.counters.bytePointer] |=(1<<sequins.serial.counters.bitPointer);
                      }
                      else if(oneSimbol == '0') 
                      {
                            //Serial.print('0');
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
        }
        Serial.println("OK");
        return;
  }
}



// чтение параметров в EEPROM
void ReadParametrs (void) {
  EEPROM.get(0, sequins.timeParametr);
}

// запись параметров в EEPROM
void WriteParametrs (void) {
  EEPROM.put(0, sequins.timeParametr); 
}
