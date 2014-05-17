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
;;;;;; MACROS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;fdasfsafdsa

bre            macro   file,number,Label
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



;checkKey - sends the PC to the specified lables depending on the keypadValue
;keypadValue - a file that keeps result of the PORTB
;
;
checkKey        macro   keypadValue,labelIGNORE,label1,label2,label3,label4,labelSTART
                local   temp_
                local   go1
                local   go2
                local   go3
                local   go4
                local   goSTART
                movwf   temp_
                movf    keypadValue,WREG
                btfss   WREG,1  ; has any key been presseed?
                goto    Ignore  ; no
                swapf   WREG,WREG    ; yes
                andlw   b'00001111'
                bre     WREG,0x0,go1
                bre     WREG,0x1,go2
                bre     WREG,0x2,go3
                bre     WREG,0xE,goSTART
                movf    temp_,WREG              ; if not one of special keys
                goto    labelIgnore
go1             movf    temp_,WREG
                goto    label1
go2             movf    temp_,WREG
                goto    lable2
go3             movf    temp_,WREG
                goto    label3
goSTART         movf    temp_,WREG
                goto    labelSTART
                endm
;CheckKey        macro       number,NoKey,Key,OtherKey
 ;               local       temp_
  ;              move        keypressResult,temp_
   ;             btfss       temp_,1
    ;                goto    NoKey
     ;           swapf       temp_,W
      ;          andlw       0xF        ; I don't know why it makes a difference, but it does :O
       ;         brwe        number, Key
        ;        goto        OtherKey
         ;       endm




             

;;;;;; VARIABLE+CONSTANT DEFINITIONS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
#define         Ser1        LATA,0
#define         Ser2        LATA,1
                cblock
                    delay1
                    delay2
                    pulse
                    pulseTemp
                    multiplier
                    multTemp
                    direction
                    temporary
                endc


;;;;;; VECTORS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            ORG         0x0000
            goto        main

            ORG         0x0008
            call        ISR_High

            ORG         0x018
            call        ISR_Low
;;;;;; ISR's ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ISR_High    retfie
ISR_Low     retfie
;;;;; MAIN PROGRAM ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
main        
            clrf     INTCON         ;Turn off interrupts
            clrf     TRISA          ; All ports are completely output

            movlw    0x0F           ;Turn off A/D conversion
            movwf    ADCON1

            ;Initialize all ports to 0
            clrf        LATA
;            movlw       0x10
 ;           movwf       pulse
  ;          movwf       multiplier
   ;         movlw       2
    ;        movwf       direction
            
branch      call        SerSinglePulse
            goto        branch

;;;; SUBROUTINES ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
;******************************************************************
delay20ms       call        delay5ms
                call        delay5ms
                call        delay5ms
                call        delay5ms
                return
;******************************************************************
delay100ms      call        delay5ms
                call        delay5ms
                call        delay5ms
                call        delay5ms
                call        delay5ms
                call        delay5ms
                call        delay5ms
                call        delay5ms
                call        delay5ms
                call        delay5ms
                call        delay5ms
                call        delay5ms
                call        delay5ms
                call        delay5ms
                call        delay5ms
                call        delay5ms
                call        delay5ms
                call        delay5ms
                call        delay5ms
                call        delay5ms
                return
;**************************************************************************


delay5ms        movlw       0xC2
                movwf       delay1,0
                movlw       0x0A
                movwf       delay2,0
Delay5msLoop    decfsz      delay1,f
                bra         d2
                decfsz      delay2,f
d2              bra         Delay5msLoop
                return

                END
