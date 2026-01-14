import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // --- MOCK DATA (Hardcoded for Demo) ---
  final double foodPercent = 0.35; // 35%
  final double temp = 28.5;
  final int humidity = 62;
  final bool hasPet = true;
  double manualPortionSize = 20.0; // Default portion size
  // --------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Control Room 📱")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // --- VISUAL 1: FUEL GAUGE ---
            CircularPercentIndicator(
              radius: 80.0,
              lineWidth: 15.0,
              percent: foodPercent,
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("${(foodPercent * 100).toInt()}%",
                      style:
                          TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                  Text("Remaining", style: TextStyle(color: Colors.grey)),
                ],
              ),
              footer: Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Text(
                  "Est. Empty in: 3.5 Days",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.blueGrey),
                ),
              ),
              progressColor: foodPercent < 0.2 ? Colors.red : Colors.green,
              backgroundColor: Colors.grey[200]!,
              circularStrokeCap: CircularStrokeCap.round,
              animation: true,
            ),
            SizedBox(height: 30),

            // --- VISUAL 3: ENVIRONMENT ---
            Row(
              children: [
                Expanded(
                    child: _buildEnvCard(
                        "Temp", "$temp°C", Icons.thermostat, Colors.orange)),
                SizedBox(width: 15),
                Expanded(
                    child: _buildEnvCard(
                        "Humidity",
                        "$humidity%",
                        Icons.water_drop,
                        Colors.red)), // Red to show warning logic
              ],
            ),
            SizedBox(height: 20),

            // --- VISUAL 2: PET PRESENCE ---
            ListTile(
              tileColor: hasPet ? Colors.green[100] : Colors.grey[200],
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              leading:
                  Icon(Icons.pets, color: hasPet ? Colors.green : Colors.grey),
              title: Text(hasPet ? "Pet Currently Eating" : "No Pet Detected",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: hasPet ? Colors.green[900] : Colors.grey)),
            ),
            SizedBox(height: 20),

            // --- PORTION SIZE CONTROL ---
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
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
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

            // --- FEED BUTTON ---
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        "Demo Mode: Dispensing ${manualPortionSize.toInt()}g! 🍖")));
              },
              icon: Icon(Icons.restaurant, color: Colors.white),
              label: Text("FEED NOW (${manualPortionSize.toInt()}g)",
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  minimumSize: Size(double.infinity, 50)),
            )
          ],
        ),
      ),
    );
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
