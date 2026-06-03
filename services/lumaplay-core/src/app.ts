import express from 'express';
import cors from 'cors';
import { authRoutes } from './routes/auth.routes.js';
import { customerRoutes } from './routes/customer.routes.js';
import { catalogRoutes } from './routes/catalog.routes.js';

const app = express();

app.use(cors());
app.use(express.json());

app.get('/health', (_, res) => {
  res.json({
    status: 'ok',
    service: 'lumaplay-core',
  });
});

app.use('/auth', authRoutes);
app.use('/customers', customerRoutes);
app.use('/catalog', catalogRoutes);

export { app };