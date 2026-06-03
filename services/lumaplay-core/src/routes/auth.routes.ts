import { Router } from 'express';
import { authController } from '../controllers/auth.controller.js';

const router = Router();

router.post('/customer/login', authController.customerLogin);

export { router as authRoutes };