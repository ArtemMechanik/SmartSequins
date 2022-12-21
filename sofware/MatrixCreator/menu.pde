float toolSize = 0.7;
int fragmentX = 0;
int fragmentY = 0;

void menuSetup () {
   menu.addRadioButton("radio")
     .setPosition(10,10)
     .setSize(30,30)
     .addItem("draw normal",0)
     .addItem("erasing",1)
     .addItem("draw pattern 1",2)
     .addItem("draw pattern 2",3)
     .addItem("draw pattern 3",4)
   ;
   
  menu.addButton("savePattern")
     .setValue(100)
     .setPosition(10,170)
     .setSize(200,30)
     .setLabel("save pattern");
     ;
     
  menu.addButton("loadPattern")
     .setValue(100)
     .setPosition(10,200)
     .setSize(200,30)
     .setLabel("load pattern");
     ;
     
     // добавить линии
    menu.addButton("addTop")
     .setValue(100)
     .setPosition(10,270)
     .setSize(110,30)
     .setLabel("top");
     ;
     menu.addButton("addBottom")
     .setValue(100)
     .setPosition(10,300)
     .setSize(110,30)
     .setLabel("bottom");
     ;
     
     menu.addButton("addLeft")
     .setValue(100)
     .setPosition(10,330)
     .setSize(110,30)
     .setLabel("left");
     ;
     
     menu.addButton("addRight")
     .setValue(100)
     .setPosition(10,360)
     .setSize(110,30)
     .setLabel("right");
     ;
     
      // удалить линии
    menu.addButton("delTop")
     .setValue(100)
     .setPosition(150,270)
     .setSize(110,30)
     .setLabel("top");
     ;
     menu.addButton("delBottom")
     .setValue(100)
     .setPosition(150,300)
     .setSize(110,30)
     .setLabel("bottom");
     ;
     
     menu.addButton("delLeft")
     .setValue(100)
     .setPosition(150,330)
     .setSize(110,30)
     .setLabel("left");
     ;
     
     menu.addButton("delRight")
     .setValue(100)
     .setPosition(150,360)
     .setSize(110,30)
     .setLabel("right");
     ;
     
     // размер фрагментов
   menu.addTextfield("editFragmentSizeX")
     .setPosition(10,430)
     .setSize(100,40)
     .setValue("0")
     .setLabel("  ")
     .setFocus(true)
     .setAutoClear(false)
     .setColor(color(255))
     ;
     
   menu.addTextfield("editFragmentSizeY")
     .setPosition(140,430)
     .setSize(100,40)
     .setValue("0")
     .setLabel("  ")
     .setFocus(true)
     .setAutoClear(false)
     .setColor(color(255))
     ;
    
     // разбиение на фрагменты
   menu.addButton("split")
     .setValue(100)
     .setPosition(10,480)
     .setSize(250,30)
     .setLabel("split");
     ;
   
     // размер пайетки (внутренний радиус)
   menu.addTextfield("editSequinsR")
     .setPosition(90,550)
     .setSize(100,40)
     .setValue("0")
     .setLabel("  ")
     .setFocus(true)
     .setAutoClear(false)
     .setColor(color(255))
     ;
     
  menu.addTextfield("editSequinsGap")
     .setPosition(90,595)
     .setSize(100,40)
     .setValue("0")
     .setLabel("  ")
     .setFocus(true)
     .setAutoClear(false)
     .setColor(color(255))
     ;
     
      // создание STL файлов
   menu.addButton("sreateSTL")
     .setValue(100)
     .setPosition(10,645)
     .setSize(250,30)
     .setLabel("CREATE STL");
     ;
}

void drawGUI () {
  fill(255,255);
  stroke(255,255);
  textSize(20);
  text("ADD LINE",20,260);
  text("DELET LINE",150,260);
  text("FRAGMENT SIZE",20,420);
  text("X",115,460);
  text("SEQUINS SIZE",20,540);
  text("R (in)",20,580);
  text("mm",195,580);
  text("GAP",20,620);
  text("mm",195,620);
  
  // строка состояния снизу
  textSize(15);
  text("matrix (" + pattern.matrixSize_X + ";" + pattern.matrixSize_Y + "), segments: " + pattern.matrixSize_Y*pattern.matrixSize_X
                  + ", sequins R (out): " + pattern.sequins.sequins_R_out
                  + ", sequins R (in): " + pattern.sequins.sequins_R_in
                  + ", sequins gap: " + pattern.sequins.gap
                ,10,height - 20);
  
}
