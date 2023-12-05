            XDEF Entry, _Startup            ; export 'Entry' symbol
            ABSENTRY Entry        ; for absolute assembly: mark this as application entry point



; Include derivative-specific definitions 
		INCLUDE 'derivative.inc' 

ROMStart    EQU  $4000  ; absolute address to place my code/constant data

; variable/data section

            ORG RAMStart
 ; Insert here your data definition.
 xhigh: DS.B 1
 xlow:  DS.B  1
; code section
            ORG   ROMStart


Entry:
_Startup:
            LDS   #RAMEnd+1       ; initialize the stack pointer
            CLI                     ; enable interrupts
            
;spi setup
            LDAA  #%00000001
            STAA  DDRA
            LDAA  #%00000000
            STAA  PORTA
            
            ;spi master
            LDAA  #mSPICR1_SPE | mSPICR1_MSTR
            STAA  SPICR1
            
            ;baudrate
            LDAA  #$02
            STAA  SPIBR

mainLoop:
            LDAA  #$0
            STAA PORTA
            
            LDAA  #$06
            STAA  SPIDR
            
spinreadxh:
            BRCLR SPISR, mSPISR_SPIF, spinreadxh
            
            nop
            nop
            
            LDAA  SPISR
            LDAA  SPIDR
            STAA  xhigh
           
            nop
            nop 
            
            LDAA  #$05
            STAA  SPIDR
            
spinreadxl:
            BRCLR SPISR, mSPISR_SPIF, spinreadxl
            
            nop
            nop
            
            LDAA  SPISR
            LDAA  SPIDR
            STAA  xlow
           
            nop
            nop 
             
            BRA mainLoop
          
;**************************************************************
;*                 Interrupt Vectors                          *
;**************************************************************
            ORG   $FFFE
            DC.W  Entry           ; Reset Vector
