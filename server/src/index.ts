import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';

import customersRoutes from './routes/customers.routes';
import playlistsRoutes from './routes/playlists.routes';
import dashboardRoutes from './routes/dashboard.routes';
import authRoutes from './routes/auth.routes';
import xtreamRoutes from './routes/xtream.routes';
import libraryRoutes from './routes/library.routes';
import accountRoutes from './routes/account.routes';
import tmdbRoutes from './routes/tmdb.routes';

dotenv.config();

const app = express();

app.use(cors());

app.use(express.json());

app.get('/', (_, res) => {
  return res.json({
    name: 'LumaPlay API',
    status: 'online',
  });
});

app.use('/dashboard', dashboardRoutes);

app.use('/customers', customersRoutes);

app.use('/playlists', playlistsRoutes);

app.use('/auth', authRoutes);

app.use('/xtream', xtreamRoutes);

app.use('/library', libraryRoutes);

app.use('/account', accountRoutes);

app.use('/tmdb', tmdbRoutes);

const PORT = process.env.PORT || 4000;

app.listen(PORT, () => {
  console.log(
    `🚀 LumaPlay API rodando na porta ${PORT}`,
  );
});
