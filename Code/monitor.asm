; Command routines in this include file:
; --------------------------------------
;	- ClearScreen					; {}
;	- Diagnostics					; {}
;	- Fill							; {SSSS EEEE BB}
;	- HexDump 						; {AAAA LL}
;	- IntelHex  					; {}
;	- List  						; {}
;	- Peek							; [AAAA]
;	- Poke							; AAAA BB
;	- Registers  					; {}
;	- Run  							; {AAAA}
;	- SetAddress					; [AAAA]
;	- SetBank						; [N]
;	- SysInfo 						; {}
;	- Write							; AAAA BB [BB] [BB] [BB] [BB] [BB]
;	- Zero							; {}


;   ____   _                         ____                                      
;  / ___| | |   ___    __ _   _ __  / ___|    ___   _ __    ___    ___   _ __  
; | |     | |  / _ \  / _` | | '__| \___ \   / __| | '__|  / _ \  / _ \ | '_ \ 
; | |___  | | |  __/ | (_| | | |     ___) | | (__  | |    |  __/ |  __/ | | | |
;  \____| |_|  \___|  \__,_| |_|    |____/   \___| |_|     \___|  \___| |_| |_|
;

; *********************************************************************************************************************
; ClearScreen: Clears the VT terminal screen
; *********************************************************************************************************************

ClearScreen:
	push	HL
	ld		HL,ClearScreenSeq
	call	PrintString
	pop		HL
	ret


;   ____                           ____    _                  _    
;  / ___|   ___    _ __    _   _  | __ )  | |   ___     ___  | | __
; | |      / _ \  | '_ \  | | | | |  _ \  | |  / _ \   / __| | |/ /
; | |___  | (_) | | |_) | | |_| | | |_) | | | | (_) | | (__  |   < 
;  \____|  \___/  | .__/   \__, | |____/  |_|  \___/   \___| |_|\_\
;                 |_|      |___/
;
; *********************************************************************************************************************
; Copy data from source to destination
; - Input:	HL = Source address
;			DE = Destination address
;			BC = Number of bytes to move
; *********************************************************************************************************************

CopyBlock:
	push	AF
	push	BC
	push	DE
	push	HL

	ld		HL,(BufferPointer)		; Restore current buffer pointer in HL
	
CopySourceAddress:
	call	GetHexParameter			; Get the first parameter, start address
	jp		nc,CopyEnd				; Exit routine if there was an error in the parameter
	cp		0						; Is there a first parameter?
	jr		z,CopyNoParameter		; No, then print error message
	ld		(StartAddress),BC		; Save source address

CopyDestinationAddress:
	call	GetHexParameter			; Get the first parameter, start address
	jp		nc,CopyEnd				; Exit routine if there was an error in the parameter
	cp		0						; Is there a first parameter?
	jr		z,CopyNoParameter		; No, then print error message
	ld		(EndAddress),BC			; Save destination address

CopyNumberOfBytes:
	call	GetHexParameter			; Get the first parameter, start address
	jp		nc,CopyEnd				; Exit routine if there was an error in the parameter
	cp		0						; Is there a first parameter?
	jr		z,CopyNoParameter		; No, then print error message

	; Check if the number of bytes is zero
	ld		A,B
	or		C
	jr		z,CopyNothing

	ld		HL,(StartAddress)		; Restore HL
	
	; Does destination area overlap source area?
	ld		DE,(StartAddress)
	ld		HL,(EndAddress)
	or		A						; Clear carry
	sbc		HL,DE
	or		A						; Clear carry
	sbc		HL,BC
	ld		HL,(StartAddress)
	ld		DE,(EndAddress)
	jr		nc,CopyNoOverlap
	
	; Destination overlaps, copy from highest address to avoid destroying data
	add		HL,BC
	dec		HL
	ex		DE,HL
	add		HL,BC
	dec		HL
	ex		DE,HL
	lddr
	jr		CopyEnd

CopyNoOverlap:
	ldir
	jr		CopyEnd

CopyNoParameter:
	call	NoParameter
	jr		CopyEnd

CopyNothing:
	call	NothingToCopy

CopyEnd:	
	pop		HL
	pop		DE
	pop		BC
	pop		AF
	ret


;  ____    _                                         _     _              
; |  _ \  (_)   __ _    __ _   _ __     ___    ___  | |_  (_)   ___   ___ 
; | | | | | |  / _` |  / _` | | '_ \   / _ \  / __| | __| | |  / __| / __|
; | |_| | | | | (_| | | (_| | | | | | | (_) | \__ \ | |_  | | | (__  \__ \
; |____/  |_|  \__,_|  \__, | |_| |_|  \___/  |___/  \__| |_|  \___| |___/
;                      |___/                                              
;
;
; *********************************************************************************************************************
; Test system RAM, except the range of this routine
; *********************************************************************************************************************

Diagnostics:
	push	AF
	push	BC
	push	DE
	push	HL
	push	IX
	push	IY
	
; TEST BANK MEMORY
; ----------------
	ld		A,0						; Set Bank number to 0
	ld		IY,0
DiagnosticsBankLoop:
	ld		HL,TestingBankNumberMsg
	call	PrintString
	call	PrintNibble
	call	PrintCRLF
	ld		IX,$0000				; Set start address
	ld		HL,$7FFF				; Set end address
	out		(BankSelect),A			; Sets bank number to value in accumulator
	call	DiagnosticsTest
	inc		A
	ld		IYL,A					; Save the bank number for error printing
	cp		$F
	jr		nz,DiagnosticsBankLoop

; TEST HIGH MEMORY (BETWEEN START OF BIOS AND START OF DIAG CODE)
; ---------------------------------------------------------------
	ld		HL,TestingHighRamMsg
	call	PrintString
	ld		IX,$8000				; Set start address
	ld		HL,DiagnosticsTest		; Set end address
	call	DiagnosticsTest

; TEST HIGH MEMORY (AFTER DIAG CODE TILL THE END)
; -----------------------------------------------
	ld		IX,DiagnosticsEnd		; Set start address
	ld		HL,$FFFF				; Set end address
	call	DiagnosticsTest

	jr		DiagnosticsEnd

; ACTUAL MEMORY TEST SUBROUTINE WITHN THE SUBROUTINE
; --------------------------------------------------
DiagnosticsTest:	
	push	AF
	
	dec		IX						; Start with one less, since the increment starts at the start of the loop
DiagnosticsTestLoop:
	inc		IX						; Increment address pointer
	ld		B,(IX)					; Save the original byte in B
	
	; Write pattern 55
	ld		A,$55					; Use $55 as the first pattern value
	ld		(IX),A					; Write it to the memory location
	ld		C,A						; Save expected byte for error messages
	ld		A,(IX)					; Read from same memory location
	cp		$55						; Compare if the it's the same
	call	nz,DiagMemoryError

	; Write pattern AA
	ld		A,$AA					; Use $55 as the first pattern value
	ld		(IX),A					; Write it to the memory location
	ld		C,A						; Save expected byte for error messages
	ld		A,(IX)					; Read from same memory location
	cp		$AA						; Compare if the it's the same
	call	nz,DiagMemoryError

	ld		(IX),B					; Attempt to save the original value back in it's original place
	
	; Check for end of range
	push	IX
	pop		DE
	or		A						; Clear carry flag
	push	HL
	sbc		HL,DE					; HL = HL - DE
	pop		HL
	jp		nz,DiagnosticsTestLoop	; If reached the end of range, exit

	pop		AF
	ret

; PRINT ERROR MESSAGE IF MEMORY IS BAD
; ------------------------------------
DiagMemoryError:
	push	AF
	push	HL

	; Print "Error at"
	ld		HL,BadMemory1Err
	call	PrintString
	
	; Print bank number it it's in low memory
	push	AF
	ld		A,IYL
	cp		$0F
	jr		nc,DiagMemoryAddr
	call	PrintNibble
	ld		A,":"
	call	PrintChar
	
	; Print address of error
DiagMemoryAddr
	pop		AF
	push	IX
	pop		HL
	call	PrintWord
	
	; Print "got"
	ld		HL,BadMemory2Err
	call	PrintString
	
	; Print the read back data
	push	AF
	ld		A,B
	call	PrintByte
	pop		AF
	
	; Print "expected"
	call	PrintString
	
	; Print the pattern that was written
	ld		A,C
	call	PrintByte
	call	PrintCRLF
	
	ld		IYH,1					; Indicate an error has occured
	pop		HL
	pop		AF
	ret

DiagnosticsEnd:
	ld		A,$0
	out		(BankSelect),A			; Sets bank number to 0
	
	ld		A,IYH
	cp		1
	jr		z,DiagnosticsEnd2		; If memory test failed, exit, as there was warning errors
	ld		HL,MemoryTestPassedMsg	; Else print test passed
	call	PrintString

DiagnosticsEnd2:
	pop		IY
	pop		IX
	pop		HL
	pop		DE
	pop		BC
	pop		AF
	ret


;  _____   _   _   _   __  __                                           
; |  ___| (_) | | | | |  \/  |   ___   _ __ ___     ___    _ __   _   _ 
; | |_    | | | | | | | |\/| |  / _ \ | '_ ` _ \   / _ \  | '__| | | | |
; |  _|   | | | | | | | |  | | |  __/ | | | | | | | (_) | | |    | |_| |
; |_|     |_| |_| |_| |_|  |_|  \___| |_| |_| |_|  \___/  |_|     \__, |
;                                                                 |___/ 

; *********************************************************************************************************************
; Fill a memory address range with a byte. Does not fill all banks, only the current one. It will exclude
; shadow ROM (otherwise it will corrupt the BIOS), as well as vector pages.
;		- Parameter 1 = Start address
;		- Parameter 2 = End address
;		- Parameter 3 = The byte to write
; *********************************************************************************************************************
; 	Wishlist:
;		- Verify after write
;		- Add: Filled xxxx bytes in decimal

FillMemory:
	push	AF
	push	BC
	push	DE
	push	HL
	
	ld		HL,(BufferPointer)		; Restore current buffer pointer in HL
	
; GET ALL THE PARAMETERS AND STORE THEM IN MEMORY
FillStartAddr:
	call	GetHexParameter			; Get the first parameter, start address
	jp		nc,FillMemoryEnd		; Exit routine if there was an error in the parameter
	cp		0						; Is there a first parameter?
	jr		z,FillNoParameter		; No, then print error message
	cp		HELP
	jr		z,FillPrintHelp
	ld		(StartAddress),BC		; Store start address
	ld		(StartAddressAlt),BC	; Store start address
	
FillEndAddr:
	call	GetHexParameter			; Get the second parameter, end address
	jr		nc,FillMemoryEnd		; Exit routine if there was an error in the parameter
	cp		0						; Is there a second parameter?
	jr		z,FillNoParameter		; No, then print error message
	ld		(EndAddress),BC			; Store end address

FillByte:
	call	GetHexParameter			; Get the second parameter, byte to write
	jr		nc,FillMemoryEnd		; Exit routine if there was an error in the parameter
	cp		0						; Is there a third parameter?
	jr		z,FillNoParameter		; No, then print error message
	ld		A,C						; Transfer C in accumulator to transfer in it in RAM
	ld		(ByteTransfer),A		; Store the byte to write
	
	call	RangeValidation			; Check if Fill can write to a valid range of RAM space (excluse BIOS and Vectors)
	jr		c,FillMemoryEnd
	
FillRange1:
	; Detect amout of bytes to copy in high range
	push	BC
	bit		1,C
	jr		z,FillRange2
	ld		HL,(EndAddressAlt)		; Load end address
	ld		DE,(StartAddressAlt)	; Load start
	or		A						; Clear carry flag
	sbc		HL,DE					; HL = HL - DE
	push	HL						; Put result of byte count
	pop		BC						; Into the byte count register
	ld		HL,(StartAddressAlt)	; Set source address
	ld		A,(ByteTransfer)		; Grab byte to write
	ld		(HL),A					; Save it at the source address
	ld		DE,(StartAddressAlt)	; Place destination address
	inc		DE						; Destination address +1
	ldir
	ld		BC,(StartAddressAlt)	; Set CurrentAddress to start of available RAM
	ld		(CurrentAddress),BC
	scf								; Set carry

FillRange2:
	; Detect amout of bytes to copy in low range
	pop		BC
	bit		0,C
	jr		z,FillMemoryEnd
	ld		HL,(EndAddress)			; Load end address
	ld		DE,(StartAddress)		; Load start
	or		A						; Clear carry flag
	sbc		HL,DE					; HL = HL - DE
	push	HL						; Put result of byte count
	pop		BC						; Into the byte count register
	ld		HL,(StartAddress)		; Set source address
	ld		A,(ByteTransfer)		; Grab byte to write
	ld		(HL),A					; Save it at the source address
	ld		DE,(StartAddress)		; Place destination address
	inc		DE						; Destination address +1
	ldir
	ld		BC,(StartAddress)		; Set CurrentAddress to start of available RAM
	ld		(CurrentAddress),BC
	scf								; Set Carry, indicates no error to calling program
	jr		FillMemoryEnd

FillNoParameter:
	call	NoParameter
	or		A						; Clear Carry, indicates error to calling program
	jr		FillMemoryEnd

FillPrintHelp:
	ld		HL,FillHelp
	call	PrintString

FillMemoryEnd:
	pop		HL
	pop		DE
	pop		BC
	pop		AF
	ret


; *********************************************************************************************************************
; Halts the CPU
; *********************************************************************************************************************
 
HaltCmd:
	halt
	ret


;  _   _                 ____                              
; | | | |   ___  __  __ |  _ \   _   _   _ __ ___    _ __  
; | |_| |  / _ \ \ \/ / | | | | | | | | | '_ ` _ \  | '_ \ 
; |  _  | |  __/  >  <  | |_| | | |_| | | | | | | | | |_) |
; |_| |_|  \___| /_/\_\ |____/   \__,_| |_| |_| |_| | .__/ 
;                                                   |_|    
;
; *********************************************************************************************************************
; Prints the content of memory to serial port A
; Parameters:	[AAAA], [LL] (where AAAA is the address to start displaying, and LL is the number of lines to display)
; *********************************************************************************************************************
;
; Registers and variables used:
;	- B is the number of bytes/characters per line
;	- C is the line counter per page
;	- DE is the number of lines to print
;	- HL is the address to display

; Wish list:
;	- End at $FFFF
;	- When more then a page long, pause every page and wait for ENTER to continues, or ESC to quit

HexDump:
	push	AF
	push	BC
	push	DE
	push	HL
	
	ld		HL,(BufferPointer)		; Restore current buffer pointer in HL
	call	GetHexParameter			; Get the first parameter: the address to display
	jr		nc,HexDumpEnd			; Exit routine if there was an error in the parameter
	cp		HELP
	jr		z,HexDumpPrintHelp
	cp		0						; Is there a parameter?
	jr		nz,HexLinesToRead		; If There's a parameter, go check second parameter
	ld		BC,(CurrentAddress)		; Since it's no parameter, then place CurrentAddress as default address

HexLinesToRead:
	push	BC						; Save the first parameter's address...
	pop		DE						;    to be later recovered as HL
	call	GetHexParameter			; Get the secode parameter: the number of lines to display
	jr		nc,HexDumpEnd			; Exit routine if there was an error in the parameter
	cp		0						; Is there a parameter?
	jr		z,HexDefaultLines		; There is no parameter, so go load the default line number
	cp		1						; Is it a one byte parameter
	jr		z,HexDisplayContent		; If it is, C already contains the number of lines, so start printing content
	ld		C,$FF					; Else, if it's a 2 byte or more parameter, set maximum lines to $FF
	jr		HexDisplayContent		; Start printing hex dump
HexDefaultLines:
	ld		C,VertTextRes-3			; Get number of vertical lines

HexDisplayContent:
	ex		DE,HL					; Restore address from first parameter read
	
; PRINT ADDRESS AT BEGINNING
HexNextLine:
	push	HL						; Save HL for later use (character portion of memory dump)
	call	PrintWord				; Print address
	ld		B,8						; Setup byte counter per line
	ld		A,":"
	call	PrintChar				; Print colon
	ld		A," "
	call	PrintChar				; Print space

; PRINT EIGHT BYTES
HexNextByte:
	ld		A,(HL)
	call	PrintByte				; Print byte contained in address HL
	ld		A," "
	call	PrintChar				; Print space
	inc		HL						; Increment HL for next byte
	dec		B						; Decrement byte counter
	jr		nz,HexNextByte			; If the 8 bytes have not all been printed, then loop again

; PRINT EIGHT CHARACTERS
	call	PrintChar				; Print an extra space (to space out bytes from character printout)
	ld		B,8						; Reset the counter to count characters instead
	pop		HL						; Reset HL so we can print the characters instead of the bytes at the end of the line
HexNextChar:
	ld		A,(HL)
	cp		$20						; Compare A with first displayable character
	jr		c,HexReplaceDot			; If it's lower, then replace with a period
	cp		$7F						; Is it higher or equal to the DEL character?
	jr		nc,HexReplaceDot		; Then replace that with a period
	jr		HexPrintChar
HexReplaceDot:
	ld		A,"."					; No, then replace it with a period
HexPrintChar:
	call	PrintChar				; Print the character representation of the byte
	inc		HL						; Increment HL for next character
	dec		B						; Decrement character counter
	jr		nz,HexNextChar			; If the 8 characters have not all been printed, then loop again
	call	PrintCRLF				; Change line
	dec		C						; 
	jp		nz,HexNextLine
	ld		(CurrentAddress),HL		; Save Current Address to where Hex left off
	jr		HexDumpEnd
	
HexDumpPrintHelp:
	ld		HL,HexDumpHelp
	call	PrintString
	
HexDumpEnd:
	pop		HL
	pop		DE
	pop		BC
	pop		AF
	ret


;  ___           _            _   _   _               
; |_ _|  _ __   | |_    ___  | | | | | |   ___  __  __
;  | |  | '_ \  | __|  / _ \ | | | |_| |  / _ \ \ \/ /
;  | |  | | | | | |_  |  __/ | | |  _  | |  __/  >  < 
; |___| |_| |_|  \__|  \___| |_| |_| |_|  \___| /_/\_\
;

; *********************************************************************************************************************
; Transfer programs via Intel Hex (i8HEX) - Press ESC to exit
; - Input:	Upload an i8Hex file from a terminal program on your computer (Transfer File)
; - Output:	Sets (CurrentAddress) variable to the start address declared in the IntelHex file

; File Format:	SBBAAAARRDDDDDDCC termintated by (CR) and/or (LF)
;				:0300300002337A1E
;					S = : is the start code
;					BB = it the data byte count ($20 is the typical)
;					AAAA = The 16-bit beginning memory address offset of the data
;					RR = Record type, 00 = Data, 01 = End of File
;					DD = Data
;					CC = Checksum from BB to the last DD (Two's complement)
; *********************************************************************************************************************
;	- B = Byte couter
;	- C = Checksum
;	- D = Flags (Start address, Checksum error, Last record)
;	- HL = Address offset pointer

StartAddr	= 0						; Start address flag bit
ChecksumErr	= 1						; Checksum error flag bit
LastRec		= 7						; Last record flag bit

IntelHex:
	push	AF
	push	BC
	push	DE
	push	HL
	push	IX
	
	call	SkipSpaces
	ld		A,(HL)					; Read a character form the CommandBuffer	
	cp		HELP
	jp		z,IntelHexPrintHelp

	ld		HL,IntelHexLoadMsg		; Print load message, or ESC to exit
	call	PrintString				;
	ld		D,0						; Clear the flags register
	ld		IX,0					; Clear byte counter
	ld		(UserCodeSize),IX		; Clear user code byte counter
	
; *** START CODE
IntelHexStartCode:
	call	ReadChar				; Read a character form the console
	cp		ESC						; Did the user press ESCAPE?
	jp		z,IntelHexAbort			; Yes, then exit
	cp		":"						; Is it the start code
	jr		z,IntelHexByteCount		; Yes, then read byte count
	jr		IntelHexStartCode		; No, then read a new character until ":" is present
	
; *** BYTE COUNT
IntelHexByteCount:
	call	ReadByte				; Read the byte count
	ld		B,A						; Store byte counter in B
	ld		C,A						; copy value of accumulator in checksum register

; *** ADDRESS
IntelHexAddress:
	call	ReadByte				; Read the MSB characters and convert it to a byte
	ld		H,A						; Store the address's MSB
	add		C						; Add checksum
	ld		C,A						; Store back result in checksum accumulator
	call	ReadByte				; Read the LSB characters and convert it to a byte
	ld		L,A						; Store the address's LSB
	add		C						; Add checksum
	ld		C,A						; Store back result in checksum accumulator
	bit		StartAddr,D				; Check if it's the first time the address has been read...
	jr		nz,IntelHexRecordType	;	If it's not the first line, then go get record type
	ld		(CurrentAddress),HL		; Else store the starting address
	set		StartAddr,D				; Set first line start address flag
;	ld		E,1						; Set first pass flag

; *** RECORD TYPE
IntelHexRecordType:
	call	ReadByte				; Read the record type byte
	push	AF
	add		C						; Add checksum
	ld		C,A						; Store back result in checksum accumulator
	pop		AF
	cp		00						; Is it data?
	jr		z,IntelHexData
	cp		01						; Is it the end of file record type
	jr		nz,IntelHexUnsupported		
	set		LastRec,D	
	jr		IntelHexChecksum		; Get checksum

; *** DATA
IntelHexData:
	call	ReadByte				; Get data byte
	ld		(HL),A					; Store data byte in memory
	inc		HL						; Point to the next address
	inc		IX						; Count the total number of bytes
	add		C						; Add checksum
	ld		C,A						; Store back result in checksum accumulator
	djnz	IntelHexData			; Decrement count, and go to next data if not finished

; *** CHECKSUM
IntelHexChecksum:
	call	ReadByte				; Read the checksum for that record
	neg								; Do a 2s compliment on A (saves instructions if I swapped C with A)
	cp		C						; Compare the transmited checksum with the calculated checksum
	jr		z,IntelHexCheckOk		; Is it the same?
	ld		A,"x"					; Display an "x" if checksum do not match
	set		ChecksumErr,D			; Indicate an error in checksum flag
	jr		IntelHexPrintStatus		;
IntelHexCheckOk:
	ld		A,"."					; Display a "." if checksum is a match
IntelHexPrintStatus:
	call	PrintChar				; Print the checksum validity character
	bit		LastRec,D				; Check if it's the last record
	jp		z,IntelHexStartCode		; No, then continue reading more lines
	call	ReadChar				; Flush CR

IntelHexPrintEndMsg:
	call	PrintCRLF
	ld		HL,IntelHexFinishedMsg	; Print the end message
	call	PrintString
	ld		HL,IntelHexSuccessMsg	; Point to "unsuccessful"
	bit		ChecksumErr,D			; Cneck if there was an error that was flagged
	jr		nz,IntelHexPrintNotOk	; If the ChecksumErr flag was set, then print unsuccessful
	inc		HL						; Push pointer to letters..
	inc		HL						;   so it becomes "successful"
IntelHexPrintNotOk:
	call	PrintString				; Print the sucess level
	push	HL
	push	IX						; Copy byte counter
	pop		HL						; To HL to be printed
	call	PrintDec				; Print the decimal number
	ld		HL,DownloadedBytesMsg	; 
	call	PrintString				; Print bytes loaded text
	pop		HL
	jr		IntelHexEnd				; And end load

IntelHexAbort:
	ld		HL,IntelHexAbortedMsg	; Abort message
	call	PrintString				;
	jr		IntelHexEnd

IntelHexUnsupported:
	ld		HL,IntelHexUnsupportedErr	; Unsupported record type message
	call	PrintString				;
	call	PrintByte				; Print the record number
	call	PrintCRLF
	jr		IntelHexEnd

IntelHexParamError:
	ld		HL,UnrecognizedParamErr
	call	PrintString
	jr		IntelHexEnd

IntelHexPrintHelp:
	ld		HL,IntelHexHelp
	call	PrintString
	
IntelHexEnd:
	pop		IX
	pop		HL
	pop		DE
	pop		BC
	pop		AF
	ret


;  _       _         _   
; | |     (_)  ___  | |_ 
; | |     | | / __| | __|
; | |___  | | \__ \ | |_ 
; |_____| |_| |___/  \__|


; *********************************************************************************************************************
; Prints a list of available commands
; *********************************************************************************************************************

ListCmd:
	push	HL
	ld		HL,ListOfCommands
	call	PrintString				; Print first line
	call	PrintLine				; Print a line
	call	PrintString				; Print the rest
	pop		HL
	ret


;  ____                  _    
; |  _ \    ___    ___  | | __
; | |_) |  / _ \  / _ \ | |/ /
; |  __/  |  __/ |  __/ |   < 
; |_|      \___|  \___| |_|\_\


; *********************************************************************************************************************
; Read a byte of a I/O port
; *********************************************************************************************************************
; To be done: Error messages

PeekCmd:
	push	AF
	push	BC
	push	HL
	
	ld		HL,(BufferPointer)		; Restore current buffer pointer in HL
	
PeekAddress:
	call	GetHexParameter			; Get the IO port number parameter
	jp		nc,PeekError			; Exit routine if there was an error in the parameter
	cp		0						; Is there a parameter?
	jr		z,PeekNoParameter		; No, then print a no parameter message

PeekRead:
	ld		A,C						; Put port number from command line parameter in accumulator
	call	PrintByte				; Print the port number
	ld		A,":"
	call	PrintChar
	in		A,(C)					; Read a byte from the specified port number
	call	PrintByte				; Print the read byte
	call	PrintCRLF				; Change line
	jp		PeekEnd					;

PeekNoParameter:
	call	NoParameter
	jp		PeekEnd
	
PeekError:

PeekEnd:
	pop		HL
	pop		BC
	pop		AF
	ret


;  ____            _           
; |  _ \    ___   | | __   ___ 
; | |_) |  / _ \  | |/ /  / _ \
; |  __/  | (_) | |   <  |  __/
; |_|      \___/  |_|\_\  \___|


; *********************************************************************************************************************
; Write a byte to a specific I/O port
;	- Input:	Parameters: Port number & Byte
; *********************************************************************************************************************
; To be done: Error message

PokeCmd:
	push 	AF
	push	BC
	push	HL
	
	ld		HL,(BufferPointer)		; Restore current buffer pointer in HL
	
PokeGetPort:
	call	GetHexParameter			; Get the first parameter, port number (byte in C)
	jp		nc,PokeError			; Exit routine if there was an error in the parameter
	cp		0						; Is there a first parameter?
	jr		z,PokeNoParameter		; No, then print error message
	ld		A,C
	ld		(CurrentPort),A			; Store port number for later use (cheaper than push-pop)
	
PokeGetByte:
	call	GetHexParameter			; Get the second parameter, byte to write
	jr		nc,PokeError			; Exit routine if there was an error in the parameter
	cp		0						; Is there a third parameter?
	jr		z,PokeNoParameter		; No, then print error message
	ld		A,C						; Save byte for later use
	ld		B,A						; ... and put it in B

PokeWrite:
	ld		A,(CurrentPort)			; Read back the stored port number
	ld		C,A						; Copy it in C for later use
	call	PrintByte				; Print it
	ld		A,":"
	call	PrintChar
	out		(C),B					; Write byte in B, to port address in C
	ld		A,B						; Place the byte to print in the accumulator
	call	PrintByte
	call	PrintCRLF
	jr		PokeEnd

PokeNoParameter:
	call	NoParameter
	jp		PokeEnd

PokeError:
	
PokeEnd
	pop		HL
	pop		BC
	pop		AF
	ret


;  ____                   _         _                       
; |  _ \    ___    __ _  (_)  ___  | |_    ___   _ __   ___ 
; | |_) |  / _ \  / _` | | | / __| | __|  / _ \ | '__| / __|
; |  _ <  |  __/ | (_| | | | \__ \ | |_  |  __/ | |    \__ \
; |_| \_\  \___|  \__, | |_| |___/  \__|  \___| |_|    |___/
;                 |___/                                     

; *********************************************************************************************************************
; Prints the contents of the registers on the console
; *********************************************************************************************************************
;
; Wish list:
;	- Modify individual registers

Registers:
	ld		(StackPtr),SP			; Save the stack pointer
	push	AF
	push	BC
	push	DE
	push	HL
	push	IX
	push	IY
	
	push	AF						; Save the flags (to be restored in C later)
	ld		(RegA),A				; Save A
	ld		(RegBC),BC				; Save BC
	ld		(RegDE),DE				; Save DE
	ld		(RegHL),HL				; Save HL
	ld		(RegIX),IX				; Save IX
	ld		(RegIY),IY				; Save IY
	pop		BC						; Restore AF in BC to get the flags
	ld		A,C
	ld		(FlagsReg),A			; Save the flags register
	
	; PRINT THE ACCUMULATOR
	ld		A,"A"
	call	PrintChar
	ld		A,":"
	call	PrintChar
	ld		A,(RegA)
	call	PrintByte
	ld		A," "
	call	PrintChar

	; PRINT BC REGISTER PAIR
	ld		A,"B"
	call	PrintChar
	ld		A,"C"
	call	PrintChar
	ld		A,":"
	call	PrintChar
	ld		HL,(RegBC)
	call	PrintWord
	ld		A," "
	call	PrintChar

	; PRINT DE REGISTER PAIR
	ld		A,"D"
	call	PrintChar
	ld		A,"E"
	call	PrintChar
	ld		A,":"
	call	PrintChar
	ld		HL,(RegDE)
	call	PrintWord
	ld		A," "
	call	PrintChar

	; PRINT HL REGISTER PAIR
	ld		A,"H"
	call	PrintChar
	ld		A,"L"
	call	PrintChar
	ld		A,":"
	call	PrintChar
	ld		HL,(RegHL)
	call	PrintWord
	call	PrintCRLF

	; PRINT IX INDEX REGISTER
	ld		A,"I"
	call	PrintChar
	ld		A,"X"
	call	PrintChar
	ld		A,":"
	call	PrintChar
	ld		HL,(RegIX)
	call	PrintWord
	ld		A," "
	call	PrintChar

	; PRINT IY INDEX REGISTER
	ld		A,"I"
	call	PrintChar
	ld		A,"Y"
	call	PrintChar
	ld		A,":"
	call	PrintChar
	ld		HL,(RegIY)
	call	PrintWord
	ld		A," "
	call	PrintChar

	; PRINT THE STACK POINTER
	ld		A,"S"
	call	PrintChar
	ld		A,"P"
	call	PrintChar
	ld		A,":"
	call	PrintChar
	ld		HL,(StackPtr)
	inc		HL						; Offset stack by 2 to compensate for...
	inc		HL						;	this routine's call
	call	PrintWord
	ld		A," "
	call	PrintChar

	; PRINT THE FLAGS
	ld		A,"F"
	call	PrintChar
	ld		A,":"
	call	PrintChar
	ld		HL,FlagBits

	; Sign
	ld		A,(HL)					; Load the lowercase flag symbol
	bit		Sign,C					; Check to the associated bit is set or not
	jr		z,FlagSignClear			; If it's Set, then print lower case
	call	UpperCase				; Else, print upper case
FlagSignClear:
	call	PrintChar				; Print the flag symbol
	inc		HL						; Point to the next symbol
	
	; Zero
	ld		A,(HL)					; Load the lowercase flag symbol
	bit		Zero,C					; Check to the associated bit is set or not
	jr		z,FlagZeroClear			; If it's Set, then print lower case
	call	UpperCase				; Else, print upper case
FlagZeroClear:
	call	PrintChar				; Print the flag symbol
	inc		HL						; Point to the next symbol
	
	; Half-Carry
	ld		A,(HL)					; Load the lowercase flag symbol
	bit		HalfCarry,C				; Check to the associated bit is set or not
	jr		z,FlagHalfClear			; If it's Set, then print lower case
	call	UpperCase				; Else, print upper case
FlagHalfClear:
	call	PrintChar				; Print the flag symbol
	inc		HL						; Point to the next symbol
	
	; Overflow/Parity
	ld		A,(HL)					; Load the lowercase flag symbol
	bit		Overflow,C				; Check to the associated bit is set or not
	jr		z,FlagOverClear			; If it's Set, then print lower case
	call	UpperCase				; Else, print upper case
FlagOverClear:
	call	PrintChar				; Print the flag symbol
	inc		HL						; Point to the next symbol
	
	; Add/Substract
	ld		A,(HL)					; Load the lowercase flag symbol
	bit		Negative,C				; Check to the associated bit is set or not
	jr		z,FlagNegativeClear		; If it's Set, then print lower case
	call	UpperCase				; Else, print upper case
FlagNegativeClear:
	call	PrintChar				; Print the flag symbol
	inc		HL						; Point to the next symbol
	
	; Carry
	ld		A,(HL)					; Load the lowercase flag symbol
	bit		Carry,C					; Check to the associated bit is set or not
	jr		z,FlagCarryClear		; If it's Set, then print lower case
	call	UpperCase				; Else, print upper case
FlagCarryClear:
	call	PrintChar				; Print the flag symbol
	inc		HL						; Point to the next symbol

	call	PrintCRLF

	pop		IY
	pop		IX
	pop		HL
	pop		DE
	pop		BC
	pop		AF
	ret


;  ____                  
; |  _ \   _   _   _ __  
; | |_) | | | | | | '_ \ 
; |  _ <  | |_| | | | | |
; |_| \_\  \__,_| |_| |_|


; *********************************************************************************************************************
; Executes code at a specific address, clearing the registers at the beginning
; Parameter:	[AAAA], where AAAA is an optional address to execute from. Defaults to CurrentAddress
; *********************************************************************************************************************

RunCode:
	ld		HL,(BufferPointer)		; Restore current buffer pointer in HL
	call	GetHexParameter			; Get the parameter
	jr		nc,RunEnd				; If there's an error in getting the parameter, then exit
	cp		0						; Is there a parameter?
	jr		nz,RunCallBC			; There's a valid parameter, then execute user code
	ld		BC,(CurrentAddress)		; Load the CurrentAddress in BC

RunCallBC:
	push	BC						; Put execution address in the stack, see bellow "ret" acting as a "call (BC)"
	ret								; Above "push BC" without "pop", "ret" acts as an indirect "call (BC)"

RunEnd:
	ret


;  ____           _        _          _       _                           
; / ___|    ___  | |_     / \      __| |   __| |  _ __    ___   ___   ___ 
; \___ \   / _ \ | __|   / _ \    / _` |  / _` | | '__|  / _ \ / __| / __|
;  ___) | |  __/ | |_   / ___ \  | (_| | | (_| | | |    |  __/ \__ \ \__ \
; |____/   \___|  \__| /_/   \_\  \__,_|  \__,_| |_|     \___| |___/ |___/


; *********************************************************************************************************************
; Set current address from the command prompt
;	- Input:	An optional address parameter, defaults to $0000
; *********************************************************************************************************************

SetAddress:
	push	AF
	push	BC
	push	DE
	push	HL
	
	ld		HL,(BufferPointer)		; Restore current buffer pointer ito HL
	call	GetHexParameter			; Get a parameter
	jr		nc,SetAddressEnd		; Exit routine if there was an error in the parameter
	cp		0						; Is there a parameter returned?
	jr		z,SetAddressDefault		; If there is none, select default address
	ld		(CurrentAddress),BC		; Save address in parameter (BC or C) in CurrentAddress global variable
	jr		SetAddressEnd

SetAddressDefault:
	ld		HL,0					; Default address is $0000
	ld		(CurrentAddress),HL		; Save it in CurrentAddress global variable

SetAddressEnd:
	pop		HL
	pop		DE
	pop		BC
	pop		AF
	
	ret
	

;  ____           _     ____                    _    
; / ___|    ___  | |_  | __ )    __ _   _ __   | | __
; \___ \   / _ \ | __| |  _ \   / _` | | '_ \  | |/ /
;  ___) | |  __/ | |_  | |_) | | (_| | | | | | |   < 
; |____/   \___|  \__| |____/   \__,_| |_| |_| |_|\_\


; *********************************************************************************************************************
; Set current bank from the command prompt
;	- Input:	An optional byte parameter, defaults to 0
; *********************************************************************************************************************
; Wishlist:
;	- Validation, only a nibble, and only 0-E
;	- Choice of BCD?

SetBank:
	push	AF
	push	BC
	push	DE
	push	HL
	
	ld		HL,(BufferPointer)		; Restore current buffer pointer ito HL
	call	GetHexParameter			; Get a parameter
	jr		nc,SetBankEnd			; Exit routine if there was an error in the parameter
	cp		0						; Is there a parameter returned?
	jr		z,SetBankDefault		; If there is none, select default bank
	cp		2
	jr		z,SetBankError
	
	ld		A,C
	cp		$0F
	jr		nc,SetBankError
	ld		(CurrentBank),A			; Save nibble in parameter (C) in CurrentBank global variable
	out		(BankSelect),A			; Sets bank number to value in accumulator
	jr		SetBankEnd

SetBankDefault:
	ld		A,0						; Default bank is 0
	ld		(CurrentBank),A			; Save it in CurrentBank global variable
	out		(BankSelect),A			; Sets bank number to value in accumulator
	jr		SetBankEnd

SetBankError:
	call	InvalidBank
	
SetBankEnd:
	pop		HL
	pop		DE
	pop		BC
	pop		AF
	
	ret
	
	
;  ____                  ___            __         
; / ___|   _   _   ___  |_ _|  _ __    / _|   ___  
; \___ \  | | | | / __|  | |  | '_ \  | |_   / _ \ 
;  ___) | | |_| | \__ \  | |  | | | | |  _| | (_) |
; |____/   \__, | |___/ |___| |_| |_| |_|    \___/ 
;          |___/                                   

; *********************************************************************************************************************
; Prints information about the ZedEighty (WiP)
; *********************************************************************************************************************

SysInfo:
	push	HL
	ld		HL,SysInfoMsg			; Point the the text message
	call	PrintString				; Print first line
	call	PrintLine				; Print a line
	call	PrintString				; Print the rest
	
	; Speed in MHz
	call	PrintString
	
	; Free RAM
	push	HL
	ld		HL,BytesFree			; Load the amount of bytes free
	call	PrintDec				; Print decimal value
	pop		HL
	call	PrintString
	
	pop		HL
	ret


; __        __         _   _          
; \ \      / /  _ __  (_) | |_    ___ 
;  \ \ /\ / /  | '__| | | | __|  / _ \
;   \ V  V /   | |    | | | |_  |  __/
;    \_/\_/    |_|    |_|  \__|  \___|
;
; *********************************************************************************************************************
; Write up to 8 bytes into memory
; *********************************************************************************************************************

Write:
	push 	AF
	push	BC
	push	DE
	push	HL
	
	ld		HL,(BufferPointer)		; Restore current buffer pointer in HL
	
WriteGetAddress:
	call	GetHexParameter			; Get the first parameter, start address
	jp		nc,WriteEnd				; Exit routine if there was an error in the parameter
	cp		0						; Is there a first parameter?
	jr		z,WriteNoParameter		; No, then print error message
	push	BC						; Store start address that's in BC
	pop		DE						; Into DE

WriteFirstByte:
	call	GetHexParameter			; Get the second parameter, byte to write
	jr		nc,WriteEnd				; Exit routine if there was an error in the parameter
	cp		0						; Is there a second parameter?
	jr		z,WriteNoParameter		; No, then print error message
	cp		2						; Is it bigger then a byte?
	jr		nc,WriteTooManyDigits	; Yes, then print error
	ld		A,C						; Transfer byte in A
	ld		(DE),A					; Save the byte
	inc		DE						; Point to the next location
	ld		(CurrentAddress),DE		; Set CurrentAddress

WriteRemainingBytes:
	call	GetHexParameter			; Get the second parameter, byte to write
	jr		nc,WriteEnd				; Exit routine if there was an error in the parameter
	cp		0						; Is there another parameter?
	jr		z,WriteEnd				; No, then exit
	cp		2						; Is it bigger then a byte?
	jr		nc,WriteTooManyDigits	; Yes, then print error
	ld		A,C						; Transfer C in accumulator to transfer in it in RAM
	ld		(DE),A					; Save the byte
	inc		DE						; Point to the next location
	ld		(CurrentAddress),DE		; Set CurrentAddress
	jr		WriteRemainingBytes		; See if there are other bytes

WriteTooManyDigits:
	call	DecErrorPointer			; Back up pointer one
	call	PrintErrorPointer		; Print's pointer to actual error in command line
	call	TooManyDigits			; Print invalid number of digits message	
	jr		WriteEnd
	
WriteNoParameter:
	call	NoParameter
	
WriteEnd:
	pop		HL
	pop		DE
	pop		BC
	pop		AF
	ret


;  _____                           _      _   _   ____                      
; |__  /   ___   _ __    ___      / \    | | | | |  _ \    __ _   _ __ ___  
;   / /   / _ \ | '__|  / _ \    / _ \   | | | | | |_) |  / _` | | '_ ` _ \ 
;  / /_  |  __/ | |    | (_) |  / ___ \  | | | | |  _ <  | (_| | | | | | | |
; /____|  \___| |_|     \___/  /_/   \_\ |_| |_| |_| \_\  \__,_| |_| |_| |_|


; *********************************************************************************************************************
; Zero all the RAM, including all the RAM. Excludes shadow ROM (otherwise it will corrupt the BIOS), as well as
; vector pages.
; *********************************************************************************************************************

ZeroAllRam:
	push	AF
	push	BC
	push	DE
	push	HL
	
	ld		A,$E
ZeroLowRange:
	out		(BankSelect),A
	ld		HL,StartOfCode			; Load end address
	dec		HL
	ld		DE,InterruptVectorEnd	; Load start
	or		A						; Clear carry flag
	sbc		HL,DE					; HL = HL - DE
	push	HL						; Put result of byte count
	pop		BC						; Into the byte count register
	ld		HL,InterruptVectorEnd	; Set source address
	push	AF
	ld		A,0						; Grab byte to write
	ld		(HL),A					; Save it at the source address
	pop		AF
	ld		DE,InterruptVectorEnd	; Place destination address
	inc		DE
	ldir
	dec		A
	cp		$FF
	jr		nz,ZeroLowRange

ZeroHighRange:
	ld		HL,VectorTable			; Load end address
	dec		HL
	ld		DE,EndOfCode			; Load start
	or		A						; Clear carry flag
	sbc		HL,DE					; HL = HL - DE
	push	HL						; Put result of byte count
	pop		BC						; Into the byte count register
	ld		HL,EndOfCode			; Set source address
	ld		A,0						; Grab byte to write
	ld		(HL),A					; Save it at the source address
	ld		DE,EndOfCode			; Place destination address
	inc		DE
	ldir

	scf								; Set Carry, indicates no error to calling program

ZeroEnd:
	pop		HL
	pop		DE
	pop		BC
	pop		AF
	ret

