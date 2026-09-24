#!/usr/bin/env bash
# ============================================================================
#   Desinstalador Oficial da Linguagem Kaz para Linux & macOS
#   Propriedade Intelectual (c) 2026 Armando Soares
# ============================================================================

echo "========================================================"
echo "     Desinstalador Oficial da Linguagem Kaz             "
echo "========================================================"
echo ""

# 1. Encerrar processos em execucao
echo "[1/4] Verificando processos em execucao..."
pkill -x kaz 2>/dev/null || true
echo "  OK: Nenhum processo kaz ativo."

# 2. Remover diretorio de instalacao
echo ""
echo "[2/4] Removendo arquivos do Kaz..."
INSTALL_DIR="${HOME}/.kaz"
if [ -d "${INSTALL_DIR}" ]; then
    rm -rf "${INSTALL_DIR}"
    echo "  OK: Diretorio ${INSTALL_DIR} removido com sucesso."
else
    echo "  OK: Diretorio de instalacao nao encontrado (ja removido)."
fi

# 3. Remover do PATH nos arquivos de configuracao do shell
echo ""
echo "[3/4] Removendo Kaz do PATH..."
SHELL_FILES=("${HOME}/.bashrc" "${HOME}/.zshrc" "${HOME}/.bash_profile" "${HOME}/.profile")
CLEANED_COUNT=0

for rc in "${SHELL_FILES[@]}"; do
    if [ -f "${rc}" ] && grep -q '\.kaz/bin' "${rc}"; then
        grep -v '\.kaz/bin' "${rc}" > "${rc}.kaz_tmp" && mv "${rc}.kaz_tmp" "${rc}"
        echo "  OK: Entrada do PATH removida de ${rc}"
        CLEANED_COUNT=$((CLEANED_COUNT + 1))
    fi
done

if [ ${CLEANED_COUNT} -eq 0 ]; then
    echo "  OK: Nenhuma entrada encontrada no PATH dos arquivos de shell."
fi

# 4. Remover extensoes instaladas de IDEs
echo ""
echo "[4/4] Removendo extensoes de IDEs..."
IDE_DIRS=(
    "${HOME}/.vscode/extensions"
    "${HOME}/.vscode-insiders/extensions"
    "${HOME}/.lumina-editor/extensions"
    "${HOME}/.lumina-editor-dev/extensions"
)

REMOVED_EXT=0
for dir in "${IDE_DIRS[@]}"; do
    if [ -d "${dir}" ]; then
        for match in "${dir}"/*kaz-language*; do
            if [ -d "${match}" ]; then
                rm -rf "${match}"
                echo "  OK: Extensao removida de ${match}"
                REMOVED_EXT=$((REMOVED_EXT + 1))
            fi
        done
    fi
done

if [ ${REMOVED_EXT} -eq 0 ]; then
    echo "  OK: Nenhuma extensao de IDE encontrada para remover."
fi

echo ""
echo "========================================================"
echo "  Desinstalacao concluida com sucesso!"
echo "  O sistema esta limpo e pronto para uma nova instalacao."
echo "========================================================"
echo ""
