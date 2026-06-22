import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/network_packet.dart';
import '../services/mock_data_generator.dart';
import '../services/soc_analyst_api.dart';

/// Cached result of a (real or fallback) SOC-analyst explanation for one
/// packet, keyed by packet.id in SentinelState.
class AnalysisResult {
  final String text;
  final bool isFallback;
  const AnalysisResult({required this.text, required this.isFallback});
}

/// Single source of truth for the whole app, shared via Provider so both
/// the Live Feed tab and the Critical Issues tab read/write the same data
/// instead of passing it down through constructors.
///
/// Owns: the live packet stream, the persistent critical-issues log,
/// top-line metrics, the current defense mode, and a shared cache of
/// Gemini SOC-analyst explanations (so the same packet never gets
/// re-analyzed twice, even across tabs).
class SentinelState extends ChangeNotifier {
  SentinelState() {
    _seedInitialPackets();
    _streamTimer = Timer.periodic(
      const Duration(milliseconds: 2200),
          (_) => _pushNewPacket(),
    );
    _healthTimer = Timer.periodic(
      const Duration(seconds: 4),
          (_) => _refreshHealth(),
    );
  }

  static const int _maxLivePackets = 45;
  static const int _maxLogEntries = 300;

  Timer? _streamTimer;
  Timer? _healthTimer;
  bool _disposed = false;

  // ---------------- live feed ----------------
  final List<NetworkPacket> _packets = [];
  List<NetworkPacket> get packets => List.unmodifiable(_packets);

  // ---------------- critical issues log (persists across the session) ----------------
  final List<NetworkPacket> _criticalLog = [];
  List<NetworkPacket> get criticalLog => List.unmodifiable(_criticalLog);

  // ---------------- top-line metrics ----------------
  int _totalScanned = 0;
  int get totalScanned => _totalScanned;

  int _threatsBlocked = 0;
  int get threatsBlocked => _threatsBlocked;

  double _systemHealth = 99.8;
  double get systemHealth => _systemHealth;

  // ---------------- defense mode ----------------
  DefenseMode _mode = DefenseMode.autonomous;
  DefenseMode get mode => _mode;

  void setMode(bool autonomous) {
    _mode = autonomous ? DefenseMode.autonomous : DefenseMode.passive;
    final packet = selectedPacket;
    if (packet != null) {
      _selectedActionText = MockDataGenerator.actionTextFor(packet, _mode);
    }
    notifyListeners();
  }

  // ---------------- live-feed selection (sidebar) ----------------
  String? _selectedPacketId;
  String? get selectedPacketId => _selectedPacketId;

  NetworkPacket? get selectedPacket =>
      _selectedPacketId == null ? null : _findPacketById(_selectedPacketId!);

  String? _selectedActionText;
  String? get selectedActionText => _selectedActionText;

  /// Selects a critical packet for the Live Feed sidebar and kicks off
  /// (or reuses) its Gemini analysis.
  void selectPacket(NetworkPacket packet) {
    if (packet.risk != RiskStatus.critical) return;
    _selectedPacketId = packet.id;
    _selectedActionText = MockDataGenerator.actionTextFor(packet, _mode);
    notifyListeners();
    _ensureAnalysis(packet);
  }

  // ---------------- shared Gemini analysis cache ----------------
  final Map<String, AnalysisResult> _analysisCache = {};
  final Set<String> _loadingIds = {};

  bool isLoadingAnalysis(String packetId) => _loadingIds.contains(packetId);
  AnalysisResult? analysisFor(String packetId) => _analysisCache[packetId];

  /// Used by the Critical Issues page to lazily fetch + cache analysis
  /// when a historical entry is expanded. Safe to call repeatedly --
  /// it's a no-op once cached or already in flight.
  void ensureAnalysisFor(NetworkPacket packet) => _ensureAnalysis(packet);

  Future<void> _ensureAnalysis(NetworkPacket packet) async {
    if (_analysisCache.containsKey(packet.id) ||
        _loadingIds.contains(packet.id)) {
      return;
    }

    _loadingIds.add(packet.id);
    _safeNotify();

    String text;
    bool fellBack = false;
    try {
      text = await SocAnalystApi.analyzePacket(packet);
    } catch (_) {
      fellBack = true;
      text = MockDataGenerator.fallbackAnalysis(packet);
    }

    _loadingIds.remove(packet.id);
    _analysisCache[packet.id] =
        AnalysisResult(text: text, isFallback: fellBack);
    _safeNotify();
  }

  NetworkPacket? _findPacketById(String id) {
    for (final p in _packets) {
      if (p.id == id) return p;
    }
    for (final p in _criticalLog) {
      if (p.id == id) return p;
    }
    return null;
  }

  // ---------------- critical log management ----------------
  void clearCriticalLog() {
    _criticalLog.clear();
    notifyListeners();
  }

  // ---------------- packet generation ----------------
  void _seedInitialPackets() {
    for (int i = 0; i < 14; i++) {
      _packets.add(MockDataGenerator.generate());
      _totalScanned++;
    }
    _threatsBlocked =
        _packets.where((p) => p.risk == RiskStatus.critical).length;
  }

  void _pushNewPacket() {
    final packet = MockDataGenerator.generate();
    _packets.insert(0, packet);
    if (_packets.length > _maxLivePackets) {
      _packets.removeRange(_maxLivePackets, _packets.length);
    }
    _totalScanned++;

    if (packet.risk == RiskStatus.critical) {
      if (_mode == DefenseMode.autonomous) {
        _threatsBlocked++;
      }
      _criticalLog.insert(0, packet);
      if (_criticalLog.length > _maxLogEntries) {
        _criticalLog.removeRange(_maxLogEntries, _criticalLog.length);
      }
    }
    _safeNotify();
  }

  void _refreshHealth() {
    _systemHealth = 99.4 + Random().nextDouble() * 0.5;
    _safeNotify();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _streamTimer?.cancel();
    _healthTimer?.cancel();
    super.dispose();
  }
}