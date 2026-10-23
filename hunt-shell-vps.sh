#!/bin/bash
# hunt-shell-vps.sh - READ-ONLY webshell/backdoor scanner for aaPanel servers hosting many domains
# RUN:   bash hunt-shell-vps.sh 2>&1 | tee hunt-report.txt
# SAFE:  reads and reports only. Nothing is modified, deleted, or restarted.
export LC_ALL=C
ROOTS="/www/wwwroot /www/server/php /www/wwwlogs"
TMPD="/tmp /var/tmp /dev/shm"
SEP(){ echo; echo "=================================================="; echo "$1"; echo "=================================================="; }
SEP "[1] PHP webshell signatures (eval/base64/gzinflate + \$_POST|GET; well-known shell names)"
grep -rIlE --include='*.php' \
-e 'eval[[:space:]]*\([[:space:]]*(stripslashes|base64_decode|gzinflate|str_rot13|gzuncompress|\$_(POST|GET|REQUEST|COOKIE))' \
-e '\$_(POST|GET|REQUEST|COOKIE)[^;]{0,80}(eval|assert|system|shell_exec|passthru|popen|proc_open|create_function|preg_replace.*\/e)' \
-e '(FilesMan|WSO|c99shell|b374k|r57shell|PHPJacka|Ani-Shell|JspSpy|Weevely|png_image|by\s+con7ext|INDRAJITH)' \
$ROOTS 2>/dev/null | head -300
echo "-- end of section 1 (empty = nothing found) --"
SEP "[2] PHP files created/modified during the DANGER WINDOW Oct 16 -> Oct 23 (before the patch)"
find /www/wwwroot -type f \( -name '*.php' -o -name '*.phtml' -o -name '*.php5' -o -name '*.pht' \) \
-newermt '2026-10-16' ! -newermt '2026-10-23 15:00' 2>/dev/null | head -300
echo "-- end of section 2 (manually inspect the content of every file listed here) --"
SEP "[3] Disguised filenames & extensions (shell.jpg.php, .phtml, hidden files)"
find $ROOTS $TMPD -type f \( -name '*.jpg.php' -o -name '*.png.php' -o -name '*.gif.php' -o -name '*.ico.php' \
-o -name '*.phtml' -o -name '*.php5' -o -name '*.pht' -o -name '.*.php' -o -name '*.php.' \) 2>/dev/null | head -100
echo "-- end of section 3 --"
SEP "[4] SMALL PHP files (<3KB) containing eval/base64 (one-dollar webshells, China Chopper style)"
find /www/wwwroot -type f -name '*.php' -size -3k 2>/dev/null \
| while read -r f; do grep -lE '(eval|assert|base64_decode|gzinflate|str_rot13)[[:space:]]*\(' "$f" 2>/dev/null; done | head -150
echo "-- end of section 4 --"
SEP "[5] PERSISTENCE: cron + ssh keys + new systemd units"
echo "-- root crontab:"; crontab -l 2>/dev/null | grep -v '^#' | head -20
echo "-- other users' crontabs:"; for u in $(ls /home 2>/dev/null) www; do crontab -u "$u" -l 2>/dev/null | grep -v '^#' | head -10 && echo "  (user: $u)"; done
echo "-- /etc/cron.d, cron.daily modified since Oct 1:"; find /etc/cron.d /etc/cron.daily /etc/cron.hourly -type f -newermt '2026-10-01' 2>/dev/null | head -20
echo "-- authorized_keys (root + home):"; ls -la /root/.ssh/ /home/*/.ssh/ 2>/dev/null | head -20; awk '{print $1, $3, length($2)}' /root/.ssh/authorized_keys /home/*/.ssh/authorized_keys 2>/dev/null | head
echo "-- systemd units created since Oct 1:"; find /etc/systemd/system -type f -newermt '2026-10-01' 2>/dev/null | head -20
echo "-- rc.local:"; cat /etc/rc.local 2>/dev/null | grep -v '^#' | grep -v '^$' | head -10
SEP "[6] Abnormal PHP processes (not the regular php-fpm master/workers)"
ps aux | grep -E 'php' | grep -vE '(php-fpm: master|php-fpm: pool|grep)' | head -20
echo "-- end of section 6 --"
SEP "[7] LOGS: attack-tool user agents + POST to odd .php files since Oct 16"
grep -hE '(python-requests|curl\/|Go-http-client|libwww-perl|masscan|zgrab|nikto|sqlmap)' /www/wwwlogs/*.log 2>/dev/null | tail -50
echo "-- POST to odd .php (excluding well-known wp-admin/login paths):"
grep -hE 'POST [^ ]+\.php' /www/wwwlogs/*.log 2>/dev/null | grep -vE '(wp-login|xmlrpc|wp-admin|admin|login|upload|api|webhook|cart|checkout|contact|search)' | tail -60
echo "-- end of section 7 --"
SEP "[8] Executable files in /tmp /var/tmp /dev/shm"
find $TMPD -maxdepth 2 -type f -executable 2>/dev/null | head -30
echo "-- end of section 8 --"
SEP "DONE - review every section; any suspicious file from 1/2/4: inspect it with cat <file>, NEVER execute it."
