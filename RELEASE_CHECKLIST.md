# NIGHTFALL Release Checklist

This checklist must be completed before any release. Items marked [ADMIN] require an elevated/admin session and cannot be verified from a non-admin account.

## Build

- [ ] `dotnet build src/Nightfall.App/Nightfall.App.csproj` → 0 warnings, 0 errors.
- [ ] `Nightfall.Privileged.exe` present at `<app>\Helper\Nightfall.Privileged.exe`.
- [ ] Target framework `net9.0-windows10.0.19041.0`; SDK at `%LOCALAPPDATA%\dotnet-sdk\dotnet.exe`.

## Tests

- [ ] `dotnet test tests/Nightfall.Core.Tests/Nightfall.Core.Tests.csproj` → all tests pass (130/130), 0 failures.
- [ ] No `UnitTest1.cs` or `Class1.cs` template leftovers remain.
- [ ] `dotnet build` and `dotnet test` run from a clean checkout.

## Smoke test (UI automation)

- [ ] `Nightfall.exe --smoke-test` → ExitCode 0, `RESULT: PASS`.
- [ ] All 10 pages load without exception: dashboard, debloat, services, startup, tweaks, gaming, resources, profiles, history, settings.
- [ ] `Nightfall.exe --screenshot %TEMP%\nightfall-shell.png` → PNG produced, dashboard populated with real data.
- [ ] `%TEMP%\nightfall-automation.log` shows "Helper present: True" and no "ERROR" page entries.
- [ ] `%LOCALAPPDATA%\Nightfall\logs\crash.log` has no entries.

## Documented limitations (verify these are stated)

- [ ] Non-admin session: machine-scope changes, helper execution, restore points, AppX removal not end-to-end tested.
- [ ] Machine-scope Run/common Startup / RunOnce: inspect-only.
- [ ] AppX removal: current-user only, curated catalog, not automatically reversible.
- [ ] Restore point: attempted only when elevated; failure is a warning, never a fabricated success.
- [ ] No arbitrary registry writes, no bulk service disabling, no uncurated AppX removal.
- [ ] Windows Server: not offered.

## Documentation

- [ ] `README.md` — build/test/run instructions, stack, limitations.
- [ ] `SECURITY.md` — elevation protocol, allowlist boundaries, transaction safety.
- [ ] `COMPATIBILITY.md` — OS/edition/build matrix, protected components.
- [ ] `ARCHITECTURE.md` — project structure, transaction lifecycle, data flow.
- [ ] `RELEASE_CHECKLIST.md` — this file.

## Publish

- [ ] Publish script written and reviewed.
- [ ] Release artifacts identified (Nightfall.App binaries, Nightfall.Privileged helper).
- [ ] Admin-required steps flagged in release notes.
