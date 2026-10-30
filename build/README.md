# Build a mesh package for an OpenWrt snapshot

Use Linux on a case-sensitive filesystem. On macOS we used a Linux container and a Docker volume; a normal case-insensitive shared source directory is unsuitable for a full OpenWrt build. [Dockerfile](Dockerfile) describes the build environment used.

## Reproduce the tested source/configuration

The release includes `openwrt-0ab51fb9.tar.gz`, the hostap source archive and checksums. These are source distributions, not firmware images. The same inputs are available upstream.

```sh
git clone https://github.com/openwrt/openwrt.git
cd openwrt
git checkout 0ab51fb9c13fd88d5eba565cd3fd22b7b9a18bbf
# Copy build/tested.config from this repository into the source root:
cp /path/to/openwrt-jidu6j11-mesh/build/tested.config .config
make defconfig
make -j2 tools/install
make -j2 toolchain/install
# Build the hostapd runtime dependencies and both selected wpad variants.
for pkg in package/libs/libjson-c package/utils/lua package/libs/libmd package/libs/libubox package/system/ubus package/libs/udebug package/libs/libnl-tiny package/libs/mbedtls package/utils/ucode package/network/services/hostapd; do
    make -j2 "$pkg/compile" V=s || exit 1
done
```

Some dependencies may require their own normal OpenWrt prerequisite build on a clean machine; this is the focused compile sequence used in our prepared tree. The clean-checkout sequence has not been independently reproduced from scratch for this publication. The complete tested `.config` is retained as `tested.full.config`. Source/configuration are pinned; byte-for-byte reproducibility has not been established.

The `qcom_rdp433` profile is used **only to obtain the matching userspace toolchain and feature selections**. It is not a JIDU6J11 firmware profile. Do not flash images made from this configuration. Install only the intended userspace wpad APK, not generated kernel modules or firmware images.

The important selections are:

```text
CONFIG_PACKAGE_wpad-mesh-mbedtls=m
CONFIG_PACKAGE_wpad-basic-mbedtls=m
CONFIG_PACKAGE_kmod-ath11k=m
CONFIG_PACKAGE_kmod-ath11k-pci=m
CONFIG_DRIVER_11AC_SUPPORT=y
CONFIG_DRIVER_11AX_SUPPORT=y
CONFIG_WPA_MBO_SUPPORT=y
```

Selecting the ath11k packages supplies feature dependencies used by wpad's build system. It does not mean a new kernel driver must be installed on the target. Do not remove these selections just because you only want a userspace APK: our earlier build without AC/AX support could not parse the existing AP feature configuration.

No custom hostap C-source patch was required. OpenWrt's existing patches and integration scripts come from the pinned source tree. APKs are normally under `bin/packages/aarch64_cortex-a53/base/`.

## For another snapshot

Use **that firmware's actual source and build configuration/SDK**, including any community-firmware patches. Do not assume its displayed revision identifies all later changes in a community build. Record its hostapd-common, wifi-scripts, ucode, ubus and libubox versions. Compare the packaged integration scripts with the firmware before any installation.

Enable mesh plus the feature selections needed by the installed AP configuration. Build, inspect declared dependencies and ELF shared-library names, then test AP configuration parsing and SAE mesh parsing. Finally, with Ethernet recovery and an automatic rollback, test live AP operation, authenticated mesh peers, LAN forwarding, DNS and internet access. A successful compilation or `iw phy` capability list alone is not a successful mesh test.

Do not publish a rebuilt APK as compatible with an untested snapshot. Open an issue with the firmware revision and non-secret package versions if you want to contribute a compatibility result; never attach `/etc/config/wireless`, private keys or complete backups.
