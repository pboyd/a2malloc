_ALLOC_LINK EQU #0
_ALLOC_SIZE EQU #1

* _AllocGetField <pointer>;<field>
* Loads a value from a free block header field into the accumulator.
* Clobbers Y
_AllocGetField	MAC
		LDY ]2
		LDA (]1),Y
		<<<

* _AllocSetFieldA <pointer>;<field>
* Loads the value of the accumulator to a header field.
* Clobbers Y
_AllocSetFieldA	MAC
		LDY ]2
		STA (]1),Y
		<<<

* _AllocSetField <pointer>;<field>;<value>
* Loads a value into a header field.
* Clobbers A and Y
_AllocSetField	MAC
		LDA ]3
		_AllocSetFieldA ]1;]2
		<<<

* _CopyPointer <src>;<dest>
* Copies 2 bytes from the location pointed to in src to the location pointed to
* in dest.
_CopyPointer	MAC
		LDY #0
		LDA (]1),Y
		STA (]2),Y
		INY
		LDA (]1),Y
		STA (]2),Y
		<<<

* CopyWord <src>;<dest>
* Copies 2 bytes at the src address to the destination address.
_CopyWord	MAC
		LDA ]1
		STA ]2
		LDA ]1+1
		STA ]2+1
		<<<

* PushWord <address>
* Pushes 2-bytes starting at the address given to the stack.
* Clobbers X
_PushWord	MAC
		LDX ]1
		PHX
		LDX ]1+1
		PHX
		<<<

* PopWord <address>
* Reverses PushWord
* Clobbers X
_PopWord	MAC
		PLX
		STX ]1+1
		PLX
		STX ]1
		<<<

* _AllocLink <in>;<out>
* Calculates the address of the next free block after <in> and writes it to
* <out>. Sets <out> to 0 and sets Z if there is no next block.
_AllocLink	MAC
		* The free block header stores the number of bytes to the next
		* free block, not a pointer. So we need to take the address of
		* the current block and add the size to it.

		_AllocGetField ]1;_ALLOC_LINK

		CMP #0				; Is the link null?
		BEQ Fail			; If so, there is no next block.

		* Copy the input pointer to the output pointer. Taking care to
		* preserve the free block size stored in the accumulator.
		PHA
		_CopyWord ]1;]2
		PLA

		* Add the link in A to the output pointer.
		CLC
		ASL A
		ADC ]2
		STA ]2
		LDA #0
		ADC ]2+1
		STA ]2+1
		JMP Success

Fail
		* Set the output pointer to all zeros when there's no next
		* block.
		LDY #0
		LDA #0
		STA (]2),Y
		INY
		STA (]2),Y
		CMP #0		; Set ZF
		JMP End

Success
		LDA #1
		CMP #0		; Clear ZF
End		<<<

* AllocInit <PageCount>
*
* Initializes the free list. Before define AllocStart and AllocPointer.
* AllocStart must point to the beginning of the first page to be managed.
AllocInit   MAC
	    LDA AllocStart
	    STA AllocPointer
	    LDA AllocStart+1
	    STA AllocPointer+1

	    * X will count down to zero
	    LDX ]1

]Loop		
	    * Block 1
	    _AllocSetField AllocPointer;_ALLOC_SIZE;#0 ; Set size to 0.
	    _AllocSetField AllocPointer;_ALLOC_LINK;#1 ; Link to the next word.

	    * Block 2
	    _AllocSetField AllocPointer;_ALLOC_SIZE+2;#$7f ; Set size to the rest of the page
	    _AllocSetField AllocPointer;_ALLOC_LINK+2;#$7f ; Link to the next page.

	    DEX			; Check if we're done.
	    BEQ LoopEnd

	    INC AllocPointer+1	; Add 1 to the MSB of the pointer.
	    JMP ]Loop

LoopEnd
	    ; Set the link on the final block to 0.
	    _AllocSetField AllocPointer;_ALLOC_LINK+2;#0

	    <<<

* Location of our working memory. We'll use 4 bytes starting at this address.
AllocScratch	EQU $80

* Alloc reserves a portion of memory. A pointer to the start of reserved
* segment will be stored at the address of AllocPointer. The caller should set
* the accumulator to the number of words (2 bytes--not bytes).
*
* The most memory that can be allocated is 127 words (254 bytes).
Alloc		
		* Use Knuth's names for a few memory locations.
:Q		EQU AllocScratch
:P		EQU AllocPointer
:N		EQU AllocScratch+2
:K		EQU AllocScratch+3

		_PushWord AllocScratch	    ; Store the value of our scratch
		_PushWord AllocScratch+2    ; space, so we can restore it later.

		STA :N

		* Q <- LOC(AVAIL)
		_CopyWord AllocStart;:Q

]Loop		
		_AllocLink :Q;:P	; P <- LINK(Q)
		BEQ [NoSpace		; End of the list? Not enough space.

		* Put SIZE(P) in A
		_AllocGetField :P;_ALLOC_SIZE

		CMP :N			; Is SIZE(P) >= N?
		BCS [Reserve

		* Set Q <- P and go again.
		_CopyWord :P;:Q
		JMP ]Loop

[Reserve
		* Find K = SIZE(P) - N
		SEC
		SBC :N
		STA :K

		CMP #0
		BEQ [RemoveNode

		* SIZE(P) = K
		_AllocSetFieldA :P;_ALLOC_SIZE

		JMP [SetPointer

[RemoveNode
		* To remove node P, make the previous node Q point to the node
		* after P.
		* Since we store the number of bytes between nodes this is
		* LINK(Q) += LINK(P)
		_AllocGetField :Q;_ALLOC_LINK
		LDY _ALLOC_LINK
		CLC
		ADC (:P),Y
		_AllocSetFieldA :Q;_ALLOC_LINK
		LDA :K

[SetPointer
		ASL
		CLC
		ADC :P
		STA :P
		LDA #0
		ADC :P+1
		STA :P+1

		_PopWord AllocScratch+2	; Reset our scratch space
		_PopWord AllocScratch

		LDA #1
		CMP #0		; Clear ZF

		RTS

[NoSpace	
		LDA #$0
		STA (:P),Y
		STA (:P+1),Y

		_PopWord AllocScratch+2	; Reset our scratch space
		_PopWord AllocScratch

		CMP #$0		; Set ZF

AllocEnd	RTS
