# domain

The shapes the rest of the app agrees on: an IT support request, the people
attached to it, and the small set of enums that decide what may happen to it
next. Everything here is plain Dart — no Flutter, no HTTP, no storage. The
models import each other, `json_annotation`, and `utils/json.dart`, and nothing
else. That is the layer's one hard rule, and it is what lets `data/` and `ui/`
both depend on these types without depending on each other.

Read this layer as the answer to "what is a request, and what is true about
one" — `data/` answers where it came from, `ui/` answers how it looks.

## What lives here

`models/` holds three kinds of thing that happen to share a folder:

**Records read from the API.** `Request`, `RequestDetail`, `RequestPage`,
`User`, `Comment`, `RequestHistory`, `RequestCategory`, `Session`. They are
immutable, `const`-constructible, and decode-only (`createToJson: false`) —
nothing sends one of these back, so generating an encoder would only invite
someone to try.

**Values written to the API.** `NewRequest` and `RequestPatch` are the mirror
image: encode-only, and deliberately not the same class as `Request`. A
creation body carries a `categoryId`, not a `RequestCategory`; a patch carries
whichever fields changed. Collapsing all three into one class would mean a pile
of nullable fields whose legal combinations only the server knows.

**Enums and query values.** `Priority`, `RequestStatus`, `UserRole`,
`RequestHistoryAction`, `RequestSort`, and the `RequestFilters` that a list
screen turns into a query string.

`models/generated/` is build output — `dart run build_runner build`. Never edit
it by hand. It sits in its own folder rather than beside each model, and
[build.yaml](../../build.yaml) explains what that costs you when you add a
model somewhere else.

## Behavior belongs on the model

These are not bags of fields. When a rule is a fact about the data rather than
a fact about a screen, it lives here, so every caller gets the same answer:

- `RequestStatus.nextOptions` — the legal transitions out of a status. The
  status-change UI renders this list rather than hard-coding one, which is why
  the workflow is defined once instead of once per menu.
- `RequestStatus.isSettled`, `UserRole.isSupportStaff`, `Request.isAssigned` —
  named predicates instead of comparisons scattered through widgets. Adding a
  fourth role only breaks one place.
- `Priority.rank` — an explicit ordering, because declaration order is not a
  promise, and a sort needs one.
- `User.initials` — an avatar fallback. Presentation-adjacent, but derived
  purely from the name, so it is the model's business.
- `label` on every enum — the human-readable spelling, kept next to the value
  it names.

## Wire enums

The API spells things `in_progress` where Dart spells them `inProgress`, so
`values.byName` throws. Every enum here implements `WireEnum` and carries its
own wire string, looked up through `byWire`/`tryByWire` in
[utils/json.dart](../utils/json.dart). Each also gets a small `WireConverter`
subclass so the generated decoders can use it.

The pattern matters more than any one enum: the wire spelling is a fact about
the API, and it is written down exactly once, in the enum that owns it. A bad
payload fails with `Unknown request status: foo` at the parse boundary rather
than turning into a null that surfaces three screens later.

Dates follow the same idea. `@LocalDateTime` parses ISO-8601 UTC and converts
to local time on the way in; the comment on it explains why skipping the
`toLocal()` silently breaks equality.

## Two shapes worth knowing about

`RequestDetail` reads its `request` from the *whole* payload, not from a
`request` key — the detail endpoint returns a request's fields flat, alongside
`comments` and `history`. The `readValue` hook absorbs that so callers still
get a proper `Request`.

`RequestPatch.toJson` is hand-written because absent and null mean different
things in a PATCH body. An omitted key means "leave this alone", so clearing an
assignee has to send an explicit `null` — one field that must survive
serialization while every other unset field stays out. `includeIfNull` is
all-or-nothing and cannot express that.

Both carry the same reasoning inline. When you hit something odd here, the
comment above it is the explanation.

## Adding a model

1. Write the class in `models/`, `const` constructor, `final` fields.
2. Annotate it `@JsonSerializable(checked: true, createToJson: false)` — for a
   read model — and add `part 'generated/<name>.g.dart';`.
3. For a new enum, implement `WireEnum` and add its `WireConverter`.
4. Run `dart run build_runner build --delete-conflicting-outputs`.
5. Keep it Flutter-free. If a model needs `package:flutter`, the thing you are
   modelling is a view concern and belongs in `ui/`.
