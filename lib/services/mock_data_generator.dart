import 'dart:math';

import '../models/network_packet.dart';

/// Generates fake (but realistic-looking) packets for the live feed, and
/// provides LOCAL FALLBACK text for when the Gemini API is unreachable.
/// The real explanation always comes from SocAnalystApi -- this is only
/// the safety net.
class MockDataGenerator {
  static final Random _rng = Random();
  static int _counter = 0;

  static const List<String> _attackTypes = [
    'DDoS Flood (SYN)',
    'Port Scanning',
    'SQL Injection',
    'Brute-Force Login',
    'Malware C2 Beacon',
    'ARP Spoofing',
  ];

  // "Weird" ports commonly associated with scanning/backdoor/C2 traffic.
  static const List<int> _suspiciousPorts = [4444, 31337, 1337, 6667, 23, 3389];
  // Ordinary ports for everyday safe traffic.
  static const List<int> _commonPorts = [443, 80, 53, 22, 8080, 123];

  static String _randomPublicIp() {
    return '${20 + _rng.nextInt(180)}.${_rng.nextInt(255)}.'
        '${_rng.nextInt(255)}.${1 + _rng.nextInt(254)}';
  }

  static String _randomInternalIp() {
    return '192.168.${1 + _rng.nextInt(4)}.${1 + _rng.nextInt(254)}';
  }

  static NetworkPacket generate() {
    _counter += 1;
    final bool isCritical = _rng.nextDouble() < 0.16;
    final String protocol = _rng.nextBool() ? 'TCP' : 'UDP';

    final int payload =
    isCritical ? 800 + _rng.nextInt(8200) : 64 + _rng.nextInt(1400);

    final int port = isCritical
        ? _suspiciousPorts[_rng.nextInt(_suspiciousPorts.length)]
        : _commonPorts[_rng.nextInt(_commonPorts.length)];

    return NetworkPacket(
      id: 'pkt_${DateTime.now().microsecondsSinceEpoch}_$_counter',
      timestamp: DateTime.now(),
      sourceIp: isCritical ? _randomPublicIp() : _randomInternalIp(),
      destIp: _randomInternalIp(),
      protocol: protocol,
      payloadSize: payload,
      destinationPort: port,
      riskScore: isCritical ? 95 : 5 + _rng.nextInt(10),
      risk: isCritical ? RiskStatus.critical : RiskStatus.safe,
      attackType:
      isCritical ? _attackTypes[_rng.nextInt(_attackTypes.length)] : null,
    );
  }

  /// LOCAL FALLBACK ONLY -- used when the Gemini API call fails.
  static String fallbackAnalysis(NetworkPacket packet) {
    final String ip = packet.sourceIp;
    final String type = packet.attackType ?? 'Anomalous Traffic';

    switch (type) {
      case 'DDoS Flood (SYN)':
        return 'DDoS attempt identified from IP $ip via a high-frequency '
            'TCP SYN flood targeting internal host ${packet.destIp}. '
            'Packet payload of ${packet.payloadSize} bytes exceeds the '
            'expected baseline for legitimate handshake traffic, and the '
            'request rate from this source matches known volumetric '
            'denial-of-service signatures.';
      case 'Port Scanning':
        return 'Port scanning activity detected from IP $ip. The source is '
            'probing sequential ports on ${packet.destIp} over multiple '
            'transport-layer connections, a pattern consistent with '
            'reconnaissance preceding a targeted intrusion attempt.';
      case 'SQL Injection':
        return 'A malicious payload consistent with SQL injection was found '
            'in traffic originating from $ip. The packet attempts to '
            'manipulate backend query logic on ${packet.destIp}, which '
            'could expose or corrupt sensitive database records.';
      case 'Brute-Force Login':
        return 'Brute-force authentication attempts detected from IP $ip '
            'against ${packet.destIp}. The model flagged an abnormally '
            'high rate of failed-credential patterns within a short '
            'time window, indicative of automated password guessing.';
      case 'Malware C2 Beacon':
        return 'Outbound beaconing behavior from internal host ${packet.destIp} '
            'to suspicious external IP $ip suggests active malware '
            'communicating with a command-and-control server. Payload '
            'entropy and timing intervals match known C2 heartbeat patterns.';
      case 'ARP Spoofing':
        return 'Irregular ARP-layer activity associated with IP $ip indicates '
            'a possible man-in-the-middle attempt via ARP spoofing, aiming '
            'to intercept traffic destined for ${packet.destIp}.';
      default:
        return 'Anomalous traffic pattern detected from IP $ip with '
            'characteristics that deviate from this network\'s learned '
            'baseline behavior.';
    }
  }

  /// What the *local* system did about it, based on the current defense
  /// mode. Independent of whatever remediation step Gemini suggests --
  /// this reflects this dashboard's own enforcement state.
  static String actionTextFor(NetworkPacket packet, DefenseMode mode) {
    final String ip = packet.sourceIp;
    return mode == DefenseMode.autonomous
        ? 'AI Autonomous Interdiction engaged: source IP $ip was '
        'automatically blacklisted and all active sessions were '
        'terminated at the firewall in under 200ms.'
        : 'Passive Monitoring mode active: the event was logged and '
        'escalated to the alert queue for analyst review. No '
        'automatic blocking action was taken.';
  }
}