# pre-bin

Repositorio APT para **Termux**, hospedado no GitHub Pages.

- URL: https://exfurr-bash.github.io/pre-bin
- Origem: https://github.com/exfurr-bash/pre-bin.git
- Suite: `stable`, Componente: `main`
- Arquiteturas suportadas: as que houverem `.deb` no pool (neste aparelho: `aarch64`)

## Estrutura

```
build-repo.sh          # regenera Packages/Packages.gz/Release/InRelease a partir de pool/
add-repo.sh            # script do cliente (Termux): instala chave + adiciona source
repo.asc               # chave publica PGP (commitada)
keys/                  # keyring privado LOCAL (nunca commitado)
pool/main/             # coloque os .deb aqui (pool/main/<pacote>/<pacote>_<ver>_<arch>.deb)
dists/stable/          # indice gerado (comitado)
```

## Como adicionar um pacote

1. Gere o `.deb` do Termux (ex.: com uma Toolchain/Termux-packages build) e coloque em `pool/main/`.
2. Dê push: o GitHub Actions executa `build-repo.sh` automaticamente e commita os índices gerados.
3. Opcional (local): execute `bash build-repo.sh` e faça commit manual.

Requisitos locais para rodar o script: `git`, `gpg`, `dpkg-deb`, `gzip`.

Confira a arquitetura do aparelho com `uname -m` (aarch64, arm, x86_64, i686).

## Configuração do GitHub (uma vez)

1. Crie o repositório `exfurr-bash/pre-bin` e faça push desta branch `main`.
2. Em Settings → Pages → Source: **Deploy from a branch** → `main` → `/ (root)` → Save.
3. (Opcional, recomendado) Assinatura no CI:
   ```
   gpg --homedir keys --armor --export-secret-keys pre-bin@localhost | base64 -w0
   ```
   Copie o resultado e salve como secret do repositório: Settings → Secrets → Actions → `GPG_SIGNING_KEY`.
   Sem esse secret, o CI publica o repositório **sem assinatura** (clientes usarão `[trusted=yes]`).

## Instalacao no cliente (Termux, sem root)

Com script:

```
curl -fsSL https://exfurr-bash.github.io/pre-bin/add-repo.sh | sh
apt update
apt install <pacote>   # ou: pkg install <pacote>
```

O script instala `curl`/`gnupg` se faltarem, baixa a chave e cria `$PREFIX/etc/apt/sources.list.d/pre-bin.list`.

Manual (verificado):

```
mkdir -p $PREFIX/etc/apt/keyrings
curl -fsSL https://exfurr-bash.github.io/pre-bin/repo.asc -o $PREFIX/etc/apt/keyrings/pre-bin.gpg
gpg --show-keys $PREFIX/etc/apt/keyrings/pre-bin.gpg   # confira a fingerprint
echo "deb [signed-by=$PREFIX/etc/apt/keyrings/pre-bin.gpg] https://exfurr-bash.github.io/pre-bin stable main" > $PREFIX/etc/apt/sources.list.d/pre-bin.list
apt update
```

Sem assinatura (apenas se o CI rodou sem o secret):

```
echo "deb [trusted=yes] https://exfurr-bash.github.io/pre-bin stable main" > $PREFIX/etc/apt/sources.list.d/pre-bin.list
apt update
```

> Dica: se quiser reverter, remova o arquivo `$PREFIX/etc/apt/sources.list.d/pre-bin.list` e rode `apt update`.