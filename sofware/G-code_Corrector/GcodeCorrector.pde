/* Программа читает файл G кода и вносит туда изменения
*  Отрисовывает контуры G кода
*  Сразу после указанного слоя (;LAYER:X) необходимо отводить экструдер по оси Z (G0 Z20;), затем включать паузу M25
*  После возобновления печати необходимо вернуть экструде на место
*/ 
import controlP5.*;
ControlP5 menu;

// константы
int keyCode_L_CTRL = 17;

// системные
color backgroundColor = color(0,0,0);  // цвет фона
float rotX, rotY, rotZ, camX, camY, camZ;
int currentKeyCode = 0;  // код текущей нажатой клавиши на клавиатуре

// чтение файла
int selectFile = 0; // команда выбора файла для чтения
int openFileFLAG = 0;
int newFileLoadFLAG = 0;
String inputFileAbsolutePath; // путь к файлу, который нужно открыть
String[] GcodetLines; // сюда читаем исходный 
float X_max = 0, X_min = 10000, Y_max = 0, Y_min = 10000, Z_max = 0, Z_min = 10000; // параметры модели в файле

// запись файла
PrintWriter output_file;
int selectOutputFile = 0;
String outputFileAbsolutePath; // путь к файлу, который нужно перезаписать
int targetStringNumber = -1; // строка после которой нужно вставить необходимые команды
int setPause = 0;  // команда установки паузы на выбранном слое

// отрисовка
int string_number = 0;
float line [][] = new float[2][3];
float layerHigh = 0; // высота слоя по оси Z
int layerNumber = -1;
int layerNumberPrev = -1;
int startNumber, endNumber;
int selectedLayer = 0;
float scaleValue = 1.0;

void setup () {
  size(1000,800,P3D);
  menuSetup(); // создаём экранные формы и объекты меню
  //
  setDefaultParam();
  defaultCameraPosition();
}

void draw () {
  background(backgroundColor);
  
  // команада на открытие файла, вызываем окно для выбора файла
  if(selectFile == 1) {
    selectInput("Select a file to process:", "readfileSelected");   
    selectFile = 2;
  }
  // загружаем файл для обработки
  if(selectFile == 3) {
    GcodetLines = loadStrings(inputFileAbsolutePath);
    
    // если файл загрузить не удалось, то пока что просто повисаем
    if(GcodetLines == null) {
      println("erorr: file not found!");
      println("adjust the file name");
      while(1==1) {}
    }
    
    newFileLoadFLAG = 1;
    selectFile = 0;
  }
  
  // обработка нового файла
  // ищем строки ;LAYER:X 
  if(newFileLoadFLAG == 1) {
    // анализируем файл перед его отрисовкой, чтобы определить параметры камеры
    layerNumber = 0;    
    layerHigh = 0;
    
    for (int i = 0; i<GcodetLines.length; i++) {  // ищем нужную строку в массиве
      if(GcodetLines[i].indexOf(";LAYER:") != -1) {
          layerNumber += 1;
      }
        
      if((GcodetLines[i].indexOf("G1") != -1)|(GcodetLines[i].indexOf("G0") != -1)) {
          startNumber = GcodetLines[i].indexOf("X");
          if(startNumber != -1) {
              endNumber   = GcodetLines[i].indexOf(" ",startNumber);
              String X_coordinates;
              if(endNumber != -1) X_coordinates = GcodetLines[i].substring(++startNumber,endNumber);
              else                X_coordinates = GcodetLines[i].substring(++startNumber);
              line[0][0] = float(X_coordinates);
              if(line[0][0] > X_max) X_max = line[0][0];
              if(line[0][0] < X_min) X_min = line[0][0];
          }
          
          // ищем Y
          startNumber = GcodetLines[i].indexOf("Y");
          if(startNumber != -1) {
              endNumber   = GcodetLines[i].indexOf(" ",startNumber);
              String Y_coordinates; 
              if(endNumber != -1) Y_coordinates = GcodetLines[i].substring(++startNumber,endNumber);
              else                Y_coordinates = GcodetLines[i].substring(++startNumber);
              line[0][1] = -float(Y_coordinates);
              if(line[0][1] > Y_max) Y_max = line[0][1];
              if(line[0][1] < Y_min) Y_min = line[0][1];
          }
          
          // ищем Z
          startNumber = GcodetLines[i].indexOf("Z");
          if(startNumber != -1) {
              endNumber   = GcodetLines[i].indexOf(" ",startNumber);
              String Z_coordinates;
              if(endNumber != -1) Z_coordinates = GcodetLines[i].substring(++startNumber,endNumber);
              else                Z_coordinates = GcodetLines[i].substring(++startNumber);
              line[0][2] = float(Z_coordinates)*scaleValue;
              if(line[0][2] > Z_max) Z_max = line[0][2];
              if(line[0][2] < Z_min) Z_min = line[0][2];
          }
          
        }
    }
    // отчитываемся о результатах иследования
    println("layers: " + layerNumber);
    println("X max: " + X_max + "; " + "X min: " + X_min);
    println("Y max: " + Y_max + "; " + "Y min: " + Y_min);
    println("Z max: " + Z_max + "; " + "Z min: " + Z_min);
    
    defaultCameraPosition();
    
    newFileLoadFLAG = 0;
    openFileFLAG = 1;
  }
  
  // после открытия файла отрисовываем его как можем
  if(openFileFLAG != 0) {
  // не знаю что это за метод, ответ нашёл здесь: https://translated.turbopages.org/proxy_u/en-ru.ru.155f9c70-63368e13-759d7578-74722d776562/https/stackoverflow.com/questions/66303006/drawing-2d-text-over-3d-objects-in-processing-3
  // но он позволяет прорисовывать GUI отдельно от 3D объектов
  hint(ENABLE_DEPTH_TEST);
  pushMatrix();
    translate(camX, camY, camZ);            // вращаем камеру вокруг модели        
    rotateX(rotX);
    rotateZ((rotZ));
    
    // парсим файл и ищем команды G1 - рабочее перемещение 
    layerNumber = 0;
    layerHigh = 0;
    for (int i = 0; i<GcodetLines.length; i++) {  // ищем нужную строку в массиве
      if(GcodetLines[i].indexOf(";LAYER:") != -1) {
          layerNumber += 1;
      }
      if((GcodetLines[i].indexOf("G1") != -1)|(GcodetLines[i].indexOf("G0") != -1)) {
          // ищем X
          startNumber = GcodetLines[i].indexOf("X");
          if(startNumber != -1) {
              endNumber   = GcodetLines[i].indexOf(" ",startNumber);
              String X_coordinates;
              if(endNumber != -1) X_coordinates = GcodetLines[i].substring(++startNumber,endNumber);
              else                X_coordinates = GcodetLines[i].substring(++startNumber);
              line[0][0] = float(X_coordinates);
          }
          
          // ищем Y
          startNumber = GcodetLines[i].indexOf("Y");
          if(startNumber != -1) {
              endNumber   = GcodetLines[i].indexOf(" ",startNumber);
              String Y_coordinates; 
              if(endNumber != -1) Y_coordinates = GcodetLines[i].substring(++startNumber,endNumber);
              else                Y_coordinates = GcodetLines[i].substring(++startNumber);
              line[0][1] = -float(Y_coordinates);
          }
          
          // ищем Z
          startNumber = GcodetLines[i].indexOf("Z");
          if(startNumber != -1) {
              endNumber   = GcodetLines[i].indexOf(" ",startNumber);
              String Z_coordinates;
              if(endNumber != -1) Z_coordinates = GcodetLines[i].substring(++startNumber,endNumber);
              else                Z_coordinates = GcodetLines[i].substring(++startNumber);
              line[0][2] = float(Z_coordinates)*scaleValue;
              
              // отрисовываем паузу
              if(setPause == 1) {
                if(layerNumber >= selectedLayer) {
                  line[0][2] += 20;
                }
              }
          }
          // сохраняем нмоер строки после которой нужно сделать вставку
          // это будет место, перед переходом экструдера на следующий слой
          // запоминаем номер этой строки
          if((layerNumber == selectedLayer)&(layerNumber != layerNumberPrev)) {
            println("target string #" + i);
            targetStringNumber = i; // сохраняем номер строки
            layerNumberPrev = layerNumber;
          }
          
          // корректируем элементы оформления
          if(layerNumber == selectedLayer)  
            stroke(color(255,0,0));
          else if(layerNumber >= selectedLayer)
          {
            if(setPause == 1) stroke(#0DCAFC);
            else              stroke(255);
          }
          else                stroke(255);
          
          // отрисовываем линию траектории
          if(GcodetLines[i].indexOf("G1") != -1) 
            line(line[0][0],line[0][1],line[0][2],line[1][0],line[1][1],line[1][2]);
          
          // сохраняем координаты начал отрезка
          line[1][0] = line[0][0];
          line[1][1] = line[0][1];
          line[1][2] = line[0][2];
        }
    }
    printCoordinateSystem();
  popMatrix();
  }
  
  // сохраняем отредактированный файл
  if(selectOutputFile == 1) {
    selectOutput("Select a file to write to:", "writefileSelected");
    selectOutputFile = 2;
  }
  
  if(selectOutputFile == 3) {
    // вносим изменения в файл
    GcodetLines = splice(GcodetLines,"M25",targetStringNumber-2);      // ставим на паузу
    GcodetLines = splice(GcodetLines,"G0 Z20",targetStringNumber-1);  // приподнимаем экструдер
    // не понятно почему, но эти команды должны идти именно в таком порядке... Иначе пауза не отрабатавается сразу, а экструдер опускается
    
    // создаём файл с указанным именем по указанному адресу outputFileAbsolutePath
    output_file = createWriter(outputFileAbsolutePath);  // создаём файл
    for(int i=0; i<GcodetLines.length; i++) {
      output_file.println(GcodetLines[i]);
    }
    output_file.flush(); 
    output_file.close();
    
    println("file was write!");
    selectFile = 3; // для корректного отображения модельки заново читаем исходный файл
    selectOutputFile = 0;
  }
  
  // перед отрисовкой GUI, выключаем метод
  hint(DISABLE_DEPTH_TEST);
  drawGUI();
}

// начальное положение камеры
void defaultCameraPosition () {
      // делаем так, чтобы модель пометилась во всю ширину экрана
      camX=width/2 - (X_min + X_max)/2;
      camY=height/2 - (Y_min + Y_max)/2;
      camZ = (Z_max - Z_min)/20;
      rotX=radians(45);
      rotZ = 0;
}

// выводим начало системы координат в виде нескольких линий
void printCoordinateSystem () { 
     // ось Z
     stroke(color(255,0,0));
     line(0,0,0,0,0,100);
     // ось Х
     stroke(color(0,255,0));
     line(0,0,0,100,0,0);
     // ось Y
     stroke(color(0,0,255));
     line(0,0,0,0,-100,0);
  }
