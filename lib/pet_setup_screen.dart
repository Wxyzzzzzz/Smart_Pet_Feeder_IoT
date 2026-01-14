import 'package:flutter/material.dart';
import 'main.dart';

class PetSetupScreen extends StatefulWidget {
  final bool isFromSignup;

  PetSetupScreen({this.isFromSignup = true});

  @override
  _PetSetupScreenState createState() => _PetSetupScreenState();
}

class _PetSetupScreenState extends State<PetSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _petNameController = TextEditingController();
  final _breedController = TextEditingController();
  
  double _weight = 10.0; // kg
  int _mealsPerDay = 2;
  int _age = 3; // years
  String _ageCategory = 'Adult'; // Puppy, Adult, Senior
  
  double _calculatedDailyPortion = 0.0;
  double _portionPerMeal = 0.0;

  @override
  void initState() {
    super.initState();
    _calculatePortion();
  }

  @override
  void dispose() {
    _petNameController.dispose();
    _breedController.dispose();
    super.dispose();
  }

  void _calculatePortion() {
    // Calculate recommended daily food portion based on weight, age, and activity
    double dailyPercentage;
    
    if (_age < 1) {
      // Puppy (0-1 year): 3-4% of body weight
      dailyPercentage = 0.035;
      _ageCategory = 'Puppy';
    } else if (_age >= 1 && _age <= 7) {
      // Adult (1-7 years): 2-3% of body weight
      dailyPercentage = 0.025;
      _ageCategory = 'Adult';
    } else {
      // Senior (7+ years): 2-2.5% of body weight
      dailyPercentage = 0.0225;
      _ageCategory = 'Senior';
    }
    
    // Calculate daily portion in grams
    _calculatedDailyPortion = _weight * 1000 * dailyPercentage;
    
    // Calculate portion per meal
    _portionPerMeal = _calculatedDailyPortion / _mealsPerDay;
    
    setState(() {});
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      // Save pet information and navigate
      if (widget.isFromSignup) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => MainNavigation()),
          (route) => false,
        );
      } else {
        Navigator.pop(context, {
          'name': _petNameController.text,
          'breed': _breedController.text,
          'weight': _weight,
          'age': _age,
          'ageCategory': _ageCategory,
          'mealsPerDay': _mealsPerDay,
          'dailyPortion': _calculatedDailyPortion,
          'portionPerMeal': _portionPerMeal,
        });
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pet profile saved! Recommended: ${_portionPerMeal.toInt()}g per meal'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isFromSignup ? 'Setup Your Pet' : 'Pet Information'),
        automaticallyImplyLeading: !widget.isFromSignup,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              if (widget.isFromSignup) ...[
                Center(
                  child: Icon(Icons.pets, size: 80, color: Colors.deepOrange),
                ),
                SizedBox(height: 20),
                Center(
                  child: Text(
                    'Tell us about your pet',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 10),
                Center(
                  child: Text(
                    'We\'ll calculate the perfect portion size',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ),
                SizedBox(height: 30),
              ],
              
              // Pet Name
              TextFormField(
                controller: _petNameController,
                decoration: InputDecoration(
                  labelText: 'Pet Name *',
                  prefixIcon: Icon(Icons.pets, color: Colors.deepOrange),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.deepOrange, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your pet\'s name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              
              // Breed
              TextFormField(
                controller: _breedController,
                decoration: InputDecoration(
                  labelText: 'Breed (Optional)',
                  prefixIcon: Icon(Icons.category, color: Colors.deepOrange),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.deepOrange, width: 2),
                  ),
                ),
              ),
              SizedBox(height: 30),
              
              // Weight Slider
              Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Weight', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('${_weight.toStringAsFixed(1)} kg', 
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                        ],
                      ),
                      Slider(
                        value: _weight,
                        min: 1,
                        max: 100,
                        divisions: 199,
                        label: '${_weight.toStringAsFixed(1)} kg',
                        onChanged: (value) {
                          setState(() {
                            _weight = value;
                            _calculatePortion();
                          });
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('1 kg', style: TextStyle(color: Colors.grey)),
                          Text('100 kg', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              
              // Age Slider
              Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Age', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('$_age ${_age == 1 ? "year" : "years"}', 
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                              Text(_ageCategory, style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                      Slider(
                        value: _age.toDouble(),
                        min: 0,
                        max: 20,
                        divisions: 40,
                        label: '$_age ${_age == 1 ? "year" : "years"}',
                        onChanged: (value) {
                          setState(() {
                            _age = value.toInt();
                            _calculatePortion();
                          });
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('0 years', style: TextStyle(color: Colors.grey)),
                          Text('20 years', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              
              // Meals Per Day
              Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Meals Per Day', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('$_mealsPerDay meals', 
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                        ],
                      ),
                      Slider(
                        value: _mealsPerDay.toDouble(),
                        min: 1,
                        max: 6,
                        divisions: 5,
                        label: '$_mealsPerDay meals',
                        onChanged: (value) {
                          setState(() {
                            _mealsPerDay = value.toInt();
                            _calculatePortion();
                          });
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('1 meal', style: TextStyle(color: Colors.grey)),
                          Text('6 meals', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 30),
              
              // Calculation Results
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepOrange[100]!, Colors.deepOrange[50]!],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.deepOrange, width: 2),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calculate, color: Colors.deepOrange, size: 30),
                        SizedBox(width: 10),
                        Text(
                          'Recommended Portions',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    Divider(),
                    SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Daily Total', style: TextStyle(color: Colors.grey[700])),
                            SizedBox(height: 5),
                            Text(
                              '${_calculatedDailyPortion.toInt()}g',
                              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.deepOrange[900]),
                            ),
                          ],
                        ),
                        Container(width: 1, height: 50, color: Colors.deepOrange[300]),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Per Meal', style: TextStyle(color: Colors.grey[700])),
                            SizedBox(height: 5),
                            Text(
                              '${_portionPerMeal.toInt()}g',
                              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.deepOrange[900]),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    Divider(),
                    SizedBox(height: 10),
                    Text(
                      'Based on $_ageCategory dog, ${_weight.toStringAsFixed(1)}kg, $_mealsPerDay meals/day',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700], fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.isFromSignup ? 'Complete Setup' : 'Save Changes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
