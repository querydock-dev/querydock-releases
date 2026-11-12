# QueryDock

A fast, native database GUI client for PostgreSQL, MySQL, SQLite, and MongoDB.

This repository hosts the public installer and release downloads. The source code lives in a separate, private repository.

## Install on macOS

**Homebrew**

```bash
brew install --cask novus-lab-dev/tap/querydock
```

**One-line installer**

```bash
curl -fsSL https://raw.githubusercontent.com/Novus-Lab-Dev/querydock-releases/main/install.sh | bash
```

## Windows and Linux

Download the `.msi` / `-setup.exe` (Windows) or `.AppImage` / `.deb` / `.rpm` (Linux) from the [latest release](https://github.com/Novus-Lab-Dev/querydock-releases/releases/latest).

## macOS "could not verify" warning

QueryDock builds aren't notarized by Apple yet. If macOS blocks the app on first launch, run:

```bash
xattr -cr /Applications/QueryDock.app
```

or open **System Settings → Privacy & Security** and click **Open Anyway**.

## Verifying downloads

Each release includes a `SHA256SUMS.txt`:

```bash
shasum -a 256 -c SHA256SUMS.txt --ignore-missing
```
