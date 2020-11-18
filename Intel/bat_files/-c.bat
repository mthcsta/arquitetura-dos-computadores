:: Compilar & Rodar
:: Condição para caso não seja informado o arquivo
@echo off
if not [%1]==[] goto StartCompile
@echo Caminho para o arquivo nao informado.
@echo Dica: informe o caminho e junto um y para que passe direto ao seu programa
@echo na forma: -c programa y
echo.
goto End

:StartCompile
:: atualiza a lista de arquivos
rescan
:: limpa a tela 
@cls
:: Setando local do arquivo temporario usado para OBJ 
SET OBJECT=\MASM611\TMP\_mthcsta_.obj
@echo on

:: compila o masm e o obj  
masm /Zi %1.asm,%OBJECT%
:: desabilita eco para melhor visualização
@echo off								
:: verifica se arquivo existe(caso foi compilado bem)
if not exist %OBJECT% goto End
:: linka objeto compilado e transforma em executavel
echo --------------------------------------------------------------------------------
echo linkando %1.obj:
link %OBJECT%,%1;
:: remove objeto compilado da pasta temporaria.
del %OBJECT%
:: Trava usuario para saber que tudo correu bem
if [%2]==[y] goto RunExe
echo --------------------------------------------------------------------------------
echo Tudo correu bem! pressione uma tecla para correr o seu programa...
echo.
pause

:RunExe
:: limpa a tela
@cls 
@echo on
:: roda arquivo executavel criado
%1

:: label auxiliar para finalizar arquivo em caso de erro
:End
