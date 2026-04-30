import 'package:flutter/material.dart';

class LensSelectionDialog extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  
  const LensSelectionDialog({super.key, required this.items});

  @override
  State<LensSelectionDialog> createState() => _LensSelectionDialogState();
}

class _LensSelectionDialogState extends State<LensSelectionDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _searchController.addListener(_filterItems);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = widget.items.where((item) {
        final name = (item['itemName'] ?? item['name'] ?? '').toString().toLowerCase();
        final brand = (item['brandName'] ?? item['category'] ?? '').toString().toLowerCase();
        return name.contains(query) || brand.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        width: double.maxFinite,
        height: 600,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                const Text('List Of Lens', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const Divider(),
            
            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search Lens...',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 8),

            // Table Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              color: Colors.grey[100],
              child: const Row(
                children: [
                  SizedBox(width: 40, child: Text('Sn', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 3, child: Text('Brand / Item Name', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 1, child: Text('Price', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            
            // List
            Expanded(
              child: _filteredItems.isEmpty
                  ? const Center(child: Text('No items found'))
                  : ListView.separated(
                      itemCount: _filteredItems.length,
                      separatorBuilder: (c, i) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        return _buildLensItem(index, _filteredItems[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLensItem(int index, Map<String, dynamic> item) {
    final name = item['itemName'] ?? item['name'] ?? 'Unknown';
    final brand = item['brandName'] ?? item['category'] ?? 'Generic';
    final price = item['salePrice']?.toString() ?? item['price']?.toString() ?? '0.00';
    final sn = index + 1;

    return InkWell(
      onTap: () {
        Navigator.pop(context, item);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            SizedBox(width: 40, child: Text('$sn.', textAlign: TextAlign.center)),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(brand, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
               flex: 1,
               child: Text(price, textAlign: TextAlign.center),
             ),
          ],
        ),
      ),
    );
  }
}
