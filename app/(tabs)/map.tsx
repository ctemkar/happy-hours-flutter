import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  SafeAreaView,
  TouchableOpacity,
  Alert,
  Platform,
  ScrollView,
  RefreshControl,
  ActivityIndicator,
} from 'react-native';
import { MapPin, Navigation, Star, Clock } from 'lucide-react-native';
import { colors, typography, spacing, borderRadius, shadows } from '@/constants/theme';
import { useLocation } from '@/hooks/useLocation';
import { useLocationSelection } from '@/hooks/useLocationSelection';
import { PlacesService } from '@/lib/placesService';
import { LocationService } from '@/lib/locationService';
import { Business } from '@/types';
import { router } from 'expo-router';

export default function MapScreen() {
  const [selectedBusiness, setSelectedBusiness] = useState<any>(null);
  const [nearbyPlaces, setNearbyPlaces] = useState<Business[]>([]);
  const [loading, setLoading] = useState(false);
  const [refreshing, setRefreshing] = useState(false);
  
  const { location, loading: locationLoading, getCurrentLocation } = useLocation();
  const { selectedLocation } = useLocationSelection();

  // Use selected location or current location
  const activeLocation = selectedLocation 
    ? {
        latitude: selectedLocation.coordinates.latitude,
        longitude: selectedLocation.coordinates.longitude,
        city: selectedLocation.name,
      }
    : location;

  useEffect(() => {
    if (activeLocation) {
      loadNearbyPlaces();
    }
  }, [activeLocation]);

  const loadNearbyPlaces = async () => {
    if (!activeLocation) return;

    setLoading(true);
    try {
      // Get all places from PlacesService (includes verified businesses and API data)
      const places = await PlacesService.searchNearbyPlaces({
        latitude: activeLocation.latitude,
        longitude: activeLocation.longitude,
        radius: 50000, // 50km radius for map view
      });

      // Show ALL active businesses, not just those with discounts
      const activePlaces = places.filter(business => business.isActive);

      console.log(`Map: Found ${activePlaces.length} active businesses in ${getLocationDisplayName()}`);
      setNearbyPlaces(activePlaces);
    } catch (error) {
      console.error('Error loading places:', error);
      Alert.alert('Error', 'Unable to load places. Please check your internet connection.');
      setNearbyPlaces([]);
    } finally {
      setLoading(false);
    }
  };

  const onRefresh = async () => {
    setRefreshing(true);
    if (activeLocation) {
      await loadNearbyPlaces();
    } else if (!selectedLocation) {
      await getCurrentLocation();
    }
    setRefreshing(false);
  };

  const calculateDistance = (lat1: number, lon1: number, lat2: number, lon2: number) => {
    const R = 6371; // Earth's radius in kilometers
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLon = (lon2 - lon1) * Math.PI / 180;
    const a = 
      Math.sin(dLat/2) * Math.sin(dLat/2) +
      Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * 
      Math.sin(dLon/2) * Math.sin(dLon/2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
    return R * c;
  };

  // Show ALL businesses, prioritize those with discounts
  const businessesWithDiscounts = nearbyPlaces.filter(business => 
    business.currentDiscount && business.isActive
  );

  const businessesWithoutDiscounts = nearbyPlaces.filter(business => 
    !business.currentDiscount && business.isActive
  );

  // Only show distance when using GPS location, not when browsing other cities
  const shouldShowDistance = () => {
    return location && !selectedLocation;
  };

  const addDistanceToBusinesses = (businesses: Business[]) => {
    if (!shouldShowDistance() || !location) return businesses;
    
    return businesses.map(business => ({
      ...business,
      distance: calculateDistance(
        location.latitude,
        location.longitude,
        business.location.latitude,
        business.location.longitude
      )
    })).sort((a: any, b: any) => a.distance - b.distance);
  };

  const businessesWithDiscountsAndDistance = addDistanceToBusinesses(businessesWithDiscounts);
  const businessesWithoutDiscountsAndDistance = addDistanceToBusinesses(businessesWithoutDiscounts);

  const handleBusinessPress = (business: Business) => {
    router.push({
      pathname: '/business/[id]',
      params: { 
        id: business.id,
        name: business.name,
        description: business.description,
        image: business.image,
        address: business.location.address,
        rating: business.rating.toString(),
        category: business.category,
        discountTitle: business.currentDiscount?.title || '',
        discountPercentage: business.currentDiscount?.percentage?.toString() || '',
        discountDescription: business.currentDiscount?.description || '',
        validFrom: business.currentDiscount?.validFrom || '',
        validTo: business.currentDiscount?.validTo || '',
        isDiscountActive: business.currentDiscount?.isActive?.toString() || 'false'
      }
    });
  };

  // Get location display name
  const getLocationDisplayName = () => {
    if (selectedLocation) {
      return LocationService.getLocationDisplayName(selectedLocation);
    }
    
    if (!activeLocation) return 'your area';
    
    // Extract city from location if available
    if (activeLocation.city) {
      return activeLocation.city;
    }
    
    // Fallback to coordinates-based city detection
    const lat = activeLocation.latitude;
    const lng = activeLocation.longitude;
    
    // Major city coordinate ranges (approximate)
    if (lat >= 40.4774 && lat <= 40.9176 && lng >= -74.2591 && lng <= -73.7004) return 'New York';
    if (lat >= 33.7037 && lat <= 34.3373 && lng >= -118.6681 && lng <= -118.1553) return 'Los Angeles';
    if (lat >= 51.2868 && lat <= 51.6918 && lng >= -0.5103 && lng <= 0.3340) return 'London';
    if (lat >= 48.8155 && lat <= 48.9021 && lng >= 2.2241 && lng <= 2.4699) return 'Paris';
    if (lat >= 35.5322 && lat <= 35.8986 && lng >= 139.3431 && lng <= 139.9194) return 'Tokyo';
    if (lat >= -34.1692 && lat <= -33.5781 && lng >= 150.5023 && lng <= 151.3430) return 'Sydney';
    if (lat >= 13.4980 && lat <= 14.0990 && lng >= 100.3273 && lng <= 100.9319) return 'Bangkok';
    if (lat >= 12.8000 && lat <= 13.0000 && lng >= 100.8000 && lng <= 101.0000) return 'Pattaya';
    
    return 'your area';
  };

  // Helper function to check if a discount is currently active based on time
  const isDiscountCurrentlyActive = (discount: any): boolean => {
    if (!discount || !discount.isActive) return false;
    
    const now = new Date();
    const currentTime = now.getHours() * 60 + now.getMinutes(); // Current time in minutes
    
    // Parse time strings (e.g., "17:00" -> 1020 minutes)
    const parseTime = (timeStr: string): number => {
      if (!timeStr) return 0;
      const [hours, minutes] = timeStr.split(':').map(Number);
      return hours * 60 + (minutes || 0);
    };
    
    const startTime = parseTime(discount.validFrom);
    const endTime = parseTime(discount.validTo);
    
    // Handle cases where end time is next day (e.g., 23:00 to 02:00)
    if (endTime < startTime) {
      return currentTime >= startTime || currentTime <= endTime;
    }
    
    return currentTime >= startTime && currentTime <= endTime;
  };

  const renderBusinessItem = (business: any, hasDiscount: boolean) => {
    const isCurrentlyActive = hasDiscount && isDiscountCurrentlyActive(business.currentDiscount);
    
    return (
      <TouchableOpacity
        key={business.id}
        style={[
          styles.businessItem,
          selectedBusiness?.id === business.id && styles.businessItemSelected,
          isCurrentlyActive && styles.businessItemActive,
          !hasDiscount && styles.businessItemNoDiscount
        ]}
        onPress={() => {
          setSelectedBusiness(business);
          handleBusinessPress(business);
        }}
      >
        <View style={styles.businessInfo}>
          <View style={styles.businessHeader}>
            <Text style={styles.businessName}>{business.name}</Text>
            <View style={styles.businessBadges}>
              {business.isVerified && (
                <View style={styles.verifiedBadge}>
                  <Text style={styles.verifiedText}>✓</Text>
                </View>
              )}
              {isCurrentlyActive && (
                <View style={styles.activeNowBadge}>
                  <Text style={styles.activeNowText}>ACTIVE NOW</Text>
                </View>
              )}
              {hasDiscount && !isCurrentlyActive && (
                <View style={styles.scheduledBadge}>
                  <Text style={styles.scheduledText}>SCHEDULED</Text>
                </View>
              )}
            </View>
          </View>
          <Text style={styles.businessCategory}>{business.category}</Text>
          <View style={styles.businessMeta}>
            <View style={styles.ratingContainer}>
              <Star size={14} color={colors.warning[500]} fill={colors.warning[500]} />
              <Text style={styles.rating}>{business.rating.toFixed(1)}</Text>
            </View>
            {shouldShowDistance() && location && 'distance' in business && (
              <Text style={styles.distance}>
                {business.distance.toFixed(1)} km away
              </Text>
            )}
          </View>
          {hasDiscount && business.currentDiscount && (
            <View style={styles.discountContainer}>
              <View style={[
                styles.discountBadge,
                isCurrentlyActive ? styles.discountBadgeActive : styles.discountBadgeInactive
              ]}>
                <Text style={styles.discountText}>
                  {business.currentDiscount.percentage}% OFF
                </Text>
              </View>
              <View style={styles.discountInfo}>
                <Text style={styles.discountTitle}>{business.currentDiscount.title}</Text>
                <View style={styles.timeContainer}>
                  <Clock size={12} color={colors.secondary[500]} />
                  <Text style={[
                    styles.timeText,
                    isCurrentlyActive && styles.timeTextActive
                  ]}>
                    {business.currentDiscount.validFrom} - {business.currentDiscount.validTo}
                    {isCurrentlyActive && ' (Active Now!)'}
                  </Text>
                </View>
              </View>
            </View>
          )}
        </View>
        <MapPin size={24} color={colors.primary[500]} />
      </TouchableOpacity>
    );
  };

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <View style={styles.headerContent}>
          <Text style={styles.headerTitle}>Business Map</Text>
          <Text style={styles.headerSubtitle}>
            {activeLocation 
              ? `${nearbyPlaces.length} businesses in ${getLocationDisplayName()}`
              : 'Businesses nearby'
            }
          </Text>
        </View>
        <TouchableOpacity 
          style={styles.locationButton} 
          onPress={getCurrentLocation}
          disabled={locationLoading}
        >
          {locationLoading ? (
            <ActivityIndicator size="small" color={colors.primary[500]} />
          ) : (
            <Navigation size={20} color={colors.primary[500]} />
          )}
        </TouchableOpacity>
      </View>

      <View style={styles.mapPlaceholder}>
        <MapPin size={48} color={colors.primary[500]} />
        <Text style={styles.mapPlaceholderText}>Interactive Map View</Text>
        <Text style={styles.mapPlaceholderSubtext}>
          {activeLocation 
            ? `Exploring: ${getLocationDisplayName()}`
            : locationLoading 
              ? 'Getting your location...'
              : 'Location not available'
          }
        </Text>
        {activeLocation && (
          <Text style={styles.coordinatesText}>
            {activeLocation.latitude.toFixed(4)}, {activeLocation.longitude.toFixed(4)}
          </Text>
        )}
      </View>

      <View style={styles.businessList}>
        <Text style={styles.listTitle}>
          All Businesses {activeLocation && `(${nearbyPlaces.length})`}
        </Text>
        
        <ScrollView 
          showsVerticalScrollIndicator={false}
          refreshControl={
            <RefreshControl
              refreshing={refreshing}
              onRefresh={onRefresh}
              colors={[colors.primary[500]]}
              tintColor={colors.primary[500]}
            />
          }
        >
          {loading && (
            <View style={styles.loadingContainer}>
              <ActivityIndicator size="large" color={colors.primary[500]} />
              <Text style={styles.loadingText}>Loading businesses...</Text>
            </View>
          )}

          {!activeLocation && !locationLoading && (
            <View style={styles.emptyContainer}>
              <Navigation size={32} color={colors.secondary[400]} />
              <Text style={styles.emptyText}>Location needed</Text>
              <Text style={styles.emptySubtext}>
                Choose a location to see businesses
              </Text>
              <TouchableOpacity style={styles.enableLocationButton} onPress={getCurrentLocation}>
                <Text style={styles.enableLocationButtonText}>Enable Location</Text>
              </TouchableOpacity>
            </View>
          )}

          {nearbyPlaces.length === 0 && !loading && activeLocation && (
            <View style={styles.emptyContainer}>
              <Text style={styles.emptyText}>No businesses found</Text>
              <Text style={styles.emptySubtext}>
                No businesses found in {getLocationDisplayName()}. Upload business data via the Admin panel or configure your Google Places API key to see real businesses.
              </Text>
            </View>
          )}

          {/* Businesses with Happy Hours */}
          {businessesWithDiscountsAndDistance.length > 0 && (
            <>
              <View style={styles.sectionHeader}>
                <Text style={styles.sectionTitle}>
                  Happy Hours ({businessesWithDiscountsAndDistance.length})
                </Text>
              </View>
              {businessesWithDiscountsAndDistance.map((business) => 
                renderBusinessItem(business, true)
              )}
            </>
          )}

          {/* Other Businesses */}
          {businessesWithoutDiscountsAndDistance.length > 0 && (
            <>
              <View style={styles.sectionHeader}>
                <Text style={styles.sectionTitle}>
                  Other Businesses ({businessesWithoutDiscountsAndDistance.length})
                </Text>
              </View>
              {businessesWithoutDiscountsAndDistance.map((business) => 
                renderBusinessItem(business, false)
              )}
            </>
          )}
        </ScrollView>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.white,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: spacing.lg,
    paddingTop: spacing.lg,
    paddingBottom: spacing.md,
  },
  headerContent: {
    flex: 1,
  },
  headerTitle: {
    fontSize: typography.fontSize['3xl'],
    fontFamily: typography.fontFamily.heading,
    color: colors.secondary[900],
  },
  headerSubtitle: {
    fontSize: typography.fontSize.base,
    fontFamily: typography.fontFamily.regular,
    color: colors.secondary[600],
    marginTop: spacing.xs,
  },
  locationButton: {
    padding: spacing.sm,
    backgroundColor: colors.primary[50],
    borderRadius: borderRadius.full,
    borderWidth: 1,
    borderColor: colors.primary[200],
  },
  mapPlaceholder: {
    height: 250,
    backgroundColor: colors.secondary[50],
    justifyContent: 'center',
    alignItems: 'center',
    marginHorizontal: spacing.lg,
    borderRadius: borderRadius.xl,
    marginBottom: spacing.lg,
    borderWidth: 2,
    borderColor: colors.secondary[200],
    borderStyle: 'dashed',
  },
  mapPlaceholderText: {
    fontSize: typography.fontSize.lg,
    fontFamily: typography.fontFamily.semibold,
    color: colors.secondary[700],
    marginTop: spacing.sm,
  },
  mapPlaceholderSubtext: {
    fontSize: typography.fontSize.sm,
    fontFamily: typography.fontFamily.regular,
    color: colors.secondary[500],
    marginTop: spacing.xs,
    textAlign: 'center',
  },
  coordinatesText: {
    fontSize: typography.fontSize.xs,
    fontFamily: typography.fontFamily.regular,
    color: colors.secondary[400],
    marginTop: spacing.xs,
  },
  businessList: {
    flex: 1,
    paddingHorizontal: spacing.lg,
  },
  listTitle: {
    fontSize: typography.fontSize.xl,
    fontFamily: typography.fontFamily.bold,
    color: colors.secondary[900],
    marginBottom: spacing.md,
  },
  sectionHeader: {
    marginTop: spacing.lg,
    marginBottom: spacing.md,
  },
  sectionTitle: {
    fontSize: typography.fontSize.lg,
    fontFamily: typography.fontFamily.bold,
    color: colors.secondary[800],
  },
  loadingContainer: {
    alignItems: 'center',
    paddingVertical: spacing.lg,
  },
  loadingText: {
    fontSize: typography.fontSize.base,
    fontFamily: typography.fontFamily.medium,
    color: colors.secondary[600],
    marginTop: spacing.sm,
  },
  emptyContainer: {
    alignItems: 'center',
    paddingVertical: spacing.xl,
  },
  emptyText: {
    fontSize: typography.fontSize.lg,
    fontFamily: typography.fontFamily.semibold,
    color: colors.secondary[700],
    marginTop: spacing.sm,
    marginBottom: spacing.xs,
  },
  emptySubtext: {
    fontSize: typography.fontSize.base,
    fontFamily: typography.fontFamily.regular,
    color: colors.secondary[500],
    textAlign: 'center',
    marginBottom: spacing.lg,
  },
  enableLocationButton: {
    backgroundColor: colors.primary[500],
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.md,
    borderRadius: borderRadius.lg,
  },
  enableLocationButtonText: {
    fontSize: typography.fontSize.base,
    fontFamily: typography.fontFamily.semibold,
    color: colors.white,
  },
  businessItem: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.white,
    padding: spacing.md,
    borderRadius: borderRadius.lg,
    marginBottom: spacing.sm,
    ...shadows.sm,
  },
  businessItemSelected: {
    backgroundColor: colors.primary[50],
    borderWidth: 2,
    borderColor: colors.primary[200],
  },
  businessItemActive: {
    backgroundColor: colors.success[50],
    borderWidth: 2,
    borderColor: colors.success[200],
  },
  businessItemNoDiscount: {
    backgroundColor: colors.secondary[25],
  },
  businessInfo: {
    flex: 1,
    marginRight: spacing.md,
  },
  businessHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: spacing.xs,
  },
  businessName: {
    fontSize: typography.fontSize.base,
    fontFamily: typography.fontFamily.semibold,
    color: colors.secondary[900],
    flex: 1,
    marginRight: spacing.sm,
  },
  businessBadges: {
    flexDirection: 'row',
    gap: spacing.xs,
  },
  verifiedBadge: {
    backgroundColor: colors.primary[500],
    paddingHorizontal: spacing.xs,
    paddingVertical: 2,
    borderRadius: borderRadius.sm,
    minWidth: 20,
    alignItems: 'center',
  },
  verifiedText: {
    fontSize: typography.fontSize.xs,
    fontFamily: typography.fontFamily.bold,
    color: colors.white,
  },
  activeNowBadge: {
    backgroundColor: colors.success[500],
    paddingHorizontal: spacing.xs,
    paddingVertical: 2,
    borderRadius: borderRadius.sm,
  },
  activeNowText: {
    fontSize: typography.fontSize.xs,
    fontFamily: typography.fontFamily.bold,
    color: colors.white,
  },
  scheduledBadge: {
    backgroundColor: colors.warning[500],
    paddingHorizontal: spacing.xs,
    paddingVertical: 2,
    borderRadius: borderRadius.sm,
  },
  scheduledText: {
    fontSize: typography.fontSize.xs,
    fontFamily: typography.fontFamily.bold,
    color: colors.white,
  },
  businessCategory: {
    fontSize: typography.fontSize.sm,
    fontFamily: typography.fontFamily.regular,
    color: colors.secondary[600],
    marginBottom: spacing.xs,
  },
  businessMeta: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: spacing.xs,
  },
  ratingContainer: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  rating: {
    marginLeft: spacing.xs,
    fontSize: typography.fontSize.sm,
    fontFamily: typography.fontFamily.medium,
    color: colors.secondary[700],
  },
  distance: {
    fontSize: typography.fontSize.sm,
    fontFamily: typography.fontFamily.medium,
    color: colors.primary[500],
  },
  discountContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: spacing.xs,
  },
  discountBadge: {
    paddingHorizontal: spacing.xs,
    paddingVertical: 2,
    borderRadius: borderRadius.sm,
    marginRight: spacing.xs,
  },
  discountBadgeActive: {
    backgroundColor: colors.success[500],
  },
  discountBadgeInactive: {
    backgroundColor: colors.warning[500],
  },
  discountText: {
    fontSize: typography.fontSize.xs,
    fontFamily: typography.fontFamily.bold,
    color: colors.white,
  },
  discountInfo: {
    flex: 1,
  },
  discountTitle: {
    fontSize: typography.fontSize.xs,
    fontFamily: typography.fontFamily.semibold,
    color: colors.primary[700],
    marginBottom: 2,
  },
  timeContainer: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  timeText: {
    marginLeft: spacing.xs,
    fontSize: typography.fontSize.xs,
    fontFamily: typography.fontFamily.regular,
    color: colors.secondary[500],
  },
  timeTextActive: {
    color: colors.success[600],
    fontFamily: typography.fontFamily.semibold,
  },
});