import { Router } from 'express';
import bcrypt from 'bcryptjs';

import { prisma } from '../lib/prisma';

const router = Router();

router.post('/:customerId/change-password', async (req, res) => {
  const { customerId } = req.params;
  const { currentPassword, newPassword } = req.body ?? {};

  if (!customerId) {
    return res.status(400).json({
      message: 'Cliente inválido',
    });
  }

  if (!currentPassword || !newPassword) {
    return res.status(400).json({
      message: 'Senha atual e nova senha são obrigatórias',
    });
  }

  if (String(newPassword).length < 6) {
    return res.status(400).json({
      message: 'A nova senha precisa ter pelo menos 6 caracteres',
    });
  }

  const customer = await prisma.customer.findUnique({
    where: {
      id: customerId,
    },
  });

  if (!customer) {
    return res.status(404).json({
      message: 'Usuário não encontrado',
    });
  }

  const passwordOk = await bcrypt.compare(
    String(currentPassword),
    customer.passwordHash,
  );

  if (!passwordOk) {
    return res.status(401).json({
      message: 'Senha atual incorreta',
    });
  }

  const passwordHash = await bcrypt.hash(String(newPassword), 10);

  await prisma.customer.update({
    where: {
      id: customer.id,
    },
    data: {
      passwordHash,
    },
  });

  return res.json({
    ok: true,
    message: 'Senha alterada com sucesso',
  });
});

export default router;
