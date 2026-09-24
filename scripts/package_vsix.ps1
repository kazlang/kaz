# ============================================================================
#   Empacotador Oficial VSIX da Linguagem Kaz (Zero dependência de Node) 🦅
#   Propriedade Intelectual (c) 2026 Armando Soares
# ============================================================================

param (
    [string]$Version = "1.1.0",
    [string]$Publisher = "Kaz-Language"
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

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "     Empacotador VSIX Kaz Language v$Version             " -ForegroundColor Cyan
Write-Host "     Publisher: $Publisher                              " -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan

# 1. Atualiza versão e publisher no package.json
$pkgJsonPath = Join-Path $srcDir "package.json"
if (Test-Path $pkgJsonPath) {
    $content = [System.IO.File]::ReadAllText($pkgJsonPath, [System.Text.Encoding]::UTF8)
    $content = [System.Text.RegularExpressions.Regex]::Replace($content, '"version":\s*"[^"]*"', "`"version`": `"$Version`"")
    $content = [System.Text.RegularExpressions.Regex]::Replace($content, '"publisher":\s*"[^"]*"', "`"publisher`": `"$Publisher`"")
    [System.IO.File]::WriteAllText($pkgJsonPath, $content, $utf8NoBom)
    Write-Host "OK: package.json atualizado (versão: $Version, publisher: $Publisher)" -ForegroundColor Green
}

$tempZip = [System.IO.Path]::GetTempFileName()
Remove-Item $tempZip -Force

$zipStream = [System.IO.File]::Create($tempZip)
$archive = New-Object System.IO.Compression.ZipArchive($zipStream, [System.IO.Compression.ZipArchiveMode]::Create)

# 2. [Content_Types].xml
$ctContent = "<?xml version=""1.0"" encoding=""utf-8""?>`r`n<Types xmlns=""http://schemas.openxmlformats.org/package/2006/content-types""><Default Extension="".json"" ContentType=""application/json""/><Default Extension="".md"" ContentType=""text/markdown""/><Default Extension="".png"" ContentType=""image/png""/><Default Extension="".vsixmanifest"" ContentType=""text/xml""/></Types>"
$entry = $archive.CreateEntry("[Content_Types].xml", [System.IO.Compression.CompressionLevel]::Optimal)
$writer = New-Object System.IO.StreamWriter($entry.Open(), $utf8NoBom)
$writer.Write($ctContent)
$writer.Close()

# 3. extension.vsixmanifest (Escrita pura UTF-8 sem BOM)
$manifestTemplate = @"
<?xml version="1.0" encoding="utf-8"?>
<PackageManifest Version="2.0.0" xmlns="http://schemas.microsoft.com/developer/vsx-schema/2011" xmlns:d="http://schemas.microsoft.com/developer/vsx-schema-design/2011">
    <Metadata>
        <Identity Language="en-US" Id="kaz-language" Version="$Version" Publisher="$Publisher" />
        <DisplayName>Kaz Programming Language</DisplayName>
        <Description xml:space="preserve">Suporte oficial a linguagem Kaz: Coloracao sintatica (Syntax Highlighting), snippets inteligentes e configuracao de linguagem para Lumina IDE e VS Code.</Description>
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
$writer = New-Object System.IO.StreamWriter($entry.Open(), $utf8NoBom)
$writer.Write($manifestTemplate)
$writer.Close()

# 4. Adiciona todos os arquivos da pasta editors/vscode
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

# 5. Salva os pacotes VSIX com nomes convenientes
$outputVsixVersion = Join-Path $distDir "kaz-language-$Version.vsix"
$outputVsixPublisher = Join-Path $distDir "$Publisher.kaz-language-$Version.vsix"
$outputVsixDefault = Join-Path $distDir "kaz-language.vsix"

Copy-Item $tempZip $outputVsixVersion -Force
Copy-Item $tempZip $outputVsixPublisher -Force
Move-Item $tempZip $outputVsixDefault -Force

Write-Host "`nOK: Pacotes VSIX gerados com sucesso (UTF-8 puro sem BOM):" -ForegroundColor Green
Write-Host "  -> $outputVsixVersion" -ForegroundColor White
Write-Host "  -> $outputVsixPublisher" -ForegroundColor White
Write-Host "  -> $outputVsixDefault" -ForegroundColor White
Write-Host "`nPronto para atualização no portal do VS Code Marketplace!" -ForegroundColor Cyan
