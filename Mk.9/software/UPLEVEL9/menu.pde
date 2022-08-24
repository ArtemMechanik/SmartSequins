void menuSetup () {
  menu.addToggle("broadcast")
     .setPosition(10,50)
     .setSize(100,30)
     .setLabel("  ")
     .setValue(false)
     .setMode(ControlP5.SWITCH)
     ;
  
  menu.addButton("button1")
     .setValue(100)
     .setPosition(10,630)
     .setSize(200,40)
     .setLabel("Sequins number");
     ;
     
  menu.addButton("button2")
     .setValue(100)
     .setPosition(10,670)
     .setSize(200,40)
     .setLabel("Change color");
     ;  
     
  menu.addButton("button3")
     .setValue(100)
     .setPosition(10,570)
     .setSize(220,40)
     .setLabel("write parameters")
     .activateBy(1);
     ;
     /*
       button3.onPress(new CallbackListener() { // add the Callback Listener to the button 
    public void controlEvent(CallbackEvent theEvent) {
      // specify whatever you want to happen here
      if(writeParametrsFLAG == 0) writeParametrsFLAG = 1;
      println("callback for startBarCode ");
    }
  }
  );*/
     
  menu.addButton("button4")
     .setValue(100)
     .setPosition(10,710)
     .setSize(200,40)
     .setLabel("set all");
     ;
     
  menu.addButton("button5")
     .setValue(100)
     .setPosition(10,750)
     .setSize(200,40)
     .setLabel("reset all");
     ; 
  
  // текстовые поля для настройки режимов энергопотребления пайеток
  menu.addTextfield("editSleapMode")
     .setPosition(10,180)
     .setSize(100,40)
     .setValue("100")
     .setLabel("  ")
     .setFocus(true)
     .setAutoClear(false)
     .setColor(color(255))
     ; 
  menu.addTextfield("editWorkMode")
     .setPosition(10,260)
     .setSize(100,40)
     .setValue("4")
     .setLabel("  ")
     .setFocus(true)
     .setAutoClear(false)
     .setColor(color(255))
     ; 
  menu.addTextfield("editcolorChangeMode")
     .setPosition(10,340)
     .setSize(100,40)
     .setValue("200")
     .setLabel("  ")
     .setFocus(true)
     .setAutoClear(false)
     .setColor(color(255))
     ;
  menu.addTextfield("editTimeDelay")
     .setPosition(10,430)
     .setSize(100,40)
     .setValue("10")
     .setLabel("  ")
     .setFocus(true)
     .setAutoClear(false)
     .setColor(color(255))
     ;
  menu.addTextfield("editTimeChangeColor")
     .setPosition(10,510)
     .setSize(100,40)
     .setValue("50")
     .setLabel("  ")
     .setFocus(true)
     .setAutoClear(false)
     .setColor(color(255))
     ; 
     

}

void menuUpdate () {
  // выводим экранные формы и надписи
  noStroke();
  fill(100);
  rectMode(CORNERS);
  rect(0,0,width/3,height);
  
  noStroke();
  fill(255);
  textSize(25);
  textAlign(LEFT,TOP);
  if(broadcastFLAG == 0) {
    fill(color(255,0,0));
    text("broadcast OFF",10,10);
  }
  else if(broadcastFLAG == 1) {
    fill(color(0,255,0));
    text("broadcast ON",10,10);
  }
  

  fill(255);
  text("sequins quantity:" + sequins.sequinsQuantity,10,100);
  
  // параметры энергопотребления
  fill(0);
  stroke(0);
  line(0,145,width/3,145);
  
  // параметр энергопотребления в спящем режиме
  noStroke();
  fill(255);
  text("sleap mode",10,150);
  text(sleapModeCurrent + "uA",120,185);
  
  // энергопотребление в рабочем режиме
  text("work mode",10,230);
  text(workModeCurrent + "mA",120,265);
  
  // энергопотребление при смене цвета
  text("color change mode",10,310);
  text(colorChangeModeCurrent + "mA",120,345);
  
  // параметры времени переключения пайеток
  fill(0);
  stroke(0);
  line(0,390,width/3,390);
  
  noStroke();
  fill(255);
  text("delay",10,400);
  text(sequinsTimeDelay + "mS",120,435);
  
  text("change color time",10,480);
  text(sequinsTimeChangeColor + "mS",120,515);
  
  if(sequinsTimeDelay != sequinsTimeDelayPrev) fill(color(255,0,0));
  else                                         fill(color(0,255,0));
  rect(width/3-30,575,width/3-5,605);
  
  fill(0);
  stroke(0);
  line(0,620,width/3,620);
  
  fill(0);
  stroke(0);
  line(0,800,width/3,800);
  
  // расчётные параметры
  noStroke();
  if(broadcastFLAG == 0)     fill(color(0,255,0));
  else                       fill(color(255,0,0));
  text("Imax: " + currentMax + "mA",10,820);
  text("Total time: " + totalTime + "mS",10,850);

}
