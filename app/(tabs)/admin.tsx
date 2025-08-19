import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  SafeAreaView,
  ScrollView,
  TouchableOpacity,
  Alert,
  ActivityIndicator,
  Platform,
} from 'react-native';
import { Upload, CircleCheck as CheckCircle, CircleAlert as AlertCircle, RefreshCw, FileText, Calendar, ChartBar as BarChart3, Shield, Database } from 'lucide-react-native';
import { colors, typography, spacing, borderRadius, shadows } from '@/constants/theme';
import { VerifiedBusinessService } from '@/lib/verifiedBusinessService';
import { Business } from '@/types';
import * as DocumentPicker from 'expo-document-picker';
import ApiTester from '@/components/ApiTester';
import DataCollectionHelper from '@/components/DataCollectionHelper';

// Define a type for upload history entries for better type safety
interface UploadHistoryEntry {
  timestamp: string;
  processedRows: number;
  errors: number;
}

// Define a more specific type for the upload result summary
interface UploadSummary {
  total: number;
  processed: number;
  errors: number;
}

// Define a type for the full upload result
interface UploadResult {
  businesses: Business[];
  errors: string[];
  summary: UploadSummary;
}

export default function AdminScreen() {
  const [verifiedBusinesses, setVerifiedBusinesses] = useState<Business[]>([]);
  const [loading, setLoading] = useState(false);
  const [uploadHistory, setUploadHistory] = useState<UploadHistoryEntry[]>([]);
  const [uploadResult, setUploadResult] = useState<UploadResult | null>(null);
  const [showDataHelper, setShowDataHelper] = useState(false);

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    setLoading(true);
    try {
      const [businesses, history] = await Promise.all([
        VerifiedBusinessService.getVerifiedBusinesses(),
        VerifiedBusinessService.getUploadHistory(),
      ]);

      setVerifiedBusinesses(businesses);
      setUploadHistory(history);
    } catch (error) {
      console.error('Error loading data:', error);
      Alert.alert('Error', 'Failed to load admin data. Please check your connection.');
    } finally {
      setLoading(false);
    }
  };

  const handleFileUpload = async () => {
    try {
      const result = await DocumentPicker.getDocumentAsync({
        type: ['text/csv', 'text/tab-separated-values', 'text/plain'],
        copyToCacheDirectory: true,
      });

      if (!result.canceled && result.assets && result.assets[0]) {
        setLoading(true);

        const response = await fetch(result.assets[0].uri);
        const csvData = await response.text();

        const processResult = await VerifiedBusinessService.processSpreadsheetData(csvData);

        setUploadResult(processResult);

        if (processResult.businesses.length > 0) {
          await VerifiedBusinessService.saveVerifiedBusinesses(processResult.businesses);
          setVerifiedBusinesses(processResult.businesses);
        }

        await loadData(); // Refresh all data including upload history and stats
        
        Alert.alert(
          'Upload Complete',
          `Successfully processed ${processResult.summary.processed} businesses with ${processResult.summary.errors} errors.`
        );
      }
    } catch (error) {
      console.error('Error uploading file:', error);
      Alert.alert('Error', 'Failed to upload and process file. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const handleRefreshData = async () => {
    await loadData();
  };

  const renderUploadResult = () => {
    if (!uploadResult) return null;

    return (
      <View style={styles.resultContainer}>
        <Text style={styles.resultTitle}>Upload Results</Text>

        <View style={styles.summaryCards}>
          <View style={styles.summaryCard}>
            <Text style={styles.summaryNumber}>{uploadResult.summary.total}</Text>
            <Text style={styles.summaryLabel}>Total Rows</Text>
          </View>
          <View style={[styles.summaryCard, styles.successCard]}>
            <Text style={styles.summaryNumber}>{uploadResult.summary.processed}</Text>
            <Text style={styles.summaryLabel}>Processed</Text>
          </View>
          <View style={[styles.summaryCard, styles.errorCard]}>
            <Text style={styles.summaryNumber}>{uploadResult.summary.errors}</Text>
            <Text style={styles.summaryLabel}>Errors</Text>
          </View>
        </View>

        {uploadResult.errors.length > 0 && (
          <View style={styles.errorsContainer}>
            <Text style={styles.errorsTitle}>Errors:</Text>
            {uploadResult.errors.slice(0, 5).map((error, index) => (
              <Text key={`error-${index}`} style={styles.errorText}>
                • {error}
              </Text>
            ))}
            {uploadResult.errors.length > 5 && (
              <Text style={styles.errorText}>
                ... and {uploadResult.errors.length - 5} more
              </Text>
            )}
          </View>
        )}
      </View>
    );
  };

  if (showDataHelper) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.helperHeader}>
          <TouchableOpacity
            style={styles.backButton}
            onPress={() => setShowDataHelper(false)}
          >
            <Text style={styles.backButtonText}>← Back to Admin</Text>
          </TouchableOpacity>
        </View>
        <DataCollectionHelper />
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView showsVerticalScrollIndicator={false}>
        <View style={styles.header}>
          <Shield size={32} color={colors.primary[500]} />
          <View style={styles.headerContent}>
            <Text style={styles.headerTitle}>Admin Panel</Text>
            <Text style={styles.headerSubtitle}>Manage verified businesses</Text>
          </View>
          <TouchableOpacity
            style={styles.refreshButton}
            onPress={handleRefreshData}
            disabled={loading}
            accessibilityRole="button"
            accessibilityLabel="Refresh admin data"
          >
            {loading ? (
              <ActivityIndicator size="small" color={colors.primary[500]} />
            ) : (
              <RefreshCw size={20} color={colors.primary[500]} />
            )}
          </TouchableOpacity>
        </View>

        {/* Data Collection Helper */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Data Collection Assistant</Text>
          <Text style={styles.sectionDescription}>
            Get help collecting happy hour data for Pattaya businesses.
          </Text>
          
          <TouchableOpacity
            style={styles.helperButton}
            onPress={() => setShowDataHelper(true)}
          >
            <Database size={20} color={colors.white} />
            <Text style={styles.helperButtonText}>Open Data Collection Guide</Text>
          </TouchableOpacity>
        </View>

        {/* API Key Test Section */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Google Places API Test</Text>
          <Text style={styles.sectionDescription}>
            Test your Google Places API key to ensure it's working correctly.
          </Text>
          <ApiTester />
        </View>

        {/* File Upload Section */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Business Data Upload</Text>
          <Text style={styles.sectionDescription}>
            Upload a CSV file with verified business data to add new businesses to the platform.
          </Text>

          <View style={styles.uploadCard}>
            <View style={styles.uploadInstructions}>
              <Text style={styles.instructionsTitle}>CSV Format Requirements:</Text>
              <Text style={styles.instructionText}>
                • First row should contain column headers
              </Text>
              <Text style={styles.instructionText}>
                • Required columns: name, description, address
              </Text>
              <Text style={styles.instructionText}>
                • Optional columns: picture, telephone, website, category
              </Text>
              <Text style={styles.instructionText}>
                • Happy hour columns: happyHourStart, happyHourEnd
              </Text>
            </View>

            <TouchableOpacity
              style={[styles.uploadButton, loading && styles.disabledButton]}
              onPress={handleFileUpload}
              disabled={loading}
              accessibilityRole="button"
              accessibilityLabel="Upload CSV file with business data"
            >
              {loading ? (
                <ActivityIndicator size="small" color={colors.white} />
              ) : (
                <Upload size={20} color={colors.white} />
              )}
              <Text style={styles.uploadButtonText}>
                {loading ? 'Processing...' : 'Upload CSV File'}
              </Text>
            </TouchableOpacity>
          </View>
        </View>

        {/* Upload Results */}
        {renderUploadResult()}

        {/* Statistics */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Statistics</Text>

          <View style={styles.statsGrid}>
            <View style={styles.statCard}>
              <View style={styles.statIcon}>
                <CheckCircle size={24} color={colors.success[500]} />
              </View>
              <Text style={styles.statNumber}>{verifiedBusinesses.length}</Text>
              <Text style={styles.statLabel}>Verified Businesses</Text>
            </View>

            <View style={styles.statCard}>
              <View style={styles.statIcon}>
                <FileText size={24} color={colors.primary[500]} />
              </View>
              <Text style={styles.statNumber}>{uploadHistory.length}</Text>
              <Text style={styles.statLabel}>Total Uploads</Text>
            </View>

            <View style={styles.statCard}>
              <View style={styles.statIcon}>
                <BarChart3 size={24} color={colors.secondary[500]} />
              </View>
              <Text style={styles.statNumber}>
                {uploadHistory.reduce((sum, entry) => sum + entry.processedRows, 0)}
              </Text>
              <Text style={styles.statLabel}>Rows Processed</Text>
            </View>

            <View style={styles.statCard}>
              <View style={styles.statIcon}>
                <AlertCircle size={24} color={colors.error[500]} />
              </View>
              <Text style={styles.statNumber}>
                {uploadHistory.reduce((sum, entry) => sum + entry.errors, 0)}
              </Text>
              <Text style={styles.statLabel}>Total Errors</Text>
            </View>
          </View>
        </View>

        {/* Active Businesses Preview */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Recent Verified Businesses</Text>
          
          {verifiedBusinesses.length === 0 ? (
            <View style={styles.emptyState}>
              <CheckCircle size={48} color={colors.secondary[400]} />
              <Text style={styles.emptyStateText}>No verified businesses yet</Text>
              <Text style={styles.emptyStateSubtext}>
                Upload your first CSV file to add verified businesses
              </Text>
            </View>
          ) : (
            <View style={styles.businessesList}>
              {verifiedBusinesses.slice(0, 5).map((business) => (
                <View key={business.id} style={styles.businessItem}>
                  <View style={styles.businessIcon}>
                    <CheckCircle size={16} color={colors.success[600]} />
                  </View>
                  <View style={styles.businessContent}>
                    <Text style={styles.businessName}>{business.name}</Text>
                    <Text style={styles.businessCategory}>{business.category}</Text>
                    <Text style={styles.businessAddress} numberOfLines={1}>
                      {business.location.address}
                    </Text>
                    {business.currentDiscount && (
                      <Text style={styles.businessDiscount}>
                        {business.currentDiscount.percentage}% OFF • {business.currentDiscount.title}
                      </Text>
                    )}
                  </View>
                  <View style={styles.businessStatus}>
                    {business.isActive ? (
                      <CheckCircle size={16} color={colors.success[500]} />
                    ) : (
                      <AlertCircle size={16} color={colors.warning[500]} />
                    )}
                  </View>
                </View>
              ))}
              {verifiedBusinesses.length > 5 && (
                <Text style={styles.businessesMoreText}>
                  View all {verifiedBusinesses.length} verified businesses...
                </Text>
              )}
            </View>
          )}
        </View>

        {/* Upload History */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Upload History</Text>

          {uploadHistory.length === 0 ? (
            <View style={styles.emptyState}>
              <FileText size={48} color={colors.secondary[400]} />
              <Text style={styles.emptyStateText}>No upload history yet</Text>
              <Text style={styles.emptyStateSubtext}>
                Upload your first CSV file to see history here
              </Text>
            </View>
          ) : (
            <View style={styles.historyList}>
              {uploadHistory.slice(0, 5).map((entry) => (
                <View key={entry.timestamp} style={styles.historyItem}>
                  <View style={styles.historyIcon}>
                    <Calendar size={16} color={colors.secondary[600]} />
                  </View>
                  <View style={styles.historyContent}>
                    <Text style={styles.historyDate}>
                      {new Date(entry.timestamp).toLocaleString()}
                    </Text>
                    <Text style={styles.historyDetails}>
                      {entry.processedRows} processed, {entry.errors} errors
                    </Text>
                  </View>
                  <View style={styles.historyStatus}>
                    {entry.errors === 0 ? (
                      <CheckCircle size={16} color={colors.success[500]} />
                    ) : (
                      <AlertCircle size={16} color={colors.warning[500]} />
                    )}
                  </View>
                </View>
              ))}
              {uploadHistory.length > 5 && (
                <Text style={styles.historyMoreText}>
                  View all {uploadHistory.length} uploads...
                </Text>
              )}
            </View>
          )}
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
  helperHeader: {
    paddingHorizontal: spacing.lg,
    paddingTop: spacing.md,
    paddingBottom: spacing.sm,
    borderBottomWidth: 1,
    borderBottomColor: colors.secondary[200],
  },
  backButton: {
    alignSelf: 'flex-start',
  },
  backButtonText: {
    fontSize: typography.fontSize.base,
    fontFamily: typography.fontFamily.medium,
    color: colors.primary[500],
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: spacing.lg,
    paddingTop: spacing.lg,
    paddingBottom: spacing.md,
  },
  headerContent: {
    marginLeft: spacing.md,
    flex: 1,
  },
  headerTitle: {
    fontSize: typography.fontSize['2xl'],
    fontFamily: typography.fontFamily.bold,
    color: colors.secondary[900],
  },
  headerSubtitle: {
    fontSize: typography.fontSize.base,
    fontFamily: typography.fontFamily.regular,
    color: colors.secondary[600],
  },
  refreshButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: colors.primary[50],
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: colors.primary[200],
  },
  section: {
    paddingHorizontal: spacing.lg,
    marginBottom: spacing.xl,
  },
  sectionTitle: {
    fontSize: typography.fontSize.lg,
    fontFamily: typography.fontFamily.bold,
    color: colors.secondary[900],
    marginBottom: spacing.xs,
  },
  sectionDescription: {
    fontSize: typography.fontSize.base,
    fontFamily: typography.fontFamily.regular,
    color: colors.secondary[600],
    marginBottom: spacing.md,
    lineHeight: typography.fontSize.base * 1.4,
  },
  helperButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.secondary[600],
    paddingVertical: spacing.md,
    borderRadius: borderRadius.lg,
    ...shadows.sm,
  },
  helperButtonText: {
    fontSize: typography.fontSize.base,
    fontFamily: typography.fontFamily.semibold,
    color: colors.white,
    marginLeft: spacing.sm,
  },
  uploadCard: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.lg,
    padding: spacing.md,
    borderWidth: 1,
    borderColor: colors.secondary[200],
    ...shadows.sm,
  },
  uploadInstructions: {
    backgroundColor: colors.secondary[50],
    padding: spacing.md,
    borderRadius: borderRadius.md,
    marginBottom: spacing.md,
  },
  instructionsTitle: {
    fontSize: typography.fontSize.base,
    fontFamily: typography.fontFamily.bold,
    color: colors.secondary[900],
    marginBottom: spacing.sm,
  },
  instructionText: {
    fontSize: typography.fontSize.sm,
    fontFamily: typography.fontFamily.regular,
    color: colors.secondary[600],
    marginBottom: spacing.xs,
    lineHeight: typography.fontSize.sm * 1.4,
  },
  uploadButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.primary[500],
    paddingVertical: spacing.md,
    borderRadius: borderRadius.lg,
    ...shadows.sm,
  },
  uploadButtonText: {
    fontSize: typography.fontSize.base,
    fontFamily: typography.fontFamily.semibold,
    color: colors.white,
    marginLeft: spacing.sm,
  },
  disabledButton: {
    backgroundColor: colors.secondary[300],
    opacity: 0.7,
  },
  resultContainer: {
    backgroundColor: colors.secondary[50],
    marginHorizontal: spacing.lg,
    padding: spacing.md,
    borderRadius: borderRadius.lg,
    marginBottom: spacing.lg,
    borderWidth: 1,
    borderColor: colors.secondary[200],
  },
  resultTitle: {
    fontSize: typography.fontSize.lg,
    fontFamily: typography.fontFamily.bold,
    color: colors.secondary[900],
    marginBottom: spacing.md,
  },
  summaryCards: {
    flexDirection: 'row',
    gap: spacing.sm,
    marginBottom: spacing.md,
  },
  summaryCard: {
    flex: 1,
    backgroundColor: colors.white,
    padding: spacing.sm,
    borderRadius: borderRadius.md,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: colors.secondary[100],
  },
  successCard: {
    backgroundColor: colors.success[50],
    borderColor: colors.success[200],
  },
  errorCard: {
    backgroundColor: colors.error[50],
    borderColor: colors.error[200],
  },
  summaryNumber: {
    fontSize: typography.fontSize.xl,
    fontFamily: typography.fontFamily.bold,
    color: colors.secondary[900],
  },
  summaryLabel: {
    fontSize: typography.fontSize.sm,
    fontFamily: typography.fontFamily.medium,
    color: colors.secondary[600],
  },
  errorsContainer: {
    backgroundColor: colors.error[50],
    padding: spacing.sm,
    borderRadius: borderRadius.md,
    borderWidth: 1,
    borderColor: colors.error[100],
  },
  errorsTitle: {
    fontSize: typography.fontSize.base,
    fontFamily: typography.fontFamily.semibold,
    color: colors.error[700],
    marginBottom: spacing.xs,
  },
  errorText: {
    fontSize: typography.fontSize.sm,
    fontFamily: typography.fontFamily.regular,
    color: colors.error[600],
    marginBottom: spacing.xs,
  },
  statsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing.sm,
    justifyContent: 'space-between',
  },
  statCard: {
    flex: 1,
    minWidth: '48%',
    maxWidth: '48%',
    backgroundColor: colors.white,
    padding: spacing.md,
    borderRadius: borderRadius.lg,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: colors.secondary[200],
    ...shadows.sm,
    marginBottom: spacing.sm,
  },
  statIcon: {
    marginBottom: spacing.sm,
  },
  statNumber: {
    fontSize: typography.fontSize.xl,
    fontFamily: typography.fontFamily.bold,
    color: colors.secondary[900],
  },
  statLabel: {
    fontSize: typography.fontSize.sm,
    fontFamily: typography.fontFamily.medium,
    color: colors.secondary[600],
    textAlign: 'center',
    marginTop: spacing.xs,
  },
  emptyState: {
    alignItems: 'center',
    paddingVertical: spacing.xl,
    borderWidth: 1,
    borderColor: colors.secondary[100],
    borderRadius: borderRadius.lg,
    backgroundColor: colors.white,
  },
  emptyStateText: {
    fontSize: typography.fontSize.lg,
    fontFamily: typography.fontFamily.semibold,
    color: colors.secondary[700],
    marginTop: spacing.md,
    marginBottom: spacing.xs,
  },
  emptyStateSubtext: {
    fontSize: typography.fontSize.base,
    fontFamily: typography.fontFamily.regular,
    color: colors.secondary[500],
    textAlign: 'center',
    paddingHorizontal: spacing.md,
  },
  businessesList: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    borderColor: colors.secondary[200],
    ...shadows.sm,
  },
  businessItem: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: spacing.md,
    borderBottomWidth: 1,
    borderBottomColor: colors.secondary[100],
  },
  businessIcon: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: colors.success[50],
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: spacing.md,
  },
  businessContent: {
    flex: 1,
  },
  businessName: {
    fontSize: typography.fontSize.base,
    fontFamily: typography.fontFamily.semibold,
    color: colors.secondary[900],
    marginBottom: spacing.xs,
  },
  businessCategory: {
    fontSize: typography.fontSize.sm,
    fontFamily: typography.fontFamily.medium,
    color: colors.primary[600],
    marginBottom: spacing.xs,
  },
  businessAddress: {
    fontSize: typography.fontSize.sm,
    fontFamily: typography.fontFamily.regular,
    color: colors.secondary[600],
    marginBottom: spacing.xs,
  },
  businessDiscount: {
    fontSize: typography.fontSize.xs,
    fontFamily: typography.fontFamily.semibold,
    color: colors.success[600],
  },
  businessStatus: {
    marginLeft: spacing.md,
  },
  businessesMoreText: {
    fontSize: typography.fontSize.sm,
    fontFamily: typography.fontFamily.medium,
    color: colors.primary[600],
    textAlign: 'center',
    paddingVertical: spacing.md,
  },
  historyList: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    borderColor: colors.secondary[200],
    ...shadows.sm,
  },
  historyItem: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: spacing.md,
    borderBottomWidth: 1,
    borderBottomColor: colors.secondary[100],
  },
  historyIcon: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: colors.secondary[50],
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: spacing.md,
  },
  historyContent: {
    flex: 1,
  },
  historyDate: {
    fontSize: typography.fontSize.base,
    fontFamily: typography.fontFamily.medium,
    color: colors.secondary[900],
    marginBottom: spacing.xs,
  },
  historyDetails: {
    fontSize: typography.fontSize.sm,
    fontFamily: typography.fontFamily.regular,
    color: colors.secondary[600],
  },
  historyStatus: {
    marginLeft: spacing.md,
  },
  historyMoreText: {
    fontSize: typography.fontSize.sm,
    fontFamily: typography.fontFamily.medium,
    color: colors.primary[600],
    textAlign: 'center',
    paddingVertical: spacing.md,
  },
});