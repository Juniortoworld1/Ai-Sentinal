import 'package:flutter/material.dart';

import '../models/network_packet.dart';
import '../theme/app_colors.dart';
import 'status_badge.dart';

class PacketRow extends StatelessWidget {
  final NetworkPacket packet;
  final bool selected;
  final Animation<double> blinkAnimation;
  final VoidCallback onTap;

  const PacketRow({
    super.key,
    required this.packet,
    required this.selected,
    required this.blinkAnimation,
    required this.onTap,
  });

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final bool isCritical = packet.risk == RiskStatus.critical;
    final time = packet.timestamp;
    final timeStr =
        '${_two(time.hour)}:${_two(time.minute)}:${_two(time.second)}';

    TextStyle cellStyle = TextStyle(
      color: AppColors.textMain.withOpacity(0.92),
      fontSize: 12.5,
      fontFamily: 'monospace',
    );

    return InkWell(
      onTap: isCritical ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.neonRed.withOpacity(0.08)
              : (isCritical
              ? AppColors.neonRed.withOpacity(0.04)
              : Colors.transparent),
          border: Border(
            bottom: BorderSide(color: AppColors.border.withOpacity(0.6)),
            left: BorderSide(
              color: selected ? AppColors.neonRed : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(flex: 3, child: Text(timeStr, style: cellStyle)),
            Expanded(flex: 3, child: Text(packet.sourceIp, style: cellStyle)),
            Expanded(flex: 3, child: Text(packet.destIp, style: cellStyle)),
            Expanded(
              flex: 2,
              child: Container(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.neonCyan.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    packet.protocol,
                    style: TextStyle(
                      color: AppColors.neonCyan,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text('${packet.payloadSize} B', style: cellStyle),
            ),
            Expanded(
              flex: 3,
              child: Align(
                alignment: Alignment.centerRight,
                child: isCritical
                    ? AnimatedBuilder(
                  animation: blinkAnimation,
                  builder: (context, _) {
                    final double t = blinkAnimation.value;
                    return StatusBadge(
                      text: 'CRITICAL ALERT',
                      color: AppColors.neonRed,
                      glowStrength: 0.3 + 0.6 * t,
                    );
                  },
                )
                    : StatusBadge(
                  text: 'SAFE',
                  color: AppColors.neonGreen,
                  glowStrength: 0.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}