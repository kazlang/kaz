; ==============================================================================
; Kaz Programming Language - Windows NSIS Modern Installer Script
; ==============================================================================

!define PRODUCT_NAME "Kaz Programming Language"
!define PRODUCT_VERSION "1.1.0"
!define PRODUCT_PUBLISHER "Armando Soares"
!define PRODUCT_WEB_SITE "https://github.com/armandosds/kaz"
!define PRODUCT_DIR_REGKEY "Software\Kaz"
!define PRODUCT_UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\Kaz"

; Definições de compressão e arquitetura
SetCompressor /SOLID lzma
Unicode true
RequestExecutionLevel user

; Inclusão da interface moderna do NSIS (MUI2)
!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "WinMessages.nsh"

; Configurações visuais e ícones
!define MUI_ICON "..\assets\kaz.ico"
!define MUI_UNICON "..\assets\kaz.ico"
!define MUI_ABORTWARNING

; Páginas do Instalador
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "..\LICENSE"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES

; Configuração da página de finalização
!define MUI_FINISHPAGE_SHOWREADME "$INSTDIR\README.md"
!define MUI_FINISHPAGE_SHOWREADME_TEXT "Visualizar Documentação do Kaz (README)"
!define MUI_FINISHPAGE_RUN "$INSTDIR\bin\kaz.exe"
!define MUI_FINISHPAGE_RUN_PARAMETERS "--version"
!define MUI_FINISHPAGE_RUN_TEXT "Testar Kaz CLI no console"
!insertmacro MUI_PAGE_FINISH

; Páginas do Desinstalador
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

; Idioma
!insertmacro MUI_LANGUAGE "PortugueseBR"
!insertmacro MUI_LANGUAGE "English"

; Nome e Arquivo de Saída
Name "${PRODUCT_NAME} v${PRODUCT_VERSION}"
OutFile "..\dist\kaz-v${PRODUCT_VERSION}-windows-x64-setup.exe"
InstallDir "$LOCALAPPDATA\Programs\Kaz"
InstallDirRegKey HKCU "${PRODUCT_DIR_REGKEY}" "Install_Dir"

; ==============================================================================
; Seção Principal de Instalação
; ==============================================================================
Section "Core" SecCore
    SetOutPath "$INSTDIR\bin"
    File "..\target\release\kaz.exe"

    SetOutPath "$INSTDIR\docs"
    File /r "..\docs\*.*"

    SetOutPath "$INSTDIR\examples"
    File /r "..\examples\*.*"

    SetOutPath "$INSTDIR"
    File "..\README.md"
    File "..\README.pt-BR.md"
    File "..\LICENSE"
    File "..\assets\kaz.ico"
    File "..\assets\flux.ico"

    ; Criação do Desinstalador
    WriteUninstaller "$INSTDIR\Uninstall.exe"

    ; Registro de Instalação
    WriteRegStr HKCU "${PRODUCT_DIR_REGKEY}" "Install_Dir" "$INSTDIR"
    WriteRegStr HKCU "${PRODUCT_UNINST_KEY}" "DisplayName" "${PRODUCT_NAME} v${PRODUCT_VERSION}"
    WriteRegStr HKCU "${PRODUCT_UNINST_KEY}" "UninstallString" '"$INSTDIR\Uninstall.exe"'
    WriteRegStr HKCU "${PRODUCT_UNINST_KEY}" "DisplayIcon" "$INSTDIR\bin\kaz.exe,0"
    WriteRegStr HKCU "${PRODUCT_UNINST_KEY}" "DisplayVersion" "${PRODUCT_VERSION}"
    WriteRegStr HKCU "${PRODUCT_UNINST_KEY}" "Publisher" "${PRODUCT_PUBLISHER}"
    WriteRegStr HKCU "${PRODUCT_UNINST_KEY}" "URLInfoAbout" "${PRODUCT_WEB_SITE}"

    ; Criação de Atalhos no Menu Iniciar
    CreateDirectory "$SMPROGRAMS\Kaz"
    CreateShortcut "$SMPROGRAMS\Kaz\Kaz CLI.lnk" "$SYSDIR\cmd.exe" '/K ""$INSTDIR\bin\kaz.exe" --version"' "$INSTDIR\bin\kaz.exe" 0
    CreateShortcut "$SMPROGRAMS\Kaz\Documentação.lnk" "$INSTDIR\README.md" "" "$INSTDIR\kaz.ico" 0
    CreateShortcut "$SMPROGRAMS\Kaz\Desinstalar Kaz.lnk" "$INSTDIR\Uninstall.exe" "" "$INSTDIR\Uninstall.exe" 0

    ; Associação de arquivos .kaz
    WriteRegStr HKCU "Software\Classes\.kaz" "" "KazSourceFile"
    WriteRegStr HKCU "Software\Classes\KazSourceFile" "" "Código Fonte Kaz"
    WriteRegStr HKCU "Software\Classes\KazSourceFile\DefaultIcon" "" "$INSTDIR\bin\kaz.exe,0"
    WriteRegStr HKCU "Software\Classes\KazSourceFile\shell\open\command" "" '"$INSTDIR\bin\kaz.exe" run "%1"'

    ; ==========================================================================
    ; Adiciona $INSTDIR\bin ao PATH do Usuário
    ; ==========================================================================
    ReadRegStr $0 HKCU "Environment" "PATH"
    Push "$INSTDIR\bin"
    Push $0
    Call StrContains
    Pop $1
    ${If} $1 == ""
        ; Se não estiver no PATH, adiciona
        ${If} $0 == ""
            WriteRegStr HKCU "Environment" "PATH" "$INSTDIR\bin"
        ${Else}
            WriteRegStr HKCU "Environment" "PATH" "$0;$INSTDIR\bin"
        ${EndIf}
        ; Notifica o Windows sobre a alteração nas variáveis de ambiente
        SendMessage ${HWND_BROADCAST} ${WM_SETTINGCHANGE} 0 "STR:Environment" /TIMEOUT=5000
    ${EndIf}

SectionEnd

; ==============================================================================
; Desinstalação
; ==============================================================================
Section "Uninstall"
    ; Remove arquivos e diretórios
    RMDir /r "$INSTDIR\bin"
    RMDir /r "$INSTDIR\docs"
    RMDir /r "$INSTDIR\examples"
    Delete "$INSTDIR\README.md"
    Delete "$INSTDIR\README.pt-BR.md"
    Delete "$INSTDIR\LICENSE"
    Delete "$INSTDIR\kaz.ico"
    Delete "$INSTDIR\flux.ico"
    Delete "$INSTDIR\Uninstall.exe"
    RMDir "$INSTDIR"

    ; Remove Atalhos
    Delete "$SMPROGRAMS\Kaz\Kaz CLI.lnk"
    Delete "$SMPROGRAMS\Kaz\Documentação.lnk"
    Delete "$SMPROGRAMS\Kaz\Desinstalar Kaz.lnk"
    RMDir "$SMPROGRAMS\Kaz"

    ; Remove Associação de Arquivos
    DeleteRegKey HKCU "Software\Classes\.kaz"
    DeleteRegKey HKCU "Software\Classes\KazSourceFile"

    ; Remove Chaves de Registro
    DeleteRegKey HKCU "${PRODUCT_UNINST_KEY}"
    DeleteRegKey HKCU "${PRODUCT_DIR_REGKEY}"

    ; Remove do PATH
    ReadRegStr $0 HKCU "Environment" "PATH"
    Push ";$INSTDIR\bin"
    Push $0
    Call un.StrReplace
    Pop $0
    Push "$INSTDIR\bin;"
    Push $0
    Call un.StrReplace
    Pop $0
    Push "$INSTDIR\bin"
    Push $0
    Call un.StrReplace
    Pop $0
    WriteRegStr HKCU "Environment" "PATH" $0
    SendMessage ${HWND_BROADCAST} ${WM_SETTINGCHANGE} 0 "STR:Environment" /TIMEOUT=5000

SectionEnd

; ==============================================================================
; Funções Utilitárias de String para o PATH
; ==============================================================================
Function StrContains
    Exch $0 ; String completa
    Exch
    Exch $1 ; Substring procurada
    Push $2
    Push $3
    Push $4

    StrCpy $2 0
    StrLen $3 $1
    ${Do}
        StrCpy $4 $0 $3 $2
        ${If} $4 == $1
            StrCpy $1 "found"
            ${Break}
        ${EndIf}
        ${If} $4 == ""
            StrCpy $1 ""
            ${Break}
        ${EndIf}
        IntOp $2 $2 + 1
    ${Loop}

    Pop $4
    Pop $3
    Pop $2
    Pop $0
    Exch $1
FunctionEnd

Function un.StrReplace
    Exch $0 ; String de busca
    Exch
    Exch $1 ; String de substituição
    Exch 2
    Exch $2 ; String original
    Push $3
    Push $4
    Push $5
    Push $6

    StrCpy $3 ""
    StrLen $4 $0
    ${Do}
        StrCpy $5 $2 $4 0
        ${If} $5 == $0
            StrCpy $3 "$3$1"
            StrCpy $2 $2 "" $4
        ${ElseIf} $2 == ""
            ${Break}
        ${Else}
            StrCpy $6 $2 1 0
            StrCpy $3 "$3$6"
            StrCpy $2 $2 "" 1
        ${EndIf}
    ${Loop}
    StrCpy $2 $3

    Pop $6
    Pop $5
    Pop $4
    Pop $3
    Pop $1
    Pop $0
    Exch $2
FunctionEnd
