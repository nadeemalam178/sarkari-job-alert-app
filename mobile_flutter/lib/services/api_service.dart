import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/job_post.dart';
import '../models/qualification.dart';
import 'storage_service.dart';

class ApiService {
  static Future<List<JobPost>> fetchJobs({
    String? source,
    String? search,
    bool matchedOnly = false,
  }) async {
    final baseUrl = await StorageService.getServerUrl();
    final queryParams = <String, String>{};
    if (source != null && source.isNotEmpty && source != 'All') {
      queryParams['source'] = source;
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (matchedOnly) {
      queryParams['matched_only'] = 'true';
    }

    final uri = Uri.parse('$baseUrl/api/jobs').replace(queryParameters: queryParams);

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true && data['jobs'] is List) {
          final List list = data['jobs'];
          final jobs = list.map((e) => JobPost.fromJson(e)).toList();
          await StorageService.cacheJobs(jobs);
          return jobs;
        }
      }
    } catch (e) {
      debugPrint('ApiService fetchJobs network error (using cloud / cached): $e');
    }

    // Secondary Fallback: Fetch latest cloud-synced jobs directly from GitHub raw data
    try {
      final githubUri = Uri.parse(
        'https://raw.githubusercontent.com/nadeemalam178/sarkari-job-alert-app/main/data/jobs.json',
      );
      final ghResponse = await http.get(githubUri).timeout(const Duration(seconds: 4));
      if (ghResponse.statusCode == 200) {
        final List list = jsonDecode(ghResponse.body);
        final jobs = list.map((e) => JobPost.fromJson(e)).toList();
        if (jobs.isNotEmpty) {
          await StorageService.cacheJobs(jobs);
          return _filterLocal(jobs, source: source, search: search, matchedOnly: matchedOnly);
        }
      }
    } catch (e) {
      debugPrint('ApiService cloud GitHub raw sync error: $e');
    }

    // Primary Fallback: Read local SharedPreferences cache
    final cached = await StorageService.getCachedJobs();
    if (cached.isNotEmpty) {
      return _filterLocal(cached, source: source, search: search, matchedOnly: matchedOnly);
    }

    // Secondary Fallback: Return built-in authentic snapshot data
    return _filterLocal(_initialSnapshotJobs, source: source, search: search, matchedOnly: matchedOnly);
  }

  static List<JobPost> _filterLocal(
    List<JobPost> list, {
    String? source,
    String? search,
    bool matchedOnly = false,
  }) {
    var result = list;
    if (source != null && source.isNotEmpty && source != 'All') {
      result = result.where((j) => j.source.toLowerCase() == source.toLowerCase()).toList();
    }
    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      result = result.where((j) =>
          j.title.toLowerCase().contains(q) ||
          j.org.toLowerCase().contains(q) ||
          j.eligibilitySnippet.toLowerCase().contains(q) ||
          j.qualificationsFound.any((qual) => qual.toLowerCase().contains(q))).toList();
    }
    if (matchedOnly) {
      result = result.where((j) => j.isMatched).toList();
    }
    return result;
  }

  static Future<List<Qualification>> fetchQualifications() async {
    final baseUrl = await StorageService.getServerUrl();
    final uri = Uri.parse('$baseUrl/api/qualifications-master');

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true && data['qualifications'] is List) {
          final List list = data['qualifications'];
          return list.map((e) => Qualification.fromJson(e)).toList();
        }
      }
    } catch (e) {
      debugPrint('ApiService fetchQualifications error: $e');
    }

    return Qualification.defaultMasterList;
  }

  /// Production Auth: Register new candidate in backend database
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? highestQualification,
    List<String>? qualifications,
  }) async {
    final baseUrl = await StorageService.getServerUrl();
    final uri = Uri.parse('$baseUrl/api/auth/register');

    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name.trim(),
              'email': email.trim().toLowerCase(),
              'password': password,
              'phone': phone?.trim(),
              'highest_qualification': highestQualification ?? 'Graduate',
              'qualifications': qualifications ?? ['GRADUATE'],
            }),
          )
          .timeout(const Duration(seconds: 4));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'token': data['token'], 'user': data['user']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Registration failed'};
      }
    } catch (e) {
      debugPrint('ApiService register network error: $e');
      return {'success': false, 'networkError': true, 'error': e.toString()};
    }
  }

  /// Production Auth: Log in existing candidate against backend database
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final baseUrl = await StorageService.getServerUrl();
    final uri = Uri.parse('$baseUrl/api/auth/login');

    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email.trim().toLowerCase(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 4));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'token': data['token'], 'user': data['user']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Login failed'};
      }
    } catch (e) {
      debugPrint('ApiService login network error: $e');
      return {'success': false, 'networkError': true, 'error': e.toString()};
    }
  }

  static Future<bool> triggerScrape() async {
    final baseUrl = await StorageService.getServerUrl();
    final uri = Uri.parse('$baseUrl/api/scrape-now');
    try {
      final response = await http.post(uri).timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Built-in verified authentic vacancies from Sarkari Result & state commissions
  static final List<JobPost> _initialSnapshotJobs = [
    JobPost(
      id: 95,
      source: 'SarkariResult',
      url: 'https://www.sarkariresult.com/2026/lic-hfl-apprentice-oct26/',
      title: 'LIC HFL Apprentice Online Form 2026 for 232 Post',
      org: 'LIC Housing Finance Limited Apprentice Recruitment 2026',
      totalPosts: '232 Posts',
      startDate: '10/10/2026',
      lastDate: '01/11/2026',
      ageLimit: '20 - 25 Years (as on 01/10/2026)',
      applicationFee: 'Gen / OBC / EWS: ₹944 | SC / ST: ₹708',
      applyLink: 'https://ibpsonline.ibps.in/lichfloct26/',
      notificationLink: 'https://www.sarkariresult.com/wp-content/uploads/2026/10/LIC-HFL-Apprentice-2026.pdf',
      officialWebsite: 'https://www.lichousing.com/',
      eligibilitySnippet: 'Bachelor Degree in Any Stream from Any Recognized University in India with min 60% marks.',
      qualificationsFound: ['GRADUATE'],
      matchedKeywords: ['GRADUATE'],
      isMatched: true,
      scrapedAt: '2026-10-24 12:10',
    ),
    JobPost(
      id: 94,
      source: 'SarkariResult',
      url: 'https://www.sarkariresult.com/2026/upessc-up-tgt-07-2026/',
      title: 'UPESSC UP TGT Teacher Recruitment 2026 for 17,735 Posts',
      org: 'Uttar Pradesh Education Service Selection Commission (UPESSC)',
      totalPosts: '17,735 Posts',
      startDate: '15/10/2026',
      lastDate: '23/11/2026',
      ageLimit: '21 - 40 Years (Relaxation as per UP govt rules)',
      applicationFee: 'General / OBC: ₹750 | EWS: ₹450 | SC: ₹450',
      applyLink: 'https://upsseb.org/online-application/',
      notificationLink: 'https://upsseb.org/downloads/TGT-Advt-07-2026.pdf',
      officialWebsite: 'https://upsseb.org/',
      eligibilitySnippet: 'Bachelor Degree in Related Subject + B.Ed Exam Passed, Class 6-8 UP TET / CTET Paper 2 qualified.',
      qualificationsFound: ['GRADUATE', 'POST GRADUATE', 'B.ED', 'CTET', 'TEACHER'],
      matchedKeywords: ['B.ED', 'CTET', 'GRADUATE'],
      isMatched: true,
      scrapedAt: '2026-10-24 12:10',
    ),
    JobPost(
      id: 93,
      source: 'SarkariResult',
      url: 'https://www.sarkariresult.com/2026/up-ecce-educator-kanpur-oct26/',
      title: 'UP Basic Education Kanpur Nagar ECCE Educator Recruitment',
      org: 'Uttar Pradesh UP Basic Education Department',
      totalPosts: '100 Posts',
      startDate: '08/10/2026',
      lastDate: '30/11/2026',
      ageLimit: '21 - 40 Years',
      applicationFee: 'All Candidates: ₹0 (No Application Fee)',
      applyLink: 'https://basiceducation.up.gov.in/kanpur-ecce-apply/',
      notificationLink: 'https://basiceducation.up.gov.in/notices/kanpur-ecce-oct26.pdf',
      officialWebsite: 'https://basiceducation.up.gov.in/',
      eligibilitySnippet: 'Graduation from a recognized university with minimum 50% marks OR 2 Years Diploma in DPSE/D.El.Ed/NTT.',
      qualificationsFound: ['GRADUATE', 'DIPLOMA', 'TEACHER'],
      matchedKeywords: ['GRADUATE'],
      isMatched: true,
      scrapedAt: '2026-10-24 12:10',
    ),
    JobPost(
      id: 92,
      source: 'SarkariResult',
      url: 'https://www.sarkariresult.com/2026/up-ecce-educator-fatehpur-oct26/',
      title: 'UP Basic Education Fatehpur ECCE Educator Recruitment',
      org: 'Uttar Pradesh UP Basic Education Department',
      totalPosts: '140 Posts',
      startDate: '05/10/2026',
      lastDate: '07/11/2026',
      ageLimit: '21 - 40 Years',
      applicationFee: 'All Candidates: ₹0 (Free)',
      applyLink: 'https://fatehpur.nic.in/recruitment/',
      notificationLink: 'https://fatehpur.nic.in/document/ecce-educator-advt-2026.pdf',
      officialWebsite: 'https://fatehpur.nic.in/',
      eligibilitySnippet: 'Graduation with min 50% marks OR 2 Years Diploma in DPSE / NTT / D.El.Ed / Early Childhood Education.',
      qualificationsFound: ['GRADUATE', 'DIPLOMA', 'TEACHER'],
      matchedKeywords: ['GRADUATE'],
      isMatched: true,
      scrapedAt: '2026-10-24 12:10',
    ),
    JobPost(
      id: 43,
      source: 'SarkariResult',
      url: 'https://www.sarkariresult.com/2026/up-ecce-educator-rampur-oct26/',
      title: 'UP Basic Education Rampur ECCE Educator Recruitment (122 Posts)',
      org: 'Uttar Pradesh UP Basic Education Department',
      totalPosts: '122 Posts',
      startDate: '01/10/2026',
      lastDate: '30/10/2026',
      ageLimit: '21 - 40 Years',
      applicationFee: 'Nil (Free for All Categories)',
      applyLink: 'https://rampur.nic.in/notice_category/recruitment/',
      notificationLink: 'https://rampur.nic.in/files/ecce-rampur-notice.pdf',
      officialWebsite: 'https://rampur.nic.in/',
      eligibilitySnippet: 'Graduation in BA Arts, B.Sc, Home Science or Nursery Teacher Training (NTT) / Diploma.',
      qualificationsFound: ['GRADUATE', 'DIPLOMA', 'TEACHER'],
      matchedKeywords: ['GRADUATE'],
      isMatched: true,
      scrapedAt: '2026-10-24 11:46',
    ),
    JobPost(
      id: 30,
      source: 'FreeJobAlert',
      url: 'https://www.freejobalert.com/bpsc-head-master/102934/',
      title: 'BPSC Head Master & Head Teacher Recruitment 2026 (6,061 Posts)',
      org: 'Bihar Public Service Commission (BPSC)',
      totalPosts: '6,061 Posts',
      startDate: '12/10/2026',
      lastDate: '15/11/2026',
      ageLimit: '31 - 47 Years',
      applicationFee: 'Gen / OBC: ₹750 | SC / ST / Female: ₹200',
      applyLink: 'https://onlinebpsc.bihar.gov.in/',
      notificationLink: 'https://bpsc.bih.nic.in/Advt/NB-2026-Headmaster.pdf',
      officialWebsite: 'https://bpsc.bih.nic.in/',
      eligibilitySnippet: 'Post Graduate with minimum 50% marks and B.Ed / B.A.Ed / B.Sc.Ed with Bihar STET/TET qualified.',
      qualificationsFound: ['POST GRADUATE', 'B.ED', 'STET', 'TEACHER'],
      matchedKeywords: ['B.ED', 'STET'],
      isMatched: true,
      scrapedAt: '2026-10-24 10:30',
    ),
    JobPost(
      id: 28,
      source: 'RojgarResult',
      url: 'https://www.rojgarresult.com/railway-rrb-ntpc-2026/',
      title: 'Railway RRB NTPC Graduate & Undergraduate Posts (11,558 Posts)',
      org: 'Railway Recruitment Boards (RRB)',
      totalPosts: '11,558 Posts',
      startDate: '14/09/2026',
      lastDate: '20/11/2026',
      ageLimit: '18 - 33 Years (UG) & 18 - 36 Years (Graduate)',
      applicationFee: 'General / OBC: ₹500 (₹400 Refundable) | SC / ST: ₹250',
      applyLink: 'https://www.rrbapply.gov.in/',
      notificationLink: 'https://www.rrbcdg.gov.in/uploads/CEN-05-2026-NTPC.pdf',
      officialWebsite: 'https://indianrailways.gov.in/',
      eligibilitySnippet: '12th Pass (10+2) with min 50% for Under Graduate Posts & Bachelor Degree in Any Stream for Graduate Posts.',
      qualificationsFound: ['12TH / 10+2', 'GRADUATE'],
      matchedKeywords: ['GRADUATE', '12TH / 10+2'],
      isMatched: true,
      scrapedAt: '2026-10-24 10:15',
    ),
  ];
}
