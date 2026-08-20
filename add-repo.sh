#!/bin/sh
set -eu

REPO_URL="https://exfurr-bash.github.io/pre-bin"
PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
KEY_PATH="$PREFIX/etc/apt/pre-bin.asc"
SOURCES_FILE="$PREFIX/etc/apt/sources.list.d/pre-bin.list"

command -v curl >/dev/null 2>&1 || pkg install -y curl

curl -fsSL "$REPO_URL/repo.asc" -o "$KEY_PATH"
echo "deb [signed-by=$KEY_PATH] $REPO_URL stable main" > "$SOURCES_FILE"
echo "Source adicionado em $SOURCES_FILE"
apt update
echo "Pronto! Instale com: apt install <pacote>"