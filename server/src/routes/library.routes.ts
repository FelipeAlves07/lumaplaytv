import { Router } from 'express';

import { prisma } from '../lib/prisma';

const router = Router();

function itemPayload(body: any) {
  return {
    itemId: body.id?.toString() ?? body.itemId?.toString() ?? '',
    itemType: body.itemType?.toString() ?? 'catalog',
    title: body.title?.toString() ?? 'Sem título',
    subtitle: body.subtitle?.toString() || null,
    tag: body.tag?.toString() || null,
    year: body.year?.toString() || null,
    duration: body.duration?.toString() || null,
    description: body.description?.toString() || null,
    poster: body.poster?.toString() || null,
    logoUrl: body.logoUrl?.toString() || null,
    streamUrl: body.streamUrl?.toString() || null,
    category: body.category?.toString() || null,
    isLive: body.isLive === true || body.isLive?.toString() === 'true',
  };
}

function toClientItem(item: any) {
  return {
    id: item.itemId,
    itemType: item.itemType,
    title: item.title,
    subtitle: item.subtitle ?? '',
    tag: item.tag ?? '',
    year: item.year ?? '',
    duration: item.duration ?? '',
    description: item.description ?? '',
    poster: item.poster ?? '',
    logoUrl: item.logoUrl ?? '',
    streamUrl: item.streamUrl ?? '',
    category: item.category ?? '',
    isLive: item.isLive,
    positionSeconds: item.positionSeconds ?? 0,
    durationSeconds: item.durationSeconds ?? 0,
    updatedAt: item.updatedAt,
    createdAt: item.createdAt,
  };
}

router.get('/:customerId/favorites', async (req, res) => {
  const { customerId } = req.params;

  const items = await prisma.customerFavorite.findMany({
    where: {
      customerId,
    },
    orderBy: {
      updatedAt: 'desc',
    },
  });

  return res.json(items.map(toClientItem));
});

router.post('/:customerId/favorites', async (req, res) => {
  const { customerId } = req.params;
  const payload = itemPayload(req.body);

  if (!payload.itemId) {
    return res.status(400).json({
      message: 'ID do item é obrigatório',
    });
  }

  const item = await prisma.customerFavorite.upsert({
    where: {
      customerId_itemId: {
        customerId,
        itemId: payload.itemId,
      },
    },
    update: payload,
    create: {
      customerId,
      ...payload,
    },
  });

  return res.json(toClientItem(item));
});

router.delete('/:customerId/favorites/:itemId', async (req, res) => {
  const { customerId, itemId } = req.params;

  await prisma.customerFavorite.deleteMany({
    where: {
      customerId,
      itemId,
    },
  });

  return res.json({
    ok: true,
  });
});

router.post('/:customerId/favorites/:itemId/toggle', async (req, res) => {
  const { customerId, itemId } = req.params;

  const existing = await prisma.customerFavorite.findUnique({
    where: {
      customerId_itemId: {
        customerId,
        itemId,
      },
    },
  });

  if (existing) {
    await prisma.customerFavorite.delete({
      where: {
        customerId_itemId: {
          customerId,
          itemId,
        },
      },
    });

    return res.json({
      favorited: false,
    });
  }

  const payload = itemPayload({
    ...req.body,
    id: itemId,
  });

  const item = await prisma.customerFavorite.create({
    data: {
      customerId,
      ...payload,
    },
  });

  return res.json({
    favorited: true,
    item: toClientItem(item),
  });
});

router.get('/:customerId/progress', async (req, res) => {
  const { customerId } = req.params;

  const items = await prisma.customerProgress.findMany({
    where: {
      customerId,
    },
    orderBy: {
      updatedAt: 'desc',
    },
    take: 50,
  });

  return res.json(items.map(toClientItem));
});

router.post('/:customerId/progress', async (req, res) => {
  const { customerId } = req.params;
  const payload = itemPayload(req.body);

  if (!payload.itemId) {
    return res.status(400).json({
      message: 'ID do item é obrigatório',
    });
  }

  const positionSeconds = Number(req.body.positionSeconds ?? 0);
  const durationSeconds = Number(req.body.durationSeconds ?? 0);

  const item = await prisma.customerProgress.upsert({
    where: {
      customerId_itemId: {
        customerId,
        itemId: payload.itemId,
      },
    },
    update: {
      ...payload,
      positionSeconds,
      durationSeconds,
    },
    create: {
      customerId,
      ...payload,
      positionSeconds,
      durationSeconds,
    },
  });

  return res.json(toClientItem(item));
});

router.delete('/:customerId/progress/:itemId', async (req, res) => {
  const { customerId, itemId } = req.params;

  await prisma.customerProgress.deleteMany({
    where: {
      customerId,
      itemId,
    },
  });

  return res.json({
    ok: true,
  });
});

export default router;
