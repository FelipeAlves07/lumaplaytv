import { Router } from 'express';
import bcrypt from 'bcryptjs';

import { prisma } from '../lib/prisma';

const router = Router();

router.post('/login', async (req, res) => {
  const { username, password } = req.body;

  const customer = await prisma.customer.findUnique({
    where: { username },
    include: { playlists: true },
  });

  if (!customer) {
    return res.status(401).json({
      message: 'Usuário não encontrado',
    });
  }

  const validPassword = await bcrypt.compare(
    password,
    customer.passwordHash,
  );

  if (!validPassword) {
    return res.status(401).json({
      message: 'Senha inválida',
    });
  }

  if (customer.status === 'BLOCKED') {
    return res.status(403).json({
      message: 'Usuário bloqueado',
    });
  }

  if (customer.status === 'EXPIRED') {
    return res.status(403).json({
      message: 'Acesso expirado',
    });
  }

  if (customer.expiresAt && customer.expiresAt < new Date()) {
    await prisma.customer.update({
      where: { id: customer.id },
      data: { status: 'EXPIRED' },
    });

    return res.status(403).json({
      message: 'Acesso expirado',
    });
  }

  const activePlaylists = customer.playlists.filter(
    (playlist) => playlist.active,
  );

  if (activePlaylists.length === 0) {
    return res.status(403).json({
      message: 'Nenhuma playlist ativa vinculada',
    });
  }

  return res.json({
    id: customer.id,
    name: customer.name,
    username: customer.username,
    status: customer.status,
    expiresAt: customer.expiresAt,
    playlists: activePlaylists,
  });
});

export default router;