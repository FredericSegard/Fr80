; --------------------------------------------------------------------------------------------------------------
;         :::::::::     ::::::::       :::::::            :::::::::     :::::::::::     ::::::::       :::::::: 
;             :+:     :+:    :+:     :+:   :+:           :+:    :+:        :+:        :+:    :+:     :+:    :+: 
;           +:+      +:+    +:+     +:+   +:+           +:+    +:+        +:+        +:+    +:+     +:+         
;         +#+        +#++:++#      +#+   +:+           +#++:++#+         +#+        +#+    +:+     +#++:++#++   
;       +#+        +#+    +#+     +#+   +#+           +#+    +#+        +#+        +#+    +#+            +#+    
;     #+#         #+#    #+#     #+#   #+#           #+#    #+#        #+#        #+#    #+#     #+#    #+#     
;   #########     ########       #######            #########     ###########     ########       ########       
; ------------------------------------------------------------------------------------------------------

; *********************************************************************************************************************
; * Z80 Project, code nema Fre80 (Freddy) by Frédéric Segard, a.k.a. MicroHobbyist
; * https://www.youtube.com/@microhobbyist
; * https://github.com/FredericSegard
; *
; * Copyright (C) 2023 Frédéric Segard
; *
; * This library is free software; you can redistribute it and/or modify it under the terms of the GNU Lesser General
; * Public License as published by the Free Software Foundation. You can use all or part of the code, regardless of
; * the version. But there is no warrenty of any kind.
; *
; * Reference:	ASCII text: https://www.messletters.com/en/big-text/ (alligator, standard)
; *				Editor tab-stops set to 4
; *				Assembler: VASM  (BIN: vasmz80_oldstyle -dotdir -chklabels -nocase %1.asm -Fbin -o %1.out -L %1.txt)
; *								 (HEX: vasmz80_oldstyle -dotdir -chklabels -nocase %1.asm -Fihex)
; * Version 0.7
; *********************************************************************************************************************


;   ____                         _                     _         
;  / ___|   ___    _ __    ___  | |_    __ _   _ __   | |_   ___ 
; | |      / _ \  | '_ \  / __| | __|  / _` | | '_ \  | __| / __|
; | |___  | (_) | | | | | \__ \ | |_  | (_| | | | | | | |_  \__ \
;  \____|  \___/  |_| |_| |___/  \__|  \__,_| |_| |_|  \__| |___/
;
; ---------------------------------------------------------------------------------------------------------------------
; VARIOUS CONSTANTS AND ADDRESSES USED IN THE CODE

; GENERAL EQUATES
NULL			= $00
CTRLC			= $03				; Control-C (Break)
CTRLG			= $07				; Control-G (Bell)
BKSP			= $08				; Backspace
TAB				= $09				; Horizontal tab
LF				= $0A				; Line-feed character
CS				= $0C				; Clear Screen
CR				= $0D				; Carriage-return character
CTRLO			= $0F				; Control "O"
CTRLQ			= $11				; Control "Q"
CTRLR			= $12				; Control "R"
CTRLS			= $13				; Control "S"
CTRLU			= $15				; Control "U"
ESC				= $1B				; Escape
SPACE			= $20				; Space character
DEL				= $7F				; Delete

DELIMITER		= " "				; Space delimiter between command line parameters
ERRORPTR		= "^"				; Error pointer symbol (used for pointing to the error position on command line)
QUOTE			= $22
JUMP			= $C3				; Delimiter for command list items (It's the actual jp command opcode)
HELP			= $0F
EOT				= $FF				; End of table

;PARAMETERS
HorizTextRes	= 40				; Horizontal text resolution (40 or 80)
VertTextRes		= 24				; Vertical text resolution (typical 24 or 25)
ErrorPtrOffset	= 8					; Take into account the command prompt width
BytesFree		= (VectorTable-EndOfCode)+(StartOfCode-InterruptVectorEnd)	; Base free bytes

; I/O ADDRESSES
SIO_PortA_Data	= $00				; SIO data port A
SIO_PortB_Data	= $01				; SIO data port B
SIO_PortA_Ctrl	= $02				; SIO control port A
SIO_PortB_Ctrl	= $03				; SIO control port B

;SIO_PortA_Data	= $08				; SIO data port A
;SIO_PortB_Data	= $09				; SIO data port B
;SIO_PortA_Ctrl	= $0A				; SIO control port A
;SIO_PortB_Ctrl	= $0B				; SIO control port B

ClockSelect		= $28				; Clock speed selection address (values $00 to $03)
BankSelect		= $30				; RAM bank select address (values ($00 to $0E)
RomDisable		= $38				; ROM dissable address (any value)

; STATUS INDICATOR FLAGS (BIT NUMBER... 3 and 5 are not used
Carry			= 0					; (F) Carry flag
Negative		= 1					; (N) Add/substract flag
Parity			= 2					; (P) Parity flag (Same bit position as bellow, depends on the instruction)
Overflow		= 2					; (V) Overflow flag (Same bit position as above, depends on the instruction)
HalfCarry		= 4					; (H) Half-carry flag
Zero			= 6					; (Z) Zero flag
Sign			= 7					; (S) Sign flag


;  ___           _                                          _    __     __                _                        
; |_ _|  _ __   | |_    ___   _ __   _ __   _   _   _ __   | |_  \ \   / /   ___    ___  | |_    ___    _ __   ___ 
;  | |  | '_ \  | __|  / _ \ | '__| | '__| | | | | | '_ \  | __|  \ \ / /   / _ \  / __| | __|  / _ \  | '__| / __|
;  | |  | | | | | |_  |  __/ | |    | |    | |_| | | |_) | | |_    \ V /   |  __/ | (__  | |_  | (_) | | |    \__ \
; |___| |_| |_|  \__|  \___| |_|    |_|     \__,_| | .__/   \__|    \_/     \___|  \___|  \__|  \___/  |_|    |___/
;                                                  |_|                                                             
; ---------------------------------------------------------------------------------------------------------------------
; RESET AND INTERRUPT VECTORS (8-BYTE VECTORS EACH)

	.org	$0000
	
RST00:								; Reset vector 0: Standard boot up reset vector
	jp		ShadowCopy				; Shadow copy BIOS and vectors
	ds		$0008-$,$FF

RST08:								; Reset Vector 1
	halt
	ds		$0010-$,$FF

RST10:								; Reset Vector 2
	halt
	ds		$0018-$,$FF
	
RST18:								; Reset Vector 3
	halt
	ds		$0020-$,$FF

RST20:								; Reset Vector 4
	halt
	ds		$0028-$,$FF

RST28:								; Reset Vector 5
	halt
	ds		$0030-$,$FF

RST30:								; Reset Vector 6
	halt
	ds		$0038-$,$FF

RST38:								; Reset vector 7: Interrupt Mode 1
	halt
	ds		$0066-$,$FF

NMI66:								; Non-masquable interreupt vector
	halt
	ds		$0080-$,$FF

InterruptVectorEnd:


;  ____    _                   _                         ____                         
; / ___|  | |__     __ _    __| |   ___   __      __    / ___|   ___    _ __    _   _ 
; \___ \  | '_ \   / _` |  / _` |  / _ \  \ \ /\ / /   | |      / _ \  | '_ \  | | | |
;  ___) | | | | | | (_| | | (_| | | (_) |  \ V  V /    | |___  | (_) | | |_) | | |_| |
; |____/  |_| |_|  \__,_|  \__,_|  \___/    \_/\_/      \____|  \___/  | .__/   \__, |
;                                                                      |_|      |___/ 
; ---------------------------------------------------------------------------------------------------------------------
; SHADOW COPY VECTORS AND BIOS FROM FLASH TO RAM

ShadowCopy:
	di								; Disable interrupts
	
; COPY INTERRUPT VECTORS TO ALL BANKS
	ld		A,$0E					; Starting bank number
BankCopyLoop:						; Loop to copy reset vectors to all banks
	out		(BankSelect),A			; Sets bank number to value in accumulator
	; Perform vector copy
	ld      HL,$0000				; Set start at address $0000 (ROM)
	ld      DE,$0000				; Set destination address (RAM)
	ld      BC,InterruptVectorEnd	; Set counter to copy the interrupt vector table only
	ldir							; Copy, paste, and repeat, until the end of BC has been reached
	; Check for next iteration
	dec		A						; Decrement accumulator to move on to next bank
	cp		$FF						; Has accumulator reached the end of the loop (past zero)?
	jr		nz,BankCopyLoop			; If not then do next bank the loop, else Bank 0 is already pre-selected
	ld		(CurrentBank),A			; Save Current Bank

; COPY THE BIOS TO RAM
ROMCopy:
    ld      HL,StartOfCode			; Source address
    ld      DE,StartOfCode			; Destination address
    ld      BC,EndOfCode-StartOfCode; Bytes to copy
    ldir							; Copy, paste, and repeat, until the range has been reached

; COPY THE VECTORS AND BLANK STACK TO RAM
VectorCopy:
    ld      HL,VectorTable			; Source address
    ld      DE,VectorTable			; Destination address
    ld      BC,$FFFF-VectorTable	; Bytes to copy
    ldir							; Copy, paste, and repeat, until the range has been reached

	jp		StartOfCode

	ds		StartOfCode-$,$FF		; Fill the rest of memory to start of code with $FF for fast FLASH programming


;  ___           _   _     _           _   _              
; |_ _|  _ __   (_) | |_  (_)   __ _  | | (_)  ____   ___ 
;  | |  | '_ \  | | | __| | |  / _` | | | | | |_  /  / _ \
;  | |  | | | | | | | |_  | | | (_| | | | | |  / /  |  __/
; |___| |_| |_| |_|  \__| |_|  \__,_| |_| |_| /___|  \___|
;
; ---------------------------------------------------------------------------------------------------------------------
; START OF CODE

	.org	$8000					; Start of code at beginning of high memory

StartOfCode:
	out		(RomDisable),A			; Disable the ROM
	ld      SP,$FFFF				; Set top of stack pointer to page FF
	
	call	SIO_Init				; Initializes the SIO

	; Print Boot message with bytes free
	call	ClearScreen				; Clear the terminal screen (with ANSI codes)
	ld		HL,BootMsg
	call	PrintString				; Print first line of boot message
	call	PrintLine				; Print a separator line
	call	PrintString				; Print second line of boot message
	push	HL
	ld		HL,BytesFree			; Load the amount of bytes free
	call	PrintDec
	pop		HL
	call	PrintString

	ld		HL,$0000				; Set default current address
	ld		(CurrentAddress),HL		; Save in CurrentAddress variable
	ld		A,0
	out		(BankSelect),A			; Set the bank to number 0
	ld		(CurrentBank),A			; Save the Current Bank

	; Clear the registers
	ld		A,0
	ld		BC,0
	ld		DE,0
	ld		HL,0
	ld		IX,0
	ld		IY,0
	push	BC						; LSB to clear the flag
	pop		AF						; Clear flag

;	ei								; Enable interrupts


;  __  __           _         
; |  \/  |   __ _  (_)  _ __  
; | |\/| |  / _` | | | | '_ \ 
; | |  | | | (_| | | | | | | |
; |_|  |_|  \__,_| |_| |_| |_|
;
; ----------------------------
; MAIN LOOP

Main:
	call	CommandPrompt			; Print the command prompt (0000>)
	
	push	BC
	push	HL
	
	ld		B,30					; Set the maximum number of bytes to read
	ld		HL,CommandBuffer		; Set the memory area to read the string to
	call	ReadString				; Read a string from console (HL is the address of buffer, BC is character count)
	
	pop		HL
	pop		BC
	
	call	Parser					; Parse the entered command
	
	jr		Main


;  ____            _                              _     _                      
; / ___|   _   _  | |__    _ __    ___    _   _  | |_  (_)  _ __     ___   ___ 
; \___ \  | | | | | '_ \  | '__|  / _ \  | | | | | __| | | | '_ \   / _ \ / __|
;  ___) | | |_| | | |_) | | |    | (_) | | |_| | | |_  | | | | | | |  __/ \__ \
; |____/   \__,_| |_.__/  |_|     \___/   \__,_|  \__| |_| |_| |_|  \___| |___/
;
; ---------------------------------------------------------------------------------------------------------------------
; ALL SUBROUTINES ARE EMBEDED IN VARIOUS INCLUDE FILES

	.include	"io.asm"			; Input and output subroutines
	.include	"convert.asm"		; Convert and process data subroutines
	.include	"monitor.asm"		; Monitor command subroutines
	.include	"ancillary.asm"		; Anscillary subroutines for monitor commands
	.include	"basic.asm"			; Nascom Microsoft Basic (from Grant Searle)
	.include	"data.asm"			; Various data and text messages. Keep last in list of includes


; __     __                 _           _       _              
; \ \   / /   __ _   _ __  (_)   __ _  | |__   | |   ___   ___ 
;  \ \ / /   / _` | | '__| | |  / _` | | '_ \  | |  / _ \ / __|
;   \ V /   | (_| | | |    | | | (_| | | |_) | | | |  __/ \__ \
;    \_/     \__,_| |_|    |_|  \__,_| |_.__/  |_|  \___| |___/
;
; ---------------------------------------------------------------------------------------------------------------------
; VARIABLES ARE DECLARED IN BYTE SIZE

CommandBuffer:		ds	HorizTextRes-10	; Command prompt buffer
BufferPointer:		ds	2			; Buffer pointer
CmdErrorPointer:	ds	1			; Command line error pointer
CurrentBank:		ds	1			; Keep track of current bank
CurrentAddress:		ds	2			; Current Address for prompt
DigitString			ds	9			; Digit string for numeric conversions (so they are printable with PrintString)
ParseSaveHL			dw	2			; Saves the HL, as HL is used to call routines, and interferes with registers
RegA:				ds	1			; Register A
RegBC:				ds	2			; Register BC
RegDE:				ds	2			; Register DE
RegHL:				ds	2			; Register HL
RegIX:				ds	2			; Index IX
RegIY:				ds	2			; Index IY
StackPtr:			ds	2			; Index SP
FlagsReg:			ds	1			; Status flags
;RegI:				ds	1			; 
;RegR:				ds	1			; 
StartAddress:		ds	2			; Original start or source address
EndAddress:			ds	2			; Original end or destination address
StartAddressAlt:	ds	2			; Original start or source address
EndAddressAlt: 		ds	2			; Original end or destination address
ByteTransfer:		ds	1			; Byte to copy/transfer
UserCodeSize		ds	2			; Size of uploaded user code 

EndOfCode:
	ds	VectorTable-$,$FF			; Fill gap with $FF to optimize speed when programming the FLASH/EEPROM


; __     __                _                      _____           _       _        
; \ \   / /   ___    ___  | |_    ___    _ __    |_   _|   __ _  | |__   | |   ___ 
;  \ \ / /   / _ \  / __| | __|  / _ \  | '__|     | |    / _` | | '_ \  | |  / _ \
;   \ V /   |  __/ | (__  | |_  | (_) | | |        | |   | (_| | | |_) | | | |  __/
;    \_/     \___|  \___|  \__|  \___/  |_|        |_|    \__,_| |_.__/  |_|  \___|
;
; ---------------------------------------------------------------------------------------------------------------------
; CONSTANT VALUES SO EXTERNALLY LOADED PROGRAMS CAN ACCESS SPECIFIC INFORMATION
	.org	$FD00

VectorTable:

IntVectorEnd:		dw	InterruptVectorEnd	;= $FD00			; End of interrupt vector table
VectorTableStart:	dw	VectorTable			;= $FD02			; Start of vector and jump tables
CodeStartAddr:		dw	StartOfCode			;= $FD04			; Start of code address
CodeEndAddr:		dw	EndOfCode			;= $FD06			; End of code address

	ds	JumpTable-$,$FF				; $FF up to the jump table


;      _                                 _____           _       _        
;     | |  _   _   _ __ ___    _ __     |_   _|   __ _  | |__   | |   ___ 
;  _  | | | | | | | '_ ` _ \  | '_ \      | |    / _` | | '_ \  | |  / _ \
; | |_| | | |_| | | | | | | | | |_) |     | |   | (_| | | |_) | | | |  __/
;  \___/   \__,_| |_| |_| |_| | .__/      |_|    \__,_| |_.__/  |_|  \___|
;                             |_|                                         
; ---------------------------------------------------------------------------------------------------------------------
; JUMP TABLE TO CALL ROUTINES FROM AN EXTERNAL PROGRAM

	.org	$FE00
	
JumpTable:
	jp		Ascii2HexNibble		;= $FE00				; [A -> A][A -> A]
	jp		Ascii2HexByte		;= $FE03				; [(HL) -> A][(HL) -> A]
	jp		Ascii2HexWord		;= $FE06				; [(HL) -> BC][(HL) -> BC]
	jp		ClearScreen			;= $FE09				; [][]
	jp		GetHexParameter		;= $FE0C				; [(HL) -> BC,A,(HL)][(HL) -> BC,A,(HL)]
	jp		PrintChar			;= $FE0F				; [A ->][A ->]
	jp		PrintString			;= $FE12				; [HL ->][HL ->]
	jp		PrintCRLF			;= $FE15				; [][]
	jp		PrintNibble			;= $FE18				; [A ->][A ->]
	jp		PrintByte			;= $FE1B				; [A ->][A ->]
	jp		PrintWord			;= $FE1E				; [HL ->][HL ->]
	jp		RangeValidation		;= $FE21				; Start&EndAddress -> C, Start&EndAddress, Start&EndAddressAlt)
	jp		ReadChar			;= $FE24				; [-> A][-> A]
	jp		ReadCharNoWait		;= $FE27
	jp		ReadString			;= $FE2A				; [HL ->][HL ->]
	jp		ReadByte			;= $FE2D				; [-> A][-> A]
	jp		ReadWord			;= $FE30				; [-> HL][-> HL]
	jp		SkipSpaces			;= $FE33				; [HL -> HL][HL -> HL]
	jp		UpperCase			;= $FE36				; [A -> A][A -> A]
	jp		Registers			;= $FE39				; [][]
	jp		Dec2Hex				;= $FE3C				; [(HL) -> BC]

VectorEnd:
	ds		StackPage-$,$FF		; $FF the rest of the jump table all the way to the stack area


;  ____    _                    _    
; / ___|  | |_    __ _    ___  | | __
; \___ \  | __|  / _` |  / __| | |/ /
;  ___) | | |_  | (_| | | (__  |   < 
; |____/   \__|  \__,_|  \___| |_|\_\
;
; ---------------------------------------------------------------------------------------------------------------------
; STACK AREA, ClEAR OUT WITH ZEROS

	.org	$FF00

StackPage:

	ds		$FFFF-$,$00			; Zero the stack all the way to end of ROM

BiosEnd:
.end