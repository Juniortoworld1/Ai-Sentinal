import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/sentinel_state.dart';
import '../theme/app_colors.dart';
import 'critical_issues_page.dart';
import 'dashboard_screen.dart';

/// Bottom-nav shell hosting the two tabs. All shared data now lives in
/// SentinelState (via Provider), so this widget only needs to track which
/// tab is selected -- no more passing mode/callbacks down manually.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Only watched here for the unread-count badge on the nav bar.
    final criticalCount = context.watch<SentinelState>().criticalLog.length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        // IndexedStack keeps both tabs mounted, so the live feed's packet
        // timer (inside SentinelState) keeps running and keeps logging new
        // critical issues even while you're looking at the other tab.
        child: IndexedStack(
          index: _tabIndex,
          children: const [
            DashboardScreen(),
            CriticalIssuesPage(),
          ],
        ),
      ),
      bottomNavigationBar: _buildNavBar(criticalCount),
    );
  }

  Widget _buildNavBar(int criticalCount) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: _navItem(0, Icons.dashboard_outlined, 'Live Feed'),
            ),
            Expanded(
              child: _navItem(
                1,
                Icons.warning_amber_rounded,
                'Critical Issues',
                badgeCount: criticalCount,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label, {int? badgeCount}) {
    final bool selected = _tabIndex == index;
    final Color color = selected ? AppColors.neonGreen : AppColors.textMuted;

    return InkWell(
      onTap: () => setState(() => _tabIndex = index),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: color, size: 22),
                if (badgeCount != null && badgeCount > 0)
                  Positioned(
                    right: -12,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      constraints: const BoxConstraints(minWidth: 16),
                      decoration: BoxDecoration(
                        color: AppColors.neonRed,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}