class CurrencyChartData {
  final DateTime date;
  final double rate;

  CurrencyChartData({
    required this.date,
    required this.rate,
  });

  factory CurrencyChartData.fromJson(Map<String, dynamic> json) {
    return CurrencyChartData(
      date: DateTime.parse(json['date']),
      rate: json['rate'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'rate': rate,
    };
  }
}

// 그래프 기간 타입
enum ChartPeriod {
  day,
  month,
  year,
}

// 그래프 기간 타입에 대한 확장 함수
extension ChartPeriodExtension on ChartPeriod {
  String get displayName {
    switch (this) {
      case ChartPeriod.day:
        return '일간';
      case ChartPeriod.month:
        return '월간';
      case ChartPeriod.year:
        return '년간';
    }
  }
}
