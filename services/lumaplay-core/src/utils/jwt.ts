import jwt from 'jsonwebtoken';
import { env } from '../config/env.js';

export function signToken(payload: object) {
  return jwt.sign(payload, env.jwtSecret, {
    expiresIn: '7d',
  });
}

export function verifyToken(token: string) {
  return jwt.verify(token, env.jwtSecret);
}