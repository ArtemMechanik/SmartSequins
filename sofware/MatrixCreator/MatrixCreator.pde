import controlP5.*;
ControlP5 menu;



color backgroundColor = color(50);
float rotX, rotY, rotZ, camX, camY, camZ;

MatrixAPI grid = new MatrixAPI();
MatrixAPI pattern = new MatrixAPI();

PrintWriter patternFile;
PrintWriter outputSTL;
String[] stlLines;
String[] stlLines2;

void setup () {
  size(1000, 800, P3D);
  frameRate(60);
  
  menu = new ControlP5(this);
  menu.setFont(createFont("Arial bold",20));
  textFont(createFont("Arial bold",20));

  menuSetup();
  resetVariable();
  
  pattern.setSize(20,9);
  pattern.setScaleAuto();
  pattern.setPositionAuto(); 
  
  defaultCameraPosition();
}

void draw () {
  background(backgroundColor,255);
  
  // ***************************************************отрисовка 3D объектов******************************************
  hint(ENABLE_DEPTH_TEST);
    pushMatrix();
      translate(camX, camY, camZ);            // вращаем камеру вокруг сцены        
      rotateX(rotX);
      rotateZ((rotZ));
      
      //printCoordinateSystem();
    popMatrix();
  hint(DISABLE_DEPTH_TEST);
  
  //*********************************************элементы графического интерфейса*************************************
  pattern.updateState();
  pattern.Print();
  drawGUI();
  
  // ***************************************сохраняем текущий паттерн в файл конфигурации****************************
  if(savePatternFLAG == 1) {
    selectOutput("Select a file to write:", "writefileSelected");
    savePatternFLAG = 2;
  }
  if(savePatternFLAG == 3) {  
    patternFile = createWriter(outputFileAbsolutePath);
    // данные о габаритах матрицы
    patternFile.println("size(" + pattern.matrixSize_X + ";" + pattern.matrixSize_Y + ")");
    patternFile.println("matrixMode(" + pattern.matrixCalculateMode + ")");
    for(int i = 0; i < pattern.matrixSize_X*pattern.matrixSize_Y; i++) {
      patternFile.println("sequin(" + pattern.sequinsCoordinates[i][0] + ";" + pattern.sequinsCoordinates[i][1] + ";" + pattern.sequinsState[i] + ")");
    }
    patternFile.flush(); 
    patternFile.close();
    println("Pattern file was write: " + outputFileAbsolutePath);
    savePatternFLAG = 0;
  }
  
  //******************************************открываем существующий паттерн***********************************
  if(loadPatternFLAG == 1) {
    selectInput("Select a file to read:", "readfileSelected");   
    loadPatternFLAG = 2;
  }
  if(loadPatternFLAG == 3) {
    // загружаем паттерн в массив строк
    String[] patternLines = loadStrings(inputFileAbsolutePath);
    if(patternLines == null) { 
      println("erorr: file not found!");
    }
    // парсим
    // сначала читаем размер матрицы
    for(int i = 0; i < patternLines.length; i++) {
      if(patternLines[i].indexOf("size") != -1) {
        int temp1, temp2;
        temp1 = patternLines[i].indexOf("(") + 1;
        temp2 = patternLines[i].indexOf(";");
        pattern.matrixSize_X = int(patternLines[i].substring(temp1,temp2));
        
        patternLines[i] = patternLines[i].substring(temp2+1);
        temp2 = patternLines[i].indexOf(")");
        pattern.matrixSize_Y = int(patternLines[i].substring(0,temp2));
        println(pattern.matrixSize_X + ";" + pattern.matrixSize_Y);
      }
    }
    // режим построения матрицы
    for(int i = 0; i < patternLines.length; i++) {
      if(patternLines[i].indexOf("matrixMode") != -1) {
        int temp1, temp2;
        temp1 = patternLines[i].indexOf("(") + 1;
        temp2 = patternLines[i].indexOf(")");
        pattern.matrixCalculateMode = int(patternLines[i].substring(temp1,temp2));
      }
    }
    // когда знаем размер матрицы, начинаем искать состояния элементов
    int sequinsCounter = 0;
    for(int X_quantity_temp = 0; X_quantity_temp< pattern.matrixSize_X; X_quantity_temp++) { // заполняем оси Х (строки)
      for(int Y_quantity_temp = 0; Y_quantity_temp< pattern.matrixSize_Y; Y_quantity_temp++) { // заполняем по оси Y (столбики)
          int temp1, temp2;
          temp1 = patternLines[2+sequinsCounter].indexOf(";") + 1;
          patternLines[2+sequinsCounter] = patternLines[2+sequinsCounter].substring(temp1);
          temp1 = patternLines[2+sequinsCounter].indexOf(";") + 1;
          temp2 = patternLines[2+sequinsCounter].indexOf(")");
          pattern.sequinsState[sequinsCounter] = int(patternLines[2+sequinsCounter].substring(temp1,temp2));
          sequinsCounter ++;
          println(pattern.sequinsState[sequinsCounter]);
      }
    }
    pattern.setScaleAuto();
    println("Pattern file was read: " + inputFileAbsolutePath);
    loadPatternFLAG = 0;
  }
  
  // *********************************************создание файлов STL**************************************
  if(pattern.createStlFLAG == 1) {
    if(pattern.fragmentPrintFLAG == 0) {
      println("fragment not found, perform fragmentation!");
      pattern.createStlFLAG = 0;
    }
    else {
      println("start create STL");
      pattern.createStlFLAG = 2;
    }
  }
  
  // загружаем исходные STL модели фрагментов паттерна
  if(pattern.createStlFLAG == 2) {
    stlLines = loadStrings("source/STL/1.stl");
    stlLines2 = loadStrings("source/STL/2.stl");
    pattern.createStlFLAG = 3;
  }
  
  // пробуем записать в несколько отдельных STL файлов
  if(pattern.createStlFLAG == 3) {
    // сканируем сканируем массив с номерами фрагментов в поисках наибольшего
    println("fragment number max: " + str(pattern.sequinsmatrixFragment[pattern.matrixSize_X*pattern.matrixSize_Y-1]));
    println("STL start write...");
    for(int fragmentCounter = 1; fragmentCounter <= pattern.sequinsmatrixFragment[pattern.matrixSize_X*pattern.matrixSize_Y-1]; fragmentCounter++) {
      // Начинаем записывать в файл новый фрагмент
      outputSTL = createWriter("output/STL/fragment" + str(fragmentCounter) + ".stl");
      outputSTL.println("solid"); 
      for(int k=0; k<pattern.matrixSize_X*pattern.matrixSize_Y; k++) {
          // если текущий элемент паттерна пустой, то пропускаем его
          if(pattern.sequinsState[k] == 0) continue;
          
          if(pattern.sequinsmatrixFragment[k] != fragmentCounter) continue;
          
          if(pattern.sequinsState[k] == 1) {
                      // иначе заполняем
                      // для этого парсим исходный файл в поисках "vertex" и смещаем на соответствующие X и Y координаты
                      int p;
                      String sub;
                      String[] list;
                      float [] vertices = new float [3];
                      for (int i = 1 ; i < stlLines.length; i++)  {
                                        if(stlLines[i].indexOf("endsolid") != -1) continue;
                                        p = stlLines[i].indexOf("vertex");
                                        if (p == -1) {
                                          outputSTL.println(stlLines[i]);
                                          continue;
                                        }
                                        sub = stlLines[i].substring(p+7);
                                        list = split(sub, ' ');
                                        vertices[0] = float(list[0]);        // копируем даные в массив
                                        vertices[1] = float(list[1]);
                                        vertices[2] = float(list[2]);
                                        
                                        vertices[0] += pattern.sequinsCoordinates[k][0];
                                        vertices[1] += pattern.sequinsCoordinates[k][1];
                                        outputSTL.println( "vertex " 
                                                           + str(vertices[0])
                                                           + " "
                                                           + str(vertices[1])
                                                           + " "
                                                           + str(vertices[2]));
                     }
          }
          
          if(pattern.sequinsState[k] == 2) {

                      int p;
                      String sub;
                      String[] list;
                      float [] vertices = new float [3];
                      for (int i = 1 ; i < stlLines2.length; i++)  {
                                        if(stlLines2[i].indexOf("endsolid") != -1) continue;
                                        p = stlLines2[i].indexOf("vertex");
                                        if (p == -1) {
                                          outputSTL.println(stlLines2[i]);
                                          continue;
                                        }
                                        sub = stlLines2[i].substring(p+7);
                                        list = split(sub, ' ');
                                        vertices[0] = float(list[0]);        // копируем даные в массив
                                        vertices[1] = float(list[1]);
                                        vertices[2] = float(list[2]);
                                        
                                        vertices[0] += pattern.sequinsCoordinates[k][0];
                                        vertices[1] += pattern.sequinsCoordinates[k][1];
                                        outputSTL.println( "vertex " 
                                                           + str(vertices[0])
                                                           + " "
                                                           + str(vertices[1])
                                                           + " "
                                                           + str(vertices[2]));
                     }
          }
      }
      outputSTL.println("endsolid"); 
      outputSTL.flush(); 
      outputSTL.close();
      println("STL fragment" + str(fragmentCounter) + " write successfully!");
    }
    println("STL end write");
    pattern.createStlFLAG = 0;
  }
}

 void printCoordinateSystem () {
     // ось Z
     stroke(color(255,0,0));
     line(0,0,0,0,0,100);
     // ось Х
     stroke(color(0,255,0));
     line(0,0,0,100,0,0);
     // ось Y
     stroke(color(0,0,255));
     line(0,0,0,0,100,0);
  }
  
void defaultCameraPosition () {
      camX=width/2;
      camY=height/2+200;
      camZ = 200;
      rotX=radians(80);
      rotY=radians(90);
      rotZ = 0;
}
