#!/bin/bash
# kasutajad_pwgen.sh
# Ülesanne 5: loeb failist kasutajanimesid, genereerib paroolid, lisab kasutajad + logib kasutaja:parool
# Sobib Debian/Ubuntu tüüpi süsteemidele. Käivitada root'ina.

set -euo pipefail

# --- Parameetrite kontroll ---
if [ $# -ne 1 ]; then
    echo "Kasutus: $0 <kasutajate_fail>"
    exit 1
fi

KASUTAJAD_FAIL="$1"
LOGIFAIL="/root/loodud_kasutajad_paroolidega"   # logifail root kodus (ainult root näeb)
PAROOL_PIKKUS=12                               # soovituslik parooli pikkus

# --- Käivitaja peab olema root (ära lase sudo kaudu käivitada kui UID != 0) ---
if [ "$(id -u)" -ne 0 ]; then
    echo "Seda skripti võib käivitada vaid root kasutaja."
    exit 1
fi

# --- Kontrollime sisendfaili olemasolu ---
if [ ! -f "$KASUTAJAD_FAIL" ]; then
    echo "Sisendfaili '$KASUTAJAD_FAIL' ei leitud!"
    exit 1
fi

# --- Kindlustame, et logifail on privaatne ---
old_umask=$(umask)
umask 077
: > "$LOGIFAIL"
chmod 600 "$LOGIFAIL"
# tagame, et umask taastatakse skripti lõpus
trap 'umask "$old_umask"' EXIT

# --- Parooli genereerimise funktsioon ---
gen_password() {
    local len="$PAROOL_PIKKUS"
    # kui pwgen on olemas, kasuta teda (turvalisem variant '-s' ja 1)
    if command -v pwgen >/dev/null 2>&1; then
        # -s: secure, üks parool ritta
        pwgen -s "$len" 1
    else
        # fallback: openssl rand -> base64 -> eemaldame mitte-alfanumeerilised -> lõikame pikkuseks
        # genereerime piisavalt baite, et pärast filtreerimist oleks piisavalt tähemärke
        openssl rand -base64 $((len + 6)) | tr -dc 'A-Za-z0-9' | cut -c1-"$len"
    fi
}

# --- Kasutajanime valideerimise funktsioon ---
# lihtne kontroll: algab tähega või alakriipsuga, lubatud: a-z0-9_- , pikkus <= 32
valid_username() {
    local u="$1"
    if [[ "$u" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]]; then
        return 0
    else
        return 1
    fi
}

# --- Pea tsükkel: loeme faili realt reale ---
while IFS= read -r rida || [ -n "${rida:-}" ]; do
    # Eemaldame ees-/taha tühikud ja võimalikud CR
    kasutaja=$(echo "$rida" | tr -d '\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    # Ignoreerime tühjad read ja kommentaarid (algusega #)
    if [ -z "$kasutaja" ] || [[ "$kasutaja" == \#* ]]; then
        continue
    fi

    # Valideerime kasutajanime
    if ! valid_username "$kasutaja"; then
        echo "Hoiatus: kasutajanimi '$kasutaja' ei vasta nõuetele — vahele jäetakse."
        continue
    fi

    # Kui kasutaja juba eksisteerib - anname teada ja jätame vahele
    if id -u "$kasutaja" >/dev/null 2>&1; then
        echo "Kasutaja '$kasutaja' juba olemas — vahelejätmine."
        continue
    fi

    # Genereerime parooli (novas reas oleva väljundi trimmitakse)
    parool=$(gen_password)
    # turvalisuse kontroll: kui parool on tühi, lükka tagasi
    if [ -z "$parool" ]; then
        echo "Viga: parooli genereerimine ebaõnnestus kasutaja jaoks: $kasutaja" >&2
        continue
    fi

    # Loome kasutaja koos kodukataloogiga ja default shelliga
    # -m : loo kodukataloog
    # -s /bin/bash : määrame vaikimisi shelli (soovi korral muuda)
    if useradd -m -s /bin/bash "$kasutaja"; then
        # Määrame parooli (chpasswd loeb username:password)
        if echo "${kasutaja}:${parool}" | chpasswd; then
            # Sunni kasutaja parooli vahetust esimesel sisselogimisel (kui soovid)
            # chage -d 0 "$kasutaja"

            # Logime faili -- kasutame printf, et olla kindel formaadis
            printf '%s:%s\n' "$kasutaja" "$parool" >> "$LOGIFAIL"
            echo "Lisatud: $kasutaja"
        else
            echo "Viga: parooli määramine ebaõnnestus: $kasutaja" >&2
        fi
    else
        echo "Viga kasutaja loomisel: $kasutaja" >&2
    fi

done < "$KASUTAJAD_FAIL"

# Lõpp
echo "Valmis. Logi salvestatud faili: $LOGIFAIL (õigused: 600, ainult root)."
