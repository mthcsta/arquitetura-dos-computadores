;--------------------------------------------------------------------------------------------------------
; Este programa faz a leitura do segundo parametro da linha de comando(sendo o primeiro o programa)
; e o interpreta como nome para um arquivo de abertura. Abre um ponteiro para o arquivo e vai
; percorrendo-o enquanto escreve os caracteres do arquivo na forma de hexadecimal.
;--------------------------------------------------------------------------------------------------------


	; Declaração do modelo de segmentos
	.model		small
	
	; Declaração do segmento de pilha
	.stack

	; Declaração do segmento de dados
	.data
	
string		db	256 dup(?)
stringError	db	'Arquivo nao encontrado.',0
FileBuffer	db		10 		dup(?)
	; Declaração do segmento de código
	.code
	.startup

	lea		dx,string
	mov		cx,256
	call	ReadCommandLine	
	; Coloque o restante do seu programa principal aqui!
	
	; abrindo arquivo 
	lea		dx,string+1
	call	fopen

	jnc		start
	lea		bx, stringError
	call	printf_s	
	jmp		End_readchar
	
start:
	
	mov		cl, 0 			; auxiliar para contagem de caracteres escritos por linha 
readchar:					
	push	cx				; coloca cx na pilha para guardar valor CL 
	
	call	getChar			; captura char do arquivo 
	
	cmp		ax,0			; verifica se capturou mesmo
	je		End_readchar	; caso não, termina laço.
	
	mov		al,dl			; passa caractere pego para o reg AL, param de printHex.
	call	printHex		; chama função que printa char em hexa 
	
	pop 	cx 				; pega pega valor de CL da pilha. 
	
	inc		cl				
	
	cmp		cl, 16			; 16 pois cada caractere ocupa 2 espaços (32 chars por linha)
	jl		readchar		; se for menor apenas escreve caractere.
	
	xor		cl, cl			; Limpa contador de caracteres escritos 
	call	breakline		; quebra linha 
	
	jmp		readchar		; fim do laço.

End_readchar:
	call	fclose
	.exit
	
	; Coloque suas subrotinas a partir daqui!

;---------------------------------------------------
;Entrada: 	AL -> caractere ascii decimal 
;Saida: 	Escreve na tela caractere em hexa
;---------------------------------------------------
printHex	proc	near 
	push	ax				; Insere na pilha o caractere ascii para modificação abaixo
	
	mov		cl, 4			; Quantidade de bits para shift
	shr		ax, cl			; Shift caractere ascii decimal >> 4 
	call	dtoh			; Chama conversor de decimal(int) para hexa(string)
	mov		ah, 2			; Define o tipo de interrupção
	int 	21h 			; Chama interrupção de escrever na tela 
	
	pop 	ax 				; Volta pilha com o caractere ascii antes da modificação 
	
	and		ax, 15			; Pega os bits 4 primeiros bits do caractere passado 
	call	dtoh			; Chama conversor de decimal(int) para hexa(string) 
	mov		ah, 2			; Define o tipo de interrupção
	int		21h				; Chama interrupção de escrever na tela 
	
	ret
printHex	endp
	
;---------------------------------------------------
; Entra: AL -> numero decimal 
; Saida: DL -> numero ascii 
;---------------------------------------------------
dtoh	proc	near
	mov		dl, al 			; passa numero para reg de retorno 
	
	cmp		dl, 10			; numero decimal >= 10
	jge		useLetter_dtoh	; Então escreve com letra 
	
	add		dl, '0'			; passa para ascii 	
	jmp		End_dtoh		; pula para fim de dtoh.
	
useLetter_dtoh:		
	add		dl, '7'			; passa para ascii, '7' pois quando dl=11, dl+'7'(55) = 66 = B.

End_dtoh:
	ret
dtoh	endp

;--------------------------------------------------------------------
; Escreve uma quebra de linha na tela 
;--------------------------------------------------------------------
breakline	proc 	near
	mov dl,13
	mov ah,2
	int 21h
	mov dl,10
	mov ah,2
	int 21h
	ret
breakline	endp
;
;--------------------------------------------------------------------
; ES:xx -> segmento onde está o PSP
; DS:DX -> endereço do string de destino da linha de comando
; CX -> número máximo de caracteres do string de destino
;
; AX <- número de caracteres copiados para o string
;
; AX=0
; di=DX
; if(CX>1) {
;	si=80H
;	CX = MIN(CX,[ES:si])
;	if (CX!=0) {
;		si++
;		do {
;			[DS:di]=[ES:si]
;			di++
;			si++
;		}while(--cx != 0)
;	}
; }
; [di]=0
;--------------------------------------------------------------------
ReadCommandLine	proc	near

	mov		ax,0				; AX=0
	mov		di,dx				; di=DX
	
	cmp		cx,1				; if(CX>1) {
	jle		rdcl1

	mov		si,80h				;	si=80H
	
	mov		bh,0				;	CX = MIN(CX,[ES:si])
	mov		bl,es:[si]
	cmp		cx,bx
	jle		rdcl3
	mov		cx,bx
rdcl3:

	cmp		cx,0				;	if (CX!=0) {
	je		rdcl1

	inc		si					;		si++
	
rdcl2:
	mov		al,es:[si]			;		do { [DS:di]=[ES:si]; di++; si++; } while(--cx != 0)
	mov		[di],al
	inc		di
	inc		si
	loop	rdcl2
								;	}
								; }
	
rdcl1:
	mov		byte ptr [di],0		; [di]=0
	ret

ReadCommandLine	endp	

;--------------------------------------------------------------------
;Função	Abre o arquivo cujo nome está no string apontado por DX
;		boolean fopen(char *FileName -> DX)
;Entra: DX -> ponteiro para o string com o nome do arquivo
;Sai:   BX -> handle do arquivo
;       CF -> 0, se OK
;--------------------------------------------------------------------
fopen	proc	near
	mov		al,0
	mov		ah,3dh
	int		21h
	mov		bx,ax
	ret
fopen	endp
;--------------------------------------------------------------------
;Entra:	BX -> file handle
;Sai:	CF -> "0" se OK
;--------------------------------------------------------------------
fclose	proc	near
	mov		ah,3eh
	int		21h
	ret
fclose	endp
;--------------------------------------------------------------------
;Função	Le um caractere do arquivo identificado pelo HANLDE BX
;		getChar(handle->BX)
;Entra: BX -> file handle
;Sai:   dl -> caractere
;		AX -> numero de caracteres lidos
;		CF -> "0" se leitura ok
;--------------------------------------------------------------------
getChar	proc	near
	mov		ah,3fh
	mov		cx,1
	lea		dx,FileBuffer
	int		21h
	mov		dl,FileBuffer
	ret
getChar	endp


printf_s	proc	near
	mov		dl,[bx]
	cmp		dl,0
	je		ps_1

	push	bx
	mov		ah,2
	int		21H
	pop		bx

	inc		bx		
	jmp		printf_s
	
ps_1:
	ret
printf_s	endp



;--------------------------------------------------------------------
	end
;--------------------------------------------------------------------


	



