#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

SUITE="stable"
COMPONENT="main"
POOL="pool"
DISTS="dists/$SUITE"
ROOT="$DISTS/$COMPONENT"
REPO_NAME="pre-bin"
REPO_URL="https://exfurr-bash.github.io/pre-bin"
KEYRING="${GPG_KEYRING:-keys}"
KEY_ID="${GPG_KEY_ID:-pre-bin@localhost}"

mkdir -p "$ROOT"

debs=($(find "$POOL" -name '*.deb' -type f | sort))

declare -A archs=()
declare -A pkg_index=()

for deb in "${debs[@]}"; do
    arch=$(dpkg-deb -f "$deb" Architecture)
    archs[$arch]=1
    pkg_index[$arch]+="$deb "
done

if [ ${#archs[@]} -eq 0 ]; then
    echo "Nenhum .deb encontrado em $POOL/. Gerando estrutura vazia."
    archs[all]=1
fi

arch_list=""
for a in "${!archs[@]}"; do
    [ -n "$arch_list" ] && arch_list+=" "
    arch_list+="$a"
done
echo "Arquiteturas: $arch_list"

for a in "${!archs[@]}"; do
    bindir="$ROOT/binary-$a"
    mkdir -p "$bindir"
    pkgfile="$bindir/Packages"
    : > "$pkgfile"

    for deb in ${pkg_index[$a]:-}; do
        {
            echo "Package: $(dpkg-deb -f "$deb" Package)"
            for field in Version Architecture Maintainer Depends Conflicts Provides Replaces Recommends Suggests Section Priority Installed-Size Description Homepage; do
                value=$(dpkg-deb -f "$deb" "$field")
                if [ -n "$value" ] && [ "$field" != "Package" ] && [ "$field" != "Architecture" ]; then
                    echo "$field: $value"
                fi
            done
            echo "Filename: $deb"
            echo "Size: $(stat -c %s "$deb")"
            echo "MD5sum: $(md5sum "$deb" | cut -d' ' -f1)"
            echo "SHA1: $(sha1sum "$deb" | cut -d' ' -f1)"
            echo "SHA256: $(sha256sum "$deb" | cut -d' ' -f1)"
            echo
        } >> "$pkgfile"
    done

    gzip -9 -c < "$pkgfile" > "$bindir/Packages.gz"
done

allpkgs=$(find "$ROOT" -name Packages -type f | wc -l)
if [ "$allpkgs" -eq 0 ]; then
    echo "AVISO: nenhum package index gerado (pool vazio)."
fi

now=$(date -Ru)
release_core="$ROOT/Release"
{
    echo "Origin: $REPO_NAME"
    echo "Label: $REPO_NAME"
    echo "Suite: $SUITE"
    echo "Codename: $SUITE"
    echo "Version: 1.0"
    echo "Architectures: $arch_list"
    echo "Components: $COMPONENT"
    echo "Description: Repositorio APT $REPO_NAME"
    echo "Date: $now"
} > "$release_core"

hash_entries() {
    local alg="$1" field="$2" hashcmd="$3"
    echo "$field:" >> "$release_core"
    find "$ROOT" -type f -printf '%p\0' | sort -z | while IFS= read -r -d '' f; do
        sum=$("$hashcmd" "$f" | cut -d' ' -f1)
        size=$(stat -c %s "$f")
        printf ' %s %s %s\n' "$sum" "$size" "${f#./}"
    done >> "$release_core"
}

hash_entries md5 MD5Sum md5sum
hash_entries sha1 SHA1 sha1sum
hash_entries sha256 SHA256 sha256sum

release="$DISTS/Release"
{
    echo "Origin: $REPO_NAME"
    echo "Label: $REPO_NAME"
    echo "Suite: $SUITE"
    echo "Codename: $SUITE"
    echo "Version: 1.0"
    echo "Architectures: $arch_list"
    echo "Components: $COMPONENT"
    echo "Description: Repositorio APT $REPO_NAME"
    echo "Date: $now"
} > "$release"

hash_root_entries() {
    local alg="$1" field="$2" hashcmd="$3"
    echo "$field:" >> "$release"
    find "$ROOT" -type f -printf '%p\0' | sort -z | while IFS= read -r -d '' f; do
        sum=$("$hashcmd" "$f" | cut -d' ' -f1)
        size=$(stat -c %s "$f")
        printf ' %s %s %s\n' "$sum" "$size" "${f#./}"
    done >> "$release"
}

hash_root_entries md5 MD5Sum md5sum
hash_root_entries sha1 SHA1 sha1sum
hash_root_entries sha256 SHA256 sha256sum

if gpg --homedir "$KEYRING" --list-secret-keys "$KEY_ID" >/dev/null 2>&1; then
    gpg --homedir "$KEYRING" --batch --pinentry-mode loopback --passphrase '' --clearsign -o "$DISTS/InRelease" "$release"
    gpg --homedir "$KEYRING" --batch --pinentry-mode loopback --passphrase '' --detach-sign -o "$DISTS/Release.gpg" "$release"
    echo "InRelease assinado com $KEY_ID"
else
    echo "AVISO: chave privada nao encontrada em $KEYRING - InRelease/Release.gpg nao gerados."
    echo "Clientes precisarao usar [trusted=yes] ou --allow-untrusted."
fi

echo "Repositorio atualizado em $DISTS (URL: $REPO_URL $SUITE $COMPONENT)"