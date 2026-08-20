#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://exfurr-bash.github.io/pre-bin"
PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
SOURCES_FILE="$PREFIX/etc/apt/sources.list.d/pre-bin.list"

mkdir -p "$(dirname "$SOURCES_FILE")"
echo "deb [trusted=yes] $REPO_URL stable main" > "$SOURCES_FILE"
echo "Source adicionado em $SOURCES_FILE"
apt update
echo "Pronto! Instale com: apt install <pacote>"