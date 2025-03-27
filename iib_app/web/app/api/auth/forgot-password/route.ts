import { NextResponse } from 'next/server';
import crypto from 'crypto';
import { sendEmail } from '../../../../lib/email';
import { MongoClient } from 'mongodb';

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017';
const DB_NAME = process.env.DB_NAME || 'lustre_mgmt';

export async function POST(request: Request) {
  try {
    const { email } = await request.json();

    const token = crypto.randomBytes(32).toString('hex');

    // Connect to MongoDB
    const client = new MongoClient(MONGODB_URI);
    await client.connect();
    const db = client.db(DB_NAME);
    const usersCollection = db.collection('users');

    // If user exists, store the password reset token and expiry (1 hour)
    const user = await usersCollection.findOne({ email });
    if (user) {
      await usersCollection.updateOne(
        { _id: user._id },
        { $set: { resetToken: token, resetTokenExpiry: new Date(Date.now() + 3600000) } }
      );
    }
    await client.close();

    // Send an email with the password reset token
    await sendEmail({
      to: email,
      subject: "Password Reset",
      text: `Your password reset token is: ${token}`
    });

    console.log(`Password reset requested for email: ${email}. Token: ${token}`);

    return NextResponse.json({
      message: "If an account with that email exists, a password reset link has been sent."
    });
  } catch (error) {
    console.error("Error processing password reset request:", error);
    return NextResponse.json({ message: "Invalid request." }, { status: 400 });
  }
}
