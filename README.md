# School Scout

## Overview
School Scout is a mobile application developed in Flutter that allows users to search for, view details of, and save favorite schools. The app integrates with Supabase for data management and OpenWeatherMap for real-time weather information.
> Note: This application requires valid Supabase and weather API credentials to enable full functionality. Without these, the app will run but core features will be limited.

### Development Credits
This project was architected and structured by me. 
- **Core Logic**: The `models` and `services` layers were implemented by me to ensure robust data handling and business logic.
- **UI Components**: The user interface and other components were developed with assistance from LLMs to accelerate prototyping.

### Current Status
- **Search**: Fully functional school search and map view.
- **Detail View**: View school information, weather, and nearby places.
- **Favorites**: 
    - You can add schools to your favorites list.
    - You can view the list of your favorite schools.
    - *Note*: Navigation from the Favorites list to the School Detail view is currently under development and may not be fully functional in this build.

## Features

- Search schools by name
- View detailed school information
- Discover nearby places (cafes, parks, libraries)
- View weather data for a school’s location
- Save favorite schools
- Map-based visualization using OpenStreetMap

### Services & API Integration
- `lib/services/`
  - Supabase: Database connections and custom SQL-based search queries
  - Weather: Manually constructed API request URLs for full control
  - OpenStreetMap / Overpass API: Manual parsing of node-based location data

## Installation & Setup

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed and configured.
- A `.env` file with valid API keys.

### Step 1: Clone & Install Dependencies
Navigate to the project directory and run:

```bash
flutter pub get
```

### Step 2: Configure Environment
Create a file named `.env` in the root directory (if not already present) and add the following keys:

```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
OPENWEATHER_API_KEY=your_openweather_api_key
```

### Step 3: Run the Application
Connect a device or start an emulator, then run:

```bash
flutter run
```

## Testing Guide

1.  **Search**: Open the app and type a school name in the search bar (e.g., "Lincoln"). Verify results appear.
2.  **View Details**: Tap a school from the search results to see detailed information tabs (Info, Map, Weather).
3.  **Add Favorite**: Tap the heart icon in the top right of the detail screen. A snackbar should confirm "Updated favorites!".
4.  **View Favorites**: Go back to the search screen and tap the heart icon in the app bar. Verify your saved school appears in the list.

## Troubleshooting

- **No search results**: Ensure Supabase tables and RLS policies are correctly configured and populated.
- **Weather not loading**: Verify the OpenWeather API key is active (keys may take time to activate).
- **Favorites not saving**: Confirm authentication and Row Level Security policies are enabled in Supabase.

