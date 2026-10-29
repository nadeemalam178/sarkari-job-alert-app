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
