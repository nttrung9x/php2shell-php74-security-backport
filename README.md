<div align="center">

# 🛡️ php2shell-php74-security-backport

**PHP 7.4.33 security hot-patch for aaPanel** · community backport of the upstream
**php2shell** fix — CVE-2026-109618 / CVE-2026-109619 · Ubuntu 22.04 x86_64

![PHP](https://img.shields.io/badge/PHP-7.4.33-777BB4?logo=php&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04%2B-E95420?logo=ubuntu&logoColor=white)
![Panel](https://img.shields.io/badge/aaPanel-compatible-2088FF)
![CVE](https://img.shields.io/badge/CVE--2026--109618%2F109619-patched-brightgreen)

## ⚡ Quick install

```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/nttrung9x/php2shell-php74-security-backport/main/install.sh)"
```

After the upgrade, `/www/server/php/74/bin/php -v` prints `Patched by Trung Nguyen` — see [Verify](#-verify-after-upgrade).

SHA256-gated download · automatic backup & restore · interactive menu · zero config

**Maintainer:** [Trung Nguyen](https://github.com/nttrung9x) · [mmo69.com](https://mmo69.com)

</div>

---

> [!WARNING]
> **PHP 7.4 is EOL.** This is a **community backport**, NOT official long-term support from php.net.
> The patch fixes the vulnerability but does **NOT remove webshells already planted** on your
> server — run the [read-only webshell scanner](#-hunt-for-planted-webshells). Plan your migration to PHP 8.x.

## 🔍 What this fixes

| Item | Detail |
|---|---|
| Bug class | php2shell — exploitable state corruption in PHP 7.4.33 |
| CVEs | CVE-2026-109618 · CVE-2026-109619 |
| Patch | Avoid state corruption via bailout — commit 712e60f9 |
| Target | aaPanel PHP 7.4 (EOL) on Ubuntu 22.04 x86_64 |

## 🧱 Build sources

| Component | Source |
|---|---|
| PHP base | [php-7.4.33.tar.gz](https://www.php.net/distributions/php-7.4.33.tar.gz) |
| Security patch | [712e60f9.patch](https://github.com/php/php-src/commit/712e60f9edfd03f0960fc4fc3c2c375f42b90aa2.patch) |
| Upstream branch | [PHP-7.4-CVE-2026-109618-109619](https://github.com/php/php-src/tree/PHP-7.4-CVE-2026-109618-109619) |

## ✅ Requirements

- Ubuntu 22.04 x86_64 (24.04 usually works — the installer runs an ldd check; glibc >= 2.35)
- aaPanel with PHP 7.4 installed at `/www/server/php/74`
- root access · ~100 MB free disk · curl

## 🚀 Installation

**Option 1 — one line:**

```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/nttrung9x/php2shell-php74-security-backport/main/install.sh)"
```

The installer downloads the overlay tarball (21 MB), the upgrade script and the webshell
scanner into `/Emyeusss7`, verifies SHA256 (aborts on mismatch), then opens the menu.

<details>
<summary><b>Option 2 — manual install</b></summary>
<br>

```bash
mkdir -p /Emyeusss7 && cd /Emyeusss7
curl -fSL -O https://raw.githubusercontent.com/nttrung9x/php2shell-php74-security-backport/main/php74-patched-overlay-ubuntu2204-x86_64.tar.gz
curl -fSL -O https://raw.githubusercontent.com/nttrung9x/php2shell-php74-security-backport/main/upgrade-fix-php2shell.sh
sha256sum php74-patched-overlay-ubuntu2204-x86_64.tar.gz
sudo bash upgrade-fix-php2shell.sh
```

Expected tarball SHA256: `8c0595b7127a29ad968842ead6384584a67f6c9b890738487badcd7efa00dd27`

</details>

## 📋 Menu

| Option | Action |
|---|---|
| 1 | Backup the aaPanel PHP 7.4 directory |
| 2 | Restore the aaPanel PHP 7.4 directory |
| 3 | Upgrade PHP 7.4 with the patched overlay — asks y/N before its backup |
| 4 | Hunt for planted webshells — read-only scan, auto-downloads the scanner and saves a timestamped report to `/Emyeusss7/hunt-report-<timestamp>.txt` |

## 🔎 Verify after upgrade

```bash
/www/server/php/74/bin/php -v
```

```text
PHP 7.4.33 (cli) (built: ...)
Patched by Trung Nguyen - github.com/nttrung9x - mmo69.com
```

Something goes wrong? Run the script again and choose option 2 — it restores the
latest backup from `/Emyeusss7/backup`.

## 🧹 Hunt for planted webshells

> [!IMPORTANT]
> The patch closes the door — it does **not** evict anyone already inside. If this server ran
> unpatched PHP 7.4 during the disclosure window (exploitation observed worldwide from
> **2026-10-17**, public disclosure **2026-10-21**), scan it for webshells and backdoors.

**`hunt-shell-vps.sh` is 100% read-only** — it only reads and reports: no edits, no deletions,
no service restarts. Designed for aaPanel multi-domain servers.

```bash
curl -fsSL -O https://raw.githubusercontent.com/nttrung9x/php2shell-php74-security-backport/main/hunt-shell-vps.sh
sudo bash hunt-shell-vps.sh 2>&1 | tee hunt-report.txt
```

Already ran the installer? Menu option **4** of `upgrade-fix-php2shell.sh` runs the same scan — the scanner is already in `/Emyeusss7` (menu 4 auto-downloads it with SHA256 verification if missing) and the report is saved automatically.

It scans 8 areas and prints everything to stdout (saved to `hunt-report.txt` by the `tee` above):

| # | Area |
|---|---|
| 1 | Webshell signatures — `eval(base64_decode(...))`, `gzinflate`, `$_POST`-driven `eval`/`system`, WSO / c99 / b374k / FilesMan / Weevely … |
| 2 | `.php` / `.phtml` files created or modified in the exposure window |
| 3 | Disguised filenames — `shell.jpg.php`, `.phtml`, `.php5`, hidden dotfiles |
| 4 | Small (`< 3 KB`) `.php` files with obfuscated code (China Chopper style) |
| 5 | Persistence — cron jobs, `authorized_keys`, new systemd units, `rc.local` |
| 6 | Abnormal PHP processes (not regular php-fpm master/pool workers) |
| 7 | Logs — attack-tool user agents, `POST` requests to unexpected `.php` endpoints |
| 8 | Executables parked in `/tmp`, `/var/tmp`, `/dev/shm` |

**Reading the report**

- Empty section = nothing found in that area.
- Section 2 hard-codes the window **2026-10-16 → 2026-10-23** (in-the-wild exploitation → first patched builds). Edit the two dates in the script if your exposure window differs.
- Anything flagged in sections 1 / 2 / 4: inspect with `cat <file>` — **never execute it**.
- Confirmed compromise? Rotate every credential (aaPanel, MySQL, SSH keys), remove the payload, diff sites against clean backups, and audit other sites sharing the server.

## 📦 Files & SHA256

| File | SHA256 |
|---|---|
| `php74-patched-overlay-ubuntu2204-x86_64.tar.gz` | `8c0595b7127a29ad968842ead6384584a67f6c9b890738487badcd7efa00dd27` |
| `upgrade-fix-php2shell.sh` | `a74b949f1a6e4ab9871fccf6cefae3239cab34eaf69a08885770ff2760e7cd4d` |
| `hunt-shell-vps.sh` | `e54c6b77110ddd85de1c43c97ef25087b6fac0414c779fef2049bf2526affd66` |

## 👤 Author

**Trung Nguyen**

- GitHub: https://github.com/nttrung9x
- Website: https://mmo69.com
- Phone/Zalo: 0372.972.971
- Telegram/Facebook: @hkvn9x

## 💸 Donate

<div align="center">

### ☕ If this backport saved your server, buy the author a coffee

| 💰 USDT TRC20 | 💰 USDT BEP20 / BSC |
|:---:|:---:|
| `THb3t5rymDNaJ5fjGGG4W93RrBnVsHywLi` | `0xc4275381a70a7dd825e154a62e257e61cc3838c8` |

*Every donation keeps EOL PHP boxes patched a little longer 🙏*

</div>

## ⚖️ Disclaimer

Provided as-is, no warranty. Community backport of an upstream fix to an EOL PHP
version; not affiliated with php.net or aaPanel. The patch does not remove
already-planted webshells. Test on a non-production copy when possible.

---

<div align="center">
Made with 🛡️ and ☕ by <b>Trung Nguyen</b> — <a href="https://github.com/nttrung9x">github.com/nttrung9x</a>
</div>
