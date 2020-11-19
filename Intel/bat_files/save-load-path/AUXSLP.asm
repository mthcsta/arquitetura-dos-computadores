; script Assembly auxiliar o funcionamento do script de Save and Load Path 
;
; Declaração do modelo de segmentos
	.model		small
		
	; Declaração do segmento de pilha
	.stack

	; Declaração do segmento de dados
	.data
	Arquivo 	db 		'C:\MASM611\TMP\LSAVED.bat',0 
	FileBuffer	db		110 dup (32)
	.code
	.startup
	
	; insere CD ao inicio do buffer
	call CD
	
	; passando o conteudo pro buffer
	lea dx,Arquivo
	call fopen
	call fread
	call fclose
	
	; atualizando o conteudo do mesmo arquivo com o do buffer modificado
	lea dx,Arquivo
	call fopen
	call fwrite
	call fclose

	.exit

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;--------------------------------------------------------------------
; Insere o comando CD ao inicio do Buffer
;--------------------------------------------------------------------
CD	proc 	near
	mov FileBuffer+1,67
	mov FileBuffer+2,68
	mov FileBuffer+3,32
	ret
CD	endp
;--------------------------------------------------------------------
;Função	Abre o arquivo cujo nome está no string apontado por DX
;		boolean fopen(char *FileName -> DX)
;Entra: DX -> ponteiro para o string com o nome do arquivo
;Sai:   BX -> handle do arquivo
;       CF -> 0, se OK
;--------------------------------------------------------------------
fopen	proc	near
	mov		al,02
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
; Le todo o arquivo contendo o caminho salvo
;--------------------------------------------------------------------
fread proc near 
	mov		ah,3fh
	mov		cx,100
	lea		dx,FileBuffer+4
	int		21h
	mov		dl,FileBuffer	
	ret
fread endp
;--------------------------------------------------------------------
; Sobrescreve o arquivo contendo o caminho salvo acrescentando 
; o comando CD
;--------------------------------------------------------------------
fwrite proc near 
	mov		ah,40h
	mov		cx,109
	mov		FileBuffer,dl
	lea		dx,FileBuffer+1
	int		21h
	ret
fwrite endp
;--------------------------------------------------------------------
	end
;--------------------------------------------------------------------


	




