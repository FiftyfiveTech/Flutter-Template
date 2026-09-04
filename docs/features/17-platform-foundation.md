# Feature Spec: Platform Foundation

Shared backend, auth/session, RBAC, environments, and infrastructure underlying all three surfaces (End-User App, Host App, Admin Dashboard). Source: PRD §6.

## 1. User Stories / Jobs-to-be-Done
* As the platform, I need a single shared backend service layer serving all three surfaces, so business logic (ratio gating, verification, matching) isn't duplicated per client.
* As the platform, I need Member and Host identities to be strictly separate account types with role-based access, so a Host account can never act as a Member (or vice versa) and Admin access is scoped separately again.
* As Engineering, I need dev/staging/prod environments and CI/CD pipelines with automated builds for both mobile apps, so the pilot can ship safely without testing against production payment credentials.

## 2. Data Entities & Screens
* No feature-specific entities; underlies the `User`/`HostAccount`/role-separation model every other feature builds on.
* No screens — this is the `lib/core/` infrastructure layer (network, database, DI, theme, routing).

## 3. Dependencies
* Every feature in this index depends on this layer (auth/session tokens, base API client, local database, theme tokens, RBAC).
* This layer must depend on **no** feature — it sits at the bottom of the dependency graph, per the Clean Architecture boundary rules in `docs/architecture.md`.

## 4. Safety, Security & Regulatory Constraints
* Role separation between Member, Host, and Admin identities is a security boundary — must prevent any cross-account privilege escalation (e.g., a Host session token must never grant Admin-scoped API access).
* Environment separation (dev/staging/prod) is required so pilot testing — especially payment-gateway integration — never touches production credentials or real member payment data.
* Session tokens must use secure device storage with refresh, consistent with the requirement stated in [Member Registration & Profile](./01-member-registration.md).
