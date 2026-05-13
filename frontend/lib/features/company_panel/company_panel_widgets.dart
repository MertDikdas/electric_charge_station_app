import 'dart:math' as math;

import 'package:flutter/material.dart';

class CompanyScaffold extends StatelessWidget {
  const CompanyScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(title: Text(title), actions: actions),
      body: SafeArea(child: child),
    );
  }
}

class DashboardTile extends StatelessWidget {
  const DashboardTile({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                foregroundColor: const Color(0xFF0B1F4D),
                child: Icon(icon),
              ),
              const Spacer(),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(title, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class StatisticCard extends StatelessWidget {
  const StatisticCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF0B1F4D)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: Theme.of(context).textTheme.titleLarge),
                  Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'AVAILABLE' || 'CONFIRMED' || 'COMPLETED' => Colors.green,
      'OCCUPIED' || 'PENDING' => Colors.orange,
      'MAINTENANCE' => Colors.blueGrey,
      'CANCELLED' || 'CLOSED' || 'OUT_OF_SERVICE' => Colors.red,
      _ => Colors.grey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class PanelLoading extends StatelessWidget {
  const PanelLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (_, index) => Container(
        height: index == 0 ? 120 : 86,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      separatorBuilder: (_, index) => const SizedBox(height: 12),
      itemCount: 6,
    );
  }
}

class BarChartCard extends StatelessWidget {
  const BarChartCard({super.key, required this.title, required this.values});

  final String title;
  final Map<String, double> values;

  @override
  Widget build(BuildContext context) {
    return _ChartFrame(
      title: title,
      child: CustomPaint(
        painter: _BarChartPainter(values),
        child: const SizedBox(height: 180),
      ),
    );
  }
}

class LineChartCard extends StatelessWidget {
  const LineChartCard({super.key, required this.title, required this.values});

  final String title;
  final Map<String, double> values;

  @override
  Widget build(BuildContext context) {
    return _ChartFrame(
      title: title,
      child: CustomPaint(
        painter: _LineChartPainter(values),
        child: const SizedBox(height: 180),
      ),
    );
  }
}

class PieChartCard extends StatelessWidget {
  const PieChartCard({super.key, required this.title, required this.values});

  final String title;
  final Map<String, double> values;

  @override
  Widget build(BuildContext context) {
    return _ChartFrame(
      title: title,
      child: Row(
        children: [
          Expanded(
            child: CustomPaint(
              painter: _PieChartPainter(values),
              child: const SizedBox(height: 180),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: values.entries
                  .map((entry) => Text('${entry.key}: ${entry.value.toInt()}'))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartFrame extends StatelessWidget {
  const _ChartFrame({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter(this.values);

  final Map<String, double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF0B1F4D);
    final maxValue = values.values.fold<double>(1, math.max);
    final barWidth = values.isEmpty ? 0.0 : size.width / (values.length * 2);
    var x = barWidth / 2;
    for (final value in values.values) {
      final height = (value / maxValue) * (size.height - 24);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height - height, barWidth, height),
          const Radius.circular(6),
        ),
        paint,
      );
      x += barWidth * 2;
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) =>
      oldDelegate.values != values;
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter(this.values);

  final Map<String, double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final axis = Paint()
      ..color = Colors.black12
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height - 16),
      Offset(size.width, size.height - 16),
      axis,
    );
    if (values.isEmpty) return;
    final maxValue = values.values.fold<double>(1, math.max);
    final step = values.length == 1
        ? size.width
        : size.width / (values.length - 1);
    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final value = values.values.elementAt(i);
      points.add(
        Offset(
          i * step,
          size.height - 16 - (value / maxValue) * (size.height - 32),
        ),
      );
    }
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF0B1F4D)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );
    for (final point in points) {
      canvas.drawCircle(point, 4, Paint()..color = const Color(0xFF25B7D3));
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.values != values;
}

class _PieChartPainter extends CustomPainter {
  _PieChartPainter(this.values);

  final Map<String, double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.values.fold<double>(0, (sum, value) => sum + value);
    if (total <= 0) return;
    final colors = [Colors.green, Colors.orange, Colors.red, Colors.blueGrey];
    final rect = Offset.zero & Size.square(math.min(size.width, size.height));
    var start = -math.pi / 2;
    var index = 0;
    for (final value in values.values) {
      final sweep = (value / total) * math.pi * 2;
      canvas.drawArc(
        rect.deflate(12),
        start,
        sweep,
        true,
        Paint()..color = colors[index % colors.length],
      );
      start += sweep;
      index++;
    }
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) =>
      oldDelegate.values != values;
}
