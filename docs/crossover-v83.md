# CrossOver v83 build

The compatibility branch starts at MapleEzorsia PR #69, commit
`5926ab7611ced00dcaab646eb398a1f873c6c712`. The adapter fallback uses a
real adapter from Wine when the legacy client supplies space for one adapter
and the full list does not fit.

Build the 32-bit DLL in the Linux Clang container. Bind a clean checkout at
`/job/source`, an empty output directory at `/job/out`, and an x86 MSVC/Windows
SDK prepared with xwin at `/job/windows-sdk`. Include
`sdk/include/shared/SDKDDKVer.h` as a symlink to `sdkddkver.h` on Linux.
The container needs Python 3 and LLVM under `/emsdk/upstream/bin`.

```sh
docker run --rm \
  -v "$PWD:/job/source:ro" \
  -v "$WIN32_SDK:/job/windows-sdk:ro" \
  -v "$WIN32_OUTPUT:/job/out" \
  --entrypoint /bin/bash "$CLANG_IMAGE" /job/source/tools/build-win32.sh
```

The tested setup uses xwin 0.10.0 and Clang 22. Record the built DLL's SHA-256
before copying it and `ezorsia/config.ini` into a CrossOver test client.
Verify login, character selection, and entry into a map on the Cosmic server.
