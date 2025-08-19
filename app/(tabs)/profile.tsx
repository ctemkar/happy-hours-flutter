import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  SafeAreaView,
  TouchableOpacity,
  ScrollView,
  Alert,
} from 'react-native';
import { User, Settings, Bell, MapPin, CreditCard, CircleHelp as HelpCircle, Shield, ChevronRight, Heart, Globe } from 'lucide-react-native';

const colors = {
  primary: '#f97316',
  secondary: '#64748b',
  white: '#ffffff',
};

const spacing = {
  xs: 4,
  sm: 8,
  md: 16,
  lg: 24,
  xl: 32,
};

const borderRadius = {
  md: 8,
  lg: 12,
  xl: 16,
  full: 9999,
};

const shadows = {
  sm: {
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 2,
    elevation: 1,
  },
  md: {
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.1,
    shadowRadius: 6,
    elevation: 3,
  },
};

export default function ProfileScreen() {
  const handleMenuItemPress = (title: string) => {
    Alert.alert(title, `${title} functionality will be implemented soon.`);
  };

  const menuItems = [
    {
      icon: Heart,
      title: 'Saved Places',
      subtitle: '3 places bookmarked',
      onPress: () => handleMenuItemPress('Saved Places'),
    },
    {
      icon: Globe,
      title: 'Location Preferences',
      subtitle: 'Currently exploring Bangkok',
      onPress: () => handleMenuItemPress('Location Preferences'),
    },
    {
      icon: Settings,
      title: 'Account Settings',
      subtitle: 'Manage your account preferences',
      onPress: () => handleMenuItemPress('Account Settings'),
    },
    {
      icon: Bell,
      title: 'Notifications',
      subtitle: 'Configure your notification preferences',
      onPress: () => handleMenuItemPress('Notifications'),
    },
    {
      icon: MapPin,
      title: 'Location Services',
      subtitle: 'Manage location permissions',
      onPress: () => handleMenuItemPress('Location Services'),
    },
    {
      icon: CreditCard,
      title: 'Payment Methods',
      subtitle: 'Add or remove payment options',
      onPress: () => handleMenuItemPress('Payment Methods'),
    },
    {
      icon: HelpCircle,
      title: 'Help & Support',
      subtitle: 'Get help or contact support',
      onPress: () => handleMenuItemPress('Help & Support'),
    },
    {
      icon: Shield,
      title: 'Privacy & Security',
      subtitle: 'Manage your privacy settings',
      onPress: () => handleMenuItemPress('Privacy & Security'),
    },
  ];

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView showsVerticalScrollIndicator={false}>
        <View style={styles.header}>
          <Text style={styles.headerTitle}>Profile</Text>
        </View>

        <View style={styles.profileCard}>
          <View style={styles.avatarContainer}>
            <User size={48} color={colors.primary} />
          </View>
          <View style={styles.profileInfo}>
            <Text style={styles.profileName}>Guest User</Text>
            <Text style={styles.profileEmail}>Not signed in</Text>
          </View>
        </View>

        <View style={styles.currentLocationCard}>
          <View style={styles.currentLocationHeader}>
            <Globe size={20} color={colors.primary} />
            <Text style={styles.currentLocationTitle}>Current Location</Text>
          </View>
          <Text style={styles.currentLocationName}>Bangkok, Thailand</Text>
          <Text style={styles.currentLocationTime}>
            Local time: {new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
          </Text>
          <TouchableOpacity style={styles.changeLocationButton}>
            <Text style={styles.changeLocationText}>Change Location</Text>
          </TouchableOpacity>
        </View>

        <View style={styles.menuSection}>
          {menuItems.map((item, index) => (
            <TouchableOpacity
              key={item.title}
              style={[
                styles.menuItem,
                index === menuItems.length - 1 && styles.menuItemLast
              ]}
              onPress={item.onPress}
            >
              <View style={styles.menuItemLeft}>
                <View style={styles.menuIconContainer}>
                  <item.icon size={20} color={colors.secondary} />
                </View>
                <View style={styles.menuItemContent}>
                  <Text style={styles.menuItemTitle}>{item.title}</Text>
                  <Text style={styles.menuItemSubtitle}>{item.subtitle}</Text>
                </View>
              </View>
              <ChevronRight size={20} color="#94a3b8" />
            </TouchableOpacity>
          ))}
        </View>

        <View style={styles.footer}>
          <Text style={styles.footerText}>Happy Arz App v1.0.0</Text>
          <Text style={styles.footerSubtext}>
            Discover amazing discounts at venues worldwide
          </Text>
        </View>
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
    paddingHorizontal: spacing.lg,
    paddingTop: spacing.lg,
    paddingBottom: spacing.md,
  },
  headerTitle: {
    fontSize: 30,
    fontFamily: 'PlayfairDisplay-Bold',
    color: '#0f172a',
  },
  profileCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.white,
    marginHorizontal: spacing.lg,
    padding: spacing.lg,
    borderRadius: borderRadius.xl,
    marginBottom: spacing.lg,
    ...shadows.md,
  },
  avatarContainer: {
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: '#fef7ee',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: spacing.md,
  },
  profileInfo: {
    flex: 1,
  },
  profileName: {
    fontSize: 20,
    fontFamily: 'Inter-Bold',
    color: '#0f172a',
    marginBottom: spacing.xs,
  },
  profileEmail: {
    fontSize: 16,
    fontFamily: 'Inter-Regular',
    color: colors.secondary,
  },
  currentLocationCard: {
    backgroundColor: '#fef7ee',
    marginHorizontal: spacing.lg,
    padding: spacing.md,
    borderRadius: borderRadius.lg,
    marginBottom: spacing.lg,
    borderLeftWidth: 4,
    borderLeftColor: colors.primary,
  },
  currentLocationHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: spacing.sm,
  },
  currentLocationTitle: {
    fontSize: 16,
    fontFamily: 'Inter-SemiBold',
    color: '#ea580c',
    marginLeft: spacing.sm,
  },
  currentLocationName: {
    fontSize: 18,
    fontFamily: 'Inter-Bold',
    color: '#0f172a',
    marginBottom: spacing.xs,
  },
  currentLocationTime: {
    fontSize: 14,
    fontFamily: 'Inter-Regular',
    color: colors.secondary,
    marginBottom: spacing.md,
  },
  changeLocationButton: {
    alignSelf: 'flex-start',
    backgroundColor: colors.primary,
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.sm,
    borderRadius: borderRadius.md,
  },
  changeLocationText: {
    fontSize: 14,
    fontFamily: 'Inter-SemiBold',
    color: colors.white,
  },
  menuSection: {
    marginHorizontal: spacing.lg,
    backgroundColor: colors.white,
    borderRadius: borderRadius.xl,
    marginBottom: spacing.lg,
    ...shadows.sm,
  },
  menuItem: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: spacing.md,
    borderBottomWidth: 1,
    borderBottomColor: '#e2e8f0',
  },
  menuItemLast: {
    borderBottomWidth: 0,
  },
  menuItemLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  menuIconContainer: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: '#f1f5f9',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: spacing.md,
  },
  menuItemContent: {
    flex: 1,
  },
  menuItemTitle: {
    fontSize: 16,
    fontFamily: 'Inter-SemiBold',
    color: '#0f172a',
    marginBottom: spacing.xs,
  },
  menuItemSubtitle: {
    fontSize: 14,
    fontFamily: 'Inter-Regular',
    color: colors.secondary,
  },
  footer: {
    alignItems: 'center',
    paddingHorizontal: spacing.lg,
    paddingBottom: spacing.xl,
  },
  footerText: {
    fontSize: 14,
    fontFamily: 'Inter-Medium',
    color: colors.secondary,
    marginBottom: spacing.xs,
  },
  footerSubtext: {
    fontSize: 14,
    fontFamily: 'Inter-Regular',
    color: '#94a3b8',
    textAlign: 'center',
  },
});