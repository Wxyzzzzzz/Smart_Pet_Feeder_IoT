import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsScreen extends StatelessWidget {
  // === MOCK DATA ===
  // Food level over 7 days (%)
  final List<double> foodLevels = [90, 85, 70, 60, 50, 35, 20];
  
  // Daily eating duration (minutes) - Mon to Sun
  final List<double> eatingMinutes = [45, 50, 48, 15, 52, 47, 50];
  final List<String> weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  
  // Meal frequency per day
  final int mealsToday = 8;
  final double avgMealDuration = 6.2; // minutes
  
  // Temperature and Humidity over time
  final List<double> humidity = [45, 48, 52, 55, 58, 54, 50, 48];
  final List<double> temperature = [24, 25, 26, 28, 27, 26, 25, 24];
  
  // Eating habits heatmap data (7 days x 24 hours)
  // Higher value = more eating activity
  final Map<int, Map<int, int>> eatingHeatmap = {
    0: {6: 3, 7: 2, 12: 2, 18: 3, 19: 1}, // Monday
    1: {6: 3, 13: 2, 18: 3, 19: 2},
    2: {7: 3, 12: 2, 18: 3, 20: 1},
    3: {6: 1, 18: 1}, // Thursday - sick day
    4: {6: 3, 7: 1, 12: 3, 18: 3, 19: 1},
    5: {7: 3, 13: 2, 18: 3, 19: 2},
    6: {6: 3, 12: 2, 18: 3, 19: 1}, // Sunday
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Analytics & Insights 📊")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === 1. FOOD CONSUMPTION ANALYTICS ===
            _buildSectionHeader("🍖 Food Consumption Analytics"),
            
            // Refill Prediction Card
            _buildRefillPrediction(),
            SizedBox(height: 15),
            
            // Consumption Trend Line (7 days)
            _buildConsumptionTrend(),
            SizedBox(height: 30),
            
            // === 2. PET HEALTH & BEHAVIOR ===
            _buildSectionHeader("🐾 Pet Health & Behavior"),
            
            // Daily Appetite Monitor
            _buildDailyAppetite(),
            SizedBox(height: 15),
            
            // Meal Frequency Counter
            _buildMealFrequency(),
            SizedBox(height: 15),
            
            // Eating Habits Heatmap
            _buildEatingHeatmap(),
            SizedBox(height: 30),
            
            // === 3. FOOD STORAGE HEALTH ===
            _buildSectionHeader("🌡️ Food Storage Health"),
            
            // Freshness Index (Humidity with threshold)
            _buildFreshnessIndex(),
            SizedBox(height: 15),
            
            // Temperature Stability
            _buildTemperatureStability(),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepOrange),
      ),
    );
  }

  // === REFILL PREDICTION ===
  Widget _buildRefillPrediction() {
    double currentLevel = foodLevels.last;
    double avgDailyDrop = (foodLevels.first - foodLevels.last) / (foodLevels.length - 1);
    int daysUntilEmpty = (currentLevel / avgDailyDrop).ceil();
    
    return Card(
      color: Colors.orange[50],
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, size: 48, color: Colors.orange),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Refill Prediction', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  Text(
                    'Estimated days until empty:',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  Text(
                    '$daysUntilEmpty Days',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.orange[800]),
                  ),
                  Text(
                    'Avg. daily consumption: ${avgDailyDrop.toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === CONSUMPTION TREND LINE ===
  Widget _buildConsumptionTrend() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Consumption Trend (Last 7 Days)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Food Level Burn Rate', style: TextStyle(color: Colors.grey, fontSize: 12)),
            SizedBox(height: 15),
            Container(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < 7) {
                            return Text('Day ${value.toInt() + 1}', style: TextStyle(fontSize: 10));
                          }
                          return Text('');
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey[300]!)),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(foodLevels.length, (i) => FlSpot(i.toDouble(), foodLevels[i])),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.2)),
                    ),
                  ],
                  minY: 0,
                  maxY: 100,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === DAILY APPETITE MONITOR ===
  Widget _buildDailyAppetite() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Daily Appetite Monitor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Minutes spent eating per day', style: TextStyle(color: Colors.grey, fontSize: 12)),
            SizedBox(height: 15),
            Container(
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 60,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < weekDays.length) {
                            return Padding(
                              padding: EdgeInsets.only(top: 5),
                              child: Text(weekDays[value.toInt()], style: TextStyle(fontSize: 11)),
                            );
                          }
                          return Text('');
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(
                    eatingMinutes.length,
                    (i) => BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: eatingMinutes[i],
                          color: eatingMinutes[i] < 30 ? Colors.red : Colors.green,
                          width: 20,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegend(Colors.green, 'Healthy'),
                SizedBox(width: 15),
                _buildLegend(Colors.red, 'Low (Possible Illness)'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // === MEAL FREQUENCY COUNTER ===
  Widget _buildMealFrequency() {
    String eatingStyle = mealsToday > 6 ? 'Grazer (Multiple small meals)' : 'Gorger (Few large meals)';
    
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.restaurant_menu, size: 48, color: Colors.blue),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Meal Frequency Today', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 8),
                  Text(
                    '$mealsToday Meals',
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.blue[800]),
                  ),
                  Text('Avg. duration: ${avgMealDuration.toStringAsFixed(1)} min/meal', style: TextStyle(color: Colors.grey[700])),
                  SizedBox(height: 5),
                  Text(eatingStyle, style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.blue[900])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === EATING HABITS HEATMAP ===
  Widget _buildEatingHeatmap() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Eating Habits Heatmap', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('When does your pet prefer to eat?', style: TextStyle(color: Colors.grey, fontSize: 12)),
            SizedBox(height: 15),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hour labels
                  Row(
                    children: [
                      SizedBox(width: 40),
                      ...List.generate(24, (hour) => Container(
                        width: 20,
                        alignment: Alignment.center,
                        child: Text(
                          hour % 3 == 0 ? '$hour' : '',
                          style: TextStyle(fontSize: 9, color: Colors.grey),
                        ),
                      )),
                    ],
                  ),
                  // Heatmap grid
                  ...List.generate(7, (day) {
                    return Row(
                      children: [
                        Container(
                          width: 40,
                          child: Text(weekDays[day], style: TextStyle(fontSize: 11)),
                        ),
                        ...List.generate(24, (hour) {
                          int intensity = eatingHeatmap[day]?[hour] ?? 0;
                          return Container(
                            width: 20,
                            height: 20,
                            margin: EdgeInsets.all(1),
                            decoration: BoxDecoration(
                              color: _getHeatmapColor(intensity),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        }),
                      ],
                    );
                  }),
                  SizedBox(height: 10),
                  // Legend
                  Row(
                    children: [
                      SizedBox(width: 40),
                      Text('Less', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      SizedBox(width: 5),
                      ...List.generate(4, (i) => Container(
                        width: 15,
                        height: 15,
                        margin: EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: _getHeatmapColor(i),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      )),
                      SizedBox(width: 5),
                      Text('More', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === FRESHNESS INDEX ===
  Widget _buildFreshnessIndex() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Freshness Index', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Humidity vs. Mold Risk Threshold (60%)', style: TextStyle(color: Colors.grey, fontSize: 12)),
            SizedBox(height: 15),
            Container(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) => Text('${value.toInt()}h', style: TextStyle(fontSize: 10)),
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey[300]!)),
                  lineBarsData: [
                    // Humidity line
                    LineChartBarData(
                      spots: List.generate(humidity.length, (i) => FlSpot(i.toDouble(), humidity[i])),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                    ),
                    // Mold risk threshold line
                    LineChartBarData(
                      spots: [FlSpot(0, 60), FlSpot(humidity.length - 1, 60)],
                      isCurved: false,
                      color: Colors.red,
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                      dashArray: [5, 5],
                    ),
                  ],
                  minY: 30,
                  maxY: 70,
                ),
              ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegend(Colors.blue, 'Humidity'),
                SizedBox(width: 15),
                _buildLegend(Colors.red, 'Mold Risk (60%)'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // === TEMPERATURE STABILITY ===
  Widget _buildTemperatureStability() {
    double avgTemp = temperature.reduce((a, b) => a + b) / temperature.length;
    bool isStable = temperature.every((t) => (t - avgTemp).abs() < 3);
    
    return Card(
      color: isStable ? Colors.green[50] : Colors.orange[50],
      child: Padding(
        padding: EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.thermostat, color: isStable ? Colors.green : Colors.orange),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Temperature Stability', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(
                        isStable ? 'Stable - Food quality protected' : 'Warning - Temperature fluctuations detected',
                        style: TextStyle(color: Colors.grey[700], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Container(
              height: 60,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(temperature.length, (i) => FlSpot(i.toDouble(), temperature[i])),
                      isCurved: true,
                      color: isStable ? Colors.green : Colors.orange,
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: (isStable ? Colors.green : Colors.orange).withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 5),
            Text('Avg: ${avgTemp.toStringAsFixed(1)}°C | Range: ${temperature.reduce((a, b) => a < b ? a : b).toStringAsFixed(1)}-${temperature.reduce((a, b) => a > b ? a : b).toStringAsFixed(1)}°C',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  // === HELPER WIDGETS ===
  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(width: 16, height: 16, color: color),
        SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 12)),
      ],
    );
  }

  Color _getHeatmapColor(int intensity) {
    switch (intensity) {
      case 0: return Colors.grey[200]!;
      case 1: return Colors.orange[200]!;
      case 2: return Colors.orange[400]!;
      case 3: return Colors.orange[700]!;
      default: return Colors.grey[200]!;
    }
  }
}
