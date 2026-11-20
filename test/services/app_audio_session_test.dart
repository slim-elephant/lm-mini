import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/services/app_audio_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('net.neuro9.lmmini/audio_session');
  final calls = <String>[];
  final session = AppAudioSession.instance;

  setUp(() async {
    calls.clear();
    AppAudioSession.debugIsIos = true;
    session.isMicActive = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      return true;
    });
    await session.leaveVoiceMode();
    calls.clear();
  });

  tearDown(() {
    AppAudioSession.debugIsIos = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('read aloud outside a voice chat uses listening mode', () async {
    await session.prepareForPlayback();
    expect(calls, ['configureForPlayback']);
  });

  test('read aloud never switches to listening while the mic is capturing',
      () async {
    session.isMicActive = () => true;
    await session.prepareForPlayback();
    expect(calls, isEmpty);
  });

  test('a voice chat keeps one setup: replies re-assert, never flip', () async {
    await session.enterVoiceMode(callMode: false);
    expect(session.inVoiceMode, isTrue);
    await session.prepareForRecording();
    await session.prepareForPlayback();
    await session.prepareForRecording();
    await session.prepareForPlayback();
    expect(calls, [
      'configureForDictation',
      'activateForRecording',
      'reassert',
      'activateForRecording',
      'reassert',
    ]);
    expect(calls, isNot(contains('configureForPlayback')));
    expect(calls, isNot(contains('deactivate')));
  });

  test('call mode asks for the echo-cancelling setup', () async {
    await session.enterVoiceMode(callMode: true);
    expect(calls, ['configureForVoiceChat']);
  });

  test('leaving the voice chat hands back and read aloud is listening again',
      () async {
    await session.enterVoiceMode(callMode: false);
    await session.leaveVoiceMode();
    expect(session.inVoiceMode, isFalse);
    await session.prepareForPlayback();
    expect(
        calls, ['configureForDictation', 'deactivate', 'configureForPlayback']);
  });

  test('a native failure is reported as false, not thrown', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'AUDIO_SESSION_ERROR');
    });
    expect(await session.enterVoiceMode(callMode: false), isFalse);
    await session.prepareForPlayback(); // must not throw
  });

  test('does nothing off iPhone', () async {
    AppAudioSession.debugIsIos = false;
    expect(await session.enterVoiceMode(callMode: false), isTrue);
    await session.prepareForPlayback();
    await session.leaveVoiceMode();
    expect(calls, isEmpty);
  });
}
