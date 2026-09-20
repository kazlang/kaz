#!/usr/bin/env bash
set -e

echo "=== Instalador Oficial da Linguagem Kaz 🦅 ==="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KAZ_BIN=""

if [ -f "${SCRIPT_DIR}/bin/kaz" ]; then
    KAZ_BIN="${SCRIPT_DIR}/bin/kaz"
elif [ -f "${SCRIPT_DIR}/kaz" ]; then
    KAZ_BIN="${SCRIPT_DIR}/kaz"
elif [ -f "${SCRIPT_DIR}/target/release/kaz" ]; then
    KAZ_BIN="${SCRIPT_DIR}/target/release/kaz"
elif [ -f "${SCRIPT_DIR}/Cargo.toml" ]; then
    echo "Ambiente de desenvolvimento detectado. Compilando Kaz com cargo..."
    cargo build --release
    KAZ_BIN="${SCRIPT_DIR}/target/release/kaz"
fi

if [ -z "${KAZ_BIN}" ] || [ ! -f "${KAZ_BIN}" ]; then
    echo "ERRO: O executável 'bin/kaz' não foi encontrado nesta pasta."
    echo "Certifique-se de extrair todos os arquivos do pacote oficial da linguagem Kaz."
    exit 1
fi

INSTALL_DIR="${HOME}/.kaz/bin"
mkdir -p "${INSTALL_DIR}"
cp "${KAZ_BIN}" "${INSTALL_DIR}/kaz"
chmod +x "${INSTALL_DIR}/kaz"

# Configurar PATH
SHELL_RC=""
if [ -n "$ZSH_VERSION" ] || [ -f "${HOME}/.zshrc" ]; then
    SHELL_RC="${HOME}/.zshrc"
elif [ -f "${HOME}/.bashrc" ]; then
    SHELL_RC="${HOME}/.bashrc"
fi

if [ -n "${SHELL_RC}" ]; then
    if ! grep -q ".kaz/bin" "${SHELL_RC}"; then
        echo 'export PATH="$HOME/.kaz/bin:$PATH"' >> "${SHELL_RC}"
        echo "Adicionado ao PATH em ${SHELL_RC}"
    fi
fi

echo "✔ Kaz instalado com sucesso em ${INSTALL_DIR}/kaz"
echo "Execute 'source ${SHELL_RC}' ou reinicie o terminal para usar o comando 'kaz'."
