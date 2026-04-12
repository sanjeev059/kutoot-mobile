/// Environment configuration for Kutoot API
class Env {
  /// Laravel **mobile** routes (`/api/mobile/...`).
  static const String apiBaseUrl = String.fromEnvironment(
    'KUTOOT_API_URL',
    defaultValue: 'https://dev.kutoot.com/api/mobile',
  );

  /// Laravel **v1** routes — same base as web (`NEXT_PUBLIC_KUTOOT_API_URL`).
  /// Used for coupon bill pay + verify to match `kutoot-frontend` / `kutootApi.js`.
  static const String apiV1BaseUrl = String.fromEnvironment(
    'KUTOOT_API_V1_URL',
    defaultValue: 'https://dev.kutoot.com/api/v1',
  );

  static const String appName = 'Kutoot';
}
