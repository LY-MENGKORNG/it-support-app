CREATE TABLE `category` (
	`id` integer PRIMARY KEY AUTOINCREMENT,
	`name` text NOT NULL UNIQUE,
	`description` text,
	`created_at` integer DEFAULT (unixepoch() * 1000) NOT NULL
);
--> statement-breakpoint
CREATE TABLE `comment` (
	`id` integer PRIMARY KEY AUTOINCREMENT,
	`request_id` integer NOT NULL,
	`user_id` integer NOT NULL,
	`content` text NOT NULL,
	`created_at` integer DEFAULT (unixepoch()) NOT NULL,
	`updated_at` integer,
	CONSTRAINT `fk_comment_request_id_request_id_fk` FOREIGN KEY (`request_id`) REFERENCES `request`(`id`) ON DELETE CASCADE,
	CONSTRAINT `fk_comment_user_id_user_id_fk` FOREIGN KEY (`user_id`) REFERENCES `user`(`id`)
);
--> statement-breakpoint
CREATE TABLE `request_history` (
	`id` integer PRIMARY KEY AUTOINCREMENT,
	`request_id` integer NOT NULL,
	`user_id` integer NOT NULL,
	`action` text NOT NULL,
	`old_value` text,
	`new_value` text,
	`created_at` integer DEFAULT (unixepoch()) NOT NULL,
	CONSTRAINT `fk_request_history_request_id_request_id_fk` FOREIGN KEY (`request_id`) REFERENCES `request`(`id`) ON DELETE CASCADE,
	CONSTRAINT `fk_request_history_user_id_user_id_fk` FOREIGN KEY (`user_id`) REFERENCES `user`(`id`)
);
--> statement-breakpoint
CREATE TABLE `request` (
	`id` integer PRIMARY KEY AUTOINCREMENT,
	`title` text NOT NULL,
	`description` text NOT NULL,
	`category_id` integer NOT NULL,
	`priority` text DEFAULT 'medium' NOT NULL,
	`status` text DEFAULT 'open' NOT NULL,
	`requester_id` integer NOT NULL,
	`assignee_id` integer,
	`created_at` integer DEFAULT (unixepoch() * 1000) NOT NULL,
	`updated_at` integer DEFAULT (unixepoch() * 1000) NOT NULL,
	`resolved_at` integer,
	`closed_at` integer,
	CONSTRAINT `fk_request_category_id_category_id_fk` FOREIGN KEY (`category_id`) REFERENCES `category`(`id`),
	CONSTRAINT `fk_request_requester_id_user_id_fk` FOREIGN KEY (`requester_id`) REFERENCES `user`(`id`),
	CONSTRAINT `fk_request_assignee_id_user_id_fk` FOREIGN KEY (`assignee_id`) REFERENCES `user`(`id`)
);
--> statement-breakpoint
CREATE TABLE `user` (
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
CREATE INDEX `comments_request_idx` ON `comment` (`request_id`);--> statement-breakpoint
CREATE INDEX `comments_user_idx` ON `comment` (`user_id`);--> statement-breakpoint
CREATE INDEX `request_history_request_idx` ON `request_history` (`request_id`);--> statement-breakpoint
CREATE INDEX `request_history_user_idx` ON `request_history` (`user_id`);--> statement-breakpoint
CREATE INDEX `request_history_created_at_idx` ON `request_history` (`created_at`);--> statement-breakpoint
CREATE INDEX `request_requester_idx` ON `request` (`requester_id`);--> statement-breakpoint
CREATE INDEX `request_assignee_idx` ON `request` (`assignee_id`);--> statement-breakpoint
CREATE INDEX `request_category_idx` ON `request` (`category_id`);--> statement-breakpoint
CREATE INDEX `request_status_idx` ON `request` (`status`);--> statement-breakpoint
CREATE INDEX `request_priority_idx` ON `request` (`priority`);--> statement-breakpoint
CREATE INDEX `request_created_at_idx` ON `request` (`created_at`);