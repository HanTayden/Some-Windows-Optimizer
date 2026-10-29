# NIGHTFALL Compatibility Matrix

This document describes which Windows versions, editions, builds, and components NIGHTFALL supports, and which controls are gated by edition or build.

## Supported operating systems

| OS | Minimum build | Notes |
|----|---------------|-------|
| Windows 10 | 19041 (2004, May 2020 Update) | Base floor for all controls |
| Windows 11 | 22000 (21H2) | Windows 11-only tweaks gated here |
| Windows Server | Not offered | Server installations are excluded |

NIGHTFALL detects the OS from registry build numbers, never from product marketing names. `WindowsVersionInfo.IsWindows11` is `true` only for non-server builds >= 22000.

## Build-floor gating

Every catalog entry declares a `MinBuild` (default `19041`) and optional `MaxBuild`, `Windows11Only`, `AllowServer`, and `RequiresEnterpriseOrEducation`. `OsRequirement.Evaluate` enforces these before any operation is offered or applied.

| Feature | MinBuild | Windows 11 only | Scope | Notes |
|---------|----------|-----------------|-------|-------|
| Base platform | 19041 | No | Both | All catalogs |
| Game Mode tweak | 19041 | No | Current user | |
| Advertising ID / privacy tweaks | 19041 | No | Current user | |
| Diagnostic-data policy (AllowTelemetry) | 19041 | No | Machine | Home/Pro may partially honor |
| Hardware-accelerated GPU scheduling (HAGS) | 19041 | No | Machine | Advanced only; requires reboot |
| Scheduled task toggling | 19041 | No | Machine | Curated Microsoft tasks only |
| AppX debloat | 19041 | No | Current user | Curated, non-protected only |
| Cortana (alternate package) | — | MaxBuild 22621 | Current user | Older upgrades only |
| Dev Home debloat | 22621 | No | Current user | |

## Edition behavior

| Edition | Diagnostic-data policy (AllowTelemetry) | Notes |
|---------|-----------------------------------------|-------|
| Home / Pro | May ignore or partially honor | Not a claim that all telemetry can be disabled |
| Enterprise / Education | Documented managed behavior | Full policy support |

## Components NIGHTFALL never touches (protected)

- **Security:** Windows Defender (WinDefend, WdNisSvc, Sense, SecurityHealthService), firewall (mpssvc, BFE), cryptographic services (CryptSvc, TrustedInstaller, msiserver), security health.
- **Updates:** Windows Update (wuauserv), Update Medic (WaaSMedicSvc), Update Orchestrator (UsoSvc), BITS, DeviceInstall, DsmSvc.
- **Networking:** DHCP (Dhcp), DNS (Dnscache), NLA (NlaSvc), network profile (netprofm, netman), Wi-Fi (WlanSvc), connection manager (Wcmsvc).
- **Audio:** Windows Audio (Audiosrv), audio endpoint builder (AudioEndpointBuilder).
- **Input/shell:** Bluetooth (bthserv, BluetoothUserService), touch/handwriting (TabletInputService), themes (Themes), power (Power), event log (EventLog), task scheduler core (Schedule).
- **Boot/core:** RPC (RpcSs, RpcEptMapper), DCOM (DcomLaunch), BrokerInfrastructure, CoreMessagingRegistrar, PlugPlay, ProfSvc, SamSs, LsaSrv, KeyIso, StateRepository, Appinfo, gpsvc, SystemEventsBroker, UserManager.
- **Printing:** Print Spooler (Spooler).
- **Notifications/search:** WpnService, WSearch.
- **Store/AppX infrastructure:** Store, App Installer, Store Purchase, Security UI, Xbox Identity Provider, Gaming Services, Shell Experience Host, Start Menu Experience Host, Edge, Game Bar, Game Overlay.

## Components offered only with clear trade-offs (guarded)

DiagTrack, DPS, WdiServiceHost, WdiSystemHost, WerSvc, WSearch, SysMain, Spooler, bthserv, TabletInputService, XblAuthManager, XblGameSave, XboxNetApiSvc, XboxGipSvc, PhoneSvc, WMPNetworkSvc, MapsBroker, RetailDemo, PcaSvc, Fax, WpnService. Each is offered only through curated service profiles with documented rationale and caveats.

## PERFORMANCE_INFORMATION note

On this x64 Windows 11 build, the native `PERFORMANCE_INFORMATION` structure is **104 bytes**: a DWORD `cb`, 4-byte alignment gap, ten pointer-sized page counters, and three trailing DWORD counters. Passing the commonly published all-DWORD (60-byte) layout to `GetPerformanceInfo` fails with `ERROR_INSUFFICIENT_BUFFER (24)`; passing a larger size without correct offsets silently shifts counters. NIGHTFALL allocates the larger of marshalled/native size, validates the kernel-reported `cb`, and throws on mismatch.
