class ActionConfig {
  const ActionConfig({
    required this.configured,
    required this.method,
    required this.executeUrl,
  });

  factory ActionConfig.fromJson(Map<String, dynamic> json) => ActionConfig(
    configured: json['configured'] as bool? ?? false,
    method: json['method'] as String? ?? 'POST',
    executeUrl: json['execute_url'] as String? ?? '',
  );

  final bool configured;
  final String method;
  final String executeUrl;
}

class AppSettings {
  const AppSettings({required this.hape, required this.mbylle});
  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    hape: ActionConfig.fromJson(json['hape'] as Map<String, dynamic>),
    mbylle: ActionConfig.fromJson(json['mbylle'] as Map<String, dynamic>),
  );
  final ActionConfig hape;
  final ActionConfig mbylle;
}

class AdminActionConfig {
  const AdminActionConfig({
    required this.url,
    required this.method,
    this.headers = const {},
    this.body = const {},
  });

  factory AdminActionConfig.fromJson(Map<String, dynamic>? json) =>
      AdminActionConfig(
        url: json?['url'] as String? ?? '',
        method: json?['method'] as String? ?? 'POST',
        headers: _mapOrEmpty(json?['headers']),
        body: _mapOrEmpty(json?['body']),
      );

  final String url;
  final String method;
  final Map<String, dynamic> headers;
  final Map<String, dynamic> body;

  Map<String, dynamic> toJson() => {
    'url': url,
    'method': method,
    'headers': headers,
    'body': body,
  };
}

Map<String, dynamic> _mapOrEmpty(dynamic value) {
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  // PHP serializes an empty associative array as [] in some responses.
  return <String, dynamic>{};
}

class AdminSettings {
  const AdminSettings({required this.hape, required this.mbylle});

  factory AdminSettings.fromJson(Map<String, dynamic> json) => AdminSettings(
    hape: AdminActionConfig.fromJson(json['hape'] as Map<String, dynamic>?),
    mbylle: AdminActionConfig.fromJson(json['mbylle'] as Map<String, dynamic>?),
  );

  final AdminActionConfig hape;
  final AdminActionConfig mbylle;
}
