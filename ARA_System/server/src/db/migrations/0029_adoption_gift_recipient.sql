-- Additive only: gift adoptions record who the animal is for, so the review
-- team can confirm the recipient is ready for a pet. Null for self adoptions
-- and for applications submitted before this field existed.
ALTER TABLE "adoption_applications" ADD COLUMN "recipient_name" text;--> statement-breakpoint
ALTER TABLE "adoption_applications" ADD COLUMN "recipient_contact" text;--> statement-breakpoint
ALTER TABLE "adoption_applications" ADD COLUMN "recipient_relationship" text;
