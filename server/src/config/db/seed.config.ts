#!/usr/bin/env bun

/**
 * Deterministic demo data.
 *
 * The previous version only refined the `user` table, so drizzle-seed filled
 * `request.status` / `request.priority` with random strings that the enums
 * reject. Everything here is written by hand instead, because the interesting
 * part of this dataset is that it is *consistent*: a resolved request has a
 * `resolvedAt`, an assigned request has an `assigned` history row, and every
 * status change in the audit trail actually happened.
 */

import { reset } from 'drizzle-seed';
import { schema } from './relation.config';
import { db } from '.';
import { category } from '@modules/categories/category.schema';
import { comment } from '@modules/comments/comment.schema';
import { requestHistory } from '@modules/request-histories/request-history.schema';
import { request } from '@modules/requests/request.schema';
import { user } from '@modules/users/user.schema';
import type { Priority, RequestStatus, Role } from '@common/constants';

/** Seeded PRNG (mulberry32) so re-running gives the same database every time. */
function rng(seed: number) {
  return () => {
    seed = (seed + 0x6d2b79f5) | 0;
    let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

const random = rng(20260830);
const pick = <T>(items: readonly T[]): T =>
  items[Math.floor(random() * items.length)];
const chance = (probability: number) => random() < probability;
const DAY = 86_400_000;
/** A date `maxDaysAgo`..0 days in the past. */
const daysAgo = (maxDaysAgo: number) =>
  new Date(Date.now() - Math.floor(random() * maxDaysAgo * DAY));

const CATEGORIES = [
  ['Network', 'Wi-Fi, VPN, connectivity and bandwidth issues'],
  ['Hardware', 'Laptops, monitors, docks, peripherals and repairs'],
  ['Software', 'Application installs, licences, updates and crashes'],
  ['Account & Access', 'Passwords, permissions, onboarding and offboarding'],
  ['Email', 'Mailboxes, distribution lists, spam and calendar'],
  ['Printing', 'Printers, drivers, scanning and print queues'],
  ['Security', 'Phishing reports, malware, device compliance'],
  ['Other', 'Anything that does not fit the categories above'],
] as const;

const PEOPLE: readonly (readonly [string, Role])[] = [
  ['Sokha Chan', 'admin'],
  ['Dara Pich', 'admin'],
  ['Vichea Nou', 'staff'],
  ['Bopha Lim', 'staff'],
  ['Rithy Sok', 'staff'],
  ['Chanthou Kim', 'staff'],
  ['Sovann Meas', 'staff'],
  ['Malis Tep', 'employee'],
  ['Piseth Heng', 'employee'],
  ['Sreyneang Ouk', 'employee'],
  ['Kosal Vann', 'employee'],
  ['Theary Chhun', 'employee'],
  ['Samnang Ly', 'employee'],
  ['Chenda Prak', 'employee'],
  ['Visal Ros', 'employee'],
  ['Kunthea Sam', 'employee'],
  ['Ratana Yim', 'employee'],
  ['Sopheak Hor', 'employee'],
  ['Ленка Новак', 'employee'],
  ['Nisa Chea', 'employee'],
];

/** Title + description pairs, grouped by the category they belong to. */
const TICKETS: Record<string, readonly (readonly [string, string])[]> = {
  Network: [
    [
      'Laptop cannot connect to Wi-Fi',
      'My laptop stopped joining the office Wi-Fi this morning. It sees the network but fails at "obtaining IP address". Other devices connect fine.',
    ],
    [
      'VPN disconnects every few minutes',
      'The VPN client drops roughly every 5 minutes while I am working from home, which kills my SSH sessions.',
    ],
    [
      'Very slow network in meeting room 3',
      'File transfers in meeting room 3 run at about 1 Mbps. The same laptop gets 200 Mbps at my desk.',
    ],
    [
      'Cannot reach internal wiki',
      'The internal wiki times out from my machine but loads on my phone over mobile data.',
    ],
    [
      'Guest Wi-Fi password not working',
      'Visitors cannot join the guest network. The password on the poster is rejected.',
    ],
  ],
  Hardware: [
    [
      'Laptop battery drains in under an hour',
      'Battery health shows 62% and the machine dies within an hour unplugged. It is a 2022 model.',
    ],
    [
      'External monitor not detected via dock',
      'The second monitor stays black when connected through the dock. Direct HDMI works.',
    ],
    [
      'Keyboard keys not responding',
      'The E, D and C keys on my laptop keyboard only register intermittently.',
    ],
    [
      'Laptop fan constantly at full speed',
      'The fan runs at maximum even when idle and the chassis is hot to the touch.',
    ],
    [
      'Request replacement headset',
      'The microphone on my headset has stopped working during calls. Needs replacing.',
    ],
  ],
  Software: [
    [
      'Docker Desktop fails to start',
      'Docker Desktop hangs on "starting the Docker Engine" and never finishes. Reinstalling did not help.',
    ],
    [
      'Need licence for JetBrains IDE',
      'My IntelliJ licence expired yesterday and I cannot open the project.',
    ],
    [
      'Excel crashes when opening large files',
      'Excel closes without an error whenever I open the quarterly report workbook.',
    ],
    [
      'Install Node.js and Bun on new laptop',
      'New starter laptop needs the standard dev toolchain installed.',
    ],
    [
      'Slack notifications not appearing',
      'Desktop notifications stopped after the last update even though they are enabled.',
    ],
  ],
  'Account & Access': [
    [
      'Locked out after password reset',
      'I reset my password and now cannot sign in to any internal tool. It says account locked.',
    ],
    [
      'Need access to finance shared drive',
      'Starting on the budget project and need read access to the finance share.',
    ],
    [
      'MFA device lost',
      'I replaced my phone and no longer have the authenticator codes for my account.',
    ],
    [
      'Offboard departing contractor',
      'Contractor finishes on Friday, all access should be revoked at end of day.',
    ],
    [
      'New starter account setup',
      'New designer joins Monday and needs email, Slack and Figma access.',
    ],
  ],
  Email: [
    [
      'Not receiving external emails',
      'Internal mail arrives fine but nothing from outside the company since yesterday afternoon.',
    ],
    [
      'Mailbox is full',
      'I cannot send mail; the client reports the mailbox has exceeded its quota.',
    ],
    [
      'Add me to the support distribution list',
      'I should be receiving mail sent to support@ but I am not on the list.',
    ],
    [
      'Calendar invites showing wrong timezone',
      'Invites I send appear an hour off for recipients in Bangkok.',
    ],
    [
      'Suspicious attachment in inbox',
      'Received an invoice attachment from an unknown sender. Not opened, reporting it.',
    ],
  ],
  Printing: [
    [
      'Printer on 2nd floor jams constantly',
      'The floor printer jams on almost every job, usually in the lower tray.',
    ],
    [
      'Cannot print from personal laptop',
      'The office printer does not appear when I try to add it on my laptop.',
    ],
    [
      'Scanner not sending to email',
      'Scanning to email fails silently; nothing arrives and the panel shows no error.',
    ],
    [
      'Toner replacement needed',
      'The colour printer is reporting low magenta toner.',
    ],
  ],
  Security: [
    [
      'Phishing email reported',
      'Received a message impersonating the CEO asking for gift card purchases. Forwarding for review.',
    ],
    [
      'Antivirus flagged a file',
      'The endpoint agent quarantined a file from a vendor download. Need it reviewed.',
    ],
    [
      'Laptop stolen from car',
      'My work laptop was stolen last night. It was locked and encrypted.',
    ],
    [
      'Unrecognised login alert',
      'Got an alert about a sign-in from a country I have never visited.',
    ],
  ],
  Other: [
    [
      'Desk phone has no dial tone',
      'The handset at desk 41 has no dial tone. Cable appears seated correctly.',
    ],
    [
      'Meeting room screen has no signal',
      'The display in the small meeting room shows "no signal" from every input.',
    ],
    [
      'Request second monitor',
      'Would like a second monitor to make code review easier.',
    ],
  ],
};

const COMMENTS = {
  triage: [
    'Thanks for reporting — taking a look now.',
    'Picking this up, I will update shortly.',
    'Could you confirm the asset tag on the device?',
    'Reproduced on my side, investigating.',
    'Assigning to myself, this looks related to last week s change.',
  ],
  progress: [
    'Reset the config and asked the user to retry.',
    'Escalated to the vendor, waiting on their response.',
    'Replacement part has been ordered, ETA two days.',
    'Applied the workaround for now, permanent fix to follow.',
    'Still not reproducible remotely — will visit the desk this afternoon.',
  ],
  resolution: [
    'Fixed, please confirm it is working on your side.',
    'Replaced the unit and verified it works.',
    'Root cause was a stale DHCP lease. Cleared and confirmed.',
    'Access has been granted, you should see it after signing out and in.',
    'Closing this out, thanks for your patience.',
  ],
  reply: [
    'Confirmed working, thank you!',
    'That did the trick, appreciate the quick turnaround.',
    'Still seeing the issue occasionally, but much better.',
    'Thanks — all good now.',
  ],
} as const;

const PRIORITIES: readonly Priority[] = ['low', 'medium', 'high', 'critical'];
/** Weighted so most tickets are ordinary and criticals stay rare. */
const PRIORITY_POOL: readonly Priority[] = [
  'low',
  'low',
  'medium',
  'medium',
  'medium',
  'medium',
  'high',
  'high',
  'critical',
];
const STATUS_POOL: readonly RequestStatus[] = [
  'open',
  'open',
  'open',
  'in_progress',
  'in_progress',
  'resolved',
  'resolved',
  'closed',
];

async function main() {
  console.log('resetting…');
  await reset(db, schema);

  const passwordHash = await Bun.password.hash('password-123');

  const categories = await db
    .insert(category)
    .values(
      CATEGORIES.map(([name, description]) => ({
        name,
        description,
        createdAt: daysAgo(400),
      })),
    )
    .returning();
  console.log(`categories: ${categories.length}`);

  const users = await db
    .insert(user)
    .values(
      PEOPLE.map(([name, role], index) => ({
        name,
        // Deterministic and collision-free, unlike a random email generator.
        email: `${name.toLowerCase().replace(/[^a-z]+/g, '.') || `user${index}`}${index}@example.com`,
        password_hash: passwordHash,
        role,
        isActive: role === 'employee' ? !chance(0.1) : true,
        createdAt: daysAgo(500),
      })),
    )
    .returning();
  console.log(`users: ${users.length}`);

  const staff = users.filter((u) => u.role !== 'employee');
  const employees = users.filter((u) => u.role === 'employee');
  const categoryByName = new Map(categories.map((c) => [c.name, c]));

  let requestCount = 0;
  let commentCount = 0;
  let historyCount = 0;

  for (const [categoryName, tickets] of Object.entries(TICKETS)) {
    const cat = categoryByName.get(categoryName)!;

    for (const [title, description] of tickets) {
      // Each ticket template is used a couple of times so the list is long
      // enough to page and filter through.
      const copies = 1 + Math.floor(random() * 2);

      for (let copy = 0; copy < copies; copy++) {
        const status = pick(STATUS_POOL);
        const priority = pick(PRIORITY_POOL);
        const requester = pick(employees);
        const isOpen = status === 'open';
        // An open ticket may still be unassigned; anything further along is not.
        const assignee = isOpen && chance(0.5) ? null : pick(staff);

        const createdAt = daysAgo(90);
        const resolvedAt =
          status === 'resolved' || status === 'closed'
            ? new Date(
              createdAt.getTime() + Math.floor(random() * 5 * DAY) + 3600_000,
            )
            : null;
        const closedAt =
          status === 'closed'
            ? new Date(
              resolvedAt!.getTime() +
              Math.floor(random() * 3 * DAY) +
              3600_000,
            )
            : null;
        const updatedAt = closedAt ?? resolvedAt ?? createdAt;

        const created = db
          .insert(request)
          .values({
            title,
            description,
            categoryId: cat.id,
            priority,
            status,
            requesterId: requester.id,
            assigneeId: assignee?.id ?? null,
            createdAt,
            updatedAt,
            resolvedAt,
            closedAt,
          })
          .returning()
          .get();
        requestCount++;

        // --- audit trail, in the order the events would really have happened
        const history: (typeof requestHistory.$inferInsert)[] = [
          {
            requestId: created.id,
            userId: requester.id,
            action: 'created',
            oldValue: null,
            newValue: 'open',
            createdAt,
          },
        ];
        const stamp = (offsetDays: number) =>
          new Date(createdAt.getTime() + offsetDays * DAY);

        if (assignee) {
          history.push({
            requestId: created.id,
            userId: assignee.id,
            action: 'assigned',
            oldValue: null,
            newValue: String(assignee.id),
            createdAt: stamp(0.2),
          });
        }
        if (status !== 'open') {
          history.push({
            requestId: created.id,
            userId: (assignee ?? pick(staff)).id,
            action: 'status_changed',
            oldValue: 'open',
            newValue: 'in_progress',
            createdAt: stamp(0.4),
          });
        }
        if (status === 'resolved' || status === 'closed') {
          history.push({
            requestId: created.id,
            userId: (assignee ?? pick(staff)).id,
            action: 'status_changed',
            oldValue: 'in_progress',
            newValue: 'resolved',
            createdAt: resolvedAt!,
          });
        }
        if (status === 'closed') {
          history.push({
            requestId: created.id,
            userId: requester.id,
            action: 'status_changed',
            oldValue: 'resolved',
            newValue: 'closed',
            createdAt: closedAt!,
          });
        }
        // An occasional priority bump, so that action shows up in the UI too.
        if (chance(0.2)) {
          history.push({
            requestId: created.id,
            userId: (assignee ?? pick(staff)).id,
            action: 'priority_changed',
            oldValue: pick(PRIORITIES.filter((p) => p !== priority)),
            newValue: priority,
            createdAt: stamp(0.5),
          });
        }

        await db.insert(requestHistory).values(history);
        historyCount += history.length;

        // --- comment thread, matching how far the ticket actually got
        const thread: (typeof comment.$inferInsert)[] = [];
        const author = assignee ?? pick(staff);

        if (!isOpen || chance(0.4)) {
          thread.push({
            requestId: created.id,
            userId: author.id,
            content: pick(COMMENTS.triage),
            createdAt: stamp(0.3),
          });
        }
        if (status !== 'open' && chance(0.7)) {
          thread.push({
            requestId: created.id,
            userId: author.id,
            content: pick(COMMENTS.progress),
            createdAt: stamp(0.6),
          });
        }
        if (resolvedAt) {
          thread.push({
            requestId: created.id,
            userId: author.id,
            content: pick(COMMENTS.resolution),
            createdAt: resolvedAt,
          });
          if (chance(0.6)) {
            thread.push({
              requestId: created.id,
              userId: requester.id,
              content: pick(COMMENTS.reply),
              createdAt: new Date(resolvedAt.getTime() + 3600_000),
            });
          }
        }

        if (thread.length) {
          await db.insert(comment).values(thread);
          commentCount += thread.length;
        }
      }
    }
  }

  console.log(`requests: ${requestCount}`);
  console.log(`comments: ${commentCount}`);
  console.log(`history:  ${historyCount}`);
  console.log('\nevery seeded account uses the password: password-123');
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
