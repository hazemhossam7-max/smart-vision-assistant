class LoggerService {
  const LoggerService();

  void info(String message) {
    // Kept as a single injectable place so demo logging can later move to Crashlytics/Sentry.
    // ignore: avoid_print
    print('[SmartVision] $message');
  }
}
