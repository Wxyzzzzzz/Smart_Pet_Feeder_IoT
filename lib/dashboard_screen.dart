import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'services/firestore_service.dart';
import 'models/sensor_data.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  double manualPortionSize = 20.0; // Default portion size

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
                  Text(snapshot.error.toString(), style: TextStyle(color: Colors.grey)),
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
                  Text('No sensor data available', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  Text('Waiting for device to send data...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // Calculate food percentage (assuming max level is 100)
          double foodPercent = _firestoreService.calculateFoodLevelPercentage(sensorData.foodLevel);
          
          return SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
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
                          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                      Text("Remaining", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                  footer: Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Column(
                      children: [
                        Text(
                          "Food Level: ${sensorData.foodLevel}",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
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
                            "Temp", "${sensorData.temp.toStringAsFixed(1)}°C", Icons.thermostat, Colors.orange)),
                    SizedBox(width: 15),
                    Expanded(
                        child: _buildEnvCard(
                            "Humidity",
                            "${sensorData.humidity}%",
                            Icons.water_drop,
                            sensorData.humidity > 60 ? Colors.red : Colors.blue)),
                  ],
                ),
                SizedBox(height: 20),

                // === PET PRESENCE ===
                ListTile(
                  tileColor: _getPetStatusColor(sensorData),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  leading: Icon(Icons.pets, 
                      color: _getPetIconColor(sensorData)),
                  title: Text(
                      _getPetStatusText(sensorData),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getPetTextColor(sensorData))),
                  subtitle: sensorData.type != null 
                      ? Text('Status: ${sensorData.type}', style: TextStyle(fontSize: 12))
                      : null,
                ),
                SizedBox(height: 20),

                // === PORTION SIZE CONTROL ===
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Manual Feed Portion',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text('${manualPortionSize.toInt()}g',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepOrange)),
                          ],
                        ),
                        SizedBox(height: 10),
                        Slider(
                          value: manualPortionSize,
                          min: 5,
                          max: 50,
                          divisions: 45,
                          label: '${manualPortionSize.toInt()}g',
                          onChanged: (val) {
                            setState(() {
                              manualPortionSize = val;
                            });
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('5g', style: TextStyle(color: Colors.grey)),
                            Text('50g', style: TextStyle(color: Colors.grey)),
                          ],
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
                  label: Text("FEED NOW (${manualPortionSize.toInt()}g)",
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      minimumSize: Size(double.infinity, 50)),
                ),
              ],
            ),
          );
        },
      ),
    );
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
                  isOnline ? 'Device Online' : 'Last seen ${_formatTimeDifference(difference)}',
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
      final commandId = await _firestoreService.sendFeedingCommand(
        manualPortionSize.toInt(),
      );

      // Listen for command status updates
      final commandSubscription = _firestoreService.watchCommandStatus(commandId).listen((command) {
        if (command == null) return;

        if (command.status == 'completed') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Fed successfully! Dispensed ${command.portionSize}g'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else if (command.status == 'failed') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Feeding failed: ${command.errorMessage ?? "Unknown error"}'),
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
      final foodAfterFeeding = (currentFoodLevel - manualPortionSize.toInt()).clamp(0, 100);
      await _firestoreService.addFeedingLog(
        foodRemaining: foodAfterFeeding,
        source: 'manually',
      );

    } catch (e) {
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
}
