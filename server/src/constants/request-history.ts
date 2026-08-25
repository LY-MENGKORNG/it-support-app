export const REQUEST_HISTORY_STATUS = [
  "created",
  "status_changed",
  "priority_changed",
  "assigned",
  "unassigned",
  "category_changed",
] as const

export type RequestHistoryStatus = typeof REQUEST_HISTORY_STATUS[number]
