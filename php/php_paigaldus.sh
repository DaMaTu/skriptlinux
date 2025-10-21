#!/bin/bash
# ------------------------------------------------------------
# php_paigaldus.sh
# Autor: [Matthias Järvet]
# Eesmärk: PHP uuema versiooni (8.x) paigaldamine koos Apache'iga Debian süsteemis
# ------------------------------------------------------------

LOGFILE="php_paigaldus.log"
exec > >(tee -a "$LOGFILE") 2>&1

echo "=== PHP paigaldamise alustamine ==="
date

# Uuendame paketilistid ja vajalikud tööriistad
sudo apt update -y
sudo apt install -y lsb-release ca-certificates apt-transport-https software-properties-common wget

# Lisame Sury PHP hoidla, kui seda veel pole
if ! grep -q "packages.sury.org/php" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
  echo "Lisatakse Sury PHP hoidla..."
  wget -qO - https://packages.sury.org/php/apt.gpg | sudo apt-key add -
  echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/php.list
else
  echo "Sury PHP hoidla on juba olemas."
fi

# Uuendame hoidlaid
sudo apt update -y

# Kontrollime, kas Apache on paigaldatud
if ! dpkg -s apache2 &>/dev/null; then
  echo "Apache2 ei ole paigaldatud. Paigaldan..."
  sudo apt install -y apache2
else
  echo "Apache2 on juba paigaldatud."
fi

# Paigaldame PHP ja vajalikud moodulid
echo "Paigaldan PHP 8.x ja vajalikud moodulid..."
sudo apt install -y php libapache2-mod-php php-mysql php-cli php-curl php-xml php-mbstring php-zip php-gd

# Kontrollime, kas paigaldus õnnestus
if php -v &>/dev/null; then
  echo "PHP paigaldus õnnestus!"
  php -v
else
  echo "Tõrge PHP paigaldamisel."
  exit 1
fi

# Apache teenuse taaskäivitamine
echo "Taaskäivitan Apache teenuse..."
sudo systemctl restart apache2

echo "=== PHP paigaldus on lõpetatud! ==="
echo "Testimiseks loo fail /var/www/html/info.php järgmise sisuga:"
echo "<?php phpinfo(); ?>"

echo "Logifail salvestatud asukohta: $(pwd)/$LOGFILE"
