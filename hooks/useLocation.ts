import { useState, useEffect, useRef } from 'react';
import * as Location from 'expo-location';
import { Platform } from 'react-native';

export interface LocationData {
  latitude: number;
  longitude: number;
  address?: string;
  city?: string;
  country?: string;
}

export function useLocation() {
  const [location, setLocation] = useState<LocationData | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const mountedRef = useRef(true);
  const timeoutRef = useRef<NodeJS.Timeout | null>(null);

  // Cleanup function
  const cleanup = () => {
    if (timeoutRef.current) {
      clearTimeout(timeoutRef.current);
      timeoutRef.current = null;
    }
  };

  const getCurrentLocation = async () => {
    if (!mountedRef.current) return;
    
    setLoading(true);
    setError(null);
    cleanup();

    // Set a timeout to prevent hanging
    timeoutRef.current = setTimeout(() => {
      if (mountedRef.current) {
        setError('Location request timed out');
        setLoading(false);
      }
    }, 15000);

    try {
      if (Platform.OS === 'web') {
        // Use browser geolocation API for web
        if (navigator.geolocation) {
          const promise = new Promise<GeolocationPosition>((resolve, reject) => {
            navigator.geolocation.getCurrentPosition(
              resolve,
              reject,
              { 
                enableHighAccuracy: false, // Reduce accuracy for faster response
                timeout: 10000, 
                maximumAge: 300000 // 5 minutes cache
              }
            );
          });

          const position = await promise;
          
          if (!mountedRef.current) return;
          
          const coords = {
            latitude: position.coords.latitude,
            longitude: position.coords.longitude,
          };
          
          // Get address from coordinates with error handling
          try {
            const address = await reverseGeocode(coords.latitude, coords.longitude);
            if (mountedRef.current) {
              setLocation({ ...coords, ...address });
            }
          } catch (geocodeError) {
            console.warn('Reverse geocoding failed:', geocodeError);
            if (mountedRef.current) {
              setLocation(coords);
            }
          }
        } else {
          if (mountedRef.current) {
            setError('Geolocation is not supported by this browser');
          }
        }
      } else {
        // Use Expo Location for mobile with enhanced error handling
        try {
          const { status } = await Location.requestForegroundPermissionsAsync();
          if (!mountedRef.current) return;
          
          if (status !== 'granted') {
            setError('Location permission denied');
            return;
          }

          const position = await Location.getCurrentPositionAsync({
            accuracy: Location.Accuracy.Balanced, // Use balanced instead of high for stability
            timeInterval: 10000,
            distanceInterval: 0,
          });

          if (!mountedRef.current) return;

          const coords = {
            latitude: position.coords.latitude,
            longitude: position.coords.longitude,
          };

          // Get address from coordinates with error handling
          try {
            const address = await reverseGeocode(coords.latitude, coords.longitude);
            if (mountedRef.current) {
              setLocation({ ...coords, ...address });
            }
          } catch (geocodeError) {
            console.warn('Reverse geocoding failed:', geocodeError);
            if (mountedRef.current) {
              setLocation(coords);
            }
          }
        } catch (locationError) {
          console.error('Location error:', locationError);
          if (mountedRef.current) {
            setError('Failed to get location');
          }
        }
      }
    } catch (err) {
      if (!mountedRef.current) return;
      
      console.error('Location error:', err);
      setError('Failed to get location');
    } finally {
      cleanup();
      if (mountedRef.current) {
        setLoading(false);
      }
    }
  };

  const reverseGeocode = async (lat: number, lng: number) => {
    try {
      if (Platform.OS !== 'web') {
        // Use Expo Location reverse geocoding for mobile with timeout
        const timeoutPromise = new Promise((_, reject) => {
          setTimeout(() => reject(new Error('Geocoding timeout')), 5000);
        });

        const geocodePromise = Location.reverseGeocodeAsync({ 
          latitude: lat, 
          longitude: lng 
        });

        const result = await Promise.race([geocodePromise, timeoutPromise]) as any[];
        
        if (result && result.length > 0) {
          const location = result[0];
          return {
            address: `${location.street || ''} ${location.streetNumber || ''}`.trim(),
            city: location.city || location.subregion || '',
            country: location.country || '',
          };
        }
      } else {
        // Use a geocoding service for web with timeout
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 5000);

        try {
          const response = await fetch(
            `https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=${lat}&longitude=${lng}&localityLanguage=en`,
            { signal: controller.signal }
          );
          
          clearTimeout(timeoutId);
          
          if (response.ok) {
            const data = await response.json();
            return {
              address: data.locality || '',
              city: data.city || data.principalSubdivision || '',
              country: data.countryName || '',
            };
          }
        } catch (fetchError) {
          clearTimeout(timeoutId);
          throw fetchError;
        }
      }
    } catch (error) {
      console.warn('Reverse geocoding error:', error);
      // Return empty object instead of throwing
      return {};
    }
    return {};
  };

  useEffect(() => {
    mountedRef.current = true;

    return () => {
      mountedRef.current = false;
      cleanup();
    };
  }, []);

  return {
    location,
    loading,
    error,
    getCurrentLocation,
  };
}