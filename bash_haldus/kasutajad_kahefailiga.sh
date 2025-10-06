#!/bin/bash
# Skript: lisab süsteemi kasutajad koos paroolidega, kasutades kahte faili
# Kasutamine: ./kasutajad_kahefailiga.sh kasutajad kasutajad_paroolid

# Kontrollime, et skripti käivitab root
if [ "$(id -u)" -ne 0 ]; then
  echo "Seda skripti peab käivitama root kasutaja."
  exit 1
fi

# Kontrollime parameetrite olemasolu
if [ $# -ne 2 ]; then
    echo "Kasutamine: $0 kasutajad_fail kasutajad_paroolid_fail"
    exit 1
fi

kasutajad_fail=$1
paroolid_fail=$2

# Kontrollime, et mõlemad failid eksisteerivad
if [ ! -f "$kasutajad_fail" ]; then
    echo "Faili $kasutajad_fail ei leitud!"
    exit 1
fi

if [ ! -f "$paroolid_fail" ]; then
    echo "Faili $paroolid_fail ei leitud!"
    exit 1
fi

# Loeme kasutajad ühest failist
while IFS= read -r kasutaja
do
    # Otsime parooli teisest failist (rida kujul kasutaja:parool)
    rida=$(grep "^${kasutaja}:" "$paroolid_fail")
    if [ -z "$rida" ]; then
        echo "Hoiatus: kasutajale '$kasutaja' ei leitud parooli failist."
        continue
    fi

    parool=$(echo "$rida" | cut -d':' -f2)

    # Kontrollime, kas kasutaja juba eksisteerib
    if id "$kasutaja" &>/dev/null; then
        echo "Kasutaja '$kasutaja' on juba olemas – vahele jäetud."
        continue
    fi

    # Loome kasutaja
    useradd -m "$kasutaja"
    if [ $? -ne 0 ]; then
        echo "Viga: kasutaja '$kasutaja' loomisel."
        continue
    fi

    # Lisame parooli
    echo "$kasutaja:$parool" | chpasswd
    if [ $? -eq 0 ]; then
        echo "Kasutaja '$kasutaja' loodud ja parool määratud."
    else
        echo "Viga: parooli määramisel kasutajale '$kasutaja'."
        continue
    fi

    # Kontrollime
    echo "Kontroll /etc/passwd:"
    grep "$kasutaja" /etc/passwd

    echo "Kontroll /etc/shadow:"
    grep "$kasutaja" /etc/shadow

    echo "Kodukataloog:"
    ls -la "/home/$kasutaja"
    echo "---------------------------"
done < "$kasutajad_fail"
