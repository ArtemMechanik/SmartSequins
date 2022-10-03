void setDefaultParam () {
  scaleValue = 1.0;
  currentKeyCode = 0;
  setPause = 0;
  selectFile = 0;
  openFileFLAG = 0;
  newFileLoadFLAG = 0;
  selectOutputFile = 0;
}

// обработка нажатия по экранным формам
public void button1 (int theValue) {
  if(selectFile == 0) selectFile = 1;
}

public void button2 (int theValue) {
  if(scaleValue == 1.0) scaleValue = 30.0; else  scaleValue = 1.0;
}

public void button3 (int theValue) {
  if(setPause == 0) setPause = 1; else setPause = 0;
}

public void button4 (int theValue) {
  if(selectOutputFile == 0) selectOutputFile = 1;
  //if(sequinsPrint == 0) sequinsPrint = 1; else sequinsPrint = 0;
}

// обработчик команды открытия файла
void readfileSelected(File selection) {
  if (selection != null) {
    selectFile = 3;
    inputFileAbsolutePath = selection.getAbsolutePath();
    println("Read file: " + inputFileAbsolutePath);
  }
}

// обработчик команды записи файла
void writefileSelected(File selection) {
  if (selection != null) {
    selectOutputFile = 3;
    outputFileAbsolutePath = selection.getAbsolutePath();
    println("Write file: " + outputFileAbsolutePath);
  }
}
