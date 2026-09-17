type StrParse<T> = (input: string) => T;
type StrOf<T> = T;

type Unsafe<T> = SyncFn<T> | AsyncFn<T> | PromiseLike<T>;
type SyncFn<T> = () => T;
type AsyncFn<T> = () => Promise<T>;
