import { NextResponse } from 'next/server';
import { MongoClient } from 'mongodb';

const uri = process.env.MONGODB_URI || "mongodb://db:27017";

const client = new MongoClient(uri);
let cachedDb: any = null;

async function connectToDatabase() {
  if (cachedDb) return cachedDb;

  try {
    await client.connect();
    const db = client.db("iib_db");
    cachedDb = db;
    return db;
  } catch (error) {
    console.error("Database connection error:", error);
    throw error;
  }
}

export async function POST(request: Request) {
  try {
    const { username, password } = await request.json();

    const db = await connectToDatabase();
    const usersCollection = db.collection("users");

    // Basic authentication check. In production, use proper password hashing.
    const user = await usersCollection.findOne({ username, password });
    if (!user) {
      return NextResponse.json({ error: "Invalid credentials" }, { status: 401 });
    }

    return NextResponse.json({ message: "Login successful", userId: user._id });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
