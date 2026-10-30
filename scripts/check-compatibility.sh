#!/bin/sh
# Read-only check for the prebuilt v0.1.0 baseline.
set -eu
fail() { echo "STOP: $*" >&2; exit 1; }
for tool in ubus jsonfilter apk sha256sum iw; do
    command -v "$tool" >/dev/null || fail "Missing $tool; this bundle expects the tested apk-based OpenWrt."
done
board=$(ubus call system board)
[ "$(printf '%s' "$board" | jsonfilter -e '@.board_name')" = 'jiorouter,ax6000-jidu6j11' ] || fail 'Untested board.'
[ "$(printf '%s' "$board" | jsonfilter -e '@.release.revision')" = 'r35553+1410-fdb162fb81' ] || fail 'Untested snapshot. Build a package matching your firmware.'
[ "$(printf '%s' "$board" | jsonfilter -e '@.release.target')" = 'qualcommbe/ipq95xx' ] || fail 'Untested target.'
[ "$(printf '%s' "$board" | jsonfilter -e '@.kernel')" = '6.18.55' ] || fail 'Untested kernel baseline.'
[ "$(cat /etc/apk/arch)" = 'aarch64_cortex-a53' ] || fail 'Wrong package architecture.'
installed=$(apk list --installed)
for pkg in 'hostapd-common-2026.08.07~831364bf-r4' 'wifi-scripts-1.0-r3' 'libubox20260721-2026.07.21~e7608b69-r1' 'libubus20260925-2026.09.25~414c60a2-r1' 'libucode20230711-2026.07.09~b885dd0f-r1'; do
    printf '%s
' "$installed" | grep -F "$pkg " >/dev/null || fail "Baseline differs: $pkg"
done
for pkg in libblobmsg-json20260721 libc libmbedtls21 libnl-tiny1 libudebug ucode ucode-mod-fs ucode-mod-nl80211 ucode-mod-rtnl ucode-mod-ubus ucode-mod-uloop; do
    apk info -e "$pkg" >/dev/null || fail "Missing dependency: $pkg"
done
check_hash() {
    [ -f "$2" ] || fail "Missing $2"
    actual=$(sha256sum "$2")
    [ "${actual%% *}" = "$1" ] || fail "Wi-Fi script differs: $2"
}
for prefix in /rom ''; do
    check_hash 0c0dd03ae6a8f27e4077cb86bdf62aca4645459f516716349809b38a74e63669 "$prefix/usr/share/hostap/common.uc"
    check_hash 56df2b06e51fd630443958da12cfcd6172094b2557af0137d8b90f32506d9b6e "$prefix/usr/share/hostap/hostapd.uc"
    check_hash 75262cc97f6675a9a3b5611d012ee250289bf710101635311794e96242f82580 "$prefix/usr/share/hostap/wpa_supplicant.uc"
done
iw phy | grep -F '* mesh point' >/dev/null || fail 'Driver does not advertise mesh point mode.'
echo 'PASS: firmware, architecture, dependencies and integration scripts match the tested baseline.'
echo 'Only the physical JIDU6411 has been tested. Keep an Ethernet recovery connection.'
