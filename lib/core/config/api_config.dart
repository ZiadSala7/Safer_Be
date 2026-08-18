abstract final class ApiConfig {
  static const baseUrl = String.fromEnvironment(
    'SAFER_BE_API_URL',
    defaultValue: 'https://backend.saferbe.com/api/v1',
  );

  static const timeout = Duration(seconds: 30);
}
