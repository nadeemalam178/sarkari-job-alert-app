import React, { useState, useRef } from 'react';
import {
  StyleSheet,
  View,
  Text,
  TextInput,
  TouchableOpacity,
  SafeAreaView,
  ActivityIndicator,
  Modal,
  BackHandler,
  Platform,
  StatusBar as RNStatusBar
} from 'react-native';
import { StatusBar } from 'expo-status-bar';
import { WebView } from 'react-native-webview';

// Default Wi-Fi Server IP of host machine
const DEFAULT_SERVER_URL = "http://192.168.1.11:5000";

export default function App() {
  const [serverUrl, setServerUrl] = useState(DEFAULT_SERVER_URL);
  const [tempUrl, setTempUrl] = useState(DEFAULT_SERVER_URL);
  const [isLoading, setIsLoading] = useState(true);
  const [hasError, setHasError] = useState(false);
  const [isSettingsOpen, setIsSettingsOpen] = useState(false);
  const webViewRef = useRef(null);

  // Handle Android physical back button to navigate back in webview
  React.useEffect(() => {
    if (Platform.OS === 'android') {
      const onBackPress = () => {
        if (webViewRef.current) {
          webViewRef.current.goBack();
          return true;
        }
        return false;
      };
      BackHandler.addEventListener('hardwareBackPress', onBackPress);
      return () => BackHandler.removeEventListener('hardwareBackPress', onBackPress);
    }
  }, []);

  const handleSaveUrl = () => {
    let clean = tempUrl.trim();
    if (!clean.startsWith('http')) {
      clean = 'http://' + clean;
    }
    setServerUrl(clean);
    setIsSettingsOpen(false);
    setHasError(false);
    setIsLoading(true);
  };

  return (
    <SafeAreaView style={styles.safeArea}>
      <StatusBar style="light" backgroundColor="#0b0f19" />

      {/* Top Mobile Debug Header */}
      <View style={styles.topBar}>
        <View style={styles.brandRow}>
          <Text style={styles.brandEmoji}>🎯</Text>
          <View>
            <Text style={styles.brandTitle}>Sarkari Job Alert</Text>
            <Text style={styles.serverInfo} numberOfLines={1}>{serverUrl}</Text>
          </View>
        </View>

        <View style={styles.topActions}>
          <TouchableOpacity
            style={styles.actionBtn}
            onPress={() => webViewRef.current?.reload()}
          >
            <Text style={styles.actionBtnText}>🔄</Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={styles.actionBtn}
            onPress={() => setIsSettingsOpen(true)}
          >
            <Text style={styles.actionBtnText}>⚙️</Text>
          </TouchableOpacity>
        </View>
      </View>

      {/* Main WebView Container */}
      <View style={styles.webContainer}>
        {hasError ? (
          <View style={styles.errorContainer}>
            <Text style={styles.errorIcon}>⚠️</Text>
            <Text style={styles.errorTitle}>Cannot Connect to Server</Text>
            <Text style={styles.errorDesc}>
              Make sure your laptop and phone are on the same Wi-Fi network and the Python server is running (`run.bat`).
            </Text>
            <Text style={styles.currentIpLabel}>Target: {serverUrl}</Text>

            <TouchableOpacity
              style={styles.retryBtn}
              onPress={() => {
                setHasError(false);
                setIsLoading(true);
                webViewRef.current?.reload();
              }}
            >
              <Text style={styles.retryBtnText}>Retry Connection</Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={styles.changeIpBtn}
              onPress={() => setIsSettingsOpen(true)}
            >
              <Text style={styles.changeIpBtnText}>Change Server IP</Text>
            </TouchableOpacity>
          </View>
        ) : (
          <WebView
            ref={webViewRef}
            source={{ uri: serverUrl }}
            style={styles.webview}
            javaScriptEnabled={true}
            domStorageEnabled={true}
            startInLoadingState={true}
            pullToRefreshEnabled={true}
            onLoadStart={() => setIsLoading(true)}
            onLoadEnd={() => setIsLoading(false)}
            onError={(e) => {
              console.log('WebView Error:', e.nativeEvent);
              setHasError(true);
              setIsLoading(false);
            }}
          />
        )}

        {isLoading && !hasError && (
          <View style={styles.loadingOverlay}>
            <ActivityIndicator size="large" color="#2563eb" />
            <Text style={styles.loadingText}>Loading Sarkari Jobs...</Text>
          </View>
        )}
      </View>

      {/* Settings Modal (Change Server IP) */}
      <Modal
        visible={isSettingsOpen}
        transparent={true}
        animationType="slide"
        onRequestClose={() => setIsSettingsOpen(false)}
      >
        <View style={styles.modalBackdrop}>
          <View style={styles.modalCard}>
            <Text style={styles.modalTitle}>⚙️ Debug Server Settings</Text>
            <Text style={styles.modalSub}>
              Enter the local IP address of your computer running `run.bat`:
            </Text>

            <TextInput
              style={styles.ipInput}
              value={tempUrl}
              onChangeText={setTempUrl}
              placeholder="http://192.168.1.11:5000"
              placeholderTextColor="#64748b"
              autoCapitalize="none"
              autoCorrect={false}
            />

            <View style={styles.modalBtnRow}>
              <TouchableOpacity
                style={[styles.modalBtn, styles.cancelBtn]}
                onPress={() => setIsSettingsOpen(false)}
              >
                <Text style={styles.cancelBtnText}>Cancel</Text>
              </TouchableOpacity>

              <TouchableOpacity
                style={[styles.modalBtn, styles.saveBtn]}
                onPress={handleSaveUrl}
              >
                <Text style={styles.saveBtnText}>Save & Reload</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
    backgroundColor: '#0b0f19',
    paddingTop: Platform.OS === 'android' ? RNStatusBar.currentHeight : 0,
  },
  topBar: {
    height: 52,
    backgroundColor: '#111827',
    borderBottomWidth: 1,
    borderBottomColor: '#1f2937',
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 14,
  },
  brandRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    flex: 1,
  },
  brandEmoji: {
    fontSize: 20,
  },
  brandTitle: {
    fontSize: 14,
    fontWeight: '700',
    color: '#f8fafc',
  },
  serverInfo: {
    fontSize: 10,
    color: '#94a3b8',
  },
  topActions: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  actionBtn: {
    width: 34,
    height: 34,
    borderRadius: 8,
    backgroundColor: '#1f2937',
    alignItems: 'center',
    justifyContent: 'center',
  },
  actionBtnText: {
    fontSize: 14,
  },
  webContainer: {
    flex: 1,
    position: 'relative',
    backgroundColor: '#0b0f19',
  },
  webview: {
    flex: 1,
    backgroundColor: '#0b0f19',
  },
  loadingOverlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: '#0b0f19',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 12,
  },
  loadingText: {
    color: '#94a3b8',
    fontSize: 13,
    fontWeight: '600',
  },
  errorContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 24,
    backgroundColor: '#0b0f19',
  },
  errorIcon: {
    fontSize: 40,
    marginBottom: 12,
  },
  errorTitle: {
    fontSize: 18,
    fontWeight: '800',
    color: '#f8fafc',
    marginBottom: 8,
  },
  errorDesc: {
    fontSize: 13,
    color: '#94a3b8',
    textAlign: 'center',
    lineHeight: 18,
    marginBottom: 14,
  },
  currentIpLabel: {
    fontSize: 11,
    color: '#38bdf8',
    fontFamily: Platform.OS === 'ios' ? 'Menlo' : 'monospace',
    marginBottom: 20,
  },
  retryBtn: {
    backgroundColor: '#2563eb',
    paddingVertical: 12,
    paddingHorizontal: 24,
    borderRadius: 10,
    width: '100%',
    alignItems: 'center',
    marginBottom: 10,
  },
  retryBtnText: {
    color: '#fff',
    fontWeight: '700',
    fontSize: 14,
  },
  changeIpBtn: {
    backgroundColor: '#1f2937',
    paddingVertical: 12,
    paddingHorizontal: 24,
    borderRadius: 10,
    width: '100%',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: '#374151',
  },
  changeIpBtnText: {
    color: '#cbd5e1',
    fontWeight: '600',
    fontSize: 13,
  },
  modalBackdrop: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.7)',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 20,
  },
  modalCard: {
    width: '100%',
    maxWidth: 380,
    backgroundColor: '#111827',
    borderRadius: 16,
    padding: 22,
    borderWidth: 1,
    borderColor: '#374151',
  },
  modalTitle: {
    fontSize: 17,
    fontWeight: '800',
    color: '#fff',
    marginBottom: 6,
  },
  modalSub: {
    fontSize: 12,
    color: '#94a3b8',
    marginBottom: 16,
    lineHeight: 16,
  },
  ipInput: {
    backgroundColor: '#0b0f19',
    borderWidth: 1,
    borderColor: '#374151',
    borderRadius: 10,
    color: '#fff',
    padding: 12,
    fontSize: 14,
    marginBottom: 18,
  },
  modalBtnRow: {
    flexDirection: 'row',
    gap: 10,
  },
  modalBtn: {
    flex: 1,
    paddingVertical: 12,
    borderRadius: 10,
    alignItems: 'center',
  },
  cancelBtn: {
    backgroundColor: '#1f2937',
  },
  cancelBtnText: {
    color: '#94a3b8',
    fontWeight: '600',
  },
  saveBtn: {
    backgroundColor: '#2563eb',
  },
  saveBtnText: {
    color: '#fff',
    fontWeight: '700',
  },
});
