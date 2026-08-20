# pre-bin

Repositorio de pacotes para Termux com OCaml, hospedado no GitHub Pages e assinado com GPG.

## Instalar

```sh
curl -fsSL https://exfurr-bash.github.io/pre-bin/add-repo.sh | sh
apt install ocaml
```

Caminhos:

```sh
curl -fsSL https://exfurr-bash.github.io/pre-bin/repo.asc -o $PREFIX/etc/apt/pre-bin.asc
echo "deb [signed-by=$PREFIX/etc/apt/pre-bin.asc] https://exfurr-bash.github.io/pre-bin stable main" > $PREFIX/etc/apt/sources.list.d/pre-bin.list
apt update
apt install ocaml
```