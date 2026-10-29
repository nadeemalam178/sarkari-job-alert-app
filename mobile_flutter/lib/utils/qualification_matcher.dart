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
        streams.addAll([
          'B.SC',
          'GRADUATE',
          '12TH / 10+2',
          '12TH PCM',
          '10TH',
          'SCIENCE',
        ]);
      }
      if (q == 'GRADUATE' || q.contains('GRADUATE')) {
        streams.addAll([
          'GRADUATE',
          '12TH / 10+2',
          '10TH',
          'BA',
          'B.SC',
          'B.COM',
          'BBA',
        ]);
      }
      if (q == 'B.TECH / B.E' ||
          q.contains('B.TECH') ||
          q.contains('ENGINEERING')) {
        streams.addAll([
          'B.TECH / B.E',
          'GRADUATE',
          'DIPLOMA',
          '12TH PCM',
          '12TH / 10+2',
          '10TH',
          'ENGINEERING',
        ]);
      }
      if (q == 'B.COM') {
        streams.addAll([
          'B.COM',
          'GRADUATE',
          '12TH / 10+2',
          '10TH',
          'COMMERCE',
          'FINANCE',
        ]);
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
        streams.addAll([
          'MBBS / BDS',
          'GRADUATE',
          '12TH PCB',
          '12TH / 10+2',
          '10TH',
          'MEDICAL',
        ]);
      }
      if (q.contains('PHARM')) {
        streams.addAll([
          'B.PHARM / D.PHARM',
          '12TH PCB',
          '12TH / 10+2',
          '10TH',
          'PHARMACY',
        ]);
      }
      if (q.contains('NURSING')) {
        streams.addAll([
          'NURSING (B.SC / GNM)',
          '12TH PCB',
          '12TH / 10+2',
          '10TH',
          'NURSING',
        ]);
      }
      if (q == 'POST GRADUATE' ||
          q.contains('POST GRADUATE') ||
          q.contains('MASTER') ||
          q == 'MCA') {
        streams.addAll([
          'POST GRADUATE',
          'GRADUATE',
          '12TH / 10+2',
          '10TH',
          'MCA',
        ]);
      }
      if (q.contains('PH.D')) {
        streams.addAll([
          'PH.D / RESEARCH',
          'POST GRADUATE',
          'GRADUATE',
          '12TH / 10+2',
          '10TH',
        ]);
      }
      if (q == '12TH / 10+2' ||
          q == '12TH PCM' ||
          q == '12TH PCB' ||
          q.contains('12TH')) {
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
        streams.addAll([
          'TYPING',
          'TYPING (HINDI)',
          'TYPING (ENGLISH)',
          'CLERK',
        ]);
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

  static const _engineeringQuals = {
    'B.TECH / B.E',
    'B.TECH CS / IT',
    'B.TECH CIVIL',
    'B.TECH MECHANICAL',
    'B.TECH ELECTRICAL',
    'ENGINEERING',
  };

  static const _teachingQuals = {
    'B.ED',
    'D.EL.ED / BTC',
    'CTET',
    'CTET PAPER 1',
    'CTET PAPER 2',
    'STET',
    'STET / STATE TET',
    'TEACHER',
    'TEACHING',
  };

  static const _medicalQuals = {
    'MBBS',
    'MBBS / BDS',
    'B.SC NURSING',
    'NURSING (B.SC / GNM)',
    'B.PHARMA',
    'B.PHARM / D.PHARM',
    'D.PHARMA',
    'ANM',
    'GNM',
  };

  static const _lawQuals = {
    'LLB',
    'LAW',
  };

  /// Determines if a job post matches the candidate's qualifications
  static bool isJobEligible(JobPost job, Iterable<String> candidateQuals, {String? highestDegree}) {
    if (candidateQuals.isEmpty) return true;
    final eligibleStreams = getEligibleStreams(candidateQuals);

    final jobQuals = job.qualificationsFound
        .map((e) => e.toUpperCase().trim())
        .toSet();

    final combinedText = '${job.title} ${job.eligibilitySnippet} ${job.org}'.toUpperCase();
    final isGenericAnyGraduate = combinedText.contains('ANY STREAM') ||
        combinedText.contains('ANY GRADUATE') ||
        combinedText.contains('DEGREE IN ANY STREAM') ||
        combinedText.contains('BACHELOR DEGREE IN ANY STREAM') ||
        combinedText.contains('GRADUATION IN ANY STREAM') ||
        combinedText.contains('RRB NTPC') ||
        combinedText.contains('SSC CGL') ||
        combinedText.contains('BANK PO') ||
        combinedText.contains('PROBATIONARY OFFICER') ||
        combinedText.contains('CLERK');

    // 1. Specialized Engineering Protection:
    // If a job requires B.Tech/Engineering and is NOT an Any-Stream Graduate post,
    // candidates without Engineering cannot apply (e.g. B.Sc, BA, B.Com excluded).
    final isJobEngineering = jobQuals.any((q) => _engineeringQuals.contains(q)) ||
        (combinedText.contains('B.TECH') || combinedText.contains('B.E.') || combinedText.contains('ENGINEERING DEGREE'));
    if (isJobEngineering && !isGenericAnyGraduate) {
      final candidateHasEngineering = candidateQuals.any((q) {
        final upper = q.toUpperCase();
        return _engineeringQuals.any((eq) => upper.contains(eq)) || upper.contains('DIPLOMA');
      });
      if (!candidateHasEngineering) {
        return false;
      }
    }

    // 2. Specialized Teaching Protection:
    final isJobTeaching = jobQuals.any((q) => _teachingQuals.contains(q)) ||
        (combinedText.contains('TEACHER') || combinedText.contains('B.ED') || combinedText.contains('CTET'));
    if (isJobTeaching && !isGenericAnyGraduate) {
      final candidateHasTeaching = candidateQuals.any((q) {
        final upper = q.toUpperCase();
        return _teachingQuals.any((tq) => upper.contains(tq)) || upper.contains('TEACH');
      });
      if (!candidateHasTeaching) {
        return false;
      }
    }

    // 3. Specialized Medical Protection:
    final isJobMedical = jobQuals.any((q) => _medicalQuals.contains(q)) ||
        (combinedText.contains('MBBS') || combinedText.contains('MEDICAL OFFICER'));
    if (isJobMedical && !isGenericAnyGraduate) {
      final candidateHasMedical = candidateQuals.any((q) {
        final upper = q.toUpperCase();
        return _medicalQuals.any((mq) => upper.contains(mq)) || upper.contains('MEDIC');
      });
      if (!candidateHasMedical) {
        return false;
      }
    }

    // 4. Specialized Law Protection:
    final isJobLaw = jobQuals.any((q) => _lawQuals.contains(q)) || combinedText.contains('LLB');
    if (isJobLaw && !isGenericAnyGraduate) {
      final candidateHasLaw = candidateQuals.any((q) {
        final upper = q.toUpperCase();
        return upper.contains('LLB') || upper.contains('LAW');
      });
      if (!candidateHasLaw) {
        return false;
      }
    }

    if (jobQuals.isEmpty) return true;

    // Direct overlap with candidate's eligible streams
    for (final stream in eligibleStreams) {
      if (jobQuals.contains(stream)) return true;
    }

    // Semantic matching for stream-level eligibility
    if (eligibleStreams.contains('B.SC')) {
      if (combinedText.contains('B.SC') ||
          combinedText.contains('SCIENCE') ||
          isGenericAnyGraduate) {
        return true;
      }
    }

    if (eligibleStreams.contains('GRADUATE')) {
      if (isGenericAnyGraduate ||
          combinedText.contains('GRADUATE') ||
          combinedText.contains('DEGREE')) {
        return true;
      }
    }

    if (eligibleStreams.contains('10TH') && combinedText.contains('10TH')) {
      return true;
    }
    if (eligibleStreams.contains('12TH / 10+2') && combinedText.contains('12TH')) {
      return true;
    }
    if (eligibleStreams.contains('B.ED') && combinedText.contains('B.ED')) {
      return true;
    }
    if (eligibleStreams.contains('CTET') && combinedText.contains('CTET')) {
      return true;
    }
    if (eligibleStreams.contains('ITI') && combinedText.contains('ITI')) {
      return true;
    }

    return false;
  }

  /// Calculates a relevance score for ranking in "For You".
  /// Highest qualification exact matches score highest (100+ points).
  static int computeRelevanceScore(JobPost job, List<String> candidateQuals, String? highestDegree) {
    if (candidateQuals.isEmpty) return 0;
    final highest = (highestDegree != null && highestDegree.isNotEmpty)
        ? highestDegree.toUpperCase().trim()
        : candidateQuals.first.toUpperCase().trim();

    final jobQuals = job.qualificationsFound.map((e) => e.toUpperCase().trim()).toSet();
    final combinedText = '${job.title} ${job.eligibilitySnippet} ${job.org}'.toUpperCase();

    int score = 0;

    // 1. Direct match with candidate's HIGHEST educational qualification (Primary Tier: +120)
    if (highest == 'B.TECH / B.E') {
      if (jobQuals.any((q) => _engineeringQuals.contains(q)) ||
          combinedText.contains('B.TECH') ||
          combinedText.contains('B.E.') ||
          combinedText.contains('ENGINEER')) {
        score += 140;
      }
    } else if (highest == 'B.SC') {
      if (jobQuals.contains('B.SC') || combinedText.contains('B.SC') || combinedText.contains('SCIENCE')) {
        score += 140;
      }
    } else if (highest == 'POST GRADUATE' || highest == 'MCA') {
      if (jobQuals.contains('POST GRADUATE') ||
          jobQuals.contains('MCA') ||
          combinedText.contains('MASTER') ||
          combinedText.contains('POST GRADUATE')) {
        score += 140;
      }
    } else if (highest == 'DIPLOMA') {
      if (jobQuals.contains('DIPLOMA') || combinedText.contains('DIPLOMA') || combinedText.contains('POLYTECHNIC')) {
        score += 140;
      }
    } else if (highest == 'MBBS / BDS') {
      if (jobQuals.contains('MBBS') || combinedText.contains('MBBS') || combinedText.contains('MEDICAL')) {
        score += 140;
      }
    } else if (highest == 'LLB') {
      if (jobQuals.contains('LLB') || combinedText.contains('LAW') || combinedText.contains('LEGAL')) {
        score += 140;
      }
    } else if (highest == '12TH / 10+2' || highest == '12TH PCM' || highest == '12TH PCB') {
      if (jobQuals.contains('12TH / 10+2') || combinedText.contains('12TH') || combinedText.contains('INTERMEDIATE')) {
        score += 120;
      }
    } else if (highest == '10TH') {
      if (jobQuals.contains('10TH') || combinedText.contains('10TH') || combinedText.contains('MATRIC')) {
        score += 120;
      }
    } else if (highest == 'GRADUATE') {
      if (jobQuals.contains('GRADUATE') || combinedText.contains('GRADUATE')) {
        score += 100;
      }
    }

    // 2. Additional Certifications & Specializations (Secondary Tier: +60)
    for (final raw in candidateQuals) {
      final q = raw.toUpperCase().trim();
      if (q == highest) continue; // Already counted

      if (_teachingQuals.contains(q)) {
        if (jobQuals.any((jq) => _teachingQuals.contains(jq)) || combinedText.contains('TEACHER')) {
          score += 60;
        }
      }
      if (q.contains('TYPING')) {
        if (jobQuals.contains('TYPING') || combinedText.contains('TYPING') || combinedText.contains('WPM')) {
          score += 50;
        }
      }
      if (q.contains('STENO')) {
        if (jobQuals.contains('STENOGRAPHER') || combinedText.contains('STENO')) {
          score += 50;
        }
      }
      if (q == 'ITI') {
        if (jobQuals.contains('ITI') || combinedText.contains('ITI')) {
          score += 50;
        }
      }
      if (q.contains('GATE')) {
        if (combinedText.contains('GATE')) {
          score += 60;
        }
      }
    }

    // 3. General Graduate Baseline Eligibility (+35)
    final isGraduate = highest == 'B.TECH / B.E' ||
        highest == 'B.SC' ||
        highest == 'B.COM' ||
        highest == 'BA' ||
        highest == 'BCA' ||
        highest == 'BBA' ||
        highest == 'GRADUATE' ||
        highest == 'POST GRADUATE';

    if (score < 100 && isGraduate) {
      if (jobQuals.contains('GRADUATE') || combinedText.contains('GRADUATE') || combinedText.contains('DEGREE')) {
        score += 35;
      }
    }

    // 4. Secondary lower-tier eligibility (12th: +15, 10th: +5)
    if (score == 0) {
      if (jobQuals.contains('12TH / 10+2') || combinedText.contains('12TH')) {
        score += 15;
      } else if (jobQuals.contains('10TH') || combinedText.contains('10TH')) {
        score += 5;
      }
    }

    return score;
  }

  /// Sorts a list of jobs with highest qualification matches first.
  static List<JobPost> sortJobsByRelevance(List<JobPost> jobs, List<String> candidateQuals, String? highestDegree) {
    final scored = jobs.map((job) {
      final score = computeRelevanceScore(job, candidateQuals, highestDegree);
      return MapEntry(job, score);
    }).toList();

    scored.sort((a, b) {
      final cmp = b.value.compareTo(a.value);
      if (cmp != 0) return cmp;
      return b.key.id.compareTo(a.key.id);
    });

    return scored.map((e) => e.key).toList();
  }
}
