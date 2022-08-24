// ответы контроллера на запросы
String [] answers = {
  "OK",                // ответ на тестовый запрос
  "parametr:",         // ответ на запрос параметра
  "data:",             // ответ на запрос данных
  "sequinsIsSet"       // ответ после установки всех пайеток в заданные цвета 
};

String [] requests = {
  "AT",                // тестовый запрос
  "GetParametr",    // запрос параметра
  "GetData",        // запрос данных с датчиков
  "SetParametr:",   // установка параметра
  "SetSequins:",    // установка значений пайеток
  "Break"           // отмена обновления пайеток
};

class HeadController {
  char [] dataTransmit = new char [1000];
  String transmitData;
  String transmitComand;
  String resiveData;
  
  int controllerReadyFLAG;
  int controllerTimeOut;
  int timeActual;
  int timePrev;
  
  // конструктор
  HeadController() {
     controllerReadyFLAG = 1;
     controllerTimeOut = 1000; // тайм аут запроса 1с
     timeActual = 0;
     timePrev = 0;
  }
  
  // методы
  void serialExecute (float sequinsTimeDelayTemp, int sequinsState [], int sequinsQuantity) {
    controllerReadyFLAG = timeOutCounter(controllerReadyFLAG);  // проверяем, что таймаут запроса не превышен
    if(controllerReadyFLAG != 1) return;                        // если контроллер ещё не готов, то новую команду мы ему точно не пошлём
    
    // по команде записываем конфигурацию в контроллер
    if(writeParametrsFLAG == 1) { 
      writeParametrs(sequinsTimeDelayTemp);
      return;
    }

    // по команде транслируем команду напрямую в контроллер
    if((broadcastFLAG == 1)&(sequinsMatrixUpdateFLAG == 1)) {
      sendSequinsState(sequinsState,sequinsQuantity);
      return;
    }
    
  }
  
  // записываем параметры в контроллер
  void writeParametrs (float sequinsTimeDelayTemp) {
    controllerReadyFLAG = 0; // контроллер занят
    writeParametrsFLAG = 0;  
    transmitComand = requests[3]; // SetParametr:
    transmitData = transmitComand + sequinsTimeDelayTemp + "\r\n";
    print(transmitData);
    headController.write(transmitData);
  }
  
  // отправляем состояние пайеток в контроллер
  void sendSequinsState (int sequinsState [], int sequinsQuantity) {
    controllerReadyFLAG = 0; // контроллер занят
    sequinsMatrixUpdateFLAG = 0;
    transmitComand = requests[4]; // SetSequins:
    transmitData = transmitComand;
    for(int i=0; i<sequinsQuantity; i++) {
      transmitData += sequinsState[i];    // записываем состояние каждой пайетки в строку
    }
    transmitData += "\r\n";
    print(transmitData);
    sequinsMatrixUpdateComplite = 0;  // сброс флага обновления матрицы
    headController.write(transmitData);
  }
  
  // дешифровка ответа контроллера и установка флагов
  void decodeAnswer (String strTemp) {
    int controllerReadyTemp = 0;
    println("answer: " + strTemp);
    if(transmitComand.equals(requests[3])) { // requests == "SetParametr:"
          if(strTemp.equals(answers[0])) { // answer == "OK"
                controllerReadyTemp = 1;
                sequinsTimeDelayPrev = sequinsTimeDelay;
                println("parameter set successfully");
          }
    }
    
    if(transmitComand.equals(requests[4])) { // requests == "SetSequins:"
          
          if(strTemp.equals(answers[0])) { // answer == "OK"
                controllerReadyTemp = 1;
                println(2);
          }
          
          if(strTemp.equals(answers[3])) {  // answer == "sequinsIsSet"
                controllerReadyTemp = 1;
                sequinsMatrixUpdateComplite = 1;
                println(1);
          }
    }
       

    controllerReadyFLAG = controllerReadyTemp;
  }
  
  // таймауст запроса от контроллера
  int timeOutCounter (int counterON) {
      timeActual = millis();
      if(counterON != 0) {      // если команду не отправили, то просто сохраняем текущее время
        timePrev = timeActual;
      }
      else {                    // если команду отправили и нет ответа, то сбрасываем флаг и мы готовы к новой отправке
        int diff = abs(timeActual - timePrev);
        if(diff > controllerTimeOut) {
          counterON = 1;
          resetWriteFlags();
          println("erorr: controller time out request");
        }
      } 
      return counterON;
  }
  
  // при возникновении таймаута запроса, разрываем соединение и сбрасываем все флаги передачи
  void resetWriteFlags() {
    broadcastFLAG = 0;
    writeParametrsFLAG = 0;
    sequinsMatrixUpdateComplite = 0;
    sequinsMatrixUpdateFLAG = 0;
  }
  
}

// принимаем посылку из COM порта
void serialEvent(Serial p) { 
  String resiveString = p.readString();
  int resiveStringLength = resiveString.length();
  resiveStringLength -= 2; // последние два символа всегда занимают \r\n
  controller.resiveData = resiveString.substring(0,resiveStringLength);
  
  // передаём в обработку полученную строку
  controller.decodeAnswer(controller.resiveData);
} 
