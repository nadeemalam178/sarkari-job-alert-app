class JobPost {
  final int id;
  final String source;
  final String url;
  final String title;
  final String org;
  final String lastDate;
  final String startDate;
  final String totalPosts;
  final String applyLink;
  final String notificationLink;
  final String officialWebsite;
  final String ageLimit;
  final String applicationFee;
  final String eligibilitySnippet;
  final List<String> qualificationsFound;
  final List<String> matchedKeywords;
  final bool isMatched;
  final String scrapedAt;

  const JobPost({
    required this.id,
    required this.source,
    required this.url,
    required this.title,
    required this.org,
    required this.lastDate,
    this.startDate = 'Active Now',
    this.totalPosts = 'Various Posts',
    this.applyLink = '',
    this.notificationLink = '',
    this.officialWebsite = '',
    this.ageLimit = 'As per rules (18-35+ Yrs)',
    this.applicationFee = 'Gen/OBC: ₹100 | SC/ST: Exempted',
    required this.eligibilitySnippet,
    required this.qualificationsFound,
    required this.matchedKeywords,
    required this.isMatched,
    required this.scrapedAt,
  });

  factory JobPost.fromJson(Map<String, dynamic> json) {
    List<String> parseStringList(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
      }
      if (value is String) {
        if (value.startsWith('[') && value.endsWith(']')) {
          try {
            final cleaned = value.substring(1, value.length - 1);
            return cleaned
                .split(',')
                .map((e) => e.replaceAll('"', '').replaceAll("'", '').trim())
                .where((s) => s.isNotEmpty)
                .toList();
          } catch (_) {}
        }
        return value.split(',').map((e) => e.trim()).where((s) => s.isNotEmpty).toList();
      }
      return [];
    }

    final rawUrl = (json['url'] ?? '').toString();
    final rawApply = (json['apply_link'] ?? '').toString().trim();
    final rawNotif = (json['notification_link'] ?? '').toString().trim();
    final rawTotal = (json['total_posts'] ?? '').toString().trim();
    final rawStart = (json['start_date'] ?? '').toString().trim();
    final rawAge = (json['age_limit'] ?? '').toString().trim();
    final rawFee = (json['application_fee'] ?? '').toString().trim();

    return JobPost(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      source: (json['source'] ?? 'SarkariResult').toString(),
      url: rawUrl,
      title: (json['title'] ?? 'Untitled Recruitment').toString().trim(),
      org: (json['org'] ?? '').toString().trim(),
      lastDate: (json['last_date'] ?? 'Check Notification').toString().trim(),
      startDate: rawStart.isNotEmpty ? rawStart : 'Active Now',
      totalPosts: rawTotal.isNotEmpty ? rawTotal : 'Various Posts',
      applyLink: rawApply.isNotEmpty ? rawApply : rawUrl,
      notificationLink: rawNotif.isNotEmpty ? rawNotif : rawUrl,
      officialWebsite: (json['official_website'] ?? '').toString().trim(),
      ageLimit: rawAge.isNotEmpty ? rawAge : 'As per official rules (18-35+ Yrs)',
      applicationFee: rawFee.isNotEmpty ? rawFee : 'Gen/OBC: ₹100 | SC/ST: Exempted',
      eligibilitySnippet: (json['eligibility_snippet'] ?? '').toString().trim(),
      qualificationsFound: parseStringList(json['qualifications_found']),
      matchedKeywords: parseStringList(json['matched_keywords']),
      isMatched: json['is_matched'] == true || json['is_matched'] == 1,
      scrapedAt: (json['scraped_at'] ?? '').toString(),
    );
  }

  bool get isExpired {
    final lower = lastDate.toLowerCase().trim();
    if (lower.contains('cancelled') || lower.contains('closed')) return true;
    final parsed = _parseDateTime(lastDate);
    if (parsed != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      if (parsed.isBefore(today)) {
        return true;
      }
    }
    return false;
  }

  bool get isUpcoming {
    if (isExpired) return false;
    final parsedStart = _parseDateTime(startDate);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (parsedStart != null) {
      return parsedStart.isAfter(today);
    }

    final lowerStart = startDate.toLowerCase().trim();
    final lowerTitle = title.toLowerCase();

    if (lowerStart.contains('link activate soon') ||
        lowerStart.contains('notify soon') ||
        lowerStart.contains('coming soon') ||
        lowerStart.contains('activate soon') ||
        lowerStart.contains('available soon') ||
        lowerStart.contains('opening soon') ||
        lowerStart.contains('calendar') ||
        lowerStart.contains('to be notified') ||
        lowerTitle.contains('form 2027')) {
      return true;
    }

    return false;
  }

  bool get isActive => !isUpcoming && !isExpired;

  static DateTime? _parseDateTime(String raw) {
    if (raw.isEmpty) return null;
    final s = raw.toLowerCase().trim();

    // Match DD/MM/YYYY or DD-MM-YYYY
    final numMatch = RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})').firstMatch(s);
    if (numMatch != null) {
      final d = int.tryParse(numMatch.group(1)!) ?? 1;
      final m = int.tryParse(numMatch.group(2)!) ?? 1;
      var y = int.tryParse(numMatch.group(3)!) ?? 2026;
      if (y < 100) y += 2000;
      try {
        return DateTime(y, m, d);
      } catch (_) {
        return null;
      }
    }

    // Match DD Month YYYY (e.g. 05 November 2026)
    final wordMatch = RegExp(r'(\d{1,2})(?:st|nd|rd|th)?\s+([a-z]+)\s+(\d{4})').firstMatch(s);
    if (wordMatch != null) {
      final d = int.tryParse(wordMatch.group(1)!) ?? 1;
      final mStr = wordMatch.group(2)!;
      final y = int.tryParse(wordMatch.group(3)!) ?? 2026;
      final m = _monthNameToNumber(mStr);
      if (m != null) {
        try {
          return DateTime(y, m, d);
        } catch (_) {
          return null;
        }
      }
    }

    // Match Month DD, YYYY (e.g. November 05, 2026)
    final mdyMatch = RegExp(r'([a-z]+)\s+(\d{1,2}),?\s+(\d{4})').firstMatch(s);
    if (mdyMatch != null) {
      final mStr = mdyMatch.group(1)!;
      final d = int.tryParse(mdyMatch.group(2)!) ?? 1;
      final y = int.tryParse(mdyMatch.group(3)!) ?? 2026;
      final m = _monthNameToNumber(mStr);
      if (m != null) {
        try {
          return DateTime(y, m, d);
        } catch (_) {
          return null;
        }
      }
    }

    return null;
  }

  static int? _monthNameToNumber(String name) {
    const months = {
      'jan': 1, 'january': 1,
      'feb': 2, 'february': 2,
      'mar': 3, 'march': 3,
      'apr': 4, 'april': 4,
      'may': 5,
      'jun': 6, 'june': 6,
      'jul': 7, 'july': 7,
      'aug': 8, 'august': 8,
      'sep': 9, 'september': 9,
      'oct': 10, 'october': 10,
      'nov': 11, 'november': 11,
      'dec': 12, 'december': 12,
    };
    return months[name];
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'source': source,
        'url': url,
        'title': title,
        'org': org,
        'last_date': lastDate,
        'start_date': startDate,
        'total_posts': totalPosts,
        'apply_link': applyLink,
        'notification_link': notificationLink,
        'official_website': officialWebsite,
        'age_limit': ageLimit,
        'application_fee': applicationFee,
        'eligibility_snippet': eligibilitySnippet,
        'qualifications_found': qualificationsFound,
        'matched_keywords': matchedKeywords,
        'is_matched': isMatched,
        'scraped_at': scrapedAt,
      };
}
