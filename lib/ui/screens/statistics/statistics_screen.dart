import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../../core/theme/app_theme.dart';

/// Tela de estatísticas com gráfico de linhas.
/// Header persistente (PlayerStatsHeader) é gerenciado pelo MainScreen.
class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título "Last 7 Days" centralizado
            const Center(
              child: Text(
                'Last 7 Days',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Container para o gráfico
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.border,
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: _LineChartPlaceholder(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder de gráfico de linhas com eixos X e Y minimalistas
class _LineChartPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LineChartPainter(),
      child: Container(),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.border
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final textStyle = TextStyle(
      color: AppTheme.textSecondary,
      fontSize: 10,
    );

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Desenha eixo Y (vertical, à esquerda)
    final yAxisX = 40.0;
    canvas.drawLine(
      Offset(yAxisX, 20),
      Offset(yAxisX, size.height - 30),
      paint,
    );

    // Desenha eixo X (horizontal, na parte inferior)
    final xAxisY = size.height - 30;
    canvas.drawLine(
      Offset(yAxisX, xAxisY),
      Offset(size.width - 20, xAxisY),
      paint,
    );

    // Labels do eixo Y (quantidade)
    final maxY = 100;
    final ySteps = 5;
    final yStepValue = maxY / ySteps;
    final yAxisHeight = size.height - 50;

    for (int i = 0; i <= ySteps; i++) {
      final value = (ySteps - i) * yStepValue;
      final y = 20 + (i * (yAxisHeight / ySteps));

      // Linha de grade horizontal
      if (i < ySteps) {
        final gridPaint = Paint()
          ..color = AppTheme.border.withOpacity(0.3)
          ..strokeWidth = 0.5;
        canvas.drawLine(
          Offset(yAxisX, y),
          Offset(size.width - 20, y),
          gridPaint,
        );
      }

      // Label do valor
      textPainter.text = TextSpan(
        text: value.toInt().toString(),
        style: textStyle,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(yAxisX - textPainter.width - 8, y - textPainter.height / 2),
      );
    }

    // Labels do eixo X (dias)
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final chartWidth = size.width - 60;
    final xStep = chartWidth / (days.length - 1);

    for (int i = 0; i < days.length; i++) {
      final x = yAxisX + (i * xStep);

      // Label do dia
      textPainter.text = TextSpan(
        text: days[i],
        style: textStyle,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, xAxisY + 8),
      );
    }

    // Desenha linha de dados (placeholder com valores aleatórios)
    final linePaint = Paint()
      ..color = AppTheme.primary
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final random = math.Random(42); // Seed fixa para valores consistentes
    final points = <Offset>[];

    for (int i = 0; i < days.length; i++) {
      final x = yAxisX + (i * xStep);
      final value = 20 + random.nextDouble() * 60; // Valor entre 20 e 80
      final y = 20 + ((maxY - value) / maxY) * yAxisHeight;
      points.add(Offset(x, y));
    }

    // Desenha a linha conectando os pontos
    if (points.length > 1) {
      final path = Path();
      path.moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, linePaint);

      // Desenha os pontos
      final pointPaint = Paint()
        ..color = AppTheme.primary
        ..style = PaintingStyle.fill;
      for (final point in points) {
        canvas.drawCircle(point, 4, pointPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
