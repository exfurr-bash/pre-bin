# pre-bin

Repositorio de pacotes para **Termux**, hospedado no GitHub Pages e assinado com GPG (sem `trusted=yes`).

## Instalar

```sh
curl -fsSL https://exfurr-bash.github.io/pre-bin/add-repo.sh | sh
apt install <pacote>
```

O script baixa a chave publica, adiciona o repositorio com `signed-by` e roda `apt update`.

### Manual (mesma coisa)

```sh
curl -fsSL https://exfurr-bash.github.io/pre-bin/repo.asc -o $PREFIX/etc/apt/pre-bin.asc
echo "deb [signed-by=$PREFIX/etc/apt/pre-bin.asc] https://exfurr-bash.github.io/pre-bin stable main" > $PREFIX/etc/apt/sources.list.d/pre-bin.list
apt update
```

### Verificar a chave

```sh
gpg --show-keys $PREFIX/etc/apt/pre-bin.asc
```

Fingerprint: `6D3A7F2B3B4D961BA1CA25DFB0E3CF9F2354A45A`

## Pacotes

| Pacote | Versao | Descricao |
|---|---|---|
| `ocaml` | 5.5.0 | Compilador, runtime e bibliotecas base do OCaml |
| `ocaml-static` | 5.5.0 | Bibliotecas estaticas do OCaml |

## Remover

```sh
rm $PREFIX/etc/apt/sources.list.d/pre-bin.list $PREFIX/etc/apt/pre-bin.asc
apt update
```

## Colaborar

Abra uma issue [aqui](https://github.com/exfurr-bash/pre-bin/issues) com a sugestao de pacote ou envie o `.deb` em [uma release](https://github.com/exfurr-bash/pre-bin/releases).