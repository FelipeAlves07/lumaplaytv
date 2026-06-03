import { app } from './app.js';
import { env } from './config/env.js';

app.listen(env.port, () => {
  console.log(`🚀 LumaPlay Core running on port ${env.port}`);
});