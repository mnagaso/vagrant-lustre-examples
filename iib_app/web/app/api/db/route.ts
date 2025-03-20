import { NextResponse } from 'next/server';
import { getUsersCollection } from './init';

export async function GET() {
  try {
    await getUsersCollection();
    return NextResponse.json({ message: 'DB initialized successfully.' });
  } catch (error: any) {
    return NextResponse.json({ error: error.message });
  }
}
