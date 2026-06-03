import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import { customerRepository } from '../repositories/customer.repository.js';
import { encrypt } from '../utils/crypto.js';

export const customerController = {
  async list(_: Request, res: Response) {
    const customers = await customerRepository.findAll();

    return res.json(customers);
  },

  async create(req: Request, res: Response) {
    const {
      name,
      appUsername,
      appPassword,
      expiresAt,
      serverUrl,
      iptvUsername,
      iptvPassword,
    } = req.body;

    const hash = await bcrypt.hash(appPassword, 10);
    const encryptedIptv = encrypt(iptvPassword);

    const customer = await customerRepository.create({
      name,
      appUsername,
      appPasswordHash: hash,
      expiresAt: new Date(expiresAt),
      serverUrl,
      iptvUsername,
      iptvPasswordEnc: encryptedIptv,
    });

    return res.status(201).json(customer);
  },

  async get(req: Request, res: Response) {
    const customer = await customerRepository.findById(req.params.id!);

    if (!customer) {
      return res.status(404).json({
        message: 'Customer not found',
      });
    }

    return res.json(customer);
  },

  async update(req: Request, res: Response) {
    const { name, expiresAt, status } = req.body;

    const customer = await customerRepository.update(
      req.params.id!,
      {
        name,
        expiresAt: new Date(expiresAt),
        status,
      },
    );

    return res.json(customer);
  },

  async delete(req: Request, res: Response) {
    await customerRepository.delete(req.params.id!);

    return res.status(204).send();
  },
};