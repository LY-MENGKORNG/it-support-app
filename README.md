# IT Support App

An internal IT support app: employees submit problems or service requests, IT
staff triage, assign, comment and resolve them.

```
it-support-app/
├── server/   NestJS + Drizzle + SQLite, run on Bun
└── client/   Flutter
```

---

## Running it

Two terminals. **The server must be running before the app starts** — the app
has no offline mode.

### 1. Server

```bash
cd server
bun install
bun run db:migrate   # create / update the SQLite schema
bun run db:seed      # ~54 realistic requests, 20 people, 8 categories
bun run start:dev    # http://localhost:3000
```

Every seeded account uses the password `password-123`. Re-running `db:seed`
wipes and rebuilds the data, and is deterministic — you get the same database
each time. Note that some seeded accounts are deactivated on purpose and cannot
sign in.

Access tokens are signed with `JWT_SECRET`, which falls back to a value
committed in `config/env.config.ts` for local work. **The server refuses to
start in production without a real one:**

```bash
JWT_SECRET=$(openssl rand -base64 32) NODE_ENV=production bun run start:prod
```

### 2. Client

```bash
cd client
flutter pub get
flutter run
```

Sign in with any active seeded account and the password `password-123`. The
access token is stored on the device with `shared_preferences` and sent as a
bearer token on every request; the server derives the requester and actor from
it. Sign out under **Settings → Sign out**.

The base URL is chosen in `ApiClient.defaultBaseUrl`: `10.0.2.2` on an Android
emulator (the emulator's alias for the host machine), `localhost` everywhere
else. Override it for a physical device:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:3000
```

---

## API

Interactive docs are served at **http://localhost:3000/api** once the server is
running, with the raw OpenAPI spec at `/api-json`.

Every route needs an `Authorization: Bearer <token>` header except
`POST /auth/login`.

`GET /request` accepts `q` (searches title and description), `status`,
`priority`, `categoryId`, `requesterId`, `assigneeId`, `unassigned=true`,
`sort` (`newest` | `oldest` | `priority`), `limit`, `offset`, and answers with:

```jsonc
{ "items": [...], "total": 54, "limit": 20, "offset": 0, "hasMore": true }
```

---

## Tests

```bash
cd client && flutter test    # enums, models, API layer, session, view models, widgets
cd server && bun run test    # service-level rules, with no database in sight
```

The repository split also makes the server testable: a service can be given a
fake repository with no database in sight.

The client's API tests run the real `ApiClient`, services and repositories over
`MockClient`, so URL building, status handling and JSON parsing are covered
together without touching the network.

---

## Project layout

### Server

```
src/
├── common/          constants, zod pipe, SQLite exception filter, HTTP logger
├── config/          env, drizzle config, docs (Swagger), db client + relations, seed
└── modules/
    ├── auth/        auth.schema.ts       ← zod DTOs + the token payload
    │                auth.guard.ts        ← the global gate on every route
    │                auth.decorator.ts    ← @Public, @Roles, @CurrentUser
    │                auth.service.ts      ← issues and verifies tokens
    │                auth.controller.ts
    ├── users/       user.schema.ts
    │                user.repository.ts   ← all Drizzle access
    │                user.service.ts      ← business rules
    │                user.controller.ts   ← HTTP
    │                user.module.ts
    ├── categories/
    ├── requests/
    ├── comments/
    └── request-histories/
```

Each module owns its Drizzle table, its zod DTOs, and one file per layer.
Cross-table relations live in `config/db/relation.config.ts`.

**controller → service → repository → Drizzle**, and the boundaries are strict:

- **Repositories** are the only place that touches `db`. They take plain
  arguments, return plain rows, and return `undefined` for "not there" — they
  never throw HTTP exceptions.
- **Services** hold the rules: what a change _means_ (which edits are worth an
  audit entry), what a status _implies_ (`resolvedAt` / `closedAt`), and that a
  missing row is a `404`.
- **Controllers** parse and validate input, then delegate.

Two consequences worth knowing. `UserRepository` reads exclusively through
`publicUserColumns`, so `password_hash` cannot leak out of that file by
accident — while hashing stays in `UserService`, because it is a policy
decision. And `RequestRepository` owns the request↔history transaction: a
change and the history row describing it are written together or not at all, so
the audit trail can never drift from the record.

### Client

Follows the [official Flutter app architecture guide](https://docs.flutter.dev/app-architecture),
including the `Result` and `Command` patterns and `package:provider` for
dependency injection.

```
lib/
├── main.dart          entry point: builds the provider tree
├── app.dart           MaterialApp.router
├── config/            dependencies.dart — the whole object graph
├── routing/           routes.dart, router.dart (go_router + session guard)
├── domain/models/     the app's data types — no Flutter imports at all
├── data/
│   ├── services/      one per external source: api/api_client.dart, shared_preferences_service.dart
│   └── repositories/  <name>/<name>_repository.dart (abstract) + _remote.dart
├── ui/
│   ├── auth/          login + splash screens, and the login view model
│   ├── core/          themes/ and ui/ — shared widgets, layout breakpoints
│   └── <feature>/     view_models/ + widgets/
└── utils/             result.dart, command.dart, json.dart, date_format.dart
```

**MVVM, one ViewModel per screen.** Widgets hold no logic: they receive a
ViewModel, read its state, and call its commands.

**`Result<T>` instead of exceptions.** Dart's exceptions are unchecked — nothing
forces a caller to handle them and nothing documents which ones a function
throws. Every service and repository method returns `Ok` or `Error`, so failure
is part of the signature and a `switch` will not compile unless both cases are
handled.

**`Command` objects for actions.** Each user action (`load`, `changeStatus`,
`addComment`) is a `Command` exposing `running` / `completed` / `error`. This
replaces the hand-rolled `isLoading` + `error` field pairs that used to drift
out of sync, and a command refuses to run twice at once — so a double-tap
cannot fire two writes.

**Abstract repositories.** ViewModels depend on `RequestRepository`, not
`RequestRepositoryRemote`. Swapping the implementation — remote, local, or a
fake in a test — is a change to `config/dependencies.dart` alone.

**One adaptive shell.** `HomeShell` picks its navigation from the _window_
width, not the platform: a rail at 700px and wider, the bottom bar below it, and
labels on the rail past 1100px. The same macOS build switches as the window is
dragged, and a tablet gets the right one in each orientation without a second
code path. `ContentColumn` caps page width so a request list does not stretch
across a 27-inch monitor.

**The session and the transport are tied together in one place.** The API client
cannot own the token — that is session state, and the router has to react to it
— and the session cannot own the header, because every request needs it. So
`config/dependencies.dart` gives each a way to ask the other: the client reads
`session.accessToken` per request, and reports a 401 back by calling
`session.signOut`. That single wiring is what turns an expired token into a trip
to the login screen instead of an error on every screen at once, and it is why
no repository, view model or widget knows requests are authenticated at all.

Data flows one way: **widget → view model → repository → service → HTTP**, and
dependencies are injected top-down, so any layer can be replaced with a fake.
