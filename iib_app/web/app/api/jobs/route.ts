import { NextResponse } from 'next/server';
import clientPromise from '@/lib/mongodb';

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const limit = parseInt(searchParams.get('limit') || '10');
    const status = searchParams.get('status');
    const user = searchParams.get('user');

    const client = await clientPromise;
    const db = client.db();

    // Build query based on filters
    const query: Record<string, string> = {};
    if (status) query.status = status;
    if (user) query.user = user;

    // Get jobs with pagination
    const jobs = await db
      .collection('jobs')
      .find(query)
      .sort({ submitted_at: -1 })
      .limit(limit)
      .toArray();

    return NextResponse.json({ jobs });
  } catch (error) {
    console.error('Error fetching jobs:', error);
    return NextResponse.json(
      { error: 'Failed to fetch jobs from database' },
      { status: 500 }
    );
  }
}
