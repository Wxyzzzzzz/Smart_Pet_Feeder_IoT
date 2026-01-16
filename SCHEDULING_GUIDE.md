# Scheduling Feature - Setup & Testing Guide

## ✅ What's Been Implemented

The scheduling feature is now **fully integrated** with Firebase and your backend!

### Components:
1. **Routine Model** (`lib/models/routine.dart`) - Data structure for schedules
2. **Firestore Service** - CRUD operations for routines
3. **Schedule Screen** - UI for managing feeding schedules
4. **Backend Scheduler** - Automatically triggers feeding at scheduled times

---

## How It Works

```
Schedule → Firebase → Backend → MQTT → ESP32 → Servo
```

1. **App**: User creates schedule (time + days + portion)
2. **Firebase**: Stored in `feeders/feeder_001` document under `routines` array
3. **Backend**: Checks every minute if current time matches any enabled routine
4. **MQTT**: Sends "FEED" command if match found
5. **ESP32**: Activates servo motor

---

## Firebase Data Structure

In Firestore at `feeders/feeder_001`:

```javascript
{
  "device_id": "feeder_001",
  "manual_feed": false,
  "routines": [
    {
      "time": "08:00",           // HH:MM format (24-hour)
      "portion_size": 20,        // grams
      "days": [0, 1, 2, 3, 4],  // 0=Mon, 1=Tue, ..., 6=Sun
      "enabled": true
    },
    {
      "time": "18:30",
      "portion_size": 25,
      "days": [0, 1, 2, 3, 4, 5, 6], // Every day
      "enabled": true
    }
  ]
}
```

---

## Testing Steps

### 1. Start the Backend
```powershell
cd c:\Users\User\Downloads\smart_pet_feeder\cloud
python backend.py
```

You should see:
```
[SYSTEM] Firebase Connected
[SYSTEM] Listening for Manual Control on 'feeders/feeder_001'...
[SYSTEM] MQTT Connected Successfully
```

### 2. Run the Flutter App
The schedule screen should now:
- ✅ Load existing schedules from Firebase
- ✅ Add new schedules
- ✅ Edit existing schedules
- ✅ Delete schedules
- ✅ Toggle schedules on/off

### 3. Create a Test Schedule
1. Open app → Navigate to Schedule screen
2. Click "Add Schedule" button
3. Set time to **2 minutes from now** (for quick testing)
4. Select days (at least today's day)
5. Set portion size
6. Click "Save"

### 4. Watch Firebase Console
1. Open Firebase Console → Firestore
2. Go to `feeders` → `feeder_001`
3. You should see the `routines` array with your schedule

### 5. Wait for Scheduled Time
When the time arrives:
- **Backend terminal**: Should print `[SCHEDULE] Match found for feeder_001 at HH:MM!`
- **Backend**: Sends MQTT "FEED" command
- **ESP32**: Receives command and activates servo
- **App**: Updates food level after feeding

---

## Day Mapping

Backend uses Python's `weekday()`:
- **0 = Monday**
- **1 = Tuesday**
- **2 = Wednesday**
- **3 = Thursday**
- **4 = Friday**
- **5 = Saturday**
- **6 = Sunday**

The app's day selector automatically uses this format!

---

## Features in Schedule Dialog

### Time Selection
- 24-hour format
- Minute precision
- Time picker UI

### Day Selection
- Individual days (Mon-Sun)
- Quick select: Weekdays, Weekends, Every day
- Visual chips for easy selection

### Portion Size
- Range: 5g to 50g
- Slider with visual feedback

---

## Schedule Management

### View Schedules
- Real-time updates from Firebase
- Shows: Time, portion, days, enabled status
- Color-coded: Orange = enabled, Grey = disabled

### Edit Schedule
- Click edit icon
- Modify time, days, or portion
- Changes sync to Firebase immediately

### Toggle On/Off
- Use switch to enable/disable
- Disabled schedules won't trigger
- Useful for temporary changes

### Delete Schedule
- Click delete icon
- Confirmation dialog
- Permanent removal from Firebase

---

## Backend Scheduler Behavior

The `check_schedules()` function runs **every minute**:

```python
current_time_str = now.strftime("%H:%M")  # e.g., "14:30"
current_day_int = now.weekday()           # 0-6

# Check each routine:
if (routine['enabled'] == True and 
    routine['time'] == current_time_str and 
    current_day_int in routine['days']):
    
    send_mqtt_command(device_id, "FEED")
```

**Important Notes:**
- Checks run at the **start of each minute**
- Schedule must match **exact time** (HH:MM)
- Will trigger only **once per minute** (no double triggers)
- Uses **Asia/Kuala_Lumpur timezone** (can be changed in backend.py)

---

## Troubleshooting

### Schedule Not Triggering

**Check 1: Backend Running?**
```powershell
Get-Process python
```

**Check 2: Schedule Format in Firebase**
- Open Firebase Console
- Verify `routines` array exists
- Check time format is "HH:MM" (e.g., "08:00" not "8:0")
- Verify days array has integers (not strings)

**Check 3: Enabled Status**
- Must be `enabled: true`

**Check 4: Day Match**
- Current day must be in `days` array
- Check backend logs for current day number

**Check 5: Time Zone**
- Backend uses `Asia/Kuala_Lumpur`
- Verify server time matches expected time

### Schedule Shows "No schedules"

**Possible causes:**
- Firebase document doesn't have `routines` field
- `routines` is not an array
- Internet connection issue

**Fix:**
Manually add to Firebase:
```javascript
feeders/feeder_001:
{
  "routines": []
}
```

### Can't Add/Edit Schedule

**Check Firestore Rules:**
```javascript
match /feeders/{feederId} {
  allow read, write: if request.auth != null;
}
```

**Check Authentication:**
- User must be logged in
- Auth token must be valid

---

## Advanced: Multiple Schedules

You can create **unlimited schedules**:
- Morning feeding (8:00 AM)
- Lunch feeding (12:30 PM)
- Dinner feeding (6:00 PM)
- Weekend special (10:00 AM, Sat-Sun only)

Each routine is independent and will trigger separately.

---

## Example Schedules

### Weekday Morning Feed
```
Time: 08:00
Portion: 20g
Days: Mon, Tue, Wed, Thu, Fri
```

### Weekend Brunch
```
Time: 10:00
Portion: 30g
Days: Sat, Sun
```

### Every Evening
```
Time: 18:30
Portion: 25g
Days: All days
```

---

## Testing Checklist

- [ ] Backend running and connected to Firebase
- [ ] MQTT broker running
- [ ] ESP32 connected to MQTT
- [ ] Create test schedule (2 min from now)
- [ ] Schedule appears in Firebase
- [ ] Wait for scheduled time
- [ ] Backend detects schedule match
- [ ] MQTT command sent
- [ ] Servo activates
- [ ] Feeding log created

---

## Next Steps

1. **Test with Flutter app** - Add a schedule and verify it saves to Firebase
2. **Test scheduling** - Create a schedule for soon and watch it trigger
3. **Test editing** - Modify an existing schedule
4. **Test toggle** - Disable/enable schedules
5. **Test delete** - Remove a schedule

Everything is ready to go! 🚀
