import React, { useState, useMemo } from 'react';
import {
  StyleSheet,
  View,
  Text,
  TextInput,
  TouchableOpacity,
  FlatList,
  ScrollView,
  Linking,
  Modal,
  useColorScheme,
  Platform,
  StatusBar as RNStatusBar
} from 'react-native';
import { SafeAreaProvider, SafeAreaView } from 'react-native-safe-area-context';
import { StatusBar } from 'expo-status-bar';
import { INITIAL_JOBS, QUALIFICATIONS_MASTER } from './jobsData';

export default function App() {
  const systemColorScheme = useColorScheme();
  const [themeMode, setThemeMode] = useState('auto'); // 'auto' | 'light' | 'dark'

  const isDark = themeMode === 'auto' ? systemColorScheme === 'dark' : themeMode === 'dark';
  const theme = isDark ? darkTheme : lightTheme;

  // Navigation State: 'jobs' | 'education' | 'alerts' | 'account'
  const [activeTab, setActiveTab] = useState('jobs');

  // Job Filters
  const [jobSubtab, setJobSubtab] = useState('matched'); // 'matched' | 'all'
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedSource, setSelectedSource] = useState('all');

  // User Qualification Profile
  const [candidateName, setCandidateName] = useState('Candidate');
  const [candidateState, setCandidateState] = useState('All India');
  const [highestLevel, setHighestLevel] = useState('Graduate');
  const [selectedDegrees, setSelectedDegrees] = useState(['GRADUATE']);

  // Auth Modal
  const [isAuthOpen, setIsAuthOpen] = useState(false);
  const [authMode, setAuthMode] = useState('login'); // 'login' | 'register'
  const [authEmail, setAuthEmail] = useState('');
  const [authPassword, setAuthPassword] = useState('');
  const [isLoggedIn, setIsLoggedIn] = useState(false);

  // Filter Jobs Matching Profile
  const matchedJobs = useMemo(() => {
    return INITIAL_JOBS.filter(job => {
      const qFound = job.qualifications_found || [];
      // Level matching
      const hasMatch = qFound.some(q => {
        if (highestLevel === 'Post Graduate' && (q.includes('POST') || q.includes('GRADUATE'))) return true;
        if (highestLevel === 'Graduate' && (q.includes('GRADUATE') || q.includes('12TH') || q.includes('10TH'))) return true;
        if (highestLevel === 'Diploma / ITI' && (q.includes('DIPLOMA') || q.includes('ITI') || q.includes('10TH') || q.includes('12TH'))) return true;
        if (highestLevel === '12th Pass' && (q.includes('12TH') || q.includes('10TH'))) return true;
        if (highestLevel === '10th Pass' && q.includes('10TH')) return true;
        return selectedDegrees.some(deg => q.toUpperCase().includes(deg.toUpperCase()));
      });
      return hasMatch;
    });
  }, [highestLevel, selectedDegrees]);

  // Active Filtered List for Display
  const displayedJobs = useMemo(() => {
    const baseList = jobSubtab === 'matched' ? matchedJobs : INITIAL_JOBS;
    return baseList.filter(job => {
      // Source portal filter
      if (selectedSource !== 'all' && job.source !== selectedSource) {
        return false;
      }
      // Search filter
      if (searchQuery.trim()) {
        const q = searchQuery.toLowerCase().trim();
        const matchTitle = job.title.toLowerCase().includes(q);
        const matchOrg = job.org && job.org.toLowerCase().includes(q);
        const matchSnippet = job.eligibility_snippet && job.eligibility_snippet.toLowerCase().includes(q);
        const matchQuals = (job.qualifications_found || []).some(k => k.toLowerCase().includes(q));
        if (!matchTitle && !matchOrg && !matchSnippet && !matchQuals) return false;
      }
      return true;
    });
  }, [jobSubtab, matchedJobs, selectedSource, searchQuery]);

  const toggleTheme = () => {
    if (themeMode === 'auto') setThemeMode('light');
    else if (themeMode === 'light') setThemeMode('dark');
    else setThemeMode('auto');
  };

  const toggleDegree = (code) => {
    if (selectedDegrees.includes(code)) {
      setSelectedDegrees(selectedDegrees.filter(c => c !== code));
    } else {
      setSelectedDegrees([...selectedDegrees, code]);
    }
  };

  const openJobUrl = (url) => {
    if (url) {
      Linking.openURL(url).catch(err => console.error("Couldn't open URL:", err));
    }
  };

  const handleAuthSubmit = () => {
    if (!authEmail || !authPassword) return;
    setIsLoggedIn(true);
    setCandidateName(authEmail.split('@')[0]);
    setIsAuthOpen(false);
  };

  return (
    <SafeAreaProvider>
      <SafeAreaView style={[styles.container, { backgroundColor: theme.bgMain }]}>
        <StatusBar style={isDark ? 'light' : 'dark'} />

        {/* ── TOP HEADER ── */}
        <View style={[styles.header, { backgroundColor: theme.bgHeader, borderColor: theme.border }]}>
          <View style={styles.brandGroup}>
            <View style={styles.brandIcon}>
              <Text style={styles.brandIconText}>🎯</Text>
            </View>
            <View>
              <Text style={[styles.brandTitle, { color: theme.textMain }]}>Sarkari Job Alert</Text>
              <Text style={[styles.brandSubtitle, { color: theme.textMuted }]}>
                {highestLevel} • {matchedJobs.length} Matches
              </Text>
            </View>
          </View>

          <View style={styles.headerActions}>
            {/* Theme Toggle */}
            <TouchableOpacity
              style={[styles.iconButton, { backgroundColor: theme.tagBg, borderColor: theme.border }]}
              onPress={toggleTheme}
            >
              <Text style={styles.actionEmoji}>
                {themeMode === 'auto' ? '🌗' : themeMode === 'light' ? '☀️' : '🌙'}
              </Text>
            </TouchableOpacity>

            {/* Profile / Login */}
            <TouchableOpacity
              style={[styles.profilePill, { backgroundColor: theme.tagBg, borderColor: theme.border }]}
              onPress={() => setIsAuthOpen(true)}
            >
              <View style={styles.userAvatar}>
                <Text style={styles.avatarLetter}>{candidateName[0].toUpperCase()}</Text>
              </View>
              <Text style={[styles.profilePillText, { color: theme.textMain }]}>
                {isLoggedIn ? candidateName : 'Login'}
              </Text>
            </TouchableOpacity>
          </View>
        </View>

        {/* ── MAIN CONTENT TABS ── */}
        <View style={styles.mainContent}>

          {/* TAB 1: JOBS FEED */}
          {activeTab === 'jobs' && (
            <View style={styles.tabContainer}>
              {/* Controls Card */}
              <View style={[styles.controlsCard, { backgroundColor: theme.bgCard, borderColor: theme.border }]}>
                {/* Segmented Toggle: For You vs All */}
                <View style={[styles.segmentedControl, { backgroundColor: theme.tagBg }]}>
                  <TouchableOpacity
                    style={[styles.segBtn, jobSubtab === 'matched' && [styles.segBtnActive, { backgroundColor: theme.bgCard }]]}
                    onPress={() => setJobSubtab('matched')}
                  >
                    <Text style={[styles.segBtnText, { color: jobSubtab === 'matched' ? theme.textMain : theme.textMuted }]}>
                      🎯 For You
                    </Text>
                    <View style={[styles.badge, { backgroundColor: jobSubtab === 'matched' ? '#2563eb' : theme.border }]}>
                      <Text style={styles.badgeText}>{matchedJobs.length}</Text>
                    </View>
                  </TouchableOpacity>

                  <TouchableOpacity
                    style={[styles.segBtn, jobSubtab === 'all' && [styles.segBtnActive, { backgroundColor: theme.bgCard }]]}
                    onPress={() => setJobSubtab('all')}
                  >
                    <Text style={[styles.segBtnText, { color: jobSubtab === 'all' ? theme.textMain : theme.textMuted }]}>
                      🌐 All Jobs
                    </Text>
                    <View style={[styles.badge, { backgroundColor: jobSubtab === 'all' ? '#2563eb' : theme.border }]}>
                      <Text style={styles.badgeText}>{INITIAL_JOBS.length}</Text>
                    </View>
                  </TouchableOpacity>
                </View>

                {/* Search Bar */}
                <View style={[styles.searchBox, { backgroundColor: theme.bgInput, borderColor: theme.border }]}>
                  <Text style={styles.searchIcon}>🔍</Text>
                  <TextInput
                    style={[styles.searchInput, { color: theme.textMain }]}
                    placeholder="Search post, board, degree..."
                    placeholderTextColor={theme.textMuted}
                    value={searchQuery}
                    onChangeText={setSearchQuery}
                  />
                  {searchQuery.length > 0 && (
                    <TouchableOpacity onPress={() => setSearchQuery('')}>
                      <Text style={[styles.clearIcon, { color: theme.textMuted }]}>✕</Text>
                    </TouchableOpacity>
                  )}
                </View>

                {/* Source Portal Chips */}
                <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.portalChipsRow}>
                  {['all', 'SarkariResult', 'FreeJobAlert', 'RojgarResult'].map(source => (
                    <TouchableOpacity
                      key={source}
                      style={[
                        styles.portalChip,
                        { backgroundColor: selectedSource === source ? '#2563eb' : theme.tagBg, borderColor: theme.border }
                      ]}
                      onPress={() => setSelectedSource(source)}
                    >
                      <Text style={[
                        styles.portalChipText,
                        { color: selectedSource === source ? '#fff' : theme.textMuted, fontWeight: selectedSource === source ? '700' : '500' }
                      ]}>
                        {source === 'all' ? 'All Portals' : source === 'SarkariResult' ? 'SarkariResult ★' : source}
                      </Text>
                    </TouchableOpacity>
                  ))}
                </ScrollView>
              </View>

              {/* Feed Header Count */}
              <View style={styles.feedHeaderRow}>
                <Text style={[styles.feedCountLabel, { color: theme.textMuted }]}>
                  Showing {displayedJobs.length} active vacancies
                </Text>
                <TouchableOpacity onPress={() => setActiveTab('education')}>
                  <Text style={[styles.editEduLink, { color: '#2563eb' }]}>
                    Edit Qualification ✎
                  </Text>
                </TouchableOpacity>
              </View>

              {/* Job Cards List */}
              <FlatList
                data={displayedJobs}
                keyExtractor={(item) => String(item.id || item.url)}
                contentContainerStyle={styles.jobsListContent}
                renderItem={({ item }) => (
                  <View style={[styles.jobCard, { backgroundColor: theme.bgCard, borderColor: theme.border }]}>
                    <View style={styles.jobTopRow}>
                      <View style={[
                        styles.sourceBadge,
                        item.source === 'SarkariResult' ? styles.sourceSr :
                        item.source === 'FreeJobAlert' ? styles.sourceFja : styles.sourceRr
                      ]}>
                        <Text style={styles.sourceBadgeText}>{item.source || 'SarkariResult'} ★</Text>
                      </View>
                      <Text style={[styles.lastDateText, { color: theme.textMuted }]}>
                        📅 {item.last_date || 'Check Notice'}
                      </Text>
                    </View>

                    <Text style={[styles.jobTitle, { color: theme.textMain }]}>{item.title}</Text>
                    {item.org && <Text style={[styles.jobOrg, { color: theme.textMuted }]}>🏢 {item.org}</Text>}

                    {/* Qualification Tags */}
                    <View style={styles.jobTagsRow}>
                      {(item.qualifications_found || []).slice(0, 4).map((tag, idx) => (
                        <View key={idx} style={[styles.tagPill, { backgroundColor: theme.tagBg, borderColor: theme.border }]}>
                          <Text style={[styles.tagPillText, { color: '#2563eb' }]}>✓ {tag}</Text>
                        </View>
                      ))}
                    </View>

                    {item.eligibility_snippet && (
                      <Text style={[styles.jobSnippet, { color: theme.textMuted, backgroundColor: theme.tagBg }]} numberOfLines={2}>
                        {item.eligibility_snippet}
                      </Text>
                    )}

                    <TouchableOpacity
                      style={styles.applyButton}
                      onPress={() => openJobUrl(item.url)}
                    >
                      <Text style={styles.applyButtonText}>Apply on Official Portal &rarr;</Text>
                    </TouchableOpacity>
                  </View>
                )}
                ListEmptyComponent={() => (
                  <View style={[styles.emptyBox, { backgroundColor: theme.bgCard, borderColor: theme.border }]}>
                    <Text style={styles.emptyIcon}>🔍</Text>
                    <Text style={[styles.emptyTitle, { color: theme.textMain }]}>No Vacancies Found</Text>
                    <Text style={[styles.emptyDesc, { color: theme.textMuted }]}>
                      No jobs matched your current filter. Try clearing your search query or selecting another qualification.
                    </Text>
                  </View>
                )}
              />
            </View>
          )}

          {/* TAB 2: EDUCATION SELECTOR */}
          {activeTab === 'education' && (
            <ScrollView contentContainerStyle={styles.scrollTabContent}>
              <View style={[styles.sectionCard, { backgroundColor: theme.bgCard, borderColor: theme.border }]}>
                <Text style={[styles.sectionTitle, { color: theme.textMain }]}>1. Highest Qualification Level</Text>
                <Text style={[styles.sectionSub, { color: theme.textMuted }]}>
                  Select your highest education level to match central and state government jobs:
                </Text>

                <View style={styles.levelsGrid}>
                  {[
                    { label: 'Post Graduate', sub: 'M.Tech / MCA / MBA / M.Sc / MA', icon: '🎓' },
                    { label: 'Graduate', sub: 'B.Tech / B.E / B.Sc / BA / B.Com', icon: '🎓' },
                    { label: 'Diploma / ITI', sub: 'Polytechnic / ITI Trade Certificate', icon: '⚙️' },
                    { label: '12th Pass', sub: 'Intermediate (PCM, PCB, Arts, Commerce)', icon: '🏫' },
                    { label: '10th Pass', sub: 'High School / Matriculation', icon: '🎒' },
                  ].map(lvl => (
                    <TouchableOpacity
                      key={lvl.label}
                      style={[
                        styles.levelCard,
                        { backgroundColor: theme.tagBg, borderColor: highestLevel === lvl.label ? '#2563eb' : theme.border },
                        highestLevel === lvl.label && styles.levelCardActive
                      ]}
                      onPress={() => setHighestLevel(lvl.label)}
                    >
                      <Text style={styles.levelIcon}>{lvl.icon}</Text>
                      <Text style={[styles.levelLabel, { color: theme.textMain, fontWeight: highestLevel === lvl.label ? '800' : '600' }]}>
                        {lvl.label}
                      </Text>
                      <Text style={[styles.levelSub, { color: theme.textMuted }]}>{lvl.sub}</Text>
                    </TouchableOpacity>
                  ))}
                </View>

                {/* Specific Degrees / Certifications */}
                <Text style={[styles.sectionTitle, { color: theme.textMain, marginTop: 20 }]}>
                  2. Specific Degrees / Certifications
                </Text>
                <Text style={[styles.sectionSub, { color: theme.textMuted }]}>
                  Tap to add or remove specific qualifications (B.Ed, CTET, Civil, Nursing, etc.):
                </Text>

                <View style={styles.degreesGrid}>
                  {QUALIFICATIONS_MASTER.slice(0, 18).map(q => {
                    const isSelected = selectedDegrees.includes(q.code);
                    return (
                      <TouchableOpacity
                        key={q.code}
                        style={[
                          styles.degreeChip,
                          { backgroundColor: isSelected ? '#2563eb' : theme.tagBg, borderColor: theme.border }
                        ]}
                        onPress={() => toggleDegree(q.code)}
                      >
                        <Text style={[styles.degreeChipText, { color: isSelected ? '#fff' : theme.textMain }]}>
                          {isSelected ? '✓ ' : '+ '} {q.code}
                        </Text>
                      </TouchableOpacity>
                    );
                  })}
                </View>

                {/* Save Button */}
                <TouchableOpacity
                  style={styles.saveEduBtn}
                  onPress={() => setActiveTab('jobs')}
                >
                  <Text style={styles.saveEduBtnText}>Save & View Matching Jobs ({matchedJobs.length}) &rarr;</Text>
                </TouchableOpacity>
              </View>
            </ScrollView>
          )}

          {/* TAB 3: PHONE ALERTS */}
          {activeTab === 'alerts' && (
            <ScrollView contentContainerStyle={styles.scrollTabContent}>
              <View style={[styles.sectionCard, { backgroundColor: theme.bgCard, borderColor: theme.border }]}>
                <Text style={[styles.sectionTitle, { color: theme.textMain }]}>📱 Phone Lockscreen Alerts</Text>
                <Text style={[styles.sectionSub, { color: theme.textMuted }]}>
                  Get instant push notifications on your phone whenever a vacancy matching {highestLevel} is published.
                </Text>

                <View style={[styles.alertInfoBox, { backgroundColor: theme.tagBg, borderColor: theme.border }]}>
                  <Text style={[styles.alertTopicTitle, { color: theme.textMain }]}>Your Alert Topic:</Text>
                  <Text style={styles.alertTopicValue}>sarkari_job_alert_user</Text>

                  <Text style={[styles.alertStepText, { color: theme.textMuted }]}>
                    1. Install the free <Text style={{ fontWeight: '700', color: theme.textMain }}>ntfy</Text> app on Android / iOS.{'\n'}
                    2. Tap <Text style={{ fontWeight: '700', color: theme.textMain }}>Subscribe</Text> and type: <Text style={{ fontWeight: '700', color: '#2563eb' }}>sarkari_job_alert_user</Text>{'\n'}
                    3. Done! You will receive instant notifications with vibration & links.
                  </Text>
                </View>

                <TouchableOpacity
                  style={styles.openNtfyBtn}
                  onPress={() => Linking.openURL('https://ntfy.sh/sarkari_job_alert_user')}
                >
                  <Text style={styles.openNtfyBtnText}>Open ntfy.sh Topic in Browser &rarr;</Text>
                </TouchableOpacity>
              </View>
            </ScrollView>
          )}

          {/* TAB 4: ACCOUNT / SETTINGS */}
          {activeTab === 'account' && (
            <ScrollView contentContainerStyle={styles.scrollTabContent}>
              <View style={[styles.sectionCard, { backgroundColor: theme.bgCard, borderColor: theme.border }]}>
                <View style={styles.accountHeader}>
                  <View style={styles.accountAvatarBig}>
                    <Text style={styles.accountAvatarText}>{candidateName[0].toUpperCase()}</Text>
                  </View>
                  <View>
                    <Text style={[styles.accountName, { color: theme.textMain }]}>{candidateName}</Text>
                    <Text style={[styles.accountSub, { color: theme.textMuted }]}>Level: {highestLevel}</Text>
                  </View>
                </View>

                <View style={styles.settingDivider} />

                <Text style={[styles.settingRowLabel, { color: theme.textMuted }]}>Appearance Theme</Text>
                <View style={styles.themeToggleRow}>
                  {['auto', 'light', 'dark'].map(m => (
                    <TouchableOpacity
                      key={m}
                      style={[
                        styles.themeChoiceBtn,
                        { backgroundColor: themeMode === m ? '#2563eb' : theme.tagBg, borderColor: theme.border }
                      ]}
                      onPress={() => setThemeMode(m)}
                    >
                      <Text style={[styles.themeChoiceText, { color: themeMode === m ? '#fff' : theme.textMain }]}>
                        {m === 'auto' ? '🌗 Auto' : m === 'light' ? '☀️ Light' : '🌙 Dark'}
                      </Text>
                    </TouchableOpacity>
                  ))}
                </View>

                <View style={styles.settingDivider} />

                <Text style={[styles.settingRowLabel, { color: theme.textMuted }]}>Direct Official Portals</Text>
                {[
                  { name: 'SarkariResult.com', url: 'https://www.sarkariresult.com' },
                  { name: 'FreeJobAlert.com', url: 'https://www.freejobalert.com' },
                  { name: 'RojgarResult.com', url: 'https://www.rojgarresult.com' }
                ].map(portal => (
                  <TouchableOpacity
                    key={portal.name}
                    style={[styles.portalLinkRow, { backgroundColor: theme.tagBg, borderColor: theme.border }]}
                    onPress={() => Linking.openURL(portal.url)}
                  >
                    <Text style={[styles.portalLinkName, { color: theme.textMain }]}>{portal.name}</Text>
                    <Text style={{ color: '#2563eb' }}>&rarr;</Text>
                  </TouchableOpacity>
                ))}

                {isLoggedIn && (
                  <TouchableOpacity
                    style={styles.logoutBtn}
                    onPress={() => {
                      setIsLoggedIn(false);
                      setCandidateName('Candidate');
                    }}
                  >
                    <Text style={styles.logoutBtnText}>Log Out</Text>
                  </TouchableOpacity>
                )}
              </View>
            </ScrollView>
          )}

        </View>

        {/* ── NATIVE BOTTOM DOCK NAVIGATION ── */}
        <View style={[styles.dockContainer, { backgroundColor: theme.dockBg, borderColor: theme.border }]}>
          {[
            { id: 'jobs', label: 'Jobs', icon: '🎯', badge: matchedJobs.length },
            { id: 'education', label: 'Education', icon: '🎓' },
            { id: 'alerts', label: 'Alerts', icon: '🔔' },
            { id: 'account', label: 'Account', icon: '⚙️' }
          ].map(tab => (
            <TouchableOpacity
              key={tab.id}
              style={[styles.dockItem, activeTab === tab.id && styles.dockItemActive]}
              onPress={() => setActiveTab(tab.id)}
            >
              <View style={styles.dockIconWrapper}>
                <Text style={styles.dockIcon}>{tab.icon}</Text>
                {tab.badge !== undefined && tab.badge > 0 && (
                  <View style={styles.dockBadge}>
                    <Text style={styles.dockBadgeText}>{tab.badge}</Text>
                  </View>
                )}
              </View>
              <Text style={[
                styles.dockLabel,
                { color: activeTab === tab.id ? '#2563eb' : theme.textMuted, fontWeight: activeTab === tab.id ? '800' : '600' }
              ]}>
                {tab.label}
              </Text>
            </TouchableOpacity>
          ))}
        </View>

        {/* ── NATIVE LOGIN / REGISTER MODAL ── */}
        <Modal
          visible={isAuthOpen}
          transparent={true}
          animationType="fade"
          onRequestClose={() => setIsAuthOpen(false)}
        >
          <View style={styles.modalBackdrop}>
            <View style={[styles.modalCard, { backgroundColor: theme.bgCard, borderColor: theme.border }]}>
              <TouchableOpacity style={styles.modalClose} onPress={() => setIsAuthOpen(false)}>
                <Text style={[styles.modalCloseText, { color: theme.textMuted }]}>✕</Text>
              </TouchableOpacity>

              <Text style={[styles.modalHeading, { color: theme.textMain }]}>
                {authMode === 'login' ? 'Sign In to Account' : 'Create Account'}
              </Text>
              <Text style={[styles.modalSub, { color: theme.textMuted }]}>
                Match government jobs strictly by your qualification.
              </Text>

              <View style={[styles.modalTabsRow, { backgroundColor: theme.tagBg }]}>
                <TouchableOpacity
                  style={[styles.modalTabBtn, authMode === 'login' && [styles.modalTabBtnActive, { backgroundColor: theme.bgCard }]]}
                  onPress={() => setAuthMode('login')}
                >
                  <Text style={[styles.modalTabText, { color: theme.textMain }]}>Log In</Text>
                </TouchableOpacity>
                <TouchableOpacity
                  style={[styles.modalTabBtn, authMode === 'register' && [styles.modalTabBtnActive, { backgroundColor: theme.bgCard }]]}
                  onPress={() => setAuthMode('register')}
                >
                  <Text style={[styles.modalTabText, { color: theme.textMain }]}>Register</Text>
                </TouchableOpacity>
              </View>

              <TextInput
                style={[styles.modalInput, { backgroundColor: theme.bgInput, borderColor: theme.border, color: theme.textMain }]}
                placeholder="Email Address"
                placeholderTextColor={theme.textMuted}
                value={authEmail}
                onChangeText={setAuthEmail}
                autoCapitalize="none"
                keyboardType="email-address"
              />

              <TextInput
                style={[styles.modalInput, { backgroundColor: theme.bgInput, borderColor: theme.border, color: theme.textMain }]}
                placeholder="Password"
                placeholderTextColor={theme.textMuted}
                value={authPassword}
                onChangeText={setAuthPassword}
                secureTextEntry={true}
              />

              <TouchableOpacity style={styles.modalSubmitBtn} onPress={handleAuthSubmit}>
                <Text style={styles.modalSubmitBtnText}>
                  {authMode === 'login' ? 'Sign In & View Jobs &rarr;' : 'Create Account & Continue &rarr;'}
                </Text>
              </TouchableOpacity>

              <TouchableOpacity onPress={() => setIsAuthOpen(false)} style={styles.guestLink}>
                <Text style={{ color: theme.textMuted, fontSize: 12 }}>Continue as Guest</Text>
              </TouchableOpacity>
            </View>
          </View>
        </Modal>

      </SafeAreaView>
    </SafeAreaProvider>
  );
}

// Design Tokens (Light & Dark)
const lightTheme = {
  bgMain: '#f8fafc',
  bgCard: '#ffffff',
  bgHeader: '#ffffff',
  bgInput: '#f1f5f9',
  border: '#e2e8f0',
  textMain: '#0f172a',
  textMuted: '#64748b',
  tagBg: '#f1f5f9',
  dockBg: '#ffffff',
};

const darkTheme = {
  bgMain: '#0b0f19',
  bgCard: '#131b2e',
  bgHeader: '#131b2e',
  bgInput: '#0b0f19',
  border: '#1e293b',
  textMain: '#f8fafc',
  textMuted: '#94a3b8',
  tagBg: '#1e293b',
  dockBg: '#131b2e',
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderBottomWidth: 1,
  },
  brandGroup: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
  },
  brandIcon: {
    width: 38,
    height: 38,
    borderRadius: 10,
    backgroundColor: '#2563eb',
    alignItems: 'center',
    justifyContent: 'center',
  },
  brandIconText: {
    fontSize: 20,
  },
  brandTitle: {
    fontSize: 16,
    fontWeight: '800',
    letterSpacing: -0.3,
  },
  brandSubtitle: {
    fontSize: 11,
    fontWeight: '600',
  },
  headerActions: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  iconButton: {
    width: 36,
    height: 36,
    borderRadius: 10,
    borderWidth: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  actionEmoji: {
    fontSize: 16,
  },
  profilePill: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 20,
    borderWidth: 1,
  },
  userAvatar: {
    width: 24,
    height: 24,
    borderRadius: 12,
    backgroundColor: '#10b981',
    alignItems: 'center',
    justifyContent: 'center',
  },
  avatarLetter: {
    color: '#fff',
    fontSize: 11,
    fontWeight: '800',
  },
  profilePillText: {
    fontSize: 12,
    fontWeight: '700',
  },
  mainContent: {
    flex: 1,
  },
  tabContainer: {
    flex: 1,
    paddingHorizontal: 14,
    paddingTop: 10,
  },
  controlsCard: {
    borderRadius: 16,
    borderWidth: 1,
    padding: 10,
    gap: 10,
    marginBottom: 6,
  },
  segmentedControl: {
    flexDirection: 'row',
    borderRadius: 10,
    padding: 3,
    gap: 4,
  },
  segBtn: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 6,
    paddingVertical: 7,
    borderRadius: 8,
  },
  segBtnActive: {
    elevation: 2,
    shadowColor: '#000',
    shadowOpacity: 0.08,
    shadowRadius: 4,
  },
  segBtnText: {
    fontSize: 13,
    fontWeight: '700',
  },
  badge: {
    paddingHorizontal: 6,
    paddingVertical: 1,
    borderRadius: 10,
  },
  badgeText: {
    color: '#fff',
    fontSize: 10,
    fontWeight: '800',
  },
  searchBox: {
    flexDirection: 'row',
    alignItems: 'center',
    borderWidth: 1,
    borderRadius: 10,
    paddingHorizontal: 10,
    height: 38,
  },
  searchIcon: {
    fontSize: 13,
    marginRight: 6,
    opacity: 0.6,
  },
  searchInput: {
    flex: 1,
    fontSize: 13,
    paddingVertical: 0,
  },
  clearIcon: {
    fontSize: 14,
    paddingHorizontal: 4,
  },
  portalChipsRow: {
    flexDirection: 'row',
    gap: 6,
  },
  portalChip: {
    paddingHorizontal: 12,
    paddingVertical: 5,
    borderRadius: 16,
    borderWidth: 1,
  },
  portalChipText: {
    fontSize: 11,
  },
  feedHeaderRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 6,
    paddingHorizontal: 2,
  },
  feedCountLabel: {
    fontSize: 11,
    fontWeight: '600',
  },
  editEduLink: {
    fontSize: 11,
    fontWeight: '700',
  },
  jobsListContent: {
    paddingBottom: 90,
    gap: 10,
  },
  jobCard: {
    borderRadius: 14,
    borderWidth: 1,
    padding: 14,
    gap: 8,
  },
  jobTopRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  sourceBadge: {
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 10,
  },
  sourceSr: {
    backgroundColor: 'rgba(239, 68, 68, 0.15)',
  },
  sourceFja: {
    backgroundColor: 'rgba(16, 185, 129, 0.15)',
  },
  sourceRr: {
    backgroundColor: 'rgba(37, 99, 235, 0.15)',
  },
  sourceBadgeText: {
    fontSize: 10,
    fontWeight: '800',
    color: '#ef4444',
  },
  lastDateText: {
    fontSize: 11,
    fontWeight: '600',
  },
  jobTitle: {
    fontSize: 14,
    fontWeight: '800',
    lineHeight: 18,
  },
  jobOrg: {
    fontSize: 12,
    fontWeight: '600',
  },
  jobTagsRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 5,
  },
  tagPill: {
    borderWidth: 1,
    borderRadius: 6,
    paddingHorizontal: 6,
    paddingVertical: 2,
  },
  tagPillText: {
    fontSize: 10,
    fontWeight: '700',
  },
  jobSnippet: {
    fontSize: 11,
    padding: 8,
    borderRadius: 6,
    lineHeight: 15,
  },
  applyButton: {
    backgroundColor: '#2563eb',
    paddingVertical: 9,
    borderRadius: 8,
    alignItems: 'center',
    marginTop: 2,
  },
  applyButtonText: {
    color: '#fff',
    fontWeight: '700',
    fontSize: 12,
  },
  scrollTabContent: {
    padding: 14,
    paddingBottom: 100,
  },
  sectionCard: {
    borderRadius: 16,
    borderWidth: 1,
    padding: 16,
  },
  sectionTitle: {
    fontSize: 15,
    fontWeight: '800',
    marginBottom: 4,
  },
  sectionSub: {
    fontSize: 12,
    lineHeight: 16,
    marginBottom: 12,
  },
  levelsGrid: {
    gap: 8,
  },
  levelCard: {
    borderWidth: 1.5,
    borderRadius: 12,
    padding: 12,
  },
  levelCardActive: {
    borderColor: '#2563eb',
    backgroundColor: 'rgba(37, 99, 235, 0.08)',
  },
  levelIcon: {
    fontSize: 18,
    marginBottom: 2,
  },
  levelLabel: {
    fontSize: 13,
  },
  levelSub: {
    fontSize: 10,
    marginTop: 2,
  },
  degreesGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 6,
  },
  degreeChip: {
    borderWidth: 1,
    borderRadius: 8,
    paddingHorizontal: 10,
    paddingVertical: 6,
  },
  degreeChipText: {
    fontSize: 11,
    fontWeight: '700',
  },
  saveEduBtn: {
    backgroundColor: '#2563eb',
    paddingVertical: 12,
    borderRadius: 10,
    alignItems: 'center',
    marginTop: 20,
  },
  saveEduBtnText: {
    color: '#fff',
    fontSize: 13,
    fontWeight: '800',
  },
  alertInfoBox: {
    borderWidth: 1,
    borderRadius: 12,
    padding: 14,
    gap: 8,
  },
  alertTopicTitle: {
    fontSize: 12,
    fontWeight: '700',
  },
  alertTopicValue: {
    fontSize: 15,
    fontWeight: '900',
    color: '#2563eb',
  },
  alertStepText: {
    fontSize: 12,
    lineHeight: 18,
  },
  openNtfyBtn: {
    backgroundColor: '#2563eb',
    paddingVertical: 12,
    borderRadius: 10,
    alignItems: 'center',
    marginTop: 14,
  },
  openNtfyBtnText: {
    color: '#fff',
    fontWeight: '700',
    fontSize: 13,
  },
  accountHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  accountAvatarBig: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: '#10b981',
    alignItems: 'center',
    justifyContent: 'center',
  },
  accountAvatarText: {
    color: '#fff',
    fontSize: 20,
    fontWeight: '800',
  },
  accountName: {
    fontSize: 16,
    fontWeight: '800',
  },
  accountSub: {
    fontSize: 12,
  },
  settingDivider: {
    height: 1,
    backgroundColor: 'rgba(150, 150, 150, 0.15)',
    marginVertical: 14,
  },
  settingRowLabel: {
    fontSize: 11,
    fontWeight: '700',
    textTransform: 'uppercase',
    letterSpacing: 0.5,
    marginBottom: 8,
  },
  themeToggleRow: {
    flexDirection: 'row',
    gap: 8,
  },
  themeChoiceBtn: {
    flex: 1,
    paddingVertical: 8,
    borderWidth: 1,
    borderRadius: 8,
    alignItems: 'center',
  },
  themeChoiceText: {
    fontSize: 12,
    fontWeight: '700',
  },
  portalLinkRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: 12,
    borderWidth: 1,
    borderRadius: 10,
    marginBottom: 6,
  },
  portalLinkName: {
    fontSize: 13,
    fontWeight: '600',
  },
  logoutBtn: {
    backgroundColor: '#ef4444',
    paddingVertical: 10,
    borderRadius: 8,
    alignItems: 'center',
    marginTop: 14,
  },
  logoutBtnText: {
    color: '#fff',
    fontWeight: '700',
    fontSize: 13,
  },
  dockContainer: {
    position: 'absolute',
    bottom: 12,
    left: 16,
    right: 16,
    flexDirection: 'row',
    borderRadius: 28,
    borderWidth: 1,
    paddingVertical: 6,
    paddingHorizontal: 8,
    elevation: 10,
    shadowColor: '#000',
    shadowOpacity: 0.15,
    shadowRadius: 12,
  },
  dockItem: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 4,
    borderRadius: 16,
  },
  dockItemActive: {
    backgroundColor: 'rgba(37, 99, 235, 0.1)',
  },
  dockIconWrapper: {
    position: 'relative',
  },
  dockIcon: {
    fontSize: 18,
  },
  dockBadge: {
    position: 'absolute',
    top: -4,
    right: -8,
    backgroundColor: '#ef4444',
    borderRadius: 8,
    minWidth: 15,
    height: 15,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 3,
  },
  dockBadgeText: {
    color: '#fff',
    fontSize: 9,
    fontWeight: '800',
  },
  dockLabel: {
    fontSize: 10,
    marginTop: 2,
  },
  modalBackdrop: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.6)',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 20,
  },
  modalCard: {
    width: '100%',
    maxWidth: 360,
    borderRadius: 20,
    borderWidth: 1,
    padding: 22,
    position: 'relative',
  },
  modalClose: {
    position: 'absolute',
    top: 14,
    right: 14,
    padding: 4,
  },
  modalCloseText: {
    fontSize: 16,
    fontWeight: '700',
  },
  modalHeading: {
    fontSize: 17,
    fontWeight: '800',
    marginBottom: 4,
  },
  modalSub: {
    fontSize: 11,
    marginBottom: 14,
  },
  modalTabsRow: {
    flexDirection: 'row',
    borderRadius: 8,
    padding: 3,
    marginBottom: 14,
  },
  modalTabBtn: {
    flex: 1,
    alignItems: 'center',
    paddingVertical: 6,
    borderRadius: 6,
  },
  modalTabBtnActive: {
    elevation: 2,
  },
  modalTabText: {
    fontSize: 12,
    fontWeight: '700',
  },
  modalInput: {
    borderWidth: 1,
    borderRadius: 10,
    paddingHorizontal: 12,
    height: 40,
    fontSize: 13,
    marginBottom: 10,
  },
  modalSubmitBtn: {
    backgroundColor: '#2563eb',
    paddingVertical: 11,
    borderRadius: 10,
    alignItems: 'center',
    marginTop: 4,
  },
  modalSubmitBtnText: {
    color: '#fff',
    fontWeight: '700',
    fontSize: 13,
  },
  guestLink: {
    alignItems: 'center',
    marginTop: 12,
  },
  emptyBox: {
    borderWidth: 1,
    borderRadius: 14,
    padding: 28,
    alignItems: 'center',
    marginTop: 10,
  },
  emptyIcon: {
    fontSize: 28,
    marginBottom: 8,
  },
  emptyTitle: {
    fontSize: 15,
    fontWeight: '800',
    marginBottom: 4,
  },
  emptyDesc: {
    fontSize: 11,
    textAlign: 'center',
    lineHeight: 16,
  },
});
