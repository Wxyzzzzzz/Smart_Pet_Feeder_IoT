import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';
import 'services/pet_profile_service.dart';
import 'models/sensor_data.dart';
import 'config/app_colors.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();
  final PetProfileService _petProfileService = PetProfileService();

  // Use portion per meal from pet profile
  double get portionSize => _petProfileService.portionPerMeal;

  // Daily feeding limits from pet profile
  double get dailyRecommendedPortion => _petProfileService.dailyPortion;
  double dailyMaxThreshold = 1.2; // 120% of recommended (safety limit)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Control Room 📱")),
      body: StreamBuilder<SensorData?>(
        stream: _firestoreService.getLatestSensorData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Error loading data', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  Text(snapshot.error.toString(),
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final sensorData = snapshot.data;
          if (sensorData == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No sensor data available',
                      style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  Text('Waiting for device to send data...',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // Calculate food percentage (assuming max level is 100)
          double foodPercent = _firestoreService
              .calculateFoodLevelPercentage(sensorData.foodLevel);

          // Monitor sensor data and trigger notifications
          _monitorSensorData(sensorData, foodPercent);

          return SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                // Web notification info banner
                if (kIsWeb)
                  Container(
                    margin: EdgeInsets.only(bottom: 16),
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Using web version. Notifications appear as in-app alerts. For mobile notifications, use the mobile app.',
                            style: TextStyle(
                                fontSize: 12, color: Colors.blue[900]),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, size: 18),
                          onPressed: () {
                            setState(() {}); // Will hide on rebuild
                          },
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                        ),
                      ],
                    ),
                  ),

                // Real-time connection indicator
                _buildConnectionStatus(sensorData.lastSeen),
                SizedBox(height: 20),

                // === FUEL GAUGE (Food Level) ===
                CircularPercentIndicator(
                  radius: 80.0,
                  lineWidth: 15.0,
                  percent: foodPercent,
                  center: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("${(foodPercent * 100).toInt()}%",
                          style: TextStyle(
                              fontSize: 30, fontWeight: FontWeight.bold)),
                      Text("Remaining", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                  footer: Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Column(
                      children: [
                        Text(
                          "Food Level: ${sensorData.foodLevel}",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey),
                        ),
                        Text(
                          _estimateDaysUntilEmpty(foodPercent),
                          style: TextStyle(color: Colors.orange),
                        ),
                      ],
                    ),
                  ),
                  progressColor: foodPercent < 0.2 ? Colors.red : Colors.green,
                  backgroundColor: Colors.grey[200]!,
                  circularStrokeCap: CircularStrokeCap.round,
                  animation: true,
                ),
                SizedBox(height: 30),

                // === ENVIRONMENT (Temp & Humidity) ===
                Row(
                  children: [
                    Expanded(
                        child: _buildEnvCard(
                            "Temp",
                            "${sensorData.temp.toStringAsFixed(1)}°C",
                            Icons.thermostat,
                            Colors.orange)),
                    SizedBox(width: 15),
                    Expanded(
                        child: _buildEnvCard(
                            "Humidity",
                            "${sensorData.humidity}%",
                            Icons.water_drop,
                            sensorData.humidity > 60
                                ? Colors.red
                                : Colors.blue)),
                  ],
                ),
                SizedBox(height: 20),

                // === PET PRESENCE ===
                ListTile(
                  tileColor: _getPetStatusColor(sensorData),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  leading:
                      Icon(Icons.pets, color: _getPetIconColor(sensorData)),
                  title: Text(_getPetStatusText(sensorData),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getPetTextColor(sensorData))),
                  subtitle: sensorData.type != null
                      ? Text('Status: ${sensorData.type}',
                          style: TextStyle(fontSize: 12))
                      : null,
                ),
                SizedBox(height: 20),

                // === DAILY FEEDING PROGRESS ===
                FutureBuilder<double>(
                  future: _firestoreService.getTodaysTotalPortions(),
                  builder: (context, snapshot) {
                    final todaysTotal = snapshot.data ?? 0.0;
                    final percentage =
                        (todaysTotal / dailyRecommendedPortion).clamp(0.0, 1.5);
                    final percentageText =
                        (percentage * 100).toStringAsFixed(0);

                    Color progressColor;
                    Color cardColor;
                    if (percentage < 0.8) {
                      progressColor = AppColors.success;
                      cardColor =
                          Color(0xFFF0F3ED); // Very soft sage background
                    } else if (percentage < 1.0) {
                      progressColor = AppColors.info;
                      cardColor =
                          Color(0xFFEFF2F5); // Soft blue-grey background
                    } else if (percentage < dailyMaxThreshold) {
                      progressColor = AppColors.warning;
                      cardColor = Color(0xFFF5F0E8); // Soft ochre background
                    } else {
                      progressColor = AppColors.error;
                      cardColor =
                          Color(0xFFF5EDE9); // Soft terracotta background
                    }

                    return Card(
                      elevation: 3,
                      color: cardColor,
                      child: Padding(
                        padding: EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.restaurant_menu,
                                        color: progressColor),
                                    SizedBox(width: 8),
                                    Text(
                                      'Today\'s Feeding',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${todaysTotal.toInt()}g / ${dailyRecommendedPortion.toInt()}g',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: progressColor,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                            LinearProgressIndicator(
                              value: percentage,
                              backgroundColor: Colors.grey[200],
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(progressColor),
                              minHeight: 8,
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$percentageText% of recommended',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[700]),
                                ),
                                if (percentage >= 1.0)
                                  Text(
                                    percentage >= dailyMaxThreshold
                                        ? '⛔ Limit reached!'
                                        : '⚠️ At limit',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: progressColor,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 20),

                // === PORTION INFO ===
                Card(
                  elevation: 3,
                  color: Color(0xFFF5F3F0), // Cream background
                  child: Padding(
                    padding: EdgeInsets.all(15),
                    child: Row(
                      children: [
                        Icon(Icons.restaurant_menu,
                            color: AppColors.primaryDark, size: 30),
                        SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Feed Portion',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[700]),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '${portionSize.toInt()}g per meal',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              Text(
                                'Recommended for ${_petProfileService.petName}',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.accentSage,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'AUTO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // === FEED BUTTON ===
                ElevatedButton.icon(
                  onPressed: () => _handleManualFeed(sensorData.foodLevel),
                  icon: Icon(Icons.restaurant, color: Colors.white),
                  label: Text("FEED NOW (${portionSize.toInt()}g)",
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      minimumSize: Size(double.infinity, 50)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Monitor sensor data and trigger notifications
  void _monitorSensorData(SensorData sensorData, double foodPercent) {
    // Convert food percentage to 0-100 scale
    double foodPercentage = foodPercent * 100;

    // Check food level and show in-app alert for web
    if (foodPercentage <= NotificationService.LOW_FOOD_THRESHOLD) {
      // Show notification
      _notificationService.checkFoodLevel(foodPercentage);

      // For web, also show an in-app banner
      if (kIsWeb && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.white),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                          '🍽️ Food level is low (${foodPercentage.toStringAsFixed(1)}%)! Please refill soon.'),
                    ),
                  ],
                ),
                backgroundColor: Colors.orange[700],
                duration: Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'OK',
                  textColor: Colors.white,
                  onPressed: () {},
                ),
              ),
            );
          }
        });
      }
    }

    // Check moisture level (humidity)
    if (sensorData.humidity >= NotificationService.HIGH_MOISTURE_THRESHOLD) {
      _notificationService.checkMoistureLevel(sensorData.humidity.toDouble());

      // For web, also show an in-app banner
      if (kIsWeb && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.white),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                          '⚠️ High moisture detected (${sensorData.humidity}%)! Food might be contaminated.'),
                    ),
                  ],
                ),
                backgroundColor: Colors.red[700],
                duration: Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'OK',
                  textColor: Colors.white,
                  onPressed: () {},
                ),
              ),
            );
          }
        });
      }
    }
  }

  Widget _buildConnectionStatus(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    final isOnline = difference.inMinutes < 5;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: isOnline ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isOnline ? Colors.green : Colors.orange,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOnline ? Icons.cloud_done : Icons.cloud_off,
            color: isOnline ? Colors.green : Colors.orange,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOnline
                      ? 'Device Online'
                      : 'Last seen ${_formatTimeDifference(difference)}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Device: feeder_001',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeDifference(Duration difference) {
    if (difference.inMinutes < 1) return 'just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  String _estimateDaysUntilEmpty(double foodPercent) {
    if (foodPercent <= 0) return 'Container Empty!';
    // Rough estimate: 3.5 days for full container
    final daysRemaining = (foodPercent * 3.5).ceil();
    return 'Est. Empty in: $daysRemaining Days';
  }

  Future<void> _handleManualFeed(int currentFoodLevel) async {
    try {
      print('DEBUG: Feed Now button pressed');
      print('DEBUG: Current food level: $currentFoodLevel');
      print('DEBUG: Portion size: ${portionSize.toInt()}g');

      // Check daily feeding limit before proceeding
      final todaysTotal = await _firestoreService.getTodaysTotalPortions();
      final newTotal = todaysTotal + portionSize;
      final dailyLimit = dailyRecommendedPortion * dailyMaxThreshold;
      final percentageOfRecommended =
          (newTotal / dailyRecommendedPortion * 100);

      print('DEBUG: Today\'s total: ${todaysTotal}g');
      print('DEBUG: New total would be: ${newTotal}g');
      print('DEBUG: Daily limit: ${dailyLimit}g');
      print(
          'DEBUG: Percentage of recommended: ${percentageOfRecommended.toStringAsFixed(1)}%');

      // Show warning if approaching or exceeding limit
      if (newTotal >= dailyLimit) {
        // EXCEEDED LIMIT - Block feeding
        _showDailyLimitDialog(
          title: '⛔ Daily Limit Exceeded!',
          message:
              'Your pet has already been fed ${todaysTotal.toInt()}g today (${percentageOfRecommended.toStringAsFixed(0)}% of recommended).\n\n'
              'Adding ${portionSize.toInt()}g would exceed the safe daily limit of ${dailyLimit.toInt()}g.\n\n'
              'Overfeeding can lead to health issues. Please wait until tomorrow.',
          isBlocked: true,
          todaysTotal: todaysTotal,
          recommendedPortion: dailyRecommendedPortion,
        );
        return; // Don't proceed with feeding
      } else if (newTotal >= dailyRecommendedPortion) {
        // APPROACHING/AT RECOMMENDED - Show warning but allow
        final shouldProceed = await _showDailyLimitDialog(
          title: '⚠️ Approaching Daily Limit',
          message:
              'Your pet has already been fed ${todaysTotal.toInt()}g today.\n\n'
              'Adding ${portionSize.toInt()}g will bring the total to ${newTotal.toInt()}g (${percentageOfRecommended.toStringAsFixed(0)}% of recommended ${dailyRecommendedPortion.toInt()}g).\n\n'
              'Do you want to proceed?',
          isBlocked: false,
          todaysTotal: todaysTotal,
          recommendedPortion: dailyRecommendedPortion,
        );

        if (shouldProceed != true) {
          return; // User cancelled
        }
      } else if (newTotal >= dailyRecommendedPortion * 0.8) {
        // SHOW INFO - Above 80% but below 100%
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                      'Fed ${todaysTotal.toInt()}g today. After this: ${newTotal.toInt()}g/${dailyRecommendedPortion.toInt()}g (${percentageOfRecommended.toStringAsFixed(0)}%)'),
                ),
              ],
            ),
            backgroundColor: Colors.blue[700],
            duration: Duration(seconds: 3),
          ),
        );
      }

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 15),
              Text('Sending command to device...'),
            ],
          ),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.blue,
        ),
      );

      // Send feeding command to IoT device via Firestore
      print('DEBUG: Calling sendFeedingCommand...');
      final commandId = await _firestoreService.sendFeedingCommand(
        portionSize.toInt(),
      );
      print('DEBUG: Command sent with ID: $commandId');

      // Listen for command status updates
      final commandSubscription =
          _firestoreService.watchCommandStatus(commandId).listen((command) {
        if (command == null) return;

        if (command.status == 'completed') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('✅ Fed successfully! Dispensed ${command.portionSize}g'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else if (command.status == 'failed') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '❌ Feeding failed: ${command.errorMessage ?? "Unknown error"}'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        } else if (command.status == 'processing') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚙️ Device is dispensing food...'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      });

      // Auto-cancel subscription after 30 seconds
      Future.delayed(Duration(seconds: 30), () {
        commandSubscription.cancel();
      });

      // Also add feeding log for record keeping
      final foodAfterFeeding =
          (currentFoodLevel - portionSize.toInt()).clamp(0, 100);
      print('DEBUG: Adding feeding log with food remaining: $foodAfterFeeding');
      await _firestoreService.addFeedingLog(
        foodRemaining: foodAfterFeeding,
        source: 'manually',
        portionSize: portionSize,
      );
      print('DEBUG: Feeding log added successfully');

      // Send notification for manual feeding
      final foodPercentage =
          _firestoreService.calculateFoodLevelPercentage(foodAfterFeeding) *
              100;
      await _notificationService.notifyManualFeed(
        portionSize: portionSize,
        foodRemaining: foodPercentage,
      );

      // For web, show in-app success message
      if (kIsWeb && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                      '🎯 Fed ${portionSize.toInt()}g! Food remaining: ${foodPercentage.toStringAsFixed(1)}%'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('ERROR in _handleManualFeed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Helper methods for pet status
  String _getPetStatusText(SensorData sensorData) {
    if (sensorData.type == 'FEEDING_COMPLETE') {
      return 'Feeding Complete';
    } else if (sensorData.type == 'PET_DETECTED') {
      return 'Pet Currently Eating';
    } else if (sensorData.detected) {
      return 'Pet Detected';
    } else {
      return 'No Pet Detected';
    }
  }

  Color _getPetStatusColor(SensorData sensorData) {
    if (sensorData.type == 'FEEDING_COMPLETE') {
      return Colors.blue[100]!;
    } else if (sensorData.detected) {
      return Colors.green[100]!;
    } else {
      return Colors.grey[200]!;
    }
  }

  Color _getPetIconColor(SensorData sensorData) {
    if (sensorData.type == 'FEEDING_COMPLETE') {
      return Colors.blue;
    } else if (sensorData.detected) {
      return Colors.green;
    } else {
      return Colors.grey;
    }
  }

  Color _getPetTextColor(SensorData sensorData) {
    if (sensorData.type == 'FEEDING_COMPLETE') {
      return Colors.blue[900]!;
    } else if (sensorData.detected) {
      return Colors.green[900]!;
    } else {
      return Colors.grey;
    }
  }

  Widget _buildEnvCard(String title, String val, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)]),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          SizedBox(height: 5),
          Text(val,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Future<bool?> _showDailyLimitDialog({
    required String title,
    required String message,
    required bool isBlocked,
    required double todaysTotal,
    required double recommendedPortion,
  }) {
    final percentageFed = (todaysTotal / recommendedPortion * 100);

    return showDialog<bool>(
      context: context,
      barrierDismissible: !isBlocked,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isBlocked ? Icons.block : Icons.warning_amber_rounded,
              color: isBlocked ? Colors.red : Colors.orange,
              size: 28,
            ),
            SizedBox(width: 12),
            Expanded(child: Text(title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Today\'s Feeding Summary',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Fed:'),
                      Text('${todaysTotal.toInt()}g',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recommended:'),
                      Text('${recommendedPortion.toInt()}g',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Percentage:'),
                      Text(
                        '${percentageFed.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              percentageFed > 100 ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (!isBlocked) ...[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text('Proceed Anyway'),
            ),
          ] else
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
              ),
              child: Text('OK'),
            ),
        ],
      ),
    );
  }
}
