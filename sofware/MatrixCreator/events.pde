byte mousePressLeftFLAG = 0;
byte mousePressRightFLAG = 0;
byte mousePressCenterFLAG = 0;
int selectionTool = -1;
int mouseDragged_X = 0;
int mouseDragged_Y = 0;

byte savePatternFLAG = 0;
byte loadPatternFLAG = 0;

String outputFileAbsolutePath;
String inputFileAbsolutePath;

void resetVariable () {
  savePatternFLAG = 0;
  loadPatternFLAG = 0;
  pattern.fragmentPrintFLAG = 0;
}

void mouseWheel(MouseEvent event) {
  float e = event.getCount();
  if(keyCode == SHIFT) {
    toolSize += e/5;
    if(toolSize < 0.7) toolSize = 0.7;
    return;
  }
  camZ+=e*10;
  grid.sequins.size += e/10;
  pattern.sequins.size += e/10;
}
 
void mouseDragged() {
  mouseDragged_X = (pmouseX - mouseX);
  mouseDragged_Y = (pmouseY - mouseY);
}

void mouseMoved() {
  mouseDragged_X = (pmouseX - mouseX);
  mouseDragged_Y = (pmouseY - mouseY);
}

void mousePressed() {
  if (mouseButton == LEFT) mousePressLeftFLAG = 1;
  if (mouseButton == RIGHT) mousePressRightFLAG = 1;
  if (mouseButton == CENTER) mousePressCenterFLAG = 1;
}

void mouseReleased() {
  if (mouseButton == LEFT) mousePressLeftFLAG = 0;
  if (mouseButton == RIGHT) mousePressRightFLAG = 0;
  if (mouseButton == CENTER) mousePressCenterFLAG = 0;
}

void radio(int a) {
  selectionTool = a;
}

public void savePattern (int theValue) {
  savePatternFLAG = 1;
}

public void loadPattern (int theValue) {
  loadPatternFLAG = 1;
}

public void addTop (int theValue) {
  pattern.matrixSize_Y += 1;
  int counter1 = 0;
  int counter2 = 0;
  for(int i=0; i<pattern.matrixSize_X*pattern.matrixSize_Y; i++) {
    // смещаем элементы массива вправо
    if(counter1 == 0) {
      for(int k=pattern.matrixSize_X*pattern.matrixSize_Y; k > counter2; k--) {
          pattern.sequinsState[k] = pattern.sequinsState[k-1];
      }
      pattern.sequinsState[i] = 0;
    }
    counter1++;
    counter2++;
    if(counter1 == pattern.matrixSize_Y) counter1 = 0;
  }
}
public void addBottom (int theValue) {
  pattern.matrixSize_Y += 1;
  int counter1 = 0;
  int counter2 = 0;
  for(int i=0; i<pattern.matrixSize_X*pattern.matrixSize_Y; i++) {
    
    if(counter1 == pattern.matrixSize_Y) {
      
      // смещаем элементы массива вправо
      for(int k=pattern.matrixSize_X*pattern.matrixSize_Y; k > counter2-1; k--) {
        pattern.sequinsState[k] = pattern.sequinsState[k-1];
      }
      pattern.sequinsState[i-1] = 0;
      counter1 = 0;
    }
    counter1++;
    counter2++;
  }
}
public void addLeft (int theValue) {
  pattern.matrixSize_X += 1;
  if(pattern.matrixCalculateMode == 0) pattern.matrixCalculateMode = 1;
  else                                 pattern.matrixCalculateMode = 0;
  // сдвигаем массив вправо на Y строк
  for(int k=pattern.matrixSize_X*pattern.matrixSize_Y; k > 0; k--) {
        if(k <= pattern.matrixSize_Y)  pattern.sequinsState[k] = 0;
        else                           pattern.sequinsState[k] = pattern.sequinsState[k-pattern.matrixSize_Y];
  }
}
public void addRight (int theValue) {
  pattern.matrixSize_X += 1;
}

public void delTop (int theValue) {
  // смещаем паттерн 
  int counter1 = 0;
  int copPointer = 0;
  for(int i = 0; i < pattern.matrixSize_X*pattern.matrixSize_Y; i++) {
    pattern.sequinsState[i] = pattern.sequinsState[i + 1];
  }   
   // отрезаем лишнее
   delBottom(100);
}

public void delBottom (int theValue) {
  int counter1 = 0;
  int copPointer = 0;
  for(int pointer = 0; pointer < pattern.matrixSize_X*pattern.matrixSize_Y; pointer++) {
            pattern.sequinsStateCop[copPointer] = pattern.sequinsState[pointer];
            copPointer ++;
            counter1 ++;
              
            if(counter1 == pattern.matrixSize_Y) {
              counter1 = 0;
              copPointer -=1;
            }
  }
       
  for(int i = 0; i < pattern.matrixSize_X*pattern.matrixSize_Y; i++) {
    pattern.sequinsState[i] = pattern.sequinsStateCop[i]; 
  }
       
  // удаляем строку
  pattern.matrixSize_Y -= 1;
}

public void delLeft (int theValue) {
  if(pattern.matrixCalculateMode == 0) pattern.matrixCalculateMode = 1;
  else                                 pattern.matrixCalculateMode = 0;
  for(int k=0; k<pattern.matrixSize_X*pattern.matrixSize_Y; k++) {
    if(k <= (pattern.matrixSize_X*pattern.matrixSize_Y - pattern.matrixSize_Y))
    pattern.sequinsState[k] = pattern.sequinsState[k+pattern.matrixSize_Y];
  else
  break;
  }
   pattern.matrixSize_X -= 1;
}

public void delRight (int theValue) {
  for(int i = (pattern.matrixSize_X*pattern.matrixSize_Y - pattern.matrixSize_Y); i<pattern.matrixSize_X*pattern.matrixSize_Y; i++) {
    pattern.sequinsState[i] = 0;
  }
  pattern.matrixSize_X -= 1;
}

public void split (int theValue) {
  if(pattern.fragmentPrintFLAG == 0) pattern.fragmentPrintFLAG = 1;
  else                               pattern.fragmentPrintFLAG = 0;
  pattern.Fragment();
  
}

public void editFragmentSizeX (String value) {
  pattern.fragmentSizeX = int(value);
}

public void editFragmentSizeY (String value) {
  pattern.fragmentSizeY = int(value);
}

public void editSequinsR (String value) {
  pattern.sequins.sequins_R_in = float(value);
  pattern.sequins.sequins_R_out = (pattern.sequins.sequins_R_in + pattern.sequins.gap/2)/cos(radians(30));
}

public void editSequinsGap (String value) {
  pattern.sequins.gap = float(value);
  pattern.sequins.sequins_R_out = (pattern.sequins.sequins_R_in + pattern.sequins.gap/2)/cos(radians(30));
}

public void sreateSTL (int Value) {
  if(pattern.createStlFLAG == 0) pattern.createStlFLAG = 1;
  pattern.sequins.sequins_R_out = (pattern.sequins.sequins_R_in + pattern.sequins.gap/2)/cos(radians(30));
}


// обработчик команды открытия файла
void readfileSelected(File selection) {
  if (selection != null) {
    loadPatternFLAG = 3;
    inputFileAbsolutePath = selection.getAbsolutePath();
  }
}

// обработчик команды записи файла
void writefileSelected(File selection) {
  if (selection != null) {
    outputFileAbsolutePath = selection.getAbsolutePath();
    savePatternFLAG = 3;
  }
}
