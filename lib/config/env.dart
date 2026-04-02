/// Environment configuration for Kutoot API
class Env {
  static const String apiBaseUrl = String.fromEnvironment(
    'KUTOOT_API_URL',
    defaultValue: 'http://kutoot.test/api/mobile',
  );

  static const String appName = 'Kutoot';
}
