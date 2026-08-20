# pre-bin

Repositorio APT para Termux (GitHub Pages), assinado com GPG.

## Instalar

```sh
curl -fsSL https://exfurr-bash.github.io/pre-bin/add-repo.sh | sh
apt install <pacote>
```

## Adicionar pacote

```sh
cp <pacote>.deb pool/main/
bash build-repo.sh   # reindexa e assina
git add -A && git commit -m "pkg: <pacote>" && git push
```

Fingerprint da chave: `6D3A7F2B3B4D961BA1CA25DFB0E3CF9F2354A45A`