export * from './request-history';
export * from './request';

export const ROLES = ['employee', 'staff', 'admin'] as const;

export type Role = (typeof ROLES)[number];
