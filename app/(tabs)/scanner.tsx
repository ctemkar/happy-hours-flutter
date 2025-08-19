import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  SafeAreaView,
  TouchableOpacity,
  Alert,
  Platform,
  Image,
} from 'react-native';
import { Camera, Image as ImageIcon, Zap, CircleCheck as CheckCircle } from 'lucide-react-native';

const colors = {
  primary: '#f97316',
  secondary: '#64748b',
  success: '#22c55e',
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
  sm: 4,
  md: 8,
  lg: 12,
  xl: 16,
};

const shadows = {
  md: {
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.1,
    shadowRadius: 6,
    elevation: 3,
  },
  sm: {
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 2,
    elevation: 1,
  },
};

export default function ScannerScreen() {
  const [scannedImage, setScannedImage] = useState<string | null>(null);
  const [scanResult, setScanResult] = useState<any>(null);
  const [isScanning, setIsScanning] = useState(false);

  const simulateScan = async (imageUri: string) => {
    setIsScanning(true);
    setScannedImage(imageUri);
    
    // Simulate AI processing delay
    await new Promise(resolve => setTimeout(resolve, 2000));
    
    // Mock scan result
    const mockResult = {
      items: [
        { name: 'Pad Thai', price: 180, discount: 25 },
        { name: 'Tom Yum Soup', price: 120, discount: 30 },
        { name: 'Green Curry', price: 200, discount: 20 },
        { name: 'Mango Sticky Rice', price: 80, discount: 15 },
      ],
      restaurant: 'Thai Fusion Kitchen',
      totalSavings: 145,
    };
    
    setScanResult(mockResult);
    setIsScanning(false);
  };

  const takePicture = async () => {
    if (Platform.OS === 'web') {
      Alert.alert('Camera not available', 'Camera functionality is not available on web. Please use the gallery option.');
      return;
    }

    try {
      // For now, simulate taking a picture with a placeholder image
      const placeholderImage = 'https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg?auto=compress&cs=tinysrgb&w=600&h=400&fit=crop';
      simulateScan(placeholderImage);
    } catch (error) {
      console.error('Camera error:', error);
      Alert.alert('Error', 'Failed to access camera. Please try again.');
    }
  };

  const pickImage = async () => {
    try {
      // For now, simulate picking an image with a placeholder
      const placeholderImage = 'https://images.pexels.com/photos/1267320/pexels-photo-1267320.jpeg?auto=compress&cs=tinysrgb&w=600&h=400&fit=crop';
      simulateScan(placeholderImage);
    } catch (error) {
      Alert.alert('Error', 'Failed to pick image from gallery');
    }
  };

  const resetScanner = () => {
    setScannedImage(null);
    setScanResult(null);
    setIsScanning(false);
  };

  if (scanResult) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.header}>
          <Text style={styles.headerTitle}>Scan Results</Text>
          <TouchableOpacity onPress={resetScanner}>
            <Text style={styles.resetText}>Scan Again</Text>
          </TouchableOpacity>
        </View>

        <View style={styles.resultContainer}>
          <View style={styles.successHeader}>
            <CheckCircle size={32} color={colors.success} />
            <Text style={styles.successTitle}>Menu Scanned Successfully!</Text>
            <Text style={styles.restaurantName}>{scanResult.restaurant}</Text>
          </View>

          {scannedImage && (
            <Image source={{ uri: scannedImage }} style={styles.scannedImage} />
          )}

          <View style={styles.savingsCard}>
            <Text style={styles.savingsTitle}>Total Potential Savings</Text>
            <Text style={styles.savingsAmount}>฿{scanResult.totalSavings}</Text>
          </View>

          <View style={styles.itemsList}>
            <Text style={styles.itemsTitle}>Discounted Items Found</Text>
            {scanResult.items.map((item: any, index: number) => (
              <View key={index} style={styles.itemCard}>
                <View style={styles.itemInfo}>
                  <Text style={styles.itemName}>{item.name}</Text>
                  <Text style={styles.itemPrice}>฿{item.price}</Text>
                </View>
                <View style={styles.discountBadge}>
                  <Text style={styles.discountText}>{item.discount}% OFF</Text>
                </View>
              </View>
            ))}
          </View>
        </View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Menu Scanner</Text>
        <Text style={styles.headerSubtitle}>Scan menus to find hidden discounts</Text>
      </View>

      {isScanning ? (
        <View style={styles.scanningContainer}>
          <Zap size={64} color={colors.primary} />
          <Text style={styles.scanningTitle}>Analyzing Menu...</Text>
          <Text style={styles.scanningText}>Our AI is finding the best discounts for you</Text>
          {scannedImage && (
            <Image source={{ uri: scannedImage }} style={styles.processingImage} />
          )}
        </View>
      ) : (
        <View style={styles.scannerOptions}>
          <TouchableOpacity
            style={styles.scanOption}
            onPress={takePicture}
          >
            <Camera size={48} color={colors.primary} />
            <Text style={styles.scanOptionTitle}>Take Photo</Text>
            <Text style={styles.scanOptionText}>
              Point your camera at a menu to scan for discounts
            </Text>
          </TouchableOpacity>

          <TouchableOpacity style={styles.scanOption} onPress={pickImage}>
            <ImageIcon size={48} color={colors.primary} />
            <Text style={styles.scanOptionTitle}>Choose from Gallery</Text>
            <Text style={styles.scanOptionText}>
              Select a menu photo from your device
            </Text>
          </TouchableOpacity>
        </View>
      )}

      <View style={styles.infoSection}>
        <Text style={styles.infoTitle}>How it works</Text>
        <View style={styles.infoSteps}>
          <View style={styles.infoStep}>
            <Text style={styles.stepNumber}>1</Text>
            <Text style={styles.stepText}>Scan or upload a menu photo</Text>
          </View>
          <View style={styles.infoStep}>
            <Text style={styles.stepNumber}>2</Text>
            <Text style={styles.stepText}>AI analyzes items and prices</Text>
          </View>
          <View style={styles.infoStep}>
            <Text style={styles.stepNumber}>3</Text>
            <Text style={styles.stepText}>Get personalized discount recommendations</Text>
          </View>
        </View>
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
    paddingHorizontal: spacing.lg,
    paddingTop: spacing.lg,
    paddingBottom: spacing.md,
  },
  headerTitle: {
    fontSize: 30,
    fontFamily: 'PlayfairDisplay-Bold',
    color: '#0f172a',
    marginBottom: spacing.xs,
  },
  headerSubtitle: {
    fontSize: 16,
    fontFamily: 'Inter-Regular',
    color: colors.secondary,
  },
  resetText: {
    fontSize: 16,
    fontFamily: 'Inter-Medium',
    color: colors.primary,
  },
  scannerOptions: {
    flex: 1,
    paddingHorizontal: spacing.lg,
    justifyContent: 'center',
  },
  scanOption: {
    backgroundColor: colors.white,
    padding: spacing.xl,
    borderRadius: borderRadius.xl,
    alignItems: 'center',
    marginBottom: spacing.lg,
    ...shadows.md,
  },
  scanOptionTitle: {
    fontSize: 20,
    fontFamily: 'Inter-Bold',
    color: '#0f172a',
    marginTop: spacing.md,
    marginBottom: spacing.sm,
  },
  scanOptionText: {
    fontSize: 16,
    fontFamily: 'Inter-Regular',
    color: colors.secondary,
    textAlign: 'center',
    lineHeight: 22,
  },
  scanningContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: spacing.xl,
  },
  scanningTitle: {
    fontSize: 20,
    fontFamily: 'Inter-Bold',
    color: '#0f172a',
    marginTop: spacing.lg,
    marginBottom: spacing.sm,
  },
  scanningText: {
    fontSize: 16,
    fontFamily: 'Inter-Regular',
    color: colors.secondary,
    textAlign: 'center',
    marginBottom: spacing.lg,
  },
  processingImage: {
    width: 200,
    height: 150,
    borderRadius: borderRadius.lg,
  },
  resultContainer: {
    flex: 1,
    paddingHorizontal: spacing.lg,
  },
  successHeader: {
    alignItems: 'center',
    marginBottom: spacing.lg,
  },
  successTitle: {
    fontSize: 20,
    fontFamily: 'Inter-Bold',
    color: '#16a34a',
    marginTop: spacing.sm,
    marginBottom: spacing.xs,
  },
  restaurantName: {
    fontSize: 16,
    fontFamily: 'Inter-Medium',
    color: '#334155',
  },
  scannedImage: {
    width: '100%',
    height: 150,
    borderRadius: borderRadius.lg,
    marginBottom: spacing.lg,
  },
  savingsCard: {
    backgroundColor: '#f0fdf4',
    padding: spacing.lg,
    borderRadius: borderRadius.xl,
    alignItems: 'center',
    marginBottom: spacing.lg,
  },
  savingsTitle: {
    fontSize: 16,
    fontFamily: 'Inter-Medium',
    color: '#15803d',
    marginBottom: spacing.xs,
  },
  savingsAmount: {
    fontSize: 30,
    fontFamily: 'Inter-Bold',
    color: '#16a34a',
  },
  itemsList: {
    flex: 1,
  },
  itemsTitle: {
    fontSize: 18,
    fontFamily: 'Inter-Bold',
    color: '#0f172a',
    marginBottom: spacing.md,
  },
  itemCard: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    backgroundColor: colors.white,
    padding: spacing.md,
    borderRadius: borderRadius.lg,
    marginBottom: spacing.sm,
    ...shadows.sm,
  },
  itemInfo: {
    flex: 1,
  },
  itemName: {
    fontSize: 16,
    fontFamily: 'Inter-SemiBold',
    color: '#0f172a',
    marginBottom: spacing.xs,
  },
  itemPrice: {
    fontSize: 14,
    fontFamily: 'Inter-Regular',
    color: colors.secondary,
  },
  discountBadge: {
    backgroundColor: colors.primary,
    paddingHorizontal: spacing.sm,
    paddingVertical: spacing.xs,
    borderRadius: borderRadius.md,
  },
  discountText: {
    fontSize: 12,
    fontFamily: 'Inter-Bold',
    color: colors.white,
  },
  infoSection: {
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.lg,
    backgroundColor: '#f1f5f9',
  },
  infoTitle: {
    fontSize: 18,
    fontFamily: 'Inter-Bold',
    color: '#0f172a',
    marginBottom: spacing.md,
  },
  infoSteps: {
    gap: spacing.md,
  },
  infoStep: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  stepNumber: {
    width: 24,
    height: 24,
    borderRadius: 12,
    backgroundColor: colors.primary,
    color: colors.white,
    fontSize: 14,
    fontFamily: 'Inter-Bold',
    textAlign: 'center',
    lineHeight: 24,
    marginRight: spacing.sm,
  },
  stepText: {
    flex: 1,
    fontSize: 16,
    fontFamily: 'Inter-Regular',
    color: '#334155',
  },
});