import { prisma } from '../providers/prisma.js';

export const customerRepository = {
  findByUsername(appUsername: string) {
    return prisma.customer.findUnique({
      where: {
        appUsername,
      },
      include: {
        iptvCredential: true,
      },
    });
  },

  findById(id: string) {
    return prisma.customer.findUnique({
      where: {
        id,
      },
      include: {
        iptvCredential: true,
      },
    });
  },

  findAll() {
    return prisma.customer.findMany({
      include: {
        iptvCredential: true,
      },
      orderBy: {
        createdAt: 'desc',
      },
    });
  },

  create(data: {
    name: string;
    appUsername: string;
    appPasswordHash: string;
    expiresAt: Date;
    serverUrl: string;
    iptvUsername: string;
    iptvPasswordEnc: string;
  }) {
    return prisma.customer.create({
      data: {
        name: data.name,
        appUsername: data.appUsername,
        appPasswordHash: data.appPasswordHash,
        expiresAt: data.expiresAt,
        iptvCredential: {
          create: {
            serverUrl: data.serverUrl,
            iptvUsername: data.iptvUsername,
            iptvPasswordEnc: data.iptvPasswordEnc,
          },
        },
      },
      include: {
        iptvCredential: true,
      },
    });
  },

  update(
    id: string,
    data: {
      name: string;
      expiresAt: Date;
      status: 'ACTIVE' | 'BLOCKED' | 'EXPIRED';
    },
  ) {
    return prisma.customer.update({
      where: {
        id,
      },
      data,
    });
  },

  delete(id: string) {
    return prisma.customer.delete({
      where: {
        id,
      },
    });
  },
};