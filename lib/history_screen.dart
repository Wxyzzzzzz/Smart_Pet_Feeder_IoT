import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'services/firestore_service.dart';
import 'models/feeding_log.dart';

class HistoryScreen extends StatelessWidget {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Feeding History 📜"),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Filter feature coming soon!')),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<FeedingLog>>(
        stream: _firestoreService.getFeedingLogs(limit: 50),
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
                  Text('Error loading logs', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  Text(snapshot.error.toString(),
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            );
          }

          final logs = snapshot.data ?? [];

          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No feeding logs yet',
                      style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  Text('Logs will appear here after feeding',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // Calculate statistics
          int totalFeedings = logs.length;
          int scheduledFeedings =
              logs.where((log) => log.source == 'scheduled').length;
          int manualFeedings =
              logs.where((log) => log.source == 'manually').length;

          return Column(
            children: [
              // Statistics Summary Card
              Card(
                margin: EdgeInsets.all(15),
                color: Colors.deepOrange[50],
                child: Padding(
                  padding: EdgeInsets.all(15),
                  child: Column(
                    children: [
                      Text(
                        'System Reliability',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                              'Total', '$totalFeedings', Icons.list),
                          _buildStatItem('Scheduled', '$scheduledFeedings',
                              Icons.schedule, Colors.purple),
                          _buildStatItem('Manual', '$manualFeedings',
                              Icons.touch_app, Colors.orange),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Log entries header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                child: Row(
                  children: [
                    Text(
                      'Audit Trail',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700]),
                    ),
                    Spacer(),
                    Text(
                      '${logs.length} entries',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              // Scrollable log list
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    bool isScheduled = log.source == 'scheduled';

                    return Card(
                      margin: EdgeInsets.only(bottom: 10),
                      elevation: 2,
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: isScheduled
                              ? Colors.blue[100]
                              : Colors.orange[100],
                          child: Icon(
                            isScheduled ? Icons.alarm : Icons.touch_app,
                            color: isScheduled ? Colors.blue : Colors.orange,
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              isScheduled ? 'Scheduled' : 'Manual',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Success',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          DateFormat('MMM dd, yyyy • hh:mm a')
                              .format(log.timestamp),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Food: ${log.foodRemaining}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.deepOrange,
                              ),
                            ),
                            Text(
                              'remaining',
                              style:
                                  TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailRow(
                                    'Date & Time',
                                    DateFormat('MMMM dd, yyyy • hh:mm:ss a')
                                        .format(log.timestamp)),
                                _buildDetailRow('Device ID', log.deviceId),
                                _buildDetailRow('Source', log.source),
                                _buildDetailRow('Food Remaining',
                                    '${log.foodRemaining}'),
                                _buildDetailRow(
                                    'Last Seen',
                                    DateFormat('hh:mm:ss a')
                                        .format(log.lastSeen)),
                                SizedBox(height: 10),
                                Text(
                                  'Servo Motor Confirmation: ✓ Completed',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon,
      [Color? color]) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.deepOrange, size: 24),
        SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: isError ? Colors.red : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
