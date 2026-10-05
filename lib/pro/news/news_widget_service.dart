// LM-MINI-PRO-STUB
/// Public-build stub: the News widget (AI briefing) is part of LM Mini Pro.
///
/// Background refreshes do nothing and explicit refreshes fail with a short
/// explanation, so the open-source build never generates briefings.
class NewsWidgetService {
  NewsWidgetService._();
  static final NewsWidgetService instance = NewsWidgetService._();

  /// Never refreshes in the open-source build.
  Future<bool> refreshIfPossible({bool force = false}) async => false;

  /// Always throws: the News widget is not part of the open-source build.
  Future<void> refreshNow(String prompt) async => throw StateError(
      'The News widget is available in the official LM Mini app.');
}
