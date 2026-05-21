const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

// Mock names & realistic details for robust Indian testing scenarios
const mockCustomers = [
  {
    fullName: 'Vikram Malhotra',
    phone: '9876543214',
    email: 'vikram.malhotra@gmail.com',
    dob: '1988-08-15',
    address: '402, Royal Residency, Bandra West, Mumbai, Maharashtra 400050'
  },
  {
    fullName: 'Priya Patel',
    phone: '9123456780',
    email: 'priya.patel@yahoo.com',
    dob: '1995-03-22',
    address: 'Shop 12, Galaxy Arcade, Satellite, Ahmedabad, Gujarat 380015'
  },
  {
    fullName: 'Amit Kumar',
    phone: '9988776655',
    email: 'amit.kumar1@hotmail.com',
    dob: '1990-12-01',
    address: 'B-45, Sector 62, Noida, Uttar Pradesh 201301'
  },
  {
    fullName: 'Ananya Sharma',
    phone: '9812345678',
    email: 'ananya.s@gmail.com',
    dob: '2001-05-10',
    address: 'Flat 102, Emerald Heights, Whitefield, Bangalore, Karnataka 560066'
  },
  {
    fullName: 'Rahul Dravid',
    phone: '9845098450',
    email: 'thewall.rahul@cricket.in',
    dob: '1973-01-11',
    address: '12, Indira Nagar Main Road, Bengaluru, Karnataka 560038'
  },
  {
    fullName: 'Sunita Deshmukh',
    phone: '9567843210',
    email: 'sunita.d@outlook.com',
    dob: '1965-11-30',
    address: 'Plot 8, Sahakar Nagar, Pune, Maharashtra 411009'
  },
  {
    fullName: 'Karan Johar',
    phone: '9773388440',
    email: 'karan.movies@dharmaprod.com',
    dob: '1972-05-25',
    address: 'Bungalow 9, Carter Road, Bandra, Mumbai, Maharashtra 400050'
  },
  {
    fullName: 'Sneha Reddy',
    phone: '9440123456',
    email: 'sneha.reddy@gmail.com',
    dob: '1992-07-04',
    address: 'Flat 504, Jubilee Hills, Road No. 36, Hyderabad, Telangana 500033'
  },
  {
    fullName: 'Jasprit Bumrah',
    phone: '9331234567',
    email: 'boom.boom@bcci.tv',
    dob: '1993-12-06',
    address: 'A-14, Vastrapur Lakeshore, Ahmedabad, Gujarat 380015'
  },
  {
    fullName: 'Deepika Padukone',
    phone: '9667788990',
    email: 'deepika.p@global.com',
    dob: '1986-01-05',
    address: 'BeauMonde Towers, Prabhadevi, Mumbai, Maharashtra 400025'
  }
];

async function seedCustomers() {
  console.log('🚀 Starting complete Customer population process...\n');

  // 1. First, let's check all current existing customers and patch missing fields
  const existing = await prisma.customer.findMany();
  console.log(`📊 Found ${existing.length} existing customers in Database. Verifying and patching incomplete data...`);

  let patchedCount = 0;
  for (const cust of existing) {
    const needsPatch = !cust.dob || !cust.address || !cust.email || cust.dob === '' || cust.address === '';
    if (needsPatch) {
      // Generate realistic fallback values
      const birthYear = 1980 + Math.floor(Math.random() * 25);
      const birthMonth = String(1 + Math.floor(Math.random() * 12)).padStart(2, '0');
      const birthDay = String(1 + Math.floor(Math.random() * 28)).padStart(2, '0');
      
      const patchData = {
        email: cust.email || `${cust.fullName.toLowerCase().replace(/\s+/g, '.')}@example.com`,
        dob: cust.dob && cust.dob !== '' ? cust.dob : `${birthYear}-${birthMonth}-${birthDay}`,
        address: cust.address && cust.address !== '' ? cust.address : `Patched Addr: H-Block, Vikas Puri, New Delhi 110018`
      };

      await prisma.customer.update({
        where: { id: cust.id },
        data: patchData
      });
      
      patchedCount++;
    }
  }
  console.log(`✅ Patched ${patchedCount} existing incomplete customers with full address/DOB fallback details.`);

  // 2. Now, insert or upsert our high-quality Mock dataset for clean manual testing
  console.log('\n💉 Injecting clean testing mock customers (with real Addresses and DOBs)...');
  let injectedCount = 0;

  for (const mock of mockCustomers) {
    try {
      await prisma.customer.upsert({
        where: { phone: mock.phone },
        update: {
          fullName: mock.fullName,
          email: mock.email,
          dob: mock.dob,
          address: mock.address
        },
        create: mock
      });
      console.log(`  ✓ Populated/Verified: ${mock.fullName} (${mock.phone})`);
      injectedCount++;
    } catch (err) {
      console.error(`  ❌ Failed for ${mock.fullName}:`, err.message);
    }
  }

  const finalCount = await prisma.customer.count();
  console.log(`\n✨ Database Operation Successful!`);
  console.log(`   🏁 Verified Mock Customers Created: ${injectedCount}`);
  console.log(`   🏠 Total Registered Customers in Database now: ${finalCount}`);
}

seedCustomers()
  .catch(console.error)
  .finally(async () => await prisma.$disconnect());
