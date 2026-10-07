// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'LM Mini';

  @override
  String get splashTagline => 'local AI chat';

  @override
  String get homeTitle => 'LM Mini';

  @override
  String get homeSearchHint => 'Search conversations...';

  @override
  String get allConversations => 'All Conversations';

  @override
  String get noFoldersTitle => 'No folders yet';

  @override
  String get noFoldersSubtitle => 'Create folders to organize your chats';

  @override
  String get noConversationsTitle => 'No conversations yet';

  @override
  String get noConversationsSubtitle => 'Start a new chat to get started';

  @override
  String get newChat => 'New Chat';

  @override
  String conversationCount(int count) {
    return '$count conversation(s)';
  }

  @override
  String get noModelsAvailable =>
      'No models available. Please check your LM Studio connection.';

  @override
  String get noVisionModelAvailable =>
      'No vision-capable model available. Please load a vision model in LM Studio.';

  @override
  String get deleteConversationTitle => 'Delete Conversation';

  @override
  String get deleteConversationMessage =>
      'Are you sure you want to delete this conversation? This action cannot be undone.';

  @override
  String get renameConversationTitle => 'Rename Conversation';

  @override
  String get conversationTitleLabel => 'Conversation Title';

  @override
  String get deleteFolderTitle => 'Delete Folder';

  @override
  String get deleteFolderMessage =>
      'This will not delete the conversations in this folder.';

  @override
  String get moveToFolderTitle => 'Move to Folder';

  @override
  String get noFolder => 'No Folder';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get close => 'Close';

  @override
  String get ok => 'OK';

  @override
  String get add => 'Add';

  @override
  String get edit => 'Edit';

  @override
  String get reset => 'Reset';

  @override
  String get retry => 'Retry';

  @override
  String get search => 'Search';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied!';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get configure => 'Configure';

  @override
  String get rename => 'Rename';

  @override
  String get duplicate => 'Duplicate';

  @override
  String get enabled => 'Enabled';

  @override
  String get disabled => 'Disabled';

  @override
  String get active => 'Active';

  @override
  String get none => 'None';

  @override
  String get auto => 'Auto';

  @override
  String get custom => 'Custom';

  @override
  String get change => 'Change';

  @override
  String get chatDefaultTitle => 'Chat';

  @override
  String get searchMessagesTooltip => 'Search messages';

  @override
  String get chatSettingsMenuItem => 'Chat Settings';

  @override
  String get appearanceMenuItem => 'Appearance';

  @override
  String get exportAsPdf => 'Export as PDF';

  @override
  String get exportAsTxt => 'Export as TXT';

  @override
  String get exportAsMarkdown => 'Export as Markdown';

  @override
  String get exportAsJson => 'Export as JSON';

  @override
  String get exportAsObsidian => 'Export for Obsidian';

  @override
  String get copyToClipboard => 'Copy to Clipboard';

  @override
  String get exportAndShare => 'Export & Share';

  @override
  String get freeFormats => 'Standard';

  @override
  String get premiumFormats => 'Pro Formats';

  @override
  String get chatExported => 'Chat exported';

  @override
  String get noModelSelectedTitle => 'No Model Selected';

  @override
  String get noModelSelectedSubtitle =>
      'Please select a model in settings to start chatting';

  @override
  String get openSettings => 'Open Settings';

  @override
  String connectionError(String error) {
    return 'Connection Error: $error';
  }

  @override
  String get startConversation => 'Greetings! How may I assist you today?';

  @override
  String get typeMessageToBegin =>
      'Pick a suggestion below, or type a message to begin';

  @override
  String get searchMessagesTitle => 'Search Messages';

  @override
  String get searchQueryHint => 'Enter search query...';

  @override
  String get semanticSearchInfo =>
      'Semantic search uses AI to find relevant messages based on meaning, not just keywords.';

  @override
  String get noMessagesToSearch => 'No messages to search';

  @override
  String get searchResults => 'Search Results';

  @override
  String searchResultsFor(int count, String query) {
    return '$count match(es) for \"$query\"';
  }

  @override
  String get noMessagesFound => 'No messages found';

  @override
  String get tryDifferentSearch => 'Try a different search query';

  @override
  String get chatCustomizationSaved => 'Chat customization saved';

  @override
  String get noMessagesToExport => 'No messages to export';

  @override
  String get exportingChat => 'Exporting chat...';

  @override
  String get chatExportedAsPdf => 'Chat exported as PDF';

  @override
  String get chatExportedAsTxt => 'Chat exported as TXT';

  @override
  String exportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get chatSettingsUpdated =>
      'Chat settings updated (overriding global settings)';

  @override
  String get chatSettingsReset => 'Chat settings reset to global defaults';

  @override
  String get you => 'You';

  @override
  String get assistant => 'Assistant';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get showDetails => 'Show details';

  @override
  String get hideDetails => 'Hide details';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAdvancedMode => 'Advanced';

  @override
  String get settingsAdvancedModeTooltip =>
      'Show technical options for power users';

  @override
  String get serverSection => 'SERVER';

  @override
  String get serverUrlLabel => 'Server URL';

  @override
  String get serverUrlHint => 'http://localhost:1234';

  @override
  String get testConnectionRequired => 'Test Connection (Required)';

  @override
  String get testConnection => 'Test Connection';

  @override
  String get modelsSection => 'MODELS';

  @override
  String get modelSelection => 'Model Selection';

  @override
  String get noModelSelected => 'No model selected';

  @override
  String get modelParameters => 'Model Parameters';

  @override
  String get modelParametersSubtitle => 'Temperature, tokens, penalties';

  @override
  String get modelParametersHelpTooltip => 'What these settings mean';

  @override
  String get modelParametersHelpTitle => 'Quick guide';

  @override
  String get modelParametersHelpIntro =>
      'Simple tips for each setting. Leave defaults if you’re unsure — you can always change them later. Some options only show for your current AI provider.';

  @override
  String get topKHelp =>
      'How many word choices the AI considers. Lower = safer and more predictable; 0 = no limit.';

  @override
  String get reasoningHelp =>
      'Turns thinking mode on or off for reasoning models. Off = faster replies without a thinking trace; On (or a level) asks the model to think step by step. Not all reasoning models support turning thinking off.';

  @override
  String get reasoningHelpShort =>
      'Turns thinking on or off. Not all models support Off.';

  @override
  String get systemPrompts => 'Personas and System Prompts';

  @override
  String get defaultPrompt => 'Default Prompt';

  @override
  String get appearanceSection => 'APPEARANCE';

  @override
  String get appearance => 'Appearance';

  @override
  String get appearanceSubtitle => 'Theme, backgrounds, avatars';

  @override
  String get supportSection => 'SUPPORT';

  @override
  String get rateApp => 'Rate LM Mini';

  @override
  String get rateAppSubtitle =>
      'Love the app? Leave a review on the App Store ⭐';

  @override
  String get hfBrowseTitle => 'Download from Hugging Face';

  @override
  String get hfBrowseSubtitle => 'Browse GGUF models — no API key needed';

  @override
  String get hfBrowseTab => 'Browse';

  @override
  String get hfPasteTab => 'Paste link';

  @override
  String get hfSearchHint => 'Search GGUF models…';

  @override
  String get hfLoadingModels => 'Searching Hugging Face…';

  @override
  String get hfNoModelsFound => 'No models found';

  @override
  String get hfNoModelsHint =>
      'Try a different search term or turn off the LM Studio filter.';

  @override
  String get hfLmStudioFilter => 'LM Studio compatible';

  @override
  String get hfLmStudioFilterHint =>
      'Only models Hugging Face lists as working with LM Studio';

  @override
  String get hfChatModelsFilter => 'Chat models';

  @override
  String get hfChatBadge => 'Chat';

  @override
  String get hfLmStudioBadge => 'LM Studio';

  @override
  String get hfPasteUrlHint => 'https://huggingface.co/owner/repo';

  @override
  String get hfModelInfo => 'Model info';

  @override
  String hfDownloadsCount(String count) {
    return '$count downloads';
  }

  @override
  String hfLikesCount(String count) {
    return '$count likes';
  }

  @override
  String hfPipelineTag(String tag) {
    return 'Task: $tag';
  }

  @override
  String hfBaseModel(String model) {
    return 'Base model: $model';
  }

  @override
  String hfLicense(String license) {
    return 'License: $license';
  }

  @override
  String get hfTagsSection => 'Tags';

  @override
  String get hfQuantPickerHint =>
      'Lower quant = smaller file. Q4_K_M is a good balance for most devices.';

  @override
  String get hfBackToModels => 'Back to models';

  @override
  String hfGgufFilesCount(int count) {
    return '$count GGUF file(s) available';
  }

  @override
  String get hfDownloadInBackground =>
      'Download started — track progress with the floating button. You can keep browsing or close this panel.';

  @override
  String get hfQuantPickerHintLmStudio =>
      'Quantizations listed by your LM Studio server. Pick one to download to the server.';

  @override
  String get hfDownloadDefaultQuant => 'Download';

  @override
  String hfDownloadFailed(String error) {
    return 'Could not start download: $error';
  }

  @override
  String get hfPasteInstructions =>
      'Paste a Hugging Face repo URL or type owner/repo. You\'ll pick a quantization next.';

  @override
  String get hfPasteInstructionsLmStudio =>
      'Paste a Hugging Face URL, owner/repo, or an LM Studio model ID.';

  @override
  String get hfPasteLabel => 'Repository';

  @override
  String get hfInvalidRepo => 'Enter a valid Hugging Face URL or owner/repo.';

  @override
  String get hfRecommended => 'Recommended';

  @override
  String get reviewPromptTitle => 'Enjoying LM Mini?';

  @override
  String get reviewPromptMessage =>
      'You\'ve had a few great chats! Would you mind leaving a quick rating on the Play Store?';

  @override
  String get reviewPromptRate => 'Rate now';

  @override
  String get reviewPromptLater => 'Maybe later';

  @override
  String get buyMeACoffee => 'Buy Me a Coffee';

  @override
  String get buyMeACoffeeSubtitle => 'Help keep the AI caffeinated! 🤖';

  @override
  String get featureRequests => 'Support / Feature Requests';

  @override
  String get featureRequestsSubtitle => 'Vote on features or submit your ideas';

  @override
  String get dataSection => 'DATA';

  @override
  String get exportAllChats => 'Export All Chats';

  @override
  String get exportAllChatsSubtitle =>
      'Download all conversations as a ZIP file';

  @override
  String get importChats => 'Import Chats';

  @override
  String get importChatsSubtitle =>
      'Import LM Studio chat exports (.md or .zip)';

  @override
  String importSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chats imported successfully',
      one: '1 chat imported successfully',
    );
    return '$_temp0';
  }

  @override
  String get importFailed => 'Import failed';

  @override
  String importPartial(int imported, int skipped) {
    return '$imported imported, $skipped skipped';
  }

  @override
  String get importing => 'Importing...';

  @override
  String get advancedSection => 'ADVANCED FEATURES';

  @override
  String get showRuntimeInfo => 'Show Runtime Info';

  @override
  String get showRuntimeInfoSubtitle =>
      'Display model architecture and runtime';

  @override
  String get embeddingModel => 'Embedding Model';

  @override
  String get enableSemanticSearch => 'Enable Semantic Search';

  @override
  String get enableSemanticSearchSubtitle =>
      'Find relevant messages using embeddings';

  @override
  String get toolCalling => 'Tool Calling';

  @override
  String get toolCallingEnabled => 'Tool calling enabled';

  @override
  String get toolCallingDisabled => 'Tool calling disabled';

  @override
  String get legalSection => 'LEGAL';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get privacyPolicySubtitle => 'Chats stay on your devices';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get termsOfServiceSubtitle => 'Terms and conditions';

  @override
  String get appName => 'LM Mini';

  @override
  String get appTagline =>
      'A Pocket A.I and companion app for LM Studio, Ollama and oMLX';

  @override
  String get couldNotOpenLink => 'Could not open link';

  @override
  String get apiToken => 'API Token and USB';

  @override
  String get tokenConfigured => 'Token configured';

  @override
  String get optionalAuthentication => 'Optional authentication';

  @override
  String get apiTokenLabel => 'API Token';

  @override
  String get apiTokenHint => 'Enter your LM Studio API token';

  @override
  String get apiTokenHelp =>
      'If your LM Studio server requires authentication, enter your API token here. This is optional and only needed if you\'ve enabled authentication in LM Studio settings.';

  @override
  String get apiTokenInfo =>
      'LM Studio 0.4.0+ supports API authentication. Enable it in LM Studio > Settings > Security.';

  @override
  String get actionRequired => '- Action Required';

  @override
  String get idleTtl => 'Idle TTL';

  @override
  String get idleTtlDefault => 'Using LM Studio default (60 min)';

  @override
  String idleTtlMinutes(int value) {
    return 'Auto-unload after $value minutes idle';
  }

  @override
  String idleTtlHoursMinutes(int hours, int mins) {
    return 'Auto-unload after $hours hr $mins min idle';
  }

  @override
  String get lmStudioDefault => 'LM Studio Default';

  @override
  String get fiveMinutes => '5 minutes';

  @override
  String get fifteenMinutes => '15 minutes';

  @override
  String get thirtyMinutes => '30 minutes';

  @override
  String get oneHour => '1 hour';

  @override
  String get twoHours => '2 hours';

  @override
  String connectionSuccess(int count) {
    return 'Connected! Loaded $count models';
  }

  @override
  String get connectionFailed => 'Connection failed';

  @override
  String get troubleshootingSteps => 'Troubleshooting Steps:';

  @override
  String get troubleshootStep1 => 'Make sure LM Studio is running';

  @override
  String get troubleshootStep2 =>
      'In LM Studio, open the Developer tab (⚙️ icon)';

  @override
  String get troubleshootStep3 => 'Enable \"Serve on Local Network\" toggle';

  @override
  String get troubleshootStep4 => 'Verify Server Port matches (default: 1234)';

  @override
  String troubleshootStep5(String ip) {
    return 'For local connection use your IP, e.g. $ip';
  }

  @override
  String get lmStudioSettings => 'LM Studio Settings';

  @override
  String get serveOnLocalNetworkHelp =>
      'The \"Serve on Local Network\" toggle should be enabled (shown in orange/green) in the LM Studio Developer tab.';

  @override
  String get networkConnections => 'Network Connections:';

  @override
  String get networkConnectionsTips =>
      '• Replace \"localhost\" with your computer\'s IP address\n• Ensure both devices are on the same network\n• Check firewall settings for port 1234';

  @override
  String get noConversationsToExport => 'No conversations to export';

  @override
  String exportingConversations(int count) {
    return 'Exporting $count conversation(s)...';
  }

  @override
  String exportSuccess(int count) {
    return '$count conversation(s) exported successfully';
  }

  @override
  String get languageSection => 'LANGUAGE';

  @override
  String get language => 'Language';

  @override
  String get languageSubtitle => 'Choose your preferred language';

  @override
  String get systemDefault => 'System Default';

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
  String get toolsCallingTitle => 'Tools Calling';

  @override
  String get toolCallingSection => 'TOOL CALLING';

  @override
  String get enableToolCallingAndMcps => 'Enable Tool Calling & MCPs';

  @override
  String get enableToolCallingSubtitle =>
      'Allow AI to search web and call MCPs';

  @override
  String get builtInToolsSection => 'BUILT-IN TOOLS';

  @override
  String get builtInToolsInfo =>
      'Tools executed locally by the app when AI requests them';

  @override
  String get webSearch => 'Web Search';

  @override
  String get webSearchUsingSearxng => 'Using SearXNG';

  @override
  String get webSearchDisabled =>
      'Disabled (configure SearXNG or upgrade to Pro)';

  @override
  String get integratedMcpsSection => 'INTEGRATED MCPs';

  @override
  String get integratedMcpsInfo =>
      'Use MCPs you already set up in LM Studio. Just add their names from your mcp.json here.';

  @override
  String get integratedMcpsAuthRequired =>
      'Integrated MCPs require Authentication enabled in LM Studio and an API token set in Settings → API Token.';

  @override
  String get requiresApiToken => 'Requires API token';

  @override
  String get setApiTokenTooltip => 'Set an API token in Settings to enable';

  @override
  String get noIntegratedMcps => 'No integrated MCPs configured';

  @override
  String get addManually => 'Add Manually';

  @override
  String get importMcpJson => 'Import mcp.json';

  @override
  String get ephemeralMcpsSection => 'EPHEMERAL MCPs';

  @override
  String get ephemeralMcpsInfo =>
      'HTTP MCP servers sent per-request. Requires \"Allow per-request MCPs\" in LM Studio.';

  @override
  String get requiresPerRequestMcps =>
      'Requires: Developer → Server Settings → Allow per-request MCPs';

  @override
  String get noEphemeralMcps => 'No ephemeral MCPs configured';

  @override
  String get addHttpMcpServer => 'Add HTTP MCP Server';

  @override
  String get browseExampleMcps => 'Browse Example MCP Servers';

  @override
  String get addIntegratedMcpTitle => 'Add MCP';

  @override
  String get editIntegratedMcpTitle => 'Edit MCP';

  @override
  String get addIntegratedMcpInfo =>
      'Copy the name from LM Studio\'s mcp.json and paste it here. For example, if you see a key named playwright, type playwright.';

  @override
  String get mcpNameLabel => 'Name from mcp.json';

  @override
  String get mcpNameHint => 'playwright';

  @override
  String get mcpNameHelper =>
      'Letters, numbers, and hyphens only — use web-search, not web_search.';

  @override
  String get exampleMcpJsonEntry => '💡 Example mcp.json entry:';

  @override
  String get nameIsRequired => 'Name is required';

  @override
  String get mcpNameInvalidChars =>
      'Use hyphens instead of underscores (LM Studio won\'t accept names like web_search).';

  @override
  String get mcpNameAlreadyExists => 'That MCP is already added';

  @override
  String addedMcp(String name) {
    return 'Added $name';
  }

  @override
  String updatedMcp(String name) {
    return 'Updated $name';
  }

  @override
  String get editMcpTooltip => 'Edit name';

  @override
  String get unlimitedToolCalls => 'Unlimited Tool Calls';

  @override
  String get unlimitedToolCallsSubtitle =>
      'Remove the 10-call limit for Integrated & Ephemeral MCPs (does not affect Pro Search)';

  @override
  String get unlimitedToolCallsOn => 'No limit on MCP tool call iterations';

  @override
  String get unlimitedToolCallsOff => 'Limited to 10 tool call iterations';

  @override
  String get structuredOutput => 'Structured Output';

  @override
  String get structuredOutputSubtitle => 'Force JSON response format';

  @override
  String get reasoningMode => 'Reasoning Mode';

  @override
  String get reasoningOff => 'Off';

  @override
  String get reasoningLow => 'Low';

  @override
  String get reasoningMedium => 'Medium';

  @override
  String get reasoningHigh => 'High';

  @override
  String get reasoningOn => 'On';

  @override
  String get reasoningDescOff => 'No reasoning traces';

  @override
  String get reasoningDescLow => 'Minimal reasoning';

  @override
  String get reasoningDescMedium => 'Balanced reasoning';

  @override
  String get reasoningDescHigh => 'Detailed reasoning';

  @override
  String get reasoningDescOn => 'Full reasoning traces';

  @override
  String get helpSection => 'HELP';

  @override
  String get toolCallingGuide => 'Tool Calling Guide';

  @override
  String get toolCallingGuideSubtitle => 'Learn how tools work';

  @override
  String get searxngSetupGuide => 'SearXNG Setup Guide';

  @override
  String get searxngSetupGuideSubtitle => 'Set up your own search server';

  @override
  String get webSearchConfig => 'Web Search Configuration';

  @override
  String get howWebSearchWorks => '💡 How Web Search Works';

  @override
  String get howWebSearchWorksSteps =>
      '1. AI decides it needs current info\n2. App searches using Premium Search or SearXNG\n3. Results are sent back to AI\n4. AI synthesizes an answer';

  @override
  String get searchResultsLabel => 'Search Results: ';

  @override
  String get webSearchDisabledWarning =>
      'Web search disabled. Configure SearXNG or upgrade to Pro.';

  @override
  String get searxngUrlOptional => 'SearXNG URL (Optional)';

  @override
  String get searxngUrlLabel => 'SearXNG URL';

  @override
  String get searxngUrlHint => 'http://localhost:8888';

  @override
  String get quickSetupDocker => '🐳 Quick Setup with Docker:';

  @override
  String get dockerCommand => 'docker run -d -p 8888:8080 searxng/searxng';

  @override
  String get mcpBadge => 'MCP';

  @override
  String get mcpResultBadge => 'MCP Result';

  @override
  String get webSearchSourcesTitle => 'Sources';

  @override
  String get toolBadge => 'Tool';

  @override
  String get resultBadge => 'Result';

  @override
  String get failedToLoadImage => 'Failed to load image';

  @override
  String get thinking => 'Thinking';

  @override
  String get think => 'Think';

  @override
  String thoughtFor(String duration) {
    return 'Thought for $duration';
  }

  @override
  String get performanceStats => 'Performance Stats';

  @override
  String get regenerate => 'Regenerate';

  @override
  String get editMessage => 'Edit Message';

  @override
  String get editMessageHint => 'Edit your message...';

  @override
  String get saveAndRegenerate => 'Save & Regenerate';

  @override
  String get deleteMessage => 'Delete Message';

  @override
  String get deleteMessageConfirm =>
      'Are you sure you want to delete this message?';

  @override
  String get mcpCallTitle => 'MCP Call';

  @override
  String get mcpResultTitle => 'MCP Result';

  @override
  String get toolCallTitle => 'Tool Call';

  @override
  String get toolResultTitle => 'Tool Result';

  @override
  String get attachFile => 'Attach File';

  @override
  String get photoLibrary => 'Photo Library';

  @override
  String get attachImagesForVision => 'Attach images for vision analysis';

  @override
  String get requiresVisionModel => 'Requires a vision-capable model';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get captureImageWithCamera => 'Capture image with camera';

  @override
  String get imageFromFiles => 'Image from Files';

  @override
  String get pickImageFromFilesApp => 'Pick an image from the Files app';

  @override
  String get attachDocuments => 'Documents';

  @override
  String get attachDocumentsSubtitle =>
      'PDF, Markdown, Excel (.xlsx), CSV, text, code, and more';

  @override
  String get textFileTxt => 'Text File (.txt)';

  @override
  String get attachPlainText => 'Attach plain text documents';

  @override
  String get csvFileCsv => 'CSV File (.csv)';

  @override
  String get attachSpreadsheetData => 'Attach spreadsheet data';

  @override
  String get pdfDocumentPdf => 'PDF Document (.pdf)';

  @override
  String get attachPdfDocuments => 'Attach PDF documents';

  @override
  String get mcpLabel => 'MCP:';

  @override
  String get typeMessageHint => 'Type a message...';

  @override
  String get attachFilesTooltip => 'Attach files';

  @override
  String get customizeChat => 'Customize Chat';

  @override
  String get overrideGlobalAppearance =>
      'Override global appearance settings for this chat';

  @override
  String get background => 'Background';

  @override
  String get userAvatar => 'User Avatar';

  @override
  String get assistantAvatar => 'Assistant Avatar';

  @override
  String get colorsSection => 'Colors';

  @override
  String get userBubble => 'User Bubble';

  @override
  String get userText => 'User Text';

  @override
  String get assistantBubble => 'Assistant Bubble';

  @override
  String get assistantText => 'Assistant Text';

  @override
  String get darkOverlay => 'Dim wallpaper';

  @override
  String get darkOverlayDescription =>
      'How dark to make the wallpaper behind your chat';

  @override
  String get usingGlobal => 'Using global';

  @override
  String get useGlobal => 'Use Global';

  @override
  String get setCustom => 'Set Custom';

  @override
  String get customColor => 'Custom color';

  @override
  String get defaultThemeColor => 'Default theme color';

  @override
  String get resetToDefault => 'Reset to default';

  @override
  String get pickAColor => 'Pick a color';

  @override
  String get chatSettingsTitle => 'Chat Settings';

  @override
  String get overrideGlobalSettings =>
      'Override global settings for this chat only';

  @override
  String get resetAll => 'Reset All';

  @override
  String get modelOverride => 'Model';

  @override
  String get noneSelected => 'None selected';

  @override
  String get systemPromptOverride => 'Persona';

  @override
  String get saved => 'Saved';

  @override
  String get noSavedPromptsInfo =>
      'No saved personas. Go to Settings → Personas to create some.';

  @override
  String get selectSavedPromptHint => 'Select a persona...';

  @override
  String get enterCustomPromptHint => 'Enter custom persona prompt...';

  @override
  String get personaShareMemoriesLabel => 'Share memories';

  @override
  String get personaShareMemoriesSubtitle =>
      'When off, this persona won\'t receive or learn memories in chats';

  @override
  String get webSearchOffForThisChat => 'Off for this chat only';

  @override
  String get reasoningOffForThisChat => 'Off for this chat only';

  @override
  String get temperatureOverride => 'Temperature';

  @override
  String get maxTokensOverride => 'Max Tokens';

  @override
  String get topPOverride => 'Top P';

  @override
  String get topKOverride => 'Top K';

  @override
  String get minPOverride => 'Min P';

  @override
  String get repeatPenaltyOverride => 'Repeat Penalty';

  @override
  String get contextLengthOverride => 'Context Length';

  @override
  String get systemPromptsTitle => 'Personas and System Prompts';

  @override
  String get addSystemPromptTooltip => 'Add prompt or persona';

  @override
  String get systemPromptsInfoText =>
      'Create and manage system prompts. Bind them to specific models or use them globally. Select one to make it active.';

  @override
  String get savedPromptsSection => 'SAVED PROMPTS';

  @override
  String get addSystemPrompt => 'Add System Prompt';

  @override
  String get newPrompt => 'New Prompt or Persona';

  @override
  String get noPromptSet => 'No prompt set';

  @override
  String get editSystemPrompt => 'Edit System Prompt';

  @override
  String get newSystemPrompt => 'New Prompt or Persona';

  @override
  String get promptNameLabel => 'Prompt Name';

  @override
  String get promptNameHint => 'e.g., Code Assistant, Creative Writer...';

  @override
  String get systemPromptLabel => 'System Prompt';

  @override
  String get systemPromptEditorHint => 'You are a helpful assistant that...';

  @override
  String get bindToModels => 'Bind to Specific Models';

  @override
  String get bindToModelsSubtitle =>
      'Restrict this prompt to certain models. When unbound, it\'s available for all models.';

  @override
  String get noModelsLoaded =>
      'No models loaded. Connect to LM Studio and load models to bind this prompt.';

  @override
  String get templatesSection => 'TEMPLATES';

  @override
  String get pleaseEnterPromptName => 'Please enter a name for this prompt';

  @override
  String get pleaseEnterPromptContent => 'Please enter the prompt content';

  @override
  String get deleteSystemPromptTitle => 'Delete System Prompt?';

  @override
  String deleteSystemPromptMessage(String name) {
    return 'Are you sure you want to delete \"$name\"? This cannot be undone.';
  }

  @override
  String get templateCodeAssistant => 'Code Assistant';

  @override
  String get templateCreativeWriter => 'Creative Writer';

  @override
  String get templateConciseExpert => 'Concise Expert';

  @override
  String get templateResearcher => 'Researcher';

  @override
  String get templateTutor => 'Tutor';

  @override
  String get templateTechnicalWriter => 'Technical Writer';

  @override
  String get downloadProgress => 'Download Progress';

  @override
  String get progressLabel => 'Progress';

  @override
  String get speedLabel => 'Speed';

  @override
  String get etaLabel => 'ETA';

  @override
  String get statusLabel => 'Status';

  @override
  String get notAvailable => 'N/A';

  @override
  String get calculating => 'Calculating...';

  @override
  String get moveToFolderPopup => 'Move to Folder';

  @override
  String contextInfo(String used, String total) {
    return 'Context: $used / $total';
  }

  @override
  String get hideAvatars => 'Hide Avatars';

  @override
  String get hideAvatarsSubtitle => 'Remove avatar icons from chat messages';

  @override
  String get autoScroll => 'Auto-scroll';

  @override
  String get autoScrollSubtitle => 'Scroll to bottom when new messages arrive';

  @override
  String get editMcpServer => 'Edit MCP Server';

  @override
  String get addMcpServer => 'Add MCP Server';

  @override
  String get serverLabelRequired => 'Server Label *';

  @override
  String get serverLabelHint => 'e.g., huggingface, tiktoken';

  @override
  String get serverLabelHelper => 'A name to identify this server';

  @override
  String get serverUrlRequired => 'Server URL *';

  @override
  String get serverUrlMcpHint => 'https://huggingface.co/mcp';

  @override
  String get serverUrlHelper => 'HTTP/HTTPS URL of the MCP server';

  @override
  String get authorizationOptional => 'API Key (Optional)';

  @override
  String get authorizationHint => 'hf_xxxxxxxx or Bearer hf_xxxxxxxx';

  @override
  String get authorizationHelper =>
      'Sent as the Authorization header to this MCP. Paste a raw token (Bearer is added) or a full header value.';

  @override
  String get additionalHeaders => 'Additional Headers';

  @override
  String get additionalHeadersHint => 'X-Custom-Header: value';

  @override
  String get additionalHeadersHelper =>
      'One header per line (name: value).\nAPI key / Authorization is set above.';

  @override
  String get labelAndUrlRequired => 'Label and URL are required';

  @override
  String get urlMustStartWithHttp => 'URL must start with http:// or https://';

  @override
  String get mcpServerUpdated => 'MCP server updated';

  @override
  String get mcpServerAdded => 'MCP server added';

  @override
  String get importMcpJsonTitle => 'Import mcp.json';

  @override
  String get pasteMcpJsonContent => 'Paste your mcp.json content';

  @override
  String get mcpJsonLocation =>
      'Find it at: ~/.lmstudio/config/mcp.json\nOr in LM Studio: Developer → MCP Settings → Open config';

  @override
  String get mcpJsonContentLabel => 'mcp.json content';

  @override
  String get mcpJsonContentHelper => 'Paste the entire mcp.json file content';

  @override
  String get parseJson => 'Parse JSON';

  @override
  String foundMcpServers(int count) {
    return 'Found $count MCP server(s):';
  }

  @override
  String get hasAuthHeaders => 'Has authentication headers';

  @override
  String importSelected(int count) {
    return 'Import $count Selected';
  }

  @override
  String get pleasePasteMcpJson => 'Please paste your mcp.json content';

  @override
  String get noMcpServersFound => 'No mcpServers found in JSON';

  @override
  String get exampleMcpServers => 'Example MCP Servers';

  @override
  String get gitMcpInfo => 'These use GitMCP to provide docs from GitHub repos';

  @override
  String get browseMoreGitMcp => 'Browse more at gitmcp.io';

  @override
  String get fileNotFound => 'File not found';

  @override
  String get openWithExternalApp => 'Open with external app';

  @override
  String get previewNotAvailable => 'Preview not available';

  @override
  String get voiceMode => 'Voice Mode';

  @override
  String get voiceSettings => 'Voice Settings';

  @override
  String get voiceSettingsSubtitle =>
      'Text-to-speech, voice input, and voice mode';

  @override
  String get voiceSection => 'Voice';

  @override
  String get voiceStatus => 'Status';

  @override
  String get voiceTtsEngine => 'Text-to-Speech Engine';

  @override
  String get voiceSttEngine => 'Speech Recognition Engine';

  @override
  String get voiceAvailable => 'Available';

  @override
  String get voiceUnavailable => 'Not available';

  @override
  String get voiceTtsSettings => 'Text-to-Speech';

  @override
  String get voiceSttSettings => 'Speech-to-Text';

  @override
  String get voiceSttProvider => 'Speech Recognition Provider';

  @override
  String get voiceSttProviderSystem => 'System speech';

  @override
  String get voiceSttProviderSystemSubtitle =>
      'Apple Speech on iOS, Google Speech on Android';

  @override
  String get voiceSttProviderWhisper => 'On-device Whisper';

  @override
  String get voiceSttProviderWhisperSubtitle =>
      'Offline sherpa-onnx Whisper — more accurate, works the same on all platforms';

  @override
  String get voiceWhisperModelNotDownloaded => 'Whisper model not downloaded';

  @override
  String get voiceWhisperModelReady => 'Whisper model ready';

  @override
  String get voiceWhisperModelSize =>
      'Choose a size — larger models transcribe more accurately';

  @override
  String get voiceWhisperDownloadButton => 'Download';

  @override
  String get voiceWhisperDownloading => 'Downloading Whisper model…';

  @override
  String get voiceWhisperDownloadStarting => 'Starting download…';

  @override
  String get voiceWhisperDownloadFailed => 'Download failed';

  @override
  String get voiceWhisperDeleteModel => 'Delete selected Whisper model';

  @override
  String get voiceWhisperDeleteTitle => 'Delete Whisper model?';

  @override
  String get voiceWhisperDeleteMessage =>
      'This frees the selected model from device storage. On-device speech recognition will fall back to system speech until you download a Whisper model again.';

  @override
  String get voiceWhisperDeleteConfirm => 'Delete';

  @override
  String get voiceWhisperFallback =>
      'Falls back to system speech if the model is not downloaded';

  @override
  String get voiceWhisperBiggerBetterTitle => 'Why bigger models?';

  @override
  String get voiceWhisperBiggerBetterBody =>
      'Larger Whisper models usually produce more accurate transcripts — especially with accents, quiet audio, background noise, and uncommon words. They also need more storage and run slower on your device.\n\nTiny is fine for short, clear speech. Base or Small is a better fit for longer files. Large v3 Turbo is the fastest/smallest of the big models (pruned Large v3). Full Large v3 is the most accurate, but also the heaviest.';

  @override
  String get voiceWhisperUseModel => 'Use';

  @override
  String get voiceWhisperSelected => 'Selected';

  @override
  String get voiceWhisperDownloaded => 'Downloaded';

  @override
  String get audioSetupTitle => 'Set up voice & audio';

  @override
  String get audioSetupMessage =>
      'Voice chat needs the assistant to speak aloud. Download a voice for the most natural sound, or use your phone\'s built-in voices — no download needed.';

  @override
  String get audioSetupWhisperStatus => 'Whisper speech recognition';

  @override
  String get audioSetupKokoroStatus => 'Kokoro neural voice';

  @override
  String get audioSetupStatusReady => 'Ready';

  @override
  String get audioSetupStatusMissing => 'Not downloaded';

  @override
  String get audioSetupOnDeviceButton => 'Download Kokoro voice';

  @override
  String get audioSetupOnDeviceSubtitle =>
      'Kokoro neural TTS · about 300 MB · works offline';

  @override
  String get audioSetupSystemButton => 'Use system speech';

  @override
  String get audioSetupSystemSubtitle =>
      'Built-in STT and TTS — no download required';

  @override
  String get audioSetupConfigureButton => 'Voice settings';

  @override
  String get audioSetupNotNow => 'Not now';

  @override
  String get audioSetupDownloadingWhisper => 'Downloading Whisper…';

  @override
  String get audioSetupDownloadingKokoro => 'Downloading Kokoro…';

  @override
  String get audioSetupDownloadComplete => 'Models ready';

  @override
  String get audioSetupContinueButton => 'Continue';

  @override
  String get voiceModeSettings => 'Voice Mode';

  @override
  String get voiceAutoRead => 'Auto-read responses';

  @override
  String get voiceAutoReadSubtitle =>
      'Automatically read new assistant messages aloud';

  @override
  String get voiceSpeechRate => 'Speech Rate';

  @override
  String get voicePitch => 'Pitch';

  @override
  String get voiceLanguage => 'Voice Language';

  @override
  String get voiceLanguageSubtitle =>
      'Language for spoken replies (text-to-speech)';

  @override
  String get voiceSttLanguage => 'Recognition language';

  @override
  String get voiceSttLanguageSubtitle =>
      'Used for the text mic and Voice Call. Can differ from spoken reply language.';

  @override
  String get voiceSelection => 'Voice Selection';

  @override
  String get voiceDefault => 'Default';

  @override
  String get voiceTestVoice => 'Test Voice';

  @override
  String get voiceTestVoiceSubtitle =>
      'Play a sample to hear the current voice settings';

  @override
  String get voiceTestPhrase => 'Hello! This is how I sound now.';

  @override
  String get voiceTestProgressInitializing => 'Starting TTS engine…';

  @override
  String get voiceTestProgressGenerating => 'Generating speech…';

  @override
  String get voiceTestProgressPreparing => 'Preparing playback…';

  @override
  String get voiceTestProgressPlaying => 'Playing sample…';

  @override
  String get voiceTestProgressConnecting => 'Connecting to remote voice…';

  @override
  String get voiceTestProgressComplete => 'Done';

  @override
  String get voiceKokoroEngineReady =>
      'Engine ready — test should start quickly';

  @override
  String get voiceKokoroEngineWarming => 'Warming up on-device engine…';

  @override
  String get voiceAutoSend => 'Auto-send after speech';

  @override
  String get voiceAutoSendSubtitle =>
      'Automatically send message when speech recognition ends';

  @override
  String get voiceSttPauseFor => 'Silence before send';

  @override
  String get voiceSttPauseForSubtitle =>
      'Seconds of silence after you stop speaking before your message is sent. This is separate from iOS mic session limits (~15s chunks, handled automatically).';

  @override
  String get voiceSttListenFor => 'Maximum listening time';

  @override
  String get voiceSttListenForSubtitle =>
      'Hard cap per mic session before the app reopens the mic. On iOS, Apple also rotates sessions about every 15 seconds during long speech.';

  @override
  String voiceSttSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String get voiceContinuousConversation => 'Continuous conversation';

  @override
  String get voiceContinuousConversationSubtitle =>
      'Automatically start listening after response is read aloud';

  @override
  String get voiceTapToSpeak => 'Tap to talk';

  @override
  String get voiceListening => 'Listening…';

  @override
  String get voiceThinking => 'One moment…';

  @override
  String get voiceResponding => 'Replying…';

  @override
  String get voiceSpeaking => 'Speaking…';

  @override
  String get voiceConvoHintIdle => 'Tap the circle to start talking';

  @override
  String get voiceConvoHintListening => 'I\'m listening — take your time';

  @override
  String get voiceConvoHintStarting => 'Getting the microphone ready…';

  @override
  String get voiceConvoHintProcessing => 'Thinking…';

  @override
  String get voiceConvoHintSpeaking => '';

  @override
  String get voiceNotAvailable =>
      'Speech recognition is not available on this device';

  @override
  String get voiceStartRecording => 'Start voice input';

  @override
  String get voiceStopRecording => 'Stop recording';

  @override
  String get voiceDiscardRecording => 'Discard';

  @override
  String get voiceSelectLanguage => 'Select Language';

  @override
  String get voiceSelectVoice => 'Select Voice';

  @override
  String get voiceNoVoicesAvailable => 'No voices available for this language';

  @override
  String get voiceAboutTitle => 'About Voice Mode';

  @override
  String get voiceAboutDescription =>
      'Voice mode can use your phone\'s built-in voices, or a downloaded voice on this device. Listening can use built-in recognition or an offline model you download. Speech stays on this device — nothing is sent to outside servers.';

  @override
  String get voiceExitMode => 'Switch to keyboard';

  @override
  String get voiceTtsProvider => 'TTS Provider';

  @override
  String get voiceTtsProviderNative => 'Device (Native)';

  @override
  String get voiceTtsProviderNativeSubtitle =>
      'Uses built-in system voices — works offline';

  @override
  String get voiceTtsProviderKokoro => 'Downloaded voice';

  @override
  String get voiceTtsProviderKokoroSubtitle =>
      'Natural voices that run on this device';

  @override
  String get voiceTtsProviderKokoroRemote => 'Kokoro (PC)';

  @override
  String get voiceTtsProviderKokoroRemoteSubtitle =>
      'Run Kokoro on your PC for faster, higher-quality speech';

  @override
  String get voiceTtsProviderElevenLabs => 'ElevenLabs';

  @override
  String get voiceTtsProviderElevenLabsSubtitle =>
      'Pro · your API key · cloud voices';

  @override
  String get voiceTtsElevenLabs => 'ElevenLabs';

  @override
  String get voiceTtsElevenLabsHint =>
      'Your key · voices from your ElevenLabs library';

  @override
  String get voiceElevenLabsApiKey => 'ElevenLabs API key';

  @override
  String get voiceElevenLabsApiKeyHint =>
      'Paste your xi-api-key from elevenlabs.io';

  @override
  String get voiceElevenLabsTestKey => 'Check key';

  @override
  String get voiceElevenLabsKeyInvalid =>
      'That key was not accepted. Check it on elevenlabs.io.';

  @override
  String get voiceElevenLabsKeyNetwork =>
      'Could not reach ElevenLabs. Check your connection.';

  @override
  String get voiceElevenLabsKeyQuota => 'This key is out of quota.';

  @override
  String get voiceElevenLabsKeyUnknown =>
      'Could not verify this key. Try again.';

  @override
  String get voiceElevenLabsPrivacy =>
      'Reply text is sent to ElevenLabs with your key. LM Mini stores the key on this device only.';

  @override
  String get voiceElevenLabsModel => 'ElevenLabs model';

  @override
  String get voiceElevenLabsVoice => 'ElevenLabs voice';

  @override
  String get voiceElevenLabsNoVoices =>
      'No voices in this account. Add voices in the ElevenLabs library first.';

  @override
  String get voiceElevenLabsChangeKey => 'Change key';

  @override
  String get voiceElevenLabsRemoveKey => 'Remove key';

  @override
  String get voiceElevenLabsReady => 'Connected to ElevenLabs';

  @override
  String get voiceElevenLabsNoKey => 'Add your ElevenLabs API key';

  @override
  String get personaElevenLabsVoiceLabel => 'ElevenLabs voice';

  @override
  String get personaElevenLabsVoiceGlobal => 'Use global ElevenLabs voice';

  @override
  String get personaElevenLabsVoicePickerTitle => 'ElevenLabs voice';

  @override
  String get personaElevenLabsVoiceAddKey =>
      'Add an API key in Voice Settings to pick an ElevenLabs voice';

  @override
  String get premiumElevenLabsTts => 'ElevenLabs voices';

  @override
  String get premiumElevenLabsTtsTagline => 'BYOK neural TTS';

  @override
  String get premiumElevenLabsTtsDescription =>
      'Bring your ElevenLabs API key and assign studio voices to personas. Voice chat, auto-read, and read-aloud use the same engine.';

  @override
  String get voiceTtsProviderGrok => 'Grok';

  @override
  String get voiceTtsProviderGrokSubtitle =>
      'Pro · your xAI API key · cloud voices';

  @override
  String get voiceTtsGrok => 'Grok';

  @override
  String get voiceTtsGrokHint => 'Your key · Grok voices from xAI';

  @override
  String get voiceGrokApiKey => 'xAI API key';

  @override
  String get voiceGrokApiKeyHint => 'Paste your API key from console.x.ai';

  @override
  String get voiceGrokTestKey => 'Check key';

  @override
  String get voiceGrokKeyInvalid =>
      'That key was not accepted. Check it on console.x.ai.';

  @override
  String get voiceGrokKeyNetwork =>
      'Could not reach xAI. Check your connection.';

  @override
  String get voiceGrokKeyQuota => 'This key is out of quota.';

  @override
  String get voiceGrokKeyUnknown => 'Could not verify this key. Try again.';

  @override
  String get voiceGrokPrivacy =>
      'Reply text is sent to xAI with your key. LM Mini stores the key on this device only.';

  @override
  String get voiceGrokVoice => 'Grok voice';

  @override
  String get voiceGrokNoVoices =>
      'No Grok voices available. Try again after checking your key.';

  @override
  String get voiceGrokChangeKey => 'Change key';

  @override
  String get voiceGrokRemoveKey => 'Remove key';

  @override
  String get voiceGrokReady => 'Connected to Grok';

  @override
  String get voiceGrokNoKey => 'Add your xAI API key';

  @override
  String get personaGrokVoiceLabel => 'Grok voice';

  @override
  String get personaGrokVoiceGlobal => 'Use global Grok voice';

  @override
  String get personaGrokVoicePickerTitle => 'Grok voice';

  @override
  String get personaGrokVoiceAddKey =>
      'Add an API key in Voice Settings to pick a Grok voice';

  @override
  String get personaVoiceSection => 'Voice';

  @override
  String get personaVoiceProviderLabel => 'Provider';

  @override
  String get personaVoiceProviderKokoro => 'Kokoro';

  @override
  String get personaVoiceProviderGlobal => 'Use global voice settings';

  @override
  String get personaVoiceConfigureInSettings =>
      'Configure under Settings → Voice';

  @override
  String get premiumGrokTts => 'Grok voices';

  @override
  String get premiumGrokTtsTagline => 'BYOK neural TTS';

  @override
  String get premiumGrokTtsDescription =>
      'Bring your xAI API key and assign Grok voices to personas. Voice chat, auto-read, and read-aloud use the same engine.';

  @override
  String get voiceRemoteKokoroConnected => 'Connected to Kokoro on PC';

  @override
  String get voiceRemoteKokoroNotFound => 'Kokoro TTS not found on PC';

  @override
  String get voiceRemoteKokoroRequiresConnect =>
      'Requires Share with phone on your Mac (or LM Mini Connect on Windows/Linux)';

  @override
  String get voiceKokoroVoice => 'Kokoro Voice';

  @override
  String get voiceKokoroSpeed => 'Speech Speed';

  @override
  String get voiceKokoroModelReady => 'Kokoro model ready';

  @override
  String get voiceKokoroModelReadySubtitle => 'Downloaded voice is ready';

  @override
  String get voiceKokoroModelNotDownloaded => 'Kokoro model not downloaded';

  @override
  String get voiceKokoroModelSize => 'Download required (~400 MB shared pack)';

  @override
  String get voiceKokoroDownloading => 'Downloading Kokoro model…';

  @override
  String get voiceKokoroDownloadStarting => 'Starting download…';

  @override
  String get voiceKokoroDownloadButton => 'Download';

  @override
  String get voiceKokoroDownloadFailed => 'Download failed. Tap to retry.';

  @override
  String get voiceKokoroFallback =>
      'Will fall back to native voice if Kokoro model is not downloaded';

  @override
  String get voiceKokoroDeleteModel => 'Delete Kokoro model';

  @override
  String get voiceKokoroDeleteTitle => 'Delete Kokoro Model?';

  @override
  String get voiceKokoroDeleteMessage =>
      'This will remove every downloaded TTS language pack. You can re-download them later.';

  @override
  String get voiceKokoroDeleteConfirm => 'Delete';

  @override
  String get voiceTtsLanguagePacksHint =>
      'English, Spanish, French, and Chinese share one download (~400 MB). German and Russian are smaller (~34 MB each).';

  @override
  String get voiceTtsLanguagePacks => 'Voice packs';

  @override
  String get voiceTtsLanguagePacksSubtitleNone =>
      'Download a language to speak on this device';

  @override
  String voiceTtsLanguagePacksSubtitleReady(int ready, int total) {
    return '$ready of $total languages ready';
  }

  @override
  String voiceTtsLanguagePacksSubtitleDownloading(String name) {
    return 'Downloading $name…';
  }

  @override
  String voiceTtsSharedPackSize(int size) {
    return 'Shared download · ~$size MB';
  }

  @override
  String voiceTtsPiperPackSize(int size) {
    return 'Smaller download · ~$size MB';
  }

  @override
  String get voiceTtsSharedPackDeleteMessage =>
      'This removes the shared download used by English, Spanish, French, and Chinese. You can download it again later.';

  @override
  String get connecting => 'Connecting...';

  @override
  String get saveAndTestConnection => 'Save & Test Connection';

  @override
  String connectedTo(String provider) {
    return '✅ Connected to $provider';
  }

  @override
  String connectionToFailed(String provider) {
    return '❌ Connection to $provider failed — check your API key';
  }

  @override
  String errorGeneric(String error) {
    return '❌ Error: $error';
  }

  @override
  String get provider => 'Provider';

  @override
  String cloudApiKeyLabel(String provider) {
    return '$provider API Key';
  }

  @override
  String get enterApiKeyHint => 'Enter your API key…';

  @override
  String getApiKey(String provider) {
    return 'Get $provider API Key';
  }

  @override
  String get baseUrl => 'Base URL';

  @override
  String get customBaseUrlOptional => 'Custom Base URL (optional)';

  @override
  String get accountSection => 'ACCOUNT';

  @override
  String get signIn => 'Sign In';

  @override
  String get signInSubtitle => 'Sign in to enable Cloud Backup';

  @override
  String get cloudServicesUnavailable => 'Cloud services unavailable';

  @override
  String signedInVia(String method) {
    return 'Signed in via $method';
  }

  @override
  String get lmMiniProSection => 'LM MINI PRO';

  @override
  String get proActive => 'Pro Active';

  @override
  String get allPremiumUnlocked => 'All premium features unlocked';

  @override
  String get upgradeToPro => 'Upgrade to Pro';

  @override
  String get unlockPremiumFeatures => 'Unlock all premium features below';

  @override
  String get proBadge => 'PRO';

  @override
  String get proFeatureTag => 'Pro Feature';

  @override
  String get betaBadge => 'BETA';

  @override
  String get imageGeneration => 'Image Generation';

  @override
  String get generatedImagesLibrary => 'Generated images';

  @override
  String get generatedImagesGallery => 'Gallery';

  @override
  String get generatedImagesShowInChat => 'Show in chat';

  @override
  String get generatedImagesLibrarySubtitle => 'View, open in chat, or delete';

  @override
  String get generatedImagesLibraryEmpty => 'No generated images yet';

  @override
  String get generatedImagesLibraryEmptyHint =>
      'Images you generate in chat are saved here.';

  @override
  String get generatedImagesSelect => 'Select';

  @override
  String get generatedImagesCancelSelect => 'Done';

  @override
  String generatedImagesDeleteN(int count) {
    return 'Delete $count';
  }

  @override
  String get generatedImagesDeleteConfirmTitle => 'Delete images?';

  @override
  String generatedImagesDeleteConfirmBody(int count) {
    return '$count image(s) will be removed from this device. Chat messages stay.';
  }

  @override
  String get generatedImagesOpenChat => 'Open in chat';

  @override
  String get saveToPhotos => 'Save to Photos';

  @override
  String get savedToPhotos => 'Saved to Photos';

  @override
  String get couldNotSaveToPhotos => 'Could not save this file.';

  @override
  String get share => 'Share';

  @override
  String get generatedImagesMissingFile => 'File missing';

  @override
  String get generatedImagesOrphan => 'Not linked to a chat';

  @override
  String get generatedImagesPrompt => 'Prompt';

  @override
  String get generatedImagesNegativePrompt => 'Negative prompt';

  @override
  String get generatedImagesDetails => 'Generation details';

  @override
  String get generatedImagesNoPrompt => 'No prompt saved';

  @override
  String get generatedImagesChatUnavailable =>
      'This chat is no longer available';

  @override
  String get generatedImagesVideo => 'Video';

  @override
  String imageGenEnabled(String url) {
    return 'Enabled — $url';
  }

  @override
  String get imageGenNotConfigured => 'Enabled — Not configured';

  @override
  String get cloudBackup => 'Cloud Backup';

  @override
  String get encryptedBackupRestore => 'Encrypted backup & restore';

  @override
  String get e2eBanner =>
      'End-to-end encrypted — your passphrase never leaves this device';

  @override
  String get analytics => 'Analytics';

  @override
  String get analyticsSubtitle => 'Usage stats, tokens & model insights';

  @override
  String get memory => 'Memories';

  @override
  String memoryItemCount(int count) {
    return '$count items • Persistent across chats';
  }

  @override
  String get premiumWebSearch => 'Premium Web Search';

  @override
  String get premiumWebSearchSubtitle => 'Instant search — no SearXNG needed';

  @override
  String get urlReader => 'URL Reader';

  @override
  String get urlReaderSubtitle => 'Read & summarize any webpage';

  @override
  String get conversationBranching => 'Conversation Branching';

  @override
  String get conversationBranchingSubtitle =>
      'Fork conversations from any message';

  @override
  String get cloudBackupPro => 'Cloud Backup';

  @override
  String get cloudBackupProSubtitle =>
      'Encrypted backup & restore to the cloud';

  @override
  String get analyticsDashboard => 'Analytics Dashboard';

  @override
  String get analyticsDashboardSubtitle =>
      'Usage stats, tokens & model insights';

  @override
  String get cloudApiProviders => 'Cloud API Providers';

  @override
  String get cloudApiProvidersSubtitle => 'Mistral, DeepSeek & more';

  @override
  String get addProviderLabel => 'Add Provider';

  @override
  String get noCloudProvidersTitle => 'No Cloud Providers';

  @override
  String get noCloudProvidersSubtitle =>
      'Tap + to add a cloud API provider.\nUse your own API keys for Groq, DeepSeek, and more.';

  @override
  String get editProviderTitle => 'Edit Provider';

  @override
  String get addCloudProviderTitle => 'Add Cloud Provider';

  @override
  String get providerLabel => 'Provider';

  @override
  String get apiKeyLabel => 'API Key';

  @override
  String get pasteLabel => 'Paste';

  @override
  String get baseUrlRequiredLabel => 'Base URL (required)';

  @override
  String get customBaseUrlOptionalLabel => 'Custom Base URL (optional)';

  @override
  String get advancedLabel => 'Advanced';

  @override
  String get fetchingLabel => 'Fetching...';

  @override
  String get fetchAvailableModelsLabel => 'Fetch Available Models';

  @override
  String get availableModelsLabel => 'Available Models:';

  @override
  String get suggestedModelsLabel => 'Suggested Models:';

  @override
  String get modelIdLabel => 'Model ID';

  @override
  String get disableCloudProviderSubtitle =>
      'Disable to keep config but not use it';

  @override
  String get setAsActiveProviderLabel => 'Set as Active Provider';

  @override
  String get deactivateLabel => 'Deactivate';

  @override
  String get switchedBackToLocalLmStudio => 'Switched back to local LM Studio';

  @override
  String get saveChangesLabel => 'Save Changes';

  @override
  String get enterDisplayNameError => 'Please enter a display name';

  @override
  String get enterApiKeyError => 'Please enter an API key';

  @override
  String get enterBaseUrlError => 'Please enter a base URL for custom provider';

  @override
  String get enterApiKeyFirst => 'Enter an API key first';

  @override
  String failedToFetchModels(String error) {
    return 'Failed to fetch models: $error';
  }

  @override
  String get deleteProviderTitle => 'Delete Provider?';

  @override
  String deleteProviderMessage(String name) {
    return 'Remove \"$name\" and its API key?';
  }

  @override
  String deleteFirstPartyOpenAiServerMessage(String name) {
    return 'Remove \"$name\" from this device?\n\nYou can’t add this server from the list anymore. To reconnect, add A.I Compatible API and set the base URL to https://api.openai.com.';
  }

  @override
  String activeProviderSet(String name) {
    return '$name set as active provider';
  }

  @override
  String get memoryPro => 'Memories';

  @override
  String get memoryProSubtitle => 'Persistent memories across conversations';

  @override
  String get richExportShare => 'Rich Export & Share';

  @override
  String get richExportShareSubtitle =>
      'Export to Obsidian, Notes, Notion & more';

  @override
  String autoUnloadAfter(String value) {
    return 'Auto-unload after $value';
  }

  @override
  String get subscriptionRestore => 'Restore';

  @override
  String get subscriptionTerms => 'Terms';

  @override
  String get subscriptionPrivacy => 'Privacy';

  @override
  String get secureYourAccount => 'Secure Your Account';

  @override
  String get signInWithApple => 'Sign in with Apple';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get subscriptionSecured => 'Your subscription is secured';

  @override
  String get packagesNotAvailable => 'Packages not available yet.';

  @override
  String get welcomeToPro => '🎉 Welcome to LM Mini Pro!';

  @override
  String get subscriptionRestored => '✅ Subscription restored!';

  @override
  String get noActiveSubscription => 'No active subscription found.';

  @override
  String get accountLinked => '✅ Account linked!';

  @override
  String get account => 'Account';

  @override
  String get createAccount => 'Create Account';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get forgotPasswordNeedEmail =>
      'Enter your email address first, then tap Forgot password.';

  @override
  String get forgotPasswordSent =>
      'If an account exists for that email, we sent a reset link. Check your inbox.';

  @override
  String get forgotPasswordFailed =>
      'Could not send a reset email. Please try again.';

  @override
  String get verificationEmailSent => 'Verification email sent!';

  @override
  String failedToSend(String error) {
    return 'Failed to send: $error';
  }

  @override
  String get cloudBackupEnabled =>
      'Enabled — your account supports encrypted backups';

  @override
  String get endToEndEncryption => 'End-to-End Encryption';

  @override
  String get e2eSubtitle =>
      'Backups encrypted with your passphrase — we can\'t read them';

  @override
  String get upgradeForCloudBackup =>
      'Upgrade to Pro to enable encrypted cloud backups';

  @override
  String get signOut => 'Sign Out';

  @override
  String get signOutConfirm => 'Sign Out?';

  @override
  String get signedOut => 'Signed out.';

  @override
  String get goToAccount => 'Go to Account';

  @override
  String get firebaseNotConfigured => 'Firebase is not configured.';

  @override
  String get refresh => 'Refresh';

  @override
  String get createBackup => 'Create Backup';

  @override
  String get encryptBackupSubtitle => 'Encrypt & back up all conversations';

  @override
  String get backUpNow => 'Back Up Now';

  @override
  String get yourBackups => 'YOUR BACKUPS';

  @override
  String get e2eBackupBanner => 'End-to-end encrypted. ';

  @override
  String get e2eBackupDetail =>
      'Your backups are encrypted with your passphrase before leaving this device. We cannot read your data.';

  @override
  String get exportingData => 'Exporting data...';

  @override
  String get preparing => 'Preparing...';

  @override
  String get encrypting => 'Encrypting...';

  @override
  String get uploading => 'Uploading...';

  @override
  String get savingMetadata => 'Saving metadata...';

  @override
  String get done => 'Done!';

  @override
  String get noBackupsYet => 'No backups yet';

  @override
  String get createFirstBackup => 'Create your first encrypted backup above';

  @override
  String get encrypted => 'Encrypted';

  @override
  String get restore => 'Restore';

  @override
  String get encryptionPassphraseLabel => 'Encryption Passphrase';

  @override
  String get enterStrongPassphrase => 'Enter a strong passphrase';

  @override
  String get confirmPassphraseLabel => 'Confirm Passphrase';

  @override
  String get passphraseRememberWarning =>
      'Remember this passphrase! If you lose it, your backups cannot be recovered. We do not store it anywhere.';

  @override
  String get passphraseRestoreHint =>
      'Enter the same passphrase you used when creating this backup.';

  @override
  String get minCharsRequired => 'At least 4 characters required.';

  @override
  String get passphrasesDoNotMatch => 'Passphrases do not match.';

  @override
  String get encryptAndBackUp => 'Encrypt & Back Up';

  @override
  String get decryptAndRestore => 'Decrypt & Restore';

  @override
  String get encryptionPassphrase => 'Encryption Passphrase';

  @override
  String get savedPassphrasePrompt =>
      'You have a saved passphrase from a previous backup. Would you like to use the same one or set a new passphrase?';

  @override
  String get newPassphrase => 'New Passphrase';

  @override
  String get useSame => 'Use Same';

  @override
  String get setEncryptionPassphrase => 'Set Encryption Passphrase';

  @override
  String get choosePassphraseBackup =>
      'Choose a passphrase to encrypt this backup. You\'ll need it to restore on any device.';

  @override
  String get choosePassphraseDetail =>
      'Choose a passphrase to encrypt your backup. This passphrase stays on your device — we never see it. You\'ll need it to restore.';

  @override
  String backupFailed(String error) {
    return 'Backup failed: $error';
  }

  @override
  String get restoreBackupConfirm => 'Restore Backup?';

  @override
  String get restoreWarning =>
      'This will REPLACE all your current conversations, messages, and folders with the data from this backup.\n\nThis cannot be undone.';

  @override
  String get continueAction => 'Continue';

  @override
  String get enterPassphrase => 'Enter Passphrase';

  @override
  String get passphraseDecryptHint =>
      'This backup is end-to-end encrypted. Enter the passphrase you used when creating it.';

  @override
  String get wrongPassphrase => 'Wrong passphrase or corrupted backup.';

  @override
  String restoreFailed(String error) {
    return 'Restore failed: $error';
  }

  @override
  String get deleteBackupConfirm => 'Delete Backup?';

  @override
  String get deleteBackupWarning =>
      'This will permanently delete this encrypted cloud backup. This cannot be undone.';

  @override
  String get backupDeleted => 'Backup deleted.';

  @override
  String deleteFailed(String error) {
    return 'Delete failed: $error';
  }

  @override
  String get overview => 'OVERVIEW';

  @override
  String get messages => 'Messages';

  @override
  String get conversations => 'Conversations';

  @override
  String get totalTokens => 'Total Tokens';

  @override
  String get avgResponse => 'Avg Response';

  @override
  String get modelUsage => 'MODEL USAGE';

  @override
  String get noModelUsageData =>
      'No model usage data yet.\nStart chatting to see stats here.';

  @override
  String get analyticsSync =>
      'Analytics are synced to your account and reset if you sign out.';

  @override
  String get clearAllMemories => 'Clear all memories';

  @override
  String get memoryOn => 'On';

  @override
  String get memoryOff => 'Off';

  @override
  String get memoryInfoText =>
      'Memories are injected into the system prompt so the LLM remembers you across conversations.';

  @override
  String get noMemoriesYet => 'No memories yet';

  @override
  String noMemoriesInCategory(String category) {
    return 'No $category memories';
  }

  @override
  String get memoryTapToAdd =>
      'Tap + to add a new memory or choose a different category.';

  @override
  String get memoryAddHint =>
      'Add facts about yourself that you want the AI to remember across all conversations.';

  @override
  String get addMemory => 'Add Memory';

  @override
  String get category => 'Category';

  @override
  String get editMemory => 'Edit Memory';

  @override
  String get deleteMemory => 'Delete Memory';

  @override
  String removeMemoryConfirm(String content) {
    return 'Remove this memory?\n\n\"$content\"';
  }

  @override
  String get clearAllMemoriesTitle => 'Clear All Memories';

  @override
  String clearAllMemoriesConfirm(int count) {
    return 'This will permanently delete all $count memories. This cannot be undone.';
  }

  @override
  String get clearAll => 'Clear All';

  @override
  String get justNow => 'just now';

  @override
  String get categoryPersonal => 'Personal';

  @override
  String get categoryPreferences => 'Preferences';

  @override
  String get categoryLifestyle => 'Lifestyle';

  @override
  String get categoryEmotional => 'Emotional';

  @override
  String get categoryTechnical => 'Technical';

  @override
  String get categoryWork => 'Work';

  @override
  String get categoryGeneral => 'General';

  @override
  String get categoryAll => 'All';

  @override
  String get modelManagement => 'Model Management';

  @override
  String get downloadNewModel => 'Download New Model';

  @override
  String get refreshModels => 'Refresh Models';

  @override
  String get tapToSelect => 'Tap to select';

  @override
  String modelSelected(String name) {
    return 'Selected: $name';
  }

  @override
  String get unloadModelTooltip => 'Unload Model from Memory';

  @override
  String get modelInfoTooltip => 'Model Info';

  @override
  String get loadedBadge => 'LOADED';

  @override
  String get visionBadge => 'Vision';

  @override
  String get toolsBadge => 'Tools';

  @override
  String get selectedModel => 'Selected Model';

  @override
  String get unloading => 'Unloading...';

  @override
  String get unload => 'Unload';

  @override
  String get loaded => 'Loaded';

  @override
  String get loadModel => 'Load Model';

  @override
  String get enterModelIdOrUrl => 'Enter a model ID or HuggingFace URL:';

  @override
  String get modelIdHint => 'microsoft/phi-4';

  @override
  String get modelIdHelper => 'Model ID or https://huggingface.co/...';

  @override
  String get huggingFaceDetected =>
      'HuggingFace URL detected - you\'ll select a quantization';

  @override
  String get starting => 'Starting...';

  @override
  String get download => 'Download';

  @override
  String get selectQuantization => 'Select Quantization';

  @override
  String get loadingQuantizations => 'Loading quantizations...';

  @override
  String get error => 'Error';

  @override
  String fetchQuantizationsFailed(String error) {
    return 'Failed to fetch quantizations: $error';
  }

  @override
  String get checkLmStudioRunning => 'Check if LM Studio is running';

  @override
  String get couldNotReachLmStudio => 'LM Mini couldn\'t reach your server.';

  @override
  String get couldNotLoadQuantizations => 'Couldn\'t load quantizations.';

  @override
  String get couldNotStartDownload => 'Could not start download.';

  @override
  String get noQuantizations => 'No Quantizations';

  @override
  String get noGgufFiles => 'No GGUF files found in this repository';

  @override
  String foundQuantizations(int count) {
    return 'Found $count GGUF quantization(s)';
  }

  @override
  String get unknown => 'unknown';

  @override
  String downloadingModel(String quantization) {
    return 'Downloading model with $quantization quantization...';
  }

  @override
  String get modelAlreadyDownloaded => 'Model already downloaded';

  @override
  String downloadFailed(String error) {
    return 'Download failed: $error';
  }

  @override
  String get enterModelIdentifier => 'Please enter a model identifier or URL';

  @override
  String get modelAlreadyLoaded => 'Model Already Loaded';

  @override
  String get currentlyLoaded => 'Currently loaded:';

  @override
  String loadAlongsideWarning(String name) {
    return 'Loading \"$name\" alongside existing model(s) will use additional memory.';
  }

  @override
  String get unloadAllAndLoad => 'Unload All & Load';

  @override
  String get swap => 'Swap';

  @override
  String get loadAlongside => 'Load Alongside';

  @override
  String get loadParamsConflictTitle => 'Load settings differ';

  @override
  String loadParamsConflictBody(String name) {
    return '\"$name\" is already loaded in LM Studio with different settings than LM Mini\'s Model Loading Config. Reloading can take a minute and use extra memory.';
  }

  @override
  String get loadParamsConflictTableHeader => 'Differing parameters:';

  @override
  String get loadParamsLmStudio => 'LM Studio';

  @override
  String get loadParamsLmMini => 'LM Mini';

  @override
  String get loadParamsConflictHint =>
      'Using LM Studio\'s loaded settings avoids a reload. Unload & reload applies your LM Mini settings. Load alongside keeps both instances in memory.';

  @override
  String get loadParamsUseExisting => 'Use LM Studio settings';

  @override
  String get loadParamsReloadWithMini => 'Unload & load with LM Mini settings';

  @override
  String get loadParamsLoadParallel => 'Load with LM Mini settings (parallel)';

  @override
  String get reloadModelForContextTitle => 'Reload model?';

  @override
  String reloadModelForContextBody(String name, String loaded, String desired) {
    return 'Context length is applied when the model loads. \"$name\" is loaded at $loaded. Reload it with $desired?';
  }

  @override
  String get reloadModelForContextNow => 'Reload';

  @override
  String get reloadModelForContextLater => 'Not now';

  @override
  String loadModelConfirm(String name) {
    return 'Load \"$name\" into memory?';
  }

  @override
  String get unloadModelTip =>
      'You can unload models using the eject button or from this screen after loading.';

  @override
  String get modelLoadedSuccess => 'Model loaded successfully';

  @override
  String get failedToLoadModel => 'Failed to load model';

  @override
  String get modelInfo => 'Model Info';

  @override
  String get infoName => 'Name';

  @override
  String get infoType => 'Type';

  @override
  String get infoArchitecture => 'Architecture';

  @override
  String get infoPublisher => 'Publisher';

  @override
  String get infoQuantization => 'Quantization';

  @override
  String get infoParameters => 'Parameters';

  @override
  String get infoSize => 'Size';

  @override
  String get infoMaxContext => 'Max Context';

  @override
  String get infoLoadedContext => 'Loaded Context';

  @override
  String get infoStatus => 'Status';

  @override
  String get available => 'Available';

  @override
  String get capabilities => 'Capabilities';

  @override
  String get standardTextGeneration => 'Standard text generation';

  @override
  String get unloadModelTitle => 'Unload Model';

  @override
  String unloadModelConfirm(String name) {
    return 'Unload \"$name\" from memory?';
  }

  @override
  String get freeResourcesTip => 'This will free up GPU/RAM resources.';

  @override
  String get modelUnloadedSuccess => 'Model unloaded successfully';

  @override
  String get failedToUnloadModel => 'Failed to unload model';

  @override
  String get enableImageGeneration => 'Enable Image Generation';

  @override
  String get showImageButtons => 'Show image buttons on chat messages';

  @override
  String get serverConnection => 'Server Connection';

  @override
  String get serverUrl => 'Server URL';

  @override
  String get test => 'Test';

  @override
  String get connected => 'Connected';

  @override
  String get model => 'Model';

  @override
  String get checkpoint => 'Checkpoint';

  @override
  String get generationParameters => 'Generation Parameters';

  @override
  String get negativePrompt => 'Negative Prompt';

  @override
  String get steps => 'Steps';

  @override
  String get cfgScale => 'CFG Scale';

  @override
  String get width => 'Width';

  @override
  String get height => 'Height';

  @override
  String get sampler => 'Sampler';

  @override
  String get scheduler => 'Scheduler';

  @override
  String get automatic => 'Automatic';

  @override
  String get seedLabel => 'Seed (-1 = random)';

  @override
  String get batchSize => 'Batch Size';

  @override
  String get options => 'Options';

  @override
  String get restoreFaces => 'Restore Faces';

  @override
  String get restoreFacesSubtitle => 'Fix faces in generated images';

  @override
  String get tiling => 'Tiling';

  @override
  String get tilingSubtitle => 'Generate seamless tileable textures';

  @override
  String get promptOptions => 'Prompt Options';

  @override
  String get reviewPromptBeforeSending => 'Review Prompt Before Sending';

  @override
  String get reviewPromptSubtitle => 'Edit the image prompt before generating';

  @override
  String get autoGenerateImage => 'Auto-Generate Image';

  @override
  String get autoGenerateSubtitle =>
      'Automatically generate image when AI provides a prompt';

  @override
  String get resetToDefaults => 'Reset to Defaults';

  @override
  String get featureRequestsTitle => 'Feature Requests';

  @override
  String get featureRequestsUnavailable => 'Feature Requests Unavailable';

  @override
  String get featureRequestsUnavailableDetail =>
      'This feature requires an internet connection. Please check your connection and try again later.';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get votesLeft => 'left';

  @override
  String get popular => 'Popular';

  @override
  String get myRequests => 'My Requests';

  @override
  String get completed => 'Completed';

  @override
  String get submitIdea => 'Submit Idea';

  @override
  String get noFeatureRequests => 'No feature requests yet';

  @override
  String get beFirstToSubmit => 'Be the first to submit an idea!';

  @override
  String get noRequestsSubmitted => 'No requests submitted';

  @override
  String get tapToSubmitFirst =>
      'Tap the button below to submit your first idea!';

  @override
  String get noCompletedRequests => 'No completed requests';

  @override
  String get completedRequestsAppear =>
      'Completed and declined requests will appear here.';

  @override
  String get adminReplied => 'Admin replied';

  @override
  String get submitFeatureRequest => 'Submit Feature Request';

  @override
  String get titleRequired => 'Title *';

  @override
  String get titleHint => 'Brief summary of your idea';

  @override
  String get descriptionRequired => 'Description *';

  @override
  String get descriptionHint => 'Describe your feature request in detail';

  @override
  String get yourNameOptional => 'Your name (optional)';

  @override
  String get leaveBlankAnonymous => 'Leave blank to submit anonymously';

  @override
  String get fillTitleAndDescription => 'Please fill in title and description';

  @override
  String get featureRequestSubmitted => 'Feature request submitted!';

  @override
  String get submit => 'Submit';

  @override
  String get featureRequest => 'Feature Request';

  @override
  String get votedTooltip => 'Voted';

  @override
  String get voteForThis => 'Vote for this';

  @override
  String get adminControls => 'Admin Controls';

  @override
  String get changeStatus => 'Change Status';

  @override
  String get officialReply => 'Official Reply';

  @override
  String get deleteRequest => 'Delete Request';

  @override
  String get unableToLoadComments => 'Unable to load comments';

  @override
  String commentsCount(int count) {
    return 'Comments ($count)';
  }

  @override
  String get readMore => 'Read more';

  @override
  String get showLess => 'Show less';

  @override
  String get deleteYourRequest => 'Delete your request';

  @override
  String get anonymous => 'Anonymous';

  @override
  String get officialResponse => 'Official Response';

  @override
  String get noCommentsYet => 'No comments yet';

  @override
  String get beFirstToComment => 'Be the first to share your thoughts!';

  @override
  String get adminBadge => 'ADMIN';

  @override
  String get moderatorBadge => 'MOD';

  @override
  String get experiencedUserBadge => 'EXP';

  @override
  String get adminManageSubmitter => 'Manage submitter';

  @override
  String get adminManageUserTitle => 'Manage user';

  @override
  String get adminUserUpdated => 'User updated';

  @override
  String get adminCommunityRoles => 'Community roles';

  @override
  String get adminModeratorRole => 'Moderator';

  @override
  String get adminModeratorRoleSubtitle =>
      'Can bypass comment spam limits and shows a Mod badge';

  @override
  String get adminExperiencedUserRole => 'Experienced user';

  @override
  String get adminExperiencedUserRoleSubtitle =>
      'Shows an Experienced badge on feature request comments';

  @override
  String get adminGrantPremiumTitle => 'Grant complimentary Pro';

  @override
  String get adminGrantPremiumSubtitle =>
      'Give this user free LM Mini Pro for a limited time';

  @override
  String get adminGrantPremiumAmountLabel => 'Duration';

  @override
  String get adminGrantPremiumAmountHint => 'Enter amount';

  @override
  String get adminGrantPremiumUnitDays => 'Days';

  @override
  String get adminGrantPremiumUnitWeeks => 'Weeks';

  @override
  String get adminGrantPremiumUnitMonths => 'Months';

  @override
  String get adminGrantPremiumGrantButton => 'Grant Pro';

  @override
  String get adminGrantPremiumInvalidAmount => 'Enter a positive number';

  @override
  String get adminGrantPremiumReasonLabel => 'Reason';

  @override
  String get adminGrantPremiumReasonHint =>
      'Optional — shown to the user (e.g. Sorry for the trouble)';

  @override
  String adminGrantPremiumDurationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String adminGrantPremiumDurationWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks',
      one: '1 week',
    );
    return '$_temp0';
  }

  @override
  String adminGrantPremiumDurationMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months',
      one: '1 month',
    );
    return '$_temp0';
  }

  @override
  String get adminRevokePremiumTitle => 'Revoke complimentary Pro';

  @override
  String get adminRevokePremiumMessage =>
      'Remove the active admin-granted Pro access for this user?';

  @override
  String get adminRevokePremiumConfirm => 'Revoke';

  @override
  String get premiumGrantBannerTitle => 'You received complimentary Pro';

  @override
  String premiumGrantBannerBody(String duration) {
    return 'Free LM Mini Pro for $duration. Enjoy premium features while it lasts.';
  }

  @override
  String premiumGrantBannerReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get premiumGrantDialogTitle => 'Complimentary Pro unlocked';

  @override
  String premiumGrantDialogBody(String duration) {
    return 'An admin granted you free LM Mini Pro for $duration. Cloud backup, memory, analytics, and more are now available.';
  }

  @override
  String premiumGrantDialogReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get premiumGrantDialogButton => 'Awesome';

  @override
  String get youBadge => 'YOU';

  @override
  String get deleteComment => 'Are you sure you want to delete this comment?';

  @override
  String maxCommentsReached(int max) {
    return 'You\'ve posted $max comments in a row. Wait for another user to reply.';
  }

  @override
  String get addYourName => 'Add your name';

  @override
  String get replyAsAdmin => 'Reply as Admin...';

  @override
  String get writeComment => 'Write a comment...';

  @override
  String get errorTryAgain => 'Error: please try again.';

  @override
  String statusUpdated(String status) {
    return 'Status updated to $status';
  }

  @override
  String get addOfficialResponse => 'Add an official response...';

  @override
  String get replySaved => 'Reply saved';

  @override
  String get deleteRequestConfirm =>
      'Are you sure you want to delete this feature request? This cannot be undone.';

  @override
  String get requestDeleted => 'Request deleted';

  @override
  String get deleteCommentTitle => 'Delete Comment';

  @override
  String get deleteCommentConfirm =>
      'Are you sure you want to delete this comment?';

  @override
  String get commentDeleted => 'Comment deleted';

  @override
  String get generationParametersSection => 'GENERATION PARAMETERS';

  @override
  String get temperature => 'Temperature';

  @override
  String get temperatureSubtitle =>
      'How creative vs focused replies are. Lower = more careful; higher = more varied.';

  @override
  String get topP => 'Top P';

  @override
  String get topPSubtitle =>
      'How wide a range of word choices to allow. Lower = more focused replies.';

  @override
  String get minP => 'Min P';

  @override
  String get minPSubtitle =>
      'Ignores very unlikely word choices. Higher = safer, more predictable text.';

  @override
  String get repeatPenalty => 'Repeat Penalty';

  @override
  String get repeatPenaltySubtitle =>
      'Discourages the AI from repeating the same phrases. 1.0 = off.';

  @override
  String get frequencyPenalty => 'Frequency Penalty';

  @override
  String get frequencyPenaltySubtitle =>
      'Cuts down on words the AI uses too often.';

  @override
  String get presencePenalty => 'Presence Penalty';

  @override
  String get presencePenaltySubtitle =>
      'Pushes the AI to bring up new topics instead of reusing old ones.';

  @override
  String get tokenLimits => 'TOKEN LIMITS';

  @override
  String get maxOutputTokens => 'Max Output Tokens';

  @override
  String get maxOutputTokensSubtitle =>
      'How long a single reply can be. Higher = longer answers (and more wait).';

  @override
  String get contextWindow => 'Context Window';

  @override
  String get contextWindowSubtitle =>
      'How much of the chat the AI can remember at once. Higher uses more memory.';

  @override
  String get modelLoadingConfig => 'MODEL LOADING CONFIG';

  @override
  String get loadContextLength => 'Context Length';

  @override
  String get loadContextSubtitle =>
      'How much context the model can use for chat and when loaded in LM Studio. Higher uses more memory / VRAM.';

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
  String get evalBatchSize => 'Eval Batch Size';

  @override
  String get evalBatchSubtitle =>
      'How much text is processed at a time while loading. Higher can be faster but uses more memory.';

  @override
  String get numExperts => 'Num Experts';

  @override
  String get numExpertsSubtitle =>
      'Only for “mixture of experts” models. Leave blank unless you know you need it.';

  @override
  String get flashAttention => 'Flash Attention';

  @override
  String get flashAttentionSubtitle =>
      'Speeds up the model and can use less memory. Keep on unless something breaks.';

  @override
  String get offloadKvCache => 'Offload KV Cache to GPU';

  @override
  String get offloadKvCacheSubtitle =>
      'Uses the GPU to remember the chat more efficiently. Keep on if you have a GPU.';

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
      'Show the AI’s step-by-step thinking when available.';

  @override
  String get reasoningUnsupportedToast =>
      'This model does not support Reasoning in LM Studio. Reasoning has been disabled.';

  @override
  String get reasoningNotExposedChatHint =>
      'LM Studio doesn\'t support turning off reasoning for this model. Try a different model.';

  @override
  String get premiumSearchActive => 'Premium Search active';

  @override
  String get premiumSearchPlusSearxng => ' + SearXNG';

  @override
  String get webSearchDisabledAll => 'Web search disabled for all chats';

  @override
  String get configureSearch => 'Configure Search';

  @override
  String get advancedFeaturesSection => 'ADVANCED FEATURES';

  @override
  String get howToolCallingWorks => 'How Tool Calling Works';

  @override
  String get stepAskQuestion => 'You ask a question';

  @override
  String get stepAskExample => 'e.g., \"What\'s the weather in Tokyo?\"';

  @override
  String get stepAiRequestsTool => 'AI requests a tool';

  @override
  String get stepAiRequestsExample => 'Model decides it needs web search';

  @override
  String get stepAppExecutes => 'App executes the tool';

  @override
  String get stepAppExecutesExample =>
      'Searches using Premium Search or SearXNG';

  @override
  String get stepResultsSent => 'Results sent to AI';

  @override
  String get stepResultsExample => 'Search results added to conversation';

  @override
  String get stepAiAnswers => 'AI generates answer';

  @override
  String get stepAiAnswersExample => 'Model synthesizes a helpful response';

  @override
  String get toolCallingModelNote => 'like Qwen, Llama 3.1+, or Mistral.';

  @override
  String get searxngSetup => 'SearXNG Setup';

  @override
  String get searxngDescription =>
      'SearXNG is a free, privacy-respecting metasearch engine that you can self-host.';

  @override
  String get dockerRecommended => 'Option 1: Docker (Recommended)';

  @override
  String get publicInstance => 'Option 2: Use a Public Instance';

  @override
  String get findPublicInstances => 'Find public instances at:';

  @override
  String get selfHostRecommended =>
      'Self-hosting is recommended for reliability.';

  @override
  String get clipboardEmpty =>
      'Clipboard is empty. Copy your mcp.json content first.';

  @override
  String get clipboardAccessFailed =>
      'Could not access clipboard. Please paste manually into the field below.';

  @override
  String get pasteFromClipboard => 'Paste from Clipboard';

  @override
  String get httpServersImportNote =>
      'HTTP servers → Ephemeral MCPs (sent to LM Studio per request)';

  @override
  String get localMcpsImportNote =>
      'Local MCPs → Integrated MCPs (uses \"mcp/name\" format)';

  @override
  String get noValidMcpServers => 'No valid MCP servers found';

  @override
  String get serverAlreadyAdded => 'This server is already added';

  @override
  String get themeSection => 'THEME';

  @override
  String get themeLabel => 'Theme';

  @override
  String get glassEffectsLabel => 'Glass effects';

  @override
  String get glassEffectsSubtitle =>
      'Frosted blur on headers and menus. Turn off to run cooler and use less battery.';

  @override
  String get lowBatteryModeLabel => 'Low battery mode';

  @override
  String get lowBatteryModeSubtitle =>
      'Turns off glass, shows plain text while the reply streams, and syncs Home/iCloud only after the message finishes. The screen stays awake until the reply is done so the stream is not cut off.';

  @override
  String get backgroundSection => 'BACKGROUND';

  @override
  String get chatBackground => 'Wallpaper';

  @override
  String get chatBackgroundSubtitle => 'Photo behind every chat';

  @override
  String get avatarsSection => 'PICTURES';

  @override
  String get chatHeaderAvatarLabel => 'Face at the top';

  @override
  String get chatHeaderAvatarSubtitle =>
      'Show a small picture in the chat header';

  @override
  String get avatarAboveMessageLabel => 'Picture above messages';

  @override
  String get avatarAboveMessageSubtitle =>
      'Place the face on top of the bubble';

  @override
  String get fullWidthAssistantLabel => 'Full-width replies';

  @override
  String get fullWidthAssistantSubtitle =>
      'Your messages stay in a bubble. Assistant text uses the whole row';

  @override
  String get tryFullWidthTitle => 'Try the new full-width view';

  @override
  String get tryFullWidthBody =>
      'Assistant replies use the whole row, with no bubble behind the text. You can switch back anytime in Appearance.';

  @override
  String get tryFullWidthOpenAppearance => 'Open Appearance';

  @override
  String get tryFullWidthNotNow => 'Not now';

  @override
  String get streamingPhaseLoadingModel => 'Loading model';

  @override
  String get streamingPhaseProcessingPrompt => 'Processing prompt';

  @override
  String get streamingPhaseThinking => 'Thinking';

  @override
  String get streamingPhaseWriting => 'Writing response';

  @override
  String get streamingPhaseSearching => 'Searching';

  @override
  String get streamingPhaseUsingTools => 'Using tools';

  @override
  String get previewUserMessage => 'What\'s the socket on this board?';

  @override
  String get bubbleAvatarSizeLabel => 'Picture size';

  @override
  String bubbleAvatarRadiusValue(int value) {
    return 'Size $value';
  }

  @override
  String get userAvatarLabel => 'You';

  @override
  String get yourProfilePicture => 'How you look in chats';

  @override
  String get assistantAvatarLabel => 'AI';

  @override
  String get aiAssistantPicture => 'Default look for the AI';

  @override
  String get chatBehaviorSection => 'CHAT TEXT';

  @override
  String get fontSizeLabel => 'Text size';

  @override
  String get iconSizeLabel => 'Button size';

  @override
  String pointsValue(int value) {
    return '$value';
  }

  @override
  String get previewLabel => 'Preview';

  @override
  String get previewAssistantMessage =>
      'Hello! I\'m your AI assistant. How can I help you today? Here\'s a **bold** word and some `inline code`.';

  @override
  String get readAloud => 'Read aloud';

  @override
  String appearanceActionTapped(String label) {
    return '$label tapped';
  }

  @override
  String get autoScrollStreaming => 'Follow new replies';

  @override
  String get autoScrollStreamingSubtitle =>
      'Keep the chat at the latest words as they appear';

  @override
  String get showChatStarters => 'New chat suggestions';

  @override
  String get showChatStartersSubtitle =>
      'Show scrolling prompt pills on empty chats';

  @override
  String get useLegacyComposer => 'Legacy message input';

  @override
  String get useLegacyComposerSubtitle =>
      'Use the classic compact composer instead of the new shine input';

  @override
  String get hideAvatarsLabel => 'Hide pictures';

  @override
  String get moreSpaceForContent => 'Gives messages a bit more room';

  @override
  String get enterKeyBehaviorLabel => 'Enter key';

  @override
  String get enterKeyAutoDescription =>
      'Send on a computer keyboard, new line on phone';

  @override
  String get enterKeySendDescription =>
      'Enter sends · Shift+Enter for a new line';

  @override
  String get enterKeyNewlineDescription => 'Enter always starts a new line';

  @override
  String get sendLabel => 'Send';

  @override
  String get newLineLabel => 'New line';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get backLabel => 'Back';

  @override
  String get nextLabel => 'Next';

  @override
  String get getStartedLabel => 'Get Started';

  @override
  String get connectionSuccessful => 'Connected successfully!';

  @override
  String get connectionFailedMessage => 'Connection failed';

  @override
  String get lmStudioServerFoundNeedsKey =>
      'Server found! Add your API key above, then tap Test Connection.';

  @override
  String get lmStudioScanServerNeedsKey => 'Found — add API key to connect';

  @override
  String lmStudioUsingServerNeedsKey(String url) {
    return 'Using $url. Add your API key below, then test the connection.';
  }

  @override
  String get lmStudioAuthDialogTitle => 'Server found';

  @override
  String get lmStudioAuthDialogMessage =>
      'This server requires an API key. Paste your LM Studio token below to connect.';

  @override
  String get lmStudioAuthHelpHint =>
      'In LM Studio, open Developer mode → Server settings → Manage tokens to create or copy your API key.';

  @override
  String get welcomeWizardTitle => 'Welcome to LM Mini';

  @override
  String get welcomeWizardSubtitle =>
      'Chat with AI models running on your local network via LM Studio. Let\'s get you set up in a few quick steps.';

  @override
  String get welcomeWizardThemeTitle => 'Choose Your Theme';

  @override
  String get welcomeWizardThemeSystemSubtitle => 'Match your device settings';

  @override
  String get welcomeWizardThemeLightSubtitle => 'Clean and bright';

  @override
  String get welcomeWizardThemeDarkSubtitle => 'Easy on the eyes';

  @override
  String get welcomeWizardAppearanceTitle => 'Customize Appearance';

  @override
  String get welcomeWizardAppearancePreviewMessage =>
      'Hello! This is how your chat messages will look.';

  @override
  String get welcomeWizardServerTitle => 'Connect to LM Studio';

  @override
  String get welcomeWizardServerSubtitle =>
      'Enter the IP address of the computer running LM Studio on your local network.';

  @override
  String get welcomeWizardLocalNetworkNote =>
      'iOS will ask for local network permission when you test the connection. Please allow it.';

  @override
  String get apiTokenOptionalLabel => 'API Token (optional)';

  @override
  String get welcomeWizardChangeLater =>
      'You can always change this later in Settings.';

  @override
  String get welcomeWizardFindModelTitle => 'Find a model that fits';

  @override
  String get welcomeWizardFindModelSubtitle =>
      'Race two options and see which is faster on your setup. Takes about a minute — or skip if you already know what you want.';

  @override
  String get welcomeWizardFindModelHelp => 'Help me pick';

  @override
  String get welcomeWizardFindModelSkip => 'Skip — I\'ll choose myself';

  @override
  String get welcomeWizardExperienceTitle => 'How do you use AI?';

  @override
  String get welcomeWizardExperienceSubtitle =>
      'We\'ll tailor recommendations. You can change everything later.';

  @override
  String get welcomeWizardBeginnerTitle => 'Beginner';

  @override
  String get welcomeWizardBeginnerSubtitle =>
      'Keep it simple — clearer Settings, and we\'ll suggest a solid model for your phone.';

  @override
  String get welcomeWizardPowerTitle => 'Power user';

  @override
  String get welcomeWizardPowerSubtitle =>
      'Full Settings plus choices — on-device models and desktop servers like LM Studio.';

  @override
  String get welcomeWizardSetupTitleBeginner => 'Choose a model';

  @override
  String get welcomeWizardSetupTitlePower => 'Choose your setup';

  @override
  String get welcomeWizardSetupSubtitleBeginner =>
      'Tap a model to download. Or connect a computer on your Wi‑Fi.';

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
  String get pickColor => 'Pick Color';

  @override
  String get hueLabel => 'Hue';

  @override
  String get saturationLabel => 'Saturation';

  @override
  String get lightnessLabel => 'Lightness';

  @override
  String get alphaLabel => 'Alpha';

  @override
  String get hexLabel => 'Hex';

  @override
  String get personaModeLabel => 'Persona Mode';

  @override
  String get personaModeSubtitle =>
      'Add avatar, accent color, voice, and preferred model for group chats';

  @override
  String get avatarLabel => 'Avatar';

  @override
  String get customAvatarSet => 'Custom avatar set';

  @override
  String get noAvatar => 'No avatar';

  @override
  String get accentColorLabel => 'Accent Color';

  @override
  String get defaultLabel => 'Default';

  @override
  String get preferredModelLabel => 'Preferred Model';

  @override
  String get preferredModelAny => 'None (use any)';

  @override
  String get personaChooseProviderTitle => 'Choose provider';

  @override
  String get personaChooseProviderSubtitle =>
      'Your configured providers. Add more in Settings.';

  @override
  String get personaCloudProvidersSection => 'Cloud providers';

  @override
  String get personaKokoroVoiceLabel => 'Kokoro Voice';

  @override
  String get personaKokoroVoiceSubtitle =>
      'Voice used when this persona speaks (voice chat / read aloud)';

  @override
  String get personaKokoroVoiceGlobal => 'Use global voice setting';

  @override
  String get personaKokoroVoicePickerTitle => 'Persona Voice';

  @override
  String get personaKokoroSpeedLabel => 'Speech Speed';

  @override
  String get personaKokoroSpeedGlobal => 'Use global speed';

  @override
  String personaKokoroSpeedValue(String speed) {
    return '${speed}x';
  }

  @override
  String get voiceWhisperModelLabel => 'Whisper model';

  @override
  String get voiceWhisperModelTapToChoose => 'Tap to choose size and download';

  @override
  String get imageGenSeedLabel => 'Image Gen Seed';

  @override
  String imageGenSeedFixed(int seed) {
    return 'Fixed seed: $seed';
  }

  @override
  String get imageGenSeedRandomGlobal => 'Random (use global setting)';

  @override
  String get personaComfyWorkflowLabel => 'ComfyUI workflow';

  @override
  String get personaComfyWorkflowUseGlobal => 'Use global setting';

  @override
  String personaComfyWorkflowUnavailable(String path) {
    return '$path (currently unavailable)';
  }

  @override
  String get personaComfyWorkflowHelper =>
      'Used when Image Generation provider is ComfyUI. Leave as global to use Settings → Image Generation.';

  @override
  String get personaComfyWorkflowNotComfy =>
      'This assignment applies only when ComfyUI is the active image provider.';

  @override
  String get personaComfyWorkflowRefresh => 'Refresh workflows';

  @override
  String get personaComfyWorkflowJsonLabel => 'Custom workflow JSON (optional)';

  @override
  String get personaComfyWorkflowJsonHint =>
      'Leave empty to use the global / built-in workflow';

  @override
  String get personaComfyWorkflowJsonHelper =>
      'Paste an API-format workflow. Supports %PROMPT%, %LORA%, %LORA_WEIGHT%, and other placeholders.';

  @override
  String get personaComfyWorkflowJsonIgnored =>
      'Ignored while a saved workflow is selected';

  @override
  String personaComfyWorkflowJsonActive(int count) {
    return 'Using custom workflow ($count chars)';
  }

  @override
  String get personaComfyWorkflowJsonClear => 'Clear (use global / default)';

  @override
  String get comfyUiDetails => 'ComfyUI details';

  @override
  String get comfyUiDetailsTitle => 'ComfyUI request';

  @override
  String get comfyUiDetailsCopy => 'Copy JSON';

  @override
  String get comfyUiDetailsCopied => 'Copied to clipboard';

  @override
  String get resetToGlobal => 'Reset to global';

  @override
  String get setSeed => 'Set seed';

  @override
  String get pickAccentColor => 'Pick Accent Color';

  @override
  String get imageGenSeedDialogDescription =>
      'Set a fixed seed so this persona always generates consistent images. Leave blank for random.';

  @override
  String get seedValueLabel => 'Seed value';

  @override
  String get seedValueHint => 'e.g. 42 (blank = random)';

  @override
  String get setLabel => 'Set';

  @override
  String get selectPreferredModelTitle => 'Select Preferred Model';

  @override
  String get branchCreated => '🔀 Branch created';

  @override
  String get yamlFrontmatter => 'YAML frontmatter';

  @override
  String get markdownFormat => 'Markdown';

  @override
  String get localNetworkBlocked => 'Local Network access may be blocked';

  @override
  String get localNetworkFix =>
      'Go to Settings → LM Mini → Local Network and enable it.';

  @override
  String get openAppSettings => 'Open App Settings';

  @override
  String get memorySaved => 'Memory saved';

  @override
  String get proSearch => 'Pro Search';

  @override
  String get webSearchLabel => 'Web search';

  @override
  String get readUrl => 'Read URL';

  @override
  String get code => 'code';

  @override
  String couldNotOpenFile(String error) {
    return 'Could not open file: $error';
  }

  @override
  String get tapOpenExternal =>
      'Tap \"Open with external app\" to view this file';

  @override
  String get proSearchEnabled => 'Pro Search enabled';

  @override
  String get proSearchDisabled => 'Pro Search disabled';

  @override
  String get thinkingEnabled => 'Thinking on for this chat';

  @override
  String get thinkingDisabled => 'Thinking off for this chat';

  @override
  String get codeSandbox => 'Code Sandbox';

  @override
  String get codeSandboxSubtitle =>
      'Run Python or JavaScript in a secure sandbox';

  @override
  String get codeSandboxEnabled => 'Code Sandbox enabled';

  @override
  String get codeSandboxDisabled => 'Code Sandbox disabled';

  @override
  String get searxngNotConfigured => 'Add a SearXNG URL to enable';

  @override
  String get searxngConfiguredOff =>
      'Configured — tap to use instead of Pro Search';

  @override
  String get searxngConfigureFirst => 'Configure a SearXNG URL before enabling';

  @override
  String get editSearxng => 'Edit SearXNG';

  @override
  String get toolCallingLabel => 'Tool Calling';

  @override
  String get on => 'On';

  @override
  String get off => 'Off';

  @override
  String get aiCanUseTools => 'AI can use tools in this chat';

  @override
  String get toolsDisabledChat => 'Tools disabled for this chat';

  @override
  String get webSearchChat => 'Web Search';

  @override
  String get aiCanSearchWeb => 'AI can search the web in this chat';

  @override
  String get webSearchDisabledChat => 'Web search disabled for this chat';

  @override
  String get disableMemory => 'Disable Memories';

  @override
  String memoryItemsActive(int count) {
    return '$count memories active';
  }

  @override
  String get memoryDisabledChat =>
      'Memories are disabled for this chat. The AI won\'t see your saved items.';

  @override
  String get lmStudioLocal => 'LM Studio (Local)';

  @override
  String get modelNoLongerAvailable =>
      'Previously selected model is no longer available. Please select a new model.';

  @override
  String get noModelsForProvider =>
      'No models found for this provider. Check API key.';

  @override
  String get noModelsCheckConnection =>
      'No models found. Check LM Studio connection.';

  @override
  String get selectModel => 'Select model';

  @override
  String get goToModels => 'Go to models';

  @override
  String get reviewImagePrompt => 'Review Image Prompt';

  @override
  String get editImagePromptHint => 'Edit the image prompt...';

  @override
  String get generate => 'Generate';

  @override
  String get imageNotFound => 'Image not found';

  @override
  String get cameraPermissionNeeded => 'Camera Permission Needed';

  @override
  String get cameraPermissionExplain =>
      'Please allow camera access to take photos for vision analysis.';

  @override
  String get photosPermissionNeeded => 'Photos Permission Needed';

  @override
  String get photosPermissionExplain =>
      'Please allow access to your images for vision analysis.';

  @override
  String couldNotOpenFilePicker(String error) {
    return 'Could not open file picker: $error';
  }

  @override
  String get filePickerCouldNotCopy =>
      'Couldn\'t copy that file. Save it on this phone (not Drive or Recents) and pick it again.';

  @override
  String get signInToUseCloudBackup => 'Sign in to use Cloud Backup';

  @override
  String get cloudBackupRequiresAccount =>
      'Cloud Backup requires an account so your encrypted backups are stored securely under your identity.';

  @override
  String get arguments => 'Arguments';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get connectionPopupTitle => 'Choose a provider';

  @override
  String get connectionPopupBody =>
      'Connect LM Studio, pick an On-Device model, or sign in to a cloud provider in Settings.';

  @override
  String get connectionPopupDismiss => 'Later';

  @override
  String get connectionPopupGoToSettings => 'Go to Settings';

  @override
  String get remoteAccess => 'Remote Access';

  @override
  String get scanQrCode => 'Scan QR Code';

  @override
  String get connectedViaLmConnect => 'Connected via LM Connect';

  @override
  String get disconnectRemoteToChangeSettings =>
      'Remote LM Studio is paired via LM Connect';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get unpair => 'Unpair';

  @override
  String get useRemoteConnection => 'Chat with this Mac';

  @override
  String get useRemoteConnectionOffSubtitle =>
      'Off — this phone uses its own models. Turn on to use models on LM Mini Home.';

  @override
  String get connectedViaLmStudio => 'Connected via LM Studio';

  @override
  String get usingLocalServer => 'Using local server';

  @override
  String get testing => 'Testing...';

  @override
  String connectedLatency(int ms) {
    return 'Connected — ${ms}ms';
  }

  @override
  String get notConnected => 'Not Connected';

  @override
  String get scanQrDescription =>
      'Scan a QR code from LM Mini on Mac (Share with phone) — or legacy LM Mini Connect — to reach your desktop models from anywhere.';

  @override
  String get remotePaired => 'Remote Paired';

  @override
  String lastConnected(String time) {
    return 'Last connected: $time';
  }

  @override
  String get reScanQrCode => 'Re-scan QR Code';

  @override
  String get qrRequiresPro => 'QR code scanning requires LM Mini Pro';

  @override
  String get enterUrlManually => 'Enter URL manually';

  @override
  String get enterUrlManuallySubtitle =>
      'Paste a pairing link if the camera is unavailable';

  @override
  String get relayUrlHint => 'https://relay.lmmini.com/s/…';

  @override
  String get connectWithUrl => 'Connect with URL';

  @override
  String get invalidRelayUrl =>
      'That is not a valid LM Mini pairing link. Copy it from Share with phone on your Mac.';

  @override
  String get invalidQrCode =>
      'Invalid QR code. Open Share with phone in LM Mini on Mac (or legacy Connect) to generate one.';

  @override
  String get pointCameraAtQr =>
      'Point your camera at the QR code shown in LM Mini on Mac (Share with phone)';

  @override
  String get connectedToRemoteLmStudio => 'Connected to remote LM Studio!';

  @override
  String get failedToConnect =>
      'Failed to connect. Make sure LM Mini on Mac has Share with phone enabled (or legacy Connect is running).';

  @override
  String get unpairRemote => 'Unpair Remote';

  @override
  String get unpairRemoteDescription =>
      'This will remove the saved remote connection. You can re-pair by scanning a new QR code.';

  @override
  String get setupGuide => 'Setup Guide';

  @override
  String get downloadLmMiniConnect => 'Get LM Mini Home';

  @override
  String get availableForPlatforms =>
      'Direct download for Mac · Connect for Windows and Linux';

  @override
  String get setupStep1Title => 'Download LM Mini Home';

  @override
  String get setupStep1Desc =>
      'Get LM Mini Home for Mac from lmmini.com. On Windows and Linux you can still use LM Mini Connect.';

  @override
  String get setupStep2Title => 'Share with phone';

  @override
  String get setupStep2Desc =>
      'In LM Mini Home on your Mac, open Share with phone and turn it on. It connects to the relay instantly.';

  @override
  String get setupStep3Title => 'Scan QR Code';

  @override
  String get setupStep3Desc =>
      'Scan the QR code shown on your Mac. That\'s it!';

  @override
  String minutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String hoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String daysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String get selectAll => 'Select all';

  @override
  String get moveToFolder => 'Move to folder';

  @override
  String get select => 'Select';

  @override
  String get dismissAction => 'Dismiss';

  @override
  String get createNewFolder => 'Create new folder';

  @override
  String deleteConversations(int count) {
    return 'Delete $count conversation(s)? This cannot be undone.';
  }

  @override
  String get averages => 'AVERAGES';

  @override
  String get tokensPerChat => 'Tokens / Chat';

  @override
  String get msgsPerChat => 'Msgs / Chat';

  @override
  String get tokensPerMsg => 'Tokens / Msg';

  @override
  String get topModel => 'Top Model';

  @override
  String get liveActivityTitle => 'Live Activity';

  @override
  String get liveActivityTitleAndroid => 'Background generation';

  @override
  String get liveActivityDescription =>
      'Process your A.I. request even when you exit the app or lock it';

  @override
  String get liveActivityDescriptionAndroid =>
      'Keep generating when you leave the app — on-device models, LM Studio, and cloud providers. Shows a silent ongoing notification with progress and keeps the HTTP stream alive on Android.';

  @override
  String get liveActivityAndroidOnDeviceOnly =>
      'Switch to an on-device GGUF or MLX model to use background generation on Android.';

  @override
  String get liveActivityNotificationDenied =>
      'Notification permission is required for background generation on Android.';

  @override
  String get premiumRemoteAccess => 'Remote Access';

  @override
  String get premiumRemoteAccessTagline => 'LM Studio from anywhere';

  @override
  String get premiumRemoteAccessDescription =>
      'Access your Mac or PC models from anywhere. On Mac, use LM Mini → Share with phone. No port forwarding or VPN — scan a QR code for an encrypted relay.';

  @override
  String get premiumLiveActivity => 'Live Activity';

  @override
  String get premiumLiveActivityTagline => 'A.I. works in the background';

  @override
  String get premiumLiveActivityDescription =>
      'Process your A.I. request even when you exit the app or lock the phone. See real-time generation progress on your Lock Screen and Dynamic Island — watch tokens counting up and generation speed without switching back.';

  @override
  String get premiumWebSearchTagline => 'No server setup required';

  @override
  String get premiumWebSearchDescription =>
      'Instantly search the web during conversations. Powered by cloud search APIs — no need to self-host SearXNG or configure anything. Just ask and your model gets fresh, real-time information from the internet.';

  @override
  String get premiumCloudBackup => 'Encrypted Cloud Backup';

  @override
  String get premiumCloudBackupTagline => 'AES-256-GCM encryption';

  @override
  String get premiumCloudBackupDescription =>
      'Back up all conversations to the cloud with military-grade encryption. Your passphrase never leaves your device — not even we can read your data. Restore on any device with one tap.';

  @override
  String get premiumUrlReader => 'URL Reader';

  @override
  String get premiumUrlReaderTagline => 'Analyze any webpage';

  @override
  String get premiumUrlReaderDescription =>
      'Paste any URL and your model reads the full page content. Summarize articles, analyze documentation, extract data from tables — all without leaving the conversation.';

  @override
  String get premiumBranching => 'Conversation Branching';

  @override
  String get premiumBranchingTagline => 'Explore alternate paths';

  @override
  String get premiumBranchingDescription =>
      'Fork any conversation from any message to explore \"what if\" scenarios. Compare different prompts, try various approaches, and keep your best threads — all without losing the original.';

  @override
  String get premiumMemory => 'Memories';

  @override
  String get premiumMemoryTagline => 'Remembers you across chats';

  @override
  String get premiumMemoryDescription =>
      'Save facts, preferences, and context that persist across all conversations. Your model will know your name, coding style, preferred language, and anything else you teach it — every time you start a new chat.';

  @override
  String get premiumAnalytics => 'Analytics Dashboard';

  @override
  String get premiumAnalyticsTagline => 'Know your usage';

  @override
  String get premiumAnalyticsDescription =>
      'Track tokens used, messages sent, model usage breakdown, and average response times. Understand your AI usage patterns and optimize your workflow with beautiful charts.';

  @override
  String get premiumCloudApi => 'Cloud API Providers';

  @override
  String get premiumCloudApiTagline => 'Mistral, Anthropic & more';

  @override
  String get premiumCloudApiDescription =>
      'Connect to cloud LLM providers alongside your local models. Use Claude, Gemini, and Mistral when you need cutting-edge performance — seamlessly switch between local and cloud.';

  @override
  String get premiumExport => 'Rich Export & Share';

  @override
  String get premiumExportTagline => 'Obsidian, Notes, Notion & more';

  @override
  String get premiumExportDescription =>
      'Export conversations as beautifully formatted Markdown, PDF, or plain text. Share directly to Obsidian, Apple Notes, Notion, or any app. Perfect for saving research and insights.';

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
  String get premiumOnDeviceLlmTagline => 'Bigger catalog models & HF imports';

  @override
  String get premiumOnDeviceLlmDescription =>
      'On-device chat is free with curated starter models. Pro unlocks catalog downloads above 2B parameters and importing your own GGUF or MLX models from Hugging Face — browse, pick a quantization, and run fully offline.';

  @override
  String get premiumHfBrowse => 'Hugging Face Import';

  @override
  String get premiumHfBrowseTagline => 'Bring any GGUF model onboard';

  @override
  String get premiumHfBrowseDescription =>
      'Search Hugging Face, download GGUF models to your device or LM Studio server, and run them in LM Mini. Filter for compatibility, track background downloads, and expand beyond the free catalog — no API key required.';

  @override
  String get onDeviceProviderLabel => 'On-Device';

  @override
  String get onDeviceManageModels => 'Manage On-Device Models';

  @override
  String get onDeviceGeneratingHint => 'Generating on-device…';

  @override
  String get onDeviceEngineUnavailable => 'On-device engine unavailable';

  @override
  String get onDeviceOpenBrowser => 'Open On-Device Models';

  @override
  String get onDeviceManagedHere =>
      'On-Device models are managed in a dedicated browser where you can download, remove and activate them.';

  @override
  String get onDeviceRemoteImageOnly =>
      'On-Device AI is selected — remote access powers image generation and Kokoro voice (if configured) only. Chat stays on this device.';

  @override
  String get onDeviceProOnly => 'Pro only';

  @override
  String get onDeviceInstalled => 'Installed';

  @override
  String get onDeviceUseModel => 'Use';

  @override
  String get onDeviceRemoveModel => 'Remove';

  @override
  String get onDeviceDownloadAnyway => 'Download anyway';

  @override
  String onDeviceNowUsing(String name) {
    return 'Now using $name on-device';
  }

  @override
  String get onDeviceEngineFllamaLabel => 'fllama (GGUF)';

  @override
  String onDeviceEngineSwitched(String engine) {
    return 'Switched to $engine. The previous model was unloaded.';
  }

  @override
  String onDeviceEngineSwitchedCleared(String engine) {
    return 'Switched to $engine. Your previous model isn\'t compatible with this engine and was deselected — pick one in On-Device Models.';
  }

  @override
  String get onDeviceImportedLabel => 'Imported';

  @override
  String get onDeviceFreeLabel => 'Free';

  @override
  String get onDeviceProLabel => 'Pro';

  @override
  String get onDeviceMayCrashLabel => 'May crash';

  @override
  String get onDeviceModelMayCrashTitle => 'This model may crash';

  @override
  String onDeviceModelMayCrashMessage(
      String name, String runtimeGb, String deviceRamGb) {
    return '$name needs roughly $runtimeGb GB of memory at runtime. Your device has about $deviceRamGb GB available for apps. Loading anyway may freeze or crash the app.';
  }

  @override
  String get onDeviceContinueLoading => 'Continue loading';

  @override
  String get yearly => 'Yearly';

  @override
  String get monthly => 'Monthly';

  @override
  String get lifetime => 'Lifetime';

  @override
  String get subscriptionLifetimeBadge => 'Pay once';

  @override
  String get subscriptionLifetimeDisclaimer =>
      'One-time purchase. Pro features on your account while LM Mini is offered and maintained. Excludes third-party API fees and may exclude separately hosted services — see Terms.';

  @override
  String subscriptionLifetimeUpgradeDisclaimer(String store) {
    return 'Lifetime is a separate one-time purchase. Your current subscription will not be cancelled automatically, and we cannot refund past subscription charges. After purchasing, cancel your subscription in the $store.';
  }

  @override
  String get subscriptionUpgradeToLifetime => 'Upgrade to Lifetime';

  @override
  String subscriptionUpgradeToLifetimeSubtitle(String price) {
    return 'Pay once — $price';
  }

  @override
  String get duplicateSubscriptionDialogTitle => 'Cancel your subscription';

  @override
  String duplicateSubscriptionDialogBody(String store) {
    return 'You have Lifetime Pro and an active subscription. Lifetime does not replace your subscription automatically, and we cannot refund subscription charges. Please cancel your subscription in the $store to avoid further billing.';
  }

  @override
  String duplicateSubscriptionDialogManage(String store) {
    return 'Open $store';
  }

  @override
  String get duplicateSubscriptionDialogDismiss => 'Got it';

  @override
  String get duplicateSubscriptionNoManageUrl =>
      'Open your device subscription settings to cancel.';

  @override
  String supportLifetime(String price) {
    return 'Unlock forever — $price';
  }

  @override
  String get encryptionKey => 'Encryption Key';

  @override
  String get encryptionEnabled => 'Encryption: On';

  @override
  String get encryptionDisabled => 'Encryption: Off';

  @override
  String get encryptionKeyDescription =>
      'End-to-end encryption key for remote access. Must match the key in LM Mini Home on your Mac.';

  @override
  String get editEncryptionKey => 'Edit Encryption Key';

  @override
  String get enterEncryptionKey => 'Enter encryption key';

  @override
  String get encryptionKeyUpdated => 'Encryption key updated';

  @override
  String get keepLmMiniAlive => 'Keep LM Mini\nAlive';

  @override
  String get supportTheApp => 'Support the app & get premium perks';

  @override
  String get mostFeaturesFree =>
      'Most features are free — Pro helps cover server costs';

  @override
  String get thankYouSupport => 'Thank you for your support!';

  @override
  String get helpingKeepAlive => 'You\'re helping keep LM Mini alive';

  @override
  String get linkSignInMethod =>
      'Link a sign-in method to keep your subscription if you switch devices.';

  @override
  String get paywallLinkAccountBody =>
      'You\'re on an anonymous account. Link Apple or Google before purchasing so Pro syncs across devices and survives reinstall.';

  @override
  String get continueAnonymously => 'Continue anonymously';

  @override
  String signedInViaMethod(String method) {
    return 'Signed in via $method';
  }

  @override
  String get yourSubscriptionSecured => 'Your subscription is secured';

  @override
  String subscriptionManagedThrough(String store) {
    return 'Subscription managed through the $store.';
  }

  @override
  String get subscriptionsComingSoon => 'Subscriptions Coming Soon';

  @override
  String get premiumPreview =>
      'Premium features are being finalized.\nYou can enable developer mode below to preview them.';

  @override
  String get enableDeveloperPremium => 'Enable Developer Premium';

  @override
  String get disableDeveloperPremium => 'Disable Developer Premium';

  @override
  String get premiumEnabled => 'Premium enabled (dev override)';

  @override
  String get premiumDisabled => 'Premium disabled';

  @override
  String supportYearly(String price) {
    return 'Support — $price/year';
  }

  @override
  String supportMonthly(String price) {
    return 'Support — $price/month';
  }

  @override
  String get welcomeToLmMiniPro => 'Welcome to LM Mini Pro!';

  @override
  String get connectedRemotely => 'Connected remotely';

  @override
  String get pairedNotActive => 'Paired — not active';

  @override
  String get accessLmStudioAnywhere => 'Access LM Studio from anywhere';

  @override
  String get appStore => 'App Store';

  @override
  String get googlePlayStore => 'Google Play Store';

  @override
  String get starterAttach => 'Attach';

  @override
  String get starterImages => 'Images';

  @override
  String get starterMode => 'Mode';

  @override
  String get newGroupChat => 'New Group Chat';

  @override
  String get groupChat => 'Group Chat';

  @override
  String get groupChatMultipleModels => 'Chat with multiple models';

  @override
  String get groupChatParticipants => 'Participants';

  @override
  String get groupChatTurnMode => 'Turn Mode';

  @override
  String get groupChatRoundRobin => 'Round Robin';

  @override
  String get groupChatManual => 'Manual';

  @override
  String get groupChatParallelStreaming => 'Parallel Streaming';

  @override
  String get groupChatAutoLoadUnload => 'Auto Load/Unload';

  @override
  String get groupChatStreamAllSimultaneously =>
      'Stream all participants simultaneously';

  @override
  String get groupChatAutoLoadModels => 'Automatically load models when needed';

  @override
  String get groupChatAsk => 'Ask:';

  @override
  String get groupChatTapToReplyNudge => 'Tap who should reply';

  @override
  String get groupChatTrialBannerTitle => 'Group Chat — Free for 7 Days!';

  @override
  String get groupChatTrialBannerBody =>
      'Try Group Chat free for 7 days with up to 2 AI personas. Upgrade to LM Mini Pro for unlimited participants and permanent access.';

  @override
  String groupChatTrialDaysLeft(int days) {
    return '$days days left in your trial';
  }

  @override
  String get groupChatTrialExpired =>
      'Your 7-day Group Chat trial has ended. Upgrade to Pro to continue.';

  @override
  String get groupChatTrialGetPro => 'Get Pro';

  @override
  String get groupChatTrialDismiss => 'Got it';

  @override
  String get groupChatBetaTitle => 'Group Chat';

  @override
  String get groupChatBetaSubtitle => 'One conversation. Multiple AI minds.';

  @override
  String get groupChatBetaPremiumNote =>
      'Group Chat is currently in beta and it\'s available to everyone as a free preview';

  @override
  String get groupChatBetaBugReport =>
      'Found a bug? Go to Settings → Feature Requests & Support to report it and get priority help.';

  @override
  String get groupChatBetaFreeNote =>
      'You have 7 days of free access with up to 2 personas. Upgrade to Pro for unlimited personas and permanent access.';

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
  String get premiumGroupChat => 'Group Chat';

  @override
  String get premiumGroupChatTagline => 'Multi-persona conversations';

  @override
  String get premiumGroupChatDescription =>
      'Chat with multiple AI personas in one thread — each with its own model, avatar, and personality. Set up freely; sending messages requires LM Mini Pro.';

  @override
  String get groupChatProRequiredTitle => 'Group Chat requires Pro';

  @override
  String get groupChatProRequiredBody =>
      'You can set up Group Chat for free. Upgrade to LM Mini Pro to start the chat and send messages with multiple AI personas.';

  @override
  String get groupChatProRequiredUpgrade => 'Upgrade to Pro';

  @override
  String get groupChatLockedBanner =>
      'Group Chat is read-only without Pro. Upgrade to send new messages.';

  @override
  String get premiumArena => 'Arena';

  @override
  String get premiumArenaTagline => 'Compare models side-by-side';

  @override
  String get premiumArenaDescription =>
      'Finding your model is free. Pro unlocks custom prompt races, cloud models in Arena, and private race history with charts.';

  @override
  String get startLabel => 'Start';

  @override
  String groupChatInviteUpTo(int count) {
    return 'Invite up to $count AI models to chat together. Each can have its own persona, avatar, and system prompt.';
  }

  @override
  String get groupChatPremiumParticipantsNote =>
      'Premium allows up to 5 participants per group chat.';

  @override
  String get groupChatUserNameHint => 'How AIs will address you (e.g. Alex)';

  @override
  String get groupChatScenarioLabel => 'Scenario / about yourself (optional)';

  @override
  String get groupChatScenarioHint =>
      'e.g. \"We are colleagues at a tech startup. I am a product manager asking the team for advice.\"';

  @override
  String get groupChatTurnModeRoundRobinDescription =>
      'Round Robin — all models respond in order';

  @override
  String get groupChatTurnModeManualDescription =>
      'Manual — type @Name to choose who replies';

  @override
  String get groupChatReplyToUserOnlyLabel => 'Reply to you only';

  @override
  String get groupChatReplyToUserOnlySubtitle =>
      'Each AI ignores the other AIs — best for smaller models';

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
      'No models available. Connect to LM Studio first.';

  @override
  String get addModelLabel => 'Add Model';

  @override
  String modelNumber(int number) {
    return 'Model $number';
  }

  @override
  String groupChatParticipantInfo(String name, String model) {
    return '$name\nModel: $model';
  }

  @override
  String get customPromptSet => 'Custom prompt set';

  @override
  String get removeLabel => 'Remove';

  @override
  String get displayNameLabel => 'Display Name';

  @override
  String get displayNameHint => 'e.g. Professor, Coder, Artist';

  @override
  String get customRequestHeaders => 'Custom request headers';

  @override
  String get customRequestHeadersSubtitle =>
      'Optional headers added to every LM Studio request';

  @override
  String get customRequestHeadersHelp =>
      'Use this for reverse proxies or auth gateways that require extra headers (e.g. Cloudflare Access service tokens, an internal token under a custom header name, etc.). Headers are sent on every request to your LM Studio server.';

  @override
  String get cloudflareAccessSection => 'Cloudflare Access (service token)';

  @override
  String get cloudflareAccessHelp =>
      'If your LM Studio is behind a Cloudflare Access policy, paste the service-token Client ID and Secret here. They are sent as CF-Access-Client-Id and CF-Access-Client-Secret on every request, so the app can authenticate without an interactive browser SSO login.';

  @override
  String get cfAccessClientIdLabel => 'CF-Access-Client-Id';

  @override
  String get cfAccessClientSecretLabel => 'CF-Access-Client-Secret';

  @override
  String get addHeader => 'Add header';

  @override
  String get removeHeader => 'Remove header';

  @override
  String get headerNameLabel => 'Header name';

  @override
  String get headerValueLabel => 'Header value';

  @override
  String headersConfigured(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count headers configured',
      one: '1 header configured',
    );
    return '$_temp0';
  }

  @override
  String get noCustomHeaders => 'No custom headers';

  @override
  String get comfyUiUseNegativePromptTitle => 'Use negative prompt';

  @override
  String get comfyUiUseNegativePromptSubtitle =>
      'Off by default for ComfyUI. When off, no negative prompt is sent to the workflow.';

  @override
  String get documentationTitle => 'Documentation';

  @override
  String get documentationSubtitle =>
      'Setup guides for Group Chat, ComfyUI, keyboard behavior, and more';

  @override
  String get changelogTitle => 'Changelog';

  @override
  String get changelogSubtitle => 'Version history & updates';

  @override
  String get enableCustomHeaders => 'Enable custom headers';

  @override
  String get enableCustomHeadersSubtitle =>
      'Attach extra HTTP headers to every LM Studio request';

  @override
  String deleteMemoriesCount(int count) {
    return 'Delete $count memories?';
  }

  @override
  String get deleteMemoriesConfirm =>
      'These memories will be removed for good.';

  @override
  String get moveToCategory => 'Move to category';

  @override
  String nSelected(int count) {
    return '$count selected';
  }

  @override
  String movedToCategory(String category) {
    return 'Moved to $category';
  }

  @override
  String get moveCategoryTooltip => 'Move category';

  @override
  String get memoryScreenSubtitle =>
      'Facts the AI keeps in mind about you across chats.';

  @override
  String get rememberMe => 'Remember me';

  @override
  String get rememberMeSubtitle => 'Use saved notes in future conversations';

  @override
  String get memoryPerPersona => 'Keep private notes separate';

  @override
  String get memoryPerPersonaSubtitle =>
      'Notes marked private stay with their persona. Character notes are always kept separate.';

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
      'A fact about you that only this persona sees';

  @override
  String get memoryScopeLore => 'Character notes';

  @override
  String get memoryScopeLoreSubtitle =>
      'Roleplay details for this character, never treated as facts about you';

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
  String get memoryBrowseSection => 'Browse';

  @override
  String get memoryMultiSelectTip =>
      'Tip: long-press a note to select several.';

  @override
  String get memoryEmptyFilteredHint => 'Add a note, or pick another category.';

  @override
  String get memoryEmptyHint =>
      'Save a few things about yourself — name, preferences, projects — so chats feel personal.';

  @override
  String get memoryShareWith => 'Share with';

  @override
  String get memoryEveryone => 'Everyone';

  @override
  String get memoryEveryoneSubtitle => 'Available in every chat';

  @override
  String get memoryNoPersonasHint =>
      'No personas yet. Create one in Settings → Personas.';

  @override
  String get memoryNewNote => 'New note';

  @override
  String get memoryNoteHint => 'e.g. I prefer short answers and live in Berlin';

  @override
  String get memoryEditNote => 'Edit note';

  @override
  String monthsAgo(int count) {
    return '${count}mo ago';
  }

  @override
  String get moreTooltip => 'More';

  @override
  String get closeSearch => 'Close search';

  @override
  String get moveTooltip => 'Move';

  @override
  String get chatsTab => 'Chats';

  @override
  String get groupsTab => 'Groups';

  @override
  String get foldersTooltip => 'Folders';

  @override
  String get newFolder => 'New folder';

  @override
  String get tapToReturnToCall => 'Tap to return to call';

  @override
  String get selectConversation => 'Select a conversation';

  @override
  String get selectConversationHint =>
      'Pick one from the list, or start a new chat.';

  @override
  String get noGroupChatsYet => 'No group chats yet';

  @override
  String get noGroupChatsSubtitle =>
      'Start a multi-persona conversation to chat with several AIs together.';

  @override
  String get newPersonaShort => 'New';

  @override
  String get downloadOnDeviceModelTitle => 'Download an on-device model';

  @override
  String get downloadOnDeviceModelBody =>
      'Download a model to chat without a PC, or connect LM Studio / Ollama.';

  @override
  String get browseModels => 'Browse models';

  @override
  String get waitingForMac => 'Waiting for Mac';

  @override
  String get waitingForMacBody =>
      'Connect your iPhone to your Mac with a USB cable, then open LM Mini on Mac and enable Share with phone (USB bridge).';

  @override
  String get arenaMode => 'Arena mode';

  @override
  String get voiceWhisperSizeInfoTitle => 'Bigger models hear better';

  @override
  String get voiceWhisperSizeInfoBody =>
      'Larger listening models are usually more accurate, especially with accents and background noise. They also use more storage and may load a bit slower.';

  @override
  String get voiceRemoveListeningModelTitle => 'Remove listening model?';

  @override
  String get voiceRemoveListeningModelBody =>
      'This frees storage. Voice Call and the mic will need the model again before offline listening works.';

  @override
  String get voiceTtsOnDeviceNeural => 'Downloaded voice';

  @override
  String get voiceTtsPcVoice => 'PC voice';

  @override
  String get voiceTtsSystemVoice => 'System voice';

  @override
  String get voiceTtsOnDeviceHint =>
      'Natural voices you download. Works without internet.';

  @override
  String get voiceTtsPcHint =>
      'Use a voice model on your computer via Share with phone';

  @override
  String get voiceTtsSystemHint => 'Your phone\'s voices — ready now';

  @override
  String get voiceSttOnDevice => 'On this device';

  @override
  String get voiceSttWhisperHint => 'Offline model — usually more accurate';

  @override
  String get voiceSttSystemHint => 'Built-in recognition — quick and simple';

  @override
  String get voiceSttSystemUnavailableOnMac => 'Needs download';

  @override
  String get voiceSttMacosRequiresWhisper =>
      'App Store builds use on-device Whisper for listening. Download a model to enable it.';

  @override
  String get voiceSttMacosSystemOptionSubtitle =>
      'Download Whisper to enable listening';

  @override
  String get voiceSttMacosDownloadWhisper =>
      'Download Whisper to enable listening';

  @override
  String get voiceSettingsIntro =>
      'How replies are spoken, and how your voice is understood.';

  @override
  String get voiceSectionReady => 'Ready';

  @override
  String get voiceSectionSpeaking => 'Speaking';

  @override
  String get voiceSectionListening => 'Listening';

  @override
  String get voiceSectionConversation => 'Conversation';

  @override
  String get voiceStatusSpeaking => 'Speaking';

  @override
  String get voiceStatusListening => 'Listening';

  @override
  String get voiceHowISpeak => 'How I speak';

  @override
  String get voiceImportPack => 'Import voice pack';

  @override
  String get voiceImportPackSubtitle => 'Paste a GitHub URL to a voice pack';

  @override
  String get voiceHowIHearYou => 'How I hear you';

  @override
  String get voiceHowIHearYouSubtitle =>
      'Choose how your speech is turned into text.';

  @override
  String get voiceListeningModel => 'Listening model';

  @override
  String get voiceAboutModelSizes => 'About model sizes';

  @override
  String get voicePauseBeforeSend => 'Pause before send';

  @override
  String get voicePauseBeforeSendSubtitle =>
      'How long to wait after you stop talking';

  @override
  String get voiceListeningLimit => 'Listening limit';

  @override
  String get voiceListeningLimitSubtitle =>
      'Longest stretch before the mic restarts';

  @override
  String get voiceQuickTip => 'Quick tip';

  @override
  String get voiceQuickTipBody =>
      'For a more natural voice, download a language under Voice packs. System voice works right away.';

  @override
  String get voiceTestSampleHint =>
      'Hear a short sample with your current settings';

  @override
  String get voiceTestNoPackReady =>
      'Download a language under Voice packs, then try Test Voice.';

  @override
  String get voiceChooseListeningModel => 'Tap to choose a listening model';

  @override
  String get voiceModelReady => 'Ready';

  @override
  String get voiceNeedsDownload => 'Needs download';

  @override
  String get voiceDownloaded => 'Downloaded';

  @override
  String get voiceDownloadFailed => 'Download failed';

  @override
  String get voiceFinishingSetup => 'Finishing setup…';

  @override
  String get voiceDownloadingListeningModel => 'Downloading listening model…';

  @override
  String get voiceDownloadingVoice => 'Downloading voice…';

  @override
  String get voiceStartingDownload => 'Starting download…';

  @override
  String get voiceReady => 'Voice ready';

  @override
  String get voiceWarmingUp => 'Warming up…';

  @override
  String get voiceReadyToSpeak => 'Ready to speak';

  @override
  String get voiceDownloadOnDevice => 'Download on-device voice';

  @override
  String get voiceDownloadFailedRetry => 'Download failed — tap to try again';

  @override
  String get voiceSpokenReplyLanguage => 'Spoken reply language';

  @override
  String get voiceSpokenReplyLanguageSubtitle =>
      'Language used when the assistant reads messages aloud.';

  @override
  String get voiceRecognitionLanguage => 'Recognition language';

  @override
  String get voiceRecognitionLanguageSubtitle =>
      'Used for the text mic and Voice Call — can differ from spoken replies.';

  @override
  String get voiceEngineTitle => 'Speaking voice';

  @override
  String get voiceEngineSubtitle => 'Choose where the spoken voice comes from.';

  @override
  String get voiceChooseAVoice => 'Choose a voice';

  @override
  String get voiceChooseAVoiceSubtitle =>
      'Preview-friendly names for on-device speech.';

  @override
  String get voiceUseSystemDefault => 'Use the system default voice';

  @override
  String get welcomeWizardTitleGetStarted => 'Get started';

  @override
  String get welcomeWizardTitleYourSetup => 'Your setup';

  @override
  String get welcomeWizardTitleLookAndFeel => 'Look & feel';

  @override
  String get welcomeWizardTitleAlmostDone => 'Almost done';

  @override
  String get welcomeWizardTitleSetup => 'Setup';

  @override
  String get welcomeWizardLmStudioSubtitle => 'Run models on your Mac or PC';

  @override
  String get welcomeWizardOllamaSubtitle => 'Popular local server';

  @override
  String get welcomeWizardOmlxSubtitle => 'Apple Silicon desktop server';

  @override
  String get welcomeWizardJanSubtitle => 'Local models from the JAN AI app';

  @override
  String get welcomeWizardUnslothSubtitle => 'Unsloth Desktop on your computer';

  @override
  String get welcomeWizardThemeSubtitle =>
      'Pick a look you like. You can change this anytime.';

  @override
  String get welcomeWizardModelReady => 'Ready';

  @override
  String get welcomeWizardConnected => 'Connected';

  @override
  String get welcomeWizardServerFound => 'Server found';

  @override
  String get welcomeWizardRequiresApiKey => 'Requires API Key';

  @override
  String get welcomeWizardScanHomeQr => 'Scan LM Mini Home QR';

  @override
  String get welcomeWizardScanHomeQrSubtitle =>
      'Pair with your Mac from Share with phone';

  @override
  String welcomeWizardModelsFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count models found',
      one: '1 model found',
    );
    return '$_temp0';
  }

  @override
  String get welcomeWizardLocalNetworkTitle => 'Allow network access';

  @override
  String get welcomeWizardLocalNetworkBody =>
      'You\'ll be asked to allow local network access. Please allow it so LM Mini can find LM Mini Home, LM Studio, or Ollama running on your computer.';

  @override
  String get welcomeWizardLocalNetworkAllow => 'Allow';

  @override
  String get welcomeWizardDownloadKeepsGoing =>
      'You can leave this screen — the download keeps going, even if you leave the app.';

  @override
  String get welcomeWizardDownloadFailed => 'Download failed. Tap to retry.';

  @override
  String get welcomeWizardAiDownloadingTitle => 'AI is downloading';

  @override
  String get welcomeWizardAiDownloadingBody =>
      'You\'ll be able to chat as soon as the perfect AI for your phone is ready. This is a one-time download.';

  @override
  String get onDeviceModels => 'On-Device Models';

  @override
  String get transcription => 'Transcription';

  @override
  String get widgetSettings => 'Widget Settings';

  @override
  String get widgetSettingsSubtitle => 'Configure home screen widgets';

  @override
  String get setUpShortcuts => 'Set up Shortcuts';

  @override
  String get shareArenaSpeedResults => 'Share Arena speed results';

  @override
  String get browseOnDeviceModels => 'Browse on-device models';

  @override
  String get homeDownloadModel => 'Download model';

  @override
  String get usbMode => 'USB Mode';

  @override
  String get usbModeHowItWorks => 'How USB Mode works';

  @override
  String get switchToUsbTitle => 'Switch from Remote to USB?';

  @override
  String get switchLabel => 'Switch';

  @override
  String usbModeStartFailed(String error) {
    return 'Could not start USB Mode: $error';
  }

  @override
  String get usbModeHowToUse => 'How to use:';

  @override
  String get openLmminiCom => 'Open lmmini.com';

  @override
  String get tapToUseServer => 'Tap to use this server';

  @override
  String get memoryPersonaFallback => 'Persona';

  @override
  String get voicePickSystemVoiceSubtitle =>
      'Pick a built-in voice for spoken replies.';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String get galleryLimitsSubtitle =>
      'Photos up to 10 MB · Videos up to 200 MB';

  @override
  String get recordVideo => 'Record a video';

  @override
  String attachmentsCount(int count, int max) {
    return 'Attachments ($count/$max)';
  }

  @override
  String get viewProfile => 'View profile';

  @override
  String get personaAndModel => 'Persona & model';

  @override
  String get chatOptions => 'Chat options';

  @override
  String get chatTab => 'Chat';

  @override
  String get voiceTab => 'Voice';

  @override
  String get craftingPersona => 'Crafting persona…';

  @override
  String get randomPersona => 'Surprise me';

  @override
  String get savePersona => 'Save persona';

  @override
  String get downloadFinished => 'Download finished.';

  @override
  String get downloadCancelled => 'Download cancelled.';

  @override
  String get downloadCancelFailed =>
      'Couldn\'t cancel in LM Studio. Stop it in LM Studio\'s Downloads list.';

  @override
  String get newsBriefing => 'News briefing';

  @override
  String get refreshNow => 'Refresh now';

  @override
  String get noBriefingYet => 'No briefing yet';

  @override
  String get newsSetPromptFirst =>
      'Set a News widget prompt in Widget Settings first.';

  @override
  String get newsRefreshed => 'News refreshed.';

  @override
  String newsRefreshFailed(String error) {
    return 'Refresh failed: $error';
  }

  @override
  String get themesTitle => 'Themes';

  @override
  String get createLabel => 'Create';

  @override
  String get browseLabel => 'Browse';

  @override
  String get signInToUploadThemes => 'Please sign in to upload themes';

  @override
  String get deleteThemeTitle => 'Delete theme?';

  @override
  String deleteThemeConfirm(String name) {
    return 'Remove \"$name\" from your downloaded themes?';
  }

  @override
  String get uploadToCommunity => 'Upload to community';

  @override
  String get installedLabel => 'Installed';

  @override
  String get getLabel => 'Get';

  @override
  String get bestForYou => 'Best for you';

  @override
  String get loadingLabel => 'Loading';

  @override
  String get loadedLabel => 'Loaded';

  @override
  String get notLoadedLabel => 'Not loaded';

  @override
  String get reasoningLabel => 'Reasoning';

  @override
  String get imagesLabel => 'Images';

  @override
  String get detailsTooltip => 'Details';

  @override
  String get transcribeAudio => 'Transcribe audio';

  @override
  String get transcribeAudioSubtitle =>
      'Upload audio and ask AI about the transcript';

  @override
  String get trimSection => 'Trim section';

  @override
  String get includeTimestamps => 'Include timestamps';

  @override
  String get phrasesLabel => 'Phrases';

  @override
  String get wordsLabel => 'Words';

  @override
  String get transcriptionLanguage => 'Transcription language';

  @override
  String get searchLanguages => 'Search languages…';

  @override
  String get transcribe => 'Transcribe';

  @override
  String get shareTranscript => 'Share transcript';

  @override
  String get transcriptionContextLargeToast =>
      'These transcripts may be too large for the model\'s context. Branch from an earlier message if answers get incomplete.';

  @override
  String get transcriptionSubtitlesOn => 'Subtitles on';

  @override
  String get transcriptionSubtitlesOff => 'Subtitles off';

  @override
  String get transcriptionFullClip => 'Full clip';

  @override
  String get transcriptionJobRunning => 'Transcribing…';

  @override
  String get transcriptionJobDone => 'Transcribed';

  @override
  String get transcriptionJobFailed => 'Transcription failed';

  @override
  String get branchFromHere => 'Branch from here';

  @override
  String get memoryUpdates => 'Memory Updates';

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
  String get personaShareMemoryCategoriesLabel => 'Categories to share';

  @override
  String get personaShareMemoryCategoriesSubtitle =>
      'Choose which kinds of memories this persona can use in chats.';

  @override
  String get chooseFaceForBubbles => 'Choose face for bubbles';

  @override
  String get moveMemories => 'Move memories';

  @override
  String get deletePersonaAndMemories => 'Delete persona + memories';

  @override
  String get moveMemoriesTo => 'Move memories to…';

  @override
  String get globalSharedMemories => 'Global (shared with all personas)';

  @override
  String personaMemoriesAssignedHint(int count, String name) {
    return '$count memory item(s) are assigned to \"$name\".\nChoose what should happen to them:';
  }

  @override
  String get homeSyncTitle => 'Keep chats in sync?';

  @override
  String homeSyncBodyBoth(int phoneChats, int macChats) {
    return 'This phone has $phoneChats chats and LM Mini Home has $macChats. Enable sync to merge conversations and folders so you can continue on either device. Uses your existing encrypted relay.';
  }

  @override
  String get homeSyncBodyPhoneOnly =>
      'Copy chats and folders from this phone to LM Mini Home, then keep them in sync over your encrypted relay.';

  @override
  String get homeSyncBodyMacOnly =>
      'Bring chats and folders from LM Mini Home onto this phone, then keep them in sync over your encrypted relay.';

  @override
  String get homeSyncBodyGeneric =>
      'Merge conversations and folders between this phone and LM Mini Home so you can continue on either device. Uses your existing encrypted relay.';

  @override
  String get homeSyncEnable => 'Enable sync';

  @override
  String get homeSyncNotNow => 'Not now';

  @override
  String get homeSyncSettingsTitle => 'Sync chats with Home';

  @override
  String get homeSyncSettingsSubtitle =>
      'Copy chats and folders between this phone and your Mac';

  @override
  String get homeSyncMergedToast => 'Chats and folders are now in sync';

  @override
  String get homeSyncFailedToast =>
      'Couldn\'t sync. Open Share with phone on your Mac and try again.';

  @override
  String get homeSyncPersonasTitle => 'Sync personas';

  @override
  String get homeSyncPersonasSubtitle =>
      'Copy the ones you pick, including photos and memories';

  @override
  String get homeSyncPersonasPickTitle => 'Choose personas';

  @override
  String get homeSyncPersonasPickSubtitle =>
      'Checked personas copy between this device and Home, with their photo and memories.';

  @override
  String get homeSyncPersonasSave => 'Save and sync';

  @override
  String get homeSyncPersonasSavedToast => 'Personas are now in sync';

  @override
  String get homeSyncPersonasEmpty => 'No personas to copy yet.';

  @override
  String get homeSyncPersonasUnreachable =>
      'Can\'t reach Home. Open Share with phone on your Mac, then try again.';

  @override
  String get homeSyncPersonasOnBoth => 'On both devices';

  @override
  String get homeSyncPersonasOnHome => 'LM Mini Home';

  @override
  String get homeSyncPersonasOnPhone => 'your phone';

  @override
  String get homeSyncPersonasThisPhone => 'this phone';

  @override
  String homeSyncPersonasOnDevice(String device) {
    return 'On $device';
  }

  @override
  String homeSyncPersonasMemoryCount(int count) {
    return '$count memories';
  }

  @override
  String get homeSyncPersonasNoMemories => 'No memories yet';

  @override
  String get reportToSupport => 'Send to support';

  @override
  String get localhostConnectionHelp =>
      'Can\'t connect to localhost. On a phone or tablet, localhost means this device — not your computer. In Settings, use your computer\'s IP address instead (for example http://192.168.1.10:1234) and keep both on the same Wi‑Fi.';

  @override
  String get lmStudioPcNotAllowingTitle =>
      'Your PC is not allowing connections';

  @override
  String get lmStudioPcNotAllowingBody =>
      'In LM Studio on your computer, open Developer → Server Settings and turn on Serve on Local Network.';

  @override
  String get lmStudioHostDownTitle => 'Can\'t reach your PC';

  @override
  String get lmStudioHostDownStep1 =>
      'Make sure the computer is on — not asleep or shut down.';

  @override
  String get lmStudioHostDownStep2 =>
      'In LM Studio, open Developer → Server Settings and turn on Serve on Local Network.';

  @override
  String get cantReachMacTitle => 'Can\'t reach your Mac';

  @override
  String get cantReachMacStep1 =>
      'Open Share with phone in LM Mini Home on your Mac.';

  @override
  String get cantReachMacStep2 =>
      'Wait until it says Connected, then try again.';

  @override
  String get lmStudioServerSettingsImageLabel =>
      'LM Studio Developer → Server Settings. Serve on Local Network should be on.';

  @override
  String get modelMissingTitle => 'This model isn\'t on your PC';

  @override
  String get modelMissingBody =>
      'The selected model isn\'t available. Pick another from Model Selection.';

  @override
  String modelMissingBodyNamed(String model) {
    return '“$model” isn\'t on your computer. Pick another from Model Selection.';
  }

  @override
  String get outputTokensExhaustedTitle => 'The model ran out of output tokens';

  @override
  String get outputTokensExhaustedBody =>
      'There weren\'t enough output tokens left to write a reply. Increase max tokens and try again.';

  @override
  String get thinkingBudgetRetryTitle => 'Thinking used the output limit';

  @override
  String get thinkingBudgetRetryBody =>
      'High thinking filled the output limit, so this reply uses low thinking. Raise max tokens to keep high thinking.';

  @override
  String get adjustMaxTokens => 'Adjust max tokens';

  @override
  String get ggmlSchedulerCrashBody =>
      'The model server crashed (llama.cpp scheduler). This isn\'t Mini. Lower context length and max tokens — very large values (for example 128k context) often cause this.';

  @override
  String get generationTerminatedBody =>
      'LM Studio stopped the generation on your computer (the process was terminated).';

  @override
  String generationTerminatedHugeImageBody(String size) {
    return 'LM Studio stopped the generation on your computer. Your attached image is probably huge ($size) — compress it and resend.';
  }

  @override
  String get compressAndResendImages => 'Compress image and resend';

  @override
  String get imageCompressFailed =>
      'Couldn\'t shrink the attached image. Try a smaller photo.';

  @override
  String get droppedChatBodyHelp =>
      'Mini sent this chat, but it never reached LM Studio. If you run a proxy, tunnel, or extra URL in front of LM Studio, try without it — or point Mini straight at LM Studio (your computer\'s IP, USB, or Connect).';

  @override
  String get comfyUiNoCheckpointsTitle => 'ComfyUI has no image model';

  @override
  String get comfyUiNoCheckpointsBody =>
      'ComfyUI has no checkpoint to load. Add a .safetensors file to ComfyUI’s models/checkpoints folder, then pick it in Image Generation settings.';

  @override
  String get comfyUiNoCheckpointSelectedBody =>
      'No image model is selected. Open Image Generation settings and pick a checkpoint.';

  @override
  String comfyUiUnknownCheckpointBody(String name) {
    return 'ComfyUI doesn’t have checkpoint “$name”. Pick another in Image Generation settings.';
  }

  @override
  String get comfyUiWorkflowRejectedBody =>
      'ComfyUI rejected the workflow. Check Image Generation settings.';

  @override
  String get comfyUiDiffusionOnlyTitle =>
      'This graph needs your ComfyUI workflow';

  @override
  String get comfyUiDiffusionOnlyBody =>
      'Mini’s built-in workflow loads a classic SD checkpoint. Your Comfy Desktop graph uses a diffusion model (UNET) plus CLIP and VAE. Export it as API Format (Workflow → Export) and pick that file under Image Generation.';

  @override
  String get openImageSettings => 'Image settings';

  @override
  String imageGenUnreachableTitle(String name) {
    return 'Can\'t reach $name';
  }

  @override
  String imageGenUnreachableBody(String name, String url) {
    return 'Nothing is answering at $url. Start $name on your computer and stay on the same Wi‑Fi.';
  }

  @override
  String get imageGenUnreachableNoUrlBody =>
      'No image generation server is set. Add ComfyUI or AUTOMATIC1111 in Image Generation settings.';

  @override
  String get sharedHostUpdateImageTitle => 'Update image generation too?';

  @override
  String sharedHostUpdateChatTitle(String name) {
    return 'Update $name too?';
  }

  @override
  String sharedHostUpdateBody(
      String changedName, String peerName, String oldHost, String newUrl) {
    return '$changedName and $peerName were both on $oldHost. Update $peerName to $newUrl?';
  }

  @override
  String get sharedHostUpdateConfirm => 'Update and test';

  @override
  String get sharedHostUpdateSkip => 'Keep current';

  @override
  String sharedHostTesting(String name) {
    return 'Testing $name…';
  }

  @override
  String get sharedHostTestSuccessTitle => 'Connected';

  @override
  String sharedHostTestSuccessBody(String name, String url) {
    return 'Reached $name at $url.';
  }

  @override
  String get sharedHostTestFailTitle => 'Couldn\'t connect';

  @override
  String sharedHostTestFailBody(String name, String url, String error) {
    return 'Updated $name to $url, but Mini couldn\'t reach it. $error';
  }

  @override
  String get supportTicketTitle => 'Report a problem';

  @override
  String get supportTicketPrefillDescription =>
      'A log file with the error details is attached. Add anything else that might help:';

  @override
  String get supportTicketSubmitted => 'Thanks — your report was sent.';

  @override
  String get supportTicketAlreadyOpen =>
      'You already have an open report for this error.';

  @override
  String get supportTicketViewExisting => 'View report';

  @override
  String get supportTicketAlreadySending =>
      'This error is already being reported.';

  @override
  String get supportUnavailable =>
      'Support isn\'t available right now. Try again when you\'re online.';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get uncaughtErrorSnack => 'Something went wrong.';

  @override
  String get errorLogLabel => 'LOG';

  @override
  String get appLock => 'App Lock';

  @override
  String get appLockSubtitleOff => 'Require a PIN after the app is closed';

  @override
  String appLockSubtitleOn(String duration) {
    return 'Asks again after $duration';
  }

  @override
  String get appLockUnlockTitle => 'LM Mini is locked';

  @override
  String get appLockDescription =>
      'Protect chats on this device with a numeric PIN and optional Face ID. The PIN stays on this device and is never synced.';

  @override
  String get appLockEnable => 'Lock with PIN';

  @override
  String get appLockEnableSubtitle => 'Ask for your PIN when you return';

  @override
  String get appLockPinLength4 => '4 digits';

  @override
  String get appLockPinLength6 => '6 digits';

  @override
  String get appLockRequireAfter => 'Ask again after';

  @override
  String get appLockTimeoutImmediate => 'Immediately';

  @override
  String get appLockTimeout15s => '15 seconds';

  @override
  String get appLockTimeout1m => '1 minute';

  @override
  String get appLockTimeout5m => '5 minutes';

  @override
  String get appLockTimeout15m => '15 minutes';

  @override
  String get appLockTimeout1h => '1 hour';

  @override
  String get appLockChangePin => 'Change PIN';

  @override
  String get appLockEnterCurrentPin => 'Enter current PIN';

  @override
  String get appLockChooseNewPin => 'Choose a PIN';

  @override
  String get appLockConfirmPin => 'Confirm PIN';

  @override
  String get appLockPinsDontMatch => 'PINs didn’t match. Try again.';

  @override
  String get appLockWrongPin => 'Wrong PIN. Try again.';

  @override
  String appLockTooManyAttempts(int seconds) {
    return 'Too many attempts. Try again in ${seconds}s.';
  }

  @override
  String get appLockForgotHint =>
      'If you forget your PIN, you can reset it with a verification email sent to your signed-in account. Sign in before you lose the PIN, or you won’t be able to recover it.';

  @override
  String get appLockProRequired => 'App Lock is a Pro feature';

  @override
  String get appLockEnabledToast => 'App Lock is on';

  @override
  String get appLockDisabledToast => 'App Lock is off';

  @override
  String get appLockChangedToast => 'PIN updated';

  @override
  String appLockBiometricsToggle(String method) {
    return 'Unlock with $method';
  }

  @override
  String get appLockBiometricsSubtitle =>
      'Use Face ID, Touch ID, or a fingerprint instead of your PIN.';

  @override
  String get appLockBiometricFaceId => 'Face ID';

  @override
  String get appLockBiometricFace => 'Face unlock';

  @override
  String get appLockBiometricTouchId => 'Touch ID';

  @override
  String get appLockBiometricFingerprint => 'Fingerprint';

  @override
  String get appLockBiometricGeneric => 'biometrics';

  @override
  String appLockUnlockWithBiometrics(String method) {
    return 'Unlock with $method';
  }

  @override
  String appLockBiometricsFailed(String method) {
    return 'Couldn’t unlock with $method. Use your PIN.';
  }

  @override
  String get appLockSignInToRecover =>
      'Sign in, or you won’t be able to recover App Lock if this PIN is lost.';

  @override
  String appLockSignInToRecoverBound(String email) {
    return 'Sign in as $email, or you won’t be able to recover App Lock if this PIN is lost.';
  }

  @override
  String get appLockNotSignedInNoRecovery =>
      'You aren’t signed in. You won’t be able to recover this PIN if it’s lost.';

  @override
  String get appLockForgotPin => 'Forgot PIN?';

  @override
  String get appLockSendRecoveryEmail => 'Email a verification link';

  @override
  String appLockRecoveryEmailSent(String email) {
    return 'We sent a verification email to $email. Open it, then come back here.';
  }

  @override
  String get appLockRecoveryIVerified => 'I verified — continue';

  @override
  String get appLockRecoveryResend => 'Resend email';

  @override
  String get appLockRecoveryReauth => 'Sign in again to reset your PIN';

  @override
  String appLockRecoveryWrongAccount(String email) {
    return 'This PIN is tied to $email. Sign in with that account to recover it.';
  }

  @override
  String get appLockRecoveryUnavailable =>
      'PIN recovery isn’t set up. You’ll need this PIN, or reinstall LM Mini.';

  @override
  String get appLockRecoveryFailed =>
      'Couldn’t verify your account. Try again.';

  @override
  String get appLockRecoveryNoEmail =>
      'This account has no email to send a verification link to.';

  @override
  String get appLockRecoveryTooMany =>
      'Too many emails. Wait a minute and try again.';

  @override
  String get appLockRecoverySetPin => 'Choose a new PIN';

  @override
  String get appLockContinueWithEmail => 'Continue with email';

  @override
  String appLockSignedInRecoverHint(String email) {
    return 'If you forget this PIN, we can email a verification link to $email.';
  }

  @override
  String get appLockRecoveryAccount => 'PIN recovery';

  @override
  String appLockRecoveryAccountOn(String email) {
    return 'Verification emails go to $email';
  }

  @override
  String get appLockRecoveryAccountOff =>
      'Sign in so you can recover a lost PIN';

  @override
  String get appLockRecoveryAccountOffSubtitle =>
      'Without a signed-in account, a lost PIN can only be cleared by reinstalling the app.';

  @override
  String get appLockBackToPin => 'Use PIN';

  @override
  String get premiumAppLock => 'App Lock';

  @override
  String get premiumAppLockTagline => 'PIN-protect the app';

  @override
  String get premiumAppLockDescription =>
      'Set a 4- or 6-digit PIN, unlock with Face ID, and recover a lost PIN with a verification email. The PIN stays on this device.';

  @override
  String spritePanelShow(String name) {
    return 'Show $name\'s expression';
  }

  @override
  String get personaExpressionsTitle => 'Expressions';

  @override
  String get personaExpressionsSubtitle =>
      'Character sprites that change with the mood of each reply. Name images after the expression, like joy.png or anger.png, or import a SillyTavern sprite zip.';

  @override
  String get personaExpressionsImport => 'Import sprites';

  @override
  String get personaExpressionsRemoveAll => 'Remove all';

  @override
  String personaExpressionsRemoveAllConfirm(String name) {
    return 'Remove all expression sprites from $name?';
  }

  @override
  String get personaExpressionsReplace => 'Replace image';

  @override
  String get personaExpressionsRemove => 'Remove';

  @override
  String personaExpressionsImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sprites added',
      one: '1 sprite added',
      zero: 'No sprites added',
    );
    return '$_temp0';
  }

  @override
  String personaExpressionsUnmatched(String files) {
    return 'Skipped (not an expression name): $files';
  }

  @override
  String get personaExpressionsMissing => 'Missing';

  @override
  String get characterCardImport => 'Import character card';

  @override
  String characterCardImportedOne(String name) {
    return 'Imported $name';
  }

  @override
  String characterCardImportedMany(int count) {
    return 'Imported $count characters';
  }

  @override
  String characterCardImportFailed(String file, String reason) {
    return 'Couldn\'t import $file: $reason';
  }

  @override
  String characterCardLoreSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count keyword lorebook entries weren\'t imported',
      one: '1 keyword lorebook entry wasn\'t imported',
    );
    return '$_temp0';
  }

  @override
  String get appearanceExpressionSprites => 'Character expressions';

  @override
  String get appearanceExpressionSpritesSubtitle =>
      'For personas with expression sprites';

  @override
  String get expressionSpriteModeOff => 'Off';

  @override
  String get expressionSpriteModePanel => 'Large sprite';

  @override
  String get expressionSpriteModeAvatar => 'Message avatar';

  @override
  String get expressionSpriteModeBoth => 'Both';

  @override
  String get spriteGenerateButton => 'Generate';

  @override
  String get spriteGenerateTitle => 'Generate expressions';

  @override
  String get spriteGenerateAppearance => 'Appearance';

  @override
  String get spriteGenerateAppearanceHint =>
      'Hair, eyes, clothing and art style';

  @override
  String get spriteGenerateSeed => 'Seed';

  @override
  String get spriteGenerateSeedHelp =>
      'The same seed keeps the character looking alike across expressions.';

  @override
  String get spriteGenerateCore => '8 core';

  @override
  String get spriteGenerateAll => 'All 28';

  @override
  String get spriteGenerateOnlyMissing => 'Only missing expressions';

  @override
  String spriteGenerateStart(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Generate $count images',
      one: 'Generate 1 image',
    );
    return '$_temp0';
  }

  @override
  String spriteGenerateProgress(int current, int total, String label) {
    return 'Generating $current of $total: $label';
  }

  @override
  String get spriteGenerateNeedsImageGen =>
      'Set up image generation first in Settings → Image Generation.';

  @override
  String spriteGenerateDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count expressions generated',
      one: '1 expression generated',
    );
    return '$_temp0';
  }

  @override
  String spriteGenerateFailed(String label, String error) {
    return 'Stopped at $label: $error';
  }

  @override
  String get personaGreetingLabel => 'First message (optional)';

  @override
  String get personaGreetingHint =>
      'What the character says when a new chat starts';
}
