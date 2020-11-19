:: Entre com -s caminho\para\guardar 
:: para salvar um caminho e sempre que quiser retornar ao caminho,
:: entre apenas com: -s, e retornara ao caminho salvo.

@echo off

if [%1]==[] goto LoadPath

>C:\MASM611\TMP\LSAVED.bat echo call cd c:\%1
echo caminho salvo.
goto End

:LoadPath
call C:\MASM611\TMP\LSAVED.bat

:End
