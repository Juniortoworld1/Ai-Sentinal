enum RiskStatus { safe, critical }

enum DefenseMode { passive, autonomous }

/// A single captured (mock) network packet, plus the metadata the rest of
/// the app needs: what risk it was scored at, what port it hit, and -- if
/// critical -- what kind of attack it was tagged as.
class NetworkPacket {
  final String id;
  final DateTime timestamp;
  final String sourceIp;
  final String destIp;
  final String protocol;
  final int payloadSize;
  final int destinationPort;
  final int riskScore;
  final RiskStatus risk;
  final String? attackType;

  NetworkPacket({
    required this.id,
    required this.timestamp,
    required this.sourceIp,
    required this.destIp,
    required this.protocol,
    required this.payloadSize,
    required this.destinationPort,
    required this.riskScore,
    required this.risk,
    this.attackType,
  });
}