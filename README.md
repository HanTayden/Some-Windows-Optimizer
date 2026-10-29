# NIGHTFALL — Windows 10/11 Optimization Desktop Application

**Project Nightfall** is a real, compiled C#/.NET 9 WPF desktop application (MVVM) for granular Windows optimization. It provides process/registry journal-based safety, undo via transactions, and a modern dark/light UI. Every change is verifiable, supported, and reversible — there is no fake UI, no synthetic metrics, and no fabricated results.

## What NIGHTFALL is

A Windows desktop optimizer that lets you review, approve, and reverse system changes through a transaction engine. It is designed for power users who want granular control without blindly running "debloat" scripts.

### Key principles

- **No PowerShell; no shell tricks.** All backend logic is compiled C#/.NET WPF MVVM.
- **Nothing is fake.** UI values come from real Windows APIs (Performance Information, GlobalMemoryStatusEx, service catalog, AppX inventory). No synthetic FPS claims, no placebo tweaks.
- **Everything is reversible.** Changes go through preview → admin routing → exact before-state → durable journal → apply → verify → after-state → log → automatic rollback.
- **UI is never elevated.** Administrative operations run in a separate elevated helper (`Nightfall.Privileged.exe`) that only accepts HMAC-signed, time-limited, same-user/same-machine requests from an allowlist.
- **Documented limitations.** Anything untested, unimplemented, or admin-only is explicitly documented. Results are never fabricated.

## Stack & targets

| Item | Value |
|------|-------|
| Language | C# 13 / .NET 9 |
| UI framework | WPF (no third-party UI framework) |
| Target framework | `net9.0-windows10.0.19041.0` |
| Supported OS | Windows 10 2004+ (build 19041+), Windows 11 features gated by build |
| UI entry | `Nightfall.App` (runs as `asInvoker`, non-admin) |
| Elevated helper | `Nightfall.Privileged.exe` (separate, admin-only) |
| Test framework | xUnit 2.9 (`Nightfall.Core.Tests`) |
| SDK path | `%LOCALAPPDATA%\dotnet-sdk\dotnet.exe` |

## Projects

- `Nightfall.Core` — Core library: abstractions, curated catalogs, discovery, elevation protocol, models, operations, platform, services, transactions.
- `Nightfall.App` — WPF shell (non-admin UI): 10 pages, view models, dialogs, activity log.
- `Nightfall.Privileged` — Elevated helper (admin-only, separate process): HMAC-verified request execution.
- `Nightfall.Core.Tests` — xUnit test suite (130 tests).

## Supported capabilities

- Dashboard with real hardware metrics (CPU, RAM, GPU, disk) and top-memory process list.
- Curated tweak catalog (gaming, privacy, explorer/usability) with exact registry targets and reversals.
- Curated service start-type changes (never touches Defender, Update, firewall, audio, network, Bluetooth, printing).
- Curated scheduled-task toggling (never touches Update, Defender, servicing, boot tasks).
- Current-user-only AppX debloat from a curated, non-protected catalog (Store, Edge, shell, Defender, etc. are protected).
- Startup folder/run backup and restore.
- Privacy, gaming profiles, power plans, resource analysis, transaction history, profile import/export, dry-run.
- Dark/light theme, sidebar, global search, review/confirm/result dialogs.

## Build, test, and run

```powershell
# Build everything
& "$env:LOCALAPPDATA\dotnet-sdk\dotnet.exe" build src/Nightfall.App/Nightfall.App.csproj

# Run the full xUnit suite
& "$env:LOCALAPPDATA\dotnet-sdk\dotnet.exe" test tests/Nightfall.Core.Tests/Nightfall.Core.Tests.csproj

# Smoke test (launches UI, loads all 10 pages, exits 0 on success)
src\Nightfall.App\bin\Debug\net9.0-windows10.0.19041.0\Nightfall.exe --smoke-test

# Screenshot automation (writes %TEMP%\nightfall-shell.png)
src\Nightfall.App\bin\Debug\net9.0-windows10.0.19041.0\Nightfall.exe --screenshot %TEMP%\nightfall-shell.png
```

## Documentation

- `SECURITY.md` — security model, elevation protocol, allowlist boundaries.
- `COMPATIBILITY.md` — OS/edition/build compatibility matrix.
- `ARCHITECTURE.md` — project structure, transaction lifecycle, data flow.
- `RELEASE_CHECKLIST.md` — pre-release verification items.

## Documented limitations (honest scope)

- **Non-admin session:** machine-scope changes, helper execution, restore points, and AppX removal cannot be end-to-end tested without elevation.
- **Machine-scope Run/common Startup and RunOnce:** inspect-only. Only current-user Run values may be disabled/restored.
- **AppX removal:** current-user only, from the curated catalog only, not automatically reversible (reinstall from Store).
- **Restore point:** only attempted when elevated; failure is a warning, never a fabricated success.
- **No arbitrary registry writes, no bulk service disabling, no uncurated AppX removal.**
- **Windows Server:** not offered.
- **All dotnet commands require `%LOCALAPPDATA%\dotnet-sdk\dotnet.exe`.**
