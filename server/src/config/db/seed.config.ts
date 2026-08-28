#!/usr/bin/env bun

import { seed, reset } from "drizzle-seed";
import { schema } from "./relation.config";
import { db } from "./db.config";
import { type Role } from "@common/constants";

async function main() {
  try {
    await reset(db, schema);

    const password_hash = await Bun.password.hash("admin-123")

    await seed(db, schema).refine(async (f) => {

      return {
        user: {
          columns: {
            name: f.fullName(),
            password_hash: await Bun.password.hash("admin-123"),
            role: f.valuesFromArray({ values: ["employee", "staff", "admin"] as Role[] })
          }
        }
      }
    });

  } catch (e) {
    console.error(e)

  }

}

main();
