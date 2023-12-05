; export symbols
            XDEF Entry, _Startup            ; export 'Entry' symbol
            ABSENTRY Entry        ; for absolute assembly: mark this as application entry point
; Include derivative-specific definitions 
		INCLUDE 'derivative.inc' 
ROMStart    EQU  $4000  ; absolute address to place my code/constant data
; variable/data section
            ORG RAMStart
; Insert here your data definition.
m1analog: DS.B  1
m2analog: DS.B  1
deltaX: DS.B  1
; code section
            ORG   ROMStart
Entry:
_Startup:
            LDS   #RAMEnd+1                        ;initialize the stack pointer
            CLI                                            ;enable interrupts
            
SPIinit:
            ;initialize Serial Peripherals Interface
            LDAA  #%01011100                      ;enable SPI, HCS12 as Master, mode 3 
            STAA  SPICR1
            LDAA  #%00000010                      ;set baud rate 1MHz
            STAA  SPIBR
            LDAA  #%00010000                      ;enable SS output on portM, bidirectional i/o off, Master 
            STAA  SPICR2
            
portInit:
            ;make portT input port
            LDAA  #%11111100                      ;scroll encoder => ptt
            STAA  DDRT
            LDAA  #%00000000                      ;reset previous data
            STAA  PTT 
            ;enable pull down resistors port T 
            LDAA  #%11111111
            STAA  PERT
            LDAA  #%11111111
            STAA  PPST
            ;enable port M SPI lines
            LDAA  #%00111000
            STAA  DDRM
            LDAA  #%00000000
            STAA  PTM                                 ;clear existing data
            ;enable port A0 output for SS line
            LDAA  #%00000001
            STAA  DDRA
            LDAA  #%00000000
            STAA PORTA
            
ATDinit: 
            ;initialize ATD converter module
            LDAA  #%11000000                      ;powers the ATD, clear flags, disable interrupts by atd
            STAA  ATDCTL2                    
            LDAA  #%00010000                      ;2 conversions per sequence, FIFO, background debug off
            STAA  ATDCTL3
            LDAA  #%10000000                      ;8 bit resolution, 2 cycles sample time, 2MHz clock
            STAA  ATDCTL4   
                 
;||||||||||||||||||||||||||||||||   MAIN   ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||            
mainLoop:
            ;start the ATD conversion sequence:
            LDAA  #%10110000
            STAA  ATDCTL5
            
            ;read/write from SPI sensor: 
            LDAA  #%00000000
            STAA  PORTA                               ;drive NCS low
            
            ;reading and writing data to motion sensor part
SPIdataio:
            ;requesting data from sensor by sending address
            LDAA  #%00000000                      ;register address on motion sensor
            STAA  SPIDR                               ;MSB (0) indicates read operation
            
            ;Analog to Digtal value conversion part
spinATD:
            ;polling status register if complete:
            BRCLR ATDSTAT0, mATDSTAT0_SCF, spinATD
            
            ;read analog input for button1
            LDAA  ATDDR0L
            STAA  m1analog                           ;store digital data for m1 in ram
            
            ;read analog input for button2            
            LDAA  ATDDR1L
            STAA  m2analog                           ;store digital data for m1 in ram
            
            ;wait for data in shift register to be transferred
spinMISO:
            BRCLR SPISR,  mSPISR_SPIF, spinMISO 
            ;done:
            LDAA  SPISR                               ;clear status reg
            LDAA  SPIDR                               ;read data => RAM
            STAA  deltaX
            
            ;transmission done:
            LDAA  #%00000001                     ;reset, drive NCS high
            STAA  PORTA
            
            
            
            BRA mainLoop
;**************************************************************
;*                 Interrupt Vectors                          *
;**************************************************************
            ORG   $FFFE
            DC.W  Entry           ; Reset Vector