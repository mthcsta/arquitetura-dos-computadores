
;--------------------------------------------------------------------------------------------------------
; Este programa faz a leitura dos parametros passados na linha de comando ao chama-lo
; e os escreve na tela, quebrando linha para os seguintes casos encontrados:
;  > espaço
;  > virgula
;  > varias virgulas juntas resulta em 1 quebra de espaço
;--------------------------------------------------------------------------------------------------------


	; Declaração do modelo de segmentos
	.model		small
	
	; Declaração do segmento de pilha
	.stack

	; Declaração do segmento de dados
	.data
	
string	db	256 dup(32)

	; Declaração do segmento de código
	.code
	.startup
		
	lea		dx,string
	mov		cx,256
	call	ReadCommandLine
	; Coloque o restante do seu programa principal aqui!

	; CL -> incrementa toda vez que tiver uma virgula.
	; CH -> incrementa toda vez que tiver um espaço.

	lea bx,string					; aponta para string contendo o que foi passado na linha de comando 
	xor	cx, cx						; limpa cx 
	mov	cl, 1						; inicia programa com espaço ativo para caso inicie string com espaço.
	
main:
	mov		dl, [bx]				; Pega char 
	or		dl, 0					; Verifica se é de fim de string 
	je		mainExit				; se for, termina programa.
	
	cmp		dl, ' '					; Compara char com espaço 
	je		insertSpace				; se for, pula para rotulo que trata espaço.
	cmp		dl, ','					; Compara char com virgula 
	je		insertCommon			; se for, pula para rotulo que trata virgula. 
	cmp		dl, 9					; Compara char com tab 
	je		insertSpace				; se for, pula para rotulo que trata espaço.
		
	; caso nenhuma condição acima seja verdade:
	jmp		insertChar				; pula para inserção de char.
	
insertCommon:						; rotulo acessado somente quando passa por uma virgula.........
	inc		ch 						; ativa encontro de virgula 
	cmp		ch, 1					; compara se virgula é igual a 1, se sim, 
	jmp		nextStep				; pula para proxima iteração.
	xor		ch, ch					; limpa virgula.
	call	breakline				; quebra linha 
	jmp		nextStep				; pula para proxima iteração.

insertSpace:						; rotulo acessado somente quando passa por um espaço ou tab....
	cmp		cl, 1					; compara espaço com 1, se sim,
	je		nextStep				; pula para proxima iteração.
	inc		cl 						; Incrementa espaço encontrado
	call	breakline				; quebra linha 
	jmp		nextStep				; pula para proxima iteração.

insertChar:							; rotulo acessado somente quando passa por um char 
	dec		ch						; decrementa ch para condição cl == ch == 0
	cmp		cl, ch					; compara cl com ch
	jne		ignoreBreakline			; se não for igual, ignora quebra de linha 
	call	breakline				; quebra linha 
ignoreBreakline:
	xor		cx, cx					; limpa reg de virgula e espaço.
	call	writeChar				; escreve char.

nextStep:
	inc		bx						; proxima iteração.
	jmp		main

mainExit:
	.exit
	

;--------------------------------------------------------------------
; Entra: 	DL -> char ascii
;--------------------------------------------------------------------
writeChar	proc	near
	mov 	ah, 2
	int		21h
	ret 
writeChar	endp

;--------------------------------------------------------------------
; Função para uma saida de quebra de linha 
;--------------------------------------------------------------------
breakline proc near 
	push	dx
	push	bx
	
	mov dl, 13
	mov ah, 2
	int 21h
	
	mov dl, 10
	mov ah, 2
	int 21h
	
	pop		bx
	pop		dx
	ret
breakline endp
	
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
	end
;--------------------------------------------------------------------


	



