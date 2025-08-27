# Symptom Suggestions System

## Overview

The symptom suggestions system provides intelligent suggestions when adding new health notes. It shows the 3 most recent unique symptom combinations based on major and minor components.

## New Symptom Structure

Each symptom now has four fields:
- **Major Component** (required): The primary symptom type (e.g., "headache", "nausea", "fatigue")
- **Minor Component** (optional): The specific location or subtype (e.g., "right temple", "vertigo", "mental")
- **Severity** (required): Level from 1-10
- **Additional Notes** (optional): Free text for additional details

## How It Works

### Suggestion Logic

1. **Data Collection**: The system analyzes all your previous health notes
2. **Chronological Sorting**: Notes are sorted by date (most recent first)
3. **Unique Combinations**: Only unique (major, minor) component pairs are considered
4. **Top 3 Selection**: The 3 most recent unique combinations are selected
5. **Severity Preservation**: The last used severity level for each combination is preserved

### Example

If you previously recorded:
- "headache - right temple" with severity 7
- "nausea" with severity 5  
- "dizziness - vertigo" with severity 4

When adding a new note, you'll see suggestions for:
1. "headache - right temple" (severity 7)
2. "nausea" (severity 5)
3. "dizziness - vertigo" (severity 4)

## User Interface

### Adding New Notes

When you create a new health note:
1. The suggestions appear above the first symptom field
2. Click any suggestion to auto-fill the symptom with the saved components and severity
3. You can still manually edit all fields after selecting a suggestion

### Form Layout

Each symptom entry now has:
1. **Major Component field**: Primary symptom type
2. **Minor Component field**: Specific location/subtype
3. **Severity field**: 1-10 scale
4. **Additional Notes field**: Free text for extra details

### Display Format

Symptoms are displayed in a user-friendly format:
- **With both components**: "headache - right temple"
- **Major only**: "nausea"
- **Minor only**: "right temple"
- **No components**: "Unnamed symptom"

## Technical Implementation

### Files Modified

- `lib/models/symptom.dart` - Updated to use major/minor components as primary fields
- `lib/services/symptom_suggestions_service.dart` - Core suggestion logic
- `lib/providers/symptom_suggestions_provider.dart` - Riverpod provider
- `lib/widgets/health_note_form_fields.dart` - UI integration with new fields
- `lib/screens/trends_screen.dart` - Updated to work with new structure
- `lib/services/search_service.dart` - Updated to search by major component

### Database Schema

The symptom model now includes:
```dart
@JsonKey(name: 'major_component') required String majorComponent,
@JsonKey(name: 'minor_component') @Default('') String minorComponent,
@JsonKey(name: 'severity_level') required int severityLevel,
@JsonKey(name: 'additional_notes') @Default('') String additionalNotes,
```

### Backward Compatibility

- Existing symptoms will be migrated to use major component as the primary field
- The system gracefully handles empty component fields
- No data migration required

## Benefits

1. **Faster Entry**: Quick selection of common symptoms
2. **Consistency**: Maintains consistent terminology across notes
3. **Context Preservation**: Remembers specific locations and subtypes
4. **Severity Memory**: Recalls your typical severity levels
5. **Flexibility**: Still allows manual entry for new symptoms
6. **Better Organization**: Clear separation between major/minor components and additional notes
