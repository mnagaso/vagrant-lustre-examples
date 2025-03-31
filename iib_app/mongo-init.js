function _getEnv(key) {
  if (typeof process !== 'undefined' && process.env && process.env[key]) {
    return process.env[key];
  }
  if (typeof getenv === 'function') {
    return getenv(key);
  }
  return null;
}

print('Starting MongoDB initialization...');

try {
  // Get the database name from environment or use default
  const dbName = _getEnv('MONGO_INITDB_DATABASE') || 'iib_db';
  print(`Using database: ${dbName}`);

  // Switch to the database (creates it if it doesn't exist)
  db = db.getSiblingDB(dbName);

  // Create collections if they don't exist
  db.createCollection('users');
  db.createCollection('jobs');
  db.createCollection('system_settings');

  // Create indexes
  db.users.createIndex({ "username": 1 }, { unique: true });
  db.users.createIndex({ "email": 1 }, { unique: true });
  db.users.createIndex({ "resetToken": 1 });
  db.jobs.createIndex({ "user_id": 1 });
  db.jobs.createIndex({ "status": 1 });
  db.jobs.createIndex({ "submitted_at": -1 });

  // Add default admin user
  const adminUser = db.users.findOne({ username: 'admin' });
  if (!adminUser) {
    db.users.insertOne({
      username: 'admin',
      // 'admin' hashed with bcrypt,  using a salt rounds of 12 and web/script/bcript-hash.js
      password: '$2b$12$tVFPFMLvrdNClCButh1zFeFYqQNmGecCnWA4KTq4YZpXfYh7t.RJm',
      email: 'mnsaru18@gmail.com',
      role: 'admin',
      fullName: 'System Administrator',
      createdAt: new Date(),
      lastLogin: null,
      requirePasswordChange: false
    });
    print('Created admin user');
  }

  // Add default test users
  const testUsers = [
    {
      username: 'researcher1',
      password: '$2b$12$fCETukrG9yuy7dFuX79eNuyV3i/BtyaN61qzy95JnaeThxZRCrHam', // 'password123' hashed with bcrypt
      email: 'researcher1@iibcluster.local',
      role: 'user',
      fullName: 'Test Researcher 1',
      createdAt: new Date(),
      lastLogin: null,
      requirePasswordChange: true
    },
    {
      username: 'researcher2',
      password: '$2b$12$fCETukrG9yuy7dFuX79eNuyV3i/BtyaN61qzy95JnaeThxZRCrHam', // 'password123' hashed with bcrypt
      email: 'researcher2@iibcluster.local',
      role: 'user',
      fullName: 'Test Researcher 2',
      createdAt: new Date(),
      lastLogin: null,
      requirePasswordChange: true
    }
  ];

  testUsers.forEach(user => {
    const existingUser = db.users.findOne({ username: user.username });
    if (!existingUser) {
      db.users.insertOne(user);
      print(`Created test user: ${user.username}`);
    }
  });

  // Add system settings
  const systemSettings = db.system_settings.findOne({ _id: 'email_config' });
  if (!systemSettings) {
    db.system_settings.insertOne({
      _id: 'email_config',
      emailNotificationsEnabled: true,
      emailVerificationRequired: false,
      updatedAt: new Date()
    });
    print('Initialized system settings');
  }

  print('MongoDB initialization completed');
} catch (error) {
  print('Error during MongoDB initialization: ' + error);
}
