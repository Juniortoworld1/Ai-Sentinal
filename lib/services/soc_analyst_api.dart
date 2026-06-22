import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/network_packet.dart';
import 'api_config.dart';

/// Talks to api_server.py's POST /analyze, which forwards packet metadata
/// to gemini_analyzer.py and returns a clean SOC-analyst explanation.
class SocAnalystApi {
  /// Throws on any failure (timeout, non-200, empty body) -- callers
  /// should catch and fall back to MockDataGenerator.fallbackAnalysis().
  static Future<String> analyzePacket(NetworkPacket packet) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/analyze');

    final payload = <String, dynamic>{
      'source_ip': packet.sourceIp,
      'destination_ip': packet.destIp,
      'protocol': packet.protocol,
      'destination_port': packet.destinationPort,
      'packet_length': packet.payloadSize,
      'risk_score': packet.riskScore,
      'threat_label': packet.attackType ?? 'Anomalous Traffic',
    };

    final response = await http
        .post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(
        'SOC analyst API returned ${response.statusCode}: ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final text = decoded['analysis'] as String?;
    if (text == null || text.trim().isEmpty) {
      throw Exception('SOC analyst API returned an empty analysis');
    }
    return text.trim();
  }
}