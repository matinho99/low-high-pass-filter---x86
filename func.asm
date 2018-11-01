;=====================================================================
; ARKO - filt dolno/gorno-przepustowy (x86)
;
; Autor: Mateusz Osowiecki
;        int func(char *in, char *out, char *filterType);
;
;=====================================================================

section	.text
global  func

section	.data
bytesPerRow	DD 0
imageHeight	DD 0
fileSize	DD 0
offsetToPixelArray	DD 0
numberOfIters	DD 0
lowPass		DD 1, 1, 1, 1, 2, 1, 1, 1, 1
highPass	DD 0, -1, 0, -1, 5, -1, 0, -1, 0
filter		DD 0, 0, 0, 0, 0, 0, 0, 0, 0
loopIter	DD 0


func:
	push	ebp
	mov	ebp, esp
	; przyklad zaladowania adresów obu argumentów do eax oraz ebx
	mov	eax, DWORD [ebp+8]	;adres *in do ebx	
	mov	ebx, DWORD [ebp+12]	;adres *out do eax

	mov	dl, [eax]
	cmp	dl, 0
	mov	esi, DWORD [eax+2]
	mov	[fileSize], esi		;store file size
	mov	esi, DWORD [eax+10]
	mov	[offsetToPixelArray], esi	;store offset to array of pixels
	mov	esi, DWORD [eax+18]
	imul	esi, esi, 3
	mov	[bytesPerRow], esi 	;store amount of bytes in row
	mov	esi, DWORD [eax+22]
	mov	[imageHeight], esi	;store image height
	mov	ecx, 0
bmpCopyLoop:				;copy input file contents to output file
	mov	dl, [eax]
	cmp	ecx, [fileSize]
	je	filterChoice
	mov	[ebx], dl
	inc	eax
	inc	ebx
	inc	ecx
	jmp	bmpCopyLoop
filterChoice:				;choice of filter
	mov	edx, 0	
	mov	ecx, DWORD [ebp+16]
	cmp	BYTE [ecx], '1'
	je	setLow
	cmp	BYTE [ecx], '2'
	je	setHigh
	jmp	end
setLow:					;setting low-pass
	mov	ecx, DWORD [lowPass+4*edx]
	mov	DWORD [filter+4*edx], ecx
	inc	edx
	cmp	edx, 9
	je	calculateNumberOfIters
	jmp	setLow	
setHigh:				;setting high-pass
	mov	ecx, DWORD [highPass+4*edx]
	mov	DWORD [filter+4*edx], ecx
	inc	edx
	cmp	edx, 9
	je	calculateNumberOfIters
	jmp	setHigh
calculateNumberOfIters:			;calculating number of iterations
	mov eax, [imageHeight]
	sub eax, 2
	mov ebx, [bytesPerRow]
	sub ebx, 6
	imul eax, ebx
	mov [numberOfIters], eax
loopInit:				;prepare for filter calculations
	mov edi, DWORD [ebp+8]
	add edi, [offsetToPixelArray]
	add edi, [bytesPerRow]
	add edi, 3
	mov esi, DWORD [ebp+12]
	add esi, [offsetToPixelArray]
	add esi, [bytesPerRow]
	add esi, 3
	mov ecx, 0
loop:					;calculating each pixel byte value in output file
	mov eax, 0
	mov ebx, 0
	mov edx, 0

	mov edx, [filter+0]		;lower-left neighbour pixel byte
	sub edi, [bytesPerRow]
	sub edi, 3
	mov bl, BYTE [edi]
	imul ebx, edx
	add eax, ebx
	mov ebx, 0

	mov edx, [filter+4]		;lower-center neighbour pixel byte
	add edi, 3
	mov bl, BYTE [edi]
	imul ebx, edx
	add eax, ebx
	mov ebx, 0

	mov edx, [filter+8]		;lower-right neighbour pixel byte
	add edi, 3
	mov bl, BYTE [edi]
	imul ebx, edx
	add eax, ebx
	mov ebx, 0

	mov edx, [filter+12]		;center-left neighbour pixel byte
	add edi, [bytesPerRow]
	sub edi, 6
	mov bl, BYTE [edi]
	imul ebx, edx
	add eax, ebx
	mov ebx, 0

	mov edx, [filter+16]		;center-center neighbour pixel byte
	add edi, 3
	mov bl, BYTE [edi]
	imul ebx, edx
	add eax, ebx
	mov ebx, 0

	mov edx, [filter+20]		;center-right neighbour pixel byte
	add edi, 3
	mov bl, BYTE [edi]
	imul ebx, edx
	add eax, ebx
	mov ebx, 0

	mov edx, [filter+24]		;upper-left neighbour pixel byte
	add edi, [bytesPerRow]
	sub edi, 6
	mov bl, BYTE [edi]
	imul ebx, edx
	add eax, ebx
	mov ebx, 0

	mov edx, [filter+28]		;upper-center neighbour pixel byte
	add edi, 3
	mov bl, BYTE [edi]
	imul ebx, edx
	add eax, ebx
	mov ebx, 0

	mov edx, [filter+32]		;upper-right neighbour pixel byte
	add edi, 3
	mov bl, BYTE [edi]
	imul ebx, edx
	add eax, ebx
	mov ebx, 0

	sub edi, [bytesPerRow]
	sub edi, 3
endLoop:
	mov	edx, DWORD [ebp+16]
	cmp	BYTE [edx], '2'		;if high-pass, then no need to divide
	je	Norm1
	xor	edx, edx
	mov	ebx, 10
	idiv ebx
Norm1:					;if lower than 0
	cmp eax, 0
	jge Norm2
	mov eax, 0
Norm2:			;if greater than 255
	cmp eax, 255
	jle afterNorm
	mov eax, 255
afterNorm:	
	mov [esi], al
	mov ebx, [bytesPerRow]
	sub ebx, 6
	inc edi
	inc esi
	inc ecx
	inc DWORD [loopIter]
	cmp ecx, ebx
	je nextRow
	jmp endLoop2
nextRow:		;calculate next row first calculated pixel byte
	add edi, 6
	add esi, 6
	mov ecx, 0
endLoop2:
	mov eax, [loopIter]
	cmp eax, [numberOfIters]
	jle loop
end:
	pop	ebp
	ret

;============================================
; STOS
;============================================
;
; wieksze adresy
; 
;  |                             |
;  | ...                         |
;  -------------------------------
;  | parametr funkcji - char *in | EBP+8
;  -------------------------------
;  | adres powrotu               | EBP+4
;  -------------------------------
;  | zachowane ebp               | EBP, ESP
;  -------------------------------
;  | ... tu ew. zmienne lokalne  | EBP-x
;  |                             |
;
; \/                         \/
; \/ w ta strone rosnie stos \/
; \/                         \/
;
; mniejsze adresy
;
;
;============================================
