class MockData {
  // --- AUTH ---
  static const Map<String, dynamic> mockUser = {
    "id": "mock-user-123",
    "name": "Branding Executive",
    "email": "branding@gmail.com",
    "role": "Admin",
    "companyId": "mock-company-999",
    "accountId": "9998887776",
    "token": "mock-jwt-token-xyz-123"
  };

  // --- DASHBOARD METRICS (Dynamic) ---
  static double totalRevenue = 125000.0; // Total sales
  static double cashInHand = 95000.0;   // Cash collected before expenses
  static double cashCollection = 95000.0;
  static double bankCollection = 20000.0;
  static double upiCollection = 10000.0;
  static double totalExpenses = 33500.0; // Sum of dummy items

  static Map<String, dynamic> getDashboardMetrics() {
    // Dynamically calculate net cash
    double netCash = cashInHand - totalExpenses;
    
    return {
      "todayCollection": totalRevenue,
      "cashInHand": netCash > 0 ? netCash : 0.0, // Don't show negative cash
      "cashCollection": cashCollection,
      "bankCollection": bankCollection,
      "upiCollection": upiCollection,
      "totalExpenses": totalExpenses,
      "activeJobCards": 12,
      "pendingTasks": 8,
      "lowStockCount": 15,
      "recentOrders": mockOrders.length,
    };
  }

  static void addSale(double amount, {String mode = 'Cash'}) {
    totalRevenue += amount;
    if (mode == 'Cash') {
      cashCollection += amount;
      cashInHand += amount;
    } else if (mode == 'Bank') {
      bankCollection += amount;
    } else {
      upiCollection += amount;
    }
    // ignore: avoid_print
    print('💰 [MockData] Sale Added: ₹$amount ($mode). New Revenue: ₹$totalRevenue');
  }

  static void addExpense(double amount, {String category = 'Misc', String note = ''}) {
    final now = DateTime.now();
    final dateStr = "${now.day}-${now.month}-${now.year}";
    
    mockExpenses.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'date': dateStr,
      'category': category,
      'amount': amount,
      'note': note,
      'type': 'Payment'
    });
    
    totalExpenses += amount;
    // ignore: avoid_print
    print('💸 [MockData] Expense Added: ₹$amount ($category). Total Expenses: ₹$totalExpenses');
  }

  // --- ORDERS ---
  static final List<Map<String, dynamic>> mockOrders = [
    {
      "id": "RX-113",
      "customer": "Rajesh Kumar",
      "mobile": "9800112233",
      "status": "Pending",
      "amount": "6500.0",
      "paidAmount": "0.0",
      "dueAmount": "6500.0",
      "date": "2026-04-29",
      "sn": "JC/2024/013",
      "type": "RX",
      "items": [
        {"eye": "R", "sph": "-2.50", "cyl": "-1.00", "axis": "180", "add": "0.00", "totalAmount": "3250.0"},
        {"eye": "L", "sph": "-2.25", "cyl": "-1.25", "axis": "175", "add": "0.00", "totalAmount": "3250.0"}
      ]
    },
    {
      "id": "RX-114",
      "customer": "Sneha Patil",
      "mobile": "9100223344",
      "status": "Ready",
      "amount": "11200.0",
      "paidAmount": "5000.0",
      "dueAmount": "6200.0",
      "date": "2026-04-29",
      "sn": "JC/2024/014",
      "type": "RX",
      "items": [
        {"eye": "R", "sph": "+1.50", "cyl": "0.00", "axis": "0", "add": "+2.25", "totalAmount": "5600.0"},
        {"eye": "L", "sph": "+1.75", "cyl": "0.00", "axis": "0", "add": "+2.25", "totalAmount": "5600.0"}
      ]
    },
    {
      "id": "RX-115",
      "customer": "Anil Deshmukh",
      "mobile": "8811223344",
      "status": "In Progress",
      "amount": "4800.0",
      "paidAmount": "4800.0",
      "dueAmount": "0.0",
      "date": "2026-04-29",
      "sn": "JC/2024/015",
      "type": "RX",
      "items": [
        {"eye": "R", "sph": "-1.00", "cyl": "-0.50", "axis": "10", "add": "0.00", "totalAmount": "2400.0"},
        {"eye": "L", "sph": "-1.00", "cyl": "-0.50", "axis": "170", "add": "0.00", "totalAmount": "2400.0"}
      ]
    },
    {
      "id": "RX-116",
      "customer": "Jyoti Rao",
      "mobile": "7700112233",
      "status": "Ready",
      "amount": "3600.0",
      "paidAmount": "3600.0",
      "dueAmount": "0.0",
      "date": "2026-04-29",
      "sn": "JC/2024/016",
      "type": "RX",
      "items": [
        {"eye": "R", "sph": "0.00", "cyl": "0.00", "axis": "0", "add": "0.00", "totalAmount": "1800.0"},
        {"eye": "L", "sph": "0.00", "cyl": "0.00", "axis": "0", "add": "0.00", "totalAmount": "1800.0"}
      ]
    },
    {
      "id": "RX-117",
      "customer": "Harish Gupta",
      "mobile": "6600112233",
      "status": "Delivered",
      "amount": "15500.0",
      "paidAmount": "15500.0",
      "dueAmount": "0.0",
      "date": "2026-04-28",
      "sn": "JC/2024/017",
      "type": "RX",
      "items": [
        {"eye": "R", "sph": "-5.50", "cyl": "-2.00", "axis": "90", "add": "+1.50", "totalAmount": "7750.0"},
        {"eye": "L", "sph": "-5.75", "cyl": "-1.75", "axis": "85", "add": "+1.50", "totalAmount": "7750.0"}
      ]
    },
    {
      "id": "RX-101",
      "customer": "Vikas Salvi",
      "mobile": "9876543210",
      "status": "In Progress",
      "amount": "4500.0",
      "paidAmount": "1500.0",
      "dueAmount": "3000.0",
      "date": "2026-04-29",
      "sn": "JC/2024/001",
      "type": "RX",
      "items": [
        {"eye": "R", "sph": "-2.50", "cyl": "-0.50", "axis": "180", "add": "+2.00", "totalAmount": "2250.0"},
        {"eye": "L", "sph": "-2.25", "cyl": "-0.75", "axis": "170", "add": "+2.00", "totalAmount": "2250.0"}
      ]
    },
    {
      "id": "RX-105",
      "customer": "Anjali Gupta",
      "mobile": "9988776655",
      "status": "In Progress",
      "amount": "1200.0",
      "paidAmount": "500.0",
      "dueAmount": "700.0",
      "date": "2026-04-29",
      "sn": "JC/2024/005",
      "type": "RX",
      "items": [
        {"eye": "R", "sph": "-1.00", "cyl": "0.00", "axis": "0", "add": "0.00", "totalAmount": "600.0"},
        {"eye": "L", "sph": "-1.00", "cyl": "0.00", "axis": "0", "add": "0.00", "totalAmount": "600.0"}
      ]
    },
    {
      "id": "RX-106",
      "customer": "Siddharth Malhotra",
      "mobile": "9900887766",
      "status": "In Progress",
      "amount": "5200.0",
      "paidAmount": "2000.0",
      "dueAmount": "3200.0",
      "date": "2026-04-29",
      "sn": "JC/2024/006",
      "type": "RX",
      "items": [
        {"eye": "R", "sph": "-3.00", "cyl": "-1.25", "axis": "90", "add": "+1.75", "totalAmount": "2600.0"},
        {"eye": "L", "sph": "-3.25", "cyl": "-1.00", "axis": "85", "add": "+1.75", "totalAmount": "2600.0"}
      ]
    },
    {
      "id": "RX-107",
      "customer": "Rahul Verma",
      "mobile": "7766554433",
      "status": "In Progress",
      "amount": "3800.0",
      "paidAmount": "3800.0",
      "dueAmount": "0.0",
      "date": "2026-04-29",
      "sn": "JC/2024/007",
      "type": "RX",
      "items": [
        {"eye": "R", "sph": "-0.50", "cyl": "-0.25", "axis": "10", "add": "0.00", "totalAmount": "1900.0"},
        {"eye": "L", "sph": "-0.75", "cyl": "0.00", "axis": "0", "add": "0.00", "totalAmount": "1900.0"}
      ]
    },
    {
      "id": "RX-108",
      "customer": "Priya Patel",
      "mobile": "8877665544",
      "status": "In Progress",
      "amount": "2500.0",
      "paidAmount": "1000.0",
      "dueAmount": "1500.0",
      "date": "2026-04-29",
      "sn": "JC/2024/008",
      "type": "RX",
      "items": [
        {"eye": "R", "sph": "-4.00", "cyl": "-0.50", "axis": "45", "add": "0.00", "totalAmount": "1250.0"},
        {"eye": "L", "sph": "-4.00", "cyl": "-0.50", "axis": "45", "add": "0.00", "totalAmount": "1250.0"}
      ]
    },
    {
      "id": "RX-109",
      "customer": "Vikram Singh",
      "mobile": "9812345678",
      "status": "Delivered",
      "amount": "8500.0",
      "paidAmount": "8500.0",
      "dueAmount": "0.0",
      "date": "2026-04-28",
      "sn": "JC/2024/009",
      "type": "RX",
      "items": [
        {"eye": "R", "sph": "+2.00", "cyl": "-0.50", "axis": "90", "add": "+2.50", "totalAmount": "4250.0"},
        {"eye": "L", "sph": "+2.25", "cyl": "-0.25", "axis": "85", "add": "+2.50", "totalAmount": "4250.0"}
      ]
    },
    {
      "id": "RX-110",
      "customer": "Meera Joshi",
      "mobile": "9988001122",
      "status": "Ready",
      "amount": "4200.0",
      "paidAmount": "1000.0",
      "dueAmount": "3200.0",
      "date": "2026-04-28",
      "sn": "JC/2024/010",
      "type": "RX",
      "items": [
        {"eye": "R", "sph": "-1.50", "cyl": "-0.75", "axis": "15", "add": "0.00", "totalAmount": "2100.0"},
        {"eye": "L", "sph": "-1.75", "cyl": "-0.50", "axis": "165", "add": "0.00", "totalAmount": "2100.0"}
      ]
    },
    {
      "id": "RX-111",
      "customer": "Sanjay Gupta",
      "mobile": "8800771122",
      "status": "Delivered",
      "amount": "2100.0",
      "paidAmount": "2100.0",
      "dueAmount": "0.0",
      "date": "2026-04-27",
      "sn": "JC/2024/011",
      "type": "RX",
      "items": [
        {"eye": "R", "sph": "-0.25", "cyl": "0.00", "axis": "0", "add": "0.00", "totalAmount": "1050.0"},
        {"eye": "L", "sph": "-0.25", "cyl": "0.00", "axis": "0", "add": "0.00", "totalAmount": "1050.0"}
      ]
    },
    {
      "id": "RX-112",
      "customer": "Kavita Rao",
      "mobile": "7722110099",
      "status": "Ready",
      "amount": "9600.0",
      "paidAmount": "5000.0",
      "dueAmount": "4600.0",
      "date": "2026-04-27",
      "sn": "JC/2024/012",
      "type": "RX",
      "items": [
        {"eye": "R", "sph": "+1.00", "cyl": "-1.00", "axis": "45", "add": "+2.00", "totalAmount": "4800.0"},
        {"eye": "L", "sph": "+1.25", "cyl": "-0.75", "axis": "135", "add": "+2.00", "totalAmount": "4800.0"}
      ]
    },
    {
      "id": "RX-102",
      "customer": "Amit Sharma",
      "mobile": "9123456789",
      "status": "Pending",
      "amount": "3200.0",
      "paidAmount": "1000.0",
      "dueAmount": "2200.0",
      "date": "2024-04-29",
      "sn": "JC/2024/002",
      "type": "RX"
    },
    {
      "id": "RX-103",
      "customer": "Priya Patel",
      "mobile": "8877665544",
      "status": "Ready",
      "amount": "2800.0",
      "paidAmount": "2800.0",
      "dueAmount": "0.0",
      "date": "2024-04-28",
      "sn": "JC/2024/003",
      "type": "RX"
    },
    {
      "id": "RX-104",
      "customer": "Rahul Verma",
      "mobile": "7766554433",
      "status": "Delivered",
      "amount": "5500.0",
      "paidAmount": "5500.0",
      "dueAmount": "0.0",
      "date": "2024-04-27",
      "sn": "JC/2024/004",
      "type": "RX"
    },
    // --- AMIT SHARMA HISTORY ---
    {
      "id": "HIST-1",
      "customer": "Amit Sharma",
      "mobile": "9876543210",
      "status": "Delivered",
      "amount": "9300.0",
      "paidAmount": "9300.0",
      "dueAmount": "0.0",
      "date": "2023-05-15",
      "sn": "JC/2023/101",
      "type": "RX",
      "items": [
        {"itemName": "Ray-Ban Aviator", "eye": "RL", "sph": "0.00", "cyl": "0.00", "axis": "0", "price": 8500.0, "quantity": 1},
        {"itemName": "ARC Coating", "eye": "RL", "sph": "0.00", "cyl": "0.00", "axis": "0", "price": 800.0, "quantity": 1}
      ]
    },
    {
      "id": "HIST-2",
      "customer": "Amit Sharma",
      "mobile": "9876543210",
      "status": "Delivered",
      "amount": "450.0",
      "paidAmount": "450.0",
      "dueAmount": "0.0",
      "date": "2023-09-20",
      "sn": "JC/2023/245",
      "type": "Bulk",
      "items": [
        {"itemName": "Renu Solution 300ml", "qty": 1, "salePrice": 450.0, "totalAmount": 450.0}
      ]
    },
    {
      "id": "HIST-3",
      "customer": "Amit Sharma",
      "mobile": "9876543210",
      "status": "Delivered",
      "amount": "5700.0",
      "paidAmount": "5700.0",
      "dueAmount": "0.0",
      "date": "2024-02-10",
      "sn": "JC/2024/012",
      "type": "RX",
      "items": [
        {"itemName": "Titan Rimless", "eye": "R", "sph": "-1.50", "cyl": "-0.50", "axis": "90", "price": 4500.0, "quantity": 1},
        {"itemName": "Blue Cut Lens", "eye": "L", "sph": "-1.50", "cyl": "-0.50", "axis": "90", "price": 1200.0, "quantity": 1}
      ]
    }
  ];

  // --- INVENTORY ---
  static final List<Map<String, dynamic>> mockInventory = [
    // FRAMES
    {"itemName": "Ray-Ban Aviator Gold", "openingStockQty": 8, "alertQty": 2, "purchasePrice": 8500.0, "groupName": "Frames", "type": "Frame", "receivedDate": "2026-01-15 09:30 AM", "vendorName": "Vision Care Lab"},
    {"itemName": "Oakley Holbrook Black", "openingStockQty": 12, "alertQty": 3, "purchasePrice": 11200.0, "groupName": "Frames", "type": "Frame", "receivedDate": "2026-02-10 11:45 AM", "vendorName": "Precision Lens Lab"},
    {"itemName": "Titan Rimless Elite", "openingStockQty": 4, "alertQty": 5, "purchasePrice": 4500.0, "groupName": "Frames", "type": "Frame", "receivedDate": "2026-03-05 02:15 PM", "vendorName": "Prime Frames & Optics"},
    {"itemName": "Gucci Square Premium", "openingStockQty": 2, "alertQty": 1, "purchasePrice": 18000.0, "groupName": "Frames", "type": "Frame", "receivedDate": "2026-04-01 10:00 AM", "vendorName": "Elite Optical Hub"},
    {"itemName": "Vogue Butterfly Pink", "openingStockQty": 6, "alertQty": 2, "purchasePrice": 6200.0, "groupName": "Frames", "type": "Frame", "receivedDate": "2026-04-12 04:30 PM", "vendorName": "Spectrum Lens Solutions"},
    
    // LENSES
    {"itemName": "Essilor Crizal Sapphire", "openingStockQty": 15, "alertQty": 5, "purchasePrice": 3500.0, "groupName": "Lenses", "type": "Lens", "receivedDate": "2026-01-20 09:00 AM", "vendorName": "Vision Care Lab"},
    {"itemName": "Zeiss Blue Guard Lens", "openingStockQty": 3, "alertQty": 5, "purchasePrice": 2800.0, "groupName": "Lenses", "type": "Lens", "receivedDate": "2026-02-25 12:30 PM", "vendorName": "Precision Lens Lab"},
    {"itemName": "Hoya Vision Clear ARC", "openingStockQty": 20, "alertQty": 10, "purchasePrice": 1500.0, "groupName": "Lenses", "type": "Lens", "receivedDate": "2026-03-15 11:15 AM", "vendorName": "Prime Frames & Optics"},
    {"itemName": "Transitions Gen8 Grey", "openingStockQty": 7, "alertQty": 2, "purchasePrice": 5500.0, "groupName": "Lenses", "type": "Lens", "receivedDate": "2026-04-05 03:45 PM", "vendorName": "Elite Optical Hub"},
    
    // CONTACT LENSES & SOLUTIONS
    {"itemName": "Acuvue Moist (30 Pack)", "openingStockQty": 25, "alertQty": 5, "purchasePrice": 2200.0, "groupName": "Contact Lenses", "type": "Contact Lens", "receivedDate": "2026-01-10 10:45 AM", "vendorName": "Spectrum Lens Solutions"},
    {"itemName": "Bausch & Lomb BioTrue", "openingStockQty": 1, "alertQty": 10, "purchasePrice": 1800.0, "groupName": "Contact Lenses", "type": "Contact Lens", "receivedDate": "2026-02-15 01:20 PM", "vendorName": "Vision Care Lab"},
    {"itemName": "Renu Multi-Purpose 300ml", "openingStockQty": 30, "alertQty": 10, "purchasePrice": 450.0, "groupName": "Solutions", "type": "Accessory", "receivedDate": "2026-03-20 09:30 AM", "vendorName": "Precision Lens Lab"},
    {"itemName": "Opti-Free Express 120ml", "openingStockQty": 45, "alertQty": 20, "purchasePrice": 280.0, "groupName": "Solutions", "type": "Accessory", "receivedDate": "2026-04-08 11:00 AM", "vendorName": "Prime Frames & Optics"},
    
    // ACCESSORIES
    {"itemName": "Hard Shell Leather Case", "openingStockQty": 50, "alertQty": 10, "purchasePrice": 350.0, "groupName": "Accessories", "type": "Accessory", "receivedDate": "2026-01-05 02:00 PM", "vendorName": "Elite Optical Hub"},
    {"itemName": "Microfiber Spray Kit", "openingStockQty": 10, "alertQty": 15, "purchasePrice": 150.0, "groupName": "Accessories", "type": "Accessory", "receivedDate": "2026-02-05 10:30 AM", "vendorName": "Spectrum Lens Solutions"},
    {"itemName": "Magnetic Clip-On Sun", "openingStockQty": 4, "alertQty": 5, "purchasePrice": 1200.0, "groupName": "Accessories", "type": "Accessory", "receivedDate": "2026-03-01 12:00 PM", "vendorName": "Vision Care Lab"},
    
    // HIGH STOCK ITEMS (>1000)
    {"itemName": "Prada Cat-Eye Black", "openingStockQty": 1250, "alertQty": 10, "purchasePrice": 15500.0, "groupName": "Frames", "type": "Frame", "receivedDate": "2026-01-01 09:00 AM", "vendorName": "Vision Care Lab"},
    {"itemName": "Burberry Check Frame", "openingStockQty": 1100, "alertQty": 10, "purchasePrice": 13800.0, "groupName": "Frames", "type": "Frame", "receivedDate": "2026-01-15 10:30 AM", "vendorName": "Precision Lens Lab"},
    {"itemName": "Crizal Prevencia Lens", "openingStockQty": 1400, "alertQty": 50, "purchasePrice": 4200.0, "groupName": "Lenses", "type": "Lens", "receivedDate": "2026-02-01 11:15 AM", "vendorName": "Prime Frames & Optics"},
    {"itemName": "Zeiss DriveSafe Lens", "openingStockQty": 1050, "alertQty": 20, "purchasePrice": 6800.0, "groupName": "Lenses", "type": "Lens", "receivedDate": "2026-02-15 01:45 PM", "vendorName": "Elite Optical Hub"},
    {"itemName": "B&L Ultra One Day", "openingStockQty": 1300, "alertQty": 100, "purchasePrice": 2500.0, "groupName": "Contact Lenses", "type": "Contact Lens", "receivedDate": "2026-03-01 09:30 AM", "vendorName": "Spectrum Lens Solutions"},
    {"itemName": "Alcon Dailies Total 1", "openingStockQty": 1150, "alertQty": 50, "purchasePrice": 3200.0, "groupName": "Contact Lenses", "type": "Contact Lens", "receivedDate": "2026-03-15 10:00 AM", "vendorName": "Vision Care Lab"},
    {"itemName": "Premium Microfiber XL", "openingStockQty": 5000, "alertQty": 100, "purchasePrice": 45.0, "groupName": "Accessories", "type": "Accessory", "receivedDate": "2026-04-01 11:30 AM", "vendorName": "Precision Lens Lab"},
    {"itemName": "Anti-Fog Lens Wipes", "openingStockQty": 2500, "alertQty": 200, "purchasePrice": 15.0, "groupName": "Accessories", "type": "Accessory", "receivedDate": "2026-04-05 12:45 PM", "vendorName": "Prime Frames & Optics"},
    {"itemName": "Silicon Nose Pads Kit", "openingStockQty": 1800, "alertQty": 50, "purchasePrice": 120.0, "groupName": "Accessories", "type": "Accessory", "receivedDate": "2026-04-10 03:00 PM", "vendorName": "Elite Optical Hub"},
    {"itemName": "Precision Repair Tool", "openingStockQty": 1200, "alertQty": 20, "purchasePrice": 250.0, "groupName": "Accessories", "type": "Accessory", "receivedDate": "2026-04-15 04:15 PM", "vendorName": "Spectrum Lens Solutions"},
  ];

  // --- TASKS ---
  static List<Map<String, dynamic>> mockTasks = [
    {"_id": "T1", "title": "Follow up with Vikas Salvi regarding Frame selection", "status": "Pending", "priority": "High"},
    {"_id": "T2", "title": "Verify lens coating specifications for JC-1005", "status": "Pending", "priority": "Medium"},
    {"_id": "T3", "title": "Contact Lab for urgent delivery of RX-106", "status": "Pending", "priority": "High"},
    {"_id": "T4", "title": "Prepare monthly sales report for April", "status": "Pending", "priority": "Medium"},
    {"_id": "T5", "title": "Schedule eye testing appointment for New Customer", "status": "Pending", "priority": "Low"},
    {"_id": "T6", "title": "Verify Stock for Order #99", "status": "In Progress", "priority": "Medium"},
    {"_id": "T7", "title": "Send Invoice to Lab", "status": "Completed", "priority": "Low"},
  ];

  // --- CUSTOMERS ---
  static final List<Map<String, dynamic>> mockCustomers = [
    {
      "Name": "Amit Sharma",
      "MobileNumber": "9876543210",
      "Pincode": "400001",
      "Address": "123, Marine Drive, Mumbai",
      "State": "Maharashtra",
      "DOB": "1990-05-15",
    },
    {
      "Name": "Siddharth Malhotra",
      "MobileNumber": "9988776655",
      "Pincode": "110001",
      "Address": "Connaught Place, New Delhi",
      "State": "Delhi",
      "DOB": "1985-11-20",
    },
    {
      "Name": "Priya Patel",
      "MobileNumber": "9123456789",
      "Pincode": "380001",
      "Address": "Navrangpura, Ahmedabad",
      "State": "Gujarat",
      "DOB": "1995-02-10",
    },
    {
      "Name": "Rahul Verma",
      "MobileNumber": "8877665544",
      "Pincode": "560001",
      "Address": "Indiranagar, Bangalore",
      "State": "Karnataka",
      "DOB": "1988-08-25",
    },
    {
      "Name": "Anjali Gupta",
      "MobileNumber": "7766554433",
      "Pincode": "700001",
      "Address": "Salt Lake, Kolkata",
      "State": "West Bengal",
      "DOB": "1992-12-30",
    },
  ];

  // --- VENDORS ---
  static final List<Map<String, dynamic>> mockVendors = [
    {"id": "V1", "name": "Vision Care Lab", "vendorName": "Vision Care Lab"},
    {"id": "V2", "name": "Precision Lens Lab", "vendorName": "Precision Lens Lab"},
    {"id": "V3", "name": "Prime Frames & Optics", "vendorName": "Prime Frames & Optics"},
    {"id": "V4", "name": "Elite Optical Hub", "vendorName": "Elite Optical Hub"},
    {"id": "V5", "name": "Spectrum Lens Solutions", "vendorName": "Spectrum Lens Solutions"},
  ];

  // --- ITEMS (LENS & FRAMES) ---
  static final List<Map<String, dynamic>> mockItems = [
    // LENSES
    {
      "id": "L1",
      "itemName": "Single Vision Blue Cut",
      "salePrice": 1200.0,
      "mainCategory": "Lens",
      "isFrame": false
    },
    {
      "id": "L2",
      "itemName": "Anti-Reflective Coating (ARC)",
      "salePrice": 800.0,
      "mainCategory": "Lens",
      "isFrame": false
    },
    {
      "id": "L3",
      "itemName": "Photochromic (Transition)",
      "salePrice": 2500.0,
      "mainCategory": "Lens",
      "isFrame": false
    },
    {
      "id": "L4",
      "itemName": "Digital Progressive Prime",
      "salePrice": 4500.0,
      "mainCategory": "Lens",
      "isFrame": false
    },
    {
      "id": "L5",
      "itemName": "Polycarbonate Safety Lens",
      "salePrice": 1800.0,
      "mainCategory": "Lens",
      "isFrame": false
    },
    // FRAMES
    {
      "id": "F1",
      "itemName": "Titan Edge - Matte Black",
      "salePrice": 3500.0,
      "mainCategory": "Frame",
      "isFrame": true
    },
    {
      "id": "F2",
      "itemName": "Ray-Ban Wayfarer Classic",
      "salePrice": 8500.0,
      "mainCategory": "Frame",
      "isFrame": true
    },
    {
      "id": "F3",
      "itemName": "Fastrack Sporty Wrap",
      "salePrice": 1500.0,
      "mainCategory": "Frame",
      "isFrame": true
    },
    {
      "id": "F4",
      "itemName": "Vogue Chic - Rose Gold",
      "salePrice": 5200.0,
      "mainCategory": "Frame",
      "isFrame": true
    },
    {
      "id": "F5",
      "itemName": "Oakley Holbrook - Sapphire",
      "salePrice": 9000.0,
      "mainCategory": "Frame",
      "isFrame": true
    },
    // SOLUTIONS & CONTACT LENS
    {
      "id": "CL1",
      "itemName": "Bausch & Lomb Soft Lens",
      "salePrice": 1500.0,
      "mainCategory": "Contact Lens",
      "isFrame": false
    },
    {
      "id": "CL2",
      "itemName": "Acuvue Oasys Weekly",
      "salePrice": 2200.0,
      "mainCategory": "Contact Lens",
      "isFrame": false
    },
    {
      "id": "CL3",
      "itemName": "Air Optix Monthly",
      "salePrice": 1800.0,
      "mainCategory": "Contact Lens",
      "isFrame": false
    },
    {
      "id": "S1",
      "itemName": "Renu Multi-Purpose Solution (300ml)",
      "salePrice": 450.0,
      "mainCategory": "Solutions",
      "isFrame": false
    },
    {
      "id": "S2",
      "itemName": "Opti-Free PureMoist (300ml)",
      "salePrice": 550.0,
      "mainCategory": "Solutions",
      "isFrame": false
    },
    {
      "id": "S3",
      "itemName": "Biotrue Multi-Purpose (300ml)",
      "salePrice": 480.0,
      "mainCategory": "Solutions",
      "isFrame": false
    },
  ];

  // --- EXPENSES ---
  static List<Map<String, dynamic>> mockExpenses = [
    {'id': '1', 'date': '29-4-2026', 'category': 'Tea/Snacks', 'amount': 150.0, 'note': 'Client meeting', 'type': 'Payment'},
    {'id': '2', 'date': '28-4-2026', 'category': 'Stationery', 'amount': 450.0, 'note': 'Paper and pens', 'type': 'Payment'},
    {'id': '3', 'date': '15-4-2026', 'category': 'Rent', 'amount': 15000.0, 'note': 'Shop monthly rent', 'type': 'Payment'},
    {'id': '4', 'date': '10-4-2026', 'category': 'Electricity', 'amount': 3200.0, 'note': 'MSEB Bill April', 'type': 'Payment'},
    {'id': '5', 'date': '05-4-2026', 'category': 'Salary', 'amount': 8500.0, 'note': 'Staff payment - Rahul', 'type': 'Payment'},
    {'id': '6', 'date': '20-3-2026', 'category': 'Maintenance', 'amount': 1200.0, 'note': 'A/C Servicing', 'type': 'Payment'},
    {'id': '7', 'date': '05-1-2026', 'category': 'Marketing', 'amount': 5000.0, 'note': 'Local newspaper ad', 'type': 'Payment'},
  ];

  static double getExpensesForDate(DateTime date) {
    final dateStr = "${date.day}-${date.month}-${date.year}";
    return mockExpenses
        .where((ex) => ex['date'] == dateStr)
        .fold(0.0, (sum, ex) => sum + (ex['amount'] as double));
  }

  // --- STAFF ---
  static List<Map<String, dynamic>> mockStaff = [
    {'_id': 'S1', 'name': 'Rahul Sharma', 'role': 'Sales'},
    {'_id': 'S2', 'name': 'Priya Singh', 'role': 'Optician'},
    {'_id': 'S3', 'name': 'Amit Patel', 'role': 'Manager'},
  ];

}
