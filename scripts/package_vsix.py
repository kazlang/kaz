#!/usr/bin/env python3
"""
Empacotador Oficial VSIX da Linguagem Kaz (Zero dependência de Node/npm) 🦅
Propriedade Intelectual (c) 2026 Armando Soares
"""

import os
import sys
import json
import shutil
import zipfile

VERSION = "1.5.0"
PUBLISHER = "Kaz-Language"

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ROOT_DIR = os.path.dirname(SCRIPT_DIR)
SRC_DIR = os.path.join(ROOT_DIR, "editors", "vscode")
DIST_DIR = os.path.join(ROOT_DIR, "dist")

os.makedirs(DIST_DIR, exist_ok=True)

# 1. Valida e atualiza package.json
pkg_json_path = os.path.join(SRC_DIR, "package.json")
if os.path.exists(pkg_json_path):
    with open(pkg_json_path, "r", encoding="utf-8") as f:
        pkg_data = json.load(f)
    pkg_data["version"] = VERSION
    pkg_data["publisher"] = PUBLISHER
    pkg_data["license"] = "MIT"
    with open(pkg_json_path, "w", encoding="utf-8") as f:
        json.dump(pkg_data, f, indent=4)
        f.write("\n")
    print(f"OK: package.json atualizado (versão: {VERSION}, publisher: {PUBLISHER})")

# 2. Gera VSIX em memória/arquivo temporário
temp_vsix = os.path.join(DIST_DIR, "temp_extension.zip")
if os.path.exists(temp_vsix):
    os.remove(temp_vsix)

content_types_xml = (
    '<?xml version="1.0" encoding="utf-8"?>\r\n'
    '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
    '<Default Extension=".json" ContentType="application/json"/>'
    '<Default Extension=".md" ContentType="text/markdown"/>'
    '<Default Extension=".txt" ContentType="text/plain"/>'
    '<Default Extension=".png" ContentType="image/png"/>'
    '<Default Extension=".vsixmanifest" ContentType="text/xml"/>'
    '<Override PartName="/extension/LICENSE" ContentType="text/plain"/>'
    '</Types>'
)

manifest_xml = f"""<?xml version="1.0" encoding="utf-8"?>
<PackageManifest Version="2.0.0" xmlns="http://schemas.microsoft.com/developer/vsx-schema/2011" xmlns:d="http://schemas.microsoft.com/developer/vsx-schema-design/2011">
    <Metadata>
        <Identity Language="en-US" Id="kaz-language" Version="{VERSION}" Publisher="{PUBLISHER}" />
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
            <Property Id="Microsoft.VisualStudio.Services.Content.License" Value="extension/LICENSE" />
        </Properties>
        <License>extension/LICENSE</License>
        <Icon>extension/icon.png</Icon>
    </Metadata>
    <Installation>
        <InstallationTarget Id="Microsoft.VisualStudio.Code"/>
    </Installation>
    <Dependencies/>
    <Assets>
        <Asset Type="Microsoft.VisualStudio.Code.Manifest" Path="extension/package.json" Addressable="true" />
        <Asset Type="Microsoft.VisualStudio.Services.Content.Details" Path="extension/README.md" Addressable="true" />
        <Asset Type="Microsoft.VisualStudio.Services.Content.License" Path="extension/LICENSE" Addressable="true" />
        <Asset Type="Microsoft.VisualStudio.Services.Icons.Default" Path="extension/icon.png" Addressable="true" />
    </Assets>
</PackageManifest>"""

with zipfile.ZipFile(temp_vsix, "w", zipfile.ZIP_DEFLATED) as z:
    # [Content_Types].xml
    z.writestr("[Content_Types].xml", content_types_xml.encode("utf-8"))
    # extension.vsixmanifest
    z.writestr("extension.vsixmanifest", manifest_xml.encode("utf-8"))
    
    # Arquivos em editors/vscode
    for root, dirs, files in os.walk(SRC_DIR):
        for file in files:
            if file.endswith(".vsix"):
                continue
            full_path = os.path.join(root, file)
            rel_path = os.path.relpath(full_path, SRC_DIR).replace("\\", "/")
            arc_name = f"extension/{rel_path}"
            z.write(full_path, arc_name)

out_version = os.path.join(DIST_DIR, f"kaz-language-{VERSION}.vsix")
out_publisher = os.path.join(DIST_DIR, f"{PUBLISHER}.kaz-language-{VERSION}.vsix")
out_default = os.path.join(DIST_DIR, "kaz-language.vsix")

shutil.copyfile(temp_vsix, out_version)
shutil.copyfile(temp_vsix, out_publisher)
shutil.move(temp_vsix, out_default)

print(f"\nOK: Pacotes VSIX gerados com sucesso (v{VERSION}):")
print(f"  -> {out_version}")
print(f"  -> {out_publisher}")
print(f"  -> {out_default}")
