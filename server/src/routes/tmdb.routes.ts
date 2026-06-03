import { Router } from 'express';

const router = Router();

function cleanTitle(value: string) {
  return value
    .replace(/\[[^\]]*\]/g, ' ')
    .replace(/\([^\)]*\)/g, ' ')
    .replace(/\b(4k|uhd|fhd|hd|dual audio|dublado|legendado|bluray|web-dl|webrip|1080p|720p)\b/gi, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function tmdbImage(path?: string | null) {
  if (!path) return '';

  return `https://image.tmdb.org/t/p/w500${path}`;
}

function tmdbBackdrop(path?: string | null) {
  if (!path) return '';

  return `https://image.tmdb.org/t/p/w780${path}`;
}

router.get('/overview', async (req, res) => {
  const apiKey = process.env.TMDB_API_KEY;

  if (!apiKey) {
    return res.status(200).json({
      overview: '',
      year: '',
      posterUrl: '',
      backdropUrl: '',
      source: 'missing_api_key',
    });
  }

  const rawTitle = req.query.title?.toString() ?? '';
  const type = req.query.type?.toString() === 'series' ? 'tv' : 'movie';
  const year = req.query.year?.toString() ?? '';

  const title = cleanTitle(rawTitle);

  if (!title) {
    return res.status(400).json({
      message: 'Título obrigatório',
    });
  }

  const params = new URLSearchParams({
    api_key: apiKey,
    language: 'pt-BR',
    region: 'BR',
    query: title,
    include_adult: 'false',
  });

  if (year && year !== 'IPTV') {
    if (type === 'movie') {
      params.set('year', year);
    } else {
      params.set('first_air_date_year', year);
    }
  }

  const url = `https://api.themoviedb.org/3/search/${type}?${params.toString()}`;

  try {
    const response = await fetch(url);

    if (!response.ok) {
      return res.status(200).json({
        overview: '',
        year: '',
        posterUrl: '',
        backdropUrl: '',
        source: 'tmdb_error',
      });
    }

    const data = await response.json() as any;
    const first = Array.isArray(data?.results) ? data.results[0] : null;

    if (!first) {
      return res.json({
        overview: '',
        year: '',
        posterUrl: '',
        backdropUrl: '',
        source: 'not_found',
      });
    }

    const date = type === 'movie'
      ? first.release_date?.toString() ?? ''
      : first.first_air_date?.toString() ?? '';

    return res.json({
      overview: first.overview?.toString() ?? '',
      year: date ? date.slice(0, 4) : '',
      posterUrl: tmdbImage(first.poster_path),
      backdropUrl: tmdbBackdrop(first.backdrop_path),
      source: 'tmdb',
    });
  } catch (error) {
    return res.status(200).json({
      overview: '',
      year: '',
      posterUrl: '',
      backdropUrl: '',
      source: 'request_failed',
    });
  }
});

router.get('/trending-brazil', async (req, res) => {
  const apiKey = process.env.TMDB_API_KEY;

  if (!apiKey) {
    return res.status(200).json({
      movies: [],
      series: [],
      source: 'missing_api_key',
    });
  }

  async function fetchList(type: 'movie' | 'tv') {
    const params = new URLSearchParams({
      api_key: apiKey,
      language: 'pt-BR',
      region: 'BR',
      sort_by: 'popularity.desc',
      include_adult: 'false',
      include_video: 'false',
      page: '1',
      watch_region: 'BR',
    });

    const url = `https://api.themoviedb.org/3/discover/${type}?${params.toString()}`;

    const response = await fetch(url);

    if (!response.ok) {
      return [];
    }

    const data = await response.json() as any;
    const results = Array.isArray(data?.results) ? data.results : [];

    return results.slice(0, 30).map((item: any) => {
      const title = type === 'movie'
        ? item.title?.toString() ?? ''
        : item.name?.toString() ?? '';

      const originalTitle = type === 'movie'
        ? item.original_title?.toString() ?? ''
        : item.original_name?.toString() ?? '';

      const date = type === 'movie'
        ? item.release_date?.toString() ?? ''
        : item.first_air_date?.toString() ?? '';

      return {
        id: item.id,
        title,
        originalTitle,
        year: date ? date.slice(0, 4) : '',
        overview: item.overview?.toString() ?? '',
        posterUrl: tmdbImage(item.poster_path),
        backdropUrl: tmdbBackdrop(item.backdrop_path),
        voteAverage: item.vote_average ?? 0,
        popularity: item.popularity ?? 0,
      };
    }).filter((item: any) => item.title);
  }

  try {
    const [movies, series] = await Promise.all([
      fetchList('movie'),
      fetchList('tv'),
    ]);

    return res.json({
      movies,
      series,
      source: 'tmdb',
    });
  } catch (error) {
    return res.status(200).json({
      movies: [],
      series: [],
      source: 'request_failed',
    });
  }
});

export default router;
