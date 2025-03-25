print('Starting MongoDB initialization...');

try {
  // Get the database name from environment or use default
  const dbName = _getEnv('MONGO_INITDB_DATABASE') || 'iib_db';
  print(`Using database: ${dbName}`);

  // Switch to the database (creates it if it doesn't exist)
  db = db.getSiblingDB(dbName);

  // Create users collection if it doesn't exist
  if (!db.getCollectionNames().includes('users')) {
    db.createCollection('users');

    // Insert default admin user
    db.users.insertOne({
      username: "admin",
      password: "admin", // In production, use proper password hashing
      role: "admin",
      createdAt: new Date()
    });

    print("Created 'users' collection and added default admin user");
  } else {
    print("'users' collection already exists");
  }

  // Create jobs collection for Slurm job information
  if (!db.getCollectionNames().includes('jobs')) {
    db.createCollection('jobs');
    print("Created 'jobs' collection");
  }

  // Create cluster_status collection for Lustre metrics
  if (!db.getCollectionNames().includes('cluster_status')) {
    db.createCollection('cluster_status');
    print("Created 'cluster_status' collection");
  }

  print('MongoDB initialization completed successfully');
} catch (error) {
  print('Error during MongoDB initialization: ' + error);
}
