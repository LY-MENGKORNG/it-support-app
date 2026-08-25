export const ROLES = ["employee", "staff", "admin"] as const

export type Role = typeof ROLES[number]

export * from "./request"
export * from "./request-history"
