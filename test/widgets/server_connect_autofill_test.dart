import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/widgets/server_connect_sheet.dart';

void main() {
  const def = 'http://localhost:11434';

  test('an untouched field takes the discovered server', () {
    expect(
      shouldAutofillDiscoveredUrl(
          userEdited: false, current: def, defaultUrl: def),
      isTrue,
    );
    expect(
      shouldAutofillDiscoveredUrl(
          userEdited: false, current: '  ', defaultUrl: def),
      isTrue,
    );
  });

  test('an address the user typed is never replaced by the scan', () {
    expect(
      shouldAutofillDiscoveredUrl(
        userEdited: true,
        current: 'http://100.79.192.75:11434',
        defaultUrl: def,
      ),
      isFalse,
    );
    // Even mid-typing, or after clearing the field to start over.
    expect(
      shouldAutofillDiscoveredUrl(
          userEdited: true, current: 'http://100.', defaultUrl: def),
      isFalse,
    );
    expect(
      shouldAutofillDiscoveredUrl(
          userEdited: true, current: '', defaultUrl: def),
      isFalse,
    );
  });

  test('a saved address being edited is kept', () {
    expect(
      shouldAutofillDiscoveredUrl(
        userEdited: false,
        current: 'http://100.79.192.75:11434',
        defaultUrl: def,
      ),
      isFalse,
    );
  });
}
