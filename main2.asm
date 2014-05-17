            #include <p18f4620.inc>
           
            list P=18F4620, F=INHX32, C=160, N=80, ST=OFF, MM=OFF, R=DEC

            CONFIG OSC=HS, FCMEN=OFF, IESO=OFF
            CONFIG PWRT = OFF, BOREN = SBORDIS, BORV = 3
            CONFIG WDT = OFF, WDTPS = 32768
            CONFIG MCLRE = ON, LPT1OSC = OFF, PBADEN = OFF, CCP2MX = PORTC
            CONFIG STVREN = ON, LVP = OFF, XINST = OFF
            CONFIG DEBUG = OFF
            CONFIG CP0 = OFF, CP1 = OFF, CP2 = OFF, CP3 = OFF
            CONFIG CPB = OFF, CPD = OFF
            CONFIG WRT0 = OFF, WRT1 = OFF, WRT2 = OFF, WRT3 = OFF
            CONFIG WRTB = OFF, WRTC = OFF, WRTD = OFF
            CONFIG EBTR0 = OFF, EBTR1 = OFF, EBTR2 = OFF, EBTR3 = OFF
            CONFIG EBTRB = OFF
;;;;;; MACROS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

bre             macro   file,number,Label
                local   end_Eq
                local   end_NOT_Eq
                movf    file,WREG
                sublw   number
                xorlw   B'00000000'
                btfsc   STATUS,Z
                    goto    end_Eq
                goto    end_NOT_Eq
end_Eq          addlw   number
                goto    Label
end_NOT_Eq      subwf   number
                endm

; Uses WREG - does not change it
checkIfKey          macro   number,label
                    local   temp
                    local   labelGO
                    local   labelIgnore
                    clrf    temp
                    btfss   WREG,1  ; has any key been presseed?
                    goto    labelIgnore  ; no
                    swapf   WREG,temp    ; yes
                    bre     temp,number,labelGO
                    goto    labelIgnore
labelGO             goto    label
    
labelIgnore         nop
                    endm


;;;;;; VARIABLE+CONSTANT DEFINITIONS ********************************************
#define         Ser1        LATA,0
#define         Ser2        LATA,1
#define         RS      LATD,2
#define         E       LATD,3
                cblock  0x20
                    month
                    date
                    
                    temp_lcd    ;buffer for Instruction
                    dat         ;buffer for data
                    delay1
                    delay2
                    pulse
                    pulseTemp
                    multiplier
                    multTemp
                    direction
                    temporary
                endc


;;;;;; VECTORS ***********************************************************
            ORG         0x0000
            goto        main

            ORG         0x0008
            call        ISR_High

            ORG         0x018
            call        ISR_Low

;;;;;;TABLES ***********************************************************




;;;;;; ISR's ************************************************************
ISR_High    retfie
ISR_Low     retfie

;;;;; MAIN PROGRAM ******************************************************
main        
                clrf     INTCON         ;Turn off interrupts
                clrf     TRISA          ; All ports are completely output
                clrf     TRISC
                clrf     TRISD
                clrf        LATA
                clrf        LATC
                clrf        LATD
                movlw    0x0F           ;Turn off A/D conversion
                movwf    ADCON1

                movlw       1
                movwf       date
                movwf       month
                
                ;Initialize all ports to 0
                call        SETUP_LCD
ReadTable       movlw       upper Date     ;load the Table Pointer
                movwf       TBLPTRU         ;with full address of Table
                movlw       high Date
                movwf       TBLPTRH
                movlw       low Date
                movwf       TBLPTRL
                tblrd*      ;read the first Table entry into TABLAT
                movf        TABLAT,WREG
Again           call        WR_DATA     ;Write to LCD
                tblrd+*                 ;Increment TBLPTR then read
                movf        TABLAT,WREG
                bnz         Again
Stop            goto        Stop        ; end of program

;;;; SUBROUTINES *********************************************************
;; 4 bits, 2 lines, 5x7 dot
SETUP_LCD       call        delay5ms
                call        delay5ms
                movlw       B'00110011'
                call        WR_INS
                movlw       B'00110010'
                call        WR_INS
                movlw       B'00101000'
                call        WR_INS
                movlw       B'00001100'
                call        WR_INS
                movlw       B'00000110'     ;Entry mode
                call        WR_INS
                movlw       B'00000001'      ;clear ram
                call        WR_INS
                return
WR_INS          bcf         RS          ; clear register status bit
                movwf       temp_lcd    ;store instruction
                andlw       0xF0
                movwf       LATD
                bsf         E
                swapf       temp_lcd,WREG
                andlw       0xF0
                bcf         E
                movwf       LATD
                bsf         E
                nop
                bcf         E
                call        delay5ms
                return
WR_DATA         bcf         RS
                movwf       dat
                movf        dat,WREG
                andlw       0xF0
                addlw       4
                movwf       PORTD
                bsf         E
                swapf       dat,WREG
                andlw       0xF0
                bcf         E
                addlw       4
                movwf       PORTD
                bsf         E
                nop
                bcf         E
                call        delay44us
                return
delay44us       movlw       0x23
                movwf       delay2,0
Delay44usLoop   decfsz      delay1,f
                bra         Delay44usLoop
                return

                


;Modifies Ser1 and Ser2 pin outputs - sends 1 pulse and waits 20ms
;Input:
;   pulse: duration of the pulse in weird units: refer to notebook)
;   direction: 1 - operates Ser1, otherwise - operates Ser2
;Preconditions: will work only if needed Ser# is output
;               does not handle negative pulse and less than 1 multiplier
SerSinglePulse  movwf       temporary
                movf        pulse,WREG
                movwf       pulseTemp
                movf        multiplier,WREG
                movwf       multTemp

                bre         direction,2,set2
set1            bsf         Ser1
                goto        loop
set2            bsf         Ser2
                goto        loop

loop            decfsz      pulseTemp
                goto        loop
                movf        pulse,WREG
                movwf       pulseTemp         
                decfsz      multTemp
                goto        loop

          
                bre         direction,2,clear2

clear1          bcf         Ser1
                goto        finish
clear2          bcf         Ser2

finish          call        delay20ms
                movf        temporary,WREG
                return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
delay20ms       call        delay5ms
                call        delay5ms
                call        delay5ms
                call        delay5ms
                return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


delay5ms        movlw       0xC2
                movwf       delay1,0
                movlw       0x0A
                movwf       delay2,0
Delay5msLoop    decfsz      delay1,f
                bra         d22
                decfsz      delay2,f
d22              bra         Delay5msLoop
                return


                END