# Dependencies

Registering repositories by their **abstract** type is the point: every
`context.read<RequestRepository>()` is satisfied by whichever implementation
is listed here, so swapping in a local or fake one is a change to this file
alone — no view model or widget knows the difference.

Order matters: a provider can only `read()` something declared above it.
