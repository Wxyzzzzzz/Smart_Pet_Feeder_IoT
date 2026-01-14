import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  // --- MOCK FEEDING HISTORY LOGS ---
  // Enhanced with more details for system reliability tracking
  final List<Map<String, String>> logs = [
    {
      'date': 'Jan 14, 2026',
      'time': '08:00 AM',
      'type': 'Scheduled',
      'portion': '20g',
      'status': 'Success',
      'duration': '45 sec'
    },
    {
      'date': 'Jan 14, 2026',
      'time': '06:30 AM',
      'type': 'Manual',
      'portion': '15g',
      'status': 'Success',
      'duration': '32 sec'
    },
    {
      'date': 'Jan 13, 2026',
      'time': '06:30 PM',
      'type': 'Scheduled',
      'portion': '25g',
      'status': 'Success',
      'duration': '51 sec'
    },
    {
      'date': 'Jan 13, 2026',
      'time': '01:00 PM',
      'type': 'Scheduled',
      'portion': '20g',
      'status': 'Success',
      'duration': '42 sec'
    },
    {
      'date': 'Jan 13, 2026',
      'time': '08:00 AM',
      'type': 'Scheduled',
      'portion': '20g',
      'status': 'Success',
      'duration': '48 sec'
    },
    {
      'date': 'Jan 12, 2026',
      'time': '06:30 PM',
      'type': 'Scheduled',
      'portion': '25g',
      'status': 'Success',
      'duration': '55 sec'
    },
    {
      'date': 'Jan 12, 2026',
      'time': '01:00 PM',
      'type': 'Manual',
      'portion': '10g',
      'status': 'Success',
      'duration': '28 sec'
    },
    {
      'date': 'Jan 12, 2026',
      'time': '08:00 AM',
      'type': 'Scheduled',
      'portion': '20g',
      'status': 'Failed',
      'duration': '0 sec',
      'error': 'Container Empty'
    },
    {
      'date': 'Jan 11, 2026',
      'time': '06:30 PM',
      'type': 'Scheduled',
      'portion': '25g',
      'status': 'Success',
      'duration': '53 sec'
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Calculate statistics
    int totalFeedings = logs.length;
    int successfulFeedings = logs.where((log) => log['status'] == 'Success').length;
    int scheduledFeedings = logs.where((log) => log['type'] == 'Scheduled').length;
    int manualFeedings = logs.where((log) => log['type'] == 'Manual').length;
    double successRate = (successfulFeedings / totalFeedings * 100);

    return Scaffold(
      appBar: AppBar(
        title: Text("Feeding History 📜"),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () {
              // Placeholder for filter functionality
            },
          ),
        ],
      ),
      body: Column(
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Total', '$totalFeedings', Icons.list),
                      _buildStatItem('Success', '$successfulFeedings', Icons.check_circle, Colors.green),
                      _buildStatItem('Success Rate', '${successRate.toStringAsFixed(1)}%', Icons.analytics, Colors.blue),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Scheduled', '$scheduledFeedings', Icons.schedule, Colors.purple),
                      _buildStatItem('Manual', '$manualFeedings', Icons.touch_app, Colors.orange),
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700]),
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
                bool isSuccess = log['status'] == 'Success';
                bool isScheduled = log['type'] == 'Scheduled';
                
                return Card(
                  margin: EdgeInsets.only(bottom: 10),
                  elevation: 2,
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: isSuccess 
                          ? (isScheduled ? Colors.blue[100] : Colors.orange[100])
                          : Colors.red[100],
                      child: Icon(
                        isSuccess
                            ? (isScheduled ? Icons.alarm : Icons.touch_app)
                            : Icons.error,
                        color: isSuccess
                            ? (isScheduled ? Colors.blue : Colors.orange)
                            : Colors.red,
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          log['type']!,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSuccess ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            log['status']!,
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text('${log['date']} • ${log['time']}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          log['portion']!,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.deepOrange,
                          ),
                        ),
                        Text(
                          log['duration']!,
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailRow('Date & Time', '${log['date']} at ${log['time']}'),
                            _buildDetailRow('Type', log['type']!),
                            _buildDetailRow('Portion Dispensed', log['portion']!),
                            _buildDetailRow('Duration', log['duration']!),
                            _buildDetailRow('Status', log['status']!),
                            if (log.containsKey('error'))
                              _buildDetailRow('Error', log['error']!, isError: true),
                            SizedBox(height: 10),
                            Text(
                              'Servo Motor Confirmation: ${isSuccess ? "✓ Completed" : "✗ Failed"}',
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: isSuccess ? Colors.green : Colors.red,
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
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, [Color? color]) {
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
