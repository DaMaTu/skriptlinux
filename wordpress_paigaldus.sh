#!/bin/bash
# ---------------------------------------------
# WordPress automaatne paigaldus- ja seadistusskript
# Autor: [Sinu nimi]
# Kuupäev: [Täna]
# ---------------------------------------------

# --- Määrangud ---
DB_NAME="wordpress"
DB_USER="wpuser"
DB_PASS="qwerty"
DB_HOST="localhost"
WP_URL="https://wordpress.org/latest.tar.gz"
WWW_DIR="/var/www/html"
WP_DIR="$WWW_DIR/wordpress"

echo "---- WordPressi automaatne paigaldus algab ----"

# --- Kontrolli vajalikud teenused ---
check_service() {
    local service=$1
    if ! dpkg -s "$service" &>/dev/null; then
        echo "$service ei ole paigaldatud. Paigaldan..."
        sudo apt update -y
        sudo apt install -y "$service"
    else
        echo "$service on juba olemas."
    fi
}

check_service apache2
check_service php
check_service php-mysql
check_service mysql-server
check_service wget
check_service tar

# --- Käivita teenused ---
sudo systemctl enable apache2 mysql
sudo systemctl start apache2 mysql

# --- Loo andmebaas ja kasutaja ---
echo "Loon WordPressi andmebaasi ja kasutaja..."
sudo mysql -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME};"
sudo mysql -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
sudo mysql -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

# --- Laadi alla ja paki lahti WordPress ---
cd /tmp || exit
echo "Laadin alla WordPressi..."
wget -q $WP_URL -O latest.tar.gz
tar xzf latest.tar.gz

# --- Liiguta WordPress veebiserveri kausta ---
sudo rm -rf $WP_DIR
sudo mv wordpress $WWW_DIR
sudo chown -R www-data:www-data $WP_DIR
sudo chmod -R 755 $WP_DIR

# --- Seadista wp-config.php ---
cd $WP_DIR || exit
sudo cp wp-config-sample.php wp-config.php

sudo sed -i "s/database_name_here/${DB_NAME}/" wp-config.php
sudo sed -i "s/username_here/${DB_USER}/" wp-config.php
sudo sed -i "s/password_here/${DB_PASS}/" wp-config.php
sudo sed -i "s/localhost/${DB_HOST}/" wp-config.php

# --- Teenused uuesti käima ---
sudo systemctl restart apache2

echo "-----------------------------------------------"
echo "WordPressi paigaldus on lõpule viidud!"
echo "Ava brauser ja mine aadressile: http://localhost/wordpress"
echo "-----------------------------------------------"
