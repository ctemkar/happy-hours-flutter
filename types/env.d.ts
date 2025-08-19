declare global {
  namespace NodeJS {
    interface ProcessEnv {
      EXPO_PUBLIC_GOOGLE_PLACES_API_KEY?: string;
      EXPO_PUBLIC_API_URL?: string;
    }
  }
}

// Ensure this file is treated as a module
export {};