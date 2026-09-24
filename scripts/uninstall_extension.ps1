# ============================================================================
#   Desinstalador da Extensao Kaz Language para Lumina IDE & VS Code
#   Propriedade Intelectual (c) 2026 Armando Soares
# ============================================================================

$ErrorActionPreference = "Continue"

$targetDirs = @(
    (Join-Path $env:USERPROFILE ".lumina-editor\extensions"),
    (Join-Path $env:USERPROFILE ".lumina-editor-dev\extensions"),
    (Join-Path $env:USERPROFILE ".vscode\extensions"),
    (Join-Path $env:USERPROFILE ".vscode-insiders\extensions")
)

$removedCount = 0

foreach ($dir in $targetDirs) {
    if (Test-Path $dir) {
        $matches = Get-ChildItem -Path $dir -Directory -Filter "*kaz-language*" -ErrorAction SilentlyContinue
        foreach ($m in $matches) {
            try {
                Remove-Item -Path $m.FullName -Recurse -Force -ErrorAction Stop
                Write-Host "OK: Extensao removida de: $($m.FullName)" -ForegroundColor Green
                $removedCount++
            } catch {
                Write-Host "Aviso: Nao foi possivel remover $($m.FullName)" -ForegroundColor Yellow
            }
        }
    }
}

if ($removedCount -gt 0) {
    Write-Host "OK: $removedCount extensao(oes) do Kaz removida(s) com sucesso!" -ForegroundColor Green
} else {
    Write-Host "OK: Nenhuma extensao encontrada para remocao." -ForegroundColor Gray
}
