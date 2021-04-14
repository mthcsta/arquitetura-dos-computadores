;--------------------------------------------------------------------------------------------------------
; Este programa faz a leitura do segundo parametro da linha de comando(sendo o primeiro o programa)
; e o interpreta como nome para um arquivo de escrita e criação. Abre um ponteiro para o arquivo criado
; e vai percorrendo-o enquanto escreve no arquivo os numeros da serie de fibonacci(numeros que são infe-
; riores a 16 bits). Após, fecha o arquivo e termina o programa.
;--------------------------------------------------------------------------------------------------------


	; Declaração do modelo de segmentos
	.model		small
	
	; Declaração do segmento de pilha
	.stack

	; Declaração do segmento de dados
	.data

StringN		db		6		dup(?)
string		db		256 	dup(?)
stringError db 		'Houve um erro ao tentar criar arquivo.',0
FileBuffer	db		10 		dup(?)
lastFibN	dw		0
	; Declaração do segmento de código
	.code
	.startup

	lea		dx,string
	mov		cx,256
	call	ReadCommandLine
	
	; Coloque o restante do seu programa principal aqui!
	
	; Cria arquivo
	lea		dx, string+1			
	call 	fcreate	
	jnc		start 						; verifica se criou sem erro 

	; caso deu erro ao criar:
	lea 	bx, stringError				
	call	printf_s

	jmp		exit_main

; caso criou sem erro:
start:
	; Insere o primeiro numero da serie
	mov 	dl, '0'				; numero a ser escrito inicialmente 
	call 	setChar				; escreve numero no arquivo 
	call	addSpace			; adiciona espaço para o proximo numero 

	; Fibonacci Series
	mov		cl, 0				; auxiliar para saber se é para ser o ultimo a ser escrito. caso cl = 1, termina o laço.
	mov		dx, 1				; começa escrevendo o segundo numero que já é possivel começar a sequencia.
main:
	; guardando dados na pilha
	push	cx					; Guarda condicional para fim do laço.
	push	dx					; Guarda numero que será passado para string.
	push	bx					; Guarda alça do arquivo.
	
	; chama função que escreve em StringN o numero de AX de numero->string.
	lea		di,StringN			; ponteiro para StringN
	mov		ax,dx				; numero de fib.
	call 	itoa				; conversão para string 
	
	; move para DX a string 
	lea		dx,StringN			; Bota em DX a StringN do Numero para escrever no arquivo 
	
	; pega BX contendo a alça do arquivo 
	pop		bx

	; escrevendo no arquivo 
	call	setString			; escreve o conteudo de DX com o numero de bytes passado em CX em itoa 	
	call	addSpace			; adiciona espaço para o proximo numero 
	
	pop		dx					; Pega da pilha o numero passado acima 
	pop		cx					; pega da pilha o valor condicional para fim de laço 
	
	; caso valor condicional seja verdade, termina programa
	cmp		cl,1				
	je		exit_main
	; caso não seja...
	
	mov		ax,dx				; Coloca em AX o ultimo numero escrito 
	add		dx,lastFibN			; Incrementa o anterior ao ultimo para gerar o proximo 
	mov		lastFibN,ax			; Guarda o já escrito em lastFibN
	
	cmp		dx, ax				; Compara se DX >= AX, se sim, continua rodando laço 
	jge		next				
								; Caso não seja, quer dizer que o numero ultrapassou o maximo de bits 
	inc		cl					; então ativa valor condicional para terminar programa na proxima iteração
	
next:
	jmp main
	
exit_main:	
	call	fclose
	
	.exit
	
	; Coloque suas subrotinas a partir daqui!
;--------------------------------------------------------------------
; Entra:	DI -> ponteiro para a string 
;			AX -> numero em numerico
; Saida:	CX -> numero em string 
;--------------------------------------------------------------------
itoa 	proc 	near
	; base para divisão
	mov 	bx,10					
	; zerando registradores auxiliares
	; cx -> quantidade de digitos do numero passado
	; dx -> resto
	mov		cx,0
	mov		dx,0
	GetDigit_itoa:
		cmp		ax,0						; Se AX == 0, termina a parte de botar caracteres na pilha
		je		saveNumDigitLength_itoa				
		
		div		bx							; divide o numero passado
		push	dx							; coloca o resto na pilha 
		inc		cx							
		
		mov		dx,0						; 
		jmp		GetDigit_itoa
	
	saveNumDigitLength_itoa:
		mov		bx,	cx	
		
	PutDigit_itoa:	
		cmp		cx,0						; Se cx == 0, terminou de pegar todos caracteres colocados na pilha
		je		End_itoa
				
		pop		dx							; pega numero colocado na pilha 
		add		dx,'0'						; passa o numero para ASCII 
		mov		[di],dx						; insere no ponteiro de string 
		inc 	di							; incrementa o ponteiro 
		
		dec		cx							; decrementa caracteres restantes para fim da string.
		jmp		PutDigit_itoa	
		
	End_itoa:
		mov		cx, bx
		ret
itoa endp 	
	
;--------------------------------------------------------------------
; insere uma string no arquivo.
; Entra:	CX -> numero de bytes da string 
;			DX -> string 
;--------------------------------------------------------------------
setString	proc	near
	mov		ah,40h
	int		21h
	ret
setString	endp

;--------------------------------------------------------------------
; adiciona espaço no arquivo 
;--------------------------------------------------------------------
addSpace	proc	near
	mov		cx,1
	mov		dl,' '
	call	setChar
	ret
addSpace	endp

;====================================================================

;--------------------------------------------------------------------
;Função Cria o arquivo cujo nome está no string apontado por DX
;		boolean fcreate(char *FileName -> DX)
;Sai:   BX -> handle do arquivo
;       CF -> 0, se OK
;--------------------------------------------------------------------	
fcreate	proc	near
	mov		cx,0
	mov		ah,3ch
	int		21h
	mov		bx,ax
	ret
fcreate	endp

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
;Entra: BX -> file handle
;       dl -> caractere
;Sai:   AX -> numero de caracteres escritos
;		CF -> "0" se escrita ok
;--------------------------------------------------------------------
setChar	proc	near
	mov		ah,40h
	mov		cx,1
	mov		FileBuffer,dl
	lea		dx,FileBuffer
	int		21h
	ret
setChar	endp	

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


	



