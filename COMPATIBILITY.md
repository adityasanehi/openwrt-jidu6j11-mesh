# Tested compatibility record

Validation date: 2026-10-30. This records observed compatibility, not a promise for future snapshots.

| Item | Tested value |
| --- | --- |
| Physical model | JIDU6411, reported as JioRouter AX6000 JIDU6J11 |
| Board | `jiorouter,ax6000-jidu6j11` |
| Firmware | OpenWrt SNAPSHOT `r35553+1410-fdb162fb81` |
| Target / APK architecture | `qualcommbe/ipq95xx` / `aarch64_cortex-a53` |
| Kernel | `6.18.55` |
| Package version | `2026.08.07~831364bf-r4` |
| Package-build OpenWrt source | `0ab51fb9c13fd88d5eba565cd3fd22b7b9a18bbf` |
| hostap source | `831364bf02710ad09c2f27d3efa92abeeb5634c0` |
| wifi-scripts | `1.0-r3` |
| libubox | `2026.07.21~e7608b69-r1`, ABI `20260721` |
| libubus | `2026.09.25~414c60a2-r1`, ABI `20260925` |
| libucode | `2026.07.09~b885dd0f-r1`, ABI `20230711` |
| 5 GHz mesh | SAE, channel 36 / HE80; both existing peers authenticated |

The source commit used to build wpad is **not** a claim that the complete community firmware was built from that commit. It was selected because its package scripts and library interfaces matched the observed firmware.

Expected SHA-256 of the firmware's original integration files:

```text
0c0dd03ae6a8f27e4077cb86bdf62aca4645459f516716349809b38a74e63669  /rom/usr/share/hostap/common.uc
56df2b06e51fd630443958da12cfcd6172094b2557af0137d8b90f32506d9b6e  /rom/usr/share/hostap/hostapd.uc
75262cc97f6675a9a3b5611d012ee250289bf710101635311794e96242f82580  /rom/usr/share/hostap/wpa_supplicant.uc
```

The same hashes were observed in the corresponding source tree. Hash matches cover these files, not the entire firmware or every possible ABI interaction.

The release's basic package is a **recovery build**, not a byte-for-byte copy of the original firmware binary. Recovery additionally restores the original `/rom` executable and scripts when present.

Other 6J11 models: untested. Other firmware snapshots: untested. MediaTek peers used their own release packages, not this custom APK.
