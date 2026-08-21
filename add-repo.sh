#!/bin/sh
set -eu

REPO_URL="https://exfurr-bash.github.io/pre-bin"
PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
KEY_PATH="$PREFIX/etc/apt/pre-bin.asc"
SOURCES_FILE="$PREFIX/etc/apt/sources.list.d/pre-bin.list"
FINGERPRINT="6D3A7F2B3B4D961BA1CA25DFB0E3CF9F2354A45A"
SUITE="testing"
COMPONENT="main"

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ] && [ "${TERM:-}" != "dumb" ]; then
    ESC=$(printf '\033')
    RED="$ESC[1;31m"
    YELLOW="$ESC[1;33m"
    GREEN="$ESC[1;32m"
    CYAN="$ESC[1;36m"
    RESET="$ESC[0m"
else
    RED=""; YELLOW=""; GREEN=""; CYAN=""; RESET=""
fi

usage() {
    cat <<EOF
${CYAN}pre-bin${RESET} — Unofficial APT repository for Termux

Usage:
  sh add-repo.sh [options]
  curl -fsSL $REPO_URL/add-repo.sh | sh -s -- [options]

Options:
  -y, --yes        Skip confirmation prompts
  --uninstall, --remove
                   Remove repository (key + sources.list) and run apt update
  --no-update      Do not run apt update after install/remove
  -h, --help       Show this help

Key fingerprint: $FINGERPRINT
Repo: $REPO_URL

Examples:
  sh add-repo.sh
  sh add-repo.sh --uninstall
  sh add-repo.sh -y --no-update
EOF
}

AUTO_YES=0
DO_UNINSTALL=0
NO_UPDATE=0

while [ $# -gt 0 ]; do
    case "$1" in
        -y|--yes) AUTO_YES=1; shift ;;
        --uninstall|--remove) DO_UNINSTALL=1; shift ;;
        --no-update) NO_UPDATE=1; shift ;;
        -h|--help) usage; exit 0 ;;
        --) shift; break ;;
        -*) echo "${RED}Unknown option:${RESET} $1" >&2; usage >&2; exit 1 ;;
        *) echo "${RED}Unknown argument:${RESET} $1" >&2; usage >&2; exit 1 ;;
    esac
done

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

fetch_to() {
    _url="$1"
    _dest="$2"
    if command -v curl >/dev/null 2>&1; then
        if curl -fsSL "$_url" -o "$_dest"; then return 0; fi
        echo "${YELLOW}curl failed, trying wget...${RESET}" >&2
    fi
    if command -v wget >/dev/null 2>&1; then
        if wget -qO "$_dest" "$_url"; then return 0; fi
    fi
    return 1
}

ensure_deps() {
    if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
        echo "${CYAN}Installing curl...${RESET}"
        pkg install -y curl || { echo "${RED}Failed to install curl.${RESET}" >&2; exit 1; }
    fi
    if ! command -v gpg >/dev/null 2>&1; then
        echo "${CYAN}Installing gnupg for key verification...${RESET}"
        pkg install -y gnupg || { echo "${RED}Failed to install gnupg.${RESET}" >&2; exit 1; }
    fi
}

verify_fingerprint() {
    _keyfile="$1"
    _found=""
    # Try gpg --show-keys (gpg 2.2+), fallback to --with-colons
    if gpg --show-keys "$_keyfile" >/dev/null 2>&1; then
        _found=$(gpg --show-keys "$_keyfile" 2>/dev/null | tr -d ' ' | grep -Eo '[0-9A-F]{40}' | head -n1 || true)
    else
        _found=$(gpg --with-colons --import-options show-only --import "$_keyfile" 2>/dev/null | awk -F: '$1=="fpr"{print $10; exit}' || true)
    fi
    if [ -z "$_found" ]; then
        echo "${RED}Failed to read GPG key fingerprint from downloaded file.${RESET}" >&2
        return 1
    fi
    if [ "$_found" != "$FINGERPRINT" ]; then
        echo "${RED}Fingerprint mismatch!${RESET}" >&2
        echo "  Expected: $FINGERPRINT" >&2
        echo "  Got:      $_found" >&2
        echo "${YELLOW}The downloaded key is NOT trusted. Aborting.${RESET}" >&2
        return 1
    fi
    echo "${GREEN}Fingerprint verified:${RESET} $_found"
}

# --- uninstall ---------------------------------------------------------------
if [ "$DO_UNINSTALL" = 1 ]; then
    echo "${CYAN}Removing pre-bin repository...${RESET}"
    rm -f "$KEY_PATH" "$SOURCES_FILE"
    echo "${GREEN}Removed:${RESET} $KEY_PATH"
    echo "${GREEN}Removed:${RESET} $SOURCES_FILE"
    if [ "$NO_UPDATE" = 0 ]; then
        echo "${CYAN}Running apt update...${RESET}"
        if ! apt update; then
            echo "${YELLOW}apt update failed — repository removed but package lists may be stale.${RESET}" >&2
            exit 1
        fi
    fi
    echo "${GREEN}Done! Repository removed.${RESET}"
    exit 0
fi

# --- confirmations -----------------------------------------------------------
if [ "$AUTO_YES" != 1 ]; then
    ask "This is an UNOFFICIAL third-party repository maintained by some random on the internet (exfurr-bash) — not the Termux project. If something breaks, don't bother the Termux maintainers. Bother me instead. Packages here are NOT reviewed or endorsed by Termux." \
        || { echo "${RED}Aborted. Nothing was changed.${RESET}"; exit 1; }

    ask "These packages are experimental and barely tested. They might break dependencies, nuke your setup, or just vibe-check your Termux install into oblivion. No guarantees of stability or compatibility — you have been warned. Twice now." \
        || { echo "${RED}Aborted. Nothing was changed.${RESET}"; exit 1; }

    ask "You're about to trust a GPG key to run code with your app privileges. The fingerprint is $FINGERPRINT — verify it like a paranoid, responsible adult. Or don't. I'm not your mom, but you really should." \
        || { echo "${RED}Aborted. Nothing was changed.${RESET}"; exit 1; }
fi

# --- deps & dirs -------------------------------------------------------------
ensure_deps

if [ ! -d "$PREFIX" ]; then
    echo "${RED}PREFIX not found:${RESET} $PREFIX" >&2
    exit 1
fi
if [ ! -w "$PREFIX" ]; then
    echo "${RED}No write permission for PREFIX:${RESET} $PREFIX" >&2
    exit 1
fi
mkdir -p "$(dirname "$KEY_PATH")" "$(dirname "$SOURCES_FILE")"

# --- download key atomically -------------------------------------------------
TMP_KEY=$(mktemp)
TMP_SRC=$(mktemp)
trap 'rm -f "${TMP_KEY:-}" "${TMP_SRC:-}"' EXIT INT TERM HUP

echo "${CYAN}Downloading signing key...${RESET}"
if ! fetch_to "$REPO_URL/repo.asc" "$TMP_KEY"; then
    echo "${RED}Failed to download GPG key from $REPO_URL/repo.asc${RESET}" >&2
    echo "${YELLOW}Check your network and try again.${RESET}" >&2
    exit 1
fi

if ! verify_fingerprint "$TMP_KEY"; then
    exit 1
fi

# --- idempotency check (still updates if already installed) ------------------
if [ -f "$KEY_PATH" ] && [ -f "$SOURCES_FILE" ]; then
    _existing_fpr=""
    if gpg --show-keys "$KEY_PATH" >/dev/null 2>&1; then
        _existing_fpr=$(gpg --show-keys "$KEY_PATH" 2>/dev/null | tr -d ' ' | grep -Eo '[0-9A-F]{40}' | head -n1 || true)
    fi
    _expected_src="deb [signed-by=$KEY_PATH] $REPO_URL $SUITE $COMPONENT"
    _current_src=$(cat "$SOURCES_FILE" 2>/dev/null || true)
    if [ "$_existing_fpr" = "$FINGERPRINT" ] && [ "$_current_src" = "$_expected_src" ]; then
        echo "${CYAN}Repository already configured — updating key and sources...${RESET}"
    else
        echo "${CYAN}Updating existing repository configuration...${RESET}"
    fi
fi

install -m 644 "$TMP_KEY" "$KEY_PATH"
echo "${GREEN}Key installed:${RESET} $KEY_PATH"

printf 'deb [signed-by=%s] %s %s %s\n' "$KEY_PATH" "$REPO_URL" "$SUITE" "$COMPONENT" > "$TMP_SRC"
install -m 644 "$TMP_SRC" "$SOURCES_FILE"
echo "${GREEN}Repository added:${RESET} $SOURCES_FILE"

# --- apt update --------------------------------------------------------------
if [ "$NO_UPDATE" = 0 ]; then
    echo "${CYAN}Running apt update...${RESET}"
    if ! apt update; then
        echo "${RED}apt update failed.${RESET}" >&2
        echo "${YELLOW}Repository was added but package lists could not be refreshed. Try: apt update${RESET}" >&2
        exit 1
    fi
else
    echo "${YELLOW}Skipping apt update (--no-update). Run: apt update${RESET}"
fi

echo "${GREEN}Done!${RESET} Install with: apt install <package>  (or pkg install <package>)"
echo "${RED} H A V E  F U N !${RESET}"
