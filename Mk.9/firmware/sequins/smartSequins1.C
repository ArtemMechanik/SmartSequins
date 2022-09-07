
#include	"extern.h"

// H-bridge pins
#define AP 7
#define AN 5
#define BP 3
#define BN 6

// motor operating modes
#define STOP     0
#define FORWRD   1
#define BACKWARD 2

#define DEADTIME 	5
#define PHASE_DEL 	20

// stepper control variable
BYTE motorDirection = STOP;
BYTE stepperPhase[10]; 
WORD pntStart, pntEND, phaseCounter;
BYTE delValue = DEADTIME;
BYTE stepCounter = 0;

// decoder variable
BYTE algoritmStep		= 0;
BYTE timerReset			= 0;
WORD erorrTime			= 500;
WORD startTime			= 275; // correct for wake-up time
WORD stopTime			= 300;
BYTE sequnsStateTime	= 200;
WORD timerCounter		= 0;

// sequin
BYTE sequinStatePrev = 0;
BYTE sequinState = 0;
BYTE dataInState = 0;
BYTE dataOutState = 0;
BYTE changeComplite	 = 1;

void	FPPA0 (void)
{
	.ADJUST_IC	SYSCLK=IHRC/2, IHRC=16MHz, Init_RAM	

	

	// pin state for all phase of step
	stepperPhase[1] = (0<<AP)|(0<<AN)|(1<<BN)|(0<<BP);
	stepperPhase[2] = (0<<AP)|(1<<AN)|(1<<BN)|(0<<BP);
	stepperPhase[3] = (0<<AP)|(1<<AN)|(0<<BN)|(0<<BP);
	stepperPhase[4] = (0<<AP)|(1<<AN)|(0<<BN)|(1<<BP);
	stepperPhase[5] = (0<<AP)|(0<<AN)|(0<<BN)|(1<<BP);
	stepperPhase[6] = (1<<AP)|(0<<AN)|(0<<BN)|(1<<BP);
	stepperPhase[7] = (1<<AP)|(0<<AN)|(0<<BN)|(0<<BP);
	stepperPhase[8] = (1<<AP)|(0<<AN)|(1<<BN)|(0<<BP);

	// we can't write: stepperPhase[phaseCounter], will be a compilation error
	// therefore, we use pointers
	pntStart = & stepperPhase[0];
	pntEND = & stepperPhase[9];
	phaseCounter = pntStart+1;

	MISC	= 0b00100000; // enable fast wake-up MISC.5 = 1
	GPCC.7	= 0;			// comparator disable
	INTEN 	= 0b00000000;	// disable all interrupt

	PADIER	= 0b00000000;	// disable all wake-up event from portA
	PA		= 0b00000000;
	PAC 	= 0b11111000;	// PA4 - data out	
	PAPH	= 0b00010000;	

	PBDIER 	= 0b00000001; 	// wake-up event from PB.0
	PB		= 0b00000000;
	PBC		= 0b00000000;	// PB0 - data in
	PBPL	= 0b00000001;	// PB0 pull-low 

	// timer 2 setup
	TM2S 	= 0b01111111;	// 8 bit, prescaller = 64, scalar = 32
	TM2C	= 0b00010001;	// source = system clock, output = disable, period mode
	TM2CT	= 0;
	TM2B	= DEADTIME;

	// timer 16 setup
	T16M 	= 0b00111000;	// source = system clock, prescaller = 64 => F_timer = 125000Hz, value ldt16 = 125 = 1mS delay

	INTEN	= 0b01000000;	// timer2 interrupt, external interrupt PB.0 an all logical change
	INTEGS	= 0b00000000;

	ENGINT;	// global interrupt enable 

	while (1)
	{
		// sleep mode enter
		if((algoritmStep == 0) && (changeComplite == 1))
		{
			STOPSYS;
			// wake-up time = 700uS
		}

		// check data in pin
		if(PB.0 == 0) {
			dataInState = 0;
		}
		else {
			dataInState = 1;
		}

		timerReset = 0;
		switch(algoritmStep) {
			case 0:
				timerReset = 1;
				if(dataInState == 1)
				{
					algoritmStep = 1;
				}
			break;

			case 1:
				if(timerCounter > erorrTime) {
					algoritmStep = 0;
				}
				if(dataInState == 0)
				{
					algoritmStep = 0;
					if(timerCounter > startTime) {
						algoritmStep = 2;
						timerReset = 1;
					}
				}
			break;

			case 2:
				dataOutState = 1;
				if(timerCounter > sequnsStateTime) {
					algoritmStep = 3;
				}
			break;

			case 3:
				if(dataInState == 1) {
					sequinState = 1;
				}
				else {
					sequinState = 0;
				}
				algoritmStep = 4;
			break;

			case 4:
				if(dataInState == 0) {
					if(timerCounter > startTime) {
						timerReset = 1;
						algoritmStep = 5;
					}
				}
				if(timerCounter > erorrTime) {
					algoritmStep = 0;
					sequinState =  sequinStatePrev;
				}
			break;

			case 5:	
				if(dataInState == 1) {
					dataOutState = 1;
					timerReset = 1;
				}
				else {
					dataOutState = 0;
				}

				if(timerCounter > stopTime) {
					algoritmStep = 0;
				}
			break;
			
		}

		// data out control
		if(dataOutState == 1) {
			PA.4 = 1;
		}
		else {
			PA.4 = 0;
		}

		// timer
		if(timerReset == 1) {
			timerCounter = 0;
			stt16 timerCounter;
			nop;	// between commands stt16 and ldt16 need delay
		}

		ldt16 timerCounter;

		// change sequin color
		if(sequinState != sequinStatePrev) {
			if(sequinState == 1) {
				motorDirection = FORWRD;
			}
			else {
				motorDirection = BACKWARD;
			}
			stepCounter = 50;

			sequinStatePrev = sequinState;
		}
	
		
	}
}


void	Interrupt (void)
{
	pushaf;

	//PA.6 = 1; // strob ON
	// timer 2 interrupt drive stepper motor
	if (Intrq.TM2)
	{	
		
		// repeat while step counter > 0
		if(stepCounter == 0) 
		{			
			changeComplite = 1;
			motorDirection = STOP;
			PA = (PA & 0b00010111);
		}
		else
		{
			if(motorDirection == FORWRD) 
			{
				phaseCounter += 1;
			}
			else if(motorDirection == BACKWARD)
			{
				phaseCounter -= 1;
			}

			// phase control
			if(phaseCounter == pntStart) 
			{
				phaseCounter = pntEND - 1;
			}
			else if(phaseCounter == pntEND)
			{ 
				phaseCounter = pntStart + 1; 
			}

			// delay control
			if(delValue == DEADTIME)
			{
				delValue = PHASE_DEL;
			}
			else if(delValue == PHASE_DEL)
			{
				delValue = DEADTIME;
			}
			TM2B = delValue; 

			// curent step send on pins
			PA = (PA & 0b00010111) | (*phaseCounter);

			stepCounter -= 1;

			changeComplite = 0;
			
		}
		
		
		Intrq.TM2 =	0;
		
		
	}

	// PB0 use fo interface
	if (Intrq.PB0)
	{	
		// falling edge
		Intrq.PB0	=	0;
	}

	//PA.6 = 0;	// strob OFF

	popaf;
}

