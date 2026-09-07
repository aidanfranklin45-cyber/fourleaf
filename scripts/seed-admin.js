import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import bcrypt from 'bcryptjs';
import mongoose from 'mongoose';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const rootDir = path.resolve(__dirname, '..');
const envPath = path.join(rootDir, '.env.fourleaf');

let MONGO_URL = process.env.MONGO_URL;
if (!MONGO_URL && fs.existsSync(envPath)) {
  const lines = fs.readFileSync(envPath, 'utf8').split(/\r?\n/);
  for (const line of lines) {
    const trimmed = line.trim();
    if (trimmed.startsWith('MONGO_URL=')) {
      MONGO_URL = trimmed.slice('MONGO_URL='.length).trim();
      break;
    }
  }
}

if (!MONGO_URL) {
  console.error(
    'Error: MONGO_URL is not defined in process.env or .env.fourleaf'
  );
  process.exit(1);
}

async function seed() {
  console.log('Connecting to MongoDB Atlas...');
  await mongoose.connect(MONGO_URL);
  console.log('Connected.');

  const email = 'aidan.franklin45@gmail.com'.toLowerCase();
  const rawPassword = 'Password123!';
  const hashedPassword = bcrypt.hashSync(rawPassword, 10);

  const accountsColl = mongoose.connection.db.collection('accounts');
  const realmsColl = mongoose.connection.db.collection('realms');

  // Upsert account
  const existingAccount = await accountsColl.findOne({ email });
  if (!existingAccount) {
    console.log(`Creating landlord admin account for ${email}...`);
    await accountsColl.insertOne({
      firstname: 'Aidan',
      lastname: 'Franklin',
      email,
      password: hashedPassword,
      mustChangePassword: false,
      createdDate: new Date().toISOString()
    });
    console.log(`Account created. Login: ${email} / ${rawPassword}`);
  } else {
    console.log(`Updating password for ${email}...`);
    await accountsColl.updateOne(
      { email },
      { $set: { password: hashedPassword } }
    );
    console.log(`Password reset to ${rawPassword}`);
  }

  // Upsert organization (Realm)
  const existingRealm = await realmsColl.findOne({ 'member1.email': email });
  if (!existingRealm) {
    console.log('Creating organization FourLeaf Real Estate...');
    await realmsColl.insertOne({
      name: 'FourLeaf Real Estate',
      member1: { name: 'Aidan Franklin', email },
      member2: null,
      addresses: [
        {
          street1: '100 Main Street',
          city: 'Austin',
          state: 'TX',
          zipCode: '78701',
          country: 'United States'
        }
      ],
      contacts: [
        {
          name: 'Aidan Franklin',
          email,
          phone1: '555-123-4567'
        }
      ],
      bankInfo: { name: '', iban: '' },
      isCompany: false,
      locale: 'en',
      currency: 'USD'
    });
    console.log('Organization FourLeaf Real Estate created.');
  } else {
    console.log('Organization already exists.');
  }

  await mongoose.disconnect();
  console.log('Done!');
}

seed().catch((err) => {
  console.error('Error seeding admin:', err);
  process.exit(1);
});
