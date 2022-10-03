// экранные формы, кнопки, обработка клавиатуры и мыши
void menuSetup() {
   menu = new ControlP5(this);
   menu.setFont(createFont("Arial bold",20));
   
   menu.addButton("button1") // открыть исходный файл
     .setValue(100)
     .setPosition(10,10)
     .setSize(200,40)
     .setLabel("ОТКРЫТЬ");
     ;
      
   menu.addButton("button2") // разнести слои
     .setValue(100)
     .setPosition(10,60)
     .setSize(200,40)
     .setLabel("РАЗНЕСТИ");
     ;
     
   menu.addButton("button3") // вставить паузу в указанном месте
     .setValue(100)
     .setPosition(10,110)
     .setSize(200,40)
     .setLabel("ВСТАВИТЬ ПАУЗУ");
     ;
     
   menu.addButton("button4") // запись файла
     .setValue(100)
     .setPosition(10,170)
     .setSize(200,40)
     .setLabel("ЗАПИСАТЬ ФАЙЛ");
     ;
}

void mouseWheel(MouseEvent event) {
  float e = event.getCount();
  if(currentKeyCode == keyCode_L_CTRL) {
    if(e > 0) {
      if(selectedLayer < layerNumber) selectedLayer += 1;
    }
    else {
      if(selectedLayer > 0) selectedLayer -= 1;
    }
  }
  else {
    camZ+=e*10;
  }
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
  }
}

void keyPressed() {
  currentKeyCode = keyCode;
}

void keyReleased() {
  currentKeyCode = 0;
}
