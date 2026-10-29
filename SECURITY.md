# NIGHTFALL Security Model

This document describes how NIGHTFALL prevents unauthorized or accidental system changes. It is intended for security reviewers and anyone auditing the application's trust boundaries.

## Core principle

**The UI process is never elevated.** `Nightfall.App` runs as a standard user (`asInvoker`). Any operation that requires administrative rights (machine-scope registry, services, scheduled tasks, power plans, AppX removal, restore points) is routed to a separate elevated helper, `Nightfall.Privileged.exe`, which only accepts requests that pass every check below.

## Elevation protocol

### Request envelope

Every helper request is a JSON envelope written by the UI and consumed by the helper:

- `schema` — protocol version (`nightfall.elevation/1`), rejected if unsupported.
- `requestId` — cryptographically random request identifier; shape-validated.
- `nonce` — cryptographically random nonce; shape-validated.
- `createdUtc / expiresUtc` — request lifetime window.
- `userName / userSid / machineName` — identity binding.
- `appVersion` — the UI version that issued the request.
- `action` — `Apply` or `Rollback`.
- `plan / transactionId` — the operation plan being authorized.
- `forceRollback` — whether rollback should ignore external-change conflicts.

### Signature & integrity

- The payload is HMAC-SHA256 signed with a per-user key derived via DPAPI (`DataProtectionScope.CurrentUser`) and stored at `%LOCALAPPDATA%\Nightfall\elevation\elevation.key`.
- The key is created on first use and is stable across calls (32 bytes).
- The helper verifies the HMAC before processing. Tampered payloads, wrong keys, malformed signatures, missing files, and unsupported schemas are all rejected (`UnauthorizedAccessException`, `InvalidDataException`, `FileNotFoundException`).
- Request files are moved into a `consumed/` audit folder before execution to prevent replay.

### Time & identity limits

- Maximum request lifetime: 15 minutes.
- Future tolerance: 2 minutes (a request created more than 2 minutes in the future is rejected).
- Requests bind to the exact user name, user SID, and machine name of the issuing UI process.

### Allowlist boundary

The elevated helper does not accept arbitrary registry writes, service names, task edits, power schemes, or package removals. Every operation must match a reviewed catalog target and the supported privilege scope:

- **HKCU tweaks** → current-user scope, no admin required; only reviewed option values accepted.
- **Machine-scope Run/common Startup / RunOnce** → inspect-only; never offered to profiles.
- **Services** → protected services (Defender, Update, firewall, audio, network, Bluetooth, printing, boot, RPC, etc.) are never toggled. Only curated non-protected services.
- **Scheduled tasks** → curated Microsoft tasks only; Update/Defender/servicing/boot tasks are absent.
- **AppX removal** → current-user only, curated non-protected catalog, non-reversible, never machine-wide.

## Transaction safety

The central engine (`TransactionEngine`) enforces:

1. **Preview → review → back up → apply → verify → log → automatic rollback.** Nothing is applied without an exact before-state.
2. **Before-state capture + journal read-back.** The journal is written and read back from disk before any write; if read-back fails, the transaction is aborted with zero writes.
3. **Verification after apply.** If verification fails, the change is rolled back automatically. If another program changed the value after verification, rollback is refused and `RecoveryRequired` is reported (manual intervention needed).
4. **Machine-scope changes run only in the elevated helper.** The engine refuses them in an unelevated process.
5. **Irreversible operations (AppX removal) require explicit consent** (`AllowIrreversible = true` in execution options).

## Boundaries explicitly NOT enforced by NIGHTFALL

NIGHTFALL does not disable, bypass, or weaken: Windows Defender, Windows Update, the firewall, networking, audio, printing, Bluetooth, accessibility, the task scheduler core, or Windows Server installations. These are protected by policy and by the allowlist.
