import 'package:flutter/material.dart';

class ScheduleScreen extends StatefulWidget {
  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  // Mock schedule data
  List<FeedingSchedule> schedules = [
    FeedingSchedule(time: TimeOfDay(hour: 8, minute: 0), portion: 20, enabled: true),
    FeedingSchedule(time: TimeOfDay(hour: 13, minute: 0), portion: 15, enabled: true),
    FeedingSchedule(time: TimeOfDay(hour: 18, minute: 30), portion: 25, enabled: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Feeding Schedule ⏰")),
      body: ListView.builder(
        padding: EdgeInsets.all(15),
        itemCount: schedules.length,
        itemBuilder: (context, index) {
          final schedule = schedules[index];
          return Card(
            margin: EdgeInsets.only(bottom: 15),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              leading: CircleAvatar(
                backgroundColor: schedule.enabled ? Colors.deepOrange : Colors.grey,
                child: Icon(Icons.alarm, color: Colors.white),
              ),
              title: Text(
                schedule.time.format(context),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              subtitle: Text('${schedule.portion}g portion'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _editSchedule(index),
                  ),
                  Switch(
                    value: schedule.enabled,
                    onChanged: (val) {
                      setState(() {
                        schedules[index].enabled = val;
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        schedules.removeAt(index);
                      });
                    },
                  ),
                ],
              ),
            ),
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
    final result = await showDialog<FeedingSchedule>(
      context: context,
      builder: (context) => ScheduleDialog(),
    );
    if (result != null) {
      setState(() {
        schedules.add(result);
      });
    }
  }

  void _editSchedule(int index) async {
    final result = await showDialog<FeedingSchedule>(
      context: context,
      builder: (context) => ScheduleDialog(schedule: schedules[index]),
    );
    if (result != null) {
      setState(() {
        schedules[index] = result;
      });
    }
  }
}

class FeedingSchedule {
  TimeOfDay time;
  int portion; // in grams
  bool enabled;

  FeedingSchedule({required this.time, required this.portion, this.enabled = true});
}

class ScheduleDialog extends StatefulWidget {
  final FeedingSchedule? schedule;

  ScheduleDialog({this.schedule});

  @override
  _ScheduleDialogState createState() => _ScheduleDialogState();
}

class _ScheduleDialogState extends State<ScheduleDialog> {
  late TimeOfDay selectedTime;
  late double portionSize;

  @override
  void initState() {
    super.initState();
    selectedTime = widget.schedule?.time ?? TimeOfDay.now();
    portionSize = (widget.schedule?.portion ?? 20).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.schedule == null ? 'Add Schedule' : 'Edit Schedule'),
      content: Column(
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
          // Portion size slider
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Portion Size: ${portionSize.toInt()}g',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Slider(
                value: portionSize,
                min: 5,
                max: 50,
                divisions: 45,
                label: '${portionSize.toInt()}g',
                onChanged: (val) {
                  setState(() {
                    portionSize = val;
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
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(
              context,
              FeedingSchedule(
                time: selectedTime,
                portion: portionSize.toInt(),
                enabled: widget.schedule?.enabled ?? true,
              ),
            );
          },
          child: Text('Save'),
        ),
      ],
    );
  }
}
