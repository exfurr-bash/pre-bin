# pre-bin

Repositorio APT para **Termux**, hospedado no GitHub Pages.

- URL: https://exfurr-bash.github.io/pre-bin
- Suite: `stable`, Componente: `main`

## Instalar

```
curl -fsSL https://exfurr-bash.github.io/pre-bin/add-repo.sh | sh
apt install <pacote>
```

Manual (mesma coisa):

```
echo "deb [trusted=yes] https://exfurr-bash.github.io/pre-bin stable main" > $PREFIX/etc/apt/sources.list.d/pre-bin.list
apt update
```

Para remover: `rm $PREFIX/etc/apt/sources.list.d/pre-bin.list && apt update`

## Adicionar pacotes

1. Coloque os `.deb` em `pool/main/` e faça push.
2. O GitHub Actions roda `build-repo.sh`, gera `Packages`/`Release` e commita sozinho.

Sem assinatura GPG por design — simples e direto.

## Estrutura

```
pool/main/     # os .deb (ex.: pool/main/<pacote>/<pacote>_<ver>_<arch>.deb)
dists/stable/  # indices gerados automaticamente
build-repo.sh  # gera os indices (usa dpkg-deb, md5sum, sha*, gzip)
add-repo.sh    # configurador do lado do cliente
```