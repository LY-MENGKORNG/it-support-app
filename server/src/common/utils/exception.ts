/**
 * NOTE: argument types:
 *   - the actual promise
 *   - regular function
 *   - function that return a promise
 */

import { isAsyncFunction } from 'util/types';

type Fn<T> = (...args: any[]) => T;
type AsyncFn<T> = (...args: any[]) => Promise<T>;

export type Unsafe<T> = Fn<T> | AsyncFn<T> | Promise<T>;
export type Result<T, E> = (T | E) | Promise<T | E>;

export function safeTry<T, E = Error>(unsafe: Unsafe<T>): Result<T, E> {
  if (unsafe instanceof Promise) {
    return unsafe.then((v) => v).catch((e) => e as E);
  }

  if (isAsyncFunction(unsafe)) {
    return safeTry(unsafe() as Promise<T>);
  }

  try {
    return unsafe();
  } catch (e) {
    return e as E;
  }
}

export const isError = <T, E = Error>(result: Result<T, E>) =>
  result instanceof Error;
