import processing.serial.*; // библиотека для работы с последовательным портом
Serial Hed_scale_controller; // создаем объект последовательного порта

PImage img_original; // оригинальное изображение
PImage img_fragment; // выделяемый фрагмент для обработки

int img_height;
int img_width;

long pixels_value;
color [][] pixels_matrix = new color[10000][10000];
int pixels_matrix_width = 0;
int pixels_matrix_height = 0;

// размеры и смещение основного изображения
float img_scale_coeff = 1.0;
int bias_height = 0;
int bias_width = 0;

float window_scale_coeff = 1.3;

float size_factor;
int vertical_indent = 61; // отступ между центрами чешуек по вертикали
int horizontal_vertical = 53; // отступ между центрами чешуек по горизонтали
int quantity_of_scale;
int quantity_of_scale_temp = 0;
int[][] coordinates_of_scale = new int[100][100]; // координаты чешуек [X][Y]
int [] scale_validate = new int[100];

color [] main_tone_color = new color [100];
color [] scale_color = new color [100];

color background_color = 0;

char[] UART_data_transmit = new char[30]; // массив символов, передаваемых на контроллер управления "живыми" чешуйками
int time_counter = 0;

//char[] UART_data_resive = new char[30];
String UART_data_resive;

void setup() {
  String Hed_scale_controller_port = "COM6";
  Hed_scale_controller = new Serial(this,Hed_scale_controller_port,9600); // настраиваем последовательный порт
  Hed_scale_controller.bufferUntil('\n');
  
  for(int i=0; i<30; i++) UART_data_transmit[i] = '0';
  
  size(800,800);
  //fullScreen();
  img_original = loadImage("kora.jpg");
  //img_original.filter(GRAY);
  img_original.loadPixels();
  img_height = img_original.height;
  img_width = img_original.width;
  println("Ширина: " + img_width + ", Высота: " + img_height);
  bias_width = 0; //img_width/2;
  bias_height = 0; //img_height/2;
  
  pixels_matrix_width = 0;
  pixels_matrix_height = 0;
  
  img_scale_coeff = 800/img_width;
  /*
  pixels_value = img_height*img_width;
  for(int i = 0; i<pixels_value; i=i+img_width) {
    for(int j=0; j<img_width; j++) {
      float red =   red(img_original.pixels[i+j]);
      float green = green(img_original.pixels[i+j]);
      float blue =  blue(img_original.pixels[i+j]);
      
      pixels_matrix[pixels_matrix_width][pixels_matrix_height] = color(red,green,blue);
      pixels_matrix_width++;
      
      println(pixels_matrix_height + " " + pixels_matrix_width);
      println(hex(img_original.pixels[i+j]) + "  ");
    }
    pixels_matrix_height++;
    pixels_matrix_width = 0;
  }
  */
}

void draw() {
  background(background_color);
  //image_print();
  image(img_original,bias_width,bias_height,800,600);
  
  noStroke();
  fill(background_color);
  rectMode(CORNER);
  rect(0,430,800,800);
  
  get_fragment(mouseX,mouseY,60);
  print_fragment(10,500,230,275);
  
  calculate_matrix(0,540,5,4,window_scale_coeff);
  //println(mouseX + " " + mouseY);
    
  for(int i=0; i<100; i++) scale_validate[i] = 0;
  scale_validate[4] = 1;
  scale_validate[5] = 1;
  scale_validate[6] = 1;
  scale_validate[9] = 1;
  scale_validate[10] = 1;
  scale_validate[11] = 1;
  scale_validate[12] = 1;
  scale_validate[13] = 1;
  scale_validate[14] = 1;
  
  fragment_analysis();
  
  for(int drawing_scale_now=0; drawing_scale_now<quantity_of_scale; drawing_scale_now++) {
      if(scale_validate[drawing_scale_now] == 1) {
        noStroke();
        noFill();
      }
      else {
        stroke(background_color);
        fill(background_color);
      }
      print_hexagon(coordinates_of_scale[drawing_scale_now][0],coordinates_of_scale[drawing_scale_now][1],window_scale_coeff,0,0,color(255,0,0)); // отрисовываем чешуйки нужного цвета
 
  }
  
  for(int i=0; i<100; i++) scale_validate[i] = 0;
  scale_validate[0] = 1;
  scale_validate[1] = 1;
  scale_validate[2] = 1;
  scale_validate[3] = 1;
  scale_validate[4] = 1;
  scale_validate[5] = 1;
  scale_validate[6] = 1;
  scale_validate[7] = 1;
  scale_validate[8] = 1;
  
  // новую матрицу считаем чуть правее
  calculate_matrix(340,580,3,3,window_scale_coeff);
  for(int drawing_scale_now=0; drawing_scale_now<quantity_of_scale; drawing_scale_now++) {
      if(scale_validate[drawing_scale_now] == 1) {
        stroke(255);
        fill(main_tone_color[drawing_scale_now]);
      }
      else {
        stroke(background_color);
        fill(background_color);
      }
      print_hexagon(coordinates_of_scale[drawing_scale_now][0],coordinates_of_scale[drawing_scale_now][1],window_scale_coeff,0,0,color(255,0,0)); // отрисовываем чешуйки нужного цвета
 
  }
  
  // а последнюю матрицу совсем в правой стороне 
  calculate_matrix(610,580,3,3,window_scale_coeff);
  for(int drawing_scale_now=0; drawing_scale_now<quantity_of_scale; drawing_scale_now++) {
      if(scale_validate[drawing_scale_now] == 1) {
        stroke(255);
        fill(scale_color[drawing_scale_now]);
        
      }
      else {
        stroke(background_color);
        fill(background_color);
        //UART_data_transmit[drawing_scale_now] = '0';
      }
      noStroke();
      circle(coordinates_of_scale[drawing_scale_now][0],coordinates_of_scale[drawing_scale_now][1],int(60*window_scale_coeff));
      stroke(255);
      noFill();
      print_hexagon(coordinates_of_scale[drawing_scale_now][0],coordinates_of_scale[drawing_scale_now][1],window_scale_coeff,0,0,color(255,0,0)); // отрисовываем чешуйки нужного цвета
 
  }
  
  // последние штрихи
  textSize(30);
  fill(255);
  text("fragment",60,480);
  text("main tone",320,480);
  text("scale color",580,480);
  print_window(1);
  
  if(time_counter>10) {
    // отправляем данные в контроллер
      Hed_scale_controller.write('S');
    for(int i=0; i<16; i++) {
      Hed_scale_controller.write(UART_data_transmit[i]); 
    }
    time_counter = 0;
    //print("send");
  }
  else time_counter++;
}

void get_fragment (int X_offset, int Y_offset, int size) {
  img_fragment = get(X_offset-30,Y_offset-30,size,size);
  img_fragment.filter(GRAY);
}

void print_fragment (int X_offset, int Y_offset, int X_high, int Y_width) {
  imageMode(CORNER);
  image(img_fragment,X_offset,Y_offset,X_high,Y_width);
}

// в окне отрисовываем преобрадающий оттенок пикселей на участке
void print_window (float window_scale) {
  rectMode(CENTER);
  strokeWeight(1);
  noFill();
  stroke(0);
  rect(mouseX,mouseY,70,70);
  
}


void print_hexagon (int offset_X, int offset_Y, float size_factor, color color_fill, int fill_flag, color color_stroke) {
  //if(fill_flag == 1) fill(color_fill); else noFill();
  strokeWeight(2);
  //stroke(color_stroke);
  beginShape(); // рисуем шестиугольник
  vertex(offset_X+17*size_factor, offset_Y+30*size_factor);
  vertex(offset_X+35*size_factor, offset_Y);
  vertex(offset_X+17*size_factor, offset_Y-30*size_factor);
  vertex(offset_X-17*size_factor, offset_Y-30*size_factor);
  vertex(offset_X-35*size_factor, offset_Y);
  vertex(offset_X-17*size_factor, offset_Y+30*size_factor);
  vertex(offset_X+17*size_factor, offset_Y+30*size_factor);
  endShape();
  /*
  rectMode(CENTER);
  noFill();
  square(offset_X,offset_Y,60*size_factor);
  */
}

// подпрограмма создания матрицы чешуек заданного размера
void calculate_matrix(int matrix_offset_X, int matrix_offset_Y, int X_quantity, int Y_quantity, float size_factor) {
  int X_quantity_temp;
  int Y_quantity_temp;
  int Y_offset_local; // смещение на нечётных
  matrix_offset_X = matrix_offset_X - int(10*size_factor);
  quantity_of_scale = X_quantity*Y_quantity; // общее количество чешуек
  quantity_of_scale_temp = 0;
  for(X_quantity_temp = 0; X_quantity_temp< X_quantity; X_quantity_temp++) { // заполняем оси Х (строки)
    if((X_quantity_temp%2)==0) { Y_offset_local = -int((vertical_indent/2)*size_factor); } else { Y_offset_local = 0; }
    for(Y_quantity_temp = 0; Y_quantity_temp< Y_quantity; Y_quantity_temp++) { // заполняем по оси Y (столбики)
      coordinates_of_scale[quantity_of_scale_temp][0] = matrix_offset_X + int(horizontal_vertical*X_quantity_temp*size_factor); // вводим координату Х
      coordinates_of_scale[quantity_of_scale_temp][1] = matrix_offset_Y + Y_offset_local + int(vertical_indent*Y_quantity_temp*size_factor); // вводим координату Y
      quantity_of_scale_temp++;
    }
  }
}

void fragment_analysis () {
  int scale_counter = 0;
  for(int m=0; m<quantity_of_scale; m++) {
    if(scale_validate[m] == 1) {
      int window_size = int(70*70);
      int pixels_pointer_loc = 0;
      float [] pixels_RED_value = new float [window_size]; 
      float [] pixels_GREEN_value = new float [window_size]; 
      float [] pixels_BLUE_value = new float [window_size]; 
      int x_start = coordinates_of_scale[m][0]-int(35);
      int y_start = coordinates_of_scale[m][1]-int(35);
      int x_end = coordinates_of_scale[m][0]+int(35);
      int y_end = coordinates_of_scale[m][1]+int(35);
      /*
      stroke(255);
      noFill();
      rectMode(CORNERS);
      rect(x_start,y_start,x_end,y_end);
      */
      color c;
      // читаем цвета всех пикселей из заданной области
      for(int i = x_start; i<x_end; i++) {
        for(int j = y_start; j<y_end; j++) {
            c = get(i,j);
            pixels_RED_value [pixels_pointer_loc] = red(c);
            pixels_GREEN_value [pixels_pointer_loc] = green(c);
            pixels_BLUE_value [pixels_pointer_loc] = blue(c);
            pixels_pointer_loc++;
        }
      }
      
      float red_result = 0;
      float green_result = 0;
      float blue_result = 0;
      
      // вычисляем сумарный оттенок области
      for(int i=0; i<pixels_pointer_loc; i++) {
        red_result = red_result + pixels_RED_value [i] / window_size;
        green_result = green_result + pixels_GREEN_value [i] / window_size;
        blue_result = blue_result + pixels_BLUE_value [i] / window_size;
      }
      main_tone_color[scale_counter] = color(red_result,green_result,blue_result); 
      if(red_result>120) {
        scale_color[scale_counter] = 255; 
        UART_data_transmit[scale_counter] = '1';
      }
      else {
        scale_color[scale_counter] = 0;
        UART_data_transmit[scale_counter] = '0';
      }
      scale_counter++;
    }
  }
  

}

void image_print () {
  /*
  rectMode(CENTER);
  noStroke();
  for(int i=0; i<img_width; i=i+1) {
    for(int j=0; j<img_height; j=j+1) {
      fill(pixels_matrix[i][j]);
      square(i*img_scale_coeff+bias_width,j*img_scale_coeff+bias_height,2*img_scale_coeff);
    }
  }
  */
}


void mouseWheel(MouseEvent event) {
  int e = event.getCount();
  if(mousePressed && (mouseButton == RIGHT)) {
    if(e<0) {
      window_scale_coeff = window_scale_coeff + 0.1;
    }
    else {
       window_scale_coeff = window_scale_coeff - 0.1;
    }
    if(window_scale_coeff<0.1) window_scale_coeff = 0.1;
    println(window_scale_coeff);
  }
  else {
    if(e<0) {
      img_scale_coeff = img_scale_coeff + img_scale_coeff/10;
    }
    else {
      img_scale_coeff = img_scale_coeff - img_scale_coeff/10;
    }
    if(img_scale_coeff<0.1) img_scale_coeff = 0.1;
    
  }
}

void mouseDragged() 
{
  bias_height = bias_height + (mouseY - pmouseY);
  bias_width = bias_width + (mouseX - pmouseX);
}

void mousePressed() {

}

int byte_counter = 0;
void serialEvent(Serial p) { 
  UART_data_resive = p.readString(); 
  println(UART_data_resive);
  
} 
