/// LM Studio's public REST docs only list start + status for Hugging Face
/// downloads. Cancel exists internally (`cancelDownloadJob`); try the REST
/// shapes that match load/unload until LMS documents one.
class LmStudioDownloadCancelAttempt {
  final String method;
  final String path;
  final Map<String, dynamic>? body;

  const LmStudioDownloadCancelAttempt({
    required this.method,
    required this.path,
    this.body,
  });
}

List<LmStudioDownloadCancelAttempt> lmStudioDownloadCancelAttempts(
    String jobId) {
  final id = jobId.trim();
  return [
    LmStudioDownloadCancelAttempt(
      method: 'POST',
      path: '/api/v1/models/download/cancel',
      body: {'job_id': id, 'jobIdentifier': id},
    ),
    LmStudioDownloadCancelAttempt(
      method: 'DELETE',
      path: '/api/v1/models/download/status/$id',
    ),
    LmStudioDownloadCancelAttempt(
      method: 'POST',
      path: '/api/v1/models/download/status/$id/cancel',
    ),
    LmStudioDownloadCancelAttempt(
      method: 'POST',
      path: '/api/v1/models/download/$id/cancel',
    ),
  ];
}

bool lmStudioCancelHttpAccepted(int statusCode) =>
    statusCode == 200 || statusCode == 202 || statusCode == 204;

bool lmStudioCancelHttpTryNext(int statusCode) =>
    statusCode == 400 ||
    statusCode == 404 ||
    statusCode == 405 ||
    statusCode == 501;

bool lmStudioDownloadStatusIsTerminal(String? status) {
  switch ((status ?? '').toLowerCase()) {
    case 'completed':
    case 'failed':
    case 'cancelled':
    case 'canceled':
      return true;
    default:
      return false;
  }
}
