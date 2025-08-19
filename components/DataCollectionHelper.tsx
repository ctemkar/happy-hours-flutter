import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Alert,
  Linking,
  Platform,
} from 'react-native';
import { 
  Download, 
  Upload, 
  ExternalLink, 
  FileText, 
  MapPin, 
  Clock,
  Phone,
  Globe,
  Camera
} from 'lucide-react-native';
import { colors, typography, spacing, borderRadius, shadows } from '@/constants/theme';

interface DataCollectionHelperProps {
  onDataCollected?: (data: any[]) => void;
}

export default function DataCollectionHelper({ onDataCollected }: DataCollectionHelperProps) {
  const [currentStep, setCurrentStep] = useState(1);

  const sampleData = [
    {
      name: "Pastel Rooftop Bar and mediterranean",
      description: "Rooftop bar with Mediterranean cuisine and stunning city views",
      address: "22nd floor, Aira Hotel, 14 ซ. สุขุมวิท 11 แขวงคลองเตยเหนือ เขตวัฒนา กรุงเทพมหานคร 10110",
      googleMarker: "https://www.pastelbangkok.com/?utm_source=google-business-profile&utm_medium=organic",
      picture: "https://images.pexels.com/photos/1581384/pexels-photo-1581384.jpeg?auto=compress&cs=tinysrgb&w=600&h=400&fit=crop&fm=webp&q=80",
      logo: "",
      open: "Open Every Day from 5:00PM – 1:00AM",
      happyHourStart: "5:00 PM",
      happyHourEnd: "7:00 PM",
      telephone: "095-703-5679",
      remark: "",
      update: "UPDATE 13/6/2025"
    },
    {
      name: "Junker and Bar: A Cozy Haven in Sala Daeng",
      description: "you can enjoy a Pint Tiger as well as mixed cocktails for only 100 baht ++",
      address: "458 Thanon Suan Phlu, Khwaeng Thung Maha Mek, Khet Sathon, Krung Thep Maha Nakhon 10120, Thailand",
      googleMarker: "https://m.facebook.com/JUNKER-AND-BAR-438784702897580/",
      picture: "https://images.pexels.com/photos/1267320/pexels-photo-1267320.jpeg?auto=compress&cs=tinysrgb&w=600&h=400&fit=crop&fm=webp&q=80",
      logo: "",
      open: "Open Every Day from 3:30PM – 12:00AM",
      happyHourStart: "3:30 PM",
      happyHourEnd: "6:30 PM",
      telephone: "085-100-3608",
      remark: "",
      update: "UPDATE 13/6/2025"
    }
  ];

  const researchSources = [
    {
      name: "Google Maps",
      url: "https://maps.google.com/",
      description: "Search for 'happy hour Pattaya' or 'bars Pattaya'",
      icon: MapPin
    },
    {
      name: "TripAdvisor",
      url: "https://www.tripadvisor.com/",
      description: "Look for restaurant and bar reviews in Pattaya",
      icon: ExternalLink
    },
    {
      name: "Facebook Pages",
      url: "https://www.facebook.com/",
      description: "Search for Pattaya bars and restaurants",
      icon: ExternalLink
    },
    {
      name: "Foursquare",
      url: "https://foursquare.com/",
      description: "Find venues with check-ins and tips",
      icon: MapPin
    },
    {
      name: "Yelp",
      url: "https://www.yelp.com/",
      description: "Business listings and reviews",
      icon: ExternalLink
    }
  ];

  const dataFields = [
    { field: "Name", description: "Business name", required: true, icon: FileText },
    { field: "Description", description: "What they offer, specialties", required: true, icon: FileText },
    { field: "Address", description: "Full street address", required: true, icon: MapPin },
    { field: "Google marker", description: "Website or Google Maps link", required: false, icon: Globe },
    { field: "Picture", description: "Photo URL (use optimized Pexels WebP links)", required: false, icon: Camera },
    { field: "Logo", description: "Logo URL if available", required: false, icon: Camera },
    { field: "Open", description: "Opening hours", required: false, icon: Clock },
    { field: "Happy Hour Start", description: "Start time (e.g., 5:00 PM)", required: false, icon: Clock },
    { field: "Happy Hour End", description: "End time (e.g., 7:00 PM)", required: false, icon: Clock },
    { field: "Telephone", description: "Phone number", required: false, icon: Phone },
    { field: "Remark", description: "Additional notes", required: false, icon: FileText },
    { field: "Update", description: "Last update date", required: false, icon: FileText },
  ];

  const handleOpenLink = (url: string) => {
    if (Platform.OS === 'web') {
      window.open(url, '_blank');
    } else {
      Linking.openURL(url);
    }
  };

  const generateGoogleSheetTemplate = () => {
    const headers = ["Name", "Description", "Address", "Google marker", "Picture", "Logo", "Open", "Happy Hour Start", "Happy Hour End", "Telephone", "Remark", "Update"];
    
    let csvContent = headers.join('\t') + '\n';
    
    sampleData.forEach((row, index) => {
      const rowData = [
        row.name,
        row.description,
        row.address,
        row.googleMarker,
        row.picture,
        row.logo,
        row.open,
        row.happyHourStart,
        row.happyHourEnd,
        row.telephone,
        row.remark,
        row.update
      ];
      csvContent += rowData.join('\t') + '\n';
    });

    if (Platform.OS === 'web') {
      const blob = new Blob([csvContent], { type: 'text/tab-separated-values' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = 'pattaya_happy_hours_template.tsv';
      a.click();
      URL.revokeObjectURL(url);
    } else {
      Alert.alert('Template Ready', 'Copy this template to create your Google Sheet:\n\n' + csvContent.substring(0, 200) + '...');
    }
  };

  const renderStep = () => {
    switch (currentStep) {
      case 1:
        return (
          <View style={styles.stepContent}>
            <Text style={styles.stepTitle}>Step 1: Research Sources</Text>
            <Text style={styles.stepDescription}>
              Use these sources to find happy hour information in Pattaya:
            </Text>
            
            {researchSources.map((source, index) => (
              <TouchableOpacity
                key={index}
                style={styles.sourceCard}
                onPress={() => handleOpenLink(source.url)}
              >
                <source.icon size={24} color={colors.primary[500]} />
                <View style={styles.sourceInfo}>
                  <Text style={styles.sourceName}>{source.name}</Text>
                  <Text style={styles.sourceDescription}>{source.description}</Text>
                </View>
                <ExternalLink size={16} color={colors.secondary[400]} />
              </TouchableOpacity>
            ))}

            <View style={styles.tipBox}>
              <Text style={styles.tipTitle}>💡 Research Tips</Text>
              <Text style={styles.tipText}>
                • Search for "happy hour Pattaya", "bars Pattaya", "restaurants Pattaya"{'\n'}
                • Look for business hours and special promotions{'\n'}
                • Check social media for current offers{'\n'}
                • Note contact information and addresses
              </Text>
            </View>
          </View>
        );

      case 2:
        return (
          <View style={styles.stepContent}>
            <Text style={styles.stepTitle}>Step 2: Data Fields</Text>
            <Text style={styles.stepDescription}>
              Collect this information for each business:
            </Text>
            
            {dataFields.map((field, index) => (
              <View key={index} style={styles.fieldCard}>
                <field.icon size={20} color={colors.primary[500]} />
                <View style={styles.fieldInfo}>
                  <Text style={styles.fieldName}>
                    {field.field} {field.required && <Text style={styles.required}>*</Text>}
                  </Text>
                  <Text style={styles.fieldDescription}>{field.description}</Text>
                </View>
              </View>
            ))}

            <View style={styles.tipBox}>
              <Text style={styles.tipTitle}>📝 Data Collection Tips</Text>
              <Text style={styles.tipText}>
                • Focus on businesses actually in Pattaya{'\n'}
                • Verify happy hour times are current{'\n'}
                • Use optimized Pexels WebP images for better performance{'\n'}
                • Double-check phone numbers and addresses{'\n'}
                • Format: ?auto=compress&cs=tinysrgb&w=600&h=400&fit=crop&fm=webp&q=80
              </Text>
            </View>
          </View>
        );

      case 3:
        return (
          <View style={styles.stepContent}>
            <Text style={styles.stepTitle}>Step 3: Create Google Sheet</Text>
            <Text style={styles.stepDescription}>
              Set up your Google Sheet with the correct format:
            </Text>

            <TouchableOpacity
              style={styles.actionButton}
              onPress={generateGoogleSheetTemplate}
            >
              <Download size={20} color={colors.white} />
              <Text style={styles.actionButtonText}>Download Template</Text>
            </TouchableOpacity>

            <View style={styles.instructionBox}>
              <Text style={styles.instructionTitle}>Google Sheets Setup:</Text>
              <Text style={styles.instructionText}>
                1. Go to sheets.google.com{'\n'}
                2. Create a new spreadsheet{'\n'}
                3. Copy the template headers{'\n'}
                4. Add your collected data{'\n'}
                5. Save and get the sharing link
              </Text>
            </View>

            <View style={styles.samplePreview}>
              <Text style={styles.sampleTitle}>Sample Data Preview:</Text>
              <ScrollView horizontal style={styles.sampleScroll}>
                <View style={styles.sampleTable}>
                  <Text style={styles.sampleText}>
                    Name: {sampleData[0].name}{'\n'}
                    Description: {sampleData[0].description.substring(0, 50)}...{'\n'}
                    Happy Hour: {sampleData[0].happyHourStart} - {sampleData[0].happyHourEnd}
                  </Text>
                </View>
              </ScrollView>
            </View>
          </View>
        );

      case 4:
        return (
          <View style={styles.stepContent}>
            <Text style={styles.stepTitle}>Step 4: Upload to App</Text>
            <Text style={styles.stepDescription}>
              Once you have your data ready, upload it to the app:
            </Text>

            <TouchableOpacity
              style={styles.actionButton}
              onPress={() => {
                Alert.alert(
                  'Upload Instructions',
                  'Go to the Admin tab and use the "Upload CSV File" feature to import your Google Sheets data.'
                );
              }}
            >
              <Upload size={20} color={colors.white} />
              <Text style={styles.actionButtonText}>Go to Admin Upload</Text>
            </TouchableOpacity>

            <View style={styles.instructionBox}>
              <Text style={styles.instructionTitle}>Upload Process:</Text>
              <Text style={styles.instructionText}>
                1. Export your Google Sheet as TSV/CSV{'\n'}
                2. Go to Admin tab in the app{'\n'}
                3. Click "Upload CSV File"{'\n'}
                4. Select your exported file{'\n'}
                5. Review the upload results
              </Text>
            </View>

            <View style={styles.tipBox}>
              <Text style={styles.tipTitle}>✅ Final Checklist</Text>
              <Text style={styles.tipText}>
                • All required fields filled{'\n'}
                • Happy hour times in correct format{'\n'}
                • Addresses are complete{'\n'}
                • Phone numbers include country code{'\n'}
                • Images use optimized WebP URLs from Pexels
              </Text>
            </View>
          </View>
        );

      default:
        return null;
    }
  };

  return (
    <ScrollView style={styles.container} showsVerticalScrollIndicator={false}>
      <View style={styles.header}>
        <Text style={styles.title}>Pattaya Happy Hours Data Collection</Text>
        <Text style={styles.subtitle}>
          Follow these steps to collect and upload happy hour data for Pattaya businesses
        </Text>
      </View>

      <View style={styles.progressBar}>
        {[1, 2, 3, 4].map((step) => (
          <TouchableOpacity
            key={step}
            style={[
              styles.progressStep,
              currentStep >= step && styles.progressStepActive
            ]}
            onPress={() => setCurrentStep(step)}
          >
            <Text style={[
              styles.progressStepText,
              currentStep >= step && styles.progressStepTextActive
            ]}>
              {step}
            </Text>
          </TouchableOpacity>
        ))}
      </View>

      {renderStep()}

      <View style={styles.navigation}>
        {currentStep > 1 && (
          <TouchableOpacity
            style={styles.navButton}
            onPress={() => setCurrentStep(currentStep - 1)}
          >
            <Text style={styles.navButtonText}>Previous</Text>
          </TouchableOpacity>
        )}
        
        {currentStep < 4 && (
          <TouchableOpacity
            style={[styles.navButton, styles.navButtonPrimary]}
            onPress={() => setCurrentStep(currentStep + 1)}
          >
            <Text style={[styles.navButtonText, styles.navButtonTextPrimary]}>Next</Text>
          </TouchableOpacity>
        )}
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.white,
  },
  header: {
    padding: spacing.lg,
    backgroundColor: colors.primary[50],
    borderBottomWidth: 1,
    borderBottomColor: colors.primary[200],
  },
  title: {
    fontSize: typography.fontSize['2xl'],
    fontFamily: typography.fontFamily.bold,
    color: colors.secondary[900],
    marginBottom: spacing.sm,
  },
  subtitle: {
    fontSize: typography.fontSize.base,
    fontFamily: typography.fontFamily.regular,
    color: colors.secondary[600],
    lineHeight: typography.fontSize.base * 1.4,
  },
  progressBar: {
    flexDirection: 'row',
    justifyContent: 'center',
    paddingVertical: spacing.lg,
    gap: spacing.md,
  },
  progressStep: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: colors.secondary[200],
    justifyContent: 'center',
    alignItems: 'center',
  },
  progressStepActive: {
    backgroundColor: colors.primary[500],
  },
  progressStepText: {
    fontSize: typography.fontSize.base,
    fontFamily: typography.fontFamily.semibold,
    color: colors.secondary[600],
  },
  progressStepTextActive: {
    color: colors.white,
  },
  stepContent: {
    padding: spacing.lg,
  },
  stepTitle: {
    fontSize: typography.fontSize.xl,
    fontFamily: typography.fontFamily.bold,
    color: colors.secondary[900],
    marginBottom: spacing.sm,
  },
  stepDescription: {
    fontSize: typography.fontSize.base,
    fontFamily: typography.fontFamily.regular,
    color: colors.secondary[600],
    marginBottom: spacing.lg,
    lineHeight: typography.fontSize.base * 1.4,
  },
  sourceCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.white,
    padding: spacing.md,
    borderRadius: borderRadius.lg,
    marginBottom: spacing.sm,
    borderWidth: 1,
    borderColor: colors.secondary[200],
    ...shadows.sm,
  },
  sourceInfo: {
    flex: 1,
    marginLeft: spacing.md,
  },
  sourceName: {
    fontSize: typography.fontSize.base,
    fontFamily: typography.fontFamily.semibold,
    color: colors.secondary[900],
    marginBottom: spacing.xs,
  },
  sourceDescription: {
    fontSize: typography.fontSize.sm,
    fontFamily: typography.fontFamily.regular,
    color: colors.secondary[600],
  },
  fieldCard: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    backgroundColor: colors.secondary[50],
    padding: spacing.md,
    borderRadius: borderRadius.md,
    marginBottom: spacing.sm,
  },
  fieldInfo: {
    flex: 1,
    marginLeft: spacing.md,
  },
  fieldName: {
    fontSize: typography.fontSize.base,
    fontFamily: typography.fontFamily.semibold,
    color: colors.secondary[900],
    marginBottom: spacing.xs,
  },
  required: {
    color: colors.error[500],
  },
  fieldDescription: {
    fontSize: typography.fontSize.sm,
    fontFamily: typography.fontFamily.regular,
    color: colors.secondary[600],
  },
  tipBox: {
    backgroundColor: colors.primary[50],
    padding: spacing.md,
    borderRadius: borderRadius.lg,
    marginTop: spacing.lg,
    borderLeftWidth: 4,
    borderLeftColor: colors.primary[500],
  },
  tipTitle: {
    fontSize: typography.fontSize.base,
    fontFamily: typography.fontFamily.bold,
    color: colors.primary[700],
    marginBottom: spacing.sm,
  },
  tipText: {
    fontSize: typography.fontSize.sm,
    fontFamily: typography.fontFamily.regular,
    color: colors.primary[600],
    lineHeight: typography.fontSize.sm * 1.4,
  },
  actionButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.primary[500],
    paddingVertical: spacing.md,
    paddingHorizontal: spacing.lg,
    borderRadius: borderRadius.lg,
    marginBottom: spacing.lg,
    ...shadows.sm,
  },
  actionButtonText: {
    fontSize: typography.fontSize.base,
    fontFamily: typography.fontFamily.semibold,
    color: colors.white,
    marginLeft: spacing.sm,
  },
  instructionBox: {
    backgroundColor: colors.secondary[50],
    padding: spacing.md,
    borderRadius: borderRadius.lg,
    marginBottom: spacing.lg,
  },
  instructionTitle: {
    fontSize: typography.fontSize.base,
    fontFamily: typography.fontFamily.bold,
    color: colors.secondary[900],
    marginBottom: spacing.sm,
  },
  instructionText: {
    fontSize: typography.fontSize.sm,
    fontFamily: typography.fontFamily.regular,
    color: colors.secondary[700],
    lineHeight: typography.fontSize.sm * 1.4,
  },
  samplePreview: {
    backgroundColor: colors.warning[50],
    padding: spacing.md,
    borderRadius: borderRadius.lg,
    marginBottom: spacing.lg,
  },
  sampleTitle: {
    fontSize: typography.fontSize.base,
    fontFamily: typography.fontFamily.bold,
    color: colors.warning[700],
    marginBottom: spacing.sm,
  },
  sampleScroll: {
    maxHeight: 100,
  },
  sampleTable: {
    backgroundColor: colors.white,
    padding: spacing.sm,
    borderRadius: borderRadius.md,
  },
  sampleText: {
    fontSize: typography.fontSize.xs,
    fontFamily: typography.fontFamily.regular,
    color: colors.secondary[700],
    lineHeight: typography.fontSize.xs * 1.3,
  },
  navigation: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    padding: spacing.lg,
    gap: spacing.md,
  },
  navButton: {
    flex: 1,
    paddingVertical: spacing.md,
    paddingHorizontal: spacing.lg,
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    borderColor: colors.secondary[300],
    alignItems: 'center',
  },
  navButtonPrimary: {
    backgroundColor: colors.primary[500],
    borderColor: colors.primary[500],
  },
  navButtonText: {
    fontSize: typography.fontSize.base,
    fontFamily: typography.fontFamily.semibold,
    color: colors.secondary[700],
  },
  navButtonTextPrimary: {
    color: colors.white,
  },
});