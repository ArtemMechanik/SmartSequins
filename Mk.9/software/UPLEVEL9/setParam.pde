int sequinsNumberShow = 1;
int sequinsModeShow = 1;
float sequinsMatrixRotateAngle = 0;
float sequinsSizeFactor = 1;
int writeParametrsFLAG = 0;
int broadcastFLAG = 1; // передача состояния пайеток напрямую в контроллер
int mouseButtonLeftFLAG = 0;
int scrolFLAG = 0;
int sequinsMatrixUpdateFLAG;
int sequinsMatrixUpdateComplite;

void setDefaultParametrs () {
  sequinsNumberShow = 0;
  sequinsModeShow = 0;
  sequinsMatrixRotateAngle = 0;
  sequinsSizeFactor = 1;
  writeParametrsFLAG = 0;
  broadcastFLAG = 0; // передача состояния пайеток напрямую в контроллер
  mouseButtonLeftFLAG = 0;
  scrolFLAG = 0;
  sequinsMatrixUpdateFLAG = 0;
  sequinsMatrixUpdateComplite = 1;
}
public void button1 (int theValue) {
  if(sequinsNumberShow == 0) sequinsNumberShow = 1; else sequinsNumberShow = 0;
  println("show numbers and states");
}

public void button2 (int theValue) {
  if(sequins.sequinsColorChangeFLAG == 0) sequins.sequinsColorChangeFLAG = 1;
}

public void button3 (int theValue) {
  if(writeParametrsFLAG == 0) writeParametrsFLAG = 1;
  println("write parametrs...");
}

public void button4 (int theValue) {
  if(sequins.sequinsSetFLAG == 0) sequins.sequinsSetFLAG = 1;
}

public void button5 (int theValue) {
  if(sequins.sequinsResetFLAG == 0) sequins.sequinsResetFLAG = 1;
}

public void editSleapMode(String theText) {
  sleapModeCurrent = float(theText);
  println("sleap mode current = " + theText + "uA");
}

public void editWorkMode (String theText) {
  workModeCurrent = float(theText);
  println("work current = " + theText + "mA");
}

public void editcolorChangeMode (String theText) {
  colorChangeModeCurrent = float(theText);
  println("color change current = " + theText + "mA");
}

public void editTimeDelay (String theText) {
  sequinsTimeDelay = float(theText);
  println("delay time = " + theText + "mS");
}

public void editTimeChangeColor (String theText) {
  sequinsTimeChangeColor = float(theText);
  println("color change time = " + theText + "mS");
}

void broadcast(boolean theFlag) {
  if(theFlag == true) {
    broadcastFLAG = 1;
    println("broadcast is enabled");
  }
  else {
    broadcastFLAG = 0;
    println("broadcast is disabled");
  }
}

void mouseWheel(MouseEvent event) {
  scrolFLAG = 1;
  float e = event.getCount();
  sizeMatrix += e/20;
}

void mousePressed() {
  if(mouseButton == LEFT) {
    mouseButtonLeftFLAG = 1;
  }
}

void mouseReleased() {
  mouseButtonLeftFLAG = 0;
}
