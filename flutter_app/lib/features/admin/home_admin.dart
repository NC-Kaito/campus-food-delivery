import 'package:flutter/material.dart';
import 'package:flutter_app/features/admin/admin_navbar.dart';

class HomeAdmin extends StatefulWidget {
  const HomeAdmin({super.key});

  @override
  State<HomeAdmin> createState() => _HomeAdminState();
}

class _HomeAdminState extends State<HomeAdmin> {
  // Mock data — replace with real API
  final int totalShops = 32;
  final int totalDeliveries = 32;
  final int newShops = 4;
  final int newDeliveries = 12;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AdminNavbar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Dashboard Title ───────────────────────────────────────
            _buildTitle(),

            // ── Overview Section ──────────────────────────────────────
            _buildSectionHeader(
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/bar_chart.png',
                    width: 40,
                    height: 40,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.bar_chart_rounded,
                      color: Colors.orange,
                      size: 36,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '-Overview of Platform Activity',
                    style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: _buildOverviewRow(),
            ),

            const SizedBox(height: 16),

            // ── New Registration Section ───────────────────────────────
            _buildSectionHeader(
              child: Row(
                children: [
                  _NewBadge(),
                  const SizedBox(width: 8),
                  Text(
                    '-รายการใหม่',
                    style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: _buildNewRow(),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Title ──────────────────────────────────────────────────────────────────
  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Person + gear icon (replicate the emoji-like icon)
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.person, size: 32, color: Colors.grey[800]),
                Positioned(
                  right: -6,
                  bottom: -2,
                  child: Icon(
                    Icons.settings,
                    size: 16,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.grey[850],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section Header (grey bar) ──────────────────────────────────────────────
  Widget _buildSectionHeader({required Widget child}) {
    return Container(
      width: double.infinity,
      color: Colors.grey[200],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: child,
    );
  }

  // ── Overview Row (2 cards) ─────────────────────────────────────────────────
  Widget _buildOverviewRow() {
    return Row(
      children: [
        // Shop card
        Expanded(
          child: _OverviewCard(
            iconWidget: const Icon(
              Icons.store_rounded,
              size: 56,
              color: Color(0xFF4CAF50),
            ),
            iconBg: const Color(0xFFC8F2C2),
            label: 'จำนวนร้านค้าทั้งหมด',
            count: totalShops,
            statBg: const Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(width: 14),
        // Delivery card
        Expanded(
          child: _OverviewCard(
            iconWidget: const Icon(
              Icons.delivery_dining_rounded,
              size: 56,
              color: Color(0xFFFF9800),
            ),
            iconBg: const Color(0xFFFDE8CC),
            label: 'จำนวนผู้จัดส่งทั้งหมด',
            count: totalDeliveries,
            statBg: const Color(0xFFFF9800),
          ),
        ),
      ],
    );
  }

  // ── New Registration Row (2 cards) ────────────────────────────────────────
  Widget _buildNewRow() {
    return Row(
      children: [
        // New shops
        Expanded(
          child: _NewRegCard(
            iconWidget: const Icon(
              Icons.tablet_android_rounded,
              size: 52,
              color: Color(0xFFFF9800),
            ),
            iconBg: const Color(0xFFFFF9C4),
            label: 'การสมัครร้านค้าใหม่',
            count: newShops,
            statBg: const Color(0xFFFFEB3B),
          ),
        ),
        const SizedBox(width: 14),
        // New deliveries
        Expanded(
          child: _NewRegCard(
            iconWidget: const Icon(
              Icons.assignment_ind_rounded,
              size: 52,
              color: Color(0xFF2196F3),
            ),
            iconBg: const Color(0xFFFFF9C4),
            label: 'การสมัครผู้จัดส่งใหม่',
            count: newDeliveries,
            statBg: const Color(0xFFFFEB3B),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Overview Card
// ══════════════════════════════════════════════════════════════════════════════
class _OverviewCard extends StatelessWidget {
  final Widget iconWidget;
  final Color iconBg;
  final String label;
  final int count;
  final Color statBg;

  const _OverviewCard({
    required this.iconWidget,
    required this.iconBg,
    required this.label,
    required this.count,
    required this.statBg,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Row(
        children: [
          // Icon side
          Expanded(
            flex: 4,
            child: Container(
              color: iconBg,
              padding: const EdgeInsets.symmetric(vertical: 22),
              child: Center(child: iconWidget),
            ),
          ),
          // Stat side
          Expanded(
            flex: 5,
            child: Container(
              color: statBg,
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1,
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
}

// ══════════════════════════════════════════════════════════════════════════════
// New Registration Card
// ══════════════════════════════════════════════════════════════════════════════
class _NewRegCard extends StatelessWidget {
  final Widget iconWidget;
  final Color iconBg;
  final String label;
  final int count;
  final Color statBg;

  const _NewRegCard({
    required this.iconWidget,
    required this.iconBg,
    required this.label,
    required this.count,
    required this.statBg,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Row(
        children: [
          // Icon side
          Expanded(
            flex: 4,
            child: Container(
              color: iconBg,
              padding: const EdgeInsets.symmetric(vertical: 22),
              child: Center(child: iconWidget),
            ),
          ),
          // Stat side
          Expanded(
            flex: 5,
            child: Container(
              color: statBg,
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1,
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
}

// ══════════════════════════════════════════════════════════════════════════════
// NEW Badge (red starburst)
// ══════════════════════════════════════════════════════════════════════════════
class _NewBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(40, 40),
      painter: _StarburstPainter(),
      child: const SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: Text(
            'NEW',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}

class _StarburstPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFD32F2F);
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = size.width / 2;
    final innerR = size.width * 0.35;
    const points = 12;
    final path = Path();

    for (int i = 0; i < points * 2; i++) {
      final angle = (i * 3.14159265 / points) - 3.14159265 / 2;
      final r = i.isEven ? outerR : innerR;
      final x = cx + r * _cos(angle);
      final y = cy + r * _sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  double _cos(double angle) =>
      angle == 0 ? 1 : (angle == 3.14159265 ? -1 : _approxCos(angle));

  double _sin(double angle) => _approxSin(angle);

  double _approxCos(double x) {
    // Taylor series approximation
    double result = 1;
    double term = 1;
    for (int i = 1; i <= 8; i++) {
      term *= -x * x / ((2 * i - 1) * (2 * i));
      result += term;
    }
    return result;
  }

  double _approxSin(double x) {
    double result = x;
    double term = x;
    for (int i = 1; i <= 8; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
