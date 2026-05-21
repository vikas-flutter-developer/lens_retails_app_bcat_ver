/*
  Warnings:

  - Added the required column `name` to the `Employee` table without a default value. This is not possible if the table is not empty.
  - Added the required column `role` to the `Employee` table without a default value. This is not possible if the table is not empty.

*/
-- DropForeignKey
ALTER TABLE "public"."Employee" DROP CONSTRAINT "Employee_userId_fkey";

-- AlterTable
ALTER TABLE "Employee" ADD COLUMN     "name" TEXT NOT NULL,
ADD COLUMN     "role" TEXT NOT NULL,
ADD COLUMN     "status" TEXT NOT NULL DEFAULT 'Active',
ALTER COLUMN "userId" DROP NOT NULL;

-- AlterTable
ALTER TABLE "JobCard" ADD COLUMN     "billNo" TEXT,
ADD COLUMN     "billSeries" TEXT,
ADD COLUMN     "bookedBy" TEXT,
ADD COLUMN     "godown" TEXT,
ADD COLUMN     "orderType" TEXT;

-- AlterTable
ALTER TABLE "JobCardItem" ADD COLUMN     "add" TEXT,
ADD COLUMN     "axis" TEXT,
ADD COLUMN     "cyl" TEXT,
ADD COLUMN     "eye" TEXT,
ADD COLUMN     "sph" TEXT;

-- CreateTable
CREATE TABLE "vendors" (
    "id" TEXT NOT NULL,
    "account_id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "print_name" TEXT,
    "alias" TEXT,
    "group_name" TEXT,
    "station" TEXT,
    "contact_person" TEXT,
    "phone" TEXT,
    "email" TEXT,
    "account_type" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "vendors_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "vendors_account_id_key" ON "vendors"("account_id");

-- AddForeignKey
ALTER TABLE "Employee" ADD CONSTRAINT "Employee_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;
