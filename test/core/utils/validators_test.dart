import 'package:connect/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('campus email', () {
    for (final email in [
      'ali@root.edu',
      'ali@cs.root.edu',
      'ali.khan@students.root.edu',
      'ali+test@a.b.root.edu',
      'Ali@ROOT.EDU', // case-insensitive
      '  ali@root.edu  ', // trimmed
    ]) {
      test('accepts $email', () => expect(Validators.email(email), isNull));
    }

    for (final email in [
      'ali@gmail.com',
      'ali@root.edu.com', // root.edu must be the end, not the middle
      'ali@notroot.edu', // ends in "root.edu" textually, but another domain
      'ali@root.org',
    ]) {
      test('rejects $email', () {
        expect(
          Validators.email(email),
          'Use your campus email ending in root.edu',
        );
      });
    }

    test('malformed input gets the format message, not the domain one', () {
      expect(Validators.email('not-an-email'), 'Enter a valid email');
      expect(Validators.email('ali@rootedu'), 'Enter a valid email');
      expect(Validators.email(''), 'Email is required');
    });
  });
}
