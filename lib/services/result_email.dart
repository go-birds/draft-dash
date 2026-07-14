import '../domain/draft/participant.dart';

/// Builds a mail draft for result delivery without sending anything itself.
class ResultEmail {
  const ResultEmail._();

  static List<String> recipients(Iterable<Participant> participants) {
    final seen = <String>{};
    return [
      for (final participant in participants)
        if (_cleanEmail(participant.email) case final email?)
          if (seen.add(email.toLowerCase())) email,
    ];
  }

  static Uri composeUri({
    required Iterable<Participant> participants,
    required String subject,
    required String body,
  }) {
    final emails = recipients(participants);
    if (emails.isEmpty) {
      throw ArgumentError('At least one manager email is required');
    }
    // BCC prevents managers from exposing one another's addresses if the
    // commissioner chooses to send the draft.
    return Uri(
      scheme: 'mailto',
      queryParameters: {
        'bcc': emails.join(','),
        'subject': subject,
        'body': body,
      },
    );
  }

  static String? _cleanEmail(String? value) {
    final email = value?.trim();
    if (email == null || email.isEmpty || !email.contains('@')) return null;
    return email;
  }
}
