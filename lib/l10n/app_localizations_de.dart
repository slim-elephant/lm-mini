// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'LM Mini';

  @override
  String get splashTagline => 'lokaler KI-Chat';

  @override
  String get homeTitle => 'LM Mini';

  @override
  String get homeSearchHint => 'Unterhaltungen suchen...';

  @override
  String get allConversations => 'Alle Unterhaltungen';

  @override
  String get noFoldersTitle => 'Keine Ordner';

  @override
  String get noFoldersSubtitle =>
      'Erstelle Ordner, um deine Chats zu organisieren';

  @override
  String get noConversationsTitle => 'Keine Unterhaltungen';

  @override
  String get noConversationsSubtitle =>
      'Starte einen neuen Chat, um loszulegen';

  @override
  String get newChat => 'Neuer Chat';

  @override
  String conversationCount(int count) {
    return '$count Unterhaltung(en)';
  }

  @override
  String get noModelsAvailable =>
      'Keine Modelle verfügbar. Überprüfe deine Verbindung zu LM Studio.';

  @override
  String get noVisionModelAvailable =>
      'Kein Vision-Modell verfügbar. Lade ein Vision-Modell in LM Studio.';

  @override
  String get deleteConversationTitle => 'Unterhaltung löschen';

  @override
  String get deleteConversationMessage =>
      'Bist du sicher, dass du diese Unterhaltung löschen möchtest? Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get renameConversationTitle => 'Unterhaltung umbenennen';

  @override
  String get conversationTitleLabel => 'Unterhaltungstitel';

  @override
  String get deleteFolderTitle => 'Ordner löschen';

  @override
  String get deleteFolderMessage =>
      'Die Unterhaltungen in diesem Ordner werden nicht gelöscht.';

  @override
  String get moveToFolderTitle => 'In Ordner verschieben';

  @override
  String get noFolder => 'Kein Ordner';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get delete => 'Löschen';

  @override
  String get save => 'Speichern';

  @override
  String get close => 'Schließen';

  @override
  String get ok => 'OK';

  @override
  String get add => 'Hinzufügen';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get reset => 'Zurücksetzen';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get search => 'Suchen';

  @override
  String get copy => 'Kopieren';

  @override
  String get copied => 'Kopiert!';

  @override
  String get copiedToClipboard => 'In Zwischenablage kopiert';

  @override
  String get dismiss => 'Schließen';

  @override
  String get configure => 'Konfigurieren';

  @override
  String get rename => 'Umbenennen';

  @override
  String get duplicate => 'Duplizieren';

  @override
  String get enabled => 'Aktiviert';

  @override
  String get disabled => 'Deaktiviert';

  @override
  String get active => 'Aktiv';

  @override
  String get none => 'Keine';

  @override
  String get auto => 'Automatisch';

  @override
  String get custom => 'Benutzerdefiniert';

  @override
  String get change => 'Ändern';

  @override
  String get chatDefaultTitle => 'Chat';

  @override
  String get searchMessagesTooltip => 'Nachrichten suchen';

  @override
  String get chatSettingsMenuItem => 'Chat-Einstellungen';

  @override
  String get appearanceMenuItem => 'Darstellung';

  @override
  String get exportAsPdf => 'Als PDF exportieren';

  @override
  String get exportAsTxt => 'Als TXT exportieren';

  @override
  String get exportAsMarkdown => 'Als Markdown exportieren';

  @override
  String get exportAsJson => 'Als JSON exportieren';

  @override
  String get exportAsObsidian => 'Für Obsidian exportieren';

  @override
  String get copyToClipboard => 'In Zwischenablage kopieren';

  @override
  String get exportAndShare => 'Exportieren & Teilen';

  @override
  String get freeFormats => 'Standard';

  @override
  String get premiumFormats => 'Pro-Formate';

  @override
  String get chatExported => 'Chat exportiert';

  @override
  String get noModelSelectedTitle => 'Kein Modell ausgewählt';

  @override
  String get noModelSelectedSubtitle =>
      'Wähle ein Modell in den Einstellungen, um zu chatten';

  @override
  String get openSettings => 'Einstellungen öffnen';

  @override
  String connectionError(String error) {
    return 'Verbindungsfehler: $error';
  }

  @override
  String get startConversation => 'Starte eine Unterhaltung';

  @override
  String get typeMessageToBegin => 'Schreibe eine Nachricht, um zu beginnen';

  @override
  String get searchMessagesTitle => 'Nachrichten suchen';

  @override
  String get searchQueryHint => 'Suchbegriff eingeben...';

  @override
  String get semanticSearchInfo =>
      'Die semantische Suche verwendet KI, um relevante Nachrichten basierend auf der Bedeutung zu finden, nicht nur nach Schlüsselwörtern.';

  @override
  String get noMessagesToSearch => 'Keine Nachrichten zum Suchen';

  @override
  String get searchResults => 'Suchergebnisse';

  @override
  String searchResultsFor(int count, String query) {
    return '$count Treffer für \"$query\"';
  }

  @override
  String get noMessagesFound => 'Keine Nachrichten gefunden';

  @override
  String get tryDifferentSearch => 'Versuche eine andere Suche';

  @override
  String get chatCustomizationSaved => 'Chat-Anpassung gespeichert';

  @override
  String get noMessagesToExport => 'Keine Nachrichten zum Exportieren';

  @override
  String get exportingChat => 'Chat wird exportiert...';

  @override
  String get chatExportedAsPdf => 'Chat als PDF exportiert';

  @override
  String get chatExportedAsTxt => 'Chat als TXT exportiert';

  @override
  String exportFailed(String error) {
    return 'Export fehlgeschlagen: $error';
  }

  @override
  String get chatSettingsUpdated =>
      'Chat-Einstellungen aktualisiert (globale Einstellungen überschrieben)';

  @override
  String get chatSettingsReset =>
      'Chat-Einstellungen auf globale Werte zurückgesetzt';

  @override
  String get you => 'Du';

  @override
  String get assistant => 'Assistent';

  @override
  String get yesterday => 'Gestern';

  @override
  String get showDetails => 'Details anzeigen';

  @override
  String get hideDetails => 'Details ausblenden';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsAdvancedMode => 'Erweitert';

  @override
  String get settingsAdvancedModeTooltip =>
      'Technische Optionen für Power-User anzeigen';

  @override
  String get serverSection => 'SERVER';

  @override
  String get serverUrlLabel => 'Server-URL';

  @override
  String get serverUrlHint => 'http://localhost:1234';

  @override
  String get testConnectionRequired => 'Verbindung testen (Erforderlich)';

  @override
  String get testConnection => 'Verbindung testen';

  @override
  String get modelsSection => 'MODELLE';

  @override
  String get modelSelection => 'Modellauswahl';

  @override
  String get noModelSelected => 'Kein Modell ausgewählt';

  @override
  String get modelParameters => 'Modellparameter';

  @override
  String get modelParametersSubtitle => 'Temperatur, Tokens, Bestrafungen';

  @override
  String get modelParametersHelpTooltip => 'Bedeutung dieser Einstellungen';

  @override
  String get modelParametersHelpTitle => 'Kurzanleitung';

  @override
  String get modelParametersHelpIntro =>
      'Einfache Tipps zu jeder Einstellung. Bei Unsicherheit die Standardwerte lassen — Sie können sie später ändern. Manche Optionen erscheinen nur beim aktuellen KI-Anbieter.';

  @override
  String get topKHelp =>
      'Wie viele Wortvorschläge die KI prüft. Niedriger = sicherer und vorhersehbarer; 0 = kein Limit.';

  @override
  String get reasoningHelp =>
      'Schaltet den Thinking-Modus für Reasoning-Modelle ein oder aus. Aus = schnellere Antworten ohne Thinking-Spur; An (oder ein Level) lässt das Modell Schritt für Schritt denken. Nicht alle Reasoning-Modelle unterstützen das Ausschalten.';

  @override
  String get reasoningHelpShort =>
      'Schaltet Thinking ein/aus. Nicht alle Modelle unterstützen Aus.';

  @override
  String get systemPrompts => 'Personas und System-Prompts';

  @override
  String get defaultPrompt => 'Standard-Prompt';

  @override
  String get appearanceSection => 'DARSTELLUNG';

  @override
  String get appearance => 'Darstellung';

  @override
  String get appearanceSubtitle => 'Thema, Hintergründe, Avatare';

  @override
  String get supportSection => 'UNTERSTÜTZUNG';

  @override
  String get rateApp => 'LM Mini bewerten';

  @override
  String get rateAppSubtitle =>
      'Gefällt dir die App? Hinterlasse eine Bewertung im App Store ⭐';

  @override
  String get hfBrowseTitle => 'Von Hugging Face herunterladen';

  @override
  String get hfBrowseSubtitle =>
      'GGUF-Modelle durchsuchen — kein API-Schlüssel nötig';

  @override
  String get hfBrowseTab => 'Durchsuchen';

  @override
  String get hfPasteTab => 'Link einfügen';

  @override
  String get hfSearchHint => 'GGUF-Modelle suchen…';

  @override
  String get hfLoadingModels => 'Hugging Face wird durchsucht…';

  @override
  String get hfNoModelsFound => 'Keine Modelle gefunden';

  @override
  String get hfNoModelsHint =>
      'Anderen Suchbegriff versuchen oder den LM-Studio-Filter ausschalten.';

  @override
  String get hfLmStudioFilter => 'LM Studio-kompatibel';

  @override
  String get hfLmStudioFilterHint =>
      'Nur Modelle, die Hugging Face als mit LM Studio kompatibel listet';

  @override
  String get hfChatModelsFilter => 'Chat-Modelle';

  @override
  String get hfChatBadge => 'Chat';

  @override
  String get hfLmStudioBadge => 'LM Studio';

  @override
  String get hfPasteUrlHint => 'https://huggingface.co/owner/repo';

  @override
  String get hfModelInfo => 'Modellinfo';

  @override
  String hfDownloadsCount(String count) {
    return '$count Downloads';
  }

  @override
  String hfLikesCount(String count) {
    return '$count Likes';
  }

  @override
  String hfPipelineTag(String tag) {
    return 'Aufgabe: $tag';
  }

  @override
  String hfBaseModel(String model) {
    return 'Basismodell: $model';
  }

  @override
  String hfLicense(String license) {
    return 'Lizenz: $license';
  }

  @override
  String get hfTagsSection => 'Stichwörter';

  @override
  String get hfQuantPickerHint =>
      'Niedrigere Quant = kleinere Datei. Q4_K_M ist ein guter Kompromiss für die meisten Geräte.';

  @override
  String get hfBackToModels => 'Zurück zu den Modellen';

  @override
  String hfGgufFilesCount(int count) {
    return '$count GGUF-Datei(en) verfügbar';
  }

  @override
  String get hfDownloadInBackground =>
      'Download gestartet — Fortschritt über den schwebenden Button verfolgen. Du kannst weiter browsen oder dieses Panel schließen.';

  @override
  String get hfQuantPickerHintLmStudio =>
      'Quantisierungen laut deinem LM-Studio-Server. Eine auswählen, um sie auf den Server zu laden.';

  @override
  String get hfDownloadDefaultQuant => 'Herunterladen';

  @override
  String hfDownloadFailed(String error) {
    return 'Download konnte nicht gestartet werden: $error';
  }

  @override
  String get hfPasteInstructions =>
      'Hugging-Face-Repo-URL einfügen oder owner/repo eingeben. Als Nächstes wählst du eine Quantisierung.';

  @override
  String get hfPasteInstructionsLmStudio =>
      'Hugging-Face-URL, owner/repo oder eine LM-Studio-Modell-ID einfügen.';

  @override
  String get hfPasteLabel => 'Repository';

  @override
  String get hfInvalidRepo =>
      'Gültige Hugging-Face-URL oder owner/repo eingeben.';

  @override
  String get hfRecommended => 'Empfohlen';

  @override
  String get reviewPromptTitle => 'Gefällt dir LM Mini?';

  @override
  String get reviewPromptMessage =>
      'Du hattest ein paar tolle Chats! Würdest du uns kurz im Play Store bewerten?';

  @override
  String get reviewPromptRate => 'Jetzt bewerten';

  @override
  String get reviewPromptLater => 'Vielleicht später';

  @override
  String get buyMeACoffee => 'Kauf mir einen Kaffee';

  @override
  String get buyMeACoffeeSubtitle => 'Hilf der KI, koffeiniert zu bleiben! 🤖';

  @override
  String get featureRequests => 'Feature-Anfragen';

  @override
  String get featureRequestsSubtitle =>
      'Stimme für Features ab oder reiche deine Ideen ein';

  @override
  String get dataSection => 'DATEN';

  @override
  String get exportAllChats => 'Alle Chats exportieren';

  @override
  String get exportAllChatsSubtitle =>
      'Alle Unterhaltungen als ZIP-Datei herunterladen';

  @override
  String get importChats => 'Chats importieren';

  @override
  String get importChatsSubtitle =>
      'LM Studio Chat-Exporte importieren (.md oder .zip)';

  @override
  String importSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Chats erfolgreich importiert',
      one: '1 Chat erfolgreich importiert',
    );
    return '$_temp0';
  }

  @override
  String get importFailed => 'Import fehlgeschlagen';

  @override
  String importPartial(int imported, int skipped) {
    return '$imported importiert, $skipped übersprungen';
  }

  @override
  String get importing => 'Importiere...';

  @override
  String get advancedSection => 'ERWEITERTE FUNKTIONEN';

  @override
  String get showRuntimeInfo => 'Laufzeitinfo anzeigen';

  @override
  String get showRuntimeInfoSubtitle =>
      'Modellarchitektur und Ausführungszeit anzeigen';

  @override
  String get embeddingModel => 'Embedding-Modell';

  @override
  String get enableSemanticSearch => 'Semantische Suche aktivieren';

  @override
  String get enableSemanticSearchSubtitle =>
      'Relevante Nachrichten mit Embeddings suchen';

  @override
  String get toolCalling => 'Tool-Aufrufe';

  @override
  String get toolCallingEnabled => 'Tool-Aufrufe aktiviert';

  @override
  String get toolCallingDisabled => 'Tool-Aufrufe deaktiviert';

  @override
  String get legalSection => 'RECHTLICHES';

  @override
  String get privacyPolicy => 'Datenschutzrichtlinie';

  @override
  String get privacyPolicySubtitle =>
      'Unterhaltungen bleiben auf deinen Geräten';

  @override
  String get termsOfService => 'Nutzungsbedingungen';

  @override
  String get termsOfServiceSubtitle => 'Allgemeine Geschäftsbedingungen';

  @override
  String get appName => 'LM Mini';

  @override
  String get appTagline => 'Eine Begleit-App für LM Studio';

  @override
  String get couldNotOpenLink => 'Link konnte nicht geöffnet werden';

  @override
  String get apiToken => 'API-Token und USB';

  @override
  String get tokenConfigured => 'Token konfiguriert';

  @override
  String get optionalAuthentication => 'Optionale Authentifizierung';

  @override
  String get apiTokenLabel => 'API-Token';

  @override
  String get apiTokenHint => 'Gib deinen LM Studio API-Token ein';

  @override
  String get apiTokenHelp =>
      'Wenn dein LM Studio-Server Authentifizierung erfordert, gib deinen API-Token hier ein. Er ist optional und wird nur benötigt, wenn du die Authentifizierung in den LM Studio-Einstellungen aktiviert hast.';

  @override
  String get apiTokenInfo =>
      'LM Studio 0.4.0+ unterstützt API-Authentifizierung. Aktiviere sie unter LM Studio > Einstellungen > Sicherheit.';

  @override
  String get actionRequired => '- Aktion erforderlich';

  @override
  String get idleTtl => 'Leerlauf-TTL';

  @override
  String get idleTtlDefault => 'Verwendet LM Studio-Standard (60 Min)';

  @override
  String idleTtlMinutes(int value) {
    return 'Automatisches Entladen nach $value Min. Leerlauf';
  }

  @override
  String idleTtlHoursMinutes(int hours, int mins) {
    return 'Automatisches Entladen nach $hours Std. $mins Min. Leerlauf';
  }

  @override
  String get lmStudioDefault => 'LM Studio Standard';

  @override
  String get fiveMinutes => '5 Minuten';

  @override
  String get fifteenMinutes => '15 Minuten';

  @override
  String get thirtyMinutes => '30 Minuten';

  @override
  String get oneHour => '1 Stunde';

  @override
  String get twoHours => '2 Stunden';

  @override
  String connectionSuccess(int count) {
    return 'Verbunden! $count Modelle geladen';
  }

  @override
  String get connectionFailed => 'Verbindung fehlgeschlagen';

  @override
  String get troubleshootingSteps => 'Fehlerbehebung:';

  @override
  String get troubleshootStep1 => 'Stelle sicher, dass LM Studio läuft';

  @override
  String get troubleshootStep2 =>
      'Öffne in LM Studio den Entwickler-Tab (⚙️-Symbol)';

  @override
  String get troubleshootStep3 =>
      'Aktiviere den Schalter \"Im lokalen Netzwerk bereitstellen\"';

  @override
  String get troubleshootStep4 =>
      'Überprüfe, ob der Server-Port übereinstimmt (Standard: 1234)';

  @override
  String troubleshootStep5(String ip) {
    return 'Verwende http://localhost:1234 für lokale Verbindungen';
  }

  @override
  String get lmStudioSettings => 'LM Studio-Einstellungen';

  @override
  String get serveOnLocalNetworkHelp =>
      'Der Schalter \"Im lokalen Netzwerk bereitstellen\" muss aktiviert sein (orange/grün angezeigt) im Entwickler-Tab von LM Studio.';

  @override
  String get networkConnections => 'Netzwerkverbindungen:';

  @override
  String get networkConnectionsTips =>
      '• Ersetze \"localhost\" durch die IP-Adresse deines Computers\n• Stelle sicher, dass beide Geräte im selben Netzwerk sind\n• Überprüfe die Firewall-Einstellungen für Port 1234';

  @override
  String get noConversationsToExport => 'Keine Unterhaltungen zum Exportieren';

  @override
  String exportingConversations(int count) {
    return '$count Unterhaltung(en) werden exportiert...';
  }

  @override
  String exportSuccess(int count) {
    return '$count Unterhaltung(en) erfolgreich exportiert';
  }

  @override
  String get languageSection => 'SPRACHE';

  @override
  String get language => 'Sprache';

  @override
  String get languageSubtitle => 'Wähle deine bevorzugte Sprache';

  @override
  String get systemDefault => 'Systemstandard';

  @override
  String get english => 'English';

  @override
  String get spanish => 'Español';

  @override
  String get german => 'Deutsch';

  @override
  String get french => 'Français';

  @override
  String get russian => 'Русский';

  @override
  String get chinese => '中文';

  @override
  String get toolsCallingTitle => 'Tool-Aufrufe';

  @override
  String get toolCallingSection => 'TOOL-AUFRUFE';

  @override
  String get enableToolCallingAndMcps => 'Tools und MCPs aktivieren';

  @override
  String get enableToolCallingSubtitle =>
      'KI erlauben, im Web zu suchen und MCPs aufzurufen';

  @override
  String get builtInToolsSection => 'EINGEBAUTE TOOLS';

  @override
  String get builtInToolsInfo =>
      'Tools, die lokal von der App ausgeführt werden, wenn die KI sie anfordert';

  @override
  String get webSearch => 'Websuche';

  @override
  String get webSearchUsingSearxng => 'Verwendet SearXNG';

  @override
  String get webSearchDisabled =>
      'Deaktiviert (SearXNG konfigurieren oder auf Pro upgraden)';

  @override
  String get integratedMcpsSection => 'INTEGRIERTE MCPs';

  @override
  String get integratedMcpsInfo =>
      'Nutze MCPs, die du bereits in LM Studio eingerichtet hast. Füge hier einfach die Namen aus deiner mcp.json hinzu.';

  @override
  String get integratedMcpsAuthRequired =>
      'Integrierte MCPs erfordern aktivierte Authentifizierung in LM Studio und einen API-Token unter Einstellungen → API-Token.';

  @override
  String get requiresApiToken => 'Erfordert API-Token';

  @override
  String get setApiTokenTooltip =>
      'Setze einen API-Token in den Einstellungen, um dies zu aktivieren';

  @override
  String get noIntegratedMcps => 'Keine integrierten MCPs konfiguriert';

  @override
  String get addManually => 'Manuell hinzufügen';

  @override
  String get importMcpJson => 'mcp.json importieren';

  @override
  String get ephemeralMcpsSection => 'EPHEMERE MCPs';

  @override
  String get ephemeralMcpsInfo =>
      'HTTP-MCP-Server, die pro Anfrage gesendet werden. Erfordert \"MCPs pro Anfrage erlauben\" in LM Studio.';

  @override
  String get requiresPerRequestMcps =>
      'Erfordert: Entwickler → Servereinstellungen → MCPs pro Anfrage erlauben';

  @override
  String get noEphemeralMcps => 'Keine ephemeren MCPs konfiguriert';

  @override
  String get addHttpMcpServer => 'HTTP-MCP-Server hinzufügen';

  @override
  String get browseExampleMcps => 'Beispiel-MCP-Server ansehen';

  @override
  String get addIntegratedMcpTitle => 'MCP hinzufügen';

  @override
  String get editIntegratedMcpTitle => 'MCP bearbeiten';

  @override
  String get addIntegratedMcpInfo =>
      'Kopiere den Namen aus der mcp.json von LM Studio und füge ihn hier ein. Steht dort z. B. der Schlüssel playwright, tippe playwright.';

  @override
  String get mcpNameLabel => 'Name aus mcp.json';

  @override
  String get mcpNameHint => 'playwright';

  @override
  String get mcpNameHelper =>
      'Nur Buchstaben, Zahlen und Bindestriche — web-search, nicht web_search.';

  @override
  String get exampleMcpJsonEntry => '💡 Beispiel mcp.json-Eintrag:';

  @override
  String get nameIsRequired => 'Name ist erforderlich';

  @override
  String get mcpNameInvalidChars =>
      'Verwende Bindestriche statt Unterstrichen (LM Studio akzeptiert Namen wie web_search nicht).';

  @override
  String get mcpNameAlreadyExists => 'Dieser MCP ist bereits hinzugefügt';

  @override
  String addedMcp(String name) {
    return '$name hinzugefügt';
  }

  @override
  String updatedMcp(String name) {
    return '$name aktualisiert';
  }

  @override
  String get editMcpTooltip => 'Name bearbeiten';

  @override
  String get unlimitedToolCalls => 'Unbegrenzte Tool-Aufrufe';

  @override
  String get unlimitedToolCallsSubtitle =>
      'Entfernt das Limit von 10 Aufrufen für integrierte und flüchtige MCPs (beeinflusst Pro Search nicht)';

  @override
  String get unlimitedToolCallsOn =>
      'Keine Begrenzung für MCP-Tool-Aufruf-Iterationen';

  @override
  String get unlimitedToolCallsOff => 'Begrenzt auf 10 Tool-Aufruf-Iterationen';

  @override
  String get structuredOutput => 'Strukturierte Ausgabe';

  @override
  String get structuredOutputSubtitle => 'JSON-Antwortformat erzwingen';

  @override
  String get reasoningMode => 'Reasoning-Modus';

  @override
  String get reasoningOff => 'Aus';

  @override
  String get reasoningLow => 'Niedrig';

  @override
  String get reasoningMedium => 'Mittel';

  @override
  String get reasoningHigh => 'Hoch';

  @override
  String get reasoningOn => 'An';

  @override
  String get reasoningDescOff => 'Keine Reasoning-Spuren';

  @override
  String get reasoningDescLow => 'Minimales Reasoning';

  @override
  String get reasoningDescMedium => 'Ausgewogenes Reasoning';

  @override
  String get reasoningDescHigh => 'Detailliertes Reasoning';

  @override
  String get reasoningDescOn => 'Vollständige Reasoning-Spuren';

  @override
  String get helpSection => 'HILFE';

  @override
  String get toolCallingGuide => 'Tool-Aufruf-Anleitung';

  @override
  String get toolCallingGuideSubtitle =>
      'Erfahre, wie Tool-Aufrufe funktionieren';

  @override
  String get searxngSetupGuide => 'SearXNG-Einrichtungsanleitung';

  @override
  String get searxngSetupGuideSubtitle =>
      'Richte deinen eigenen Suchserver ein';

  @override
  String get webSearchConfig => 'Websuche-Konfiguration';

  @override
  String get howWebSearchWorks => '💡 Wie die Websuche funktioniert';

  @override
  String get howWebSearchWorksSteps =>
      '1. Die KI entscheidet, dass sie aktuelle Informationen benötigt\n2. Die App sucht mit Premium-Suche oder SearXNG\n3. Die Ergebnisse werden an die KI gesendet\n4. Die KI erstellt eine Antwort';

  @override
  String get searchResultsLabel => 'Suchergebnisse: ';

  @override
  String get webSearchDisabledWarning =>
      'Websuche deaktiviert. Konfiguriere SearXNG oder upgrade auf Pro.';

  @override
  String get searxngUrlOptional => 'SearXNG-URL (Optional)';

  @override
  String get searxngUrlLabel => 'SearXNG-URL';

  @override
  String get searxngUrlHint => 'http://localhost:8888';

  @override
  String get quickSetupDocker => '🐳 Schnelleinrichtung mit Docker:';

  @override
  String get dockerCommand => 'docker run -d -p 8888:8080 searxng/searxng';

  @override
  String get mcpBadge => 'MCP';

  @override
  String get mcpResultBadge => 'MCP-Ergebnis';

  @override
  String get webSearchSourcesTitle => 'Quellen';

  @override
  String get toolBadge => 'Tool';

  @override
  String get resultBadge => 'Ergebnis';

  @override
  String get failedToLoadImage => 'Bild konnte nicht geladen werden';

  @override
  String get thinking => 'Denkt nach';

  @override
  String get think => 'Denken';

  @override
  String thoughtFor(String duration) {
    return 'Hat $duration lang nachgedacht';
  }

  @override
  String get performanceStats => 'Leistungsstatistiken';

  @override
  String get regenerate => 'Regenerieren';

  @override
  String get editMessage => 'Nachricht bearbeiten';

  @override
  String get editMessageHint => 'Bearbeite deine Nachricht...';

  @override
  String get saveAndRegenerate => 'Speichern und regenerieren';

  @override
  String get deleteMessage => 'Nachricht löschen';

  @override
  String get deleteMessageConfirm =>
      'Bist du sicher, dass du diese Nachricht löschen möchtest?';

  @override
  String get mcpCallTitle => 'MCP-Aufruf';

  @override
  String get mcpResultTitle => 'MCP-Ergebnis';

  @override
  String get toolCallTitle => 'Tool-Aufruf';

  @override
  String get toolResultTitle => 'Tool-Ergebnis';

  @override
  String get attachFile => 'Datei anhängen';

  @override
  String get photoLibrary => 'Fotobibliothek';

  @override
  String get attachImagesForVision => 'Bilder für Bildanalyse anhängen';

  @override
  String get requiresVisionModel => 'Erfordert ein Modell mit Bilderkennung';

  @override
  String get takePhoto => 'Foto aufnehmen';

  @override
  String get captureImageWithCamera => 'Bild mit Kamera aufnehmen';

  @override
  String get imageFromFiles => 'Bild aus Dateien';

  @override
  String get pickImageFromFilesApp => 'Ein Bild aus der Dateien-App auswählen';

  @override
  String get attachDocuments => 'Dokumente';

  @override
  String get attachDocumentsSubtitle =>
      'PDF, Markdown, Excel (.xlsx), CSV, Text, Code und mehr';

  @override
  String get textFileTxt => 'Textdatei (.txt)';

  @override
  String get attachPlainText => 'Nur-Text-Dokumente anhängen';

  @override
  String get csvFileCsv => 'CSV-Datei (.csv)';

  @override
  String get attachSpreadsheetData => 'Tabellendaten anhängen';

  @override
  String get pdfDocumentPdf => 'PDF-Dokument (.pdf)';

  @override
  String get attachPdfDocuments => 'PDF-Dokumente anhängen';

  @override
  String get mcpLabel => 'MCP:';

  @override
  String get typeMessageHint => 'Nachricht eingeben...';

  @override
  String get attachFilesTooltip => 'Dateien anhängen';

  @override
  String get customizeChat => 'Chat anpassen';

  @override
  String get overrideGlobalAppearance =>
      'Globale Darstellung für diesen Chat überschreiben';

  @override
  String get background => 'Hintergrund';

  @override
  String get userAvatar => 'Benutzer-Avatar';

  @override
  String get assistantAvatar => 'Assistenten-Avatar';

  @override
  String get colorsSection => 'Farben';

  @override
  String get userBubble => 'Benutzerblase';

  @override
  String get userText => 'Benutzertext';

  @override
  String get assistantBubble => 'Assistentenblase';

  @override
  String get assistantText => 'Assistententext';

  @override
  String get darkOverlay => 'Dunkle Überlagerung';

  @override
  String get darkOverlayDescription =>
      'Dunkelheit der Hintergrundbild-Überlagerung anpassen';

  @override
  String get usingGlobal => 'Verwendet global';

  @override
  String get useGlobal => 'Global verwenden';

  @override
  String get setCustom => 'Anpassen';

  @override
  String get customColor => 'Benutzerdefinierte Farbe';

  @override
  String get defaultThemeColor => 'Standard-Themafarbe';

  @override
  String get resetToDefault => 'Auf Standard zurücksetzen';

  @override
  String get pickAColor => 'Wähle eine Farbe';

  @override
  String get chatSettingsTitle => 'Chat-Einstellungen';

  @override
  String get overrideGlobalSettings =>
      'Globale Einstellungen nur für diesen Chat überschreiben';

  @override
  String get resetAll => 'Alles zurücksetzen';

  @override
  String get modelOverride => 'Modell';

  @override
  String get noneSelected => 'Nichts ausgewählt';

  @override
  String get systemPromptOverride => 'Persona';

  @override
  String get saved => 'Gespeichert';

  @override
  String get noSavedPromptsInfo =>
      'Keine gespeicherten Personas. Gehe zu Einstellungen → Personas, um welche zu erstellen.';

  @override
  String get selectSavedPromptHint => 'Persona auswählen...';

  @override
  String get enterCustomPromptHint =>
      'Benutzerdefinierten Persona-Prompt eingeben...';

  @override
  String get personaShareMemoriesLabel => 'Erinnerungen teilen';

  @override
  String get personaShareMemoriesSubtitle =>
      'Wenn aus, erhält und lernt diese Persona in Chats keine Erinnerungen';

  @override
  String get webSearchOffForThisChat => 'Nur für diesen Chat aus';

  @override
  String get reasoningOffForThisChat => 'Nur für diesen Chat aus';

  @override
  String get temperatureOverride => 'Temperatur';

  @override
  String get maxTokensOverride => 'Maximale Tokens';

  @override
  String get topPOverride => 'Top P';

  @override
  String get topKOverride => 'Top K';

  @override
  String get minPOverride => 'Min P';

  @override
  String get repeatPenaltyOverride => 'Wiederholungsbestrafung';

  @override
  String get contextLengthOverride => 'Kontextlänge';

  @override
  String get systemPromptsTitle => 'Personas und System-Prompts';

  @override
  String get addSystemPromptTooltip => 'System-Prompt hinzufügen';

  @override
  String get systemPromptsInfoText =>
      'Erstelle und verwalte System-Prompts. Verknüpfe sie mit bestimmten Modellen oder verwende sie global. Wähle einen aus, um ihn zu aktivieren.';

  @override
  String get savedPromptsSection => 'GESPEICHERTE PROMPTS';

  @override
  String get addSystemPrompt => 'System-Prompt hinzufügen';

  @override
  String get newPrompt => 'Neuer Prompt oder Persona';

  @override
  String get noPromptSet => 'Kein Prompt gesetzt';

  @override
  String get editSystemPrompt => 'System-Prompt bearbeiten';

  @override
  String get newSystemPrompt => 'Neuer System-Prompt';

  @override
  String get promptNameLabel => 'Prompt-Name';

  @override
  String get promptNameHint => 'z.B. Code-Assistent, Kreativer Schreiber...';

  @override
  String get systemPromptLabel => 'System-Prompt';

  @override
  String get systemPromptEditorHint =>
      'Du bist ein hilfreicher Assistent, der...';

  @override
  String get bindToModels => 'An bestimmte Modelle binden';

  @override
  String get bindToModelsSubtitle =>
      'Beschränke diesen Prompt auf bestimmte Modelle. Ohne Bindung ist er für alle Modelle verfügbar.';

  @override
  String get noModelsLoaded =>
      'Keine Modelle geladen. Verbinde dich mit LM Studio und lade Modelle, um diesen Prompt zu binden.';

  @override
  String get templatesSection => 'VORLAGEN';

  @override
  String get pleaseEnterPromptName =>
      'Bitte gib einen Namen für diesen Prompt ein';

  @override
  String get pleaseEnterPromptContent => 'Bitte gib den Prompt-Inhalt ein';

  @override
  String get deleteSystemPromptTitle => 'System-Prompt löschen?';

  @override
  String deleteSystemPromptMessage(String name) {
    return 'Bist du sicher, dass du \"$name\" löschen möchtest? Dies kann nicht rückgängig gemacht werden.';
  }

  @override
  String get templateCodeAssistant => 'Code-Assistent';

  @override
  String get templateCreativeWriter => 'Kreativer Schreiber';

  @override
  String get templateConciseExpert => 'Präziser Experte';

  @override
  String get templateResearcher => 'Forscher';

  @override
  String get templateTutor => 'Tutor';

  @override
  String get templateTechnicalWriter => 'Technischer Autor';

  @override
  String get downloadProgress => 'Download-Fortschritt';

  @override
  String get progressLabel => 'Fortschritt';

  @override
  String get speedLabel => 'Geschwindigkeit';

  @override
  String get etaLabel => 'Geschätzte Zeit';

  @override
  String get statusLabel => 'Status';

  @override
  String get notAvailable => 'N/V';

  @override
  String get calculating => 'Berechne...';

  @override
  String get moveToFolderPopup => 'In Ordner verschieben';

  @override
  String contextInfo(String used, String total) {
    return 'Kontext: $used / $total';
  }

  @override
  String get hideAvatars => 'Avatare ausblenden';

  @override
  String get hideAvatarsSubtitle =>
      'Avatar-Symbole aus Chat-Nachrichten entfernen';

  @override
  String get autoScroll => 'Automatisches Scrollen';

  @override
  String get autoScrollSubtitle =>
      'Nach unten scrollen, wenn neue Nachrichten eintreffen';

  @override
  String get editMcpServer => 'MCP-Server bearbeiten';

  @override
  String get addMcpServer => 'MCP-Server hinzufügen';

  @override
  String get serverLabelRequired => 'Server-Bezeichnung *';

  @override
  String get serverLabelHint => 'z.B. huggingface, tiktoken';

  @override
  String get serverLabelHelper => 'Ein Name zur Identifizierung dieses Servers';

  @override
  String get serverUrlRequired => 'Server-URL *';

  @override
  String get serverUrlMcpHint => 'https://huggingface.co/mcp';

  @override
  String get serverUrlHelper => 'HTTP/HTTPS-URL des MCP-Servers';

  @override
  String get authorizationOptional => 'API-Schlüssel (Optional)';

  @override
  String get authorizationHint => 'hf_xxxxxxxx oder Bearer hf_xxxxxxxx';

  @override
  String get authorizationHelper =>
      'Wird als Authorization-Header an diesen MCP gesendet. Rohes Token einfügen (Bearer wird ergänzt) oder vollen Header-Wert.';

  @override
  String get additionalHeaders => 'Zusätzliche Header';

  @override
  String get additionalHeadersHint => 'X-Custom-Header: Wert';

  @override
  String get additionalHeadersHelper =>
      'Ein Header pro Zeile (Name: Wert).\nAutorisierung wird oben konfiguriert.';

  @override
  String get labelAndUrlRequired => 'Bezeichnung und URL sind erforderlich';

  @override
  String get urlMustStartWithHttp =>
      'URL muss mit http:// oder https:// beginnen';

  @override
  String get mcpServerUpdated => 'MCP-Server aktualisiert';

  @override
  String get mcpServerAdded => 'MCP-Server hinzugefügt';

  @override
  String get importMcpJsonTitle => 'mcp.json importieren';

  @override
  String get pasteMcpJsonContent => 'Füge den Inhalt deiner mcp.json ein';

  @override
  String get mcpJsonLocation =>
      'Zu finden unter: ~/.lmstudio/config/mcp.json\nOder in LM Studio: Entwickler → MCP-Konfiguration → Config öffnen';

  @override
  String get mcpJsonContentLabel => 'mcp.json-Inhalt';

  @override
  String get mcpJsonContentHelper =>
      'Füge den vollständigen Inhalt der mcp.json-Datei ein';

  @override
  String get parseJson => 'JSON analysieren';

  @override
  String foundMcpServers(int count) {
    return '$count MCP-Server gefunden:';
  }

  @override
  String get hasAuthHeaders => 'Hat Authentifizierungs-Header';

  @override
  String importSelected(int count) {
    return '$count Ausgewählte importieren';
  }

  @override
  String get pleasePasteMcpJson => 'Bitte füge den Inhalt deiner mcp.json ein';

  @override
  String get noMcpServersFound => 'Keine mcpServers im JSON gefunden';

  @override
  String get exampleMcpServers => 'Beispiel-MCP-Server';

  @override
  String get gitMcpInfo =>
      'Diese verwenden GitMCP, um Dokumentation von GitHub-Repos bereitzustellen';

  @override
  String get browseMoreGitMcp => 'Mehr auf gitmcp.io ansehen';

  @override
  String get fileNotFound => 'Datei nicht gefunden';

  @override
  String get openWithExternalApp => 'Mit externer App öffnen';

  @override
  String get previewNotAvailable => 'Vorschau nicht verfügbar';

  @override
  String get voiceMode => 'Sprachmodus';

  @override
  String get voiceSettings => 'Spracheinstellungen';

  @override
  String get voiceSettingsSubtitle =>
      'Sprachausgabe, Spracheingabe und Sprachmodus';

  @override
  String get voiceSection => 'Stimme';

  @override
  String get voiceStatus => 'Status';

  @override
  String get voiceTtsEngine => 'Sprachausgabe-Engine';

  @override
  String get voiceSttEngine => 'Spracherkennung-Engine';

  @override
  String get voiceAvailable => 'Verfügbar';

  @override
  String get voiceUnavailable => 'Nicht verfügbar';

  @override
  String get voiceTtsSettings => 'Sprachausgabe';

  @override
  String get voiceSttSettings => 'Sprache-zu-Text';

  @override
  String get voiceSttProvider => 'Spracherkennungsanbieter';

  @override
  String get voiceSttProviderSystem => 'Systemsprache';

  @override
  String get voiceSttProviderSystemSubtitle =>
      'Apple Speech auf iOS, Google Speech auf Android';

  @override
  String get voiceSttProviderWhisper => 'On-Device Whisper';

  @override
  String get voiceSttProviderWhisperSubtitle =>
      'Offline sherpa-onnx Whisper — genauer, auf allen Plattformen gleich';

  @override
  String get voiceWhisperModelNotDownloaded =>
      'Whisper-Modell nicht heruntergeladen';

  @override
  String get voiceWhisperModelReady => 'Whisper-Modell bereit';

  @override
  String get voiceWhisperModelSize =>
      'Größe wählen — größere Modelle transkribieren genauer';

  @override
  String get voiceWhisperDownloadButton => 'Herunterladen';

  @override
  String get voiceWhisperDownloading => 'Whisper-Modell wird heruntergeladen…';

  @override
  String get voiceWhisperDownloadStarting => 'Download wird gestartet…';

  @override
  String get voiceWhisperDownloadFailed => 'Download fehlgeschlagen';

  @override
  String get voiceWhisperDeleteModel => 'Ausgewähltes Whisper-Modell löschen';

  @override
  String get voiceWhisperDeleteTitle => 'Whisper-Modell löschen?';

  @override
  String get voiceWhisperDeleteMessage =>
      'Dadurch wird das ausgewählte Modell vom Gerätespeicher entfernt. Die On-Device-Spracherkennung fällt auf die Systemsprache zurück, bis du erneut ein Whisper-Modell herunterlädst.';

  @override
  String get voiceWhisperDeleteConfirm => 'Löschen';

  @override
  String get voiceWhisperFallback =>
      'Fällt auf Systemsprache zurück, wenn das Modell nicht heruntergeladen ist';

  @override
  String get voiceWhisperBiggerBetterTitle => 'Warum größere Modelle?';

  @override
  String get voiceWhisperBiggerBetterBody =>
      'Größere Whisper-Modelle liefern meist genauere Transkripte — besonders bei Akzenten, leiser Audio, Hintergrundgeräuschen und ungewöhnlichen Wörtern. Sie brauchen mehr Speicher und laufen langsamer auf dem Gerät.\n\nTiny reicht für kurze, klare Sprache. Base oder Small eignet sich besser für längere Dateien. Large v3 Turbo ist das schnellste/kleinste der großen Modelle (reduziertes Large v3). Volles Large v3 ist am genauesten, aber auch am schwersten.';

  @override
  String get voiceWhisperUseModel => 'Verwenden';

  @override
  String get voiceWhisperSelected => 'Ausgewählt';

  @override
  String get voiceWhisperDownloaded => 'Heruntergeladen';

  @override
  String get audioSetupTitle => 'Stimme & Audio einrichten';

  @override
  String get audioSetupMessage =>
      'Voice-Chat braucht eine Stimme, damit die KI laut antworten kann. Lade eine Stimme für den natürlichsten Klang herunter, oder nutze die eingebauten Stimmen deines Telefons — kein Download nötig.';

  @override
  String get audioSetupWhisperStatus => 'Whisper-Spracherkennung';

  @override
  String get audioSetupKokoroStatus => 'Kokoro-Neuralstimme';

  @override
  String get audioSetupStatusReady => 'Bereit';

  @override
  String get audioSetupStatusMissing => 'Nicht heruntergeladen';

  @override
  String get audioSetupOnDeviceButton => 'Kokoro-Stimme herunterladen';

  @override
  String get audioSetupOnDeviceSubtitle =>
      'Kokoro Neural-TTS · ca. 300 MB · funktioniert offline';

  @override
  String get audioSetupSystemButton => 'Systemsprache verwenden';

  @override
  String get audioSetupSystemSubtitle =>
      'Integriertes STT und TTS — kein Download nötig';

  @override
  String get audioSetupConfigureButton => 'Spracheinstellungen';

  @override
  String get audioSetupNotNow => 'Nicht jetzt';

  @override
  String get audioSetupDownloadingWhisper => 'Whisper wird heruntergeladen…';

  @override
  String get audioSetupDownloadingKokoro => 'Kokoro wird heruntergeladen…';

  @override
  String get audioSetupDownloadComplete => 'Modelle bereit';

  @override
  String get audioSetupContinueButton => 'Weiter';

  @override
  String get voiceModeSettings => 'Sprachmodus';

  @override
  String get voiceAutoRead => 'Antworten automatisch vorlesen';

  @override
  String get voiceAutoReadSubtitle =>
      'Neue Assistenten-Nachrichten automatisch vorlesen';

  @override
  String get voiceSpeechRate => 'Sprechgeschwindigkeit';

  @override
  String get voicePitch => 'Tonhöhe';

  @override
  String get voiceLanguage => 'Stimmsprache';

  @override
  String get voiceLanguageSubtitle =>
      'Language for spoken replies (text-to-speech)';

  @override
  String get voiceSttLanguage => 'Recognition language';

  @override
  String get voiceSttLanguageSubtitle =>
      'Used for the text mic and Voice Call. Can differ from spoken reply language.';

  @override
  String get voiceSelection => 'Stimmauswahl';

  @override
  String get voiceDefault => 'Standard';

  @override
  String get voiceTestVoice => 'Stimme testen';

  @override
  String get voiceTestVoiceSubtitle =>
      'Probe abspielen, um die aktuellen Stimmeinstellungen zu hören';

  @override
  String get voiceTestPhrase => 'Hallo! So klinge ich jetzt.';

  @override
  String get voiceTestProgressInitializing => 'TTS-Engine wird gestartet…';

  @override
  String get voiceTestProgressGenerating => 'Sprache wird erzeugt…';

  @override
  String get voiceTestProgressPreparing => 'Wiedergabe wird vorbereitet…';

  @override
  String get voiceTestProgressPlaying => 'Beispiel wird abgespielt…';

  @override
  String get voiceTestProgressConnecting => 'Verbindung zur Remote-Stimme…';

  @override
  String get voiceTestProgressComplete => 'Fertig';

  @override
  String get voiceKokoroEngineReady =>
      'Engine bereit — Test sollte schnell starten';

  @override
  String get voiceKokoroEngineWarming => 'On-Device-Engine wird vorbereitet…';

  @override
  String get voiceAutoSend => 'Automatisch senden nach Sprache';

  @override
  String get voiceAutoSendSubtitle =>
      'Nachricht automatisch senden, wenn die Spracherkennung endet';

  @override
  String get voiceSttPauseFor => 'Stille vor dem Senden';

  @override
  String get voiceSttPauseForSubtitle =>
      'Sekunden Stille, bevor die Sprache an die KI gesendet wird';

  @override
  String get voiceSttListenFor => 'Maximale Hörzeit';

  @override
  String get voiceSttListenForSubtitle =>
      'Hört nach so vielen Sekunden auf, auch wenn du noch sprichst';

  @override
  String voiceSttSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String get voiceContinuousConversation => 'Endlosgespräch';

  @override
  String get voiceContinuousConversationSubtitle =>
      'Automatisch zuhören, nachdem die Antwort vorgelesen wurde';

  @override
  String get voiceTapToSpeak => 'Tippen zum Sprechen';

  @override
  String get voiceListening => 'Hört zu…';

  @override
  String get voiceThinking => 'Einen Moment…';

  @override
  String get voiceResponding => 'Antwortet…';

  @override
  String get voiceSpeaking => 'Spricht…';

  @override
  String get voiceConvoHintIdle => 'Tippe auf den Kreis, um zu sprechen';

  @override
  String get voiceConvoHintListening => 'Ich höre zu — nimm dir Zeit';

  @override
  String get voiceConvoHintStarting => 'Mikrofon wird vorbereitet…';

  @override
  String get voiceConvoHintProcessing => 'Denke nach…';

  @override
  String get voiceConvoHintSpeaking => '';

  @override
  String get voiceNotAvailable =>
      'Spracherkennung ist auf diesem Gerät nicht verfügbar';

  @override
  String get voiceStartRecording => 'Spracheingabe starten';

  @override
  String get voiceStopRecording => 'Aufnahme stoppen';

  @override
  String get voiceDiscardRecording => 'Verwerfen';

  @override
  String get voiceSelectLanguage => 'Sprache wählen';

  @override
  String get voiceSelectVoice => 'Stimme wählen';

  @override
  String get voiceNoVoicesAvailable =>
      'Keine Stimmen für diese Sprache verfügbar';

  @override
  String get voiceAboutTitle => 'Über den Sprachmodus';

  @override
  String get voiceAboutDescription =>
      'Der Sprachmodus nutzt die nativen Sprach-Engines Ihres Geräts. Die Sprachausgabe verwendet Apples AVSpeechSynthesizer auf iOS und Google TTS auf Android. Die Spracherkennung verwendet Apples Speech Framework auf iOS und Google Speech auf Android. Alle Verarbeitung erfolgt auf dem Gerät — keine Daten werden an externe Server gesendet.';

  @override
  String get voiceExitMode => 'Zur Tastatur wechseln';

  @override
  String get voiceTtsProvider => 'TTS-Anbieter';

  @override
  String get voiceTtsProviderNative => 'Gerät (Nativ)';

  @override
  String get voiceTtsProviderNativeSubtitle =>
      'Nutzt integrierte Systemstimmen — funktioniert offline';

  @override
  String get voiceTtsProviderKokoro => 'Heruntergeladene Stimme';

  @override
  String get voiceTtsProviderKokoroSubtitle =>
      'Natürliche Stimmen, die auf diesem Gerät laufen';

  @override
  String get voiceTtsProviderKokoroRemote => 'Kokoro (PC)';

  @override
  String get voiceTtsProviderKokoroRemoteSubtitle =>
      'Kokoro auf Ihrem PC für schnellere, hochwertigere Sprache ausführen';

  @override
  String get voiceTtsProviderElevenLabs => 'ElevenLabs';

  @override
  String get voiceTtsProviderElevenLabsSubtitle =>
      'Pro · dein API-Schlüssel · Cloud-Stimmen';

  @override
  String get voiceTtsElevenLabs => 'ElevenLabs';

  @override
  String get voiceTtsElevenLabsHint =>
      'Dein Schlüssel · Stimmen aus deiner ElevenLabs-Bibliothek';

  @override
  String get voiceElevenLabsApiKey => 'ElevenLabs-API-Schlüssel';

  @override
  String get voiceElevenLabsApiKeyHint =>
      'Füge deinen xi-api-key von elevenlabs.io ein';

  @override
  String get voiceElevenLabsTestKey => 'Schlüssel prüfen';

  @override
  String get voiceElevenLabsKeyInvalid =>
      'Dieser Schlüssel wurde nicht akzeptiert. Prüfe ihn auf elevenlabs.io.';

  @override
  String get voiceElevenLabsKeyNetwork =>
      'ElevenLabs war nicht erreichbar. Prüfe deine Verbindung.';

  @override
  String get voiceElevenLabsKeyQuota =>
      'Dieser Schlüssel hat kein Kontingent mehr.';

  @override
  String get voiceElevenLabsKeyUnknown =>
      'Dieser Schlüssel konnte nicht geprüft werden. Bitte erneut versuchen.';

  @override
  String get voiceElevenLabsPrivacy =>
      'Antworttext wird mit deinem Schlüssel an ElevenLabs gesendet. LM Mini speichert den Schlüssel nur auf diesem Gerät.';

  @override
  String get voiceElevenLabsModel => 'ElevenLabs-Modell';

  @override
  String get voiceElevenLabsVoice => 'ElevenLabs-Stimme';

  @override
  String get voiceElevenLabsNoVoices =>
      'Keine Stimmen in diesem Konto. Füge zuerst Stimmen in der ElevenLabs-Bibliothek hinzu.';

  @override
  String get voiceElevenLabsChangeKey => 'Schlüssel ändern';

  @override
  String get voiceElevenLabsRemoveKey => 'Schlüssel entfernen';

  @override
  String get voiceElevenLabsReady => 'Mit ElevenLabs verbunden';

  @override
  String get voiceElevenLabsNoKey => 'ElevenLabs-API-Schlüssel hinzufügen';

  @override
  String get personaElevenLabsVoiceLabel => 'ElevenLabs-Stimme';

  @override
  String get personaElevenLabsVoiceGlobal =>
      'Globale ElevenLabs-Stimme verwenden';

  @override
  String get personaElevenLabsVoicePickerTitle => 'ElevenLabs-Stimme';

  @override
  String get personaElevenLabsVoiceAddKey =>
      'Füge in den Spracheinstellungen einen API-Schlüssel hinzu, um eine ElevenLabs-Stimme zu wählen';

  @override
  String get premiumElevenLabsTts => 'ElevenLabs-Stimmen';

  @override
  String get premiumElevenLabsTtsTagline =>
      'Neurales TTS mit eigenem Schlüssel';

  @override
  String get premiumElevenLabsTtsDescription =>
      'Hinterlege deinen ElevenLabs-API-Schlüssel und weise Personas Studio-Stimmen zu. Voice-Chat, Vorlesen und Vorlesen in Blasen nutzen dieselbe Engine.';

  @override
  String get voiceTtsProviderGrok => 'Grok';

  @override
  String get voiceTtsProviderGrokSubtitle =>
      'Pro · dein xAI-API-Schlüssel · Cloud-Stimmen';

  @override
  String get voiceTtsGrok => 'Grok';

  @override
  String get voiceTtsGrokHint => 'Dein Schlüssel · Grok-Stimmen von xAI';

  @override
  String get voiceGrokApiKey => 'xAI-API-Schlüssel';

  @override
  String get voiceGrokApiKeyHint =>
      'Füge deinen API-Schlüssel von console.x.ai ein';

  @override
  String get voiceGrokTestKey => 'Schlüssel prüfen';

  @override
  String get voiceGrokKeyInvalid =>
      'Dieser Schlüssel wurde nicht akzeptiert. Prüfe ihn auf console.x.ai.';

  @override
  String get voiceGrokKeyNetwork =>
      'xAI war nicht erreichbar. Prüfe deine Verbindung.';

  @override
  String get voiceGrokKeyQuota => 'Dieser Schlüssel hat kein Kontingent mehr.';

  @override
  String get voiceGrokKeyUnknown =>
      'Dieser Schlüssel konnte nicht geprüft werden. Bitte erneut versuchen.';

  @override
  String get voiceGrokPrivacy =>
      'Antworttext wird mit deinem Schlüssel an xAI gesendet. LM Mini speichert den Schlüssel nur auf diesem Gerät.';

  @override
  String get voiceGrokVoice => 'Grok-Stimme';

  @override
  String get voiceGrokNoVoices =>
      'Keine Grok-Stimmen verfügbar. Prüfe den Schlüssel und versuche es erneut.';

  @override
  String get voiceGrokChangeKey => 'Schlüssel ändern';

  @override
  String get voiceGrokRemoveKey => 'Schlüssel entfernen';

  @override
  String get voiceGrokReady => 'Mit Grok verbunden';

  @override
  String get voiceGrokNoKey => 'xAI-API-Schlüssel hinzufügen';

  @override
  String get personaGrokVoiceLabel => 'Grok-Stimme';

  @override
  String get personaGrokVoiceGlobal => 'Globale Grok-Stimme verwenden';

  @override
  String get personaGrokVoicePickerTitle => 'Grok-Stimme';

  @override
  String get personaGrokVoiceAddKey =>
      'Füge in den Spracheinstellungen einen API-Schlüssel hinzu, um eine Grok-Stimme zu wählen';

  @override
  String get personaVoiceSection => 'Stimme';

  @override
  String get personaVoiceProviderLabel => 'Anbieter';

  @override
  String get personaVoiceProviderKokoro => 'Kokoro';

  @override
  String get personaVoiceProviderGlobal =>
      'Globale Spracheinstellungen verwenden';

  @override
  String get personaVoiceConfigureInSettings =>
      'Unter Einstellungen → Stimme einrichten';

  @override
  String get premiumGrokTts => 'Grok-Stimmen';

  @override
  String get premiumGrokTtsTagline => 'Neurales TTS mit eigenem Schlüssel';

  @override
  String get premiumGrokTtsDescription =>
      'Hinterlege deinen xAI-API-Schlüssel und weise Personas Grok-Stimmen zu. Voice-Chat, Vorlesen und Vorlesen in Blasen nutzen dieselbe Engine.';

  @override
  String get voiceRemoteKokoroConnected => 'Verbunden mit Kokoro auf dem PC';

  @override
  String get voiceRemoteKokoroNotFound =>
      'Kokoro TTS nicht auf dem PC gefunden';

  @override
  String get voiceRemoteKokoroRequiresConnect =>
      'Erfordert „Mit Telefon teilen“ auf dem Mac oder LM Mini Connect unter Windows/Linux';

  @override
  String get voiceKokoroVoice => 'Kokoro Stimme';

  @override
  String get voiceKokoroSpeed => 'Sprechgeschwindigkeit';

  @override
  String get voiceKokoroModelReady => 'Kokoro-Modell bereit';

  @override
  String get voiceKokoroModelReadySubtitle =>
      'Heruntergeladene Stimme ist bereit';

  @override
  String get voiceKokoroModelNotDownloaded =>
      'Kokoro-Modell nicht heruntergeladen';

  @override
  String get voiceKokoroModelSize =>
      'Download erforderlich (~400 MB gemeinsames Paket)';

  @override
  String get voiceKokoroDownloading => 'Kokoro-Modell wird heruntergeladen…';

  @override
  String get voiceKokoroDownloadStarting => 'Download wird gestartet…';

  @override
  String get voiceKokoroDownloadButton => 'Herunterladen';

  @override
  String get voiceKokoroDownloadFailed =>
      'Download fehlgeschlagen. Tippen zum Wiederholen.';

  @override
  String get voiceKokoroFallback =>
      'Fällt auf native Stimme zurück, wenn das Kokoro-Modell nicht heruntergeladen ist';

  @override
  String get voiceKokoroDeleteModel => 'Kokoro-Modell löschen';

  @override
  String get voiceKokoroDeleteTitle => 'Kokoro-Modell löschen?';

  @override
  String get voiceKokoroDeleteMessage =>
      'Dies entfernt alle heruntergeladenen TTS-Sprachpakete. Sie können sie später erneut herunterladen.';

  @override
  String get voiceKokoroDeleteConfirm => 'Löschen';

  @override
  String get voiceTtsLanguagePacksHint =>
      'Englisch, Spanisch, Französisch und Chinesisch teilen einen Download (~400 MB). Deutsch und Russisch sind kleiner (~34 MB).';

  @override
  String get voiceTtsLanguagePacks => 'Sprachpakete';

  @override
  String get voiceTtsLanguagePacksSubtitleNone =>
      'Lade eine Sprache herunter, um auf diesem Gerät zu sprechen';

  @override
  String voiceTtsLanguagePacksSubtitleReady(int ready, int total) {
    return '$ready von $total Sprachen bereit';
  }

  @override
  String voiceTtsLanguagePacksSubtitleDownloading(String name) {
    return '$name wird heruntergeladen…';
  }

  @override
  String voiceTtsSharedPackSize(int size) {
    return 'Gemeinsamer Download · ~$size MB';
  }

  @override
  String voiceTtsPiperPackSize(int size) {
    return 'Kleinerer Download · ~$size MB';
  }

  @override
  String get voiceTtsSharedPackDeleteMessage =>
      'Dies entfernt den gemeinsamen Download für Englisch, Spanisch, Französisch und Chinesisch. Sie können ihn später erneut herunterladen.';

  @override
  String get connecting => 'Verbinde...';

  @override
  String get saveAndTestConnection => 'Speichern & Verbindung testen';

  @override
  String connectedTo(String provider) {
    return '✅ Verbunden mit $provider';
  }

  @override
  String connectionToFailed(String provider) {
    return '❌ Verbindung zu $provider fehlgeschlagen — überprüfe deinen API-Schlüssel';
  }

  @override
  String errorGeneric(String error) {
    return '❌ Fehler: $error';
  }

  @override
  String get provider => 'Anbieter';

  @override
  String cloudApiKeyLabel(String provider) {
    return '$provider API-Schlüssel';
  }

  @override
  String get enterApiKeyHint => 'API-Schlüssel eingeben…';

  @override
  String getApiKey(String provider) {
    return '$provider API-Schlüssel holen';
  }

  @override
  String get baseUrl => 'Basis-URL';

  @override
  String get customBaseUrlOptional => 'Benutzerdefinierte Basis-URL (optional)';

  @override
  String get accountSection => 'KONTO';

  @override
  String get signIn => 'Anmelden';

  @override
  String get signInSubtitle => 'Anmelden, um Cloud-Backup zu aktivieren';

  @override
  String get cloudServicesUnavailable => 'Cloud-Dienste nicht verfügbar';

  @override
  String signedInVia(String method) {
    return 'Angemeldet über $method';
  }

  @override
  String get lmMiniProSection => 'LM MINI PRO';

  @override
  String get proActive => 'Pro Aktiv';

  @override
  String get allPremiumUnlocked => 'Alle Premium-Funktionen freigeschaltet';

  @override
  String get upgradeToPro => 'Auf Pro upgraden';

  @override
  String get unlockPremiumFeatures =>
      'Alle Premium-Funktionen unten freischalten';

  @override
  String get proBadge => 'PRO';

  @override
  String get proFeatureTag => 'Pro-Funktion';

  @override
  String get betaBadge => 'BETA';

  @override
  String get imageGeneration => 'Bilderzeugung';

  @override
  String get generatedImagesLibrary => 'Erzeugte Bilder';

  @override
  String get generatedImagesGallery => 'Galerie';

  @override
  String get generatedImagesShowInChat => 'Im Chat zeigen';

  @override
  String get generatedImagesLibrarySubtitle =>
      'Ansehen, im Chat öffnen oder löschen';

  @override
  String get generatedImagesLibraryEmpty => 'Noch keine erzeugten Bilder';

  @override
  String get generatedImagesLibraryEmptyHint =>
      'Bilder, die du im Chat erzeugst, werden hier gespeichert.';

  @override
  String get generatedImagesSelect => 'Auswählen';

  @override
  String get generatedImagesCancelSelect => 'Fertig';

  @override
  String generatedImagesDeleteN(int count) {
    return '$count löschen';
  }

  @override
  String get generatedImagesDeleteConfirmTitle => 'Bilder löschen?';

  @override
  String generatedImagesDeleteConfirmBody(int count) {
    return '$count Bild(er) werden von diesem Gerät entfernt. Chat-Nachrichten bleiben.';
  }

  @override
  String get generatedImagesOpenChat => 'Im Chat öffnen';

  @override
  String get saveToPhotos => 'Save to Photos';

  @override
  String get savedToPhotos => 'Saved to Photos';

  @override
  String get couldNotSaveToPhotos => 'Could not save this file.';

  @override
  String get share => 'Share';

  @override
  String get generatedImagesMissingFile => 'Datei fehlt';

  @override
  String get generatedImagesOrphan => 'Keinem Chat zugeordnet';

  @override
  String get generatedImagesPrompt => 'Prompt';

  @override
  String get generatedImagesNegativePrompt => 'Negativ-Prompt';

  @override
  String get generatedImagesDetails => 'Erzeugungsdetails';

  @override
  String get generatedImagesNoPrompt => 'Kein Prompt gespeichert';

  @override
  String get generatedImagesChatUnavailable =>
      'Dieser Chat ist nicht mehr verfügbar';

  @override
  String get generatedImagesVideo => 'Video';

  @override
  String imageGenEnabled(String url) {
    return 'Aktiviert — $url';
  }

  @override
  String get imageGenNotConfigured => 'Aktiviert — Nicht konfiguriert';

  @override
  String get cloudBackup => 'Cloud-Backup';

  @override
  String get encryptedBackupRestore =>
      'Verschlüsseltes Backup & Wiederherstellung';

  @override
  String get e2eBanner =>
      'Ende-zu-Ende-verschlüsselt — Ihre Passphrase verlässt dieses Gerät nie';

  @override
  String get analytics => 'Statistiken';

  @override
  String get analyticsSubtitle =>
      'Nutzungsstatistiken, Token & Modell-Einblicke';

  @override
  String get memory => 'Erinnerungen';

  @override
  String memoryItemCount(int count) {
    return '$count Einträge • Dauerhaft über Chats hinweg';
  }

  @override
  String get premiumWebSearch => 'Premium-Websuche';

  @override
  String get premiumWebSearchSubtitle => 'Sofortige Suche — kein SearXNG nötig';

  @override
  String get urlReader => 'URL-Reader';

  @override
  String get urlReaderSubtitle => 'Beliebige Webseite lesen & zusammenfassen';

  @override
  String get conversationBranching => 'Gesprächsverzweigung';

  @override
  String get conversationBranchingSubtitle =>
      'Gespräche ab jeder Nachricht abzweigen';

  @override
  String get cloudBackupPro => 'Cloud-Backup';

  @override
  String get cloudBackupProSubtitle =>
      'Verschlüsseltes Backup & Wiederherstellung in die Cloud';

  @override
  String get analyticsDashboard => 'Statistik-Dashboard';

  @override
  String get analyticsDashboardSubtitle =>
      'Nutzungsstatistiken, Token & Modell-Einblicke';

  @override
  String get cloudApiProviders => 'Cloud-API-Anbieter';

  @override
  String get cloudApiProvidersSubtitle => 'Mistral, DeepSeek & mehr';

  @override
  String get addProviderLabel => 'Anbieter hinzufügen';

  @override
  String get noCloudProvidersTitle => 'Keine Cloud-Anbieter';

  @override
  String get noCloudProvidersSubtitle =>
      'Tippe auf +, um einen Cloud-API-Anbieter hinzuzufügen.\nVerwende deine eigenen API-Schlüssel für Groq, DeepSeek und mehr.';

  @override
  String get editProviderTitle => 'Anbieter bearbeiten';

  @override
  String get addCloudProviderTitle => 'Cloud-Anbieter hinzufügen';

  @override
  String get providerLabel => 'Anbieter';

  @override
  String get apiKeyLabel => 'API-Schlüssel';

  @override
  String get pasteLabel => 'Einfügen';

  @override
  String get baseUrlRequiredLabel => 'Basis-URL (erforderlich)';

  @override
  String get customBaseUrlOptionalLabel =>
      'Benutzerdefinierte Basis-URL (optional)';

  @override
  String get advancedLabel => 'Erweitert';

  @override
  String get fetchingLabel => 'Lade...';

  @override
  String get fetchAvailableModelsLabel => 'Verfügbare Modelle laden';

  @override
  String get availableModelsLabel => 'Verfügbare Modelle:';

  @override
  String get suggestedModelsLabel => 'Vorgeschlagene Modelle:';

  @override
  String get modelIdLabel => 'Modell-ID';

  @override
  String get disableCloudProviderSubtitle =>
      'Deaktiviert die Konfiguration, ohne sie zu entfernen';

  @override
  String get setAsActiveProviderLabel => 'Als aktiven Anbieter festlegen';

  @override
  String get deactivateLabel => 'Deaktivieren';

  @override
  String get switchedBackToLocalLmStudio =>
      'Zurück zu lokalem LM Studio gewechselt';

  @override
  String get saveChangesLabel => 'Änderungen speichern';

  @override
  String get enterDisplayNameError => 'Bitte einen Anzeigenamen eingeben';

  @override
  String get enterApiKeyError => 'Bitte einen API-Schlüssel eingeben';

  @override
  String get enterBaseUrlError =>
      'Bitte eine Basis-URL für den benutzerdefinierten Anbieter eingeben';

  @override
  String get enterApiKeyFirst => 'Bitte zuerst einen API-Schlüssel eingeben';

  @override
  String failedToFetchModels(String error) {
    return 'Modelle konnten nicht geladen werden: $error';
  }

  @override
  String get deleteProviderTitle => 'Anbieter löschen?';

  @override
  String deleteProviderMessage(String name) {
    return '\"$name\" und den zugehörigen API-Schlüssel entfernen?';
  }

  @override
  String deleteFirstPartyOpenAiServerMessage(String name) {
    return '„$name“ von diesem Gerät entfernen?\n\nDiesen Server kannst du nicht mehr über die Liste hinzufügen. Zum erneuten Verbinden füge A.I Compatible API hinzu und setze die Basis-URL auf https://api.openai.com.';
  }

  @override
  String activeProviderSet(String name) {
    return '$name als aktiven Anbieter festgelegt';
  }

  @override
  String get memoryPro => 'Erinnerungen';

  @override
  String get memoryProSubtitle =>
      'Dauerhafte Erinnerungen über Gespräche hinweg';

  @override
  String get richExportShare => 'Rich-Export & Teilen';

  @override
  String get richExportShareSubtitle =>
      'Export zu Obsidian, Notizen, Notion & mehr';

  @override
  String autoUnloadAfter(String value) {
    return 'Auto-Entladen nach $value';
  }

  @override
  String get subscriptionRestore => 'Wiederherstellen';

  @override
  String get subscriptionTerms => 'AGB';

  @override
  String get subscriptionPrivacy => 'Datenschutz';

  @override
  String get secureYourAccount => 'Konto sichern';

  @override
  String get signInWithApple => 'Mit Apple anmelden';

  @override
  String get signInWithGoogle => 'Mit Google anmelden';

  @override
  String get subscriptionSecured => 'Ihr Abo ist gesichert';

  @override
  String get packagesNotAvailable => 'Pakete noch nicht verfügbar.';

  @override
  String get welcomeToPro => '🎉 Willkommen bei LM Mini Pro!';

  @override
  String get subscriptionRestored => '✅ Abo wiederhergestellt!';

  @override
  String get noActiveSubscription => 'Kein aktives Abo gefunden.';

  @override
  String get accountLinked => '✅ Konto verknüpft!';

  @override
  String get account => 'Konto';

  @override
  String get createAccount => 'Konto erstellen';

  @override
  String get emailLabel => 'E-Mail';

  @override
  String get passwordLabel => 'Passwort';

  @override
  String get forgotPassword => 'Passwort vergessen?';

  @override
  String get forgotPasswordNeedEmail =>
      'Gib zuerst deine E-Mail-Adresse ein und tippe dann auf Passwort vergessen.';

  @override
  String get forgotPasswordSent =>
      'Wenn ein Konto mit dieser E-Mail existiert, haben wir einen Link zum Zurücksetzen geschickt. Prüfe deinen Posteingang.';

  @override
  String get forgotPasswordFailed =>
      'Die E-Mail zum Zurücksetzen konnte nicht gesendet werden. Bitte versuche es erneut.';

  @override
  String get verificationEmailSent => 'Bestätigungs-E-Mail gesendet!';

  @override
  String failedToSend(String error) {
    return 'Senden fehlgeschlagen: $error';
  }

  @override
  String get cloudBackupEnabled =>
      'Aktiviert — Ihr Konto unterstützt verschlüsselte Backups';

  @override
  String get endToEndEncryption => 'Ende-zu-Ende-Verschlüsselung';

  @override
  String get e2eSubtitle =>
      'Backups mit Ihrer Passphrase verschlüsselt — wir können sie nicht lesen';

  @override
  String get upgradeForCloudBackup =>
      'Upgrade auf Pro für verschlüsselte Cloud-Backups';

  @override
  String get signOut => 'Abmelden';

  @override
  String get signOutConfirm => 'Abmelden?';

  @override
  String get signedOut => 'Abgemeldet.';

  @override
  String get goToAccount => 'Zum Konto';

  @override
  String get firebaseNotConfigured => 'Firebase ist nicht konfiguriert.';

  @override
  String get refresh => 'Aktualisieren';

  @override
  String get createBackup => 'Backup erstellen';

  @override
  String get encryptBackupSubtitle => 'Alle Gespräche verschlüsseln & sichern';

  @override
  String get backUpNow => 'Jetzt sichern';

  @override
  String get yourBackups => 'IHRE BACKUPS';

  @override
  String get e2eBackupBanner => 'Ende-zu-Ende-verschlüsselt. ';

  @override
  String get e2eBackupDetail =>
      'Ihre Backups werden mit Ihrer Passphrase verschlüsselt, bevor sie dieses Gerät verlassen. Wir können Ihre Daten nicht lesen.';

  @override
  String get exportingData => 'Daten exportieren...';

  @override
  String get preparing => 'Vorbereiten...';

  @override
  String get encrypting => 'Verschlüsseln...';

  @override
  String get uploading => 'Hochladen...';

  @override
  String get savingMetadata => 'Metadaten speichern...';

  @override
  String get done => 'Fertig!';

  @override
  String get noBackupsYet => 'Noch keine Backups';

  @override
  String get createFirstBackup =>
      'Erstellen Sie oben Ihr erstes verschlüsseltes Backup';

  @override
  String get encrypted => 'Verschlüsselt';

  @override
  String get restore => 'Wiederherstellen';

  @override
  String get encryptionPassphraseLabel => 'Verschlüsselungs-Passphrase';

  @override
  String get enterStrongPassphrase => 'Geben Sie eine starke Passphrase ein';

  @override
  String get confirmPassphraseLabel => 'Passphrase bestätigen';

  @override
  String get passphraseRememberWarning =>
      'Merken Sie sich diese Passphrase! Wenn Sie sie verlieren, können Ihre Backups nicht wiederhergestellt werden. Wir speichern sie nirgendwo.';

  @override
  String get passphraseRestoreHint =>
      'Geben Sie die gleiche Passphrase ein, die Sie beim Erstellen dieses Backups verwendet haben.';

  @override
  String get minCharsRequired => 'Mindestens 4 Zeichen erforderlich.';

  @override
  String get passphrasesDoNotMatch => 'Passphrasen stimmen nicht überein.';

  @override
  String get encryptAndBackUp => 'Verschlüsseln & Sichern';

  @override
  String get decryptAndRestore => 'Entschlüsseln & Wiederherstellen';

  @override
  String get encryptionPassphrase => 'Verschlüsselungs-Passphrase';

  @override
  String get savedPassphrasePrompt =>
      'Sie haben eine gespeicherte Passphrase von einem früheren Backup. Möchten Sie dieselbe verwenden oder eine neue festlegen?';

  @override
  String get newPassphrase => 'Neue Passphrase';

  @override
  String get useSame => 'Gleiche verwenden';

  @override
  String get setEncryptionPassphrase => 'Verschlüsselungs-Passphrase festlegen';

  @override
  String get choosePassphraseBackup =>
      'Wählen Sie eine Passphrase, um dieses Backup zu verschlüsseln. Sie benötigen sie zur Wiederherstellung auf jedem Gerät.';

  @override
  String get choosePassphraseDetail =>
      'Wählen Sie eine Passphrase, um Ihr Backup zu verschlüsseln. Diese Passphrase bleibt auf Ihrem Gerät — wir sehen sie nie. Sie benötigen sie zur Wiederherstellung.';

  @override
  String backupFailed(String error) {
    return 'Backup fehlgeschlagen: $error';
  }

  @override
  String get restoreBackupConfirm => 'Backup wiederherstellen?';

  @override
  String get restoreWarning =>
      'Dies wird ALLE Ihre aktuellen Gespräche, Nachrichten und Ordner durch die Daten aus diesem Backup ERSETZEN.\n\nDies kann nicht rückgängig gemacht werden.';

  @override
  String get continueAction => 'Weiter';

  @override
  String get enterPassphrase => 'Passphrase eingeben';

  @override
  String get passphraseDecryptHint =>
      'Dieses Backup ist Ende-zu-Ende-verschlüsselt. Geben Sie die Passphrase ein, die Sie beim Erstellen verwendet haben.';

  @override
  String get wrongPassphrase => 'Falsche Passphrase oder beschädigtes Backup.';

  @override
  String restoreFailed(String error) {
    return 'Wiederherstellung fehlgeschlagen: $error';
  }

  @override
  String get deleteBackupConfirm => 'Backup löschen?';

  @override
  String get deleteBackupWarning =>
      'Dies löscht dieses verschlüsselte Cloud-Backup dauerhaft. Dies kann nicht rückgängig gemacht werden.';

  @override
  String get backupDeleted => 'Backup gelöscht.';

  @override
  String deleteFailed(String error) {
    return 'Löschen fehlgeschlagen: $error';
  }

  @override
  String get overview => 'ÜBERSICHT';

  @override
  String get messages => 'Nachrichten';

  @override
  String get conversations => 'Gespräche';

  @override
  String get totalTokens => 'Tokens gesamt';

  @override
  String get avgResponse => 'Ø Antwort';

  @override
  String get modelUsage => 'MODELLNUTZUNG';

  @override
  String get noModelUsageData =>
      'Noch keine Modellnutzungsdaten.\nBeginnen Sie zu chatten, um hier Statistiken zu sehen.';

  @override
  String get analyticsSync =>
      'Statistiken werden mit Ihrem Konto synchronisiert und beim Abmelden zurückgesetzt.';

  @override
  String get clearAllMemories => 'Alle Erinnerungen löschen';

  @override
  String get memoryOn => 'Ein';

  @override
  String get memoryOff => 'Aus';

  @override
  String get memoryInfoText =>
      'Gedächtniseinträge werden in den System-Prompt eingefügt, damit sich das LLM über Gespräche hinweg an Sie erinnert.';

  @override
  String get noMemoriesYet => 'Noch keine Erinnerungen';

  @override
  String noMemoriesInCategory(String category) {
    return 'Keine $category-Erinnerungen';
  }

  @override
  String get memoryTapToAdd =>
      'Tippen Sie auf +, um eine neue Erinnerung hinzuzufügen oder wählen Sie eine andere Kategorie.';

  @override
  String get memoryAddHint =>
      'Fügen Sie Fakten über sich hinzu, die die KI über alle Gespräche hinweg behalten soll.';

  @override
  String get addMemory => 'Erinnerung hinzufügen';

  @override
  String get category => 'Kategorie';

  @override
  String get editMemory => 'Erinnerung bearbeiten';

  @override
  String get deleteMemory => 'Erinnerung löschen';

  @override
  String removeMemoryConfirm(String content) {
    return 'Diese Erinnerung entfernen?\n\n\"$content\"';
  }

  @override
  String get clearAllMemoriesTitle => 'Alle Erinnerungen löschen';

  @override
  String clearAllMemoriesConfirm(int count) {
    return 'Dies löscht dauerhaft alle $count Erinnerungen. Dies kann nicht rückgängig gemacht werden.';
  }

  @override
  String get clearAll => 'Alle löschen';

  @override
  String get justNow => 'gerade eben';

  @override
  String get categoryPersonal => 'Persönlich';

  @override
  String get categoryPreferences => 'Einstellungen';

  @override
  String get categoryLifestyle => 'Lifestyle';

  @override
  String get categoryEmotional => 'Emotional';

  @override
  String get categoryTechnical => 'Technisch';

  @override
  String get categoryWork => 'Arbeit';

  @override
  String get categoryGeneral => 'Allgemein';

  @override
  String get categoryAll => 'Alle';

  @override
  String get modelManagement => 'Modellverwaltung';

  @override
  String get downloadNewModel => 'Neues Modell herunterladen';

  @override
  String get refreshModels => 'Modelle aktualisieren';

  @override
  String get tapToSelect => 'Zum Auswählen tippen';

  @override
  String modelSelected(String name) {
    return 'Ausgewählt: $name';
  }

  @override
  String get unloadModelTooltip => 'Modell aus dem Speicher entladen';

  @override
  String get modelInfoTooltip => 'Modell-Info';

  @override
  String get loadedBadge => 'GELADEN';

  @override
  String get visionBadge => 'Vision';

  @override
  String get toolsBadge => 'Tools';

  @override
  String get selectedModel => 'Ausgewähltes Modell';

  @override
  String get unloading => 'Entlade...';

  @override
  String get unload => 'Entladen';

  @override
  String get loaded => 'Geladen';

  @override
  String get loadModel => 'Modell laden';

  @override
  String get enterModelIdOrUrl => 'Modell-ID oder HuggingFace-URL eingeben:';

  @override
  String get modelIdHint => 'microsoft/phi-4';

  @override
  String get modelIdHelper => 'Modell-ID oder https://huggingface.co/...';

  @override
  String get huggingFaceDetected =>
      'HuggingFace-URL erkannt — Sie wählen eine Quantisierung';

  @override
  String get starting => 'Starte...';

  @override
  String get download => 'Herunterladen';

  @override
  String get selectQuantization => 'Quantisierung wählen';

  @override
  String get loadingQuantizations => 'Quantisierungen laden...';

  @override
  String get error => 'Fehler';

  @override
  String fetchQuantizationsFailed(String error) {
    return 'Quantisierungen konnten nicht abgerufen werden: $error';
  }

  @override
  String get checkLmStudioRunning => 'Prüfe, ob LM Studio läuft';

  @override
  String get couldNotReachLmStudio =>
      'LM Mini konnte deinen Server nicht erreichen.';

  @override
  String get couldNotLoadQuantizations =>
      'Quantisierungen konnten nicht geladen werden.';

  @override
  String get couldNotStartDownload => 'Download konnte nicht gestartet werden.';

  @override
  String get noQuantizations => 'Keine Quantisierungen';

  @override
  String get noGgufFiles => 'Keine GGUF-Dateien in diesem Repository gefunden';

  @override
  String foundQuantizations(int count) {
    return '$count GGUF-Quantisierung(en) gefunden';
  }

  @override
  String get unknown => 'unbekannt';

  @override
  String downloadingModel(String quantization) {
    return 'Modell mit $quantization-Quantisierung wird heruntergeladen...';
  }

  @override
  String get modelAlreadyDownloaded => 'Modell bereits heruntergeladen';

  @override
  String downloadFailed(String error) {
    return 'Download fehlgeschlagen: $error';
  }

  @override
  String get enterModelIdentifier =>
      'Bitte geben Sie eine Modell-ID oder URL ein';

  @override
  String get modelAlreadyLoaded => 'Modell bereits geladen';

  @override
  String get currentlyLoaded => 'Aktuell geladen:';

  @override
  String loadAlongsideWarning(String name) {
    return '\"$name\" neben vorhandenen Modellen zu laden wird zusätzlichen Speicher verwenden.';
  }

  @override
  String get unloadAllAndLoad => 'Alle entladen & laden';

  @override
  String get swap => 'Tauschen';

  @override
  String get loadAlongside => 'Parallel laden';

  @override
  String get loadParamsConflictTitle => 'Ladeeinstellungen unterscheiden sich';

  @override
  String loadParamsConflictBody(String name) {
    return '\"$name\" ist bereits in LM Studio mit anderen Einstellungen geladen als in LM Minis Modell-Ladekonfiguration. Ein Neuladen kann eine Minute dauern und zusätzlichen Speicher belegen.';
  }

  @override
  String get loadParamsConflictTableHeader => 'Unterschiedliche Parameter:';

  @override
  String get loadParamsLmStudio => 'LM Studio';

  @override
  String get loadParamsLmMini => 'LM Mini';

  @override
  String get loadParamsConflictHint =>
      'LM-Studio-Einstellungen beibehalten vermeidet ein Neuladen. Entladen & neu laden wendet Ihre LM-Mini-Einstellungen an. Parallel laden behält beide Instanzen im Speicher.';

  @override
  String get loadParamsUseExisting => 'LM-Studio-Einstellungen verwenden';

  @override
  String get loadParamsReloadWithMini =>
      'Entladen & mit LM-Mini-Einstellungen laden';

  @override
  String get loadParamsLoadParallel =>
      'Mit LM-Mini-Einstellungen laden (parallel)';

  @override
  String get reloadModelForContextTitle => 'Modell neu laden?';

  @override
  String reloadModelForContextBody(String name, String loaded, String desired) {
    return 'Die Kontextlänge gilt beim Laden des Modells. \"$name\" ist mit $loaded geladen. Mit $desired neu laden?';
  }

  @override
  String get reloadModelForContextNow => 'Neu laden';

  @override
  String get reloadModelForContextLater => 'Später';

  @override
  String loadModelConfirm(String name) {
    return '\"$name\" in den Speicher laden?';
  }

  @override
  String get unloadModelTip =>
      'Sie können Modelle über den Auswerfen-Button oder von diesem Bildschirm nach dem Laden entladen.';

  @override
  String get modelLoadedSuccess => 'Modell erfolgreich geladen';

  @override
  String get failedToLoadModel => 'Modell konnte nicht geladen werden';

  @override
  String get modelInfo => 'Modell-Info';

  @override
  String get infoName => 'Name';

  @override
  String get infoType => 'Typ';

  @override
  String get infoArchitecture => 'Architektur';

  @override
  String get infoPublisher => 'Herausgeber';

  @override
  String get infoQuantization => 'Quantisierung';

  @override
  String get infoParameters => 'Parameter';

  @override
  String get infoSize => 'Größe';

  @override
  String get infoMaxContext => 'Max. Kontext';

  @override
  String get infoLoadedContext => 'Geladener Kontext';

  @override
  String get infoStatus => 'Status';

  @override
  String get available => 'Verfügbar';

  @override
  String get capabilities => 'Fähigkeiten';

  @override
  String get standardTextGeneration => 'Standard-Textgenerierung';

  @override
  String get unloadModelTitle => 'Modell entladen';

  @override
  String unloadModelConfirm(String name) {
    return '\"$name\" aus dem Speicher entladen?';
  }

  @override
  String get freeResourcesTip => 'Dies gibt GPU-/RAM-Ressourcen frei.';

  @override
  String get modelUnloadedSuccess => 'Modell erfolgreich entladen';

  @override
  String get failedToUnloadModel => 'Modell konnte nicht entladen werden';

  @override
  String get enableImageGeneration => 'Bilderzeugung aktivieren';

  @override
  String get showImageButtons => 'Bild-Buttons bei Chat-Nachrichten anzeigen';

  @override
  String get serverConnection => 'Serververbindung';

  @override
  String get serverUrl => 'Server-URL';

  @override
  String get test => 'Test';

  @override
  String get connected => 'Verbunden';

  @override
  String get model => 'Modell';

  @override
  String get checkpoint => 'Checkpoint';

  @override
  String get generationParameters => 'Generierungs-Parameter';

  @override
  String get negativePrompt => 'Negativ-Prompt';

  @override
  String get steps => 'Schritte';

  @override
  String get cfgScale => 'CFG-Skala';

  @override
  String get width => 'Breite';

  @override
  String get height => 'Höhe';

  @override
  String get sampler => 'Sampler';

  @override
  String get scheduler => 'Scheduler';

  @override
  String get automatic => 'Automatisch';

  @override
  String get seedLabel => 'Seed (-1 = zufällig)';

  @override
  String get batchSize => 'Batch-Größe';

  @override
  String get options => 'Optionen';

  @override
  String get restoreFaces => 'Gesichter wiederherstellen';

  @override
  String get restoreFacesSubtitle =>
      'Gesichter in generierten Bildern korrigieren';

  @override
  String get tiling => 'Kacheln';

  @override
  String get tilingSubtitle => 'Nahtlose kachelbare Texturen erzeugen';

  @override
  String get promptOptions => 'Prompt-Optionen';

  @override
  String get reviewPromptBeforeSending => 'Prompt vor dem Senden überprüfen';

  @override
  String get reviewPromptSubtitle =>
      'Bild-Prompt vor der Generierung bearbeiten';

  @override
  String get autoGenerateImage => 'Bild automatisch generieren';

  @override
  String get autoGenerateSubtitle =>
      'Bild automatisch generieren, wenn KI einen Prompt liefert';

  @override
  String get resetToDefaults => 'Auf Standardwerte zurücksetzen';

  @override
  String get featureRequestsTitle => 'Feature-Anfragen';

  @override
  String get featureRequestsUnavailable => 'Feature-Anfragen nicht verfügbar';

  @override
  String get featureRequestsUnavailableDetail =>
      'Diese Funktion erfordert eine Internetverbindung. Bitte überprüfen Sie Ihre Verbindung und versuchen Sie es später erneut.';

  @override
  String get tryAgain => 'Erneut versuchen';

  @override
  String get votesLeft => 'übrig';

  @override
  String get popular => 'Beliebt';

  @override
  String get myRequests => 'Meine Anfragen';

  @override
  String get completed => 'Abgeschlossen';

  @override
  String get submitIdea => 'Idee einreichen';

  @override
  String get noFeatureRequests => 'Noch keine Feature-Anfragen';

  @override
  String get beFirstToSubmit => 'Seien Sie der Erste, der eine Idee einreicht!';

  @override
  String get noRequestsSubmitted => 'Keine Anfragen eingereicht';

  @override
  String get tapToSubmitFirst =>
      'Tippen Sie auf die Schaltfläche unten, um Ihre erste Idee einzureichen!';

  @override
  String get noCompletedRequests => 'Keine abgeschlossenen Anfragen';

  @override
  String get completedRequestsAppear =>
      'Abgeschlossene und abgelehnte Anfragen erscheinen hier.';

  @override
  String get adminReplied => 'Admin hat geantwortet';

  @override
  String get submitFeatureRequest => 'Feature-Anfrage einreichen';

  @override
  String get titleRequired => 'Titel *';

  @override
  String get titleHint => 'Kurze Zusammenfassung Ihrer Idee';

  @override
  String get descriptionRequired => 'Beschreibung *';

  @override
  String get descriptionHint =>
      'Beschreiben Sie Ihre Feature-Anfrage im Detail';

  @override
  String get yourNameOptional => 'Dein Name (optional)';

  @override
  String get leaveBlankAnonymous => 'Leer lassen für anonyme Einreichung';

  @override
  String get fillTitleAndDescription =>
      'Bitte füllen Sie Titel und Beschreibung aus';

  @override
  String get featureRequestSubmitted => 'Feature-Anfrage eingereicht!';

  @override
  String get submit => 'Einreichen';

  @override
  String get featureRequest => 'Feature-Anfrage';

  @override
  String get votedTooltip => 'Abgestimmt';

  @override
  String get voteForThis => 'Dafür abstimmen';

  @override
  String get adminControls => 'Admin-Steuerung';

  @override
  String get changeStatus => 'Status ändern';

  @override
  String get officialReply => 'Offizielle Antwort';

  @override
  String get deleteRequest => 'Anfrage löschen';

  @override
  String get unableToLoadComments => 'Kommentare können nicht geladen werden';

  @override
  String commentsCount(int count) {
    return 'Kommentare ($count)';
  }

  @override
  String get readMore => 'Mehr anzeigen';

  @override
  String get showLess => 'Weniger anzeigen';

  @override
  String get deleteYourRequest => 'Deine Anfrage löschen';

  @override
  String get anonymous => 'Anonym';

  @override
  String get officialResponse => 'Offizielle Antwort';

  @override
  String get noCommentsYet => 'Noch keine Kommentare';

  @override
  String get beFirstToComment =>
      'Seien Sie der Erste, der seine Gedanken teilt!';

  @override
  String get adminBadge => 'ADMIN';

  @override
  String get moderatorBadge => 'MOD';

  @override
  String get experiencedUserBadge => 'EXP';

  @override
  String get adminManageSubmitter => 'Einreicher verwalten';

  @override
  String get adminManageUserTitle => 'Benutzer verwalten';

  @override
  String get adminUserUpdated => 'Benutzer aktualisiert';

  @override
  String get adminCommunityRoles => 'Community-Rollen';

  @override
  String get adminModeratorRole => 'Moderator';

  @override
  String get adminModeratorRoleSubtitle =>
      'Kann Kommentar-Spam-Limits umgehen und zeigt ein Mod-Badge';

  @override
  String get adminExperiencedUserRole => 'Erfahrener Nutzer';

  @override
  String get adminExperiencedUserRoleSubtitle =>
      'Zeigt ein „Erfahren“-Badge bei Feature-Request-Kommentaren';

  @override
  String get adminGrantPremiumTitle => 'Kostenloses Pro gewähren';

  @override
  String get adminGrantPremiumSubtitle =>
      'Diesem Nutzer für begrenzte Zeit kostenloses LM Mini Pro geben';

  @override
  String get adminGrantPremiumAmountLabel => 'Dauer';

  @override
  String get adminGrantPremiumAmountHint => 'Betrag eingeben';

  @override
  String get adminGrantPremiumUnitDays => 'Tage';

  @override
  String get adminGrantPremiumUnitWeeks => 'Wochen';

  @override
  String get adminGrantPremiumUnitMonths => 'Monate';

  @override
  String get adminGrantPremiumGrantButton => 'Pro gewähren';

  @override
  String get adminGrantPremiumInvalidAmount => 'Positive Zahl eingeben';

  @override
  String get adminGrantPremiumReasonLabel => 'Grund';

  @override
  String get adminGrantPremiumReasonHint =>
      'Optional — wird dem Nutzer angezeigt (z. B. Entschuldigung für die Umstände)';

  @override
  String adminGrantPremiumDurationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage',
      one: '1 Tag',
    );
    return '$_temp0';
  }

  @override
  String adminGrantPremiumDurationWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Wochen',
      one: '1 Woche',
    );
    return '$_temp0';
  }

  @override
  String adminGrantPremiumDurationMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Monate',
      one: '1 Monat',
    );
    return '$_temp0';
  }

  @override
  String get adminRevokePremiumTitle => 'Kostenloses Pro widerrufen';

  @override
  String get adminRevokePremiumMessage =>
      'Die aktive, vom Admin gewährte Pro-Freischaltung für diesen Nutzer entfernen?';

  @override
  String get adminRevokePremiumConfirm => 'Widerrufen';

  @override
  String get premiumGrantBannerTitle => 'Du hast kostenloses Pro erhalten';

  @override
  String premiumGrantBannerBody(String duration) {
    return 'Kostenloses LM Mini Pro für $duration. Genieße die Premium-Funktionen, solange es läuft.';
  }

  @override
  String premiumGrantBannerReason(String reason) {
    return 'Grund: $reason';
  }

  @override
  String get premiumGrantDialogTitle => 'Kostenloses Pro freigeschaltet';

  @override
  String premiumGrantDialogBody(String duration) {
    return 'Ein Admin hat dir kostenloses LM Mini Pro für $duration gewährt. Cloud-Backup, Memory, Analytics und mehr sind jetzt verfügbar.';
  }

  @override
  String premiumGrantDialogReason(String reason) {
    return 'Grund: $reason';
  }

  @override
  String get premiumGrantDialogButton => 'Super';

  @override
  String get youBadge => 'SIE';

  @override
  String get deleteComment =>
      'Bist du sicher, dass du diesen Kommentar löschen möchtest?';

  @override
  String maxCommentsReached(int max) {
    return 'Sie haben $max Kommentare hintereinander gepostet. Warten Sie, bis ein anderer Benutzer antwortet.';
  }

  @override
  String get addYourName => 'Ihren Namen hinzufügen';

  @override
  String get replyAsAdmin => 'Als Admin antworten...';

  @override
  String get writeComment => 'Kommentar schreiben...';

  @override
  String get errorTryAgain => 'Fehler: Bitte versuche es erneut.';

  @override
  String statusUpdated(String status) {
    return 'Status aktualisiert auf $status';
  }

  @override
  String get addOfficialResponse => 'Offizielle Antwort hinzufügen...';

  @override
  String get replySaved => 'Antwort gespeichert';

  @override
  String get deleteRequestConfirm =>
      'Möchten Sie diese Feature-Anfrage wirklich löschen? Dies kann nicht rückgängig gemacht werden.';

  @override
  String get requestDeleted => 'Anfrage gelöscht';

  @override
  String get deleteCommentTitle => 'Kommentar löschen';

  @override
  String get deleteCommentConfirm =>
      'Möchten Sie diesen Kommentar wirklich löschen?';

  @override
  String get commentDeleted => 'Kommentar gelöscht';

  @override
  String get generationParametersSection => 'GENERIERUNGS-PARAMETER';

  @override
  String get temperature => 'Temperatur';

  @override
  String get temperatureSubtitle =>
      'Wie kreativ oder fokussiert Antworten sind. Niedriger = vorsichtiger; höher = abwechslungsreicher.';

  @override
  String get topP => 'Top P';

  @override
  String get topPSubtitle =>
      'Wie breit die Wortauswahl sein darf. Niedriger = fokussiertere Antworten.';

  @override
  String get minP => 'Min P';

  @override
  String get minPSubtitle =>
      'Ignoriert sehr unwahrscheinliche Wörter. Höher = sicherer, vorhersehbarer Text.';

  @override
  String get repeatPenalty => 'Wiederholungsstrafe';

  @override
  String get repeatPenaltySubtitle =>
      'Verhindert, dass die KI dieselben Phrasen wiederholt. 1.0 = aus.';

  @override
  String get frequencyPenalty => 'Häufigkeitsstrafe';

  @override
  String get frequencyPenaltySubtitle =>
      'Verringert Wörter, die die KI zu oft benutzt.';

  @override
  String get presencePenalty => 'Präsenzstrafe';

  @override
  String get presencePenaltySubtitle =>
      'Ermutigt die KI zu neuen Themen statt alten Formulierungen.';

  @override
  String get tokenLimits => 'TOKEN-LIMITS';

  @override
  String get maxOutputTokens => 'Max. Ausgabe-Token';

  @override
  String get maxOutputTokensSubtitle =>
      'Wie lang eine einzelne Antwort sein darf. Höher = längere Antworten (und mehr Wartezeit).';

  @override
  String get contextWindow => 'Kontextfenster';

  @override
  String get contextWindowSubtitle =>
      'Wie viel vom Chat die KI auf einmal behält. Darf Load Context Length nicht überschreiten, falls gesetzt.';

  @override
  String get modelLoadingConfig => 'MODELL-LADEKONFIGURATION';

  @override
  String get loadContextLength => 'Kontextlänge';

  @override
  String get loadContextSubtitle =>
      'Wie viel Kontext das Modell für den Chat und beim Laden in LM Studio nutzen kann. Höher braucht mehr Speicher / VRAM.';

  @override
  String get contextFitTitle => 'When context is full';

  @override
  String get contextFitSubtitle =>
      'Keep chatting by fitting history into 90% of the loaded context. Compact writes a summary you can reuse if the server session is lost.';

  @override
  String get contextFitOff => 'Stop';

  @override
  String get contextFitRoll => 'Roll';

  @override
  String get contextFitCutMiddle => 'Cut middle';

  @override
  String get contextFitOffHelp =>
      'Show an error when the prompt is larger than the model context.';

  @override
  String get contextFitRollHelp =>
      'Drop the oldest messages and keep the recent ones.';

  @override
  String get contextFitCutMiddleHelp =>
      'Keep the start of the chat and the latest turns; drop the middle.';

  @override
  String get compactChat => 'Compact';

  @override
  String get compactingChat => 'Compacting…';

  @override
  String get compactChatHint =>
      'Summarize older messages so you can keep chatting in this context window.';

  @override
  String get compactChatDone =>
      'Chat compacted. The next send uses the summary plus new messages.';

  @override
  String get compactChatFailed => 'Couldn’t compact this chat. Try again.';

  @override
  String get compactChatNeedModel => 'Select a model before compacting.';

  @override
  String get evalBatchSize => 'Eval-Batch-Größe';

  @override
  String get evalBatchSubtitle =>
      'Wie viel Text beim Laden auf einmal verarbeitet wird. Höher kann schneller sein, braucht aber mehr Speicher.';

  @override
  String get numExperts => 'Anzahl Experten';

  @override
  String get numExpertsSubtitle =>
      'Nur für „Mixture of Experts“-Modelle. Leer lassen, wenn Sie unsicher sind.';

  @override
  String get flashAttention => 'Flash Attention';

  @override
  String get flashAttentionSubtitle =>
      'Macht das Modell schneller und kann Speicher sparen. An lassen, außer es gibt Probleme.';

  @override
  String get offloadKvCache => 'KV-Cache auf GPU auslagern';

  @override
  String get offloadKvCacheSubtitle =>
      'Nutzt die GPU, um den Chat effizienter zu speichern. An lassen, wenn eine GPU vorhanden ist.';

  @override
  String get resizeImageForPhysicalBatch => 'Resize images for physical batch';

  @override
  String get resizeImageForPhysicalBatchSubtitle =>
      'Shrink a photo when it would use more tokens than the local server\'s physical batch, so the model doesn\'t crash.';

  @override
  String get resizeImageForPhysicalBatchHelp =>
      'LM Studio, Ollama, Jan, Unsloth, oMLX, and on-device models keep a physical batch of 512 tokens. A full-size photo can take 560 or more vision tokens. The server then aborts and the model unloads. When this is on, Mini measures the photo and shrinks it so it stays under that batch. Turn it off to send the original image.';

  @override
  String get chainOfThoughtSubtitle =>
      'Zeigt das schrittweise Denken der KI, falls verfügbar.';

  @override
  String get reasoningUnsupportedToast =>
      'Dieses Modell unterstützt Reasoning in LM Studio nicht. Reasoning wurde deaktiviert.';

  @override
  String get reasoningNotExposedChatHint =>
      'LM Studio unterstützt das Ausschalten von Reasoning für dieses Modell nicht. Versuche ein anderes Modell.';

  @override
  String get premiumSearchActive => 'Premium-Suche aktiv';

  @override
  String get premiumSearchPlusSearxng => ' + SearXNG';

  @override
  String get webSearchDisabledAll => 'Websuche für alle Chats deaktiviert';

  @override
  String get configureSearch => 'Suche konfigurieren';

  @override
  String get advancedFeaturesSection => 'ERWEITERTE FUNKTIONEN';

  @override
  String get howToolCallingWorks => 'Wie Tool-Aufrufe funktionieren';

  @override
  String get stepAskQuestion => 'Sie stellen eine Frage';

  @override
  String get stepAskExample => 'z.B. ‚Wie ist das Wetter in Tokio?\'';

  @override
  String get stepAiRequestsTool => 'KI fordert ein Tool an';

  @override
  String get stepAiRequestsExample =>
      'Modell entscheidet, dass es eine Websuche braucht';

  @override
  String get stepAppExecutes => 'App führt das Tool aus';

  @override
  String get stepAppExecutesExample => 'Sucht mit Premium-Suche oder SearXNG';

  @override
  String get stepResultsSent => 'Ergebnisse an KI gesendet';

  @override
  String get stepResultsExample => 'Suchergebnisse zum Gespräch hinzugefügt';

  @override
  String get stepAiAnswers => 'KI generiert Antwort';

  @override
  String get stepAiAnswersExample =>
      'Modell synthetisiert eine hilfreiche Antwort';

  @override
  String get toolCallingModelNote => 'wie Qwen, Llama 3.1+ oder Mistral.';

  @override
  String get searxngSetup => 'SearXNG-Einrichtung';

  @override
  String get searxngDescription =>
      'SearXNG ist eine kostenlose, datenschutzfreundliche Metasuchmaschine, die Sie selbst hosten können.';

  @override
  String get dockerRecommended => 'Option 1: Docker (Empfohlen)';

  @override
  String get publicInstance => 'Option 2: Öffentliche Instanz nutzen';

  @override
  String get findPublicInstances => 'Öffentliche Instanzen finden unter:';

  @override
  String get selfHostRecommended =>
      'Selbst-Hosting wird für Zuverlässigkeit empfohlen.';

  @override
  String get clipboardEmpty =>
      'Zwischenablage ist leer. Kopieren Sie zuerst Ihren mcp.json-Inhalt.';

  @override
  String get clipboardAccessFailed =>
      'Konnte nicht auf die Zwischenablage zugreifen. Bitte fügen Sie manuell in das Feld unten ein.';

  @override
  String get pasteFromClipboard => 'Aus Zwischenablage einfügen';

  @override
  String get httpServersImportNote =>
      'HTTP-Server → Flüchtige MCPs (pro Anfrage an LM Studio gesendet)';

  @override
  String get localMcpsImportNote =>
      'Lokale MCPs → Integrierte MCPs (verwenden ‚mcp/name\'-Format)';

  @override
  String get noValidMcpServers => 'Keine gültigen MCP-Server gefunden';

  @override
  String get serverAlreadyAdded => 'Dieser Server ist bereits hinzugefügt';

  @override
  String get themeSection => 'DESIGN';

  @override
  String get themeLabel => 'Thema';

  @override
  String get glassEffectsLabel => 'Glaseffekte';

  @override
  String get glassEffectsSubtitle =>
      'Milchglas-Unschärfe in Kopfzeilen und Menüs. Aus schont Akku und Wärme.';

  @override
  String get lowBatteryModeLabel => 'Energiesparmodus';

  @override
  String get lowBatteryModeSubtitle =>
      'Schaltet Glas aus, zeigt beim Streamen Klartext und synchronisiert Home/iCloud erst nach der Nachricht. Der Bildschirm bleibt an, bis die Antwort fertig ist, damit der Stream nicht abbricht.';

  @override
  String get backgroundSection => 'HINTERGRUND';

  @override
  String get chatBackground => 'Chat-Hintergrund';

  @override
  String get chatBackgroundSubtitle =>
      'Standard-Hintergrund für alle Chats festlegen';

  @override
  String get avatarsSection => 'AVATARE';

  @override
  String get chatHeaderAvatarLabel => 'Avatar in der Chat-Kopfzeile';

  @override
  String get chatHeaderAvatarSubtitle =>
      'Profilbild in der App-Leiste des Chatfensters anzeigen';

  @override
  String get avatarAboveMessageLabel => 'Avatar über der Nachricht';

  @override
  String get avatarAboveMessageSubtitle =>
      'Avatar über der Nachrichtenblase statt daneben anzeigen';

  @override
  String get fullWidthAssistantLabel => 'Antworten in voller Breite';

  @override
  String get fullWidthAssistantSubtitle =>
      'Deine Nachrichten bleiben in einer Blase. Antworten nutzen die ganze Zeile';

  @override
  String get tryFullWidthTitle => 'Neue Vollbreite ausprobieren';

  @override
  String get tryFullWidthBody =>
      'Antworten nutzen die ganze Zeile, ohne Blase dahinter. Du kannst jederzeit unter Darstellung zurückwechseln.';

  @override
  String get tryFullWidthOpenAppearance => 'Darstellung öffnen';

  @override
  String get tryFullWidthNotNow => 'Jetzt nicht';

  @override
  String get streamingPhaseLoadingModel => 'Modell wird geladen';

  @override
  String get streamingPhaseProcessingPrompt => 'Eingabe wird verarbeitet';

  @override
  String get streamingPhaseThinking => 'Denke nach';

  @override
  String get streamingPhaseWriting => 'Schreibe Antwort';

  @override
  String get streamingPhaseSearching => 'Suche';

  @override
  String get streamingPhaseUsingTools => 'Nutze Werkzeuge';

  @override
  String streamingPhaseConnecting(String provider) {
    return 'Verbinde mit $provider…';
  }

  @override
  String get networkOfflineTitle => 'Du bist offline';

  @override
  String get networkOfflineBody =>
      'Verbinde dich mit WLAN oder mobilen Daten und versuch es noch einmal.';

  @override
  String networkNeedsWifiTitle(String provider) {
    return 'Mobile Daten – $provider braucht WLAN';
  }

  @override
  String networkNeedsWifiBody(String provider, String host) {
    return '$provider auf deinem Computer ($host) ist nur im selben WLAN wie dein Computer erreichbar. Verbinde dich mit diesem WLAN oder schalte Fernzugriff ein, um es überall zu nutzen.';
  }

  @override
  String networkLostWifiTitle(String provider) {
    return 'Verbindung zu $provider verloren';
  }

  @override
  String get networkLostWifiBody =>
      'Dein Handy ist nicht mehr im WLAN. Verbinde dich wieder mit demselben WLAN wie dein Computer oder schalte Fernzugriff ein, um überall weiterzuchatten.';

  @override
  String get networkUseRemoteAccess => 'Fernzugriff nutzen';

  @override
  String get networkSwitchProvider => 'Anbieter wechseln';

  @override
  String get messageNotDelivered => 'Nicht zugestellt · Tippen zum Wiederholen';

  @override
  String get messageRetrying => 'Wird gesendet…';

  @override
  String get messageNotDeliveredA11y =>
      'Nachricht nicht zugestellt. Tippen zum Wiederholen.';

  @override
  String get previewUserMessage => 'Welchen Sockel hat dieses Board?';

  @override
  String get bubbleAvatarSizeLabel => 'Avatargröße in Sprechblasen';

  @override
  String bubbleAvatarRadiusValue(int value) {
    return '${value}px Radius';
  }

  @override
  String get userAvatarLabel => 'Benutzeravatar';

  @override
  String get yourProfilePicture => 'Ihr Profilbild';

  @override
  String get assistantAvatarLabel => 'Assistent-Avatar';

  @override
  String get aiAssistantPicture => 'KI-Assistent-Bild';

  @override
  String get chatBehaviorSection => 'CHAT-VERHALTEN';

  @override
  String get fontSizeLabel => 'Schriftgröße';

  @override
  String get iconSizeLabel => 'Symbolgröße';

  @override
  String pointsValue(int value) {
    return '${value}pt';
  }

  @override
  String get previewLabel => 'Vorschau';

  @override
  String get previewAssistantMessage =>
      'Hallo! Ich bin dein KI-Assistent. Wie kann ich dir heute helfen? Hier ist ein **fettes** Wort und etwas `Inline-Code`.';

  @override
  String get readAloud => 'Vorlesen';

  @override
  String appearanceActionTapped(String label) {
    return '$label angetippt';
  }

  @override
  String get autoScrollStreaming => 'Auto-Scrollen beim Streaming';

  @override
  String get autoScrollStreamingSubtitle =>
      'Automatisch zu neuen Nachrichten scrollen';

  @override
  String get showChatStarters => 'Vorschläge für neue Chats';

  @override
  String get showChatStartersSubtitle =>
      'Scrollende Prompt-Pills in leeren Chats anzeigen';

  @override
  String get useLegacyComposer => 'Klassisches Nachrichtenfeld';

  @override
  String get useLegacyComposerSubtitle =>
      'Das klassische kompakte Eingabefeld statt dem neuen Shine-Composer verwenden';

  @override
  String get hideAvatarsLabel => 'Avatare ausblenden';

  @override
  String get moreSpaceForContent => 'Mehr Platz für Nachrichteninhalte';

  @override
  String get enterKeyBehaviorLabel => 'Verhalten der Return-/Enter-Taste';

  @override
  String get enterKeyAutoDescription =>
      'Auf Hardware-Tastaturen senden, auf Bildschirmtastaturen neue Zeile einfügen';

  @override
  String get enterKeySendDescription =>
      'Enter sendet die Nachricht (Umschalt+Enter für neue Zeile)';

  @override
  String get enterKeyNewlineDescription =>
      'Enter fügt immer eine neue Zeile ein';

  @override
  String get sendLabel => 'Senden';

  @override
  String get newLineLabel => 'Neue Zeile';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get backLabel => 'Zurück';

  @override
  String get nextLabel => 'Weiter';

  @override
  String get getStartedLabel => 'Loslegen';

  @override
  String get connectionSuccessful => 'Verbindung erfolgreich!';

  @override
  String get connectionFailedMessage => 'Verbindung fehlgeschlagen';

  @override
  String get lmStudioServerFoundNeedsKey =>
      'Server gefunden! API-Schlüssel oben eintragen und dann Verbindung testen tippen.';

  @override
  String get lmStudioScanServerNeedsKey =>
      'Gefunden — API-Schlüssel zum Verbinden hinzufügen';

  @override
  String lmStudioUsingServerNeedsKey(String url) {
    return 'Verwende $url. API-Schlüssel unten eintragen und die Verbindung testen.';
  }

  @override
  String get lmStudioAuthDialogTitle => 'Server gefunden';

  @override
  String get lmStudioAuthDialogMessage =>
      'Dieser Server erfordert einen API-Schlüssel. Füge unten deinen LM-Studio-Token ein, um dich zu verbinden.';

  @override
  String get lmStudioAuthHelpHint =>
      'In LM Studio: Entwicklermodus → Servereinstellungen → Tokens verwalten, um deinen API-Schlüssel zu erstellen oder zu kopieren.';

  @override
  String get welcomeWizardTitle => 'Willkommen bei LM Mini';

  @override
  String get welcomeWizardSubtitle =>
      'Chatte mit KI-Modellen, die über LM Studio in deinem lokalen Netzwerk laufen. Lass uns alles in ein paar schnellen Schritten einrichten.';

  @override
  String get welcomeWizardThemeTitle => 'Wähle dein Design';

  @override
  String get welcomeWizardThemeSystemSubtitle =>
      'An die Geräteeinstellungen anpassen';

  @override
  String get welcomeWizardThemeLightSubtitle => 'Klar und hell';

  @override
  String get welcomeWizardThemeDarkSubtitle => 'Angenehm für die Augen';

  @override
  String get welcomeWizardAppearanceTitle => 'Erscheinungsbild anpassen';

  @override
  String get welcomeWizardAppearancePreviewMessage =>
      'Hallo! So werden deine Chat-Nachrichten aussehen.';

  @override
  String get welcomeWizardServerTitle => 'Mit LM Studio verbinden';

  @override
  String get welcomeWizardServerSubtitle =>
      'Gib die IP-Adresse des Computers ein, auf dem LM Studio in deinem lokalen Netzwerk läuft.';

  @override
  String get welcomeWizardLocalNetworkNote =>
      'iOS fragt beim Testen der Verbindung nach der Berechtigung für das lokale Netzwerk. Bitte erlaube sie.';

  @override
  String get apiTokenOptionalLabel => 'API-Token (optional)';

  @override
  String get welcomeWizardChangeLater =>
      'Du kannst das später jederzeit in den Einstellungen ändern.';

  @override
  String get welcomeWizardFindModelTitle => 'Passendes Modell finden';

  @override
  String get welcomeWizardFindModelSubtitle =>
      'Lass zwei Optionen gegeneinander antreten und sieh, welches auf deinem Setup schneller ist. Dauert etwa eine Minute — oder überspringe, wenn du schon weißt, was du willst.';

  @override
  String get welcomeWizardFindModelHelp => 'Hilf mir auswählen';

  @override
  String get welcomeWizardFindModelSkip => 'Überspringen — ich wähle selbst';

  @override
  String get welcomeWizardExperienceTitle => 'How do you use AI?';

  @override
  String get welcomeWizardExperienceSubtitle =>
      'We\'ll tailor recommendations. You can change everything later.';

  @override
  String get welcomeWizardBeginnerTitle => 'Beginner';

  @override
  String get welcomeWizardBeginnerSubtitle =>
      'Einfach halten — klarere Einstellungen, und wir schlagen ein gutes Modell vor.';

  @override
  String get welcomeWizardPowerTitle => 'Power user';

  @override
  String get welcomeWizardPowerSubtitle =>
      'Volle Einstellungen plus Auswahl — On-Device-Modelle und Desktop-Server wie LM Studio.';

  @override
  String get welcomeWizardSetupTitleBeginner => 'Modell wählen';

  @override
  String get welcomeWizardSetupTitlePower => 'Choose your setup';

  @override
  String get welcomeWizardSetupSubtitleBeginner =>
      'Tippe auf ein Modell zum Laden. Oder verbinde einen Computer im WLAN.';

  @override
  String get welcomeWizardSetupSubtitlePower =>
      'Pick a model or connect a desktop server.';

  @override
  String get welcomeWizardOnDeviceSection => 'On this device';

  @override
  String get welcomeWizardComputerSection => 'On your computer';

  @override
  String get welcomeWizardScanningWifi => 'Looking on Wi‑Fi…';

  @override
  String welcomeWizardFoundCount(int count) {
    return 'Found $count';
  }

  @override
  String get welcomeWizardModelFasterBlurb =>
      'Quick replies. Great for everyday chat.';

  @override
  String get welcomeWizardModelBalancedBlurb =>
      'Good balance of speed and quality.';

  @override
  String get welcomeWizardModelBestBlurb =>
      'Strongest quality that fits your device.';

  @override
  String get welcomeWizardNameTitle => 'What should AI call you?';

  @override
  String get welcomeWizardNameSubtitle =>
      'A first name or nickname is perfect. You can skip this.';

  @override
  String get welcomeWizardNameHint => 'e.g. Alex';

  @override
  String get welcomeWizardFinish => 'Finish';

  @override
  String get welcomeWizardContinue => 'Continue';

  @override
  String get welcomeWizardSkip => 'Skip';

  @override
  String get welcomeWizardConnectLmStudio => 'Connect LM Studio';

  @override
  String get welcomeWizardConnectOllama => 'Connect Ollama';

  @override
  String get welcomeWizardConnectOmlx => 'Connect oMLX';

  @override
  String get pickColor => 'Farbe wählen';

  @override
  String get hueLabel => 'Farbton';

  @override
  String get saturationLabel => 'Sättigung';

  @override
  String get lightnessLabel => 'Helligkeit';

  @override
  String get alphaLabel => 'Alpha';

  @override
  String get hexLabel => 'Hex';

  @override
  String get personaModeLabel => 'Persona-Modus';

  @override
  String get personaModeSubtitle =>
      'Avatar, Akzentfarbe, Stimme und bevorzugtes Modell für Gruppenchats hinzufügen';

  @override
  String get avatarLabel => 'Avatar';

  @override
  String get customAvatarSet => 'Benutzerdefinierter Avatar gesetzt';

  @override
  String get noAvatar => 'Kein Avatar';

  @override
  String get accentColorLabel => 'Akzentfarbe';

  @override
  String get defaultLabel => 'Standard';

  @override
  String get preferredModelLabel => 'Bevorzugtes Modell';

  @override
  String get preferredModelAny => 'Keines (beliebiges verwenden)';

  @override
  String get personaChooseProviderTitle => 'Anbieter wählen';

  @override
  String get personaChooseProviderSubtitle =>
      'Deine eingerichteten Anbieter. Weitere in den Einstellungen hinzufügen.';

  @override
  String get personaCloudProvidersSection => 'Cloud-Anbieter';

  @override
  String get personaKokoroVoiceLabel => 'Kokoro-Stimme';

  @override
  String get personaKokoroVoiceSubtitle =>
      'Stimme, wenn diese Persona spricht (Voice-Chat / Vorlesen)';

  @override
  String get personaKokoroVoiceGlobal => 'Globale Stimmeinstellung verwenden';

  @override
  String get personaKokoroVoicePickerTitle => 'Persona-Stimme';

  @override
  String get personaKokoroSpeedLabel => 'Sprechgeschwindigkeit';

  @override
  String get personaKokoroSpeedGlobal => 'Globale Geschwindigkeit verwenden';

  @override
  String personaKokoroSpeedValue(String speed) {
    return '${speed}x';
  }

  @override
  String get voiceWhisperModelLabel => 'Whisper-Modell';

  @override
  String get voiceWhisperModelTapToChoose =>
      'Tippen, um Größe zu wählen und herunterzuladen';

  @override
  String get imageGenSeedLabel => 'Bildgenerierungs-Seed';

  @override
  String imageGenSeedFixed(int seed) {
    return 'Fester Seed: $seed';
  }

  @override
  String get imageGenSeedRandomGlobal =>
      'Zufällig (globale Einstellung verwenden)';

  @override
  String get personaComfyWorkflowLabel => 'ComfyUI-Workflow';

  @override
  String get personaComfyWorkflowUseGlobal => 'Globale Einstellung verwenden';

  @override
  String personaComfyWorkflowUnavailable(String path) {
    return '$path (derzeit nicht verfügbar)';
  }

  @override
  String get personaComfyWorkflowHelper =>
      'Wird verwendet, wenn der Bildgenerierungs-Anbieter ComfyUI ist. Bei „global“ gilt Einstellungen → Bildgenerierung.';

  @override
  String get personaComfyWorkflowNotComfy =>
      'Diese Zuweisung gilt nur, wenn ComfyUI der aktive Bildanbieter ist.';

  @override
  String get personaComfyWorkflowRefresh => 'Workflows aktualisieren';

  @override
  String get personaComfyWorkflowJsonLabel =>
      'Benutzerdefiniertes Workflow-JSON (optional)';

  @override
  String get personaComfyWorkflowJsonHint =>
      'Leer lassen für globalen / integrierten Workflow';

  @override
  String get personaComfyWorkflowJsonHelper =>
      'API-Format-Workflow einfügen. Unterstützt %PROMPT%, %LORA%, %LORA_WEIGHT% und andere Platzhalter.';

  @override
  String get personaComfyWorkflowJsonIgnored =>
      'Wird ignoriert, solange ein gespeicherter Workflow ausgewählt ist';

  @override
  String personaComfyWorkflowJsonActive(int count) {
    return 'Benutzerdefinierter Workflow ($count Zeichen)';
  }

  @override
  String get personaComfyWorkflowJsonClear => 'Löschen (global / Standard)';

  @override
  String get comfyUiDetails => 'ComfyUI-Details';

  @override
  String get comfyUiDetailsTitle => 'ComfyUI-Anfrage';

  @override
  String get comfyUiDetailsCopy => 'JSON kopieren';

  @override
  String get comfyUiDetailsCopied => 'In die Zwischenablage kopiert';

  @override
  String get resetToGlobal => 'Auf global zurücksetzen';

  @override
  String get setSeed => 'Seed festlegen';

  @override
  String get pickAccentColor => 'Akzentfarbe wählen';

  @override
  String get imageGenSeedDialogDescription =>
      'Lege einen festen Seed fest, damit diese Persona immer konsistente Bilder erzeugt. Für Zufall leer lassen.';

  @override
  String get seedValueLabel => 'Seed-Wert';

  @override
  String get seedValueHint => 'z. B. 42 (leer = zufällig)';

  @override
  String get setLabel => 'Festlegen';

  @override
  String get selectPreferredModelTitle => 'Bevorzugtes Modell auswählen';

  @override
  String get branchCreated => '🔀 Abzweigung erstellt';

  @override
  String get yamlFrontmatter => 'YAML-Frontmatter';

  @override
  String get markdownFormat => 'Markdown';

  @override
  String get localNetworkBlocked =>
      'Lokaler Netzwerkzugriff möglicherweise blockiert';

  @override
  String get localNetworkFix =>
      'Gehen Sie zu Einstellungen → LM Mini → Lokales Netzwerk und aktivieren Sie es.';

  @override
  String get openAppSettings => 'App-Einstellungen öffnen';

  @override
  String get memorySaved => 'Erinnerung gespeichert';

  @override
  String get proSearch => 'Pro-Suche';

  @override
  String get webSearchLabel => 'Websuche';

  @override
  String get readUrl => 'URL lesen';

  @override
  String get code => 'Code';

  @override
  String couldNotOpenFile(String error) {
    return 'Datei konnte nicht geöffnet werden: $error';
  }

  @override
  String get tapOpenExternal =>
      'Tippen Sie auf ‚Mit externer App öffnen\', um diese Datei anzuzeigen';

  @override
  String get proSearchEnabled => 'Pro-Suche aktiviert';

  @override
  String get proSearchDisabled => 'Pro-Suche deaktiviert';

  @override
  String get thinkingEnabled => 'Denken für diesen Chat ein';

  @override
  String get thinkingDisabled => 'Denken für diesen Chat aus';

  @override
  String get codeSandbox => 'Code-Sandbox';

  @override
  String get codeSandboxSubtitle =>
      'Python oder JavaScript in einer sicheren Sandbox ausführen';

  @override
  String get codeSandboxEnabled => 'Code-Sandbox aktiviert';

  @override
  String get codeSandboxDisabled => 'Code-Sandbox deaktiviert';

  @override
  String get searxngNotConfigured => 'SearXNG-URL hinzufügen, um zu aktivieren';

  @override
  String get searxngConfiguredOff =>
      'Konfiguriert — tippen, um statt Pro-Suche zu nutzen';

  @override
  String get searxngConfigureFirst => 'SearXNG-URL zuerst konfigurieren';

  @override
  String get editSearxng => 'SearXNG bearbeiten';

  @override
  String get toolCallingLabel => 'Tool-Aufrufe';

  @override
  String get on => 'Ein';

  @override
  String get off => 'Aus';

  @override
  String get aiCanUseTools => 'KI kann in diesem Chat Tools verwenden';

  @override
  String get toolsDisabledChat => 'Tools für diesen Chat deaktiviert';

  @override
  String get webSearchChat => 'Websuche';

  @override
  String get aiCanSearchWeb => 'KI kann in diesem Chat das Web durchsuchen';

  @override
  String get webSearchDisabledChat => 'Websuche für diesen Chat deaktiviert';

  @override
  String get disableMemory => 'Gedächtnis deaktivieren';

  @override
  String memoryItemsActive(int count) {
    return '$count Gedächtniseinträge aktiv';
  }

  @override
  String get memoryDisabledChat =>
      'Gedächtnis ist für diesen Chat deaktiviert. Die KI sieht Ihre gespeicherten Einträge nicht.';

  @override
  String get lmStudioLocal => 'LM Studio (Lokal)';

  @override
  String get modelNoLongerAvailable =>
      'Das zuvor gewählte Modell ist nicht mehr verfügbar. Bitte wählen Sie ein neues Modell.';

  @override
  String get noModelsForProvider =>
      'Keine Modelle für diesen Anbieter gefunden. API-Schlüssel prüfen.';

  @override
  String get noModelsCheckConnection =>
      'Keine Modelle gefunden. LM Studio-Verbindung prüfen.';

  @override
  String get selectModel => 'Modell auswählen';

  @override
  String get goToModels => 'Zu Modellen';

  @override
  String get reviewImagePrompt => 'Bild-Prompt überprüfen';

  @override
  String get editImagePromptHint => 'Bild-Prompt bearbeiten...';

  @override
  String get generate => 'Generieren';

  @override
  String get imageNotFound => 'Bild nicht gefunden';

  @override
  String get cameraPermissionNeeded => 'Kamera-Berechtigung erforderlich';

  @override
  String get cameraPermissionExplain =>
      'Bitte erlauben Sie den Kamerazugriff, um Fotos für die Bildanalyse aufzunehmen.';

  @override
  String get photosPermissionNeeded => 'Fotos-Berechtigung erforderlich';

  @override
  String get photosPermissionExplain =>
      'Bitte erlauben Sie den Zugriff auf Ihre Bilder für die Bildanalyse.';

  @override
  String couldNotOpenFilePicker(String error) {
    return 'Dateiauswahl konnte nicht geöffnet werden: $error';
  }

  @override
  String get filePickerCouldNotCopy =>
      'Diese Datei ließ sich nicht kopieren. Speichere sie auf dem Telefon (nicht Drive oder Zuletzt) und wähle sie erneut.';

  @override
  String get signInToUseCloudBackup => 'Anmelden, um Cloud-Backup zu nutzen';

  @override
  String get cloudBackupRequiresAccount =>
      'Cloud-Backup erfordert ein Konto, damit Ihre verschlüsselten Backups sicher unter Ihrer Identität gespeichert werden.';

  @override
  String get arguments => 'Argumente';

  @override
  String get selectLanguage => 'Sprache auswählen';

  @override
  String get connectionPopupTitle => 'Nicht verbunden';

  @override
  String get connectionPopupBody =>
      'LM Mini konnte LM Studio nicht erreichen.\nGehe zu den Einstellungen, um deine Serveradresse einzugeben.';

  @override
  String get connectionPopupDismiss => 'Später';

  @override
  String get connectionPopupGoToSettings => 'Zu den Einstellungen';

  @override
  String get remoteAccess => 'Fernzugriff';

  @override
  String get scanQrCode => 'QR-Code scannen';

  @override
  String get connectedViaLmConnect => 'Verbunden über LM Connect';

  @override
  String get disconnectRemoteToChangeSettings =>
      'LM Studio ist per LM Connect gekoppelt';

  @override
  String get disconnect => 'Trennen';

  @override
  String get unpair => 'Entkoppeln';

  @override
  String get useRemoteConnection => 'Mit diesem Mac chatten';

  @override
  String get useRemoteConnectionOffSubtitle =>
      'Aus — dieses Telefon nutzt eigene Modelle. Einschalten, um Modelle auf LM Mini Home zu verwenden.';

  @override
  String get connectedViaLmStudio => 'Verbunden über LM Studio';

  @override
  String get usingLocalServer => 'Lokaler Server wird verwendet';

  @override
  String get testing => 'Test läuft...';

  @override
  String connectedLatency(int ms) {
    return 'Verbunden — ${ms}ms';
  }

  @override
  String get notConnected => 'Nicht verbunden';

  @override
  String get scanQrDescription =>
      'Scanne einen QR-Code aus der LM Mini Connect Desktop-App, um von überall auf dein LM Studio zuzugreifen.';

  @override
  String get remotePaired => 'Fernzugriff gekoppelt';

  @override
  String lastConnected(String time) {
    return 'Letzte Verbindung: $time';
  }

  @override
  String get reScanQrCode => 'QR-Code erneut scannen';

  @override
  String get qrRequiresPro => 'QR-Code scannen erfordert LM Mini Pro';

  @override
  String get enterUrlManually => 'URL manuell eingeben';

  @override
  String get enterUrlManuallySubtitle =>
      'Füge einen Pairing-Link ein, wenn die Kamera nicht verfügbar ist';

  @override
  String get relayUrlHint => 'https://relay.lmmini.com/s/…';

  @override
  String get connectWithUrl => 'Mit URL verbinden';

  @override
  String get invalidRelayUrl =>
      'Das ist kein gültiger LM Mini Pairing-Link. Kopiere ihn unter „Mit dem Telefon teilen“ auf dem Mac.';

  @override
  String get invalidQrCode =>
      'Ungültiger QR-Code. Verwende die LM Mini Connect App, um einen zu generieren.';

  @override
  String get pointCameraAtQr =>
      'Richte deine Kamera auf den QR-Code in der LM Mini Connect Desktop-App';

  @override
  String get connectedToRemoteLmStudio => 'Mit Remote-LM Studio verbunden!';

  @override
  String get failedToConnect =>
      'Verbindung fehlgeschlagen. Stelle sicher, dass LM Mini Connect läuft.';

  @override
  String get unpairRemote => 'Fernzugriff entkoppeln';

  @override
  String get unpairRemoteDescription =>
      'Dadurch wird die gespeicherte Fernverbindung entfernt. Du kannst dich erneut koppeln, indem du einen neuen QR-Code scannst.';

  @override
  String get setupGuide => 'Einrichtungshilfe';

  @override
  String get downloadLmMiniConnect => 'LM Mini Home holen';

  @override
  String get availableForPlatforms =>
      'Direkt-Download für Mac · Connect für Windows und Linux';

  @override
  String get setupStep1Title => 'LM Mini Home herunterladen';

  @override
  String get setupStep1Desc =>
      'LM Mini Home für Mac von lmmini.com laden. Unter Windows und Linux kannst du weiterhin LM Mini Connect nutzen.';

  @override
  String get setupStep2Title => 'Mit dem Telefon teilen';

  @override
  String get setupStep2Desc =>
      'Öffne in LM Mini Home auf dem Mac „Mit dem Telefon teilen“ und schalte es ein. Die Verbindung zum Relay steht sofort.';

  @override
  String get setupStep3Title => 'QR-Code scannen';

  @override
  String get setupStep3Desc =>
      'Scanne den QR-Code, den LM Mini Home auf dem Mac anzeigt. Das war\'s!';

  @override
  String minutesAgo(int count) {
    return 'vor ${count}min';
  }

  @override
  String hoursAgo(int count) {
    return 'vor ${count}h';
  }

  @override
  String daysAgo(int count) {
    return 'vor ${count}T';
  }

  @override
  String get selectAll => 'Alle auswählen';

  @override
  String get moveToFolder => 'In Ordner verschieben';

  @override
  String get select => 'Auswählen';

  @override
  String get dismissAction => 'Verwerfen';

  @override
  String get createNewFolder => 'Neuen Ordner erstellen';

  @override
  String deleteConversations(int count) {
    return '$count Unterhaltung(en) löschen? Dies kann nicht rückgängig gemacht werden.';
  }

  @override
  String get averages => 'DURCHSCHNITTE';

  @override
  String get tokensPerChat => 'Tokens / Chat';

  @override
  String get msgsPerChat => 'Nachr. / Chat';

  @override
  String get tokensPerMsg => 'Tokens / Nachr.';

  @override
  String get topModel => 'Top-Modell';

  @override
  String get liveActivityTitle => 'Live-Aktivität';

  @override
  String get liveActivityTitleAndroid => 'Hintergrundgenerierung';

  @override
  String get liveActivityDescription =>
      'Verarbeite deine KI-Anfrage auch wenn du die App verlässt oder sperrst';

  @override
  String get liveActivityDescriptionAndroid =>
      'Generierung läuft weiter, wenn du die App verlässt. Fortschritt in einer dauerhaften Benachrichtigung; Android beendet das Modell nicht mitten in der Antwort.';

  @override
  String get liveActivityAndroidOnDeviceOnly =>
      'Wechsle zu einem On-Device-GGUF- oder MLX-Modell, um Hintergrundgenerierung unter Android zu nutzen.';

  @override
  String get liveActivityNotificationDenied =>
      'Benachrichtigungsberechtigung ist für Hintergrundgenerierung auf Android erforderlich.';

  @override
  String get premiumRemoteAccess => 'Fernzugriff';

  @override
  String get premiumRemoteAccessTagline => 'LM Studio von überall';

  @override
  String get premiumRemoteAccessDescription =>
      'Greife von überall auf dein lokales LM Studio zu mit LM Mini Connect. Kein Port-Forwarding oder VPN nötig — einfach QR-Code scannen und sicher über einen verschlüsselten Relay verbinden.';

  @override
  String get premiumLiveActivity => 'Live-Aktivität';

  @override
  String get premiumLiveActivityTagline => 'KI arbeitet im Hintergrund';

  @override
  String get premiumLiveActivityDescription =>
      'Verarbeite deine KI-Anfrage auch wenn du die App verlässt oder das Telefon sperrst. Sieh den Echtzeit-Generierungsfortschritt auf deinem Sperrbildschirm und der Dynamic Island.';

  @override
  String get premiumWebSearchTagline => 'Keine Servereinrichtung erforderlich';

  @override
  String get premiumWebSearchDescription =>
      'Durchsuche das Web sofort während Unterhaltungen. Betrieben von Cloud-Such-APIs — kein SearXNG-Hosting oder Konfiguration nötig.';

  @override
  String get premiumCloudBackup => 'Verschlüsseltes Cloud-Backup';

  @override
  String get premiumCloudBackupTagline => 'AES-256-GCM Verschlüsselung';

  @override
  String get premiumCloudBackupDescription =>
      'Sichere alle Unterhaltungen in der Cloud mit militärischer Verschlüsselung. Dein Passwort verlässt nie dein Gerät.';

  @override
  String get premiumUrlReader => 'URL-Reader';

  @override
  String get premiumUrlReaderTagline => 'Jede Webseite analysieren';

  @override
  String get premiumUrlReaderDescription =>
      'Füge eine URL ein und dein Modell liest den gesamten Seiteninhalt. Artikel zusammenfassen, Dokumentation analysieren, Daten extrahieren.';

  @override
  String get premiumBranching => 'Unterhaltungsverzweigung';

  @override
  String get premiumBranchingTagline => 'Alternative Pfade erkunden';

  @override
  String get premiumBranchingDescription =>
      'Spalte jede Unterhaltung ab jedem Punkt, um ‚Was wäre wenn\'-Szenarien zu erkunden.';

  @override
  String get premiumMemory => 'Erinnerungen';

  @override
  String get premiumMemoryTagline => 'Erinnert sich über Chats hinweg';

  @override
  String get premiumMemoryDescription =>
      'Speichere Fakten, Präferenzen und Kontext, die über alle Unterhaltungen bestehen bleiben.';

  @override
  String get premiumAnalytics => 'Analyse-Dashboard';

  @override
  String get premiumAnalyticsTagline => 'Kenne deine Nutzung';

  @override
  String get premiumAnalyticsDescription =>
      'Verfolge verwendete Tokens, gesendete Nachrichten, Modellnutzung und durchschnittliche Antwortzeiten.';

  @override
  String get premiumCloudApi => 'Cloud-API-Anbieter';

  @override
  String get premiumCloudApiTagline => 'Mistral, Anthropic & mehr';

  @override
  String get premiumCloudApiDescription =>
      'Verbinde Cloud-LLM-Anbieter neben deinen lokalen Modellen.';

  @override
  String get premiumExport => 'Export & Teilen';

  @override
  String get premiumExportTagline => 'Obsidian, Notizen, Notion & mehr';

  @override
  String get premiumExportDescription =>
      'Exportiere Unterhaltungen als formatiertes Markdown, PDF oder Klartext.';

  @override
  String get premiumCompactContext => 'Compact context';

  @override
  String get premiumCompactContextTagline =>
      'Keep chatting when the window is full';

  @override
  String get premiumCompactContextDescription =>
      'Roll older messages, cut the middle, or compact a long chat into a summary on the same loaded model so a full context window doesn’t stop the conversation.';

  @override
  String get premiumParamPresets => 'Param presets';

  @override
  String get premiumParamPresetsTagline =>
      'Per-model and persona generation settings';

  @override
  String get premiumParamPresetsDescription =>
      'Save sampler and load settings per model, and optional custom params on a persona. Free stays on the Global defaults that ship with the app.';

  @override
  String get paramPresetSetFor => 'Set params for';

  @override
  String get paramPresetGlobalTab => 'Global';

  @override
  String get paramPresetScopeHelpTitle => 'How params apply';

  @override
  String get paramPresetScopeHelpIntro =>
      'The most specific layer that is on wins. Chat-level overrides (if you set them in a conversation) still sit on top.';

  @override
  String get paramPresetScopeHelpGlobal =>
      'Defaults for every model that does not have its own preset. This is what the app ships with.';

  @override
  String get paramPresetScopeHelpModel =>
      'Changing knobs on the selected-model tab saves a preset for that model only. Use Global params removes it so the model follows Global again.';

  @override
  String get paramPresetScopeHelpPersonaTitle => 'Persona';

  @override
  String get paramPresetScopeHelpPersona =>
      'If a persona has a preferred model, turn on Use custom params to override that model’s preset (or Global) while the persona is active.';

  @override
  String get paramPresetSelectedModelTab => 'Selected model';

  @override
  String get paramPresetNoModel => 'Select a model to save a preset for it.';

  @override
  String get paramPresetUsingGlobal => 'This model uses Global params.';

  @override
  String get paramPresetUsingCustom => 'This model has a custom preset.';

  @override
  String get paramPresetUseGlobal => 'Use Global params';

  @override
  String get paramPresetUseGlobalSubtitle =>
      'Remove this model’s preset and fall back to Global.';

  @override
  String get paramPresetModelLocked =>
      'Model presets are Pro. Global params still apply to every model.';

  @override
  String get personaUseCustomParams => 'Use custom params';

  @override
  String get personaUseCustomParamsSubtitle =>
      'Override this model’s params while the persona is active';

  @override
  String get personaAdjustParams => 'Adjust params';

  @override
  String get personaAdjustParamsSubtitle =>
      'Temperature, context, and other generation settings';

  @override
  String get premiumOnDeviceLlm => 'On-Device Pro';

  @override
  String get premiumOnDeviceLlmTagline => 'Größere Katalogmodelle & HF-Import';

  @override
  String get premiumOnDeviceLlmDescription =>
      'On-Device-Chat ist kostenlos mit kuratierten Startermodellen. Pro schaltet Katalog-Downloads über 2B Parameter frei und den Import eigener GGUF- oder MLX-Modelle von Hugging Face — vollständig offline.';

  @override
  String get premiumHfBrowse => 'Hugging-Face-Import';

  @override
  String get premiumHfBrowseTagline => 'Beliebige GGUF-Modelle mitbringen';

  @override
  String get premiumHfBrowseDescription =>
      'Durchsuche Hugging Face, lade GGUF-Modelle auf dein Gerät oder LM Studio und nutze sie in LM Mini. Filtere nach Kompatibilität, verfolge Hintergrund-Downloads und gehe über den kostenlosen Katalog hinaus — ohne API-Schlüssel.';

  @override
  String get onDeviceProviderLabel => 'Auf dem Gerät';

  @override
  String get onDeviceManageModels => 'Modelle auf dem Gerät verwalten';

  @override
  String get onDeviceGeneratingHint => 'Generiere auf dem Gerät…';

  @override
  String get onDeviceEngineUnavailable => 'On-Device-Engine nicht verfügbar';

  @override
  String get onDeviceOpenBrowser => 'On-Device-Modelle öffnen';

  @override
  String get onDeviceManagedHere =>
      'On-Device-Modelle werden in einem eigenen Browser verwaltet, in dem du sie herunterladen, entfernen und aktivieren kannst.';

  @override
  String get onDeviceRemoteImageOnly =>
      'On-Device AI ist aktiv — Fernzugriff dient nur der Bildgenerierung und Kokoro-Stimme (falls konfiguriert). Der Chat bleibt auf diesem Gerät.';

  @override
  String get onDeviceProOnly => 'Nur Pro';

  @override
  String get onDeviceInstalled => 'Installiert';

  @override
  String get onDeviceUseModel => 'Verwenden';

  @override
  String get onDeviceRemoveModel => 'Entfernen';

  @override
  String get onDeviceDownloadAnyway => 'Trotzdem herunterladen';

  @override
  String onDeviceNowUsing(String name) {
    return 'Verwende jetzt $name auf dem Gerät';
  }

  @override
  String get onDeviceEngineFllamaLabel => 'fllama (GGUF)';

  @override
  String onDeviceEngineSwitched(String engine) {
    return 'Zu $engine gewechselt. Das vorherige Modell wurde entladen.';
  }

  @override
  String onDeviceEngineSwitchedCleared(String engine) {
    return 'Zu $engine gewechselt. Das vorherige Modell ist nicht kompatibel und wurde abgewählt — wähle ein Modell unter On-Device-Modelle.';
  }

  @override
  String get onDeviceImportedLabel => 'Importiert';

  @override
  String get onDeviceFreeLabel => 'Kostenlos';

  @override
  String get onDeviceProLabel => 'Pro';

  @override
  String get onDeviceMayCrashLabel => 'Kann abstürzen';

  @override
  String get onDeviceModelMayCrashTitle => 'Dieses Modell kann abstürzen';

  @override
  String onDeviceModelMayCrashMessage(
      String name, String runtimeGb, String deviceRamGb) {
    return '$name benötigt zur Laufzeit etwa $runtimeGb GB Speicher. Dein Gerät hat etwa $deviceRamGb GB für Apps verfügbar. Das Laden kann die App einfrieren oder zum Absturz bringen.';
  }

  @override
  String get onDeviceContinueLoading => 'Trotzdem laden';

  @override
  String get yearly => 'Jährlich';

  @override
  String get monthly => 'Monatlich';

  @override
  String get lifetime => 'Lebenslang';

  @override
  String get subscriptionLifetimeBadge => 'Einmal zahlen';

  @override
  String get subscriptionLifetimeDisclaimer =>
      'Einmaliger Kauf. Pro-Funktionen auf deinem Konto, solange LM Mini angeboten und gepflegt wird. Ausgenommen sind Gebühren für Drittanbieter-APIs und ggf. separat gehostete Dienste — siehe AGB.';

  @override
  String subscriptionLifetimeUpgradeDisclaimer(String store) {
    return 'Lifetime ist ein separater Einmalkauf. Dein aktuelles Abo wird nicht automatisch gekündigt, und wir können vergangene Abogebühren nicht erstatten. Kündige dein Abo nach dem Kauf im $store.';
  }

  @override
  String get subscriptionUpgradeToLifetime => 'Auf Lifetime upgraden';

  @override
  String subscriptionUpgradeToLifetimeSubtitle(String price) {
    return 'Einmal zahlen — $price';
  }

  @override
  String get duplicateSubscriptionDialogTitle => 'Abo kündigen';

  @override
  String duplicateSubscriptionDialogBody(String store) {
    return 'Du hast Lifetime Pro und ein aktives Abo. Lifetime ersetzt dein Abo nicht automatisch, und wir können Abogebühren nicht erstatten. Bitte kündige dein Abo im $store, um weitere Abbuchungen zu vermeiden.';
  }

  @override
  String duplicateSubscriptionDialogManage(String store) {
    return '$store öffnen';
  }

  @override
  String get duplicateSubscriptionDialogDismiss => 'Verstanden';

  @override
  String get duplicateSubscriptionNoManageUrl =>
      'Öffne die Abo-Einstellungen deines Geräts, um zu kündigen.';

  @override
  String supportLifetime(String price) {
    return 'Für immer freischalten — $price';
  }

  @override
  String get encryptionKey => 'Verschlüsselungsschlüssel';

  @override
  String get encryptionEnabled => 'Verschlüsselung: Ein';

  @override
  String get encryptionDisabled => 'Verschlüsselung: Aus';

  @override
  String get encryptionKeyDescription =>
      'Ende-zu-Ende-Verschlüsselungsschlüssel für Fernzugriff. Muss mit dem Schlüssel in LM Mini Connect übereinstimmen.';

  @override
  String get editEncryptionKey => 'Verschlüsselungsschlüssel bearbeiten';

  @override
  String get enterEncryptionKey => 'Verschlüsselungsschlüssel eingeben';

  @override
  String get encryptionKeyUpdated => 'Verschlüsselungsschlüssel aktualisiert';

  @override
  String get keepLmMiniAlive => 'Halte LM Mini\nam Leben';

  @override
  String get supportTheApp => 'Unterstütze die App & erhalte Premium-Vorteile';

  @override
  String get mostFeaturesFree =>
      'Die meisten Funktionen sind kostenlos — Pro hilft bei den Serverkosten';

  @override
  String get thankYouSupport => 'Vielen Dank für deine Unterstützung!';

  @override
  String get helpingKeepAlive => 'Du hilfst, LM Mini am Leben zu halten';

  @override
  String get linkSignInMethod =>
      'Verknüpfe eine Anmeldemethode, um dein Abo beim Gerätewechsel zu behalten.';

  @override
  String get paywallLinkAccountBody =>
      'Du nutzt ein anonymes Konto. Verknüpfe Apple oder Google vor dem Kauf, damit Pro geräteübergreifend synchronisiert und Reinstallation überlebt.';

  @override
  String get continueAnonymously => 'Anonym fortfahren';

  @override
  String signedInViaMethod(String method) {
    return 'Angemeldet über $method';
  }

  @override
  String get yourSubscriptionSecured => 'Dein Abonnement ist gesichert';

  @override
  String subscriptionManagedThrough(String store) {
    return 'Abonnement verwaltet über den $store.';
  }

  @override
  String get subscriptionsComingSoon => 'Abonnements demnächst verfügbar';

  @override
  String get premiumPreview =>
      'Premium-Funktionen werden finalisiert.\nDu kannst unten den Entwicklermodus aktivieren, um sie vorab zu testen.';

  @override
  String get enableDeveloperPremium => 'Entwickler-Premium aktivieren';

  @override
  String get disableDeveloperPremium => 'Entwickler-Premium deaktivieren';

  @override
  String get premiumEnabled => 'Premium aktiviert (Entwickler-Override)';

  @override
  String get premiumDisabled => 'Premium deaktiviert';

  @override
  String supportYearly(String price) {
    return 'Unterstützen — $price/Jahr';
  }

  @override
  String supportMonthly(String price) {
    return 'Unterstützen — $price/Monat';
  }

  @override
  String get welcomeToLmMiniPro => 'Willkommen bei LM Mini Pro!';

  @override
  String get connectedRemotely => 'Remote verbunden';

  @override
  String get pairedNotActive => 'Gekoppelt — nicht aktiv';

  @override
  String get accessLmStudioAnywhere => 'Greife von überall auf LM Studio zu';

  @override
  String get appStore => 'App Store';

  @override
  String get googlePlayStore => 'Google Play Store';

  @override
  String get starterAttach => 'Anhang';

  @override
  String get starterImages => 'Bilder';

  @override
  String get starterMode => 'Modus';

  @override
  String get newGroupChat => 'Neuer Gruppenchat';

  @override
  String get groupChat => 'Gruppenchat';

  @override
  String get groupChatMultipleModels => 'Mit mehreren Modellen chatten';

  @override
  String get groupChatParticipants => 'Teilnehmer';

  @override
  String get groupChatTurnMode => 'Zugmodus';

  @override
  String get groupChatRoundRobin => 'Reihum';

  @override
  String get groupChatManual => 'Manuell';

  @override
  String get groupChatParallelStreaming => 'Paralleles Streaming';

  @override
  String get groupChatAutoLoadUnload => 'Automatisch laden/entladen';

  @override
  String get groupChatStreamAllSimultaneously =>
      'Alle Teilnehmer gleichzeitig streamen';

  @override
  String get groupChatAutoLoadModels => 'Modelle automatisch bei Bedarf laden';

  @override
  String get groupChatAsk => 'Fragen:';

  @override
  String get groupChatTapToReplyNudge => 'Tippe, wer antworten soll';

  @override
  String get groupChatTrialBannerTitle => 'Gruppen-Chat — 7 Tage kostenlos!';

  @override
  String get groupChatTrialBannerBody =>
      'Teste den Gruppen-Chat 7 Tage lang kostenlos mit bis zu 2 KI-Personas. Upgrade auf LM Mini Pro für unbegrenzte Teilnehmer.';

  @override
  String groupChatTrialDaysLeft(int days) {
    return 'Noch $days Tage im Test';
  }

  @override
  String get groupChatTrialExpired =>
      'Dein 7-tägiger Test für den Gruppen-Chat ist abgelaufen. Upgrade auf Pro, um fortzufahren.';

  @override
  String get groupChatTrialGetPro => 'Pro holen';

  @override
  String get groupChatTrialDismiss => 'Verstanden';

  @override
  String get groupChatBetaTitle => 'Group Chat (Beta)';

  @override
  String get groupChatBetaSubtitle => 'One conversation. Multiple AI minds.';

  @override
  String get groupChatBetaPremiumNote =>
      'Group Chat is currently in beta and not yet part of your Pro subscription.';

  @override
  String get groupChatBetaBugReport =>
      'Found a bug? Go to Settings -> Feature Requests & Support to report it.';

  @override
  String get groupChatBetaFreeNote =>
      'You have 7 days of free access with up to 2 personas.';

  @override
  String get groupChatBetaFeaturePersona =>
      'Each persona powered by its own model';

  @override
  String get groupChatBetaFeatureSystem =>
      'Unique personality per system prompt';

  @override
  String get groupChatBetaFeatureConvo => 'All in one shared conversation';

  @override
  String get groupChatBetaStartFree => 'Start Free Trial';

  @override
  String get groupChatBetaStartPremium => 'Try Group Chat';

  @override
  String get groupChatBetaLearnMore => 'Get Pro';

  @override
  String get premiumGroupChat => 'Gruppen-Chat';

  @override
  String get premiumGroupChatTagline => 'Mehrpersonengespräche';

  @override
  String get premiumGroupChatDescription =>
      'Chatte mit mehreren KI-Personas in einem Thread — jede mit eigenem Modell, Avatar und Persönlichkeit. Einrichtung ist kostenlos; Nachrichten senden erfordert LM Mini Pro.';

  @override
  String get groupChatProRequiredTitle => 'Gruppen-Chat erfordert Pro';

  @override
  String get groupChatProRequiredBody =>
      'Du kannst die Einrichtung erkunden und alte Chats lesen. Upgrade auf LM Mini Pro, um Nachrichten zu senden und mit mehreren KI-Personas weiterzuchatten.';

  @override
  String get groupChatProRequiredUpgrade => 'Auf Pro upgraden';

  @override
  String get groupChatLockedBanner =>
      'Gruppen-Chat ist ohne Pro schreibgeschützt. Upgrade, um neue Nachrichten zu senden.';

  @override
  String get premiumArena => 'Arena';

  @override
  String get premiumArenaTagline => 'Modelle nebeneinander vergleichen';

  @override
  String get premiumArenaDescription =>
      'Führe denselben Prompt durch mehrere Modelle und vergleiche Antworten, Geschwindigkeit und Geräte-Eignung. Der Benchmark-Modus bewertet Modelle mit einer transparenten Rubrik.';

  @override
  String get startLabel => 'Starten';

  @override
  String groupChatInviteUpTo(int count) {
    return 'Lade bis zu $count KI-Modelle ein, gemeinsam zu chatten. Jedes kann eine eigene Persona, einen eigenen Avatar und einen eigenen System-Prompt haben.';
  }

  @override
  String get groupChatPremiumParticipantsNote =>
      'Premium erlaubt bis zu 5 Teilnehmer pro Gruppenchat.';

  @override
  String get groupChatUserNameHint =>
      'Wie die KIs dich ansprechen sollen (z. B. Alex)';

  @override
  String get groupChatScenarioLabel => 'Szenario / über dich (optional)';

  @override
  String get groupChatScenarioHint =>
      'z. B. „Wir sind Kollegen in einem Tech-Startup. Ich bin Produktmanager und frage das Team um Rat.“';

  @override
  String get groupChatTurnModeRoundRobinDescription =>
      'Reihum: Alle Modelle antworten der Reihe nach';

  @override
  String get groupChatTurnModeManualDescription =>
      'Manuell: Tippe @Name, um auszuwählen, wer antwortet';

  @override
  String get groupChatReplyToUserOnlyLabel => 'Nur dem Nutzer antworten';

  @override
  String get groupChatReplyToUserOnlySubtitle =>
      'Jede KI ignoriert andere KIs, damit kleine Modelle nicht durcheinanderreden';

  @override
  String get groupChatWhosInChat => 'Who\'s in the chat?';

  @override
  String get groupChatTapToInvite => 'Tap people below to invite them';

  @override
  String get groupChatAddPeople => 'Add people';

  @override
  String get groupChatInTheRoom => 'In the room';

  @override
  String get groupChatNeedTwo => 'Add at least 2 to start';

  @override
  String get groupChatTakeTurnsTitle => 'Take turns';

  @override
  String get groupChatTakeTurnsSubtitle =>
      'Everyone answers in order, one after another';

  @override
  String get groupChatTalkMentionedTitle => 'Talk when mentioned';

  @override
  String get groupChatTalkMentionedSubtitle =>
      'If one AI names another, that person can jump in';

  @override
  String get groupChatIChooseTitle => 'I choose who speaks';

  @override
  String get groupChatIChooseSubtitle => 'Only the person you @mention replies';

  @override
  String get groupChatHowTheyTalk => 'How they talk';

  @override
  String get groupChatAboutYou => 'About you';

  @override
  String get groupChatSceneLabel => 'Scene (optional)';

  @override
  String get groupChatSceneHint =>
      'e.g. We\'re coworkers brainstorming a product idea';

  @override
  String get groupChatAutoLoadTitle => 'Save memory on local models';

  @override
  String get groupChatAutoLoadSubtitle =>
      'Unload one model before loading the next — helpful when people use different LM Studio, Ollama, or on-device models';

  @override
  String get groupChatMoreOptions => 'More options';

  @override
  String get groupChatHelpTooltip => 'How Group Chat works';

  @override
  String get groupChatHelpTitle => 'How Group Chat works';

  @override
  String get groupChatHelpIntro =>
      'Invite at least two AI people into one conversation. Each can use a different model and personality.';

  @override
  String get groupChatHelpTakeTurns =>
      'Take turns: every AI answers your message in order.';

  @override
  String get groupChatHelpMentioned =>
      'Talk when mentioned: after someone replies, another AI can continue if they were named.';

  @override
  String get groupChatHelpManual =>
      'I choose who speaks: use @Name so only that person replies.';

  @override
  String get groupChatHelpMemory =>
      'Save memory: for local models, unload the previous model before loading the next so phones and PCs with less RAM can still run a group.';

  @override
  String get groupChatHelpProvider =>
      'Tap a person in the room to change their provider and model anytime.';

  @override
  String get groupChatStartProGate => 'Pro needed to start';

  @override
  String get groupChatFixBeforeStart =>
      'Fix the highlighted people before starting.';

  @override
  String get groupChatEditPerson => 'Edit person';

  @override
  String get groupChatProviderAndModel => 'Provider & model';

  @override
  String get groupChatChooseProviderModel => 'Choose provider & model';

  @override
  String get groupChatParallelEasy => 'Reply at the same time';

  @override
  String get groupChatParallelEasySubtitle =>
      'When more than one AI should answer, stream them together';

  @override
  String get noModelsAvailableConnectLmStudio =>
      'Keine Modelle verfügbar. Verbinde dich zuerst mit LM Studio.';

  @override
  String get addModelLabel => 'Modell hinzufügen';

  @override
  String modelNumber(int number) {
    return 'Modell $number';
  }

  @override
  String groupChatParticipantInfo(String name, String model) {
    return '$name\nModell: $model';
  }

  @override
  String get customPromptSet => 'Benutzerdefinierter Prompt gesetzt';

  @override
  String get removeLabel => 'Entfernen';

  @override
  String get displayNameLabel => 'Anzeigename';

  @override
  String get displayNameHint => 'z. B. Professor, Entwickler, Künstler';

  @override
  String get customRequestHeaders => 'Eigene Anfrage-Header';

  @override
  String get customRequestHeadersSubtitle =>
      'Optionale Header, die jeder LM-Studio-Anfrage hinzugefügt werden';

  @override
  String get customRequestHeadersHelp =>
      'Verwende dies für Reverse-Proxys oder Auth-Gateways, die zusätzliche Header benötigen (z. B. Cloudflare Access Service-Tokens, ein internes Token unter einem benutzerdefinierten Header-Namen usw.). Header werden bei jeder Anfrage an deinen LM-Studio-Server gesendet.';

  @override
  String get cloudflareAccessSection => 'Cloudflare Access (Service-Token)';

  @override
  String get cloudflareAccessHelp =>
      'Wenn dein LM Studio hinter einer Cloudflare-Access-Richtlinie steht, füge hier die Client-ID und das Secret des Service-Tokens ein. Sie werden bei jeder Anfrage als CF-Access-Client-Id und CF-Access-Client-Secret gesendet, sodass sich die App ohne interaktive Browser-SSO-Anmeldung authentifizieren kann.';

  @override
  String get cfAccessClientIdLabel => 'CF-Access-Client-Id';

  @override
  String get cfAccessClientSecretLabel => 'CF-Access-Client-Secret';

  @override
  String get addHeader => 'Header hinzufügen';

  @override
  String get removeHeader => 'Header entfernen';

  @override
  String get headerNameLabel => 'Header-Name';

  @override
  String get headerValueLabel => 'Header-Wert';

  @override
  String headersConfigured(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Header konfiguriert',
      one: '1 Header konfiguriert',
    );
    return '$_temp0';
  }

  @override
  String get noCustomHeaders => 'Keine eigenen Header';

  @override
  String get comfyUiUseNegativePromptTitle => 'Negativen Prompt verwenden';

  @override
  String get comfyUiUseNegativePromptSubtitle =>
      'Standardmäßig aus für ComfyUI. Wenn aus, wird kein negativer Prompt an den Workflow gesendet.';

  @override
  String get documentationTitle => 'Dokumentation';

  @override
  String get documentationSubtitle =>
      'Einrichtungsanleitungen für Gruppen-Chat, ComfyUI, Tastaturverhalten und mehr';

  @override
  String get changelogTitle => 'Änderungsprotokoll';

  @override
  String get changelogSubtitle => 'Versionsverlauf & Updates';

  @override
  String get enableCustomHeaders => 'Eigene Header aktivieren';

  @override
  String get enableCustomHeadersSubtitle =>
      'Zusätzliche HTTP-Header an jede LM-Studio-Anfrage anhängen';

  @override
  String deleteMemoriesCount(int count) {
    return '$count Erinnerungen löschen?';
  }

  @override
  String get deleteMemoriesConfirm =>
      'Diese Erinnerungen werden endgültig entfernt.';

  @override
  String get moveToCategory => 'In Kategorie verschieben';

  @override
  String nSelected(int count) {
    return '$count ausgewählt';
  }

  @override
  String movedToCategory(String category) {
    return 'Verschoben nach $category';
  }

  @override
  String get moveCategoryTooltip => 'Kategorie verschieben';

  @override
  String get memoryScreenSubtitle =>
      'Fakten, die die KI über Chats hinweg über dich behält.';

  @override
  String get rememberMe => 'An mich erinnern';

  @override
  String get rememberMeSubtitle =>
      'Gespeicherte Notizen in zukünftigen Gesprächen nutzen';

  @override
  String get memoryPerPersona => 'Pro Persona';

  @override
  String get memoryPerPersonaSubtitle =>
      'Notizen nur für die aktive Persona teilen (und globale)';

  @override
  String get memoryOnDeviceExtraction => 'Learn memories on-device';

  @override
  String get memoryOnDeviceExtractionSubtitle =>
      'Let the local model extract facts too. Uses extra battery.';

  @override
  String get memoryScopeGlobal => 'Everyone';

  @override
  String get memoryScopeGlobalSubtitle => 'Available in every chat';

  @override
  String get memoryScopePrivate => 'Private to persona';

  @override
  String get memoryScopePrivateSubtitle =>
      'Facts about you that only this persona sees. It won\'t see your shared memories';

  @override
  String get memoryScopeLore => 'Character notes';

  @override
  String get memoryScopeLoreSubtitle =>
      'Roleplay details for this character, never treated as facts about you. It won\'t see your shared memories';

  @override
  String get memoryVisibility => 'Visibility';

  @override
  String get memoryChangeVisibility => 'Change visibility';

  @override
  String get memoryScopeFilterAll => 'All';

  @override
  String get memoryOrphaned => 'Orphaned';

  @override
  String get memoryOrphanedHint =>
      'These notes belong to a persona that no longer exists, so no chat can see them. Repair them to bring them back.';

  @override
  String get memoryMakeGlobal => 'Make available to everyone';

  @override
  String get memorySearchHint => 'Search notes';

  @override
  String memoryNoSearchResults(String query) {
    return 'No notes match \"$query\"';
  }

  @override
  String get memoryPickPersona => 'Choose a persona';

  @override
  String memoryMovedToScope(String scope) {
    return 'Moved to $scope';
  }

  @override
  String memoryCountForPersona(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count memories',
      one: '1 memory',
      zero: 'No memories',
    );
    return '$_temp0';
  }

  @override
  String get personaMemoryWriteScope => 'Save new memories as';

  @override
  String get personaMemoryWriteScopeSubtitle =>
      'Where facts learned in this persona\'s chats are filed';

  @override
  String get memoryBrowseSection => 'Durchsuchen';

  @override
  String get memoryMultiSelectTip =>
      'Tipp: Lange drücken, um mehrere Notizen auszuwählen.';

  @override
  String get memoryEmptyFilteredHint =>
      'Notiz hinzufügen oder andere Kategorie wählen.';

  @override
  String get memoryEmptyHint =>
      'Speichere ein paar Dinge über dich — Name, Vorlieben, Projekte — damit Chats persönlicher wirken.';

  @override
  String get memoryShareWith => 'Teilen mit';

  @override
  String get memoryEveryone => 'Alle';

  @override
  String get memoryEveryoneSubtitle => 'In jedem Chat verfügbar';

  @override
  String get memoryNoPersonasHint =>
      'Noch keine Personas. Erstelle eine unter Einstellungen → Personas.';

  @override
  String get memoryNewNote => 'Neue Notiz';

  @override
  String get memoryNoteHint =>
      'z. B. Ich mag kurze Antworten und wohne in Berlin';

  @override
  String get memoryEditNote => 'Notiz bearbeiten';

  @override
  String monthsAgo(int count) {
    return 'vor $count Mon.';
  }

  @override
  String get moreTooltip => 'Mehr';

  @override
  String get closeSearch => 'Suche schließen';

  @override
  String get moveTooltip => 'Verschieben';

  @override
  String get chatsTab => 'Chats';

  @override
  String get groupsTab => 'Gruppen';

  @override
  String get foldersTooltip => 'Ordner';

  @override
  String get newFolder => 'Neuer Ordner';

  @override
  String get tapToReturnToCall => 'Tippen, um zum Anruf zurückzukehren';

  @override
  String get selectConversation => 'Unterhaltung auswählen';

  @override
  String get selectConversationHint =>
      'Wähle eine aus der Liste oder starte einen neuen Chat.';

  @override
  String get noGroupChatsYet => 'Noch keine Gruppenchats';

  @override
  String get noGroupChatsSubtitle =>
      'Starte eine Multi-Persona-Unterhaltung, um mit mehreren KIs zu chatten.';

  @override
  String get newPersonaShort => 'Neu';

  @override
  String get downloadOnDeviceModelTitle => 'On-Device-Modell herunterladen';

  @override
  String get downloadOnDeviceModelBody =>
      'Lade ein Modell herunter, um ohne PC zu chatten, oder verbinde LM Studio / Ollama.';

  @override
  String get browseModels => 'Modelle durchsuchen';

  @override
  String get waitingForMac => 'Warte auf Mac';

  @override
  String get waitingForMacBody =>
      'Verbinde dein iPhone per USB mit dem Mac und öffne LM Mini Connect auf dem Mac.';

  @override
  String get arenaMode => 'Arena-Modus';

  @override
  String get voiceWhisperSizeInfoTitle => 'Größere Modelle hören besser';

  @override
  String get voiceWhisperSizeInfoBody =>
      'Größere Hör-Modelle sind meist genauer, besonders bei Akzenten und Hintergrundgeräuschen. Sie brauchen mehr Speicher und laden etwas langsamer.';

  @override
  String get voiceRemoveListeningModelTitle => 'Hör-Modell entfernen?';

  @override
  String get voiceRemoveListeningModelBody =>
      'Das gibt Speicher frei. Voice Call und das Mikrofon brauchen das Modell erneut für Offline-Erkennung.';

  @override
  String get voiceTtsOnDeviceNeural => 'Heruntergeladene Stimme';

  @override
  String get voiceTtsPcVoice => 'PC-Stimme';

  @override
  String get voiceTtsSystemVoice => 'Systemstimme';

  @override
  String get voiceTtsOnDeviceHint =>
      'Natürliche Stimmen zum Download. Funktioniert ohne Internet.';

  @override
  String get voiceTtsPcHint =>
      'Stimmenmodell auf dem Computer über „Mit Telefon teilen“';

  @override
  String get voiceTtsSystemHint =>
      'Die Stimmen deines Telefons — sofort bereit';

  @override
  String get voiceSttOnDevice => 'Auf diesem Gerät';

  @override
  String get voiceSttWhisperHint => 'Offline-Modell — meist genauer';

  @override
  String get voiceSttSystemHint => 'Eingebaute Erkennung — schnell und einfach';

  @override
  String get voiceSttSystemUnavailableOnMac => 'Download nötig';

  @override
  String get voiceSttMacosRequiresWhisper =>
      'App-Store-Builds nutzen fürs Zuhören on-device Whisper. Lade ein Modell herunter, um es zu aktivieren.';

  @override
  String get voiceSttMacosSystemOptionSubtitle =>
      'Whisper herunterladen, um Zuhören zu aktivieren';

  @override
  String get voiceSttMacosDownloadWhisper =>
      'Whisper herunterladen, um Zuhören zu aktivieren';

  @override
  String get voiceSettingsIntro =>
      'Wie Antworten gesprochen und deine Stimme verstanden wird.';

  @override
  String get voiceSectionReady => 'Bereit';

  @override
  String get voiceSectionSpeaking => 'Sprechen';

  @override
  String get voiceSectionListening => 'Zuhören';

  @override
  String get voiceSectionConversation => 'Gespräch';

  @override
  String get voiceStatusSpeaking => 'Sprechen';

  @override
  String get voiceStatusListening => 'Zuhören';

  @override
  String get voiceHowISpeak => 'Wie ich spreche';

  @override
  String get voiceImportPack => 'Stimmenpaket importieren';

  @override
  String get voiceImportPackSubtitle =>
      'GitHub-URL zu einem Stimmenpaket einfügen';

  @override
  String get voiceHowIHearYou => 'Wie ich dich höre';

  @override
  String get voiceHowIHearYouSubtitle =>
      'Wähle, wie deine Sprache in Text umgewandelt wird.';

  @override
  String get voiceListeningModel => 'Hör-Modell';

  @override
  String get voiceAboutModelSizes => 'Über Modellgrößen';

  @override
  String get voicePauseBeforeSend => 'Pause vor dem Senden';

  @override
  String get voicePauseBeforeSendSubtitle =>
      'Wartezeit, nachdem du aufgehört hast zu sprechen';

  @override
  String get voiceListeningLimit => 'Zuhör-Limit';

  @override
  String get voiceListeningLimitSubtitle =>
      'Längste Spanne, bevor das Mikrofon neu startet';

  @override
  String get voiceQuickTip => 'Kurzer Tipp';

  @override
  String get voiceQuickTipBody =>
      'Für eine natürlichere Stimme lade unter Sprachpakete eine Sprache herunter. Die Systemstimme funktioniert sofort.';

  @override
  String get voiceTestSampleHint =>
      'Kurze Probe mit deinen aktuellen Einstellungen hören';

  @override
  String get voiceTestNoPackReady =>
      'Lade unter Sprachpakete eine Sprache herunter und versuche dann Test Voice.';

  @override
  String get voiceChooseListeningModel => 'Tippen, um ein Hör-Modell zu wählen';

  @override
  String get voiceModelReady => 'Bereit';

  @override
  String get voiceNeedsDownload => 'Download nötig';

  @override
  String get voiceDownloaded => 'Heruntergeladen';

  @override
  String get voiceDownloadFailed => 'Download fehlgeschlagen';

  @override
  String get voiceFinishingSetup => 'Einrichtung wird abgeschlossen…';

  @override
  String get voiceDownloadingListeningModel => 'Hör-Modell wird geladen…';

  @override
  String get voiceDownloadingVoice => 'Stimme wird geladen…';

  @override
  String get voiceStartingDownload => 'Download startet…';

  @override
  String get voiceReady => 'Stimme bereit';

  @override
  String get voiceWarmingUp => 'Wird vorbereitet…';

  @override
  String get voiceReadyToSpeak => 'Bereit zu sprechen';

  @override
  String get voiceDownloadOnDevice => 'On-Device-Stimme herunterladen';

  @override
  String get voiceDownloadFailedRetry =>
      'Download fehlgeschlagen — tippen zum erneuten Versuch';

  @override
  String get voiceSpokenReplyLanguage => 'Sprache der gesprochenen Antworten';

  @override
  String get voiceSpokenReplyLanguageSubtitle =>
      'Sprache, wenn der Assistent Nachrichten vorliest.';

  @override
  String get voiceRecognitionLanguage => 'Erkennungssprache';

  @override
  String get voiceRecognitionLanguageSubtitle =>
      'Für Text-Mikrofon und Voice Call — kann sich von gesprochenen Antworten unterscheiden.';

  @override
  String get voiceEngineTitle => 'Sprechstimme';

  @override
  String get voiceEngineSubtitle =>
      'Wähle, woher die gesprochene Stimme kommt.';

  @override
  String get voiceChooseAVoice => 'Stimme wählen';

  @override
  String get voiceChooseAVoiceSubtitle =>
      'Vorschau-freundliche Namen für On-Device-Sprache.';

  @override
  String get voiceUseSystemDefault => 'Systemstandardstimme verwenden';

  @override
  String get welcomeWizardTitleGetStarted => 'Loslegen';

  @override
  String get welcomeWizardTitleYourSetup => 'Dein Setup';

  @override
  String get welcomeWizardTitleLookAndFeel => 'Look & Feel';

  @override
  String get welcomeWizardTitleAlmostDone => 'Fast fertig';

  @override
  String get welcomeWizardTitleSetup => 'Einrichtung';

  @override
  String get welcomeWizardLmStudioSubtitle =>
      'Modelle auf Mac oder PC ausführen';

  @override
  String get welcomeWizardOllamaSubtitle => 'Beliebter lokaler Server';

  @override
  String get welcomeWizardOmlxSubtitle => 'Apple-Silicon-Desktop-Server';

  @override
  String get welcomeWizardJanSubtitle => 'Lokale Modelle aus der JAN AI App';

  @override
  String get welcomeWizardUnslothSubtitle =>
      'Unsloth Desktop auf deinem Computer';

  @override
  String get welcomeWizardThemeSubtitle =>
      'Wähle ein Design. Du kannst es jederzeit ändern.';

  @override
  String get welcomeWizardModelReady => 'Bereit';

  @override
  String get welcomeWizardConnected => 'Verbunden';

  @override
  String get welcomeWizardServerFound => 'Server gefunden';

  @override
  String get welcomeWizardRequiresApiKey => 'API-Schlüssel erforderlich';

  @override
  String get welcomeWizardScanHomeQr => 'LM Mini Home QR scannen';

  @override
  String get welcomeWizardScanHomeQrSubtitle =>
      'Mit deinem Mac über „Mit dem Telefon teilen“ koppeln';

  @override
  String welcomeWizardModelsFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Modelle gefunden',
      one: '1 Modell gefunden',
    );
    return '$_temp0';
  }

  @override
  String get welcomeWizardLocalNetworkTitle => 'Netzwerkzugriff erlauben';

  @override
  String get welcomeWizardLocalNetworkBody =>
      'Du wirst aufgefordert, den Zugriff auf das lokale Netzwerk zu erlauben. Bitte erlaube ihn, damit LM Mini LM Mini Home, LM Studio oder Ollama auf deinem Computer finden kann.';

  @override
  String get welcomeWizardLocalNetworkAllow => 'Erlauben';

  @override
  String get welcomeWizardDownloadKeepsGoing =>
      'Du kannst diesen Bildschirm verlassen — der Download läuft weiter, auch wenn du die App verlässt.';

  @override
  String get welcomeWizardDownloadFailed =>
      'Download fehlgeschlagen. Tippe, um es erneut zu versuchen.';

  @override
  String get welcomeWizardAiDownloadingTitle => 'KI wird heruntergeladen';

  @override
  String get welcomeWizardAiDownloadingBody =>
      'Du kannst chatten, sobald die passende KI für dein Handy bereit ist. Das ist ein einmaliger Download.';

  @override
  String get onDeviceModels => 'On-Device-Modelle';

  @override
  String get transcription => 'Transkription';

  @override
  String get widgetSettings => 'Widget-Einstellungen';

  @override
  String get widgetSettingsSubtitle => 'Home-Screen-Widgets konfigurieren';

  @override
  String get setUpShortcuts => 'Kurzbefehle einrichten';

  @override
  String get shareArenaSpeedResults =>
      'Arena-Geschwindigkeitsergebnisse teilen';

  @override
  String get browseOnDeviceModels => 'On-Device-Modelle durchsuchen';

  @override
  String get homeDownloadModel => 'Modell herunterladen';

  @override
  String get usbMode => 'USB-Modus';

  @override
  String get usbModeHowItWorks => 'So funktioniert der USB-Modus';

  @override
  String get switchToUsbTitle => 'Von Remote auf USB wechseln?';

  @override
  String get switchLabel => 'Wechseln';

  @override
  String usbModeStartFailed(String error) {
    return 'USB-Modus konnte nicht gestartet werden: $error';
  }

  @override
  String get usbModeHowToUse => 'So geht’s:';

  @override
  String get openLmminiCom => 'lmmini.com öffnen';

  @override
  String get tapToUseServer => 'Tippen, um diesen Server zu nutzen';

  @override
  String get memoryPersonaFallback => 'Persona';

  @override
  String get voicePickSystemVoiceSubtitle =>
      'Wähle eine eingebaute Stimme für gesprochene Antworten.';

  @override
  String get chooseFromGallery => 'Aus Galerie wählen';

  @override
  String get galleryLimitsSubtitle => 'Fotos bis 10 MB · Videos bis 200 MB';

  @override
  String get recordVideo => 'Video aufnehmen';

  @override
  String attachmentsCount(int count, int max) {
    return 'Anhänge ($count/$max)';
  }

  @override
  String get viewProfile => 'Profil anzeigen';

  @override
  String get personaAndModel => 'Persona & Modell';

  @override
  String get chatOptions => 'Chat-Optionen';

  @override
  String get chatTab => 'Chat';

  @override
  String get voiceTab => 'Stimme';

  @override
  String get craftingPersona => 'Persona wird erstellt…';

  @override
  String get randomPersona => 'Überrasch mich';

  @override
  String get savePersona => 'Persona speichern';

  @override
  String get downloadFinished => 'Download abgeschlossen.';

  @override
  String get downloadCancelled => 'Download abgebrochen.';

  @override
  String get downloadCancelFailed =>
      'Konnte in LM Studio nicht abbrechen. Stoppe es in der Download-Liste von LM Studio.';

  @override
  String get newsBriefing => 'News-Briefing';

  @override
  String get refreshNow => 'Jetzt aktualisieren';

  @override
  String get noBriefingYet => 'Noch kein Briefing';

  @override
  String get newsSetPromptFirst =>
      'Lege zuerst einen News-Widget-Prompt in den Widget-Einstellungen fest.';

  @override
  String get newsRefreshed => 'News aktualisiert.';

  @override
  String newsRefreshFailed(String error) {
    return 'Aktualisierung fehlgeschlagen: $error';
  }

  @override
  String get themesTitle => 'Themes';

  @override
  String get createLabel => 'Erstellen';

  @override
  String get browseLabel => 'Durchsuchen';

  @override
  String get signInToUploadThemes => 'Bitte anmelden, um Themes hochzuladen';

  @override
  String get deleteThemeTitle => 'Theme löschen?';

  @override
  String deleteThemeConfirm(String name) {
    return '„$name“ aus deinen heruntergeladenen Themes entfernen?';
  }

  @override
  String get uploadToCommunity => 'In Community hochladen';

  @override
  String get installedLabel => 'Installiert';

  @override
  String get getLabel => 'Holen';

  @override
  String get bestForYou => 'Am besten für dich';

  @override
  String get loadingLabel => 'Laden';

  @override
  String get loadedLabel => 'Geladen';

  @override
  String get notLoadedLabel => 'Nicht geladen';

  @override
  String get reasoningLabel => 'Reasoning';

  @override
  String get imagesLabel => 'Bilder';

  @override
  String get detailsTooltip => 'Details';

  @override
  String get transcribeAudio => 'Audio transkribieren';

  @override
  String get transcribeAudioSubtitle =>
      'Audio hochladen und die KI zum Transkript befragen';

  @override
  String get trimSection => 'Abschnitt zuschneiden';

  @override
  String get includeTimestamps => 'Zeitstempel einschließen';

  @override
  String get phrasesLabel => 'Phrasen';

  @override
  String get wordsLabel => 'Wörter';

  @override
  String get transcriptionLanguage => 'Transkriptionssprache';

  @override
  String get searchLanguages => 'Sprachen suchen…';

  @override
  String get transcribe => 'Transkribieren';

  @override
  String get shareTranscript => 'Transkript teilen';

  @override
  String get transcriptionContextLargeToast =>
      'Diese Transkripte könnten für den Kontext des Modells zu groß sein. Verzweige von einer früheren Nachricht, falls Antworten unvollständig werden.';

  @override
  String get transcriptionSubtitlesOn => 'Untertitel an';

  @override
  String get transcriptionSubtitlesOff => 'Untertitel aus';

  @override
  String get transcriptionFullClip => 'Ganzes Audio';

  @override
  String get transcriptionJobRunning => 'Transkribieren…';

  @override
  String get transcriptionJobDone => 'Transkribiert';

  @override
  String get transcriptionJobFailed => 'Transkription fehlgeschlagen';

  @override
  String get branchFromHere => 'Ab hier verzweigen';

  @override
  String get memoryUpdates => 'Gedächtnis-Updates';

  @override
  String get promptWriteEmail => 'Write an email';

  @override
  String get promptWriteEmailBody =>
      'Help me write a clear, friendly email to ';

  @override
  String get promptGiveIdeas => 'Give me ideas';

  @override
  String get promptGiveIdeasBody => 'Brainstorm creative ideas with me about ';

  @override
  String get promptExplainSimply => 'Explain simply';

  @override
  String get promptExplainSimplyBody => 'Explain this in simple words: ';

  @override
  String get promptFixWriting => 'Fix my writing';

  @override
  String get promptFixWritingBody =>
      'Improve this writing for clarity and tone:\n\n';

  @override
  String get promptHelpStudy => 'Help me study';

  @override
  String get promptHelpStudyBody => 'Help me study this topic: ';

  @override
  String get promptPlanTrip => 'Plan a trip';

  @override
  String get promptPlanTripBody => 'Help me plan a trip to ';

  @override
  String get promptSummarize => 'Summarize this';

  @override
  String get promptSummarizeBody => 'Summarize this clearly:\n\n';

  @override
  String get promptChecklist => 'Make a checklist';

  @override
  String get promptChecklistBody => 'Make a practical checklist for ';

  @override
  String get promptFunFact => 'Tell me a fun fact';

  @override
  String get promptFunFactBody => 'Tell me a fun fact about ';

  @override
  String get promptQuizMe => 'Quiz me';

  @override
  String get promptQuizMeBody => 'Quiz me on ';

  @override
  String get promptRoleplay => 'Roleplay with me';

  @override
  String get promptRoleplayBody => 'Let\'s roleplay. You are ';

  @override
  String get promptCodeHelp => 'Code help';

  @override
  String get promptCodeHelpBody => 'Help me with this code problem:\n\n';

  @override
  String get promptDraftReply => 'Draft a reply';

  @override
  String get promptDraftReplyBody => 'Draft a polite reply to this:\n\n';

  @override
  String get promptPracticeInterview => 'Practice interview';

  @override
  String get promptPracticeInterviewBody => 'Practice interview questions for ';

  @override
  String get promptMealIdeas => 'Meal ideas';

  @override
  String get promptMealIdeasBody => 'Suggest meal ideas using ';

  @override
  String get promptWorkoutPlan => 'Workout plan';

  @override
  String get promptWorkoutPlanBody => 'Create a simple workout plan for ';

  @override
  String get promptTranslateCasually => 'Translate casually';

  @override
  String get promptTranslateCasuallyBody => 'Translate this casually:\n\n';

  @override
  String get promptNameIdeas => 'Name ideas';

  @override
  String get promptNameIdeasBody => 'Brainstorm name ideas for ';

  @override
  String get promptProsCons => 'Pros and cons';

  @override
  String get promptProsConsBody => 'List pros and cons of ';

  @override
  String get promptRewriteShorter => 'Rewrite shorter';

  @override
  String get promptRewriteShorterBody =>
      'Rewrite this shorter and clearer:\n\n';

  @override
  String get promptTeachVocab => 'Teach me vocab';

  @override
  String get promptTeachVocabBody => 'Teach me useful vocabulary about ';

  @override
  String get promptStoryTime => 'Story time';

  @override
  String get promptStoryTimeBody => 'Tell a short story about ';

  @override
  String get promptDebugWithMe => 'Debug with me';

  @override
  String get promptDebugWithMeBody => 'Help me debug this:\n\n';

  @override
  String get promptDailyMotivation => 'Daily motivation';

  @override
  String get promptDailyMotivationBody =>
      'Give me a short motivational nudge about ';

  @override
  String get promptPlayDnd => 'Play DnD';

  @override
  String get promptPlayDndBody => 'Let\'s play a short D&D adventure. I am ';

  @override
  String get promptWordChain => 'Word chain';

  @override
  String get promptWordChainBody => 'Let\'s play word chain. Start with: ';

  @override
  String get promptRiddleDuel => 'Riddle duel';

  @override
  String get promptRiddleDuelBody => 'Give me a riddle to solve.';

  @override
  String get promptWouldYouRather => 'Would you rather';

  @override
  String get promptWouldYouRatherBody =>
      'Ask me a fun would-you-rather question.';

  @override
  String get promptEscapeRoom => 'Escape room';

  @override
  String get promptEscapeRoomBody =>
      'Start a short text escape-room puzzle for me.';

  @override
  String get promptTriviaBattle => 'Trivia battle';

  @override
  String get promptTriviaBattleBody => 'Quiz me with trivia about ';

  @override
  String get promptStoryRpg => 'Story RPG';

  @override
  String get promptStoryRpgBody => 'Start a short story RPG. My character is ';

  @override
  String get promptGuessNumber => 'Guess the number';

  @override
  String get promptGuessNumberBody =>
      'Let\'s play guess the number. Think of a number between 1 and 100.';

  @override
  String get promptTwoTruths => 'Two truths one lie';

  @override
  String get promptTwoTruthsBody =>
      'Let\'s play two truths and a lie. You go first.';

  @override
  String get promptReadMyFile => 'Read my file';

  @override
  String get promptWhatIsImage => 'What is this image';

  @override
  String get promptTakePhoto => 'Take a photo';

  @override
  String get promptTranscribeAudio => 'Transcribe audio';

  @override
  String get promptPersonaGenerator => 'Persona Generator';

  @override
  String get personaShareMemoryCategoriesLabel => 'Zu teilende Kategorien';

  @override
  String get personaShareMemoryCategoriesSubtitle =>
      'Wähle, welche Arten von Erinnerungen diese Persona in Chats nutzen darf.';

  @override
  String get chooseFaceForBubbles => 'Gesicht für Bubbles wählen';

  @override
  String get moveMemories => 'Erinnerungen verschieben';

  @override
  String get deletePersonaAndMemories => 'Persona + Erinnerungen löschen';

  @override
  String get moveMemoriesTo => 'Erinnerungen verschieben nach…';

  @override
  String get globalSharedMemories => 'Global (mit allen Personas geteilt)';

  @override
  String personaMemoriesAssignedHint(int count, String name) {
    return '$count Erinnerung(en) sind „$name“ zugewiesen.\nWähle, was damit geschehen soll:';
  }

  @override
  String get homeSyncTitle => 'Chats synchron halten?';

  @override
  String homeSyncBodyBoth(int phoneChats, int macChats) {
    return 'Dieses Telefon hat $phoneChats Chats, LM Mini Home hat $macChats. Aktiviere Sync, um Unterhaltungen und Ordner zusammenzuführen — dann kannst du auf beiden Geräten weitermachen. Nutzt deine bestehende verschlüsselte Relay-Verbindung.';
  }

  @override
  String get homeSyncBodyPhoneOnly =>
      'Kopiere Chats und Ordner von diesem Telefon nach LM Mini Home und halte sie danach über die verschlüsselte Relay-Verbindung synchron.';

  @override
  String get homeSyncBodyMacOnly =>
      'Hol Chats und Ordner von LM Mini Home auf dieses Telefon und halte sie danach über die verschlüsselte Relay-Verbindung synchron.';

  @override
  String get homeSyncBodyGeneric =>
      'Führe Unterhaltungen und Ordner zwischen diesem Telefon und LM Mini Home zusammen, damit du auf beiden Geräten weitermachen kannst. Nutzt deine bestehende verschlüsselte Relay-Verbindung.';

  @override
  String get homeSyncEnable => 'Sync aktivieren';

  @override
  String get homeSyncNotNow => 'Nicht jetzt';

  @override
  String get homeSyncSettingsTitle => 'Chats mit Home synchronisieren';

  @override
  String get homeSyncSettingsSubtitle =>
      'Unterhaltungen und Ordner über die verschlüsselte Relay-Verbindung zusammenführen';

  @override
  String get homeSyncMergedToast => 'Chats und Ordner sind jetzt synchron';

  @override
  String get homeSyncFailedToast =>
      'Sync fehlgeschlagen. Öffne „Share with phone“ auf dem Mac und versuche es erneut.';

  @override
  String get homeSyncPersonasTitle => 'Personas synchronisieren';

  @override
  String get homeSyncPersonasSubtitle =>
      'Die ausgewählten kopieren, inklusive Fotos und Erinnerungen';

  @override
  String get homeSyncPersonasPickTitle => 'Personas wählen';

  @override
  String get homeSyncPersonasPickSubtitle =>
      'Markierte Personas werden zwischen diesem Gerät und Home kopiert, mit Foto und Erinnerungen.';

  @override
  String get homeSyncPersonasSave => 'Speichern und synchronisieren';

  @override
  String get homeSyncPersonasSavedToast => 'Personas sind synchron';

  @override
  String get homeSyncPersonasEmpty => 'Noch keine Personas zum Kopieren.';

  @override
  String get homeSyncPersonasUnreachable =>
      'Home nicht erreichbar. Öffne „Share with phone“ auf dem Mac und versuche es erneut.';

  @override
  String get homeSyncPersonasOnBoth => 'Auf beiden Geräten';

  @override
  String get homeSyncPersonasOnHome => 'LM Mini Home';

  @override
  String get homeSyncPersonasOnPhone => 'deinem Telefon';

  @override
  String get homeSyncPersonasThisPhone => 'diesem Telefon';

  @override
  String homeSyncPersonasOnDevice(String device) {
    return 'Auf $device';
  }

  @override
  String homeSyncPersonasMemoryCount(int count) {
    return '$count Erinnerungen';
  }

  @override
  String get homeSyncPersonasNoMemories => 'Noch keine Erinnerungen';

  @override
  String get reportToSupport => 'An Support senden';

  @override
  String get localhostConnectionHelp =>
      'Keine Verbindung zu localhost. Auf dem Handy bedeutet localhost dieses Gerät — nicht deinen Computer. Trag in den Einstellungen die IP-Adresse deines Computers ein (z. B. http://192.168.1.10:1234) und bleib im selben WLAN.';

  @override
  String get lmStudioPcNotAllowingTitle => 'Dein PC lässt keine Verbindung zu';

  @override
  String get lmStudioPcNotAllowingBody =>
      'Öffne in LM Studio auf dem Computer Developer → Server Settings und schalte Serve on Local Network ein.';

  @override
  String get lmStudioHostDownTitle => 'PC nicht erreichbar';

  @override
  String get lmStudioHostDownStep1 =>
      'Prüfe, ob der Computer an ist — nicht im Ruhezustand oder ausgeschaltet.';

  @override
  String get lmStudioHostDownStep2 =>
      'Öffne in LM Studio Developer → Server Settings und schalte Serve on Local Network ein.';

  @override
  String get cantReachMacTitle => 'Mac nicht erreichbar';

  @override
  String get cantReachMacStep1 =>
      'Öffne „Share with phone“ in LM Mini Home auf dem Mac.';

  @override
  String get cantReachMacStep2 =>
      'Warte, bis dort „Connected“ steht, und versuche es erneut.';

  @override
  String get lmStudioServerSettingsImageLabel =>
      'LM Studio Developer → Server Settings. Serve on Local Network muss an sein.';

  @override
  String get modelMissingTitle => 'Dieses Modell ist nicht auf deinem PC';

  @override
  String get modelMissingBody =>
      'Das gewählte Modell ist nicht verfügbar. Wähle ein anderes unter Modellauswahl.';

  @override
  String modelMissingBodyNamed(String model) {
    return '„$model“ ist nicht auf deinem Computer. Wähle ein anderes unter Modellauswahl.';
  }

  @override
  String get outputTokensExhaustedTitle =>
      'Das Modell hat keine Ausgabetokens mehr';

  @override
  String get outputTokensExhaustedBody =>
      'Die Tools sind durchgelaufen, aber für die Antwort fehlen Tokens. Erhöhe die maximale Tokenzahl und versuche es erneut.';

  @override
  String get thinkingBudgetRetryTitle => 'Thinking used the output limit';

  @override
  String get thinkingBudgetRetryBody =>
      'High thinking filled the output limit, so this reply uses low thinking. Raise max tokens to keep high thinking.';

  @override
  String get adjustMaxTokens => 'Max. Tokens anpassen';

  @override
  String get ggmlSchedulerCrashBody =>
      'Der Modellserver ist abgestürzt (llama.cpp-Scheduler). Das liegt nicht an Mini. Senke Kontextlänge und max. Tokens — sehr große Werte (zum Beispiel 128k Kontext) verursachen das oft.';

  @override
  String get generationTerminatedBody =>
      'LM Studio hat die Generierung auf deinem Computer beendet (der Prozess wurde beendet).';

  @override
  String generationTerminatedHugeImageBody(String size) {
    return 'LM Studio hat die Generierung auf deinem Computer beendet. Dein angehängtes Bild ist wahrscheinlich riesig ($size) — komprimiere es und sende erneut.';
  }

  @override
  String get compressAndResendImages => 'Bild komprimieren und erneut senden';

  @override
  String get imageCompressFailed =>
      'Das angehängte Bild ließ sich nicht verkleinern. Versuche ein kleineres Foto.';

  @override
  String get droppedChatBodyHelp =>
      'Mini hat diesen Chat gesendet, aber er ist nie bei LM Studio angekommen. Wenn vor LM Studio ein Proxy, Tunnel oder eine Extra-URL liegt, versuche es ohne — oder verbinde Mini direkt mit LM Studio (IP deines Computers, USB oder Connect).';

  @override
  String get comfyUiNoCheckpointsTitle => 'ComfyUI hat kein Bildmodell';

  @override
  String get comfyUiNoCheckpointsBody =>
      'ComfyUI hat kein Checkpoint geladen. Lege eine .safetensors-Datei in ComfyUIs models/checkpoints-Ordner und wähle sie unter Bilderzeugung.';

  @override
  String get comfyUiNoCheckpointSelectedBody =>
      'Kein Bildmodell ausgewählt. Öffne die Bilderzeugungseinstellungen und wähle einen Checkpoint.';

  @override
  String comfyUiUnknownCheckpointBody(String name) {
    return 'ComfyUI hat den Checkpoint „$name“ nicht. Wähle einen anderen unter Bilderzeugung.';
  }

  @override
  String get comfyUiWorkflowRejectedBody =>
      'ComfyUI hat den Workflow abgelehnt. Prüfe die Bilderzeugungseinstellungen.';

  @override
  String get comfyUiDiffusionOnlyTitle =>
      'Dieser Graph braucht deinen ComfyUI-Workflow';

  @override
  String get comfyUiDiffusionOnlyBody =>
      'Minis Standard-Workflow lädt einen klassischen SD-Checkpoint. Dein Comfy-Desktop-Graph nutzt ein Diffusionsmodell (UNET) plus CLIP und VAE. Exportiere ihn als API-Format (Workflow → Export) und wähle die Datei unter Bilderzeugung.';

  @override
  String get openImageSettings => 'Bildeinstellungen';

  @override
  String imageGenUnreachableTitle(String name) {
    return '$name nicht erreichbar';
  }

  @override
  String imageGenUnreachableBody(String name, String url) {
    return 'Unter $url antwortet nichts. Starte $name auf dem Computer und bleib im selben WLAN.';
  }

  @override
  String get imageGenUnreachableNoUrlBody =>
      'Kein Bildserver eingetragen. Füge ComfyUI oder AUTOMATIC1111 unter Bildgenerierung hinzu.';

  @override
  String get sharedHostUpdateImageTitle =>
      'Bildgenerierung auch aktualisieren?';

  @override
  String sharedHostUpdateChatTitle(String name) {
    return '$name auch aktualisieren?';
  }

  @override
  String sharedHostUpdateBody(
      String changedName, String peerName, String oldHost, String newUrl) {
    return '$changedName und $peerName liefen beide auf $oldHost. $peerName auf $newUrl ändern?';
  }

  @override
  String get sharedHostUpdateConfirm => 'Aktualisieren und testen';

  @override
  String get sharedHostUpdateSkip => 'Aktuell behalten';

  @override
  String sharedHostTesting(String name) {
    return 'Teste $name…';
  }

  @override
  String get sharedHostTestSuccessTitle => 'Verbunden';

  @override
  String sharedHostTestSuccessBody(String name, String url) {
    return '$name unter $url erreicht.';
  }

  @override
  String get sharedHostTestFailTitle => 'Keine Verbindung';

  @override
  String sharedHostTestFailBody(String name, String url, String error) {
    return '$name wurde auf $url geändert, aber Mini kommt nicht ran. $error';
  }

  @override
  String get supportTicketTitle => 'Problem melden';

  @override
  String get supportTicketPrefillDescription =>
      'Eine Logdatei mit den Fehlerdetails ist angehängt. Ergänze gerne weitere Hinweise:';

  @override
  String get supportTicketSubmitted => 'Danke — dein Bericht wurde gesendet.';

  @override
  String get supportTicketAlreadyOpen =>
      'Du hast bereits einen offenen Bericht zu diesem Fehler.';

  @override
  String get supportTicketViewExisting => 'Bericht ansehen';

  @override
  String get supportTicketAlreadySending =>
      'Dieser Fehler wird bereits gemeldet.';

  @override
  String get supportUnavailable =>
      'Support ist gerade nicht verfügbar. Versuche es später erneut, wenn du online bist.';

  @override
  String get somethingWentWrong => 'Etwas ist schiefgelaufen';

  @override
  String get uncaughtErrorSnack => 'Etwas ist schiefgelaufen.';

  @override
  String get errorLogLabel => 'LOG';

  @override
  String get appLock => 'App-Sperre';

  @override
  String get appLockSubtitleOff =>
      'PIN verlangen, wenn die App geschlossen war';

  @override
  String appLockSubtitleOn(String duration) {
    return 'Fragt nach $duration erneut';
  }

  @override
  String get appLockUnlockTitle => 'LM Mini ist gesperrt';

  @override
  String get appLockDescription =>
      'Schütze Chats auf diesem Gerät mit einer numerischen PIN und optional Face ID. Die PIN bleibt auf diesem Gerät und wird nicht synchronisiert.';

  @override
  String get appLockEnable => 'Mit PIN sperren';

  @override
  String get appLockEnableSubtitle => 'Beim Zurückkehren nach der PIN fragen';

  @override
  String get appLockPinLength4 => '4 Ziffern';

  @override
  String get appLockPinLength6 => '6 Ziffern';

  @override
  String get appLockRequireAfter => 'Erneut fragen nach';

  @override
  String get appLockTimeoutImmediate => 'Sofort';

  @override
  String get appLockTimeout15s => '15 Sekunden';

  @override
  String get appLockTimeout1m => '1 Minute';

  @override
  String get appLockTimeout5m => '5 Minuten';

  @override
  String get appLockTimeout15m => '15 Minuten';

  @override
  String get appLockTimeout1h => '1 Stunde';

  @override
  String get appLockChangePin => 'PIN ändern';

  @override
  String get appLockEnterCurrentPin => 'Aktuelle PIN eingeben';

  @override
  String get appLockChooseNewPin => 'PIN wählen';

  @override
  String get appLockConfirmPin => 'PIN bestätigen';

  @override
  String get appLockPinsDontMatch =>
      'PINs stimmen nicht überein. Bitte erneut versuchen.';

  @override
  String get appLockWrongPin => 'Falsche PIN. Bitte erneut versuchen.';

  @override
  String appLockTooManyAttempts(int seconds) {
    return 'Zu viele Versuche. Erneut in ${seconds}s.';
  }

  @override
  String get appLockForgotHint =>
      'Wenn du die PIN vergessen hast, kannst du sie mit einer Bestätigungs-E-Mail an dein angemeldetes Konto zurücksetzen. Melde dich an, bevor du die PIN verlierst — sonst ist keine Wiederherstellung möglich.';

  @override
  String get appLockProRequired => 'App-Sperre ist eine Pro-Funktion';

  @override
  String get appLockEnabledToast => 'App-Sperre ist an';

  @override
  String get appLockDisabledToast => 'App-Sperre ist aus';

  @override
  String get appLockChangedToast => 'PIN aktualisiert';

  @override
  String appLockBiometricsToggle(String method) {
    return 'Mit $method entsperren';
  }

  @override
  String get appLockBiometricsSubtitle =>
      'Face ID, Touch ID oder Fingerabdruck statt der PIN verwenden.';

  @override
  String get appLockBiometricFaceId => 'Face ID';

  @override
  String get appLockBiometricFace => 'Gesichtserkennung';

  @override
  String get appLockBiometricTouchId => 'Touch ID';

  @override
  String get appLockBiometricFingerprint => 'Fingerabdruck';

  @override
  String get appLockBiometricGeneric => 'Biometrie';

  @override
  String appLockUnlockWithBiometrics(String method) {
    return 'Mit $method entsperren';
  }

  @override
  String appLockBiometricsFailed(String method) {
    return 'Mit $method nicht entsperrt. Nutze deine PIN.';
  }

  @override
  String get appLockSignInToRecover =>
      'Melde dich an, sonst kannst du die App-Sperre nicht wiederherstellen, wenn diese PIN verloren geht.';

  @override
  String appLockSignInToRecoverBound(String email) {
    return 'Melde dich als $email an, sonst kannst du die App-Sperre nicht wiederherstellen, wenn diese PIN verloren geht.';
  }

  @override
  String get appLockNotSignedInNoRecovery =>
      'Du bist nicht angemeldet. Diese PIN kann nicht wiederhergestellt werden, wenn sie verloren geht.';

  @override
  String get appLockForgotPin => 'PIN vergessen?';

  @override
  String get appLockSendRecoveryEmail => 'Bestätigungslink per E-Mail senden';

  @override
  String appLockRecoveryEmailSent(String email) {
    return 'Wir haben eine Bestätigungs-E-Mail an $email gesendet. Öffne sie und komm dann zurück.';
  }

  @override
  String get appLockRecoveryIVerified => 'Ich habe bestätigt — weiter';

  @override
  String get appLockRecoveryResend => 'E-Mail erneut senden';

  @override
  String get appLockRecoveryReauth =>
      'Erneut anmelden, um die PIN zurückzusetzen';

  @override
  String appLockRecoveryWrongAccount(String email) {
    return 'Diese PIN ist an $email gebunden. Melde dich mit diesem Konto an, um sie wiederherzustellen.';
  }

  @override
  String get appLockRecoveryUnavailable =>
      'PIN-Wiederherstellung ist nicht eingerichtet. Du brauchst diese PIN oder musst LM Mini neu installieren.';

  @override
  String get appLockRecoveryFailed =>
      'Konto konnte nicht bestätigt werden. Bitte erneut versuchen.';

  @override
  String get appLockRecoveryNoEmail =>
      'Dieses Konto hat keine E-Mail für einen Bestätigungslink.';

  @override
  String get appLockRecoveryTooMany =>
      'Zu viele E-Mails. Warte eine Minute und versuche es erneut.';

  @override
  String get appLockRecoverySetPin => 'Neue PIN wählen';

  @override
  String get appLockContinueWithEmail => 'Mit E-Mail fortfahren';

  @override
  String appLockSignedInRecoverHint(String email) {
    return 'Wenn du diese PIN vergisst, können wir einen Bestätigungslink an $email senden.';
  }

  @override
  String get appLockRecoveryAccount => 'PIN-Wiederherstellung';

  @override
  String appLockRecoveryAccountOn(String email) {
    return 'Bestätigungs-E-Mails gehen an $email';
  }

  @override
  String get appLockRecoveryAccountOff =>
      'Anmelden, um eine vergessene PIN wiederherstellen zu können';

  @override
  String get appLockRecoveryAccountOffSubtitle =>
      'Ohne angemeldetes Konto lässt sich eine verlorene PIN nur durch Neuinstallation löschen.';

  @override
  String get appLockBackToPin => 'PIN verwenden';

  @override
  String get premiumAppLock => 'App-Sperre';

  @override
  String get premiumAppLockTagline => 'App per PIN schützen';

  @override
  String get premiumAppLockDescription =>
      'Lege eine 4- oder 6-stellige PIN fest, entsperre mit Face ID und setze eine vergessene PIN per Bestätigungs-E-Mail zurück. Die PIN bleibt auf diesem Gerät.';

  @override
  String spritePanelShow(String name) {
    return 'Ausdruck von $name zeigen';
  }

  @override
  String get personaExpressionsTitle => 'Ausdrücke';

  @override
  String get personaExpressionsSubtitle =>
      'Charakterbilder, die sich mit der Stimmung jeder Antwort ändern. Benenne Bilder nach dem Ausdruck, z. B. joy.png oder anger.png, oder importiere ein SillyTavern-Sprite-Zip.';

  @override
  String get personaExpressionsImport => 'Sprites importieren';

  @override
  String get personaExpressionsRemoveAll => 'Alle entfernen';

  @override
  String personaExpressionsRemoveAllConfirm(String name) {
    return 'Alle Ausdrucks-Sprites von $name entfernen?';
  }

  @override
  String get personaExpressionsReplace => 'Bild ersetzen';

  @override
  String get personaExpressionsRemove => 'Entfernen';

  @override
  String personaExpressionsImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Sprites hinzugefügt',
      one: '1 Sprite hinzugefügt',
      zero: 'Keine Sprites hinzugefügt',
    );
    return '$_temp0';
  }

  @override
  String personaExpressionsUnmatched(String files) {
    return 'Übersprungen (kein Ausdrucksname): $files';
  }

  @override
  String get personaExpressionsMissing => 'Fehlt';

  @override
  String get characterCardImport => 'Charakterkarte importieren';

  @override
  String characterCardImportedOne(String name) {
    return '$name importiert';
  }

  @override
  String characterCardImportedMany(int count) {
    return '$count Charaktere importiert';
  }

  @override
  String characterCardImportFailed(String file, String reason) {
    return '$file konnte nicht importiert werden: $reason';
  }

  @override
  String characterCardLoreSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count Lorebook-Einträge mit Schlüsselwörtern wurden nicht importiert',
      one: '1 Lorebook-Eintrag mit Schlüsselwörtern wurde nicht importiert',
    );
    return '$_temp0';
  }

  @override
  String get appearanceExpressionSprites => 'Charakter-Ausdrücke';

  @override
  String get appearanceExpressionSpritesSubtitle =>
      'Für Personas mit Ausdrucks-Sprites';

  @override
  String get expressionSpriteModeOff => 'Aus';

  @override
  String get expressionSpriteModePanel => 'Großes Bild';

  @override
  String get expressionSpriteModeAvatar => 'Nachrichten-Avatar';

  @override
  String get expressionSpriteModeBoth => 'Beides';

  @override
  String get spriteGenerateButton => 'Generieren';

  @override
  String get spriteGenerateTitle => 'Ausdrücke generieren';

  @override
  String get spriteGenerateAppearance => 'Aussehen';

  @override
  String get spriteGenerateAppearanceHint => 'Haare, Augen, Kleidung und Stil';

  @override
  String get spriteGenerateSeed => 'Seed';

  @override
  String get spriteGenerateSeedHelp =>
      'Derselbe Seed hält den Charakter über alle Ausdrücke ähnlich.';

  @override
  String get spriteGenerateCore => '8 Grundausdrücke';

  @override
  String get spriteGenerateAll => 'Alle 28';

  @override
  String get spriteGenerateOnlyMissing => 'Nur fehlende Ausdrücke';

  @override
  String spriteGenerateStart(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bilder generieren',
      one: '1 Bild generieren',
    );
    return '$_temp0';
  }

  @override
  String spriteGenerateProgress(int current, int total, String label) {
    return 'Generiere $current von $total: $label';
  }

  @override
  String get spriteGenerateNeedsImageGen =>
      'Richte zuerst die Bildgenerierung ein: Einstellungen → Bildgenerierung.';

  @override
  String spriteGenerateDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Ausdrücke generiert',
      one: '1 Ausdruck generiert',
    );
    return '$_temp0';
  }

  @override
  String spriteGenerateFailed(String label, String error) {
    return 'Bei $label gestoppt: $error';
  }

  @override
  String get personaGreetingLabel => 'Erste Nachricht (optional)';

  @override
  String get personaGreetingHint =>
      'Was der Charakter sagt, wenn ein neuer Chat beginnt';

  @override
  String get personaMemoryOwnOnlyNote =>
      'Diese Persona hat ein eigenes Gedächtnis: Sie sieht nur, was sie in ihren eigenen Chats gelernt hat, nie deine geteilten Erinnerungen.';

  @override
  String get remoteAccessSwitchTitle => 'Fernzugriff verwenden';

  @override
  String get remoteAccessSwitchOnSubtitle =>
      'An: Erreiche deinen Computer von überall.';

  @override
  String get remoteAccessSwitchOffSubtitle =>
      'Aus: Nutzt den Server in deinem Heimnetz. Die Kopplung bleibt erhalten.';

  @override
  String get remoteAccessSwitchConnecting => 'Verbinde mit deinem Computer…';

  @override
  String get remoteAccessUnreachable =>
      'Fernzugriff ist an, aber dein Computer antwortet nicht. Achte darauf, dass er wach ist und freigibt.';

  @override
  String get remoteAccessTurnOnFailed =>
      'Fernzugriff konnte nicht eingeschaltet werden. Versuch es noch einmal.';

  @override
  String get remoteAccessTurnOffFailed =>
      'Fernzugriff konnte nicht ausgeschaltet werden. Versuch es noch einmal.';
}
