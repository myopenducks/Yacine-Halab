CREATE TABLE IF NOT EXISTS `expenses` (
	`id` serial AUTO_INCREMENT NOT NULL,
	`user_id` bigint unsigned NOT NULL,
	`title` varchar(150) NOT NULL,
	`recipient_name` varchar(120),
	`category` varchar(60) NOT NULL DEFAULT 'other',
	`amount` int NOT NULL,
	`notes` varchar(500),
	`expense_date` timestamp NOT NULL DEFAULT (now()),
	`created_at` timestamp NOT NULL DEFAULT (now()),
	`updated_at` timestamp NOT NULL DEFAULT (now()) ON UPDATE CURRENT_TIMESTAMP,
	CONSTRAINT `expenses_id` PRIMARY KEY(`id`),
	CONSTRAINT `expenses_user_id_users_id_fk` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE cascade ON UPDATE no action
);--> statement-breakpoint
CREATE INDEX IF NOT EXISTS `expenses_user_idx` ON `expenses` (`user_id`);--> statement-breakpoint
CREATE INDEX IF NOT EXISTS `expenses_expense_date_idx` ON `expenses` (`expense_date`);--> statement-breakpoint
CREATE INDEX IF NOT EXISTS `expenses_category_idx` ON `expenses` (`category`);
