#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

SUITE="testing"
COMPONENT="main"
POOL="pool"
DISTS="dists/$SUITE"
ROOT="$DISTS/$COMPONENT"
REPO_NAME="pre-bin"

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

for old in "$ROOT"/binary-*; do
    [ -d "$old" ] || continue
    base=$(basename "$old")
    if ! grep -qw "${base#binary-}" <<<"$arch_list"; then
        rm -rf "$old"
        echo "Removido diretorio obsoleto: $old"
    fi
done

for a in "${!archs[@]}"; do
    bindir="$ROOT/binary-$a"
    mkdir -p "$bindir"
    pkgfile="$bindir/Packages"
    : > "$pkgfile"

    for deb in ${pkg_index[$a]:-}; do
        {
            echo "Package: $(dpkg-deb -f "$deb" Package)"
            echo "Architecture: $a"
            for field in Version Maintainer Depends Conflicts Provides Replaces Recommends Suggests Section Priority Installed-Size Description Homepage; do
                value=$(dpkg-deb -f "$deb" "$field")
                if [ -n "$value" ]; then
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

pool_commit=$(git log -1 --format='%cI' -- "$POOL" 2>/dev/null || true)
now=$(date -d "$pool_commit" -Ru 2>/dev/null || date -Ru)

write_release() {
    local file="$1"
    {
        echo "Origin: $REPO_NAME"
        echo "Label: $REPO_NAME"
        echo "Suite: $SUITE"
        echo "Codename: $SUITE"
        echo "Version: 1.0"
        echo "Architectures: $arch_list"
        echo "Components: $COMPONENT"
        echo "Description: Repositorio APT $REPO_NAME (Termux)"
        echo "Date: $now"
        echo "MD5Sum:"
        find "$ROOT" -type f -printf 'main/%P\0' | sort -z | while IFS= read -r -d '' f; do
            printf ' %s %s %s\n' "$(md5sum "$ROOT/${f#main/}" | cut -d' ' -f1)" "$(stat -c %s "$ROOT/${f#main/}")" "$f"
        done
        echo "SHA1:"
        find "$ROOT" -type f -printf 'main/%P\0' | sort -z | while IFS= read -r -d '' f; do
            printf ' %s %s %s\n' "$(sha1sum "$ROOT/${f#main/}" | cut -d' ' -f1)" "$(stat -c %s "$ROOT/${f#main/}")" "$f"
        done
        echo "SHA256:"
        find "$ROOT" -type f -printf 'main/%P\0' | sort -z | while IFS= read -r -d '' f; do
            printf ' %s %s %s\n' "$(sha256sum "$ROOT/${f#main/}" | cut -d' ' -f1)" "$(stat -c %s "$ROOT/${f#main/}")" "$f"
        done
    } > "$file"
}

write_release "$DISTS/Release"

if gpg --homedir keys --list-secret-keys pre-bin@localhost >/dev/null 2>&1; then
    rm -f "$DISTS/InRelease"
    gpg --homedir keys --batch --pinentry-mode loopback --passphrase '' \
        --clearsign -o "$DISTS/InRelease" "$DISTS/Release"
    echo "Release assinado -> $DISTS/InRelease"
else
    echo "AVISO: chave privada nao encontrada em keys/ - repo gerado SEM assinatura."
    echo "Clientes precisarao de [trusted=yes]."
fi

echo "Repositorio atualizado em $DISTS"