#!/bin/bash
set -euo pipefail
cd /job/source/ezorsia
SDK=/job/windows-sdk
LLVM=/emsdk/upstream/bin
mkdir -p /job/out
python3 - <<'PY'
import pathlib, re, struct
def record(kind, ident, data, flags, lang):
    header = struct.pack('<IIHHHHIHHII',len(data),32,65535,kind,65535,ident,0,flags,lang,0,0)
    return header+data+bytes(-len(data)%4)
ids = dict(re.findall(r'#define\s+(IDR_RCDATA\d+)\s+(\d+)',pathlib.Path('resource.h').read_text()))
rc = pathlib.Path('Resource.rc').read_text(encoding='utf-16')
with open('/job/out/resource.res','wb') as f:
    f.write(record(0,0,b'',0,0))
    for name, asset in re.findall(r'(IDR_RCDATA\d+)\s+RCDATA\s+"([^"]+)"',rc):
        f.write(record(10,int(ids[name]),pathlib.Path(asset).read_bytes(),0x0030,0x0409))
PY
for file in Client dinput8 MainMain ZAllocEx dllmain Memory stdafx; do
    "$LLVM/clang" --driver-mode=cl --target=i686-pc-windows-msvc /nologo /std:c++17 /O2 /MD /EHsc /c /DWIN32 /DUNICODE /D_UNICODE /DNDEBUG /DEZORSIA_EXPORTS /D_WINDOWS /D_USRDLL /D_WINSOCK_DEPRECATED_NO_WARNINGS /D_CRT_SECURE_NO_WARNINGS /clang:-ferror-limit=0 \
        "/imsvc$SDK/crt/include" "/imsvc$SDK/sdk/include/ucrt" "/imsvc$SDK/sdk/include/shared" "/imsvc$SDK/sdk/include/um" "/imsvc$SDK/sdk/include/winrt" "/Fo/job/out/$file.obj" "$file.cpp"
done
"$LLVM/lld" -flavor link /dll /machine:x86 /out:/job/out/dinput8.dll /opt:ref,icf /libpath:"$SDK/crt/lib/x86" /libpath:"$SDK/sdk/lib/um/x86" /libpath:"$SDK/sdk/lib/ucrt/x86" /job/out/*.obj /job/out/resource.res /job/source/detours/detours.lib winmm.lib ws2_32.lib kernel32.lib user32.lib ole32.lib oleaut32.lib advapi32.lib
