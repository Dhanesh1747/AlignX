import 'package:flutter/foundation.dart';

class BackendConfig {
  static final String baseUrl =
      (defaultTargetPlatform == TargetPlatform.android && !kIsWeb)
          ? 'http://10.0.2.2:8081/api'
          : 'http://localhost:8081/api';
}
