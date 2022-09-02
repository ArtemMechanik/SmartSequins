#include <MDR32FxQI_port.h>
#include <MDR32FxQI_rst_clk.h>

struct sequinsCounters {
  uint8_t delayCounter;
  uint8_t currentStep;  
  uint8_t bytePointer;
  uint8_t bitPointer;
  uint8_t sequinsCounter;
};

struct matrixUpdateVariables {
  uint8_t timeLow;
  uint8_t timeTotal;
  uint8_t updateStart;
  uint8_t updateComplite;
  
  struct  sequinsCounters counters;
};

struct sequinsSerial {
  struct  sequinsCounters counters;
};

struct sequinsFLAGs {
  uint8_t change;             // флаг начала смены цвета
  uint8_t changeComplite;     // флаг окончания смены цвета
  uint8_t changeBreak;        // флаг преждевременного завершения изменения состояния пайеток
  uint8_t stateResiveMode;    // режим работы приёмника
  uint8_t matrixUpdateStart;        // запуск механизма обновления матрицы
  uint8_t matrixUpdateComplite;
};

struct sequinsMatrix {
  uint16_t quantity;          // количество пайеток состояние которых нужно изменить на текущем этапе
  uint16_t timeParametr;     // задержка между переключенями пайеток
  uint8_t state[10];      // состояние пайеток (каждый бит - одна пайетка)
  uint8_t stateNew[10];   // состояние пайеток, полученное по UART
  struct sequinsCounters        counters;
  struct sequinsFLAGs           FLAG;
  struct matrixUpdateVariables  matrix;
  struct sequinsSerial          serial;
};

void sequinsStructReset (void);
void sequinsBreakChange (struct sequinsMatrix *matrixLoc);
void sequinsExecute (struct sequinsMatrix *matrixLoc);