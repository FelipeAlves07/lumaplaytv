import axios from 'axios';

export const xtreamService = {
  async request(
    serverUrl: string,
    username: string,
    password: string,
    action: string,
  ) {
    const url =
      `${serverUrl}/player_api.php` +
      `?username=${username}` +
      `&password=${password}` +
      `&action=${action}`;

    const response = await axios.get(url, {
      timeout: 15000,
    });

    return response.data;
  },

  async requestWithId(
    serverUrl: string,
    username: string,
    password: string,
    action: string,
    idKey: string,
    idValue: string,
  ) {
    const url =
      `${serverUrl}/player_api.php` +
      `?username=${username}` +
      `&password=${password}` +
      `&action=${action}` +
      `&${idKey}=${idValue}`;

    const response = await axios.get(url, {
      timeout: 15000,
    });

    return response.data;
  },

  async movieInfo(
    serverUrl: string,
    username: string,
    password: string,
    vodId: string,
  ) {
    return this.requestWithId(
      serverUrl,
      username,
      password,
      'get_vod_info',
      'vod_id',
      vodId,
    );
  },

  async seriesInfo(
    serverUrl: string,
    username: string,
    password: string,
    seriesId: string,
  ) {
    return this.requestWithId(
      serverUrl,
      username,
      password,
      'get_series_info',
      'series_id',
      seriesId,
    );
  },
};