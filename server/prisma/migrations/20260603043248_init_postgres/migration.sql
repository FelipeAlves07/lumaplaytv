-- CreateEnum
CREATE TYPE "UserStatus" AS ENUM ('ACTIVE', 'BLOCKED', 'EXPIRED');

-- CreateTable
CREATE TABLE "Customer" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "username" TEXT NOT NULL,
    "passwordHash" TEXT NOT NULL,
    "status" "UserStatus" NOT NULL DEFAULT 'ACTIVE',
    "expiresAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Customer_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Playlist" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "m3uUrl" TEXT NOT NULL,
    "host" TEXT,
    "username" TEXT,
    "password" TEXT,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "customerId" TEXT NOT NULL,

    CONSTRAINT "Playlist_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "CustomerFavorite" (
    "id" TEXT NOT NULL,
    "customerId" TEXT NOT NULL,
    "itemId" TEXT NOT NULL,
    "itemType" TEXT NOT NULL DEFAULT 'catalog',
    "title" TEXT NOT NULL,
    "subtitle" TEXT,
    "tag" TEXT,
    "year" TEXT,
    "duration" TEXT,
    "description" TEXT,
    "poster" TEXT,
    "logoUrl" TEXT,
    "streamUrl" TEXT,
    "category" TEXT,
    "isLive" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "CustomerFavorite_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "CustomerProgress" (
    "id" TEXT NOT NULL,
    "customerId" TEXT NOT NULL,
    "itemId" TEXT NOT NULL,
    "itemType" TEXT NOT NULL DEFAULT 'catalog',
    "title" TEXT NOT NULL,
    "subtitle" TEXT,
    "tag" TEXT,
    "year" TEXT,
    "duration" TEXT,
    "description" TEXT,
    "poster" TEXT,
    "logoUrl" TEXT,
    "streamUrl" TEXT,
    "category" TEXT,
    "isLive" BOOLEAN NOT NULL DEFAULT false,
    "positionSeconds" INTEGER NOT NULL DEFAULT 0,
    "durationSeconds" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "CustomerProgress_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Customer_username_key" ON "Customer"("username");

-- CreateIndex
CREATE UNIQUE INDEX "CustomerFavorite_customerId_itemId_key" ON "CustomerFavorite"("customerId", "itemId");

-- CreateIndex
CREATE UNIQUE INDEX "CustomerProgress_customerId_itemId_key" ON "CustomerProgress"("customerId", "itemId");

-- AddForeignKey
ALTER TABLE "Playlist" ADD CONSTRAINT "Playlist_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES "Customer"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CustomerFavorite" ADD CONSTRAINT "CustomerFavorite_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES "Customer"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CustomerProgress" ADD CONSTRAINT "CustomerProgress_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES "Customer"("id") ON DELETE CASCADE ON UPDATE CASCADE;
