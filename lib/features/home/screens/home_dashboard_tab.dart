import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../auth/services/auth_service.dart';
import '../../expenses/services/expense_service.dart';
import '../services/analytics_service.dart';
import '../../orders/screens/my_order_list_screen.dart';
import '../../job_cards/screens/job_cards_list_screen.dart';
import '../../inventory/screens/local_inventory_screen.dart';
import '../../inventory/screens/inventory_alerts_screen.dart';
import '../../expenses/screens/expenses_screen.dart';
import '../../collections/screens/daily_collections_screen.dart';
import '../../employees/screens/staff_list_screen.dart';
import '../../reports/screens/reports_screen.dart';
import '../../tasks/screens/task_management_screen.dart';
import '../../orders/screens/vendor_master_screen.dart';
import '../../ledger/screens/my_ledger_screen.dart';
import '../../common/screens/qr_scanner_hub_screen.dart';
import '../../common/screens/rfid_command_center.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Design tokens — Light theme
// ─────────────────────────────────────────────────────────────────────────────
class _C {
  // Backgrounds
  static const bg       = Color(0xFFF4F6FB);
  static const card     = Color(0xFFFFFFFF);
  static const cardAlt  = Color(0xFFF9FAFB);

  // Accent palette
  static const indigo   = Color(0xFF4F46E5);
  static const indigoLt = Color(0xFFEEEDFD);
  static const violet   = Color(0xFF7C3AED);
  static const violetLt = Color(0xFFEDE9FE);
  static const teal     = Color(0xFF0D9488);
  static const tealLt   = Color(0xFFCCFBF1);
  static const sky      = Color(0xFF0284C7);
  static const skyLt    = Color(0xFFE0F2FE);
  static const amber    = Color(0xFFD97706);
  static const amberLt  = Color(0xFFFEF3C7);
  static const rose     = Color(0xFFE11D48);
  static const roseLt   = Color(0xFFFFE4E6);
  static const emerald  = Color(0xFF059669);
  static const emeraldLt= Color(0xFFD1FAE5);
  static const fuchsia  = Color(0xFFC026D3);
  static const fuchsiaLt= Color(0xFFFAE8FF);
  static const orange   = Color(0xFFEA580C);
  static const orangeLt = Color(0xFFFFF7ED);

  // Text
  static const textPri  = Color(0xFF0F172A);
  static const textSec  = Color(0xFF64748B);
  static const textHint = Color(0xFFCBD5E1);

  // Border
  static const border   = Color(0xFFE9EDF5);
}

// ─────────────────────────────────────────────────────────────────────────────
class HomeDashboardTab extends StatefulWidget {
  final VoidCallback onAddOrder;
  final VoidCallback onProfileTap;
  final ValueNotifier<int>? reloadSignal;

  const HomeDashboardTab({
    super.key, 
    required this.onAddOrder, 
    required this.onProfileTap,
    this.reloadSignal
  });

  @override
  State<HomeDashboardTab> createState() => _HomeDashboardTabState();
}

class _HomeDashboardTabState extends State<HomeDashboardTab>
    with TickerProviderStateMixin {
  final AuthService      _authService      = AuthService();
  final ExpenseService   _expenseService   = ExpenseService();
  final AnalyticsService _analyticsService = AnalyticsService();

  bool   _isLoading       = true;
  Timer? _refreshTimer;
  String _todayCollection = '₹0';
  String _todayProfit     = '₹0';
  int    _activeJobCards  = 0;
  int    _pendingTasks    = 0;
  int    _lowStockCount   = 0;
  String _cashInHand      = '₹0';
  String _netProfit       = '₹0';
  String _userName        = '';

  late AnimationController _entryCtrl;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor:            Colors.transparent,
      statusBarBrightness:       Brightness.light,
      statusBarIconBrightness:   Brightness.dark,
    ));
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _loadDashboardData();
    widget.reloadSignal?.addListener(_onReloadSignal);
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadDashboardData());
  }

  void _onReloadSignal() => _loadDashboardData();

  @override
  void dispose() {
    widget.reloadSignal?.removeListener(_onReloadSignal);
    _refreshTimer?.cancel();
    _entryCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    try {
      final analytics = await _analyticsService.fetchMobileDashboard();
      final name      = await _authService.getUserName();
      
      List expenses = [];
      try {
        expenses = await _expenseService.fetchExpenses();
      } catch (e) {
        debugPrint('Dashboard failed to load expenses: $e');
      }

       final double rev = (analytics['todayCollection'] != null)
           ? double.tryParse(analytics['todayCollection'].toString()) ?? 0.0 : 0.0;
       final double profitT = (analytics['todayProfit'] != null)
           ? double.tryParse(analytics['todayProfit'].toString()) ?? (rev * 0.5) : (rev * 0.5);

       double todayExp = 0.0;
       final now = DateTime.now();
       for (var ex in expenses) {
         if (ex['date'] == "${now.day}-${now.month}-${now.year}") {
           todayExp += (ex['amount'] as num).toDouble();
         }
       }
       
       final double cashH = (analytics['cashInHand'] ?? (rev - todayExp)).toDouble();
       final double profitN = (analytics['netProfit'] != null)
           ? double.tryParse(analytics['netProfit'].toString()) ?? (cashH * 0.5) : (cashH * 0.5);

       if (mounted) {
         setState(() {
           _todayCollection = "₹${_fmt(rev)}";
           _todayProfit     = "₹${_fmt(profitT)}";
           _cashInHand      = "₹${_fmt(cashH)}";
           _netProfit       = "₹${_fmt(profitN)}";
           _activeJobCards  = analytics['activeJobCards'] ?? 0;
           _pendingTasks    = analytics['pendingTasks']   ?? 0;
           _lowStockCount   = analytics['lowStockCount']  ?? 0;
           _userName        = name;
           _isLoading       = false;
         });
         _entryCtrl.forward(from: 0);
       }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _entryCtrl.forward(from: 0);
      }
    }
  }

  String _fmt(double v) =>
      v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}K' : v.toStringAsFixed(0);

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Animation<double> _slideIn(double delay) =>
      Tween(begin: 24.0, end: 0.0).animate(CurvedAnimation(
        parent: _entryCtrl,
        curve: Interval(delay, math.min(delay + 0.55, 1.0), curve: Curves.easeOutCubic),
      ));

  Animation<double> _fadeIn(double delay) =>
      Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _entryCtrl,
        curve: Interval(delay, math.min(delay + 0.55, 1.0), curve: Curves.easeOut),
      ));

  // ── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _C.bg,
        body: Center(child: CircularProgressIndicator(color: _C.indigo, strokeWidth: 2.5)),
      );
    }
    return Scaffold(
      backgroundColor: _C.bg,
      body: RefreshIndicator(
        color: _C.indigo,
        onRefresh: _loadDashboardData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 48),
              sliver: SliverList(delegate: SliverChildListDelegate([
                _buildMetricCards(),
                const SizedBox(height: 28),
                _buildQRToolsHub(),
                const SizedBox(height: 28),
                _buildSectionLabel('Quick Access'),
                const SizedBox(height: 14),
                _buildServicesGrid(),
                const SizedBox(height: 28),
                _buildSectionLabel('Live Operations'),
                const SizedBox(height: 14),
                _buildOpsCard(),
              ])),
            ),
          ],
        ),
      ),
    );
  }

  // ── HEADER ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4338CA), Color(0xFF6D28D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft:  Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          // top-right orb
          Positioned(top: -30, right: -30,
              child: Container(width: 180, height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.07),
                  ))),
          // bottom-left orb
          Positioned(bottom: 10, left: -20,
              child: Container(width: 100, height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ))),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // greeting row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AnimatedBuilder(
                        animation: _fadeIn(0),
                        builder: (_, __) => Opacity(
                          opacity: _fadeIn(0).value,
                          child: Text(_greeting, style: const TextStyle(
                              color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w500)),
                        ),
                      ),
                      _livePill(),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // name
                    GestureDetector(
                      onTap: widget.onProfileTap,
                      child: AnimatedBuilder(
                        animation: _slideIn(0.06),
                        builder: (_, __) => Transform.translate(
                          offset: Offset(0, _slideIn(0.06).value),
                          child: Opacity(
                            opacity: _fadeIn(0.06).value,
                            child: Row(
                              children: [
                                Text(
                                  _userName.isNotEmpty ? _userName : 'Executive',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 26,
                                      fontWeight: FontWeight.w900, letterSpacing: -0.4),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.5), size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _livePill() {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.30)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6EE7B7).withOpacity(0.7 + 0.3 * _pulseCtrl.value),
                boxShadow: [BoxShadow(
                    color: const Color(0xFF6EE7B7).withOpacity(0.6 * _pulseCtrl.value),
                    blurRadius: 6)],
              ),
            ),
            const SizedBox(width: 6),
            const Text('LIVE', style: TextStyle(
                color: Colors.white, fontSize: 10,
                fontWeight: FontWeight.w900, letterSpacing: 1.4)),
          ],
        ),
      ),
    );
  }

  // ── METRIC CARDS ───────────────────────────────────────────────────────────

  Widget _buildMetricCards() {
    return AnimatedBuilder(
      animation: _slideIn(0.10),
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _slideIn(0.10).value),
        child: Opacity(
          opacity: _fadeIn(0.10).value,
          child: Row(children: [
            _metricCard(
              label: "Today's Revenue",
              value: _todayCollection,
              profit: _todayProfit,
              icon: Icons.trending_up_rounded,
              iconBg: _C.indigoLt,
              iconColor: _C.indigo,
              valueColor: _C.indigo,
              badge: 'Today',
              badgeColor: _C.indigoLt,
              badgeTextColor: _C.indigo,
              onTap: () => _nav(const DailyCollectionsScreen()),
            ),
            const SizedBox(width: 14),
            _metricCard(
              label: 'Net Revenue',
              value: _cashInHand,
              profit: _netProfit,
              icon: Icons.account_balance_wallet_rounded,
              iconBg: _C.tealLt,
              iconColor: _C.teal,
              valueColor: _C.teal,
              badge: 'Net',
              badgeColor: _C.tealLt,
              badgeTextColor: _C.teal,
              onTap: () => _nav(const DailyCollectionsScreen(isMonthly: true)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _metricCard({
    required String label,
    required String value,
    String? profit,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required Color valueColor,
    required String badge,
    required Color badgeColor,
    required Color badgeTextColor,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (onTap != null) {
            HapticFeedback.mediumImpact();
            onTap();
          }
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _C.border),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.045),
                blurRadius: 16, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                        color: iconBg, borderRadius: BorderRadius.circular(12)),
                    child: Icon(icon, color: iconColor, size: 18),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: badgeColor, borderRadius: BorderRadius.circular(8)),
                    child: Text(badge, style: TextStyle(
                        color: badgeTextColor, fontSize: 9, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(value, style: TextStyle(
                  color: valueColor, fontSize: 26,
                  fontWeight: FontWeight.w900, letterSpacing: -0.6)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(label, 
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _C.textSec, fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                  if (profit != null)
                    Text('Profit: $profit', style: const TextStyle(
                        color: _C.emerald, fontSize: 9, fontWeight: FontWeight.w800)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  // ── QR TOOLS HUB ─────────────────────────────────────────────────────────────

  Widget _buildQRToolsHub() {
    return AnimatedBuilder(
      animation: _fadeIn(0.16),
      builder: (_, __) => Opacity(
        opacity: _fadeIn(0.16).value,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _C.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16, offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _C.indigoLt,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.qr_code_scanner_rounded, color: _C.indigo, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('QR & RFID HUB', style: TextStyle(
                          color: _C.textPri, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.0
                        )),
                        Text('Operations Control Center', style: TextStyle(
                          color: _C.textSec, fontSize: 10,
                        )),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, color: _C.textSec.withOpacity(0.4), size: 12),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _qrAction('Scan & Bill', Icons.shopping_cart_checkout, _C.indigo, _C.indigoLt, () => _nav(const QRScannerHubScreen(initialMode: 'bill'))),
                  _qrAction('Manage Stock', Icons.warehouse, _C.amber, _C.amberLt, () => _nav(const QRScannerHubScreen(initialMode: 'inventory'))),
                  _qrAction('Track Orders', Icons.local_shipping, _C.teal, _C.tealLt, () => _nav(const QRScannerHubScreen(initialMode: 'track'))),
                  _qrAction('RFID Audit', Icons.sensors_rounded, _C.violet, _C.violetLt, () => _nav(const RFIDCommandCenterScreen())),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _qrAction(String label, IconData icon, Color accentColor, Color bgColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.heavyImpact();
        onTap();
      },
      child: Column(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(icon, color: accentColor, size: 24),
            ),
          ),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(
            color: _C.textSec, fontSize: 10, fontWeight: FontWeight.w600,
          )),
        ],
      ),
    );
  }

  // ── SECTION LABEL ──────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String text) {
    return Text(text, style: const TextStyle(
        color: _C.textPri, fontSize: 16,
        fontWeight: FontWeight.w800, letterSpacing: -0.2));
  }

  // ── SERVICES GRID ──────────────────────────────────────────────────────────

  Widget _buildServicesGrid() {
    final svcs = [
      _Svc('New Order',  Icons.add_shopping_cart_rounded,  _C.indigo,   _C.indigoLt,   widget.onAddOrder),
      _Svc('Invoices',   Icons.receipt_rounded,             _C.fuchsia,  _C.fuchsiaLt,  () => _nav(const MyOrderListScreen())),
      _Svc('Job Cards',  Icons.assignment_rounded,          _C.sky,      _C.skyLt,      () => _nav(const JobCardsListScreen())),
      _Svc('Expenses',   Icons.receipt_long_rounded,        _C.rose,     _C.roseLt,     () => _nav(const ExpensesScreen())),
      _Svc('Reports',    Icons.bar_chart_rounded,           _C.fuchsia,  _C.fuchsiaLt,  () => _nav(const ReportsScreen())),
      _Svc('Inventory',  Icons.inventory_2_rounded,         _C.amber,    _C.amberLt,    () => _nav(const LocalInventoryScreen())),
      _Svc('Tasks',      Icons.checklist_rounded,           _C.teal,     _C.tealLt,     () => _nav(const TaskManagementScreen())),
      _Svc('Staff',      Icons.badge_rounded,               _C.emerald,  _C.emeraldLt,  () => _nav(const StaffListScreen())),
      _Svc('Vendors',    Icons.business_rounded,            _C.violet,   _C.violetLt,   () => _nav(const VendorMasterScreen())),
      _Svc('Ledger',     Icons.account_balance_rounded,     _C.orange,   _C.orangeLt,   () => _nav(const MyLedgerScreen())),
    ];

    return AnimatedBuilder(
      animation: _fadeIn(0.22),
      builder: (_, __) => Opacity(
        opacity: _fadeIn(0.22).value,
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 18, 10, 18),
          decoration: BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _C.border),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16, offset: const Offset(0, 4))],
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 18,
              crossAxisSpacing: 4,
              childAspectRatio: 0.88,
            ),
            itemCount: svcs.length,
            itemBuilder: (_, i) {
              final s = svcs[i];
              return GestureDetector(
                onTap: () { HapticFeedback.lightImpact(); s.onTap(); },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 54, height: 54,
                      decoration: BoxDecoration(
                        color: s.bg,
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: Icon(s.icon, color: s.color, size: 24),
                    ),
                    const SizedBox(height: 8),
                    Text(s.label,
                        textAlign: TextAlign.center,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: _C.textSec, fontSize: 10, fontWeight: FontWeight.w700)),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ── OPS CARD ───────────────────────────────────────────────────────────────

  Widget _buildOpsCard() {
    return AnimatedBuilder(
      animation: _fadeIn(0.36),
      builder: (_, __) => Opacity(
        opacity: _fadeIn(0.36).value,
        child: Container(
          decoration: BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _C.border),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16, offset: const Offset(0, 4))],
          ),
          child: Column(children: [
            // header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
              child: Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, __) => Container(
                      width: 7, height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _C.emerald,
                        boxShadow: [BoxShadow(
                            color: _C.emerald.withOpacity(0.55 * _pulseCtrl.value),
                            blurRadius: 8)],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Real-time status', style: TextStyle(
                      color: _C.textSec, fontSize: 12,
                      fontWeight: FontWeight.w700, letterSpacing: 0.3)),
                ],
              ),
            ),
            Divider(height: 1, color: _C.border),
            // 3 cells
            IntrinsicHeight(
              child: Row(children: [
                _opsCell('ACTIVE\nJOBS',    _activeJobCards, _C.sky,    _C.skyLt,
                        () => _nav(const MyOrderListScreen(initialStatus: 'Active')), isFirst: true),
                VerticalDivider(width: 1, color: _C.border),
                _opsCell('PENDING\nTASKS', _pendingTasks,   _C.amber,  _C.amberLt,
                        () => _nav(const TaskManagementScreen())),
                VerticalDivider(width: 1, color: _C.border),
                _opsCell('LOW\nSTOCK',     _lowStockCount,  _C.rose,   _C.roseLt,
                        () => _nav(const InventoryAlertsScreen()), isLast: true),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _opsCell(String label, int count, Color color, Color bg, VoidCallback onTap,
      {bool isFirst = false, bool isLast = false}) {
    return Expanded(
      child: GestureDetector(
        onTap: () { HapticFeedback.selectionClick(); onTap(); },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 22),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.only(
              bottomLeft:  isFirst ? const Radius.circular(27) : Radius.zero,
              bottomRight: isLast  ? const Radius.circular(27) : Radius.zero,
            ),
          ),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(12)),
              child: Text('$count', style: TextStyle(
                  color: color, fontSize: 24,
                  fontWeight: FontWeight.w900, height: 1)),
            ),
            const SizedBox(height: 10),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: _C.textSec, fontSize: 8.5,
                    fontWeight: FontWeight.w800, letterSpacing: 1.0, height: 1.5)),
          ]),
        ),
      ),
    );
  }

  void _nav(Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
}

// ─────────────────────────────────────────────────────────────────────────────
//  Models
// ─────────────────────────────────────────────────────────────────────────────
class _Svc {
  final String   label;
  final IconData icon;
  final Color    color;
  final Color    bg;
  final VoidCallback onTap;
  const _Svc(this.label, this.icon, this.color, this.bg, this.onTap);
}