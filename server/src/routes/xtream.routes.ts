import { Router } from 'express';

import { prisma } from '../lib/prisma';

const router = Router();

function cleanHost(host: string) {
  return host.endsWith('/') ? host.slice(0, -1) : host;
}

function buildXtreamApiUrl({
  host,
  username,
  password,
  action,
  extraParams = {},
}: {
  host: string;
  username: string;
  password: string;
  action?: string;
  extraParams?: Record<string, string>;
}) {
  const url = new URL(`${cleanHost(host)}/player_api.php`);

  url.searchParams.set('username', username);
  url.searchParams.set('password', password);

  if (action) {
    url.searchParams.set('action', action);
  }

  for (const [key, value] of Object.entries(extraParams)) {
    url.searchParams.set(key, value);
  }

  return url.toString();
}

async function getActivePlaylist(customerId: string) {
  return prisma.playlist.findFirst({
    where: {
      customerId,
      active: true,
      host: {
        not: null,
      },
      username: {
        not: null,
      },
      password: {
        not: null,
      },
    },
    orderBy: {
      createdAt: 'desc',
    },
  });
}

async function fetchXtream({
  customerId,
  action,
  extraParams,
}: {
  customerId: string;
  action?: string;
  extraParams?: Record<string, string>;
}) {
  const playlist = await getActivePlaylist(customerId);

  if (!playlist || !playlist.host || !playlist.username || !playlist.password) {
    return {
      error: true,
      status: 404,
      playlist: null,
      body: {
        message: 'Nenhuma playlist Xtream ativa encontrada para este usuário',
      },
    };
  }

  const url = buildXtreamApiUrl({
    host: playlist.host,
    username: playlist.username,
    password: playlist.password,
    action,
    extraParams,
  });

  const response = await fetch(url);

  if (!response.ok) {
    return {
      error: true,
      status: response.status,
      playlist,
      body: {
        message: 'Erro ao consultar servidor Xtream',
      },
    };
  }

  const body = await response.json();

  return {
    error: false,
    status: 200,
    playlist,
    body,
  };
}

function movieUrl({
  host,
  username,
  password,
  streamId,
  extension,
}: {
  host: string;
  username: string;
  password: string;
  streamId: string;
  extension: string;
}) {
  return `${cleanHost(host)}/movie/${encodeURIComponent(
    username,
  )}/${encodeURIComponent(password)}/${streamId}.${extension || 'mp4'}`;
}

function liveUrl({
  host,
  username,
  password,
  streamId,
  extension,
}: {
  host: string;
  username: string;
  password: string;
  streamId: string;
  extension: string;
}) {
  return `${cleanHost(host)}/live/${encodeURIComponent(
    username,
  )}/${encodeURIComponent(password)}/${streamId}.${extension || 'ts'}`;
}

function seriesUrl({
  host,
  username,
  password,
  streamId,
  extension,
}: {
  host: string;
  username: string;
  password: string;
  streamId: string;
  extension: string;
}) {
  return `${cleanHost(host)}/series/${encodeURIComponent(
    username,
  )}/${encodeURIComponent(password)}/${streamId}.${extension || 'mp4'}`;
}

router.get('/account/:customerId', async (req, res) => {
  const { customerId } = req.params;

  const result = await fetchXtream({
    customerId,
  });

  return res.status(result.status).json(result.body);
});

router.get('/live-categories/:customerId', async (req, res) => {
  const { customerId } = req.params;

  const result = await fetchXtream({
    customerId,
    action: 'get_live_categories',
  });

  return res.status(result.status).json(result.body);
});

router.get('/movie-categories/:customerId', async (req, res) => {
  const { customerId } = req.params;

  const result = await fetchXtream({
    customerId,
    action: 'get_vod_categories',
  });

  return res.status(result.status).json(result.body);
});

router.get('/series-categories/:customerId', async (req, res) => {
  const { customerId } = req.params;

  const result = await fetchXtream({
    customerId,
    action: 'get_series_categories',
  });

  return res.status(result.status).json(result.body);
});

router.get('/live/:customerId', async (req, res) => {
  const { customerId } = req.params;

  const result = await fetchXtream({
    customerId,
    action: 'get_live_streams',
  });

  if (result.error || !result.playlist) {
    return res.status(result.status).json(result.body);
  }

  const playlist = result.playlist;

  const streams = Array.isArray(result.body)
    ? result.body.map((item) => {
        const streamId = item.stream_id?.toString() || '';

        return {
          ...item,
          streamUrl: streamId
            ? liveUrl({
                host: playlist.host!,
                username: playlist.username!,
                password: playlist.password!,
                streamId,
                extension: item.container_extension?.toString() || 'ts',
              })
            : '',
        };
      })
    : [];

  return res.json(streams);
});

router.get('/movies/:customerId', async (req, res) => {
  const { customerId } = req.params;

  const result = await fetchXtream({
    customerId,
    action: 'get_vod_streams',
  });

  if (result.error || !result.playlist) {
    return res.status(result.status).json(result.body);
  }

  const playlist = result.playlist;

  const movies = Array.isArray(result.body)
    ? result.body.map((item) => {
        const streamId = item.stream_id?.toString() || '';
        const extension = item.container_extension?.toString() || 'mp4';

        return {
          ...item,
          streamUrl: streamId
            ? movieUrl({
                host: playlist.host!,
                username: playlist.username!,
                password: playlist.password!,
                streamId,
                extension,
              })
            : '',
        };
      })
    : [];

  return res.json(movies);
});

router.get('/series/:customerId', async (req, res) => {
  const { customerId } = req.params;

  const result = await fetchXtream({
    customerId,
    action: 'get_series',
  });

  return res.status(result.status).json(result.body);
});

router.get('/series-info/:customerId/:seriesId', async (req, res) => {
  const { customerId, seriesId } = req.params;

  const result = await fetchXtream({
    customerId,
    action: 'get_series_info',
    extraParams: {
      series_id: seriesId,
    },
  });

  if (result.error || !result.playlist) {
    return res.status(result.status).json(result.body);
  }

  const playlist = result.playlist;
  const body: any = result.body;

  const episodes = body?.episodes || {};

  const enrichedEpisodes: Record<string, any[]> = {};

  for (const [season, seasonEpisodes] of Object.entries(episodes)) {
    if (!Array.isArray(seasonEpisodes)) {
      enrichedEpisodes[season] = [];
      continue;
    }

    enrichedEpisodes[season] = seasonEpisodes.map((episode: any) => {
      const episodeId = episode.id?.toString() || '';
      const extension =
        episode.container_extension?.toString() ||
        episode.info?.container_extension?.toString() ||
        'mp4';

      return {
        ...episode,
        streamUrl: episodeId
          ? seriesUrl({
              host: playlist.host!,
              username: playlist.username!,
              password: playlist.password!,
              streamId: episodeId,
              extension,
            })
          : '',
      };
    });
  }

  return res.json({
    ...body,
    episodes: enrichedEpisodes,
  });
});

export default router;
