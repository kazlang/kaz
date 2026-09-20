# ============================================================================
#   Empacotador Oficial VSIX da Linguagem Kaz (Zero dependência de Node) 🦅
#   Propriedade Intelectual (c) 2026 Armando Soares
# ============================================================================

param (
    [string]$Version = "1.0.1"
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$rootDir = Split-Path -Parent $scriptDir
$srcDir = Join-Path $rootDir "editors\vscode"
$distDir = Join-Path $rootDir "dist"

if (-not (Test-Path $distDir)) {
    New-Item -ItemType Directory -Path $distDir -Force | Out-Null
}

$outputVsix = Join-Path $distDir "kaz-language-$Version.vsix"
$outputVsixLatest = Join-Path $distDir "kaz-language-1.0.0.vsix"

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "     Empacotador VSIX Kaz Language v$Version             " -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan

# Atualiza versão no package.json
$pkgJsonPath = Join-Path $srcDir "package.json"
if (Test-Path $pkgJsonPath) {
    $pkg = Get-Content $pkgJsonPath -Raw | ConvertFrom-Json
    $pkg.version = $Version
    $pkg | ConvertTo-Json -Depth 10 | Set-Content $pkgJsonPath -Encoding UTF8
    Write-Host "OK: package.json atualizado para v$Version" -ForegroundColor Green
}

$tempZip = [System.IO.Path]::GetTempFileName()
Remove-Item $tempZip -Force

$zipStream = [System.IO.File]::Create($tempZip)
$archive = New-Object System.IO.Compression.ZipArchive($zipStream, [System.IO.Compression.ZipArchiveMode]::Create)

# 1. [Content_Types].xml
$ctContent = "<?xml version=""1.0"" encoding=""utf-8""?>`r`n<Types xmlns=""http://schemas.openxmlformats.org/package/2006/content-types""><Default Extension="".json"" ContentType=""application/json""/><Default Extension="".md"" ContentType=""text/markdown""/><Default Extension="".png"" ContentType=""image/png""/><Default Extension="".vsixmanifest"" ContentType=""text/xml""/></Types>"
$entry = $archive.CreateEntry("[Content_Types].xml", [System.IO.Compression.CompressionLevel]::Optimal)
$writer = New-Object System.IO.StreamWriter($entry.Open(), [System.Text.Encoding]::UTF8)
$writer.Write($ctContent)
$writer.Close()

# 2. extension.vsixmanifest
$manifestTemplate = @"
<?xml version="1.0" encoding="utf-8"?>
<PackageManifest Version="2.0.0" xmlns="http://schemas.microsoft.com/developer/vsx-schema/2011" xmlns:d="http://schemas.microsoft.com/developer/vsx-schema-design/2011">
    <Metadata>
        <Identity Language="en-US" Id="kaz-language" Version="$Version" Publisher="Kaz-Language" />
        <DisplayName>Kaz Programming Language</DisplayName>
        <Description xml:space="preserve">Suporte oficial à linguagem Kaz 🦅: Coloração sintática (Syntax Highlighting), snippets inteligentes e configuração de linguagem para Lumina IDE e VS Code.</Description>
        <Tags>kaz,lumina,programming-language,syntax,highlighting,rust,snippet,Kaz,__ext_kaz,__web_extension</Tags>
        <Categories>Programming Languages,Snippets</Categories>
        <GalleryFlags>Public</GalleryFlags>
        <Properties>
            <Property Id="Microsoft.VisualStudio.Code.Engine" Value="^1.60.0" />
            <Property Id="Microsoft.VisualStudio.Code.ExtensionDependencies" Value="" />
            <Property Id="Microsoft.VisualStudio.Code.ExtensionPack" Value="" />
            <Property Id="Microsoft.VisualStudio.Code.ExtensionKind" Value="ui,workspace,web" />
            <Property Id="Microsoft.VisualStudio.Code.LocalizedLanguages" Value="" />
            <Property Id="Microsoft.VisualStudio.Code.EnabledApiProposals" Value="" />
            <Property Id="Microsoft.VisualStudio.Services.Links.Source" Value="https://github.com/kazlang/kaz.git" />
            <Property Id="Microsoft.VisualStudio.Services.Links.Getstarted" Value="https://github.com/kazlang/kaz.git" />
            <Property Id="Microsoft.VisualStudio.Services.Links.GitHub" Value="https://github.com/kazlang/kaz.git" />
            <Property Id="Microsoft.VisualStudio.Services.Links.Support" Value="https://github.com/kazlang/kaz/issues" />
            <Property Id="Microsoft.VisualStudio.Services.Links.Learn" Value="https://github.com/kazlang/kaz#readme" />
            <Property Id="Microsoft.VisualStudio.Services.GitHubFlavoredMarkdown" Value="true" />
            <Property Id="Microsoft.VisualStudio.Services.Content.Pricing" Value="Free"/>
        </Properties>
        <Icon>extension/icon.png</Icon>
    </Metadata>
    <Installation>
        <InstallationTarget Id="Microsoft.VisualStudio.Code"/>
    </Installation>
    <Dependencies/>
    <Assets>
        <Asset Type="Microsoft.VisualStudio.Code.Manifest" Path="extension/package.json" Addressable="true" />
        <Asset Type="Microsoft.VisualStudio.Services.Content.Details" Path="extension/readme.md" Addressable="true" />
        <Asset Type="Microsoft.VisualStudio.Services.Icons.Default" Path="extension/icon.png" Addressable="true" />
    </Assets>
</PackageManifest>
"@
$entry = $archive.CreateEntry("extension.vsixmanifest", [System.IO.Compression.CompressionLevel]::Optimal)
$writer = New-Object System.IO.StreamWriter($entry.Open(), [System.Text.Encoding]::UTF8)
$writer.Write($manifestTemplate)
$writer.Close()

# 3. Adiciona arquivos da extensão
$files = Get-ChildItem -Path $srcDir -Recurse -File
foreach ($file in $files) {
    $relPath = $file.FullName.Substring($srcDir.Length).TrimStart('\', '/')
    $entryName = "extension/" + ($relPath -replace '\\', '/')
    $entry = $archive.CreateEntry($entryName, [System.IO.Compression.CompressionLevel]::Optimal)
    $fileStream = [System.IO.File]::OpenRead($file.FullName)
    $entryStream = $entry.Open()
    $fileStream.CopyTo($entryStream)
    $entryStream.Close()
    $fileStream.Close()
}

$archive.Dispose()
$zipStream.Close()

# Grava para a versão especificada e como padrão
Copy-Item $tempZip $outputVsix -Force
Move-Item $tempZip $outputVsixLatest -Force

Write-Host "OK: Pacote VSIX gerado: $outputVsix" -ForegroundColor Green
Write-Host "OK: Pacote padrão atualizado: $outputVsixLatest" -ForegroundColor Green
Write-Host "`nPronto para publicação no VS Code Marketplace ou instalação manual!" -ForegroundColor Cyan
