Just for fun, this is a version of Microsoft BASIC 4.7 modified to run
on the calculator.  Originally for NASCOM computers, modified by
Grant Searle for his "7-chip Z80 computer" (see http://searle.wales).
Further modified by me to work with the bit-bang serial interface on
the Retro-25.

Memory info (Grant's version):

`int32k.asm` is a small monitor which handles the serial port
and basic initialization.  `bas32k.asm` is the BASIC interpreter.
```
-------------------- int32k memory --------------------

  0000       DI
             JP     INIT      ; 00B8
  0008       JP     TXA       ; RST08 - serial TX
  0010       JP     RXA       ; RST10 - serial RX
  0018       JP     CKINCHAR  ; RST18 - check serial status
  0038       JR     serialInt ; RST38 - hardware interrupt
  
  003A serialInt:
  0074 RXA:
  009F TXA:
  00AA CKINCHAR:
  00B0 PRINT:   ; print a string
  
  00B8 INIT:  ; initialize serial, print message, jump to either
              ; $150 (cold) or $153 (warm)
			  
  0144 END
  
  8000 serBuf       ; serial buffer of 3FH bytes
  803F
   ...              ; other local variables
  8044   
  
  80ED TEMPSTACK    ; temporary stack location
  
  -------------------- BASIC memory map --------------------
  
  0150 ORG
  0150          JP STARTB
  0153          JP WARMST
  0156 STARTB:  LD IX,0
                JP CSTART
				...
  0160 CSTART:  LD HL,WRKSPC   ; copy init table to 8045H
                LD B,INITBE-INITAB+3
				LD DE,INITAB
	   COPY:    ...
	   
```

Strategy for porting BASIC:

Code runs from 0150 to 1DB3

Include serial I/O code 
Load the code starting at 8150H so currently would end at 9DB3 (plus serial code)

Apparently the only thing needed to change for RAM size is WRKSPC, as in
Grant's version the 56K BASIC has `WRKSPC .EQU 2045H` and the 32K BASIC has
`WRKSPC .EQU 8045H`.  
