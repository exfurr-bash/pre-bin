# pre-bin

Unofficial APT repository for Termux. Hosted on GitHub Pages and GPG-signed.

> **Disclaimer, with love:** This is *not* an official Termux repo. It's maintained by some random on the internet (exfurr-bash) in their free time. Packages are experimental, barely tested, and might vibe-check your install into oblivion. If it breaks, bother me — not the Termux maintainers.

## Quick install (the easy way)

_Yes, it's a `curl | sh`. We know. At least we verify the GPG key for you._

```sh
curl -fsSL https://exfurr-bash.github.io/pre-bin/add-repo.sh | sh
# you'll get 3 warnings — read them, seriously
apt install <package>
```

Options: `sh add-repo.sh --help` | `-y/--yes` skip prompts | `--uninstall` remove | `--no-update` skip apt update

## Manual way (for the paranoid, responsible adults)

```sh
curl -fsSL https://exfurr-bash.github.io/pre-bin/repo.asc -o $PREFIX/etc/apt/pre-bin.asc
# verify fingerprint like a pro:
gpg --show-keys $PREFIX/etc/apt/pre-bin.asc
echo "deb [signed-by=$PREFIX/etc/apt/pre-bin.asc] https://exfurr-bash.github.io/pre-bin testing main" > $PREFIX/etc/apt/sources.list.d/pre-bin.list
apt update
apt install <package>
```

## Uninstall

```sh
sh add-repo.sh --uninstall   # removes key + sources, keeps gnupg
# or if you already removed the file:
curl -O https://exfurr-bash.github.io/pre-bin/add-repo.sh && sh add-repo.sh --uninstall
```

Key fingerprint: `6D3A7F2B3B4D961BA1CA25DFB0E3CF9F2354A45A`

Source: [github.com/exfurr-bash/pre-bin](https://github.com/exfurr-bash/pre-bin) — PRs welcome, blame welcome too.
