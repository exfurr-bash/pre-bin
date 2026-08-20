# TESTING-REPO

«⚠️ Notice: Artificial intelligence is used in the development and maintenance of this repository.»

Unofficial and unstable packages for Termux, hosted on GitHub Pages and GPG-signed.

# Install

Automatic
```
curl -fsSL https://exfurr-bash.github.io/pre-bin/add-repo.sh | sh
```
# Manual
```
curl -fsSL https://exfurr-bash.github.io/pre-bin/repo.asc \
  -o $PREFIX/etc/apt/pre-bin.asc

echo "deb [signed-by=$PREFIX/etc/apt/pre-bin.asc] https://exfurr-bash.github.io/pre-bin stable main" \
  > $PREFIX/etc/apt/sources.list.d/pre-bin.list

apt update
```
# Warning!!!

Packages in this repository **IS** unstable or experimental. Use at your own risk.
