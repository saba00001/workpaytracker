import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Full-screen work confirmation screen — Georgian UI.
class WorkConfirmationScreen extends StatefulWidget {
  final Future<void> Function(bool worked) onConfirm;
  final bool? currentStatus;

  const WorkConfirmationScreen({
    super.key,
    required this.onConfirm,
    this.currentStatus,
  });

  @override
  State<WorkConfirmationScreen> createState() => _WorkConfirmationScreenState();
}

class _WorkConfirmationScreenState extends State<WorkConfirmationScreen>
    with TickerProviderStateMixin {
  late AnimationController _entranceCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _pulseAnim;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _fadeAnim = CurvedAnimation(
      parent: _entranceCtrl,
      curve: Curves.easeOutCubic,
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic),
        );
    _pulseAnim = Tween<double>(
      begin: 0.92,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm(bool worked) async {
    if (_loading) return;
    HapticFeedback.heavyImpact();
    setState(() => _loading = true);
    await widget.onConfirm(worked);
    if (mounted) Navigator.of(context).pop();
  }

  String _formatDate(DateTime d) {
    const geoWeekdays = [
      '',
      'ორშაბათი',
      'სამშაბათი',
      'ოთხშაბათი',
      'ხუთშაბათი',
      'პარასკევი',
      'შაბათი',
      'კვირა',
    ];
    const geoMonths = [
      '',
      'იანვ',
      'თებ',
      'მარ',
      'აპრ',
      'მაი',
      'ივნ',
      'ივლ',
      'აგვ',
      'სექ',
      'ოქტ',
      'ნოე',
      'დეკ',
    ];
    return '${geoWeekdays[d.weekday]}, ${d.day} ${geoMonths[d.month]}';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = _formatDate(now);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0B0D),
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _GlowPainter())),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  children: [
                    // Top bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFF16181C),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF1E2028),
                                ),
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Color(0xFF6B7280),
                                size: 18,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16181C),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF1E2028),
                              ),
                            ),
                            child: Text(
                              dateStr,
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: const Color(0xFF9CA3AF),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Pulsing icon
                    ScaleTransition(
                      scale: _pulseAnim,
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withAlpha(18),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF10B981).withAlpha(50),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withAlpha(30),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.work_rounded,
                          color: Color(0xFF10B981),
                          size: 52,
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'იმუშავე დღეს?',
                        style: GoogleFonts.dmSans(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFFAFAFA),
                          letterSpacing: -0.8,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'დააჭირე დიახ ან არა, რომ სამუშაო დღე დაფიქსირდეს.',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: const Color(0xFF6B7280),
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const Spacer(),
                    // Buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          _BigButton(
                            label: 'დიახ, ვიმუშავე',
                            sublabel: 'სამუშაო დღედ მოინიშნება',
                            icon: Icons.check_circle_rounded,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF059669), Color(0xFF10B981)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            glowColor: const Color(0xFF10B981),
                            onTap: _loading ? null : () => _handleConfirm(true),
                          ),
                          const SizedBox(height: 12),
                          _BigButton(
                            label: 'არა, არ მიმუშავია',
                            sublabel: 'დასვენების დღედ მოინიშნება',
                            icon: Icons.cancel_rounded,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF991B1B), Color(0xFFEF4444)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            glowColor: const Color(0xFFEF4444),
                            onTap: _loading
                                ? null
                                : () => _handleConfirm(false),
                          ),
                          const SizedBox(height: 16),
                          if (widget.currentStatus != null)
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                'უკვე დაფიქსირებულია — დახურვა',
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
          if (_loading)
            Container(
              color: Colors.black.withAlpha(100),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF10B981)),
              ),
            ),
        ],
      ),
    );
  }
}

class _BigButton extends StatefulWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  final LinearGradient gradient;
  final Color glowColor;
  final VoidCallback? onTap;

  const _BigButton({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.gradient,
    required this.glowColor,
    required this.onTap,
  });

  @override
  State<_BigButton> createState() => _BigButtonState();
}

class _BigButtonState extends State<_BigButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = _pressCtrl;
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.reverse(),
      onTapUp: (_) {
        _pressCtrl.forward();
        widget.onTap?.call();
      },
      onTapCancel: () => _pressCtrl.forward(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          decoration: BoxDecoration(
            gradient: widget.onTap != null ? widget.gradient : null,
            color: widget.onTap == null ? const Color(0xFF1C1E24) : null,
            borderRadius: BorderRadius.circular(20),
            boxShadow: widget.onTap != null
                ? [
                    BoxShadow(
                      color: widget.glowColor.withAlpha(60),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(25),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(widget.icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: GoogleFonts.dmSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.sublabel,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: Colors.white.withAlpha(160),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.2),
        radius: 0.8,
        colors: [const Color(0xFF10B981).withAlpha(18), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
