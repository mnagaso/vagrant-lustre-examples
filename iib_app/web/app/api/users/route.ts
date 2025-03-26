import { NextRequest, NextResponse } from 'next/server';
import clientPromise from '@/lib/mongodb';
import { MongoClient } from 'mongodb';
import bcrypt from 'bcryptjs';
import { authMiddleware } from '../../../lib/auth';

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017';
const DB_NAME = process.env.DB_NAME || 'lustre_mgmt';

export async function GET() {
  try {
    const client = await clientPromise;
    const db = client.db();

    // Get all users except their passwords
    const users = await db
      .collection('users')
      .find({})
      .project({ password: 0 })
      .toArray();

    return NextResponse.json({ users });
  } catch (error) {
    console.error('Error fetching users:', error);
    return NextResponse.json(
      { error: 'Failed to fetch users from database' },
      { status: 500 }
    );
  }
}

// Create a new user
export async function POST(req: NextRequest) {
  try {
    // Only admins can create users - validate admin role
    const authResult = await authMiddleware(req);
    if (!authResult.isAuthenticated || authResult.user?.role !== 'admin') {
      return NextResponse.json(
        { error: 'Unauthorized' },
        { status: 403 }
      );
    }

    const { username, password, role } = await req.json();

    if (!username || !password) {
      return NextResponse.json(
        { error: 'Username and password are required' },
        { status: 400 }
      );
    }

    // Validate password strength
    if (password.length < 10) {
      return NextResponse.json(
        { error: 'Password must be at least 10 characters long' },
        { status: 400 }
      );
    }

    const client = new MongoClient(MONGODB_URI);
    await client.connect();

    const db = client.db(DB_NAME);
    const usersCollection = db.collection('users');

    // Check if user already exists
    const existingUser = await usersCollection.findOne({ username });
    if (existingUser) {
      await client.close();
      return NextResponse.json(
        { error: 'Username already exists' },
        { status: 409 }
      );
    }

    // Hash the password
    const salt = await bcrypt.genSalt(12);
    const hashedPassword = await bcrypt.hash(password, salt);

    const newUser = {
      username,
      password: hashedPassword,
      role: role || 'user',
      createdAt: new Date(),
      requirePasswordChange: true // Force password change on first login
    };

    await usersCollection.insertOne(newUser);
    await client.close();

    return NextResponse.json(
      {
        message: 'User created successfully',
        user: { username, role: newUser.role }
      },
      { status: 201 }
    );

  } catch (error) {
    console.error('User creation error:', error);
    return NextResponse.json(
      { error: 'Failed to create user' },
      { status: 500 }
    );
  }
}
