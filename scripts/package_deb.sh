#!/usr/bin/env bash
set -e

VERSION="1.5.0"
ARCH="amd64"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="${ROOT_DIR}/dist"
DEB_NAME="kaz_${VERSION}_${ARCH}.deb"
DEB_FILE="${DIST_DIR}/${DEB_NAME}"
KAZ_BIN="${ROOT_DIR}/target/release/kaz"

if [ ! -f "${KAZ_BIN}" ]; then
    echo "ERRO: Binario ${KAZ_BIN} nao encontrado. Compile primeiro com cargo build --release."
    exit 1
fi

TMP_DIR=$(mktemp -d /tmp/kaz_deb_build_XXXXXX)
cleanup() {
    rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

mkdir -p "${TMP_DIR}/debian"
mkdir -p "${TMP_DIR}/data/usr/local/bin"

echo "2.0" > "${TMP_DIR}/debian-binary"

cat << 'CTRL' > "${TMP_DIR}/debian/control"
Package: kaz
Version: 1.5.0
Section: devel
Priority: optional
Architecture: amd64
Maintainer: Armando Soares <armandosds@gmail.com>
Description: Kaz Programming Language (AOT Native x86-64, Cranelift JIT & Stack VM)
 Modern statically typed compiled programming language with 100% self-hosted sovereignty.
CTRL

cp "${KAZ_BIN}" "${TMP_DIR}/data/usr/local/bin/kaz"
chmod 755 "${TMP_DIR}/data/usr/local/bin/kaz"

(cd "${TMP_DIR}/debian" && tar --owner=0 --group=0 -czf "${TMP_DIR}/control.tar.gz" control)
(cd "${TMP_DIR}/data" && tar --owner=0 --group=0 -czf "${TMP_DIR}/data.tar.gz" usr)

mkdir -p "${DIST_DIR}"
(cd "${TMP_DIR}" && ar rcs "${DEB_FILE}" debian-binary control.tar.gz data.tar.gz)

echo "=== Pacote Debian gerado com sucesso! ==="
echo "Arquivo: ${DEB_FILE}"
ls -lh "${DEB_FILE}"
