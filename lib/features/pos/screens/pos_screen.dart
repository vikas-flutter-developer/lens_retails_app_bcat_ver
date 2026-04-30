import 'package:flutter/material.dart';
import 'barcode_scanner_screen.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final List<Map<String, dynamic>> _cart = [];
  final TextEditingController _barcodeController = TextEditingController();
  
  // Mock products
  final List<Map<String, dynamic>> _inventory = [
    {'id': '1', 'name': 'RayBan Aviator', 'price': 5500.0, 'stock': 12},
    {'id': '2', 'name': 'Fastrack Rectangle', 'price': 1200.0, 'stock': 5},
    {'id': '3', 'name': 'Lenskart Blu', 'price': 1500.0, 'stock': 20},
    {'id': '4', 'name': 'Contact Lens (Bausch)', 'price': 800.0, 'stock': 40},
    {'id': '5', 'name': 'Cleaning Solution', 'price': 150.0, 'stock': 80},
    {'id': '6', 'name': 'Microfiber Cloth', 'price': 50.0, 'stock': 150},
  ];

  @override
  void dispose() {
    _barcodeController.dispose();
    super.dispose();
  }

  void _addToCart(Map<String, dynamic> product) {
    setState(() {
      final index = _cart.indexWhere((item) => item['id'] == product['id']);
      if (index >= 0) {
        _cart[index]['qty'] += 1;
      } else {
        _cart.add({...product, 'qty': 1});
      }
    });
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product['name']} added to cart'), duration: const Duration(seconds: 1)),
    );
  }
  
  double get _cartTotal {
    return _cart.fold(0, (sum, item) => sum + (item['price'] * item['qty']));
  }
  
  int get _cartItemCount {
    return _cart.fold(0, (sum, item) => sum + (item['qty'] as int));
  }

  void _checkout() {
    if (_cart.isEmpty) return;
    
    // If inside bottom sheet, pop it first
    if (Navigator.canPop(context)) {
        Navigator.pop(context); 
    }
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [Icon(Icons.check_circle, color: Colors.green), SizedBox(width: 8), Text('Payment')]),
        content: Text('Total collected: ₹${_cartTotal.toStringAsFixed(2)}\n(Mock sync to backend)'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _cart.clear();
              });
            },
            child: const Text('Complete Sale'),
          )
        ],
      ),
    );
  }

  void _showCartBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
             void modalUpdateQty(int index, int delta) {
                 setModalState(() {
                    _cart[index]['qty'] += delta;
                    if (_cart[index]['qty'] <= 0) {
                      _cart.removeAt(index);
                    }
                 });
                 // Update the main UI underneath
                 setState((){});
                 
                 // if cart is empty, close sheet automatically
                 if (_cart.isEmpty) {
                   Navigator.pop(ctx);
                 }
             }

             return Padding(
               padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
               child: Container(
                 height: MediaQuery.of(ctx).size.height * 0.75, // Take up 75% of screen
                 padding: const EdgeInsets.all(20),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         const Text('Current Cart', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                         IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx))
                       ],
                     ),
                     const Divider(),
                     Expanded(
                       child: _cart.isEmpty 
                         ? const Center(child: Text('Cart is empty', style: TextStyle(color: Colors.grey, fontSize: 16)))
                         : ListView.builder(
                             itemCount: _cart.length,
                             itemBuilder: (context, index) {
                               final item = _cart[index];
                               return Card(
                                 margin: const EdgeInsets.only(bottom: 12),
                                 elevation: 0,
                                 color: Colors.grey.shade50,
                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200, width: 1.5)),
                                 child: Padding(
                                   padding: const EdgeInsets.all(16.0),
                                   child: Row(
                                     children: [
                                       Expanded(
                                         child: Column(
                                           crossAxisAlignment: CrossAxisAlignment.start,
                                           children: [
                                             Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                             const SizedBox(height: 6),
                                             Text('₹${item['price']}', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w900)),
                                           ],
                                         ),
                                       ),
                                       Row(
                                         children: [
                                           IconButton(
                                             icon: const Icon(Icons.remove_circle, color: Colors.redAccent, size: 28),
                                             onPressed: () => modalUpdateQty(index, -1),
                                           ),
                                           Container(
                                             width: 32,
                                             alignment: Alignment.center,
                                             child: Text('${item['qty']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                                           ),
                                           IconButton(
                                             icon: const Icon(Icons.add_circle, color: Colors.green, size: 28),
                                             onPressed: () => modalUpdateQty(index, 1),
                                           ),
                                         ],
                                       )
                                     ],
                                   ),
                                 ),
                               );
                             },
                           ),
                     ),
                     const Divider(),
                     Padding(
                       padding: const EdgeInsets.symmetric(vertical: 20),
                       child: Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                           const Text('Grand Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                           Text('₹${_cartTotal.toStringAsFixed(2)}', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary)),
                         ],
                       ),
                     ),
                     SizedBox(
                       width: double.infinity,
                       height: 60,
                       child: ElevatedButton(
                         onPressed: _cart.isEmpty ? null : _checkout,
                         style: ElevatedButton.styleFrom(
                           backgroundColor: Theme.of(context).colorScheme.primary,
                           foregroundColor: Colors.white,
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                           elevation: 5,
                         ),
                         child: const Text('CONFIRM PAYMENT', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                       ),
                     ),
                     const SizedBox(height: 10), // extra padding for iOS home indicator
                   ],
                 ),
               ),
             );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Retail POS'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search & Scanner Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            color: Colors.white,
            child: TextFormField(
              controller: _barcodeController,
              decoration: InputDecoration(
                hintText: 'Scan or Enter Barcode',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF1A237E)),
                  onPressed: () async {
                    if (!mounted) return;
                    final String? code = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
                    );
                    if (code != null && mounted) {
                       _barcodeController.text = code;
                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Scanned: $code')));
                    }
                  },
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
              onFieldSubmitted: (value) {
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Scanned: $value')));
              },
            ),
          ),
          
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isTablet ? 4 : 2, 
                childAspectRatio: 0.72, // Gives enough vertical space for image/text/button
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _inventory.length,
              itemBuilder: (context, index) {
                final item = _inventory[index];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200, width: 1.5),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 5))],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                               width: 48, height: 48,
                               decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                               child: Icon(Icons.inventory_2, color: Theme.of(context).colorScheme.primary, size: 24),
                            ),
                            const SizedBox(height: 16),
                            Text(item['name'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 8),
                            Text('₹${item['price']}', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 18)),
                            const SizedBox(height: 6),
                            Text('${item['stock']} in stock', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () => _addToCart(item),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(18), bottomRight: Radius.circular(18))
                          ),
                          child: const Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                 Icon(Icons.add_shopping_cart, color: Colors.white, size: 18),
                                 SizedBox(width: 8),
                                 Text('Add to Cart', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                              ]
                            )
                          ),
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          )
        ],
      ),
      bottomNavigationBar: _cart.isNotEmpty 
        ? SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -5))]
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$_cartItemCount Items in Cart', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text('₹${_cartTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showCartBottomSheet,
                    icon: const Icon(Icons.shopping_basket),
                    label: const Text('View Cart'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      backgroundColor: const Color(0xFFD4AF37), // Gold accent
                      foregroundColor: const Color(0xFF1A237E), // Navy text
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
                    ),
                  )
                ],
              ),
            ),
          )
        : null,
    );
  }
}
