class Qualification {
  final String code;
  final String name;
  final String category;
  final bool isAdditional;

  const Qualification({
    required this.code,
    required this.name,
    required this.category,
    this.isAdditional = false,
  });

  factory Qualification.fromJson(Map<String, dynamic> json) {
    return Qualification(
      code: (json['code'] ?? '').toString().toUpperCase().trim(),
      name: (json['name'] ?? '').toString().trim(),
      category: (json['category'] ?? 'General').toString().trim(),
      isAdditional: json['is_additional'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'category': category,
        'is_additional': isAdditional,
      };

  /// 1. Highest Regular Educational Degrees (Single-choice tier)
  static const List<Qualification> highestDegrees = [
    Qualification(code: 'B.SC', name: 'B.Sc (Bachelor of Science - Physics, Chem, Maths, Bio)', category: 'Graduation'),
    Qualification(code: 'GRADUATE', name: 'Graduate in Any Stream (BA / BSc / BCom / BTech)', category: 'Graduation'),
    Qualification(code: 'B.TECH / B.E', name: 'B.Tech / B.E (Engineering - CS, Civil, Mech, EE)', category: 'Graduation'),
    Qualification(code: 'B.COM', name: 'B.Com (Bachelor of Commerce / Finance)', category: 'Graduation'),
    Qualification(code: 'BA', name: 'B.A (Bachelor of Arts / Humanities)', category: 'Graduation'),
    Qualification(code: 'BCA', name: 'BCA (Bachelor of Computer Applications)', category: 'Graduation'),
    Qualification(code: 'BBA', name: 'BBA (Bachelor of Business Administration)', category: 'Graduation'),
    Qualification(code: 'LLB', name: 'LLB (Bachelor of Laws)', category: 'Professional'),
    Qualification(code: 'MBBS / BDS', name: 'MBBS / BDS (Medical Degree)', category: 'Medical'),
    Qualification(code: 'B.PHARM / D.PHARM', name: 'B.Pharm / D.Pharm (Pharmacy)', category: 'Medical'),
    Qualification(code: 'NURSING (B.SC / GNM)', name: 'B.Sc Nursing / GNM Diploma', category: 'Medical'),
    Qualification(code: 'DIPLOMA', name: 'Polytechnic Engineering Diploma (3 Years)', category: 'Diploma & ITI'),
    Qualification(code: '12TH / 10+2', name: '12th Pass / Intermediate (Any Stream)', category: 'Schooling'),
    Qualification(code: '12TH PCM', name: '12th Pass (Physics, Chemistry, Maths)', category: 'Schooling'),
    Qualification(code: '12TH PCB', name: '12th Pass (Physics, Chemistry, Biology)', category: 'Schooling'),
    Qualification(code: '10TH', name: '10th Pass / High School Matriculation', category: 'Schooling'),
    Qualification(code: 'POST GRADUATE', name: 'Post Graduate (M.Sc, M.Com, M.A, M.Tech, MBA)', category: 'Post Graduation'),
    Qualification(code: 'MCA', name: 'MCA (Master in Computer Application)', category: 'Post Graduation'),
    Qualification(code: 'PH.D / RESEARCH', name: 'Ph.D / Doctorate / M.Phil', category: 'Post Graduation'),
  ];

  /// 2. Additional & Professional Certifications (Multi-choice tier)
  static const List<Qualification> additionalCertificates = [
    Qualification(code: 'B.ED', name: 'B.Ed (Bachelor of Education)', category: 'Teaching & TET', isAdditional: true),
    Qualification(code: 'D.EL.ED / BTC', name: 'D.El.Ed / BTC (Elementary Education)', category: 'Teaching & TET', isAdditional: true),
    Qualification(code: 'CTET PAPER 1', name: 'CTET Paper 1 (Primary Class 1-5)', category: 'Teaching & TET', isAdditional: true),
    Qualification(code: 'CTET PAPER 2', name: 'CTET Paper 2 (Upper Primary Class 6-8)', category: 'Teaching & TET', isAdditional: true),
    Qualification(code: 'STET / STATE TET', name: 'State Teacher Eligibility (STET / UPTET / REET)', category: 'Teaching & TET', isAdditional: true),
    Qualification(code: 'ITI', name: 'ITI National Trade Certificate (NCVT/SCVT)', category: 'Vocational', isAdditional: true),
    Qualification(code: 'CCC', name: 'CCC (Course on Computer Concepts - NIELIT)', category: 'Computer & Typing', isAdditional: true),
    Qualification(code: 'O LEVEL', name: 'O-Level Computer Diploma (NIELIT)', category: 'Computer & Typing', isAdditional: true),
    Qualification(code: 'TYPING (HINDI)', name: 'Hindi Typing (25 / 30 WPM KrutiDev / Mangal)', category: 'Computer & Typing', isAdditional: true),
    Qualification(code: 'TYPING (ENGLISH)', name: 'English Typing (30 / 35 WPM)', category: 'Computer & Typing', isAdditional: true),
    Qualification(code: 'STENO', name: 'Stenographer / Shorthand (80 / 100 WPM)', category: 'Computer & Typing', isAdditional: true),
    Qualification(code: 'GATE', name: 'GATE Qualified Scorecard (PSU & Fellowship)', category: 'Competitive Exam', isAdditional: true),
    Qualification(code: 'UGC NET / JRF', name: 'UGC NET / JRF (Assistant Professor)', category: 'Competitive Exam', isAdditional: true),
    Qualification(code: 'CSIR NET', name: 'CSIR NET (Science Junior Research Fellowship)', category: 'Competitive Exam', isAdditional: true),
    Qualification(code: 'CA / CMA / CS', name: 'Chartered Accountant / CMA / Company Secretary', category: 'Finance', isAdditional: true),
    Qualification(code: 'NCC CERTIFICATE', name: 'NCC "B" or "C" Wing Certificate', category: 'Special Quota', isAdditional: true),
    Qualification(code: 'SPORTS QUOTA', name: 'National / State Level Sports Certificate', category: 'Special Quota', isAdditional: true),
    Qualification(code: 'DRIVING LICENSE', name: 'Commercial / Heavy Driving License (HMV/LMV)', category: 'Vocational', isAdditional: true),
  ];

  /// Combined master catalogue
  static List<Qualification> get defaultMasterList => [
        ...highestDegrees,
        ...additionalCertificates,
      ];
}
