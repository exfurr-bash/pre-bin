#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://exfurr-bash.github.io/pre-bin"
KEY_URL="$REPO_URL/repo.asc"
PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
KEYRING_DIR="$PREFIX/etc/apt/keyrings"
KEY_PATH="$KEYRING_DIR/pre-bin.gpg"
SOURCES_FILE="$PREFIX/etc/apt/sources.list.d/pre-bin.list"

main() {
    if [ "$(id -u)" -eq 0 ]; then
        echo "AVISO: rodando como root. Se estiver no Termux normal, o PREFIX correto e $PREFIX." >&2
    fi

    command -v curl >/dev/null 2>&1 || pkg install -y curl
    command -v gpg  >/dev/null 2>&1 || pkg install -y gnupg

    mkdir -p "$KEYRING_DIR"
    curl -fsSL "$KEY_URL" -o "$KEY_PATH"
    echo "Chave publica salva em $KEY_PATH"

    cat > "$SOURCES_FILE" <<EOF
deb [signed-by=$KEY_PATH] $REPO_URL stable main
EOF
    echo "Source adicionado em $SOURCES_FILE"
    apt update
    echo "Pronto! Instale com: apt install <pacote>  (ou pkg install <pacote>)"
}

main "$@"