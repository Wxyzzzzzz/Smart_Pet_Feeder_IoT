import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'services/firestore_service.dart';
import 'services/pet_profile_service.dart';
import 'models/feeding_log.dart';
import 'models/sensor_data.dart';

class AnalyticsScreen extends StatefulWidget {
  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final PetProfileService _petProfileService = PetProfileService();

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

            // Food Level Trend (7 days from Firebase)
            StreamBuilder<SensorData?>(
              stream: _firestoreService.getLatestSensorData(),
              builder: (context, currentSnapshot) {
                return StreamBuilder<List<SensorData>>(
                  stream: _firestoreService.getSensorDataLastNDays(7),
                  builder: (context, historySnapshot) {
                    if (currentSnapshot.connectionState ==
                            ConnectionState.waiting ||
                        historySnapshot.connectionState ==
                            ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (!historySnapshot.hasData ||
                        historySnapshot.data!.isEmpty) {
                      return _buildNoDataCard('No sensor data available');
                    }
                    return Column(
                      children: [
                        _buildRefillPrediction(
                          currentSnapshot.data?.foodLevel ?? 0,
                          historySnapshot.data!,
                        ),
                        SizedBox(height: 15),
                        _buildConsumptionTrend(historySnapshot.data!),
                      ],
                    );
                  },
                );
              },
            ),
            SizedBox(height: 30),

            // === 2. PET HEALTH & BEHAVIOR ===
            _buildSectionHeader("🐾 Pet Health & Behavior"),

            // Feeding statistics from Firebase
            StreamBuilder<List<FeedingLog>>(
              stream: _firestoreService.getFeedingLogsLastNDays(7),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildNoDataCard('No feeding data available');
                }
                return Column(
                  children: [
                    _buildDailyAppetite(snapshot.data!),
                    SizedBox(height: 15),
                    _buildMealFrequency(snapshot.data!),
                  ],
                );
              },
            ),
            SizedBox(height: 30),

            // === 3. FOOD STORAGE HEALTH ===
            _buildSectionHeader("🌡️ Food Storage Health"),

            // Environment monitoring from Firebase
            StreamBuilder<List<SensorData>>(
              stream: _firestoreService.getSensorDataLastNDays(7),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildNoDataCard('No environmental data available');
                }
                return Column(
                  children: [
                    _buildFreshnessIndex(snapshot.data!),
                    SizedBox(height: 15),
                    _buildTemperatureStability(snapshot.data!),
                  ],
                );
              },
            ),
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
        style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.deepOrange),
      ),
    );
  }

  Widget _buildNoDataCard(String message) {
    return Card(
      color: Colors.grey[100],
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 40, color: Colors.grey),
            SizedBox(width: 15),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === REFILL PREDICTION ===
  Widget _buildRefillPrediction(
      int currentFoodLevel, List<SensorData> sensorData) {
    // Calculate food percentage
    double foodPercent = currentFoodLevel / 100.0;

    if (foodPercent <= 0) {
      return Card(
        color: Colors.red[50],
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Refill Prediction',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 5),
                    Text('Status:', style: TextStyle(color: Colors.grey[700])),
                    Text('Container Empty!',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[800])),
                    Text('Refill immediately',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Rough estimate: 3.5 days for full container (same logic as dashboard)
    final daysRemaining = (foodPercent * 3.5).ceil();

    // Determine color and icon based on days remaining
    Color cardColor;
    Color iconColor;
    IconData icon;

    if (daysRemaining <= 1) {
      cardColor = Colors.red[50]!;
      iconColor = Colors.red;
      icon = Icons.warning_amber_rounded;
    } else if (daysRemaining <= 2) {
      cardColor = Colors.orange[50]!;
      iconColor = Colors.orange;
      icon = Icons.warning_amber_rounded;
    } else {
      cardColor = Colors.green[50]!;
      iconColor = Colors.green;
      icon = Icons.check_circle_outline;
    }

    return Card(
      color: cardColor,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, size: 48, color: iconColor),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Refill Prediction',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  Text('Current Level: ${currentFoodLevel}%',
                      style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                  SizedBox(height: 3),
                  Text('Estimated days until empty:',
                      style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                  Text('$daysRemaining Days',
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: iconColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === CONSUMPTION TREND LINE ===
  Widget _buildConsumptionTrend(List<SensorData> sensorData) {
    // Group by day and get the last reading of each day
    Map<String, SensorData> dailyData = {};
    for (var sensor in sensorData) {
      String day = '${sensor.timestamp.month}/${sensor.timestamp.day}';
      // Keep the latest reading for each day
      if (!dailyData.containsKey(day) ||
          sensor.timestamp.isAfter(dailyData[day]!.timestamp)) {
        dailyData[day] = sensor;
      }
    }

    // Sort by date and extract data
    var sortedEntries = dailyData.entries.toList()
      ..sort((a, b) {
        // Sort by actual date for proper chronological order
        return a.value.timestamp.compareTo(b.value.timestamp);
      });

    List<double> foodLevels =
        sortedEntries.map((e) => e.value.foodLevel.toDouble()).toList();
    List<String> dayLabels = sortedEntries.map((e) => e.key).toList();

    if (foodLevels.isEmpty) return _buildNoDataCard('No trend data available');
    return Card(
      child: Padding(
        padding: EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Consumption Trend (Last 7 Days)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Food Level Burn Rate',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            SizedBox(height: 15),
            Container(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles:
                          SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index >= 0 && index < dayLabels.length) {
                            return Text(dayLabels[index],
                                style: TextStyle(fontSize: 10));
                          }
                          return Text('');
                        },
                      ),
                    ),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(
                      show: true, border: Border.all(color: Colors.grey[300]!)),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(foodLevels.length,
                          (i) => FlSpot(i.toDouble(), foodLevels[i])),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                          show: true, color: Colors.blue.withOpacity(0.2)),
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
  Widget _buildDailyAppetite(List<FeedingLog> feedingLogs) {
    // Group feeding logs by day
    Map<int, List<FeedingLog>> logsByDay = {};
    DateTime now = DateTime.now();

    for (int i = 0; i < 7; i++) {
      DateTime day = now.subtract(Duration(days: 6 - i));
      int dayKey = day.weekday - 1; // 0=Mon, 6=Sun
      logsByDay[dayKey] = [];
    }

    for (var log in feedingLogs) {
      int dayKey = log.timestamp.weekday - 1;
      if (logsByDay.containsKey(dayKey)) {
        logsByDay[dayKey]!.add(log);
      }
    }

    // Calculate portions per day as proxy for eating time
    List<double> dailyPortions = [];
    List<String> weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    for (int i = 0; i < 7; i++) {
      double totalPortion = logsByDay[i]
              ?.fold<double>(0.0, (sum, log) => sum + log.portionSize) ??
          0.0;
      dailyPortions.add(totalPortion);
    }

    double maxPortion = dailyPortions.reduce((a, b) => a > b ? a : b);
    if (maxPortion == 0) maxPortion = 100; // Avoid division by zero

    return Card(
      child: Padding(
        padding: EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Daily Food Consumption',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Grams consumed per day',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            SizedBox(height: 15),
            Container(
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxPortion * 1.2,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                        sideTitles:
                            SideTitles(showTitles: true, reservedSize: 40)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < weekDays.length) {
                            return Padding(
                              padding: EdgeInsets.only(top: 5),
                              child: Text(weekDays[value.toInt()],
                                  style: TextStyle(fontSize: 11)),
                            );
                          }
                          return Text('');
                        },
                      ),
                    ),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(
                    dailyPortions.length,
                    (i) => BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: dailyPortions[i],
                          color: dailyPortions[i] <
                                  (_petProfileService.dailyPortion * 0.5)
                              ? Colors.red
                              : Colors.green,
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
                _buildLegend(Colors.red, 'Low Appetite(Check health)'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // === MEAL FREQUENCY COUNTER ===
  Widget _buildMealFrequency(List<FeedingLog> feedingLogs) {
    // Get today's logs
    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);

    List<FeedingLog> todaysLogs =
        feedingLogs.where((log) => log.timestamp.isAfter(startOfDay)).toList();

    int mealsToday = todaysLogs.length;
    double totalPortions =
        todaysLogs.fold(0.0, (sum, log) => sum + log.portionSize);

    // String eatingStyle = mealsToday > 6
    //     ? 'Grazer (Multiple small meals)'
    //     : mealsToday > 0 ? 'Gorger (Few large meals)' : 'No meals yet today';

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
                  Text('Feeding Activity Today',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 8),
                  Text(
                    '$mealsToday Feeds',
                    style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800]),
                  ),
                  Text('Total: ${totalPortions.toStringAsFixed(0)}g',
                      style: TextStyle(color: Colors.grey[700])),
                  // SizedBox(height: 5),
                  // Text(eatingStyle,
                  //     style: TextStyle(
                  //         fontSize: 12,
                  //         fontStyle: FontStyle.italic,
                  //         color: Colors.blue[900])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === EATING HABITS HEATMAP ===
  // Widget _buildEatingHeatmap() {
  //   return Card(
  //     child: Padding(
  //       padding: EdgeInsets.all(15),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text('Eating Habits Heatmap', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
  //           Text('When does your pet prefer to eat?', style: TextStyle(color: Colors.grey, fontSize: 12)),
  //           SizedBox(height: 15),
  //           SingleChildScrollView(
  //             scrollDirection: Axis.horizontal,
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 // Hour labels
  //                 Row(
  //                   children: [
  //                     SizedBox(width: 40),
  //                     ...List.generate(24, (hour) => Container(
  //                       width: 20,
  //                       alignment: Alignment.center,
  //                       child: Text(
  //                         hour % 3 == 0 ? '$hour' : '',
  //                         style: TextStyle(fontSize: 9, color: Colors.grey),
  //                       ),
  //                     )),
  //                   ],
  //                 ),
  //                 // Heatmap grid
  //                 ...List.generate(7, (day) {
  //                   return Row(
  //                     children: [
  //                       Container(
  //                         width: 40,
  //                         child: Text(weekDays[day], style: TextStyle(fontSize: 11)),
  //                       ),
  //                       ...List.generate(24, (hour) {
  //                         int intensity = eatingHeatmap[day]?[hour] ?? 0;
  //                         return Container(
  //                           width: 20,
  //                           height: 20,
  //                           margin: EdgeInsets.all(1),
  //                           decoration: BoxDecoration(
  //                             color: _getHeatmapColor(intensity),
  //                             borderRadius: BorderRadius.circular(2),
  //                           ),
  //                         );
  //                       }),
  //                     ],
  //                   );
  //                 }),
  //                 SizedBox(height: 10),
  //                 // Legend
  //                 Row(
  //                   children: [
  //                     SizedBox(width: 40),
  //                     Text('Less', style: TextStyle(fontSize: 10, color: Colors.grey)),
  //                     SizedBox(width: 5),
  //                     ...List.generate(4, (i) => Container(
  //                       width: 15,
  //                       height: 15,
  //                       margin: EdgeInsets.symmetric(horizontal: 2),
  //                       decoration: BoxDecoration(
  //                         color: _getHeatmapColor(i),
  //                         borderRadius: BorderRadius.circular(2),
  //                       ),
  //                     )),
  //                     SizedBox(width: 5),
  //                     Text('More', style: TextStyle(fontSize: 10, color: Colors.grey)),
  //                   ],
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // === FRESHNESS INDEX ===
  Widget _buildFreshnessIndex(List<SensorData> sensorData) {
    // Get humidity readings
    List<double> humidity =
        sensorData.map((s) => s.humidity.toDouble()).toList();
    if (humidity.isEmpty) return _buildNoDataCard('No humidity data');

    return Card(
      child: Padding(
        padding: EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Freshness Index',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Humidity vs. Mold Risk Threshold (80%)',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            SizedBox(height: 15),
            Container(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                        sideTitles:
                            SideTitles(showTitles: true, reservedSize: 40)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index >= 0 && index < sensorData.length) {
                            int hoursAgo = sensorData.length - index - 1;
                            return Text('${hoursAgo}h',
                                style: TextStyle(fontSize: 10));
                          }
                          return Text('');
                        },
                      ),
                    ),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(
                      show: true, border: Border.all(color: Colors.grey[300]!)),
                  lineBarsData: [
                    // Humidity line
                    LineChartBarData(
                      spots: List.generate(humidity.length,
                          (i) => FlSpot(i.toDouble(), humidity[i])),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                    ),
                    // Mold risk threshold line
                    LineChartBarData(
                      spots: [FlSpot(0, 80), FlSpot(humidity.length - 1.0, 80)],
                      isCurved: false,
                      color: Colors.red,
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                      dashArray: [5, 5],
                    ),
                  ],
                  minY: 0,
                  maxY: 100,
                ),
              ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegend(Colors.blue, 'Humidity'),
                SizedBox(width: 15),
                _buildLegend(Colors.red, 'Mold Risk (80%)'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // === TEMPERATURE STABILITY ===
  Widget _buildTemperatureStability(List<SensorData> sensorData) {
    List<double> temperature =
        sensorData.map((s) => s.temp.toDouble()).toList();
    if (temperature.isEmpty) return _buildNoDataCard('No temperature data');

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
                Icon(Icons.thermostat,
                    color: isStable ? Colors.green : Colors.orange),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Temperature Stability',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(
                        isStable
                            ? 'Stable - Food quality protected'
                            : 'Warning - Temperature fluctuations detected',
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
                      spots: List.generate(temperature.length,
                          (i) => FlSpot(i.toDouble(), temperature[i])),
                      isCurved: true,
                      color: isStable ? Colors.green : Colors.orange,
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: (isStable ? Colors.green : Colors.orange)
                            .withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Avg: ${avgTemp.toStringAsFixed(1)}°C | Range: ${temperature.reduce((a, b) => a < b ? a : b).toStringAsFixed(1)}-${temperature.reduce((a, b) => a > b ? a : b).toStringAsFixed(1)}°C',
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
      case 0:
        return Colors.grey[200]!;
      case 1:
        return Colors.orange[200]!;
      case 2:
        return Colors.orange[400]!;
      case 3:
        return Colors.orange[700]!;
      default:
        return Colors.grey[200]!;
    }
  }
}
