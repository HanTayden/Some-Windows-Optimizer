# NIGHTFALL Architecture

This document describes the internal structure of NIGHTFALL: projects, layers, the transaction lifecycle, the elevation protocol, and the data flow. It is intended for contributors and reviewers.

## Project structure

```
src/Nightfall.Core          Core library (net9.0-windows10.0.19041.0)
├── Abstractions/           Interfaces and contracts (IRegistryStore, IServiceBackend, etc.)
├── Catalogs/               Curated allowlists (tweak, service, task, debloat, gaming profiles)
├── Discovery/              MetricsSampler, PdhCounters, hardware discovery
├── Elevation/              HMAC protocol, envelope, server/client models
├── Models/                 Data models, enums, catalog models, Windows version info
├── Operations/             Operation factory, safety rules, registry state codec
├── Platform/               Native P/Invoke, AppPaths, clock, filesystem
│   └── Native/             NativeSystem.cs (PERFORMANCE_INFORMATION, etc.)
├── Services/               Dashboard, tweaks, debloat, services, startup, settings,
│                           gaming, profile, plan coordinator, operation specs, restore
└── Transactions/           TransactionEngine, OperationValidator, exceptions

src/Nightfall.App           WPF shell (asInvoker, non-admin UI)
├── ViewModels/             MainViewModel, page view models, NavigationItem
├── Views/                  10 pages + History, Settings, ReviewWindow, MessageWindow
├── Services/               AppServices, DialogService, Activity log
├── Mvvm/                   ObservableObject, AsyncRelayCommand
└── App.xaml.cs             Startup, automation/smoke-test, crash handling

src/Nightfall.Privileged    Elevated helper (admin-only, separate process)
└── ElevationServer/        Request validation and execution

tests/Nightfall.Core.Tests/ xUnit test suite (130 tests)
├── TestSupport.cs          Fakes, TestData, NIGHTFALL_DATA_DIR redirection
├── CatalogIntegrityTests.cs
├── ProfileServiceTests.cs
├── SettingsServiceTests.cs
├── StartupBackupStoreTests.cs
├── WindowsVersionTests.cs
├── OperationValidatorTests.cs
├── RegistryStateCodecTests.cs
├── TransactionEngineTests.cs
└── ElevationCryptoTests.cs
```

## Layers

### UI layer (`Nightfall.App`)
Runs non-admin (`asInvoker`). Owns all presentation: pages, view models, dialogs, theme, search, activity log. Never performs machine-scope writes. Page load failures are captured in `PageViewModelBase.LastError` and surfaced in `MainViewModel.PageFailures` and the automation log so a swallowed exception is never reported as a successful load.

### Core service layer (`Nightfall.Core.Services`)
Orchestrates discovery, plan building, profile import/export, settings, startup backup index, and dashboard capture. All services are testable with fake backends.

### Catalog layer (`Nightfall.Core.Catalogs`)
Curated allowlists: tweaks, services, scheduled tasks, AppX debloat, gaming profiles. Every entry documents purpose, side effects, reversal, Microsoft support reference, risk, scope, and build floor. Unknown or uncurated items are inspect-only.

### Transaction layer (`Nightfall.Core.Transactions`)
`TransactionEngine` implements preview → back up → apply → verify → log → automatic rollback. `OperationValidator` enforces the allowlist: exactly one typed target, privilege/scope metadata matching the target, reviewed catalog IDs, reviewed option values, protected-service rejection, current-user-only startup/AppX, non-reversible-only-for-AppX.

### Elevation layer (`Nightfall.Core.Elevation`)
HMAC-SHA256 signed, time-limited (max 15 min, 2-min future tolerance), same-user/same-machine requests. DPAPI-protected key. Replay prevention via `consumed/` audit folder.

### Platform / Native (`Nightfall.Core.Platform`)
P/Invoke wrappers. `NativeSystem.ReadPerformanceInfo` uses a 104+ byte unmanaged buffer and validates the kernel-reported `cb` against the marshalled struct size, throwing on mismatch. `AppPaths` redirects all data via `NIGHTFALL_DATA_DIR` for testing.

## Transaction lifecycle

1. **Preview** — `PlanRunner.ReviewAndApplyAsync` (always preview + review; dry-run never writes).
2. **Admin routing** — machine-scope operations go to `Nightfall.Privileged.exe`.
3. **Exact before-state** — captured per operation and persisted to the transaction journal.
4. **Journal read-back** — the journal is read back from disk before any write; failure aborts with zero writes.
5. **Apply** — executed (in helper if machine-scope).
6. **Verify** — after-state compared against before-state; failure triggers automatic rollback.
7. **After-state** — recorded; result logged.
8. **Rollback** — automatic on verify failure; manual on external-change conflict unless forced.

## Profiles

Profile files contain only catalog IDs (no executable content, arbitrary registry paths, or package identities). Import (`ProfileService.Import`) re-resolves every ID against the installed catalog, drops unknown/protected/unsupported entries with warnings, and normalizes null collections instead of crashing.

## Test approach

130 xUnit tests run in a redirected `%TEMP%` data directory (`NIGHTFALL_DATA_DIR`) with module-initialized cleanup. Fakes cover registry, services, power, tasks, AppX, clock, elevation, action log, transaction store, and operation factory. Real machine-scope changes, helper execution, restore points, and AppX removal cannot be end-to-end tested from a non-admin session.
