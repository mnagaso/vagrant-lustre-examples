/**
 * This script updates existing user documents in the MongoDB database
 * to include an email field based on their username.
 *
 * Run with: node scripts/update_user_schema.js
 */

const { MongoClient } = require('mongodb');
require('dotenv').config({ path: '.env.local' });

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017';
const DB_NAME = process.env.DB_NAME || 'lustre_mgmt';

async function updateUserSchema() {
  const client = new MongoClient(MONGODB_URI);

  try {
    await client.connect();
    console.log('Connected to MongoDB');

    const db = client.db(DB_NAME);
    const usersCollection = db.collection('users');

    // Find all users without email
    const users = await usersCollection.find({ email: { $exists: false } }).toArray();

    console.log(`Found ${users.length} users without email field`);

    for (const user of users) {
      // Generate a default email based on username
      const defaultEmail = `${user.username}@example.com`;

      // Update the user document
      await usersCollection.updateOne(
        { _id: user._id },
        { $set: { email: defaultEmail } }
      );

      console.log(`Updated user ${user.username} with email ${defaultEmail}`);
    }

    console.log('User schema update completed');
  } catch (error) {
    console.error('Error updating user schema:', error);
  } finally {
    await client.close();
    console.log('MongoDB connection closed');
  }
}

updateUserSchema().catch(console.error);
