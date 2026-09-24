#!/usr/bin/env bash
# ============================================================================
#   Instalador Oficial da Linguagem Kaz para Linux & macOS
#   Propriedade Intelectual (c) 2026 Armando Soares
# ============================================================================

set -e

echo "========================================================"
echo "     Instalador Oficial da Linguagem Kaz                "
echo "                 Versao 1.1.0                           "
echo "========================================================"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KAZ_BIN=""

# 1. Localizar executavel pre-compilado
if [ -f "${SCRIPT_DIR}/bin/kaz" ]; then
    KAZ_BIN="${SCRIPT_DIR}/bin/kaz"
elif [ -f "${SCRIPT_DIR}/kaz" ]; then
    KAZ_BIN="${SCRIPT_DIR}/kaz"
elif [ -f "${SCRIPT_DIR}/target/release/kaz" ]; then
    KAZ_BIN="${SCRIPT_DIR}/target/release/kaz"
elif [ -f "${SCRIPT_DIR}/Cargo.toml" ]; then
    echo "Ambiente de desenvolvimento detectado. Compilando com cargo..."
    if command -v cargo >/dev/null 2>&1; then
        (cd "${SCRIPT_DIR}" && cargo build --release)
        KAZ_BIN="${SCRIPT_DIR}/target/release/kaz"
    else
        echo "ERRO: O compilador 'cargo' nao foi encontrado no sistema."
        exit 1
    fi
fi

if [ -z "${KAZ_BIN}" ] || [ ! -f "${KAZ_BIN}" ]; then
    echo "ERRO: O executavel 'bin/kaz' nao foi encontrado nesta pasta."
    echo "Certifique-se de extrair todos os arquivos do pacote oficial da linguagem Kaz."
    exit 1
fi

# 2. Instalar binario em ~/.kaz/bin
INSTALL_DIR="${HOME}/.kaz/bin"
mkdir -p "${INSTALL_DIR}"
cp -f "${KAZ_BIN}" "${INSTALL_DIR}/kaz"
chmod +x "${INSTALL_DIR}/kaz"
echo "OK: Executavel copiado para ${INSTALL_DIR}/kaz"

# 3. Configurar PATH em todos os shells detectados
PATH_LINE='export PATH="$HOME/.kaz/bin:$PATH"'
SHELL_FILES=("${HOME}/.bashrc" "${HOME}/.zshrc" "${HOME}/.bash_profile" "${HOME}/.profile")
UPDATED_COUNT=0

for rc in "${SHELL_FILES[@]}"; do
    if [ -f "${rc}" ]; then
        if ! grep -q '\.kaz/bin' "${rc}"; then
            echo "" >> "${rc}"
            echo "${PATH_LINE}" >> "${rc}"
            echo "OK: PATH adicionado em ${rc}"
            UPDATED_COUNT=$((UPDATED_COUNT + 1))
        fi
    fi
done

if [ ${UPDATED_COUNT} -eq 0 ]; then
    if [ ! -f "${HOME}/.profile" ]; then
        echo "${PATH_LINE}" > "${HOME}/.profile"
        echo "OK: Criado ${HOME}/.profile com PATH configurado."
    fi
fi

# 4. Instalar Extensao para VS Code / Lumina IDE
EXT_SRC="${SCRIPT_DIR}/editors/vscode"
if [ -d "${EXT_SRC}" ]; then
    IDE_TARGETS=(
        "${HOME}/.vscode/extensions/kaz-language"
        "${HOME}/.vscode-insiders/extensions/kaz-language"
        "${HOME}/.lumina-editor/extensions/kaz-language"
        "${HOME}/.lumina-editor-dev/extensions/kaz-language"
    )
    for ide in "${IDE_TARGETS[@]}"; do
        parent_dir="$(dirname "${ide}")"
        root_editor="$(dirname "${parent_dir}")"
        if [ -d "${root_editor}" ]; then
            mkdir -p "${ide}"
            cp -f "${EXT_SRC}/package.json" "${ide}/" 2>/dev/null || true
            cp -f "${EXT_SRC}/language-configuration.json" "${ide}/" 2>/dev/null || true
            cp -f "${EXT_SRC}/README.md" "${ide}/" 2>/dev/null || true
            [ -f "${EXT_SRC}/icon.png" ] && cp -f "${EXT_SRC}/icon.png" "${ide}/" 2>/dev/null || true
            mkdir -p "${ide}/syntaxes" && cp -rf "${EXT_SRC}/syntaxes/"* "${ide}/syntaxes/" 2>/dev/null || true
            mkdir -p "${ide}/snippets" && cp -rf "${EXT_SRC}/snippets/"* "${ide}/snippets/" 2>/dev/null || true
            echo "OK: Extensao instalada em ${ide}"
        fi
    done
fi

# 5. Testar execucao
echo ""
echo "Testando instalacao..."
if "${INSTALL_DIR}/kaz" --version >/dev/null 2>&1; then
    VERSION_STR="$("${INSTALL_DIR}/kaz" --version)"
    echo "OK: ${VERSION_STR} instalado e verificado com sucesso!"
else
    echo "Aviso: Falha ao invocar executavel instalado."
fi

echo ""
echo "========================================================"
echo "  Instalacao concluida com sucesso!"
echo "  Reinicie o terminal ou execute:"
echo "    export PATH=\"\$HOME/.kaz/bin:\$PATH\""
echo "  Comandos disponiveis: kaz --help, kaz repl, kaz run <arquivo>"
echo "========================================================"
echo ""
