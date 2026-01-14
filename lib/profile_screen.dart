import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'pet_setup_screen.dart';
import 'services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  
  // User data from Firebase Auth
  String get userName => _authService.currentUser?.displayName ?? 'User';
  String get userEmail => _authService.currentUser?.email ?? 'No email';
  
  // Pet data (will be updated from pet setup)
  String petName = 'Fluffy';
  String petBreed = 'Golden Retriever';
  double petWeight = 25.0;
  int petAge = 3;
  String ageCategory = 'Adult';
  int mealsPerDay = 2;
  double dailyPortion = 625.0;
  double portionPerMeal = 312.5;

  void _navigateToPetSetup() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PetSetupScreen(isFromSignup: false)),
    );
    
    if (result != null) {
      setState(() {
        petName = result['name'];
        petBreed = result['breed'];
        petWeight = result['weight'];
        petAge = result['age'];
        ageCategory = result['ageCategory'];
        mealsPerDay = result['mealsPerDay'];
        dailyPortion = result['dailyPortion'];
        portionPerMeal = result['portionPerMeal'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile & Settings ⚙️'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // User Profile Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.deepOrange[100],
                      child: Icon(Icons.person, size: 60, color: Colors.deepOrange),
                    ),
                    SizedBox(height: 15),
                    Text(
                      userName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      userEmail,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            
            // Pet Information Card
            Card(
              elevation: 4,
              color: Colors.orange[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.pets, color: Colors.deepOrange, size: 28),
                            SizedBox(width: 10),
                            Text(
                              'Pet Profile',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.deepOrange),
                          onPressed: _navigateToPetSetup,
                        ),
                      ],
                    ),
                    Divider(),
                    SizedBox(height: 10),
                    _buildPetInfoRow('Name', petName),
                    _buildPetInfoRow('Breed', petBreed),
                    _buildPetInfoRow('Weight', '${petWeight.toStringAsFixed(1)} kg'),
                    _buildPetInfoRow('Age', '$petAge years ($ageCategory)'),
                    _buildPetInfoRow('Meals/Day', '$mealsPerDay meals'),
                    SizedBox(height: 15),
                    Container(
                      padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.deepOrange, width: 2),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '🍖 Recommended Portions',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  Text('Daily', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                  Text(
                                    '${dailyPortion.toInt()}g',
                                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                                  ),
                                ],
                              ),
                              Container(width: 1, height: 40, color: Colors.grey[300]),
                              Column(
                                children: [
                                  Text('Per Meal', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                  Text(
                                    '${portionPerMeal.toInt()}g',
                                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 30),

            // Account Settings
            _buildSectionTitle('Account'),
            _buildSettingsTile(
              icon: Icons.edit,
              title: 'Edit Profile',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Edit profile feature coming soon!')),
                );
              },
            ),
            _buildSettingsTile(
              icon: Icons.lock,
              title: 'Change Password',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Change password feature coming soon!')),
                );
              },
            ),
            SizedBox(height: 20),

            // Pet Settings
            _buildSectionTitle('Pet Settings'),
            _buildSettingsTile(
              icon: Icons.pets,
              title: 'Pet Information',
              subtitle: '$petName • $petBreed • ${petWeight.toStringAsFixed(1)}kg',
              onTap: _navigateToPetSetup,
            ),
            _buildSettingsTile(
              icon: Icons.food_bank,
              title: 'Food Preferences',
              subtitle: 'Dry food, 100g/day recommended',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Food preferences feature coming soon!')),
                );
              },
            ),
            SizedBox(height: 20),

            // Device Settings
            _buildSectionTitle('Device'),
            _buildSettingsTile(
              icon: Icons.bluetooth,
              title: 'Device Connection',
              subtitle: 'Smart Feeder #1234',
              trailing: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Connected',
                  style: TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Device settings feature coming soon!')),
                );
              },
            ),
            _buildSettingsTile(
              icon: Icons.notifications,
              title: 'Notifications',
              subtitle: 'Feeding alerts and reminders',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Notification settings feature coming soon!')),
                );
              },
            ),
            SizedBox(height: 20),

            // App Settings
            _buildSectionTitle('App'),
            _buildSettingsTile(
              icon: Icons.help,
              title: 'Help & Support',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Help center feature coming soon!')),
                );
              },
            ),
            _buildSettingsTile(
              icon: Icons.info,
              title: 'About',
              subtitle: 'Version 1.0.0',
              onTap: () {
                _showAboutDialog(context);
              },
            ),
            SizedBox(height: 30),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _handleLogout(context),
                icon: Icon(Icons.logout, color: Colors.white),
                label: Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPetInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[700], fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.deepOrange[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.deepOrange),
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              )
            : null,
        trailing: trailing ?? Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _handleLogout(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _authService.signOut();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logout failed: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.pets, color: Colors.deepOrange),
            SizedBox(width: 10),
            Text('Smart Pet Feeder'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0'),
            SizedBox(height: 10),
            Text('An IoT-based smart feeding system for your beloved pets.'),
            SizedBox(height: 10),
            Text(
              '© 2026 Smart Pet Feeder',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}
