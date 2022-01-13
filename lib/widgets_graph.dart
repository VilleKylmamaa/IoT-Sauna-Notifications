import 'dart:ui';

import 'package:sauna_temperature/sensor_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:fl_chart/fl_chart.dart';

// ignore: must_be_immutable
class TemperatureLineChart extends StatefulWidget {
  List<double> recordedTemperatures = [];
  TemperatureLineChart({Key? key, required this.recordedTemperatures})
      : super(key: key);

  @override
  _TemperatureLineChartState createState() => _TemperatureLineChartState();
}

class _TemperatureLineChartState extends State<TemperatureLineChart> {
  List<Color> gradientColors = [
    const Color(0xff23b6e6),
    const Color(0xff02d39a),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        AspectRatio(
          aspectRatio: 1.70,
          child: Container(
            decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(
                  Radius.circular(18),
                ),
                color: Color(0xff232d37)),
            child: Padding(
              padding: const EdgeInsets.only(
                  right: 18.0, left: 12.0, top: 10, bottom: 12),
              child: LineChart(mainData()),
            ),
          ),
        ),
      ],
    );
  }

  LineChartData mainData() {
    final List<FlSpot> traceTemperature = [];
    double xValue = 0;
    double xMax = 600;
    double xMin = 0;

    for (var temperature in widget.recordedTemperatures) {
      traceTemperature.add(FlSpot(xValue, temperature));
      if (xValue < xMax) {
        xValue++;
      }
    }

    // When the graph is full, the first value will be removed
    // and the x values are shifted by -1
    while (traceTemperature.length - 1 > xMax) {
      traceTemperature.asMap().forEach((index, temperature) {
        traceTemperature[index] = FlSpot(index.toDouble() - 1, temperature.y);
      });
      traceTemperature.removeAt(0);
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: const Color(0xff37434d),
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: const Color(0xff37434d),
            strokeWidth: 1,
          );
        },
      ),
      /* axisTitleData: FlAxisTitleData(
          bottomTitle: AxisTitle(
        showTitle: true,
        margin: 5,
        titleText: 'Time',
        textStyle: TextStyle(
            fontSize: 10,
            color: Colors.purple[200]!,
            fontWeight: FontWeight.bold),
      )), */
      titlesData: FlTitlesData(
        show: true,
        rightTitles: SideTitles(showTitles: false),
        topTitles: SideTitles(showTitles: false),
        bottomTitles: SideTitles(
          showTitles: true,
          interval: 1,
          getTextStyles: (context, value) => TextStyle(
            color: Colors.orange[200]!,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
          getTitles: (value) {
            switch (value.toInt()) {
              case 0:
                return '0min';
              case 100:
                return '5min';
              case 200:
                return '10min';
              case 300:
                return '15min';
              case 400:
                return '20min';
              case 500:
                return '25min';
              case 600:
                return '30min';
              case 700:
                return '35min';
              case 800:
                return '40min';
              case 900:
                return '45min';
              case 1000:
                return '50min';
            }
            return '';
          },
          reservedSize: 15,
          margin: 5,
        ),
        leftTitles: SideTitles(
          showTitles: true,
          interval: 1,
          getTextStyles: (context, value) => TextStyle(
            color: Colors.pink[200]!,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
          getTitles: (value) {
            switch (value.toInt()) {
              case 20:
                return '20°C';
              case 40:
                return '40°C';
              case 60:
                return '60°C';
              case 80:
                return '80°C';
              case 100:
                return '100°C';
              case 120:
                return '120°C';
            }
            return '';
          },
          reservedSize: 31,
          margin: 5,
        ),
      ),
      borderData: FlBorderData(
          show: true,
          border: Border.all(color: const Color(0xff37434d), width: 1)),
      minX: xMin,
      maxX: xMax,
      minY: 20,
      maxY: 120,
      extraLinesData: ExtraLinesData(horizontalLines: [
        HorizontalLine(
          y: notificationTemperature,
          color: Colors.purpleAccent[100]!.withOpacity(0.65),
          strokeWidth: 1.5,
          dashArray: [20, 1],
        ),
      ]),
      lineBarsData: [
        LineChartBarData(
          spots: traceTemperature,
          isCurved: true,
          colors: gradientColors,
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: false,
          ),
          belowBarData: BarAreaData(
            show: true,
            colors:
                gradientColors.map((color) => color.withOpacity(0.3)).toList(),
          ),
        ),
      ],
    );
  }
}
