:: Salve o caminho e o carregue logo que abrir o MASM
@echo off
if [%1]==[] goto End
>C:\MASM611\TMP\SAVEDLOCAL.bat echo call cd c:\%1
echo caminho salvo.
:End
