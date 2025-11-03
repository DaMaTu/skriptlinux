#!/bin/bash
# Lihtne MySQL paigaldamise skript Debian 12-le (MySQL 8.4 jaoks)
set -e

MYSQL_PW="${MYSQL_PW:-qwerty}"

echo ">>> Uuendan süsteemi ja paigaldan vajalikud tööriistad..."
apt update -y
apt install -y wget gnupg lsb-release ca-certificates

echo ">>> Laen alla ja paigaldan MySQL APT konfiguratsiooni..."
wget -q https://dev.mysql.com/get/mysql-apt-config_0.8.36-1_all.deb -O /tmp/mysql-apt.deb
DEBIAN_FRONTEND=noninteractive dpkg -i /tmp/mysql-apt.deb || apt -f install -y
apt update -y

echo ">>> Paigaldan MySQL serveri..."
DEBIAN_FRONTEND=noninteractive apt install -y mysql-server

echo ">>> Käivitan ja luban MySQL teenuse..."
systemctl enable --now mysql

echo ">>> Seadistan root parooli (kasutades caching_sha2_password)..."
mysql -u root <<SQL
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_PW}';
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
FLUSH PRIVILEGES;
SQL

echo ">>> Loon /root/.my.cnf faili..."
cat > /root/.my.cnf <<EOF
[client]
user=root
password=${MYSQL_PW}
EOF
chmod 600 /root/.my.cnf

echo ">>> Valmis!"
echo "Logi sisse käsuga: mysql"
