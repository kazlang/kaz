# ============================================================================
#   Desinstalador Oficial da Linguagem Kaz para Windows
#   Propriedade Intelectual (c) 2026 Armando Soares
# ============================================================================

$ErrorActionPreference = "Continue"

Write-Host "========================================================" -ForegroundColor Yellow
Write-Host "     Desinstalador Oficial da Linguagem Kaz             " -ForegroundColor Yellow
Write-Host "========================================================" -ForegroundColor Yellow
Write-Host ""

# 1. Encerrar processos em execucao do Kaz
Write-Host "[1/4] Verificando processos em execucao..." -ForegroundColor White
try {
    $processes = Get-Process kaz -ErrorAction SilentlyContinue
    if ($processes) {
        Write-Host "  Encerrando processos ativos do kaz.exe..." -ForegroundColor Yellow
        $processes | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 500
    }
    Write-Host "  OK: Nenhum processo kaz ativo." -ForegroundColor Green
} catch {
    # Ignora se nao conseguir parar processos
}

# 2. Remover diretorio de instalacao
$targetDir = Join-Path $env:LOCALAPPDATA "Kaz"
$binDir = Join-Path $targetDir "bin"

Write-Host "`n[2/4] Removendo arquivos do Kaz..." -ForegroundColor White
if (Test-Path $targetDir) {
    try {
        Remove-Item -Path $targetDir -Recurse -Force -ErrorAction Stop
        Write-Host "  OK: Arquivos removidos com sucesso de: $targetDir" -ForegroundColor Green
    } catch {
        Write-Host "  AVISO: Falha ao remover completamente $targetDir. Tentando novamente..." -ForegroundColor Yellow
        Start-Sleep -Milliseconds 500
        Remove-Item -Path $targetDir -Recurse -Force -ErrorAction SilentlyContinue
    }
} else {
    Write-Host "  OK: Diretorio de instalacao nao encontrado (ja removido)." -ForegroundColor Gray
}

# 3. Remover do PATH do Usuario de forma permanente
Write-Host "`n[3/4] Removendo Kaz do PATH do Usuario..." -ForegroundColor White
try {
    $userPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)
    if ($userPath) {
        $paths = $userPath.Split(';', [System.StringSplitOptions]::RemoveEmptyEntries)
        $cleanPaths = $paths | Where-Object {
            $p = $_.TrimEnd('\', '/')
            $p -ne $targetDir -and $p -ne $binDir -and $p -notlike "*\AppData\Local\Kaz*"
        }
        $newPathString = ($cleanPaths -join ';')
        [Environment]::SetEnvironmentVariable("Path", $newPathString, [EnvironmentVariableTarget]::User)
        Write-Host "  OK: Kaz removido do PATH do Usuario permanentemente no Registro." -ForegroundColor Green
    } else {
        Write-Host "  OK: PATH do Usuario ja esta limpo." -ForegroundColor Gray
    }
} catch {
    Write-Host "  AVISO: Nao foi possivel atualizar a variavel de ambiente PATH." -ForegroundColor Yellow
}

# Atualiza a variavel PATH na sessao atual do terminal
if ($env:Path) {
    $currentPaths = $env:Path.Split(';', [System.StringSplitOptions]::RemoveEmptyEntries)
    $cleanCurrent = $currentPaths | Where-Object {
        $p = $_.TrimEnd('\', '/')
        $p -ne $targetDir -and $p -ne $binDir -and $p -notlike "*\AppData\Local\Kaz*"
    }
    $env:Path = ($cleanCurrent -join ';')
}

# 4. Remover extensoes do VS Code e Lumina IDE
Write-Host "`n[4/4] Removendo extensoes de IDEs..." -ForegroundColor White
$extDirs = @(
    (Join-Path $env:USERPROFILE ".vscode\extensions"),
    (Join-Path $env:USERPROFILE ".vscode-insiders\extensions"),
    (Join-Path $env:USERPROFILE ".lumina-editor\extensions"),
    (Join-Path $env:USERPROFILE ".lumina-editor-dev\extensions")
)

$removedExtCount = 0
foreach ($dir in $extDirs) {
    if (Test-Path $dir) {
        $matches = Get-ChildItem -Path $dir -Directory -Filter "*kaz-language*" -ErrorAction SilentlyContinue
        foreach ($m in $matches) {
            try {
                Remove-Item -Path $m.FullName -Recurse -Force -ErrorAction Stop
                Write-Host "  OK: Extensao removida de: $($m.FullName)" -ForegroundColor Green
                $removedExtCount++
            } catch {
                Write-Host "  AVISO: Nao foi possivel remover $($m.FullName)" -ForegroundColor Yellow
            }
        }
    }
}
if ($removedExtCount -eq 0) {
    Write-Host "  OK: Nenhuma extensao do Kaz encontrada para remover." -ForegroundColor Gray
}

Write-Host ""
Write-Host "========================================================" -ForegroundColor Green
Write-Host "  Desinstalacao concluida com sucesso!" -ForegroundColor Green
Write-Host "  O sistema esta limpo e pronto para uma nova instalacao." -ForegroundColor White
Write-Host "========================================================" -ForegroundColor Green
Write-Host ""
