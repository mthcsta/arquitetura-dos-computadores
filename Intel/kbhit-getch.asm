;--------------------------------------------------------------------------------------------------------
; programa que usa os interruptores do teclado para criar funções como a kbhit e getch da lang C
; este programa detecta que foi apertado um botão e captura a interrupção, passando o botão apertado
; para uma subrotina que verifica se o botão apertado foi um digito, se sim, escreve este digito, se não,
; então apenas bota o caractere apertado na tela.
;--------------------------------------------------------------------------------------------------------
  .model small
	.stack
	
	.data
; Vetor contendo os numeros por escrito
numbers		db		'ZERO',0, 'UM',0, 'DOIS',0, 'TRES',0, 'QUATRO',0, 'CINCO',0, 'SEIS',0, 'SETE',0, 'OITO',0, 'NOVE',0 
; Vetor contendo a posição no ponteiro referente a cada numero
numberPos	db		0,5,8,13,18,25,31,36,41,46

	.code
	.startup

main:
	call 	getchar
	
	cmp 	al, 'f' 						; Se entrou com um 'f' 
	je 		exit							; termina o programa.

	call 	isdigit							; verifica se é um digito
	jz 		notDigit						; se não for, pula para printar um char
	
	call 	numbertoword					; se for, chama number_to_word para printar um digito
	jmp 	next							; e termina o laço.

notDigit:
	call 	putchar							; função que printa o char
	
next:
	jmp 	main
	
exit:	
	.exit
	
;--------------------------------------------------------------------
;Função Verificar se o char passado é um digito
;	is_digit(char c -> al)
;Saida: ZF -> 0 se não for digito
;--------------------------------------------------------------------
isdigit proc near 
		mov 	ah, 0						; Auxiliar para a condição de checagem de retorno (se o char passado é ou não um digito)
		cmp 	al, '0'						; Verifica se o char é inferior a '0'
		jl 		End_isdigit				; se sim, o char não é um digito. 
		cmp 	al, '9'						; Verifica se o char é superior a '9'
		jg 		End_isdigit				; se sim então o char não é um digito.
		inc 	ah							; Incrementa pois o char é um digito.
	End_isdigit:
		cmp 	ah, 0						; Comparação auxiliar para o programa que a chama 
		ret
isdigit endp
;--------------------------------------------------------------------
;Função Passar Numerico para Escrito.
;		number_to_word(char s -> al)
;Saida: BX -> ponteiro para string de um numero 
;--------------------------------------------------------------------
numbertoword proc near 
	sub 	al, '0'							; Passa numero ascii pra binario.
	xor 	ah, ah							; Limpa ah para passar para SI apenas o char ascii
	mov 	si, ax							; 
	mov 	dl, [numberPos+si]				; Passa para dl a posição do ponteiro para Numbers 
	lea 	bx, numbers						; Posiciona o ponteiro no inico de Numbers 
	add 	bl, dl							; Incrementa o ponteiro com a posição dada.
	call 	printf_s						; Escreve String 
	ret 
numbertoword endp 

;--------------------------------------------------------------------
;Função Checar a entrada e trata-la de acordo com o objetivo do programa.
;		putchar(char s -> al)
;--------------------------------------------------------------------
putchar proc near 
	mov 	dl, al
	mov 	ah, 2
	int 	21h
	ret
putchar endp

;--------------------------------------------------------------------
;Função capturar teclado e guardar no registrador al.
;		getchar(void)
;Saida: al -> caractere
;--------------------------------------------------------------------
getchar proc near 						
	mov 	ah, 0							
	int 	16h								
	ret 								
getchar endp							

;--------------------------------------------------------------------
;Função Escrever um string na tela
;		printf_s(char *s -> BX)
;--------------------------------------------------------------------
printf_s	proc	near
	mov		dl, [bx]
	cmp		dl, 0
	je		ps_1

	push	bx
	mov		ah, 2
	int		21H
	pop		bx

	inc		bx		
	jmp		printf_s
	
ps_1:
	ret
printf_s	endp

;---------------------------------------------------------------------
	end
;---------------------------------------------------------------------
