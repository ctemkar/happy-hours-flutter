import { useEffect, useState } from 'react';
import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { useFonts } from 'expo-font';
import { SplashScreen } from 'expo-router';
import {
  Inter_400Regular,
  Inter_500Medium,
  Inter_600SemiBold,
  Inter_700Bold,
} from '@expo-google-fonts/inter';
import {
  PlayfairDisplay_700Bold,
} from '@expo-google-fonts/playfair-display';
import { useFrameworkReady } from '@/hooks/useFrameworkReady';
import { Platform, View, Text } from 'react-native';
import 'react-native-gesture-handler';
import 'react-native-reanimated';

// Prevent splash screen from auto-hiding
SplashScreen.preventAutoHideAsync();

// Minimal error boundary
function ErrorBoundary({ children }: { children: React.ReactNode }) {
  const [hasError, setHasError] = useState(false);

  useEffect(() => {
    if (Platform.OS === 'web') {
      const handleError = (event: any) => {
        console.warn('Global error caught:', event.error);
        event.preventDefault();
      };

      const handleRejection = (event: any) => {
        console.warn('Unhandled rejection caught:', event.reason);
        event.preventDefault();
      };

      window.addEventListener('error', handleError);
      window.addEventListener('unhandledrejection', handleRejection);

      return () => {
        window.removeEventListener('error', handleError);
        window.removeEventListener('unhandledrejection', handleRejection);
      };
    }
  }, []);

  if (hasError) {
    return (
      <View style={{ 
        flex: 1, 
        justifyContent: 'center', 
        alignItems: 'center', 
        padding: 20,
        backgroundColor: '#fff'
      }}>
        <Text style={{ 
          fontSize: 24, 
          fontWeight: 'bold', 
          marginBottom: 16,
          textAlign: 'center'
        }}>
          Something went wrong
        </Text>
        <Text style={{ 
          fontSize: 16,
          textAlign: 'center', 
          color: '#666'
        }}>
          Please restart the app
        </Text>
      </View>
    );
  }

  return <>{children}</>;
}

export default function RootLayout() {
  // REQUIRED: This hook must never be removed or modified
  useFrameworkReady();

  const [fontsLoaded, fontError] = useFonts({
    'Inter-Regular': Inter_400Regular,
    'Inter-Medium': Inter_500Medium,
    'Inter-SemiBold': Inter_600SemiBold,
    'Inter-Bold': Inter_700Bold,
    'PlayfairDisplay-Bold': PlayfairDisplay_700Bold,
  });

  const [isReady, setIsReady] = useState(false);

  useEffect(() => {
    if (fontsLoaded || fontError) {
      const timer = setTimeout(() => {
        try {
          SplashScreen.hideAsync();
        } catch (error) {
          console.warn('SplashScreen hide error:', error);
        } finally {
          setIsReady(true);
        }
      }, 100);

      return () => clearTimeout(timer);
    }
  }, [fontsLoaded, fontError]);

  if (!fontsLoaded || !isReady) {
    return null;
  }

  if (fontError) {
    console.error('Font loading error:', fontError);
  }

  return (
    <ErrorBoundary>
      <Stack screenOptions={{ headerShown: false }}>
        <Stack.Screen name="(tabs)" />
        <Stack.Screen name="+not-found" />
      </Stack>
      <StatusBar style="auto" />
    </ErrorBoundary>
  );
}