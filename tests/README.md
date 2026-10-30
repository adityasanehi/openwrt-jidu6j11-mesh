# Helper checks

Run only inside a disposable Linux container; the recovery test creates mock
system paths there. It never invokes a real package manager or Wi-Fi service.

```sh
docker run --rm --network none --user root \
  -e MESH_TEST_CONTAINER=1 \
  -v "$PWD:/publish:ro" \
  -v /path/to/release-assets:/release:ro \
  mesh-6411-builder:local python3 /publish/tests/test_helpers.py
```

Build `mesh-6411-builder:local` from `build/Dockerfile` first if needed.
The release-assets directory must contain the actual basic recovery APK.
The test checks shell syntax, rejection of a different board/snapshot,
recovery ordering/restoration, and checksum failure before any mutation.
The compatibility checker was also run read-only on the live tested router.
The generalized recovery helper has not been executed against a live router.
