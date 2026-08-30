export const PRIORITY = ['low', 'medium', 'high', 'critical'] as const;
export type Priority = (typeof PRIORITY)[number];

export const REQUEST_STATUS = [
  'open',
  'in_progress',
  'resolved',
  'closed',
] as const;
export type RequestStatus = (typeof REQUEST_STATUS)[number];
