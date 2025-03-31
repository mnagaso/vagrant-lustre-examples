import { NextResponse } from 'next/server';
import { MongoClient } from 'mongodb';
import crypto from 'crypto';
import { sendEmail } from '@/lib/email';

const MONGODB_URI = process.env.MONGODB_URI || "mongodb://localhost:27017";
const DB_NAME = process.env.DB_NAME || "lustre_mgmt";
const BASE_URL = process.env.BASE_URL || 'http://localhost:3000';

export async function POST(request: Request) {
  try {
    const { email } = await request.json();

    if (!email) {
      return NextResponse.json(
        { error: 'Email address is required' },
        { status: 400 }
      );
    }

    // Connect to the database
    const client = new MongoClient(MONGODB_URI);
    await client.connect();
    const db = client.db(DB_NAME);
    const usersCollection = db.collection('users');

    // Check if user exists with this email
    const user = await usersCollection.findOne({ email });

    if (!user) {
      // For security, don't reveal whether email exists or not
      await client.close();
      return NextResponse.json(
        { message: 'If your email exists in our system, you will receive reset instructions shortly' },
        { status: 200 }
      );
    }

    // Generate reset token
    const resetToken = crypto.randomBytes(32).toString('hex');
    const resetTokenExpiry = new Date(Date.now() + 3600000); // 1 hour from now

    // Update user with reset token
    await usersCollection.updateOne(
      { _id: user._id },
      { $set: { resetToken, resetTokenExpiry } }
    );

    // Create reset URL
    const resetUrl = `${BASE_URL}/reset-password?token=${resetToken}`;

    // Send email with reset link
    await sendEmail({
      to: email,
      subject: 'IIB Cluster - Password Reset',
      text: `You requested a password reset for your IIB Cluster account. Please use the following link to reset your password: ${resetUrl}\n\nIf you didn't request this, please ignore this email.`,
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2>Password Reset Request</h2>
          <p>You requested a password reset for your IIB Cluster account.</p>
          <p>Please click the button below to reset your password:</p>
          <p style="text-align: center; margin: 20px 0;">
            <a href="${resetUrl}" style="background-color: #0066cc; color: white; padding: 10px 20px; text-decoration: none; border-radius: 4px; display: inline-block;">Reset Your Password</a>
          </p>
          <p>If the button doesn't work, you can also copy and paste this link into your browser:</p>
          <p style="word-break: break-all; color: #0066cc;">${resetUrl}</p>
          <p>This link will expire in 1 hour.</p>
          <p>If you didn't request this password reset, please ignore this email and your password will remain unchanged.</p>
        </div>
      `
    });

    await client.close();

    // Return success response
    return NextResponse.json(
      { message: 'If your email exists in our system, you will receive reset instructions shortly' },
      { status: 200 }
    );
  } catch (error) {
    console.error('Password reset error:', error);
    return NextResponse.json(
      { error: 'An error occurred while processing your request' },
      { status: 500 }
    );
  }
}
