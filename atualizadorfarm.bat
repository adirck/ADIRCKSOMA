@echo off
color 0A

:: Definir o título da janela do console
title Att Dll Linx e Forms Moda Feminina by Alexandre Rocha

:: ===============================
:: VERIFICAÇÃO E CRIAÇÃO DA PASTA TEMP
:: ===============================
cls
echo Verificando a existencia da pasta C:\temp...
timeout /t 2 >nul

:: Verificar se a pasta C:\temp existe
if exist "C:\temp" (
    echo A pasta C:\temp ja existe. Verificando permissoes...
) else (
    echo A pasta C:\temp nao existe. Criando a pasta...
    mkdir "C:\temp"
    echo Pasta C:\temp criada com sucesso!
)

:: Verificar permissões e garantir que o usuário "Todos" e outros grupos tenham controle total
echo Definindo permissoes para os usuarios "Todos", "Administradores", "SYSTEM"...
:: Garantir controle total para "Todos", "Administradores" e "SYSTEM" na pasta
icacls "C:\temp" /reset
icacls "C:\temp" /grant "Todos":(F) /T
icacls "C:\temp" /grant "Administradores":(F) /T
icacls "C:\temp" /grant "SYSTEM":(F) /T

:: ===============================
:: EXCLUIR ARQUIVOS NA PASTA TEMP
:: ===============================
cls
echo Excluindo todos os arquivos na pasta C:\temp...
timeout /t 2 >nul

:: Excluir todos os arquivos dentro da pasta C:\temp
del /f /q "C:\temp\*" >nul 2>&1
:: Excluir subpastas dentro de C:\temp
for /d %%p in ("C:\temp\*") do rmdir "%%p" /s /q

:: Verificar se a pasta C:\temp existe
if exist "C:\temp" (
    echo A pasta C:\temp já existe. Verificando permissoes...
) else (
    echo A pasta C:\temp nao existe. Criando a pasta...
    mkdir "C:\temp"
    echo Pasta C:\temp criada com sucesso!
)


:: ===============================
:: ENCERRAR PROCESSOS
:: ===============================
cls
powershell -command "Write-Host 'Encerrando processos LPeLib, LPeMLib e Linx Mre Service' -ForegroundColor Green"
timeout /t 2 >nul

:: Encerrar processos pelo nome
taskkill /f /im LPeLib.exe >nul 2>&1
taskkill /f /im LPeMLib.exe >nul 2>&1
net stop "Linx Mre Service" /y >nul 2>&1




:: ===============================
:: DEFINIR PERMISSÕES
:: ===============================
call :PrintGreen "Definindo permissoes para a pasta..."
icacls "C:\Program Files (x86)\Common Files\Linx Sistemas" /grant "Todos":(F)
icacls "C:\Program Files (x86)\Common Files\Linx Sistemas" /grant "Administradores":(F)
icacls "C:\Program Files (x86)\Common Files\Linx Sistemas" /grant "SYSTEM":(F)

:: ===============================
:: REMOVER ARQUIVOS EXISTENTES
:: ===============================
cls
echo Verificando se ha arquivos existentes na pasta Shared...
timeout /t 2 >nul

:: Forçar a exclusão do arquivo LnSecurity.dll e forms se ele existirem
powershell -Command "Remove-Item 'C:\Program Files (x86)\Common Files\Linx Sistemas\Shared\LnSecurity.dll' -Force -ErrorAction SilentlyContinue"
powershell -Command "Remove-Item 'C:\Program Files (x86)\Common Files\Linx Sistemas\Shared\*.DAT' -Force -ErrorAction SilentlyContinue"
powershell -Command "Remove-Item 'C:\Program Files (x86)\Linx Sistemas\LinxPOS-e\UserPrograms\Forms\reservesusr' -Force -ErrorAction SilentlyContinue"
powershell -Command "Remove-Item 'C:\Program Files (x86)\Linx Sistemas\LinxPOS-e\UserPrograms\Forms\reservesusr.scx' -Force -ErrorAction SilentlyContinue"
powershell -Command "Remove-Item 'C:\Program Files (x86)\Linx Sistemas\LinxPOS-e\UserPrograms\Forms\saleusr' -Force -ErrorAction SilentlyContinue"
powershell -Command "Remove-Item 'C:\Program Files (x86)\Linx Sistemas\LinxPOS-e\UserPrograms\Forms\saleusr.scx' -Force -ErrorAction SilentlyContinue"

:: ===============================
:: BAIXAR E EXTRAIR O ARQUIVO FORMS
:: ===============================
call :PrintGreen "Baixando e extraindo forms.zip..."
powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/adirck/ADIRCKSOMA/bf5c23c24e8cc09ef0b4dda1b75ba98ec34320f1/forms.zip' -OutFile 'C:\temp\forms.zip'"

timeout /t 2 >nul

:: Usando o parâmetro -Force para sobrescrever arquivos existentes
powershell -Command "Expand-Archive -Path 'C:\temp\forms.zip' -DestinationPath 'C:\Program Files (x86)\Linx Sistemas\LinxPOS-e\UserPrograms\Forms' -Force"

:: ===============================
:: BAIXAR E EXTRAIR O ARQUIVO DLL LINX
:: ===============================
call :PrintGreen "Baixando e extraindo LINXDLL.zip..."
powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/adirck/ADIRCKSOMA/bf5c23c24e8cc09ef0b4dda1b75ba98ec34320f1/LINXDLL.zip' -OutFile 'C:\temp\LINXDLL.zip'"

timeout /t 2 >nul

:: Usando o parâmetro -Force para sobrescrever arquivos existentes
powershell -Command "Expand-Archive -Path 'C:\temp\LINXDLL.zip' -DestinationPath 'C:\Program Files (x86)\Common Files\Linx Sistemas\Shared' -Force"


:: ===============================
:: INICIAR SERVIÇO
:: ===============================
echo Iniciando o servico "Linx Mre Service"...
net start "Linx Mre Service" >nul 2>&1


:: ===============================
:: MENSAGEM DE CONCLUSÃO
:: ===============================
call :PrintGreen "Processo concluido com sucesso!"
timeout /t 2 >nul

exit

:: Função para exibir mensagem em verde
:PrintGreen
echo %1
exit /b
