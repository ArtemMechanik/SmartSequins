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
  uint8_t change;             // ���� ������ ����� �����
  uint8_t changeComplite;     // ���� ��������� ����� �����
  uint8_t changeBreak;        // ���� ���������������� ���������� ��������� ��������� �������
  uint8_t stateResiveMode;    // ����� ������ ��������
  uint8_t matrixUpdateStart;        // ������ ��������� ���������� �������
  uint8_t matrixUpdateComplite;
};

struct sequinsMatrix {
  uint16_t quantity;          // ���������� ������� ��������� ������� ����� �������� �� ������� �����
  uint16_t timeParametr;     // �������� ����� ������������� �������
  uint8_t state[10];      // ��������� ������� (������ ��� - ���� �������)
  uint8_t stateNew[10];   // ��������� �������, ���������� �� UART
  struct sequinsCounters        counters;
  struct sequinsFLAGs           FLAG;
  struct matrixUpdateVariables  matrix;
  struct sequinsSerial          serial;
};

void sequinsStructReset (void);
void sequinsBreakChange (struct sequinsMatrix *matrixLoc);
void sequinsExecute (struct sequinsMatrix *matrixLoc);