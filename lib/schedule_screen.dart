import 'package:flutter/material.dart';
import 'services/firestore_service.dart';
import 'services/pet_profile_service.dart';
import 'models/routine.dart';

class ScheduleScreen extends StatefulWidget {
  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final PetProfileService _petProfileService = PetProfileService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Feeding Schedule ⏰")),
      body: StreamBuilder<List<Routine>>(
        stream: _firestoreService.getRoutines(),
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
                  Text('Error loading schedules',
                      style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  Text(snapshot.error.toString(),
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final routines = snapshot.data ?? [];

          if (routines.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.alarm_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No feeding schedules yet',
                      style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  Text('Tap + to add your first schedule',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(15),
            itemCount: routines.length,
            itemBuilder: (context, index) {
              final routine = routines[index];
              return Card(
                margin: EdgeInsets.only(bottom: 15),
                child: ListTile(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  leading: CircleAvatar(
                    backgroundColor:
                        routine.enabled ? Colors.deepOrange : Colors.grey,
                    child: Icon(Icons.alarm, color: Colors.white),
                  ),
                  title: Text(
                    routine.time,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${routine.portionSize}g per feeding'),
                      Text(routine.getFormattedDays(),
                          style: TextStyle(color: Colors.blue, fontSize: 12)),
                      if (routine.portionSize !=
                          _petProfileService.portionPerMeal.toInt())
                        Text('⚠️ Using custom portion',
                            style:
                                TextStyle(color: Colors.orange, fontSize: 11)),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editSchedule(index, routine),
                      ),
                      Switch(
                        value: routine.enabled,
                        onChanged: (val) async {
                          try {
                            await _firestoreService.toggleRoutineEnabled(index);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(val
                                    ? 'Schedule enabled'
                                    : 'Schedule disabled'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(index),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSchedule,
        icon: Icon(Icons.add),
        label: Text('Add Schedule'),
        backgroundColor: Colors.deepOrange,
      ),
    );
  }

  void _addSchedule() async {
    print('DEBUG: Opening schedule dialog...');
    final result = await showDialog<Routine>(
      context: context,
      builder: (context) => ScheduleDialog(),
    );

    print('DEBUG: Dialog result: $result');

    if (result != null) {
      try {
        print('DEBUG: Attempting to add routine to Firebase...');
        print(
            'DEBUG: Routine details - Time: ${result.time}, Portion: ${result.portionSize}g, Days: ${result.days}, Enabled: ${result.enabled}');

        await _firestoreService.addRoutine(result);

        print('DEBUG: Routine added, showing success message');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Schedule added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print('ERROR: Failed to add routine: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      print('DEBUG: Dialog cancelled or returned null');
    }
  }

  void _editSchedule(int index, Routine routine) async {
    final result = await showDialog<Routine>(
      context: context,
      builder: (context) => ScheduleDialog(routine: routine),
    );
    if (result != null) {
      try {
        await _firestoreService.updateRoutine(index, result);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Schedule updated successfully'),
            backgroundColor: Colors.green,
          ),
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
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Schedule'),
        content: Text('Are you sure you want to delete this feeding schedule?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _firestoreService.deleteRoutine(index);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ Schedule deleted'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class ScheduleDialog extends StatefulWidget {
  final Routine? routine;

  ScheduleDialog({this.routine});

  @override
  _ScheduleDialogState createState() => _ScheduleDialogState();
}

class _ScheduleDialogState extends State<ScheduleDialog> {
  final PetProfileService _petProfileService = PetProfileService();
  late TimeOfDay selectedTime;
  late List<bool> selectedDays; // 0=Mon, 6=Sun

  // Always use portion from pet profile
  int get portionSize => _petProfileService.portionPerMeal.toInt();

  @override
  void initState() {
    super.initState();
    if (widget.routine != null) {
      selectedTime = widget.routine!.getTimeOfDay();
      selectedDays =
          List.generate(7, (index) => widget.routine!.days.contains(index));
    } else {
      selectedTime = TimeOfDay.now();
      selectedDays = List.generate(7, (index) => true); // All days by default
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.routine == null ? 'Add Schedule' : 'Edit Schedule'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Time picker
            ListTile(
              leading: Icon(Icons.access_time),
              title: Text('Time'),
              subtitle: Text(selectedTime.format(context)),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: selectedTime,
                );
                if (time != null) {
                  setState(() {
                    selectedTime = time;
                  });
                }
              },
            ),
            SizedBox(height: 20),

            // Day selection
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Days',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: List.generate(7, (index) {
                      final days = [
                        'Mon',
                        'Tue',
                        'Wed',
                        'Thu',
                        'Fri',
                        'Sat',
                        'Sun'
                      ];
                      return FilterChip(
                        label: Text(days[index]),
                        selected: selectedDays[index],
                        onSelected: (selected) {
                          setState(() {
                            selectedDays[index] = selected;
                          });
                        },
                        selectedColor: Colors.deepOrange,
                        labelStyle: TextStyle(
                          color:
                              selectedDays[index] ? Colors.white : Colors.black,
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Portion info (auto from pet profile)
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.restaurant_menu, color: Colors.blue, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Feed Portion',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${portionSize}g per feeding',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                        Text(
                          'From ${_petProfileService.petName}\'s profile',
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      'AUTO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // Validate at least one day is selected
            if (!selectedDays.contains(true)) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Please select at least one day'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            // Create list of selected day indices
            final days = <int>[];
            for (int i = 0; i < selectedDays.length; i++) {
              if (selectedDays[i]) days.add(i);
            }

            Navigator.pop(
              context,
              Routine(
                id: widget.routine?.id,
                time: Routine.timeOfDayToString(selectedTime),
                portionSize: portionSize,
                days: days,
                enabled: widget.routine?.enabled ?? true,
              ),
            );
          },
          child: Text('Save'),
        ),
      ],
    );
  }
}
