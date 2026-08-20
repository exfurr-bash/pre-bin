#!/bin/sh
set -eu

REPO_URL="https://exfurr-bash.github.io/pre-bin"
PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
KEY_PATH="$PREFIX/etc/apt/pre-bin.asc"
SOURCES_FILE="$PREFIX/etc/apt/sources.list.d/pre-bin.list"
FINGERPRINT="6D3A7F2B3B4D961BA1CA25DFB0E3CF9F2354A45A"

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ] && [ "$TERM" != "dumb" ]; then
    ESC=$(printf '\033')
    RED="$ESC[1;31m"
    YELLOW="$ESC[1;33m"
    GREEN="$ESC[1;32m"
    CYAN="$ESC[1;36m"
    RESET="$ESC[0m"
else
    RED=""; YELLOW=""; GREEN=""; CYAN=""; RESET=""
fi

ask() {
    printf '\n%sWARNING:%s %s\n' "$RED" "$RESET" "$1"
    for _ in 1 2 3; do
        printf '%sAre you sure you want to continue? [s/N] %s' "$YELLOW" "$RESET"
        if ! read -r answer < /dev/tty; then
            echo "${RED}No interactive terminal detected.${RESET}"
            echo "${CYAN}Download the script and run it locally instead:${RESET}"
            echo "${CYAN}  curl -O $REPO_URL/add-repo.sh && sh add-repo.sh${RESET}"
            exit 1
        fi
        case "$answer" in
            s|S|y|Y|yes|YES) return 0 ;;
            "") return 1 ;;
        esac
    done
    return 1
}

if [ "${1:-}" != "-y" ] && [ "${1:-}" != "--yes" ]; then
    ask "This is an UNOFFICIAL third-party repository maintained by exfurr-bash, \
not part of the Termux project. Packages here are NOT reviewed or endorsed by Termux maintainers." \
        || { echo "${RED}Aborted. Nothing was changed.${RESET}"; exit 1; }

    ask "Packages in this repository are experimental and NOT fully tested. \
They may break other packages or interfere with your existing Termux setup. \
No guarantees of stability or compatibility." \
        || { echo "${RED}Aborted. Nothing was changed.${RESET}"; exit 1; }

    ask "Installing packages runs scripts with app privileges. \
Before trusting this repository, verify the signing key fingerprint: $FINGERPRINT" \
        || { echo "${RED}Aborted. Nothing was changed.${RESET}"; exit 1; }
fi

command -v curl >/dev/null 2>&1 || pkg install -y curl

curl -fsSL "$REPO_URL/repo.asc" -o "$KEY_PATH"
echo "deb [signed-by=$KEY_PATH] $REPO_URL testing main" > "$SOURCES_FILE"
echo "${GREEN}Repository added:${RESET} $SOURCES_FILE"
apt update
echo "${GREEN}Done!${RESET} Install with: apt install <package>"