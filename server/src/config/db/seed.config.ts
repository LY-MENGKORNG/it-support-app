#!/usr/bin/env bun

import { seed, reset } from "drizzle-seed";
import { schema } from "./relation.config";
import { db } from "./db.config";

console.log("hi mom")
const defaultPassword = "admin-123";

function hashPassword() {
  return Bun.password.hash(defaultPassword)
}

async function main() {
  try {
    await reset(db, schema);

    await seed(db, schema).refine(async (f) => ({
      user: {
        columns: {
          password_hash: await hashPassword()
        }
      }
    }))
  } catch (e) {
    console.error(e)

  }

}

main();
