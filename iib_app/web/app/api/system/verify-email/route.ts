import { NextResponse } from 'next/server';
import { verifyEmailConfig } from '@/lib/email';

export async function GET() {
  try {
    const isValid = await verifyEmailConfig();

    if (isValid) {
      return NextResponse.json({
        status: 'ok',
        message: 'Email configuration verified successfully'
      });
    } else {
      return NextResponse.json({
        status: 'error',
        message: 'Email configuration is invalid'
      }, { status: 500 });
    }
  } catch (error) {
    console.error('Email verification error:', error);
    return NextResponse.json({
      status: 'error',
      message: 'Failed to verify email configuration'
    }, { status: 500 });
  }
}