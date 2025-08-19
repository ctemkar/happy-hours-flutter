import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  SafeAreaView,
  ScrollView,
  Image,
  TouchableOpacity,
  Linking,
  Platform,
  Dimensions,
} from 'react-native';
import { useLocalSearchParams, router } from 'expo-router';
import { 
  ArrowLeft, 
  MapPin, 
  Star, 
  Clock, 
  Phone, 
  Globe, 
  Navigation,
  Share2,
  Heart
} from 'lucide-react-native';
import { colors, typography, spacing, borderRadius, shadows } from '@/constants/theme';

const { width: screenWidth, height: screenHeight } = Dimensions.get('window');

export default function BusinessDetailsScreen() {
  const params = useLocalSearchParams();
  
  const business = {
    id: params.id as string,
    name: params.name as string,
    description: params.description as string,
    image: params.image as string,
    address: params.address as string,
    rating: parseFloat(params.rating as string),
    category: params.category as string,
    discount: {
      title: params.discountTitle as string,
      percentage: parseInt(params.discountPercentage as string),
      description: params.discountDescription as string,
      validFrom: params.validFrom as string,
      validTo: params.validTo as string,
      isActive: params.isDiscountActive === 'true',
    }
  };

  const handleBack = () => {
    router.back();
  };

  const handleGetDirections = () => {
    // Search by business name for better Google Maps integration
    const searchQuery = `${business.name} ${business.address}`;
    const googleMapsUrl = `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(searchQuery)}`;
    
    if (Platform.OS === 'web') {
      // For web, open in new tab
      window.open(googleMapsUrl, '_blank');
    } else {
      // For mobile, try to open Google Maps app first, fallback to web
      const mobileGoogleMapsUrl = Platform.select({
        ios: `comgooglemaps://?q=${encodeURIComponent(searchQuery)}`,
        android: `google.navigation:q=${encodeURIComponent(searchQuery)}`,
      });

      // Try to open native Google Maps app first
      if (mobileGoogleMapsUrl) {
        Linking.canOpenURL(mobileGoogleMapsUrl).then(supported => {
          if (supported) {
            Linking.openURL(mobileGoogleMapsUrl);
          } else {
            // Fallback to web Google Maps
            Linking.openURL(googleMapsUrl);
          }
        }).catch(() => {
          // If anything fails, use web Google Maps
          Linking.openURL(googleMapsUrl);
        });
      } else {
        // Fallback to web Google Maps
        Linking.openURL(googleMapsUrl);
      }
    }
  };

  const handleShare = async () => {
    const shareData = {
      title: business.name,
      message: `Check out ${business.name} - ${business.description}. ${business.discount.isActive ? `${business.discount.percentage}% OFF ${business.discount.title}!` : ''}`,
      url: `https://happyarz.app/business/${business.id}`,
    };

    if (Platform.OS === 'web' && navigator.share) {
      try {
        await navigator.share(shareData);
      } catch (error) {
        console.log('Error sharing:', error);
        // Fallback: copy to clipboard or show share options
        if (navigator.clipboard) {
          navigator.clipboard.writeText(`${shareData.message} ${shareData.url}`);
        }
      }
    } else {
      // For mobile platforms, you could use expo-sharing
      console.log('Share:', shareData);
    }
  };

  const handleCall = () => {
    // Mock phone number for demo - in real app this would come from place details
    const phoneNumber = '+66-2-123-4567';
    Linking.openURL(`tel:${phoneNumber}`);
  };

  const handleWebsite = () => {
    // Mock website for demo - in real app this would come from place details
    const website = 'https://example.com';
    Linking.openURL(website);
  };

  return (
    <View style={styles.container}>
      {/* Header Image with Fixed Height */}
      <View style={styles.imageContainer}>
        <Image source={{ uri: business.image }} style={styles.heroImage} />
        <View style={styles.imageOverlay}>
          <TouchableOpacity style={styles.backButton} onPress={handleBack}>
            <ArrowLeft size={24} color={colors.white} />
          </TouchableOpacity>
          <View style={styles.imageActions}>
            <TouchableOpacity style={styles.actionButton} onPress={handleShare}>
              <Share2 size={20} color={colors.white} />
            </TouchableOpacity>
            <TouchableOpacity style={styles.actionButton}>
              <Heart size={20} color={colors.white} />
            </TouchableOpacity>
          </View>
        </View>
      </View>

      {/* Scrollable Content */}
      <ScrollView 
        style={styles.scrollContainer}
        showsVerticalScrollIndicator={false}
        bounces={false}
      >
        <View style={styles.contentContainer}>
          {/* Business Header */}
          <View style={styles.businessHeader}>
            <View style={styles.businessTitleSection}>
              <Text style={styles.businessName} numberOfLines={2}>
                {business.name}
              </Text>
              <Text style={styles.businessCategory}>{business.category}</Text>
            </View>
            <View style={styles.ratingContainer}>
              <Star size={18} color={colors.warning[500]} fill={colors.warning[500]} />
              <Text style={styles.rating}>{business.rating.toFixed(1)}</Text>
            </View>
          </View>

          <Text style={styles.businessDescription}>{business.description}</Text>

          {/* Current Discount - Show First if Active */}
          {business.discount.isActive && (
            <View style={styles.discountSection}>
              <View style={styles.discountHeader}>
                <View style={styles.discountBadge}>
                  <Text style={styles.discountPercentage}>{business.discount.percentage}% OFF</Text>
                </View>
                <Text style={styles.discountTitle} numberOfLines={1}>
                  {business.discount.title}
                </Text>
              </View>
              <Text style={styles.discountDescription} numberOfLines={2}>
                {business.discount.description}
              </Text>
              <View style={styles.discountTime}>
                <Clock size={14} color={colors.secondary[500]} />
                <Text style={styles.discountTimeText}>
                  Valid: {business.discount.validFrom} - {business.discount.validTo}
                </Text>
              </View>
            </View>
          )}

          {/* Location */}
          <View style={styles.locationSection}>
            <View style={styles.locationHeader}>
              <MapPin size={18} color={colors.secondary[600]} />
              <Text style={styles.sectionTitle}>Location</Text>
            </View>
            <Text style={styles.address} numberOfLines={3}>
              {business.address}
            </Text>
            <TouchableOpacity style={styles.directionsButton} onPress={handleGetDirections}>
              <Navigation size={16} color={colors.primary[500]} />
              <Text style={styles.directionsText}>Find "{business.name}" in Google Maps</Text>
            </TouchableOpacity>
          </View>

          {/* Contact Actions */}
          <View style={styles.contactSection}>
            <Text style={styles.sectionTitle}>Contact</Text>
            <View style={styles.contactButtons}>
              <TouchableOpacity style={styles.contactButton} onPress={handleCall}>
                <Phone size={18} color={colors.primary[500]} />
                <Text style={styles.contactButtonText}>Call</Text>
              </TouchableOpacity>
              <TouchableOpacity style={styles.contactButton} onPress={handleWebsite}>
                <Globe size={18} color={colors.primary[500]} />
                <Text style={styles.contactButtonText}>Website</Text>
              </TouchableOpacity>
            </View>
          </View>

          {/* Additional Info */}
          <View style={styles.infoSection}>
            <Text style={styles.sectionTitle}>About</Text>
            <View style={styles.infoGrid}>
              <View style={styles.infoItem}>
                <Text style={styles.infoLabel}>Category</Text>
                <Text style={styles.infoValue} numberOfLines={1}>{business.category}</Text>
              </View>
              <View style={styles.infoItem}>
                <Text style={styles.infoLabel}>Rating</Text>
                <Text style={styles.infoValue}>{business.rating.toFixed(1)}/5.0</Text>
              </View>
              <View style={styles.infoItem}>
                <Text style={styles.infoLabel}>Status</Text>
                <Text style={[styles.infoValue, styles.statusOpen]}>Open Now</Text>
              </View>
              <View style={styles.infoItem}>
                <Text style={styles.infoLabel}>Happy Hour</Text>
                <Text style={[styles.infoValue, business.discount.isActive ? styles.statusActive : styles.statusInactive]}>
                  {business.discount.isActive ? 'Active Now' : 'Not Active'}
                </Text>
              </View>
            </View>
          </View>

          {/* Bottom Padding for Safe Area */}
          <View style={styles.bottomPadding} />
        </View>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.white,
  },
  imageContainer: {
    position: 'relative',
    height: Math.min(screenHeight * 0.35, 280), // Responsive height, max 280px
    width: '100%',
  },
  heroImage: {
    width: '100%',
    height: '100%',
    resizeMode: 'cover',
  },
  imageOverlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    backgroundColor: 'rgba(0,0,0,0.3)',
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    paddingTop: Platform.OS === 'ios' ? 50 : 40, // Account for status bar
    paddingHorizontal: spacing.lg,
  },
  backButton: {
    backgroundColor: 'rgba(0,0,0,0.6)',
    borderRadius: borderRadius.full,
    padding: spacing.sm,
    ...shadows.sm,
  },
  imageActions: {
    flexDirection: 'row',
    gap: spacing.sm,
  },
  actionButton: {
    backgroundColor: 'rgba(0,0,0,0.6)',
    borderRadius: borderRadius.full,
    padding: spacing.sm,
    ...shadows.sm,
  },
  scrollContainer: {
    flex: 1,
  },
  contentContainer: {
    paddingHorizontal: spacing.lg,
    paddingTop: spacing.lg,
  },
  businessHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: spacing.md,
  },
  businessTitleSection: {
    flex: 1,
    marginRight: spacing.md,
  },
  businessName: {
    fontSize: typography.fontSize['2xl'],
    fontFamily: typography.fontFamily.bold,
    color: colors.secondary[900],
    marginBottom: spacing.xs,
    lineHeight: typography.fontSize['2xl'] * 1.2,
  },
  businessCategory: {
    fontSize: typography.fontSize.base,
    fontFamily: typography.fontFamily.medium,
    color: colors.primary[500],
  },
  ratingContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.warning[50],
    paddingHorizontal: spacing.sm,
    paddingVertical: spacing.xs,
    borderRadius: borderRadius.md,
    minWidth: 60,
    justifyContent: 'center',
  },
  rating: {
    marginLeft: spacing.xs,
    fontSize: typography.fontSize.sm,
    fontFamily: typography.fontFamily.bold,
    color: colors.warning[700],
  },
  businessDescription: {
    fontSize: typography.fontSize.base,
    fontFamily: typography.fontFamily.regular,
    color: colors.secondary[600],
    lineHeight: typography.fontSize.base * 1.5,
    marginBottom: spacing.lg,
  },
  discountSection: {
    backgroundColor: colors.primary[50],
    padding: spacing.md,
    borderRadius: borderRadius.lg,
    marginBottom: spacing.lg,
    borderLeftWidth: 4,
    borderLeftColor: colors.primary[500],
  },
  discountHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: spacing.sm,
    flexWrap: 'wrap',
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
  discountTitle: {
    fontSize: typography.fontSize.lg,
    fontFamily: typography.fontFamily.bold,
    color: colors.primary[700],
    flex: 1,
  },
  discountDescription: {
    fontSize: typography.fontSize.base,
    fontFamily: typography.fontFamily.regular,
    color: colors.primary[600],
    marginBottom: spacing.sm,
    lineHeight: typography.fontSize.base * 1.4,
  },
  discountTime: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  discountTimeText: {
    fontSize: typography.fontSize.sm,
    fontFamily: typography.fontFamily.medium,
    color: colors.secondary[600],
    marginLeft: spacing.xs,
  },
  locationSection: {
    backgroundColor: colors.secondary[50],
    padding: spacing.md,
    borderRadius: borderRadius.lg,
    marginBottom: spacing.lg,
  },
  locationHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: spacing.sm,
  },
  sectionTitle: {
    fontSize: typography.fontSize.lg,
    fontFamily: typography.fontFamily.bold,
    color: colors.secondary[900],
    marginLeft: spacing.sm,
  },
  address: {
    fontSize: typography.fontSize.base,
    fontFamily: typography.fontFamily.regular,
    color: colors.secondary[700],
    marginBottom: spacing.md,
    lineHeight: typography.fontSize.base * 1.4,
  },
  directionsButton: {
    flexDirection: 'row',
    alignItems: 'center',
    alignSelf: 'flex-start',
    backgroundColor: colors.white,
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.sm,
    borderRadius: borderRadius.md,
    borderWidth: 1,
    borderColor: colors.primary[200],
  },
  directionsText: {
    fontSize: typography.fontSize.base,
    fontFamily: typography.fontFamily.medium,
    color: colors.primary[500],
    marginLeft: spacing.xs,
  },
  contactSection: {
    marginBottom: spacing.lg,
  },
  contactButtons: {
    flexDirection: 'row',
    gap: spacing.md,
    marginTop: spacing.sm,
  },
  contactButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.primary[50],
    paddingVertical: spacing.md,
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    borderColor: colors.primary[200],
    minHeight: 48, // Ensure touch target is large enough
  },
  contactButtonText: {
    fontSize: typography.fontSize.base,
    fontFamily: typography.fontFamily.medium,
    color: colors.primary[500],
    marginLeft: spacing.sm,
  },
  infoSection: {
    marginBottom: spacing.lg,
  },
  infoGrid: {
    marginTop: spacing.sm,
  },
  infoItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: spacing.sm,
    borderBottomWidth: 1,
    borderBottomColor: colors.secondary[200],
    minHeight: 44, // Ensure adequate spacing
  },
  infoLabel: {
    fontSize: typography.fontSize.base,
    fontFamily: typography.fontFamily.medium,
    color: colors.secondary[600],
    flex: 1,
  },
  infoValue: {
    fontSize: typography.fontSize.base,
    fontFamily: typography.fontFamily.semibold,
    color: colors.secondary[900],
    textAlign: 'right',
    flex: 1,
  },
  statusOpen: {
    color: colors.success[600],
  },
  statusActive: {
    color: colors.primary[600],
  },
  statusInactive: {
    color: colors.secondary[500],
  },
  bottomPadding: {
    height: spacing.xl, // Extra padding at bottom
  },
});