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

unsigned char volatile current_step = 0; // ������� ��� ����� �������
unsigned char volatile time_counter  = 0; // ������� �������

unsigned char volatile sequinse_state = 0; // ��������� �������
unsigned char volatile sequinse_state_previous = 0;

unsigned char volatile sleep_FLAG = 0;

ISR (INT0_vect) {
	
	if(sleep_FLAG==1) {						// ���� ��� ���������� �� ������� ������, �� ��������������� ����������
		GIMSK = (1<<INT0);
		MCUCR = (0<<ISC01)|(1<<ISC00);		// ����������� ���������� � ����� ������������ ����� ����������� �����
		sleep_FLAG = 0;						// ���������� ���� ������ ���
	}
	
	switch(current_step) {
		case 0:
			if(!(PINB&(1<<IN_PIN))) {		// ����� ���������� ����� ������ �������
				TCNT0 = 0;					// ��������� ������� ���������� �������, ��������� �� ����������� ������
				TIMSK0 |= (1<<OCIE0A);
				time_counter = 0;
				current_step = 1;
			}
		break;
		case 1:								// ���������� ����� ������� ���� �������		
			if(time_counter > 3) {			// ���� ��������� ������ �� ������, �� ��� ������ �������
				TCNT0 = 0;							
				TIFR0 = (1<<OCF0A);
				time_counter = 0;
				OUT_LOW;
				current_step = 2;
			}
			else current_step = 5;			// ���� ��� ����� �� ������, �� ��� ������
		break;
		case 2:								// ���������� ����� ������� ���� �������
			if(time_counter == 1) {			// ���������� ������������ ������� ����
				sequinse_state = 0;
			}
			else {
				sequinse_state = 1;
			}
			current_step = 4;
		break;
		case 4:								// ��������� ���� ������� ��� ���������
			if(!(PINB&(1<<IN_PIN))) OUT_LOW;	
			else					OUT_HIGH;
			time_counter = 0;				// ���� ������� ���, �� ���������� �������
		break;
		case 5:
			TIMSK0 &=(~(1<<OCIE0A));
			OUT_HIGH;						// ������ �� ����� ������� �������, ����� ��������� ������� ����� �����
			current_step = 0;
			sleep_FLAG = 1;
		break;
	}
}

ISR (TIM0_COMPA_vect) {
	time_counter++;
	if(time_counter > 15) {					// ���� ������� ����� ������ �� ����������, �� ������ ��� ����� �������� ��� ������, ������� ���������� ��������� ����� ������ 
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

void INT0_interrupt_setup_awakening (void) {	// ��������� ���������� ��� �����������
	MCUCR = (0<<ISC00);							// ����������� ���������� �� INT0 ����� ���������� �� LOW_LEVEL
	GIMSK = (1<<INT0);							// �������� ���������� INT0, ����� ����������
	MCUCR = (1<<SM1)|(1<<SE);					// ����� power-down
}


void Timer0_setup (void) {																// ������� ������������� ������� 0 ��� �������� ��������� ����������� � ������������� ����������
	TCCR0A = (0<<COM0A1)|(0<<COM0A0)|(0<<COM0B1)|(0<<COM0B0)|(1<<WGM01)|(0<<WGM00);		// ����� CTC, ���� ��������� �� �������, ������� ������ ������� OCR
	TCCR0B = (0<<CS00)|(0<<CS01)|(1<<CS02)|(0<<WGM02);									// ������������ 256
	OCR0A = 32;																			// ����������� ������ �� 1���	
	//TIMSK0 |= (1<<OCIE0A);																// ���������� ���������� �� ����������
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
	PORTB &=(~((1<<DIR_PIN)|(1<<STEP_PIN)));	// ����� ������� ����
	
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

