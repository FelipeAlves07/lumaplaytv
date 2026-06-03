import { Router } from 'express';

import { prisma } from '../lib/prisma';

const router = Router();

function parseXtreamFromM3uUrl(m3uUrl: string) {
  try {
    const url = new URL(m3uUrl);

    const username = url.searchParams.get('username') || '';
    const password = url.searchParams.get('password') || '';

    const host = `${url.protocol}//${url.host}`;

    return {
      host,
      username,
      password,
    };
  } catch {
    return {
      host: '',
      username: '',
      password: '',
    };
  }
}

function buildM3uUrl({
  m3uUrl,
  host,
  username,
  password,
}: {
  m3uUrl?: string;
  host?: string;
  username?: string;
  password?: string;
}) {
  if (m3uUrl && m3uUrl.trim().length > 0) {
    return m3uUrl.trim();
  }

  if (!host || !username || !password) {
    return '';
  }

  const cleanHost = host.endsWith('/') ? host.slice(0, -1) : host;

  return `${cleanHost}/get.php?username=${encodeURIComponent(
    username,
  )}&password=${encodeURIComponent(
    password,
  )}&type=m3u_plus&output=mpegts`;
}

router.get('/', async (_, res) => {
  const playlists = await prisma.playlist.findMany({
    orderBy: {
      createdAt: 'desc',
    },
    include: {
      customer: true,
    },
  });

  return res.json(playlists);
});

router.post('/', async (req, res) => {
  const { name, m3uUrl, customerId } = req.body;

  if (!name || !m3uUrl || !customerId) {
    return res.status(400).json({
      message: 'Nome, URL M3U e usuário são obrigatórios',
    });
  }

  const parsed = parseXtreamFromM3uUrl(m3uUrl);

  const finalM3uUrl = buildM3uUrl({
    m3uUrl,
    host: parsed.host,
    username: parsed.username,
    password: parsed.password,
  });

  const playlist = await prisma.playlist.create({
    data: {
      name,
      m3uUrl: finalM3uUrl,
      host: parsed.host || null,
      username: parsed.username || null,
      password: parsed.password || null,
      customerId,
    },
    include: {
      customer: true,
    },
  });

  return res.json(playlist);
});

router.patch('/:id', async (req, res) => {
  const { id } = req.params;
  const { name, m3uUrl, customerId } = req.body;

  if (!name || !m3uUrl || !customerId) {
    return res.status(400).json({
      message: 'Nome, URL M3U e usuário são obrigatórios',
    });
  }

  const parsed = parseXtreamFromM3uUrl(m3uUrl);

  const finalM3uUrl = buildM3uUrl({
    m3uUrl,
    host: parsed.host,
    username: parsed.username,
    password: parsed.password,
  });

  const playlist = await prisma.playlist.update({
    where: {
      id,
    },
    data: {
      name,
      m3uUrl: finalM3uUrl,
      host: parsed.host || null,
      username: parsed.username || null,
      password: parsed.password || null,
      customerId,
    },
    include: {
      customer: true,
    },
  });

  return res.json(playlist);
});

router.patch('/:id/toggle', async (req, res) => {
  const { id } = req.params;

  const current = await prisma.playlist.findUnique({
    where: {
      id,
    },
  });

  if (!current) {
    return res.status(404).json({
      message: 'Playlist não encontrada',
    });
  }

  const playlist = await prisma.playlist.update({
    where: {
      id,
    },
    data: {
      active: !current.active,
    },
    include: {
      customer: true,
    },
  });

  return res.json(playlist);
});

router.delete('/:id', async (req, res) => {
  const { id } = req.params;

  await prisma.playlist.delete({
    where: {
      id,
    },
  });

  return res.json({
    ok: true,
  });
});

export default router;
