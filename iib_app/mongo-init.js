db = db.getSiblingDB('iib_db');

// Create users collection if it doesn't exist
if (!db.getCollectionNames().includes('users')) {
  db.createCollection('users');

  // Insert default admin user
  db.users.insertOne({
    username: "admin",
    password: "admin", // In production, use proper password hashing
    createdAt: new Date()
  });

  print("Created 'users' collection and added default admin user");
}
