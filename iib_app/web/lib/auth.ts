import { NextRequest } from 'next/server';
import jwt from 'jsonwebtoken';
import { MongoClient, ObjectId } from 'mongodb';

const JWT_SECRET = process.env.JWT_SECRET || 'replacethiswithstrongsecretkey';
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017';
const DB_NAME = process.env.DB_NAME || 'lustre_mgmt';

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
    const client = new MongoClient(MONGODB_URI);
    await client.connect();

    const db = client.db(DB_NAME);
    const usersCollection = db.collection('users');

    const user = await usersCollection.findOne({
      _id: new ObjectId(decodedToken.userId)
    });

    await client.close();

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
