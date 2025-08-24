# My Tools Feature

## Overview

The "My Tools" feature is a comprehensive health management system that allows you to organize and access your personal health procedures, coping strategies, and remedies for different health issues. It's designed to be easily customizable as you work through therapy and discover new tools that work for you.

## Features

### 🏷️ **Health Tool Categories**
- **Organized by Issue**: Categories like Allergies, Anxiety, Nausea, Cold & Flu, Travel, etc.
- **Visual Design**: Each category has a custom icon and color for easy identification
- **Flexible**: Add, edit, or remove categories as your needs evolve

### 🛠️ **Health Tools**
- **Detailed Descriptions**: Each tool includes step-by-step instructions
- **Categorized**: Tools are organized under relevant health categories
- **Easy Access**: Quick access to your go-to procedures when you need them most

### 📱 **User Interface**
- **Intuitive Navigation**: Clean, organized interface following iOS design patterns
- **Quick Actions**: Add new tools and categories with just a few taps
- **Search & Browse**: Easy to find the right tool when you need it

## Setup Instructions

### 1. Database Setup

Run the SQL script in your Supabase SQL editor:

```sql
-- Copy and paste the contents of database_setup_health_tools.sql
-- This will create the necessary tables, indexes, and security policies
```

### 2. Default Data

The setup script includes some default categories and tools to get you started:

**Categories:**
- Allergies (Orange)
- Anxiety (Red) 
- Nausea (Green)
- Cold & Flu (Blue)
- Travel (Purple)
- Car Travel (Pink)
- Plane Travel (Yellow)

**Example Tools:**
- **Allergies**: Flonase, Albuterol Inhaler
- **Anxiety**: Lorazepam, 54321 Senses Exercise, Move the Shape Exercise, Deep Breathing, Yoga, Go for a Walk, Warm Shower
- **Nausea**: Ginger Tea, Acupressure

### 3. App Integration

The feature is already integrated into your app with:
- New "My Tools" tab in the bottom navigation
- Full CRUD operations for categories and tools
- Proper state management with Riverpod
- Database integration with Supabase

## How to Use

### Adding New Categories

1. Tap the "My Tools" tab
2. Tap the "+" button in the top right
3. Fill in:
   - **Category Name**: e.g., "Migraines", "Insomnia"
   - **Description**: What this category is for
   - **Icon**: Choose from predefined options
   - **Color**: Pick a color for visual identification
4. Tap "Save"

### Adding New Tools

1. Navigate to a category
2. Tap the "+" button
3. Fill in:
   - **Tool Name**: e.g., "Triptan Medication", "Progressive Muscle Relaxation"
   - **Description**: Detailed instructions on how to use the tool
   - **Category**: Select which category this tool belongs to
4. Tap "Save"

### Managing Your Tools

- **View**: Tap on any tool to see full details
- **Edit**: Tap "Edit" in the tool details to modify
- **Delete**: Tap "Delete" in the tool details to remove
- **Reorder**: Tools are automatically sorted by creation order

## Customization Ideas

### Therapy Integration
As you work with your therapist, you can add:
- **Grounding Techniques**: 5-4-3-2-1 exercise, body scans
- **Breathing Exercises**: Box breathing, 4-7-8 technique
- **Physical Tools**: Progressive muscle relaxation, yoga poses
- **Medication Reminders**: Dosage, timing, side effects to watch for

### Travel Preparation
- **Car Travel**: Motion sickness remedies, comfort items
- **Plane Travel**: Ear pressure techniques, anxiety management
- **General Travel**: First aid items, emergency contacts

### Health Conditions
- **Allergies**: Medication schedules, trigger avoidance
- **Chronic Conditions**: Flare-up management, symptom tracking
- **Mental Health**: Crisis management, daily wellness routines

## Technical Details

### Database Schema

**health_tool_categories:**
- `id`: Unique identifier
- `name`: Category name
- `description`: Category description
- `icon_name`: Icon identifier
- `color_hex`: Color code
- `sort_order`: Display order
- `is_active`: Whether category is active
- `user_id`: Owner of the category

**health_tools:**
- `id`: Unique identifier
- `name`: Tool name
- `description`: Detailed instructions
- `category_id`: Reference to category
- `sort_order`: Display order
- `is_active`: Whether tool is active
- `user_id`: Owner of the tool

### Security
- Row Level Security (RLS) ensures users only see their own data
- Automatic user_id assignment on insert
- Proper authentication integration

### State Management
- Riverpod for reactive state management
- Automatic UI updates when data changes
- Error handling and loading states

## Future Enhancements

Potential features you could add:
- **Favorites**: Mark frequently used tools
- **Usage Tracking**: Log when you use a tool
- **Effectiveness Rating**: Rate how well tools work for you
- **Reminders**: Set up medication or exercise reminders
- **Sharing**: Share tools with healthcare providers
- **Backup**: Export/import your tools
- **Search**: Find tools quickly across all categories

## Support

If you need help with:
- **Database setup**: Check the SQL script comments
- **Adding tools**: Use the built-in forms
- **Customization**: Modify the predefined categories and tools
- **Technical issues**: Check the Flutter/Riverpod documentation

The My Tools feature is designed to grow with you as your health journey evolves. Start with the basics and add more tools as you discover what works best for you!
