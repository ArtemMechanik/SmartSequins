color sequinsColorFirst = #FFFFFF;  // белый
color sequinsColorSecond = #FF12C8; // розовый
color sequinsColorBorder = #000000; // чёрный

// токи потребления каждой пайетки в различных режимах
float   sleapModeCurrent = 100;       // мкА
float   workModeCurrent = 4;          // мА
float   colorChangeModeCurrent = 200; // мА

// задержка переключения пайеток
float   sequinsTimeDelay  = 10;       // мС
float   sequinsTimeDelayPrev = 0; 
// время смены цвета
float   sequinsTimeChangeColor = 50;  // мС
float   sequinsTimeChangeColorPrev = 0; 

// парамтеры моделирования
float totalTime = 0;
float currentMax = 0;

class SequinsAPI {
  int [][] sequinsCoordinates = new int [1000][2];
  int [][] sequinsColor = new color [1000][2]; // 0 fill, 1-stroke
  int [] sequinsWorkState = new int [1000]; // состояние пайеток (0 - спящий режим, 1 - работает, 2 - смена цвета)
  int [] sequinsState = new int [1000]; // 0 - первый цвет, 1-второй цвет
  int [] sequinsStatePrev = new int [1000]; // предыдущее состояние матрицы пайеток
  int sequinsQuantity;
  int sequins_X_quantity;
  int sequins_Y_quantity;
  float sequinsSize;
  int sequins_R_out; // радиус описанной окружности пайеток
  int sequinsColorChangeFLAG;
  int sequinsSetFLAG;
  int sequinsResetFLAG;
  int sequinsColorPointer;
  float workVoltage;
  
  // конструктор
  SequinsAPI() {
    sequinsQuantity = 0;
    sequins_X_quantity = 0;
    sequins_Y_quantity = 0;
    sequinsSize = 1;
    sequins_R_out = 35;
    sequinsColorChangeFLAG = 0;
    sequinsSetFLAG = 0;
    sequinsResetFLAG = 0;
    sequinsColorPointer = 0;
    workVoltage = 5.0;
    for(int i=0; i<sequinsQuantity; i++) {
      sequinsColor[i][0] = sequinsColorFirst;
      sequinsColor[i][1] = backgroundColor;
      sequinsState[i] = 0;
      sequinsStatePrev[i] = sequinsState[i];
    }
  }
  
  void setSize (float sizeTemp) {
    sequinsSize = sizeTemp;
  }
  
  // вывод одной пайетки
  void Print (int offset_X, int offset_Y, float size_factor, color color_fill, color strokeColor) {
    strokeWeight(2);
    stroke(strokeColor);
    fill(sequinsColorSecond);
    beginShape(); // рисуем шестиугольник
      vertex(offset_X+sequins_R_out*cos(radians(60))*size_factor, offset_Y+sequins_R_out*sin(radians(60))*size_factor);
      vertex(offset_X+sequins_R_out*size_factor, offset_Y);
      vertex(offset_X+sequins_R_out*cos(radians(60))*size_factor, offset_Y-sequins_R_out*sin(radians(60))*size_factor);
      vertex(offset_X-sequins_R_out*cos(radians(60))*size_factor, offset_Y-sequins_R_out*sin(radians(60))*size_factor);
      vertex(offset_X-sequins_R_out*size_factor, offset_Y);
      vertex(offset_X-sequins_R_out*cos(radians(60))*size_factor, offset_Y+sequins_R_out*sin(radians(60))*size_factor);
      vertex(offset_X+sequins_R_out*cos(radians(60))*size_factor, offset_Y+sequins_R_out*sin(radians(60))*size_factor);
    endShape();
    // а вот теперь фрагмент, который меняет цвет
    noStroke();
    fill(color_fill);
    circle(offset_X,offset_Y,(sequins_R_out-8)*size_factor*2);
  }
  
  // расчёт матрицы пайеток
  void CalculateMatrix (int X_quantity, int Y_quantity) {
    int X_quantity_temp;
    int Y_quantity_temp;
    int Y_offset_local; // смещение на нечётных
    int sequinsCounter = 0;
    sequins_X_quantity = X_quantity;
    sequins_Y_quantity = Y_quantity;
    
    sequinsQuantity = X_quantity * Y_quantity;
    for(X_quantity_temp = 0; X_quantity_temp< X_quantity; X_quantity_temp++) { // заполняем оси Х (строки)
      if((X_quantity_temp%2)==0) { Y_offset_local = -int((sequins_R_out*sin(radians(60)))*sequinsSize); } else { Y_offset_local = 0; }
      for(Y_quantity_temp = 0; Y_quantity_temp< Y_quantity; Y_quantity_temp++) { // заполняем по оси Y (столбики)
        sequinsCoordinates[sequinsCounter][0] =  int(54*X_quantity_temp*sequinsSize); // вводим координату Х
        sequinsCoordinates[sequinsCounter][1] =  Y_offset_local + int(62*Y_quantity_temp*sequinsSize); // вводим координату Y
        sequinsCounter++;
      }
    }
  }
  
  // вывод матрицы пайеток, указывам только положение центра первого элемента матрицы
  void PrintMatrix (int offset_X, int offset_Y) {  
    // в зависимости от режима меняем 
    if(broadcastFLAG == 1) {
      for(int i=0; i<sequinsQuantity; i++) {
        if(sequinsState[i] == 0) sequinsColor[i][0] = sequinsColorFirst; else if(sequinsState[i] == 1) sequinsColor[i][0] = sequinsColorSecond;
      }
    }
    else {
      for(int i=0; i<sequinsQuantity; i++) {
        if(sequinsState[i] == 0) sequinsColor[i][0] = #B2B2B2; else if(sequinsState[i] == 1) sequinsColor[i][0] = #B0A3FC;;
      }
    }
    
    if(sequinsMatrixUpdateComplite == 0) {
       for(int i=0; i<sequinsQuantity; i++) {
          sequinsColor[i][0] = color(255,0,0,150);
       }
    }
    
    // теперь прорисовываем каждую пайетку
    for(int i = 0; i < sequinsQuantity; i++) {
          Print(sequinsCoordinates[i][0]+offset_X,sequinsCoordinates[i][1]+offset_Y,sequinsSize,sequinsColor[i][0],sequinsColor[i][1]);
          
          // отобразить номер пайетки
          if(sequinsNumberShow == 1) { 
            fill(0);
            textSize(20*sequinsSize);
            textAlign(CENTER,CENTER);
            text(i,sequinsCoordinates[i][0]+offset_X,sequinsCoordinates[i][1]+offset_Y);
          }
          
          // отображаем информацию о режиме работы
          if(sequinsNumberShow == 1) {
            switch(sequinsWorkState[i]) {
              case 0:
                fill(#2FFC08); // зелёный
              break;
              
              case 1:
                fill(#EBFC08); // жёлтый
              break;
              
              case 2:
                fill(#FC0808); // красный
              break;
            }
            noStroke();
            circle(sequinsCoordinates[i][0]+offset_X,sequinsCoordinates[i][1]+sequinsCoordinates[0][1]*0.6+offset_Y,20*sequinsSize);
          }
    }
    
    // если необходимо изменить цвет пайеток
   changeColor();
   setAll();
   resetAll();
   // установка цвета мышкой
   setColor(offset_X,offset_Y);
   // вычисляем параметры переключения матрицы
   calculator();
   
   // если изменилось состояние хоть одной пайетки, то отправляем команду в контроллер
   for(int i=0; i<sequinsQuantity; i++) {
     if(sequinsState[i] != sequinsStatePrev[i]) sequinsMatrixUpdateFLAG = 1;
   }
   
   // копируем текущее состояние матрицы, когда включаем режим трансляции в контроллер
    if(broadcastFLAG == 1) {
      for(int i=0; i<sequinsQuantity; i++) {
        sequinsStatePrev[i] = sequinsState[i];
      }
    }
  }
  
  void changeColor () {
     if(sequinsColorChangeFLAG == 1) {
           for(int i=0; i<sequinsQuantity; i++) {
                  if(sequinsState[i] == 0) sequinsState[i] = 1; else sequinsState[i] = 0;
           }
           sequinsColorChangeFLAG = 0;
      }
  }
  
  void setAll () {
    if(sequinsSetFLAG == 1) {
           for(int i=0; i<sequinsQuantity; i++) {
                  sequinsState[i] = 1;
           }
           sequinsSetFLAG = 0;
      }
  }
  
  void resetAll () {
    if(sequinsResetFLAG == 1) {
           for(int i=0; i<sequinsQuantity; i++) {
                  sequinsState[i] = 0;
           }
           sequinsResetFLAG = 0;
      }
  }
  
  // установка цвета пайетки вручную
  void setColor (int offset_X, int offset_Y) {  
    for(int i=0; i<sequinsQuantity; i++) {
      int distance = distance(mouseX,mouseY,sequinsCoordinates[i][0]+offset_X,sequinsCoordinates[i][1]+offset_Y);
      if(distance < (sequins_R_out*sequinsSize)) sequinsColor[i][1] = 255; else sequinsColor[i][1] = backgroundColor;
      if((sequinsColor[i][1] != backgroundColor)&(mouseButtonLeftFLAG != 0))  {  // если щёлкнули по какой-то пайетке, то она непременно меняет цвет
        if(sequinsState[i] == 0) sequinsState[i] = 1; else sequinsState[i] = 0;
        mouseButtonLeftFLAG = 0;
      }
    }
  }
  
  // вычисляем расстояние между двумя точками на плоскости с заданными координатам, ответ округляем до int
  private int distance (int x1, int y1, int x2, int y2) {
    int distanceTemp = 0;
    distanceTemp = int(sqrt((x1-x2)*(x1-x2) + (y1-y2)*(y1-y2)));
    return distanceTemp;
  }
  
  // метод используется чтобы расчитать ток потребления матрицы и скорость смены цвета для каждого из режимов
  // вычисляемые параметры:
  // - пиковый ток потребления
  // - общее время переключения матрицы
  // для простоты расчётов, считаем, что ограничение скорости сигнала накладывает только параметр delay
  private void calculator () {
    // ячеек изменилось и какими затратами времени это грозит

    int changeFLAG = 0;
    totalTime = 0;
    for(int i=0; i<sequinsQuantity; i++) {
       if(sequinsState[i] != sequinsStatePrev[i]) { // если значение ячейки изменилось
         // пайетки, которые не изменяют цвет, пропускаются без задержек
         totalTime += sequinsTimeDelay; // считаем время
         changeFLAG = 1;
       }
    }
    // поскольку процесс смены цвета начинается сразу после поступления сигнала, к итоговому времени работы полотна будет прибавляться только время смены цвета одной пайеткой
    if(changeFLAG == 1) totalTime += sequinsTimeChangeColor;
    //println("totalTime = " + totalTime + "mS");

    
    // считаем пиковые значения тока
    int lastSequin = -1;
    int sequinChangeColorCounter = 0;
    float currentWork = 0; // рабочий ток электроники пайеток
    for(int i=0; i<sequinsQuantity; i++) {
      if(sequinsState[i] != sequinsStatePrev[i]) {
        lastSequin = i+1; // вычисляем последний элемент матрицы, который должен изменить цвет, все, идущие после него можно не тревожить
        sequinChangeColorCounter ++ ;
      }
    }
    
    if(lastSequin == -1) currentWork = (sleapModeCurrent/1000)*sequinsQuantity; // если состояние пайеток не изменяется, то будет только энергопотребление от спящего режима
    else {                 
        currentWork = workModeCurrent;                          // если изменяется хотя бы одна, то первая уж точно будет в рабочем режиме
        for(int i=1; i<lastSequin; i++) {
          currentWork += (workModeCurrent); // рабочий ток * количество пайеток = ток потребления
          
        }
        currentWork += (sleapModeCurrent/1000)*(sequinsQuantity-lastSequin); // уситываем энергопотребление оставшихся спящих пайеток
    }
    
    // также не забываем про ток смены цвета паеток
    int overlay = 0; // количество пайеток переключающихся одновременно
    float currentChange = 0; // ток потребляемый двигателем во премя смены цвета
    int changingOneTime = ceil((sequinsTimeChangeColor)/(sequinsTimeDelay)); // определяем сколько пайеток может измениться одновременно (то есть сколько будет перекрытий)
    if(changingOneTime <= sequinChangeColorCounter) currentChange = changingOneTime*colorChangeModeCurrent; // если меняется большее количество, чем количество перекрытий, то максимальное количество перекрытий всё равно не измениться
    else currentChange = sequinChangeColorCounter*colorChangeModeCurrent; 
    
    // суммарный ток, потребляемой матрицей
    currentMax =  currentWork + currentChange;
  }
  
  

}
