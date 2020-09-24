; define e-1 como e, e logo após subtrai 1,
; para o usar como o expoente;
;;;;;;
; Fim para o programa se o expoente for igual a 0
;;;;;;
; carrega o expoente para o acumulador, acrescenta o menos um,
; guarda na expoente_1, se o valor deu negativo, fim para o programa.
LDA expoente
ADD menosUm
STA expoente_1
JN FimExpoente
; definindo a base como valor inicial de resultado;

;;;;;;
; Fim para o programa se a base for igual a 0
;;;;;;
; carrega a base, a define como o resultado, 
; se ela for igual a 0, finaliza o programa.
LDA base 
STA resultado
JZ FimExpoente

; carrega o expoente-1, guarda como iterador para a expoente
LDA expoente_1
STA IteradorExpoente

; laço de repetição para o Expoente:
LoopExpoente:
; carrega o iterador, checa for igual a 0,
; se sim, finaliza o laço
LDA IteradorExpoente
JZ FimExpoente

;;;;;;;;;
;; definindo valores para inicio do laço da multiplicação
;;;;;;;;;
; carrega a base, acrescenta o menos 1 para a base,
; guarda o novo valor para o iterador da multiplação,
LDA base
ADD menosUm
STA IteradorMult
; salva o resultado para uma variavel auxiliar
LDA resultado
STA ultimoResultado

; laço de repetição para a Multiplicação:
LoopMult:
; carrega o iterador, checa se for igual a 0,
; se sim, finaliza o laço
LDA IteradorMult
JZ FimMult

; carrega o resultado, soma ele ao ultimo resultado,
; guarda o novo resultado
LDA resultado
ADD ultimoResultado
STA resultado    

; carrega o iterador da multiplicação, 
; acrescenta o menos 1, salva o novo valor
LDA IteradorMult
ADD menosUm
STA IteradorMult

; retorno para inicio do laço da multiplicação
JMP LoopMult

; para o fim do laço de repetição da multiplicação:
FimMult:
; carrega o iterador expoente,
; acrescenta o menos 1, salva o novo valor e pula para o inicio do laço.
LDA IteradorExpoente
ADD menosUm
STA IteradorExpoente
JMP LoopExpoente

; para o fim do programa e do laço de repetição do expoente:
FimExpoente:
  HLT


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; 	               DADOS                      ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; move para o endereço dos dados:
ORG 128

;; para o programa:
base: DB 0 ; 128
expoente: DB 0 ; 129
resultado: DB 1 ; 130 
ultimoResultado: DB 0 ; 131

;; auxiliares:
expoente_1: DB 0 ; 132 | expoente-1
menosUm: DB 255 ; 133 | -1 para ser acrescentado
IteradorExpoente: DB 0 ; 134 | usada para iterar para a expoente
IteradorMult: DB 0 ; 135 | usada para iterar para a multiplicação
