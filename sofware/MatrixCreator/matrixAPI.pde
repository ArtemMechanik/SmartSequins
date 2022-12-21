class MatrixAPI  {
  int matrixCalculateMode;
  int matrixSize_X;
  int matrixSize_Y;
  float matrixOffset_X;
  float matrixOffset_Y;
  float matrixWidth;
  float matrixHeight;
  int matrixPosition_X;
  int matrixPosition_Y;
  float [][] sequinsCoordinates   = new float [2000][2];
  int [] sequinsState           = new int [2000];
  int [] sequinsStateCop        = new int [2000];
  int [] sequinsHit             = new int [2000];
  
  int [] sequinsmatrixFragment  = new int [2000];
  int fragmentCounter;
  int fragmentPrintFLAG;
  int fragmentSizeX;
  int fragmentSizeY;
  
  int createStlFLAG = 0;
  
  color strokeColor = color(100);
  color fillColor = backgroundColor;
  
  SequinsAPI sequins = new SequinsAPI();
  
  
  // конструктор
  MatrixAPI() {
    super();
    matrixCalculateMode = 0;
    sequinsmatrixFragment[0] = 1;
    fragmentPrintFLAG = 0;
    fragmentSizeX = 3;
    fragmentSizeY = 3;
  }
  
  // установка размеров матрицы
  public void setSize (int X_quantity, int Y_quantity) {
    matrixSize_X = X_quantity;
    matrixSize_Y = Y_quantity;
  }
  
  // установка размера по габаритам окна
  public void setScaleAuto () {
    CalculateMatrix();
    float scaleHeight  =   (height)/matrixHeight;
    float scaleWidth   =   (width-300)/matrixWidth;
    if(scaleWidth >= scaleHeight) {
      sequins.size = scaleHeight;
    }
    else {
      sequins.size = scaleWidth;
    }
  }
  
  public void setPositionAuto () {
    CalculateMatrix();
    matrixOffset_X = width - (matrixWidth) + (sequins.sequins_R_out*sequins.size);
    matrixOffset_Y = (2*sequins.sequins_R_out*sequins.size*cos(radians(30)));
  }

 public void setPosition (int Offset_X, int Offset_Y) {
    CalculateMatrix();
    matrixOffset_X = Offset_X;
    matrixOffset_Y = Offset_Y;
  }
  
 public float getPositionX () {
   return matrixOffset_X;
 }
 
 public float getPositionY () {
   return matrixOffset_Y;
 }
  
  public void Stroke (color strokeCol) {
    strokeColor = strokeCol;
  }
  
  public void NoStroke () {
    strokeColor = backgroundColor;
  }
  
  public void Fill (color color_fill) {
    fillColor = color_fill;
  }
  
  public void NoFill () {
    fillColor = backgroundColor;
  }
  
  // расчёт матрицы
  public void CalculateMatrix () {
    int X_quantity_temp;
    int Y_quantity_temp;
    float Y_offset_local; // смещение на нечётных
    int sequinsCounter = 0;
    matrixWidth = 0;
    matrixHeight = 0;
    
    for(X_quantity_temp = 0; X_quantity_temp< matrixSize_X; X_quantity_temp++) { // заполняем оси Х (строки)
      if(matrixCalculateMode == 0) {
        if((X_quantity_temp%2)!=0) Y_offset_local = -((sequins.sequins_R_out*sin(radians(60))));
        else                       Y_offset_local = 0; 
      }
      else {
        if((X_quantity_temp%2)==0) Y_offset_local = -((sequins.sequins_R_out*sin(radians(60))));
        else                       Y_offset_local = 0; 
      }

      matrixWidth += sequins.sequins_R_out*sequins.size + sequins.sequins_R_out*sequins.size*sin(radians(30));
      
      for(Y_quantity_temp = 0; Y_quantity_temp< matrixSize_Y; Y_quantity_temp++) { // заполняем по оси Y (столбики)
        sequinsCoordinates[sequinsCounter][0] =  (((sequins.sequins_R_out + sequins.sequins_R_out*sin(radians(30)))*X_quantity_temp)); // вводим координату Х
        sequinsCoordinates[sequinsCounter][1] =  ((Y_offset_local + (2*sequins.sequins_R_out*cos(radians(30))*Y_quantity_temp))); // вводим координату Y
        if(X_quantity_temp == 0) matrixHeight += 2*sequins.sequins_R_out*sequins.size*cos(radians(30));
        sequinsCounter++;
      }
    }
    matrixWidth -= sequins.sequins_R_out*sequins.size*sin(radians(30));
    matrixWidth += sequins.sequins_R_out*sequins.size;
    
    matrixHeight += sequins.sequins_R_out*sequins.size*cos(radians(30));
  }
  
  public void updateState () {
        for(int i = 0; i < matrixSize_X*matrixSize_Y; i++) {
              float distance = sequins.CheckDistance (sequinsCoordinates[i][0]*sequins.size + matrixOffset_X,sequinsCoordinates[i][1]*sequins.size + matrixOffset_Y,mouseX,mouseY);
              if(distance > toolSize*sequins.sequins_R_out*sequins.size) {
                sequinsHit[i] = 0;
              }
              else {
                sequinsHit[i] = 1;
                if(mousePressLeftFLAG == 1) {
                  switch(selectionTool) {
                    case 0: sequinsState[i] = 1; break;
                    case 1: sequinsState[i] = 0; break;
                    case 2: sequinsState[i] = 2; break;
                    case 3: sequinsState[i] = 3; break;
                    case 4: sequinsState[i] = 4; break;
                  }
                }
              }
        }
  }
  
  // разбиение на фрагменты
  public void Fragment () {
    int counter1 = 0;
    int counter2 = 0;
    int counter3 = 0;
    int numberMax = 1;
    int fragmentCounter = 1;
    if((fragmentSizeX == 0)||(fragmentSizeY == 0)) return;
    for(int i=0; i<matrixSize_X*matrixSize_Y; i++) {
      sequinsmatrixFragment[i] = fragmentCounter;
      counter1 ++;
      counter2 ++;
  
      if(counter2 == matrixSize_Y) {
        counter3++;
        if(counter3 == fragmentSizeX) {
          fragmentCounter++; 
          numberMax = fragmentCounter;
          counter3 = 0;
        }
        else   fragmentCounter = numberMax;
        
        counter2 = 0;
        counter1 = 0;
      } 
      
       if(counter1 == fragmentSizeY) {
        fragmentCounter++;
        counter1 = 0;
      }
    }
  }
  
  public void Print () {
    CalculateMatrix();
    if(mousePressRightFLAG == 1) {
      matrixOffset_X -= mouseDragged_X;
      matrixOffset_Y -= mouseDragged_Y;
    }
    for(int i = 0; i < matrixSize_X*matrixSize_Y; i++) {
      sequins.Stroke(strokeColor);
      sequins.Fill(fillColor);
      
      
      // цвет пайеток
      switch(sequinsState[i]) {
        case 1: sequins.Fill(200);     break;
        case 2: sequins.Fill(#F7F782); break;
        case 3: sequins.Fill(#8FF782); break;
      }
      sequins.Print((sequinsCoordinates[i][0])*sequins.size + matrixOffset_X,(sequinsCoordinates[i][1])*sequins.size + matrixOffset_Y);
      
      // цвет при наведении мыши
      if(sequinsHit[i] == 1) {
        fill(255,100);
        sequins.Print((sequinsCoordinates[i][0])*sequins.size + matrixOffset_X,(sequinsCoordinates[i][1])*sequins.size + matrixOffset_Y);
      }
      
      // если стоит галочка разбиения на слои, накладываем полутона
      if(pattern.fragmentPrintFLAG == 1) {
        // переключаемся в режим цветового круга
        colorMode(HSB, 360);
        int colorValue = sequinsmatrixFragment[i]*60;
        int temp = colorValue/360;
        colorValue -= temp*360;
        fill(colorValue,360,360);
      sequins.Print(sequinsCoordinates[i][0]*sequins.size + matrixOffset_X,sequinsCoordinates[i][1]*sequins.size + matrixOffset_Y);
        // возвращаемся в режим RGB 
        colorMode(RGB,255);
        // выводим номер фрагмента, которому принадлежит пайетка
        fill(0);
        textSize(10);
        textAlign(CENTER);
        text(sequinsmatrixFragment[i],sequinsCoordinates[i][0]*sequins.size + matrixOffset_X,sequinsCoordinates[i][1]*sequins.size + matrixOffset_Y);   
        textAlign(LEFT); 
      }
    }
  }
  
  class SequinsAPI {
  float sequins_R_out;
  float sequins_R_in;
  float size;
  float gap;
  
  byte mouseHit;
  
  // конструктор
  SequinsAPI() {
    size = 1;
    sequins_R_in = 5;
    sequins_R_out = (sequins_R_in + gap/2)/cos(radians(30)); //6.35;
    gap = 0;
    mouseHit = 0;
    
  }
  
  public void setSize (float sizeTemp) {
    size = sizeTemp;
  }
  
  public float getSize () {
    return size;
  }
  
  private float CheckDistance (float x1, float y1, float x2, float y2) {
    float distanceTemp = 0;
    distanceTemp = int(sqrt((x1-x2)*(x1-x2) + (y1-y2)*(y1-y2)));
    return distanceTemp;
  }
  
  public void Stroke (color strokeColor) {
    stroke(strokeColor);
  }
  
  public void NoStroke () {
    noStroke();
  }
  
  public void Fill (color color_fill) {
    fill(color_fill);
  }
  
  public void NoFill () {
    noFill();
  }
  
  // вывод одной пайетки
  public void Print (float offset_X, float offset_Y) {
    strokeWeight(2);
    beginShape(); // рисуем шестиугольник с координатами центра посередине фигуры
          vertex(offset_X+sequins_R_out*cos(radians(60))*size, offset_Y+sequins_R_out*sin(radians(60))*size);
          vertex(offset_X+sequins_R_out*size, offset_Y);
          vertex(offset_X+sequins_R_out*cos(radians(60))*size, offset_Y-sequins_R_out*sin(radians(60))*size);
          vertex(offset_X-sequins_R_out*cos(radians(60))*size, offset_Y-sequins_R_out*sin(radians(60))*size);
          vertex(offset_X-sequins_R_out*size, offset_Y);
          vertex(offset_X-sequins_R_out*cos(radians(60))*size, offset_Y+sequins_R_out*sin(radians(60))*size);
          vertex(offset_X+sequins_R_out*cos(radians(60))*size, offset_Y+sequins_R_out*sin(radians(60))*size);
    endShape();
  }
  }
}
