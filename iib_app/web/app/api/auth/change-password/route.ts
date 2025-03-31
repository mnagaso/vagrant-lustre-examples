import { NextRequest, NextResponse } from 'next/server';
import { MongoClient, ObjectId } from 'mongodb';
import bcrypt from 'bcryptjs';

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://db:27017';
const DB_NAME = process.env.DB_NAME || 'iib_db';

export async function POST(req: NextRequest) {
  try {
    const { userId, currentPassword, newPassword } = await req.json();

    if (!userId || !currentPassword || !newPassword) {
      return NextResponse.json(
        { error: 'All fields are required' },
        { status: 400 }
      );
    }

    // Password strength validation
    if (newPassword.length < 10) {
      return NextResponse.json(
        { error: 'New password must be at least 10 characters long' },
        { status: 400 }
      );
    }

    // Pattern matching for complexity
    const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{10,}$/;
    if (!passwordRegex.test(newPassword)) {
      return NextResponse.json({
        error: 'Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character'
      }, { status: 400 });
    }

    const client = new MongoClient(MONGODB_URI);
    await client.connect();

    const db = client.db(DB_NAME);
    const usersCollection = db.collection('users');

    const user = await usersCollection.findOne({ _id: new ObjectId(userId) });

    if (!user) {
      await client.close();
      return NextResponse.json(
        { error: 'User not found' },
        { status: 404 }
      );
    }

    // Verify current password
    const isCurrentPasswordValid = await bcrypt.compare(currentPassword, user.password);
    if (!isCurrentPasswordValid) {
      await client.close();
      return NextResponse.json(
        { error: 'Current password is incorrect' },
        { status: 401 }
      );
    }

    // Hash the new password
    const salt = await bcrypt.genSalt(12);
    const hashedNewPassword = await bcrypt.hash(newPassword, salt);

    // Update password and clear requirePasswordChange flag
    await usersCollection.updateOne(
      { _id: new ObjectId(userId) },
      {
        $set: {
          password: hashedNewPassword,
          requirePasswordChange: false,
          passwordLastChanged: new Date()
        }
      }
    );

    await client.close();

    return NextResponse.json(
      { message: 'Password changed successfully' },
      { status: 200 }
    );

  } catch (error) {
    console.error('Password change error:', error);
    return NextResponse.json(
      { error: 'Failed to change password' },
      { status: 500 }
    );
  }
}
