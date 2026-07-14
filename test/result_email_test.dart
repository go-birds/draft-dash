import 'package:draft_race/domain/draft/participant.dart';
import 'package:draft_race/services/result_email.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'mail draft de-duplicates recipients in BCC and keeps recap in body',
    () {
      const participants = [
        Participant(
          id: 'p1',
          name: 'Nick',
          initials: 'NC',
          email: ' nick@example.com ',
          colorValue: 0xFF000000,
        ),
        Participant(
          id: 'p2',
          name: 'Jordan',
          initials: 'JR',
          email: 'NICK@example.com',
          colorValue: 0xFF000000,
        ),
        Participant(
          id: 'p3',
          name: 'Taylor',
          initials: 'TS',
          email: 'taylor@example.com',
          colorValue: 0xFF000000,
        ),
      ];

      final uri = ResultEmail.composeUri(
        participants: participants,
        subject: 'Sunday League results',
        body: 'Proof code: DD-ABC-1234\n1. Nick',
      );

      expect(uri.scheme, 'mailto');
      expect(uri.path, isEmpty);
      expect(uri.queryParameters['bcc'], 'nick@example.com,taylor@example.com');
      expect(uri.queryParameters['subject'], 'Sunday League results');
      expect(uri.queryParameters['body'], contains('DD-ABC-1234'));
    },
  );
}
