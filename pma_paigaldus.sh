#!/bin/bash
# phpMyAdmini paigaldamise skript
# Autor: [sinu nimi]
# Kuupäev: $(date +"%Y-%m-%d")

echo "------------------------------------------"
echo "   phpMyAdmini paigaldus algab..."
echo "------------------------------------------"

# Süsteemi uuendamine
sudo apt update -y
sudo apt upgrade -y

# Vajalikud paketid: MariaDB server ja klient
echo "Paigaldan MariaDB serveri ja kliendi..."
sudo apt install -y mariadb-server mariadb-client

# Apache2 ja PHP paigaldamine, kui veel puuduvad
echo "Kontrollin Apache2 ja PHP olemasolu..."
sudo apt install -y apache2 php php-mbstring php-zip php-gd php-json php-curl

# phpMyAdmini paigaldamine
echo "Paigaldan phpMyAdmini..."
sudo apt install -y phpmyadmin

# phpMyAdmini sidumine Apache'iga
echo "Lubame phpMyAdmini Apache konfis..."
sudo ln -s /etc/phpmyadmin/apache.conf /etc/apache2/conf-available/phpmyadmin.conf
sudo a2enconf phpmyadmin.conf

# Teenuste taaskäivitamine
echo "Taaskäivitan Apache2 ja MariaDB teenused..."
sudo systemctl restart apache2
sudo systemctl restart mariadb

# Lõpetuseks teade
echo "------------------------------------------"
echo "phpMyAdmini paigaldus lõpetatud!"
echo "Mine aadressile: http://localhost/phpmyadmin"
echo "------------------------------------------"
