/*
 * SmartSequinse8.c
 *
 * Created: 07.07.2021 8:11:35
 * Author : brazhnikov
 */ 
#define F_CPU 9600000UL
#define BITRATE 1000

#include <avr/io.h>
#include <util/delay.h>
#include <avr/interrupt.h>

#define IN_PIN		PB1
#define OUT_PIN		PB2
#define EN_PIN		PB0
#define STEP_PIN 	PB3
#define DIR_PIN		PB4

#define DIR_FORWARD PORTB |=(1<<DIR_PIN)
#define DIR_BACK	PORTB &=(~(1<<DIR_PIN))

#define STEP_ON		PORTB |=(1<<STEP_PIN)
#define STEP_OFF	PORTB &=(~(1<<STEP_PIN))

#define EN_ON		PORTB |=(1<<EN_PIN)
#define EN_OFF		PORTB &=(~(1<<EN_PIN))

#define OUT_HIGH	PORTB |=(1<<OUT_PIN)
#define OUT_LOW		PORTB &=(~(1<<OUT_PIN))

unsigned char volatile current_step = 0; // текущий шаг приёма посылки
unsigned char volatile time_counter  = 0; // счётчик времени

unsigned char volatile sequinse_state = 0; // состояние пайетки
unsigned char volatile sequinse_state_previous = 0;

unsigned char volatile sleep_FLAG = 0;

ISR (INT0_vect) {
	
	if(sleep_FLAG==1) {						// если это прерывание из спящего режима, то перенастраиваем прерывание
		GIMSK = (1<<INT0);
		MCUCR = (0<<ISC01)|(1<<ISC00);		// переключаем прерывание в режим фиксирования смены логического уроня
		sleep_FLAG = 0;						// сьрасываем флаг режима сна
	}
	
	switch(current_step) {
		case 0:
			if(!(PINB&(1<<IN_PIN))) {		// ловим нисходящий фронт начала посылки
				TCNT0 = 0;					// готовимся считать количество времени, прошедшее от нисходящего фронта
				TIMSK0 |= (1<<OCIE0A);
				time_counter = 0;
				current_step = 1;
			}
		break;
		case 1:								// восходящий фронт первого бита посылки		
			if(time_counter > 3) {			// если отсчитали больше тёх тактов, то это начало посылки
				TCNT0 = 0;							
				TIFR0 = (1<<OCF0A);
				time_counter = 0;
				OUT_LOW;
				current_step = 2;
			}
			else current_step = 5;			// если три такта не прошло, то это ошибка
		break;
		case 2:								// нисходящий фронт первого бита посылки
			if(time_counter == 1) {			// определяем длительность первого бита
				sequinse_state = 0;
			}
			else {
				sequinse_state = 1;
			}
			current_step = 4;
		break;
		case 4:								// остальные биты передаём без изменений
			if(!(PINB&(1<<IN_PIN))) OUT_LOW;	
			else					OUT_HIGH;
			time_counter = 0;				// если приняли бит, то сбрасываем счётчик
		break;
		case 5:
			TIMSK0 &=(~(1<<OCIE0A));
			OUT_HIGH;						// держим на линии высокий уровень, чтобы остальные пайетки мирно спали
			current_step = 0;
			sleep_FLAG = 1;
		break;
	}
}

ISR (TIM0_COMPA_vect) {
	time_counter++;
	if(time_counter > 15) {					// если слишком долго ничего не происходит, то видимо это конец передачи или ошибка, поэтому сбрасываем процедуру приёма данных 
		current_step = 0;
		time_counter = 0;
		TCNT0 = 0;
		TIFR0 = (1<<OCF0A);
		TIMSK0 &=(~(1<<OCIE0A));
		
		OUT_HIGH;
		sleep_FLAG = 1;
	}
}
void pin_setup () {
	DDRB &=(~(1<<IN_PIN));
	PORTB |=(1<<IN_PIN);
	DDRB |=(1<<OUT_PIN);
	DDRB |=(1<<EN_PIN)|(1<<STEP_PIN)|(1<<DIR_PIN);

}

void delay_time_ms (unsigned int delay) {
	for(unsigned int i=0; i<delay; i++) {
		_delay_ms(1);
	}
}

void INT0_interrupt_setup_awakening (void) {	// настройка прерывания для пробуждения
	MCUCR = (0<<ISC00);							// настраиваем прерывание на INT0 чтобы проснуться на LOW_LEVEL
	GIMSK = (1<<INT0);							// включаем прерывание INT0, чтобы проснуться
	MCUCR = (1<<SM1)|(1<<SE);					// режим power-down
}


void Timer0_setup (void) {																// функция инициализации таймера 0 для контроля временных промежутков и генерирования прерываний
	TCCR0A = (0<<COM0A1)|(0<<COM0A0)|(0<<COM0B1)|(0<<COM0B0)|(1<<WGM01)|(0<<WGM00);		// режим CTC, пины отключены от таймера, верхний предел задаётся OCR
	TCCR0B = (0<<CS00)|(0<<CS01)|(1<<CS02)|(0<<WGM02);									// предделитель 256
	OCR0A = 32;																			// настраиваем таймер на 1КГц	
	//TIMSK0 |= (1<<OCIE0A);																// разрешение прерывания по совпадению
}

void motor_step (char direction, unsigned char step_value, unsigned int delay) {
	unsigned char step_counter;
	EN_ON;
	
	if(direction == 'F') DIR_FORWARD;
	if(direction == 'B') DIR_BACK;
	
	for(step_counter = 0; step_counter < step_value; step_counter ++) {
		STEP_ON;
		_delay_us(100);
		STEP_OFF;
		delay_time_ms(delay);
	}
	
	EN_OFF;

}

int main(void) {
	
	pin_setup();
	PORTB &=(~((1<<DIR_PIN)|(1<<STEP_PIN)));	// режим полного шага
	
	while (!(PINB&(1<<IN_PIN))) { _delay_us(10); }	

	Timer0_setup();
	
	INT0_interrupt_setup_awakening();

	sei();
	
	sleep_FLAG = 1;
	    
    while (1) {
		if(current_step == 0) {
			if(sequinse_state != sequinse_state_previous) {
				if(sequinse_state == 0) {
					motor_step('F',13,8);
				}
				else {
					motor_step('B',13,8);
				}
				sequinse_state_previous = sequinse_state;
			}
			
			if(sleep_FLAG == 1) {
				INT0_interrupt_setup_awakening();
				asm("sleep");
			}
		}
		
		/*
		motor_step('F',13,8);
		_delay_ms(1000);
		motor_step('B',13,8);
		_delay_ms(1000);
		*/
    }
}

