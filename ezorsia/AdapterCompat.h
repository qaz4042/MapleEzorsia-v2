#pragma once
#include <iphlpapi.h>
#include <vector>

using GetAdaptersInfoFn = DWORD (WINAPI *)(PIP_ADAPTER_INFO, PULONG);
static GetAdaptersInfoFn realGetAdaptersInfo = nullptr;

static DWORD WINAPI GetAdaptersInfoCompat(PIP_ADAPTER_INFO output, PULONG size)
{
    const ULONG capacity = size ? *size : 0;
    const DWORD result = realGetAdaptersInfo(output, size);
    if (result != ERROR_BUFFER_OVERFLOW || !output || capacity < sizeof(IP_ADAPTER_INFO) ||
        *size <= capacity || *size > 1024 * 1024) {
        return result;
    }

    std::vector<unsigned char> buffer(*size);
    auto adapter = reinterpret_cast<PIP_ADAPTER_INFO>(buffer.data());
    if (realGetAdaptersInfo(adapter, size) != ERROR_SUCCESS) {
        return result;
    }

    const auto first = adapter;
    while (adapter && adapter->AddressLength != 6) {
        adapter = adapter->Next;
    }
    if (!adapter) {
        adapter = first;
    }
    *output = *adapter;
    output->Next = nullptr;
    output->CurrentIpAddress = nullptr;
    output->IpAddressList.Next = nullptr;
    output->GatewayList.Next = nullptr;
    output->DhcpServer.Next = nullptr;
    output->PrimaryWinsServer.Next = nullptr;
    output->SecondaryWinsServer.Next = nullptr;
    *size = sizeof(IP_ADAPTER_INFO);
    return ERROR_SUCCESS;
}

static void InstallAdapterCompat()
{
    const auto module = GetModuleHandleW(L"iphlpapi.dll");
    if (!module || !GetProcAddress(GetModuleHandleW(L"ntdll.dll"), "wine_get_version")) {
        return;
    }
    realGetAdaptersInfo = reinterpret_cast<GetAdaptersInfoFn>(GetProcAddress(module, "GetAdaptersInfo"));
    if (realGetAdaptersInfo) {
        Memory::SetHook(true, reinterpret_cast<void**>(&realGetAdaptersInfo),
                        reinterpret_cast<void*>(&GetAdaptersInfoCompat));
    }
}
