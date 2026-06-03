import { Request, Response } from 'express';
import { customerRepository } from '../repositories/customer.repository.js';
import { decrypt } from '../utils/crypto.js';
import { xtreamService } from '../integrations/xtream/xtream.service.js';
import { cache } from '../utils/cache.js';
import { paginate } from '../utils/pagination.js';
import { streamUrl } from '../utils/stream-url.js';

async function getCustomerCredentials(customerId: string) {
  const customer = await customerRepository.findById(customerId);

  if (!customer?.iptvCredential) {
    return null;
  }

  return {
    serverUrl: customer.iptvCredential.serverUrl,
    username: customer.iptvCredential.iptvUsername,
    password: decrypt(customer.iptvCredential.iptvPasswordEnc),
  };
}

async function getCachedXtreamData(
  cacheKey: string,
  creds: {
    serverUrl: string;
    username: string;
    password: string;
  },
  action: string,
) {
  const cached = cache.get<any[]>(cacheKey);

  if (cached) {
    return cached;
  }

  const data = await xtreamService.request(
    creds.serverUrl,
    creds.username,
    creds.password,
    action,
  );

  cache.set(cacheKey, data);

  return data;
}

export const catalogController = {
  async liveCategories(req: Request, res: Response) {
    const creds = await getCustomerCredentials(req.customerId!);

    if (!creds) {
      return res.status(404).json({
        message: 'IPTV credentials not found',
      });
    }

    const data = await getCachedXtreamData(
      `live_categories_${req.customerId}`,
      creds,
      'get_live_categories',
    );

    return res.json(data);
  },

  async liveStreams(req: Request, res: Response) {
    const creds = await getCustomerCredentials(req.customerId!);

    if (!creds) {
      return res.status(404).json({
        message: 'IPTV credentials not found',
      });
    }

    const page = Number(req.query.page || 1);
    const limit = Number(req.query.limit || 50);

    const data = await getCachedXtreamData(
      `live_streams_${req.customerId}`,
      creds,
      'get_live_streams',
    );

    return res.json(paginate(data, page, limit));
  },

  async liveByCategory(req: Request, res: Response) {
    const creds = await getCustomerCredentials(req.customerId!);

    if (!creds) {
      return res.status(404).json({
        message: 'IPTV credentials not found',
      });
    }

    const page = Number(req.query.page || 1);
    const limit = Number(req.query.limit || 50);

    const data = await getCachedXtreamData(
      `live_streams_${req.customerId}`,
      creds,
      'get_live_streams',
    );

    const filtered = data.filter(
      (item) => item.category_id === req.params.categoryId,
    );

    return res.json(paginate(filtered, page, limit));
  },

  async liveDetail(req: Request, res: Response) {
    const creds = await getCustomerCredentials(req.customerId!);

    if (!creds) {
      return res.status(404).json({
        message: 'IPTV credentials not found',
      });
    }

    const data = await getCachedXtreamData(
      `live_streams_${req.customerId}`,
      creds,
      'get_live_streams',
    );

    const stream = data.find(
      (item) => String(item.stream_id) === req.params.streamId,
    );

    if (!stream) {
      return res.status(404).json({
        message: 'Live stream not found',
      });
    }

    return res.json({
      ...stream,
      stream_url: streamUrl.live(
        creds,
        req.params.streamId,
      ),
    });
  },

  async movies(req: Request, res: Response) {
    const creds = await getCustomerCredentials(req.customerId!);

    if (!creds) {
      return res.status(404).json({
        message: 'IPTV credentials not found',
      });
    }

    const page = Number(req.query.page || 1);
    const limit = Number(req.query.limit || 50);

    const data = await getCachedXtreamData(
      `movies_${req.customerId}`,
      creds,
      'get_vod_streams',
    );

    return res.json(paginate(data, page, limit));
  },

  async movieSearch(req: Request, res: Response) {
    const creds = await getCustomerCredentials(req.customerId!);

    if (!creds) {
      return res.status(404).json({
        message: 'IPTV credentials not found',
      });
    }

    const query = String(req.query.q || '').toLowerCase();

    const data = await getCachedXtreamData(
      `movies_${req.customerId}`,
      creds,
      'get_vod_streams',
    );

    const filtered = data.filter((item) =>
      item.name?.toLowerCase().includes(query),
    );

    return res.json(filtered);
  },

  async moviesByCategory(req: Request, res: Response) {
    const creds = await getCustomerCredentials(req.customerId!);

    if (!creds) {
      return res.status(404).json({
        message: 'IPTV credentials not found',
      });
    }

    const page = Number(req.query.page || 1);
    const limit = Number(req.query.limit || 50);

    const data = await getCachedXtreamData(
      `movies_${req.customerId}`,
      creds,
      'get_vod_streams',
    );

    const filtered = data.filter(
      (item) => item.category_id === req.params.categoryId,
    );

    return res.json(paginate(filtered, page, limit));
  },

  async movieDetail(req: Request, res: Response) {
    const creds = await getCustomerCredentials(req.customerId!);

    if (!creds) {
      return res.status(404).json({
        message: 'IPTV credentials not found',
      });
    }

    const data = await xtreamService.movieInfo(
      creds.serverUrl,
      creds.username,
      creds.password,
      req.params.streamId,
    );

    return res.json({
      ...data,
      stream_url: streamUrl.movie(
        creds,
        req.params.streamId,
      ),
    });
  },

  async series(req: Request, res: Response) {
    const creds = await getCustomerCredentials(req.customerId!);

    if (!creds) {
      return res.status(404).json({
        message: 'IPTV credentials not found',
      });
    }

    const page = Number(req.query.page || 1);
    const limit = Number(req.query.limit || 50);

    const data = await getCachedXtreamData(
      `series_${req.customerId}`,
      creds,
      'get_series',
    );

    return res.json(paginate(data, page, limit));
  },

  async seriesSearch(req: Request, res: Response) {
    const creds = await getCustomerCredentials(req.customerId!);

    if (!creds) {
      return res.status(404).json({
        message: 'IPTV credentials not found',
      });
    }

    const query = String(req.query.q || '').toLowerCase();

    const data = await getCachedXtreamData(
      `series_${req.customerId}`,
      creds,
      'get_series',
    );

    const filtered = data.filter((item) =>
      item.name?.toLowerCase().includes(query),
    );

    return res.json(filtered);
  },

  async seriesByCategory(req: Request, res: Response) {
    const creds = await getCustomerCredentials(req.customerId!);

    if (!creds) {
      return res.status(404).json({
        message: 'IPTV credentials not found',
      });
    }

    const page = Number(req.query.page || 1);
    const limit = Number(req.query.limit || 50);

    const data = await getCachedXtreamData(
      `series_${req.customerId}`,
      creds,
      'get_series',
    );

    const filtered = data.filter(
      (item) => item.category_id === req.params.categoryId,
    );

    return res.json(paginate(filtered, page, limit));
  },

  async seriesDetail(req: Request, res: Response) {
    const creds = await getCustomerCredentials(req.customerId!);

    if (!creds) {
      return res.status(404).json({
        message: 'IPTV credentials not found',
      });
    }

    const data = await xtreamService.seriesInfo(
      creds.serverUrl,
      creds.username,
      creds.password,
      req.params.seriesId,
    );

    return res.json(data);
  },
};