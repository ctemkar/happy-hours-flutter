# Happy Arz - Happy Hour Discovery App

A React Native Expo app for discovering happy hours and discounts at restaurants, bars, and venues worldwide.

## Features

- 🌍 **Global Location Support** - Browse businesses in major cities worldwide
- 🍻 **Happy Hour Discovery** - Find active and scheduled happy hour deals
- 📍 **Location-Based Search** - Use GPS or select cities manually
- ✅ **Verified Businesses** - Upload and manage verified business data
- 🔍 **Google Places Integration** - Real business data from Google Places API
- 📱 **Cross-Platform** - Works on iOS, Android, and Web
- 🎨 **Beautiful UI** - Modern design with smooth animations

## Tech Stack

- **Framework**: Expo SDK 53.0.0 with Expo Router 4.0.17
- **Language**: TypeScript
- **Styling**: React Native StyleSheet
- **Navigation**: Expo Router (file-based routing)
- **Storage**: AsyncStorage / localStorage
- **APIs**: Google Places API
- **Icons**: Lucide React Native

## Getting Started

### Prerequisites

- Node.js 18+ 
- Expo CLI
- Google Places API key (optional, for real business data)

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   npm install
   ```

3. Set up environment variables (optional):
   ```bash
   # Create .env file
   EXPO_PUBLIC_GOOGLE_PLACES_API_KEY=your_google_places_api_key
   ```

4. Start the development server:
   ```bash
   npm start
   ```

## Project Structure

```
app/
├── (tabs)/           # Tab-based navigation
│   ├── index.tsx     # Discover screen
│   ├── map.tsx       # Map view
│   ├── saved.tsx     # Saved places
│   ├── scanner.tsx   # Menu scanner
│   ├── admin.tsx     # Admin panel
│   └── profile.tsx   # User profile
├── business/         # Business detail pages
└── api/             # API routes

components/          # Reusable components
├── LocationSelector.tsx
├── DataCollectionHelper.tsx
└── ApiTester.tsx

lib/                # Services and utilities
├── placesService.ts
├── verifiedBusinessService.ts
├── locationService.ts
└── bookmarkService.ts

constants/          # Theme and constants
└── theme.ts

types/             # TypeScript definitions
└── index.ts
```

## Key Features

### 1. Business Discovery
- Browse businesses by location and category
- Real-time happy hour status
- Distance-based sorting
- Search functionality

### 2. Admin Panel
- Upload business data via CSV/TSV files
- Google Places API testing
- Data collection helper
- Upload history tracking

### 3. Location Management
- 50+ pre-configured cities worldwide
- GPS location support
- Manual city selection
- Time zone aware

### 4. Data Management
- Verified business database
- Bookmark system
- User preferences
- Offline storage

## Image Optimization

All images use WebP format with optimized parameters:
- Format: WebP
- Quality: 80%
- Dimensions: 600x400px
- Compression: Enabled

Example URL format:
```
https://images.pexels.com/photos/[id]/[filename].jpeg?auto=compress&cs=tinysrgb&w=600&h=400&fit=crop&fm=webp&q=80
```

## File Size Optimization

The app has been optimized for minimal size:
- ✅ WebP images for better compression
- ✅ Removed cache directories
- ✅ Removed build artifacts
- ✅ Optimized dependencies
- ✅ Cleaned temporary files

## Environment Variables

```bash
# Google Places API (optional)
EXPO_PUBLIC_GOOGLE_PLACES_API_KEY=your_api_key

# API URL (if using custom backend)
EXPO_PUBLIC_API_URL=https://your-api.com
```

## Building for Production

### Web
```bash
npm run build:web
```

### Mobile (requires Expo account)
```bash
npx expo build:android
npx expo build:ios
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License.

## Support

For support or questions, please open an issue on GitHub.