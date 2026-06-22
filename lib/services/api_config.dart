/// Where api_server.py (the FastAPI wrapper around the Gemini SOC analyst)
/// is running. Override at build/run time with:
///   flutter run --dart-define=SOC_API_BASE_URL=http://192.168.1.20:8000
///
/// Notes:
/// - Web / desktop / iOS simulator: 'http://localhost:8000' works as-is.
/// - Android emulator: use 'http://10.0.2.2:8000' instead of localhost.
/// - Physical device: use your machine's LAN IP, e.g. 'http://192.168.x.x:8000'.
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'SOC_API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );
}