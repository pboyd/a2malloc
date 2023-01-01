* CopyPointer <src>;<dest>
* Copies 2 bytes from the location pointed to in src to the location pointed to
* in dest.
CopyPointer	MAC
		LDY #0
		LDA (]1),Y
		STA (]2),Y
		INY
		LDA (]1),Y
		STA (]2),Y
		<<<

* CopyWord <src>;<dest>
* Copies 2 bytes at the src address to the destination address.
CopyWord	MAC
		LDA ]1
		STA ]2
		LDA ]1+1
		STA ]2+1
		<<<

* PushWord <address>
* Pushes 2-bytes starting at the address given to the stack.
* Clobbers X
PushWord	MAC
		LDX ]1
		PHX
		LDX ]1+1
		PHX
		<<<

* CmpWords <word1>;<word2>
* Compares the values in two words, simulating word1 - word2.
* Sets Z if they are equal. Sets C if word1 >= word2.
CmpWords    MAC
	    LDA ]1+1	; Compare MSB
	    CMP ]2+1
	    BNE Done	; If the MSB's are unequal, we're done.

	    LDA ]1	; Compare LSB
	    CMP ]2
Done	    <<<

* PopWord <address>
* Reverses PushWord
* Clobbers X
PopWord	MAC
	PLX
	STX ]1+1
	PLX
	STX ]1
	<<<

COUT	EQU $FDED
PrintLn	MAC
	LDX #$0

]Loop	    
	INX

	LDA ]1,X
	JSR COUT

	CPX ]1	
	BEQ End	
	JMP ]Loop

	LDA #$8D
	JSR COUT
	<<<
