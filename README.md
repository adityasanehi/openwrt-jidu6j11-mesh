# OpenWrt mesh package for Jio JIDU6J11

Enable encrypted **802.11s wireless mesh** on a Jio AX6000 JIDU6J11 already running a compatible OpenWrt snapshot. Downloadable `wpad-mesh-mbedtls` APKs, a compatibility check, recovery instructions, and the build configuration are included.

> **Tested only on a JIDU6411 running OpenWrt SNAPSHOT `r35553+1410-fdb162fb81`, target `qualcommbe/ipq95xx`, kernel `6.18.55`.** Other 6J11 models and snapshot builds have not been tested with these APKs. A matching model or package version alone does not establish compatibility.

**[Download the tested package bundle](https://github.com/adityasanehi/openwrt-jidu6j11-mesh/releases/tag/v0.1.0)** · [Build for another snapshot](build/README.md) · [Credits](#credits)

## What this does

A mesh backhaul is the wireless connection between your routers. Each router can also broadcast your usual Wi-Fi name for phones and laptops. Devices connected by Wi-Fi or a LAN cable can then reach the main router through the mesh.

This package replaces the basic Wi-Fi authentication service with its mesh-enabled variant. It supports encrypted SAE mesh alongside existing Wi-Fi 6 access points. It does **not** flash firmware, unlock stock Jio firmware, or install a new radio driver. Installing the APK makes mesh available; you still need to configure the mesh connection on each node.

The firmware and initial OpenWrt setup are credited to **[Mayank Raut's Jio-AX6000-6J11-OpenWRT-SSH project](https://github.com/themayankraut/Jio-AX6000-6J11-OpenWRT-SSH)**. Start with that project's instructions if your router is still on stock firmware. This repository is an independent package build, not a firmware release or an endorsement from that project.

## Which download should I use?

| Your router | What to do |
| --- | --- |
| JIDU6411 on the exact tested snapshot above | Run the compatibility check, then follow the steps below. |
| Another OpenWrt snapshot, even on a 6411 | Build against its matching source, libraries and Wi-Fi scripts. Do not force these APKs onto it. |
| Another 6J11 model | Untested. Verify both firmware compatibility and actual mesh operation before relying on it. |
| MediaTek JIDU6101 / 6J01 | Use its own release's official mesh package. These custom Qualcomm snapshot APKs are not the appropriate download. |
| Stock Jio firmware | Install compatible OpenWrt first, using the firmware project's own guide. |

`wpad-mesh-mbedtls-2026.08.07~831364bf-r4.apk` is the mesh package. The companion `wpad-basic-mbedtls` APK is for recovery. Inside the install bundle, filenames retain the native `~` version separator; standalone GitHub assets replace it with `.`. Both are built from pinned source; they are not signed by OpenWrt. Published SHA-256 checksums identify the exact files we tested.

## Before you start

Connect your computer to a **LAN port with an Ethernet cable** and confirm you can log into the router. Keep the cable connected while replacing Wi-Fi packages. Download an OpenWrt configuration backup through **System → Backup / Flash Firmware** and keep it on your computer.

Use root SSH access to your OpenWrt router. Replace `192.168.1.1` below with its actual management address. This guide uses `apk`; it does not apply to older `opkg` firmware.

Do not run `apk upgrade` or replace core libraries to make this package fit. Snapshot feeds move forward, and packages with the same displayed version can depend on different libraries or scripts.

## Install the tested package

### 1. Download and copy the bundle

From the [v0.1.0 release](https://github.com/adityasanehi/openwrt-jidu6j11-mesh/releases/tag/v0.1.0), download **`jidu6j11-mesh-v0.1.0.tar.gz`** and **`SHA256SUMS`** to the same folder. Check the bundle on your computer:

```sh
# macOS
shasum -a 256 --ignore-missing -c SHA256SUMS
# Linux alternative: sha256sum --ignore-missing -c SHA256SUMS
```

The bundle must report `OK`. Copy it to the router:

```sh
scp -O jidu6j11-mesh-v0.1.0.tar.gz root@192.168.1.1:/tmp/
ssh root@192.168.1.1
```

The following commands run **on the router**:

```sh
mkdir -p /root/jidu6j11-mesh
cd /root/jidu6j11-mesh
tar -xzf /tmp/jidu6j11-mesh-v0.1.0.tar.gz
sha256sum -c SHA256SUMS
sh check-compatibility.sh
```

Continue only if all checks pass. The checker reads the router's firmware, library names and Wi-Fi script fingerprints without changing settings. A pass matches the tested baseline; it cannot guarantee every hardware or configuration combination.

### 2. Prepare recovery, then replace the package

These commands expect `wpad-basic-mbedtls` to be installed. If you already use a full or mesh-enabled `wpad`, stop and check whether a replacement is needed.

```sh
cd /root/jidu6j11-mesh
mkdir -p backup
cp -p /etc/config/wireless backup/wireless
rm -f KEEP
# Restore basic Wi-Fi after three minutes unless you confirm success.
(sh -c 'sleep 180; [ -f KEEP ] || sh ./rollback.sh') >rollback.log 2>&1 </dev/null &

if apk --network=no del wpad-basic-mbedtls &&
   apk --network=no --allow-untrusted add ./wpad-mesh-mbedtls-2026.08.07~831364bf-r4.apk; then
    /etc/init.d/wpad restart
    wifi reload
else
    sh ./rollback.sh
fi
```

`--allow-untrusted` is needed for this locally built package. Use it only after checking the downloaded files. `--network=no` prevents pulling newer dependencies from a rolling feed; missing dependencies should stop installation.

### 3. Verify and keep it

After Wi-Fi returns, confirm your existing Wi-Fi names are visible and a device can reconnect. On the router, inspect the installed package and active interfaces:

```sh
apk list --installed | grep wpad
iw dev
```

You should see `wpad-mesh-mbedtls` installed and your existing access points running. If that works, cancel the timed recovery:

```sh
touch /root/jidu6j11-mesh/KEEP
```

If Wi-Fi fails, stay connected by Ethernet and run:

```sh
cd /root/jidu6j11-mesh
sh ./rollback.sh
```

The recovery script checks the basic APK, reinstalls it, restores the original Wi-Fi configuration, and restores the original firmware's Wi-Fi executable and integration scripts when available. Keep this folder until you have finished testing. Do not install several `wpad` variants together.

## Set up the mesh in LuCI

Use **Network → Wireless**. Names and field placement vary slightly between LuCI versions.

1. On the **5 GHz radio**, keep or create the normal **Access Point** named whatever you want phones and laptops to see. Its Wi-Fi password can match your other access points.
2. Add another interface on that radio. Select **802.11s / Mesh Point** mode and enter a shared **Mesh ID**, for example `mesh-backhaul`.
3. Choose **SAE / WPA3-SAE** encryption and a strong mesh password. All mesh nodes must use the **same Mesh ID and mesh password**. This password can differ from your normal Wi-Fi password.
4. Set the same fixed **channel and channel width** on every backhaul radio. We tested **channel 36, HE80**, with the actual country set to **IN**. Use settings permitted in your location; do not copy a country code that is wrong for you.
5. Attach the mesh interface to **LAN**. Save and apply, keeping the Ethernet recovery connection available.
6. Repeat on each node. Each radio must support mesh; an extra node may need its own firmware's mesh-enabled `wpad` package.

For a node that only extends the main network, give its LAN a unique unused address in the main LAN's subnet, set the main router as its gateway/DNS, and disable its DHCP server and IPv6 router advertisements. The main router remains the DHCP server. Preserve existing access points unless you intend to change them.

**Avoid a network loop:** if mesh is bridged to LAN, do not also connect that node's LAN to the main network by Ethernet. A direct recovery cable to a standalone computer is different. Disconnect any network uplink before bridging it, or plan a separate wired-backhaul design.

### Confirm that it is actually working

Find the mesh interface name using `iw dev`, then run, substituting that name:

```sh
iw dev YOUR_MESH_INTERFACE station dump
```

A working peer shows `mesh plink: ESTAB`, `authorized: yes` and `authenticated: yes`. Also test reaching the main router and the internet from the remote node. Peer establishment alone does not prove LAN forwarding works.

To confirm a phone or laptop is using the new node, check **Associated Stations** in LuCI and match the device's Wi-Fi MAC address. Sharing a Wi-Fi name does not force a client to switch nodes; the client decides when to roam. Toggling its Wi-Fi can help test a fresh association.

## What we verified

On the tested **6411 snapshot**, the custom package ran the existing 2.4 GHz and 5 GHz access points alongside encrypted 5 GHz mesh. It formed authenticated links to two MediaTek OpenWrt nodes. LAN forwarding, internet access and DNS worked. A remote node's radio reload re-established its mesh links. A laptop also connected to an access point on the newly added node.

This is a functional result from a small network, not a throughput certification. We have not completed a full power-cycle recovery campaign, a controlled roaming test, a throughput benchmark, or tests on other 6J11 models/snapshots. Client access and the shared 5 GHz backhaul compete for the same radio airtime.

## Why not just install the latest feed package?

On this snapshot, a newer feed package expected newer system libraries and Wi-Fi integration functions. An initial custom build also lacked Wi-Fi 5/6 feature flags needed by existing access points. The published build uses matching historical source and enables those features. It is a packaging/configuration compatibility fix; no radio firmware modification or new kernel driver was needed.

For a different snapshot, use its matching build environment. See [building](build/README.md) and [the compatibility record](COMPATIBILITY.md).

## Credits

- **[Mayank Raut — Jio-AX6000-6J11-OpenWRT-SSH](https://github.com/themayankraut/Jio-AX6000-6J11-OpenWRT-SSH):** community firmware and the initial firmware installation/setup route used for the tested 6J11. [Firmware releases](https://github.com/themayankraut/Jio-AX6000-6J11-OpenWRT-SSH/releases).
- **[OpenWrt](https://github.com/openwrt/openwrt):** build system, hostapd packaging, Wi-Fi integration and mesh configuration support. Tested package-build source: [`0ab51fb9c13fd88d5eba565cd3fd22b7b9a18bbf`](https://github.com/openwrt/openwrt/tree/0ab51fb9c13fd88d5eba565cd3fd22b7b9a18bbf).
- **[Jouni Malinen and hostap contributors](https://w1.fi/):** hostapd and wpa_supplicant, which implement the authentication and mesh features.
- **Linux wireless, ath11k and mac80211 contributors:** the existing driver support used by the tested hardware.

This project supplies a compatible userspace package build and usage notes. It does not claim authorship of the firmware, the 802.11s implementation, or the upstream driver work. See [NOTICE](NOTICE) and [upstream licensing](licenses/).
