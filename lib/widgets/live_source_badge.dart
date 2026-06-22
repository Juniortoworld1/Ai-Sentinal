import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Small pill showing whether an analysis came from the live Gemini call
/// or the local fallback text (so it's obvious during a demo which one
/// you're looking at).
class LiveSourceBadge extends StatelessWidget {
  final bool usingFallback;

  const LiveSourceBadge({super.key, required this.usingFallback});

  @override
  Widget build(BuildContext context) {
    final Color color =
    usingFallback ? AppColors.neonCyan : AppColors.neonGreen;
    final String label = usingFallback ? 'LOCAL FALLBACK' : 'LIVE GEMINI';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}