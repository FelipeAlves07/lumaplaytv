import { Router } from 'express';
import { customerController } from '../controllers/customer.controller.js';
import { authMiddleware } from '../middlewares/auth.middleware.js';

const router = Router();

router.use(authMiddleware);

router.get('/', customerController.list);
router.get('/:id', customerController.get);
router.post('/', customerController.create);
router.put('/:id', customerController.update);
router.delete('/:id', customerController.delete);

export { router as customerRoutes };