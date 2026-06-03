import dotenv from 'dotenv';

dotenv.config();

export const env = {
  port: Number(process.env.PORT || 4000),
  jwtSecret: process.env.JWT_SECRET || '',
  aesSecret: process.env.AES_SECRET || '',
  databaseUrl: process.env.DATABASE_URL || '',
};