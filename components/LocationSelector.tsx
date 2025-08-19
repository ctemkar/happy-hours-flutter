import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Modal,
  ScrollView,
  TextInput,
  SafeAreaView,
} from 'react-native';
import { Search, MapPin, Clock, X, Globe } from 'lucide-react-native';
import { colors, typography, spacing, borderRadius, shadows } from '@/constants/theme';
import { LocationOption } from '@/types';
import { LocationService } from '@/lib/locationService';

interface LocationSelectorProps {
  visible: boolean;
  onClose: () => void;
  onSelectLocation: (location: LocationOption) => void;
  currentLocation?: LocationOption | null;
}

export default function LocationSelector({
  visible,
  onClose,
  onSelectLocation,
  currentLocation,
}: LocationSelectorProps) {
  const [searchQuery, setSearchQuery] = useState('');
  const [filteredLocations, setFilteredLocations] = useState<LocationOption[]>(
    LocationService.getAllLocations()
  );

  const handleSearch = (query: string) => {
    setSearchQuery(query);
    if (query.trim() === '') {
      setFilteredLocations(LocationService.getAllLocations());
    } else {
      setFilteredLocations(LocationService.searchLocations(query));
    }
  };

  const handleSelectLocation = (location: LocationOption) => {
    onSelectLocation(location);
    onClose();
  };

  const popularLocations = LocationService.getPopularLocations();
  const otherLocations = filteredLocations.filter(loc => !loc.isPopular);

  return (
    <Modal
      visible={visible}
      animationType="slide"
      presentationStyle="pageSheet"
      onRequestClose={onClose}
    >
      <SafeAreaView style={styles.container}>
        <View style={styles.header}>
          <View style={styles.headerContent}>
            <Text style={styles.headerTitle}>Choose Location</Text>
            <Text style={styles.headerSubtitle}>
              Explore happy hours in different cities
            </Text>
          </View>
          <TouchableOpacity style={styles.closeButton} onPress={onClose}>
            <X size={24} color={colors.secondary[600]} />
          </TouchableOpacity>
        </View>

        <View style={styles.searchContainer}>
          <View style={styles.searchInputContainer}>
            <Search size={20} color={colors.secondary[400]} />
            <TextInput
              style={styles.searchInput}
              placeholder="Search cities..."
              value={searchQuery}
              onChangeText={handleSearch}
              placeholderTextColor={colors.secondary[400]}
            />
          </View>
        </View>

        <ScrollView style={styles.locationsContainer} showsVerticalScrollIndicator={false}>
          {searchQuery === '' && (
            <>
              <View style={styles.sectionHeader}>
                <Globe size={18} color={colors.primary[500]} />
                <Text style={styles.sectionTitle}>Popular Destinations</Text>
              </View>
              {popularLocations.map((location) => (
                <LocationItem
                  key={location.id}
                  location={location}
                  isSelected={currentLocation?.id === location.id}
                  onSelect={handleSelectLocation}
                />
              ))}

              {otherLocations.length > 0 && (
                <>
                  <View style={styles.sectionHeader}>
                    <MapPin size={18} color={colors.secondary[500]} />
                    <Text style={styles.sectionTitle}>More Cities</Text>
                  </View>
                  {otherLocations.map((location) => (
                    <LocationItem
                      key={location.id}
                      location={location}
                      isSelected={currentLocation?.id === location.id}
                      onSelect={handleSelectLocation}
                    />
                  ))}
                </>
              )}
            </>
          )}

          {searchQuery !== '' && (
            <>
              <View style={styles.sectionHeader}>
                <Search size={18} color={colors.secondary[500]} />
                <Text style={styles.sectionTitle}>Search Results</Text>
              </View>
              {filteredLocations.length === 0 ? (
                <View style={styles.emptyState}>
                  <Text style={styles.emptyText}>No cities found</Text>
                  <Text style={styles.emptySubtext}>
                    Try searching for a different city name
                  </Text>
                </View>
              ) : (
                filteredLocations.map((location) => (
                  <LocationItem
                    key={location.id}
                    location={location}
                    isSelected={currentLocation?.id === location.id}
                    onSelect={handleSelectLocation}
                  />
                ))
              )}
            </>
          )}
        </ScrollView>
      </SafeAreaView>
    </Modal>
  );
}

interface LocationItemProps {
  location: LocationOption;
  isSelected: boolean;
  onSelect: (location: LocationOption) => void;
}

function LocationItem({ location, isSelected, onSelect }: LocationItemProps) {
  const currentTime = LocationService.getCurrentTimeInLocation(location);

  return (
    <TouchableOpacity
      style={[styles.locationItem, isSelected && styles.locationItemSelected]}
      onPress={() => onSelect(location)}
      activeOpacity={0.7}
    >
      <View style={styles.locationInfo}>
        <Text style={styles.locationName}>{location.name}</Text>
        <Text style={styles.locationCountry}>{location.country}</Text>
        <View style={styles.locationMeta}>
          <Clock size={14} color={colors.secondary[500]} />
          <Text style={styles.locationTime}>{currentTime}</Text>
        </View>
      </View>
      {isSelected && (
        <View style={styles.selectedIndicator}>
          <Text style={styles.selectedText}>✓</Text>
        </View>
      )}
    </TouchableOpacity>
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
    fontSize: typography.fontSize['2xl'],
    fontFamily: typography.fontFamily.bold,
    color: colors.secondary[900],
    marginBottom: spacing.xs,
  },
  headerSubtitle: {
    fontSize: typography.fontSize.base,
    fontFamily: typography.fontFamily.regular,
    color: colors.secondary[600],
  },
  closeButton: {
    padding: spacing.sm,
    backgroundColor: colors.secondary[50],
    borderRadius: borderRadius.full,
  },
  searchContainer: {
    paddingHorizontal: spacing.lg,
    marginBottom: spacing.lg,
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
  locationsContainer: {
    flex: 1,
    paddingHorizontal: spacing.lg,
  },
  sectionHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: spacing.md,
    marginTop: spacing.lg,
  },
  sectionTitle: {
    fontSize: typography.fontSize.lg,
    fontFamily: typography.fontFamily.bold,
    color: colors.secondary[900],
    marginLeft: spacing.sm,
  },
  locationItem: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: colors.white,
    padding: spacing.md,
    borderRadius: borderRadius.lg,
    marginBottom: spacing.sm,
    borderWidth: 1,
    borderColor: colors.secondary[200],
    ...shadows.sm,
  },
  locationItemSelected: {
    borderColor: colors.primary[500],
    backgroundColor: colors.primary[50],
  },
  locationInfo: {
    flex: 1,
  },
  locationName: {
    fontSize: typography.fontSize.lg,
    fontFamily: typography.fontFamily.bold,
    color: colors.secondary[900],
    marginBottom: spacing.xs,
  },
  locationCountry: {
    fontSize: typography.fontSize.base,
    fontFamily: typography.fontFamily.regular,
    color: colors.secondary[600],
    marginBottom: spacing.xs,
  },
  locationMeta: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  locationTime: {
    fontSize: typography.fontSize.sm,
    fontFamily: typography.fontFamily.medium,
    color: colors.secondary[500],
    marginLeft: spacing.xs,
  },
  selectedIndicator: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: colors.primary[500],
    justifyContent: 'center',
    alignItems: 'center',
  },
  selectedText: {
    fontSize: typography.fontSize.base,
    fontFamily: typography.fontFamily.bold,
    color: colors.white,
  },
  emptyState: {
    alignItems: 'center',
    paddingVertical: spacing.xl,
  },
  emptyText: {
    fontSize: typography.fontSize.lg,
    fontFamily: typography.fontFamily.semibold,
    color: colors.secondary[700],
    marginBottom: spacing.xs,
  },
  emptySubtext: {
    fontSize: typography.fontSize.base,
    fontFamily: typography.fontFamily.regular,
    color: colors.secondary[500],
    textAlign: 'center',
  },
});