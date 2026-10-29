import 'package:flutter_test/flutter_test.dart';
import 'package:sarkari_job_alert/models/job_post.dart';
import 'package:sarkari_job_alert/utils/qualification_matcher.dart';

void main() {
  group('1. Job Lifecycle Verification (Active, Upcoming, Expired)', () {
    test('Job with future start date is Upcoming', () {
      final job = JobPost(
        id: 1,
        source: 'SarkariResult',
        url: 'https://test.com/1',
        title: 'Supreme Court Junior Court Attendant',
        org: 'Supreme Court of India',
        lastDate: '25/11/2026',
        startDate: '15/11/2026', // Future date
        eligibilitySnippet: '10th pass',
        qualificationsFound: ['10TH'],
        matchedKeywords: [],
        isMatched: true,
        scrapedAt: '2026-10-29',
      );

      expect(job.isExpired, isFalse);
      expect(job.isUpcoming, isTrue);
      expect(job.isActive, isFalse);
    });

    test('Job with Link Activate Soon is Upcoming', () {
      final job = JobPost(
        id: 2,
        source: 'SarkariResult',
        url: 'https://test.com/2',
        title: 'NTA NIFT Online Form 2027',
        org: 'NTA',
        lastDate: '16 November 2026',
        startDate: 'Link Activate Soon',
        eligibilitySnippet: '12th pass',
        qualificationsFound: ['12TH / 10+2'],
        matchedKeywords: [],
        isMatched: true,
        scrapedAt: '2026-10-29',
      );

      expect(job.isExpired, isFalse);
      expect(job.isUpcoming, isTrue);
      expect(job.isActive, isFalse);
    });

    test('Job currently accepting applications is Active', () {
      final job = JobPost(
        id: 3,
        source: 'SarkariResult',
        url: 'https://test.com/3',
        title: 'UPESSC Primary Teacher Online Form',
        org: 'UPESSC',
        lastDate: '23/11/2026',
        startDate: '16/09/2026', // Past start date
        eligibilitySnippet: 'Graduation with B.Ed / D.El.Ed',
        qualificationsFound: ['GRADUATE', 'B.ED'],
        matchedKeywords: [],
        isMatched: true,
        scrapedAt: '2026-10-29',
      );

      expect(job.isExpired, isFalse);
      expect(job.isUpcoming, isFalse);
      expect(job.isActive, isTrue);
    });

    test('Job with past closing date is Expired', () {
      final job = JobPost(
        id: 4,
        source: 'SarkariResult',
        url: 'https://test.com/4',
        title: 'Old Vacancy 2024',
        org: 'Govt Org',
        lastDate: '31/12/2024', // Expired
        startDate: '01/12/2024',
        eligibilitySnippet: 'Graduate',
        qualificationsFound: ['GRADUATE'],
        matchedKeywords: [],
        isMatched: true,
        scrapedAt: '2024-12-01',
      );

      expect(job.isExpired, isTrue);
      expect(job.isUpcoming, isFalse);
      expect(job.isActive, isFalse);
    });
  });

  group('2. Qualification Precision & Exclusion Verification', () {
    final btechJob = JobPost(
      id: 10,
      source: 'SarkariResult',
      url: 'https://test.com/btech',
      title: 'NeGD - MLOps Engineer',
      org: 'NeGD',
      lastDate: '20/11/2026',
      startDate: 'Active Now',
      eligibilitySnippet: 'B.E. / B.Tech in Computer Science / IT or M.Tech',
      qualificationsFound: ['B.TECH / B.E', 'M.TECH'],
      matchedKeywords: [],
      isMatched: true,
      scrapedAt: '2026-10-29',
    );

    final genericGradJob = JobPost(
      id: 11,
      source: 'SarkariResult',
      url: 'https://test.com/grad',
      title: 'Railway RRB NTPC Station Master',
      org: 'Railway Recruitment Board',
      lastDate: '25/11/2026',
      startDate: '27/10/2026',
      eligibilitySnippet: 'Bachelor Degree in Any Stream from a recognized university',
      qualificationsFound: ['GRADUATE'],
      matchedKeywords: [],
      isMatched: true,
      scrapedAt: '2026-10-29',
    );

    final bscResearchJob = JobPost(
      id: 12,
      source: 'SarkariResult',
      url: 'https://test.com/bsc',
      title: 'CSIR Research Assistant (Chemistry / Physics)',
      org: 'CSIR',
      lastDate: '15/11/2026',
      startDate: 'Active Now',
      eligibilitySnippet: 'B.Sc with Chemistry / Physics as main subject',
      qualificationsFound: ['B.SC'],
      matchedKeywords: [],
      isMatched: true,
      scrapedAt: '2026-10-29',
    );

    test('B.Sc candidate is NOT eligible for B.Tech Engineer job', () {
      final isEligible = QualificationMatcher.isJobEligible(
        btechJob,
        ['B.SC', 'GRADUATE', '12TH / 10+2'],
        highestDegree: 'B.SC',
      );
      expect(isEligible, isFalse);
    });

    test('Generic Graduate candidate is NOT eligible for B.Tech Engineer job', () {
      final isEligible = QualificationMatcher.isJobEligible(
        btechJob,
        ['GRADUATE', '12TH / 10+2'],
        highestDegree: 'GRADUATE',
      );
      expect(isEligible, isFalse);
    });

    test('B.Tech candidate IS eligible for B.Tech Engineer job', () {
      final isEligible = QualificationMatcher.isJobEligible(
        btechJob,
        ['B.TECH / B.E', 'GRADUATE', '12TH / 10+2'],
        highestDegree: 'B.TECH / B.E',
      );
      expect(isEligible, isTrue);
    });

    test('ALL Graduates (B.Tech, B.Sc, BA) are eligible for Generic Any-Stream Graduate jobs', () {
      expect(
        QualificationMatcher.isJobEligible(genericGradJob, ['B.TECH / B.E', 'GRADUATE'], highestDegree: 'B.TECH / B.E'),
        isTrue,
      );
      expect(
        QualificationMatcher.isJobEligible(genericGradJob, ['B.SC', 'GRADUATE'], highestDegree: 'B.SC'),
        isTrue,
      );
      expect(
        QualificationMatcher.isJobEligible(genericGradJob, ['GRADUATE', '12TH / 10+2'], highestDegree: 'GRADUATE'),
        isTrue,
      );
    });

    test('B.Sc candidate IS eligible for B.Sc Science Research job', () {
      final isEligible = QualificationMatcher.isJobEligible(
        bscResearchJob,
        ['B.SC', 'GRADUATE'],
        highestDegree: 'B.SC',
      );
      expect(isEligible, isTrue);
    });
  });

  group('3. Highest Qualification Relevance Sorting Verification', () {
    final btechJob = JobPost(
      id: 101,
      source: 'SarkariResult',
      url: 'https://test.com/btech',
      title: 'BEL Probationary Engineer',
      org: 'BEL',
      lastDate: '20/11/2026',
      startDate: 'Active Now',
      eligibilitySnippet: 'B.E / B.Tech in Engineering',
      qualificationsFound: ['B.TECH / B.E'],
      matchedKeywords: [],
      isMatched: true,
      scrapedAt: '2026-10-29',
    );

    final genericGradJob = JobPost(
      id: 102,
      source: 'SarkariResult',
      url: 'https://test.com/grad',
      title: 'Bank PO Probationary Officer',
      org: 'IBPS',
      lastDate: '25/11/2026',
      startDate: '27/10/2026',
      eligibilitySnippet: 'Degree in Any Stream',
      qualificationsFound: ['GRADUATE'],
      matchedKeywords: [],
      isMatched: true,
      scrapedAt: '2026-10-29',
    );

    final tenthJob = JobPost(
      id: 103,
      source: 'SarkariResult',
      url: 'https://test.com/10th',
      title: 'MTS Peon Staff',
      org: 'Staff Selection',
      lastDate: '30/11/2026',
      startDate: '01/11/2026',
      eligibilitySnippet: '10th class pass',
      qualificationsFound: ['10TH'],
      matchedKeywords: [],
      isMatched: true,
      scrapedAt: '2026-10-29',
    );

    test('For B.Tech candidate: B.Tech Engineering job is ranked NUMBER 1 at the top', () {
      final jobs = [tenthJob, genericGradJob, btechJob];
      final sorted = QualificationMatcher.sortJobsByRelevance(
        jobs,
        ['B.TECH / B.E', 'GRADUATE', '12TH / 10+2'],
        'B.TECH / B.E',
      );

      expect(sorted.first.id, equals(101)); // B.Tech job first!
      expect(sorted[1].id, equals(102));   // General graduate second
      expect(sorted.last.id, equals(103));  // 10th job last
    });

    test('For B.Sc candidate: B.Sc job is ranked NUMBER 1 at the top', () {
      final bscJob = JobPost(
        id: 104,
        source: 'SarkariResult',
        url: 'https://test.com/bsc',
        title: 'Senior Scientific Assistant (B.Sc Chemistry)',
        org: 'DRDO',
        lastDate: '20/11/2026',
        startDate: 'Active Now',
        eligibilitySnippet: 'B.Sc in Science with minimum 60% marks',
        qualificationsFound: ['B.SC'],
        matchedKeywords: [],
        isMatched: true,
        scrapedAt: '2026-10-29',
      );

      final jobs = [tenthJob, genericGradJob, bscJob];
      final sorted = QualificationMatcher.sortJobsByRelevance(
        jobs,
        ['B.SC', 'GRADUATE', '12TH / 10+2'],
        'B.SC',
      );

      expect(sorted.first.id, equals(104)); // B.Sc job first!
      expect(sorted[1].id, equals(102));   // General graduate second
      expect(sorted.last.id, equals(103));  // 10th job last
    });
  });
}

