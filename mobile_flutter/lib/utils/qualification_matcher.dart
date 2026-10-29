import '../models/job_post.dart';

class QualificationMatcher {
  /// Resolves the candidate's active qualifications (both highest and additional) into all valid eligibility streams.
  /// A candidate with 'B.SC' is a Graduate, has passed 12th PCM, and 10th.
  /// Hence, they are eligible for:
  /// - All general Graduate posts (RRB NTPC Graduate, SSC CGL, UPSC, Bank PO)
  /// - Any specialized Science/B.Sc posts
  /// - All 12th level posts (RRB NTPC Under-Graduate, SSC CHSL)
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
        streams.addAll(['B.TECH / B.E', 'GRADUATE', 'DIPLOMA', '12TH PCM', '12TH / 10+2', '10TH', 'ENGINEERING']);
      }
      if (q == 'B.COM') {
        streams.addAll(['B.COM', 'GRADUATE', '12TH / 10+2', '10TH', 'COMMERCE', 'FINANCE']);
      }
      if (q == 'BA') {
        streams.addAll(['BA', 'GRADUATE', '12TH / 10+2', '10TH', 'ARTS']);
      }
      if (q == 'BCA') {
        streams.addAll(['BCA', 'GRADUATE', '12TH / 10+2', '10TH', 'COMPUTER']);
      }
      if (q == 'LLB') {
        streams.addAll(['LLB', 'GRADUATE', '12TH / 10+2', '10TH', 'LAW']);
      }
      if (q == 'MBBS / BDS') {
        streams.addAll(['MBBS / BDS', 'GRADUATE', '12TH PCB', '12TH / 10+2', '10TH', 'MEDICAL']);
      }
      if (q.contains('PHARM')) {
        streams.addAll(['B.PHARM / D.PHARM', '12TH PCB', '12TH / 10+2', '10TH', 'PHARMACY']);
      }
      if (q.contains('NURSING')) {
        streams.addAll(['NURSING (B.SC / GNM)', '12TH PCB', '12TH / 10+2', '10TH', 'NURSING']);
      }
      if (q == 'POST GRADUATE' || q.contains('POST GRADUATE') || q.contains('MASTER') || q == 'MCA') {
        streams.addAll(['POST GRADUATE', 'GRADUATE', '12TH / 10+2', '10TH', 'MCA']);
      }
      if (q.contains('PH.D')) {
        streams.addAll(['PH.D / RESEARCH', 'POST GRADUATE', 'GRADUATE', '12TH / 10+2', '10TH']);
      }
      if (q == '12TH / 10+2' || q == '12TH PCM' || q == '12TH PCB' || q.contains('12TH')) {
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
      if (q == 'B.ED' || q.contains('B.ED')) {
        streams.addAll(['B.ED', 'TEACHING']);
      }
      if (q.contains('D.EL.ED') || q.contains('BTC')) {
        streams.addAll(['D.EL.ED / BTC', 'TEACHING']);
      }
      if (q.contains('CTET')) {
        streams.addAll(['CTET', 'CTET PAPER 1', 'CTET PAPER 2', 'TEACHING']);
      }
      if (q.contains('TET') || q.contains('STET')) {
        streams.addAll(['STET / STATE TET', 'TEACHING']);
      }
      if (q == 'CCC' || q.contains('CCC')) {
        streams.addAll(['CCC', 'COMPUTER']);
      }
      if (q.contains('TYPING')) {
        streams.addAll(['TYPING', 'TYPING (HINDI)', 'TYPING (ENGLISH)', 'CLERK']);
      }
      if (q.contains('STENO')) {
        streams.addAll(['STENO', 'SHORTHAND']);
      }
      if (q.contains('GATE')) {
        streams.addAll(['GATE', 'PSU']);
      }
      if (q.contains('NET')) {
        streams.addAll(['UGC NET / JRF', 'CSIR NET', 'PROFESSOR']);
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

    if (eligibleStreams.contains('10TH') && combinedText.contains('10TH')) return true;
    if (eligibleStreams.contains('12TH / 10+2') && combinedText.contains('12TH')) return true;
    if (eligibleStreams.contains('B.ED') && combinedText.contains('B.ED')) return true;
    if (eligibleStreams.contains('CTET') && combinedText.contains('CTET')) return true;
    if (eligibleStreams.contains('ITI') && combinedText.contains('ITI')) return true;

    return false;
  }
}
