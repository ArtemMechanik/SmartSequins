PShape s; int p; String sub; float X,Y,Z;
float rotX, rotY, rotZ, camX, camY, camZ;
    
float pointX, pointY, pointZ;
float pointX_counter, pointY_counter, pointZ_counter;
    
float vertices [][] = new float [50000][3]; // [][0] - X, [][1] - Y, [][2] - Z
float faset_n_vector [][] = new float [50000][3]; // вектор нормали для фасеты

int vertices_counter = 0;
int vertices_counter_temp = 0;
int vertices_FLAG = 0;
int faset_counter = 0;

// строим сетку 
float grid_vertices [][][] = new float [100][100][3]; // вершины сетки
int grid_vertices_counter = 0;
// среднее расстояние от вершин фасет до оси Z
float R_cylinder = 0;
float R_cylinder_max = 0; // максимальный радиус

float H_cylinder = 200; // длина образующей цилиндра
float grid_nodes [][][] = new float [100][100][3];  // координаты узлов сетки
float grid_nodes_counter = 0;

float hexagon_size = 14;                    // диаметр вписаной окружности пайетки
float hexagon_gap = 1;                     // зазор между пайетками
// при построении сетки из шестиугольников расстояние между их центрами по вертикали соответствует радиусу вписанной окружности (hexagon_size/2)
// расстояние между их центрами по горизонтали определяется магическим числом, если захочешь, сможешь это проверить при помощи геометрических построений, а пока просто прими, что это число равно 1,732 
float magic_number = 1.732; 

float grid_size_height = 0;                 // количество узлов сетки по вертикали
float grid_size_width = 0;                  // количество узлов сетки по горизонтали
float grid_angle = 359;    
float grid_temp;

float grid_node_height = 0;
float grid_node_width = 0;

/*
float[][] hexagon_translate = new float [5000][3];
float[][] hexagon_angle = new float [5000][2];
color[] hexagon_color = new color [5000];
int hexagon_counter = 0;
float[] hexagon_distance = new float [5000];
*/

// размещение координат в двухмерной матрице позволит упростить нахождение образующих поверности платья
float[][][] hexagon_translate = new float [100][100][3];
float[][][] hexagon_angle = new float [100][100][2];
color[][] hexagon_color = new color [100][100];
int hexagon_counter = 0;
float[] hexagon_distance = new float [5000];
float hexagon_height_counter = 0;
float hexagon_width_counter = 0;
 float hexagon_scale [][][] = new float[100][100][2];

int keyboard_key_code = 0;
int color_cahnge_FLAG = 0;
int hexagon_color_counter = 0;
int hexagon_color_state = 1;

PrintWriter output_file;

float razvertka [][] = new float [100][100]; // длина отрезков развёртки, горизонтальные и вертикальные линии

float image_mode = 0; // этапы отрисовки изображения


void setup() { 
      size(640, 800, P3D);
      frameRate(60);
      
      output_file = createWriter("hexagon_matrix.txt"); // перезаписываем в тот же файл
      
      background(0); 
      
      // читаем вершины из файла STL
      String[] lines = loadStrings("test4.stl");   // выгружаем текстовый STL
      for (int i = 0 ; i < lines.length; i++)  {  // пока не распарсим все строки
        p=lines[i].indexOf("vertex");             // ищем указатель на точку
        if (p>-1)                                 // если нашли
        { 
         sub=lines[i].substring(p+7);             // то через 7 символов будет первая цифра
         String[] list = split(sub, ' ');         // split разбивает новую строку на массивы подстрок
         X=float(list[0]);                        // в каждой подстроке в формате float лежат координаты вершин
         Y=-float(list[1]); 
         Z=float(list[2]);
         
         vertices[vertices_counter][0] = X;        // копируем даные в массив
         vertices[vertices_counter][1] = Y;
         vertices[vertices_counter][2] = Z;
                
         vertices_counter++;
        } 
      } 
      println("вершин: " + vertices_counter);
      faset_counter = vertices_counter/3;
      println("фасет: " + faset_counter);
      faset_counter = 0;
      
      // необходимо определить среднюю удалённость точек тела от оси Z
      // строим вокруг тела цилиндр со средним радиусом
      // цилиндр состоит из точек с заданным шагом по оси Z и отстоящих на равные угловые расстояния
      
      // вычисляем среднюю удалённость вершин модели от оси Z, это значение станет радиусом основания цилиндра
      float line [][] = new float [2][3];
      for(int i=0; i<vertices_counter; i++) {
        // определяем линию от вершины поверхности тела до оси Z
        line[0][0] = vertices[i][0];  line[0][1] = vertices[i][1];  line[0][2] = vertices[i][2];
        line[1][0] = 0;               line[1][1] = 0;               line[1][2] = vertices[i][2];
        float temp  = line_lenght(line);
        if(R_cylinder_max < temp)  R_cylinder_max = temp;
        R_cylinder = R_cylinder + line_lenght(line)/vertices_counter; 
      }
      println("средний радиус: " + R_cylinder);
      println("максимальный радиус: " + R_cylinder_max);
      
      // вычисляем максимальное и минимальную Z координаты для всех вершин модели, разность между этими координатами будет равна длине образующей цилинтра
      float H_cylinder; // длина образующей цилиндра
      float cylinder_Z_max = 0;
      float cylinder_Z_min = 1000;
      for(int i=0; i<vertices_counter; i++) {
        if(vertices[i][2] > cylinder_Z_max) cylinder_Z_max = vertices[i][2];
        if(vertices[i][2] < cylinder_Z_min) cylinder_Z_min = vertices[i][2];
      }
      H_cylinder = cylinder_Z_max - cylinder_Z_min;
      println("cylinder_Z_max: " + cylinder_Z_max);
      println("cylinder_Z_min: " + cylinder_Z_min);
      println("образующая цилиндра: " + H_cylinder);
      
      // определяем параметры сетки
      grid_size_height = ceil(H_cylinder/(hexagon_size+hexagon_gap));
      //grid_size_height = 1;
      println("количество узлов сетки по вертикали: " + grid_size_height);

      // число элементов сетки должно быть чётным чтобы обесспечить сходимость при сопряжении двух краёв
      grid_size_width = -1;
       while(((grid_size_width%2) != 0)/*|(grid_size_width*grid_temp > 360)*/) {
             grid_temp = degrees(asin((magic_number*hexagon_size+hexagon_gap)/(2*R_cylinder)));
             grid_size_width = ceil(grid_angle/grid_temp);
             R_cylinder ++;
      }
        // затем подгоняем шов между первым и последним столбцом пайеток
        while(grid_size_width*grid_temp > 359) {
            grid_temp = degrees(asin((magic_number*hexagon_size+hexagon_gap)/(2*R_cylinder)));
            R_cylinder +=0.1;
        }
        
        while(grid_size_width*grid_temp < 359) {
           grid_temp = degrees(asin((magic_number*hexagon_size+hexagon_gap)/(2*R_cylinder)));
           R_cylinder -=0.1;
        }
      println("количество узлов сетки по горизонтали: " + grid_size_width);
      println("новый радиус основания цилиндра: " + R_cylinder);
      
       stroke(color(255,0,0));

       grid_vertices_counter = 0;
       // генерация сетки
       for(int i = 0; i<grid_size_height; i++) {
         for(int j = 0; j<grid_size_width; j++) {
           if((j%2)==0) grid_node_height = i*(hexagon_size+hexagon_gap) + (hexagon_size+hexagon_gap)/2; else grid_node_height = i*(hexagon_size+hexagon_gap);
           grid_node_width = j*grid_temp;
           
           grid_vertices[i][j][0] = R_cylinder*sin(radians(grid_node_width)); // заполняем массив
           grid_vertices[i][j][1] = R_cylinder*cos(radians(grid_node_width));
           grid_vertices[i][j][2] = cylinder_Z_min + grid_node_height;
           
           grid_vertices_counter ++;
         }
       }
        
        println("количество вершин сетки: " + grid_vertices_counter);
         grid_node_height = 0;
         grid_node_width = 0;
         grid_vertices_counter = 0;
         
         for(int k = 0; k<grid_size_height; k++) {
             for(int j = 0; j<grid_size_width; j++) {
               
               for(int i = 0; i<vertices_counter; i=i+3) {
                 // координаты вершин текущей фасеты
                 float line_temp [][] = new float [2][3];
                 float temp_matrix [][] = new float[3][3];
                 temp_matrix[0][0] = vertices[i][0];   temp_matrix[1][0] = vertices[i+1][0];   temp_matrix[2][0] = vertices[i+2][0];
                 temp_matrix[0][1] = vertices[i][1];   temp_matrix[1][1] = vertices[i+1][1];   temp_matrix[2][1] = vertices[i+2][1];
                 temp_matrix[0][2] = vertices[i][2];   temp_matrix[1][2] = vertices[i+1][2];   temp_matrix[2][2] = vertices[i+2][2];
         
                 // определяем линию
                 line_temp[0][0] = 0;                       line_temp[0][1] = 0;                        line_temp[0][2] = grid_vertices[k][j][2];
                 line_temp[1][0] = grid_vertices[k][j][0];  line_temp[1][1] = grid_vertices[k][j][1];   line_temp[1][2] = grid_vertices[k][j][2];
                 
                 
                 int temp;
                 float intersection_point [] = new float [3];
                 // вычисляем точку пересечения прямой и плоскости фасеты
                 intersection_point = plane_intersection_calculate(temp_matrix,line_temp);
                 if((intersection_point[0] != 0)|(intersection_point[1] != 0)|(intersection_point[2] != 0)) {
                   // расчёт принадлежности точки некоторой треугольной области производяится по методу площадей
                   temp = intersection_calculate(temp_matrix,intersection_point);
                 }
                 else temp = 0;
                 
                 if(temp == 1) {
                    // рисуем вектор нормали к фасете, проведённый из точки пересечния указателя и плоскости фасеты
                    float [] faset_n_vestor = new float [3];
                    faset_n_vestor = n_vector_calculate(temp_matrix); // отправляем координаты вершин фасеты, получаем координаты вектора нормали
                    
                    float [][] n_line_points = new float [2][3]; // координаты точек линии нормали
                    float n_line_lenght = 2;  // длинна вектора нормали
                    n_line_points[0][0] = intersection_point[0];                                      n_line_points[0][1] = intersection_point[1];                                      n_line_points[0][2] = intersection_point[2];  // первая точка - точка пересечения указателя и фасеты
                    n_line_points[1][0] = -faset_n_vestor[0]*n_line_lenght +  intersection_point[0];   n_line_points[1][1] = -faset_n_vestor[1]*n_line_lenght +  intersection_point[1];   n_line_points[1][2] = -faset_n_vestor[2]*n_line_lenght +  intersection_point[2];
                    //stroke(color(250,0,0));
                    //line(n_line_points[0][0], n_line_points[0][1], n_line_points[0][2],n_line_points[1][0], n_line_points[1][1], n_line_points[1][2]);
                    
                    // проверяем расстояние между текущей  точкой пересечения и предыдущей, чтобы выявить коллизии, если точка пересечения онарушивается на линии соприкосновения двух фасет с одинаковой площадью
                    // если расстояние меньше шага сетки, то это ошибка
                    float hexagon_points_lenght = 10;
                    float [][] hexagon_line = new float [2][3];
                    
                    if(hexagon_counter == 0) { hexagon_points_lenght = 10; } // первая пайетка не может ни с чем пересекаться
                    else {  
                      /*
                      hexagon_line[0][0] = hexagon_translate[hexagon_counter-1][0];    hexagon_line[0][1] = hexagon_translate[hexagon_counter-1][1];    hexagon_line[0][2] = hexagon_translate[hexagon_counter-1][2];
                      hexagon_line[1][0] = n_line_points[1][0];                        hexagon_line[1][1] = n_line_points[1][1];                        hexagon_line[1][2] = n_line_points[1][2];
                      hexagon_points_lenght = line_lenght(hexagon_line);
                      */
                    }
                      
                    if(hexagon_points_lenght > 2) { // если расстояние больше некоторого минимального значения, то ошибки быть не может
                       
                        hexagon_translate[k][j][0] = n_line_points[1][0];
                        hexagon_translate[k][j][1] = n_line_points[1][1];
                        hexagon_translate[k][j][2] = n_line_points[1][2];
                        
                        
                        // на кончике вектора нормали рисуем пайетку
                        // для этого находим угол, который образует вектор нормали с осями ГСК
                        // определяем векторы базиса ГСК
                        float [] OX_vector = new float [3];
                        OX_vector[0] = 10; OX_vector[1] = 0; OX_vector[2] = 0;
                        float [] OY_vector = new float [3];
                        OY_vector[0] = 0; OY_vector[1] = 10; OY_vector[2] = 0;
                        float [] OZ_vector = new float [3];
                        OZ_vector[0] = 0; OZ_vector[1] = 0; OZ_vector[2] = 10;
                        
                        // через скалярное произведение вектора нормали и базиса ГСК находим углы
                        float cos_OZ_n = (faset_n_vestor[0]*OX_vector[0] + faset_n_vestor[1]*OX_vector[1] + faset_n_vestor[2]*OX_vector[2])/(vector_lenght(OX_vector)*vector_lenght(faset_n_vestor));
                        float angle_OZ_n = acos(cos_OZ_n); // угол между вектором нормали и осью ОХ (в радианах)
                        float cos_OX_n = (faset_n_vestor[0]*OY_vector[0] + faset_n_vestor[1]*OY_vector[1] + faset_n_vestor[2]*OY_vector[2])/(vector_lenght(OY_vector)*vector_lenght(faset_n_vestor));
                        float angle_OX_n = acos(cos_OX_n);
                        float cos_OY_n = (faset_n_vestor[0]*OZ_vector[0] + faset_n_vestor[1]*OZ_vector[1] + faset_n_vestor[2]*OZ_vector[2])/(vector_lenght(OZ_vector)*vector_lenght(faset_n_vestor));
                        float angle_OY_n = acos(cos_OY_n); // угол между вектором нормали и осью ОZ (в радианах)
                        //println("OZ: " + cos_OZ_n +  " OX: " + cos_OX_n + " OY: " + cos_OY_n);
                        //println("OZ: " + degrees(angle_OZ_n) +  " OX: " + degrees(angle_OX_n) + " OY: " + degrees(angle_OY_n));
                        
                        // это позволяет бороться с краевым эффектами, наблюдающимися при приближении косинуса к максимальным и минимальным значениям
                        // суть метода в том, что в некотором диапазоне используется угол между вектором нормали и осью OX, а в другом диапазоне угол между вектором нормали и соью ОY
                        float angle;
                        if((cos_OZ_n > 0.7) | (cos_OZ_n < -0.7)) {
                          if(cos_OZ_n > 0) angle_OX_n = radians(90.0) - angle_OX_n;  
                          else angle_OX_n = radians(90.0) + angle_OX_n;  
                          angle = angle_OX_n;
                        }
                        else {
                          if(cos_OX_n < 0) angle_OZ_n = -angle_OZ_n;
                          angle = angle_OZ_n;
                        }
                        
                        hexagon_angle[k][j][0] = angle; 
                        hexagon_angle[k][j][1] = angle_OY_n; 
                        
                        hexagon_counter++;
                    }

                 }    
                
             }
             grid_vertices_counter ++; 
          }
     } 
     
     // находим расстояние оси модели до каждой пайетки, это будет определять масштабный коэффициент пайеток
     /*
     for(int i = 0; i<hexagon_counter; i++) { 
       float line_temp [][] = new float [2][3];
       line_temp[0][0] = 0;                        line_temp[0][1] = 0;                         line_temp[0][2] = hexagon_translate[i][2];
       line_temp[1][0] = hexagon_translate[i][0];  line_temp[1][1] = hexagon_translate[i][1];   line_temp[1][2] = hexagon_translate[i][2];
       
       hexagon_distance[i] = line_lenght(line_temp);
       println(hexagon_distance[i]);
       
     }
     */
         
         
      println("Количество пайеток: " + hexagon_counter);
      // заполняем начальные цвета пайеток
      for(int k = 0; k<grid_size_height; k++) {
             for(int j = 0; j<grid_size_width; j++) {
               hexagon_color[k][j] = color(255,255,255);
               //output_file.println("k: " + k + "; j: " + j);
               //output_file.println("(" + hexagon_translate[k][j][0] + " " + hexagon_translate[k][j][1] + " " + hexagon_translate[k][j][2] + ") ");   
               //delay(10);
             }
      }
      
      // расчитываем длину образующих по вертикали
      float summ = 0;
      int FLAG = 0;
      float line_temp [][] = new float [2][3];
       for(int j = 0; j<grid_size_width; j++) {
           output_file.println("Номер столбца: " + j);
             for(int k = 0; k<grid_size_height; k++) {
               if((hexagon_translate[k][j][0] != 0)|(hexagon_translate[k][j][1] != 0)|(hexagon_translate[k][j][2] != 0)) {
                 if(FLAG == 0) { line_temp[0][0] = hexagon_translate[k][j][0];  line_temp[0][1] = hexagon_translate[k][j][1];  line_temp[0][2] = hexagon_translate[k][j][2]; FLAG = 1; }
                 else {
                       line_temp[1][0] = hexagon_translate[k][j][0];  line_temp[1][1] = hexagon_translate[k][j][1];  line_temp[1][2] = hexagon_translate[k][j][2];  
                       output_file.println("Расстояние между пайетками: " + line_lenght(line_temp));
                       summ = summ + line_lenght(line_temp);
                       
                       //hexagon_scale[k][j][0]= line_lenght(line_temp)/(hexagon_size+hexagon_gap);
                       //print(line_lenght(line_temp) + "; ");
                       //println(hexagon_scale[k][j]);
                       
                       
                       line_temp[0][0] = line_temp[1][0];
                       line_temp[0][1] = line_temp[1][1];
                       line_temp[0][2] = line_temp[1][2];
                 }
               }
            
             }
           razvertka[0][j] = summ;
           //println(razvertka[0][j]);
           summ = 0;
           FLAG = 0;
      }
      
      FLAG = 0;
      summ = 0;
      int first_step_FLAG = 0;
      float point_temp [] = new float [3];
      for(int k = 0; k<grid_size_height; k++) { 
        //output_file.println("Номер столбца: " + k);
          for(int j = 0; j<grid_size_width; j++) {
              if(first_step_FLAG == 0) {  // если проходимся по этой строке первый раз
                  if((hexagon_translate[k][j][0] != 0)|(hexagon_translate[k][j][1] != 0)|(hexagon_translate[k][j][2] != 0)) { // встречаем ненулевую координату
                    line_temp[0][0] = hexagon_translate[k][j][0];  // эта координата будет началом линии
                    line_temp[0][1] = hexagon_translate[k][j][1];
                    line_temp[0][2] = hexagon_translate[k][j][2];
                    
                    point_temp[0] = line_temp[0][0];
                    point_temp[1] = line_temp[0][1];
                    point_temp[2] = line_temp[0][2];
                    
                    first_step_FLAG = j+1;

                  }
              }
              else { // продолжаем двигаться по строке
                if((hexagon_translate[k][j][0] != 0)|(hexagon_translate[k][j][1] != 0)|(hexagon_translate[k][j][2] != 0)) {
                  line_temp[1][0] = hexagon_translate[k][j][0];
                  line_temp[1][1] = hexagon_translate[k][j][1];
                  line_temp[1][2] = hexagon_translate[k][j][2];
                  
                  hexagon_scale[k][j][1]= line_lenght(line_temp)/(hexagon_size+hexagon_gap);
                  //output_file.println("Размер пайетки: " + 1.05*hexagon_scale[k][j][1]*100); 

                  line_temp[0][0] = line_temp[1][0];
                  line_temp[0][1] = line_temp[1][1];
                  line_temp[0][2] = line_temp[1][2];
                  
                }
                
                else {
                  first_step_FLAG = 0;
                }
                
              }
            //}// 
          }
          if((first_step_FLAG < 3)&(first_step_FLAG != 0)) {
            line_temp[1][0] = point_temp[0];
            line_temp[0][1] = point_temp[1];
            line_temp[0][2] = point_temp[2];
            
            hexagon_scale[k][0][1]= line_lenght(line_temp)/(hexagon_size+hexagon_gap);
            //output_file.println("Размер пайетки: " + 1.05*hexagon_scale[k][0][1]*100); 

          }
          
          first_step_FLAG = 0; 

      }
      
     
       for(int j = 0; j<grid_size_width; j++) {
       output_file.println("Номер столбца: " + j);
         for(int i = 0; i<grid_size_height; i++) {
                if((hexagon_translate[i][j][0] != 0) | (hexagon_translate[i][j][1] != 0) | (hexagon_translate[i][j][2] != 0)) {
                    if(hexagon_scale[i][j][1] == 0) hexagon_scale[i][j][1] = 0.9;
                    if(hexagon_scale[i][j][1] > 1.1) hexagon_scale[i][j][1] = 1.1;
                    output_file.println("Размер пайетки: " + hexagon_scale[i][j][1]*1.0*(hexagon_size)); 
                    
                }
                 
             }
      }
      
      output_file.flush(); // Writes the remaining data to the file
      output_file.close(); // Finishes the file
       
      // начальное положение пространства
      camX=width/2;
      camY=height/2+100;
      camZ = 390;
      rotX=radians(80);
      rotY=radians(90);
      rotZ = 0;
}
 
void draw() { 
     delay(20);
     background(0);

     // сначала поворачиваем пространство
     translate(camX, camY, camZ);
     rotateX(rotX);
     //if(rotZ < 360) rotZ=rotZ+2; else rotZ = 0;
     //rotateZ(radians(rotZ));
     rotateZ((rotZ));
     
     // по команде меняем цвет
     if((color_cahnge_FLAG == 1)|(color_cahnge_FLAG == 2)) {
        if(hexagon_color_counter <grid_size_height) {
             for(int j = 0; j<grid_size_width; j++) {
               if(color_cahnge_FLAG == 2) {
                 hexagon_color_state = 1;
                 hexagon_color[hexagon_color_counter][j] = color(255,255,255);
               }
               else {
                 hexagon_color_state = 2;
                 hexagon_color[hexagon_color_counter][j] = color(0,0,0);
               }
             }
             
             hexagon_color_counter ++;
             //delay(20);
        }
        else {
        hexagon_color_counter = 0;
        color_cahnge_FLAG = 0;
        println("OK");
        }
     }
     ///int vertices_counter_temp = 0;
     ///int vertices_FLAG = 0;
     ///vertices_counter
     
         // отрисовываем фасеты модели
 
         for(int i = 0; i<vertices_counter; i=i+3) {
     
            // отрисовываем текущую фасету
            stroke(255);
            fill(130);
            beginShape(); 
            vertex(vertices[i][0],vertices[i][1],vertices[i][2]);
            vertex(vertices[i+1][0],vertices[i+1][1],vertices[i+1][2]);
            vertex(vertices[i+2][0],vertices[i+2][1],vertices[i+2][2]);
            endShape(CLOSE);
        
            faset_counter++;
           }
   
     
     // диаметры оснований цилиндров
      noFill();
      stroke(color(255,0,0));
      if(image_mode == 2) circle(0, 0, R_cylinder*2);
    
     // отрисовываем расчитанную сетку
     grid_node_height = 0;
     grid_node_width = 0;
     grid_vertices_counter = 0;
     for(int i = 0; i<grid_size_height; i++) {
         for(int j = 0; j<grid_size_width; j++) {
             
             pushMatrix();
             stroke(color(255,0,0));
             translate(grid_vertices[i][j][0],grid_vertices[i][j][1],grid_vertices[i][j][2]);
             //point(0,0,0);
             sphereDetail(5);
             if((image_mode == 3)|(image_mode == 4)) sphere(1);
             popMatrix();
             
             stroke(#F011AD); // сиреневый цвет
             // для наглядности проводим линию
             if(image_mode == 4) line(0,0,grid_vertices[i][j][2],grid_vertices[i][j][0],grid_vertices[i][j][1],grid_vertices[i][j][2]);
             grid_vertices_counter ++;
         }
     }
  
      // для отладки будем производить эту операцию в цикле
      // расчитываем длину образующих по вертикали
      float summ = 0;
      int FLAG = 0;
      float line_temp [][] = new float [2][3];
       for(int j = 0; j<grid_size_width; j++) {
             for(int k = 0; k<grid_size_height; k++) {
               if((hexagon_translate[k][j][0] != 0)|(hexagon_translate[k][j][1] != 0)|(hexagon_translate[k][j][2] != 0)) {
                 if(FLAG == 0) { line_temp[0][0] = hexagon_translate[k][j][0];  line_temp[0][1] = hexagon_translate[k][j][1];  line_temp[0][2] = hexagon_translate[k][j][2]; FLAG = 1; }
                 else {
                       line_temp[1][0] = hexagon_translate[k][j][0];  line_temp[1][1] = hexagon_translate[k][j][1];  line_temp[1][2] = hexagon_translate[k][j][2];  
                       summ = summ + line_lenght(line_temp);
                       
                       // отрисовываем получившиеся линии
                       pushMatrix();
                       
                       if(j!=0) stroke(color(0,255,0)); else stroke(color(0,255,255));
                       strokeWeight(3);
                       line(line_temp[0][0],line_temp[0][1],line_temp[0][2],line_temp[1][0],line_temp[1][1],line_temp[1][2]);
                       stroke(color(255,0,0));
                       
                           pushMatrix();
                           translate(line_temp[0][0],line_temp[0][1],line_temp[0][2]);
                           sphereDetail(5);
                            sphere(1);
                           popMatrix();
                           
                           pushMatrix();
                           translate(line_temp[1][0],line_temp[1][1],line_temp[1][2]);
                           sphereDetail(5);
                             sphere(1);
                           popMatrix();
                       
                       strokeWeight(1);
                       popMatrix();
                       
                       line_temp[0][0] = line_temp[1][0];
                       line_temp[0][1] = line_temp[1][1];
                       line_temp[0][2] = line_temp[1][2];
                  }
               }
            }
           razvertka[0][j] = summ;
           summ = 0;
           FLAG = 0;
      }
      
      // расчитываем длину образующих по горизонтали
      //strokeWeight(3);
      FLAG = 0;
      summ = 0;
      int first_step_FLAG = 0;
      float point_temp [] = new float [3];
      for(int k = 0; k<grid_size_height; k++) { 
          for(int j = 0; j<grid_size_width; j++) {
            //if(j%2 !=0 ) {
              if(first_step_FLAG == 0) {  // если проходимся по этой строке первый раз
                  if((hexagon_translate[k][j][0] != 0)|(hexagon_translate[k][j][1] != 0)|(hexagon_translate[k][j][2] != 0)) { // встречаем ненулевую координату
                    line_temp[0][0] = hexagon_translate[k][j][0];  // эта координата будет началом линии
                    line_temp[0][1] = hexagon_translate[k][j][1];
                    line_temp[0][2] = hexagon_translate[k][j][2];
                    
                    point_temp[0] = line_temp[0][0];
                    point_temp[1] = line_temp[0][1];
                    point_temp[2] = line_temp[0][2];
                    
                    first_step_FLAG = j+1;
                    
                    pushMatrix();
                      translate(hexagon_translate[k][j][0],hexagon_translate[k][j][1],hexagon_translate[k][j][2]);
                      stroke(color(255,0,0));
                      //sphere(1);
                    popMatrix(); 
                  }
              }
              else { // продолжаем двигаться по строке
                if((hexagon_translate[k][j][0] != 0)|(hexagon_translate[k][j][1] != 0)|(hexagon_translate[k][j][2] != 0)) {
                  line_temp[1][0] = hexagon_translate[k][j][0];
                  line_temp[1][1] = hexagon_translate[k][j][1];
                  line_temp[1][2] = hexagon_translate[k][j][2];
                  
                  hexagon_scale[k][j][1]= line_lenght(line_temp)/(hexagon_size+hexagon_gap);
                  
                  pushMatrix();
                    translate(hexagon_translate[k][j][0],hexagon_translate[k][j][1],hexagon_translate[k][j][2]);
                    stroke(color(255,0,0));
                   // sphere(1);
                  popMatrix(); 
                       
                  stroke(color(0,255,255));
                  strokeWeight(3);
                    line(line_temp[0][0],line_temp[0][1],line_temp[0][2],line_temp[1][0],line_temp[1][1],line_temp[1][2]);
                  strokeWeight(1);
                  
                  line_temp[0][0] = line_temp[1][0];
                  line_temp[0][1] = line_temp[1][1];
                  line_temp[0][2] = line_temp[1][2];
                  
                }
                
                else {
                  first_step_FLAG = 0;
                }
                
              }
            //}// 
          }
          if((first_step_FLAG < 3)&(first_step_FLAG != 0)) {
            line_temp[1][0] = point_temp[0];
            line_temp[0][1] = point_temp[1];
            line_temp[0][2] = point_temp[2];
            
            hexagon_scale[k][0][1]= line_lenght(line_temp)/(hexagon_size+hexagon_gap);
            //if((hexagon_translate[k][0][0] != 0)|(hexagon_translate[k][0][1] != 0)|(hexagon_translate[k][0][2] != 0)) {
            stroke(color(0,255,255));
            strokeWeight(3);
            //line(line_temp[0][0],line_temp[0][1],line_temp[0][2],hexagon_translate[k][0][0],hexagon_translate[k][0][1],hexagon_translate[k][0][2]);
               line(line_temp[0][0],line_temp[0][1],line_temp[0][2],point_temp[0],point_temp[1],point_temp[2]);
            strokeWeight(1);
            //}
          }
          
          first_step_FLAG = 0; 
          /*
           if((hexagon_translate[k][0][0] != 0)|(hexagon_translate[k][0][1] != 0)|(hexagon_translate[k][0][2] != 0)) {
          line_temp[1][0] = hexagon_translate[k][0][0];
          line_temp[1][1] = hexagon_translate[k][0][1];
          line_temp[1][2] = hexagon_translate[k][0][2];
          
          stroke(color(0,255,255));
          strokeWeight(3);
          line(line_temp[0][0],line_temp[0][1],line_temp[0][2],line_temp[1][0],line_temp[1][1],line_temp[1][2]);
          strokeWeight(1);
           }
           */
      }
      
     // отрисовываем пайетки
     for(int i = 0; i<grid_size_height; i++) {
         for(int j = 0; j<grid_size_width; j++) {
        // перемещаем и поворачиваем ЛСК
        if((hexagon_translate[i][j][0] != 0) | (hexagon_translate[i][j][1] != 0) | (hexagon_translate[i][j][2] != 0)) {
          pushMatrix();
             translate(hexagon_translate[i][j][0], hexagon_translate[i][j][1], hexagon_translate[i][j][2]);             
             rotateZ(hexagon_angle[i][j][0]);
             rotateY(PI+hexagon_angle[i][j][1]);
             
             
             pushMatrix();
             //translate(0,0,100);
             stroke(color(255,0,0));
             sphereDetail(5);
             if(image_mode == 8) sphere(1);
             popMatrix();
             
             // отрисовываем пайетку  
             pushMatrix();
             rotateZ(radians(90.0));
             stroke(color(255,0,0));

             //fill(hexagon_color[i]);
             //if(hexagon_scale[i][j][1]<1) hexagon_scale[i][j][1] = 0.5;
             //else hexagon_scale[i][j][1] = 1.0;
             if(hexagon_scale[i][j][1] == 0) hexagon_scale[i][j][1] = 0.9;
             if(hexagon_scale[i][j][1] > 1.1) hexagon_scale[i][j][1] = 1.1;
             /*if((image_mode == 8) | (image_mode ==9))*/ print_hexagon(0,0,hexagon_scale[i][j][1]*1.00,hexagon_color[i][j]);
             
             //translate(0,0,0.1);
             //fill(color(0,255,0));
             //circle(0,0,10);
             popMatrix();
             
          popMatrix();
        }
       }
       /*
       pushMatrix();
       translate(0, 0, hexagon_translate[i][0][2]);
       fill(color(0,255,0),100);
       stroke(color(0,255,0));
       circle(0,0,razvertka[0][i]/(PI));
       popMatrix();
       */
     }
      
    
     
     // вспомогательная геометрия
     // ось Z
     stroke(color(255,0,0));
     line(0,0,0,0,0,100);
     // ось Х
     stroke(color(0,255,0));
     line(0,0,0,100,0,0);
     // ось Y
     stroke(color(0,0,255));
     line(0,0,0,0,100,0);
     //начало отсчёта
     stroke(255);
    
}
 
// возвращает длину отрезка, заданного двумя точками    
float line_lenght (float line_loc [][]) {
  float line_lenght = 0;
  float [][] vectors_loc = new float [2][3];
  vectors_loc[0][0] = line_loc[0][0] - line_loc[1][0];
  vectors_loc[0][1] = line_loc[0][1] - line_loc[1][1];
  vectors_loc[0][2] = line_loc[0][2] - line_loc[1][2];
  line_lenght = sqrt(vectors_loc[0][0]*vectors_loc[0][0] + vectors_loc[0][1]*vectors_loc[0][1] + vectors_loc[0][2]*vectors_loc[0][2]);
  return line_lenght;
}

// возвращает длину вектора
float vector_lenght (float vector_loc []) {
  float vector_lenght = 0;
  vector_lenght = sqrt(vector_loc[0]*vector_loc[0] + vector_loc[1]*vector_loc[1] + vector_loc[2]*vector_loc[2]);
  return vector_lenght;
}
    
float triangle_square_calculate (float x1, float y1, float z1, float x2, float y2, float z2, float x3, float y3, float z3) {
  float [][] vectors_loc = new float [3][3];
  float [] vectors_lenght_loc = new float [3];
  
  vectors_loc[0][0] = x1 - x2;
  vectors_loc[0][1] = y1 - y2;
  vectors_loc[0][2] = z1 - z2;
  vectors_lenght_loc[0] = sqrt(vectors_loc[0][0]*vectors_loc[0][0] + vectors_loc[0][1]*vectors_loc[0][1] + vectors_loc[0][2]*vectors_loc[0][2]);
  
  //stroke(color(0,0,255));
  //line(x1,y1,z1,x2,y2,z2);
    
  vectors_loc[1][0] = x1 - x3;
  vectors_loc[1][1] = y1 - y3;
  vectors_loc[1][2] = z1 - z3;
  vectors_lenght_loc[1] = sqrt(vectors_loc[1][0]*vectors_loc[1][0] + vectors_loc[1][1]*vectors_loc[1][1] + vectors_loc[1][2]*vectors_loc[1][2]);
  
  //stroke(color(0,0,255));
  //line(x1,y1,z1,x3,y3,z3);
    
  vectors_loc[2][0] = x2 - x3;
  vectors_loc[2][1] = y2 - y3;
  vectors_loc[2][2] = z2 - z3;
  vectors_lenght_loc[2] = sqrt(vectors_loc[2][0]*vectors_loc[2][0] + vectors_loc[2][1]*vectors_loc[2][1] + vectors_loc[2][2]*vectors_loc[2][2]);
  
  //stroke(color(0,0,255));
  //line(x2,y2,z2,x3,y3,z3);
    
  float perimetr = (vectors_lenght_loc[0] + vectors_lenght_loc[1] + vectors_lenght_loc[2])/2;
  return sqrt(perimetr*(perimetr-vectors_lenght_loc[0])*(perimetr-vectors_lenght_loc[1])*(perimetr-vectors_lenght_loc[2]));
}

// в качестве аргумента принимает массив с координатами трёх точек, определяющи исследуемую оласть плоскости, в качестве второго аргумента - массив, с координатами
// возвращает 1, если точка находится в внутри области, возвращает 0, если точка находится снаружи области
int  intersection_calculate (float plane_vertex [][], float point []) {
    float S,S1,S2,S3,S_summ;
    // считаем площадь базового треугольника
    S = triangle_square_calculate(plane_vertex[0][0],plane_vertex[0][1],plane_vertex[0][2],plane_vertex[1][0],plane_vertex[1][1],plane_vertex[1][2],plane_vertex[2][0],plane_vertex[2][1],plane_vertex[2][2]);
      
    // считаем площади производных треугольников  
    S1 = triangle_square_calculate(plane_vertex[0][0],plane_vertex[0][1],plane_vertex[0][2],plane_vertex[1][0],plane_vertex[1][1],plane_vertex[1][2],point[0],point[1],point[2]);
    if(S1 < S) {  // для скорости снача считаем только одну площадь и если она уже больше исходной, то остальные и проверять не нужно
      S2 = triangle_square_calculate(plane_vertex[0][0],plane_vertex[0][1],plane_vertex[0][2],point[0],point[1],point[2],plane_vertex[2][0],plane_vertex[2][1],plane_vertex[2][2]);
      S3 = triangle_square_calculate(point[0],point[1],point[2],plane_vertex[1][0],plane_vertex[1][1],plane_vertex[1][2],plane_vertex[2][0],plane_vertex[2][1],plane_vertex[2][2]);
      S_summ = S1+S2+S3; 
      
      // определяем принадлежность точки этому треугольнику
      if((S_summ-1) > S)  return 0;
      else  return 1;
    }
    else return 0; 
}

// функция возвращает вектор нормали к плоскости, заданной тремя вершинами
float[] n_vector_calculate (float plane_loc[][]) {
  float [] plane_n_vector = new float [3];
  float temp_matrix_loc [][] = new float[3][3];
  float plane_n_vector_lenght = 0;
  
  // каноническое уравнение плоскости
  temp_matrix_loc[0][0] = 1;                                   temp_matrix_loc[0][1] = 1;                                   temp_matrix_loc[0][2] = 1;
  temp_matrix_loc[1][0] = plane_loc[1][0] - plane_loc[0][0];   temp_matrix_loc[1][1] = plane_loc[1][1] - plane_loc[0][1];   temp_matrix_loc[1][2] = plane_loc[1][2] - plane_loc[0][2];
  temp_matrix_loc[2][0] = plane_loc[2][0] - plane_loc[0][0];   temp_matrix_loc[2][1] = plane_loc[2][1] - plane_loc[0][1];   temp_matrix_loc[2][2] = plane_loc[2][2] - plane_loc[0][2];
      
  // вектор нормали к плоскости
  plane_n_vector[0] = temp_matrix_loc[1][1]*temp_matrix_loc[2][2] - temp_matrix_loc[2][1]*temp_matrix_loc[1][2];
  plane_n_vector[1] = temp_matrix_loc[2][0]*temp_matrix_loc[1][2] - temp_matrix_loc[1][0]*temp_matrix_loc[2][2];
  plane_n_vector[2] = temp_matrix_loc[1][0]*temp_matrix_loc[2][1] - temp_matrix_loc[2][0]*temp_matrix_loc[1][1];
  
  // нормируем вектор по длине
  plane_n_vector_lenght = sqrt(plane_n_vector[0]*plane_n_vector[0] + plane_n_vector[1]*plane_n_vector[1] + plane_n_vector[2]*plane_n_vector[2]);
  plane_n_vector[0] = plane_n_vector[0]/plane_n_vector_lenght;
  plane_n_vector[1] = plane_n_vector[1]/plane_n_vector_lenght;
  plane_n_vector[2] = plane_n_vector[2]/plane_n_vector_lenght;
  
  return plane_n_vector;
}

// функция определяет пересекает ли прямая область плоскости, огранченную треугольником
// возвращает координаты точки пересечения прямой и плоскости
// если прямая не пересекает плоскость, то возвращается массив со значениями 0
// первый аргумент функции - массив с тремя вершинами, определяющими плоскость plane
// второй аргумент функции - массив с двумя вершинами прямой line, пересекающей плоскость plane
float[] plane_intersection_calculate (float plane_loc[][], float line_loc[][]) {
  int validate_flag = 0;
  float[] intersection_point_loc = new float [3];
  float temp_matrix_loc [][] = new float[3][3];
  float [] plane_n_vector = new float [3];
   
  // проверяем пересечение плоскости и фасеты по двум критериям
  // 1. Первый критерий: координата Z прямой находится между наибольшей и наименьшей координатой Z выбранной плоскости
  // определяем наибольшую и наименьшую координату Z для фасеты
  float Z_max_loc = 0, Z_min_loc = 0;
  if(plane_loc[0][2] > plane_loc[1][2]) { 
    Z_max_loc = plane_loc[0][2];
    Z_min_loc = plane_loc[1][2];
  }  
  else {
    Z_max_loc = plane_loc[1][2];
    Z_min_loc = plane_loc[0][2];
  }
  if(plane_loc[2][2] > Z_max_loc) Z_max_loc = plane_loc[2][2];
  if(plane_loc[2][2] < Z_min_loc) Z_min_loc = plane_loc[2][2];
  
  // это позволяет определять наиболее вероятные фасеты с которыми указатель имеет пересечение
  if((line_loc[0][2] < Z_max_loc) & (line_loc[0][2] > Z_min_loc)) validate_flag = 1;
  else validate_flag = 0;
  
  if(validate_flag == 1) {
    // 2. Второй критерий: вектор нормали к плоскости и направляющий вектор пярмой, пересекающей плоскость дожны смотреть в одном направлении (скалярное произведение больше нуля)
    // направляющий вектор пямой, пересекающей плоскость
    float faset_intersection_vector_loc [] = new float [3];    
    faset_intersection_vector_loc[0] = line_loc[1][0] - line_loc[0][0];
    faset_intersection_vector_loc[1] = line_loc[1][1] - line_loc[0][1];
    faset_intersection_vector_loc[2] = line_loc[1][2] - line_loc[0][2];
    
    // каноническое уравнение плоскости
    temp_matrix_loc[0][0] = 1;                                   temp_matrix_loc[0][1] = 1;                                   temp_matrix_loc[0][2] = 1;
    temp_matrix_loc[1][0] = plane_loc[1][0] - plane_loc[0][0];   temp_matrix_loc[1][1] = plane_loc[1][1] - plane_loc[0][1];   temp_matrix_loc[1][2] = plane_loc[1][2] - plane_loc[0][2];
    temp_matrix_loc[2][0] = plane_loc[2][0] - plane_loc[0][0];   temp_matrix_loc[2][1] = plane_loc[2][1] - plane_loc[0][1];   temp_matrix_loc[2][2] = plane_loc[2][2] - plane_loc[0][2];
      
    // вектор нормали к плоскости
    plane_n_vector[0] = temp_matrix_loc[1][1]*temp_matrix_loc[2][2] - temp_matrix_loc[2][1]*temp_matrix_loc[1][2];
    plane_n_vector[1] = temp_matrix_loc[2][0]*temp_matrix_loc[1][2] - temp_matrix_loc[1][0]*temp_matrix_loc[2][2];
    plane_n_vector[2] = temp_matrix_loc[1][0]*temp_matrix_loc[2][1] - temp_matrix_loc[2][0]*temp_matrix_loc[1][1];
    
    float plane_n_vector_lenght = 0;
    // нормируем вектор по длине
    plane_n_vector_lenght = sqrt(plane_n_vector[0]*plane_n_vector[0] + plane_n_vector[1]*plane_n_vector[1] + plane_n_vector[2]*plane_n_vector[2]);
    plane_n_vector[0] = plane_n_vector[0]/plane_n_vector_lenght;
    plane_n_vector[1] = plane_n_vector[1]/plane_n_vector_lenght;
    plane_n_vector[2] = plane_n_vector[2]/plane_n_vector_lenght;
  
    float cos = plane_n_vector[0]*faset_intersection_vector_loc[0] + plane_n_vector[1]*faset_intersection_vector_loc[1] + plane_n_vector[2]*faset_intersection_vector_loc[2];
    float denominator = sqrt(faset_intersection_vector_loc[0]*faset_intersection_vector_loc[0] + faset_intersection_vector_loc[1]*faset_intersection_vector_loc[1] + faset_intersection_vector_loc[2]*faset_intersection_vector_loc[2])*sqrt(plane_n_vector[0]*plane_n_vector[0] + plane_n_vector[1]*plane_n_vector[1] + plane_n_vector[2]*plane_n_vector[2]);
    if(denominator != 0) cos = cos/denominator;
    else cos = -1;
    
    if(cos <= 0) validate_flag = 0;     // если скалярное произведение равно нулю, значит прямая не пересекает плоскость
    else if(cos > 0.5) validate_flag = 2;  // если скалярное произведение больше нуля, то продолжаем вычисления
  }
  
  if(validate_flag == 2) {
            
    // параметр t, математические преобразования за кадром
    float t2 = (plane_n_vector[0]*(line_loc[1][0] - line_loc[0][0]) + plane_n_vector[1]*(line_loc[1][1] - line_loc[0][1]) + plane_n_vector[2]*(line_loc[1][2] - line_loc[0][2]));  // знаменатель
    float t1 = (plane_n_vector[0]*(plane_loc[0][0] - line_loc[0][0]) + plane_n_vector[1]*(plane_loc[0][1] - line_loc[0][1]) + plane_n_vector[2]*(plane_loc[0][2] - line_loc[0][2]));  // числитель
    if(t1 != 0) { 
      t1 = t1/t2;
      // подставляем параметр в уравнения прямой и находим координаты точки
      intersection_point_loc[0] = (line_loc[1][0] - line_loc[0][0])*t1 + line_loc[0][0];
      intersection_point_loc[1] = (line_loc[1][1] - line_loc[0][1])*t1 + line_loc[0][1];
      intersection_point_loc[2] = (line_loc[1][2] - line_loc[0][2])*t1 + line_loc[0][2];
    }
    else {
      intersection_point_loc[0] = 0;
      intersection_point_loc[1] = 0;
      intersection_point_loc[2] = 0;      
    }  
  }
  
  else {
      intersection_point_loc[0] = 0;
      intersection_point_loc[1] = 0;
      intersection_point_loc[2] = 0;
  }
  return intersection_point_loc;
}

void print_hexagon (int offset_X, int offset_Y, float size_loc, color sequinc_color) {
   float size_factor = hexagon_size/100;   // нормирование шестиугольника по размеру (радиус вписанной окружности 10)
    fill(#292626);
    beginShape(); // рисуем шестиугольник
    vertex(offset_X+28.9*size_factor*size_loc, offset_Y+50*size_factor*size_loc);
    vertex(offset_X+57.7*size_factor*size_loc, offset_Y);
    vertex(offset_X+28.9*size_factor*size_loc, offset_Y-50*size_factor*size_loc);
    vertex(offset_X-28.9*size_factor*size_loc, offset_Y-50*size_factor*size_loc);
    vertex(offset_X-57.7*size_factor*size_loc, offset_Y);
    vertex(offset_X-28.9*size_factor*size_loc, offset_Y+50*size_factor*size_loc);
    vertex(offset_X+28.9*size_factor*size_loc, offset_Y+50*size_factor*size_loc);
    endShape();
    
     // цвет будет менять только внутренний круг
    noStroke();
    translate(0,0,0.1);
    fill(sequinc_color);
    circle(0,0,90*size_factor*size_loc); // диаметр его будет чуть меньше радиуса вписанной окружности пайетки
}

/*
void print_hexagon (int offset_X, int offset_Y, float size_factor, color sequinc_color) {
  
  // рама пайетки будет всегда чёрного цвета
  fill(color(0,0,0));
  beginShape(); // рисуем шестиугольник
  vertex(offset_X+17*size_factor, offset_Y+30*size_factor);
  vertex(offset_X+35*size_factor, offset_Y);
  vertex(offset_X+17*size_factor, offset_Y-30*size_factor);
  vertex(offset_X-17*size_factor, offset_Y-30*size_factor);
  vertex(offset_X-35*size_factor, offset_Y);
  vertex(offset_X-17*size_factor, offset_Y+30*size_factor);
  vertex(offset_X+17*size_factor, offset_Y+30*size_factor);
  endShape();
   
  // цвет будет менять только внутренний круг
  translate(0,0,0.1);
  fill(sequinc_color);
  circle(0,0,55*size_factor); // диаметр его будет чуть меньше радиуса вписанной окружности пайетки
}
*/

void keyPressed() { // обработка нажатия клавиши
  keyboard_key_code = keyCode;
  //for(int i = 0; i<hexagon_counter; i++) hexagon_color[i] = color(0,0,0);
  if(keyboard_key_code == 32) { // пробел
    if(color_cahnge_FLAG == 0) {
      if(hexagon_color_state == 1) color_cahnge_FLAG = 1;
      else color_cahnge_FLAG = 2;
    }
  }
  
  if(keyboard_key_code == 90) { // Z
    if(image_mode <10) image_mode++;
    else image_mode = 0;
  }
  println(keyboard_key_code);
}

void keyReleased() { // обработка отпукания клавиши
   keyboard_key_code = 0;
   //for(int i = 0; i<hexagon_counter; i++) hexagon_color[i] = color(255,255,255);
}

void mouseWheel(MouseEvent event) {
  float e = event.getCount();
  camZ+=e*5;
  //println(camZ);
}
 
void mouseDragged()
{
  if (mouseButton == LEFT)
  {
    rotZ += (pmouseX - mouseX)*0.01;
    rotX += (pmouseY - mouseY)*0.01;
  }
  if (mouseButton == RIGHT)
  {
    camX -= (pmouseX - mouseX);
    camY -= (pmouseY - mouseY);
  }
  if (mouseButton == CENTER)
  {
    pointX_counter = pointX_counter + (pmouseX - mouseX);
    pointZ_counter = pointZ_counter + (pmouseY - mouseY);
   
    //camZ += (pmouseY - mouseY);
  }
}
