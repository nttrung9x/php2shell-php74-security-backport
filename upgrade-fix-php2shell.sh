#!/bin/bash
# ============================================================
# upgrade-fix-php2shell.sh v2 (overlay edition)
# aaPanel PHP hot-patch for the php2shell bug class.
# Applies the PHP 7.4.33 community backport of upstream
# commit 712e60f9edfd03f0960fc4fc3c2c375f42b90aa2 (2026-10-23)
# Patch: Avoid state corruption via bailout
# CVE-2026-109618 / CVE-2026-109619
#
# Author: Trung Nguyen
#   GitHub : https://github.com/nttrung9x/
#   Web    : https://mmo69.com/
#   Phone/Zalo : 0372.972.971
#   Telegram/Facebook : @hkvn9x
#
# v2 overlay model: the tarball binaries are built with the
# same --prefix aaPanel uses, so this script simply copies
# them OVER /www/server/php/NN. No /opt engine, no symlinks.
# The tree stays a plain aaPanel install, so future aaPanel
# PHP updates or reinstalls behave exactly like before.
# Only 3 php.ini extension lines get commented (zip and
# fileinfo are built into the patched binary; aaPanel
# security_notice.so is excluded on purpose).
#
# Menus: 1 backup, 2 restore, 3 upgrade (asks y/n before its backup).
# Hardwired to aaPanel PHP 7.4 (/www/server/php/74) - no version selection.
# Usage: sudo bash upgrade-fix-php2shell.sh [tarball]
# Tarball home and backups: /Emyeusss7
# Ubuntu 22.04/24.04 x86_64, glibc >= 2.35.
#
# NOTE: community backport for an EOL PHP version, NOT
# official support. The patch does NOT remove webshells that
# are already planted - hunt them separately. Plan migration
# to PHP 8.x.
# ============================================================
PANEL_ROOT=/www/server/php
WORKDIR=/Emyeusss7
# This overlay build is for aaPanel PHP 7.4 ONLY - all paths below are fixed to 74.
VER=74
PHPDIR="$PANEL_ROOT/$VER"
INIT=/etc/init.d/php-fpm-$VER
BACKUP_DIR="$WORKDIR/backup"
KNOWN_TARBALL_NAME=php74-patched-overlay-ubuntu2204-x86_64.tar.gz
SHA74=8c0595b7127a29ad968842ead6384584a67f6c9b890738487badcd7efa00dd27
CREDIT_MARK="Patched by Trung Nguyen"
APT_LIBS="libpq5 libldap-2.5-0 libgssapi-krb5-2 libkrb5-3 libk5crypto3 libkrb5support0 libcom-err2 libnghttp2-14 libidn2-0 librtmp1 libssh-4 libpsl5 libbrotli1 libzstd1 liblzma5 libicu70 libonig5 libsodium23 libpng16-16 libwebp7 libjpeg-turbo8 libfreetype6 libsqlite3-0 libxml2 libcurl4 libssl3 libbz2-1.0 zlib1g libstdc++6 libgcc-s1"
die() { echo "[ERROR] $*"; exit 1; }
info() { echo "[OK] $*"; }
warn() { echo "[WARN] $*"; }
banner() {
    echo "====================================================="
    echo "  PHP FIX PHP2SHELL (aaPanel) - overlay edition"
    echo "  by Trung Nguyen - github.com/nttrung9x"
    echo "  mmo69.com - Zalo 0372.972.971 - @hkvn9x"
    echo "====================================================="
}
check_root() {
    [ "$(id -u)" = "0" ] || die "Run as root: sudo bash $0"
}
find_tarball() {
    local d f
    for d in "$(dirname $0)" "$WORKDIR" /root /tmp; do
        f=$(ls -1t "$d"/php*-patched-*.tar.gz 2>/dev/null | head -n 1)
        [ -n "$f" ] && { echo "$f"; return 0; }
    done
    return 1
}
# (version auto-detection removed - this script is hardwired to aaPanel PHP 7.4)
master_pid() {
    pgrep -f "php-fpm: master process.*$PHPDIR" | head -n 1
}
fpm_ctl() {
    if [ -x "$INIT" ]; then "$INIT" "$1"; else systemctl "$1" php-fpm-$VER; fi
}
fpm_stop_hard() {
    fpm_ctl stop >/dev/null 2>&1
    local i pid
    pid=$(master_pid)
    for i in 1 2 3 4 5; do
        [ -z "$pid" ] && break
        sleep 1
        pid=$(master_pid)
    done
    if [ -n "$pid" ]; then
        warn "graceful stop failed - force killing"
        pkill -9 -f "php-fpm[:] master process.*$PHPDIR" 2>/dev/null
        pkill -9 -f "php-fpm[:] pool" 2>/dev/null
        sleep 1
    fi
    rm -f $PHPDIR/var/run/php-fpm.pid
}
backup_one() {
    local stamp out
    stamp=$(date +%Y%m%d-%H%M%S)
    out="$BACKUP_DIR/php$VER-full-$stamp.tar.gz"
    echo "Backing up $PHPDIR to $out ..."
    tar -czpf "$out" -C "$PANEL_ROOT" $VER || die "Backup failed"
    sha256sum "$out" > "$out.sha256"
    info "Backup done: $out"
}
ini_fix() {
    local ini
    for ini in "$PHPDIR/etc/php.ini" "$PHPDIR/etc/php-cli.ini"; do
        [ -f "$ini" ] || continue
        if [ ! -f "$ini.p2s.bak" ]; then cp -p "$ini" "$ini.p2s.bak"; fi
        sed -i -e "s|^extension = zip.so|;p2s zip built into patched php|" -e "s|^extension = security_notice.so|;p2s security_notice excluded on purpose|" -e "s|^extension = .*/fileinfo.so|;p2s fileinfo built into patched php|" "$ini"
    done
}
do_backup() {
    check_root
    [ -d "$PHPDIR" ] || die "aaPanel PHP 7.4 not found at $PHPDIR"
    mkdir -p "$BACKUP_DIR"
    backup_one
}
do_restore() {
    check_root
    [ -d "$PHPDIR" ] || die "aaPanel PHP 7.4 not found at $PHPDIR"
    mkdir -p "$BACKUP_DIR"
    local latest sure pid
    latest=$(ls -1t "$BACKUP_DIR"/php$VER-full-*.tar.gz 2>/dev/null | head -n 1)
    [ -n "$latest" ] || die "No backup for php$VER in $BACKUP_DIR"
    echo "Restore from: $latest"
    echo "Current $PHPDIR will be DELETED and replaced by this backup."
    read -r -p "Type y to continue (anything else cancels): " sure
    [ "$sure" = "y" ] || { echo "Restore cancelled."; return 0; }
    fpm_stop_hard
    rm -rf "$PHPDIR"
    tar -xzpf "$latest" -C "$PANEL_ROOT" || die "Restore failed - reinstall this PHP from aaPanel if needed"
    rm -f $PHPDIR/var/run/php-fpm.pid
    fpm_ctl start
    sleep 3
    pid=$(master_pid)
    if [ -n "$pid" ]; then
        echo "Master PID $pid -> $(readlink /proc/$pid/exe)"
    else
        warn "php-fpm did not start - check $PHPDIR/var/log/php-fpm.log"
    fi
    "$PHPDIR/bin/php" -v | head -n 1 || true
    info "Restore done"
}
do_upgrade() {
    check_root
    echo =========================================================
    echo " PHP hot-patch installer - commit 712e60f9edfd03f0960fc4fc3c2c375f42b90aa2"
    echo =========================================================
    [ "$(uname -m)" = "x86_64" ] || die "CPU is not x86_64"
    [ -d "$PANEL_ROOT" ] || die "aaPanel PHP root not found: $PANEL_ROOT"
    grep -q "22.04" /etc/os-release 2>/dev/null || warn "Not Ubuntu 22.04 - the ldd check will decide if libraries fit"
    TARBALL="$TARBALL_ARG"
    if [ -z "$TARBALL" ]; then TARBALL=$(find_tarball); fi
    [ -n "$TARBALL" ] || die "No phpNN-patched-*.tar.gz found in /Emyeusss7, next to this script, in /root or /tmp. Or pass the path as argument."
    [ -f "$TARBALL" ] || die "Tarball not readable: $TARBALL"
    BN=$(basename "$TARBALL")
    if [ "$BN" = "$KNOWN_TARBALL_NAME" ]; then
        echo "Step 1/8: Verifying SHA256 of $BN ..."
        ( cd "$(dirname $TARBALL)" && echo "$SHA74  $BN" | sha256sum -c - ) || die "SHA256 mismatch - download the tarball again"
    else
        warn "Unknown tarball name $BN - automatic hash check skipped"
    fi
    echo "Step 2/8: Checking tarball layout and target ..."
    tar -tzf "$TARBALL" | grep -qx "bin/php" || die "tarball does not carry bin/php (not an overlay tarball?)"
    case "$BN" in php74-*) : ;; *) die "This overlay tarball is for PHP 7.4 only: $BN" ;; esac
    PHPDIR="$PANEL_ROOT/$VER"
    [ -d "$PHPDIR" ] || die "aaPanel dir not found: $PHPDIR"
    [ -f "$PHPDIR/bin/php" ] || die "$PHPDIR/bin/php missing"
    INIT=/etc/init.d/php-fpm-$VER
    BACKUP_DIR="$WORKDIR/backup"
    mkdir -p "$BACKUP_DIR"
    echo "Target: $PHPDIR (service: $INIT)"
    echo "Step 3/8: Extracting to a staging dir and checking ABI ..."
    TMPD=$(mktemp -d /root/p2s.XXXXXX) || die "mktemp failed"
    tar -xzf "$TARBALL" -C "$TMPD" || { rm -rf "$TMPD"; die "extract failed"; }
    [ -x "$TMPD/bin/php" ] || { rm -rf "$TMPD"; die "no bin/php in tarball"; }
    "$TMPD/bin/php" -n -v >/dev/null 2>&1 || { rm -rf "$TMPD"; die "staged php binary does not run"; }
    ABI_NEW=$($TMPD/bin/php -n -i 2>/dev/null | grep "^extension_dir" | head -n 1 | sed "s|.*extensions/||")
    ABI_OLD=$($PHPDIR/bin/php -n -i 2>/dev/null | grep "^extension_dir" | head -n 1 | sed "s|.*extensions/||")
    echo "installed ABI: $ABI_OLD / tarball ABI: $ABI_NEW"
    [ "$ABI_NEW" = "$ABI_OLD" ] || { rm -rf "$TMPD"; die "ABI mismatch - wrong tarball for this PHP build"; }
    echo "Step 4/8: Installing runtime libraries (apt) ..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get install -y -q $APT_LIBS >/dev/null 2>&1 || warn "apt-get had an issue - the ldd check will decide"
    if ldd "$TMPD/bin/php" 2>/dev/null | grep -q "not found"; then ldd "$TMPD/bin/php" | grep "not found"; rm -rf "$TMPD"; die "missing libraries (Ubuntu 20.04? that needs a separate build)"; fi
    if ldd "$TMPD/sbin/php-fpm" 2>/dev/null | grep -q "not found"; then ldd "$TMPD/sbin/php-fpm" | grep "not found"; rm -rf "$TMPD"; die "missing libraries for php-fpm"; fi
    echo "Step 5/8: Snapshot before upgrade ..."
    V_BEFORE="$($PHPDIR/bin/php -v | head -n 1)"
    $PHPDIR/bin/php -m > /root/p2s-mod-before.txt 2>/dev/null
    read -r -p "Backup current PHP 7.4 tree before upgrading? [y/N]: " sure
    if [ "$sure" = "y" ] || [ "$sure" = "Y" ]; then
        backup_one
    else
        warn "No backup taken - if this upgrade fails, reinstall PHP 7.4 from aaPanel"
    fi
    echo "Step 6/8: Stopping PHP-FPM, copying files over $PHPDIR ..."
    fpm_stop_hard
    cp -a "$TMPD/bin" "$TMPD/sbin" "$TMPD/lib" "$TMPD/include" "$PHPDIR/" || { rm -rf "$TMPD"; die "copy failed - if the tree is half-copied run menu 2 to restore"; }
    ini_fix
    echo "Step 7/8: Starting PHP-FPM ..."
    fpm_ctl start
    pid=""
    tries=0
    while [ -z "$pid" ] && [ "$tries" -lt 10 ]; do
        pid=$(master_pid)
        tries=$((tries+1))
        if [ -z "$pid" ]; then sleep 1; fi
    done
    [ -n "$pid" ] || { rm -rf "$TMPD"; die "php-fpm did not start - run menu 2 to restore. Log: tail -n 30 $PHPDIR/var/log/php-fpm.log"; }
    exe=$(readlink /proc/$pid/exe)
    echo "Master PID $pid -> $exe"
    [ "$exe" = "$PHPDIR/sbin/php-fpm" ] || warn "unexpected master binary: $exe"
    echo "Step 8/8: Verifying ..."
    V_AFTER="$($PHPDIR/bin/php -v | head -n 1)"
    echo "before: $V_BEFORE"
    echo "after : $V_AFTER"
    [ "$V_AFTER" != "$V_BEFORE" ] || { rm -rf "$TMPD"; die "php -v did not change - upgrade failed"; }
    $PHPDIR/bin/php -v | grep -q "$CREDIT_MARK" || warn "credit line missing in php -v"
    $PHPDIR/bin/php -m > /root/p2s-mod-after.txt 2>/dev/null
    if ! diff -q /root/p2s-mod-before.txt /root/p2s-mod-after.txt >/dev/null; then
        echo "Module diff (expected: security_notice gone; zip/fileinfo built in):"
        diff /root/p2s-mod-before.txt /root/p2s-mod-after.txt | head -n 12
    fi
    rm -rf "$TMPD"
    echo "====================================================="
    info "UPGRADE DONE - $PHPDIR now runs the patched build"
    echo "Test at least one real site before leaving this shell."
    echo "If anything is wrong: run again and choose 2 (restore)."
    echo "- aaPanel security_notice.so is not loaded by this engine."
    echo "- The patch does not remove already-planted webshells."
    echo "- Community backport for EOL PHP - plan migration to 8.x."
    echo "====================================================="
}
TARBALL_ARG="${1:-}"
while :; do
    banner
    echo "Tarball is auto-detected in /Emyeusss7, next to this script"
    echo "or /tmp - or pass it: sudo bash $0 [tarball]"
    echo "-----------------------------------------------------"
    echo "1. Backup the aaPanel PHP 7.4 directory"
    echo "2. Restore the aaPanel PHP 7.4 directory"
    echo "3. Upgrade PHP 7.4 using the patched overlay"
    echo "0. Exit"
    echo "====================================================="
    read -r -p "Choose: " c || break
    case "$c" in
        1) do_backup ;;
        2) do_restore ;;
        3) do_upgrade ;;
        0) break ;;
        *) echo "Invalid choice: $c" ;;
    esac
done
echo "Bye - Trung Nguyen / github.com/nttrung9x / mmo69.com"
