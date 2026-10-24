#!/usr/bin/env bash
set -e

VERSION="1.5.0"
DIST_NAME="kaz-${VERSION}-linux-x86_64"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="${ROOT_DIR}/dist"
TARGET_DIST_DIR="${DIST_DIR}/${DIST_NAME}"
TAR_FILE="${DIST_DIR}/${DIST_NAME}.tar.gz"

echo "=== Empacotando Distribuição: ${DIST_NAME} ==="

KAZ_BIN="${ROOT_DIR}/bin/kaz"
if [ ! -f "${KAZ_BIN}" ]; then
    echo "ERRO: Binário ${KAZ_BIN} não encontrado."
    exit 1
fi

rm -rf "${TARGET_DIST_DIR}" "${TAR_FILE}"
mkdir -p "${TARGET_DIST_DIR}/bin"
mkdir -p "${TARGET_DIST_DIR}/examples"
mkdir -p "${TARGET_DIST_DIR}/docs"

cp "${KAZ_BIN}" "${TARGET_DIST_DIR}/bin/kaz"
cp -r "${ROOT_DIR}/examples/"* "${TARGET_DIST_DIR}/examples/"
cp -r "${ROOT_DIR}/docs/"* "${TARGET_DIST_DIR}/docs/"
cp "${ROOT_DIR}/README.md" "${TARGET_DIST_DIR}/"
cp "${ROOT_DIR}/LICENSE" "${TARGET_DIST_DIR}/"
cp "${ROOT_DIR}/install.sh" "${TARGET_DIST_DIR}/"
cp "${ROOT_DIR}/uninstall.sh" "${TARGET_DIST_DIR}/"

cd "${DIST_DIR}"
tar -czf "${TAR_FILE}" "${DIST_NAME}"

echo "Pacote de distribuição criado com sucesso!"
echo "Arquivo: ${TAR_FILE}"
