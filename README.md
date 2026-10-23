# php2shell-php74-security-backport

Hot-patch (community backport) for the **php2shell** bug class in **PHP 7.4.33**,
packaged for **aaPanel** on **Ubuntu 22.04 x86_64**.

> [!WARNING]
> PHP 7.4 is EOL. This is a **community backport**, NOT official long-term
> support from php.net. The patch fixes the vulnerability but does **NOT**
> remove webshells already planted on your server - hunt them separately.
> Plan your migration to PHP 8.x.

## What this fixes

- CVE-2026-109618 / CVE-2026-109619 (php2shell bug class)
- Patch: Avoid state corruption via bailout
- Upstream commit: 712e60f9edfd03f0960fc4fc3c2c375f42b90aa2

## Build sources

| Component | Source |
|---|---|
| PHP base | https://www.php.net/distributions/php-7.4.33.tar.gz |
| Security patch | https://github.com/php/php-src/commit/712e60f9edfd03f0960fc4fc3c2c375f42b90aa2.patch |
| Upstream branch | https://github.com/php/php-src/tree/PHP-7.4-CVE-2026-109618-109619 |

## Requirements

- VPS: Ubuntu 22.04 x86_64 (24.04 usually works too - the installer runs an ldd check; glibc >=> 2.35)
- Panel: aaPanel with PHP 7.4 installed at /www/server/php/74
- root access, $100 MB free disk

## Install (one line)

    sudo bash <(curl -sSL https://raw.githubusercontent.com/nttrung9x/php2shell-php74-security-backport/main/install.sh)

The installer downloads the overlay tarball and the upgrade script into /Emyeusss7,
verifies the tarball SHA256 (aborts on mismatch), then starts the interactive menu.

## Manual install

    mkdir -p /Emyeusss7 && cd /Emyeusss7
    curl -fSL -O https://raw.githubusercontent.com/nttrung9x/php2shell-php74-security-backport/main/php74-patched-overlay-ubuntu2204-x86_64.tar.gz
    curl -fSL -O https://raw.githubusercontent.com/nttrung9x/php2shell-php74-security-backport/main/upgrade-fix-php2shell.sh
    sha256sum php74-patched-overlay-ubuntu2204-x86_64.tar.gz
    sudo bash upgrade-fix-php2shell.sh

Expected tarball SHA256: 8c0595b7127a29ad968842ead6384584a67f6c9b890738487badcd7efa00dd27

## Menu

    1. Backup the aaPanel PHP 7.4 directory
    2. Restore the aaPanel PHP 7.4 directory
    3. Upgrade PHP 7.4 using the patched overlay  (asks y/N before its backup)

After the upgrade, php -v shows the patched build:

    PHP 7.4.33 (cli) (built: ...) ( NTS )
    Patched by Trung Nguyen - github.com/nttrung9x - mmo69.com

If anything goes wrong, run the script again and choose 2 to restore the
latest backup in /Emyeusss7/backup.

## Files and SHA256

| File | SHA256 |
|---|---|
| php74-patched-overlay-ubuntu2204-x86_64.tar.gz | 8c0595b7127a29ad968842ead6384584a67f6c9b890738487badcd7efa00dd27 |
| upgrade-fix-php2shell.sh | b8892dd18b7310c4ea5e25ebb1b15edfca1d6cd1ae4acbf90ce6ed68c3cce8e4 |

## Author

Trung Nguyen

- GitHub: https://github.com/nttrung9x
- Web: https://mmo69.com
- Phone/Zalo: 0372.972.971
- Telegram/Facebook: @hkvn9x

## Donate

- USDT TRC20: THb3t5rymDNaJ5fjGGG4W93RrBnVsHywLi
- USDT BEP20/BSC: 0xc4275381a70a7dd825e154a62e257e61cc3838c8

## Disclaimer

Provided as-is, no warranty. Community backport of an upstream fix to an EOL
PHP version; not affiliated with php.net or aaPanel. The patch does not remove
already-planted webshells. Test on a non-production copy when possible.
