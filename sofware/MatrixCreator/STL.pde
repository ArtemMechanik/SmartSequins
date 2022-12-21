class modelImport {
  public
  String fileName;
  String[] lines;
  float vertices [][] = new float [50000][3];       // координаты вершин модели платья, читаемые из STL файла и[][0] - X, [][1] - Y, [][2] - Z
  float faset_N_vector [][] = new float [50000][3]; // вектор нормали для фасеты
  int   verticess_counter;                      // счётчик вершин модели платья
  int   fasets_counter;                         // счётчик фасет модели платья
  color fasetFillColor;
  color fasetStrokeColor;
  int   modelPrint = 1;
  
  // конструктор 
  modelImport(String fileNameTemp) {
    fileName = fileNameTemp;
    verticess_counter = 0;
    fasets_counter = 0;
    fasetFillColor = color(130); // цвет фасеты по умолчанию
    fasetStrokeColor = 255;
  }
  
  // методы
  void readSTL () {  // чтание STL файла
      lines = loadStrings(fileName);
      String sub;
      int p;
      for (int i = 0 ; i < lines.length; i++)  {  // пока не распарсим все строки
        p=lines[i].indexOf("vertex");             // ищем указатель на точку
        if (p>-1)                                 // если нашли
        { 
         sub=lines[i].substring(p+7);             // то через 7 символов будет первая цифра
         String[] list = split(sub, ' ');         // split разбивает новую строку на массивы подстрок
            
         vertices[verticess_counter][0] = float(list[0]);        // копируем даные в массив
         vertices[verticess_counter][1] = -float(list[1]);
         vertices[verticess_counter][2] = float(list[2]);
                
         verticess_counter++;
        } 
      } 
      // информация для откладки, выводимая в консоль
      println("имя файла: " + fileName);
      println("вершин: " + verticess_counter);
      fasets_counter = verticess_counter/3;
      println("фасет: " + fasets_counter);
  }
  
  void printModel () { // отрисовка модели в сцене
    if(modelPrint == 1) {
       for(int i = 0; i<verticess_counter; i=i+3) {
         // отрисовываем текущую фасету
         stroke(fasetStrokeColor);
         fill(fasetFillColor);
         beginShape(); // все вершины, находящиеся между beginShape и endShape образуют плоскость
           vertex(vertices[i][0],vertices[i][1],vertices[i][2]);
           vertex(vertices[i+1][0],vertices[i+1][1],vertices[i+1][2]);
           vertex(vertices[i+2][0],vertices[i+2][1],vertices[i+2][2]);
         endShape(CLOSE);
      }
    }
  }
  
  void setFasetColor (color fasetStrokeColorTemp, color fasetFillColorTemp) { // установка цвета при отрисовки модели
    fasetFillColor = fasetFillColorTemp;
    fasetStrokeColor = fasetStrokeColorTemp;
  }
  
  void writeSTL (String[] lines) { // запись STL файла
     outputSTL = createWriter("model2.stl");
     for (int i = 0 ; i < lines.length; i++)  {
       outputSTL.println(lines[i]);
     }
     outputSTL.flush(); 
     outputSTL.close();
  }
  
  void transform(String[] lines1, String[] lines2, float x_transform) {
    String sub;
    int p;
    float x_temp;
    for (int i = 0 ; i < lines1.length; i++)  {
      p=lines1[i].indexOf("vertex");
      if (p == -1) {
        lines2[i] = lines1[i];
        continue;
      }
      sub=lines1[i].substring(p+7);
      String[] list = split(sub, ' ');
      vertices[verticess_counter][0] = float(list[0]);        // копируем даные в массив
      vertices[verticess_counter][1] = float(list[1]);
      vertices[verticess_counter][2] = float(list[2]);
      
      vertices[verticess_counter][0] += x_transform;
      lines2[i] = "vertex " 
                 + str(vertices[verticess_counter][0])
                 + " "
                 + str(vertices[verticess_counter][1])
                 + " "
                 + str(vertices[verticess_counter][2]);
    }
  }
  
  // добавление к lines1 объекта из lines2
  void addSolid(String[] lines1, String[] lines2, float x_transform, float y_transform) {
    int lineNumber = -1;
    int line1Couter = 0;
    
    for (int i = 0 ; i < lines1.length; i++) {
      if(lines1[i].indexOf("endsolid") != -1) {
        lineNumber = i;
        break;
      }
      outputSTL.println(lines1[i]);
    }
    if(lineNumber < 0) return;
        String sub;
    int p;
    float x_temp;
    for (int i = 1 ; i < lines2.length; i++)  {
      p=lines1[i].indexOf("vertex");
      if (p == -1) {
        outputSTL.println(lines2[i]);
        continue;
      }
      sub=lines2[i].substring(p+7);
      String[] list = split(sub, ' ');
      vertices[verticess_counter][0] = float(list[0]);        // копируем даные в массив
      vertices[verticess_counter][1] = float(list[1]);
      vertices[verticess_counter][2] = float(list[2]);
      
      vertices[verticess_counter][0] += x_transform;
      vertices[verticess_counter][1] += y_transform;
      outputSTL.println( "vertex " 
                         + str(vertices[verticess_counter][0])
                         + " "
                         + str(vertices[verticess_counter][1])
                         + " "
                         + str(vertices[verticess_counter][2]));
    }
    
  }
}
