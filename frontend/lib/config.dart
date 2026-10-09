import 'package:flutter/foundation.dart';

class AppConfig {
  // Your computer's Wi-Fi IP address:
  static const String serverHost = "192.168.29.153";

  static String get baseUrl {
    if (kIsWeb) {
      // In web browser: dynamically use the same hostname the user opened the site with!
      // If opened on phone at http://192.168.29.153:3000, this automatically uses 192.168.29.153:8000!
      final host = Uri.base.host.isNotEmpty ? Uri.base.host : serverHost;
      return "http://$host:8000/api/v1";
    }
    // On native Android/iOS mobile apps:
    return "http://$serverHost:8000/api/v1";
  }
}
