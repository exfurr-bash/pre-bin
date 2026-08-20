# pre-bin

Unofficial APT repository for Termux with OCaml packages. Hosted on GitHub Pages and GPG-signed.

## Install

```sh
curl -fsSL https://exfurr-bash.github.io/pre-bin/add-repo.sh | sh
apt install ocaml
```

Manual way:

```sh
curl -fsSL https://exfurr-bash.github.io/pre-bin/repo.asc -o $PREFIX/etc/apt/pre-bin.asc
echo "deb [signed-by=$PREFIX/etc/apt/pre-bin.asc] https://exfurr-bash.github.io/pre-bin testing main" > $PREFIX/etc/apt/sources.list.d/pre-bin.list
apt update
apt install ocaml
```

Key fingerprint: `6D3A7F2B3B4D961BA1CA25DFB0E3CF9F2354A45A`