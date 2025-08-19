export interface Business {
  id: string;
  name: string;
  description: string;
  image: string;
  location: {
    latitude: number;
    longitude: number;
    address: string;
  };
  category: string;
  rating: number;
  currentDiscount?: Discount;
  isActive: boolean;
  isBookmarked?: boolean;
  isVerified?: boolean; // NEW: Mark verified businesses
  verificationData?: VerificationData; // NEW: Store verification details
}

export interface VerificationData {
  source: 'spreadsheet' | 'manual' | 'api';
  verifiedAt: string;
  verifiedBy?: string;
  originalData?: any; // Store original spreadsheet data
  googleMarker?: string;
  logo?: string;
  telephone?: string;
  website?: string;
  remarks?: string;
  lastUpdate?: string;
}

export interface SpreadsheetRow {
  name: string;
  description: string;
  address: string;
  googleMarker?: string;
  picture?: string;
  logo?: string;
  open?: string;
  happyHourStart?: string;
  happyHourEnd?: string;
  telephone?: string;
  remark?: string;
  update?: string;
}

export interface Discount {
  id: string;
  businessId: string;
  title: string;
  description: string;
  percentage: number;
  validFrom: string;
  validTo: string;
  isActive: boolean;
}

export interface LocationOption {
  id: string;
  name: string;
  country: string;
  coordinates: {
    latitude: number;
    longitude: number;
  };
  timezone: string;
  isPopular?: boolean;
}

export interface UserPreferences {
  selectedLocation: LocationOption | null;
  bookmarkedPlaces: string[];
  favoriteCategories: string[];
}

export interface AppState {
  businesses: Business[];
  discounts: Discount[];
  userLocation: {
    latitude: number;
    longitude: number;
  } | null;
  selectedLocation: LocationOption | null;
  userPreferences: UserPreferences;
  isLoading: boolean;
  error: string | null;
}