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
  useColorScheme
} from 'react-native';
import { SafeAreaProvider, SafeAreaView } from 'react-native-safe-area-context';
import { StatusBar } from 'expo-status-bar';
import { INITIAL_JOBS, QUALIFICATIONS_MASTER } from './jobsData';

export default function App() {
  const systemColorScheme = useColorScheme();
  const [themeMode, setThemeMode] = useState('auto'); // 'auto' | 'light' | 'dark'
  const isDark = themeMode === 'auto' ? systemColorScheme === 'dark' : themeMode === 'dark';
  const theme = isDark ? darkTheme : lightTheme;

  // Active Tab: 'jobs' | 'education' | 'alerts' | 'settings'
  const [activeTab, setActiveTab] = useState('jobs');

  // Job Filters
  const [jobSubtab, setJobSubtab] = useState('matched'); // 'matched' | 'all'
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedSource, setSelectedSource] = useState('all');

  // User Profile
  const [highestLevel, setHighestLevel] = useState('Graduate');
  const [selectedDegrees, setSelectedDegrees] = useState(['GRADUATE']);

  // Selected Job Preview Modal (optional quick view)
  const [previewJob, setPreviewJob] = useState(null);

  // Filter Jobs Matching Qualification
  const matchedJobs = useMemo(() => {
    return INITIAL_JOBS.filter(job => {
      const qFound = job.qualifications_found || [];
      return qFound.some(q => {
        if (highestLevel === 'Post Graduate' && (q.includes('POST') || q.includes('GRADUATE'))) return true;
        if (highestLevel === 'Graduate' && (q.includes('GRADUATE') || q.includes('12TH') || q.includes('10TH'))) return true;
        if (highestLevel === 'Diploma / ITI' && (q.includes('DIPLOMA') || q.includes('ITI') || q.includes('10TH') || q.includes('12TH'))) return true;
        if (highestLevel === '12th Pass' && (q.includes('12TH') || q.includes('10TH'))) return true;
        if (highestLevel === '10th Pass' && q.includes('10TH')) return true;
        return selectedDegrees.some(deg => q.toUpperCase().includes(deg.toUpperCase()));
      });
    });
  }, [highestLevel, selectedDegrees]);

  // Displayed Jobs List
  const displayedJobs = useMemo(() => {
    const list = jobSubtab === 'matched' ? matchedJobs : INITIAL_JOBS;
    return list.filter(job => {
      if (selectedSource !== 'all' && job.source !== selectedSource) return false;
      if (searchQuery.trim()) {
        const q = searchQuery.toLowerCase().trim();
        const inTitle = job.title.toLowerCase().includes(q);
        const inOrg = job.org && job.org.toLowerCase().includes(q);
        const inQuals = (job.qualifications_found || []).some(k => k.toLowerCase().includes(q));
        if (!inTitle && !inOrg && !inQuals) return false;
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

  return (
    <SafeAreaProvider>
      <SafeAreaView style={[styles.container, { backgroundColor: theme.bgMain }]}>
        <StatusBar style={isDark ? 'light' : 'dark'} />

        {/* ── MINIMAL TOP BAR ── */}
        <View style={[styles.topBar, { backgroundColor: theme.bgCard, borderColor: theme.border }]}>
          <View style={styles.brandGroup}>
            <Text style={styles.brandEmoji}>🎯</Text>
            <View>
              <Text style={[styles.brandTitle, { color: theme.textMain }]}>Sarkari Job Alert</Text>
              <Text style={[styles.brandSubtitle, { color: theme.textMuted }]}>
                {highestLevel} • {matchedJobs.length} Matches
              </Text>
            </View>
          </View>

          <View style={styles.topRightActions}>
            <TouchableOpacity
              style={[styles.themeBtn, { backgroundColor: theme.tagBg, borderColor: theme.border }]}
              onPress={toggleTheme}
            >
              <Text style={styles.themeBtnText}>
                {themeMode === 'auto' ? '🌗' : themeMode === 'light' ? '☀️' : '🌙'}
              </Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={[styles.eduPill, { backgroundColor: theme.tagBg, borderColor: theme.border }]}
              onPress={() => setActiveTab('education')}
            >
              <Text style={[styles.eduPillText, { color: theme.primary }]}>🎓 {highestLevel.split(' ')[0]}</Text>
            </TouchableOpacity>
          </View>
        </View>

        {/* ── TAB CONTENT ── */}
        <View style={styles.mainContent}>

          {/* TAB 1: 1-LINERS JOB LIST */}
          {activeTab === 'jobs' && (
            <View style={styles.tabJobsWrapper}>
              
              {/* Minimal 1-Line Filters Bar */}
              <View style={[styles.filtersBar, { backgroundColor: theme.bgCard, borderColor: theme.border }]}>
                
                {/* Clean 2-Option Segment */}
                <View style={[styles.segRow, { backgroundColor: theme.tagBg }]}>
                  <TouchableOpacity
                    style={[styles.segBtn, jobSubtab === 'matched' && [styles.segBtnActive, { backgroundColor: theme.bgCard }]]}
                    onPress={() => setJobSubtab('matched')}
                  >
                    <Text style={[styles.segBtnText, { color: jobSubtab === 'matched' ? theme.textMain : theme.textMuted, fontWeight: jobSubtab === 'matched' ? '800' : '600' }]}>
                      🎯 For You ({matchedJobs.length})
                    </Text>
                  </TouchableOpacity>

                  <TouchableOpacity
                    style={[styles.segBtn, jobSubtab === 'all' && [styles.segBtnActive, { backgroundColor: theme.bgCard }]]}
                    onPress={() => setJobSubtab('all')}
                  >
                    <Text style={[styles.segBtnText, { color: jobSubtab === 'all' ? theme.textMain : theme.textMuted, fontWeight: jobSubtab === 'all' ? '800' : '600' }]}>
                      🌐 All ({INITIAL_JOBS.length})
                    </Text>
                  </TouchableOpacity>
                </View>

                {/* Compact Search Input */}
                <View style={[styles.searchRow, { backgroundColor: theme.bgInput, borderColor: theme.border }]}>
                  <Text style={styles.searchIcon}>🔍</Text>
                  <TextInput
                    style={[styles.searchInput, { color: theme.textMain }]}
                    placeholder="Search jobs..."
                    placeholderTextColor={theme.textMuted}
                    value={searchQuery}
                    onChangeText={setSearchQuery}
                  />
                  {searchQuery.length > 0 && (
                    <TouchableOpacity onPress={() => setSearchQuery('')}>
                      <Text style={[styles.clearSearch, { color: theme.textMuted }]}>✕</Text>
                    </TouchableOpacity>
                  )}
                </View>

                {/* Horizontal Minimal Portal Chips */}
                <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.portalScroll}>
                  {['all', 'SarkariResult', 'FreeJobAlert', 'RojgarResult'].map(portal => (
                    <TouchableOpacity
                      key={portal}
                      style={[
                        styles.portalChip,
                        { backgroundColor: selectedSource === portal ? theme.primary : theme.tagBg, borderColor: theme.border }
                      ]}
                      onPress={() => setSelectedSource(portal)}
                    >
                      <Text style={[
                        styles.portalChipText,
                        { color: selectedSource === portal ? '#fff' : theme.textMuted, fontWeight: selectedSource === portal ? '800' : '600' }
                      ]}>
                        {portal === 'all' ? 'All' : portal === 'SarkariResult' ? 'SarkariResult ★' : portal}
                      </Text>
                    </TouchableOpacity>
                  ))}
                </ScrollView>
              </View>

              {/* 1-LINERS LIST */}
              <FlatList
                data={displayedJobs}
                keyExtractor={(item) => String(item.id || item.url)}
                contentContainerStyle={styles.oneLineListContent}
                renderItem={({ item }) => (
                  <TouchableOpacity
                    style={[styles.oneLineRow, { backgroundColor: theme.bgCard, borderColor: theme.border }]}
                    onPress={() => openJobUrl(item.url)}
                    onLongPress={() => setPreviewJob(item)}
                    activeOpacity={0.65}
                  >
                    {/* Source Dot Badge */}
                    <View style={[
                      styles.sourceDot,
                      item.source === 'SarkariResult' ? styles.dotSr :
                      item.source === 'FreeJobAlert' ? styles.dotFja : styles.dotRr
                    ]}>
                      <Text style={styles.sourceDotText}>
                        {item.source === 'SarkariResult' ? 'SR' : item.source === 'FreeJobAlert' ? 'FJA' : 'RR'}
                      </Text>
                    </View>

                    {/* 1-Liner Content */}
                    <View style={styles.rowMain}>
                      <Text style={[styles.rowTitle, { color: theme.textMain }]} numberOfLines={1}>
                        {item.title}
                      </Text>
                      <View style={styles.rowSubLine}>
                        {item.org ? (
                          <Text style={[styles.rowOrg, { color: theme.textMuted }]} numberOfLines={1}>
                            {item.org} •{' '}
                          </Text>
                        ) : null}
                        <Text style={[styles.rowDate, { color: theme.primary }]}>
                          📅 {item.last_date || 'Check Notice'}
                        </Text>
                      </View>
                    </View>

                    {/* Arrow Action */}
                    <Text style={[styles.chevronArrow, { color: theme.textMuted }]}>›</Text>
                  </TouchableOpacity>
                )}
                ListEmptyComponent={() => (
                  <View style={[styles.emptyBox, { borderColor: theme.border }]}>
                    <Text style={[styles.emptyText, { color: theme.textMuted }]}>
                      No vacancies found matching "{searchQuery}"
                    </Text>
                  </View>
                )}
              />
            </View>
          )}

          {/* TAB 2: EDUCATION (CLEAN & DIRECT) */}
          {activeTab === 'education' && (
            <ScrollView contentContainerStyle={styles.scrollTabContent}>
              <View style={[styles.sectionCard, { backgroundColor: theme.bgCard, borderColor: theme.border }]}>
                <Text style={[styles.sectionHeading, { color: theme.textMain }]}>Highest Qualification Level</Text>
                
                <View style={styles.levelButtonsCol}>
                  {[
                    'Post Graduate (Master / MCA / MBA / M.Tech)',
                    'Graduate (BA / B.Sc / B.Com / B.Tech / B.E)',
                    'Diploma / ITI (Polytechnic / ITI Trade)',
                    '12th Pass (Intermediate / 10+2)',
                    '10th Pass (High School / Matriculation)'
                  ].map(fullLvl => {
                    const shortName = fullLvl.split(' (')[0];
                    const isSelected = highestLevel === shortName;
                    return (
                      <TouchableOpacity
                        key={shortName}
                        style={[
                          styles.levelRowBtn,
                          { backgroundColor: isSelected ? theme.primary : theme.tagBg, borderColor: theme.border }
                        ]}
                        onPress={() => setHighestLevel(shortName)}
                      >
                        <Text style={[styles.levelRowText, { color: isSelected ? '#fff' : theme.textMain, fontWeight: isSelected ? '800' : '600' }]}>
                          {isSelected ? '✓ ' : '○ '} {fullLvl}
                        </Text>
                      </TouchableOpacity>
                    );
                  })}
                </View>

                <Text style={[styles.sectionHeading, { color: theme.textMain, marginTop: 18 }]}>
                  Specific Degrees / Exams
                </Text>

                <View style={styles.degPillsWrap}>
                  {QUALIFICATIONS_MASTER.slice(0, 24).map(deg => {
                    const isSelected = selectedDegrees.includes(deg.code);
                    return (
                      <TouchableOpacity
                        key={deg.code}
                        style={[
                          styles.degPill,
                          { backgroundColor: isSelected ? theme.primary : theme.tagBg, borderColor: theme.border }
                        ]}
                        onPress={() => toggleDegree(deg.code)}
                      >
                        <Text style={[styles.degPillText, { color: isSelected ? '#fff' : theme.textMain, fontWeight: isSelected ? '800' : '600' }]}>
                          {isSelected ? '✓ ' : '+ '} {deg.code}
                        </Text>
                      </TouchableOpacity>
                    );
                  })}
                </View>

                <TouchableOpacity
                  style={[styles.saveBtn, { backgroundColor: theme.primary }]}
                  onPress={() => setActiveTab('jobs')}
                >
                  <Text style={styles.saveBtnText}>
                    Save & Show {matchedJobs.length} Matching Jobs &rarr;
                  </Text>
                </TouchableOpacity>
              </View>
            </ScrollView>
          )}

          {/* TAB 3: ALERTS */}
          {activeTab === 'alerts' && (
            <ScrollView contentContainerStyle={styles.scrollTabContent}>
              <View style={[styles.sectionCard, { backgroundColor: theme.bgCard, borderColor: theme.border }]}>
                <Text style={[styles.sectionHeading, { color: theme.textMain }]}>📱 Phone Lockscreen Alerts</Text>
                <Text style={[styles.sectionDesc, { color: theme.textMuted }]}>
                  Get instant notification on phone whenever a job matching {highestLevel} is published.
                </Text>

                <View style={[styles.topicBox, { backgroundColor: theme.tagBg, borderColor: theme.border }]}>
                  <Text style={[styles.topicLabel, { color: theme.textMuted }]}>ntfy Topic Name:</Text>
                  <Text style={[styles.topicVal, { color: theme.primary }]}>sarkari_job_alert_user</Text>
                </View>

                <TouchableOpacity
                  style={[styles.saveBtn, { backgroundColor: theme.primary, marginTop: 12 }]}
                  onPress={() => Linking.openURL('https://ntfy.sh/sarkari_job_alert_user')}
                >
                  <Text style={styles.saveBtnText}>Open ntfy.sh Subscription &rarr;</Text>
                </TouchableOpacity>
              </View>
            </ScrollView>
          )}

          {/* TAB 4: SETTINGS */}
          {activeTab === 'settings' && (
            <ScrollView contentContainerStyle={styles.scrollTabContent}>
              <View style={[styles.sectionCard, { backgroundColor: theme.bgCard, borderColor: theme.border }]}>
                <Text style={[styles.sectionHeading, { color: theme.textMain }]}>Appearance Theme</Text>
                <View style={styles.themeToggleRow}>
                  {['auto', 'light', 'dark'].map(m => (
                    <TouchableOpacity
                      key={m}
                      style={[
                        styles.themeChoiceBtn,
                        { backgroundColor: themeMode === m ? theme.primary : theme.tagBg, borderColor: theme.border }
                      ]}
                      onPress={() => setThemeMode(m)}
                    >
                      <Text style={[styles.themeChoiceText, { color: themeMode === m ? '#fff' : theme.textMain }]}>
                        {m === 'auto' ? '🌗 Auto' : m === 'light' ? '☀️ Light' : '🌙 Dark'}
                      </Text>
                    </TouchableOpacity>
                  ))}
                </View>

                <Text style={[styles.sectionHeading, { color: theme.textMain, marginTop: 20 }]}>
                  Direct Portal Links
                </Text>
                {[
                  { name: 'SarkariResult.com', url: 'https://www.sarkariresult.com' },
                  { name: 'FreeJobAlert.com', url: 'https://www.freejobalert.com' },
                  { name: 'RojgarResult.com', url: 'https://www.rojgarresult.com' }
                ].map(p => (
                  <TouchableOpacity
                    key={p.name}
                    style={[styles.portalLinkRow, { backgroundColor: theme.tagBg, borderColor: theme.border }]}
                    onPress={() => Linking.openURL(p.url)}
                  >
                    <Text style={[styles.portalLinkText, { color: theme.textMain }]}>{p.name}</Text>
                    <Text style={{ color: theme.primary, fontSize: 16 }}>&rarr;</Text>
                  </TouchableOpacity>
                ))}
              </View>
            </ScrollView>
          )}

        </View>

        {/* ── CLEAN BOTTOM DOCK ── */}
        <View style={[styles.bottomDock, { backgroundColor: theme.dockBg, borderColor: theme.border }]}>
          {[
            { id: 'jobs', label: 'Jobs', icon: '🎯', badge: matchedJobs.length },
            { id: 'education', label: 'Education', icon: '🎓' },
            { id: 'alerts', label: 'Alerts', icon: '🔔' },
            { id: 'settings', label: 'Settings', icon: '⚙️' }
          ].map(tab => (
            <TouchableOpacity
              key={tab.id}
              style={[styles.dockItem, activeTab === tab.id && styles.dockItemActive]}
              onPress={() => setActiveTab(tab.id)}
            >
              <View style={styles.dockIconWrapper}>
                <Text style={styles.dockIconText}>{tab.icon}</Text>
                {tab.badge !== undefined && tab.badge > 0 && (
                  <View style={styles.dockBadge}>
                    <Text style={styles.dockBadgeText}>{tab.badge}</Text>
                  </View>
                )}
              </View>
              <Text style={[
                styles.dockLabel,
                { color: activeTab === tab.id ? theme.primary : theme.textMuted, fontWeight: activeTab === tab.id ? '800' : '600' }
              ]}>
                {tab.label}
              </Text>
            </TouchableOpacity>
          ))}
        </View>

        {/* ── QUICK JOB PREVIEW MODAL (ON LONG PRESS) ── */}
        <Modal
          visible={!!previewJob}
          transparent={true}
          animationType="fade"
          onRequestClose={() => setPreviewJob(null)}
        >
          <View style={styles.modalOverlay}>
            <View style={[styles.previewCard, { backgroundColor: theme.bgCard, borderColor: theme.border }]}>
              <Text style={[styles.previewTitle, { color: theme.textMain }]}>{previewJob?.title}</Text>
              {previewJob?.org ? (
                <Text style={[styles.previewOrg, { color: theme.textMuted }]}>🏢 {previewJob?.org}</Text>
              ) : null}

              <Text style={[styles.previewSnippet, { color: theme.textMuted, backgroundColor: theme.tagBg }]}>
                {previewJob?.eligibility_snippet || 'Check official advertisement for full eligibility details.'}
              </Text>

              <Text style={[styles.previewDate, { color: theme.primary }]}>
                📅 Last Date: {previewJob?.last_date || 'Check Notice'}
              </Text>

              <View style={styles.modalActionsRow}>
                <TouchableOpacity
                  style={[styles.modalCloseBtn, { backgroundColor: theme.tagBg }]}
                  onPress={() => setPreviewJob(null)}
                >
                  <Text style={[styles.modalCloseBtnText, { color: theme.textMain }]}>Close</Text>
                </TouchableOpacity>

                <TouchableOpacity
                  style={[styles.modalApplyBtn, { backgroundColor: theme.primary }]}
                  onPress={() => {
                    const url = previewJob?.url;
                    setPreviewJob(null);
                    openJobUrl(url);
                  }}
                >
                  <Text style={styles.modalApplyBtnText}>Open Official Link &rarr;</Text>
                </TouchableOpacity>
              </View>
            </View>
          </View>
        </Modal>

      </SafeAreaView>
    </SafeAreaProvider>
  );
}

// ── THEME COLORS ──
const lightTheme = {
  bgMain: '#f8fafc',
  bgCard: '#ffffff',
  bgInput: '#f1f5f9',
  border: '#e2e8f0',
  textMain: '#0f172a',
  textMuted: '#64748b',
  tagBg: '#f1f5f9',
  dockBg: '#ffffff',
  primary: '#2563eb',
};

const darkTheme = {
  bgMain: '#0b0f19',
  bgCard: '#131b2e',
  bgInput: '#0b0f19',
  border: '#1e293b',
  textMain: '#f8fafc',
  textMuted: '#94a3b8',
  tagBg: '#1e293b',
  dockBg: '#131b2e',
  primary: '#38bdf8',
};

// ── COMPACT STYLES (1-LINER FOCUS) ──
const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  topBar: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 14,
    paddingVertical: 8,
    borderBottomWidth: 1,
  },
  brandGroup: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  brandEmoji: {
    fontSize: 20,
  },
  brandTitle: {
    fontSize: 15,
    fontWeight: '800',
    letterSpacing: -0.2,
  },
  brandSubtitle: {
    fontSize: 10,
    fontWeight: '600',
  },
  topRightActions: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  themeBtn: {
    width: 32,
    height: 32,
    borderRadius: 8,
    borderWidth: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  themeBtnText: {
    fontSize: 14,
  },
  eduPill: {
    paddingHorizontal: 8,
    paddingVertical: 5,
    borderRadius: 14,
    borderWidth: 1,
  },
  eduPillText: {
    fontSize: 11,
    fontWeight: '700',
  },
  mainContent: {
    flex: 1,
  },
  tabJobsWrapper: {
    flex: 1,
  },
  filtersBar: {
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderBottomWidth: 1,
    gap: 6,
  },
  segRow: {
    flexDirection: 'row',
    borderRadius: 8,
    padding: 2,
    gap: 4,
  },
  segBtn: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 6,
    borderRadius: 6,
  },
  segBtnActive: {
    elevation: 1,
    shadowColor: '#000',
    shadowOpacity: 0.05,
    shadowRadius: 2,
  },
  segBtnText: {
    fontSize: 12,
  },
  searchRow: {
    flexDirection: 'row',
    alignItems: 'center',
    borderWidth: 1,
    borderRadius: 8,
    paddingHorizontal: 8,
    height: 34,
  },
  searchIcon: {
    fontSize: 12,
    marginRight: 6,
    opacity: 0.6,
  },
  searchInput: {
    flex: 1,
    fontSize: 12,
    paddingVertical: 0,
  },
  clearSearch: {
    fontSize: 13,
    paddingHorizontal: 4,
  },
  portalScroll: {
    flexDirection: 'row',
    gap: 5,
    paddingVertical: 2,
  },
  portalChip: {
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 12,
    borderWidth: 1,
  },
  portalChipText: {
    fontSize: 10,
  },
  oneLineListContent: {
    paddingHorizontal: 10,
    paddingTop: 6,
    paddingBottom: 80,
    gap: 5,
  },
  oneLineRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 9,
    paddingHorizontal: 10,
    borderRadius: 10,
    borderWidth: 1,
    gap: 9,
  },
  sourceDot: {
    width: 28,
    height: 28,
    borderRadius: 6,
    alignItems: 'center',
    justifyContent: 'center',
  },
  dotSr: {
    backgroundColor: 'rgba(239, 68, 68, 0.15)',
  },
  dotFja: {
    backgroundColor: 'rgba(16, 185, 129, 0.15)',
  },
  dotRr: {
    backgroundColor: 'rgba(56, 189, 248, 0.15)',
  },
  sourceDotText: {
    fontSize: 9,
    fontWeight: '900',
    color: '#ef4444',
  },
  rowMain: {
    flex: 1,
    gap: 1,
  },
  rowTitle: {
    fontSize: 13,
    fontWeight: '700',
    letterSpacing: -0.2,
  },
  rowSubLine: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  rowOrg: {
    fontSize: 10,
    fontWeight: '500',
    maxWidth: '55%',
  },
  rowDate: {
    fontSize: 10,
    fontWeight: '700',
  },
  chevronArrow: {
    fontSize: 16,
    fontWeight: '700',
    paddingLeft: 2,
  },
  emptyBox: {
    padding: 30,
    alignItems: 'center',
    borderRadius: 10,
    borderWidth: 1,
    margin: 12,
  },
  emptyText: {
    fontSize: 12,
    textAlign: 'center',
  },
  scrollTabContent: {
    padding: 12,
    paddingBottom: 90,
  },
  sectionCard: {
    borderRadius: 14,
    borderWidth: 1,
    padding: 14,
  },
  sectionHeading: {
    fontSize: 14,
    fontWeight: '800',
    marginBottom: 8,
  },
  sectionDesc: {
    fontSize: 11,
    lineHeight: 15,
    marginBottom: 10,
  },
  levelButtonsCol: {
    gap: 6,
  },
  levelRowBtn: {
    paddingVertical: 10,
    paddingHorizontal: 12,
    borderRadius: 8,
    borderWidth: 1,
  },
  levelRowText: {
    fontSize: 12,
  },
  degPillsWrap: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 6,
  },
  degPill: {
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: 8,
    borderWidth: 1,
  },
  degPillText: {
    fontSize: 11,
  },
  saveBtn: {
    paddingVertical: 11,
    borderRadius: 8,
    alignItems: 'center',
    marginTop: 16,
  },
  saveBtnText: {
    color: '#fff',
    fontSize: 12,
    fontWeight: '800',
  },
  topicBox: {
    padding: 12,
    borderRadius: 8,
    borderWidth: 1,
    gap: 4,
  },
  topicLabel: {
    fontSize: 11,
    fontWeight: '600',
  },
  topicVal: {
    fontSize: 14,
    fontWeight: '900',
  },
  themeToggleRow: {
    flexDirection: 'row',
    gap: 8,
    marginTop: 4,
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
    paddingVertical: 10,
    paddingHorizontal: 12,
    borderRadius: 8,
    borderWidth: 1,
    marginBottom: 6,
  },
  portalLinkText: {
    fontSize: 12,
    fontWeight: '600',
  },
  bottomDock: {
    position: 'absolute',
    bottom: 10,
    left: 16,
    right: 16,
    flexDirection: 'row',
    borderRadius: 24,
    borderWidth: 1,
    paddingVertical: 5,
    paddingHorizontal: 6,
    elevation: 8,
    shadowColor: '#000',
    shadowOpacity: 0.12,
    shadowRadius: 10,
  },
  dockItem: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 3,
    borderRadius: 14,
  },
  dockItemActive: {
    backgroundColor: 'rgba(56, 189, 248, 0.1)',
  },
  dockIconWrapper: {
    position: 'relative',
  },
  dockIconText: {
    fontSize: 16,
  },
  dockBadge: {
    position: 'absolute',
    top: -3,
    right: -8,
    backgroundColor: '#ef4444',
    borderRadius: 8,
    minWidth: 14,
    height: 14,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 2,
  },
  dockBadgeText: {
    color: '#fff',
    fontSize: 8,
    fontWeight: '900',
  },
  dockLabel: {
    fontSize: 9,
    marginTop: 1,
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.6)',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 16,
  },
  previewCard: {
    width: '100%',
    maxWidth: 340,
    borderRadius: 16,
    borderWidth: 1,
    padding: 16,
    gap: 8,
  },
  previewTitle: {
    fontSize: 14,
    fontWeight: '800',
    lineHeight: 18,
  },
  previewOrg: {
    fontSize: 11,
  },
  previewSnippet: {
    fontSize: 11,
    padding: 8,
    borderRadius: 6,
    lineHeight: 15,
  },
  previewDate: {
    fontSize: 11,
    fontWeight: '700',
  },
  modalActionsRow: {
    flexDirection: 'row',
    gap: 8,
    marginTop: 6,
  },
  modalCloseBtn: {
    flex: 1,
    paddingVertical: 9,
    borderRadius: 8,
    alignItems: 'center',
  },
  modalCloseBtnText: {
    fontSize: 12,
    fontWeight: '700',
  },
  modalApplyBtn: {
    flex: 2,
    paddingVertical: 9,
    borderRadius: 8,
    alignItems: 'center',
  },
  modalApplyBtnText: {
    color: '#fff',
    fontSize: 12,
    fontWeight: '800',
  },
});
