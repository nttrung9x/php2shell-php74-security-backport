#!/bin/bash
# hunt-shell-vps.sh - READ-ONLY webshell/backdoor scanner cho aaPanel VPS nhieu domain
# CHAY:  bash hunt-shell-vps.sh 2>&1 | tee hunt-report.txt
# AN TOAN: chi doc + bao cao. KHONG sua, KHONG xoa, KHONG khoi dong lai dich vu gi.
export LC_ALL=C
ROOTS="/www/wwwroot /www/server/php /www/wwwlogs"
TMPD="/tmp /var/tmp /dev/shm"
SEP(){ echo; echo "=================================================="; echo "$1"; echo "=================================================="; }

SEP "[1] PHP webshell signatures (eval/base64/gzinflate + \$_POST|GET; ten shell noi tieng)"
grep -rIlE --include='*.php' \
  -e 'eval[[:space:]]*\([[:space:]]*(stripslashes|base64_decode|gzinflate|str_rot13|gzuncompress|\$_(POST|GET|REQUEST|COOKIE))' \
  -e '\$_(POST|GET|REQUEST|COOKIE)[^;]{0,80}(eval|assert|system|shell_exec|passthru|popen|proc_open|create_function|preg_replace.*\/e)' \
  -e '(FilesMan|WSO|c99shell|b374k|r57shell|PHPJacka|Ani-Shell|JspSpy|Weevely|png_image|by\s+con7ext|INDRAJITH)' \
  $ROOTS 2>/dev/null | head -300
echo "-- ket thuc muc 1 (trong = khong tim thay) --"

SEP "[2] File .php moi tao/duoc sua trong WINDOW NGUY HIEM 16/10 -> 23/10 (truoc patch)"
find /www/wwwroot -type f \( -name '*.php' -o -name '*.phtml' -o -name '*.php5' -o -name '*.pht' \) \
  -newermt '2026-10-16' ! -newermt '2026-10-23 15:00' 2>/dev/null | head -300
echo "-- ket thuc muc 2 (cac file trong nay PHAI tu tay kiem tra noi dung) --"

SEP "[3] Ten file & extension bien kieu (shell.jpg.php, .phtml, an file)"
find $ROOTS $TMPD -type f \( -name '*.jpg.php' -o -name '*.png.php' -o -name '*.gif.php' -o -name '*.ico.php' \
  -o -name '*.phtml' -o -name '*.php5' -o -name '*.pht' -o -name '.*.php' -o -name '*.php.' \) 2>/dev/null | head -100
echo "-- ket thuc muc 3 --"

SEP "[4] File .php NHO (<3KB) chua ma doc/base64 (1-dollar webshell kieu China Chopper)"
find /www/wwwroot -type f -name '*.php' -size -3k 2>/dev/null \
  | while read -r f; do grep -lE '(eval|assert|base64_decode|gzinflate|str_rot13)[[:space:]]*\(' "$f" 2>/dev/null; done | head -150
echo "-- ket thuc muc 4 --"

SEP "[5] PERSISTENCE: cron + ssh keys + systemd moi"
echo "-- crontab root:"; crontab -l 2>/dev/null | grep -v '^#' | head -20
echo "-- cron users khac:"; for u in $(ls /home 2>/dev/null) www; do crontab -u "$u" -l 2>/dev/null | grep -v '^#' | head -10 && echo "  (user: $u)"; done
echo "-- /etc/cron.d, cron.daily moi sua tu 1/10:"; find /etc/cron.d /etc/cron.daily /etc/cron.hourly -type f -newermt '2026-10-01' 2>/dev/null | head -20
echo "-- authorized_keys (root + home):"; ls -la /root/.ssh/ /home/*/.ssh/ 2>/dev/null | head -20; awk '{print $1, $3, length($2)}' /root/.ssh/authorized_keys /home/*/.ssh/authorized_keys 2>/dev/null | head
echo "-- systemd unit moi tu 1/10:"; find /etc/systemd/system -type f -newermt '2026-10-01' 2>/dev/null | head -20
echo "-- rc.local:"; cat /etc/rc.local 2>/dev/null | grep -v '^#' | grep -v '^$' | head -10

SEP "[6] PROCESS php bat thuong (khong phai php-fpm master/worker chinh)"
ps aux | grep -E 'php' | grep -vE '(php-fpm: master|php-fpm: pool|grep)' | head -20
echo "-- ket thuc muc 6 --"

SEP "[7] LOG: UA cua tool tan cong + POST vao file .php la tu 16/10"
grep -hE '(python-requests|curl\/|Go-http-client|libwww-perl|masscan|zgrab|nikto|sqlmap)' /www/wwwlogs/*.log 2>/dev/null | tail -50
echo "-- POST .php la (khong phai wp-admin/login quen thuoc):"
grep -hE 'POST [^ ]+\.php' /www/wwwlogs/*.log 2>/dev/null | grep -vE '(wp-login|xmlrpc|wp-admin|admin|login|upload|api|webhook|cart|checkout|contact|search)' | tail -60
echo "-- ket thuc muc 7 --"

SEP "[8] File executable la trong /tmp /var/tmp /dev/shm"
find $TMPD -maxdepth 2 -type f -executable 2>/dev/null | head -30
echo "-- ket thuc muc 8 --"

SEP "DONE - review tung muc; file nao trong muc 1/2/4 nghi ngo thi: cat <file> xem, KHONG chay no."
