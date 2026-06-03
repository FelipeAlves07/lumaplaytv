import { Router } from 'express';
import bcrypt from 'bcryptjs';

import { prisma } from '../lib/prisma';

const router = Router();

router.get('/', async (_, res) => {
  const customers = await prisma.customer.findMany({
    orderBy: { createdAt: 'desc' },
    include: { playlists: true },
  });

  return res.json(customers);
});

router.post('/', async (req, res) => {
  const { name, username, password, expiresAt } = req.body;

  if (!name || !username || !password) {
    return res.status(400).json({
      message: 'Nome, usuário e senha são obrigatórios',
    });
  }

  const exists = await prisma.customer.findUnique({
    where: { username },
  });

  if (exists) {
    return res.status(409).json({
      message: 'Usuário já existe',
    });
  }

  const passwordHash = await bcrypt.hash(password, 10);

  const customer = await prisma.customer.create({
    data: {
      name,
      username,
      passwordHash,
      expiresAt: expiresAt ? new Date(expiresAt) : null,
    },
    include: { playlists: true },
  });

  return res.json(customer);
});

router.patch('/:id/status', async (req, res) => {
  const { id } = req.params;
  const { status } = req.body;

  const allowedStatuses = ['ACTIVE', 'BLOCKED', 'EXPIRED'];

  if (!allowedStatuses.includes(status)) {
    return res.status(400).json({
      message: 'Status inválido',
    });
  }

  const customer = await prisma.customer.update({
    where: { id },
    data: { status },
    include: { playlists: true },
  });

  return res.json(customer);
});

router.delete('/:id', async (req, res) => {
  const { id } = req.params;

  await prisma.customer.delete({
    where: { id },
  });

  return res.json({ ok: true });
});

export default router;
