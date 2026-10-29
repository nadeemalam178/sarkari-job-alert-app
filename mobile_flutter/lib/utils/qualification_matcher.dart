import '../models/job_post.dart';

class QualificationMatcher {
  /// Resolves the candidate's active qualifications into all valid eligibility streams.
  /// A candidate with 'B.SC' is a Graduate, has passed 12th PCM/PCB, and 10th.
  /// Hence, they are eligible for:
  /// - All general Graduate posts (RRB NTPC Graduate, SSC CGL, UPSC, Bank PO)
  /// - Any specialized Science/B.Sc posts
  /// - All 12th level posts (RRB NTPC Under-Graduate, SSC CHSL, Railway Group D)
  /// - All 10th level posts
  static Set<String> getEligibleStreams(Iterable<String> candidateQuals) {
    final streams = <String>{};
    for (final raw in candidateQuals) {
      final q = raw.toUpperCase().trim();
      streams.add(q);

      if (q == 'B.SC' || q.contains('B.SC') || q.contains('BSC')) {
        streams.addAll(['B.SC', 'GRADUATE', '12TH / 10+2', '12TH PCM', '10TH', 'SCIENCE']);
      }
      if (q == 'GRADUATE' || q.contains('GRADUATE')) {
        streams.addAll(['GRADUATE', '12TH / 10+2', '10TH', 'BA', 'B.SC', 'B.COM', 'BBA']);
      }
      if (q == 'B.TECH / B.E' || q.contains('B.TECH') || q.contains('ENGINEERING')) {
        streams.addAll(['B.TECH / B.E', 'GRADUATE', 'DIPLOMA', '12TH PCM', '12TH / 10+2', '10TH']);
      }
      if (q == 'B.COM') {
        streams.addAll(['B.COM', 'GRADUATE', '12TH / 10+2', '10TH', 'COMMERCE']);
      }
      if (q == 'BA') {
        streams.addAll(['BA', 'GRADUATE', '12TH / 10+2', '10TH', 'ARTS']);
      }
      if (q == 'POST GRADUATE' || q.contains('POST GRADUATE') || q.contains('MASTER')) {
        streams.addAll(['POST GRADUATE', 'GRADUATE', '12TH / 10+2', '10TH']);
      }
      if (q == '12TH / 10+2' || q == '12TH PCM' || q.contains('12TH')) {
        streams.addAll(['12TH / 10+2', '10TH']);
      }
      if (q == '10TH') {
        streams.add('10TH');
      }
      if (q == 'DIPLOMA') {
        streams.addAll(['DIPLOMA', '12TH / 10+2', '10TH']);
      }
      if (q == 'ITI') {
        streams.addAll(['ITI', '10TH']);
      }
    }
    return streams;
  }

  /// Determines if a job post matches the candidate's qualifications
  static bool isJobEligible(JobPost job, Iterable<String> candidateQuals) {
    if (candidateQuals.isEmpty) return true;
    final eligibleStreams = getEligibleStreams(candidateQuals);

    final jobQuals = job.qualificationsFound.map((e) => e.toUpperCase().trim()).toSet();
    if (jobQuals.isEmpty) return true;

    // 1. Direct overlap with candidate's eligible streams
    for (final stream in eligibleStreams) {
      if (jobQuals.contains(stream)) return true;
    }

    // 2. Semantic matching in text (Railway RRB NTPC, SSC CGL, etc.)
    final combinedText = '${job.title} ${job.eligibilitySnippet} ${job.org}'.toUpperCase();
    if (eligibleStreams.contains('B.SC')) {
      if (combinedText.contains('B.SC') ||
          combinedText.contains('SCIENCE') ||
          combinedText.contains('ANY GRADUATE') ||
          combinedText.contains('BACHELOR DEGREE') ||
          combinedText.contains('DEGREE IN ANY STREAM') ||
          combinedText.contains('RRB NTPC') ||
          combinedText.contains('RAILWAY')) {
        return true;
      }
    }

    if (eligibleStreams.contains('GRADUATE')) {
      if (combinedText.contains('GRADUATE') ||
          combinedText.contains('DEGREE') ||
          combinedText.contains('ANY STREAM') ||
          combinedText.contains('NTPC') ||
          combinedText.contains('CGL')) {
        return true;
      }
    }

    return false;
  }
}
