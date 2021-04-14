;--------------------------------------------------------------------------------------------------------
; Este programa faz a leitura do segundo e terceiro parametro da linha de comando (sendo o primeiro o 
; programa) e interpreta como sendo o arquivo para leitura e o para escrita, respectivamente.
; Abre um ponteiro para o inicio do primeiro arquivo dado e vai percorrendo-o, quando encontra um espaço
; considera que foi montada uma palavra. Pega esta palavra e o compara com vetor Numbers, caso a palavra
; seja igual a uma do vetor, então ela é um numero, fazendo a troca do numero por escrito para o numero 
; em digito. Não case-sensitive. Caso não for um numero, então apenas coloca a palavra no arquivo de saida
;--------------------------------------------------------------------------------------------------------


  ; Declaração do modelo de segmentos
	.model		small
	
	; Declaração do segmento de pilha
	.stack

	; Declaração do segmento de dados
	.data
; lista de numeros 
Numbers			db		'zero',0, 'um',0, 'dois',0, 'tres',0, 'quatro',0, 'cinco',0, 'seis',0, 'sete',0, 'oito',0, 'nove',0,0 	
; lista auxiliar para navegar no vetor acima 
; cada indice passa a posição que começa o numero 
NumberPos		db		0,5,8,13,18,25,31,36,41,46,0

; filename do arquivo de origem 
origem			db		50 dup(?)
; filename do arquivo de destino
destino			db		50 dup(?)
; tamanho em bytes dos nomes dos arquivos
filenameSize	db		0,0

; string para linha de comando
string		db	256 dup(?)
FileBuffer	db	10 	dup(?)

; guarda palavra para comparar com numeros por escrito 
wordStorage		db 10	dup(?)
; guarda tamanho da palavra
wordStorageSize db 0

; lista de numeros provaveis 
NumbersProbable				db	10 dup(99)
; tamanho da lista de numeros provaveis 
NumbersProbableLength		db	0

; booleano, se 1 então escreve palavra em numerico, se 0 escreve palavra contida em wordStorage
IsToWriteANumber			db	0	; bool

; mensagens de erro para o programa.
msgErrorFcreate	db		'Erro ao tentar criar arquivo',0
msgErrorFopen	db		'Erro ao tentar abrir arquivo',0

	.code
	.startup	
		
	lea		dx,string
	mov		cx,256
	call	ReadCommandLine	
	; Coloque o restante do seu programa principal aqui!
	
	; parametros de splitwords:
	xor		cx, cx 					; limpando auxiliares para função 
	lea		bx, string+1 			; ponteiro para percorrer a string 
	lea		si, string 				; ponteiro para escrever em string somente quando não for espaço ou virgula
	lea		di, filenameSize		; ponteiro para guardar o tamanho em caracteres do nome do arquivo 
	call	splitwords				; chamada de splitwords
	
	
	; setando SI e DI para programa abaixo.
	push 	ds						
	pop 	es						; faz ES=DS
	cld								; coloca SI e DI para auto-incrementar

	; Passando da linha de comando para o arquivo com nome de origem
	lea		si, string				; coloca a string no ponteiro de origem  
	lea		di, origem				; coloca a variavel de nome de origem no ponteiro para destino 
	xor		cx, cx					; limpa cx 
	mov		cl, filenameSize		; adiciona em cx o numero de bytes da string 
		
	rep 	movsb					; faz loop de transferencia

	
	; Passando da linha de comando para o arquivo com nome de destino 
	lea		di, destino				; nome de destino 
	xor		cx, cx					; limpa cx 
	mov		cl, filenameSize+1		; adiciona em CX o numero de bytes da string
	
	rep 	movsb					; faz loop de transferencia

	
	
	
	; lendo arquivo de origem 
	lea		dx, origem
	call 	fopen
	jnc		Success_fopen
; caso deu erro na leitura:
	lea 	bx, msgErrorFopen
	call	printf_s
	jmp 	exit_main	
	
; caso não tenha dado erro na leitura:
Success_fopen:	
	; movendo a alça do arquivo de origem para SI 
	mov		si,bx
	
	; criando arquivo de destino 
	lea		dx,destino
	call	fcreate
	jnc 	Success_fcreate
; caso deu erro na criação de arquivo:
	lea 	bx, msgErrorFcreate
	call 	printf_s
	jmp 	Success_fcreate
	
; caso não tenha dado erro na criação de arquivo:
Success_fcreate:
	; movendo a alça do arquivo de destino para DI 
	mov		di,bx
	
	; pegando alça do arquivo de origem 
	mov		bx,si	
	
	
main:
; Pegando char de origem e verificando se foi lido um novo
	call	getChar
	cmp		ax,0
	je		exit_main
;--------------------------------------------------------------------
	cmp		dl, '@'						; Se char for menor que @, então não é uma letra,
	jl		writeWord					; portanto deve escrever palavra guardada.
	cmp		dl, '{'						; Se char for maior que {, então não é uma letra,
	jge		writeWord					; portanto deve escrever palavra guardada. 
	cmp		dl, '`'						; Se char for maior que `, então é uma letra.
	jg		formWord					; Pula para formar palavra.
	cmp 	dl, '['						; Se char for menor que [, então não é uma letra,
	jge 	writeWord					; portanto deve escrever palavra guardada.
	
; coloca caractere na formação da palavra  
formWord:
	call	getCharToWord				
	jmp		main

; escreve palavra formada ou um numero
writeWord:
	push	dx							; guarda na pilha caractere não-letra lido
	call	putWordOrInt				; função de escrita da palavra ou numero 
	pop		dx							; pega da pilha caractere não-letra lido 
	
	mov		bx,di						; move alça para destino 		
	call	setChar						; insere char 
	mov		bx,si						; retorna alça para origem 
	
	jmp		main	
	
;--------------------------------------------------------------------	
exit_main:
	call	putWordOrInt				; escreve ultima palavra do arquivo.
	; fechando arquivo de origem 
	mov		bx,si						
	call 	fclose
	; fechando arquivo de destino 
	mov		bx,di
	call 	fclose
	
	.exit
	
;--------------------------------------------------------------------	
; Função para pegar uma string e retirar os espaços e virgulas 
; Entra:	
;			BX -> ponteiro para string 
; 			SI -> ponteiro para mesma string
;			DI -> ponteiro para vetor de posição de cada palavra na string 
;			CX -> 0. pois são auxiliares para a função
; Sai:		
;			string modificada e posições de inicio de origem e destino 
;			gravadas no vetor do ponteiro em DI
; 
; cl -> se cl != 0 então leu antes um espaço ou virgula
; ch -> tamanho da palavra 
;--------------------------------------------------------------------	
splitwords	proc	near
	mov		dl, [bx]					; move um char da string para dl 

	cmp		dl, 0						; verifica se a string ja terminou
	je		Termina_splitwords			; se sim, termina função.

	cmp		dl, ' '						; Verifica o char se é um espaço 
	je		OcorreuMal_splitwords		; se sim, não escreve em SI.
	cmp		dl, ','						; Verifica o char se é uma virgula 
	je		OcorreuMal_splitwords		; se sim, não escreve em SI.
	

OcorreuBem_splitwords:	
	; verifica se precisa quebrar palavra 
	cmp		cl, 0						; verifica se teve espaço ou virgula		
	je		SemQuebra_splitwords		; se não, não quebra palavra, apenas escreve. 
	; caso não precise quebrar palavra:
	mov		[di], ch					
	inc		di
	xor		ch, ch
; caso precise quebrar palavra:
SemQuebra_splitwords:
	mov		[si], dl					; poe char em string 
	inc		si							; incrementa ponteiro para string 
	inc		ch							; incrementa numero de chars da string 
	xor		cl,cl						; zera espaços/virgulas encontradas.
	jmp		Next_splitwords				; pula para proxima iteração

OcorreuMal_splitwords:					
	inc		cl							; encontrou espaço ou virgula 

Next_splitwords:
	inc 	bx							; proximo char 
	jmp		splitwords

Termina_splitwords:
	mov		[di], ch					; escreve tamanho da palavra no vetor filenameSize
	mov		[si], 0						; coloca \0 para terminar string.
	ret
splitwords	endp

;--------------------------------------------------------------------	
; Função em que dado um caractere em dl, percorre todos os digitos por escrito 
; e ve se o primeiro char do digito é igual dl, se sim, adiciona a uma lista.
; Entra: 	dl -> caractere 
;--------------------------------------------------------------------	
getDigitsStartsWithLetter	proc	near
	; guarda dados 
		push	ax				
		push 	bx
		push	cx 
		push 	dx
;---------------------------------------
		mov		dl, [wordStorage]				; guarda palavra em dl
		lea		bx, NumbersProbable				; move ponteiro para vetor de numeros provaveis para cria-lo
		mov 	NumbersProbableLength, 0		; zera tamanho de numeros provaveis 
		mov		cl,0							; Auxiliar para contagem de 0 a 9
	Loop_verificaSeEhAlgumNumero:
		cmp		cl,10							; caso cl == 10, termina loop de provaveis numeros.
		je		End_verificaSeEhAlgumNumero
		
		; parametros de getcharbypos
		mov 	al,cl							; move o numero provavel para parametro de getcharbypos
		mov		ch,0							; primeiro char do numero 
		call	getcharbypos					; retorna a primeira letra do numero passado em AL 
		call	cmpchar							; compara com o primeiro char da palavra passada 
		jc		NextLoop_iteraProvaveisNumeros	; se não for igual apenas itera para proximo numero 
		
		; se o primeiro char do numero for igual o primeiro char da palavra passada:
		mov		[bx], cl						; poe numero na lista de provaveis numeros 
		inc		bx								; incrementa ponteiro da lista 
		inc		NumbersProbableLength			; incrementa tamanho da lista
		
	NextLoop_iteraProvaveisNumeros:
		inc		cl								; incrementa o numero passado
		jmp		Loop_verificaSeEhAlgumNumero	; fim da iteração
;---------------------------------------	
	End_verificaSeEhAlgumNumero:
		mov		[bx], 99						; coloca codigo de fim de lista

	; recupera dados 
		pop		dx
		pop		cx
		pop		bx
		pop		ax
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		mov		IsToWriteANumber, 0
		cmp		NumbersProbableLength, 0
		je		endsWithCarry_getDigitsStartsWithLetter
		mov		IsToWriteANumber, 1
	endsWithCarry_getDigitsStartsWithLetter:
		ret
getDigitsStartsWithLetter	endp	

;--------------------------------------------------------------------	
; Função que em cima de um char DL e uma posição CH itera por lista 
; de NumbersProbable, apagando da lista digitos que não baterem com 
; o caractere de DL.
; Entra: 	dl -> letra 
;			ch -> numero posição na string  
; Sai:		dh -> numero provavel 
;--------------------------------------------------------------------	
iterateRestNumbersProbable	proc	near 
	; guarda dados
		push	ax
		push	bx
		push	cx
;--------------------------------------------
		xor		bx, bx								; Limpa bx 
		lea		bx, NumbersProbable					; aponta para lista de numeros provaveis 
	loop_iterate:
		mov		al, [bx]							; coloca numero provavel em al 
		cmp		al, 99								; Verifica se é o codigo de fim de lista 
		je		End_iterateRestNumbersProbable		; se sim, termina iteração.
		cmp		al, 90								; Verifica se é o codigo de Ignore
		je		next_iterate						; se sim, ignora indice e prossegue
		
		call	getcharbypos						; pega char do numero provavel 
		call	cmpchar								; compara com char da palavra 
		jnc		save_char							; se for igual, salva numero para retorno 
				
		mov		byte ptr [bx], 90					; adiciona byte em ex numero provavel 
		dec		NumbersProbableLength				; decrementa tamanho de lista de numeros provaveis 
		jmp		next_iterate						; pula para parte de tratamento de fim de iteração.
	save_char:
		mov		dh, [bx]							; guardando numero provavel em DH para retorno 
		add		dh, 48								; passando numero para ASCII 

	next_iterate:
		inc		bx
		inc		ah
		jmp	loop_iterate

;--------------------------------------------
	End_iterateRestNumbersProbable:
	; recupera dados
		pop		cx
		pop		bx
		pop		ax
		
		ret
iterateRestNumbersProbable	endp

;--------------------------------------------------------
; Entra: 	al -> numero de indice de array NumberPos
;			ch -> posição na palavra
; Sai: 		al -> char correspondente ao indice 
;--------------------------------------------------------
getcharbypos	proc 	near
	push	bx
	lea		bx,NumberPos				; carrega array de NumberPos
	add		bl,al						; pula para posição do array
	mov		al,[bx]						; coloca numero contido na posição em AL 
	add		al,ch						; soma para chegar na posição na palavra.
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	lea		bx, Numbers					; aponta para lista de numeros por escrito 
	add		bl, al						; incrementa para posição dada por atual al 
	mov		al, [bx]					; move caractere da posição selecionada para al 
	pop		bx
	ret
getcharbypos 	endp

;-----------------------------------------------------------------------
; compara AL e DL se são iguais e se não retorna um carry 
; Entra:	dl -> char Ascii	
;			al -> char Ascii 
; Sai:		CF -> 0, letra diferente
;-----------------------------------------------------------------------
cmpchar 	proc	near
	CLC									; limpa carry
	cmp		dl, al						; compara chars 
	je		IsSame_cmpchar				; caso sejam iguais, termina.
	sub		al, 32						; subtrai para chegar a char maiusculo 
	cmp		dl, al						; compara chars 
	je		IsSame_cmpchar				; caso sejam iguais, termina.
	STC									; Caso não sejam, ativa carry!
IsSame_cmpchar:
	ret
cmpchar		endp

;-----------------------------------------------------------------------
; saida: 	dh -> char numerico 
; 			cf -> 0 se for uma palavra não-digito.
;-----------------------------------------------------------------------
isDigitWord		proc	near
	; guarda dados 
	push	ax
	push	bx
	push	cx
;------------------------------------------------------------
	
	lea		bx, wordStorage								; aponta para palavra formada 
	call	getDigitsStartsWithLetter					; chama função para comparar com todos numeros
	cmp		IsToWriteANumber, 0							; Se não for igual nenhum
	je		EndsNotDigit_isDigitWord					; termina escrevendo palavra. 

	mov		ch, 1										; coloca no segundo caractere dos digitos por escrito 
	mov		cl, wordStorageSize							; guarda o tamanho da palavra 

	inc		bx											; incrementa ponteiro de palavra formada para segundo char

	mov		IsToWriteANumber, 1							; ativa bool de escrita de numero 
	
	cmp 	ch, cl 										; compara posição com tamanho, se for igual termina aqui
	je		EndsNotDigit_isDigitWord					; escrevendo palavra. (Para palavras de 1 letra só e
														; caractere igual primeira letra de um numero por escrito)

loop_isDigitWord:
	cmp		ch, cl										; caso ch for igual ou maior, termina loop.
	jge		EndsAndCheckIfDigitEndsTo_isDigitWord
	
	mov		dl,[bx]										; guarda em dl char de wordStorage 
	
	call	iterateRestNumbersProbable					; chama iterador
	cmp		NumbersProbableLength,0						; verifica se numeros provaveis chegou a 0
	je		EndsNotDigit_isDigitWord					; caso sim, então não era um digito e termina loop.
	
	inc		ch											; pula para proxima posição nos numeros provaveis 
	inc		bx											; pula para proximo char de wordStorage
	jmp		loop_isDigitWord							; retorna ao inicio do loop.

EndsAndCheckIfDigitEndsTo_isDigitWord:					; caso termine tudo bem, então retorna em al o numero
	mov		al,dh										; passa para al o numero q tava por escrito 
	sub		al,48										; da sub para retornar a numero normal 
	call	getcharbypos								; pega posição do numero com ch atual 
	cmp		al,0										; verifica se o numero chegou a terminar mesmo 
	je		End_isDigitWord								; se sim, termina função.
EndsNotDigit_isDigitWord:
	mov		IsToWriteANumber, 0							; se não, diz que não é para passar para numero.

;------------------------------------------------------------
End_isDigitWord:
	; recupera dados 
	pop		cx
	pop		bx
	pop		ax
	ret
isDigitWord		endp

;--------------------------------------------------------------------
; Entra: 	
;--------------------------------------------------------------------
putWordOrInt	proc	near
	mov		bx,di						; Coloca ponteiro para arquivo de destino
	call	isDigitWord					; chama função que verifica se wordStorage eh um digito por escrito
	cmp		IsToWriteANumber,1			; se sim, então IsToWriteANumber=1
	je		jump_p						; pula para parte de escrever numero
	call	setString					; Caso não pule, escreve string contida em wordStorage
	jmp		End_putWordOrInt			; pula para fim da função
jump_p:
	mov		dl,dh						; move dh contendo o digito que estava escrito
	call	setChar						; coloca digito no arquivo
End_putWordOrInt:
	mov		bx,si						; volta ponteiro para arquivo de origem
	mov		byte ptr wordStorage, 0		; coloca fim de palavra no inicio de wordStorage
	mov		wordStorageSize, 0			; zera tamanho de palavra
	ret
putWordOrInt	endp

;--------------------------------------------------------------------
; Função para inserir char de dl em wordStorage
; Entra: 	dl -> char a ser inserido
;--------------------------------------------------------------------
getCharToWord	proc	near 
	push	bx							
	lea		bx, wordStorage				; ponteiro para wordStorage
	add		bl, wordStorageSize			; incrementa ponteiro
	mov		[bx], dl					; insere char na posição marcada no ponteiro
	inc		wordStorageSize				; atualiza tamanho de wordStorage em wordStorageSize.
	pop		bx
	ret
getCharToWord	endp

;--------------------------------------------------------------------
;Entra: BX -> file handle
;       dl -> caractere
;Sai:   AX -> numero de caracteres escritos
;		CF -> "0" se escrita ok
;--------------------------------------------------------------------
setString	proc	near
	push	cx
	mov		ah,40h
	; limpando regs 
	xor		cx,cx
	xor		dx,dx
	; colocando dados nos regs para escrever palavra
	mov		cl,wordStorageSize
	lea		dx,wordStorage
	; chamada da interrupção de escrita no arquivo
	int		21h
	pop		cx
	ret
setString	endp	

;=================================================================================================
; Abaixo apenas funções dadas pelo professor
;=================================================================================================
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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
