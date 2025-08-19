import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  SafeAreaView,
  ScrollView,
  TouchableOpacity,
  Image,
  RefreshControl,
  ActivityIndicator,
  Alert,
  Pressable,
} from 'react-native';
import { Heart, MapPin, Star, Clock, Search, Filter } from 'lucide-react-native';
import { colors, typography, spacing, borderRadius, shadows } from '@/constants/theme';
import { useBookmarks } from '@/hooks/useBookmarks';
import { useLocationSelection } from '@/hooks/useLocationSelection';
import { PlacesService } from '@/lib/placesService';
import { VerifiedBusinessService } from '@/lib/verifiedBusinessService';
import { categories } from '@/lib/data';
import { Business } from '@/types';
import { router } from 'expo-router';

export default function SavedPlacesScreen() {
  const [savedBusinesses, setSavedBusinesses] = useState<Business[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [selectedCategory, setSelectedCategory] = useState('All');
  
  const { bookmarkedPlaces, toggleBookmark, refreshBookmarks } = useBookmarks();
  const { selectedLocation } = useLocationSelection();

  useEffect(() => {
    loadSavedPlaces();
  }, [bookmarkedPlaces]);

  const loadSavedPlaces = async () => {
    setLoading(true);
    try {
      // Get verified businesses first
      const verifiedBusinesses = await VerifiedBusinessService.getVerifiedBusinesses();
      
      // Get places from API if we have a selected location
      let apiPlaces: Business[] = [];
      if (selectedLocation) {
        try {
          apiPlaces = await PlacesService.searchNearbyPlaces({
            latitude: selectedLocation.coordinates.latitude,
            longitude: selectedLocation.coordinates.longitude,
            radius: 10000,
          });
        } catch (error) {
          console.error('Error loading API places:', error);
        }
      }

      // Combine all businesses
      const allBusinesses = [...verifiedBusinesses, ...apiPlaces];

      // Filter to only show bookmarked places
      const savedPlaces = allBusinesses
        .filter(business => bookmarkedPlaces.includes(business.id))
        .map(business => ({
          ...business,
          isBookmarked: true,
        }));

      // Remove duplicates based on ID
      const uniqueSavedPlaces = savedPlaces.filter((business, index, self) =>
        index === self.findIndex(b => b.id === business.id)
      );

      setSavedBusinesses(uniqueSavedPlaces);
    } catch (error) {
      console.error('Error loading saved places:', error);
      Alert.alert('Error', 'Unable to load saved places. Please try again.');
      setSavedBusinesses([]);
    } finally {
      setLoading(false);
    }
  };

  const onRefresh = async () => {
    setRefreshing(true);
    await refreshBookmarks();
    await loadSavedPlaces();
    setRefreshing(false);
  };

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

  const handleRemoveBookmark = async (business: Business) => {
    await toggleBookmark(business.id);
    // Remove from local state immediately for better UX
    setSavedBusinesses(prev => prev.filter(b => b.id !== business.id));
  };

  const filteredBusinesses = savedBusinesses.filter(business => {
    const matchesCategory = selectedCategory === 'All' || business.category === selectedCategory;
    return matchesCategory;
  });

  const renderBusinessCard = (business: Business) => {
    return (
      <View 
        key={business.id} 
        style={styles.businessCard}
      >
        <Image source={{ uri: business.image }} style={styles.businessImage} />
        <TouchableOpacity 
          style={styles.removeButton}
          onPress={() => handleRemoveBookmark(business)}
          activeOpacity={0.7}
        >
          <Heart 
            size={20} 
            color={colors.error[500]} 
            fill={colors.error[500]}
          />
        </TouchableOpacity>
        
        <Pressable
          style={styles.businessContent}
          onPress={() => handleBusinessPress(business)}
        >
          <View style={styles.businessInfo}>
            <View style={styles.businessHeader}>
              <Text style={styles.businessName}>{business.name}</Text>
              <View style={styles.ratingContainer}>
                <Star size={16} color={colors.warning[500]} fill={colors.warning[500]} />
                <Text style={styles.rating}>{business.rating.toFixed(1)}</Text>
              </View>
            </View>
            
            <Text style={styles.businessDescription} numberOfLines={2}>
              {business.description}
            </Text>
            
            <View style={styles.locationContainer}>
              <MapPin size={14} color={colors.secondary[500]} />
              <Text style={styles.locationText} numberOfLines={1}>
                {business.location.address}
              </Text>
            </View>
            
            {business.currentDiscount && business.currentDiscount.isActive && (
              <View style={styles.discountContainer}>
                <View style={styles.discountBadge}>
                  <Text style={styles.discountPercentage}>
                    {business.currentDiscount.percentage}% OFF
                  </Text>
                </View>
                <View style={styles.discountInfo}>
                  <Text style={styles.discountTitle} numberOfLines={1}>
                    {business.currentDiscount.title}
                  </Text>
                  <View style={styles.timeContainer}>
                    <Clock size={12} color={colors.secondary[500]} />
                    <Text style={styles.timeText}>
                      {business.currentDiscount.validFrom} - {business.currentDiscount.validTo}
                    </Text>
                  </View>
                </View>
              </View>
            )}
          </View>
        </Pressable>
      </View>
    );
  };

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <View style={styles.headerContent}>
          <Text style={styles.headerTitle}>Saved Places</Text>
          <Text style={styles.headerSubtitle}>
            {filteredBusinesses.length} place{filteredBusinesses.length !== 1 ? 's' : ''} saved
          </Text>
        </View>
        <View style={styles.headerActions}>
          <TouchableOpacity style={styles.actionButton}>
            <Search size={20} color={colors.secondary[600]} />
          </TouchableOpacity>
          <TouchableOpacity style={styles.actionButton}>
            <Filter size={20} color={colors.secondary[600]} />
          </TouchableOpacity>
        </View>
      </View>

      {/* Category Filter */}
      <View style={styles.categoriesContainer}>
        <ScrollView 
          horizontal 
          showsHorizontalScrollIndicator={false}
          style={styles.categoriesScrollView}
          contentContainerStyle={styles.categoriesContent}
        >
          {categories.map((category, index) => (
            <TouchableOpacity
              key={`category-${index}`}
              style={[
                styles.categoryChip,
                selectedCategory === category && styles.categoryChipActive,
              ]}
              onPress={() => setSelectedCategory(category)}
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
        {loading && (
          <View style={styles.loadingContainer}>
            <ActivityIndicator size="large" color={colors.primary[500]} />
            <Text style={styles.loadingText}>Loading your saved places...</Text>
          </View>
        )}

        {!loading && filteredBusinesses.length === 0 && (
          <View style={styles.emptyContainer}>
            <Heart size={64} color={colors.secondary[300]} />
            <Text style={styles.emptyTitle}>No saved places yet</Text>
            <Text style={styles.emptySubtitle}>
              {bookmarkedPlaces.length === 0 
                ? "Start exploring and tap the heart icon to save places you're interested in visiting."
                : selectedCategory !== 'All'
                ? `No saved places in the ${selectedCategory} category. Try selecting "All" to see all your saved places.`
                : "Your saved places will appear here."
              }
            </Text>
            {bookmarkedPlaces.length === 0 && (
              <TouchableOpacity 
                style={styles.exploreButton}
                onPress={() => router.push('/(tabs)/')}
              >
                <Text style={styles.exploreButtonText}>Explore Places</Text>
              </TouchableOpacity>
            )}
          </View>
        )}

        {!loading && filteredBusinesses.length > 0 && (
          <View style={styles.businessGrid}>
            {filteredBusinesses.map(renderBusinessCard)}
          </View>
        )}

        <View style={styles.bottomPadding} />
      </ScrollView>
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
    alignItems: 'flex-start',
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
    marginBottom: spacing.xs,
  },
  headerSubtitle: {
    fontSize: typography.fontSize.base,
    fontFamily: typography.fontFamily.regular,
    color: colors.secondary[600],
  },
  headerActions: {
    flexDirection: 'row',
    gap: spacing.sm,
  },
  actionButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: colors.secondary[50],
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: colors.secondary[200],
  },
  categoriesContainer: {
    marginBottom: spacing.lg,
    height: 50,
  },
  categoriesScrollView: {
    flex: 1,
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
  businessGrid: {
    gap: spacing.lg,
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
  emptyTitle: {
    fontSize: typography.fontSize.xl,
    fontFamily: typography.fontFamily.bold,
    color: colors.secondary[700],
    marginTop: spacing.lg,
    marginBottom: spacing.sm,
  },
  emptySubtitle: {
    fontSize: typography.fontSize.base,
    fontFamily: typography.fontFamily.regular,
    color: colors.secondary[500],
    textAlign: 'center',
    lineHeight: typography.fontSize.base * 1.5,
    marginBottom: spacing.xl,
  },
  exploreButton: {
    backgroundColor: colors.primary[500],
    paddingHorizontal: spacing.xl,
    paddingVertical: spacing.md,
    borderRadius: borderRadius.lg,
  },
  exploreButtonText: {
    fontSize: typography.fontSize.base,
    fontFamily: typography.fontFamily.semibold,
    color: colors.white,
  },
  businessCard: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.xl,
    marginBottom: spacing.lg,
    position: 'relative',
    ...shadows.md,
  },
  businessImage: {
    width: '100%',
    height: 200,
    borderTopLeftRadius: borderRadius.xl,
    borderTopRightRadius: borderRadius.xl,
  },
  removeButton: {
    position: 'absolute',
    top: spacing.md,
    right: spacing.md,
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: 'rgba(255,255,255,0.9)',
    justifyContent: 'center',
    alignItems: 'center',
    zIndex: 1,
    ...shadows.sm,
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
    backgroundColor: colors.warning[50],
    paddingHorizontal: spacing.sm,
    paddingVertical: spacing.xs,
    borderRadius: borderRadius.md,
  },
  rating: {
    marginLeft: spacing.xs,
    fontSize: typography.fontSize.sm,
    fontFamily: typography.fontFamily.bold,
    color: colors.warning[700],
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
  discountContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.primary[50],
    borderRadius: borderRadius.lg,
    padding: spacing.sm,
  },
  discountBadge: {
    backgroundColor: colors.primary[500],
    paddingHorizontal: spacing.sm,
    paddingVertical: spacing.xs,
    borderRadius: borderRadius.md,
    marginRight: spacing.sm,
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
  bottomPadding: {
    height: spacing.xl,
  },
});