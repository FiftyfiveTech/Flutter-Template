# Host App — Feature Specification Index

The Host App is a **separate cross-platform mobile app** from the End-User App (PRD §2), sharing only the backend. Host features are kept in this subfolder, and independently numbered, so they are never scaffolded into the End-User app's `lib/features/` namespace — a Host feature must import only the domain-layer interfaces of End-User/Admin features it depends on, never their `presentation/` or `data/` internals (and vice versa).

## Host App Modules
1. [Host Onboarding & Licence Verification](./01-host-onboarding.md) — host_type-conditional documents, excise/FSSAI expiry tracking.
2. [Host Event Creation & Publishing](./02-host-event-publishing.md) — event form, draft→submit→published lifecycle, edit-lock rules.
3. [Host Night Operations](./03-host-night-operations.md) — live dashboard, offline-capable QR check-in, payout view.

See the [top-level feature index](../index.md) for the End-User App and Admin & Platform feature areas this app depends on.
