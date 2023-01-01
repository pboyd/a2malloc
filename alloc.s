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

* _AllocLink <in>;<out>
* Calculates the address of the next free block after <in> and writes it to
* <out>. Sets <out> to 0 and sets Z if there is no next block.
_AllocLink	MAC
		* The free block header stores the number of bytes to the next
		* free block, not a pointer. So we need to take the address of
		* the current block and add the size to it.

		_AllocGetField ]1;_ALLOC_LINK
		CMP #0 ; Is this needed?
		BEQ Fail			; No next block if link is null

		* Copy the input pointer to the output pointer. Taking care to
		* preserve the free block size stored in the accumulator.
		PHA
		CopyWord ]1;]2
		PLA

		* Add the link in A to the output pointer.
		CMP #$80
		BEQ AddFullPage

		ASL A
		CLC
		ADC ]2
		STA ]2
		LDA #0
		ADC ]2+1
		STA ]2+1
		JMP Success

AddFullPage
		INC ]2+1	; Add 1 to the MSB
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

* Location of our working memory. Alloc uses 4 bytes starting at this address.
* Free uses 6 bytes. Both Alloc and Free will restore the original contents
* before returning.
AllocScratch	EQU $80

* Alloc reserves a portion of memory. A pointer to the start of reserved
* segment will be stored at the address of AllocPointer. The caller should set
* the accumulator to the number of 2-byte words it needs.
*
* The most memory that can be allocated at one time is 127 words (254 bytes).
Alloc		
		* Use Knuth's names for a few memory locations.
]Q		EQU AllocScratch
]P		EQU AllocPointer
]N		EQU AllocScratch+2
]K		EQU AllocScratch+3

		PushWord AllocScratch	    ; Store the value of our scratch
		PushWord AllocScratch+2    ; space, so we can restore it later.

		STA ]N

		* Q <- LOC(AVAIL)
		CopyWord AllocStart;]Q

]Loop		
		_AllocLink ]Q;]P	; P <- LINK(Q)
		BEQ [NoSpace		; End of the list? Not enough space.

		* Put SIZE(P) in A
		_AllocGetField ]P;_ALLOC_SIZE

		CMP ]N			; Is SIZE(P) >= N?
		BCS [Reserve

		* Set Q <- P and go again.
		CopyWord ]P;]Q
		JMP ]Loop

[Reserve
		* Find K = SIZE(P) - N
		SEC
		SBC ]N
		STA ]K

		CMP #0
		BEQ [RemoveNode

		* SIZE(P) = K
		_AllocSetFieldA ]P;_ALLOC_SIZE

		JMP [SetPointer

[RemoveNode
		* To remove node P, make the previous node Q point to the node
		* after P.
		* Since we store the number of bytes between nodes this is
		* LINK(Q) += LINK(P)
		_AllocGetField ]Q;_ALLOC_LINK
		LDY _ALLOC_LINK
		CLC
		ADC (]P),Y
		_AllocSetFieldA ]Q;_ALLOC_LINK
		LDA ]K

[SetPointer
		ASL
		CLC
		ADC ]P
		STA ]P
		LDA #0
		ADC ]P+1
		STA ]P+1

		PopWord AllocScratch+2	; Reset our scratch space
		PopWord AllocScratch

		LDA #1
		CMP #0		; Clear ZF

		RTS

[NoSpace	
		LDA #$0
		STA (]P),Y
		STA (]P+1),Y

		PopWord AllocScratch+2	; Reset our scratch space
		PopWord AllocScratch

		CMP #$0		; Set ZF

AllocEnd	RTS

* Free adds memory back to the free list. AllocPointer should point to the
* memory to be freed, and the number of words (2 bytes) should be in the
* accumulator.
*
* This should only be called with memory which was reserved by Alloc.
Free
	* Use Knuth's names for a few memory locations.
]P0	EQU AllocPointer
]Q	EQU AllocScratch
]P	EQU AllocScratch+2


	* Save the old values in the scratch space.
	PushWord AllocScratch
	PushWord AllocScratch+2
	PushWord AllocScratch+4

	PHA			; Save N to the stack.

	CopyWord AllocStart;]Q	; Q <- LOC(AVAIL)

]Loop
	_AllocLink ]Q;]P	; P <- LINK(Q)
	BEQ [CheckUpper		; End of the list? Free it.

	CmpWords ]P;]P0		; Is P > P0?
	BCS [CheckUpper

	CopyWord ]P;]Q		; Set Q <- P and go again.
	JMP ]Loop

[CheckUpper
	* After this point: Q < P0 < P

	* P0End = P0 + 2N
]P0End	EQU AllocScratch+4
	PLA		; Load N from the stack,
	PHA		; but put it right back.
	ASL		; Convert N from words to bytes.
	CLC
	ADC ]P0
	STA ]P0End
	LDA #0
	ADC ]P0+1
	STA ]P0End+1

	CmpWords ]P;]P0End	; If P0 + End != P
	BNE [DontAbsorbP

	* If P has a size of zero it's the new page marker, so don't absorb it.
	_AllocGetField ]P;_ALLOC_SIZE
	CMP #0
	BEQ [DontAbsorbP

	* Absord P in P0. First step is to set LINK(P0) = LINK(P), but we store
	* sizes, not pointers, so the operation is LINK(P0) = LINK(P) + ((LOC(P) - LOC(P0)) >> 1)
	LDY _ALLOC_LINK
	LDA ]P
	SEC
	SBC ]P0
	LSR
	CLC
	ADC (]P),Y
	STA (]P0),Y

	* Second step to absorb P: N = N + SIZE(P)
	PLA		    ; N is on the stack
	LDY _ALLOC_SIZE	    ; Add SIZE(P)
	ADC (]P),Y
	PHA		    ; Put N back on the stack.

	JMP [CheckLower

[DontAbsorbP
	* LINK(P0) = P, but since we use word sizes: (LOC(P) - LOC(P0)) / 2
	* Ignore MSB because we assume P and P0 are in the same page.
	LDA ]P
	SEC
	SBC ]P0
	LSR
	_AllocSetFieldA ]P0;_ALLOC_LINK

[CheckLower
	_AllocGetField ]Q;_ALLOC_SIZE	; Is Q the page boundry marker?
	;CMP #0 ???
	BEQ [DontAbsorbP0

	* Find Q + SIZE(Q)
]QEnd	EQU AllocScratch+4
	ASL
	CLC
	ADC ]Q
	STA ]QEnd
	LDA ]Q+1
	STA ]QEnd+1

	CmpWords ]P0;]QEnd
	BNE [DontAbsorbP0

	* Absord P0 into Q. First step find the new size of Q.
	PLA			; Get N from the stack.
	LDY _ALLOC_SIZE		; Find SIZE(Q) + N
	CLC
	ADC (]Q),Y
	STA (]Q),Y		; Set SIZE(Q)

	* Second step. Set LINK(Q) = LINK(P0) Rather:
	* LINK(Q) = LINK(P0) + ((LOC(P0) - LOC(Q)) >> 1)
	LDA ]P0
	SEC
	SBC ]Q
	LSR
	CLC
	LDY _ALLOC_LINK
	ADC (]P0),Y
	STA (]Q),Y

	JMP [Cleanup

[DontAbsorbP0
	* SIZE(P0) = N
	PLA
	_AllocSetFieldA ]P0;_ALLOC_SIZE

	* LINK(Q) = P0. Rather, LINK(Q) = (LOC(P0) - LOC(Q)) >> 1
	LDA ]P0
	SEC
	SBC ]Q
	LSR
	_AllocSetFieldA ]Q;_ALLOC_LINK

[Cleanup
	PopWord AllocScratch+4
	PopWord AllocScratch+2
	PopWord AllocScratch
EndFree	RTS
