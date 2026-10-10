import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// TCP connect budget for chat / model-list traffic to LM Studio, Ollama,
/// Jan, oMLX, Unsloth and other servers.
///
/// Only bounds opening the socket. Model loading and slow replies are not
/// affected (those have their own idle timeouts). Without it, connecting to
/// a 192.168.x.x host over mobile data waits for the OS (~60–75 s).
const Duration kServerConnectTimeout = Duration(seconds: 8);

/// `http.Client` with a short TCP connect timeout.
http.Client createServerHttpClient({
  Duration connectTimeout = kServerConnectTimeout,
}) {
  if (kIsWeb) return http.Client();
  final inner = HttpClient()..connectionTimeout = connectTimeout;
  return IOClient(inner);
}
