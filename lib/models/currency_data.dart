class CurrencyData {
  final String fromCurrency;
  final String toCurrency;
  final double rate;
  final DateTime lastUpdated;

  CurrencyData({
    required this.fromCurrency,
    required this.toCurrency,
    required this.rate,
    required this.lastUpdated,
  });

  // JSON 직렬화/역직렬화를 위한 메서드
  factory CurrencyData.fromJson(Map<String, dynamic> json) {
    return CurrencyData(
      fromCurrency: json['fromCurrency'],
      toCurrency: json['toCurrency'],
      rate: json['rate'].toDouble(),
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fromCurrency': fromCurrency,
      'toCurrency': toCurrency,
      'rate': rate,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}
