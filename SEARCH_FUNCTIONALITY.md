# Advanced Search Functionality

## Overview

The health notes app now features an advanced search system that provides more intelligent and flexible search capabilities compared to the previous simple text matching.

## How It Works

### Word-Based Search
Instead of looking for the entire search query as a single phrase, the search now:
1. **Breaks the query into individual words** - "headache pain medication" becomes ["headache", "pain", "medication"]
2. **Filters out very short words** - Words with 1 character or less are ignored
3. **Requires ALL words to be present** - Each word must be found somewhere across all searchable fields

### Stemming
The search uses the Porter Stemmer algorithm to match word variations:
- "headaches" matches "headache"
- "medications" matches "medication" 
- "running" matches "run"
- "better" matches "good" (in some cases)

### Multi-Field Search
The search looks across all relevant fields in a health note:
- **Symptoms** - The recorded symptoms
- **Notes** - Additional notes and observations
- **Drug Names** - Names of medications taken

## Search Examples

| Search Query | Will Match | Won't Match | Reason |
|--------------|------------|-------------|---------|
| "headache pain" | ✅ | | Both words found in symptoms |
| "aspirin medication" | ✅ | | "aspirin" in drugs, "medication" in notes |
| "headaches" | ✅ | | "headaches" stems to "headache" |
| "headache fever" | | ❌ | "fever" not found anywhere |
| "aspirin paracetamol" | | ❌ | "paracetamol" not found anywhere |
| "a b c" | ✅ | | Short words ignored, no search terms remain |

## Technical Implementation

- **Library**: Uses the `stemmer` package for Porter Stemmer algorithm
- **Service**: `SearchService` class handles all search logic
- **Integration**: Seamlessly integrated into the existing filter system
- **Performance**: Efficient word processing with minimal overhead

## Benefits

1. **More Intuitive**: Users can search with natural language
2. **Flexible Matching**: Handles word variations and plurals
3. **Comprehensive**: Searches across all relevant data fields
4. **Precise**: Requires all search terms to be present (AND logic)
5. **Fast**: Efficient implementation with minimal performance impact
