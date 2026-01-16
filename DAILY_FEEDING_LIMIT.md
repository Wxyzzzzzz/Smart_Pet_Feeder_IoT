# Daily Feeding Limit Feature

## Overview
The app now tracks total daily feeding (manual + scheduled) and prevents overfeeding by comparing against the daily recommended portion. This helps maintain your pet's health and prevents accidental overfeeding.

## How It Works

### 1. **Daily Tracking**
- Tracks all portions dispensed today (manual + scheduled feeds)
- Stores portion size in grams with each feeding log
- Calculates running total automatically

### 2. **Smart Thresholds**
The system has multiple warning levels:

| Level | Threshold | Action | Visual |
|-------|-----------|--------|--------|
| **Safe** | < 80% | No warning | 🟢 Green progress bar |
| **Approaching** | 80-99% | Info message | 🔵 Blue progress bar |
| **At Limit** | 100-119% | Warning dialog (allows override) | 🟠 Orange progress bar |
| **Exceeded** | ≥ 120% | **BLOCKED** - Cannot feed | 🔴 Red progress bar |

### 3. **Default Settings**
- **Daily Recommended**: 625g (based on 25kg adult dog)
- **Safety Limit**: 120% of recommended (750g)
- Can be customized in code based on pet profile

---

## Features

### ✅ Visual Progress Indicator
The dashboard shows a **Daily Feeding Progress** card displaying:
- Total fed today (e.g., "250g / 625g")
- Progress bar (color-coded by threshold)
- Percentage of recommended
- Warning badges when approaching/at limit

### ⚠️ Smart Warnings

#### **80-99% (Info Message)**
Simple notification:
> "Fed 500g today. After this: 520g/625g (83%)"

#### **100-119% (Warning Dialog)**
Shows a dialog with:
- Warning message about approaching limit
- Today's feeding summary table
- Option to **Cancel** or **Proceed Anyway**

Example:
```
⚠️ Approaching Daily Limit

Your pet has already been fed 600g today.
Adding 20g will bring the total to 620g (99% of recommended 625g).

Do you want to proceed?

Today's Feeding Summary:
  Total Fed:      620g
  Recommended:    625g
  Percentage:     99%

[Cancel] [Proceed Anyway]
```

#### **≥120% (BLOCKED)**
Shows blocking dialog:
```
⛔ Daily Limit Exceeded!

Your pet has already been fed 750g today (120% of recommended).
Adding 20g would exceed the safe daily limit of 750g.

Overfeeding can lead to health issues. Please wait until tomorrow.

[OK]
```

---

## Testing the Feature

### Test 1: Normal Feeding (< 80%)
1. Start with fresh day (or clear logs)
2. Feed 100g manually
3. See: Green progress bar, no warnings
4. ✅ Feeding succeeds

### Test 2: Approaching Limit (80-99%)
1. In Firebase, add logs totaling 500g today
2. Try to feed 50g (would be 550g = 88%)
3. See: Blue info message
4. ✅ Feeding succeeds

### Test 3: At Recommended (100-119%)
1. Add logs totaling 600g
2. Try to feed 30g (would be 630g = 101%)
3. See: Orange warning dialog with option to proceed
4. ⚠️ Can proceed if confirmed

### Test 4: Exceeded Limit (≥120%)
1. Add logs totaling 750g
2. Try to feed any amount
3. See: Red blocking dialog
4. ⛔ Feeding is blocked

---

## Customization

### Change Daily Recommended Portion
Edit in [dashboard_screen.dart](lib/dashboard_screen.dart):
```dart
// In _DashboardScreenState
double dailyRecommendedPortion = 625.0; // Change this value
```

### Change Safety Threshold
```dart
double dailyMaxThreshold = 1.2; // 1.2 = 120%, change to 1.3 for 130%
```

### Adjust Warning Levels
In `_handleManualFeed` method, modify the conditions:
```dart
// Current thresholds:
if (newTotal >= dailyLimit) {              // 120% - BLOCKED
if (newTotal >= dailyRecommendedPortion) { // 100% - WARNING
if (newTotal >= dailyRecommendedPortion * 0.8) { // 80% - INFO
```

---

## Integration with Pet Profile

To make this feature use actual pet data from the Pet Setup screen:

### Option 1: Shared Preferences
Store dailyPortion in SharedPreferences when pet is set up, retrieve in dashboard.

### Option 2: Firestore
Add pet profile to Firestore:
```dart
// Store in: feeders/feeder_001/pet_profile
{
  'name': 'Fluffy',
  'weight': 25.0,
  'dailyPortion': 625.0
}
```

Then retrieve in dashboard:
```dart
// In initState
_loadPetProfile() async {
  final doc = await _firestore
    .collection('feeders')
    .doc('feeder_001')
    .collection('pet_profile')
    .doc('profile')
    .get();
    
  if (doc.exists) {
    setState(() {
      dailyRecommendedPortion = doc.data()!['dailyPortion'];
    });
  }
}
```

---

## Backend Integration

For scheduled feeding, update [backend.py](cloud/backend.py) to include portion_size:

```python
def on_message(client, userdata, msg):
    # ... existing code ...
    
    if "events" in msg.topic:
        data['portion_size'] = 20  # Add actual portion from routine
        save_history(device_id, "feeding_logs", data)
```

---

## Technical Details

### Database Schema
**feeding_logs collection:**
```javascript
{
  device_id: "feeder_001",
  food_remaining: 50,
  source: "manually",  // or "scheduled"
  timestamp: Timestamp,
  last_seen: Timestamp,
  portion_size: 20.0   // NEW FIELD in grams
}
```

### Methods Added

**FirestoreService:**
- `getTodaysTotalPortions()` - Returns sum of all portions fed today
- `getTodaysFeedingLogs()` - Stream of today's logs
- Updated `addFeedingLog()` - Now accepts `portionSize` parameter

**DashboardScreen:**
- `_showDailyLimitDialog()` - Shows warning/blocking dialog
- Daily progress card with FutureBuilder
- Validation logic in `_handleManualFeed()`

---

## Benefits

### Health & Safety
✅ Prevents accidental overfeeding
✅ Maintains consistent daily portions
✅ Reduces risk of obesity and health issues
✅ Peace of mind for pet owners

### User Experience
✅ Clear visual feedback
✅ Progressive warnings (info → warning → block)
✅ Option to override when needed (up to 120%)
✅ Tracks all feeding sources (manual + scheduled)

### Data Insights
✅ Historical feeding patterns
✅ Daily consumption trends
✅ Can identify unusual eating behaviors

---

## Future Enhancements

- [ ] Multi-pet support (different limits per pet)
- [ ] Weekly/monthly feeding reports
- [ ] Adjust recommendations based on weight changes
- [ ] Veterinarian recommendations integration
- [ ] Activity-based adjustments (more active = more food)
- [ ] Feeding schedule suggestions based on patterns
- [ ] Export feeding data for vet visits

---

## Quick Reference

**File Changes:**
- ✅ `models/feeding_log.dart` - Added portionSize field
- ✅ `services/firestore_service.dart` - Added daily tracking methods
- ✅ `dashboard_screen.dart` - Added validation and progress UI

**Test Values:**
```dart
dailyRecommendedPortion = 625.0  // grams per day
dailyMaxThreshold = 1.2          // 120% of recommended
manualPortionSize = 20.0         // default portion
```

**Thresholds:**
- 🟢 Safe: 0-499g (< 80%)
- 🔵 Approaching: 500-624g (80-99%)
- 🟠 At Limit: 625-749g (100-119%)
- 🔴 Exceeded: 750g+ (≥120%)
