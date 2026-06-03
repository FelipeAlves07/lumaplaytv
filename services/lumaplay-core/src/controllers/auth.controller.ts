import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import { customerRepository } from '../repositories/customer.repository.js';
import { signToken } from '../utils/jwt.js';

export const authController = {
  async customerLogin(req: Request, res: Response) {
    const { username, password } = req.body;

    const customer = await customerRepository.findByUsername(username);

    if (!customer) {
      return res.status(401).json({
        message: 'Invalid credentials',
      });
    }

    if (customer.status !== 'ACTIVE') {
      return res.status(403).json({
        message: 'Account unavailable',
      });
    }

    if (customer.expiresAt < new Date()) {
      return res.status(403).json({
        message: 'Subscription expired',
      });
    }

    const valid = await bcrypt.compare(
      password,
      customer.appPasswordHash,
    );

    if (!valid) {
      return res.status(401).json({
        message: 'Invalid credentials',
      });
    }

    const token = signToken({
      customerId: customer.id,
      username: customer.appUsername,
    });

    return res.json({
      token,
      customer: {
        id: customer.id,
        name: customer.name,
        username: customer.appUsername,
      },
    });
  },
};