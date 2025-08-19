const { getDefaultConfig } = require('expo/metro-config');

const config = getDefaultConfig(__dirname);

// Stability improvements
config.resolver.platforms = ['ios', 'android', 'native', 'web'];
config.resolver.sourceExts = [...config.resolver.sourceExts, 'mjs', 'ts', 'tsx'];

// Critical: Enable require.context for Expo Router and fix TypeScript handling
config.transformer = {
  ...config.transformer,
  babelTransformerPath: require.resolve('metro-react-native-babel-transformer'),
  unstable_allowRequireContext: true,
  minifierConfig: {
    keep_fnames: true,
    mangle: {
      keep_fnames: true,
    },
  },
  transform: {
    enableBabelRCLookup: false,
    enableBabelRuntime: false,
  },
};

// Reduce memory usage
config.maxWorkers = 1;

module.exports = config;