import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/services/print_service.dart';
import '../../../../core/utils/order_status_util.dart';
import '../services/order_service.dart';

class OrderCard extends StatefulWidget {
  final Map<String, dynamic> order;
  final VoidCallback? onDelete;

  const OrderCard({super.key, required this.order, this.onDelete});

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  final PageController _pageController = PageController();
  final int _currentIndex = 0;
  late String _currentStatus;  // Local state so setState() refreshes badge instantly
  Map<String, dynamic>? _otpData;
  bool _isLoadingOtp = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.order['status']?.toString() ?? 'Pending';
    if (_shouldShowOtp(_currentStatus)) {
      _fetchOtpData();
    }
  }

  bool _shouldShowOtp(String status) {
    return OrderStatusUtil.isShipped(status);
  }

  Future<void> _fetchOtpData() async {
    final orderId = widget.order['id']?.toString() ?? widget.order['sn']?.toString() ?? '';
    if (orderId.isEmpty) return;

    if (mounted) setState(() => _isLoadingOtp = true);
    
    try {
      final data = await OrderService().fetchDeliveryOtp(orderId);
      if (mounted) {
        setState(() {
          _otpData = data;
          _isLoadingOtp = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingOtp = false);
      debugPrint('⚠️ [OrderCard] Error fetching OTP: $e');
    }
  }

  /// Returns the appropriate color for the given order status
  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'received':
      case 'completed':
      case 'delivered':
      case 'done':
        return Colors.green;
      case 'cancelled':
      case 'rejected':
        return Colors.red;
      case 'processing':
      case 'in progress':
        return Colors.blue;
      case 'shipped':
      case 'dispatched':
      case 'out for delivery':
        return Colors.purple;
      default:
        return Colors.grey[600]!;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(_currentStatus);
    final items = widget.order['items'] as List?;
    final hasMultipleItems = items != null && items.length > 1;
    

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Row: Customer Name & Badge (Responsive)
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.order['customer']?.toUpperCase() ?? 'UNKNOWN CUSTOMER',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 80),
                    child: Text(
                      '#${widget.order['sn'] ?? '0'}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 4),

            // Content Body
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Right Info Column (Invoice, Lens, etc)
                Expanded(
                  flex: 2, // Changed from 3 to 2 to give status more room
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Invoice (Conditional)
                      if (widget.order['invoice'] != null && widget.order['invoice'].toString().toLowerCase() != 'unknown' && widget.order['invoice'].toString().isNotEmpty)
                        _buildInfoText('INVOICE: ${widget.order['invoice']}'),
                        
                      // Date & Delivery (Conditional)
                      if (widget.order['date'] != null && widget.order['date'].toString().isNotEmpty)
                        _buildInfoText('Date: ${widget.order['date']} ${ (widget.order['delDate'] != null && widget.order['delDate'].toString().isNotEmpty) ? "Del: ${widget.order['delDate']}" : "" }'),
                        
                      // Remarks (Conditional)
                      if (widget.order['remarks'] != null && widget.order['remarks'].toString().isNotEmpty)
                        _buildInfoText('Rem: ${widget.order['remarks']}'),
                        
                      // Lens Name (Show current item name if multiple, or single lens name)
                      // Lens Name (Show single lens name if not multiple)
                      if (!hasMultipleItems && widget.order['lens'] != null && widget.order['lens'].toString().isNotEmpty) ...[
                         const SizedBox(height: 2),
                         Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(text: 'Lens: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                              TextSpan(text: widget.order['lens']?.toString() ?? '', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                            ],
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
                // Left Price/Status Column
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        widget.order['amount'] ?? '0.00',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      _buildStatusDropdown(widget.order, statusColor),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Swipable Eye Grid Area
            // Vertical Eye Grid Area (Stacking)
            // Handles both List-based items and Legacy flat structure
            Builder(
              builder: (context) {
                final items = widget.order['items'] as List?;
                final hasListItems = items != null && items.isNotEmpty;
                
                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                    color: Colors.orange[50], 
                    borderRadius: BorderRadius.circular(4)
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                       // Table Header
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Expanded(child: Center(child: Text('EYE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9)))),
                            Expanded(child: Center(child: Text('SPH', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9)))),
                            Expanded(child: Center(child: Text('CYL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9)))),
                            Expanded(child: Center(child: Text('AXIS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9)))),
                            Expanded(child: Center(child: Text('ADD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9)))),
                            Expanded(child: Center(child: Text('QTY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9)))),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Colors.orange),
                      
                      // Render Items Logic
                      if (hasListItems) 
                        Builder(
                          builder: (context) {
                             // Group items by itemName
                             final Map<String, List<dynamic>> grouped = {};
                             for (var item in items) {
                               final name = item['itemName']?.toString() ?? 'Lens Item';
                               if (!grouped.containsKey(name)) grouped[name] = [];
                               grouped[name]!.add(item);
                             }

                             return Column(
                               children: grouped.entries.map((entry) {
                                 final itemName = entry.key;
                                 final groupItems = entry.value;
                                 
                                 return Column(
                                   children: [
                                     // Product Header
                                     Container(
                                       width: double.infinity,
                                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                       color: Colors.orange[100],
                                       child: Row(
                                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                         children: [
                                           Text(
                                             itemName,
                                             style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.brown),
                                           ),
                                           Text(
                                             '₹${groupItems.fold<double>(0, (sum, item) => sum + (double.tryParse(item['totalAmount']?.toString() ?? '0') ?? 0)).toStringAsFixed(2)}',
                                             style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.brown),
                                           ),
                                         ],
                                       ),
                                     ),
                                     // Items in this group
                                     ...groupItems.map((item) {
                                        final String eye = item['eye'] ?? 'RL';
                                        final Map<String, dynamic> data = {
                                              'sph': item['sph']?.toString() ?? '',
                                              'cyl': item['cyl']?.toString() ?? '',
                                              'axis': item['axis']?.toString() ?? '',
                                              'add': item['add']?.toString() ?? '',
                                              'qty': item['qty']?.toString() ?? '1',
                                        };
                                        return Column(
                                          children: [
                                            _buildEyeRow(eye, data),
                                            Divider(height: 1, color: Colors.orange.withValues(alpha: 0.1)),
                                          ],
                                        );
                                     }),
                                   ],
                                 );
                               }).toList(),
                             );
                          }
                        )
                      else ...[
                        // Legacy / Fallback for Flat Structure (Single Finish usually)
                        _buildEyeRow('R', {...(widget.order['eye_r'] ?? {}), 'qty': '1'}),
                        _buildEyeRow('L', {...(widget.order['eye_l'] ?? {}), 'qty': '1'}),
                      ],
                      // Total Row
                      if (hasListItems) ...[
                const Divider(height: 1, color: Colors.orange),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.brown),
                      ),
                      Text(
                        '₹${(items).fold<double>(0, (sum, item) => sum + (double.tryParse(item['totalAmount']?.toString() ?? '0') ?? 0)).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.brown),
                      ),
                    ],
                  ),
                ),
              ]
            ],
          ),
        );
              }
            ),

            const SizedBox(height: 4),

            // OTP / Delivery Verification Section
            if (_shouldShowOtp(_currentStatus))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    border: Border.all(color: Colors.blue[200]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user, color: Colors.blue, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'DELIVERY VERIFICATION',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                            const SizedBox(height: 4),
                            if (_isLoadingOtp)
                              const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            else if (_otpData?['isWhitelisted'] == true)
                              Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Direct Delivery (Whitelisted)',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green),
                                  ),
                                ],
                              )
                            else if (_otpData?['otp'] != null)
                              Text(
                                'Delivery OTP: ${_otpData!['otp']}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.5, color: Colors.black87),
                              )
                            else
                              const Text(
                                'OTP Pending...',
                                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 13),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.blue, size: 20),
                        onPressed: _fetchOtpData,
                        tooltip: 'Refresh OTP',
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 4),

            // Footer (Ref No, Vend, Actions) - Responsive Layout
            LayoutBuilder(builder: (context, c) {
              bool isNarrow = c.maxWidth < 250;
              
              Widget leftPart = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.order['refNo'] != null && widget.order['refNo'].toString().isNotEmpty)
                    Text('Ref: ${widget.order['refNo']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 9), overflow: TextOverflow.ellipsis),
                  if (widget.order['vendor'] != null && widget.order['vendor'].toString().isNotEmpty)
                    Text('Vend: ${widget.order['vendor']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 9), overflow: TextOverflow.ellipsis),
                ],
              );

              Widget actions = Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildActionIcon(context, Icons.remove_red_eye, () => _showViewDialog(context)),
                  _buildActionIcon(context, Icons.edit_square, () {
                    Navigator.of(context).pushNamed('/add_order', arguments: widget.order);
                  }),
                  _buildActionIcon(context, Icons.print, () async {
                    try {
                      await PrintService.printOrderReceipt(widget.order);
                    } catch (e) {
                      if(context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Print Error: $e'), backgroundColor: Colors.red));
                      }
                    }
                  }),
                  _buildActionIcon(context, const IconData(0xf05a6, fontFamily: 'MaterialIcons'), () => _launchWhatsApp(), color: Colors.green),
                  _buildActionIcon(context, Icons.delete, () => _showDeleteDialog(context)),
                ],
              );

              if (isNarrow) {
                return Column(
                  children: [
                    leftPart,
                    actions,
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(flex: 1, child: leftPart),
                  Expanded(flex: 2, child: actions),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showViewDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Order #${widget.order['sn']}'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('Customer:', widget.order['customer']),
                _detailRow('Invoice:', widget.order['invoice']),
                _detailRow('Date:', widget.order['date']),
                _detailRow('Lens:', widget.order['lens']),
                _detailRow('Status:', widget.order['status']),
                _detailRow('Amount:', widget.order['amount']),
                _detailRow('Remarks:', widget.order['remarks']),
                const Divider(),
                const Divider(),
                const Text('Items & Eye Details:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                if (widget.order['items'] != null && (widget.order['items'] as List).isNotEmpty)
                  ...(widget.order['items'] as List).map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• ${item['itemName'] ?? 'Item'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey)),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (item['eye'] == 'RL' || item['eye'] == 'R' || item['eye'] == 'Right')
                                  Text('R: SPH ${item['sph'] ?? ''} CYL ${item['cyl'] ?? ''} AXIS ${item['axis'] ?? ''} ADD ${item['add'] ?? ''}'),
                                if (item['eye'] == 'RL' || item['eye'] == 'L' || item['eye'] == 'Left')
                                  Text('L: SPH ${item['sph'] ?? ''} CYL ${item['cyl'] ?? ''} AXIS ${item['axis'] ?? ''} ADD ${item['add'] ?? ''}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  })
                else ...[
                  Text('R: ${widget.order['eye_r'].toString()}'),
                  Text('L: ${widget.order['eye_l'].toString()}'),
                ],
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Delete Order?'),
              content: Text(isDeleting ? 'Deleting order...' : 'Are you sure you want to delete this order?'),
              actions: isDeleting 
                ? [const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))]
                : [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () async {
                        setDialogState(() => isDeleting = true);
                        try {
                          final service = OrderService();
                          final String orderId = widget.order['id'] ?? widget.order['sn'];
                          final String orderType = widget.order['type'] ?? 'Unknown';
                          debugPrint('🗑️ [OrderCard] User confirmed delete. Type: $orderType, ID: $orderId');

                          // Try the appropriate endpoint first based on type
                          try {
                            if (orderType == 'RX') {
                              await service.deleteRxOrder(orderId);
                            } else {
                              await service.deleteOrder(orderId);
                            }
                          } catch (firstError) {
                            debugPrint('⚠️ [OrderCard] First delete attempt failed, trying alternate endpoint...');
                            // Fallback: Try the opposite endpoint
                            if (orderType == 'RX') {
                              await service.deleteOrder(orderId);
                            } else {
                              await service.deleteRxOrder(orderId);
                            }
                          }

                          if (context.mounted) {
                            Navigator.pop(context); // Close dialog
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Order Deleted Successfully'), backgroundColor: Colors.green),
                            );
                            if (widget.onDelete != null) widget.onDelete!();
                          }
                        } catch (e) {
                          if (context.mounted) {
                            setDialogState(() => isDeleting = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
            );
          }
        );
      },
    );
  }

  Widget _detailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value ?? 'N/A')),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown(Map<String, dynamic> order, Color currentColor) {
    final String currentStatus = _currentStatus; // Use local state, not order map
    final List<String> statuses = ['Pending', 'In Progress', 'Done', 'Shipped', 'Out for Delivery', 'Delivered', 'Cancelled'];
    
    // Ensure current status is in the list, otherwise add it
    final List<String> availableStatuses = List.from(statuses);
    if (!availableStatuses.contains(currentStatus)) {
      availableStatuses.add(currentStatus);
    }

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(currentStatus), // Use local state for color too
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: currentStatus,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 16),
          dropdownColor: Colors.white,
          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          selectedItemBuilder: (BuildContext context) {
             return availableStatuses.map<Widget>((String item) {
                return Center(
                  child: Text(
                    item,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                );
             }).toList();
          },
          items: availableStatuses.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value, 
                style: TextStyle(color: _getStatusColor(value), fontSize: 12, fontWeight: FontWeight.bold)
              ),
            );
          }).toList(),
          onChanged: (String? newValue) async {
             if (newValue != null && newValue != currentStatus) {
                _updateOrderStatus(order, newValue);
             }
          },
        ),
      ),
    );
  }

  Future<void> _updateOrderStatus(Map<String, dynamic> order, String newStatus) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Updating to $newStatus...'), duration: const Duration(seconds: 1)),
      );

      final service = OrderService();
      final String orderId = order['id']?.toString() ?? order['sn']?.toString() ?? '';
      final String orderType = order['type']?.toString() ?? 'RX';
      final String customerId = order['customer']?.toString() ?? '';
      final List<dynamic> items = (order['items'] as List?) ?? [];

      await service.updateOrderStatus(orderId, orderType, newStatus, customerId: customerId, items: items);

      // Update local status state — this refreshes the badge and dropdown instantly
      if (context.mounted) {
        setState(() {
          _currentStatus = newStatus;
          if (_shouldShowOtp(newStatus)) {
            _fetchOtpData();
          } else {
            _otpData = null;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status updated!'), backgroundColor: Colors.green, duration: Duration(seconds: 2)),
        );
        if (widget.onDelete != null) widget.onDelete!();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildInfoText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.0),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: Colors.grey[800], fontWeight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildEyeRow(String side, Map<String, dynamic> data) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        children: [
          Expanded(child: Center(child: Text(side, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 9)))),
          Expanded(child: Center(child: Text(data['sph'] ?? '', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600)))),
          Expanded(child: Center(child: Text(data['cyl'] ?? '', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600)))),
          Expanded(child: Center(child: Text(data['axis'] ?? '', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600)))),
          Expanded(child: Center(child: Text(data['add'] ?? '', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600)))),
          Expanded(child: Center(child: Text(data['qty'] ?? '', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600)))),
        ],
      ),
    );
  }

  Widget _buildActionIcon(BuildContext context, IconData icon, VoidCallback onTap, {Color? color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Icon(icon, size: 16, color: color ?? Colors.grey[700]),
      ),
    );
  }

  Future<void> _launchWhatsApp() async {
    final String customerName = widget.order['customer'] ?? 'Customer';
    final String orderId = widget.order['invoice'] ?? widget.order['sn'] ?? '';
    final String status = _currentStatus.toUpperCase();
    
    // Attempt to find phone number in the order data
    String? phone = widget.order['phone'] ?? widget.order['customerPhone'] ?? widget.order['mobile'];
    
    if (phone == null || phone.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No phone number found for this customer')),
        );
      }
      return;
    }

    // Clean phone number (remove spaces, dashes, etc)
    phone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (!phone.startsWith('91') && phone.length == 10) {
      phone = '91$phone';
    }

    final String message = "Hello $customerName, your order #$orderId is now $status at our store. Please visit us for collection. Thank you!";
    final Uri whatsappUrl = Uri.parse("whatsapp://send?phone=$phone&text=${Uri.encodeComponent(message)}");
    final Uri webUrl = Uri.parse("https://wa.me/$phone?text=${Uri.encodeComponent(message)}");

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl);
      } else {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open WhatsApp: $e')),
        );
      }
    }
  }
}
