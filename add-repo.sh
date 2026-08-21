#!/bin/sh
set -eu

REPO_URL="https://exfurr-bash.github.io/pre-bin"
PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
KEY_PATH="$PREFIX/etc/apt/pre-bin.asc"
SOURCES_FILE="$PREFIX/etc/apt/sources.list.d/pre-bin.list"
FINGERPRINT="6D3A7F2B3B4D961BA1CA25DFB0E3CF9F2354A45A"
SUITE="testing"
COMPONENT="main"

E_OK=0
E_ABORT=1
E_USAGE=2
E_NETWORK=10
E_GPG=11
E_PERMISSION=13

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

# --- structured logging & error handling (Android compat, no pipe fail) ---------
TMP_KEY=""
TMP_SRC=""
BKUP_KEY=""
BKUP_SRC=""
DID_INSTALL=0

info()  { printf '%s[INFO]%s %s\n' "$CYAN" "$RESET" "$*" >&2; }
warn()  { printf '%s[WARN]%s %s\n' "$YELLOW" "$RESET" "$*" >&2; }
error() { printf '%s[ERROR]%s %s\n' "$RED" "$RESET" "$*" >&2; }

cleanup() {
    rm -f "${TMP_KEY:-}" "${TMP_SRC:-}" 2>/dev/null || true
}

rollback() {
    if [ "${DID_INSTALL:-0}" = 1 ]; then
        if [ -n "${BKUP_KEY:-}" ] && [ -f "$BKUP_KEY" ]; then
            install -m 644 "$BKUP_KEY" "$KEY_PATH" 2>/dev/null || rm -f "$KEY_PATH" 2>/dev/null || true
            rm -f "$BKUP_KEY" 2>/dev/null || true
        else
            rm -f "$KEY_PATH" 2>/dev/null || true
        fi
        if [ -n "${BKUP_SRC:-}" ] && [ -f "$BKUP_SRC" ]; then
            install -m 644 "$BKUP_SRC" "$SOURCES_FILE" 2>/dev/null || rm -f "$SOURCES_FILE" 2>/dev/null || true
            rm -f "$BKUP_SRC" 2>/dev/null || true
        else
            rm -f "$SOURCES_FILE" 2>/dev/null || true
        fi
    else
        rm -f "${BKUP_KEY:-}" "${BKUP_SRC:-}" 2>/dev/null || true
    fi
}

die() {
    _msg="$1"
    _code="${2:-$E_ABORT}"
    error "$_msg"
    rollback
    cleanup
    exit "$_code"
}

do_apt_update() {
    info "Running apt update..."
    if ! apt update; then
        die "apt update failed — repository added but lists not refreshed. Run 'apt update' when WiFi cooperates." $E_NETWORK
    fi
}

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

# --- early validation --------------------------------------------------------
if [ -z "${PREFIX:-}" ]; then
    die "PREFIX is empty — I need somewhere to write. Check your environment." $E_USAGE
fi
if [ -z "$REPO_URL" ]; then
    die "REPO_URL is empty — not sure where to fetch from." $E_USAGE
fi
if ! command -v install >/dev/null 2>&1; then
    die "install not found — coreutils missing? Can't set permissions safely." $E_PERMISSION
fi

AUTO_YES=0
DO_UNINSTALL=0
NO_UPDATE=0

while [ $# -gt 0 ]; do
    case "$1" in
        -y|--yes) AUTO_YES=1; shift ;;
        --uninstall|--remove) DO_UNINSTALL=1; shift ;;
        --no-update) NO_UPDATE=1; shift ;;
        -h|--help) usage; exit $E_OK ;;
        --) shift; break ;;
        -*) die "Unknown option: $1 — I don't know that trick. Try --help before inventing flags." $E_USAGE ;;
        *) die "Unknown argument: $1 — not in the script today. See --help." $E_USAGE ;;
    esac
done

ask() {
    printf '\n%sWARNING:%s %s\n' "$RED" "$RESET" "$1"
    for _ in 1 2 3; do
        printf '%sAre you sure you want to continue? [s/N] %s' "$YELLOW" "$RESET"
        if ! read -r answer < /dev/tty; then
            die "No interactive terminal — can't ask for permission. Download and run locally: curl -O $REPO_URL/add-repo.sh && sh add-repo.sh" $E_USAGE
        fi
        case "$answer" in
            s|S|y|Y|yes|YES) return 0 ;;
            "") return 1 ;;
        esac
    done
    warn "No answer after 3 tries — I'll take that as a no."
    return 1
}

fetch_to() {
    _url="$1"
    _dest="$2"
    if command -v curl >/dev/null 2>&1; then
        if curl --connect-timeout 15 -fsSL "$_url" -o "$_dest"; then return 0; fi
        warn "curl failed — trying wget, plan B."
    fi
    if command -v wget >/dev/null 2>&1; then
        if wget --timeout=15 -qO "$_dest" "$_url"; then return 0; fi
        warn "wget also failed — network is being mysterious."
    fi
    return 1
}

ensure_deps() {
    if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
        info "Installing curl..."
        pkg install -y curl || die "Failed to install curl via pkg — pkg is being difficult. Try 'pkg update' first." $E_NETWORK
    fi
    if ! command -v gpg >/dev/null 2>&1; then
        info "Installing gnupg for key verification..."
        pkg install -y gnupg || die "Failed to install gnupg — need gpg to verify. Try 'pkg install gnupg' manually." $E_GPG
    fi
}

verify_fingerprint() {
    _keyfile="$1"
    _found=""
    if gpg --show-keys "$_keyfile" >/dev/null 2>&1; then
        _found=$(gpg --show-keys "$_keyfile" 2>/dev/null | tr -d ' ' | grep -Eo '[0-9A-F]{40}' | head -n1 || true)
    else
        _found=$(gpg --with-colons --import-options show-only --import "$_keyfile" 2>/dev/null | awk -F: '$1=="fpr"{print $10; exit}' || true)
    fi
    if [ -z "$_found" ]; then
        error "Failed to read fingerprint — file looks more like modern art than PGP."
        warn "Nothing was changed, nothing trusted."
        return 1
    fi
    if [ "$_found" != "$FINGERPRINT" ]; then
        error "Fingerprint mismatch!"
        error "  Expected: $FINGERPRINT"
        error "  Got:      $_found"
        warn "That's not the key you're looking for — aborting, nothing trusted."
        return 1
    fi
    printf '%sFingerprint verified:%s %s\n' "$GREEN" "$RESET" "$_found" >&2
}

# --- uninstall ---------------------------------------------------------------
if [ "$DO_UNINSTALL" = 1 ]; then
    info "Removing pre-bin repository..."
    rm -f "$KEY_PATH" "$SOURCES_FILE" || die "Failed to remove $KEY_PATH or $SOURCES_FILE — permission denied?" $E_PERMISSION
    printf '%sRemoved:%s %s\n' "$GREEN" "$RESET" "$KEY_PATH" >&2
    printf '%sRemoved:%s %s\n' "$GREEN" "$RESET" "$SOURCES_FILE" >&2
    if [ "$NO_UPDATE" = 0 ]; then
        do_apt_update
    else
        warn "Skipping apt update (--no-update)."
    fi
    printf '%sDone! Repository removed.%s\n' "$GREEN" "$RESET" >&2
    cleanup
    exit $E_OK
fi

# --- confirmations -----------------------------------------------------------
if [ "$AUTO_YES" != 1 ]; then
    ask "This is an UNOFFICIAL third-party repository maintained by some random on the internet (exfurr-bash) — not the Termux project. If something breaks, don't bother the Termux maintainers. Bother me instead. Packages here are NOT reviewed or endorsed by Termux." \
        || die "Aborted. Nothing was changed. Wise choice — paranoia is a feature." $E_ABORT

    ask "These packages are experimental and barely tested. They might break dependencies, nuke your setup, or just vibe-check your Termux install into oblivion. No guarantees of stability or compatibility — you have been warned. Twice now." \
        || die "Aborted. Nothing was changed. You read the warnings, good." $E_ABORT

    ask "You're about to trust a GPG key to run code with your app privileges. The fingerprint is $FINGERPRINT — verify it like a paranoid, responsible adult. Or don't. I'm not your mom, but you really should." \
        || die "Aborted. Nothing was changed. The key will wait." $E_ABORT
fi

# --- deps & dirs -------------------------------------------------------------
ensure_deps

if [ ! -d "$PREFIX" ]; then
    die "PREFIX not found: $PREFIX — Termux prefix wandered off?" $E_PERMISSION
fi
if [ ! -w "$PREFIX" ]; then
    die "No write permission for $PREFIX — I can't write where you won't let me." $E_PERMISSION
fi
mkdir -p "$(dirname "$KEY_PATH")" "$(dirname "$SOURCES_FILE")" || die "Cannot create $(dirname "$KEY_PATH") — permission denied. Nothing was changed." $E_PERMISSION

# --- prepare temps and backups for rollback ---------------------------------
TMP_KEY=$(mktemp) || die "mktemp failed for key — /tmp full or no permission? Nothing was changed." $E_PERMISSION
TMP_SRC=$(mktemp) || die "mktemp failed for sources — /tmp full or no permission? Nothing was changed." $E_PERMISSION
# traps must be after TMPs are set, so they have values to clean
trap 'cleanup' EXIT INT TERM HUP

# backup existing files for rollback (if they exist)
if [ -f "$KEY_PATH" ]; then
    BKUP_KEY=$(mktemp) || die "mktemp failed for backup — /tmp full?" $E_PERMISSION
    cp -a "$KEY_PATH" "$BKUP_KEY" 2>/dev/null || die "Failed to backup $KEY_PATH — permission denied?" $E_PERMISSION
fi
if [ -f "$SOURCES_FILE" ]; then
    BKUP_SRC=$(mktemp) || die "mktemp failed for backup — /tmp full?" $E_PERMISSION
    cp -a "$SOURCES_FILE" "$BKUP_SRC" 2>/dev/null || die "Failed to backup $SOURCES_FILE — permission denied?" $E_PERMISSION
fi
DID_INSTALL=1

# --- download key atomically -------------------------------------------------
info "Downloading signing key..."
if ! fetch_to "$REPO_URL/repo.asc" "$TMP_KEY"; then
    die "Failed to download GPG key from $REPO_URL/repo.asc — the internet is shy today. Check your connection. Nothing was changed." $E_NETWORK
fi

if ! verify_fingerprint "$TMP_KEY"; then
    die "GPG verification failed — nothing was changed, nothing trusted. Check fingerprint $FINGERPRINT." $E_GPG
fi

# --- idempotency check (still updates if already installed) ------------------
if [ -f "$KEY_PATH" ] && [ -f "$SOURCES_FILE" ]; then
    _existing_fpr=""
    if gpg --show-keys "$KEY_PATH" >/dev/null 2>&1; then
        _existing_fpr=$(gpg --show-keys "$KEY_PATH" 2>/dev/null | tr -d ' ' | grep -Eo '[0-9A-F]{40}' | head -n1 || true)
    else
        _existing_fpr=$(gpg --with-colons --import-options show-only --import "$KEY_PATH" 2>/dev/null | awk -F: '$1=="fpr"{print $10; exit}' || true)
    fi
    _expected_src="deb [signed-by=$KEY_PATH] $REPO_URL $SUITE $COMPONENT"
    _current_src=$(cat "$SOURCES_FILE" 2>/dev/null || true)
    if [ "$_existing_fpr" = "$FINGERPRINT" ] && [ "$_current_src" = "$_expected_src" ]; then
        info "Repository already configured — updating key and sources..."
    else
        info "Updating existing repository configuration..."
    fi
fi

install -m 644 "$TMP_KEY" "$KEY_PATH" || die "Cannot install $KEY_PATH — permission denied. Rolled back." $E_PERMISSION
printf '%sKey installed:%s %s\n' "$GREEN" "$RESET" "$KEY_PATH" >&2

printf 'deb [signed-by=%s] %s %s %s\n' "$KEY_PATH" "$REPO_URL" "$SUITE" "$COMPONENT" > "$TMP_SRC" || die "Failed to write temp sources — disk full? Rolled back." $E_PERMISSION
install -m 644 "$TMP_SRC" "$SOURCES_FILE" || die "Cannot install $SOURCES_FILE — permission denied. Rolled back." $E_PERMISSION
printf '%sRepository added:%s %s\n' "$GREEN" "$RESET" "$SOURCES_FILE" >&2

# rollback no longer needed after successful install — clear backups
rm -f "${BKUP_KEY:-}" "${BKUP_SRC:-}" 2>/dev/null || true
BKUP_KEY=""; BKUP_SRC=""; DID_INSTALL=0

# --- apt update --------------------------------------------------------------
if [ "$NO_UPDATE" = 0 ]; then
    do_apt_update
else
    warn "Skipping apt update (--no-update). Run: apt update"
fi

printf '%sDone!%s Install with: apt install <package>  (or pkg install <package>)\n' "$GREEN" "$RESET" >&2
printf '%s H A V E  F U N !%s\n' "$RED" "$RESET" >&2
