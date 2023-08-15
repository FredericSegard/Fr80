; Routines in this include file:
; ------------------------------
;	- Ascii2HexNibble	[A -> A]
;	- Ascii2HexByte		[HL -> A]
;	- Ascii2HexWord		[HL -> BC]
;	- UpperCase			[A -> A]

; *********************************************************************************************************************
; Converts a single decimal digit to BCD
;	- Input:	A = Contains the ASCII character to convert to BCD
;	- Output:	A = Contains the 4-bit BCD value in LSB
;				Carry set if valid; Carry clear if error
; *********************************************************************************************************************

Ascii2BcdDigit:

;     _                   _   _   ____    _   _                 _   _   _   _       _       _        
;    / \     ___    ___  (_) (_) |___ \  | | | |   ___  __  __ | \ | | (_) | |__   | |__   | |   ___ 
;   / _ \   / __|  / __| | | | |   __) | | |_| |  / _ \ \ \/ / |  \| | | | | '_ \  | '_ \  | |  / _ \
;  / ___ \  \__ \ | (__  | | | |  / __/  |  _  | |  __/  >  <  | |\  | | | | |_) | | |_) | | | |  __/
; /_/   \_\ |___/  \___| |_| |_| |_____| |_| |_|  \___| /_/\_\ |_| \_| |_| |_.__/  |_.__/  |_|  \___|
;

; *********************************************************************************************************************
; Converts a single ASCII hex character to a nibble, and validate if it's ok
;	- Input:	A = Contains the ASCII character to convert to hex value
;	- Output:	A = Converted 4-bit value in LSB
;				Carry set if valid; Carry clear if error
; *********************************************************************************************************************

Ascii2HexNibble:
	call	UpperCase				; Convert a-f to uppercase
	cp		"0"						; If it's anything bellow 0
	jr		c,Ascii2HexNibbleErr	; Then indicate an error
	cp		"F"+1					; If it's anything above F
	jr		nc,Ascii2HexNibbleErr	; Then indicate an error
	cp		"9"+1					; Check if it's less then 9
	jr		c,Ascii2HexNibbleOK		; Then it's a valid 0-9 digit
	cp		"A"						; Check if it's above A
	jr		nc,Ascii2HexNibbleOK	; Then it's a valid A-F hex digit
	jr		Ascii2HexNibbleErr		; Else, anything in between is an error

Ascii2HexNibbleOK:
	sub		$30						; Substract $30 to transform character 0-9 into a number
	cp		9+1						; Is it a decimal 0-9 digit?
	jr		c,Ascii2HexNibbleEnd	; If it's then return value it as is
	sub		$07						; If not, then substract the alpha offset to get A-F

Ascii2HexNibbleEnd:
	call	IncErrorPointer			; Increment command line error pointer
	scf								; Set carry flag
	ret

Ascii2HexNibbleErr:
	or		A						; Clear carry flag
	ret


;     _                   _   _   ____    _   _                 ____            _          
;    / \     ___    ___  (_) (_) |___ \  | | | |   ___  __  __ | __ )   _   _  | |_    ___ 
;   / _ \   / __|  / __| | | | |   __) | | |_| |  / _ \ \ \/ / |  _ \  | | | | | __|  / _ \
;  / ___ \  \__ \ | (__  | | | |  / __/  |  _  | |  __/  >  <  | |_) | | |_| | | |_  |  __/
; /_/   \_\ |___/  \___| |_| |_| |_____| |_| |_|  \___| /_/\_\ |____/   \__, |  \__|  \___|
;                                                                       |___/              
;
; *********************************************************************************************************************
; Converts a pair of ASCII hex characters to a byte and validate if it's ok
;	- Input:	HL = Points to the two characters to convert
;	- Output:	A = Converted 8-bit byte
;				HL = points to the next position
;				Carry set if valid; Carry clear if error
; *********************************************************************************************************************

Ascii2HexByte:
	push	BC
	ld		A,(HL)
	inc		HL
	call	Ascii2HexNibble			; Convert the first character (MSB)
	jr		nc,Ascii2HexByteErr		; Was there an error? If Yes, then exit with error code
	sla		A						; Place result to the MSB position...
	sla		A						;	by shifting it 4 times to the left...
	sla		A						;	and zeroing out the LSB in the process
	sla		A						;
	ld		B,A						; Save resulting MSB
	ld		A,(HL)
	inc		HL
	call	Ascii2HexNibble			; Convert the second character (LSB)
	jr		nc,Ascii2HexByteErr		; Was there an error? If Yes, then exit with error code
	or		B						; Merge MSB with LSB, result in A
	pop		BC
	scf								; Set carry flag
	ret

Ascii2HexByteErr:
	pop		BC
	or		A						; Clear carry flag
	ret


;     _                   _   _   ____    _   _                 ____            _          
;    / \     ___    ___  (_) (_) |___ \  | | | |   ___  __  __ | __ )   _   _  | |_    ___ 
;   / _ \   / __|  / __| | | | |   __) | | |_| |  / _ \ \ \/ / |  _ \  | | | | | __|  / _ \
;  / ___ \  \__ \ | (__  | | | |  / __/  |  _  | |  __/  >  <  | |_) | | |_| | | |_  |  __/
; /_/   \_\ |___/  \___| |_| |_| |_____| |_| |_|  \___| /_/\_\ |____/   \__, |  \__|  \___|
;                                                                       |___/              
;
; *********************************************************************************************************************
; Converts four ASCII hex characters to a 16-bit word and validate if it's ok
;	- Input:	HL = Points to the 4 characters to be converted
;	- Output:	BC = Contains the 16-bit value
;				HL = points to the next position
;				Carry set if valid; Carry clear if error
; *********************************************************************************************************************

Ascii2HexWord:
	push	AF
	call	Ascii2HexByte			; Convert the upper 2 characters (MSB)
	jr		nc,Ascii2HexWordErr		; Was there an error? If Yes, then exit with error code
	ld		B,A						; Save the MSB result to B
	call	Ascii2HexByte			; Convert the lower 2 characters (LSB)
	jr		nc,Ascii2HexWordErr		; Was there an error? If Yes, then exit with error code
	ld		C,A						; Save the the LSB
	pop		AF
	scf								; Set carry flag
	ret
	
Ascii2HexWordErr:
	pop		AF
	or		A						; Clear carry flag
	ret


;  ____                  ____    _   _               
; |  _ \    ___    ___  |___ \  | | | |   ___  __  __
; | | | |  / _ \  / __|   __) | | |_| |  / _ \ \ \/ /
; | |_| | |  __/ | (__   / __/  |  _  | |  __/  >  < 
; |____/   \___|  \___| |_____| |_| |_|  \___| /_/\_\
;
;
; *********************************************************************************************************************
; Convert decimal digits in a string to a hex number
;	- Input:	HL = Points to the string the decimal characters are
;	- Output:	BC = 16-bit hex value
;				HL = Points to the next position after the last decimal number
; *********************************************************************************************************************

Dec2Hex:
	push	AF
	push	DE
	
	call	SkipSpaces
	ex		DE,HL					; HL is normally processed for strings, but ADD requires HL in this routine
	ld		HL,0
Dec2HexLoop:		
	ld		A,(DE)					; HL is required for add, so DE is used to grab the string instead of HL
	cp		0
	jr		z,Dec2HexShuffleRegs
	cp		DELIMITER
	jr		z,Dec2HexShuffleRegs
	
	cp		"0"						; If it's anything bellow 0
	jr		c,Dec2HexInvalidDec		; Then indicate an error
	cp		"9"+1					; Check if it's less then 9
	jr		nc,Dec2HexInvalidDec	; Then indicate an error

	sub		$30						; Convert ASCII decimal to BCD
	inc		DE						; Increment buffer pointer
	call	IncErrorPointer

	push	HL
	pop		BC

	add		HL,HL
	jr		c,Dec2HexOutOfRange
	add		HL,HL	
	jr		c,Dec2HexOutOfRange
	add		HL,BC	
	jr		c,Dec2HexOutOfRange
	add		HL,HL
	jr		c,Dec2HexOutOfRange
	
	add		L	
	ld		L,A	
	jr		nc,Dec2HexLoop
	inc		H
	jr		c,Dec2HexOutOfRange
	jr		Dec2HexLoop

Dec2HexShuffleRegs:
	push	HL						; Push result in BC
	pop		BC						;
	ex		DE,HL					; Place buffer pointer in HL
	scf								; Set Carry
	jr		Dec2HexEnd

Dec2HexOutOfRange:
	call	NumberOutOfRange
	or		A
	jr		Dec2HexEnd
	
Dec2HexInvalidDec:
	call	PrintErrorPointer
	call	InvalidDecimalNumber
	or		A
	
Dec2HexEnd:
	pop		DE
	pop		AF
	ret


;  _   _                 ____    ____                
; | | | |   ___  __  __ |___ \  |  _ \    ___    ___ 
; | |_| |  / _ \ \ \/ /   __) | | | | |  / _ \  / __|
; |  _  | |  __/  >  <   / __/  | |_| | |  __/ | (__ 
; |_| |_|  \___| /_/\_\ |_____| |____/   \___|  \___|
;
;
; *********************************************************************************************************************
; Convert a 16-bit a hex binary data to a decimal string
;	- Input:	HL = 16-bit hex number
;	- Output:	HL = Start of string pointer (DigitString variable) - Ends with null
; *********************************************************************************************************************
; B is the first non-zero flag, so as not to print leading zero's

Hex2Dec:
	push	AF
	push	BC
	push	DE
	push	IX

	ld		B,0
	ld		IX,DigitString
Hex2Dec10000:
	; CALCULATE THE 10,000's
	ld		A,-1					; Start at -1
Hex2Dec10000Loop:
	inc		A						; Add 1
	or		A						; Clear carry
	ld		DE,10000
	sbc		HL,DE					; Substract 10,000
	jr		nc,Hex2Dec10000Loop		; Continue if not reached negative
	add		HL,DE					; Add 10,000 back to make it positive
	cp		0
	jr		nz,Hex2Dec10000Set
	jr		Hex2Dec1000				; If it's not set
Hex2Dec10000Set
	set		0,B
	add		$30
	ld		(IX),A
	inc		IX

	; CALCULATE THE 1,000's
Hex2Dec1000:
	ld		A,-1					; Start at -1
Hex2Dec1000Loop:
	inc		A						; Add 1
	or		A						; Clear carry
	ld		DE,1000
	sbc		HL,DE					; Substract 1,000
	jr		nc,Hex2Dec1000Loop		; Continue if not reached negative
	add		HL,DE					; Add 1,000 back to make it positive
	cp		0
	jr		nz,Hex2Dec1000Set
	bit		0,B						; Check the flag
	jr		z,Hex2Dec100			; If it's not set
Hex2Dec1000Set
	set		0,B						
	add		$30
	ld		(IX),A
	inc		IX

	; CALCULATE THE 100's
Hex2Dec100:
	ld		A,-1					; Start at -1
Hex2Dec100Loop:
	inc		A						; Add 1
	or		A						; Clear carry
	ld		DE,100
	sbc		HL,DE					; Substract 100
	jr		nc,Hex2Dec100Loop		; Continue if not reached negative
	add		HL,DE					; Add 100 back to make it positive
	cp		0
	jr		nz,Hex2Dec100Set
	bit		0,B						; Check the flag
	jr		z,Hex2Dec10				; If it's not set
Hex2Dec100Set
	set		0,B						
	add		$30
	ld		(IX),A
	inc		IX


	; CALCULATE THE 10's
Hex2Dec10:
	ld		A,-1					; Start at -1
Hex2Dec10Loop:
	inc		A						; Add 1
	or		A						; Clear carry
	ld		DE,10
	sbc		HL,DE					; Substract 10
	jr		nc,Hex2Dec10Loop		; Continue if not reached negative
	add		HL,DE					; Add 10 back to make it positive
	cp		0
	jr		nz,Hex2Dec10Set
	bit		0,B						; Check the flag
	jr		z,Hex2Dec1				; If it's not set
Hex2Dec10Set
	set		0,B						
	add		$30
	ld		(IX),A
	inc		IX

	; STORE THE 1's
Hex2Dec1:
	ld		A,L
	add		$30
	ld		(IX),A
	inc		IX
	ld		A,0
	ld		(IX),A					; End string with null character
	
Hex2DecEnd:
	ld		HL,DigitString			; Point to decimal string to output
	
	pop		IX
	pop		DE
	pop		BC
	pop		AF
	ret


;  _   _                                  ____                      
; | | | |  _ __    _ __     ___   _ __   / ___|   __ _   ___    ___ 
; | | | | | '_ \  | '_ \   / _ \ | '__| | |      / _` | / __|  / _ \
; | |_| | | |_) | | |_) | |  __/ | |    | |___  | (_| | \__ \ |  __/
;  \___/  | .__/  | .__/   \___| |_|     \____|  \__,_| |___/  \___|
;         |_|     |_|                                               
;
; *********************************************************************************************************************
; Converts a character to uppercase
;	- INPUT:	A = Character to uppercase
;	- OUTPUT:	A = Uppercased character
; *********************************************************************************************************************

UpperCase:
	cp		"a"						; Is the value less then lowercase a?
	jr		c,UpperCaseEnd			; If so, then end routine
	cp		"z"+1					; Is the value more then lowercase z?
	jr		nc,UpperCaseEnd			; If so, then end routine
	sub		32						; Substract the ASCII difference
UpperCaseEnd:
	ret
	