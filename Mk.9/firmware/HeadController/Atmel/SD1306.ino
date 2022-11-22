#include "avr/pgmspace.h" // библиотека для работы с flash памятью
// макросы для дисплея и часть простых примитивов взял здесь: https://github.com/tibounise/SSD1306-AVR

// макросы с командами для дисплея
#define SSD1306_DEFAULT_ADDRESS       0x78
#define SSD1306_SETCONTRAST           0x81
#define SSD1306_DISPLAYALLON_RESUME   0xA4
#define SSD1306_DISPLAYALLON          0xA5
#define SSD1306_NORMALDISPLAY         0xA6
#define SSD1306_INVERTDISPLAY         0xA7
#define SSD1306_DISPLAYOFF            0xAE
#define SSD1306_DISPLAYON             0xAF
#define SSD1306_SETDISPLAYOFFSET      0xD3
#define SSD1306_SETCOMPINS            0xDA
#define SSD1306_SETVCOMDETECT         0xDB
#define SSD1306_SETDISPLAYCLOCKDIV    0xD5
#define SSD1306_SETPRECHARGE          0xD9
#define SSD1306_SETMULTIPLEX          0xA8
#define SSD1306_SETLOWCOLUMN          0x00
#define SSD1306_SETHIGHCOLUMN         0x10
#define SSD1306_SETSTARTLINE          0x40
#define SSD1306_MEMORYMODE            0x20
#define SSD1306_COLUMNADDR            0x21
#define SSD1306_PAGEADDR              0x22
#define SSD1306_COMSCANINC            0xC0
#define SSD1306_COMSCANDEC            0xC8
#define SSD1306_SEGREMAP              0xA0
#define SSD1306_CHARGEPUMP            0x8D
#define SSD1306_SWITCHCAPVCC          0x2
#define SSD1306_NOP                   0xE3

#define SSD1306_WIDTH                 128
#define SSD1306_HEIGHT                32
#define SSD1306_BUFFERSIZE            (SSD1306_WIDTH*SSD1306_HEIGHT)/8

// цвета пикселя
#define BLUE  0x01
#define BLACK 0x00

void SSD1306_sendCommand(uint8_t command) {
  I2Cstart(SSD1306_DEFAULT_ADDRESS);
  I2Cwrite(0x00);
  I2Cwrite(command);
  I2Cstop();
}

void SSD1306_sendData(uint8_t data) {
  I2Cstart(SSD1306_DEFAULT_ADDRESS);
  I2Cwrite(0x40);
  I2Cwrite(data);
  I2Cstop();
}

void SSD1306_invert(uint8_t inverted) {
  if (inverted) {
    SSD1306_sendCommand(SSD1306_INVERTDISPLAY);
    } else {
    SSD1306_sendCommand(SSD1306_NORMALDISPLAY);
  }
}

void SSD1306_sendFramebuffer(uint8_t *buffer) {
  I2Cstart(SSD1306_DEFAULT_ADDRESS);
  I2Cwrite(0x40); // передаём данные
  
  for (uint8_t packet = 0; packet < 32; packet++) {
    for (uint8_t packet_byte = 0; packet_byte < 16; ++packet_byte) {
      I2Cwrite(buffer[packet*16+packet_byte]);
    }
  }
  I2Cstop();
}

// процедуру инициализации взял отсюда: https://microtechnics.ru/displej-na-baze-kontrollera-ssd1306-biblioteka-dlya-stm32/
// порядок процедуры инициализации и описание регистров дисплея на русском здесь: http://microsin.net/adminstuff/hardware/ssd1306-oled-controller.html
void SSD1306_setup (void) {
  I2Csetup();
  
  // Turn display off
  uint8_t data[3];
  
  // Set display off
  SSD1306_sendCommand(0xAE);
  
  // Set MUX ratio
  SSD1306_sendCommand(0xA8);
  SSD1306_sendCommand(63);
    
  // Set display offset
  SSD1306_sendCommand(0xD3);
  SSD1306_sendCommand(0);
  
  // Set display start line
  SSD1306_sendCommand(0x40);
  
  // Set segment remap
  SSD1306_sendCommand(0xA1);
  
  // Enable charge pump regulator
  SSD1306_sendCommand(0x8D);
  SSD1306_sendCommand(0x14);

  // Set COM output scan direction
  SSD1306_sendCommand(0xC8);
  
  // Set COM pins hardware configuration
  SSD1306_sendCommand(0xDA);
  SSD1306_sendCommand(0x22); // проблема была вот в этом бите (в библиотеки стаяло значение 0х12)
  
  // Set contrast
  SSD1306_sendCommand(0x81);
  SSD1306_sendCommand(0xFF);
  
  // Entire display on
  SSD1306_sendCommand(0xA4);
  
  //Set normal display
  SSD1306_sendCommand(0xA6);
  
  // Set oscillator frequency
  SSD1306_sendCommand(0xD5);
  SSD1306_sendCommand(0x80);
  
  // Set display on
  SSD1306_sendCommand(0xAF);
  
  // Set horizontal addressing mode
  SSD1306_sendCommand(0x20);
  SSD1306_sendCommand(0x00);
  
  // Set column address
  SSD1306_sendCommand(0x21);
  SSD1306_sendCommand(0);
  SSD1306_sendCommand(127);
  
  // Set page address
  SSD1306_sendCommand(0x22);
  SSD1306_sendCommand(0);
  SSD1306_sendCommand(3);

}

// здесь функции для рисования графических примитивов
void drawPixel(uint8_t pos_x, uint8_t pos_y, uint8_t color) {
  if (pos_x >= SSD1306_WIDTH || pos_y >= SSD1306_HEIGHT) return;  // если не попадаем в дисплей, то и не рисуем...
  if(color != 0x00)  SD1306_buffer[pos_x+(pos_y/8)*SSD1306_WIDTH] |= (1 << (pos_y&7));
  else               SD1306_buffer[pos_x+(pos_y/8)*SSD1306_WIDTH] &=(~(1 << (pos_y&7)));
}

void drawVLine(uint8_t x, uint8_t y, int8_t length, uint8_t color) {
  int8_t dir = 1;
  if(length < 0) {
    length = abs(length);
    dir = -1;
  }
  for (uint8_t i = 0; i < length; ++i) {
    drawPixel(x,y+i*dir,color);
  }
}

void drawHLine(uint8_t x, uint8_t y, int8_t length,uint8_t color) {
  int8_t dir = 1;
  if(length < 0) {
    length = abs(length);
    dir = -1;
  }
  for (uint8_t i = 0; i < length; ++i) {
    drawPixel(x+i*dir,y,color);
  }
}

void drawLine(uint8_t x0, uint8_t y0, uint8_t x1, uint8_t y1, uint8_t fill) {
        if (x0 == x1) drawVLine(x0, y0, y1-y0, fill);
        else if (y0 == y1) drawHLine(x0, y0, x1-x0, fill);
        else {
            int sx, sy, e2, err;
            int dx = abs(x1 - x0);
            int dy = abs(y1 - y0);
            sx = (x0 < x1) ? 1 : -1;
            sy = (y0 < y1) ? 1 : -1;
            err = dx - dy;
            for (;;) {
                drawPixel(x0, y0, fill);
                if (x0 == x1 && y0 == y1) return;
                e2 = err<<1;
                if (e2 > -dy) { 
                    err -= dy; 
                    x0 += sx; 
                }
                if (e2 < dx) { 
                    err += dx; 
                    y0 += sy; 
                }
            }
        }
    }

void drawRectangle(uint8_t x1, uint8_t y1, uint8_t x2, uint8_t y2,uint8_t color) {
  uint8_t length = x2 - x1 + 1;
  uint8_t height = y2 - y1;

  drawHLine(x1,y1,length,color);
  drawHLine(x1,y2,length,color);
  drawVLine(x1,y1,height,color);
  drawVLine(x2,y1,height,color);
}

void drawFillRectangle(uint8_t x1, uint8_t y1, uint8_t x2, uint8_t y2,uint8_t color) {
  for(uint8_t width = x1; width <= x2; width++) {
    for(uint8_t high = y1; high <= y2; high++) {
      drawPixel(width,high,color);
    }
  }
}



void SSD1306_clear() {
  for (uint16_t buffer_location = 0; buffer_location < SSD1306_BUFFERSIZE; buffer_location++) {
    SD1306_buffer[buffer_location] = 0x00;
  }
}

void SSD1306_show() {
  SSD1306_sendFramebuffer(SD1306_buffer);
}

// несколько хороших шрифтов нашлось здесь: https://github.com/greiman/SSD1306Ascii/blob/master/src/fonts/lcdnums14x24.h
const PROGMEM uint8_t fonts8x8 [800] = {
  0x3C,0x62,0x52,0x4A,0x46,0x3C,0x00,0x00,  // 0
  0x44,0x42,0x7E,0x40,0x40,0x00,0x00,0x00,  // 1
  0x64,0x52,0x52,0x52,0x52,0x4C,0x00,0x00,  // 2
  0x24,0x42,0x42,0x4A,0x4A,0x34,0x00,0x00,  // 3
  0x30,0x28,0x24,0x7E,0x20,0x20,0x00,0x00,  // 4
  0x2E,0x4A,0x4A,0x4A,0x4A,0x32,0x00,0x00,  // 5
  0x3C,0x4A,0x4A,0x4A,0x4A,0x30,0x00,0x00,  // 6
  0x02,0x02,0x62,0x12,0x0A,0x06,0x00,0x00,  // 7
  0x34,0x4A,0x4A,0x4A,0x4A,0x34,0x00,0x00,  // 8
  0x0C,0x52,0x52,0x52,0x52,0x3C,0x00,0x00,  // 9

  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,  // <space>
  0x00,0x00,0x00,0x00,0x5F,0x00,0x00,0x00,  // !
  0x00,0x00,0x00,0x03,0x00,0x03,0x00,0x00,  // "
  0x00,0x24,0x7E,0x24,0x24,0x7E,0x24,0x00,  // #
  0x00,0x2E,0x2A,0x7F,0x2A,0x3A,0x00,0x00,  // $
  0x00,0x46,0x26,0x10,0x08,0x64,0x62,0x00,  // %
  0x00,0x20,0x54,0x4A,0x54,0x20,0x50,0x00,  // &
  0x00,0x00,0x00,0x04,0x02,0x00,0x00,0x00,  // '
  0x00,0x00,0x00,0x3C,0x42,0x00,0x00,0x00,  // (
  0x00,0x00,0x00,0x42,0x3C,0x00,0x00,0x00,  // )
  0x00,0x10,0x54,0x38,0x54,0x10,0x00,0x00,  // *
  0x00,0x10,0x10,0x7C,0x10,0x10,0x00,0x00,  // +
  0x00,0x00,0x00,0x80,0x60,0x00,0x00,0x00,  // ,
  0x00,0x10,0x10,0x10,0x10,0x10,0x00,0x00,  // -
  0x00,0x00,0x00,0x60,0x60,0x00,0x00,0x00,  // .
  0x00,0x40,0x20,0x10,0x08,0x04,0x00,0x00,  // /

  0x00,0x3C,0x42,0x5A,0x56,0x5A,0x1C,0x00,  // @
  0x7C,0x12,0x12,0x12,0x12,0x7C,0x00,0x00,  // A
  0x7E,0x4A,0x4A,0x4A,0x4A,0x34,0x00,0x00,  // B
  0x3C,0x42,0x42,0x42,0x42,0x24,0x00,0x00,  // C
  0x7E,0x42,0x42,0x42,0x24,0x18,0x00,0x00,  // D
  0x7E,0x4A,0x4A,0x4A,0x4A,0x42,0x00,0x00,  // E
  0x7E,0x0A,0x0A,0x0A,0x0A,0x02,0x00,0x00,  // F
  0x3C,0x42,0x42,0x52,0x52,0x34,0x00,0x00,  // G
  0x7E,0x08,0x08,0x08,0x08,0x7E,0x00,0x00,  // H
  0x00,0x42,0x42,0x7E,0x42,0x42,0x00,0x00,  // I
  0x30,0x40,0x40,0x40,0x40,0x3E,0x00,0x00,  // J
  0x7E,0x08,0x08,0x14,0x22,0x40,0x00,0x00,  // K
  0x7E,0x40,0x40,0x40,0x40,0x40,0x00,0x00,  // L
  0x7E,0x04,0x08,0x08,0x04,0x7E,0x00,0x00,  // M
  0x7E,0x04,0x08,0x10,0x20,0x7E,0x00,0x00,  // N
  0x3C,0x42,0x42,0x42,0x42,0x3C,0x00,0x00,  // O
  
  0x7E,0x12,0x12,0x12,0x12,0x0C,0x00,0x00,  // P
  0x3C,0x42,0x52,0x62,0x42,0x3C,0x00,0x00,  // Q
  0x7E,0x12,0x12,0x12,0x32,0x4C,0x00,0x00,  // R
  0x24,0x4A,0x4A,0x4A,0x4A,0x30,0x00,0x00,  // S
  0x02,0x02,0x02,0x7E,0x02,0x02,0x02,0x00,  // T
  0x3E,0x40,0x40,0x40,0x40,0x3E,0x00,0x00,  // U
  0x1E,0x20,0x40,0x40,0x20,0x1E,0x00,0x00,  // V
  0x3E,0x40,0x20,0x20,0x40,0x3E,0x00,0x00,  // W
  0x42,0x24,0x18,0x18,0x24,0x42,0x00,0x00,  // X
  0x02,0x04,0x08,0x70,0x08,0x04,0x02,0x00,  // Y
  0x42,0x62,0x52,0x4A,0x46,0x42,0x00,0x00,  // Z
  0x00,0x00,0x7E,0x42,0x42,0x00,0x00,0x00,  // [
  0x00,0x04,0x08,0x10,0x20,0x40,0x00,0x00,  // <backslash>
  0x00,0x00,0x42,0x42,0x7E,0x00,0x00,0x00,  // ]
  0x00,0x08,0x04,0x7E,0x04,0x08,0x00,0x00,  // ^
  0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x00,  // _
  
  0x3C,0x42,0x99,0xA5,0xA5,0x81,0x42,0x3C,  // `
  0x00,0x20,0x54,0x54,0x54,0x78,0x00,0x00,  // a
  0x00,0x7E,0x48,0x48,0x48,0x30,0x00,0x00,  // b
  0x00,0x00,0x38,0x44,0x44,0x44,0x00,0x00,  // c
  0x00,0x30,0x48,0x48,0x48,0x7E,0x00,0x00,  // d
  0x00,0x38,0x54,0x54,0x54,0x48,0x00,0x00,  // e
  0x00,0x00,0x00,0x7C,0x0A,0x02,0x00,0x00,  // f
  0x00,0x18,0xA4,0xA4,0xA4,0xA4,0x7C,0x00,  // g
  0x00,0x7E,0x08,0x08,0x08,0x70,0x00,0x00,  // h
  0x00,0x00,0x00,0x48,0x7A,0x40,0x00,0x00,  // i
  0x00,0x00,0x40,0x80,0x80,0x7A,0x00,0x00,  // j
  0x00,0x7E,0x18,0x24,0x40,0x00,0x00,0x00,  // k
  0x00,0x00,0x00,0x3E,0x40,0x40,0x00,0x00,  // l
  0x00,0x7C,0x04,0x78,0x04,0x78,0x00,0x00,  // m
  0x00,0x7C,0x04,0x04,0x04,0x78,0x00,0x00,  // n
  0x00,0x38,0x44,0x44,0x44,0x38,0x00,0x00,  // o
  
  0x00,0xFC,0x24,0x24,0x24,0x18,0x00,0x00,  // p
  0x00,0x18,0x24,0x24,0x24,0xFC,0x80,0x00,  // q
  0x00,0x00,0x78,0x04,0x04,0x04,0x00,0x00,  // r
  0x00,0x48,0x54,0x54,0x54,0x20,0x00,0x00,  // s
  0x00,0x00,0x04,0x3E,0x44,0x40,0x00,0x00,  // t
  0x00,0x3C,0x40,0x40,0x40,0x3C,0x00,0x00,  // u
  0x00,0x0C,0x30,0x40,0x30,0x0C,0x00,0x00,  // v
  0x00,0x3C,0x40,0x38,0x40,0x3C,0x00,0x00,  // w
  0x00,0x44,0x28,0x10,0x28,0x44,0x00,0x00,  // x
  0x00,0x1C,0xA0,0xA0,0xA0,0x7C,0x00,0x00,  // y
  0x00,0x44,0x64,0x54,0x4C,0x44,0x00,0x00,  // z
  0x00,0x08,0x08,0x76,0x42,0x42,0x00,0x00,  // {
  0x00,0x00,0x00,0x7E,0x00,0x00,0x00,0x00,  // |
  0x00,0x42,0x42,0x76,0x08,0x08,0x00,0x00,  // }
  0x00,0x00,0x04,0x02,0x04,0x02,0x00,0x00,  // ~

  0x00,0x00,0x00,0x48,0x00,0x00,0x00,0x00,  // :
  0x00,0x00,0x80,0x64,0x00,0x00,0x00,0x00,  // ;
  0x00,0x00,0x10,0x28,0x44,0x00,0x00,0x00,  // <
  0x00,0x28,0x28,0x28,0x28,0x28,0x00,0x00,  // =
  0x00,0x00,0x44,0x28,0x10,0x00,0x00,0x00,  // >
  0x00,0x04,0x02,0x02,0x52,0x0A,0x04,0x00,  // ?
};

// преобразование символа char в номер позиции в массиве символов
int16_t charToFonts (char simbol) {
  int16_t fontNumber = -1;
  switch(simbol) {
    case '0': fontNumber = 0;     break;
    case '1': fontNumber = 8;     break;
    case '2': fontNumber = 16;    break;
    case '3': fontNumber = 24;    break;
    case '4': fontNumber = 32;    break;
    case '5': fontNumber = 40;    break;
    case '6': fontNumber = 48;    break;
    case '7': fontNumber = 56;    break;
    case '8': fontNumber = 64;    break;
    case '9': fontNumber = 72;    break;
    case ' ': fontNumber = 80;    break;
    case '!': fontNumber = 88;    break;
    case '"': fontNumber = 96;    break;
    case '#': fontNumber = 104;   break;
    case '$': fontNumber = 112;   break;
    case '%': fontNumber = 120;   break;
    case '&': fontNumber = 128;   break;
    case '`': fontNumber = 136;   break;
    case '(': fontNumber = 144;   break;
    case ')': fontNumber = 152;   break;
    case '*': fontNumber = 160;   break;
    case '+': fontNumber = 168;   break;
    case ',': fontNumber = 176;   break;
    case '-': fontNumber = 184;   break;
    case '.': fontNumber = 192;   break;
    case '/': fontNumber = 200;   break;
    case '@': fontNumber = 208;   break;
    case 'A': fontNumber = 216;   break;
    case 'B': fontNumber = 224;   break;
    case 'C': fontNumber = 232;   break;
    case 'D': fontNumber = 240;   break;
    case 'E': fontNumber = 248;   break;
    case 'F': fontNumber = 256;   break;
    case 'G': fontNumber = 264;   break;
    case 'H': fontNumber = 272;   break;
    case 'I': fontNumber = 280;   break;
    case 'J': fontNumber = 288;   break;
    case 'K': fontNumber = 296;   break;
    case 'L': fontNumber = 304;   break;
    case 'M': fontNumber = 312;   break;
    case 'N': fontNumber = 320;   break;
    case 'O': fontNumber = 328;   break;
    case 'P': fontNumber = 336;   break;
    case 'Q': fontNumber = 344;   break;
    case 'R': fontNumber = 352;   break;
    case 'S': fontNumber = 360;   break;
    case 'T': fontNumber = 368;   break;
    case 'U': fontNumber = 376;   break;
    case 'V': fontNumber = 384;   break;
    case 'W': fontNumber = 392;   break;
    case 'X': fontNumber = 400;   break;
    case 'Y': fontNumber = 408;   break;
    case 'Z': fontNumber = 416;   break;
    case '[': fontNumber = 424;   break;
    case '|': fontNumber = 432;   break;
    case ']': fontNumber = 440;   break;
    case '^': fontNumber = 448;   break;
    case '_': fontNumber = 456;   break;
    //case '`': fontNumber = 464;   break;
    case 'a': fontNumber = 472;   break;
    case 'b': fontNumber = 480;   break;
    case 'c': fontNumber = 488;   break;
    case 'd': fontNumber = 496;   break;
    case 'e': fontNumber = 504;   break;
    case 'f': fontNumber = 512;   break;
    case 'g': fontNumber = 520;   break;
    case 'h': fontNumber = 528;   break;
    case 'i': fontNumber = 536;   break;
    case 'j': fontNumber = 544;   break;
    case 'k': fontNumber = 552;   break;
    case 'l': fontNumber = 560;   break;
    case 'm': fontNumber = 568;   break;
    case 'n': fontNumber = 576;   break;
    case 'o': fontNumber = 584;   break;
    case 'p': fontNumber = 592;   break;
    case 'q': fontNumber = 600;   break;
    case 'r': fontNumber = 608;   break;
    case 's': fontNumber = 616;   break;
    case 't': fontNumber = 624;   break;
    case 'u': fontNumber = 632;   break;
    case 'v': fontNumber = 640;   break;
    case 'w': fontNumber = 648;   break;
    case 'x': fontNumber = 656;   break;
    case 'y': fontNumber = 664;   break;
    case 'z': fontNumber = 672;   break;
    case '{': fontNumber = 680;   break;
    //case '\': fontNumber = 688;   break;
    case '}': fontNumber = 696;   break;
    case '~': fontNumber = 704;   break;
    case ':': fontNumber = 712;   break;
    case ';': fontNumber = 720;   break;
    case '<': fontNumber = 728;   break;
    case '=': fontNumber = 736;   break;
    case '>': fontNumber = 744;   break;
    case '?': fontNumber = 752;   break;
  }
  return fontNumber;
}

// вывод одного символа 8х8
void print_font8x8 (uint8_t line, uint8_t column, char simbol) {
    int16_t fontNumber = charToFonts(simbol);
    if(fontNumber < 0) return;
    
    for(int16_t i = 0; i < 8; i++) {
      SD1306_buffer[(column*8 + line*128 + i)] = pgm_read_byte(&fonts8x8[fontNumber + i]);
    }
}

// вывод строки из символов 8х8 на экран
void print_str8x8 (uint8_t line, uint8_t column, uint8_t *buff) {
    while(*buff != 0x00) {  // выводим, пока не закончится строка
      print_font8x8(line,column,*buff);
      buff += 1;
      column += 1;
      if(column >= 16) break; // или пока не закончится место на экране
    }
}

// вывод n значной цифры на ЖКИ, передние нули убираем
void print_int (uint8_t line, uint8_t column, int16_t data) {
  unsigned char lowNumber;  
  unsigned char n_digit = 0;
  char string_format[10];
  
  if(data < 0) {
    print_font8x8(line,column,'-');
    column += 1;
    data = abs(data);
  }
  if(data == 0) {
    print_font8x8(line,column,'0');
  }
  else {
    while(data > 0) {         
      lowNumber = data%10;
      string_format[n_digit] = 0x30+lowNumber;
      data = (data-lowNumber)/10;
      n_digit ++;
    }
    do {
      n_digit--;
      print_font8x8(line,column,string_format[n_digit]);
      column += 1;
    } while(n_digit > 0); 
    
  }
}

// специальные графические элементы
// батарейка

void batareyPrint(uint8_t batarey_voltage) {
  drawRectangle(110,5,127,31,BLUE);  // внешний контур батарейки
  drawRectangle(114,0,124,5,BLUE);  // верхний "плюс" батарейки
  drawHLine(110, 13, 18, BLUE);  // делим батарейку на три сектора
  drawHLine(110, 22, 18, BLUE);
  
  // заполненные сектора батарейки
  switch(batarey_voltage) {
    case 0: // батарейка пуста
    
    break;
    case 1: // батарейка 1/3
    drawFillRectangle(112,24,125,29,BLUE);
    break;
    case 2: // батарейка 2/3
    drawFillRectangle(112,15,125,20,BLUE);
    drawFillRectangle(112,24,125,29,BLUE);
    break;
    case 3: // батарейка 3/3
    drawFillRectangle(112,7,125,11,BLUE);
    drawFillRectangle(112,15,125,20,BLUE);
    drawFillRectangle(112,24,125,29,BLUE);
    break;
  }
}

// один шестиугольник, x,y - координаты центра
void sequinsPrint (uint8_t x, uint8_t y, float sizeFactor, uint8_t sequinsState) {
  uint8_t factor1 = 9*sizeFactor;
  uint8_t factor2 = 16*sizeFactor;
  uint8_t factor3 = 18*sizeFactor;
  drawLine(x-factor1, y+factor2, x+factor1, y+factor2, BLUE);
  drawLine(x+factor1, y+factor2, x+factor3, y, BLUE);
  drawLine(x+factor3, y, x+factor1, y-factor2, BLUE);
  drawLine(x+factor1, y-factor2, x-factor1, y-factor2, BLUE);
  drawLine(x-factor1, y-factor2, x-factor3, y, BLUE);
  drawLine(x-factor3, y, x-factor1, y+factor2, BLUE);
  
}

  /*
  drawPixel(1,1,BLUE);    // левый верхний угол
  drawPixel(127,1,BLUE);  // правый верхний угол
  drawPixel(1,31,BLUE); // левый нижний
  drawPixel(127,31,BLUE); // правый нижний
    */
