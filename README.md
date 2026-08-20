# pre-bin

Repositorio APT hospedado no GitHub Pages.

- URL: https://exfurr-bash.github.io/pre-bin
- Origem: https://github.com/exfurr-bash/pre-bin.git
- Suite: `stable`, Componente: `main`

## Estrutura

```
build-repo.sh          # regenera Packages/Packages.gz/Release/InRelease a partir de pool/
add-repo.sh            # script do cliente: instala chave + adiciona source
repo.asc               # chave publica PGP (commitada)
keys/                  # keyring privado LOCAL (nunca commitado)
pool/main/             # coloque os .deb aqui (pool/main/<pacote>/<pacote>_<ver>_<arch>.deb)
dists/stable/          # indice gerado (Commit)
```

## Como adicionar um pacote

1. Coloque o `.deb` em `pool/main/` (qualquer subpasta serve).
2. Dê push: o GitHub Actions executa `build-repo.sh` automaticamente
   e commit er os índices gerados.
3. Opcional (local): execute `bash build-repo.sh` e faça commit manual.

Requisitos locais para rodar o script: `git`, `gpg`, `dpkg-deb`, `gzip`.

## Configuração do GitHub (uma vez)

1. Crie o repositório `exfurr-bash/pre-bin` e faça push desta branch `main`.
2. Em Settings → Pages → Source: **Deploy from a branch** → `main` → `/ (root)` → Save.
3. (Opcional, recomendado) Assinatura no CI:
   ```
   gpg --homedir keys --armor --export-secret-keys pre-bin@localhost | base64 -w0
   ```
   Copie o resultado e salve como secret do repositório: Settings → Secrets → Actions → `GPG_SIGNING_KEY`.
   Sem esse secret, o CI publica o repositório **sem assinatura** (clientes usarão `[trusted=yes]`).

## Instalação no cliente (Termux com root/tsu, ou Debian/Ubuntu)

Com script:

```
curl -fsSL https://exfurr-bash.github.io/pre-bin/add-repo.sh | sudo sh
apt update
apt install <pacote>
```

Sem confiança no script, manual (verificado):

```
sudo mkdir -p /etc/apt/keyrings
sudo curl -fsSL https://exfurr-bash.github.io/pre-bin/repo.asc -o /etc/apt/keyrings/pre-bin.gpg
gpg --show-keys /etc/apt/keyrings/pre-bin.gpg   # confira a fingerprint
echo "deb [signed-by=/etc/apt/keyrings/pre-bin.gpg] https://exfurr-bash.github.io/pre-bin stable main" | sudo tee /etc/apt/sources.list.d/pre-bin.list
sudo apt update
```

Sem assinatura (apenas se o CI rodou sem o secret):

```
echo "deb [trusted=yes] https://exfurr-bash.github.io/pre-bin stable main" | sudo tee /etc/apt/sources.list.d/pre-bin.list
sudo apt update
```