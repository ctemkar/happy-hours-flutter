import { useState, useEffect, useRef } from 'react';
import { LocationOption } from '@/types';
import { LocationService } from '@/lib/locationService';
import { BookmarkService } from '@/lib/bookmarkService';

export function useLocationSelection() {
  const [selectedLocation, setSelectedLocation] = useState<LocationOption | null>(null);
  const [loading, setLoading] = useState(true);
  const mountedRef = useRef(true);

  useEffect(() => {
    mountedRef.current = true;
    loadSelectedLocation();

    return () => {
      mountedRef.current = false;
    };
  }, []);

  const loadSelectedLocation = async () => {
    try {
      const preferences = await BookmarkService.getUserPreferences();
      if (mountedRef.current && preferences.selectedLocationId) {
        const location = LocationService.getLocationById(preferences.selectedLocationId);
        if (location) {
          setSelectedLocation(location);
        }
      }
    } catch (error) {
      console.error('Error loading selected location:', error);
    } finally {
      if (mountedRef.current) {
        setLoading(false);
      }
    }
  };

  const selectLocation = async (location: LocationOption) => {
    if (!mountedRef.current) return;

    try {
      await BookmarkService.saveSelectedLocation(location.id);
      if (mountedRef.current) {
        setSelectedLocation(location);
      }
    } catch (error) {
      console.error('Error saving selected location:', error);
    }
  };

  const clearLocation = async () => {
    if (!mountedRef.current) return;

    try {
      const preferences = await BookmarkService.getUserPreferences();
      delete preferences.selectedLocationId;
      await BookmarkService.saveUserPreferences(preferences);
      if (mountedRef.current) {
        setSelectedLocation(null);
      }
    } catch (error) {
      console.error('Error clearing selected location:', error);
    }
  };

  return {
    selectedLocation,
    loading,
    selectLocation,
    clearLocation,
  };
}