import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/network_packet.dart';
import '../services/mock_data_generator.dart';
import '../state/sentinel_state.dart';
import '../theme/app_colors.dart';
import '../widgets/live_source_badge.dart';

/// A running incident log: every critical packet flagged this session,
/// searchable, with a breakdown by attack type. Unlike the Live Feed,
/// nothing here scrolls away on its own -- it stays until "Clear log".
class CriticalIssuesPage extends StatefulWidget {
  const CriticalIssuesPage({super.key});

  @override
  State<CriticalIssuesPage> createState() => _CriticalIssuesPageState();
}

class _CriticalIssuesPageState extends State<CriticalIssuesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  final Set<String> _expandedIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<NetworkPacket> _filtered(List<NetworkPacket> all) {
    if (_query.isEmpty) return all;
    final q = _query.toLowerCase();
    return all.where((p) {
      return p.sourceIp.toLowerCase().contains(q) ||
          p.destIp.toLowerCase().contains(q) ||
          (p.attackType ?? '').toLowerCase().contains(q);
    }).toList();
  }

  void _toggleExpand(BuildContext context, NetworkPacket packet) {
    setState(() {
      if (_expandedIds.contains(packet.id)) {
        _expandedIds.remove(packet.id);
      } else {
        _expandedIds.add(packet.id);
        // Lazily fetch + cache the analysis the moment a card opens.
        context.read<SentinelState>().ensureAnalysisFor(packet);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SentinelState>();
    final allCritical = state.criticalLog;
    final packets = _filtered(allCritical);

    final Map<String, int> breakdown = {};
    for (final p in allCritical) {
      final key = p.attackType ?? 'Unknown';
      breakdown[key] = (breakdown[key] ?? 0) + 1;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: AppColors.neonRed, size: 22),
              const SizedBox(width: 10),
              Text(
                'CRITICAL ISSUES',
                style: TextStyle(
                  color: AppColors.textMain,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: allCritical.isEmpty
                    ? null
                    : () {
                  context.read<SentinelState>().clearCriticalLog();
                  setState(() => _expandedIds.clear());
                },
                icon: Icon(Icons.delete_outline,
                    size: 16, color: AppColors.textMuted),
                label: Text(
                  'Clear log',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'A running record of every threat this session has flagged -- '
                'nothing here ages out of the live feed.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
          ),
          const SizedBox(height: 16),
          _buildBreakdownRow(breakdown),
          if (breakdown.isNotEmpty) const SizedBox(height: 16),
          _buildSearchField(),
          const SizedBox(height: 16),
          Expanded(
            child: packets.isEmpty
                ? Center(
              child: Text(
                allCritical.isEmpty
                    ? 'No critical issues yet -- they will appear\nhere the moment the live feed flags one.'
                    : 'No matches for "$_query".',
                textAlign: TextAlign.center,
                style:
                TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            )
                : ListView.builder(
              itemCount: packets.length,
              itemBuilder: (context, index) =>
                  _buildIssueCard(context, state, packets[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (v) => setState(() => _query = v),
      style: TextStyle(color: AppColors.textMain, fontSize: 13),
      decoration: InputDecoration(
        hintText: 'Filter by IP or attack type...',
        hintStyle: TextStyle(color: AppColors.textMuted),
        prefixIcon: Icon(Icons.search, color: AppColors.textMuted, size: 18),
        filled: true,
        fillColor: AppColors.panel,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.neonCyan.withOpacity(0.6)),
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(Map<String, int> breakdown) {
    if (breakdown.isEmpty) return const SizedBox.shrink();
    final entries = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: entries.map((e) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                e.key,
                style: TextStyle(
                  color: AppColors.textMain,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.neonRed.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${e.value}',
                  style: TextStyle(
                    color: AppColors.neonRed,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildIssueCard(
      BuildContext context,
      SentinelState state,
      NetworkPacket packet,
      ) {
    final bool expanded = _expandedIds.contains(packet.id);
    final bool loading = state.isLoadingAnalysis(packet.id);
    final analysis = state.analysisFor(packet.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _toggleExpand(context, packet),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.neonRed.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.neonRed.withOpacity(0.4),
                                ),
                              ),
                              child: Text(
                                packet.attackType ?? 'Threat',
                                style: TextStyle(
                                  color: AppColors.neonRed,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatTimestamp(packet.timestamp),
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${packet.sourceIp}  →  ${packet.destIp}:${packet.destinationPort}',
                          style: TextStyle(
                            color: AppColors.textMain,
                            fontSize: 13,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${packet.riskScore}',
                    style: TextStyle(
                      color: AppColors.neonRed,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: loading
                  ? Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.neonRed,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Asking Gemini SOC analyst...',
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              )
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        'AI ANALYSIS',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const Spacer(),
                      if (analysis != null)
                        LiveSourceBadge(
                            usingFallback: analysis.isFallback),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    analysis?.text ?? '',
                    style: TextStyle(
                      color: AppColors.textMain,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    MockDataGenerator.actionTextFor(packet, state.mode),
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      height: 1.4,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
  }
}