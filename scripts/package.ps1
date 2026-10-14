$version = "1.4.0"
$distName = "kaz-$version-windows-x64"
$rootDir = (Get-Item $PSScriptRoot).Parent.FullName
$distDir = Join-Path $rootDir "dist"
$targetDistDir = Join-Path $distDir $distName
$zipFile = Join-Path $distDir "$distName.zip"

Write-Host "=== Empacotando Distribuição: $distName ===" -ForegroundColor Cyan

# 1. Compilar release
Set-Location $rootDir
cargo build --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "Falha na compilação!" -ForegroundColor Red
    exit 1
}

# 2. Preparar diretório de distribuição
if (Test-Path $targetDistDir) {
    Remove-Item $targetDistDir -Recurse -Force
}
if (Test-Path $zipFile) {
    Remove-Item $zipFile -Force
}

New-Item -ItemType Directory -Path (Join-Path $targetDistDir "bin") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $targetDistDir "examples") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $targetDistDir "docs") -Force | Out-Null

# 3. Copiar binário
Copy-Item (Join-Path $rootDir "target\release\kaz.exe") (Join-Path $targetDistDir "bin\kaz.exe") -Force

# 4. Copiar documentação e exemplos
Copy-Item (Join-Path $rootDir "examples\*") (Join-Path $targetDistDir "examples") -Recurse -Force
Copy-Item (Join-Path $rootDir "docs\*") (Join-Path $targetDistDir "docs") -Recurse -Force
Copy-Item (Join-Path $rootDir "README.md") $targetDistDir -Force
Copy-Item (Join-Path $rootDir "LICENSE") $targetDistDir -Force

# 5. Copiar instaladores
Copy-Item (Join-Path $rootDir "install.ps1") $targetDistDir -Force
Copy-Item (Join-Path $rootDir "install.bat") $targetDistDir -Force
Copy-Item (Join-Path $rootDir "uninstall.ps1") $targetDistDir -Force
Copy-Item (Join-Path $rootDir "uninstall.bat") $targetDistDir -Force

# 6. Compactar em ZIP
Compress-Archive -Path "$targetDistDir\*" -DestinationPath $zipFile -Force

Write-Host "Pacote de distribuição criado com sucesso!" -ForegroundColor Green
Write-Host "Arquivo: $zipFile" -ForegroundColor Yellow
