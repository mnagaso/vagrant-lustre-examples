import { NextRequest } from 'next/server';
import jwt from 'jsonwebtoken';
import { ObjectId } from 'mongodb';
import clientPromise from '@/lib/mongodb';

const JWT_SECRET = process.env.JWT_SECRET || 'replacethiswithstrongsecretkey';

export async function authMiddleware(req: NextRequest) {
  try {
    // Get the token from cookies
    const cookie = req.cookies.get('authToken');

    if (!cookie?.value) {
      return { isAuthenticated: false, user: null };
    }

    // Verify the token
    const decodedToken = jwt.verify(cookie.value, JWT_SECRET) as {
      userId: string;
      username: string;
      role: string;
    };

    // Verify the user exists in the database
    const client = await clientPromise;
    const db = client.db();
    const user = await db.collection('users').findOne({
      _id: new ObjectId(decodedToken.userId)
    });

    if (!user) {
      return { isAuthenticated: false, user: null };
    }

    return {
      isAuthenticated: true,
      user: {
        id: user._id.toString(),
        username: user.username,
        role: user.role
      }
    };

  } catch (error) {
    console.error('Auth middleware error:', error);
    return { isAuthenticated: false, user: null };
  }
}
