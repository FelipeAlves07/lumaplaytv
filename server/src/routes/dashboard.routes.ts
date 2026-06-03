import { Router } from 'express';
import { prisma } from '../lib/prisma';

const router = Router();

router.get('/', async (_, res) => {
  const users = await prisma.customer.count();

  const playlists = await prisma.playlist.count();

  const activeUsers = await prisma.customer.count({
    where: {
      status: 'ACTIVE',
    },
  });

  const blockedUsers = await prisma.customer.count({
    where: {
      status: 'BLOCKED',
    },
  });

  return res.json({
    users,
    playlists,
    activeUsers,
    blockedUsers,
  });
});

export default router;