#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://exfurr-bash.github.io/pre-bin"
KEY_URL="$REPO_URL/repo.asc"
KEYRING_DIR="/etc/apt/keyrings"
KEY_PATH="$KEYRING_DIR/pre-bin.gpg"
SOURCES_FILE="/etc/apt/sources.list.d/pre-bin.list"

require_root() {
    if [ "$(id -u)" -ne 0 ]; then
        if command -v sudo >/dev/null 2>&1; then
            exec sudo bash "$0" "$@"
        fi
        echo "ERRO: rode como root (use 'sudo' no Termux: pkg install root-repo tsu)" >&2
        exit 1
    fi
}

main() {
    require_root "$@"
    command -v curl >/dev/null 2>&1 || { echo "ERRO: curl nao instalado (pkg install curl)" >&2; exit 1; }
    command -v gpg >/dev/null 2>&1 || { echo "ERRO: gnupg nao instalado (pkg install gnupg)" >&2; exit 1; }

    mkdir -p "$KEYRING_DIR"
    curl -fsSL "$KEY_URL" -o "$KEY_PATH"
    echo "Chave publica salva em $KEY_PATH"

    cat > "$SOURCES_FILE" <<EOF
deb [signed-by=$KEY_PATH] $REPO_URL stable main
EOF
    echo "Source adicionado em $SOURCES_FILE"
    echo "Execute: apt update && apt install <pacote>"
}

main "$@"