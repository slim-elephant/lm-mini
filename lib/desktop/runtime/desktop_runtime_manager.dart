import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../desktop_platform.dart';
import 'sidecar_port.dart';

/// Manages the desktop llama.cpp `llama-server` sidecar process.
///
/// Phone builds never call this.
///
/// **Mac:** ships inside the app bundle at `Contents/Resources/runtime/llama-server`.
/// **Windows:** ships next to the exe at `runtime/llama-server.exe` (Vulkan).
///
/// Discovery order:
/// 1. Explicit [configuredBinaryPath] (dev override)
/// 2. Bundled runtime (production)
/// 3. Application Support copy (optional update channel later)
/// 4. Homebrew / PATH — **debug builds only**
class DesktopRuntimeManager extends ChangeNotifier {
  DesktopRuntimeManager._();
  static final DesktopRuntimeManager instance = DesktopRuntimeManager._();

  static const int defaultPort = 8741;
  static const String defaultHost = '127.0.0.1';

  static const _trayChannel = MethodChannel('lm_mini/desktop_tray');

  Process? _process;
  String? _binaryPath;
  String? _loadedModelPath;
  String? _lastError;
  int _port = defaultPort;
  bool _starting = false;
  final StringBuffer _stderrBuf = StringBuffer();

  /// Optional user/override path to `llama-server` (dev only).
  String? configuredBinaryPath;

  /// Resolves the GGUF model path to load when a remote/USB phone asks for the
  /// builtin backend but the runtime isn't running yet. Set by
  /// [DesktopHostService]. Returns `null` when no GGUF model is available.
  Future<String?> Function()? builtinModelResolver;

  Future<bool>? _ensureBuiltinInFlight;

  bool get isRunning => _process != null;
  bool get isStarting => _starting;
  String? get binaryPath => _binaryPath;
  String? get loadedModelPath => _loadedModelPath;
  String? get lastError => _lastError;
  int get port => _port;
  String get baseUrl => 'http://$defaultHost:$_port';

  /// Whether a `llama-server` binary can be found for this build.
  Future<bool> get isBinaryAvailable async =>
      (await resolveBinaryPath()) != null;

  /// Path to the embedded runtime binary, if present.
  String? bundledBinaryPath() {
    try {
      final exeDir = File(Platform.resolvedExecutable).parent;
      if (Platform.isWindows) {
        return p.join(exeDir.path, 'runtime', 'llama-server.exe');
      }
      if (Platform.isMacOS) {
        // .../LM Mini.app/Contents/MacOS/<executable>
        return p.join(
            exeDir.parent.path, 'Resources', 'runtime', 'llama-server');
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<String?> resolveBinaryPath() async {
    if (!DesktopPlatform.supportsSidecarRuntime) return null;

    final configured = configuredBinaryPath?.trim();
    if (configured != null &&
        configured.isNotEmpty &&
        await File(configured).exists()) {
      return configured;
    }

    // 1) Shipped with the app (Mac bundle / Windows exe dir)
    final bundled = bundledBinaryPath();
    if (bundled != null && await File(bundled).exists()) {
      return bundled;
    }

    // 2) Application Support (future in-app runtime updates — optional)
    try {
      final support = await getApplicationSupportDirectory();
      final name = Platform.isWindows ? 'llama-server.exe' : 'llama-server';
      final local = File(p.join(support.path, 'runtime', name));
      if (await local.exists()) return local.path;
    } catch (_) {}

    // 3) Dev machines only — never required for store users
    if (kDebugMode) {
      if (Platform.isWindows) {
        try {
          final result = await Process.run('where', ['llama-server.exe']);
          if (result.exitCode == 0) {
            final path =
                (result.stdout as String).trim().split('\n').first.trim();
            if (path.isNotEmpty && await File(path).exists()) return path;
          }
        } catch (_) {}
      } else {
        const candidates = <String>[
          '/opt/homebrew/bin/llama-server',
          '/usr/local/bin/llama-server',
          '/opt/homebrew/opt/llama.cpp/bin/llama-server',
          '/usr/local/opt/llama.cpp/bin/llama-server',
        ];
        for (final path in candidates) {
          if (await File(path).exists()) return path;
        }
        try {
          final result = await Process.run('which', ['llama-server']);
          if (result.exitCode == 0) {
            final path = (result.stdout as String).trim().split('\n').first;
            if (path.isNotEmpty && await File(path).exists()) return path;
          }
        } catch (_) {}
      }
    }

    return null;
  }

  /// Start (or restart) the sidecar with [modelPath] loaded.
  Future<bool> ensureStarted({
    required String modelPath,
    int? port,
    int contextSize = 8192,
  }) async {
    if (!DesktopPlatform.supportsSidecarRuntime) {
      _lastError = 'Desktop runtime is only available on Mac/Windows.';
      notifyListeners();
      return false;
    }

    final modelFile = File(modelPath);
    if (!await modelFile.exists()) {
      _lastError = 'Model file not found: $modelPath';
      notifyListeners();
      return false;
    }

    if (isRunning && _loadedModelPath == modelPath && await _healthOk()) {
      return true;
    }

    await stop();

    final binary = await resolveBinaryPath();
    if (binary == null) {
      _lastError = Platform.isWindows
          ? 'Desktop runtime is missing from this app build. '
              'Reinstall LM Mini Home.'
          : 'Desktop runtime is missing from this app build. '
              'Update LM Mini from the Mac App Store, or reinstall the app.';
      notifyListeners();
      return false;
    }

    // Ensure execute bit (sometimes lost when copying resources).
    if (!Platform.isWindows) {
      try {
        await Process.run('chmod', ['+x', binary]);
      } catch (_) {}
    }

    _starting = true;
    _lastError = null;
    _port = port ?? defaultPort;
    _binaryPath = binary;
    notifyListeners();

    try {
      final args = <String>[
        '--host',
        defaultHost,
        '--port',
        '$_port',
        '-m',
        modelPath,
        '-c',
        '$contextSize',
        '-ngl',
        '99',
        '--parallel',
        '1',
        // Hybrid Qwen 3.x templates: per-request enable_thinking / budget.
        '--reasoning',
        'auto',
      ];
      final mmproj = _siblingMmproj(modelPath);
      if (mmproj != null) {
        args.addAll(['--mmproj', mmproj]);
      }

      debugPrint('🖥️ DesktopRuntime: starting $binary ${args.join(' ')}');
      final binDir = File(binary).parent.path;
      _stderrBuf.clear();
      _process = await Process.start(
        binary,
        args,
        runInShell: false,
        workingDirectory: binDir,
        mode: ProcessStartMode.normal,
      );
      _loadedModelPath = modelPath;
      await _rememberPid(_process!.pid);
      await _notifyNativeSidecarPid(_process!.pid);

      void onLog(String prefix, String data) {
        final text = data.trim();
        if (text.isEmpty) return;
        debugPrint('$prefix $text');
      }

      _process!.stdout.transform(utf8.decoder).listen((data) {
        onLog('llama-server:', data);
      });
      _process!.stderr.transform(utf8.decoder).listen((data) {
        onLog('llama-server err:', data);
        if (_stderrBuf.length < 4000) _stderrBuf.write(data);
      });
      unawaited(_process!.exitCode.then((code) async {
        debugPrint('🖥️ DesktopRuntime: llama-server exited ($code)');
        if (_process != null) {
          _process = null;
          _loadedModelPath = null;
          if (code != 0 && _lastError == null) {
            _lastError = _formatExitError(code);
          }
          notifyListeners();
        }
        await _notifyNativeSidecarPid(0);
      }));

      final ready = await _waitForHealth(timeout: const Duration(seconds: 45));
      if (!ready) {
        // Let stderr drain into the buffer before composing the UI error.
        await Future<void>.delayed(const Duration(milliseconds: 80));
        _lastError ??= _formatExitError(null) ??
            'Desktop runtime failed to start. Please try again.';
        await stop();
        return false;
      }
      return true;
    } catch (e) {
      _lastError = 'Could not start desktop runtime.';
      debugPrint('🖥️ DesktopRuntime start error: $e');
      await stop();
      return false;
    } finally {
      _starting = false;
      notifyListeners();
    }
  }

  /// Ensure the builtin sidecar is running so a phone's builtin-backend request
  /// can be proxied. Starts the runtime with the model from
  /// [builtinModelResolver] when idle. De-duplicates concurrent callers so a
  /// burst of relay requests doesn't spawn multiple `llama-server` starts.
  ///
  /// Returns `false` (with [lastError] set) when no GGUF model is available or
  /// the runtime could not start — the proxy turns this into a clear 503.
  Future<bool> ensureBuiltinRunning({
    int contextSize = 8192,
  }) async {
    if (!DesktopPlatform.supportsSidecarRuntime) return false;
    if (isRunning && await _healthOk()) return true;

    // Coalesce concurrent starts (relay delivers requests in parallel).
    final inFlight = _ensureBuiltinInFlight;
    if (inFlight != null) return inFlight;

    final future = () async {
      final resolver = builtinModelResolver;
      if (resolver == null) {
        _lastError =
            'No on-device model is selected on ${DesktopPlatform.thisMachine}. '
            'Open LM Mini Home and pick a model to share.';
        notifyListeners();
        return false;
      }
      final modelPath = await resolver();
      if (modelPath == null || modelPath.isEmpty) {
        _lastError = 'No downloaded GGUF model to share. '
            'Download an on-device model in LM Mini Home first.';
        notifyListeners();
        return false;
      }
      return ensureStarted(modelPath: modelPath, contextSize: contextSize);
    }();

    _ensureBuiltinInFlight = future;
    try {
      return await future;
    } finally {
      _ensureBuiltinInFlight = null;
    }
  }

  /// Kill leftover `llama-server` on [defaultPort] from a previous app
  /// session (Cmd-Q / crash often reparents the child to launchd).
  ///
  /// Does not touch other ports (LM Studio, a user's own llama.cpp, etc.).
  Future<void> reapStaleSidecar({int? exceptPid}) async {
    if (!DesktopPlatform.supportsSidecarRuntime) return;
    final skip = exceptPid ?? _process?.pid;
    final listening = await _pidsListeningOnPort(_port);
    final pids = <int>{...listening};
    final stored = await _readStoredPid();
    if (stored != null &&
        stored != skip &&
        await _shouldReapPid(stored, listening)) {
      pids.add(stored);
    }
    for (final pid in pids) {
      if (skip != null && pid == skip) continue;
      debugPrint(
          '🖥️ DesktopRuntime: reaping stale sidecar pid=$pid on :$_port');
      Process.killPid(pid, ProcessSignal.sigterm);
    }
    if (pids.isEmpty) {
      if (skip == null) await _clearPidFile();
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 400));
    for (final pid in pids) {
      if (skip != null && pid == skip) continue;
      Process.killPid(pid, ProcessSignal.sigkill);
    }
    if (skip == null) await _clearPidFile();
  }

  Future<bool> _shouldReapPid(int pid, Set<int> listening) async {
    if (listening.contains(pid)) return true;
    final comm = await _pidCommandName(pid);
    if (comm == null) return true;
    return comm.contains('llama-server');
  }

  Future<String?> _pidCommandName(int pid) async {
    if (pid <= 1) return null;
    try {
      if (Platform.isWindows) {
        final result = await Process.run('tasklist', [
          '/FI',
          'PID eq $pid',
          '/FO',
          'CSV',
          '/NH',
        ]);
        final out = (result.stdout as String).trim().toLowerCase();
        if (out.isEmpty || out.contains('no tasks')) return null;
        return out;
      }
      final result = await Process.run('ps', ['-p', '$pid', '-o', 'comm=']);
      if (result.exitCode != 0) return null;
      final name = (result.stdout as String).trim().toLowerCase();
      return name.isEmpty ? null : name;
    } catch (_) {
      return null;
    }
  }

  Future<void> _notifyNativeSidecarPid(int pid) async {
    try {
      await _trayChannel.invokeMethod('setSidecarPid', {'pid': pid});
    } catch (_) {}
  }

  Future<File> _pidFile() async {
    final support = await getApplicationSupportDirectory();
    return File(p.join(support.path, 'llama-server.pid'));
  }

  Future<void> _rememberPid(int pid) async {
    try {
      await (await _pidFile()).writeAsString('$pid');
    } catch (e) {
      debugPrint('🖥️ DesktopRuntime: could not write pid file: $e');
    }
  }

  Future<int?> _readStoredPid() async {
    try {
      final f = await _pidFile();
      if (!await f.exists()) return null;
      return int.tryParse((await f.readAsString()).trim());
    } catch (_) {
      return null;
    }
  }

  Future<void> _clearPidFile() async {
    try {
      final f = await _pidFile();
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  Future<Set<int>> _pidsListeningOnPort(int port) async {
    try {
      if (Platform.isWindows) {
        final result = await Process.run('netstat', ['-ano', '-p', 'TCP']);
        if (result.exitCode != 0) return {};
        return SidecarPort.parseNetstatListeningPids(
          result.stdout as String,
          port,
        );
      }
      final result = await Process.run('lsof', [
        '-nP',
        '-iTCP:$port',
        '-sTCP:LISTEN',
        '-t',
      ]);
      if (result.exitCode != 0 && result.exitCode != 1) return {};
      return SidecarPort.parseLsofPids(result.stdout as String);
    } catch (e) {
      debugPrint('🖥️ DesktopRuntime: port scan failed: $e');
      return {};
    }
  }

  Future<void> stop() async {
    final proc = _process;
    _process = null;
    _loadedModelPath = null;
    if (proc != null) {
      proc.kill(ProcessSignal.sigterm);
      try {
        await proc.exitCode.timeout(const Duration(seconds: 3));
      } catch (_) {
        proc.kill(ProcessSignal.sigkill);
      }
    }
    await _notifyNativeSidecarPid(0);
    await reapStaleSidecar();
    notifyListeners();
  }

  Future<bool> _waitForHealth({required Duration timeout}) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (_process == null) return false;
      if (await _healthOk()) return true;
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }
    return false;
  }

  String? _siblingMmproj(String modelPath) {
    final dir = File(modelPath).parent;
    try {
      final matches = dir.listSync().whereType<File>().where((f) {
        final name = f.path.split(Platform.pathSeparator).last.toLowerCase();
        return name.contains('mmproj') && name.endsWith('.gguf');
      }).toList();
      if (matches.isEmpty) return null;
      return matches.first.path;
    } catch (_) {
      return null;
    }
  }

  String? _formatExitError(int? code) {
    final detail = _stderrBuf.toString().trim();
    if (detail.isEmpty) {
      return code == null
          ? null
          : 'Desktop runtime exited unexpectedly (code $code).';
    }
    final lines = detail
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .where((l) {
      final lower = l.toLowerCase();
      if (lower.startsWith('warning:')) return false;
      if (lower.contains('ggml_print_backtrace')) return false;
      if (RegExp(r'^\d+\s+\S+\s+0x').hasMatch(l)) return false;
      return true;
    }).toList();
    final errors = lines.where((l) {
      final lower = l.toLowerCase();
      return lower.contains('failed') ||
          lower.contains('no backends') ||
          lower.contains('filesystem error') ||
          lower.contains('terminating') ||
          lower.contains('error') ||
          RegExp(r'\sE\s').hasMatch(l);
    }).toList();
    final compact = (errors.isNotEmpty ? errors : lines).take(3).join(' ');
    final clipped =
        compact.length > 280 ? '${compact.substring(0, 277)}…' : compact;
    return code == null ? clipped : '$clipped (code $code)';
  }

  Future<bool> _healthOk() async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 2);
      final req = await client.getUrl(Uri.parse('$baseUrl/health'));
      final res = await req.close().timeout(const Duration(seconds: 2));
      await res.drain<void>();
      client.close(force: true);
      return res.statusCode == 200;
    } catch (_) {
      try {
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 2);
        final req = await client.getUrl(Uri.parse('$baseUrl/v1/models'));
        final res = await req.close().timeout(const Duration(seconds: 2));
        await res.drain<void>();
        client.close(force: true);
        return res.statusCode == 200;
      } catch (_) {
        return false;
      }
    }
  }
}
