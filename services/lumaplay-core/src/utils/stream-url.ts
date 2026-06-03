type StreamCreds = {
  serverUrl: string;
  username: string;
  password: string;
};

export const streamUrl = {
  live(
    creds: StreamCreds,
    streamId: string,
    extension = 'ts',
  ) {
    return (
      `${creds.serverUrl}/live/` +
      `${creds.username}/` +
      `${creds.password}/` +
      `${streamId}.${extension}`
    );
  },

  movie(
    creds: StreamCreds,
    streamId: string,
    extension = 'mp4',
  ) {
    return (
      `${creds.serverUrl}/movie/` +
      `${creds.username}/` +
      `${creds.password}/` +
      `${streamId}.${extension}`
    );
  },

  series(
    creds: StreamCreds,
    episodeId: string,
    extension = 'mp4',
  ) {
    return (
      `${creds.serverUrl}/series/` +
      `${creds.username}/` +
      `${creds.password}/` +
      `${episodeId}.${extension}`
    );
  },
};