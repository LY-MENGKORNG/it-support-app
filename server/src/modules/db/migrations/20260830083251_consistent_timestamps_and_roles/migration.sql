PRAGMA foreign_keys=OFF;--> statement-breakpoint
CREATE TABLE `__new_comment` (
	`id` integer PRIMARY KEY AUTOINCREMENT,
	`request_id` integer NOT NULL,
	`user_id` integer NOT NULL,
	`content` text NOT NULL,
	`created_at` integer DEFAULT (unixepoch() * 1000) NOT NULL,
	`updated_at` integer,
	CONSTRAINT `fk_comment_request_id_request_id_fk` FOREIGN KEY (`request_id`) REFERENCES `request`(`id`) ON DELETE CASCADE,
	CONSTRAINT `fk_comment_user_id_user_id_fk` FOREIGN KEY (`user_id`) REFERENCES `user`(`id`)
);
--> statement-breakpoint
INSERT INTO `__new_comment`(`id`, `request_id`, `user_id`, `content`, `created_at`, `updated_at`) SELECT `id`, `request_id`, `user_id`, `content`, `created_at`, `updated_at` FROM `comment`;--> statement-breakpoint
DROP TABLE `comment`;--> statement-breakpoint
ALTER TABLE `__new_comment` RENAME TO `comment`;--> statement-breakpoint
PRAGMA foreign_keys=ON;--> statement-breakpoint
PRAGMA foreign_keys=OFF;--> statement-breakpoint
CREATE TABLE `__new_request_history` (
	`id` integer PRIMARY KEY AUTOINCREMENT,
	`request_id` integer NOT NULL,
	`user_id` integer NOT NULL,
	`action` text NOT NULL,
	`old_value` text,
	`new_value` text,
	`created_at` integer DEFAULT (unixepoch() * 1000) NOT NULL,
	CONSTRAINT `fk_request_history_request_id_request_id_fk` FOREIGN KEY (`request_id`) REFERENCES `request`(`id`) ON DELETE CASCADE,
	CONSTRAINT `fk_request_history_user_id_user_id_fk` FOREIGN KEY (`user_id`) REFERENCES `user`(`id`)
);
--> statement-breakpoint
INSERT INTO `__new_request_history`(`id`, `request_id`, `user_id`, `action`, `old_value`, `new_value`, `created_at`) SELECT `id`, `request_id`, `user_id`, `action`, `old_value`, `new_value`, `created_at` FROM `request_history`;--> statement-breakpoint
DROP TABLE `request_history`;--> statement-breakpoint
ALTER TABLE `__new_request_history` RENAME TO `request_history`;--> statement-breakpoint
PRAGMA foreign_keys=ON;--> statement-breakpoint
PRAGMA foreign_keys=OFF;--> statement-breakpoint
CREATE TABLE `__new_user` (
	`id` integer PRIMARY KEY AUTOINCREMENT,
	`created_at` integer DEFAULT (unixepoch() * 1000) NOT NULL,
	`updated_at` integer DEFAULT (unixepoch() * 1000) NOT NULL,
	`name` text NOT NULL,
	`email` text NOT NULL UNIQUE,
	`password_hash` text NOT NULL,
	`role` text DEFAULT 'employee' NOT NULL,
	`is_active` integer DEFAULT true NOT NULL
);
--> statement-breakpoint
INSERT INTO `__new_user`(`id`, `created_at`, `updated_at`, `name`, `email`, `password_hash`, `role`, `is_active`) SELECT `id`, `created_at`, `updated_at`, `name`, `email`, `password_hash`, `role`, `is_active` FROM `user`;--> statement-breakpoint
DROP TABLE `user`;--> statement-breakpoint
ALTER TABLE `__new_user` RENAME TO `user`;--> statement-breakpoint
PRAGMA foreign_keys=ON;--> statement-breakpoint
CREATE INDEX `comments_request_idx` ON `comment` (`request_id`);--> statement-breakpoint
CREATE INDEX `comments_user_idx` ON `comment` (`user_id`);--> statement-breakpoint
CREATE INDEX `request_history_request_idx` ON `request_history` (`request_id`);--> statement-breakpoint
CREATE INDEX `request_history_user_idx` ON `request_history` (`user_id`);--> statement-breakpoint
CREATE INDEX `request_history_created_at_idx` ON `request_history` (`created_at`);