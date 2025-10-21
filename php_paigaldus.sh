#!/bin/bash
# PHP paigaldamise skript (Debian 10/11/12)
# Autor: [Matthias Järvet]
# Kuupäev: $(date +"%Y-%m-%d")

echo "=== PHP paigaldamise alustamine... ==="

if [ "$EUID" -ne 0 ]; then
  echo "Palun käivita skript root kasutajana (kasuta sudo)."
  exit 1
fi

echo "Uuendan pakettide nimekirja..."
apt update -y

# Kui PHP 8.x pole Debiani hoidlas, lisame sury.org hoidla (PHP uusimad versioonid)
if ! apt-cache show php8.2 >/dev/null 2>&1; then
  echo "Lisan PHP hoidla (sury.org)..."
  apt install -y ca-certificates apt-transport-https software-properties-common lsb-release wget
  wget -qO - https://packages.sury.org/php/apt.gpg | apt-key add -
  echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list
  apt update -y
fi

# Paigaldame PHP ja vajalikud moodulid
echo "Paigaldan PHP ja vajalikud abipaketid..."
apt install -y php8.2 libapache2-mod-php8.2 php8.2-mysql

# Kontrollime paigaldust
if php -v > /dev/null 2>&1; the
