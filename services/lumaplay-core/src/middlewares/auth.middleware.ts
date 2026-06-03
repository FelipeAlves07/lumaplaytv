import { Request, Response, NextFunction } from 'express';
import { verifyToken } from '../utils/jwt.js';

declare global {
  namespace Express {
    interface Request {
      customerId?: string;
    }
  }
}

export function authMiddleware(
  req: Request,
  res: Response,
  next: NextFunction,
) {
  const auth = req.headers.authorization;

  if (!auth) {
    return res.status(401).json({
      message: 'Unauthorized',
    });
  }

  const token = auth.replace('Bearer ', '');

  try {
    const payload = verifyToken(token) as {
      customerId: string;
    };

    req.customerId = payload.customerId;

    next();
  } catch {
    return res.status(401).json({
      message: 'Invalid token',
    });
  }
}