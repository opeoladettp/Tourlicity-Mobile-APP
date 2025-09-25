# Dropdown Gender Case Sensitivity Fix

## Problem
The app was crashing with this error:
```
There should be exactly one item with [DropdownButton]'s value: female.
Either zero or 2 or more [DropdownMenuItem]s were detected with the same value
```

## Root Cause
**Case Sensitivity Mismatch**: 
- **Database stores**: `"male"`, `"female"` (lowercase)
- **Dropdown expects**: `"Male"`, `"Female"` (capitalized)
- **User's current value**: `"male"` (from database)
- **Dropdown items**: `["Male", "Female", "Non-binary", "Prefer not to say"]`

When the dropdown tried to find the initial value `"male"`, it couldn't find an exact match with `"Male"`, causing the assertion error.

## Fix Applied

### 1. Added Gender Normalization Methods
```dart
/// Normalize gender value to match dropdown options (database → UI)
String? _normalizeGender(String? gender) {
  if (gender == null) return null;
  
  switch (gender.toLowerCase()) {
    case 'male': return 'Male';
    case 'female': return 'Female';
    case 'non-binary': return 'Non-binary';
    case 'prefer not to say': return 'Prefer not to say';
    default: return null;
  }
}

/// Convert display gender back to database format (UI → database)
String? _genderForDatabase(String? displayGender) {
  if (displayGender == null) return null;
  
  switch (displayGender) {
    case 'Male': return 'male';
    case 'Female': return 'female';
    case 'Non-binary': return 'non-binary';
    case 'Prefer not to say': return 'prefer not to say';
    default: return displayGender.toLowerCase();
  }
}
```

### 2. Updated Profile Initialization
```dart
// OLD CODE (problematic)
_selectedGender = user.gender;

// NEW CODE (fixed)
_selectedGender = _normalizeGender(user.gender);
```

### 3. Updated Profile Saving
```dart
// Convert back to database format when saving
gender: _genderForDatabase(_selectedGender),
```

## Data Flow

### Loading Profile:
1. **Database**: `"male"` 
2. **Normalize**: `"male"` → `"Male"`
3. **Dropdown**: Shows `"Male"` as selected ✅

### Saving Profile:
1. **Dropdown**: User selects `"Female"`
2. **Convert**: `"Female"` → `"female"`
3. **Database**: Saves `"female"` ✅

## Benefits
- ✅ **Fixes crash**: Dropdown now finds exact matches
- ✅ **Maintains consistency**: Database format stays lowercase
- ✅ **User-friendly**: UI shows proper capitalization
- ✅ **Backward compatible**: Handles existing data correctly

## Files Modified
- `lib/screens/auth/profile_update_screen.dart`
  - Added `_normalizeGender()` method
  - Added `_genderForDatabase()` method
  - Updated profile initialization
  - Updated profile saving

## Testing
The app should now:
1. **Load correctly** with existing gender data
2. **Display proper capitalization** in dropdown
3. **Save in correct format** to database
4. **Handle all gender options** without crashes

## Prevention
This type of issue can be prevented by:
1. **Consistent data formats** across frontend/backend
2. **Input validation** and normalization
3. **Case-insensitive comparisons** where appropriate
4. **Clear API documentation** for data formats