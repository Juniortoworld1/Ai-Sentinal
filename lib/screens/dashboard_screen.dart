import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/network_packet.dart';
import '../state/sentinel_state.dart';
import '../theme/app_colors.dart';
import '../widgets/live_source_badge.dart';
import '../widgets/metric_card.dart';
import '../widgets/packet_row.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  // Purely cosmetic animation state -- doesn't belong in shared app state.
  late final AnimationController _pulseController;
  late final AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          const SizedBox(height: 20),
          _buildMetricsRow(context),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 3, child: _buildPacketStreamPanel(context)),
                const SizedBox(width: 20),
                SizedBox(
                  width: 360,
                  child: _buildThreatAnalysisPanel(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- HEADER ----------------
  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, _) {
            final double t = _pulseController.value;
            return Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.neonGreen,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonGreen.withOpacity(0.25 + 0.55 * t),
                    blurRadius: 6 + 14 * t,
                    spreadRadius: 1 + 4 * t,
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI-SENTINEL ACTIVE',
                style: TextStyle(
                  color: AppColors.textMain,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  shadows: [
                    Shadow(
                      color: AppColors.neonGreen.withOpacity(0.45),
                      blurRadius: 16,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Real-time Network Intrusion Detection · Command Center',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        _buildDefenseModeToggle(context),
      ],
    );
  }

  // ---------------- DEFENSE MODE TOGGLE ----------------
  Widget _buildDefenseModeToggle(BuildContext context) {
    final mode = context.watch<SentinelState>().mode;
    final bool isAuto = mode == DefenseMode.autonomous;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'DEFENSE MODE',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isAuto ? 'AI Autonomous Interdiction' : 'Passive Monitoring',
                style: TextStyle(
                  color: isAuto ? AppColors.neonGreen : AppColors.neonCyan,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Switch(
            value: isAuto,
            onChanged: (value) =>
                context.read<SentinelState>().setMode(value),
            activeColor: AppColors.neonGreen,
            activeTrackColor: AppColors.neonGreen.withOpacity(0.25),
            inactiveThumbColor: AppColors.neonCyan,
            inactiveTrackColor: AppColors.neonCyan.withOpacity(0.2),
          ),
        ],
      ),
    );
  }

  // ---------------- METRICS ROW ----------------
  Widget _buildMetricsRow(BuildContext context) {
    final state = context.watch<SentinelState>();
    return Row(
      children: [
        Expanded(
          child: MetricCard(
            label: 'TOTAL PACKETS SCANNED',
            value: state.totalScanned.toString().replaceAllMapped(
                RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},'),
            icon: Icons.shield_outlined,
            accent: AppColors.neonCyan,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: MetricCard(
            label: 'ACTIVE THREATS BLOCKED',
            value: state.threatsBlocked.toString(),
            icon: Icons.gpp_bad_outlined,
            accent: AppColors.neonRed,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: MetricCard(
            label: 'SYSTEM HEALTH',
            value: '${state.systemHealth.toStringAsFixed(1)}%',
            icon: Icons.monitor_heart_outlined,
            accent: AppColors.neonGreen,
          ),
        ),
      ],
    );
  }

  // ---------------- PACKET STREAM PANEL ----------------
  Widget _buildPacketStreamPanel(BuildContext context) {
    final state = context.watch<SentinelState>();
    final packets = state.packets;
    final selectedId = state.selectedPacketId;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Icon(Icons.lan_outlined, color: AppColors.neonCyan, size: 18),
                const SizedBox(width: 8),
                Text(
                  'LIVE PACKET STREAM',
                  style: TextStyle(
                    color: AppColors.textMain,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
                const Spacer(),
                Text(
                  'Tap a critical row for AI analysis',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          _buildColumnHeader(),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: ListView.builder(
              itemCount: packets.length,
              itemBuilder: (context, index) {
                final packet = packets[index];
                return PacketRow(
                  packet: packet,
                  selected: selectedId == packet.id,
                  blinkAnimation: _blinkController,
                  onTap: () =>
                      context.read<SentinelState>().selectPacket(packet),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnHeader() {
    TextStyle style = TextStyle(
      color: AppColors.textMuted,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('TIMESTAMP', style: style)),
          Expanded(flex: 3, child: Text('SOURCE IP', style: style)),
          Expanded(flex: 3, child: Text('DESTINATION IP', style: style)),
          Expanded(flex: 2, child: Text('PROTO', style: style)),
          Expanded(flex: 3, child: Text('PAYLOAD', style: style)),
          Expanded(
            flex: 3,
            child:
            Text('RISK STATUS', style: style, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  // ---------------- AI THREAT ANALYSIS PANEL ----------------
  Widget _buildThreatAnalysisPanel(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology_outlined,
                  color: AppColors.neonRed, size: 18),
              const SizedBox(width: 8),
              Text(
                'AI THREAT ANALYSIS ROOM',
                style: TextStyle(
                  color: AppColors.textMain,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Autonomous threat reasoning, live from the detection engine.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 18),
          Expanded(child: _buildAnalysisBody(context)),
        ],
      ),
    );
  }

  Widget _buildAnalysisBody(BuildContext context) {
    final state = context.watch<SentinelState>();
    final packet = state.selectedPacket;

    if (packet == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app_outlined,
                color: AppColors.textMuted, size: 36),
            const SizedBox(height: 12),
            Text(
              'Select a flagged (critical) packet\nfrom the stream to view AI analysis.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final bool loading = state.isLoadingAnalysis(packet.id);

    if (loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: AppColors.neonRed,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Asking Gemini SOC analyst about ${packet.sourceIp} ...',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final analysis = state.analysisFor(packet.id);
    if (analysis == null) return const SizedBox.shrink();
    final actionText = state.selectedActionText ?? '';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.neonRed.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border:
                  Border.all(color: AppColors.neonRed.withOpacity(0.4)),
                ),
                child: Text(
                  packet.attackType ?? 'Threat Detected',
                  style: TextStyle(
                    color: AppColors.neonRed,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              LiveSourceBadge(usingFallback: analysis.isFallback),
            ],
          ),
          const SizedBox(height: 14),
          _infoLine('Source IP', packet.sourceIp),
          _infoLine('Destination IP', packet.destIp),
          _infoLine('Protocol', packet.protocol),
          _infoLine('Destination Port', packet.destinationPort.toString()),
          _infoLine('Payload Size', '${packet.payloadSize} bytes'),
          _infoLine('Risk Score', '${packet.riskScore}/100'),
          _infoLine('Detected At', _formatTime(packet.timestamp)),
          const SizedBox(height: 18),
          Text(
            'AI ANALYSIS',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            analysis.text,
            style: TextStyle(
              color: AppColors.textMain,
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'SYSTEM ACTION (DEFENSE MODE)',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.panelAlt,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  state.mode == DefenseMode.autonomous
                      ? Icons.gpp_good_outlined
                      : Icons.visibility_outlined,
                  color: state.mode == DefenseMode.autonomous
                      ? AppColors.neonGreen
                      : AppColors.neonCyan,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    actionText,
                    style: TextStyle(
                      color: AppColors.textMain,
                      fontSize: 12.5,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.textMain,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
  }
}