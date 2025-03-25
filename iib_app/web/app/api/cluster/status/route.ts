import { NextResponse } from 'next/server';
import clientPromise from '@/lib/mongodb';

export async function GET() {
  try {
    const client = await clientPromise;
    const db = client.db();

    // Get latest cluster status
    const status = await db
      .collection('cluster_status')
      .find({})
      .sort({ timestamp: -1 })
      .limit(1)
      .toArray();

    return NextResponse.json({ status: status[0] || null });
  } catch (error) {
    console.error('Error fetching cluster status:', error);
    return NextResponse.json(
      { error: 'Failed to fetch cluster status from database' },
      { status: 500 }
    );
  }
}
