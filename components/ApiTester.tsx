import React, { useState } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  ActivityIndicator,
  ScrollView,
} from 'react-native';
import { CircleCheck as CheckCircle, Circle as XCircle, CircleAlert as AlertCircle } from 'lucide-react-native';
import { colors, typography, spacing, borderRadius } from '@/constants/theme';

interface ApiTestResult {
  success: boolean;
  message: string;
  error?: string;
  resultsCount?: number;
  samplePlace?: string;
  status?: string;
  errorMessage?: string;
  details?: string;
}

export default function ApiTester() {
  const [testing, setTesting] = useState(false);
  const [result, setResult] = useState<ApiTestResult | null>(null);

  const testApiKey = async () => {
    setTesting(true);
    setResult(null);

    try {
      const response = await fetch('/test-api?lat=13.7563&lng=100.5018');
      const data = await response.json();
      setResult(data);
    } catch (error) {
      setResult({
        success: false,
        error: 'Network Error',
        message: 'Failed to test API key',
        details: error instanceof Error ? error.message : 'Unknown error'
      });
    } finally {
      setTesting(false);
    }
  };

  const getStatusIcon = () => {
    if (!result) return null;
    
    if (result.success) {
      return <CheckCircle size={24} color={colors.success[500]} />;
    } else {
      return <XCircle size={24} color={colors.error[500]} />;
    }
  };

  const getStatusColor = () => {
    if (!result) return colors.secondary[100];
    return result.success ? colors.success[50] : colors.error[50];
  };

  const getBorderColor = () => {
    if (!result) return colors.secondary[200];
    return result.success ? colors.success[200] : colors.error[200];
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Google Places API Test</Text>
      <Text style={styles.subtitle}>
        Test your API key to ensure it's working correctly
      </Text>

      <TouchableOpacity
        style={[styles.testButton, testing && styles.testButtonDisabled]}
        onPress={testApiKey}
        disabled={testing}
      >
        {testing ? (
          <ActivityIndicator size="small" color={colors.white} />
        ) : (
          <AlertCircle size={20} color={colors.white} />
        )}
        <Text style={styles.testButtonText}>
          {testing ? 'Testing API Key...' : 'Test API Key'}
        </Text>
      </TouchableOpacity>

      {result && (
        <View style={[
          styles.resultContainer,
          { backgroundColor: getStatusColor(), borderColor: getBorderColor() }
        ]}>
          <View style={styles.resultHeader}>
            {getStatusIcon()}
            <Text style={[
              styles.resultTitle,
              { color: result.success ? colors.success[700] : colors.error[700] }
            ]}>
              {result.success ? 'API Key Working!' : 'API Key Issue'}
            </Text>
          </View>

          <Text style={styles.resultMessage}>{result.message}</Text>

          {result.success && (
            <View style={styles.successDetails}>
              <Text style={styles.detailText}>
                ✓ Found {result.resultsCount} places nearby
              </Text>
              {result.samplePlace && (
                <Text style={styles.detailText}>
                  ✓ Sample place: {result.samplePlace}
                </Text>
              )}
            </View>
          )}

          {!result.success && (
            <ScrollView style={styles.errorDetails}>
              {result.error && (
                <Text style={styles.errorText}>Error: {result.error}</Text>
              )}
              {result.status && (
                <Text style={styles.errorText}>Status: {result.status}</Text>
              )}
              {result.errorMessage && (
                <Text style={styles.errorText}>Details: {result.errorMessage}</Text>
              )}
              {result.details && (
                <Text style={styles.errorText}>Technical: {result.details}</Text>
              )}
            </ScrollView>
          )}
        </View>
      )}

      <View style={styles.instructions}>
        <Text style={styles.instructionsTitle}>Setup Instructions:</Text>
        <Text style={styles.instructionText}>
          1. Get a Google Places API key from Google Cloud Console
        </Text>
        <Text style={styles.instructionText}>
          2. Enable the Places API for your project
        </Text>
        <Text style={styles.instructionText}>
          3. Add your key to the .env file as EXPO_PUBLIC_GOOGLE_PLACES_API_KEY
        </Text>
        <Text style={styles.instructionText}>
          4. Restart your development server
        </Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    padding: spacing.lg,
  },
  title: {
    fontSize: typography.fontSize.xl,
    fontFamily: typography.fontFamily.bold,
    color: colors.secondary[900],
    marginBottom: spacing.xs,
  },
  subtitle: {
    fontSize: typography.fontSize.base,
    fontFamily: typography.fontFamily.regular,
    color: colors.secondary[600],
    marginBottom: spacing.lg,
  },
  testButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.primary[500],
    paddingVertical: spacing.md,
    paddingHorizontal: spacing.lg,
    borderRadius: borderRadius.lg,
    marginBottom: spacing.lg,
  },
  testButtonDisabled: {
    backgroundColor: colors.secondary[400],
  },
  testButtonText: {
    fontSize: typography.fontSize.base,
    fontFamily: typography.fontFamily.semibold,
    color: colors.white,
    marginLeft: spacing.sm,
  },
  resultContainer: {
    padding: spacing.md,
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    marginBottom: spacing.lg,
  },
  resultHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: spacing.sm,
  },
  resultTitle: {
    fontSize: typography.fontSize.lg,
    fontFamily: typography.fontFamily.bold,
    marginLeft: spacing.sm,
  },
  resultMessage: {
    fontSize: typography.fontSize.base,
    fontFamily: typography.fontFamily.regular,
    color: colors.secondary[700],
    marginBottom: spacing.sm,
  },
  successDetails: {
    marginTop: spacing.sm,
  },
  detailText: {
    fontSize: typography.fontSize.sm,
    fontFamily: typography.fontFamily.regular,
    color: colors.success[600],
    marginBottom: spacing.xs,
  },
  errorDetails: {
    marginTop: spacing.sm,
    maxHeight: 120,
  },
  errorText: {
    fontSize: typography.fontSize.sm,
    fontFamily: typography.fontFamily.regular,
    color: colors.error[600],
    marginBottom: spacing.xs,
  },
  instructions: {
    backgroundColor: colors.secondary[50],
    padding: spacing.md,
    borderRadius: borderRadius.lg,
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
    color: colors.secondary[700],
    marginBottom: spacing.xs,
  },
});