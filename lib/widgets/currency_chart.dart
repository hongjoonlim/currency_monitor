import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'dart:ui' show TextDirection;
import '../models/currency_chart_data.dart';
import '../services/currency_service.dart';

// 깨박거림 방지를 위해 StatefulWidget 사용
class CurrencyChart extends StatefulWidget {
  const CurrencyChart({Key? key}) : super(key: key);

  @override
  State<CurrencyChart> createState() => _CurrencyChartState();
}

class _CurrencyChartState extends State<CurrencyChart> {
  late List<CurrencyChartData> _chartData;
  late ChartPeriod _period;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // 초기화는 didChangeDependencies에서 수행
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final currencyService = Provider.of<CurrencyService>(context, listen: false);
      _chartData = currencyService.currentChartData;
      _period = currencyService.selectedPeriod;
      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 이미 가져온 데이터 사용
    if (!_isInitialized || _chartData.isEmpty) {
      return const SizedBox(
        height: 250,
        child: Center(
          child: Text('차트 데이터가 없습니다.'),
        ),
      );
    }

    return Column(
      children: [
        // 기간 선택 탭
        _buildPeriodSelector(context),
        
        // 차트
        SizedBox(
          height: 250,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SimpleLineChart(
              data: _chartData,
              period: _period,
            ),
          ),
        ),
      ],
    );
  }

  // 기간 선택 탭 위젯
  Widget _buildPeriodSelector(BuildContext context) {
    final service = Provider.of<CurrencyService>(context, listen: false);
    
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: ChartPeriod.values.map((period) {
          final isSelected = period == _period;
          return InkWell(
            onTap: () {
              // 서비스에 변경 사항 전달 및 로컬 상태 업데이트
              service.setChartPeriod(period);
              setState(() {
                _period = period;
                _chartData = service.currentChartData;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                period.displayName,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// 직접 구현한 간단한 차트 위젯
class SimpleLineChart extends StatelessWidget {
  final List<CurrencyChartData> data;
  final ChartPeriod period;

  const SimpleLineChart({
    Key? key,
    required this.data,
    required this.period,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('데이터가 없습니다'));
    }

    // 최소/최대 값 계산
    final minRate = data.map((e) => e.rate).reduce((a, b) => a < b ? a : b);
    final maxRate = data.map((e) => e.rate).reduce((a, b) => a > b ? a : b);
    final rateRange = maxRate - minRate;
    
    // 아주 작은 범위일 경우 범위 확대
    final effectiveMinRate = rateRange < 10 ? minRate - (10 - rateRange) / 2 : minRate;
    final effectiveMaxRate = rateRange < 10 ? maxRate + (10 - rateRange) / 2 : maxRate;
    final effectiveRange = effectiveMaxRate - effectiveMinRate;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final chartHeight = height * 0.8; // 차트 높이 (하단에 레이블 공간 확보)
        final labelHeight = height * 0.2;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 차트 영역
            SizedBox(
              height: chartHeight,
              width: width,
              child: CustomPaint(
                painter: LineChartPainter(
                  data: data,
                  minY: effectiveMinRate,
                  maxY: effectiveMaxRate,
                  lineColor: Colors.blue,
                  gridColor: Colors.grey.shade300,
                ),
              ),
            ),
            
            // x축 레이블
            SizedBox(
              height: labelHeight,
              width: width,
              child: _buildXAxisLabels(width),
            ),
            
            // y축 레이블은 차트 영역 위에 그림
          ],
        );
      },
    );
  }

  // x축 레이블 생성
  Widget _buildXAxisLabels(double width) {
    final labelCount = _getLabelCount();
    final step = data.length ~/ labelCount;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(labelCount, (index) {
        final dataIndex = index * step;
        if (dataIndex >= data.length) return const SizedBox.shrink();
        
        final date = data[dataIndex].date;
        final label = _formatDate(date);
        
        return Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.black54),
          ),
        );
      }),
    );
  }
  
  // 레이블 개수 결정
  int _getLabelCount() {
    switch (period) {
      case ChartPeriod.day:
        return 6; // 4시간 간격
      case ChartPeriod.month:
        return 5; // 6일 간격
      case ChartPeriod.year:
        return 6; // 2개월 간격
    }
  }
  
  // 날짜 포맷팅
  String _formatDate(DateTime date) {
    switch (period) {
      case ChartPeriod.day:
        return DateFormat('HH:mm').format(date);
      case ChartPeriod.month:
        return DateFormat('MM/dd').format(date);
      case ChartPeriod.year:
        return DateFormat('yy/MM').format(date);
    }
  }
}

// 차트 그리기 위한 커스텀 페인터
class LineChartPainter extends CustomPainter {
  final List<CurrencyChartData> data;
  final double minY;
  final double maxY;
  final Color lineColor;
  final Color gridColor;
  final int horizontalLines;

  LineChartPainter({
    required this.data,
    required this.minY,
    required this.maxY,
    this.lineColor = Colors.blue,
    this.gridColor = Colors.grey,
    this.horizontalLines = 5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final yRange = maxY - minY;
    
    // 그리드 그리기
    _drawGrid(canvas, size);
    
    // y축 값 표시
    _drawYLabels(canvas, size);
    
    // 데이터 그리기
    if (data.length < 2) return;
    
    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
      
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withOpacity(0.3),
          lineColor.withOpacity(0.05),
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, height))
      ..style = PaintingStyle.fill;
    
    final path = Path();
    final fillPath = Path();
    
    // 첫 번째 포인트
    final firstX = 0.0;
    final firstY = height - ((data[0].rate - minY) / yRange * height);
    path.moveTo(firstX, firstY);
    fillPath.moveTo(firstX, height); // 채우기 경로는 하단부터 시작
    fillPath.lineTo(firstX, firstY);
    
    // 나머지 포인트
    for (int i = 0; i < data.length; i++) {
      final x = i / (data.length - 1) * width;
      final y = height - ((data[i].rate - minY) / yRange * height);
      path.lineTo(x, y);
      fillPath.lineTo(x, y);
    }
    
    // 채우기 경로 닫기
    fillPath.lineTo(width, height);
    fillPath.close();
    
    // 그리기
    canvas.drawPath(fillPath, fillPaint); // 먼저 채우기
    canvas.drawPath(path, linePaint); // 그 다음 선
  }
  
  // 그리드 그리기
  void _drawGrid(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    
    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    
    // 수평선 그리기
    for (int i = 0; i <= horizontalLines; i++) {
      final y = i / horizontalLines * height;
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }
    
    // 수직선 그리기 (선택적)
    for (int i = 0; i <= 4; i++) {
      final x = i / 4 * width;
      canvas.drawLine(Offset(x, 0), Offset(x, height), gridPaint);
    }
  }
  
  // y축 레이블 그리기 - 점으로 표시
  void _drawYLabels(Canvas canvas, Size size) {
    final height = size.height;
    final yRange = maxY - minY;
    
    // 점 스타일 정의
    final dotStyle = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;
    
    // 표시할 레이블 수 제한
    final labelsToShow = 6;
    
    for (int i = 0; i < labelsToShow; i++) {
      final y = i / (labelsToShow - 1) * height;
      
      // 중요한 값은 큰 점으로 표시
      if (i == 0 || i == labelsToShow - 1 || i == (labelsToShow - 1) / 2) {
        canvas.drawCircle(Offset(5, y), 3, dotStyle);
      } else {
        // 나머지는 작은 점으로 표시
        canvas.drawCircle(Offset(5, y), 2, dotStyle);
      }
    }
  }

  @override
  bool shouldRepaint(LineChartPainter oldDelegate) {
    return oldDelegate.data != data || 
           oldDelegate.minY != minY || 
           oldDelegate.maxY != maxY;
  }
}
