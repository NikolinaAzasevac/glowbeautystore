import 'dart:convert';

import 'package:http/http.dart' as http;

class CurrencyRates {
  const CurrencyRates({
    required this.baseCode,
    required this.lastUpdated,
    required this.rates,
  });

  final String baseCode;
  final DateTime lastUpdated;
  final Map<String, double> rates;
}

class CurrencyApiService {
  CurrencyApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<CurrencyRates> fetchEuroRates() async {
    final uri = Uri.parse('https://open.er-api.com/v6/latest/EUR');
    final response = await _client.get(uri).timeout(
          const Duration(seconds: 8),
          onTimeout: () => throw Exception('Currency API request timed out.'),
        );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Currency API request failed with status ${response.statusCode}.',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (decoded['result'] != 'success') {
      throw Exception('Currency API returned an invalid response.');
    }

    final rawRates = decoded['rates'] as Map<String, dynamic>? ?? {};
    final rates = <String, double>{};
    for (final code in const ['RSD', 'USD', 'GBP', 'CHF']) {
      final rawValue = rawRates[code];
      if (rawValue is num) {
        rates[code] = rawValue.toDouble();
      }
    }

    final updated = DateTime.fromMillisecondsSinceEpoch(
      ((decoded['time_last_update_unix'] as num?)?.toInt() ?? 0) * 1000,
    ).toLocal();

    return CurrencyRates(
      baseCode: (decoded['base_code'] ?? 'EUR').toString(),
      lastUpdated: updated,
      rates: rates,
    );
  }
}
