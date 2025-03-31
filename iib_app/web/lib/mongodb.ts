import { MongoClient, Db } from 'mongodb';

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://db:27017';
const DB_NAME = process.env.DB_NAME || 'iib_db';

let cachedClient: MongoClient | null = null;
let cachedDb: Db | null = null;

export async function connectToDatabase() {
  // If we already have a connection, use it
  if (cachedClient && cachedDb) {
    return { client: cachedClient, db: cachedDb };
  }

  // Create a new connection
  const client = new MongoClient(MONGODB_URI);
  await client.connect();
  const db = client.db(DB_NAME);

  // Cache the connection
  cachedClient = client;
  cachedDb = db;

  return { client, db };
}

// Helper function to close the MongoDB connection
export async function closeMongoConnection() {
  if (cachedClient) {
    await cachedClient.close();
    cachedClient = null;
    cachedDb = null;
  }
}

// Add a default export that creates and manages a MongoDB client
const clientPromise = new MongoClient(MONGODB_URI).connect().then(client => {
  cachedClient = client;
  cachedDb = client.db(DB_NAME);
  return client;
});

export default clientPromise;
