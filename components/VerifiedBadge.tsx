import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { CircleCheck as CheckCircle } from 'lucide-react-native';
import { colors, typography, spacing, borderRadius } from '@/constants/theme';

interface VerifiedBadgeProps {
  size?: 'small' | 'medium' | 'large';
  showText?: boolean;
  style?: any;
}

export default function VerifiedBadge({ 
  size = 'medium', 
  showText = true, 
  style 
}: VerifiedBadgeProps) {
  const sizeConfig = {
    small: {
      iconSize: 12,
      fontSize: typography.fontSize.xs,
      padding: spacing.xs,
    },
    medium: {
      iconSize: 16,
      fontSize: typography.fontSize.sm,
      padding: spacing.sm,
    },
    large: {
      iconSize: 20,
      fontSize: typography.fontSize.base,
      padding: spacing.md,
    },
  };

  const config = sizeConfig[size];

  return (
    <View style={[styles.container, { padding: config.padding }, style]}>
      <CheckCircle 
        size={config.iconSize} 
        color={colors.success[600]} 
        fill={colors.success[600]}
      />
      {showText && (
        <Text style={[styles.text, { fontSize: config.fontSize }]}>
          Verified
        </Text>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.success[50],
    borderRadius: borderRadius.md,
    borderWidth: 1,
    borderColor: colors.success[200],
  },
  text: {
    fontFamily: typography.fontFamily.semibold,
    color: colors.success[700],
    marginLeft: spacing.xs,
  },
});