# Flutter Clean Architecture Starter Template

A production-grade, highly structured, and swap-friendly Flutter starter template. It is designed to work seamlessly with AI coding assistants (like Claude Code and Antigravity) to enable fast, clean, and error-free development.

## Key Features
* **Clean Architecture**: Out-of-the-box Presentation, Domain, and Data layer isolation per feature.
* **State Management**: Riverpod (code-generation flavor) for clean dependency injection and reactive state.
* **Local Database**: Drift (SQLite) setup for local caching and offline storage.
* **REST & Firebase Ready**: Includes a generic `Dio` client wrapper for HTTP REST endpoints and setup for Cloud Firestore remote data mapping.
* **Modular Sync Queue**: An optional outbox-pattern background synchronization engine.
* **AI-Assisted Scaffolding**: Pre-packaged `.claude/` commands for auto-generating features, models, screens, and tests.

---

## Getting Started

### 1. Rename the Package
Run a search and replace across the workspace for `flutter_app_template` to rename it to your preferred Dart package name.
Additionally, rename the bundle identifiers/application IDs in the platform folders (Android `build.gradle`, iOS `Info.plist`).

### 2. Install Dependencies
Run from the root directory:
```bash
flutter pub get
```

### 3. Generate Code
Generate Drift databases and Riverpod notifier codes:
```bash
dart run build_runner build --delete-conflicting-outputs
```

### 4. Run the App
```bash
flutter run
```

---

## Swapping Backends

By default, the template comes with dual-datasource implementations under the sample feature:
* **Dio Client (REST)**: Handles standard JSON communication with REST endpoints.
* **Firestore (Firebase)**: Writes directly to collections in the cloud.

To switch which backend your feature uses, modify the dependency injection binding:
1. Open the remote datasource provider (e.g. `lib/features/sample_counter/presentation/controllers/counter_controller.dart`).
2. Swap the return type binding of the remote datasource provider:
   ```dart
   @riverpod
   CounterRemoteDatasource counterRemoteDatasource(Ref ref) {
     // REST Client Datasource:
     return CounterRestDatasource(ref.watch(baseApiClientProvider));
     
     // Firebase/Firestore Datasource:
     // return CounterFirebaseDatasource(FirebaseFirestore.instance);
   }
   ```

No domain entities, repository contracts, or UI pages require any modifications.

---

## Data Synchronization Strategy
Three data strategies are documented in `counter_repository_impl.dart`:
* **Strategy A (Direct Remote)**: Default. Writes directly to the server and updates cache on success. Highly recommended for standard CRUD.
* **Strategy B (Offline-Only)**: Only writes to the local SQLite/Drift database.
* **Strategy C (Outbox Sync)**: Writes instantly to local Drift (optimistic update), queues a task in `syncQueueEntries`, and processes it in the background when connectivity returns.

The outbox sync components reside in `lib/core/sync/` and are fully modular—delete them if your project only requires direct reads and writes.

---

## Tooling & Prompt playbooks
Check the `docs/ai_workflow.md` playbook for the complete 8-step playbook on using Claude/Antigravity design tools, prompts, and skills to build screens and features.
