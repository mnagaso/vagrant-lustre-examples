import { NextRequest, NextResponse } from 'next/server';
import { MongoClient } from 'mongodb';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { serialize } from 'cookie';
import { rateLimit } from '../../../lib/rateLimit';

// Environment variables should be properly set in your deployment
const JWT_SECRET = process.env.JWT_SECRET || 'replacethiswithstrongsecretkey';
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017';
const DB_NAME = process.env.DB_NAME || 'lustre_mgmt';
const TOKEN_EXPIRY = '8h'; // Token expires after 8 hours

// Rate limiting middleware
const limiter = rateLimit({
  interval: 60 * 1000, // 1 minute
  uniqueTokenPerInterval: 500,
  limit: 5, // 5 login attempts per minute
});

export async function POST(req: NextRequest) {
  try {
    // Apply rate limiting
    const clientIp = req.headers.get('x-forwarded-for') || 'unknown';
    await limiter.check(clientIp);

    const { username, password } = await req.json();

    if (!username || !password) {
      return NextResponse.json(
        { error: 'Username and password are required' },
        { status: 400 }
      );
    }

    const client = new MongoClient(MONGODB_URI);
    await client.connect();

    const db = client.db(DB_NAME);
    const usersCollection = db.collection('users');

    // Find user by username only (not by password anymore)
    const user = await usersCollection.findOne({ username });

    if (!user) {
      // Use generic error message to prevent username enumeration
      return NextResponse.json(
        { error: 'Invalid credentials' },
        { status: 401 }
      );
    }

    // Compare hashed password
    const isPasswordValid = await bcrypt.compare(password, user.password);

    if (!isPasswordValid) {
      return NextResponse.json(
        { error: 'Invalid credentials' },
        { status: 401 }
      );
    }

    // Check if first login and password change required
    if (user.requirePasswordChange) {
      return NextResponse.json(
        {
          message: 'Password change required',
          requirePasswordChange: true,
          userId: user._id.toString()
        },
        { status: 200 }
      );
    }

    // Generate JWT token
    const token = jwt.sign(
      {
        userId: user._id.toString(),
        username: user.username,
        role: user.role
      },
      JWT_SECRET,
      { expiresIn: TOKEN_EXPIRY }
    );

    // Set HttpOnly cookie
    const cookie = serialize('authToken', token, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production', // Secure in production
      sameSite: 'strict',
      maxAge: 8 * 60 * 60, // 8 hours in seconds
      path: '/'
    });

    // Create a response that sets the cookie
    const response = NextResponse.json(
      {
        message: 'Login successful',
        user: {
          id: user._id.toString(),
          username: user.username,
          role: user.role
        }
      },
      { status: 200 }
    );

    response.headers.set('Set-Cookie', cookie);

    await client.close();
    return response;

  } catch (error) {
    console.error('Login error:', error);
    return NextResponse.json(
      { error: 'Authentication failed' },
      { status: 500 }
    );
  }
}
