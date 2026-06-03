import CryptoJS from 'crypto-js';
import { env } from '../config/env.js';

export function encrypt(text: string): string {
  return CryptoJS.AES.encrypt(text, env.aesSecret).toString();
}

export function decrypt(cipher: string): string {
  const bytes = CryptoJS.AES.decrypt(cipher, env.aesSecret);
  return bytes.toString(CryptoJS.enc.Utf8);
}