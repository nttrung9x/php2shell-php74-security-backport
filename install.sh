#!/bin/bash
# ============================================================
# install.sh - one-line installer for the php2shell fix
# Repo  : https://github.com/nttrung9x/php2shell-php74-security-backport
# Target: aaPanel PHP 7.4 on Ubuntu 22.04 x86_64
# Author: Trung Nguyen - github.com/nttrung9x - mmo69.com
#          Zalo 0372.972.971 - Telegram/Facebook @hkvn9x
# Downloads the patched overlay, upgrade script & webshell scanner into /Emyeusss7,
# verifies SHA256, then runs the interactive menu.
# ============================================================
set -e

REPO=https://raw.githubusercontent.com/nttrung9x/php2shell-php74-security-backport/main
WORKDIR=/Emyeusss7
TARBALL=php74-patched-overlay-ubuntu2204-x86_64.tar.gz
SCRIPT=upgrade-fix-php2shell.sh
HUNT=hunt-shell-vps.sh
HUNTSHA=e54c6b77110ddd85de1c43c97ef25087b6fac0414c779fef2049bf2526affd66
SHA=8c0595b7127a29ad968842ead6384584a67f6c9b890738487badcd7efa00dd27

[ "$(id -u)" = "0" ] || { echo "[ERROR] Run as root: sudo bash install.sh"; exit 1; }
command -v curl >/dev/null 2>&1 || apt-get install -y -q curl

echo "===================================================="
echo " php2shell PHP 7.4 backport installer (aaPanel)"
echo " by Trung Nguyen - github.com/nttrung9x"
echo "===================================================="
mkdir -p "$WORKDIR"
cd "$WORKDIR"

echo "[1/4] Downloading $TARBALL (21 MB) ..."
curl -fSL --retry 3 -o "$TARBALL" "$REPO/$TARBALL"

echo "[2/4] Verifying SHA256 ..."
echo "$SHA  $TARBALL" | sha256sum -c -

echo "[3/4] Downloading $SCRIPT ..."
curl -fSL --retry 3 -o "$SCRIPT" "$REPO/$SCRIPT"
echo "[4/4] Downloading $HUNT ..."
curl -fSL --retry 3 -o "$HUNT" "$REPO/$HUNT"
echo "$HUNTSHA  $HUNT" | sha256sum -c -

echo
echo "All files are in $WORKDIR - starting the menu."
exec bash "$SCRIPT" "$WORKDIR/$TARBALL"
