#!/bin/sh
# Run from the persistent extracted release bundle, alongside the recovery APK.
set -eu
cd "$(dirname "$0")"
pkg=wpad-basic-mbedtls-2026.08.07~831364bf-r4.apk
[ -f "$pkg" ] && [ -f backup/wireless ] || { echo 'Missing recovery APK or wireless backup.' >&2; exit 1; }
actual=$(sha256sum "$pkg")
[ "${actual%% *}" = 90cd9c00c06acc568846783aa37b0d484f4b4bb311605e54687da9e7d97f4bc6 ] || { echo 'Recovery APK checksum mismatch.' >&2; exit 1; }
apk --network=no del wpad-mesh-mbedtls
apk --network=no --allow-untrusted add "./$pkg"
/etc/init.d/wpad stop
for path in /usr/sbin/wpad /usr/share/hostap/hostapd.uc /usr/share/hostap/wpa_supplicant.uc; do
    if [ -f "/rom$path" ]; then cp -p "/rom$path" "$path"; fi
done
ln -sf wpad /usr/sbin/hostapd
ln -sf wpad /usr/sbin/wpa_supplicant
cp -p backup/wireless /etc/config/wireless
/etc/init.d/wpad start
wifi reload
echo 'Restored basic Wi-Fi. Review iw dev and test a client connection.'
