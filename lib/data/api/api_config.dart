/// Build-time backend configuration, set with `--dart-define` (or `--dart-define-from-file=env/dev.json`).
///
/// ```sh
/// flutter run --dart-define=USE_MOCK_DATA=false --dart-define=API_BASE_URL=https://api.example.com/api/v1
/// ```
class ApiConfig {
  const ApiConfig({required this.baseUrl, required this.useMockData, this.timeout = const Duration(seconds: 20)});

  factory ApiConfig.fromEnvironment() => const ApiConfig(
    baseUrl: String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:3100/api/v1'),
    useMockData: bool.fromEnvironment('USE_MOCK_DATA', defaultValue: true),
  );

  /// Versioned REST root, without a trailing slash (e.g. `https://cms.example.com/api/v1`).
  final String baseUrl;

  /// True: read the bundled JSON in `assets/data/` (demo build). False: call [baseUrl].
  final bool useMockData;
  final Duration timeout;

  Uri uri(String path, [Map<String, String>? query]) {
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$p').replace(queryParameters: query);
  }
}
