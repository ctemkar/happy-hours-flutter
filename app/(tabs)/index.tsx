import React, { useState, useEffect, useRef, useMemo, useCallback } from 'react';
import {
  View,
  Text,
  ScrollView,
  Image,
  TouchableOpacity,
  TextInput,
  StyleSheet,
  SafeAreaView,
  ActivityIndicator,
  Platform,
  RefreshControl,
  Alert,
  Pressable,
} from 'react-native';
import { Search, MapPin, Clock, Star, Navigation, Heart, Globe, ChevronDown, ChevronLeft, ChevronRight } from 'lucide-react-native';
import { colors, typography, spacing, borderRadius, shadows } from '@/constants/theme';
import { categories } from '@/lib/data';
import { useLocation } from '@/hooks/useLocation';
import { useBookmarks } from '@/hooks/useBookmarks';
import { useLocationSelection } from '@/hooks/useLocationSelection';
import { PlacesService } from '@/lib/placesService';
import { LocationService } from '@/lib/locationService';
import { Business, Discount } from '@/types';
import { router } from 'expo-router';
import LocationSelector from '@/components/LocationSelector';

export default function DiscoverScreen() {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('All');
  const [realPlaces, setRealPlaces] = useState<Business[]>([]);
  const [loadingPlaces, setLoadingPlaces] = useState(false);
  const [refreshing, setRefreshing] = useState(false);
  const [showLocationSelector, setShowLocationSelector] = useState(false);
  const [canScrollLeft, setCanScrollLeft] = useState(false);
  const [canScrollRight, setCanScrollRight] = useState(true);
  const scrollViewRef = useRef<ScrollView>(null);
  const isMountedRef = useRef(true);

  const { location, loading: locationLoading, error: locationError, getCurrentLocation } = useLocation();
  const { bookmarkedPlaces, toggleBookmark, isBookmarked } = useBookmarks();
  const { selectedLocation, selectLocation, clearLocation } = useLocationSelection();

  // Use selected location or current location - memoized to prevent unnecessary re-renders
  const activeLocation = useMemo(() => {
    if (selectedLocation) {
      return {
        latitude: selectedLocation.coordinates.latitude,
        longitude: selectedLocation.coordinates.longitude,
        city: selectedLocation.name,
      };
    }
    return location;
  }, [selectedLocation, location]);

  // Cleanup on unmount
  useEffect(() => {
    return () => {
      isMountedRef.current = false;
    };
  }, []);

  // Load places when activeLocation or selectedCategory changes
  const loadNearbyPlaces = useCallback(async () => {
    if (!activeLocation || !isMountedRef.current) {
      setRealPlaces([]);
      return;
    }

    setLoadingPlaces(true);
    
    try {
      const places = await PlacesService.searchNearbyPlaces({
        latitude: activeLocation.latitude,
        longitude: activeLocation.longitude,
        radius: 50000, // 50km radius to find more businesses
        category: selectedCategory !== 'All' ? selectedCategory : undefined,
      });

      if (!isMountedRef.current) return;

      // Add bookmark status to places
      const placesWithBookmarks = places.map(place => ({
        ...place,
        isBookmarked: isBookmarked(place.id),
      }));

      setRealPlaces(placesWithBookmarks);
    } catch (error) {
      if (!isMountedRef.current) return;
      
      console.error('DiscoverScreen: Error loading places:', error);
      Alert.alert('Error', 'Unable to load places. Please check your internet connection and try again.');
      setRealPlaces([]);
    } finally {
      if (isMountedRef.current) {
        setLoadingPlaces(false);
      }
    }
  }, [activeLocation, selectedCategory, isBookmarked]);

  useEffect(() => {
    if (activeLocation && !locationLoading) {
      loadNearbyPlaces();
    }
  }, [activeLocation, selectedCategory, locationLoading, loadNearbyPlaces]);

  const onRefresh = useCallback(async () => {
    if (!isMountedRef.current) return;
    
    setRefreshing(true);
    if (!selectedLocation) {
      await getCurrentLocation();
    }
    await loadNearbyPlaces();
    if (isMountedRef.current) {
      setRefreshing(false);
    }
  }, [selectedLocation, getCurrentLocation, loadNearbyPlaces]);

  const handleUseMyLocation = useCallback(async () => {
    await clearLocation();
    await getCurrentLocation();
  }, [clearLocation, getCurrentLocation]);

  // Helper function to check if a discount is currently active based on time
  const isDiscountCurrentlyActive = useCallback((discount: Discount | undefined): boolean => {
    if (!discount || !discount.isActive) return false;

    const now = new Date();
    const currentTime = now.getHours() * 60 + now.getMinutes();

    const parseTime = (timeStr: string): number => {
      if (!timeStr) return 0;
      const [hours, minutes] = timeStr.split(':').map(Number);
      return hours * 60 + (minutes || 0);
    };

    const startTime = parseTime(discount.validFrom);
    const endTime = parseTime(discount.validTo);

    if (endTime < startTime) {
      return currentTime >= startTime || currentTime <= endTime;
    }

    return currentTime >= startTime && currentTime <= endTime;
  }, []);

  // Filter and sort businesses - SHOW ALL BUSINESSES, prioritize those with discounts
  const filteredBusinesses = useMemo(() => {
    const filtered = realPlaces.filter(business => {
      if (!business.isActive) return false;

      const matchesSearch = business.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
                           business.description.toLowerCase().includes(searchQuery.toLowerCase()) ||
                           business.location.address.toLowerCase().includes(searchQuery.toLowerCase());
      const matchesCategory = selectedCategory === 'All' || business.category === selectedCategory;

      return matchesSearch && matchesCategory;
    });

    // Sort by: 1. Currently active discounts first, 2. Any discounts, 3. Verified businesses, 4. Rating
    return filtered.sort((a, b) => {
      // Currently active discounts first
      const aCurrentlyActive = isDiscountCurrentlyActive(a.currentDiscount);
      const bCurrentlyActive = isDiscountCurrentlyActive(b.currentDiscount);
      
      if (aCurrentlyActive && !bCurrentlyActive) return -1;
      if (!aCurrentlyActive && bCurrentlyActive) return 1;
      
      // Then any discounts (active or inactive)
      const aHasDiscount = a.currentDiscount !== undefined;
      const bHasDiscount = b.currentDiscount !== undefined;
      
      if (aHasDiscount && !bHasDiscount) return -1;
      if (!aHasDiscount && bHasDiscount) return 1;
      
      // Then verified businesses
      if (a.isVerified && !b.isVerified) return -1;
      if (!a.isVerified && b.isVerified) return 1;

      // Finally by rating (highest first)
      return b.rating - a.rating;
    });
  }, [realPlaces, searchQuery, selectedCategory, isDiscountCurrentlyActive]);

  const handleCategoryChange = useCallback(async (category: string) => {
    setSelectedCategory(category);
  }, []);

  const handleSearch = useCallback(async (query: string) => {
    setSearchQuery(query);

    if (query.length === 0 && activeLocation) {
      await loadNearbyPlaces();
      return;
    }

    if (activeLocation && query.length > 0) {
      setLoadingPlaces(true);
      try {
        const places = await PlacesService.searchNearbyPlaces({
          latitude: activeLocation.latitude,
          longitude: activeLocation.longitude,
          radius: 50000, // 50km radius
          category: selectedCategory !== 'All' ? selectedCategory : undefined,
          query,
        });

        if (!isMountedRef.current) return;

        const placesWithBookmarks = places.map(place => ({
          ...place,
          isBookmarked: isBookmarked(place.id),
        }));

        setRealPlaces(placesWithBookmarks);
      } catch (error) {
        if (!isMountedRef.current) return;
        
        console.error('Error searching places:', error);
        Alert.alert('Search Error', 'Unable to search places. Please try again.');
        setRealPlaces([]);
      } finally {
        if (isMountedRef.current) {
          setLoadingPlaces(false);
        }
      }
    }
  }, [activeLocation, selectedCategory, loadNearbyPlaces, isBookmarked]);

  const handleBusinessPress = useCallback((business: Business) => {
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
  }, []);

  const handleBookmarkToggle = useCallback(async (business: Business) => {
    const isNowBookmarked = await toggleBookmark(business.id);

    setRealPlaces(prev => prev.map(place =>
      place.id === business.id
        ? { ...place, isBookmarked: isNowBookmarked }
        : place
    ));
  }, [toggleBookmark]);

  const shouldShowDistance = useCallback((business: Business) => {
    return !!location && !selectedLocation;
  }, [location, selectedLocation]);

  const getDistanceText = useCallback((business: Business) => {
    if (!shouldShowDistance(business) || !location) return null;

    const distance = calculateDistance(
      location.latitude,
      location.longitude,
      business.location.latitude,
      business.location.longitude
    );

    return `${distance.toFixed(1)}km`;
  }, [shouldShowDistance, location]);

  const calculateDistance = useCallback((lat1: number, lon1: number, lat2: number, lon2: number) => {
    const R = 6371;
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLon = (lon2 - lon1) * Math.PI / 180;
    const a =
      Math.sin(dLat/2) * Math.sin(dLat/2) +
      Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
      Math.sin(dLon/2) * Math.sin(dLon/2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
    return R * c;
  }, []);

  const renderBusinessCard = useCallback((business: Business) => {
    const distanceText = getDistanceText(business);
    const isCurrentlyActive = isDiscountCurrentlyActive(business.currentDiscount);
    const hasDiscount = business.currentDiscount !== undefined;

    return (
      <View
        key={business.id}
        style={[
          styles.businessCard,
          isCurrentlyActive && styles.businessCardActive
        ]}
      >
        <Image source={{ uri: business.image }} style={styles.businessImage} />
        <TouchableOpacity
          style={styles.bookmarkButton}
          onPress={() => handleBookmarkToggle(business)}
          activeOpacity={0.7}
          accessibilityRole="button"
          accessibilityLabel={business.isBookmarked ? `Remove ${business.name} from bookmarks` : `Add ${business.name} to bookmarks`}
        >
          <Heart
            size={20}
            color={business.isBookmarked ? colors.error[500] : colors.white}
            fill={business.isBookmarked ? colors.error[500] : 'transparent'}
          />
        </TouchableOpacity>

        <View style={styles.statusBadges}>
          {isCurrentlyActive && (
            <View style={styles.activeBadge}>
              <Text style={styles.activeBadgeText}>ACTIVE NOW</Text>
            </View>
          )}
          {!isCurrentlyActive && hasDiscount && (
            <View style={styles.inactiveBadge}>
              <Text style={styles.inactiveBadgeText}>SCHEDULED</Text>
            </View>
          )}
          {business.isVerified && (
            <View style={styles.verifiedBadge}>
              <Text style={styles.verifiedBadgeText}>✓ VERIFIED</Text>
            </View>
          )}
        </View>

        <Pressable
          style={styles.businessContent}
          onPress={() => handleBusinessPress(business)}
          accessibilityRole="button"
          accessibilityLabel={`View details for ${business.name}. Rating ${business.rating.toFixed(1)} stars. ${hasDiscount ? business.currentDiscount?.percentage + '% off.' : ''}`}
        >
          <View style={styles.businessInfo}>
            <View style={styles.businessHeader}>
              <Text style={styles.businessName}>{business.name}</Text>
              <View style={styles.ratingContainer}>
                <Star size={16} color={colors.warning[500]} fill={colors.warning[500]} />
                <Text style={styles.rating}>{business.rating.toFixed(1)}</Text>
              </View>
            </View>
            <Text style={styles.businessDescription} numberOfLines={2}>{business.description}</Text>
            <View style={styles.locationContainer}>
              <MapPin size={14} color={colors.secondary[500]} />
              <Text style={styles.locationText} numberOfLines={1}>{business.location.address}</Text>
              {distanceText && (
                <Text style={styles.distanceText}>
                   • {distanceText}
                </Text>
              )}
            </View>

            {hasDiscount && (
              <View style={[
                styles.discountContainer,
                isCurrentlyActive ? styles.discountContainerActive : styles.discountContainerInactive
              ]}>
                <View style={[
                  styles.discountBadge,
                  isCurrentlyActive ? styles.discountBadgeActive : styles.discountBadgeInactive
                ]}>
                  <Text style={styles.discountPercentage}>{business.currentDiscount!.percentage}% OFF</Text>
                </View>
                <View style={styles.discountInfo}>
                  <Text style={styles.discountTitle}>{business.currentDiscount!.title}</Text>
                  <View style={styles.timeContainer}>
                    <Clock size={12} color={colors.secondary[500]} />
                    <Text style={[
                      styles.timeText,
                      isCurrentlyActive && styles.timeTextActive
                    ]}>
                      {`${business.currentDiscount!.validFrom} - ${business.currentDiscount!.validTo}`}
                      {isCurrentlyActive && ' (Active Now!)'}
                    </Text>
                  </View>
                </View>
              </View>
            )}
          </View>
        </Pressable>
      </View>
    );
  }, [getDistanceText, isDiscountCurrentlyActive, handleBookmarkToggle, handleBusinessPress]);

  const getLocationDisplayName = useCallback(() => {
    if (selectedLocation) {
      return LocationService.getLocationDisplayName(selectedLocation);
    }

    if (activeLocation?.city) {
      return activeLocation.city;
    }

    if (!activeLocation || !activeLocation.latitude || !activeLocation.longitude) {
      return 'your area';
    }

    const lat = activeLocation.latitude;
    const lng = activeLocation.longitude;

    if (lat >= 40.4774 && lat <= 40.9176 && lng >= -74.2591 && lng <= -73.7004) return 'New York';
    if (lat >= 33.7037 && lat <= 34.3373 && lng >= -118.6681 && lng <= -118.1553) return 'Los Angeles';
    if (lat >= 51.2868 && lat <= 51.6918 && lng >= -0.5103 && lng <= 0.3340) return 'London';
    if (lat >= 48.8155 && lat <= 48.9021 && lng >= 2.2241 && lng <= 2.4699) return 'Paris';
    if (lat >= 35.5322 && lat <= 35.8986 && lng >= 139.3431 && lng <= 139.9194) return 'Tokyo';
    if (lat >= -34.1692 && lat <= -33.5781 && lng >= 150.5023 && lng <= 151.3430) return 'Sydney';
    if (lat >= 13.4980 && lat <= 14.0990 && lng >= 100.3273 && lng <= 100.9319) return 'Bangkok';
    if (lat >= 12.8000 && lat <= 13.0000 && lng >= 100.8000 && lng <= 101.0000) return 'Pattaya';

    return 'your area';
  }, [selectedLocation, activeLocation]);

  const getSearchSuggestion = useCallback(() => {
    if (searchQuery.length > 2) {
      const matchingLocations = LocationService.searchLocations(searchQuery);
      if (matchingLocations.length > 0) {
        const topMatch = matchingLocations[0];
        const currentLocationName = getLocationDisplayName().toLowerCase();
        if (!currentLocationName.includes(topMatch.name.toLowerCase())) {
          return topMatch;
        }
      }
    }
    return null;
  }, [searchQuery, getLocationDisplayName]);

  const searchSuggestion = getSearchSuggestion();

  const handleCategoryScroll = useCallback((event: any) => {
    const { contentOffset, contentSize, layoutMeasurement } = event.nativeEvent;
    const scrollX = contentOffset.x;
    const maxScrollX = contentSize.width - layoutMeasurement.width;

    setCanScrollLeft(scrollX > 5);
    setCanScrollRight(scrollX < maxScrollX - 5);
  }, []);

  const scrollCategoriesLeft = useCallback(() => {
    scrollViewRef.current?.scrollTo({ x: 0, animated: true });
  }, []);

  const scrollCategoriesRight = useCallback(() => {
    scrollViewRef.current?.scrollToEnd({ animated: true });
  }, []);

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <View style={styles.headerTop}>
          <View style={styles.headerContent}>
            <Text style={styles.headerTitle}>Happy Hours</Text>
            <TouchableOpacity
              style={styles.locationSelector}
              onPress={() => setShowLocationSelector(true)}
              activeOpacity={0.7}
              accessibilityRole="button"
              accessibilityLabel={`Currently showing businesses in ${getLocationDisplayName()}. Tap to change location.`}
            >
              <Globe size={16} color={colors.primary[500]} />
              <Text style={styles.headerSubtitle} numberOfLines={1}>
                {activeLocation
                  ? `All businesses in ${getLocationDisplayName()}`
                  : 'Choose a city to explore'
                }
              </Text>
              <ChevronDown size={16} color={colors.primary[500]} />
            </TouchableOpacity>
          </View>
          <TouchableOpacity
            style={styles.locationButton}
            onPress={selectedLocation ? () => setShowLocationSelector(true) : getCurrentLocation}
            disabled={locationLoading}
            accessibilityRole="button"
            accessibilityLabel={locationLoading ? 'Getting your current location' : (selectedLocation ? 'Change selected city' : 'Use my current location')}
          >
            {locationLoading ? (
              <ActivityIndicator size="small" color={colors.primary[500]} />
            ) : (
              <Navigation size={16} color={colors.primary[500]} />
            )}
          </TouchableOpacity>
        </View>

        <View style={styles.popularDestinationsContainer}>
          <Text style={styles.popularDestinationsTitle}>Quick Location Access</Text>
          <ScrollView
            horizontal
            showsHorizontalScrollIndicator={false}
            style={styles.popularDestinationsScroll}
            contentContainerStyle={styles.popularDestinationsContent}
          >
            <TouchableOpacity
              style={[
                styles.currentLocationChip,
                location && !selectedLocation && styles.currentLocationChipActive,
                locationLoading && styles.disabledButton,
              ]}
              onPress={handleUseMyLocation}
              activeOpacity={0.7}
              disabled={locationLoading}
              accessibilityRole="button"
              accessibilityLabel={locationLoading ? 'Getting your current location' : (location && !selectedLocation ? 'Currently using your current location' : 'Use your current location')}
            >
              {locationLoading ? (
                <ActivityIndicator size={14} color={colors.success[600]} />
              ) : (
                <Navigation size={14} color={colors.success[600]} />
              )}
              <Text style={styles.currentLocationText}>
                {locationLoading ? 'Getting Location...' :
                  location && !selectedLocation ? 'Current Location' : 'Use My Location'}
              </Text>
            </TouchableOpacity>

            {LocationService.getPopularLocations().slice(0, 5).map((loc) => (
              <TouchableOpacity
                key={loc.id}
                style={[
                  styles.popularDestinationChip,
                  selectedLocation?.id === loc.id && styles.popularDestinationChipActive
                ]}
                onPress={() => {
                  selectLocation(loc);
                }}
                activeOpacity={0.7}
                accessibilityRole="button"
                accessibilityLabel={selectedLocation?.id === loc.id ? `Currently selected city: ${loc.name}` : `Select ${loc.name} as city`}
              >
                <Globe size={14} color={selectedLocation?.id === loc.id ? colors.primary[700] : colors.primary[600]} />
                <Text style={[
                  styles.popularDestinationText,
                  selectedLocation?.id === loc.id && styles.popularDestinationTextActive
                ]}>
                  {loc.name}
                </Text>
              </TouchableOpacity>
            ))}

            <TouchableOpacity
              style={styles.moreDestinationsChip}
              onPress={() => setShowLocationSelector(true)}
              activeOpacity={0.7}
              accessibilityRole="button"
              accessibilityLabel="Show more cities to choose from"
            >
              <Text style={styles.moreDestinationsText}>More Cities</Text>
              <ChevronDown size={14} color={colors.secondary[600]} />
            </TouchableOpacity>
          </ScrollView>
        </View>

        {locationError && (
          <View style={styles.errorContainer}>
            <Text style={styles.errorText}>
              {locationError} - Please try again or select a city manually.
            </Text>
          </View>
        )}
      </View>

      <View style={styles.searchContainer}>
        <View style={styles.searchInputContainer}>
          <Search size={20} color={colors.secondary[400]} />
          <TextInput
            style={styles.searchInput}
            placeholder="Search venues or cities..."
            value={searchQuery}
            onChangeText={handleSearch}
            placeholderTextColor={colors.secondary[400]}
            accessibilityLabel="Search for venues or cities"
          />
        </View>

        {searchSuggestion && (
          <TouchableOpacity
            style={styles.searchSuggestion}
            onPress={() => {
              selectLocation(searchSuggestion);
              setSearchQuery('');
            }}
            activeOpacity={0.7}
            accessibilityRole="button"
            accessibilityLabel={`Suggests switching to ${LocationService.getLocationDisplayName(searchSuggestion)}`}
          >
            <Globe size={16} color={colors.primary[500]} />
            <Text style={styles.suggestionText}>
              Switch to {LocationService.getLocationDisplayName(searchSuggestion)}
            </Text>
          </TouchableOpacity>
        )}
      </View>

      <View style={styles.categoriesContainer}>
        <View style={styles.categoriesWrapper}>
          {canScrollLeft && (
            <TouchableOpacity
              style={[styles.scrollArrow, styles.scrollArrowLeft]}
              onPress={scrollCategoriesLeft}
              activeOpacity={0.7}
              accessibilityRole="button"
              accessibilityLabel="Scroll categories left"
            >
              <ChevronLeft size={20} color={colors.primary[500]} />
            </TouchableOpacity>
          )}

          <ScrollView
            ref={scrollViewRef}
            horizontal
            showsHorizontalScrollIndicator={false}
            style={styles.categoriesScrollView}
            contentContainerStyle={styles.categoriesContent}
            onScroll={handleCategoryScroll}
            scrollEventThrottle={16}
            decelerationRate="fast"
          >
            {categories.map((category) => (
              <TouchableOpacity
                key={`category-${category}`}
                style={[
                  styles.categoryChip,
                  selectedCategory === category && styles.categoryChipActive,
                ]}
                onPress={() => handleCategoryChange(category)}
                accessibilityRole="button"
                accessibilityLabel={selectedCategory === category ? `Currently selected category: ${category}` : `Select category ${category}`}
              >
                <Text style={[
                  styles.categoryText,
                  selectedCategory === category && styles.categoryTextActive
                ]}>
                  {category}
                </Text>
              </TouchableOpacity>
            ))}
          </ScrollView>

          {canScrollRight && (
            <TouchableOpacity
              style={[styles.scrollArrow, styles.scrollArrowRight]}
              onPress={scrollCategoriesRight}
              activeOpacity={0.7}
              accessibilityRole="button"
              accessibilityLabel="Scroll categories right"
            >
              <ChevronRight size={20} color={colors.primary[500]} />
            </TouchableOpacity>
          )}
        </View>
      </View>

      <ScrollView
        style={styles.businessList}
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
        {(loadingPlaces || locationLoading) && (
          <View style={styles.loadingContainer}>
            <ActivityIndicator size="large" color={colors.primary[500]} />
            <Text style={styles.loadingText}>
              {locationLoading ? 'Getting your location...' : 'Finding businesses near you...'}
            </Text>
          </View>
        )}

        {!activeLocation && !locationLoading && (
          <View style={styles.emptyContainer}>
            <Globe size={48} color={colors.secondary[400]} />
            <Text style={styles.emptyText}>Choose a location</Text>
            <Text style={styles.emptySubtext}>
              Select a city or use your current location to discover amazing businesses and deals.
            </Text>
            <View style={styles.emptyActions}>
              <TouchableOpacity
                style={[styles.locationPermissionButton, locationLoading && styles.disabledButton]}
                onPress={handleUseMyLocation}
                disabled={locationLoading}
                accessibilityRole="button"
                accessibilityLabel={locationLoading ? 'Getting your location' : 'Use my current location'}
              >
                {locationLoading ? (
                  <ActivityIndicator size="small" color={colors.white} />
                ) : (
                  <Navigation size={16} color={colors.white} />
                )}
                <Text style={styles.locationPermissionButtonText}>
                  {locationLoading ? 'Getting Location...' : 'Use My Location'}
                </Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={styles.browseCitiesButton}
                onPress={() => setShowLocationSelector(true)}
                accessibilityRole="button"
                accessibilityLabel="Browse other cities for businesses"
              >
                <Globe size={16} color={colors.primary[500]} />
                <Text style={styles.browseCitiesButtonText}>Browse Cities</Text>
              </TouchableOpacity>
            </View>
          </View>
        )}

        {filteredBusinesses.length === 0 && !loadingPlaces && !locationLoading && activeLocation ? (
          <View style={styles.emptyContainer}>
            <Text style={styles.emptyText}>
              {searchQuery ? 'No results found' : 'No businesses found'}
            </Text>
            <Text style={styles.emptySubtext}>
              {searchQuery
                ? `No venues found matching "${searchQuery}" in ${getLocationDisplayName()}. Try adjusting your search or category filter.`
                : `No businesses found in ${getLocationDisplayName()}. Upload business data via the Admin panel or configure your Google Places API key to see real businesses.`
              }
            </Text>
            {searchQuery.length > 0 && (
              <TouchableOpacity
                style={styles.clearSearchButton}
                onPress={() => setSearchQuery('')}
                accessibilityRole="button"
                accessibilityLabel="Clear search query"
              >
                <Text style={styles.clearSearchButtonText}>Clear Search</Text>
              </TouchableOpacity>
            )}
          </View>
        ) : (
          filteredBusinesses.map(renderBusinessCard)
        )}
      </ScrollView>

      <LocationSelector
        visible={showLocationSelector}
        onClose={() => setShowLocationSelector(false)}
        onSelectLocation={selectLocation}
        currentLocation={selectedLocation}
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.white,
  },
  header: {
    paddingHorizontal: spacing.lg,
    paddingTop: spacing.lg,
    paddingBottom: spacing.md,
  },
  headerTop: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: spacing.sm,
  },
  headerContent: {
    flex: 1,
  },
  headerTitle: {
    fontSize: typography.fontSize['3xl'],
    fontFamily: typography.fontFamily.heading,
    color: colors.secondary[900],
    marginBottom: spacing.xs,
  },
  locationSelector: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.primary[50],
    paddingHorizontal: spacing.sm,
    paddingVertical: spacing.xs,
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    borderColor: colors.primary[200],
    maxWidth: '90%',
  },
  headerSubtitle: {
    fontSize: typography.fontSize.base,
    fontFamily: typography.fontFamily.regular,
    color: colors.primary[700],
    marginLeft: spacing.xs,
    marginRight: spacing.xs,
    flexShrink: 1,
  },
  locationButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: colors.primary[50],
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: colors.primary[200],
    marginLeft: spacing.md,
  },
  popularDestinationsContainer: {
    marginTop: spacing.md,
    marginBottom: spacing.sm,
  },
  popularDestinationsTitle: {
    fontSize: typography.fontSize.base,
    fontFamily: typography.fontFamily.semibold,
    color: colors.secondary[700],
    marginBottom: spacing.sm,
  },
  popularDestinationsScroll: {
    flexGrow: 0,
  },
  popularDestinationsContent: {
    gap: spacing.sm,
  },
  currentLocationChip: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.success[50],
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.sm,
    borderRadius: borderRadius.full,
    borderWidth: 1,
    borderColor: colors.success[200],
    ...shadows.sm,
  },
  currentLocationChipActive: {
    backgroundColor: colors.success[100],
    borderColor: colors.success[300],
  },
  currentLocationText: {
    fontSize: typography.fontSize.sm,
    fontFamily: typography.fontFamily.semibold,
    color: colors.success[700],
    marginLeft: spacing.xs,
  },
  popularDestinationChip: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.white,
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.sm,
    borderRadius: borderRadius.full,
    borderWidth: 1,
    borderColor: colors.primary[200],
    ...shadows.sm,
  },
  popularDestinationChipActive: {
    backgroundColor: colors.primary[100],
    borderColor: colors.primary[300],
  },
  popularDestinationText: {
    fontSize: typography.fontSize.sm,
    fontFamily: typography.fontFamily.medium,
    color: colors.primary[700],
    marginLeft: spacing.xs,
  },
  popularDestinationTextActive: {
    fontFamily: typography.fontFamily.semibold,
    color: colors.primary[800],
  },
  moreDestinationsChip: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.secondary[100],
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.sm,
    borderRadius: borderRadius.full,
    borderWidth: 1,
    borderColor: colors.secondary[200],
  },
  moreDestinationsText: {
    fontSize: typography.fontSize.sm,
    fontFamily: typography.fontFamily.medium,
    color: colors.secondary[600],
    marginRight: spacing.xs,
  },
  errorContainer: {
    backgroundColor: colors.error[50],
    padding: spacing.sm,
    borderRadius: borderRadius.md,
    borderLeftWidth: 4,
    borderLeftColor: colors.error[500],
    marginTop: spacing.sm,
  },
  errorText: {
    fontSize: typography.fontSize.sm,
    fontFamily: typography.fontFamily.medium,
    color: colors.error[600],
  },
  searchContainer: {
    paddingHorizontal: spacing.lg,
    marginBottom: spacing.md,
  },
  searchInputContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.secondary[50],
    borderRadius: borderRadius.lg,
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.sm,
  },
  searchInput: {
    flex: 1,
    marginLeft: spacing.sm,
    fontSize: typography.fontSize.base,
    fontFamily: typography.fontFamily.regular,
    color: colors.secondary[900],
  },
  searchSuggestion: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.primary[50],
    borderRadius: borderRadius.md,
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.sm,
    marginTop: spacing.sm,
    borderWidth: 1,
    borderColor: colors.primary[200],
  },
  suggestionText: {
    fontSize: typography.fontSize.sm,
    fontFamily: typography.fontFamily.medium,
    color: colors.primary[700],
    marginLeft: spacing.sm,
  },
  categoriesContainer: {
    marginBottom: spacing.lg,
    height: 50,
  },
  categoriesWrapper: {
    flexDirection: 'row',
    alignItems: 'center',
    height: '100%',
  },
  scrollArrow: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: colors.white,
    justifyContent: 'center',
    alignItems: 'center',
    zIndex: 1,
    ...shadows.sm,
  },
  scrollArrowLeft: {
    marginLeft: spacing.md,
    marginRight: -16,
  },
  scrollArrowRight: {
    marginRight: spacing.md,
    marginLeft: -16,
  },
  categoriesScrollView: {
    flex: 1,
    overflow: 'visible',
  },
  categoriesContent: {
    paddingHorizontal: spacing.lg,
    alignItems: 'center',
    gap: spacing.sm,
  },
  categoryChip: {
    backgroundColor: colors.secondary[100],
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.sm,
    borderRadius: borderRadius.full,
    alignItems: 'center',
    justifyContent: 'center',
    minWidth: 100,
    height: 36,
  },
  categoryChipActive: {
    backgroundColor: colors.primary[500],
  },
  categoryText: {
    fontSize: typography.fontSize.sm,
    fontFamily: typography.fontFamily.medium,
    color: colors.secondary[700],
    textAlign: 'center',
  },
  categoryTextActive: {
    color: colors.white,
  },
  businessList: {
    flex: 1,
    paddingHorizontal: spacing.lg,
  },
  loadingContainer: {
    alignItems: 'center',
    paddingVertical: spacing.xl,
  },
  loadingText: {
    fontSize: typography.fontSize.base,
    fontFamily: typography.fontFamily.medium,
    color: colors.secondary[600],
    marginTop: spacing.md,
  },
  emptyContainer: {
    alignItems: 'center',
    paddingVertical: spacing.xl,
    paddingHorizontal: spacing.lg,
  },
  emptyText: {
    fontSize: typography.fontSize.lg,
    fontFamily: typography.fontFamily.semibold,
    color: colors.secondary[700],
    marginBottom: spacing.xs,
    marginTop: spacing.md,
  },
  emptySubtext: {
    fontSize: typography.fontSize.base,
    fontFamily: typography.fontFamily.regular,
    color: colors.secondary[500],
    textAlign: 'center',
    marginBottom: spacing.lg,
    lineHeight: typography.fontSize.base * 1.4,
  },
  emptyActions: {
    flexDirection: 'row',
    gap: spacing.md,
    flexWrap: 'wrap',
    justifyContent: 'center',
  },
  locationPermissionButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.primary[500],
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.md,
    borderRadius: borderRadius.lg,
    ...shadows.sm,
  },
  locationPermissionButtonText: {
    fontSize: typography.fontSize.base,
    fontFamily: typography.fontFamily.semibold,
    color: colors.white,
    marginLeft: spacing.sm,
  },
  browseCitiesButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.white,
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.md,
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    borderColor: colors.primary[200],
    ...shadows.sm,
  },
  browseCitiesButtonText: {
    fontSize: typography.fontSize.base,
    fontFamily: typography.fontFamily.semibold,
    color: colors.primary[500],
    marginLeft: spacing.sm,
  },
  clearSearchButton: {
    backgroundColor: colors.secondary[100],
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.md,
    borderRadius: borderRadius.lg,
  },
  clearSearchButtonText: {
    fontSize: typography.fontSize.base,
    fontFamily: typography.fontFamily.semibold,
    color: colors.secondary[700],
  },
  businessCard: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.xl,
    marginBottom: spacing.lg,
    position: 'relative',
    ...shadows.md,
  },
  businessCardActive: {
    borderWidth: 2,
    borderColor: colors.success[300],
    ...shadows.lg,
  },
  businessImage: {
    width: '100%',
    height: 200,
    borderTopLeftRadius: borderRadius.xl,
    borderTopRightRadius: borderRadius.xl,
  },
  bookmarkButton: {
    position: 'absolute',
    top: spacing.md,
    right: spacing.md,
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: 'rgba(0,0,0,0.6)',
    justifyContent: 'center',
    alignItems: 'center',
    zIndex: 1,
  },
  statusBadges: {
    position: 'absolute',
    top: spacing.md,
    left: spacing.md,
    gap: spacing.xs,
  },
  activeBadge: {
    backgroundColor: colors.success[500],
    paddingHorizontal: spacing.sm,
    paddingVertical: spacing.xs,
    borderRadius: borderRadius.md,
  },
  activeBadgeText: {
    fontSize: typography.fontSize.xs,
    fontFamily: typography.fontFamily.bold,
    color: colors.white,
  },
  inactiveBadge: {
    backgroundColor: colors.warning[500],
    paddingHorizontal: spacing.sm,
    paddingVertical: spacing.xs,
    borderRadius: borderRadius.md,
  },
  inactiveBadgeText: {
    fontSize: typography.fontSize.xs,
    fontFamily: typography.fontFamily.bold,
    color: colors.white,
  },
  verifiedBadge: {
    backgroundColor: colors.primary[500],
    paddingHorizontal: spacing.sm,
    paddingVertical: spacing.xs,
    borderRadius: borderRadius.md,
  },
  verifiedBadgeText: {
    fontSize: typography.fontSize.xs,
    fontFamily: typography.fontFamily.bold,
    color: colors.white,
  },
  businessContent: {
    flex: 1,
  },
  businessInfo: {
    padding: spacing.md,
  },
  businessHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: spacing.sm,
  },
  businessName: {
    flex: 1,
    fontSize: typography.fontSize.lg,
    fontFamily: typography.fontFamily.bold,
    color: colors.secondary[900],
    marginRight: spacing.sm,
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
  businessDescription: {
    fontSize: typography.fontSize.sm,
    fontFamily: typography.fontFamily.regular,
    color: colors.secondary[600],
    marginBottom: spacing.sm,
    lineHeight: typography.fontSize.sm * 1.4,
  },
  locationContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: spacing.md,
  },
  locationText: {
    marginLeft: spacing.xs,
    fontSize: typography.fontSize.sm,
    fontFamily: typography.fontFamily.regular,
    color: colors.secondary[500],
    flex: 1,
  },
  distanceText: {
    fontSize: typography.fontSize.sm,
    fontFamily: typography.fontFamily.medium,
    color: colors.primary[500],
    marginLeft: spacing.xs,
  },
  discountContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.primary[50],
    borderRadius: borderRadius.lg,
    padding: spacing.sm,
  },
  discountContainerActive: {
    backgroundColor: colors.success[50],
    borderWidth: 1,
    borderColor: colors.success[200],
  },
  discountContainerInactive: {
    backgroundColor: colors.warning[50],
    borderWidth: 1,
    borderColor: colors.warning[200],
  },
  discountBadge: {
    backgroundColor: colors.primary[500],
    paddingHorizontal: spacing.sm,
    paddingVertical: spacing.xs,
    borderRadius: borderRadius.md,
    marginRight: spacing.sm,
  },
  discountBadgeActive: {
    backgroundColor: colors.success[500],
  },
  discountBadgeInactive: {
    backgroundColor: colors.warning[500],
  },
  discountPercentage: {
    fontSize: typography.fontSize.xs,
    fontFamily: typography.fontFamily.bold,
    color: colors.white,
  },
  discountInfo: {
    flex: 1,
  },
  discountTitle: {
    fontSize: typography.fontSize.sm,
    fontFamily: typography.fontFamily.semibold,
    color: colors.primary[700],
    marginBottom: spacing.xs,
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
  disabledButton: {
    opacity: 0.6,
  },
});