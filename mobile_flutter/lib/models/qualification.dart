class Qualification {
  final String code;
  final String name;
  final String category;

  const Qualification({
    required this.code,
    required this.name,
    required this.category,
  });

  factory Qualification.fromJson(Map<String, dynamic> json) {
    return Qualification(
      code: (json['code'] ?? '').toString().toUpperCase().trim(),
      name: (json['name'] ?? '').toString().trim(),
      category: (json['category'] ?? 'General').toString().trim(),
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'category': category,
      };

  static const List<Qualification> defaultMasterList = [
    Qualification(code: 'B.SC', name: 'B.Sc (Bachelor of Science - Physics, Chem, Maths, Bio)', category: 'Graduation'),
    Qualification(code: 'GRADUATE', name: 'Graduate in Any Stream (BA / BSc / BCom / BTech)', category: 'Graduation'),
    Qualification(code: 'B.TECH / B.E', name: 'B.Tech / B.E (Engineering Degree)', category: 'Engineering'),
    Qualification(code: 'B.COM', name: 'B.Com (Bachelor of Commerce)', category: 'Graduation'),
    Qualification(code: 'BA', name: 'B.A (Bachelor of Arts)', category: 'Graduation'),
    Qualification(code: '12TH / 10+2', name: '12th Pass / Intermediate', category: 'Schooling'),
    Qualification(code: '12TH PCM', name: '12th Pass (Physics, Chemistry, Maths)', category: 'Schooling'),
    Qualification(code: '10TH', name: '10th Pass / High School Matriculation', category: 'Schooling'),
    Qualification(code: 'B.ED', name: 'B.Ed (Bachelor of Education)', category: 'Teaching'),
    Qualification(code: 'CTET', name: 'CTET (Central Teacher Eligibility Test)', category: 'Teaching'),
    Qualification(code: 'STET', name: 'STET / State Teacher Eligibility', category: 'Teaching'),
    Qualification(code: 'DIPLOMA', name: 'Polytechnic Engineering Diploma', category: 'Diploma & ITI'),
    Qualification(code: 'ITI', name: 'ITI Trade Certificate', category: 'Diploma & ITI'),
    Qualification(code: 'POST GRADUATE', name: 'Post Graduate / Master Degree (M.Sc, M.A, M.Com)', category: 'Post Graduation'),
    Qualification(code: 'BCA', name: 'BCA (Computer Applications)', category: 'Graduation'),
    Qualification(code: 'MCA', name: 'MCA (Master in Computer Application)', category: 'Post Graduation'),
    Qualification(code: 'POLICE / DEFENCE', name: 'Police / Constable / SI / Paramilitary', category: 'Defence'),
  ];
}
