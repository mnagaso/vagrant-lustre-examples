import bcrypt from 'bcryptjs';

// Get bcrypt salt rounds from environment or use a default
const BCRYPT_SALT_ROUNDS = parseInt(process.env.BCRYPT_SALT_ROUNDS || '12', 10);

/**
 * Hash a password using bcrypt with salt rounds from environment
 * @param password The plain text password to hash
 * @returns Promise containing the hashed password
 */
export async function hashPassword(password: string): Promise<string> {
  const salt = await bcrypt.genSalt(BCRYPT_SALT_ROUNDS);
  return bcrypt.hash(password, salt);
}

/**
 * Verify if a password matches a hash
 * @param password The plain text password to check
 * @param hash The hashed password to compare against
 * @returns Promise<boolean> True if the password matches
 */
export async function verifyPassword(password: string, hash: string): Promise<boolean> {
  return bcrypt.compare(password, hash);
}
