;  ____            _           
; |  _ \    __ _  | |_    __ _ 
; | | | |  / _` | | __|  / _` |
; | |_| | | (_| | | |_  | (_| |
; |____/   \__,_|  \__|  \__,_|
;
; ---------------------------------------------------------------------------------------------------------------------

BootMsg:
	db		"ZedEighty Project by Frederic Segard",CR,LF
	db		"www.youtube.com/@microhobbyist",CR,LF
	db		"www.github.com/FredericSegard",CR,LF,0
	db		"BIOS 0.7  (c)2023  ",0," bytes free",CR,LF,LF,0

CommandList:						; Commands must be in uppercase, and the jp opcode also acts as a delimiter
	db		"ADDR"					; Sets current address
	jp		SetAddress				;
	db		"BANK"					; Sets current bank
	jp		SetBank					;
	db		"BASIC"					; Tiny Basic
	jp		BASIC					;
	db		"CLS"					; Clear screen command
	jp		ClearScreen				;
	db		"COPY"					; Copy data from one place to another (destructive)
	jp		CopyBlock				;
	db		"DIAG"					; Test RAM (and eventually other system components)
	jp		Diagnostics				;
	db		"FILL"					; Fill a region of memory with a byte of data 
	jp		FillMemory				;
;	db		"FORTH"					; Camel Forth
;	jp		FORTH					;
	db		"DUMP"					; Hex dump command
	jp		HexDump					;
	db		"HALT"					; Halt the CPU
	jp		HaltCmd
	db		"LIST"					; List of commands
	jp		ListCmd					;
	db		"LOAD"					; Intel Hex load command
	jp		IntelHex				;
	db		"PEEK"					; Read a byte from I/O port
	jp		PeekCmd					;
	db		"POKE"					; Write a byte to I/O port
	jp		PokeCmd					;
	db		"REG"					; Prints the content of the registers
	jp		Registers				;
	db		"RUN"					; Execute a program in RAM
	jp		RunCode					;
	db		"SYSINFO"				; Info command
	jp		SysInfo					;
	db		"WRITE"					; Write up to 8 bytes of data
	jp		Write					;
	db		"ZERO"					; Zero all memory, including banks
	jp		ZeroAllRam				;
	db		EOT

ListOfCommands:
	;		"                                        "
	db		LF
	db		"Monitor Commands",CR,LF,0
	db		"- ADDR [AAAA]: Sets current address",CR,LF
	db		"- BANK [N]: Sets current bank",CR,LF
	db		"- BASIC: Nascom MS BASIC",CR,LF
	db		"- CLS: Clear screen",CR,LF
	db		"- COPY SSSS DDDD BBBB: Copy memory block",CR,LF
	db		"- DIAG: Diagnostics (RAM)",CR,LF
	db		"- DUMP [AAAA] [LL]: Memory hex dump",CR,LF
	db		"- FILL SSSS EEEE BB: Fill memory",CR,LF
;	db		"- FORTH: Camel Forth, by Brad Rodriguez",CR,LF
	db		"- LIST: List of commands",CR,LF
	db		"- LOAD: Intel Hex loader",CR,LF
	db		"- PEEK PP: Read a byte from I/O port",CR,LF
	db		"- POKE PP BB: Write a byte to I/O port",CR,LF
	db		"- REG: Z80 registers",CR,LF
	db		"- RUN [AAAA]: Execute a program",CR,LF
	db		"- SYSINFO: System information",CR,LF
	db		"- WRITE AAAA BB [BB]...: Write to RAM",CR,LF
	db		"- ZERO: Zero free RAM, banks included",CR,LF
	db		LF
	db		" * Type ? in command parameter for help",CR,LF
	db		LF,0

FlagBits:
	db		"szhvnc"				; Flag short hand. Use UpperCase to indicate set, else lowercase indicated clear
	
ClearScreenSeq:
	db		ESC, "[", "2", "J"		; Clears the screen
	db		ESC, "[", "0", "1", ";", "0", "1", "H", 0 ; Sets to home position
	
SysInfoMsg:
	;		"                                        "
	db		LF
	db		"ZedEighty System Information",CR,LF,0
	db		"- CPU:   Z84C00 Z80 @",0,"7.3728 MHz",CR,LF
	db		"- ROM:   64KB FLASH (Shadow ROM)",CR,LF
	db		"- RAM:   64KB SRAM, ",0," bytes free",CR,LF
	db		"- BANKS: 480KB (15x 32KB in lower RAM)",CR,LF
	db		"- UART:  Z84C40 SIO/0",CR,LF
	db		LF,0




;  __  __                                                 
; |  \/  |   ___   ___   ___    __ _    __ _    ___   ___ 
; | |\/| |  / _ \ / __| / __|  / _` |  / _` |  / _ \ / __|
; | |  | | |  __/ \__ \ \__ \ | (_| | | (_| | |  __/ \__ \
; |_|  |_|  \___| |___/ |___/  \__,_|  \__, |  \___| |___/
;                                      |___/
; ---------------------------------------------------------------------------------------------------------------------
; SYSTEM MESSAGES, AND ERROR MESSAGES


ParseInvalidErr:		db	"Command not found or invalid syntax",CR,LF,0
InvalidHexDigitErr:		db	"Invalid hexadecimal digit in parameter",CR,LF,0
TooManyDigitsErr:		db	"Too many number of digits in parameter",CR,LF,0
MissingParameterErr:	db	"Missing Parameter(s)",CR,LF,0
UnrecognizedParamErr:	db	"Unrecognized parameter",CR,LF,0
StartGreaterEndErr:		db	"Start greater than end address",CR,LF,0
IntelHexUnsupportedErr:	db	"Record type unsupported: ",0
InvalidVectorRangeErr:	db	"Reserved vector/stack area",CR,LF,0
ReservedBiosAreaErr:	db	"Reserved BIOS range",CR,LF,0
RangeTooSmallErr:		db	"Range is null or too small",CR,LF,0
InvalidBankNumberErr:	db	"Invalid bank number ($0-$E)",CR,LF,0
InvalidDecimalNumberErr	db	"Invalid decimal number",CR,LF,0
NumberOutOfRangeErr		db	"Number is out of range",CR,LF,0
BadMemory1Err:			db	"Error at ",0
BadMemory2Err:			db	", got ",0,", expected ",0
NothingToCopyErr:		db	"Nothing to copy",CR,LF,0

TestingBankNumberMsg:	db	"Testing Bank RAM #",0
TestingHighRamMsg:		db	"Testing High RAM",CR,LF,0
MemoryTestPassedMsg:	db	"Memory test Passed",CR,LF,0
RangeMsg:				db	"Address range:",0
IntelHexFinishedMsg:	db	"File transfer: ",0
IntelHexSuccessMsg:		db	"unsuccessful",CR,LF,0
IntelHexLoadMsg:		db	"Load a program using Intel Hex format",CR,LF,"Press ESC to cancel",CR,LF,0
IntelHexAbortedMsg:		db	"Transfer aborted by user",CR,LF,0
DownloadedBytesMsg:		db	" bytes transfered",CR,LF,0

;					"                                        "
FillHelp:		db	"Fills a range of memory with a byte.",CR,LF
				db	"Protects the vector areas and the BIOS.",CR,LF
				db	"Usage: Fill 2400 A400 8A",CR,LF,LF,0

HexDumpHelp:	db	"Displays the content of memory. The",CR,LF
				db	"second parameter is the number of lines.",CR,LF
				db	"Usage: DUMP 1000 4",CR,LF,LF,0

IntelHexHelp:	db	"Load IntelHex binary programs via the",CR,LF
				db	"SIO Port A.",CR,LF
				db	"Usage: LOAD",CR,LF,LF,0

Range:
	push	HL
	ld		HL,RangeMsg
	call	PrintString
	pop		HL
	ret

InvalidVectorRange:
	push	HL
	ld		HL,InvalidVectorRangeErr
	call	PrintString
	pop		HL
	ret

RangeTooSmall:
	push	HL
	ld		HL,RangeTooSmallErr
	call	PrintString
	pop		HL
	ret

BiosRange:
	push	HL
	ld		HL,ReservedBiosAreaErr
	call	PrintString
	pop		HL
	ret

RangeInverted:
	push	HL
	ld		HL,StartGreaterEndErr
	call	PrintString
	pop		HL
	ret

NoParameter:
	push	HL
	call	PrintErrorPointer
	ld		HL,MissingParameterErr
	call	PrintString
	pop		HL
	ret

InvalidBank:
	push	HL
	ld		HL,InvalidBankNumberErr
	call	PrintString
	pop		HL
	ret

TooManyDigits:
	push	HL
	ld		HL,TooManyDigitsErr
	call	PrintString
	pop		HL
	ret

InvalidHexDigit:
	push	HL
	ld		HL,InvalidHexDigitErr
	call	PrintString
	pop		HL
	ret

NumberOutOfRange:
	push	HL
	ld		HL,NumberOutOfRangeErr
	call	PrintString
	pop		HL
	ret

InvalidDecimalNumber:
	push	HL
	ld		HL,InvalidDecimalNumberErr
	call	PrintString
	pop		HL
	ret

NothingToCopy:
	push	HL
	call	DecErrorPointer
	call	PrintErrorPointer
	ld		HL,NothingToCopyErr
	call	PrintString
	pop		HL
	ret
	