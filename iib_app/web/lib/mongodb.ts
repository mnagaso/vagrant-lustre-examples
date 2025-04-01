import { MongoClient, Db } from 'mongodb';

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://db:27017';
const DB_NAME = process.env.DB_NAME || 'iib_db';

let clientPromise: Promise<MongoClient> | null = null;

function createClientPromise(): Promise<MongoClient> {
  if (!clientPromise) {
    clientPromise = new MongoClient(MONGODB_URI)
      .connect()
      .then(client => client)
      .catch(error => {
        // Reset clientPromise on error to allow retrying
        clientPromise = null;
        throw error;
      });
  }
  return clientPromise;
}

export async function connectToDatabase() {
  const client = await createClientPromise();
  const db: Db = client.db(DB_NAME);
  return { client, db };
}

export async function closeMongoConnection() {
  if (clientPromise) {
    const client = await clientPromise;
    await client.close();
    clientPromise = null;
  }
}

export default createClientPromise();
