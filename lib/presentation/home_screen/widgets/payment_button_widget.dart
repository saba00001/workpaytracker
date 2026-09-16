import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PaymentButtonWidget extends StatefulWidget {
  final double currentEarnings;
  final int workedDays;
  final VoidCallback? onPressed;

  const PaymentButtonWidget({
    super.key,
    required this.currentEarnings,
    required this.workedDays,
    required this.onPressed,
  });

  @override
  State<PaymentButtonWidget> createState() => _PaymentButtonWidgetState();
}

class _PaymentButtonWidgetState extends State<PaymentButtonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;

    return GestureDetector(
      onTapDown: enabled ? (_) => _pressCtrl.forward() : null,
      onTapUp: enabled
          ? (_) {
              _pressCtrl.reverse();
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: () => _pressCtrl.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 22),
          decoration: BoxDecoration(
            gradient: enabled
                ? const LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF10B981)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: enabled ? null : const Color(0xFF111214),
            borderRadius: BorderRadius.circular(20),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: const Color(0xFF10B981).withAlpha(60),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
            border: Border.all(
              color: enabled
                  ? Colors.white.withAlpha(25)
                  : const Color(0xFF1E2028),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: enabled
                      ? Colors.white.withAlpha(25)
                      : const Color(0xFF16181C),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.payments_rounded,
                  color: enabled ? Colors.white : const Color(0xFF4B5563),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PAYMENT RECEIVED',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: enabled ? Colors.white : const Color(0xFF4B5563),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      enabled
                          ? 'Save ₾${widget.currentEarnings.toStringAsFixed(0)} · ${widget.workedDays} ${widget.workedDays == 1 ? 'day' : 'days'}'
                          : 'Record worked days first',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: enabled
                            ? Colors.white.withAlpha(200)
                            : const Color(0xFF4B5563),
                      ),
                    ),
                  ],
                ),
              ),
              if (enabled)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
