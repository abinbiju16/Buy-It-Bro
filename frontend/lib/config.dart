class AppConfig {
  // Live Cloudflare Global Public URL:
  static const String cloudflareUrl = "https://lunch-purposes-rays-disclaimers.trycloudflare.com/api/v1";

  // Connects to your live backend over the global internet from any phone:
  static String get baseUrl => cloudflareUrl;
}
