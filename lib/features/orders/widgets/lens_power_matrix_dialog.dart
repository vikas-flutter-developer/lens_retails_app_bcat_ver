import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LensPowerMatrixDialog extends StatefulWidget {
  final Map<String, dynamic>? selectedItem;
  final Function(List<Map<String, dynamic>>) onAddItems;

  const LensPowerMatrixDialog({
    super.key,
    required this.selectedItem,
    required this.onAddItems,
  });

  @override
  State<LensPowerMatrixDialog> createState() => _LensPowerMatrixDialogState();
}

class _LensPowerMatrixDialogState extends State<LensPowerMatrixDialog> {
  // Range Filters
  final _sphMinController = TextEditingController(text: '-4');
  final _sphMaxController = TextEditingController(text: '4');
  final _cylMinController = TextEditingController(text: '-4');
  final _cylMaxController = TextEditingController(text: '0');
  final _addMinController = TextEditingController(text: '1');
  final _addMaxController = TextEditingController(text: '2');

  // Eye Selection
  String _selectedEye = 'RL';

  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();

  // Matrix: key = "SPH_CYL_ADD", value = quantity entered
  final Map<String, TextEditingController> _controllers = {};

  List<double> _sphValues = [];
  List<double> _cylValues = [];
  List<double> _addValues = [];
  final double _step = 0.25;

  int _resetKey = 0;

  @override
  void initState() {
    super.initState();
    _generateGrid();
  }

  @override
  void dispose() {
    _sphMinController.dispose();
    _sphMaxController.dispose();
    _cylMinController.dispose();
    _cylMaxController.dispose();
    _addMinController.dispose();
    _addMaxController.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  void _generateGrid() {
    // Dispose old controllers
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();

    setState(() {
      double sMin = double.tryParse(_sphMinController.text) ?? -1.0;
      double sMax = double.tryParse(_sphMaxController.text) ?? 2.0;
      double cMin = double.tryParse(_cylMinController.text) ?? -4.0;
      double cMax = double.tryParse(_cylMaxController.text) ?? 0.0;
      double aMin = double.tryParse(_addMinController.text) ?? 1.0;
      double aMax = double.tryParse(_addMaxController.text) ?? 2.0;

      // Custom sort helper: 0 first, negatives (closest to 0), then positives
      List<double> sortedRange(double mn, double mx) {
        final vals = _generateRange(mn, mx, _step);
        vals.sort((a, b) {
          if (a == 0 && b == 0) return 0;
          if (a == 0) return -1;
          if (b == 0) return 1;
          if (a < 0 && b < 0) return b.compareTo(a);
          if (a > 0 && b > 0) return a.compareTo(b);
          if (a < 0) return -1;
          return 1;
        });
        return vals;
      }

      _sphValues = sortedRange(sMin, sMax);
      _cylValues = sortedRange(cMin, cMax);
      _addValues = _generateRange(aMin, aMax, _step);

      // Pre-create controllers for each cell (SPH × CYL × ADD)
      for (final sph in _sphValues) {
        for (final cyl in _cylValues) {
          for (final add in _addValues) {
            final key = _makeKey(sph, cyl, add);
            _controllers[key] = TextEditingController();
          }
        }
      }
    });
  }

  String _makeKey(double sph, double cyl, double add) =>
      '${sph.toStringAsFixed(2)}_${cyl.toStringAsFixed(2)}_${add.toStringAsFixed(2)}';

  List<double> _generateRange(double min, double max, double step) {
    List<double> values = [];
    if (min > max) return values;
    double current = min;
    while (current <= max + 0.001) {
      values.add(double.parse(current.toStringAsFixed(2)));
      current += step;
    }
    return values;
  }

  // ─── Totals ────────────────────────────────────────────────
  int get _totalItems {
    int count = 0;
    for (final c in _controllers.values) {
      if ((int.tryParse(c.text) ?? 0) > 0) count++;
    }
    return count;
  }

  int get _totalQty {
    int sum = 0;
    for (final c in _controllers.values) {
      sum += int.tryParse(c.text) ?? 0;
    }
    return sum;
  }

  // ─── Add Items ─────────────────────────────────────────────
  void _addItems() {
    List<Map<String, dynamic>> itemsToAdd = [];

    _controllers.forEach((key, ctrl) {
      final qty = int.tryParse(ctrl.text) ?? 0;
      if (qty > 0) {
        // key format: "sph_cyl_add" e.g. "0.00_-0.25_1.00"
        final parts = key.split('_');
        // Handle negative sign: parts may be ["0.00", "-0.25", "1.00"]
        // or ["-0.25", "-0.50", "1.00"] etc.
        // We rebuild by joining with _ and re-parsing positions carefully
        // Since values are toStringAsFixed(2), format is like "0.00", "-0.25"
        // Split key by pattern: three groups separated by '_' but '-' is part of value
        final regex = RegExp(r'^(-?\d+\.\d+)_(-?\d+\.\d+)_(-?\d+\.\d+)$');
        final match = regex.firstMatch(key);
        final sph = match?.group(1) ?? '0.00';
        final cyl = match?.group(2) ?? '0.00';
        final add = match?.group(3) ?? '0.00';
        final eyeValue = _selectedEye == 'RL' ? 'BOTH' : _selectedEye;

        itemsToAdd.add({
          'itemName': widget.selectedItem?['itemName'] ??
              widget.selectedItem?['name'] ??
              'Lens Item',
          'itemId':
              widget.selectedItem?['_id'] ?? widget.selectedItem?['id'],
          'eye': eyeValue,
          'sph': sph,
          'cyl': cyl,
          'axis': '1',
          'add': add,
          'qty': qty.toDouble(),
          'salePrice': double.tryParse(
                  widget.selectedItem?['salePrice']?.toString() ?? '0') ??
              0.0,
          'totalAmount':
              (double.tryParse(
                          widget.selectedItem?['salePrice']?.toString() ??
                              '0') ??
                      0.0) *
                  qty,
          'key': '${DateTime.now().millisecondsSinceEpoch}$key',
        });
      }
    });

    if (itemsToAdd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter quantity first')),
      );
      return;
    }

    widget.onAddItems(itemsToAdd);
    Navigator.pop(context);
  }

  void _resetAll() {
    setState(() {
      for (final c in _controllers.values) {
        c.clear();
      }
      _resetKey++;
    });
  }

  // ═══════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 24,
        vertical: isMobile ? 16 : 32,
      ),
      child: Container(
        width: size.width * (isMobile ? 0.98 : 0.95),
        height: size.height * (isMobile ? 0.95 : 0.9),
        constraints: const BoxConstraints(maxWidth: 1300, maxHeight: 900),
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: EdgeInsets.all(isMobile ? 12.0 : 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFiltersRow(isMobile),
                  SizedBox(height: isMobile ? 12 : 18),
                  _buildEyeSelectorRow(),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: KeyedSubtree(
                    key: ValueKey(_resetKey),
                    child: _buildMatrix(),
                  ),
                ),
              ),
            ),
            _buildFooter(isMobile),
          ],
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.filter_alt_outlined,
                    color: Color(0xFF3B82F6), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bulk Lens Order Matrix',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.selectedItem?['itemName'] ?? 'Lens Item',
                        style:
                            TextStyle(color: Colors.blueGrey[300], fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 22),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // ─── Filters Row ───────────────────────────────────────────
  Widget _buildFiltersRow(bool isMobile) {
    Widget content = Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _buildInputCol('SPH FROM', _sphMinController)),
        const SizedBox(width: 8),
        Expanded(child: _buildInputCol('SPH TO', _sphMaxController)),
        const SizedBox(width: 16),
        Expanded(child: _buildInputCol('CYL FROM', _cylMinController)),
        const SizedBox(width: 8),
        Expanded(child: _buildInputCol('CYL TO', _cylMaxController)),
        const SizedBox(width: 16),
        Expanded(child: _buildInputCol('ADD FROM', _addMinController)),
        const SizedBox(width: 8),
        Expanded(child: _buildInputCol('ADD TO', _addMaxController)),
        const SizedBox(width: 16),
        SizedBox(
          height: 42,
          child: ElevatedButton.icon(
            onPressed: _generateGrid,
            icon: const Icon(Icons.search, size: 18),
            label: const Text('Show',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );

    if (isMobile) {
      return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: 900, child: content));
    }
    return content;
  }

  Widget _buildInputCol(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B))),
        const SizedBox(height: 8),
        SizedBox(
          height: 42,
          child: TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(
                signed: true, decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*'))
            ],
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide:
                    const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Eye Selector ──────────────────────────────────────────
  Widget _buildEyeSelectorRow() {
    return Row(
      children: [
        const Text('SELECT EYE:',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: Color(0xFF64748B))),
        const SizedBox(width: 16),
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildEyeOption('RL', isFirst: true),
              Container(width: 1, color: Colors.grey[200]),
              _buildEyeOption('R'),
              Container(width: 1, color: Colors.grey[200]),
              _buildEyeOption('L', isLast: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEyeOption(String value,
      {bool isFirst = false, bool isLast = false}) {
    final isSelected = _selectedEye == value;
    return InkWell(
      onTap: () => setState(() => _selectedEye = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E293B) : Colors.transparent,
          borderRadius: BorderRadius.horizontal(
            left: isFirst ? const Radius.circular(20) : Radius.zero,
            right: isLast ? const Radius.circular(20) : Radius.zero,
          ),
        ),
        child: Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // MATRIX TABLE  (SPH × CYL rows × ADD columns)
  // ═══════════════════════════════════════════════════════════
  Widget _buildMatrix() {
    if (_sphValues.isEmpty || _cylValues.isEmpty || _addValues.isEmpty) {
      return const Center(
        child: Text('No data. Adjust ranges and press Show.',
            style: TextStyle(color: Color(0xFF94A3B8))),
      );
    }

    // Fixed column widths
    const double sphColW  = 80;
    const double cylColW  = 80;
    const double axisColW = 60;
    const double addColW  = 110;

    final totalTableWidth =
        sphColW + cylColW + axisColW + (_addValues.length * addColW);

    // Column widths map: 0=SPH, 1=CYL, 2=AXIS, 3..N=ADD
    final colWidths = <int, TableColumnWidth>{
      0: const FixedColumnWidth(sphColW),
      1: const FixedColumnWidth(cylColW),
      2: const FixedColumnWidth(axisColW),
      for (int i = 0; i < _addValues.length; i++)
        i + 3: const FixedColumnWidth(addColW),
    };

    // Build all data rows (one per SPH × CYL combination)
    final dataRows = <TableRow>[];
    for (final sph in _sphValues) {
      for (final cyl in _cylValues) {
        dataRows.add(TableRow(
          decoration: const BoxDecoration(color: Colors.white),
          children: [
            // SPH label
            Container(
              height: 50,
              alignment: Alignment.center,
              color: const Color(0xFFF8FAFC),
              child: Text(
                _formatSph(sph),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            // CYL label
            Container(
              height: 50,
              alignment: Alignment.center,
              color: const Color(0xFFF1F5F9),
              child: Text(
                _formatSph(cyl),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Color(0xFF334155),
                ),
              ),
            ),
            // AXIS label (fixed = 1)
            Container(
              height: 50,
              alignment: Alignment.center,
              color: const Color(0xFFF8FAFC),
              child: const Text(
                '1',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
            // Qty input cells per ADD
            ..._addValues.map((add) {
              final key = _makeKey(sph, cyl, add);
              return Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 6),
                child: _buildQtyInput(key),
              );
            }),
          ],
        ));
      }
    }

    return Scrollbar(
      controller: _verticalScrollController,
      thumbVisibility: true,
      trackVisibility: true,
      thickness: 6,
      child: SingleChildScrollView(
        controller: _verticalScrollController,
        scrollDirection: Axis.vertical,
        child: Scrollbar(
          controller: _horizontalScrollController,
          thumbVisibility: true,
          trackVisibility: true,
          thickness: 6,
          notificationPredicate: (n) => n.depth == 1,
          child: SingleChildScrollView(
            controller: _horizontalScrollController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: totalTableWidth,
              child: Table(
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                border: TableBorder.all(
                    color: const Color(0xFFE2E8F0), width: 1),
                columnWidths: colWidths,
                children: [
                  // ── Header Row ──
                  TableRow(
                    decoration:
                        const BoxDecoration(color: Color(0xFF1E293B)),
                    children: [
                      _headerCell('SPH'),
                      _headerCell('CYL'),
                      _headerCell('AXIS'),
                      ..._addValues.map(
                        (add) => _headerCell(
                            add.toStringAsFixed(2),
                            isAdd: true),
                      ),
                    ],
                  ),
                  // ── Data Rows ──
                  ...dataRows,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerCell(String text, {bool isAdd = false}) {
    return Container(
      height: 48,
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 12,
          color: isAdd ? const Color(0xFF60A5FA) : Colors.white,
        ),
      ),
    );
  }

  String _formatSph(double v) {
    if (v >= 0) return '+${v.toStringAsFixed(2)}';
    return v.toStringAsFixed(2);
  }

  // ─── Qty Input ─────────────────────────────────────────────
  Widget _buildQtyInput(String key) {
    return SizedBox(
      height: 36,
      child: TextFormField(
        controller: _controllers[key],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A)),
        decoration: InputDecoration(
          hintText: '—',
          hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 16),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(6),
          ),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          focusedBorder: OutlineInputBorder(
            borderSide:
                const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        onChanged: (_) => setState(() {}), // update totals
      ),
    );
  }

  // ─── Footer ────────────────────────────────────────────────
  Widget _buildFooter(bool isMobile) {
    // Buttons widget — shared between mobile and desktop
    final actionButtons = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton.icon(
          onPressed: _resetAll,
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Reset',
              style: TextStyle(fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF475569),
            padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 24, vertical: 12),
            side: BorderSide(color: Colors.grey[300]!),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6)),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: _addItems,
          icon: const Icon(Icons.add, size: 18),
          label: Text(isMobile ? 'Add' : 'Add Items',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 14 : 28, vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6)),
            elevation: 0,
          ),
        ),
      ],
    );

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 14 : 24,
          vertical: isMobile ? 10 : 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: isMobile
          // ── Mobile: 2 rows (totals on top, buttons below) ──
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  _buildTotalChip('Items', '$_totalItems'),
                  const SizedBox(width: 16),
                  _buildTotalChip('Qty', '$_totalQty'),
                ]),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [actionButtons],
                ),
              ],
            )
          // ── Desktop: single row ────────────────────────────
          : Row(
              children: [
                _buildTotalChip('Total Items', '$_totalItems'),
                const SizedBox(width: 20),
                _buildTotalChip('Total Qty', '$_totalQty'),
                const Spacer(),
                actionButtons,
              ],
            ),
    );
  }

  Widget _buildTotalChip(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ',
            style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
                fontSize: 13)),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: Color(0xFF0F172A))),
      ],
    );
  }
}