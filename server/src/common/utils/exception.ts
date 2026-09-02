type SyncFn<T> = () => T;
type AsyncFn<T> = () => Promise<T>;

export type Unsafe<T> = SyncFn<T> | AsyncFn<T> | PromiseLike<T>;

/** Either the value or the error, but not both! */
export type Result<T, E = Error> = T | E;

export type SafeResult<R, E = Error> = [R] extends [never]
  ? Result<never, E>
  : R extends PromiseLike<infer U>
  ? Promise<Result<U, E>>
  : Result<R, E>;

/** Promises are not the only thenables: drizzle's query builders are too. */
function isThenable(value: unknown): value is PromiseLike<unknown> {
  return (
    typeof (value as PromiseLike<unknown> | null | undefined)?.then ===
    'function'
  );
}

export function safeTry<T, E = Error>(
  unsafe: PromiseLike<T>,
): Promise<Result<T, E>>;
export function safeTry<R, E = Error>(unsafe: SyncFn<R>): SafeResult<R, E>;
export function safeTry<T, E = Error>(unsafe: Unsafe<T>): unknown {
  // Already a promise (or a thenable), so only attach the catch.
  if (isThenable(unsafe)) {
    return Promise.resolve(unsafe).catch((e) => toError(e) as E);
  }

  try {
    const value = unsafe();

    // Covers both `async` functions and plain functions.
    if (isThenable(value)) {
      return Promise.resolve(value).catch((e) => toError(e) as E);
    }
    return value;
  } catch (e) {
    // try-catch for unsafe synchronous functions.
    return toError(e) as E;
  }
}

export function isError<T>(result: T): result is Extract<T, Error> {
  return result instanceof Error;
}

/** `throw` accepts any value, but this module's contract is `Error`. */
function toError(e: unknown): Error {
  return e instanceof Error ? e : new Error(String(e), { cause: e });
}
