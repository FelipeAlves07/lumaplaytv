import { Router } from 'express';
import { authMiddleware } from '../middlewares/auth.middleware.js';
import { catalogController } from '../controllers/catalog.controller.js';

const router = Router();

router.use(authMiddleware);

router.get('/live/categories', catalogController.liveCategories);
router.get('/live/streams', catalogController.liveStreams);
router.get('/live/category/:categoryId', catalogController.liveByCategory);
router.get('/live/:streamId', catalogController.liveDetail);

router.get('/movies', catalogController.movies);
router.get('/movies/search', catalogController.movieSearch);
router.get('/movies/category/:categoryId', catalogController.moviesByCategory);
router.get('/movie/:streamId', catalogController.movieDetail);

router.get('/series', catalogController.series);
router.get('/series/search', catalogController.seriesSearch);
router.get('/series/category/:categoryId', catalogController.seriesByCategory);
router.get('/series/:seriesId', catalogController.seriesDetail);

export { router as catalogRoutes };