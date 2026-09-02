import { describe, expect, it } from 'bun:test';
import { isError, safeTry } from './exception';

type Msg = { msg: string };

function unsafeParse(str: string): Msg {
  return JSON.parse(str) as Msg;
}

/**
 * Stands in for a thenable that is not a real promise, which is what drizzle's
 * query builders are: `instanceof Promise` is false for them.
 */
class FakeQuery<T> implements PromiseLike<T> {
  constructor(private readonly source: Promise<T>) {}

  // oxlint-disable-next-line unicorn/no-thenable -- being a thenable is the point
  then<R1 = T, R2 = never>(
    onFulfilled?: ((value: T) => R1 | PromiseLike<R1>) | null,
    onRejected?: ((reason: unknown) => R2 | PromiseLike<R2>) | null,
  ): PromiseLike<R1 | R2> {
    return this.source.then(onFulfilled, onRejected);
  }
}

describe('Exception', () => {
  describe('safeTry', () => {
    describe('normal function', () => {
      it('should handle non-promise function correctly', () => {
        const result = safeTry(() => unsafeParse('{"msg": "hi mom"}'));
        expect(result).not.toBeInstanceOf(Error);
        if (!(result instanceof Error)) {
          expect(result).toEqual({ msg: 'hi mom' });
        }
      });

      it('should return the error instead of throwing', () => {
        const result = safeTry(() => unsafeParse('not json at all'));
        expect(result).toBeInstanceOf(SyntaxError);
      });

      it('should stay synchronous', () => {
        const result = safeTry(() => 'no await needed');
        expect(result).not.toBeInstanceOf(Promise);
        expect(result).toBe('no await needed');
      });

      it('should wrap a thrown non-error so isError stays reliable', () => {
        const result = safeTry(() => {
          throw 'just a string';
        });
        expect(isError(result)).toBe(true);
        expect(result.message).toBe('just a string');
        expect(result.cause).toBe('just a string');
      });
    });

    describe('async function', () => {
      it('should resolve to the value', async () => {
        // oxlint-disable-next-line typescript/require-await -- subject is the `async` declaration
        const result = await safeTry(async () =>
          unsafeParse('{"msg": "hi mom"}'),
        );
        expect(result).toEqual({ msg: 'hi mom' });
      });

      it('should resolve to the rejection reason', async () => {
        // oxlint-disable-next-line typescript/require-await -- subject is the `async` declaration
        const result = await safeTry(async () => {
          throw new Error('async boom');
        });
        expect(isError(result)).toBe(true);
        expect(result.message).toBe('async boom');
      });
    });

    describe('function returning a promise', () => {
      it('should resolve to the value', async () => {
        const result = await safeTry(() =>
          Promise.resolve(unsafeParse('{"msg": "hi mom"}')),
        );
        expect(result).toEqual({ msg: 'hi mom' });
      });

      // Regression: a function that is not declared `async` used to skip the
      // promise branch, so the rejection escaped as an unhandled rejection.
      it('should catch the rejection rather than leaving it unhandled', async () => {
        const result = await safeTry(() => Promise.reject(new Error('boom')));
        expect(isError(result)).toBe(true);
        expect(result.message).toBe('boom');
      });
    });

    describe('promise', () => {
      it('should resolve to the value', async () => {
        const result = await safeTry(
          Promise.resolve(unsafeParse('{"msg": "hi mom"}')),
        );
        expect(result).toEqual({ msg: 'hi mom' });
      });

      it('should resolve to the rejection reason', async () => {
        const result = await safeTry(Promise.reject(new Error('rejected')));
        expect(isError(result)).toBe(true);
        expect(result.message).toBe('rejected');
      });

      // Regression: `instanceof Promise` is false for these, so they fell
      // through to being called as a function and came back as a TypeError.
      it('should handle a thenable that is not a real promise', async () => {
        const result = await safeTry(
          new FakeQuery(Promise.resolve({ msg: 'from thenable' })),
        );
        expect(result).toEqual({ msg: 'from thenable' });
      });

      it('should handle a rejecting thenable', async () => {
        const result = await safeTry(
          new FakeQuery(Promise.reject(new Error('db down'))),
        );
        expect(isError(result)).toBe(true);
        expect(result.message).toBe('db down');
      });
    });
  });

  describe('isError', () => {
    it('should tell errors and values apart', () => {
      expect(isError(safeTry(() => unsafeParse('nope')))).toBe(true);
      expect(isError(safeTry(() => unsafeParse('{"msg": "ok"}')))).toBe(false);
    });

    // Narrowing is the point of the type predicate: `result.msg` below only
    // compiles because the guard removed `Error` from the union.
    it('should narrow the result to the value', () => {
      const result = safeTry(() => unsafeParse('{"msg": "hi mom"}'));
      if (isError(result)) throw result;
      expect(result.msg).toBe('hi mom');
    });
  });
});
