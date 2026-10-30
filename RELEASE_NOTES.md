## Changes

- Publish mesh-enabled wpad and companion basic recovery APKs for the tested JIDU6411 snapshot.
- Include a plain-language installation/mesh guide, read-only compatibility checker, recovery helper and SHA-256 checksums.
- Include pinned build configuration, upstream source archives and attribution to Mayank Raut's firmware/setup project, OpenWrt and hostap contributors.

Tested only on JIDU6411 / JIDU6J11, OpenWrt SNAPSHOT `r35553+1410-fdb162fb81`, `qualcommbe/ipq95xx`, kernel `6.18.55`. Other models and snapshot builds are untested. This is a custom userspace package release, not a firmware image or an official OpenWrt package feed. No new live router changes were made to prepare this release.

Start with the README and compatibility checker. Use the bundle for installation; standalone APKs are also supplied for inspection. Check SHA256SUMS before use. The prebuilt APK must not be treated as universal snapshot compatibility.
