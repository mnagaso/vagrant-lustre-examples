// This module establishes a connection to the MongoDB database,
// using the "mongodb" driver and connecting to the "db" service defined in docker-compose.
// The default database is set to "iib_db" and the users collection is "users" as initialized in mongo-init.js.
import { MongoClient, Collection } from 'mongodb';

const uri = process.env.MONGODB_URI || 'mongodb://db:27017/iib_db';
const options = {};

// Use cached connection pattern
let client: MongoClient;
let clientPromise: Promise<MongoClient>;

// In development, use a global variable so that the value
// is preserved across module reloads caused by HMR (Hot Module Replacement).
if (process.env.NODE_ENV === 'development') {
  // In development mode, use a global variable to preserve the value
  // across module reloads caused by HMR
  const globalWithMongo = global as typeof globalThis & {
    _mongoClientPromise?: Promise<MongoClient>
  };

  if (!globalWithMongo._mongoClientPromise) {
    client = new MongoClient(uri, options);
    globalWithMongo._mongoClientPromise = client.connect();
  }
  clientPromise = globalWithMongo._mongoClientPromise;
} else {
  // In production mode, it's best to not use a global variable
  client = new MongoClient(uri, options);
  clientPromise = client.connect();
}

export default clientPromise;

// Helper function to get the "users" collection as defined in mongo-init.js
export async function getUsersCollection(): Promise<Collection> {
  const client = await clientPromise;
  return client.db().collection('users');
}
