/// Environment configuration for Kutoot API
class Env {
  static const String apiBaseUrl = String.fromEnvironment(
    'KUTOOT_API_URL',
    defaultValue: 'https://dev.kutoot.com/api/v1',
  );

  static const String appName = 'Kutoot';
}
