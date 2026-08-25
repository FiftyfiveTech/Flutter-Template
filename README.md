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

## Documentation-First Workflow (Read This Before You Start Building)

This template ships with **fill-in-the-blank docs, not finished ones** — `docs/architecture.md`,
`docs/features/`, and `docs/screen_flow.md` are scaffolds for *your* project's specifics, and
`docs/ai_workflow.md` is the playbook (with copy-paste prompts) for filling them in with an AI
coding assistant instead of skipping straight to code. New to the template? Start here, in order:

1. **`docs/ai_workflow.md`** — the full 8-step loop (design tokens → PRD/feature breakdown →
   screens → architecture docs → `CLAUDE.md` rules → equip skills → flow-by-flow build → audit),
   with a reusable prompt for each step. Read this first — the order below follows that loop.
2. **`docs/design_systems/tokens/`** — generate or import your color/typography/spacing tokens
   before creating any screens (loop step 1).
3. **`docs/features/`** — add one spec file per feature area, following the shape in
   `00-sample-feature.md`, and list each one in `index.md` (loop step 2).
4. **`docs/screen_flow.md`** — keep a running index of every screen: its ID, route, and which
   feature it belongs to (see the two sample rows already there) (loop step 3).
5. **`docs/architecture.md`** — fill in §1 (Project Overview) and §2 (Technology Stack — e.g.
   which backend: REST, Firebase, or both), then detail schemas/network paths now that your
   features and screens exist (loop step 4). §3 onward already describes this template's
   conventions (folder structure, error handling, testing, Definition of Done).
6. **`CLAUDE.md`** — already encodes this template's non-negotiable architecture rules; update it
   as your project's own rules solidify, and every time you add a `.claude/skills/` entry (loop
   step 5).

Once those docs reflect your actual project, the `.claude/commands/` and `.claude/skills/` in this
repo will read them (not just infer from code) when scaffolding new features.

Reference doc, read as needed rather than up front: **`docs/local_storage.md`** — where the local
Drift database is initialized, which files own which part of it, and what's involved in swapping
it for a different local storage plugin.

---

## Getting Started

### 0. Generate Platform Folders
This template ships as `lib/`/`test/` only — no `android/`, `ios/`, etc. are committed. Before the
first run, generate them from inside this directory:
```bash
flutter create .
```
This scaffolds the platform runners around the existing `lib/` without touching your source.

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

### 4. Configure Firebase (only if using the Firestore backend)
If you plan to use the Firebase datasource path (see "Swapping Backends" below), run
`flutterfire configure` to generate `lib/firebase_options.dart`, then initialize it in `main.dart`
before `runApp`:
```dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```
Skip this step entirely if you're only using the REST/Dio path.

### 5. Run the App
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
