// подключаемые библиотеки
import processing.serial.*; // библиотека для работы с последовательным портом
import controlP5.*;

Serial headController; 

ControlP5 menu;

// основные параметры
color backgroundColor = 0;
float sizeMatrix = 2.2;

SequinsAPI sequins;
SequinsAPI sequins1;
HeadController controller;

void setup () {
  size(800,900);
  frameRate(60);
  menu = new ControlP5(this);
  menu.setFont(createFont("Arial bold",20));
  textFont(createFont("Arial",20));
  sequins = new SequinsAPI ();
  sequins1 = new SequinsAPI ();
  
  // последовательный порт для работы с контроллером
  String Hed_scale_controller_port = "COM10";
  headController = new Serial(this,Hed_scale_controller_port,9600);
  headController.bufferUntil('\n');
  controller = new HeadController();
      
  menuSetup();
  
  sequins.setSize(sizeMatrix);
  sequins.CalculateMatrix(3,3);
  
  setDefaultParametrs();
}

void draw () {
  background(backgroundColor);
  
  if(scrolFLAG != 0) {
     sequins.setSize(sizeMatrix);
     sequins.CalculateMatrix(3,3);
     scrolFLAG = 0;
  }
  
  sequins.PrintMatrix((width/2),200);
  menuUpdate();
  controller.serialExecute(sequinsTimeDelay,sequins.sequinsState,sequins.sequinsQuantity);
}
