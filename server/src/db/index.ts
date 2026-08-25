import { drizzle } from "drizzle-orm/bun-sqlite"
import { Database } from "bun:sqlite";
import { relations } from "./relations"

const client = new Database("server.db")
export const db = drizzle({ client, relations })

