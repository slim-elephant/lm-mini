import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('ru'),
    Locale('zh')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'LM Mini'**
  String get appTitle;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'local AI chat'**
  String get splashTagline;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'LM Mini'**
  String get homeTitle;

  /// No description provided for @homeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search conversations...'**
  String get homeSearchHint;

  /// No description provided for @allConversations.
  ///
  /// In en, this message translates to:
  /// **'All Conversations'**
  String get allConversations;

  /// No description provided for @noFoldersTitle.
  ///
  /// In en, this message translates to:
  /// **'No folders yet'**
  String get noFoldersTitle;

  /// No description provided for @noFoldersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create folders to organize your chats'**
  String get noFoldersSubtitle;

  /// No description provided for @noConversationsTitle.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get noConversationsTitle;

  /// No description provided for @noConversationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start a new chat to get started'**
  String get noConversationsSubtitle;

  /// No description provided for @newChat.
  ///
  /// In en, this message translates to:
  /// **'New Chat'**
  String get newChat;

  /// No description provided for @conversationCount.
  ///
  /// In en, this message translates to:
  /// **'{count} conversation(s)'**
  String conversationCount(int count);

  /// No description provided for @noModelsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No models available. Please check your LM Studio connection.'**
  String get noModelsAvailable;

  /// No description provided for @noVisionModelAvailable.
  ///
  /// In en, this message translates to:
  /// **'No vision-capable model available. Please load a vision model in LM Studio.'**
  String get noVisionModelAvailable;

  /// No description provided for @deleteConversationTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Conversation'**
  String get deleteConversationTitle;

  /// No description provided for @deleteConversationMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this conversation? This action cannot be undone.'**
  String get deleteConversationMessage;

  /// No description provided for @renameConversationTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename Conversation'**
  String get renameConversationTitle;

  /// No description provided for @conversationTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Conversation Title'**
  String get conversationTitleLabel;

  /// No description provided for @deleteFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Folder'**
  String get deleteFolderTitle;

  /// No description provided for @deleteFolderMessage.
  ///
  /// In en, this message translates to:
  /// **'This will not delete the conversations in this folder.'**
  String get deleteFolderMessage;

  /// No description provided for @moveToFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'Move to Folder'**
  String get moveToFolderTitle;

  /// No description provided for @noFolder.
  ///
  /// In en, this message translates to:
  /// **'No Folder'**
  String get noFolder;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied!'**
  String get copied;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @configure.
  ///
  /// In en, this message translates to:
  /// **'Configure'**
  String get configure;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @duplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicate;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @auto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get auto;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @chatDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatDefaultTitle;

  /// No description provided for @searchMessagesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Search messages'**
  String get searchMessagesTooltip;

  /// No description provided for @chatSettingsMenuItem.
  ///
  /// In en, this message translates to:
  /// **'Chat Settings'**
  String get chatSettingsMenuItem;

  /// No description provided for @appearanceMenuItem.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceMenuItem;

  /// No description provided for @exportAsPdf.
  ///
  /// In en, this message translates to:
  /// **'Export as PDF'**
  String get exportAsPdf;

  /// No description provided for @exportAsTxt.
  ///
  /// In en, this message translates to:
  /// **'Export as TXT'**
  String get exportAsTxt;

  /// No description provided for @exportAsMarkdown.
  ///
  /// In en, this message translates to:
  /// **'Export as Markdown'**
  String get exportAsMarkdown;

  /// No description provided for @exportAsJson.
  ///
  /// In en, this message translates to:
  /// **'Export as JSON'**
  String get exportAsJson;

  /// No description provided for @exportAsObsidian.
  ///
  /// In en, this message translates to:
  /// **'Export for Obsidian'**
  String get exportAsObsidian;

  /// No description provided for @copyToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copy to Clipboard'**
  String get copyToClipboard;

  /// No description provided for @exportAndShare.
  ///
  /// In en, this message translates to:
  /// **'Export & Share'**
  String get exportAndShare;

  /// No description provided for @freeFormats.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get freeFormats;

  /// No description provided for @premiumFormats.
  ///
  /// In en, this message translates to:
  /// **'Pro Formats'**
  String get premiumFormats;

  /// No description provided for @chatExported.
  ///
  /// In en, this message translates to:
  /// **'Chat exported'**
  String get chatExported;

  /// No description provided for @noModelSelectedTitle.
  ///
  /// In en, this message translates to:
  /// **'No Model Selected'**
  String get noModelSelectedTitle;

  /// No description provided for @noModelSelectedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please select a model in settings to start chatting'**
  String get noModelSelectedSubtitle;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection Error: {error}'**
  String connectionError(String error);

  /// No description provided for @startConversation.
  ///
  /// In en, this message translates to:
  /// **'Greetings! How may I assist you today?'**
  String get startConversation;

  /// No description provided for @typeMessageToBegin.
  ///
  /// In en, this message translates to:
  /// **'Pick a suggestion below, or type a message to begin'**
  String get typeMessageToBegin;

  /// No description provided for @searchMessagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Search Messages'**
  String get searchMessagesTitle;

  /// No description provided for @searchQueryHint.
  ///
  /// In en, this message translates to:
  /// **'Enter search query...'**
  String get searchQueryHint;

  /// No description provided for @semanticSearchInfo.
  ///
  /// In en, this message translates to:
  /// **'Semantic search uses AI to find relevant messages based on meaning, not just keywords.'**
  String get semanticSearchInfo;

  /// No description provided for @noMessagesToSearch.
  ///
  /// In en, this message translates to:
  /// **'No messages to search'**
  String get noMessagesToSearch;

  /// No description provided for @searchResults.
  ///
  /// In en, this message translates to:
  /// **'Search Results'**
  String get searchResults;

  /// No description provided for @searchResultsFor.
  ///
  /// In en, this message translates to:
  /// **'{count} match(es) for \"{query}\"'**
  String searchResultsFor(int count, String query);

  /// No description provided for @noMessagesFound.
  ///
  /// In en, this message translates to:
  /// **'No messages found'**
  String get noMessagesFound;

  /// No description provided for @tryDifferentSearch.
  ///
  /// In en, this message translates to:
  /// **'Try a different search query'**
  String get tryDifferentSearch;

  /// No description provided for @chatCustomizationSaved.
  ///
  /// In en, this message translates to:
  /// **'Chat customization saved'**
  String get chatCustomizationSaved;

  /// No description provided for @noMessagesToExport.
  ///
  /// In en, this message translates to:
  /// **'No messages to export'**
  String get noMessagesToExport;

  /// No description provided for @exportingChat.
  ///
  /// In en, this message translates to:
  /// **'Exporting chat...'**
  String get exportingChat;

  /// No description provided for @chatExportedAsPdf.
  ///
  /// In en, this message translates to:
  /// **'Chat exported as PDF'**
  String get chatExportedAsPdf;

  /// No description provided for @chatExportedAsTxt.
  ///
  /// In en, this message translates to:
  /// **'Chat exported as TXT'**
  String get chatExportedAsTxt;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportFailed(String error);

  /// No description provided for @chatSettingsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Chat settings updated (overriding global settings)'**
  String get chatSettingsUpdated;

  /// No description provided for @chatSettingsReset.
  ///
  /// In en, this message translates to:
  /// **'Chat settings reset to global defaults'**
  String get chatSettingsReset;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @assistant.
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get assistant;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @showDetails.
  ///
  /// In en, this message translates to:
  /// **'Show details'**
  String get showDetails;

  /// No description provided for @hideDetails.
  ///
  /// In en, this message translates to:
  /// **'Hide details'**
  String get hideDetails;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAdvancedMode.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get settingsAdvancedMode;

  /// No description provided for @settingsAdvancedModeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Show technical options for power users'**
  String get settingsAdvancedModeTooltip;

  /// No description provided for @serverSection.
  ///
  /// In en, this message translates to:
  /// **'SERVER'**
  String get serverSection;

  /// No description provided for @serverUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get serverUrlLabel;

  /// No description provided for @serverUrlHint.
  ///
  /// In en, this message translates to:
  /// **'http://localhost:1234'**
  String get serverUrlHint;

  /// No description provided for @testConnectionRequired.
  ///
  /// In en, this message translates to:
  /// **'Test Connection (Required)'**
  String get testConnectionRequired;

  /// No description provided for @testConnection.
  ///
  /// In en, this message translates to:
  /// **'Test Connection'**
  String get testConnection;

  /// No description provided for @modelsSection.
  ///
  /// In en, this message translates to:
  /// **'MODELS'**
  String get modelsSection;

  /// No description provided for @modelSelection.
  ///
  /// In en, this message translates to:
  /// **'Model Selection'**
  String get modelSelection;

  /// No description provided for @noModelSelected.
  ///
  /// In en, this message translates to:
  /// **'No model selected'**
  String get noModelSelected;

  /// No description provided for @modelParameters.
  ///
  /// In en, this message translates to:
  /// **'Model Parameters'**
  String get modelParameters;

  /// No description provided for @modelParametersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Temperature, tokens, penalties'**
  String get modelParametersSubtitle;

  /// No description provided for @modelParametersHelpTooltip.
  ///
  /// In en, this message translates to:
  /// **'What these settings mean'**
  String get modelParametersHelpTooltip;

  /// No description provided for @modelParametersHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick guide'**
  String get modelParametersHelpTitle;

  /// No description provided for @modelParametersHelpIntro.
  ///
  /// In en, this message translates to:
  /// **'Simple tips for each setting. Leave defaults if you’re unsure — you can always change them later. Some options only show for your current AI provider.'**
  String get modelParametersHelpIntro;

  /// No description provided for @topKHelp.
  ///
  /// In en, this message translates to:
  /// **'How many word choices the AI considers. Lower = safer and more predictable; 0 = no limit.'**
  String get topKHelp;

  /// No description provided for @reasoningHelp.
  ///
  /// In en, this message translates to:
  /// **'Turns thinking mode on or off for reasoning models. Off = faster replies without a thinking trace; On (or a level) asks the model to think step by step. Not all reasoning models support turning thinking off.'**
  String get reasoningHelp;

  /// No description provided for @reasoningHelpShort.
  ///
  /// In en, this message translates to:
  /// **'Turns thinking on or off. Not all models support Off.'**
  String get reasoningHelpShort;

  /// No description provided for @systemPrompts.
  ///
  /// In en, this message translates to:
  /// **'Personas and System Prompts'**
  String get systemPrompts;

  /// No description provided for @defaultPrompt.
  ///
  /// In en, this message translates to:
  /// **'Default Prompt'**
  String get defaultPrompt;

  /// No description provided for @appearanceSection.
  ///
  /// In en, this message translates to:
  /// **'APPEARANCE'**
  String get appearanceSection;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @appearanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Theme, backgrounds, avatars'**
  String get appearanceSubtitle;

  /// No description provided for @supportSection.
  ///
  /// In en, this message translates to:
  /// **'SUPPORT'**
  String get supportSection;

  /// No description provided for @rateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate LM Mini'**
  String get rateApp;

  /// No description provided for @rateAppSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Love the app? Leave a review on the App Store ⭐'**
  String get rateAppSubtitle;

  /// No description provided for @hfBrowseTitle.
  ///
  /// In en, this message translates to:
  /// **'Download from Hugging Face'**
  String get hfBrowseTitle;

  /// No description provided for @hfBrowseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse GGUF models — no API key needed'**
  String get hfBrowseSubtitle;

  /// No description provided for @hfBrowseTab.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get hfBrowseTab;

  /// No description provided for @hfPasteTab.
  ///
  /// In en, this message translates to:
  /// **'Paste link'**
  String get hfPasteTab;

  /// No description provided for @hfSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search GGUF models…'**
  String get hfSearchHint;

  /// No description provided for @hfLoadingModels.
  ///
  /// In en, this message translates to:
  /// **'Searching Hugging Face…'**
  String get hfLoadingModels;

  /// No description provided for @hfNoModelsFound.
  ///
  /// In en, this message translates to:
  /// **'No models found'**
  String get hfNoModelsFound;

  /// No description provided for @hfNoModelsHint.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term or turn off the LM Studio filter.'**
  String get hfNoModelsHint;

  /// No description provided for @hfLmStudioFilter.
  ///
  /// In en, this message translates to:
  /// **'LM Studio compatible'**
  String get hfLmStudioFilter;

  /// No description provided for @hfLmStudioFilterHint.
  ///
  /// In en, this message translates to:
  /// **'Only models Hugging Face lists as working with LM Studio'**
  String get hfLmStudioFilterHint;

  /// No description provided for @hfChatModelsFilter.
  ///
  /// In en, this message translates to:
  /// **'Chat models'**
  String get hfChatModelsFilter;

  /// No description provided for @hfChatBadge.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get hfChatBadge;

  /// No description provided for @hfLmStudioBadge.
  ///
  /// In en, this message translates to:
  /// **'LM Studio'**
  String get hfLmStudioBadge;

  /// No description provided for @hfPasteUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://huggingface.co/owner/repo'**
  String get hfPasteUrlHint;

  /// No description provided for @hfModelInfo.
  ///
  /// In en, this message translates to:
  /// **'Model info'**
  String get hfModelInfo;

  /// No description provided for @hfDownloadsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} downloads'**
  String hfDownloadsCount(String count);

  /// No description provided for @hfLikesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} likes'**
  String hfLikesCount(String count);

  /// No description provided for @hfPipelineTag.
  ///
  /// In en, this message translates to:
  /// **'Task: {tag}'**
  String hfPipelineTag(String tag);

  /// No description provided for @hfBaseModel.
  ///
  /// In en, this message translates to:
  /// **'Base model: {model}'**
  String hfBaseModel(String model);

  /// No description provided for @hfLicense.
  ///
  /// In en, this message translates to:
  /// **'License: {license}'**
  String hfLicense(String license);

  /// No description provided for @hfTagsSection.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get hfTagsSection;

  /// No description provided for @hfQuantPickerHint.
  ///
  /// In en, this message translates to:
  /// **'Lower quant = smaller file. Q4_K_M is a good balance for most devices.'**
  String get hfQuantPickerHint;

  /// No description provided for @hfBackToModels.
  ///
  /// In en, this message translates to:
  /// **'Back to models'**
  String get hfBackToModels;

  /// No description provided for @hfGgufFilesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} GGUF file(s) available'**
  String hfGgufFilesCount(int count);

  /// No description provided for @hfDownloadInBackground.
  ///
  /// In en, this message translates to:
  /// **'Download started — track progress with the floating button. You can keep browsing or close this panel.'**
  String get hfDownloadInBackground;

  /// No description provided for @hfQuantPickerHintLmStudio.
  ///
  /// In en, this message translates to:
  /// **'Quantizations listed by your LM Studio server. Pick one to download to the server.'**
  String get hfQuantPickerHintLmStudio;

  /// No description provided for @hfDownloadDefaultQuant.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get hfDownloadDefaultQuant;

  /// No description provided for @hfDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start download: {error}'**
  String hfDownloadFailed(String error);

  /// No description provided for @hfPasteInstructions.
  ///
  /// In en, this message translates to:
  /// **'Paste a Hugging Face repo URL or type owner/repo. You\'ll pick a quantization next.'**
  String get hfPasteInstructions;

  /// No description provided for @hfPasteInstructionsLmStudio.
  ///
  /// In en, this message translates to:
  /// **'Paste a Hugging Face URL, owner/repo, or an LM Studio model ID.'**
  String get hfPasteInstructionsLmStudio;

  /// No description provided for @hfPasteLabel.
  ///
  /// In en, this message translates to:
  /// **'Repository'**
  String get hfPasteLabel;

  /// No description provided for @hfInvalidRepo.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid Hugging Face URL or owner/repo.'**
  String get hfInvalidRepo;

  /// No description provided for @hfRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get hfRecommended;

  /// No description provided for @reviewPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Enjoying LM Mini?'**
  String get reviewPromptTitle;

  /// No description provided for @reviewPromptMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'ve had a few great chats! Would you mind leaving a quick rating on the Play Store?'**
  String get reviewPromptMessage;

  /// No description provided for @reviewPromptRate.
  ///
  /// In en, this message translates to:
  /// **'Rate now'**
  String get reviewPromptRate;

  /// No description provided for @reviewPromptLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get reviewPromptLater;

  /// No description provided for @buyMeACoffee.
  ///
  /// In en, this message translates to:
  /// **'Buy Me a Coffee'**
  String get buyMeACoffee;

  /// No description provided for @buyMeACoffeeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Help keep the AI caffeinated! 🤖'**
  String get buyMeACoffeeSubtitle;

  /// No description provided for @featureRequests.
  ///
  /// In en, this message translates to:
  /// **'Support / Feature Requests'**
  String get featureRequests;

  /// No description provided for @featureRequestsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Vote on features or submit your ideas'**
  String get featureRequestsSubtitle;

  /// No description provided for @dataSection.
  ///
  /// In en, this message translates to:
  /// **'DATA'**
  String get dataSection;

  /// No description provided for @exportAllChats.
  ///
  /// In en, this message translates to:
  /// **'Export All Chats'**
  String get exportAllChats;

  /// No description provided for @exportAllChatsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Download all conversations as a ZIP file'**
  String get exportAllChatsSubtitle;

  /// No description provided for @importChats.
  ///
  /// In en, this message translates to:
  /// **'Import Chats'**
  String get importChats;

  /// No description provided for @importChatsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Import LM Studio chat exports (.md or .zip)'**
  String get importChatsSubtitle;

  /// No description provided for @importSuccess.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 chat imported successfully} other{{count} chats imported successfully}}'**
  String importSuccess(int count);

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed'**
  String get importFailed;

  /// No description provided for @importPartial.
  ///
  /// In en, this message translates to:
  /// **'{imported} imported, {skipped} skipped'**
  String importPartial(int imported, int skipped);

  /// No description provided for @importing.
  ///
  /// In en, this message translates to:
  /// **'Importing...'**
  String get importing;

  /// No description provided for @advancedSection.
  ///
  /// In en, this message translates to:
  /// **'ADVANCED FEATURES'**
  String get advancedSection;

  /// No description provided for @showRuntimeInfo.
  ///
  /// In en, this message translates to:
  /// **'Show Runtime Info'**
  String get showRuntimeInfo;

  /// No description provided for @showRuntimeInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Display model architecture and runtime'**
  String get showRuntimeInfoSubtitle;

  /// No description provided for @embeddingModel.
  ///
  /// In en, this message translates to:
  /// **'Embedding Model'**
  String get embeddingModel;

  /// No description provided for @enableSemanticSearch.
  ///
  /// In en, this message translates to:
  /// **'Enable Semantic Search'**
  String get enableSemanticSearch;

  /// No description provided for @enableSemanticSearchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find relevant messages using embeddings'**
  String get enableSemanticSearchSubtitle;

  /// No description provided for @toolCalling.
  ///
  /// In en, this message translates to:
  /// **'Tool Calling'**
  String get toolCalling;

  /// No description provided for @toolCallingEnabled.
  ///
  /// In en, this message translates to:
  /// **'Tool calling enabled'**
  String get toolCallingEnabled;

  /// No description provided for @toolCallingDisabled.
  ///
  /// In en, this message translates to:
  /// **'Tool calling disabled'**
  String get toolCallingDisabled;

  /// No description provided for @legalSection.
  ///
  /// In en, this message translates to:
  /// **'LEGAL'**
  String get legalSection;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @privacyPolicySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Chats stay on your devices'**
  String get privacyPolicySubtitle;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @termsOfServiceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Terms and conditions'**
  String get termsOfServiceSubtitle;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'LM Mini'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'A Pocket A.I and companion app for LM Studio, Ollama and oMLX'**
  String get appTagline;

  /// No description provided for @couldNotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open link'**
  String get couldNotOpenLink;

  /// No description provided for @apiToken.
  ///
  /// In en, this message translates to:
  /// **'API Token and USB'**
  String get apiToken;

  /// No description provided for @tokenConfigured.
  ///
  /// In en, this message translates to:
  /// **'Token configured'**
  String get tokenConfigured;

  /// No description provided for @optionalAuthentication.
  ///
  /// In en, this message translates to:
  /// **'Optional authentication'**
  String get optionalAuthentication;

  /// No description provided for @apiTokenLabel.
  ///
  /// In en, this message translates to:
  /// **'API Token'**
  String get apiTokenLabel;

  /// No description provided for @apiTokenHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your LM Studio API token'**
  String get apiTokenHint;

  /// No description provided for @apiTokenHelp.
  ///
  /// In en, this message translates to:
  /// **'If your LM Studio server requires authentication, enter your API token here. This is optional and only needed if you\'ve enabled authentication in LM Studio settings.'**
  String get apiTokenHelp;

  /// No description provided for @apiTokenInfo.
  ///
  /// In en, this message translates to:
  /// **'LM Studio 0.4.0+ supports API authentication. Enable it in LM Studio > Settings > Security.'**
  String get apiTokenInfo;

  /// No description provided for @actionRequired.
  ///
  /// In en, this message translates to:
  /// **'- Action Required'**
  String get actionRequired;

  /// No description provided for @idleTtl.
  ///
  /// In en, this message translates to:
  /// **'Idle TTL'**
  String get idleTtl;

  /// No description provided for @idleTtlDefault.
  ///
  /// In en, this message translates to:
  /// **'Using LM Studio default (60 min)'**
  String get idleTtlDefault;

  /// No description provided for @idleTtlMinutes.
  ///
  /// In en, this message translates to:
  /// **'Auto-unload after {value} minutes idle'**
  String idleTtlMinutes(int value);

  /// No description provided for @idleTtlHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'Auto-unload after {hours} hr {mins} min idle'**
  String idleTtlHoursMinutes(int hours, int mins);

  /// No description provided for @lmStudioDefault.
  ///
  /// In en, this message translates to:
  /// **'LM Studio Default'**
  String get lmStudioDefault;

  /// No description provided for @fiveMinutes.
  ///
  /// In en, this message translates to:
  /// **'5 minutes'**
  String get fiveMinutes;

  /// No description provided for @fifteenMinutes.
  ///
  /// In en, this message translates to:
  /// **'15 minutes'**
  String get fifteenMinutes;

  /// No description provided for @thirtyMinutes.
  ///
  /// In en, this message translates to:
  /// **'30 minutes'**
  String get thirtyMinutes;

  /// No description provided for @oneHour.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get oneHour;

  /// No description provided for @twoHours.
  ///
  /// In en, this message translates to:
  /// **'2 hours'**
  String get twoHours;

  /// No description provided for @connectionSuccess.
  ///
  /// In en, this message translates to:
  /// **'Connected! Loaded {count} models'**
  String connectionSuccess(int count);

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get connectionFailed;

  /// No description provided for @troubleshootingSteps.
  ///
  /// In en, this message translates to:
  /// **'Troubleshooting Steps:'**
  String get troubleshootingSteps;

  /// No description provided for @troubleshootStep1.
  ///
  /// In en, this message translates to:
  /// **'Make sure LM Studio is running'**
  String get troubleshootStep1;

  /// No description provided for @troubleshootStep2.
  ///
  /// In en, this message translates to:
  /// **'In LM Studio, open the Developer tab (⚙️ icon)'**
  String get troubleshootStep2;

  /// No description provided for @troubleshootStep3.
  ///
  /// In en, this message translates to:
  /// **'Enable \"Serve on Local Network\" toggle'**
  String get troubleshootStep3;

  /// No description provided for @troubleshootStep4.
  ///
  /// In en, this message translates to:
  /// **'Verify Server Port matches (default: 1234)'**
  String get troubleshootStep4;

  /// No description provided for @troubleshootStep5.
  ///
  /// In en, this message translates to:
  /// **'For local connection use your IP, e.g. {ip}'**
  String troubleshootStep5(String ip);

  /// No description provided for @lmStudioSettings.
  ///
  /// In en, this message translates to:
  /// **'LM Studio Settings'**
  String get lmStudioSettings;

  /// No description provided for @serveOnLocalNetworkHelp.
  ///
  /// In en, this message translates to:
  /// **'The \"Serve on Local Network\" toggle should be enabled (shown in orange/green) in the LM Studio Developer tab.'**
  String get serveOnLocalNetworkHelp;

  /// No description provided for @networkConnections.
  ///
  /// In en, this message translates to:
  /// **'Network Connections:'**
  String get networkConnections;

  /// No description provided for @networkConnectionsTips.
  ///
  /// In en, this message translates to:
  /// **'• Replace \"localhost\" with your computer\'s IP address\n• Ensure both devices are on the same network\n• Check firewall settings for port 1234'**
  String get networkConnectionsTips;

  /// No description provided for @noConversationsToExport.
  ///
  /// In en, this message translates to:
  /// **'No conversations to export'**
  String get noConversationsToExport;

  /// No description provided for @exportingConversations.
  ///
  /// In en, this message translates to:
  /// **'Exporting {count} conversation(s)...'**
  String exportingConversations(int count);

  /// No description provided for @exportSuccess.
  ///
  /// In en, this message translates to:
  /// **'{count} conversation(s) exported successfully'**
  String exportSuccess(int count);

  /// No description provided for @languageSection.
  ///
  /// In en, this message translates to:
  /// **'LANGUAGE'**
  String get languageSection;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language'**
  String get languageSubtitle;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @spanish.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get spanish;

  /// No description provided for @german.
  ///
  /// In en, this message translates to:
  /// **'Deutsch'**
  String get german;

  /// No description provided for @french.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get french;

  /// No description provided for @russian.
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get russian;

  /// No description provided for @chinese.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get chinese;

  /// No description provided for @toolsCallingTitle.
  ///
  /// In en, this message translates to:
  /// **'Tools Calling'**
  String get toolsCallingTitle;

  /// No description provided for @toolCallingSection.
  ///
  /// In en, this message translates to:
  /// **'TOOL CALLING'**
  String get toolCallingSection;

  /// No description provided for @enableToolCallingAndMcps.
  ///
  /// In en, this message translates to:
  /// **'Enable Tool Calling & MCPs'**
  String get enableToolCallingAndMcps;

  /// No description provided for @enableToolCallingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Allow AI to search web and call MCPs'**
  String get enableToolCallingSubtitle;

  /// No description provided for @builtInToolsSection.
  ///
  /// In en, this message translates to:
  /// **'BUILT-IN TOOLS'**
  String get builtInToolsSection;

  /// No description provided for @builtInToolsInfo.
  ///
  /// In en, this message translates to:
  /// **'Tools executed locally by the app when AI requests them'**
  String get builtInToolsInfo;

  /// No description provided for @webSearch.
  ///
  /// In en, this message translates to:
  /// **'Web Search'**
  String get webSearch;

  /// No description provided for @webSearchUsingSearxng.
  ///
  /// In en, this message translates to:
  /// **'Using SearXNG'**
  String get webSearchUsingSearxng;

  /// No description provided for @webSearchDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled (configure SearXNG or upgrade to Pro)'**
  String get webSearchDisabled;

  /// No description provided for @integratedMcpsSection.
  ///
  /// In en, this message translates to:
  /// **'INTEGRATED MCPs'**
  String get integratedMcpsSection;

  /// No description provided for @integratedMcpsInfo.
  ///
  /// In en, this message translates to:
  /// **'Use MCPs you already set up in LM Studio. Just add their names from your mcp.json here.'**
  String get integratedMcpsInfo;

  /// No description provided for @integratedMcpsAuthRequired.
  ///
  /// In en, this message translates to:
  /// **'Integrated MCPs require Authentication enabled in LM Studio and an API token set in Settings → API Token.'**
  String get integratedMcpsAuthRequired;

  /// No description provided for @requiresApiToken.
  ///
  /// In en, this message translates to:
  /// **'Requires API token'**
  String get requiresApiToken;

  /// No description provided for @setApiTokenTooltip.
  ///
  /// In en, this message translates to:
  /// **'Set an API token in Settings to enable'**
  String get setApiTokenTooltip;

  /// No description provided for @noIntegratedMcps.
  ///
  /// In en, this message translates to:
  /// **'No integrated MCPs configured'**
  String get noIntegratedMcps;

  /// No description provided for @addManually.
  ///
  /// In en, this message translates to:
  /// **'Add Manually'**
  String get addManually;

  /// No description provided for @importMcpJson.
  ///
  /// In en, this message translates to:
  /// **'Import mcp.json'**
  String get importMcpJson;

  /// No description provided for @ephemeralMcpsSection.
  ///
  /// In en, this message translates to:
  /// **'EPHEMERAL MCPs'**
  String get ephemeralMcpsSection;

  /// No description provided for @ephemeralMcpsInfo.
  ///
  /// In en, this message translates to:
  /// **'HTTP MCP servers sent per-request. Requires \"Allow per-request MCPs\" in LM Studio.'**
  String get ephemeralMcpsInfo;

  /// No description provided for @requiresPerRequestMcps.
  ///
  /// In en, this message translates to:
  /// **'Requires: Developer → Server Settings → Allow per-request MCPs'**
  String get requiresPerRequestMcps;

  /// No description provided for @noEphemeralMcps.
  ///
  /// In en, this message translates to:
  /// **'No ephemeral MCPs configured'**
  String get noEphemeralMcps;

  /// No description provided for @addHttpMcpServer.
  ///
  /// In en, this message translates to:
  /// **'Add HTTP MCP Server'**
  String get addHttpMcpServer;

  /// No description provided for @browseExampleMcps.
  ///
  /// In en, this message translates to:
  /// **'Browse Example MCP Servers'**
  String get browseExampleMcps;

  /// No description provided for @addIntegratedMcpTitle.
  ///
  /// In en, this message translates to:
  /// **'Add MCP'**
  String get addIntegratedMcpTitle;

  /// No description provided for @editIntegratedMcpTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit MCP'**
  String get editIntegratedMcpTitle;

  /// No description provided for @addIntegratedMcpInfo.
  ///
  /// In en, this message translates to:
  /// **'Copy the name from LM Studio\'s mcp.json and paste it here. For example, if you see a key named playwright, type playwright.'**
  String get addIntegratedMcpInfo;

  /// No description provided for @mcpNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name from mcp.json'**
  String get mcpNameLabel;

  /// No description provided for @mcpNameHint.
  ///
  /// In en, this message translates to:
  /// **'playwright'**
  String get mcpNameHint;

  /// No description provided for @mcpNameHelper.
  ///
  /// In en, this message translates to:
  /// **'Letters, numbers, and hyphens only — use web-search, not web_search.'**
  String get mcpNameHelper;

  /// No description provided for @exampleMcpJsonEntry.
  ///
  /// In en, this message translates to:
  /// **'💡 Example mcp.json entry:'**
  String get exampleMcpJsonEntry;

  /// No description provided for @nameIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameIsRequired;

  /// No description provided for @mcpNameInvalidChars.
  ///
  /// In en, this message translates to:
  /// **'Use hyphens instead of underscores (LM Studio won\'t accept names like web_search).'**
  String get mcpNameInvalidChars;

  /// No description provided for @mcpNameAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'That MCP is already added'**
  String get mcpNameAlreadyExists;

  /// No description provided for @addedMcp.
  ///
  /// In en, this message translates to:
  /// **'Added {name}'**
  String addedMcp(String name);

  /// No description provided for @updatedMcp.
  ///
  /// In en, this message translates to:
  /// **'Updated {name}'**
  String updatedMcp(String name);

  /// No description provided for @editMcpTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit name'**
  String get editMcpTooltip;

  /// No description provided for @unlimitedToolCalls.
  ///
  /// In en, this message translates to:
  /// **'Unlimited Tool Calls'**
  String get unlimitedToolCalls;

  /// No description provided for @unlimitedToolCallsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Remove the 10-call limit for Integrated & Ephemeral MCPs (does not affect Pro Search)'**
  String get unlimitedToolCallsSubtitle;

  /// No description provided for @unlimitedToolCallsOn.
  ///
  /// In en, this message translates to:
  /// **'No limit on MCP tool call iterations'**
  String get unlimitedToolCallsOn;

  /// No description provided for @unlimitedToolCallsOff.
  ///
  /// In en, this message translates to:
  /// **'Limited to 10 tool call iterations'**
  String get unlimitedToolCallsOff;

  /// No description provided for @structuredOutput.
  ///
  /// In en, this message translates to:
  /// **'Structured Output'**
  String get structuredOutput;

  /// No description provided for @structuredOutputSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Force JSON response format'**
  String get structuredOutputSubtitle;

  /// No description provided for @reasoningMode.
  ///
  /// In en, this message translates to:
  /// **'Reasoning Mode'**
  String get reasoningMode;

  /// No description provided for @reasoningOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get reasoningOff;

  /// No description provided for @reasoningLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get reasoningLow;

  /// No description provided for @reasoningMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get reasoningMedium;

  /// No description provided for @reasoningHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get reasoningHigh;

  /// No description provided for @reasoningOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get reasoningOn;

  /// No description provided for @reasoningDescOff.
  ///
  /// In en, this message translates to:
  /// **'No reasoning traces'**
  String get reasoningDescOff;

  /// No description provided for @reasoningDescLow.
  ///
  /// In en, this message translates to:
  /// **'Minimal reasoning'**
  String get reasoningDescLow;

  /// No description provided for @reasoningDescMedium.
  ///
  /// In en, this message translates to:
  /// **'Balanced reasoning'**
  String get reasoningDescMedium;

  /// No description provided for @reasoningDescHigh.
  ///
  /// In en, this message translates to:
  /// **'Detailed reasoning'**
  String get reasoningDescHigh;

  /// No description provided for @reasoningDescOn.
  ///
  /// In en, this message translates to:
  /// **'Full reasoning traces'**
  String get reasoningDescOn;

  /// No description provided for @helpSection.
  ///
  /// In en, this message translates to:
  /// **'HELP'**
  String get helpSection;

  /// No description provided for @toolCallingGuide.
  ///
  /// In en, this message translates to:
  /// **'Tool Calling Guide'**
  String get toolCallingGuide;

  /// No description provided for @toolCallingGuideSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Learn how tools work'**
  String get toolCallingGuideSubtitle;

  /// No description provided for @searxngSetupGuide.
  ///
  /// In en, this message translates to:
  /// **'SearXNG Setup Guide'**
  String get searxngSetupGuide;

  /// No description provided for @searxngSetupGuideSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set up your own search server'**
  String get searxngSetupGuideSubtitle;

  /// No description provided for @webSearchConfig.
  ///
  /// In en, this message translates to:
  /// **'Web Search Configuration'**
  String get webSearchConfig;

  /// No description provided for @howWebSearchWorks.
  ///
  /// In en, this message translates to:
  /// **'💡 How Web Search Works'**
  String get howWebSearchWorks;

  /// No description provided for @howWebSearchWorksSteps.
  ///
  /// In en, this message translates to:
  /// **'1. AI decides it needs current info\n2. App searches using Premium Search or SearXNG\n3. Results are sent back to AI\n4. AI synthesizes an answer'**
  String get howWebSearchWorksSteps;

  /// No description provided for @searchResultsLabel.
  ///
  /// In en, this message translates to:
  /// **'Search Results: '**
  String get searchResultsLabel;

  /// No description provided for @webSearchDisabledWarning.
  ///
  /// In en, this message translates to:
  /// **'Web search disabled. Configure SearXNG or upgrade to Pro.'**
  String get webSearchDisabledWarning;

  /// No description provided for @searxngUrlOptional.
  ///
  /// In en, this message translates to:
  /// **'SearXNG URL (Optional)'**
  String get searxngUrlOptional;

  /// No description provided for @searxngUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'SearXNG URL'**
  String get searxngUrlLabel;

  /// No description provided for @searxngUrlHint.
  ///
  /// In en, this message translates to:
  /// **'http://localhost:8888'**
  String get searxngUrlHint;

  /// No description provided for @quickSetupDocker.
  ///
  /// In en, this message translates to:
  /// **'🐳 Quick Setup with Docker:'**
  String get quickSetupDocker;

  /// No description provided for @dockerCommand.
  ///
  /// In en, this message translates to:
  /// **'docker run -d -p 8888:8080 searxng/searxng'**
  String get dockerCommand;

  /// No description provided for @mcpBadge.
  ///
  /// In en, this message translates to:
  /// **'MCP'**
  String get mcpBadge;

  /// No description provided for @mcpResultBadge.
  ///
  /// In en, this message translates to:
  /// **'MCP Result'**
  String get mcpResultBadge;

  /// No description provided for @webSearchSourcesTitle.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get webSearchSourcesTitle;

  /// No description provided for @toolBadge.
  ///
  /// In en, this message translates to:
  /// **'Tool'**
  String get toolBadge;

  /// No description provided for @resultBadge.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get resultBadge;

  /// No description provided for @failedToLoadImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to load image'**
  String get failedToLoadImage;

  /// No description provided for @thinking.
  ///
  /// In en, this message translates to:
  /// **'Thinking'**
  String get thinking;

  /// No description provided for @think.
  ///
  /// In en, this message translates to:
  /// **'Think'**
  String get think;

  /// No description provided for @thoughtFor.
  ///
  /// In en, this message translates to:
  /// **'Thought for {duration}'**
  String thoughtFor(String duration);

  /// No description provided for @performanceStats.
  ///
  /// In en, this message translates to:
  /// **'Performance Stats'**
  String get performanceStats;

  /// No description provided for @regenerate.
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get regenerate;

  /// No description provided for @editMessage.
  ///
  /// In en, this message translates to:
  /// **'Edit Message'**
  String get editMessage;

  /// No description provided for @editMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Edit your message...'**
  String get editMessageHint;

  /// No description provided for @saveAndRegenerate.
  ///
  /// In en, this message translates to:
  /// **'Save & Regenerate'**
  String get saveAndRegenerate;

  /// No description provided for @deleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete Message'**
  String get deleteMessage;

  /// No description provided for @deleteMessageConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this message?'**
  String get deleteMessageConfirm;

  /// No description provided for @mcpCallTitle.
  ///
  /// In en, this message translates to:
  /// **'MCP Call'**
  String get mcpCallTitle;

  /// No description provided for @mcpResultTitle.
  ///
  /// In en, this message translates to:
  /// **'MCP Result'**
  String get mcpResultTitle;

  /// No description provided for @toolCallTitle.
  ///
  /// In en, this message translates to:
  /// **'Tool Call'**
  String get toolCallTitle;

  /// No description provided for @toolResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Tool Result'**
  String get toolResultTitle;

  /// No description provided for @attachFile.
  ///
  /// In en, this message translates to:
  /// **'Attach File'**
  String get attachFile;

  /// No description provided for @photoLibrary.
  ///
  /// In en, this message translates to:
  /// **'Photo Library'**
  String get photoLibrary;

  /// No description provided for @attachImagesForVision.
  ///
  /// In en, this message translates to:
  /// **'Attach images for vision analysis'**
  String get attachImagesForVision;

  /// No description provided for @requiresVisionModel.
  ///
  /// In en, this message translates to:
  /// **'Requires a vision-capable model'**
  String get requiresVisionModel;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @captureImageWithCamera.
  ///
  /// In en, this message translates to:
  /// **'Capture image with camera'**
  String get captureImageWithCamera;

  /// No description provided for @imageFromFiles.
  ///
  /// In en, this message translates to:
  /// **'Image from Files'**
  String get imageFromFiles;

  /// No description provided for @pickImageFromFilesApp.
  ///
  /// In en, this message translates to:
  /// **'Pick an image from the Files app'**
  String get pickImageFromFilesApp;

  /// No description provided for @attachDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get attachDocuments;

  /// No description provided for @attachDocumentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'PDF, Markdown, Excel (.xlsx), CSV, text, code, and more'**
  String get attachDocumentsSubtitle;

  /// No description provided for @textFileTxt.
  ///
  /// In en, this message translates to:
  /// **'Text File (.txt)'**
  String get textFileTxt;

  /// No description provided for @attachPlainText.
  ///
  /// In en, this message translates to:
  /// **'Attach plain text documents'**
  String get attachPlainText;

  /// No description provided for @csvFileCsv.
  ///
  /// In en, this message translates to:
  /// **'CSV File (.csv)'**
  String get csvFileCsv;

  /// No description provided for @attachSpreadsheetData.
  ///
  /// In en, this message translates to:
  /// **'Attach spreadsheet data'**
  String get attachSpreadsheetData;

  /// No description provided for @pdfDocumentPdf.
  ///
  /// In en, this message translates to:
  /// **'PDF Document (.pdf)'**
  String get pdfDocumentPdf;

  /// No description provided for @attachPdfDocuments.
  ///
  /// In en, this message translates to:
  /// **'Attach PDF documents'**
  String get attachPdfDocuments;

  /// No description provided for @mcpLabel.
  ///
  /// In en, this message translates to:
  /// **'MCP:'**
  String get mcpLabel;

  /// No description provided for @typeMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeMessageHint;

  /// No description provided for @attachFilesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Attach files'**
  String get attachFilesTooltip;

  /// No description provided for @customizeChat.
  ///
  /// In en, this message translates to:
  /// **'Customize Chat'**
  String get customizeChat;

  /// No description provided for @overrideGlobalAppearance.
  ///
  /// In en, this message translates to:
  /// **'Override global appearance settings for this chat'**
  String get overrideGlobalAppearance;

  /// No description provided for @background.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get background;

  /// No description provided for @userAvatar.
  ///
  /// In en, this message translates to:
  /// **'User Avatar'**
  String get userAvatar;

  /// No description provided for @assistantAvatar.
  ///
  /// In en, this message translates to:
  /// **'Assistant Avatar'**
  String get assistantAvatar;

  /// No description provided for @colorsSection.
  ///
  /// In en, this message translates to:
  /// **'Colors'**
  String get colorsSection;

  /// No description provided for @userBubble.
  ///
  /// In en, this message translates to:
  /// **'User Bubble'**
  String get userBubble;

  /// No description provided for @userText.
  ///
  /// In en, this message translates to:
  /// **'User Text'**
  String get userText;

  /// No description provided for @assistantBubble.
  ///
  /// In en, this message translates to:
  /// **'Assistant Bubble'**
  String get assistantBubble;

  /// No description provided for @assistantText.
  ///
  /// In en, this message translates to:
  /// **'Assistant Text'**
  String get assistantText;

  /// No description provided for @darkOverlay.
  ///
  /// In en, this message translates to:
  /// **'Dim wallpaper'**
  String get darkOverlay;

  /// No description provided for @darkOverlayDescription.
  ///
  /// In en, this message translates to:
  /// **'How dark to make the wallpaper behind your chat'**
  String get darkOverlayDescription;

  /// No description provided for @usingGlobal.
  ///
  /// In en, this message translates to:
  /// **'Using global'**
  String get usingGlobal;

  /// No description provided for @useGlobal.
  ///
  /// In en, this message translates to:
  /// **'Use Global'**
  String get useGlobal;

  /// No description provided for @setCustom.
  ///
  /// In en, this message translates to:
  /// **'Set Custom'**
  String get setCustom;

  /// No description provided for @customColor.
  ///
  /// In en, this message translates to:
  /// **'Custom color'**
  String get customColor;

  /// No description provided for @defaultThemeColor.
  ///
  /// In en, this message translates to:
  /// **'Default theme color'**
  String get defaultThemeColor;

  /// No description provided for @resetToDefault.
  ///
  /// In en, this message translates to:
  /// **'Reset to default'**
  String get resetToDefault;

  /// No description provided for @pickAColor.
  ///
  /// In en, this message translates to:
  /// **'Pick a color'**
  String get pickAColor;

  /// No description provided for @chatSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat Settings'**
  String get chatSettingsTitle;

  /// No description provided for @overrideGlobalSettings.
  ///
  /// In en, this message translates to:
  /// **'Override global settings for this chat only'**
  String get overrideGlobalSettings;

  /// No description provided for @resetAll.
  ///
  /// In en, this message translates to:
  /// **'Reset All'**
  String get resetAll;

  /// No description provided for @modelOverride.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get modelOverride;

  /// No description provided for @noneSelected.
  ///
  /// In en, this message translates to:
  /// **'None selected'**
  String get noneSelected;

  /// No description provided for @systemPromptOverride.
  ///
  /// In en, this message translates to:
  /// **'Persona'**
  String get systemPromptOverride;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @noSavedPromptsInfo.
  ///
  /// In en, this message translates to:
  /// **'No saved personas. Go to Settings → Personas to create some.'**
  String get noSavedPromptsInfo;

  /// No description provided for @selectSavedPromptHint.
  ///
  /// In en, this message translates to:
  /// **'Select a persona...'**
  String get selectSavedPromptHint;

  /// No description provided for @enterCustomPromptHint.
  ///
  /// In en, this message translates to:
  /// **'Enter custom persona prompt...'**
  String get enterCustomPromptHint;

  /// No description provided for @personaShareMemoriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Share memories'**
  String get personaShareMemoriesLabel;

  /// No description provided for @personaShareMemoriesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When off, this persona won\'t receive or learn memories in chats'**
  String get personaShareMemoriesSubtitle;

  /// No description provided for @webSearchOffForThisChat.
  ///
  /// In en, this message translates to:
  /// **'Off for this chat only'**
  String get webSearchOffForThisChat;

  /// No description provided for @reasoningOffForThisChat.
  ///
  /// In en, this message translates to:
  /// **'Off for this chat only'**
  String get reasoningOffForThisChat;

  /// No description provided for @temperatureOverride.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperatureOverride;

  /// No description provided for @maxTokensOverride.
  ///
  /// In en, this message translates to:
  /// **'Max Tokens'**
  String get maxTokensOverride;

  /// No description provided for @topPOverride.
  ///
  /// In en, this message translates to:
  /// **'Top P'**
  String get topPOverride;

  /// No description provided for @topKOverride.
  ///
  /// In en, this message translates to:
  /// **'Top K'**
  String get topKOverride;

  /// No description provided for @minPOverride.
  ///
  /// In en, this message translates to:
  /// **'Min P'**
  String get minPOverride;

  /// No description provided for @repeatPenaltyOverride.
  ///
  /// In en, this message translates to:
  /// **'Repeat Penalty'**
  String get repeatPenaltyOverride;

  /// No description provided for @contextLengthOverride.
  ///
  /// In en, this message translates to:
  /// **'Context Length'**
  String get contextLengthOverride;

  /// No description provided for @systemPromptsTitle.
  ///
  /// In en, this message translates to:
  /// **'Personas and System Prompts'**
  String get systemPromptsTitle;

  /// No description provided for @addSystemPromptTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add prompt or persona'**
  String get addSystemPromptTooltip;

  /// No description provided for @systemPromptsInfoText.
  ///
  /// In en, this message translates to:
  /// **'Create and manage system prompts. Bind them to specific models or use them globally. Select one to make it active.'**
  String get systemPromptsInfoText;

  /// No description provided for @savedPromptsSection.
  ///
  /// In en, this message translates to:
  /// **'SAVED PROMPTS'**
  String get savedPromptsSection;

  /// No description provided for @addSystemPrompt.
  ///
  /// In en, this message translates to:
  /// **'Add System Prompt'**
  String get addSystemPrompt;

  /// No description provided for @newPrompt.
  ///
  /// In en, this message translates to:
  /// **'New Prompt or Persona'**
  String get newPrompt;

  /// No description provided for @noPromptSet.
  ///
  /// In en, this message translates to:
  /// **'No prompt set'**
  String get noPromptSet;

  /// No description provided for @editSystemPrompt.
  ///
  /// In en, this message translates to:
  /// **'Edit System Prompt'**
  String get editSystemPrompt;

  /// No description provided for @newSystemPrompt.
  ///
  /// In en, this message translates to:
  /// **'New Prompt or Persona'**
  String get newSystemPrompt;

  /// No description provided for @promptNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Prompt Name'**
  String get promptNameLabel;

  /// No description provided for @promptNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Code Assistant, Creative Writer...'**
  String get promptNameHint;

  /// No description provided for @systemPromptLabel.
  ///
  /// In en, this message translates to:
  /// **'System Prompt'**
  String get systemPromptLabel;

  /// No description provided for @systemPromptEditorHint.
  ///
  /// In en, this message translates to:
  /// **'You are a helpful assistant that...'**
  String get systemPromptEditorHint;

  /// No description provided for @bindToModels.
  ///
  /// In en, this message translates to:
  /// **'Bind to Specific Models'**
  String get bindToModels;

  /// No description provided for @bindToModelsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Restrict this prompt to certain models. When unbound, it\'s available for all models.'**
  String get bindToModelsSubtitle;

  /// No description provided for @noModelsLoaded.
  ///
  /// In en, this message translates to:
  /// **'No models loaded. Connect to LM Studio and load models to bind this prompt.'**
  String get noModelsLoaded;

  /// No description provided for @templatesSection.
  ///
  /// In en, this message translates to:
  /// **'TEMPLATES'**
  String get templatesSection;

  /// No description provided for @pleaseEnterPromptName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name for this prompt'**
  String get pleaseEnterPromptName;

  /// No description provided for @pleaseEnterPromptContent.
  ///
  /// In en, this message translates to:
  /// **'Please enter the prompt content'**
  String get pleaseEnterPromptContent;

  /// No description provided for @deleteSystemPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete System Prompt?'**
  String get deleteSystemPromptTitle;

  /// No description provided for @deleteSystemPromptMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"? This cannot be undone.'**
  String deleteSystemPromptMessage(String name);

  /// No description provided for @templateCodeAssistant.
  ///
  /// In en, this message translates to:
  /// **'Code Assistant'**
  String get templateCodeAssistant;

  /// No description provided for @templateCreativeWriter.
  ///
  /// In en, this message translates to:
  /// **'Creative Writer'**
  String get templateCreativeWriter;

  /// No description provided for @templateConciseExpert.
  ///
  /// In en, this message translates to:
  /// **'Concise Expert'**
  String get templateConciseExpert;

  /// No description provided for @templateResearcher.
  ///
  /// In en, this message translates to:
  /// **'Researcher'**
  String get templateResearcher;

  /// No description provided for @templateTutor.
  ///
  /// In en, this message translates to:
  /// **'Tutor'**
  String get templateTutor;

  /// No description provided for @templateTechnicalWriter.
  ///
  /// In en, this message translates to:
  /// **'Technical Writer'**
  String get templateTechnicalWriter;

  /// No description provided for @downloadProgress.
  ///
  /// In en, this message translates to:
  /// **'Download Progress'**
  String get downloadProgress;

  /// No description provided for @progressLabel.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progressLabel;

  /// No description provided for @speedLabel.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get speedLabel;

  /// No description provided for @etaLabel.
  ///
  /// In en, this message translates to:
  /// **'ETA'**
  String get etaLabel;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notAvailable;

  /// No description provided for @calculating.
  ///
  /// In en, this message translates to:
  /// **'Calculating...'**
  String get calculating;

  /// No description provided for @moveToFolderPopup.
  ///
  /// In en, this message translates to:
  /// **'Move to Folder'**
  String get moveToFolderPopup;

  /// No description provided for @contextInfo.
  ///
  /// In en, this message translates to:
  /// **'Context: {used} / {total}'**
  String contextInfo(String used, String total);

  /// No description provided for @hideAvatars.
  ///
  /// In en, this message translates to:
  /// **'Hide Avatars'**
  String get hideAvatars;

  /// No description provided for @hideAvatarsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Remove avatar icons from chat messages'**
  String get hideAvatarsSubtitle;

  /// No description provided for @autoScroll.
  ///
  /// In en, this message translates to:
  /// **'Auto-scroll'**
  String get autoScroll;

  /// No description provided for @autoScrollSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scroll to bottom when new messages arrive'**
  String get autoScrollSubtitle;

  /// No description provided for @editMcpServer.
  ///
  /// In en, this message translates to:
  /// **'Edit MCP Server'**
  String get editMcpServer;

  /// No description provided for @addMcpServer.
  ///
  /// In en, this message translates to:
  /// **'Add MCP Server'**
  String get addMcpServer;

  /// No description provided for @serverLabelRequired.
  ///
  /// In en, this message translates to:
  /// **'Server Label *'**
  String get serverLabelRequired;

  /// No description provided for @serverLabelHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., huggingface, tiktoken'**
  String get serverLabelHint;

  /// No description provided for @serverLabelHelper.
  ///
  /// In en, this message translates to:
  /// **'A name to identify this server'**
  String get serverLabelHelper;

  /// No description provided for @serverUrlRequired.
  ///
  /// In en, this message translates to:
  /// **'Server URL *'**
  String get serverUrlRequired;

  /// No description provided for @serverUrlMcpHint.
  ///
  /// In en, this message translates to:
  /// **'https://huggingface.co/mcp'**
  String get serverUrlMcpHint;

  /// No description provided for @serverUrlHelper.
  ///
  /// In en, this message translates to:
  /// **'HTTP/HTTPS URL of the MCP server'**
  String get serverUrlHelper;

  /// No description provided for @authorizationOptional.
  ///
  /// In en, this message translates to:
  /// **'API Key (Optional)'**
  String get authorizationOptional;

  /// No description provided for @authorizationHint.
  ///
  /// In en, this message translates to:
  /// **'hf_xxxxxxxx or Bearer hf_xxxxxxxx'**
  String get authorizationHint;

  /// No description provided for @authorizationHelper.
  ///
  /// In en, this message translates to:
  /// **'Sent as the Authorization header to this MCP. Paste a raw token (Bearer is added) or a full header value.'**
  String get authorizationHelper;

  /// No description provided for @additionalHeaders.
  ///
  /// In en, this message translates to:
  /// **'Additional Headers'**
  String get additionalHeaders;

  /// No description provided for @additionalHeadersHint.
  ///
  /// In en, this message translates to:
  /// **'X-Custom-Header: value'**
  String get additionalHeadersHint;

  /// No description provided for @additionalHeadersHelper.
  ///
  /// In en, this message translates to:
  /// **'One header per line (name: value).\nAPI key / Authorization is set above.'**
  String get additionalHeadersHelper;

  /// No description provided for @labelAndUrlRequired.
  ///
  /// In en, this message translates to:
  /// **'Label and URL are required'**
  String get labelAndUrlRequired;

  /// No description provided for @urlMustStartWithHttp.
  ///
  /// In en, this message translates to:
  /// **'URL must start with http:// or https://'**
  String get urlMustStartWithHttp;

  /// No description provided for @mcpServerUpdated.
  ///
  /// In en, this message translates to:
  /// **'MCP server updated'**
  String get mcpServerUpdated;

  /// No description provided for @mcpServerAdded.
  ///
  /// In en, this message translates to:
  /// **'MCP server added'**
  String get mcpServerAdded;

  /// No description provided for @importMcpJsonTitle.
  ///
  /// In en, this message translates to:
  /// **'Import mcp.json'**
  String get importMcpJsonTitle;

  /// No description provided for @pasteMcpJsonContent.
  ///
  /// In en, this message translates to:
  /// **'Paste your mcp.json content'**
  String get pasteMcpJsonContent;

  /// No description provided for @mcpJsonLocation.
  ///
  /// In en, this message translates to:
  /// **'Find it at: ~/.lmstudio/config/mcp.json\nOr in LM Studio: Developer → MCP Settings → Open config'**
  String get mcpJsonLocation;

  /// No description provided for @mcpJsonContentLabel.
  ///
  /// In en, this message translates to:
  /// **'mcp.json content'**
  String get mcpJsonContentLabel;

  /// No description provided for @mcpJsonContentHelper.
  ///
  /// In en, this message translates to:
  /// **'Paste the entire mcp.json file content'**
  String get mcpJsonContentHelper;

  /// No description provided for @parseJson.
  ///
  /// In en, this message translates to:
  /// **'Parse JSON'**
  String get parseJson;

  /// No description provided for @foundMcpServers.
  ///
  /// In en, this message translates to:
  /// **'Found {count} MCP server(s):'**
  String foundMcpServers(int count);

  /// No description provided for @hasAuthHeaders.
  ///
  /// In en, this message translates to:
  /// **'Has authentication headers'**
  String get hasAuthHeaders;

  /// No description provided for @importSelected.
  ///
  /// In en, this message translates to:
  /// **'Import {count} Selected'**
  String importSelected(int count);

  /// No description provided for @pleasePasteMcpJson.
  ///
  /// In en, this message translates to:
  /// **'Please paste your mcp.json content'**
  String get pleasePasteMcpJson;

  /// No description provided for @noMcpServersFound.
  ///
  /// In en, this message translates to:
  /// **'No mcpServers found in JSON'**
  String get noMcpServersFound;

  /// No description provided for @exampleMcpServers.
  ///
  /// In en, this message translates to:
  /// **'Example MCP Servers'**
  String get exampleMcpServers;

  /// No description provided for @gitMcpInfo.
  ///
  /// In en, this message translates to:
  /// **'These use GitMCP to provide docs from GitHub repos'**
  String get gitMcpInfo;

  /// No description provided for @browseMoreGitMcp.
  ///
  /// In en, this message translates to:
  /// **'Browse more at gitmcp.io'**
  String get browseMoreGitMcp;

  /// No description provided for @fileNotFound.
  ///
  /// In en, this message translates to:
  /// **'File not found'**
  String get fileNotFound;

  /// No description provided for @openWithExternalApp.
  ///
  /// In en, this message translates to:
  /// **'Open with external app'**
  String get openWithExternalApp;

  /// No description provided for @previewNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Preview not available'**
  String get previewNotAvailable;

  /// No description provided for @voiceMode.
  ///
  /// In en, this message translates to:
  /// **'Voice Mode'**
  String get voiceMode;

  /// No description provided for @voiceSettings.
  ///
  /// In en, this message translates to:
  /// **'Voice Settings'**
  String get voiceSettings;

  /// No description provided for @voiceSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Text-to-speech, voice input, and voice mode'**
  String get voiceSettingsSubtitle;

  /// No description provided for @voiceSection.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get voiceSection;

  /// No description provided for @voiceStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get voiceStatus;

  /// No description provided for @voiceTtsEngine.
  ///
  /// In en, this message translates to:
  /// **'Text-to-Speech Engine'**
  String get voiceTtsEngine;

  /// No description provided for @voiceSttEngine.
  ///
  /// In en, this message translates to:
  /// **'Speech Recognition Engine'**
  String get voiceSttEngine;

  /// No description provided for @voiceAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get voiceAvailable;

  /// No description provided for @voiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get voiceUnavailable;

  /// No description provided for @voiceTtsSettings.
  ///
  /// In en, this message translates to:
  /// **'Text-to-Speech'**
  String get voiceTtsSettings;

  /// No description provided for @voiceSttSettings.
  ///
  /// In en, this message translates to:
  /// **'Speech-to-Text'**
  String get voiceSttSettings;

  /// No description provided for @voiceSttProvider.
  ///
  /// In en, this message translates to:
  /// **'Speech Recognition Provider'**
  String get voiceSttProvider;

  /// No description provided for @voiceSttProviderSystem.
  ///
  /// In en, this message translates to:
  /// **'System speech'**
  String get voiceSttProviderSystem;

  /// No description provided for @voiceSttProviderSystemSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Apple Speech on iOS, Google Speech on Android'**
  String get voiceSttProviderSystemSubtitle;

  /// No description provided for @voiceSttProviderWhisper.
  ///
  /// In en, this message translates to:
  /// **'On-device Whisper'**
  String get voiceSttProviderWhisper;

  /// No description provided for @voiceSttProviderWhisperSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Offline sherpa-onnx Whisper — more accurate, works the same on all platforms'**
  String get voiceSttProviderWhisperSubtitle;

  /// No description provided for @voiceWhisperModelNotDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Whisper model not downloaded'**
  String get voiceWhisperModelNotDownloaded;

  /// No description provided for @voiceWhisperModelReady.
  ///
  /// In en, this message translates to:
  /// **'Whisper model ready'**
  String get voiceWhisperModelReady;

  /// No description provided for @voiceWhisperModelSize.
  ///
  /// In en, this message translates to:
  /// **'Choose a size — larger models transcribe more accurately'**
  String get voiceWhisperModelSize;

  /// No description provided for @voiceWhisperDownloadButton.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get voiceWhisperDownloadButton;

  /// No description provided for @voiceWhisperDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading Whisper model…'**
  String get voiceWhisperDownloading;

  /// No description provided for @voiceWhisperDownloadStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting download…'**
  String get voiceWhisperDownloadStarting;

  /// No description provided for @voiceWhisperDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get voiceWhisperDownloadFailed;

  /// No description provided for @voiceWhisperDeleteModel.
  ///
  /// In en, this message translates to:
  /// **'Delete selected Whisper model'**
  String get voiceWhisperDeleteModel;

  /// No description provided for @voiceWhisperDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Whisper model?'**
  String get voiceWhisperDeleteTitle;

  /// No description provided for @voiceWhisperDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'This frees the selected model from device storage. On-device speech recognition will fall back to system speech until you download a Whisper model again.'**
  String get voiceWhisperDeleteMessage;

  /// No description provided for @voiceWhisperDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get voiceWhisperDeleteConfirm;

  /// No description provided for @voiceWhisperFallback.
  ///
  /// In en, this message translates to:
  /// **'Falls back to system speech if the model is not downloaded'**
  String get voiceWhisperFallback;

  /// No description provided for @voiceWhisperBiggerBetterTitle.
  ///
  /// In en, this message translates to:
  /// **'Why bigger models?'**
  String get voiceWhisperBiggerBetterTitle;

  /// No description provided for @voiceWhisperBiggerBetterBody.
  ///
  /// In en, this message translates to:
  /// **'Larger Whisper models usually produce more accurate transcripts — especially with accents, quiet audio, background noise, and uncommon words. They also need more storage and run slower on your device.\n\nTiny is fine for short, clear speech. Base or Small is a better fit for longer files. Large v3 Turbo is the fastest/smallest of the big models (pruned Large v3). Full Large v3 is the most accurate, but also the heaviest.'**
  String get voiceWhisperBiggerBetterBody;

  /// No description provided for @voiceWhisperUseModel.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get voiceWhisperUseModel;

  /// No description provided for @voiceWhisperSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get voiceWhisperSelected;

  /// No description provided for @voiceWhisperDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get voiceWhisperDownloaded;

  /// No description provided for @audioSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up voice & audio'**
  String get audioSetupTitle;

  /// No description provided for @audioSetupMessage.
  ///
  /// In en, this message translates to:
  /// **'Voice chat needs the assistant to speak aloud. Download a voice for the most natural sound, or use your phone\'s built-in voices — no download needed.'**
  String get audioSetupMessage;

  /// No description provided for @audioSetupWhisperStatus.
  ///
  /// In en, this message translates to:
  /// **'Whisper speech recognition'**
  String get audioSetupWhisperStatus;

  /// No description provided for @audioSetupKokoroStatus.
  ///
  /// In en, this message translates to:
  /// **'Kokoro neural voice'**
  String get audioSetupKokoroStatus;

  /// No description provided for @audioSetupStatusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get audioSetupStatusReady;

  /// No description provided for @audioSetupStatusMissing.
  ///
  /// In en, this message translates to:
  /// **'Not downloaded'**
  String get audioSetupStatusMissing;

  /// No description provided for @audioSetupOnDeviceButton.
  ///
  /// In en, this message translates to:
  /// **'Download Kokoro voice'**
  String get audioSetupOnDeviceButton;

  /// No description provided for @audioSetupOnDeviceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Kokoro neural TTS · about 300 MB · works offline'**
  String get audioSetupOnDeviceSubtitle;

  /// No description provided for @audioSetupSystemButton.
  ///
  /// In en, this message translates to:
  /// **'Use system speech'**
  String get audioSetupSystemButton;

  /// No description provided for @audioSetupSystemSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Built-in STT and TTS — no download required'**
  String get audioSetupSystemSubtitle;

  /// No description provided for @audioSetupConfigureButton.
  ///
  /// In en, this message translates to:
  /// **'Voice settings'**
  String get audioSetupConfigureButton;

  /// No description provided for @audioSetupNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get audioSetupNotNow;

  /// No description provided for @audioSetupDownloadingWhisper.
  ///
  /// In en, this message translates to:
  /// **'Downloading Whisper…'**
  String get audioSetupDownloadingWhisper;

  /// No description provided for @audioSetupDownloadingKokoro.
  ///
  /// In en, this message translates to:
  /// **'Downloading Kokoro…'**
  String get audioSetupDownloadingKokoro;

  /// No description provided for @audioSetupDownloadComplete.
  ///
  /// In en, this message translates to:
  /// **'Models ready'**
  String get audioSetupDownloadComplete;

  /// No description provided for @audioSetupContinueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get audioSetupContinueButton;

  /// No description provided for @voiceModeSettings.
  ///
  /// In en, this message translates to:
  /// **'Voice Mode'**
  String get voiceModeSettings;

  /// No description provided for @voiceAutoRead.
  ///
  /// In en, this message translates to:
  /// **'Auto-read responses'**
  String get voiceAutoRead;

  /// No description provided for @voiceAutoReadSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatically read new assistant messages aloud'**
  String get voiceAutoReadSubtitle;

  /// No description provided for @voiceSpeechRate.
  ///
  /// In en, this message translates to:
  /// **'Speech Rate'**
  String get voiceSpeechRate;

  /// No description provided for @voicePitch.
  ///
  /// In en, this message translates to:
  /// **'Pitch'**
  String get voicePitch;

  /// No description provided for @voiceLanguage.
  ///
  /// In en, this message translates to:
  /// **'Voice Language'**
  String get voiceLanguage;

  /// No description provided for @voiceLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Language for spoken replies (text-to-speech)'**
  String get voiceLanguageSubtitle;

  /// No description provided for @voiceSttLanguage.
  ///
  /// In en, this message translates to:
  /// **'Recognition language'**
  String get voiceSttLanguage;

  /// No description provided for @voiceSttLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Used for the text mic and Voice Call. Can differ from spoken reply language.'**
  String get voiceSttLanguageSubtitle;

  /// No description provided for @voiceSelection.
  ///
  /// In en, this message translates to:
  /// **'Voice Selection'**
  String get voiceSelection;

  /// No description provided for @voiceDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get voiceDefault;

  /// No description provided for @voiceTestVoice.
  ///
  /// In en, this message translates to:
  /// **'Test Voice'**
  String get voiceTestVoice;

  /// No description provided for @voiceTestVoiceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Play a sample to hear the current voice settings'**
  String get voiceTestVoiceSubtitle;

  /// No description provided for @voiceTestPhrase.
  ///
  /// In en, this message translates to:
  /// **'Hello! This is how I sound now.'**
  String get voiceTestPhrase;

  /// No description provided for @voiceTestProgressInitializing.
  ///
  /// In en, this message translates to:
  /// **'Starting TTS engine…'**
  String get voiceTestProgressInitializing;

  /// No description provided for @voiceTestProgressGenerating.
  ///
  /// In en, this message translates to:
  /// **'Generating speech…'**
  String get voiceTestProgressGenerating;

  /// No description provided for @voiceTestProgressPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing playback…'**
  String get voiceTestProgressPreparing;

  /// No description provided for @voiceTestProgressPlaying.
  ///
  /// In en, this message translates to:
  /// **'Playing sample…'**
  String get voiceTestProgressPlaying;

  /// No description provided for @voiceTestProgressConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting to remote voice…'**
  String get voiceTestProgressConnecting;

  /// No description provided for @voiceTestProgressComplete.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get voiceTestProgressComplete;

  /// No description provided for @voiceKokoroEngineReady.
  ///
  /// In en, this message translates to:
  /// **'Engine ready — test should start quickly'**
  String get voiceKokoroEngineReady;

  /// No description provided for @voiceKokoroEngineWarming.
  ///
  /// In en, this message translates to:
  /// **'Warming up on-device engine…'**
  String get voiceKokoroEngineWarming;

  /// No description provided for @voiceAutoSend.
  ///
  /// In en, this message translates to:
  /// **'Auto-send after speech'**
  String get voiceAutoSend;

  /// No description provided for @voiceAutoSendSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatically send message when speech recognition ends'**
  String get voiceAutoSendSubtitle;

  /// No description provided for @voiceSttPauseFor.
  ///
  /// In en, this message translates to:
  /// **'Silence before send'**
  String get voiceSttPauseFor;

  /// No description provided for @voiceSttPauseForSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Seconds of silence after you stop speaking before your message is sent. This is separate from iOS mic session limits (~15s chunks, handled automatically).'**
  String get voiceSttPauseForSubtitle;

  /// No description provided for @voiceSttListenFor.
  ///
  /// In en, this message translates to:
  /// **'Maximum listening time'**
  String get voiceSttListenFor;

  /// No description provided for @voiceSttListenForSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hard cap per mic session before the app reopens the mic. On iOS, Apple also rotates sessions about every 15 seconds during long speech.'**
  String get voiceSttListenForSubtitle;

  /// No description provided for @voiceSttSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s'**
  String voiceSttSeconds(int seconds);

  /// No description provided for @voiceContinuousConversation.
  ///
  /// In en, this message translates to:
  /// **'Continuous conversation'**
  String get voiceContinuousConversation;

  /// No description provided for @voiceContinuousConversationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatically start listening after response is read aloud'**
  String get voiceContinuousConversationSubtitle;

  /// No description provided for @voiceTapToSpeak.
  ///
  /// In en, this message translates to:
  /// **'Tap to talk'**
  String get voiceTapToSpeak;

  /// No description provided for @voiceListening.
  ///
  /// In en, this message translates to:
  /// **'Listening…'**
  String get voiceListening;

  /// No description provided for @voiceThinking.
  ///
  /// In en, this message translates to:
  /// **'One moment…'**
  String get voiceThinking;

  /// No description provided for @voiceResponding.
  ///
  /// In en, this message translates to:
  /// **'Replying…'**
  String get voiceResponding;

  /// No description provided for @voiceSpeaking.
  ///
  /// In en, this message translates to:
  /// **'Speaking…'**
  String get voiceSpeaking;

  /// No description provided for @voiceConvoHintIdle.
  ///
  /// In en, this message translates to:
  /// **'Tap the circle to start talking'**
  String get voiceConvoHintIdle;

  /// No description provided for @voiceConvoHintListening.
  ///
  /// In en, this message translates to:
  /// **'I\'m listening — take your time'**
  String get voiceConvoHintListening;

  /// No description provided for @voiceConvoHintStarting.
  ///
  /// In en, this message translates to:
  /// **'Getting the microphone ready…'**
  String get voiceConvoHintStarting;

  /// No description provided for @voiceConvoHintProcessing.
  ///
  /// In en, this message translates to:
  /// **'Thinking…'**
  String get voiceConvoHintProcessing;

  /// No description provided for @voiceConvoHintSpeaking.
  ///
  /// In en, this message translates to:
  /// **''**
  String get voiceConvoHintSpeaking;

  /// No description provided for @voiceNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Speech recognition is not available on this device'**
  String get voiceNotAvailable;

  /// No description provided for @voiceStartRecording.
  ///
  /// In en, this message translates to:
  /// **'Start voice input'**
  String get voiceStartRecording;

  /// No description provided for @voiceStopRecording.
  ///
  /// In en, this message translates to:
  /// **'Stop recording'**
  String get voiceStopRecording;

  /// No description provided for @voiceDiscardRecording.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get voiceDiscardRecording;

  /// No description provided for @voiceSelectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get voiceSelectLanguage;

  /// No description provided for @voiceSelectVoice.
  ///
  /// In en, this message translates to:
  /// **'Select Voice'**
  String get voiceSelectVoice;

  /// No description provided for @voiceNoVoicesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No voices available for this language'**
  String get voiceNoVoicesAvailable;

  /// No description provided for @voiceAboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About Voice Mode'**
  String get voiceAboutTitle;

  /// No description provided for @voiceAboutDescription.
  ///
  /// In en, this message translates to:
  /// **'Voice mode can use your phone\'s built-in voices, or a downloaded voice on this device. Listening can use built-in recognition or an offline model you download. Speech stays on this device — nothing is sent to outside servers.'**
  String get voiceAboutDescription;

  /// No description provided for @voiceExitMode.
  ///
  /// In en, this message translates to:
  /// **'Switch to keyboard'**
  String get voiceExitMode;

  /// No description provided for @voiceTtsProvider.
  ///
  /// In en, this message translates to:
  /// **'TTS Provider'**
  String get voiceTtsProvider;

  /// No description provided for @voiceTtsProviderNative.
  ///
  /// In en, this message translates to:
  /// **'Device (Native)'**
  String get voiceTtsProviderNative;

  /// No description provided for @voiceTtsProviderNativeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Uses built-in system voices — works offline'**
  String get voiceTtsProviderNativeSubtitle;

  /// No description provided for @voiceTtsProviderKokoro.
  ///
  /// In en, this message translates to:
  /// **'Downloaded voice'**
  String get voiceTtsProviderKokoro;

  /// No description provided for @voiceTtsProviderKokoroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Natural voices that run on this device'**
  String get voiceTtsProviderKokoroSubtitle;

  /// No description provided for @voiceTtsProviderKokoroRemote.
  ///
  /// In en, this message translates to:
  /// **'Kokoro (PC)'**
  String get voiceTtsProviderKokoroRemote;

  /// No description provided for @voiceTtsProviderKokoroRemoteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Run Kokoro on your PC for faster, higher-quality speech'**
  String get voiceTtsProviderKokoroRemoteSubtitle;

  /// No description provided for @voiceTtsProviderElevenLabs.
  ///
  /// In en, this message translates to:
  /// **'ElevenLabs'**
  String get voiceTtsProviderElevenLabs;

  /// No description provided for @voiceTtsProviderElevenLabsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pro · your API key · cloud voices'**
  String get voiceTtsProviderElevenLabsSubtitle;

  /// No description provided for @voiceTtsElevenLabs.
  ///
  /// In en, this message translates to:
  /// **'ElevenLabs'**
  String get voiceTtsElevenLabs;

  /// No description provided for @voiceTtsElevenLabsHint.
  ///
  /// In en, this message translates to:
  /// **'Your key · voices from your ElevenLabs library'**
  String get voiceTtsElevenLabsHint;

  /// No description provided for @voiceElevenLabsApiKey.
  ///
  /// In en, this message translates to:
  /// **'ElevenLabs API key'**
  String get voiceElevenLabsApiKey;

  /// No description provided for @voiceElevenLabsApiKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Paste your xi-api-key from elevenlabs.io'**
  String get voiceElevenLabsApiKeyHint;

  /// No description provided for @voiceElevenLabsTestKey.
  ///
  /// In en, this message translates to:
  /// **'Check key'**
  String get voiceElevenLabsTestKey;

  /// No description provided for @voiceElevenLabsKeyInvalid.
  ///
  /// In en, this message translates to:
  /// **'That key was not accepted. Check it on elevenlabs.io.'**
  String get voiceElevenLabsKeyInvalid;

  /// No description provided for @voiceElevenLabsKeyNetwork.
  ///
  /// In en, this message translates to:
  /// **'Could not reach ElevenLabs. Check your connection.'**
  String get voiceElevenLabsKeyNetwork;

  /// No description provided for @voiceElevenLabsKeyQuota.
  ///
  /// In en, this message translates to:
  /// **'This key is out of quota.'**
  String get voiceElevenLabsKeyQuota;

  /// No description provided for @voiceElevenLabsKeyUnknown.
  ///
  /// In en, this message translates to:
  /// **'Could not verify this key. Try again.'**
  String get voiceElevenLabsKeyUnknown;

  /// No description provided for @voiceElevenLabsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Reply text is sent to ElevenLabs with your key. LM Mini stores the key on this device only.'**
  String get voiceElevenLabsPrivacy;

  /// No description provided for @voiceElevenLabsModel.
  ///
  /// In en, this message translates to:
  /// **'ElevenLabs model'**
  String get voiceElevenLabsModel;

  /// No description provided for @voiceElevenLabsVoice.
  ///
  /// In en, this message translates to:
  /// **'ElevenLabs voice'**
  String get voiceElevenLabsVoice;

  /// No description provided for @voiceElevenLabsNoVoices.
  ///
  /// In en, this message translates to:
  /// **'No voices in this account. Add voices in the ElevenLabs library first.'**
  String get voiceElevenLabsNoVoices;

  /// No description provided for @voiceElevenLabsChangeKey.
  ///
  /// In en, this message translates to:
  /// **'Change key'**
  String get voiceElevenLabsChangeKey;

  /// No description provided for @voiceElevenLabsRemoveKey.
  ///
  /// In en, this message translates to:
  /// **'Remove key'**
  String get voiceElevenLabsRemoveKey;

  /// No description provided for @voiceElevenLabsReady.
  ///
  /// In en, this message translates to:
  /// **'Connected to ElevenLabs'**
  String get voiceElevenLabsReady;

  /// No description provided for @voiceElevenLabsNoKey.
  ///
  /// In en, this message translates to:
  /// **'Add your ElevenLabs API key'**
  String get voiceElevenLabsNoKey;

  /// No description provided for @personaElevenLabsVoiceLabel.
  ///
  /// In en, this message translates to:
  /// **'ElevenLabs voice'**
  String get personaElevenLabsVoiceLabel;

  /// No description provided for @personaElevenLabsVoiceGlobal.
  ///
  /// In en, this message translates to:
  /// **'Use global ElevenLabs voice'**
  String get personaElevenLabsVoiceGlobal;

  /// No description provided for @personaElevenLabsVoicePickerTitle.
  ///
  /// In en, this message translates to:
  /// **'ElevenLabs voice'**
  String get personaElevenLabsVoicePickerTitle;

  /// No description provided for @personaElevenLabsVoiceAddKey.
  ///
  /// In en, this message translates to:
  /// **'Add an API key in Voice Settings to pick an ElevenLabs voice'**
  String get personaElevenLabsVoiceAddKey;

  /// No description provided for @premiumElevenLabsTts.
  ///
  /// In en, this message translates to:
  /// **'ElevenLabs voices'**
  String get premiumElevenLabsTts;

  /// No description provided for @premiumElevenLabsTtsTagline.
  ///
  /// In en, this message translates to:
  /// **'BYOK neural TTS'**
  String get premiumElevenLabsTtsTagline;

  /// No description provided for @premiumElevenLabsTtsDescription.
  ///
  /// In en, this message translates to:
  /// **'Bring your ElevenLabs API key and assign studio voices to personas. Voice chat, auto-read, and read-aloud use the same engine.'**
  String get premiumElevenLabsTtsDescription;

  /// No description provided for @voiceTtsProviderGrok.
  ///
  /// In en, this message translates to:
  /// **'Grok'**
  String get voiceTtsProviderGrok;

  /// No description provided for @voiceTtsProviderGrokSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pro · your xAI API key · cloud voices'**
  String get voiceTtsProviderGrokSubtitle;

  /// No description provided for @voiceTtsGrok.
  ///
  /// In en, this message translates to:
  /// **'Grok'**
  String get voiceTtsGrok;

  /// No description provided for @voiceTtsGrokHint.
  ///
  /// In en, this message translates to:
  /// **'Your key · Grok voices from xAI'**
  String get voiceTtsGrokHint;

  /// No description provided for @voiceGrokApiKey.
  ///
  /// In en, this message translates to:
  /// **'xAI API key'**
  String get voiceGrokApiKey;

  /// No description provided for @voiceGrokApiKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Paste your API key from console.x.ai'**
  String get voiceGrokApiKeyHint;

  /// No description provided for @voiceGrokTestKey.
  ///
  /// In en, this message translates to:
  /// **'Check key'**
  String get voiceGrokTestKey;

  /// No description provided for @voiceGrokKeyInvalid.
  ///
  /// In en, this message translates to:
  /// **'That key was not accepted. Check it on console.x.ai.'**
  String get voiceGrokKeyInvalid;

  /// No description provided for @voiceGrokKeyNetwork.
  ///
  /// In en, this message translates to:
  /// **'Could not reach xAI. Check your connection.'**
  String get voiceGrokKeyNetwork;

  /// No description provided for @voiceGrokKeyQuota.
  ///
  /// In en, this message translates to:
  /// **'This key is out of quota.'**
  String get voiceGrokKeyQuota;

  /// No description provided for @voiceGrokKeyUnknown.
  ///
  /// In en, this message translates to:
  /// **'Could not verify this key. Try again.'**
  String get voiceGrokKeyUnknown;

  /// No description provided for @voiceGrokPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Reply text is sent to xAI with your key. LM Mini stores the key on this device only.'**
  String get voiceGrokPrivacy;

  /// No description provided for @voiceGrokVoice.
  ///
  /// In en, this message translates to:
  /// **'Grok voice'**
  String get voiceGrokVoice;

  /// No description provided for @voiceGrokNoVoices.
  ///
  /// In en, this message translates to:
  /// **'No Grok voices available. Try again after checking your key.'**
  String get voiceGrokNoVoices;

  /// No description provided for @voiceGrokChangeKey.
  ///
  /// In en, this message translates to:
  /// **'Change key'**
  String get voiceGrokChangeKey;

  /// No description provided for @voiceGrokRemoveKey.
  ///
  /// In en, this message translates to:
  /// **'Remove key'**
  String get voiceGrokRemoveKey;

  /// No description provided for @voiceGrokReady.
  ///
  /// In en, this message translates to:
  /// **'Connected to Grok'**
  String get voiceGrokReady;

  /// No description provided for @voiceGrokNoKey.
  ///
  /// In en, this message translates to:
  /// **'Add your xAI API key'**
  String get voiceGrokNoKey;

  /// No description provided for @personaGrokVoiceLabel.
  ///
  /// In en, this message translates to:
  /// **'Grok voice'**
  String get personaGrokVoiceLabel;

  /// No description provided for @personaGrokVoiceGlobal.
  ///
  /// In en, this message translates to:
  /// **'Use global Grok voice'**
  String get personaGrokVoiceGlobal;

  /// No description provided for @personaGrokVoicePickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Grok voice'**
  String get personaGrokVoicePickerTitle;

  /// No description provided for @personaGrokVoiceAddKey.
  ///
  /// In en, this message translates to:
  /// **'Add an API key in Voice Settings to pick a Grok voice'**
  String get personaGrokVoiceAddKey;

  /// No description provided for @personaVoiceSection.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get personaVoiceSection;

  /// No description provided for @personaVoiceProviderLabel.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get personaVoiceProviderLabel;

  /// No description provided for @personaVoiceProviderKokoro.
  ///
  /// In en, this message translates to:
  /// **'Kokoro'**
  String get personaVoiceProviderKokoro;

  /// No description provided for @personaVoiceProviderGlobal.
  ///
  /// In en, this message translates to:
  /// **'Use global voice settings'**
  String get personaVoiceProviderGlobal;

  /// No description provided for @personaVoiceConfigureInSettings.
  ///
  /// In en, this message translates to:
  /// **'Configure under Settings → Voice'**
  String get personaVoiceConfigureInSettings;

  /// No description provided for @premiumGrokTts.
  ///
  /// In en, this message translates to:
  /// **'Grok voices'**
  String get premiumGrokTts;

  /// No description provided for @premiumGrokTtsTagline.
  ///
  /// In en, this message translates to:
  /// **'BYOK neural TTS'**
  String get premiumGrokTtsTagline;

  /// No description provided for @premiumGrokTtsDescription.
  ///
  /// In en, this message translates to:
  /// **'Bring your xAI API key and assign Grok voices to personas. Voice chat, auto-read, and read-aloud use the same engine.'**
  String get premiumGrokTtsDescription;

  /// No description provided for @voiceRemoteKokoroConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected to Kokoro on PC'**
  String get voiceRemoteKokoroConnected;

  /// No description provided for @voiceRemoteKokoroNotFound.
  ///
  /// In en, this message translates to:
  /// **'Kokoro TTS not found on PC'**
  String get voiceRemoteKokoroNotFound;

  /// No description provided for @voiceRemoteKokoroRequiresConnect.
  ///
  /// In en, this message translates to:
  /// **'Requires Share with phone on your Mac (or LM Mini Connect on Windows/Linux)'**
  String get voiceRemoteKokoroRequiresConnect;

  /// No description provided for @voiceKokoroVoice.
  ///
  /// In en, this message translates to:
  /// **'Kokoro Voice'**
  String get voiceKokoroVoice;

  /// No description provided for @voiceKokoroSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speech Speed'**
  String get voiceKokoroSpeed;

  /// No description provided for @voiceKokoroModelReady.
  ///
  /// In en, this message translates to:
  /// **'Kokoro model ready'**
  String get voiceKokoroModelReady;

  /// No description provided for @voiceKokoroModelReadySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Downloaded voice is ready'**
  String get voiceKokoroModelReadySubtitle;

  /// No description provided for @voiceKokoroModelNotDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Kokoro model not downloaded'**
  String get voiceKokoroModelNotDownloaded;

  /// No description provided for @voiceKokoroModelSize.
  ///
  /// In en, this message translates to:
  /// **'Download required (~400 MB shared pack)'**
  String get voiceKokoroModelSize;

  /// No description provided for @voiceKokoroDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading Kokoro model…'**
  String get voiceKokoroDownloading;

  /// No description provided for @voiceKokoroDownloadStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting download…'**
  String get voiceKokoroDownloadStarting;

  /// No description provided for @voiceKokoroDownloadButton.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get voiceKokoroDownloadButton;

  /// No description provided for @voiceKokoroDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed. Tap to retry.'**
  String get voiceKokoroDownloadFailed;

  /// No description provided for @voiceKokoroFallback.
  ///
  /// In en, this message translates to:
  /// **'Will fall back to native voice if Kokoro model is not downloaded'**
  String get voiceKokoroFallback;

  /// No description provided for @voiceKokoroDeleteModel.
  ///
  /// In en, this message translates to:
  /// **'Delete Kokoro model'**
  String get voiceKokoroDeleteModel;

  /// No description provided for @voiceKokoroDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Kokoro Model?'**
  String get voiceKokoroDeleteTitle;

  /// No description provided for @voiceKokoroDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'This will remove every downloaded TTS language pack. You can re-download them later.'**
  String get voiceKokoroDeleteMessage;

  /// No description provided for @voiceKokoroDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get voiceKokoroDeleteConfirm;

  /// No description provided for @voiceTtsLanguagePacksHint.
  ///
  /// In en, this message translates to:
  /// **'English, Spanish, French, and Chinese share one download (~400 MB). German and Russian are smaller (~34 MB each).'**
  String get voiceTtsLanguagePacksHint;

  /// No description provided for @voiceTtsLanguagePacks.
  ///
  /// In en, this message translates to:
  /// **'Voice packs'**
  String get voiceTtsLanguagePacks;

  /// No description provided for @voiceTtsLanguagePacksSubtitleNone.
  ///
  /// In en, this message translates to:
  /// **'Download a language to speak on this device'**
  String get voiceTtsLanguagePacksSubtitleNone;

  /// No description provided for @voiceTtsLanguagePacksSubtitleReady.
  ///
  /// In en, this message translates to:
  /// **'{ready} of {total} languages ready'**
  String voiceTtsLanguagePacksSubtitleReady(int ready, int total);

  /// No description provided for @voiceTtsLanguagePacksSubtitleDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading {name}…'**
  String voiceTtsLanguagePacksSubtitleDownloading(String name);

  /// No description provided for @voiceTtsSharedPackSize.
  ///
  /// In en, this message translates to:
  /// **'Shared download · ~{size} MB'**
  String voiceTtsSharedPackSize(int size);

  /// No description provided for @voiceTtsPiperPackSize.
  ///
  /// In en, this message translates to:
  /// **'Smaller download · ~{size} MB'**
  String voiceTtsPiperPackSize(int size);

  /// No description provided for @voiceTtsSharedPackDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'This removes the shared download used by English, Spanish, French, and Chinese. You can download it again later.'**
  String get voiceTtsSharedPackDeleteMessage;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get connecting;

  /// No description provided for @saveAndTestConnection.
  ///
  /// In en, this message translates to:
  /// **'Save & Test Connection'**
  String get saveAndTestConnection;

  /// No description provided for @connectedTo.
  ///
  /// In en, this message translates to:
  /// **'✅ Connected to {provider}'**
  String connectedTo(String provider);

  /// No description provided for @connectionToFailed.
  ///
  /// In en, this message translates to:
  /// **'❌ Connection to {provider} failed — check your API key'**
  String connectionToFailed(String provider);

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'❌ Error: {error}'**
  String errorGeneric(String error);

  /// No description provided for @provider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get provider;

  /// No description provided for @cloudApiKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'{provider} API Key'**
  String cloudApiKeyLabel(String provider);

  /// No description provided for @enterApiKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your API key…'**
  String get enterApiKeyHint;

  /// No description provided for @getApiKey.
  ///
  /// In en, this message translates to:
  /// **'Get {provider} API Key'**
  String getApiKey(String provider);

  /// No description provided for @baseUrl.
  ///
  /// In en, this message translates to:
  /// **'Base URL'**
  String get baseUrl;

  /// No description provided for @customBaseUrlOptional.
  ///
  /// In en, this message translates to:
  /// **'Custom Base URL (optional)'**
  String get customBaseUrlOptional;

  /// No description provided for @accountSection.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT'**
  String get accountSection;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to enable Cloud Backup'**
  String get signInSubtitle;

  /// No description provided for @cloudServicesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Cloud services unavailable'**
  String get cloudServicesUnavailable;

  /// No description provided for @signedInVia.
  ///
  /// In en, this message translates to:
  /// **'Signed in via {method}'**
  String signedInVia(String method);

  /// No description provided for @lmMiniProSection.
  ///
  /// In en, this message translates to:
  /// **'LM MINI PRO'**
  String get lmMiniProSection;

  /// No description provided for @proActive.
  ///
  /// In en, this message translates to:
  /// **'Pro Active'**
  String get proActive;

  /// No description provided for @allPremiumUnlocked.
  ///
  /// In en, this message translates to:
  /// **'All premium features unlocked'**
  String get allPremiumUnlocked;

  /// No description provided for @upgradeToPro.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro'**
  String get upgradeToPro;

  /// No description provided for @unlockPremiumFeatures.
  ///
  /// In en, this message translates to:
  /// **'Unlock all premium features below'**
  String get unlockPremiumFeatures;

  /// No description provided for @proBadge.
  ///
  /// In en, this message translates to:
  /// **'PRO'**
  String get proBadge;

  /// No description provided for @proFeatureTag.
  ///
  /// In en, this message translates to:
  /// **'Pro Feature'**
  String get proFeatureTag;

  /// No description provided for @betaBadge.
  ///
  /// In en, this message translates to:
  /// **'BETA'**
  String get betaBadge;

  /// No description provided for @imageGeneration.
  ///
  /// In en, this message translates to:
  /// **'Image Generation'**
  String get imageGeneration;

  /// No description provided for @generatedImagesLibrary.
  ///
  /// In en, this message translates to:
  /// **'Generated images'**
  String get generatedImagesLibrary;

  /// No description provided for @generatedImagesGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get generatedImagesGallery;

  /// No description provided for @generatedImagesShowInChat.
  ///
  /// In en, this message translates to:
  /// **'Show in chat'**
  String get generatedImagesShowInChat;

  /// No description provided for @generatedImagesLibrarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'View, open in chat, or delete'**
  String get generatedImagesLibrarySubtitle;

  /// No description provided for @generatedImagesLibraryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No generated images yet'**
  String get generatedImagesLibraryEmpty;

  /// No description provided for @generatedImagesLibraryEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Images you generate in chat are saved here.'**
  String get generatedImagesLibraryEmptyHint;

  /// No description provided for @generatedImagesSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get generatedImagesSelect;

  /// No description provided for @generatedImagesCancelSelect.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get generatedImagesCancelSelect;

  /// No description provided for @generatedImagesDeleteN.
  ///
  /// In en, this message translates to:
  /// **'Delete {count}'**
  String generatedImagesDeleteN(int count);

  /// No description provided for @generatedImagesDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete images?'**
  String get generatedImagesDeleteConfirmTitle;

  /// No description provided for @generatedImagesDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'{count} image(s) will be removed from this device. Chat messages stay.'**
  String generatedImagesDeleteConfirmBody(int count);

  /// No description provided for @generatedImagesOpenChat.
  ///
  /// In en, this message translates to:
  /// **'Open in chat'**
  String get generatedImagesOpenChat;

  /// No description provided for @saveToPhotos.
  ///
  /// In en, this message translates to:
  /// **'Save to Photos'**
  String get saveToPhotos;

  /// No description provided for @savedToPhotos.
  ///
  /// In en, this message translates to:
  /// **'Saved to Photos'**
  String get savedToPhotos;

  /// No description provided for @couldNotSaveToPhotos.
  ///
  /// In en, this message translates to:
  /// **'Could not save this file.'**
  String get couldNotSaveToPhotos;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @generatedImagesMissingFile.
  ///
  /// In en, this message translates to:
  /// **'File missing'**
  String get generatedImagesMissingFile;

  /// No description provided for @generatedImagesOrphan.
  ///
  /// In en, this message translates to:
  /// **'Not linked to a chat'**
  String get generatedImagesOrphan;

  /// No description provided for @generatedImagesPrompt.
  ///
  /// In en, this message translates to:
  /// **'Prompt'**
  String get generatedImagesPrompt;

  /// No description provided for @generatedImagesNegativePrompt.
  ///
  /// In en, this message translates to:
  /// **'Negative prompt'**
  String get generatedImagesNegativePrompt;

  /// No description provided for @generatedImagesDetails.
  ///
  /// In en, this message translates to:
  /// **'Generation details'**
  String get generatedImagesDetails;

  /// No description provided for @generatedImagesNoPrompt.
  ///
  /// In en, this message translates to:
  /// **'No prompt saved'**
  String get generatedImagesNoPrompt;

  /// No description provided for @generatedImagesChatUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This chat is no longer available'**
  String get generatedImagesChatUnavailable;

  /// No description provided for @generatedImagesVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get generatedImagesVideo;

  /// No description provided for @imageGenEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled — {url}'**
  String imageGenEnabled(String url);

  /// No description provided for @imageGenNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Enabled — Not configured'**
  String get imageGenNotConfigured;

  /// No description provided for @cloudBackup.
  ///
  /// In en, this message translates to:
  /// **'Cloud Backup'**
  String get cloudBackup;

  /// No description provided for @encryptedBackupRestore.
  ///
  /// In en, this message translates to:
  /// **'Encrypted backup & restore'**
  String get encryptedBackupRestore;

  /// No description provided for @e2eBanner.
  ///
  /// In en, this message translates to:
  /// **'End-to-end encrypted — your passphrase never leaves this device'**
  String get e2eBanner;

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// No description provided for @analyticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Usage stats, tokens & model insights'**
  String get analyticsSubtitle;

  /// No description provided for @memory.
  ///
  /// In en, this message translates to:
  /// **'Memories'**
  String get memory;

  /// No description provided for @memoryItemCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items • Persistent across chats'**
  String memoryItemCount(int count);

  /// No description provided for @premiumWebSearch.
  ///
  /// In en, this message translates to:
  /// **'Premium Web Search'**
  String get premiumWebSearch;

  /// No description provided for @premiumWebSearchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Instant search — no SearXNG needed'**
  String get premiumWebSearchSubtitle;

  /// No description provided for @urlReader.
  ///
  /// In en, this message translates to:
  /// **'URL Reader'**
  String get urlReader;

  /// No description provided for @urlReaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Read & summarize any webpage'**
  String get urlReaderSubtitle;

  /// No description provided for @conversationBranching.
  ///
  /// In en, this message translates to:
  /// **'Conversation Branching'**
  String get conversationBranching;

  /// No description provided for @conversationBranchingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fork conversations from any message'**
  String get conversationBranchingSubtitle;

  /// No description provided for @cloudBackupPro.
  ///
  /// In en, this message translates to:
  /// **'Cloud Backup'**
  String get cloudBackupPro;

  /// No description provided for @cloudBackupProSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Encrypted backup & restore to the cloud'**
  String get cloudBackupProSubtitle;

  /// No description provided for @analyticsDashboard.
  ///
  /// In en, this message translates to:
  /// **'Analytics Dashboard'**
  String get analyticsDashboard;

  /// No description provided for @analyticsDashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Usage stats, tokens & model insights'**
  String get analyticsDashboardSubtitle;

  /// No description provided for @cloudApiProviders.
  ///
  /// In en, this message translates to:
  /// **'Cloud API Providers'**
  String get cloudApiProviders;

  /// No description provided for @cloudApiProvidersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Mistral, DeepSeek & more'**
  String get cloudApiProvidersSubtitle;

  /// No description provided for @addProviderLabel.
  ///
  /// In en, this message translates to:
  /// **'Add Provider'**
  String get addProviderLabel;

  /// No description provided for @noCloudProvidersTitle.
  ///
  /// In en, this message translates to:
  /// **'No Cloud Providers'**
  String get noCloudProvidersTitle;

  /// No description provided for @noCloudProvidersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add a cloud API provider.\nUse your own API keys for Groq, DeepSeek, and more.'**
  String get noCloudProvidersSubtitle;

  /// No description provided for @editProviderTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Provider'**
  String get editProviderTitle;

  /// No description provided for @addCloudProviderTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Cloud Provider'**
  String get addCloudProviderTitle;

  /// No description provided for @providerLabel.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get providerLabel;

  /// No description provided for @apiKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get apiKeyLabel;

  /// No description provided for @pasteLabel.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get pasteLabel;

  /// No description provided for @baseUrlRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Base URL (required)'**
  String get baseUrlRequiredLabel;

  /// No description provided for @customBaseUrlOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom Base URL (optional)'**
  String get customBaseUrlOptionalLabel;

  /// No description provided for @advancedLabel.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advancedLabel;

  /// No description provided for @fetchingLabel.
  ///
  /// In en, this message translates to:
  /// **'Fetching...'**
  String get fetchingLabel;

  /// No description provided for @fetchAvailableModelsLabel.
  ///
  /// In en, this message translates to:
  /// **'Fetch Available Models'**
  String get fetchAvailableModelsLabel;

  /// No description provided for @availableModelsLabel.
  ///
  /// In en, this message translates to:
  /// **'Available Models:'**
  String get availableModelsLabel;

  /// No description provided for @suggestedModelsLabel.
  ///
  /// In en, this message translates to:
  /// **'Suggested Models:'**
  String get suggestedModelsLabel;

  /// No description provided for @modelIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Model ID'**
  String get modelIdLabel;

  /// No description provided for @disableCloudProviderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Disable to keep config but not use it'**
  String get disableCloudProviderSubtitle;

  /// No description provided for @setAsActiveProviderLabel.
  ///
  /// In en, this message translates to:
  /// **'Set as Active Provider'**
  String get setAsActiveProviderLabel;

  /// No description provided for @deactivateLabel.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get deactivateLabel;

  /// No description provided for @switchedBackToLocalLmStudio.
  ///
  /// In en, this message translates to:
  /// **'Switched back to local LM Studio'**
  String get switchedBackToLocalLmStudio;

  /// No description provided for @saveChangesLabel.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChangesLabel;

  /// No description provided for @enterDisplayNameError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a display name'**
  String get enterDisplayNameError;

  /// No description provided for @enterApiKeyError.
  ///
  /// In en, this message translates to:
  /// **'Please enter an API key'**
  String get enterApiKeyError;

  /// No description provided for @enterBaseUrlError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a base URL for custom provider'**
  String get enterBaseUrlError;

  /// No description provided for @enterApiKeyFirst.
  ///
  /// In en, this message translates to:
  /// **'Enter an API key first'**
  String get enterApiKeyFirst;

  /// No description provided for @failedToFetchModels.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch models: {error}'**
  String failedToFetchModels(String error);

  /// No description provided for @deleteProviderTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Provider?'**
  String get deleteProviderTitle;

  /// No description provided for @deleteProviderMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{name}\" and its API key?'**
  String deleteProviderMessage(String name);

  /// No description provided for @deleteFirstPartyOpenAiServerMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{name}\" from this device?\n\nYou can’t add this server from the list anymore. To reconnect, add A.I Compatible API and set the base URL to https://api.openai.com.'**
  String deleteFirstPartyOpenAiServerMessage(String name);

  /// No description provided for @activeProviderSet.
  ///
  /// In en, this message translates to:
  /// **'{name} set as active provider'**
  String activeProviderSet(String name);

  /// No description provided for @memoryPro.
  ///
  /// In en, this message translates to:
  /// **'Memories'**
  String get memoryPro;

  /// No description provided for @memoryProSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Persistent memories across conversations'**
  String get memoryProSubtitle;

  /// No description provided for @richExportShare.
  ///
  /// In en, this message translates to:
  /// **'Rich Export & Share'**
  String get richExportShare;

  /// No description provided for @richExportShareSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Export to Obsidian, Notes, Notion & more'**
  String get richExportShareSubtitle;

  /// No description provided for @autoUnloadAfter.
  ///
  /// In en, this message translates to:
  /// **'Auto-unload after {value}'**
  String autoUnloadAfter(String value);

  /// No description provided for @subscriptionRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get subscriptionRestore;

  /// No description provided for @subscriptionTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get subscriptionTerms;

  /// No description provided for @subscriptionPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get subscriptionPrivacy;

  /// No description provided for @secureYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Secure Your Account'**
  String get secureYourAccount;

  /// No description provided for @signInWithApple.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple'**
  String get signInWithApple;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @subscriptionSecured.
  ///
  /// In en, this message translates to:
  /// **'Your subscription is secured'**
  String get subscriptionSecured;

  /// No description provided for @packagesNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Packages not available yet.'**
  String get packagesNotAvailable;

  /// No description provided for @welcomeToPro.
  ///
  /// In en, this message translates to:
  /// **'🎉 Welcome to LM Mini Pro!'**
  String get welcomeToPro;

  /// No description provided for @subscriptionRestored.
  ///
  /// In en, this message translates to:
  /// **'✅ Subscription restored!'**
  String get subscriptionRestored;

  /// No description provided for @noActiveSubscription.
  ///
  /// In en, this message translates to:
  /// **'No active subscription found.'**
  String get noActiveSubscription;

  /// No description provided for @accountLinked.
  ///
  /// In en, this message translates to:
  /// **'✅ Account linked!'**
  String get accountLinked;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @forgotPasswordNeedEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address first, then tap Forgot password.'**
  String get forgotPasswordNeedEmail;

  /// No description provided for @forgotPasswordSent.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for that email, we sent a reset link. Check your inbox.'**
  String get forgotPasswordSent;

  /// No description provided for @forgotPasswordFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send a reset email. Please try again.'**
  String get forgotPasswordFailed;

  /// No description provided for @verificationEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent!'**
  String get verificationEmailSent;

  /// No description provided for @failedToSend.
  ///
  /// In en, this message translates to:
  /// **'Failed to send: {error}'**
  String failedToSend(String error);

  /// No description provided for @cloudBackupEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled — your account supports encrypted backups'**
  String get cloudBackupEnabled;

  /// No description provided for @endToEndEncryption.
  ///
  /// In en, this message translates to:
  /// **'End-to-End Encryption'**
  String get endToEndEncryption;

  /// No description provided for @e2eSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Backups encrypted with your passphrase — we can\'t read them'**
  String get e2eSubtitle;

  /// No description provided for @upgradeForCloudBackup.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro to enable encrypted cloud backups'**
  String get upgradeForCloudBackup;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @signOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sign Out?'**
  String get signOutConfirm;

  /// No description provided for @signedOut.
  ///
  /// In en, this message translates to:
  /// **'Signed out.'**
  String get signedOut;

  /// No description provided for @goToAccount.
  ///
  /// In en, this message translates to:
  /// **'Go to Account'**
  String get goToAccount;

  /// No description provided for @firebaseNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Firebase is not configured.'**
  String get firebaseNotConfigured;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @createBackup.
  ///
  /// In en, this message translates to:
  /// **'Create Backup'**
  String get createBackup;

  /// No description provided for @encryptBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Encrypt & back up all conversations'**
  String get encryptBackupSubtitle;

  /// No description provided for @backUpNow.
  ///
  /// In en, this message translates to:
  /// **'Back Up Now'**
  String get backUpNow;

  /// No description provided for @yourBackups.
  ///
  /// In en, this message translates to:
  /// **'YOUR BACKUPS'**
  String get yourBackups;

  /// No description provided for @e2eBackupBanner.
  ///
  /// In en, this message translates to:
  /// **'End-to-end encrypted. '**
  String get e2eBackupBanner;

  /// No description provided for @e2eBackupDetail.
  ///
  /// In en, this message translates to:
  /// **'Your backups are encrypted with your passphrase before leaving this device. We cannot read your data.'**
  String get e2eBackupDetail;

  /// No description provided for @exportingData.
  ///
  /// In en, this message translates to:
  /// **'Exporting data...'**
  String get exportingData;

  /// No description provided for @preparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing...'**
  String get preparing;

  /// No description provided for @encrypting.
  ///
  /// In en, this message translates to:
  /// **'Encrypting...'**
  String get encrypting;

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get uploading;

  /// No description provided for @savingMetadata.
  ///
  /// In en, this message translates to:
  /// **'Saving metadata...'**
  String get savingMetadata;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done!'**
  String get done;

  /// No description provided for @noBackupsYet.
  ///
  /// In en, this message translates to:
  /// **'No backups yet'**
  String get noBackupsYet;

  /// No description provided for @createFirstBackup.
  ///
  /// In en, this message translates to:
  /// **'Create your first encrypted backup above'**
  String get createFirstBackup;

  /// No description provided for @encrypted.
  ///
  /// In en, this message translates to:
  /// **'Encrypted'**
  String get encrypted;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @encryptionPassphraseLabel.
  ///
  /// In en, this message translates to:
  /// **'Encryption Passphrase'**
  String get encryptionPassphraseLabel;

  /// No description provided for @enterStrongPassphrase.
  ///
  /// In en, this message translates to:
  /// **'Enter a strong passphrase'**
  String get enterStrongPassphrase;

  /// No description provided for @confirmPassphraseLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Passphrase'**
  String get confirmPassphraseLabel;

  /// No description provided for @passphraseRememberWarning.
  ///
  /// In en, this message translates to:
  /// **'Remember this passphrase! If you lose it, your backups cannot be recovered. We do not store it anywhere.'**
  String get passphraseRememberWarning;

  /// No description provided for @passphraseRestoreHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the same passphrase you used when creating this backup.'**
  String get passphraseRestoreHint;

  /// No description provided for @minCharsRequired.
  ///
  /// In en, this message translates to:
  /// **'At least 4 characters required.'**
  String get minCharsRequired;

  /// No description provided for @passphrasesDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passphrases do not match.'**
  String get passphrasesDoNotMatch;

  /// No description provided for @encryptAndBackUp.
  ///
  /// In en, this message translates to:
  /// **'Encrypt & Back Up'**
  String get encryptAndBackUp;

  /// No description provided for @decryptAndRestore.
  ///
  /// In en, this message translates to:
  /// **'Decrypt & Restore'**
  String get decryptAndRestore;

  /// No description provided for @encryptionPassphrase.
  ///
  /// In en, this message translates to:
  /// **'Encryption Passphrase'**
  String get encryptionPassphrase;

  /// No description provided for @savedPassphrasePrompt.
  ///
  /// In en, this message translates to:
  /// **'You have a saved passphrase from a previous backup. Would you like to use the same one or set a new passphrase?'**
  String get savedPassphrasePrompt;

  /// No description provided for @newPassphrase.
  ///
  /// In en, this message translates to:
  /// **'New Passphrase'**
  String get newPassphrase;

  /// No description provided for @useSame.
  ///
  /// In en, this message translates to:
  /// **'Use Same'**
  String get useSame;

  /// No description provided for @setEncryptionPassphrase.
  ///
  /// In en, this message translates to:
  /// **'Set Encryption Passphrase'**
  String get setEncryptionPassphrase;

  /// No description provided for @choosePassphraseBackup.
  ///
  /// In en, this message translates to:
  /// **'Choose a passphrase to encrypt this backup. You\'ll need it to restore on any device.'**
  String get choosePassphraseBackup;

  /// No description provided for @choosePassphraseDetail.
  ///
  /// In en, this message translates to:
  /// **'Choose a passphrase to encrypt your backup. This passphrase stays on your device — we never see it. You\'ll need it to restore.'**
  String get choosePassphraseDetail;

  /// No description provided for @backupFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup failed: {error}'**
  String backupFailed(String error);

  /// No description provided for @restoreBackupConfirm.
  ///
  /// In en, this message translates to:
  /// **'Restore Backup?'**
  String get restoreBackupConfirm;

  /// No description provided for @restoreWarning.
  ///
  /// In en, this message translates to:
  /// **'This will REPLACE all your current conversations, messages, and folders with the data from this backup.\n\nThis cannot be undone.'**
  String get restoreWarning;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @enterPassphrase.
  ///
  /// In en, this message translates to:
  /// **'Enter Passphrase'**
  String get enterPassphrase;

  /// No description provided for @passphraseDecryptHint.
  ///
  /// In en, this message translates to:
  /// **'This backup is end-to-end encrypted. Enter the passphrase you used when creating it.'**
  String get passphraseDecryptHint;

  /// No description provided for @wrongPassphrase.
  ///
  /// In en, this message translates to:
  /// **'Wrong passphrase or corrupted backup.'**
  String get wrongPassphrase;

  /// No description provided for @restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed: {error}'**
  String restoreFailed(String error);

  /// No description provided for @deleteBackupConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete Backup?'**
  String get deleteBackupConfirm;

  /// No description provided for @deleteBackupWarning.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete this encrypted cloud backup. This cannot be undone.'**
  String get deleteBackupWarning;

  /// No description provided for @backupDeleted.
  ///
  /// In en, this message translates to:
  /// **'Backup deleted.'**
  String get backupDeleted;

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed: {error}'**
  String deleteFailed(String error);

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'OVERVIEW'**
  String get overview;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @conversations.
  ///
  /// In en, this message translates to:
  /// **'Conversations'**
  String get conversations;

  /// No description provided for @totalTokens.
  ///
  /// In en, this message translates to:
  /// **'Total Tokens'**
  String get totalTokens;

  /// No description provided for @avgResponse.
  ///
  /// In en, this message translates to:
  /// **'Avg Response'**
  String get avgResponse;

  /// No description provided for @modelUsage.
  ///
  /// In en, this message translates to:
  /// **'MODEL USAGE'**
  String get modelUsage;

  /// No description provided for @noModelUsageData.
  ///
  /// In en, this message translates to:
  /// **'No model usage data yet.\nStart chatting to see stats here.'**
  String get noModelUsageData;

  /// No description provided for @analyticsSync.
  ///
  /// In en, this message translates to:
  /// **'Analytics are synced to your account and reset if you sign out.'**
  String get analyticsSync;

  /// No description provided for @clearAllMemories.
  ///
  /// In en, this message translates to:
  /// **'Clear all memories'**
  String get clearAllMemories;

  /// No description provided for @memoryOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get memoryOn;

  /// No description provided for @memoryOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get memoryOff;

  /// No description provided for @memoryInfoText.
  ///
  /// In en, this message translates to:
  /// **'Memories are injected into the system prompt so the LLM remembers you across conversations.'**
  String get memoryInfoText;

  /// No description provided for @noMemoriesYet.
  ///
  /// In en, this message translates to:
  /// **'No memories yet'**
  String get noMemoriesYet;

  /// No description provided for @noMemoriesInCategory.
  ///
  /// In en, this message translates to:
  /// **'No {category} memories'**
  String noMemoriesInCategory(String category);

  /// No description provided for @memoryTapToAdd.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add a new memory or choose a different category.'**
  String get memoryTapToAdd;

  /// No description provided for @memoryAddHint.
  ///
  /// In en, this message translates to:
  /// **'Add facts about yourself that you want the AI to remember across all conversations.'**
  String get memoryAddHint;

  /// No description provided for @addMemory.
  ///
  /// In en, this message translates to:
  /// **'Add Memory'**
  String get addMemory;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @editMemory.
  ///
  /// In en, this message translates to:
  /// **'Edit Memory'**
  String get editMemory;

  /// No description provided for @deleteMemory.
  ///
  /// In en, this message translates to:
  /// **'Delete Memory'**
  String get deleteMemory;

  /// No description provided for @removeMemoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove this memory?\n\n\"{content}\"'**
  String removeMemoryConfirm(String content);

  /// No description provided for @clearAllMemoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear All Memories'**
  String get clearAllMemoriesTitle;

  /// No description provided for @clearAllMemoriesConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all {count} memories. This cannot be undone.'**
  String clearAllMemoriesConfirm(int count);

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get justNow;

  /// No description provided for @categoryPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get categoryPersonal;

  /// No description provided for @categoryPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get categoryPreferences;

  /// No description provided for @categoryLifestyle.
  ///
  /// In en, this message translates to:
  /// **'Lifestyle'**
  String get categoryLifestyle;

  /// No description provided for @categoryEmotional.
  ///
  /// In en, this message translates to:
  /// **'Emotional'**
  String get categoryEmotional;

  /// No description provided for @categoryTechnical.
  ///
  /// In en, this message translates to:
  /// **'Technical'**
  String get categoryTechnical;

  /// No description provided for @categoryWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get categoryWork;

  /// No description provided for @categoryGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get categoryGeneral;

  /// No description provided for @categoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get categoryAll;

  /// No description provided for @modelManagement.
  ///
  /// In en, this message translates to:
  /// **'Model Management'**
  String get modelManagement;

  /// No description provided for @downloadNewModel.
  ///
  /// In en, this message translates to:
  /// **'Download New Model'**
  String get downloadNewModel;

  /// No description provided for @refreshModels.
  ///
  /// In en, this message translates to:
  /// **'Refresh Models'**
  String get refreshModels;

  /// No description provided for @tapToSelect.
  ///
  /// In en, this message translates to:
  /// **'Tap to select'**
  String get tapToSelect;

  /// No description provided for @modelSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected: {name}'**
  String modelSelected(String name);

  /// No description provided for @unloadModelTooltip.
  ///
  /// In en, this message translates to:
  /// **'Unload Model from Memory'**
  String get unloadModelTooltip;

  /// No description provided for @modelInfoTooltip.
  ///
  /// In en, this message translates to:
  /// **'Model Info'**
  String get modelInfoTooltip;

  /// No description provided for @loadedBadge.
  ///
  /// In en, this message translates to:
  /// **'LOADED'**
  String get loadedBadge;

  /// No description provided for @visionBadge.
  ///
  /// In en, this message translates to:
  /// **'Vision'**
  String get visionBadge;

  /// No description provided for @toolsBadge.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get toolsBadge;

  /// No description provided for @selectedModel.
  ///
  /// In en, this message translates to:
  /// **'Selected Model'**
  String get selectedModel;

  /// No description provided for @unloading.
  ///
  /// In en, this message translates to:
  /// **'Unloading...'**
  String get unloading;

  /// No description provided for @unload.
  ///
  /// In en, this message translates to:
  /// **'Unload'**
  String get unload;

  /// No description provided for @loaded.
  ///
  /// In en, this message translates to:
  /// **'Loaded'**
  String get loaded;

  /// No description provided for @loadModel.
  ///
  /// In en, this message translates to:
  /// **'Load Model'**
  String get loadModel;

  /// No description provided for @enterModelIdOrUrl.
  ///
  /// In en, this message translates to:
  /// **'Enter a model ID or HuggingFace URL:'**
  String get enterModelIdOrUrl;

  /// No description provided for @modelIdHint.
  ///
  /// In en, this message translates to:
  /// **'microsoft/phi-4'**
  String get modelIdHint;

  /// No description provided for @modelIdHelper.
  ///
  /// In en, this message translates to:
  /// **'Model ID or https://huggingface.co/...'**
  String get modelIdHelper;

  /// No description provided for @huggingFaceDetected.
  ///
  /// In en, this message translates to:
  /// **'HuggingFace URL detected - you\'ll select a quantization'**
  String get huggingFaceDetected;

  /// No description provided for @starting.
  ///
  /// In en, this message translates to:
  /// **'Starting...'**
  String get starting;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @selectQuantization.
  ///
  /// In en, this message translates to:
  /// **'Select Quantization'**
  String get selectQuantization;

  /// No description provided for @loadingQuantizations.
  ///
  /// In en, this message translates to:
  /// **'Loading quantizations...'**
  String get loadingQuantizations;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @fetchQuantizationsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch quantizations: {error}'**
  String fetchQuantizationsFailed(String error);

  /// No description provided for @checkLmStudioRunning.
  ///
  /// In en, this message translates to:
  /// **'Check if LM Studio is running'**
  String get checkLmStudioRunning;

  /// No description provided for @couldNotReachLmStudio.
  ///
  /// In en, this message translates to:
  /// **'LM Mini couldn\'t reach your server.'**
  String get couldNotReachLmStudio;

  /// No description provided for @couldNotLoadQuantizations.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load quantizations.'**
  String get couldNotLoadQuantizations;

  /// No description provided for @couldNotStartDownload.
  ///
  /// In en, this message translates to:
  /// **'Could not start download.'**
  String get couldNotStartDownload;

  /// No description provided for @noQuantizations.
  ///
  /// In en, this message translates to:
  /// **'No Quantizations'**
  String get noQuantizations;

  /// No description provided for @noGgufFiles.
  ///
  /// In en, this message translates to:
  /// **'No GGUF files found in this repository'**
  String get noGgufFiles;

  /// No description provided for @foundQuantizations.
  ///
  /// In en, this message translates to:
  /// **'Found {count} GGUF quantization(s)'**
  String foundQuantizations(int count);

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'unknown'**
  String get unknown;

  /// No description provided for @downloadingModel.
  ///
  /// In en, this message translates to:
  /// **'Downloading model with {quantization} quantization...'**
  String downloadingModel(String quantization);

  /// No description provided for @modelAlreadyDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Model already downloaded'**
  String get modelAlreadyDownloaded;

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed: {error}'**
  String downloadFailed(String error);

  /// No description provided for @enterModelIdentifier.
  ///
  /// In en, this message translates to:
  /// **'Please enter a model identifier or URL'**
  String get enterModelIdentifier;

  /// No description provided for @modelAlreadyLoaded.
  ///
  /// In en, this message translates to:
  /// **'Model Already Loaded'**
  String get modelAlreadyLoaded;

  /// No description provided for @currentlyLoaded.
  ///
  /// In en, this message translates to:
  /// **'Currently loaded:'**
  String get currentlyLoaded;

  /// No description provided for @loadAlongsideWarning.
  ///
  /// In en, this message translates to:
  /// **'Loading \"{name}\" alongside existing model(s) will use additional memory.'**
  String loadAlongsideWarning(String name);

  /// No description provided for @unloadAllAndLoad.
  ///
  /// In en, this message translates to:
  /// **'Unload All & Load'**
  String get unloadAllAndLoad;

  /// No description provided for @swap.
  ///
  /// In en, this message translates to:
  /// **'Swap'**
  String get swap;

  /// No description provided for @loadAlongside.
  ///
  /// In en, this message translates to:
  /// **'Load Alongside'**
  String get loadAlongside;

  /// No description provided for @loadParamsConflictTitle.
  ///
  /// In en, this message translates to:
  /// **'Load settings differ'**
  String get loadParamsConflictTitle;

  /// No description provided for @loadParamsConflictBody.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" is already loaded in LM Studio with different settings than LM Mini\'s Model Loading Config. Reloading can take a minute and use extra memory.'**
  String loadParamsConflictBody(String name);

  /// No description provided for @loadParamsConflictTableHeader.
  ///
  /// In en, this message translates to:
  /// **'Differing parameters:'**
  String get loadParamsConflictTableHeader;

  /// No description provided for @loadParamsLmStudio.
  ///
  /// In en, this message translates to:
  /// **'LM Studio'**
  String get loadParamsLmStudio;

  /// No description provided for @loadParamsLmMini.
  ///
  /// In en, this message translates to:
  /// **'LM Mini'**
  String get loadParamsLmMini;

  /// No description provided for @loadParamsConflictHint.
  ///
  /// In en, this message translates to:
  /// **'Using LM Studio\'s loaded settings avoids a reload. Unload & reload applies your LM Mini settings. Load alongside keeps both instances in memory.'**
  String get loadParamsConflictHint;

  /// No description provided for @loadParamsUseExisting.
  ///
  /// In en, this message translates to:
  /// **'Use LM Studio settings'**
  String get loadParamsUseExisting;

  /// No description provided for @loadParamsReloadWithMini.
  ///
  /// In en, this message translates to:
  /// **'Unload & load with LM Mini settings'**
  String get loadParamsReloadWithMini;

  /// No description provided for @loadParamsLoadParallel.
  ///
  /// In en, this message translates to:
  /// **'Load with LM Mini settings (parallel)'**
  String get loadParamsLoadParallel;

  /// No description provided for @reloadModelForContextTitle.
  ///
  /// In en, this message translates to:
  /// **'Reload model?'**
  String get reloadModelForContextTitle;

  /// No description provided for @reloadModelForContextBody.
  ///
  /// In en, this message translates to:
  /// **'Context length is applied when the model loads. \"{name}\" is loaded at {loaded}. Reload it with {desired}?'**
  String reloadModelForContextBody(String name, String loaded, String desired);

  /// No description provided for @reloadModelForContextNow.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get reloadModelForContextNow;

  /// No description provided for @reloadModelForContextLater.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get reloadModelForContextLater;

  /// No description provided for @loadModelConfirm.
  ///
  /// In en, this message translates to:
  /// **'Load \"{name}\" into memory?'**
  String loadModelConfirm(String name);

  /// No description provided for @unloadModelTip.
  ///
  /// In en, this message translates to:
  /// **'You can unload models using the eject button or from this screen after loading.'**
  String get unloadModelTip;

  /// No description provided for @modelLoadedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Model loaded successfully'**
  String get modelLoadedSuccess;

  /// No description provided for @failedToLoadModel.
  ///
  /// In en, this message translates to:
  /// **'Failed to load model'**
  String get failedToLoadModel;

  /// No description provided for @modelInfo.
  ///
  /// In en, this message translates to:
  /// **'Model Info'**
  String get modelInfo;

  /// No description provided for @infoName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get infoName;

  /// No description provided for @infoType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get infoType;

  /// No description provided for @infoArchitecture.
  ///
  /// In en, this message translates to:
  /// **'Architecture'**
  String get infoArchitecture;

  /// No description provided for @infoPublisher.
  ///
  /// In en, this message translates to:
  /// **'Publisher'**
  String get infoPublisher;

  /// No description provided for @infoQuantization.
  ///
  /// In en, this message translates to:
  /// **'Quantization'**
  String get infoQuantization;

  /// No description provided for @infoParameters.
  ///
  /// In en, this message translates to:
  /// **'Parameters'**
  String get infoParameters;

  /// No description provided for @infoSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get infoSize;

  /// No description provided for @infoMaxContext.
  ///
  /// In en, this message translates to:
  /// **'Max Context'**
  String get infoMaxContext;

  /// No description provided for @infoLoadedContext.
  ///
  /// In en, this message translates to:
  /// **'Loaded Context'**
  String get infoLoadedContext;

  /// No description provided for @infoStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get infoStatus;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @capabilities.
  ///
  /// In en, this message translates to:
  /// **'Capabilities'**
  String get capabilities;

  /// No description provided for @standardTextGeneration.
  ///
  /// In en, this message translates to:
  /// **'Standard text generation'**
  String get standardTextGeneration;

  /// No description provided for @unloadModelTitle.
  ///
  /// In en, this message translates to:
  /// **'Unload Model'**
  String get unloadModelTitle;

  /// No description provided for @unloadModelConfirm.
  ///
  /// In en, this message translates to:
  /// **'Unload \"{name}\" from memory?'**
  String unloadModelConfirm(String name);

  /// No description provided for @freeResourcesTip.
  ///
  /// In en, this message translates to:
  /// **'This will free up GPU/RAM resources.'**
  String get freeResourcesTip;

  /// No description provided for @modelUnloadedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Model unloaded successfully'**
  String get modelUnloadedSuccess;

  /// No description provided for @failedToUnloadModel.
  ///
  /// In en, this message translates to:
  /// **'Failed to unload model'**
  String get failedToUnloadModel;

  /// No description provided for @enableImageGeneration.
  ///
  /// In en, this message translates to:
  /// **'Enable Image Generation'**
  String get enableImageGeneration;

  /// No description provided for @showImageButtons.
  ///
  /// In en, this message translates to:
  /// **'Show image buttons on chat messages'**
  String get showImageButtons;

  /// No description provided for @serverConnection.
  ///
  /// In en, this message translates to:
  /// **'Server Connection'**
  String get serverConnection;

  /// No description provided for @serverUrl.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get serverUrl;

  /// No description provided for @test.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get test;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @model.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get model;

  /// No description provided for @checkpoint.
  ///
  /// In en, this message translates to:
  /// **'Checkpoint'**
  String get checkpoint;

  /// No description provided for @generationParameters.
  ///
  /// In en, this message translates to:
  /// **'Generation Parameters'**
  String get generationParameters;

  /// No description provided for @negativePrompt.
  ///
  /// In en, this message translates to:
  /// **'Negative Prompt'**
  String get negativePrompt;

  /// No description provided for @steps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get steps;

  /// No description provided for @cfgScale.
  ///
  /// In en, this message translates to:
  /// **'CFG Scale'**
  String get cfgScale;

  /// No description provided for @width.
  ///
  /// In en, this message translates to:
  /// **'Width'**
  String get width;

  /// No description provided for @height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get height;

  /// No description provided for @sampler.
  ///
  /// In en, this message translates to:
  /// **'Sampler'**
  String get sampler;

  /// No description provided for @scheduler.
  ///
  /// In en, this message translates to:
  /// **'Scheduler'**
  String get scheduler;

  /// No description provided for @automatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get automatic;

  /// No description provided for @seedLabel.
  ///
  /// In en, this message translates to:
  /// **'Seed (-1 = random)'**
  String get seedLabel;

  /// No description provided for @batchSize.
  ///
  /// In en, this message translates to:
  /// **'Batch Size'**
  String get batchSize;

  /// No description provided for @options.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get options;

  /// No description provided for @restoreFaces.
  ///
  /// In en, this message translates to:
  /// **'Restore Faces'**
  String get restoreFaces;

  /// No description provided for @restoreFacesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fix faces in generated images'**
  String get restoreFacesSubtitle;

  /// No description provided for @tiling.
  ///
  /// In en, this message translates to:
  /// **'Tiling'**
  String get tiling;

  /// No description provided for @tilingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Generate seamless tileable textures'**
  String get tilingSubtitle;

  /// No description provided for @promptOptions.
  ///
  /// In en, this message translates to:
  /// **'Prompt Options'**
  String get promptOptions;

  /// No description provided for @reviewPromptBeforeSending.
  ///
  /// In en, this message translates to:
  /// **'Review Prompt Before Sending'**
  String get reviewPromptBeforeSending;

  /// No description provided for @reviewPromptSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Edit the image prompt before generating'**
  String get reviewPromptSubtitle;

  /// No description provided for @autoGenerateImage.
  ///
  /// In en, this message translates to:
  /// **'Auto-Generate Image'**
  String get autoGenerateImage;

  /// No description provided for @autoGenerateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatically generate image when AI provides a prompt'**
  String get autoGenerateSubtitle;

  /// No description provided for @resetToDefaults.
  ///
  /// In en, this message translates to:
  /// **'Reset to Defaults'**
  String get resetToDefaults;

  /// No description provided for @featureRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Feature Requests'**
  String get featureRequestsTitle;

  /// No description provided for @featureRequestsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Feature Requests Unavailable'**
  String get featureRequestsUnavailable;

  /// No description provided for @featureRequestsUnavailableDetail.
  ///
  /// In en, this message translates to:
  /// **'This feature requires an internet connection. Please check your connection and try again later.'**
  String get featureRequestsUnavailableDetail;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @votesLeft.
  ///
  /// In en, this message translates to:
  /// **'left'**
  String get votesLeft;

  /// No description provided for @popular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get popular;

  /// No description provided for @myRequests.
  ///
  /// In en, this message translates to:
  /// **'My Requests'**
  String get myRequests;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @submitIdea.
  ///
  /// In en, this message translates to:
  /// **'Submit Idea'**
  String get submitIdea;

  /// No description provided for @noFeatureRequests.
  ///
  /// In en, this message translates to:
  /// **'No feature requests yet'**
  String get noFeatureRequests;

  /// No description provided for @beFirstToSubmit.
  ///
  /// In en, this message translates to:
  /// **'Be the first to submit an idea!'**
  String get beFirstToSubmit;

  /// No description provided for @noRequestsSubmitted.
  ///
  /// In en, this message translates to:
  /// **'No requests submitted'**
  String get noRequestsSubmitted;

  /// No description provided for @tapToSubmitFirst.
  ///
  /// In en, this message translates to:
  /// **'Tap the button below to submit your first idea!'**
  String get tapToSubmitFirst;

  /// No description provided for @noCompletedRequests.
  ///
  /// In en, this message translates to:
  /// **'No completed requests'**
  String get noCompletedRequests;

  /// No description provided for @completedRequestsAppear.
  ///
  /// In en, this message translates to:
  /// **'Completed and declined requests will appear here.'**
  String get completedRequestsAppear;

  /// No description provided for @adminReplied.
  ///
  /// In en, this message translates to:
  /// **'Admin replied'**
  String get adminReplied;

  /// No description provided for @submitFeatureRequest.
  ///
  /// In en, this message translates to:
  /// **'Submit Feature Request'**
  String get submitFeatureRequest;

  /// No description provided for @titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title *'**
  String get titleRequired;

  /// No description provided for @titleHint.
  ///
  /// In en, this message translates to:
  /// **'Brief summary of your idea'**
  String get titleHint;

  /// No description provided for @descriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Description *'**
  String get descriptionRequired;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe your feature request in detail'**
  String get descriptionHint;

  /// No description provided for @yourNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Your name (optional)'**
  String get yourNameOptional;

  /// No description provided for @leaveBlankAnonymous.
  ///
  /// In en, this message translates to:
  /// **'Leave blank to submit anonymously'**
  String get leaveBlankAnonymous;

  /// No description provided for @fillTitleAndDescription.
  ///
  /// In en, this message translates to:
  /// **'Please fill in title and description'**
  String get fillTitleAndDescription;

  /// No description provided for @featureRequestSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Feature request submitted!'**
  String get featureRequestSubmitted;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @featureRequest.
  ///
  /// In en, this message translates to:
  /// **'Feature Request'**
  String get featureRequest;

  /// No description provided for @votedTooltip.
  ///
  /// In en, this message translates to:
  /// **'Voted'**
  String get votedTooltip;

  /// No description provided for @voteForThis.
  ///
  /// In en, this message translates to:
  /// **'Vote for this'**
  String get voteForThis;

  /// No description provided for @adminControls.
  ///
  /// In en, this message translates to:
  /// **'Admin Controls'**
  String get adminControls;

  /// No description provided for @changeStatus.
  ///
  /// In en, this message translates to:
  /// **'Change Status'**
  String get changeStatus;

  /// No description provided for @officialReply.
  ///
  /// In en, this message translates to:
  /// **'Official Reply'**
  String get officialReply;

  /// No description provided for @deleteRequest.
  ///
  /// In en, this message translates to:
  /// **'Delete Request'**
  String get deleteRequest;

  /// No description provided for @unableToLoadComments.
  ///
  /// In en, this message translates to:
  /// **'Unable to load comments'**
  String get unableToLoadComments;

  /// No description provided for @commentsCount.
  ///
  /// In en, this message translates to:
  /// **'Comments ({count})'**
  String commentsCount(int count);

  /// No description provided for @readMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get readMore;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get showLess;

  /// No description provided for @deleteYourRequest.
  ///
  /// In en, this message translates to:
  /// **'Delete your request'**
  String get deleteYourRequest;

  /// No description provided for @anonymous.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get anonymous;

  /// No description provided for @officialResponse.
  ///
  /// In en, this message translates to:
  /// **'Official Response'**
  String get officialResponse;

  /// No description provided for @noCommentsYet.
  ///
  /// In en, this message translates to:
  /// **'No comments yet'**
  String get noCommentsYet;

  /// No description provided for @beFirstToComment.
  ///
  /// In en, this message translates to:
  /// **'Be the first to share your thoughts!'**
  String get beFirstToComment;

  /// No description provided for @adminBadge.
  ///
  /// In en, this message translates to:
  /// **'ADMIN'**
  String get adminBadge;

  /// No description provided for @moderatorBadge.
  ///
  /// In en, this message translates to:
  /// **'MOD'**
  String get moderatorBadge;

  /// No description provided for @experiencedUserBadge.
  ///
  /// In en, this message translates to:
  /// **'EXP'**
  String get experiencedUserBadge;

  /// No description provided for @adminManageSubmitter.
  ///
  /// In en, this message translates to:
  /// **'Manage submitter'**
  String get adminManageSubmitter;

  /// No description provided for @adminManageUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage user'**
  String get adminManageUserTitle;

  /// No description provided for @adminUserUpdated.
  ///
  /// In en, this message translates to:
  /// **'User updated'**
  String get adminUserUpdated;

  /// No description provided for @adminCommunityRoles.
  ///
  /// In en, this message translates to:
  /// **'Community roles'**
  String get adminCommunityRoles;

  /// No description provided for @adminModeratorRole.
  ///
  /// In en, this message translates to:
  /// **'Moderator'**
  String get adminModeratorRole;

  /// No description provided for @adminModeratorRoleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Can bypass comment spam limits and shows a Mod badge'**
  String get adminModeratorRoleSubtitle;

  /// No description provided for @adminExperiencedUserRole.
  ///
  /// In en, this message translates to:
  /// **'Experienced user'**
  String get adminExperiencedUserRole;

  /// No description provided for @adminExperiencedUserRoleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Shows an Experienced badge on feature request comments'**
  String get adminExperiencedUserRoleSubtitle;

  /// No description provided for @adminGrantPremiumTitle.
  ///
  /// In en, this message translates to:
  /// **'Grant complimentary Pro'**
  String get adminGrantPremiumTitle;

  /// No description provided for @adminGrantPremiumSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Give this user free LM Mini Pro for a limited time'**
  String get adminGrantPremiumSubtitle;

  /// No description provided for @adminGrantPremiumAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get adminGrantPremiumAmountLabel;

  /// No description provided for @adminGrantPremiumAmountHint.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get adminGrantPremiumAmountHint;

  /// No description provided for @adminGrantPremiumUnitDays.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get adminGrantPremiumUnitDays;

  /// No description provided for @adminGrantPremiumUnitWeeks.
  ///
  /// In en, this message translates to:
  /// **'Weeks'**
  String get adminGrantPremiumUnitWeeks;

  /// No description provided for @adminGrantPremiumUnitMonths.
  ///
  /// In en, this message translates to:
  /// **'Months'**
  String get adminGrantPremiumUnitMonths;

  /// No description provided for @adminGrantPremiumGrantButton.
  ///
  /// In en, this message translates to:
  /// **'Grant Pro'**
  String get adminGrantPremiumGrantButton;

  /// No description provided for @adminGrantPremiumInvalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a positive number'**
  String get adminGrantPremiumInvalidAmount;

  /// No description provided for @adminGrantPremiumReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get adminGrantPremiumReasonLabel;

  /// No description provided for @adminGrantPremiumReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Optional — shown to the user (e.g. Sorry for the trouble)'**
  String get adminGrantPremiumReasonHint;

  /// No description provided for @adminGrantPremiumDurationDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String adminGrantPremiumDurationDays(int count);

  /// No description provided for @adminGrantPremiumDurationWeeks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 week} other{{count} weeks}}'**
  String adminGrantPremiumDurationWeeks(int count);

  /// No description provided for @adminGrantPremiumDurationMonths.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 month} other{{count} months}}'**
  String adminGrantPremiumDurationMonths(int count);

  /// No description provided for @adminRevokePremiumTitle.
  ///
  /// In en, this message translates to:
  /// **'Revoke complimentary Pro'**
  String get adminRevokePremiumTitle;

  /// No description provided for @adminRevokePremiumMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove the active admin-granted Pro access for this user?'**
  String get adminRevokePremiumMessage;

  /// No description provided for @adminRevokePremiumConfirm.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get adminRevokePremiumConfirm;

  /// No description provided for @premiumGrantBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'You received complimentary Pro'**
  String get premiumGrantBannerTitle;

  /// No description provided for @premiumGrantBannerBody.
  ///
  /// In en, this message translates to:
  /// **'Free LM Mini Pro for {duration}. Enjoy premium features while it lasts.'**
  String premiumGrantBannerBody(String duration);

  /// No description provided for @premiumGrantBannerReason.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String premiumGrantBannerReason(String reason);

  /// No description provided for @premiumGrantDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Complimentary Pro unlocked'**
  String get premiumGrantDialogTitle;

  /// No description provided for @premiumGrantDialogBody.
  ///
  /// In en, this message translates to:
  /// **'An admin granted you free LM Mini Pro for {duration}. Cloud backup, memory, analytics, and more are now available.'**
  String premiumGrantDialogBody(String duration);

  /// No description provided for @premiumGrantDialogReason.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String premiumGrantDialogReason(String reason);

  /// No description provided for @premiumGrantDialogButton.
  ///
  /// In en, this message translates to:
  /// **'Awesome'**
  String get premiumGrantDialogButton;

  /// No description provided for @youBadge.
  ///
  /// In en, this message translates to:
  /// **'YOU'**
  String get youBadge;

  /// No description provided for @deleteComment.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this comment?'**
  String get deleteComment;

  /// No description provided for @maxCommentsReached.
  ///
  /// In en, this message translates to:
  /// **'You\'ve posted {max} comments in a row. Wait for another user to reply.'**
  String maxCommentsReached(int max);

  /// No description provided for @addYourName.
  ///
  /// In en, this message translates to:
  /// **'Add your name'**
  String get addYourName;

  /// No description provided for @replyAsAdmin.
  ///
  /// In en, this message translates to:
  /// **'Reply as Admin...'**
  String get replyAsAdmin;

  /// No description provided for @writeComment.
  ///
  /// In en, this message translates to:
  /// **'Write a comment...'**
  String get writeComment;

  /// No description provided for @errorTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Error: please try again.'**
  String get errorTryAgain;

  /// No description provided for @statusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Status updated to {status}'**
  String statusUpdated(String status);

  /// No description provided for @addOfficialResponse.
  ///
  /// In en, this message translates to:
  /// **'Add an official response...'**
  String get addOfficialResponse;

  /// No description provided for @replySaved.
  ///
  /// In en, this message translates to:
  /// **'Reply saved'**
  String get replySaved;

  /// No description provided for @deleteRequestConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this feature request? This cannot be undone.'**
  String get deleteRequestConfirm;

  /// No description provided for @requestDeleted.
  ///
  /// In en, this message translates to:
  /// **'Request deleted'**
  String get requestDeleted;

  /// No description provided for @deleteCommentTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Comment'**
  String get deleteCommentTitle;

  /// No description provided for @deleteCommentConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this comment?'**
  String get deleteCommentConfirm;

  /// No description provided for @commentDeleted.
  ///
  /// In en, this message translates to:
  /// **'Comment deleted'**
  String get commentDeleted;

  /// No description provided for @generationParametersSection.
  ///
  /// In en, this message translates to:
  /// **'GENERATION PARAMETERS'**
  String get generationParametersSection;

  /// No description provided for @temperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperature;

  /// No description provided for @temperatureSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How creative vs focused replies are. Lower = more careful; higher = more varied.'**
  String get temperatureSubtitle;

  /// No description provided for @topP.
  ///
  /// In en, this message translates to:
  /// **'Top P'**
  String get topP;

  /// No description provided for @topPSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How wide a range of word choices to allow. Lower = more focused replies.'**
  String get topPSubtitle;

  /// No description provided for @minP.
  ///
  /// In en, this message translates to:
  /// **'Min P'**
  String get minP;

  /// No description provided for @minPSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ignores very unlikely word choices. Higher = safer, more predictable text.'**
  String get minPSubtitle;

  /// No description provided for @repeatPenalty.
  ///
  /// In en, this message translates to:
  /// **'Repeat Penalty'**
  String get repeatPenalty;

  /// No description provided for @repeatPenaltySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Discourages the AI from repeating the same phrases. 1.0 = off.'**
  String get repeatPenaltySubtitle;

  /// No description provided for @frequencyPenalty.
  ///
  /// In en, this message translates to:
  /// **'Frequency Penalty'**
  String get frequencyPenalty;

  /// No description provided for @frequencyPenaltySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Cuts down on words the AI uses too often.'**
  String get frequencyPenaltySubtitle;

  /// No description provided for @presencePenalty.
  ///
  /// In en, this message translates to:
  /// **'Presence Penalty'**
  String get presencePenalty;

  /// No description provided for @presencePenaltySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pushes the AI to bring up new topics instead of reusing old ones.'**
  String get presencePenaltySubtitle;

  /// No description provided for @tokenLimits.
  ///
  /// In en, this message translates to:
  /// **'TOKEN LIMITS'**
  String get tokenLimits;

  /// No description provided for @maxOutputTokens.
  ///
  /// In en, this message translates to:
  /// **'Max Output Tokens'**
  String get maxOutputTokens;

  /// No description provided for @maxOutputTokensSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How long a single reply can be. Higher = longer answers (and more wait).'**
  String get maxOutputTokensSubtitle;

  /// No description provided for @contextWindow.
  ///
  /// In en, this message translates to:
  /// **'Context Window'**
  String get contextWindow;

  /// No description provided for @contextWindowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How much of the chat the AI can remember at once. Higher uses more memory.'**
  String get contextWindowSubtitle;

  /// No description provided for @modelLoadingConfig.
  ///
  /// In en, this message translates to:
  /// **'MODEL LOADING CONFIG'**
  String get modelLoadingConfig;

  /// No description provided for @loadContextLength.
  ///
  /// In en, this message translates to:
  /// **'Context Length'**
  String get loadContextLength;

  /// No description provided for @loadContextSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How much context the model can use for chat and when loaded in LM Studio. Higher uses more memory / VRAM.'**
  String get loadContextSubtitle;

  /// No description provided for @contextFitTitle.
  ///
  /// In en, this message translates to:
  /// **'When context is full'**
  String get contextFitTitle;

  /// No description provided for @contextFitSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep chatting by fitting history into 90% of the loaded context. Compact writes a summary you can reuse if the server session is lost.'**
  String get contextFitSubtitle;

  /// No description provided for @contextFitOff.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get contextFitOff;

  /// No description provided for @contextFitRoll.
  ///
  /// In en, this message translates to:
  /// **'Roll'**
  String get contextFitRoll;

  /// No description provided for @contextFitCutMiddle.
  ///
  /// In en, this message translates to:
  /// **'Cut middle'**
  String get contextFitCutMiddle;

  /// No description provided for @contextFitOffHelp.
  ///
  /// In en, this message translates to:
  /// **'Show an error when the prompt is larger than the model context.'**
  String get contextFitOffHelp;

  /// No description provided for @contextFitRollHelp.
  ///
  /// In en, this message translates to:
  /// **'Drop the oldest messages and keep the recent ones.'**
  String get contextFitRollHelp;

  /// No description provided for @contextFitCutMiddleHelp.
  ///
  /// In en, this message translates to:
  /// **'Keep the start of the chat and the latest turns; drop the middle.'**
  String get contextFitCutMiddleHelp;

  /// No description provided for @compactChat.
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get compactChat;

  /// No description provided for @compactingChat.
  ///
  /// In en, this message translates to:
  /// **'Compacting…'**
  String get compactingChat;

  /// No description provided for @compactChatHint.
  ///
  /// In en, this message translates to:
  /// **'Summarize older messages so you can keep chatting in this context window.'**
  String get compactChatHint;

  /// No description provided for @compactChatDone.
  ///
  /// In en, this message translates to:
  /// **'Chat compacted. The next send uses the summary plus new messages.'**
  String get compactChatDone;

  /// No description provided for @compactChatFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t compact this chat. Try again.'**
  String get compactChatFailed;

  /// No description provided for @compactChatNeedModel.
  ///
  /// In en, this message translates to:
  /// **'Select a model before compacting.'**
  String get compactChatNeedModel;

  /// No description provided for @evalBatchSize.
  ///
  /// In en, this message translates to:
  /// **'Eval Batch Size'**
  String get evalBatchSize;

  /// No description provided for @evalBatchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How much text is processed at a time while loading. Higher can be faster but uses more memory.'**
  String get evalBatchSubtitle;

  /// No description provided for @numExperts.
  ///
  /// In en, this message translates to:
  /// **'Num Experts'**
  String get numExperts;

  /// No description provided for @numExpertsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only for “mixture of experts” models. Leave blank unless you know you need it.'**
  String get numExpertsSubtitle;

  /// No description provided for @flashAttention.
  ///
  /// In en, this message translates to:
  /// **'Flash Attention'**
  String get flashAttention;

  /// No description provided for @flashAttentionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Speeds up the model and can use less memory. Keep on unless something breaks.'**
  String get flashAttentionSubtitle;

  /// No description provided for @offloadKvCache.
  ///
  /// In en, this message translates to:
  /// **'Offload KV Cache to GPU'**
  String get offloadKvCache;

  /// No description provided for @offloadKvCacheSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Uses the GPU to remember the chat more efficiently. Keep on if you have a GPU.'**
  String get offloadKvCacheSubtitle;

  /// No description provided for @resizeImageForPhysicalBatch.
  ///
  /// In en, this message translates to:
  /// **'Resize images for physical batch'**
  String get resizeImageForPhysicalBatch;

  /// No description provided for @resizeImageForPhysicalBatchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Shrink a photo when it would use more tokens than the local server\'s physical batch, so the model doesn\'t crash.'**
  String get resizeImageForPhysicalBatchSubtitle;

  /// No description provided for @resizeImageForPhysicalBatchHelp.
  ///
  /// In en, this message translates to:
  /// **'LM Studio, Ollama, Jan, Unsloth, oMLX, and on-device models keep a physical batch of 512 tokens. A full-size photo can take 560 or more vision tokens. The server then aborts and the model unloads. When this is on, Mini measures the photo and shrinks it so it stays under that batch. Turn it off to send the original image.'**
  String get resizeImageForPhysicalBatchHelp;

  /// No description provided for @chainOfThoughtSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show the AI’s step-by-step thinking when available.'**
  String get chainOfThoughtSubtitle;

  /// No description provided for @reasoningUnsupportedToast.
  ///
  /// In en, this message translates to:
  /// **'This model does not support Reasoning in LM Studio. Reasoning has been disabled.'**
  String get reasoningUnsupportedToast;

  /// No description provided for @reasoningNotExposedChatHint.
  ///
  /// In en, this message translates to:
  /// **'LM Studio doesn\'t support turning off reasoning for this model. Try a different model.'**
  String get reasoningNotExposedChatHint;

  /// No description provided for @premiumSearchActive.
  ///
  /// In en, this message translates to:
  /// **'Premium Search active'**
  String get premiumSearchActive;

  /// No description provided for @premiumSearchPlusSearxng.
  ///
  /// In en, this message translates to:
  /// **' + SearXNG'**
  String get premiumSearchPlusSearxng;

  /// No description provided for @webSearchDisabledAll.
  ///
  /// In en, this message translates to:
  /// **'Web search disabled for all chats'**
  String get webSearchDisabledAll;

  /// No description provided for @configureSearch.
  ///
  /// In en, this message translates to:
  /// **'Configure Search'**
  String get configureSearch;

  /// No description provided for @advancedFeaturesSection.
  ///
  /// In en, this message translates to:
  /// **'ADVANCED FEATURES'**
  String get advancedFeaturesSection;

  /// No description provided for @howToolCallingWorks.
  ///
  /// In en, this message translates to:
  /// **'How Tool Calling Works'**
  String get howToolCallingWorks;

  /// No description provided for @stepAskQuestion.
  ///
  /// In en, this message translates to:
  /// **'You ask a question'**
  String get stepAskQuestion;

  /// No description provided for @stepAskExample.
  ///
  /// In en, this message translates to:
  /// **'e.g., \"What\'s the weather in Tokyo?\"'**
  String get stepAskExample;

  /// No description provided for @stepAiRequestsTool.
  ///
  /// In en, this message translates to:
  /// **'AI requests a tool'**
  String get stepAiRequestsTool;

  /// No description provided for @stepAiRequestsExample.
  ///
  /// In en, this message translates to:
  /// **'Model decides it needs web search'**
  String get stepAiRequestsExample;

  /// No description provided for @stepAppExecutes.
  ///
  /// In en, this message translates to:
  /// **'App executes the tool'**
  String get stepAppExecutes;

  /// No description provided for @stepAppExecutesExample.
  ///
  /// In en, this message translates to:
  /// **'Searches using Premium Search or SearXNG'**
  String get stepAppExecutesExample;

  /// No description provided for @stepResultsSent.
  ///
  /// In en, this message translates to:
  /// **'Results sent to AI'**
  String get stepResultsSent;

  /// No description provided for @stepResultsExample.
  ///
  /// In en, this message translates to:
  /// **'Search results added to conversation'**
  String get stepResultsExample;

  /// No description provided for @stepAiAnswers.
  ///
  /// In en, this message translates to:
  /// **'AI generates answer'**
  String get stepAiAnswers;

  /// No description provided for @stepAiAnswersExample.
  ///
  /// In en, this message translates to:
  /// **'Model synthesizes a helpful response'**
  String get stepAiAnswersExample;

  /// No description provided for @toolCallingModelNote.
  ///
  /// In en, this message translates to:
  /// **'like Qwen, Llama 3.1+, or Mistral.'**
  String get toolCallingModelNote;

  /// No description provided for @searxngSetup.
  ///
  /// In en, this message translates to:
  /// **'SearXNG Setup'**
  String get searxngSetup;

  /// No description provided for @searxngDescription.
  ///
  /// In en, this message translates to:
  /// **'SearXNG is a free, privacy-respecting metasearch engine that you can self-host.'**
  String get searxngDescription;

  /// No description provided for @dockerRecommended.
  ///
  /// In en, this message translates to:
  /// **'Option 1: Docker (Recommended)'**
  String get dockerRecommended;

  /// No description provided for @publicInstance.
  ///
  /// In en, this message translates to:
  /// **'Option 2: Use a Public Instance'**
  String get publicInstance;

  /// No description provided for @findPublicInstances.
  ///
  /// In en, this message translates to:
  /// **'Find public instances at:'**
  String get findPublicInstances;

  /// No description provided for @selfHostRecommended.
  ///
  /// In en, this message translates to:
  /// **'Self-hosting is recommended for reliability.'**
  String get selfHostRecommended;

  /// No description provided for @clipboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'Clipboard is empty. Copy your mcp.json content first.'**
  String get clipboardEmpty;

  /// No description provided for @clipboardAccessFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not access clipboard. Please paste manually into the field below.'**
  String get clipboardAccessFailed;

  /// No description provided for @pasteFromClipboard.
  ///
  /// In en, this message translates to:
  /// **'Paste from Clipboard'**
  String get pasteFromClipboard;

  /// No description provided for @httpServersImportNote.
  ///
  /// In en, this message translates to:
  /// **'HTTP servers → Ephemeral MCPs (sent to LM Studio per request)'**
  String get httpServersImportNote;

  /// No description provided for @localMcpsImportNote.
  ///
  /// In en, this message translates to:
  /// **'Local MCPs → Integrated MCPs (uses \"mcp/name\" format)'**
  String get localMcpsImportNote;

  /// No description provided for @noValidMcpServers.
  ///
  /// In en, this message translates to:
  /// **'No valid MCP servers found'**
  String get noValidMcpServers;

  /// No description provided for @serverAlreadyAdded.
  ///
  /// In en, this message translates to:
  /// **'This server is already added'**
  String get serverAlreadyAdded;

  /// No description provided for @themeSection.
  ///
  /// In en, this message translates to:
  /// **'THEME'**
  String get themeSection;

  /// No description provided for @themeLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeLabel;

  /// No description provided for @glassEffectsLabel.
  ///
  /// In en, this message translates to:
  /// **'Glass effects'**
  String get glassEffectsLabel;

  /// No description provided for @glassEffectsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Frosted blur on headers and menus. Turn off to run cooler and use less battery.'**
  String get glassEffectsSubtitle;

  /// No description provided for @lowBatteryModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Low battery mode'**
  String get lowBatteryModeLabel;

  /// No description provided for @lowBatteryModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Turns off glass, shows plain text while the reply streams, and syncs Home/iCloud only after the message finishes. The screen stays awake until the reply is done so the stream is not cut off.'**
  String get lowBatteryModeSubtitle;

  /// No description provided for @backgroundSection.
  ///
  /// In en, this message translates to:
  /// **'BACKGROUND'**
  String get backgroundSection;

  /// No description provided for @chatBackground.
  ///
  /// In en, this message translates to:
  /// **'Wallpaper'**
  String get chatBackground;

  /// No description provided for @chatBackgroundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Photo behind every chat'**
  String get chatBackgroundSubtitle;

  /// No description provided for @avatarsSection.
  ///
  /// In en, this message translates to:
  /// **'PICTURES'**
  String get avatarsSection;

  /// No description provided for @chatHeaderAvatarLabel.
  ///
  /// In en, this message translates to:
  /// **'Face at the top'**
  String get chatHeaderAvatarLabel;

  /// No description provided for @chatHeaderAvatarSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show a small picture in the chat header'**
  String get chatHeaderAvatarSubtitle;

  /// No description provided for @avatarAboveMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'Picture above messages'**
  String get avatarAboveMessageLabel;

  /// No description provided for @avatarAboveMessageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Place the face on top of the bubble'**
  String get avatarAboveMessageSubtitle;

  /// No description provided for @fullWidthAssistantLabel.
  ///
  /// In en, this message translates to:
  /// **'Full-width replies'**
  String get fullWidthAssistantLabel;

  /// No description provided for @fullWidthAssistantSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your messages stay in a bubble. Assistant text uses the whole row'**
  String get fullWidthAssistantSubtitle;

  /// No description provided for @tryFullWidthTitle.
  ///
  /// In en, this message translates to:
  /// **'Try the new full-width view'**
  String get tryFullWidthTitle;

  /// No description provided for @tryFullWidthBody.
  ///
  /// In en, this message translates to:
  /// **'Assistant replies use the whole row, with no bubble behind the text. You can switch back anytime in Appearance.'**
  String get tryFullWidthBody;

  /// No description provided for @tryFullWidthOpenAppearance.
  ///
  /// In en, this message translates to:
  /// **'Open Appearance'**
  String get tryFullWidthOpenAppearance;

  /// No description provided for @tryFullWidthNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get tryFullWidthNotNow;

  /// No description provided for @streamingPhaseLoadingModel.
  ///
  /// In en, this message translates to:
  /// **'Loading model'**
  String get streamingPhaseLoadingModel;

  /// No description provided for @streamingPhaseProcessingPrompt.
  ///
  /// In en, this message translates to:
  /// **'Processing prompt'**
  String get streamingPhaseProcessingPrompt;

  /// No description provided for @streamingPhaseThinking.
  ///
  /// In en, this message translates to:
  /// **'Thinking'**
  String get streamingPhaseThinking;

  /// No description provided for @streamingPhaseWriting.
  ///
  /// In en, this message translates to:
  /// **'Writing response'**
  String get streamingPhaseWriting;

  /// No description provided for @streamingPhaseSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching'**
  String get streamingPhaseSearching;

  /// No description provided for @streamingPhaseUsingTools.
  ///
  /// In en, this message translates to:
  /// **'Using tools'**
  String get streamingPhaseUsingTools;

  /// No description provided for @previewUserMessage.
  ///
  /// In en, this message translates to:
  /// **'What\'s the socket on this board?'**
  String get previewUserMessage;

  /// No description provided for @bubbleAvatarSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Picture size'**
  String get bubbleAvatarSizeLabel;

  /// No description provided for @bubbleAvatarRadiusValue.
  ///
  /// In en, this message translates to:
  /// **'Size {value}'**
  String bubbleAvatarRadiusValue(int value);

  /// No description provided for @userAvatarLabel.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get userAvatarLabel;

  /// No description provided for @yourProfilePicture.
  ///
  /// In en, this message translates to:
  /// **'How you look in chats'**
  String get yourProfilePicture;

  /// No description provided for @assistantAvatarLabel.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get assistantAvatarLabel;

  /// No description provided for @aiAssistantPicture.
  ///
  /// In en, this message translates to:
  /// **'Default look for the AI'**
  String get aiAssistantPicture;

  /// No description provided for @chatBehaviorSection.
  ///
  /// In en, this message translates to:
  /// **'CHAT TEXT'**
  String get chatBehaviorSection;

  /// No description provided for @fontSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get fontSizeLabel;

  /// No description provided for @iconSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Button size'**
  String get iconSizeLabel;

  /// No description provided for @pointsValue.
  ///
  /// In en, this message translates to:
  /// **'{value}'**
  String pointsValue(int value);

  /// No description provided for @previewLabel.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get previewLabel;

  /// No description provided for @previewAssistantMessage.
  ///
  /// In en, this message translates to:
  /// **'Hello! I\'m your AI assistant. How can I help you today? Here\'s a **bold** word and some `inline code`.'**
  String get previewAssistantMessage;

  /// No description provided for @readAloud.
  ///
  /// In en, this message translates to:
  /// **'Read aloud'**
  String get readAloud;

  /// No description provided for @appearanceActionTapped.
  ///
  /// In en, this message translates to:
  /// **'{label} tapped'**
  String appearanceActionTapped(String label);

  /// No description provided for @autoScrollStreaming.
  ///
  /// In en, this message translates to:
  /// **'Follow new replies'**
  String get autoScrollStreaming;

  /// No description provided for @autoScrollStreamingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep the chat at the latest words as they appear'**
  String get autoScrollStreamingSubtitle;

  /// No description provided for @showChatStarters.
  ///
  /// In en, this message translates to:
  /// **'New chat suggestions'**
  String get showChatStarters;

  /// No description provided for @showChatStartersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show scrolling prompt pills on empty chats'**
  String get showChatStartersSubtitle;

  /// No description provided for @useLegacyComposer.
  ///
  /// In en, this message translates to:
  /// **'Legacy message input'**
  String get useLegacyComposer;

  /// No description provided for @useLegacyComposerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use the classic compact composer instead of the new shine input'**
  String get useLegacyComposerSubtitle;

  /// No description provided for @hideAvatarsLabel.
  ///
  /// In en, this message translates to:
  /// **'Hide pictures'**
  String get hideAvatarsLabel;

  /// No description provided for @moreSpaceForContent.
  ///
  /// In en, this message translates to:
  /// **'Gives messages a bit more room'**
  String get moreSpaceForContent;

  /// No description provided for @enterKeyBehaviorLabel.
  ///
  /// In en, this message translates to:
  /// **'Enter key'**
  String get enterKeyBehaviorLabel;

  /// No description provided for @enterKeyAutoDescription.
  ///
  /// In en, this message translates to:
  /// **'Send on a computer keyboard, new line on phone'**
  String get enterKeyAutoDescription;

  /// No description provided for @enterKeySendDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter sends · Shift+Enter for a new line'**
  String get enterKeySendDescription;

  /// No description provided for @enterKeyNewlineDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter always starts a new line'**
  String get enterKeyNewlineDescription;

  /// No description provided for @sendLabel.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendLabel;

  /// No description provided for @newLineLabel.
  ///
  /// In en, this message translates to:
  /// **'New line'**
  String get newLineLabel;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @backLabel.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backLabel;

  /// No description provided for @nextLabel.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextLabel;

  /// No description provided for @getStartedLabel.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStartedLabel;

  /// No description provided for @connectionSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Connected successfully!'**
  String get connectionSuccessful;

  /// No description provided for @connectionFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get connectionFailedMessage;

  /// No description provided for @lmStudioServerFoundNeedsKey.
  ///
  /// In en, this message translates to:
  /// **'Server found! Add your API key above, then tap Test Connection.'**
  String get lmStudioServerFoundNeedsKey;

  /// No description provided for @lmStudioScanServerNeedsKey.
  ///
  /// In en, this message translates to:
  /// **'Found — add API key to connect'**
  String get lmStudioScanServerNeedsKey;

  /// No description provided for @lmStudioUsingServerNeedsKey.
  ///
  /// In en, this message translates to:
  /// **'Using {url}. Add your API key below, then test the connection.'**
  String lmStudioUsingServerNeedsKey(String url);

  /// No description provided for @lmStudioAuthDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Server found'**
  String get lmStudioAuthDialogTitle;

  /// No description provided for @lmStudioAuthDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'This server requires an API key. Paste your LM Studio token below to connect.'**
  String get lmStudioAuthDialogMessage;

  /// No description provided for @lmStudioAuthHelpHint.
  ///
  /// In en, this message translates to:
  /// **'In LM Studio, open Developer mode → Server settings → Manage tokens to create or copy your API key.'**
  String get lmStudioAuthHelpHint;

  /// No description provided for @welcomeWizardTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to LM Mini'**
  String get welcomeWizardTitle;

  /// No description provided for @welcomeWizardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Chat with AI models running on your local network via LM Studio. Let\'s get you set up in a few quick steps.'**
  String get welcomeWizardSubtitle;

  /// No description provided for @welcomeWizardThemeTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Theme'**
  String get welcomeWizardThemeTitle;

  /// No description provided for @welcomeWizardThemeSystemSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Match your device settings'**
  String get welcomeWizardThemeSystemSubtitle;

  /// No description provided for @welcomeWizardThemeLightSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Clean and bright'**
  String get welcomeWizardThemeLightSubtitle;

  /// No description provided for @welcomeWizardThemeDarkSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Easy on the eyes'**
  String get welcomeWizardThemeDarkSubtitle;

  /// No description provided for @welcomeWizardAppearanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Customize Appearance'**
  String get welcomeWizardAppearanceTitle;

  /// No description provided for @welcomeWizardAppearancePreviewMessage.
  ///
  /// In en, this message translates to:
  /// **'Hello! This is how your chat messages will look.'**
  String get welcomeWizardAppearancePreviewMessage;

  /// No description provided for @welcomeWizardServerTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect to LM Studio'**
  String get welcomeWizardServerTitle;

  /// No description provided for @welcomeWizardServerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the IP address of the computer running LM Studio on your local network.'**
  String get welcomeWizardServerSubtitle;

  /// No description provided for @welcomeWizardLocalNetworkNote.
  ///
  /// In en, this message translates to:
  /// **'iOS will ask for local network permission when you test the connection. Please allow it.'**
  String get welcomeWizardLocalNetworkNote;

  /// No description provided for @apiTokenOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'API Token (optional)'**
  String get apiTokenOptionalLabel;

  /// No description provided for @welcomeWizardChangeLater.
  ///
  /// In en, this message translates to:
  /// **'You can always change this later in Settings.'**
  String get welcomeWizardChangeLater;

  /// No description provided for @welcomeWizardFindModelTitle.
  ///
  /// In en, this message translates to:
  /// **'Find a model that fits'**
  String get welcomeWizardFindModelTitle;

  /// No description provided for @welcomeWizardFindModelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Race two options and see which is faster on your setup. Takes about a minute — or skip if you already know what you want.'**
  String get welcomeWizardFindModelSubtitle;

  /// No description provided for @welcomeWizardFindModelHelp.
  ///
  /// In en, this message translates to:
  /// **'Help me pick'**
  String get welcomeWizardFindModelHelp;

  /// No description provided for @welcomeWizardFindModelSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip — I\'ll choose myself'**
  String get welcomeWizardFindModelSkip;

  /// No description provided for @welcomeWizardExperienceTitle.
  ///
  /// In en, this message translates to:
  /// **'How do you use AI?'**
  String get welcomeWizardExperienceTitle;

  /// No description provided for @welcomeWizardExperienceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll tailor recommendations. You can change everything later.'**
  String get welcomeWizardExperienceSubtitle;

  /// No description provided for @welcomeWizardBeginnerTitle.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get welcomeWizardBeginnerTitle;

  /// No description provided for @welcomeWizardBeginnerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep it simple — clearer Settings, and we\'ll suggest a solid model for your phone.'**
  String get welcomeWizardBeginnerSubtitle;

  /// No description provided for @welcomeWizardPowerTitle.
  ///
  /// In en, this message translates to:
  /// **'Power user'**
  String get welcomeWizardPowerTitle;

  /// No description provided for @welcomeWizardPowerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Full Settings plus choices — on-device models and desktop servers like LM Studio.'**
  String get welcomeWizardPowerSubtitle;

  /// No description provided for @welcomeWizardSetupTitleBeginner.
  ///
  /// In en, this message translates to:
  /// **'Choose a model'**
  String get welcomeWizardSetupTitleBeginner;

  /// No description provided for @welcomeWizardSetupTitlePower.
  ///
  /// In en, this message translates to:
  /// **'Choose your setup'**
  String get welcomeWizardSetupTitlePower;

  /// No description provided for @welcomeWizardSetupSubtitleBeginner.
  ///
  /// In en, this message translates to:
  /// **'Tap a model to download. Or connect a computer on your Wi‑Fi.'**
  String get welcomeWizardSetupSubtitleBeginner;

  /// No description provided for @welcomeWizardSetupSubtitlePower.
  ///
  /// In en, this message translates to:
  /// **'Pick a model or connect a desktop server.'**
  String get welcomeWizardSetupSubtitlePower;

  /// No description provided for @welcomeWizardOnDeviceSection.
  ///
  /// In en, this message translates to:
  /// **'On this device'**
  String get welcomeWizardOnDeviceSection;

  /// No description provided for @welcomeWizardComputerSection.
  ///
  /// In en, this message translates to:
  /// **'On your computer'**
  String get welcomeWizardComputerSection;

  /// No description provided for @welcomeWizardScanningWifi.
  ///
  /// In en, this message translates to:
  /// **'Looking on Wi‑Fi…'**
  String get welcomeWizardScanningWifi;

  /// No description provided for @welcomeWizardFoundCount.
  ///
  /// In en, this message translates to:
  /// **'Found {count}'**
  String welcomeWizardFoundCount(int count);

  /// No description provided for @welcomeWizardModelFasterBlurb.
  ///
  /// In en, this message translates to:
  /// **'Quick replies. Great for everyday chat.'**
  String get welcomeWizardModelFasterBlurb;

  /// No description provided for @welcomeWizardModelBalancedBlurb.
  ///
  /// In en, this message translates to:
  /// **'Good balance of speed and quality.'**
  String get welcomeWizardModelBalancedBlurb;

  /// No description provided for @welcomeWizardModelBestBlurb.
  ///
  /// In en, this message translates to:
  /// **'Strongest quality that fits your device.'**
  String get welcomeWizardModelBestBlurb;

  /// No description provided for @welcomeWizardNameTitle.
  ///
  /// In en, this message translates to:
  /// **'What should AI call you?'**
  String get welcomeWizardNameTitle;

  /// No description provided for @welcomeWizardNameSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A first name or nickname is perfect. You can skip this.'**
  String get welcomeWizardNameSubtitle;

  /// No description provided for @welcomeWizardNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Alex'**
  String get welcomeWizardNameHint;

  /// No description provided for @welcomeWizardFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get welcomeWizardFinish;

  /// No description provided for @welcomeWizardContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get welcomeWizardContinue;

  /// No description provided for @welcomeWizardSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get welcomeWizardSkip;

  /// No description provided for @welcomeWizardConnectLmStudio.
  ///
  /// In en, this message translates to:
  /// **'Connect LM Studio'**
  String get welcomeWizardConnectLmStudio;

  /// No description provided for @welcomeWizardConnectOllama.
  ///
  /// In en, this message translates to:
  /// **'Connect Ollama'**
  String get welcomeWizardConnectOllama;

  /// No description provided for @welcomeWizardConnectOmlx.
  ///
  /// In en, this message translates to:
  /// **'Connect oMLX'**
  String get welcomeWizardConnectOmlx;

  /// No description provided for @pickColor.
  ///
  /// In en, this message translates to:
  /// **'Pick Color'**
  String get pickColor;

  /// No description provided for @hueLabel.
  ///
  /// In en, this message translates to:
  /// **'Hue'**
  String get hueLabel;

  /// No description provided for @saturationLabel.
  ///
  /// In en, this message translates to:
  /// **'Saturation'**
  String get saturationLabel;

  /// No description provided for @lightnessLabel.
  ///
  /// In en, this message translates to:
  /// **'Lightness'**
  String get lightnessLabel;

  /// No description provided for @alphaLabel.
  ///
  /// In en, this message translates to:
  /// **'Alpha'**
  String get alphaLabel;

  /// No description provided for @hexLabel.
  ///
  /// In en, this message translates to:
  /// **'Hex'**
  String get hexLabel;

  /// No description provided for @personaModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Persona Mode'**
  String get personaModeLabel;

  /// No description provided for @personaModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add avatar, accent color, voice, and preferred model for group chats'**
  String get personaModeSubtitle;

  /// No description provided for @avatarLabel.
  ///
  /// In en, this message translates to:
  /// **'Avatar'**
  String get avatarLabel;

  /// No description provided for @customAvatarSet.
  ///
  /// In en, this message translates to:
  /// **'Custom avatar set'**
  String get customAvatarSet;

  /// No description provided for @noAvatar.
  ///
  /// In en, this message translates to:
  /// **'No avatar'**
  String get noAvatar;

  /// No description provided for @accentColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Accent Color'**
  String get accentColorLabel;

  /// No description provided for @defaultLabel.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultLabel;

  /// No description provided for @preferredModelLabel.
  ///
  /// In en, this message translates to:
  /// **'Preferred Model'**
  String get preferredModelLabel;

  /// No description provided for @preferredModelAny.
  ///
  /// In en, this message translates to:
  /// **'None (use any)'**
  String get preferredModelAny;

  /// No description provided for @personaChooseProviderTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose provider'**
  String get personaChooseProviderTitle;

  /// No description provided for @personaChooseProviderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your configured providers. Add more in Settings.'**
  String get personaChooseProviderSubtitle;

  /// No description provided for @personaCloudProvidersSection.
  ///
  /// In en, this message translates to:
  /// **'Cloud providers'**
  String get personaCloudProvidersSection;

  /// No description provided for @personaKokoroVoiceLabel.
  ///
  /// In en, this message translates to:
  /// **'Kokoro Voice'**
  String get personaKokoroVoiceLabel;

  /// No description provided for @personaKokoroVoiceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Voice used when this persona speaks (voice chat / read aloud)'**
  String get personaKokoroVoiceSubtitle;

  /// No description provided for @personaKokoroVoiceGlobal.
  ///
  /// In en, this message translates to:
  /// **'Use global voice setting'**
  String get personaKokoroVoiceGlobal;

  /// No description provided for @personaKokoroVoicePickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Persona Voice'**
  String get personaKokoroVoicePickerTitle;

  /// No description provided for @personaKokoroSpeedLabel.
  ///
  /// In en, this message translates to:
  /// **'Speech Speed'**
  String get personaKokoroSpeedLabel;

  /// No description provided for @personaKokoroSpeedGlobal.
  ///
  /// In en, this message translates to:
  /// **'Use global speed'**
  String get personaKokoroSpeedGlobal;

  /// No description provided for @personaKokoroSpeedValue.
  ///
  /// In en, this message translates to:
  /// **'{speed}x'**
  String personaKokoroSpeedValue(String speed);

  /// No description provided for @voiceWhisperModelLabel.
  ///
  /// In en, this message translates to:
  /// **'Whisper model'**
  String get voiceWhisperModelLabel;

  /// No description provided for @voiceWhisperModelTapToChoose.
  ///
  /// In en, this message translates to:
  /// **'Tap to choose size and download'**
  String get voiceWhisperModelTapToChoose;

  /// No description provided for @imageGenSeedLabel.
  ///
  /// In en, this message translates to:
  /// **'Image Gen Seed'**
  String get imageGenSeedLabel;

  /// No description provided for @imageGenSeedFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed seed: {seed}'**
  String imageGenSeedFixed(int seed);

  /// No description provided for @imageGenSeedRandomGlobal.
  ///
  /// In en, this message translates to:
  /// **'Random (use global setting)'**
  String get imageGenSeedRandomGlobal;

  /// No description provided for @personaComfyWorkflowLabel.
  ///
  /// In en, this message translates to:
  /// **'ComfyUI workflow'**
  String get personaComfyWorkflowLabel;

  /// No description provided for @personaComfyWorkflowUseGlobal.
  ///
  /// In en, this message translates to:
  /// **'Use global setting'**
  String get personaComfyWorkflowUseGlobal;

  /// No description provided for @personaComfyWorkflowUnavailable.
  ///
  /// In en, this message translates to:
  /// **'{path} (currently unavailable)'**
  String personaComfyWorkflowUnavailable(String path);

  /// No description provided for @personaComfyWorkflowHelper.
  ///
  /// In en, this message translates to:
  /// **'Used when Image Generation provider is ComfyUI. Leave as global to use Settings → Image Generation.'**
  String get personaComfyWorkflowHelper;

  /// No description provided for @personaComfyWorkflowNotComfy.
  ///
  /// In en, this message translates to:
  /// **'This assignment applies only when ComfyUI is the active image provider.'**
  String get personaComfyWorkflowNotComfy;

  /// No description provided for @personaComfyWorkflowRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh workflows'**
  String get personaComfyWorkflowRefresh;

  /// No description provided for @personaComfyWorkflowJsonLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom workflow JSON (optional)'**
  String get personaComfyWorkflowJsonLabel;

  /// No description provided for @personaComfyWorkflowJsonHint.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to use the global / built-in workflow'**
  String get personaComfyWorkflowJsonHint;

  /// No description provided for @personaComfyWorkflowJsonHelper.
  ///
  /// In en, this message translates to:
  /// **'Paste an API-format workflow. Supports %PROMPT%, %LORA%, %LORA_WEIGHT%, and other placeholders.'**
  String get personaComfyWorkflowJsonHelper;

  /// No description provided for @personaComfyWorkflowJsonIgnored.
  ///
  /// In en, this message translates to:
  /// **'Ignored while a saved workflow is selected'**
  String get personaComfyWorkflowJsonIgnored;

  /// No description provided for @personaComfyWorkflowJsonActive.
  ///
  /// In en, this message translates to:
  /// **'Using custom workflow ({count} chars)'**
  String personaComfyWorkflowJsonActive(int count);

  /// No description provided for @personaComfyWorkflowJsonClear.
  ///
  /// In en, this message translates to:
  /// **'Clear (use global / default)'**
  String get personaComfyWorkflowJsonClear;

  /// No description provided for @comfyUiDetails.
  ///
  /// In en, this message translates to:
  /// **'ComfyUI details'**
  String get comfyUiDetails;

  /// No description provided for @comfyUiDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'ComfyUI request'**
  String get comfyUiDetailsTitle;

  /// No description provided for @comfyUiDetailsCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy JSON'**
  String get comfyUiDetailsCopy;

  /// No description provided for @comfyUiDetailsCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get comfyUiDetailsCopied;

  /// No description provided for @resetToGlobal.
  ///
  /// In en, this message translates to:
  /// **'Reset to global'**
  String get resetToGlobal;

  /// No description provided for @setSeed.
  ///
  /// In en, this message translates to:
  /// **'Set seed'**
  String get setSeed;

  /// No description provided for @pickAccentColor.
  ///
  /// In en, this message translates to:
  /// **'Pick Accent Color'**
  String get pickAccentColor;

  /// No description provided for @imageGenSeedDialogDescription.
  ///
  /// In en, this message translates to:
  /// **'Set a fixed seed so this persona always generates consistent images. Leave blank for random.'**
  String get imageGenSeedDialogDescription;

  /// No description provided for @seedValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Seed value'**
  String get seedValueLabel;

  /// No description provided for @seedValueHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 42 (blank = random)'**
  String get seedValueHint;

  /// No description provided for @setLabel.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get setLabel;

  /// No description provided for @selectPreferredModelTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Preferred Model'**
  String get selectPreferredModelTitle;

  /// No description provided for @branchCreated.
  ///
  /// In en, this message translates to:
  /// **'🔀 Branch created'**
  String get branchCreated;

  /// No description provided for @yamlFrontmatter.
  ///
  /// In en, this message translates to:
  /// **'YAML frontmatter'**
  String get yamlFrontmatter;

  /// No description provided for @markdownFormat.
  ///
  /// In en, this message translates to:
  /// **'Markdown'**
  String get markdownFormat;

  /// No description provided for @localNetworkBlocked.
  ///
  /// In en, this message translates to:
  /// **'Local Network access may be blocked'**
  String get localNetworkBlocked;

  /// No description provided for @localNetworkFix.
  ///
  /// In en, this message translates to:
  /// **'Go to Settings → LM Mini → Local Network and enable it.'**
  String get localNetworkFix;

  /// No description provided for @openAppSettings.
  ///
  /// In en, this message translates to:
  /// **'Open App Settings'**
  String get openAppSettings;

  /// No description provided for @memorySaved.
  ///
  /// In en, this message translates to:
  /// **'Memory saved'**
  String get memorySaved;

  /// No description provided for @proSearch.
  ///
  /// In en, this message translates to:
  /// **'Pro Search'**
  String get proSearch;

  /// No description provided for @webSearchLabel.
  ///
  /// In en, this message translates to:
  /// **'Web search'**
  String get webSearchLabel;

  /// No description provided for @readUrl.
  ///
  /// In en, this message translates to:
  /// **'Read URL'**
  String get readUrl;

  /// No description provided for @code.
  ///
  /// In en, this message translates to:
  /// **'code'**
  String get code;

  /// No description provided for @couldNotOpenFile.
  ///
  /// In en, this message translates to:
  /// **'Could not open file: {error}'**
  String couldNotOpenFile(String error);

  /// No description provided for @tapOpenExternal.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Open with external app\" to view this file'**
  String get tapOpenExternal;

  /// No description provided for @proSearchEnabled.
  ///
  /// In en, this message translates to:
  /// **'Pro Search enabled'**
  String get proSearchEnabled;

  /// No description provided for @proSearchDisabled.
  ///
  /// In en, this message translates to:
  /// **'Pro Search disabled'**
  String get proSearchDisabled;

  /// No description provided for @thinkingEnabled.
  ///
  /// In en, this message translates to:
  /// **'Thinking on for this chat'**
  String get thinkingEnabled;

  /// No description provided for @thinkingDisabled.
  ///
  /// In en, this message translates to:
  /// **'Thinking off for this chat'**
  String get thinkingDisabled;

  /// No description provided for @codeSandbox.
  ///
  /// In en, this message translates to:
  /// **'Code Sandbox'**
  String get codeSandbox;

  /// No description provided for @codeSandboxSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Run Python or JavaScript in a secure sandbox'**
  String get codeSandboxSubtitle;

  /// No description provided for @codeSandboxEnabled.
  ///
  /// In en, this message translates to:
  /// **'Code Sandbox enabled'**
  String get codeSandboxEnabled;

  /// No description provided for @codeSandboxDisabled.
  ///
  /// In en, this message translates to:
  /// **'Code Sandbox disabled'**
  String get codeSandboxDisabled;

  /// No description provided for @searxngNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Add a SearXNG URL to enable'**
  String get searxngNotConfigured;

  /// No description provided for @searxngConfiguredOff.
  ///
  /// In en, this message translates to:
  /// **'Configured — tap to use instead of Pro Search'**
  String get searxngConfiguredOff;

  /// No description provided for @searxngConfigureFirst.
  ///
  /// In en, this message translates to:
  /// **'Configure a SearXNG URL before enabling'**
  String get searxngConfigureFirst;

  /// No description provided for @editSearxng.
  ///
  /// In en, this message translates to:
  /// **'Edit SearXNG'**
  String get editSearxng;

  /// No description provided for @toolCallingLabel.
  ///
  /// In en, this message translates to:
  /// **'Tool Calling'**
  String get toolCallingLabel;

  /// No description provided for @on.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get on;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @aiCanUseTools.
  ///
  /// In en, this message translates to:
  /// **'AI can use tools in this chat'**
  String get aiCanUseTools;

  /// No description provided for @toolsDisabledChat.
  ///
  /// In en, this message translates to:
  /// **'Tools disabled for this chat'**
  String get toolsDisabledChat;

  /// No description provided for @webSearchChat.
  ///
  /// In en, this message translates to:
  /// **'Web Search'**
  String get webSearchChat;

  /// No description provided for @aiCanSearchWeb.
  ///
  /// In en, this message translates to:
  /// **'AI can search the web in this chat'**
  String get aiCanSearchWeb;

  /// No description provided for @webSearchDisabledChat.
  ///
  /// In en, this message translates to:
  /// **'Web search disabled for this chat'**
  String get webSearchDisabledChat;

  /// No description provided for @disableMemory.
  ///
  /// In en, this message translates to:
  /// **'Disable Memories'**
  String get disableMemory;

  /// No description provided for @memoryItemsActive.
  ///
  /// In en, this message translates to:
  /// **'{count} memories active'**
  String memoryItemsActive(int count);

  /// No description provided for @memoryDisabledChat.
  ///
  /// In en, this message translates to:
  /// **'Memories are disabled for this chat. The AI won\'t see your saved items.'**
  String get memoryDisabledChat;

  /// No description provided for @lmStudioLocal.
  ///
  /// In en, this message translates to:
  /// **'LM Studio (Local)'**
  String get lmStudioLocal;

  /// No description provided for @modelNoLongerAvailable.
  ///
  /// In en, this message translates to:
  /// **'Previously selected model is no longer available. Please select a new model.'**
  String get modelNoLongerAvailable;

  /// No description provided for @noModelsForProvider.
  ///
  /// In en, this message translates to:
  /// **'No models found for this provider. Check API key.'**
  String get noModelsForProvider;

  /// No description provided for @noModelsCheckConnection.
  ///
  /// In en, this message translates to:
  /// **'No models found. Check LM Studio connection.'**
  String get noModelsCheckConnection;

  /// No description provided for @selectModel.
  ///
  /// In en, this message translates to:
  /// **'Select model'**
  String get selectModel;

  /// No description provided for @goToModels.
  ///
  /// In en, this message translates to:
  /// **'Go to models'**
  String get goToModels;

  /// No description provided for @reviewImagePrompt.
  ///
  /// In en, this message translates to:
  /// **'Review Image Prompt'**
  String get reviewImagePrompt;

  /// No description provided for @editImagePromptHint.
  ///
  /// In en, this message translates to:
  /// **'Edit the image prompt...'**
  String get editImagePromptHint;

  /// No description provided for @generate.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get generate;

  /// No description provided for @imageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Image not found'**
  String get imageNotFound;

  /// No description provided for @cameraPermissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Camera Permission Needed'**
  String get cameraPermissionNeeded;

  /// No description provided for @cameraPermissionExplain.
  ///
  /// In en, this message translates to:
  /// **'Please allow camera access to take photos for vision analysis.'**
  String get cameraPermissionExplain;

  /// No description provided for @photosPermissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Photos Permission Needed'**
  String get photosPermissionNeeded;

  /// No description provided for @photosPermissionExplain.
  ///
  /// In en, this message translates to:
  /// **'Please allow access to your images for vision analysis.'**
  String get photosPermissionExplain;

  /// No description provided for @couldNotOpenFilePicker.
  ///
  /// In en, this message translates to:
  /// **'Could not open file picker: {error}'**
  String couldNotOpenFilePicker(String error);

  /// No description provided for @filePickerCouldNotCopy.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t copy that file. Save it on this phone (not Drive or Recents) and pick it again.'**
  String get filePickerCouldNotCopy;

  /// No description provided for @signInToUseCloudBackup.
  ///
  /// In en, this message translates to:
  /// **'Sign in to use Cloud Backup'**
  String get signInToUseCloudBackup;

  /// No description provided for @cloudBackupRequiresAccount.
  ///
  /// In en, this message translates to:
  /// **'Cloud Backup requires an account so your encrypted backups are stored securely under your identity.'**
  String get cloudBackupRequiresAccount;

  /// No description provided for @arguments.
  ///
  /// In en, this message translates to:
  /// **'Arguments'**
  String get arguments;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @connectionPopupTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a provider'**
  String get connectionPopupTitle;

  /// No description provided for @connectionPopupBody.
  ///
  /// In en, this message translates to:
  /// **'Connect LM Studio, pick an On-Device model, or sign in to a cloud provider in Settings.'**
  String get connectionPopupBody;

  /// No description provided for @connectionPopupDismiss.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get connectionPopupDismiss;

  /// No description provided for @connectionPopupGoToSettings.
  ///
  /// In en, this message translates to:
  /// **'Go to Settings'**
  String get connectionPopupGoToSettings;

  /// No description provided for @remoteAccess.
  ///
  /// In en, this message translates to:
  /// **'Remote Access'**
  String get remoteAccess;

  /// No description provided for @scanQrCode.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get scanQrCode;

  /// No description provided for @connectedViaLmConnect.
  ///
  /// In en, this message translates to:
  /// **'Connected via LM Connect'**
  String get connectedViaLmConnect;

  /// No description provided for @disconnectRemoteToChangeSettings.
  ///
  /// In en, this message translates to:
  /// **'Remote LM Studio is paired via LM Connect'**
  String get disconnectRemoteToChangeSettings;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @unpair.
  ///
  /// In en, this message translates to:
  /// **'Unpair'**
  String get unpair;

  /// No description provided for @useRemoteConnection.
  ///
  /// In en, this message translates to:
  /// **'Chat with this Mac'**
  String get useRemoteConnection;

  /// No description provided for @useRemoteConnectionOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Off — this phone uses its own models. Turn on to use models on LM Mini Home.'**
  String get useRemoteConnectionOffSubtitle;

  /// No description provided for @connectedViaLmStudio.
  ///
  /// In en, this message translates to:
  /// **'Connected via LM Studio'**
  String get connectedViaLmStudio;

  /// No description provided for @usingLocalServer.
  ///
  /// In en, this message translates to:
  /// **'Using local server'**
  String get usingLocalServer;

  /// No description provided for @testing.
  ///
  /// In en, this message translates to:
  /// **'Testing...'**
  String get testing;

  /// No description provided for @connectedLatency.
  ///
  /// In en, this message translates to:
  /// **'Connected — {ms}ms'**
  String connectedLatency(int ms);

  /// No description provided for @notConnected.
  ///
  /// In en, this message translates to:
  /// **'Not Connected'**
  String get notConnected;

  /// No description provided for @scanQrDescription.
  ///
  /// In en, this message translates to:
  /// **'Scan a QR code from LM Mini on Mac (Share with phone) — or legacy LM Mini Connect — to reach your desktop models from anywhere.'**
  String get scanQrDescription;

  /// No description provided for @remotePaired.
  ///
  /// In en, this message translates to:
  /// **'Remote Paired'**
  String get remotePaired;

  /// No description provided for @lastConnected.
  ///
  /// In en, this message translates to:
  /// **'Last connected: {time}'**
  String lastConnected(String time);

  /// No description provided for @reScanQrCode.
  ///
  /// In en, this message translates to:
  /// **'Re-scan QR Code'**
  String get reScanQrCode;

  /// No description provided for @qrRequiresPro.
  ///
  /// In en, this message translates to:
  /// **'QR code scanning requires LM Mini Pro'**
  String get qrRequiresPro;

  /// No description provided for @enterUrlManually.
  ///
  /// In en, this message translates to:
  /// **'Enter URL manually'**
  String get enterUrlManually;

  /// No description provided for @enterUrlManuallySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Paste a pairing link if the camera is unavailable'**
  String get enterUrlManuallySubtitle;

  /// No description provided for @relayUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://relay.lmmini.com/s/…'**
  String get relayUrlHint;

  /// No description provided for @connectWithUrl.
  ///
  /// In en, this message translates to:
  /// **'Connect with URL'**
  String get connectWithUrl;

  /// No description provided for @invalidRelayUrl.
  ///
  /// In en, this message translates to:
  /// **'That is not a valid LM Mini pairing link. Copy it from Share with phone on your Mac.'**
  String get invalidRelayUrl;

  /// No description provided for @invalidQrCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid QR code. Open Share with phone in LM Mini on Mac (or legacy Connect) to generate one.'**
  String get invalidQrCode;

  /// No description provided for @pointCameraAtQr.
  ///
  /// In en, this message translates to:
  /// **'Point your camera at the QR code shown in LM Mini on Mac (Share with phone)'**
  String get pointCameraAtQr;

  /// No description provided for @connectedToRemoteLmStudio.
  ///
  /// In en, this message translates to:
  /// **'Connected to remote LM Studio!'**
  String get connectedToRemoteLmStudio;

  /// No description provided for @failedToConnect.
  ///
  /// In en, this message translates to:
  /// **'Failed to connect. Make sure LM Mini on Mac has Share with phone enabled (or legacy Connect is running).'**
  String get failedToConnect;

  /// No description provided for @unpairRemote.
  ///
  /// In en, this message translates to:
  /// **'Unpair Remote'**
  String get unpairRemote;

  /// No description provided for @unpairRemoteDescription.
  ///
  /// In en, this message translates to:
  /// **'This will remove the saved remote connection. You can re-pair by scanning a new QR code.'**
  String get unpairRemoteDescription;

  /// No description provided for @setupGuide.
  ///
  /// In en, this message translates to:
  /// **'Setup Guide'**
  String get setupGuide;

  /// No description provided for @downloadLmMiniConnect.
  ///
  /// In en, this message translates to:
  /// **'Get LM Mini Home'**
  String get downloadLmMiniConnect;

  /// No description provided for @availableForPlatforms.
  ///
  /// In en, this message translates to:
  /// **'Direct download for Mac · Connect for Windows and Linux'**
  String get availableForPlatforms;

  /// No description provided for @setupStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Download LM Mini Home'**
  String get setupStep1Title;

  /// No description provided for @setupStep1Desc.
  ///
  /// In en, this message translates to:
  /// **'Get LM Mini Home for Mac from lmmini.com. On Windows and Linux you can still use LM Mini Connect.'**
  String get setupStep1Desc;

  /// No description provided for @setupStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Share with phone'**
  String get setupStep2Title;

  /// No description provided for @setupStep2Desc.
  ///
  /// In en, this message translates to:
  /// **'In LM Mini Home on your Mac, open Share with phone and turn it on. It connects to the relay instantly.'**
  String get setupStep2Desc;

  /// No description provided for @setupStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get setupStep3Title;

  /// No description provided for @setupStep3Desc.
  ///
  /// In en, this message translates to:
  /// **'Scan the QR code shown on your Mac. That\'s it!'**
  String get setupStep3Desc;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String minutesAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String hoursAgo(int count);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String daysAgo(int count);

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// No description provided for @moveToFolder.
  ///
  /// In en, this message translates to:
  /// **'Move to folder'**
  String get moveToFolder;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @dismissAction.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismissAction;

  /// No description provided for @createNewFolder.
  ///
  /// In en, this message translates to:
  /// **'Create new folder'**
  String get createNewFolder;

  /// No description provided for @deleteConversations.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} conversation(s)? This cannot be undone.'**
  String deleteConversations(int count);

  /// No description provided for @averages.
  ///
  /// In en, this message translates to:
  /// **'AVERAGES'**
  String get averages;

  /// No description provided for @tokensPerChat.
  ///
  /// In en, this message translates to:
  /// **'Tokens / Chat'**
  String get tokensPerChat;

  /// No description provided for @msgsPerChat.
  ///
  /// In en, this message translates to:
  /// **'Msgs / Chat'**
  String get msgsPerChat;

  /// No description provided for @tokensPerMsg.
  ///
  /// In en, this message translates to:
  /// **'Tokens / Msg'**
  String get tokensPerMsg;

  /// No description provided for @topModel.
  ///
  /// In en, this message translates to:
  /// **'Top Model'**
  String get topModel;

  /// No description provided for @liveActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Live Activity'**
  String get liveActivityTitle;

  /// No description provided for @liveActivityTitleAndroid.
  ///
  /// In en, this message translates to:
  /// **'Background generation'**
  String get liveActivityTitleAndroid;

  /// No description provided for @liveActivityDescription.
  ///
  /// In en, this message translates to:
  /// **'Process your A.I. request even when you exit the app or lock it'**
  String get liveActivityDescription;

  /// No description provided for @liveActivityDescriptionAndroid.
  ///
  /// In en, this message translates to:
  /// **'Keep generating when you leave the app — on-device models, LM Studio, and cloud providers. Shows a silent ongoing notification with progress and keeps the HTTP stream alive on Android.'**
  String get liveActivityDescriptionAndroid;

  /// No description provided for @liveActivityAndroidOnDeviceOnly.
  ///
  /// In en, this message translates to:
  /// **'Switch to an on-device GGUF or MLX model to use background generation on Android.'**
  String get liveActivityAndroidOnDeviceOnly;

  /// No description provided for @liveActivityNotificationDenied.
  ///
  /// In en, this message translates to:
  /// **'Notification permission is required for background generation on Android.'**
  String get liveActivityNotificationDenied;

  /// No description provided for @premiumRemoteAccess.
  ///
  /// In en, this message translates to:
  /// **'Remote Access'**
  String get premiumRemoteAccess;

  /// No description provided for @premiumRemoteAccessTagline.
  ///
  /// In en, this message translates to:
  /// **'LM Studio from anywhere'**
  String get premiumRemoteAccessTagline;

  /// No description provided for @premiumRemoteAccessDescription.
  ///
  /// In en, this message translates to:
  /// **'Access your Mac or PC models from anywhere. On Mac, use LM Mini → Share with phone. No port forwarding or VPN — scan a QR code for an encrypted relay.'**
  String get premiumRemoteAccessDescription;

  /// No description provided for @premiumLiveActivity.
  ///
  /// In en, this message translates to:
  /// **'Live Activity'**
  String get premiumLiveActivity;

  /// No description provided for @premiumLiveActivityTagline.
  ///
  /// In en, this message translates to:
  /// **'A.I. works in the background'**
  String get premiumLiveActivityTagline;

  /// No description provided for @premiumLiveActivityDescription.
  ///
  /// In en, this message translates to:
  /// **'Process your A.I. request even when you exit the app or lock the phone. See real-time generation progress on your Lock Screen and Dynamic Island — watch tokens counting up and generation speed without switching back.'**
  String get premiumLiveActivityDescription;

  /// No description provided for @premiumWebSearchTagline.
  ///
  /// In en, this message translates to:
  /// **'No server setup required'**
  String get premiumWebSearchTagline;

  /// No description provided for @premiumWebSearchDescription.
  ///
  /// In en, this message translates to:
  /// **'Instantly search the web during conversations. Powered by cloud search APIs — no need to self-host SearXNG or configure anything. Just ask and your model gets fresh, real-time information from the internet.'**
  String get premiumWebSearchDescription;

  /// No description provided for @premiumCloudBackup.
  ///
  /// In en, this message translates to:
  /// **'Encrypted Cloud Backup'**
  String get premiumCloudBackup;

  /// No description provided for @premiumCloudBackupTagline.
  ///
  /// In en, this message translates to:
  /// **'AES-256-GCM encryption'**
  String get premiumCloudBackupTagline;

  /// No description provided for @premiumCloudBackupDescription.
  ///
  /// In en, this message translates to:
  /// **'Back up all conversations to the cloud with military-grade encryption. Your passphrase never leaves your device — not even we can read your data. Restore on any device with one tap.'**
  String get premiumCloudBackupDescription;

  /// No description provided for @premiumUrlReader.
  ///
  /// In en, this message translates to:
  /// **'URL Reader'**
  String get premiumUrlReader;

  /// No description provided for @premiumUrlReaderTagline.
  ///
  /// In en, this message translates to:
  /// **'Analyze any webpage'**
  String get premiumUrlReaderTagline;

  /// No description provided for @premiumUrlReaderDescription.
  ///
  /// In en, this message translates to:
  /// **'Paste any URL and your model reads the full page content. Summarize articles, analyze documentation, extract data from tables — all without leaving the conversation.'**
  String get premiumUrlReaderDescription;

  /// No description provided for @premiumBranching.
  ///
  /// In en, this message translates to:
  /// **'Conversation Branching'**
  String get premiumBranching;

  /// No description provided for @premiumBranchingTagline.
  ///
  /// In en, this message translates to:
  /// **'Explore alternate paths'**
  String get premiumBranchingTagline;

  /// No description provided for @premiumBranchingDescription.
  ///
  /// In en, this message translates to:
  /// **'Fork any conversation from any message to explore \"what if\" scenarios. Compare different prompts, try various approaches, and keep your best threads — all without losing the original.'**
  String get premiumBranchingDescription;

  /// No description provided for @premiumMemory.
  ///
  /// In en, this message translates to:
  /// **'Memories'**
  String get premiumMemory;

  /// No description provided for @premiumMemoryTagline.
  ///
  /// In en, this message translates to:
  /// **'Remembers you across chats'**
  String get premiumMemoryTagline;

  /// No description provided for @premiumMemoryDescription.
  ///
  /// In en, this message translates to:
  /// **'Save facts, preferences, and context that persist across all conversations. Your model will know your name, coding style, preferred language, and anything else you teach it — every time you start a new chat.'**
  String get premiumMemoryDescription;

  /// No description provided for @premiumAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics Dashboard'**
  String get premiumAnalytics;

  /// No description provided for @premiumAnalyticsTagline.
  ///
  /// In en, this message translates to:
  /// **'Know your usage'**
  String get premiumAnalyticsTagline;

  /// No description provided for @premiumAnalyticsDescription.
  ///
  /// In en, this message translates to:
  /// **'Track tokens used, messages sent, model usage breakdown, and average response times. Understand your AI usage patterns and optimize your workflow with beautiful charts.'**
  String get premiumAnalyticsDescription;

  /// No description provided for @premiumCloudApi.
  ///
  /// In en, this message translates to:
  /// **'Cloud API Providers'**
  String get premiumCloudApi;

  /// No description provided for @premiumCloudApiTagline.
  ///
  /// In en, this message translates to:
  /// **'Mistral, Anthropic & more'**
  String get premiumCloudApiTagline;

  /// No description provided for @premiumCloudApiDescription.
  ///
  /// In en, this message translates to:
  /// **'Connect to cloud LLM providers alongside your local models. Use Claude, Gemini, and Mistral when you need cutting-edge performance — seamlessly switch between local and cloud.'**
  String get premiumCloudApiDescription;

  /// No description provided for @premiumExport.
  ///
  /// In en, this message translates to:
  /// **'Rich Export & Share'**
  String get premiumExport;

  /// No description provided for @premiumExportTagline.
  ///
  /// In en, this message translates to:
  /// **'Obsidian, Notes, Notion & more'**
  String get premiumExportTagline;

  /// No description provided for @premiumExportDescription.
  ///
  /// In en, this message translates to:
  /// **'Export conversations as beautifully formatted Markdown, PDF, or plain text. Share directly to Obsidian, Apple Notes, Notion, or any app. Perfect for saving research and insights.'**
  String get premiumExportDescription;

  /// No description provided for @premiumCompactContext.
  ///
  /// In en, this message translates to:
  /// **'Compact context'**
  String get premiumCompactContext;

  /// No description provided for @premiumCompactContextTagline.
  ///
  /// In en, this message translates to:
  /// **'Keep chatting when the window is full'**
  String get premiumCompactContextTagline;

  /// No description provided for @premiumCompactContextDescription.
  ///
  /// In en, this message translates to:
  /// **'Roll older messages, cut the middle, or compact a long chat into a summary on the same loaded model so a full context window doesn’t stop the conversation.'**
  String get premiumCompactContextDescription;

  /// No description provided for @premiumParamPresets.
  ///
  /// In en, this message translates to:
  /// **'Param presets'**
  String get premiumParamPresets;

  /// No description provided for @premiumParamPresetsTagline.
  ///
  /// In en, this message translates to:
  /// **'Per-model and persona generation settings'**
  String get premiumParamPresetsTagline;

  /// No description provided for @premiumParamPresetsDescription.
  ///
  /// In en, this message translates to:
  /// **'Save sampler and load settings per model, and optional custom params on a persona. Free stays on the Global defaults that ship with the app.'**
  String get premiumParamPresetsDescription;

  /// No description provided for @paramPresetSetFor.
  ///
  /// In en, this message translates to:
  /// **'Set params for'**
  String get paramPresetSetFor;

  /// No description provided for @paramPresetGlobalTab.
  ///
  /// In en, this message translates to:
  /// **'Global'**
  String get paramPresetGlobalTab;

  /// No description provided for @paramPresetScopeHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'How params apply'**
  String get paramPresetScopeHelpTitle;

  /// No description provided for @paramPresetScopeHelpIntro.
  ///
  /// In en, this message translates to:
  /// **'The most specific layer that is on wins. Chat-level overrides (if you set them in a conversation) still sit on top.'**
  String get paramPresetScopeHelpIntro;

  /// No description provided for @paramPresetScopeHelpGlobal.
  ///
  /// In en, this message translates to:
  /// **'Defaults for every model that does not have its own preset. This is what the app ships with.'**
  String get paramPresetScopeHelpGlobal;

  /// No description provided for @paramPresetScopeHelpModel.
  ///
  /// In en, this message translates to:
  /// **'Changing knobs on the selected-model tab saves a preset for that model only. Use Global params removes it so the model follows Global again.'**
  String get paramPresetScopeHelpModel;

  /// No description provided for @paramPresetScopeHelpPersonaTitle.
  ///
  /// In en, this message translates to:
  /// **'Persona'**
  String get paramPresetScopeHelpPersonaTitle;

  /// No description provided for @paramPresetScopeHelpPersona.
  ///
  /// In en, this message translates to:
  /// **'If a persona has a preferred model, turn on Use custom params to override that model’s preset (or Global) while the persona is active.'**
  String get paramPresetScopeHelpPersona;

  /// No description provided for @paramPresetSelectedModelTab.
  ///
  /// In en, this message translates to:
  /// **'Selected model'**
  String get paramPresetSelectedModelTab;

  /// No description provided for @paramPresetNoModel.
  ///
  /// In en, this message translates to:
  /// **'Select a model to save a preset for it.'**
  String get paramPresetNoModel;

  /// No description provided for @paramPresetUsingGlobal.
  ///
  /// In en, this message translates to:
  /// **'This model uses Global params.'**
  String get paramPresetUsingGlobal;

  /// No description provided for @paramPresetUsingCustom.
  ///
  /// In en, this message translates to:
  /// **'This model has a custom preset.'**
  String get paramPresetUsingCustom;

  /// No description provided for @paramPresetUseGlobal.
  ///
  /// In en, this message translates to:
  /// **'Use Global params'**
  String get paramPresetUseGlobal;

  /// No description provided for @paramPresetUseGlobalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this model’s preset and fall back to Global.'**
  String get paramPresetUseGlobalSubtitle;

  /// No description provided for @paramPresetModelLocked.
  ///
  /// In en, this message translates to:
  /// **'Model presets are Pro. Global params still apply to every model.'**
  String get paramPresetModelLocked;

  /// No description provided for @personaUseCustomParams.
  ///
  /// In en, this message translates to:
  /// **'Use custom params'**
  String get personaUseCustomParams;

  /// No description provided for @personaUseCustomParamsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Override this model’s params while the persona is active'**
  String get personaUseCustomParamsSubtitle;

  /// No description provided for @personaAdjustParams.
  ///
  /// In en, this message translates to:
  /// **'Adjust params'**
  String get personaAdjustParams;

  /// No description provided for @personaAdjustParamsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Temperature, context, and other generation settings'**
  String get personaAdjustParamsSubtitle;

  /// No description provided for @premiumOnDeviceLlm.
  ///
  /// In en, this message translates to:
  /// **'On-Device Pro'**
  String get premiumOnDeviceLlm;

  /// No description provided for @premiumOnDeviceLlmTagline.
  ///
  /// In en, this message translates to:
  /// **'Bigger catalog models & HF imports'**
  String get premiumOnDeviceLlmTagline;

  /// No description provided for @premiumOnDeviceLlmDescription.
  ///
  /// In en, this message translates to:
  /// **'On-device chat is free with curated starter models. Pro unlocks catalog downloads above 2B parameters and importing your own GGUF or MLX models from Hugging Face — browse, pick a quantization, and run fully offline.'**
  String get premiumOnDeviceLlmDescription;

  /// No description provided for @premiumHfBrowse.
  ///
  /// In en, this message translates to:
  /// **'Hugging Face Import'**
  String get premiumHfBrowse;

  /// No description provided for @premiumHfBrowseTagline.
  ///
  /// In en, this message translates to:
  /// **'Bring any GGUF model onboard'**
  String get premiumHfBrowseTagline;

  /// No description provided for @premiumHfBrowseDescription.
  ///
  /// In en, this message translates to:
  /// **'Search Hugging Face, download GGUF models to your device or LM Studio server, and run them in LM Mini. Filter for compatibility, track background downloads, and expand beyond the free catalog — no API key required.'**
  String get premiumHfBrowseDescription;

  /// No description provided for @onDeviceProviderLabel.
  ///
  /// In en, this message translates to:
  /// **'On-Device'**
  String get onDeviceProviderLabel;

  /// No description provided for @onDeviceManageModels.
  ///
  /// In en, this message translates to:
  /// **'Manage On-Device Models'**
  String get onDeviceManageModels;

  /// No description provided for @onDeviceGeneratingHint.
  ///
  /// In en, this message translates to:
  /// **'Generating on-device…'**
  String get onDeviceGeneratingHint;

  /// No description provided for @onDeviceEngineUnavailable.
  ///
  /// In en, this message translates to:
  /// **'On-device engine unavailable'**
  String get onDeviceEngineUnavailable;

  /// No description provided for @onDeviceOpenBrowser.
  ///
  /// In en, this message translates to:
  /// **'Open On-Device Models'**
  String get onDeviceOpenBrowser;

  /// No description provided for @onDeviceManagedHere.
  ///
  /// In en, this message translates to:
  /// **'On-Device models are managed in a dedicated browser where you can download, remove and activate them.'**
  String get onDeviceManagedHere;

  /// No description provided for @onDeviceRemoteImageOnly.
  ///
  /// In en, this message translates to:
  /// **'On-Device AI is selected — remote access powers image generation and Kokoro voice (if configured) only. Chat stays on this device.'**
  String get onDeviceRemoteImageOnly;

  /// No description provided for @onDeviceProOnly.
  ///
  /// In en, this message translates to:
  /// **'Pro only'**
  String get onDeviceProOnly;

  /// No description provided for @onDeviceInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get onDeviceInstalled;

  /// No description provided for @onDeviceUseModel.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get onDeviceUseModel;

  /// No description provided for @onDeviceRemoveModel.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get onDeviceRemoveModel;

  /// No description provided for @onDeviceDownloadAnyway.
  ///
  /// In en, this message translates to:
  /// **'Download anyway'**
  String get onDeviceDownloadAnyway;

  /// No description provided for @onDeviceNowUsing.
  ///
  /// In en, this message translates to:
  /// **'Now using {name} on-device'**
  String onDeviceNowUsing(String name);

  /// No description provided for @onDeviceEngineFllamaLabel.
  ///
  /// In en, this message translates to:
  /// **'fllama (GGUF)'**
  String get onDeviceEngineFllamaLabel;

  /// No description provided for @onDeviceEngineSwitched.
  ///
  /// In en, this message translates to:
  /// **'Switched to {engine}. The previous model was unloaded.'**
  String onDeviceEngineSwitched(String engine);

  /// No description provided for @onDeviceEngineSwitchedCleared.
  ///
  /// In en, this message translates to:
  /// **'Switched to {engine}. Your previous model isn\'t compatible with this engine and was deselected — pick one in On-Device Models.'**
  String onDeviceEngineSwitchedCleared(String engine);

  /// No description provided for @onDeviceImportedLabel.
  ///
  /// In en, this message translates to:
  /// **'Imported'**
  String get onDeviceImportedLabel;

  /// No description provided for @onDeviceFreeLabel.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get onDeviceFreeLabel;

  /// No description provided for @onDeviceProLabel.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get onDeviceProLabel;

  /// No description provided for @onDeviceMayCrashLabel.
  ///
  /// In en, this message translates to:
  /// **'May crash'**
  String get onDeviceMayCrashLabel;

  /// No description provided for @onDeviceModelMayCrashTitle.
  ///
  /// In en, this message translates to:
  /// **'This model may crash'**
  String get onDeviceModelMayCrashTitle;

  /// No description provided for @onDeviceModelMayCrashMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} needs roughly {runtimeGb} GB of memory at runtime. Your device has about {deviceRamGb} GB available for apps. Loading anyway may freeze or crash the app.'**
  String onDeviceModelMayCrashMessage(
      String name, String runtimeGb, String deviceRamGb);

  /// No description provided for @onDeviceContinueLoading.
  ///
  /// In en, this message translates to:
  /// **'Continue loading'**
  String get onDeviceContinueLoading;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @lifetime.
  ///
  /// In en, this message translates to:
  /// **'Lifetime'**
  String get lifetime;

  /// No description provided for @subscriptionLifetimeBadge.
  ///
  /// In en, this message translates to:
  /// **'Pay once'**
  String get subscriptionLifetimeBadge;

  /// No description provided for @subscriptionLifetimeDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'One-time purchase. Pro features on your account while LM Mini is offered and maintained. Excludes third-party API fees and may exclude separately hosted services — see Terms.'**
  String get subscriptionLifetimeDisclaimer;

  /// No description provided for @subscriptionLifetimeUpgradeDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Lifetime is a separate one-time purchase. Your current subscription will not be cancelled automatically, and we cannot refund past subscription charges. After purchasing, cancel your subscription in the {store}.'**
  String subscriptionLifetimeUpgradeDisclaimer(String store);

  /// No description provided for @subscriptionUpgradeToLifetime.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Lifetime'**
  String get subscriptionUpgradeToLifetime;

  /// No description provided for @subscriptionUpgradeToLifetimeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pay once — {price}'**
  String subscriptionUpgradeToLifetimeSubtitle(String price);

  /// No description provided for @duplicateSubscriptionDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel your subscription'**
  String get duplicateSubscriptionDialogTitle;

  /// No description provided for @duplicateSubscriptionDialogBody.
  ///
  /// In en, this message translates to:
  /// **'You have Lifetime Pro and an active subscription. Lifetime does not replace your subscription automatically, and we cannot refund subscription charges. Please cancel your subscription in the {store} to avoid further billing.'**
  String duplicateSubscriptionDialogBody(String store);

  /// No description provided for @duplicateSubscriptionDialogManage.
  ///
  /// In en, this message translates to:
  /// **'Open {store}'**
  String duplicateSubscriptionDialogManage(String store);

  /// No description provided for @duplicateSubscriptionDialogDismiss.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get duplicateSubscriptionDialogDismiss;

  /// No description provided for @duplicateSubscriptionNoManageUrl.
  ///
  /// In en, this message translates to:
  /// **'Open your device subscription settings to cancel.'**
  String get duplicateSubscriptionNoManageUrl;

  /// No description provided for @supportLifetime.
  ///
  /// In en, this message translates to:
  /// **'Unlock forever — {price}'**
  String supportLifetime(String price);

  /// No description provided for @encryptionKey.
  ///
  /// In en, this message translates to:
  /// **'Encryption Key'**
  String get encryptionKey;

  /// No description provided for @encryptionEnabled.
  ///
  /// In en, this message translates to:
  /// **'Encryption: On'**
  String get encryptionEnabled;

  /// No description provided for @encryptionDisabled.
  ///
  /// In en, this message translates to:
  /// **'Encryption: Off'**
  String get encryptionDisabled;

  /// No description provided for @encryptionKeyDescription.
  ///
  /// In en, this message translates to:
  /// **'End-to-end encryption key for remote access. Must match the key in LM Mini Home on your Mac.'**
  String get encryptionKeyDescription;

  /// No description provided for @editEncryptionKey.
  ///
  /// In en, this message translates to:
  /// **'Edit Encryption Key'**
  String get editEncryptionKey;

  /// No description provided for @enterEncryptionKey.
  ///
  /// In en, this message translates to:
  /// **'Enter encryption key'**
  String get enterEncryptionKey;

  /// No description provided for @encryptionKeyUpdated.
  ///
  /// In en, this message translates to:
  /// **'Encryption key updated'**
  String get encryptionKeyUpdated;

  /// No description provided for @keepLmMiniAlive.
  ///
  /// In en, this message translates to:
  /// **'Keep LM Mini\nAlive'**
  String get keepLmMiniAlive;

  /// No description provided for @supportTheApp.
  ///
  /// In en, this message translates to:
  /// **'Support the app & get premium perks'**
  String get supportTheApp;

  /// No description provided for @mostFeaturesFree.
  ///
  /// In en, this message translates to:
  /// **'Most features are free — Pro helps cover server costs'**
  String get mostFeaturesFree;

  /// No description provided for @thankYouSupport.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your support!'**
  String get thankYouSupport;

  /// No description provided for @helpingKeepAlive.
  ///
  /// In en, this message translates to:
  /// **'You\'re helping keep LM Mini alive'**
  String get helpingKeepAlive;

  /// No description provided for @linkSignInMethod.
  ///
  /// In en, this message translates to:
  /// **'Link a sign-in method to keep your subscription if you switch devices.'**
  String get linkSignInMethod;

  /// No description provided for @paywallLinkAccountBody.
  ///
  /// In en, this message translates to:
  /// **'You\'re on an anonymous account. Link Apple or Google before purchasing so Pro syncs across devices and survives reinstall.'**
  String get paywallLinkAccountBody;

  /// No description provided for @continueAnonymously.
  ///
  /// In en, this message translates to:
  /// **'Continue anonymously'**
  String get continueAnonymously;

  /// No description provided for @signedInViaMethod.
  ///
  /// In en, this message translates to:
  /// **'Signed in via {method}'**
  String signedInViaMethod(String method);

  /// No description provided for @yourSubscriptionSecured.
  ///
  /// In en, this message translates to:
  /// **'Your subscription is secured'**
  String get yourSubscriptionSecured;

  /// No description provided for @subscriptionManagedThrough.
  ///
  /// In en, this message translates to:
  /// **'Subscription managed through the {store}.'**
  String subscriptionManagedThrough(String store);

  /// No description provided for @subscriptionsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions Coming Soon'**
  String get subscriptionsComingSoon;

  /// No description provided for @premiumPreview.
  ///
  /// In en, this message translates to:
  /// **'Premium features are being finalized.\nYou can enable developer mode below to preview them.'**
  String get premiumPreview;

  /// No description provided for @enableDeveloperPremium.
  ///
  /// In en, this message translates to:
  /// **'Enable Developer Premium'**
  String get enableDeveloperPremium;

  /// No description provided for @disableDeveloperPremium.
  ///
  /// In en, this message translates to:
  /// **'Disable Developer Premium'**
  String get disableDeveloperPremium;

  /// No description provided for @premiumEnabled.
  ///
  /// In en, this message translates to:
  /// **'Premium enabled (dev override)'**
  String get premiumEnabled;

  /// No description provided for @premiumDisabled.
  ///
  /// In en, this message translates to:
  /// **'Premium disabled'**
  String get premiumDisabled;

  /// No description provided for @supportYearly.
  ///
  /// In en, this message translates to:
  /// **'Support — {price}/year'**
  String supportYearly(String price);

  /// No description provided for @supportMonthly.
  ///
  /// In en, this message translates to:
  /// **'Support — {price}/month'**
  String supportMonthly(String price);

  /// No description provided for @welcomeToLmMiniPro.
  ///
  /// In en, this message translates to:
  /// **'Welcome to LM Mini Pro!'**
  String get welcomeToLmMiniPro;

  /// No description provided for @connectedRemotely.
  ///
  /// In en, this message translates to:
  /// **'Connected remotely'**
  String get connectedRemotely;

  /// No description provided for @pairedNotActive.
  ///
  /// In en, this message translates to:
  /// **'Paired — not active'**
  String get pairedNotActive;

  /// No description provided for @accessLmStudioAnywhere.
  ///
  /// In en, this message translates to:
  /// **'Access LM Studio from anywhere'**
  String get accessLmStudioAnywhere;

  /// No description provided for @appStore.
  ///
  /// In en, this message translates to:
  /// **'App Store'**
  String get appStore;

  /// No description provided for @googlePlayStore.
  ///
  /// In en, this message translates to:
  /// **'Google Play Store'**
  String get googlePlayStore;

  /// No description provided for @starterAttach.
  ///
  /// In en, this message translates to:
  /// **'Attach'**
  String get starterAttach;

  /// No description provided for @starterImages.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get starterImages;

  /// No description provided for @starterMode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get starterMode;

  /// No description provided for @newGroupChat.
  ///
  /// In en, this message translates to:
  /// **'New Group Chat'**
  String get newGroupChat;

  /// No description provided for @groupChat.
  ///
  /// In en, this message translates to:
  /// **'Group Chat'**
  String get groupChat;

  /// No description provided for @groupChatMultipleModels.
  ///
  /// In en, this message translates to:
  /// **'Chat with multiple models'**
  String get groupChatMultipleModels;

  /// No description provided for @groupChatParticipants.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get groupChatParticipants;

  /// No description provided for @groupChatTurnMode.
  ///
  /// In en, this message translates to:
  /// **'Turn Mode'**
  String get groupChatTurnMode;

  /// No description provided for @groupChatRoundRobin.
  ///
  /// In en, this message translates to:
  /// **'Round Robin'**
  String get groupChatRoundRobin;

  /// No description provided for @groupChatManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get groupChatManual;

  /// No description provided for @groupChatParallelStreaming.
  ///
  /// In en, this message translates to:
  /// **'Parallel Streaming'**
  String get groupChatParallelStreaming;

  /// No description provided for @groupChatAutoLoadUnload.
  ///
  /// In en, this message translates to:
  /// **'Auto Load/Unload'**
  String get groupChatAutoLoadUnload;

  /// No description provided for @groupChatStreamAllSimultaneously.
  ///
  /// In en, this message translates to:
  /// **'Stream all participants simultaneously'**
  String get groupChatStreamAllSimultaneously;

  /// No description provided for @groupChatAutoLoadModels.
  ///
  /// In en, this message translates to:
  /// **'Automatically load models when needed'**
  String get groupChatAutoLoadModels;

  /// No description provided for @groupChatAsk.
  ///
  /// In en, this message translates to:
  /// **'Ask:'**
  String get groupChatAsk;

  /// No description provided for @groupChatTapToReplyNudge.
  ///
  /// In en, this message translates to:
  /// **'Tap who should reply'**
  String get groupChatTapToReplyNudge;

  /// No description provided for @groupChatTrialBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Group Chat — Free for 7 Days!'**
  String get groupChatTrialBannerTitle;

  /// No description provided for @groupChatTrialBannerBody.
  ///
  /// In en, this message translates to:
  /// **'Try Group Chat free for 7 days with up to 2 AI personas. Upgrade to LM Mini Pro for unlimited participants and permanent access.'**
  String get groupChatTrialBannerBody;

  /// No description provided for @groupChatTrialDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{days} days left in your trial'**
  String groupChatTrialDaysLeft(int days);

  /// No description provided for @groupChatTrialExpired.
  ///
  /// In en, this message translates to:
  /// **'Your 7-day Group Chat trial has ended. Upgrade to Pro to continue.'**
  String get groupChatTrialExpired;

  /// No description provided for @groupChatTrialGetPro.
  ///
  /// In en, this message translates to:
  /// **'Get Pro'**
  String get groupChatTrialGetPro;

  /// No description provided for @groupChatTrialDismiss.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get groupChatTrialDismiss;

  /// No description provided for @groupChatBetaTitle.
  ///
  /// In en, this message translates to:
  /// **'Group Chat'**
  String get groupChatBetaTitle;

  /// No description provided for @groupChatBetaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One conversation. Multiple AI minds.'**
  String get groupChatBetaSubtitle;

  /// No description provided for @groupChatBetaPremiumNote.
  ///
  /// In en, this message translates to:
  /// **'Group Chat is currently in beta and it\'s available to everyone as a free preview'**
  String get groupChatBetaPremiumNote;

  /// No description provided for @groupChatBetaBugReport.
  ///
  /// In en, this message translates to:
  /// **'Found a bug? Go to Settings → Feature Requests & Support to report it and get priority help.'**
  String get groupChatBetaBugReport;

  /// No description provided for @groupChatBetaFreeNote.
  ///
  /// In en, this message translates to:
  /// **'You have 7 days of free access with up to 2 personas. Upgrade to Pro for unlimited personas and permanent access.'**
  String get groupChatBetaFreeNote;

  /// No description provided for @groupChatBetaFeaturePersona.
  ///
  /// In en, this message translates to:
  /// **'Each persona powered by its own model'**
  String get groupChatBetaFeaturePersona;

  /// No description provided for @groupChatBetaFeatureSystem.
  ///
  /// In en, this message translates to:
  /// **'Unique personality per system prompt'**
  String get groupChatBetaFeatureSystem;

  /// No description provided for @groupChatBetaFeatureConvo.
  ///
  /// In en, this message translates to:
  /// **'All in one shared conversation'**
  String get groupChatBetaFeatureConvo;

  /// No description provided for @groupChatBetaStartFree.
  ///
  /// In en, this message translates to:
  /// **'Start Free Trial'**
  String get groupChatBetaStartFree;

  /// No description provided for @groupChatBetaStartPremium.
  ///
  /// In en, this message translates to:
  /// **'Try Group Chat'**
  String get groupChatBetaStartPremium;

  /// No description provided for @groupChatBetaLearnMore.
  ///
  /// In en, this message translates to:
  /// **'Get Pro'**
  String get groupChatBetaLearnMore;

  /// No description provided for @premiumGroupChat.
  ///
  /// In en, this message translates to:
  /// **'Group Chat'**
  String get premiumGroupChat;

  /// No description provided for @premiumGroupChatTagline.
  ///
  /// In en, this message translates to:
  /// **'Multi-persona conversations'**
  String get premiumGroupChatTagline;

  /// No description provided for @premiumGroupChatDescription.
  ///
  /// In en, this message translates to:
  /// **'Chat with multiple AI personas in one thread — each with its own model, avatar, and personality. Set up freely; sending messages requires LM Mini Pro.'**
  String get premiumGroupChatDescription;

  /// No description provided for @groupChatProRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Group Chat requires Pro'**
  String get groupChatProRequiredTitle;

  /// No description provided for @groupChatProRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'You can set up Group Chat for free. Upgrade to LM Mini Pro to start the chat and send messages with multiple AI personas.'**
  String get groupChatProRequiredBody;

  /// No description provided for @groupChatProRequiredUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro'**
  String get groupChatProRequiredUpgrade;

  /// No description provided for @groupChatLockedBanner.
  ///
  /// In en, this message translates to:
  /// **'Group Chat is read-only without Pro. Upgrade to send new messages.'**
  String get groupChatLockedBanner;

  /// No description provided for @premiumArena.
  ///
  /// In en, this message translates to:
  /// **'Arena'**
  String get premiumArena;

  /// No description provided for @premiumArenaTagline.
  ///
  /// In en, this message translates to:
  /// **'Compare models side-by-side'**
  String get premiumArenaTagline;

  /// No description provided for @premiumArenaDescription.
  ///
  /// In en, this message translates to:
  /// **'Finding your model is free. Pro unlocks custom prompt races, cloud models in Arena, and private race history with charts.'**
  String get premiumArenaDescription;

  /// No description provided for @startLabel.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startLabel;

  /// No description provided for @groupChatInviteUpTo.
  ///
  /// In en, this message translates to:
  /// **'Invite up to {count} AI models to chat together. Each can have its own persona, avatar, and system prompt.'**
  String groupChatInviteUpTo(int count);

  /// No description provided for @groupChatPremiumParticipantsNote.
  ///
  /// In en, this message translates to:
  /// **'Premium allows up to 5 participants per group chat.'**
  String get groupChatPremiumParticipantsNote;

  /// No description provided for @groupChatUserNameHint.
  ///
  /// In en, this message translates to:
  /// **'How AIs will address you (e.g. Alex)'**
  String get groupChatUserNameHint;

  /// No description provided for @groupChatScenarioLabel.
  ///
  /// In en, this message translates to:
  /// **'Scenario / about yourself (optional)'**
  String get groupChatScenarioLabel;

  /// No description provided for @groupChatScenarioHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. \"We are colleagues at a tech startup. I am a product manager asking the team for advice.\"'**
  String get groupChatScenarioHint;

  /// No description provided for @groupChatTurnModeRoundRobinDescription.
  ///
  /// In en, this message translates to:
  /// **'Round Robin — all models respond in order'**
  String get groupChatTurnModeRoundRobinDescription;

  /// No description provided for @groupChatTurnModeManualDescription.
  ///
  /// In en, this message translates to:
  /// **'Manual — type @Name to choose who replies'**
  String get groupChatTurnModeManualDescription;

  /// No description provided for @groupChatReplyToUserOnlyLabel.
  ///
  /// In en, this message translates to:
  /// **'Reply to you only'**
  String get groupChatReplyToUserOnlyLabel;

  /// No description provided for @groupChatReplyToUserOnlySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Each AI ignores the other AIs — best for smaller models'**
  String get groupChatReplyToUserOnlySubtitle;

  /// No description provided for @groupChatWhosInChat.
  ///
  /// In en, this message translates to:
  /// **'Who\'s in the chat?'**
  String get groupChatWhosInChat;

  /// No description provided for @groupChatTapToInvite.
  ///
  /// In en, this message translates to:
  /// **'Tap people below to invite them'**
  String get groupChatTapToInvite;

  /// No description provided for @groupChatAddPeople.
  ///
  /// In en, this message translates to:
  /// **'Add people'**
  String get groupChatAddPeople;

  /// No description provided for @groupChatInTheRoom.
  ///
  /// In en, this message translates to:
  /// **'In the room'**
  String get groupChatInTheRoom;

  /// No description provided for @groupChatNeedTwo.
  ///
  /// In en, this message translates to:
  /// **'Add at least 2 to start'**
  String get groupChatNeedTwo;

  /// No description provided for @groupChatTakeTurnsTitle.
  ///
  /// In en, this message translates to:
  /// **'Take turns'**
  String get groupChatTakeTurnsTitle;

  /// No description provided for @groupChatTakeTurnsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Everyone answers in order, one after another'**
  String get groupChatTakeTurnsSubtitle;

  /// No description provided for @groupChatTalkMentionedTitle.
  ///
  /// In en, this message translates to:
  /// **'Talk when mentioned'**
  String get groupChatTalkMentionedTitle;

  /// No description provided for @groupChatTalkMentionedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'If one AI names another, that person can jump in'**
  String get groupChatTalkMentionedSubtitle;

  /// No description provided for @groupChatIChooseTitle.
  ///
  /// In en, this message translates to:
  /// **'I choose who speaks'**
  String get groupChatIChooseTitle;

  /// No description provided for @groupChatIChooseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only the person you @mention replies'**
  String get groupChatIChooseSubtitle;

  /// No description provided for @groupChatHowTheyTalk.
  ///
  /// In en, this message translates to:
  /// **'How they talk'**
  String get groupChatHowTheyTalk;

  /// No description provided for @groupChatAboutYou.
  ///
  /// In en, this message translates to:
  /// **'About you'**
  String get groupChatAboutYou;

  /// No description provided for @groupChatSceneLabel.
  ///
  /// In en, this message translates to:
  /// **'Scene (optional)'**
  String get groupChatSceneLabel;

  /// No description provided for @groupChatSceneHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. We\'re coworkers brainstorming a product idea'**
  String get groupChatSceneHint;

  /// No description provided for @groupChatAutoLoadTitle.
  ///
  /// In en, this message translates to:
  /// **'Save memory on local models'**
  String get groupChatAutoLoadTitle;

  /// No description provided for @groupChatAutoLoadSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unload one model before loading the next — helpful when people use different LM Studio, Ollama, or on-device models'**
  String get groupChatAutoLoadSubtitle;

  /// No description provided for @groupChatMoreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get groupChatMoreOptions;

  /// No description provided for @groupChatHelpTooltip.
  ///
  /// In en, this message translates to:
  /// **'How Group Chat works'**
  String get groupChatHelpTooltip;

  /// No description provided for @groupChatHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'How Group Chat works'**
  String get groupChatHelpTitle;

  /// No description provided for @groupChatHelpIntro.
  ///
  /// In en, this message translates to:
  /// **'Invite at least two AI people into one conversation. Each can use a different model and personality.'**
  String get groupChatHelpIntro;

  /// No description provided for @groupChatHelpTakeTurns.
  ///
  /// In en, this message translates to:
  /// **'Take turns: every AI answers your message in order.'**
  String get groupChatHelpTakeTurns;

  /// No description provided for @groupChatHelpMentioned.
  ///
  /// In en, this message translates to:
  /// **'Talk when mentioned: after someone replies, another AI can continue if they were named.'**
  String get groupChatHelpMentioned;

  /// No description provided for @groupChatHelpManual.
  ///
  /// In en, this message translates to:
  /// **'I choose who speaks: use @Name so only that person replies.'**
  String get groupChatHelpManual;

  /// No description provided for @groupChatHelpMemory.
  ///
  /// In en, this message translates to:
  /// **'Save memory: for local models, unload the previous model before loading the next so phones and PCs with less RAM can still run a group.'**
  String get groupChatHelpMemory;

  /// No description provided for @groupChatHelpProvider.
  ///
  /// In en, this message translates to:
  /// **'Tap a person in the room to change their provider and model anytime.'**
  String get groupChatHelpProvider;

  /// No description provided for @groupChatStartProGate.
  ///
  /// In en, this message translates to:
  /// **'Pro needed to start'**
  String get groupChatStartProGate;

  /// No description provided for @groupChatFixBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'Fix the highlighted people before starting.'**
  String get groupChatFixBeforeStart;

  /// No description provided for @groupChatEditPerson.
  ///
  /// In en, this message translates to:
  /// **'Edit person'**
  String get groupChatEditPerson;

  /// No description provided for @groupChatProviderAndModel.
  ///
  /// In en, this message translates to:
  /// **'Provider & model'**
  String get groupChatProviderAndModel;

  /// No description provided for @groupChatChooseProviderModel.
  ///
  /// In en, this message translates to:
  /// **'Choose provider & model'**
  String get groupChatChooseProviderModel;

  /// No description provided for @groupChatParallelEasy.
  ///
  /// In en, this message translates to:
  /// **'Reply at the same time'**
  String get groupChatParallelEasy;

  /// No description provided for @groupChatParallelEasySubtitle.
  ///
  /// In en, this message translates to:
  /// **'When more than one AI should answer, stream them together'**
  String get groupChatParallelEasySubtitle;

  /// No description provided for @noModelsAvailableConnectLmStudio.
  ///
  /// In en, this message translates to:
  /// **'No models available. Connect to LM Studio first.'**
  String get noModelsAvailableConnectLmStudio;

  /// No description provided for @addModelLabel.
  ///
  /// In en, this message translates to:
  /// **'Add Model'**
  String get addModelLabel;

  /// No description provided for @modelNumber.
  ///
  /// In en, this message translates to:
  /// **'Model {number}'**
  String modelNumber(int number);

  /// No description provided for @groupChatParticipantInfo.
  ///
  /// In en, this message translates to:
  /// **'{name}\nModel: {model}'**
  String groupChatParticipantInfo(String name, String model);

  /// No description provided for @customPromptSet.
  ///
  /// In en, this message translates to:
  /// **'Custom prompt set'**
  String get customPromptSet;

  /// No description provided for @removeLabel.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeLabel;

  /// No description provided for @displayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayNameLabel;

  /// No description provided for @displayNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Professor, Coder, Artist'**
  String get displayNameHint;

  /// No description provided for @customRequestHeaders.
  ///
  /// In en, this message translates to:
  /// **'Custom request headers'**
  String get customRequestHeaders;

  /// No description provided for @customRequestHeadersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optional headers added to every LM Studio request'**
  String get customRequestHeadersSubtitle;

  /// No description provided for @customRequestHeadersHelp.
  ///
  /// In en, this message translates to:
  /// **'Use this for reverse proxies or auth gateways that require extra headers (e.g. Cloudflare Access service tokens, an internal token under a custom header name, etc.). Headers are sent on every request to your LM Studio server.'**
  String get customRequestHeadersHelp;

  /// No description provided for @cloudflareAccessSection.
  ///
  /// In en, this message translates to:
  /// **'Cloudflare Access (service token)'**
  String get cloudflareAccessSection;

  /// No description provided for @cloudflareAccessHelp.
  ///
  /// In en, this message translates to:
  /// **'If your LM Studio is behind a Cloudflare Access policy, paste the service-token Client ID and Secret here. They are sent as CF-Access-Client-Id and CF-Access-Client-Secret on every request, so the app can authenticate without an interactive browser SSO login.'**
  String get cloudflareAccessHelp;

  /// No description provided for @cfAccessClientIdLabel.
  ///
  /// In en, this message translates to:
  /// **'CF-Access-Client-Id'**
  String get cfAccessClientIdLabel;

  /// No description provided for @cfAccessClientSecretLabel.
  ///
  /// In en, this message translates to:
  /// **'CF-Access-Client-Secret'**
  String get cfAccessClientSecretLabel;

  /// No description provided for @addHeader.
  ///
  /// In en, this message translates to:
  /// **'Add header'**
  String get addHeader;

  /// No description provided for @removeHeader.
  ///
  /// In en, this message translates to:
  /// **'Remove header'**
  String get removeHeader;

  /// No description provided for @headerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Header name'**
  String get headerNameLabel;

  /// No description provided for @headerValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Header value'**
  String get headerValueLabel;

  /// No description provided for @headersConfigured.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 header configured} other{{count} headers configured}}'**
  String headersConfigured(int count);

  /// No description provided for @noCustomHeaders.
  ///
  /// In en, this message translates to:
  /// **'No custom headers'**
  String get noCustomHeaders;

  /// No description provided for @comfyUiUseNegativePromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Use negative prompt'**
  String get comfyUiUseNegativePromptTitle;

  /// No description provided for @comfyUiUseNegativePromptSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Off by default for ComfyUI. When off, no negative prompt is sent to the workflow.'**
  String get comfyUiUseNegativePromptSubtitle;

  /// No description provided for @documentationTitle.
  ///
  /// In en, this message translates to:
  /// **'Documentation'**
  String get documentationTitle;

  /// No description provided for @documentationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Setup guides for Group Chat, ComfyUI, keyboard behavior, and more'**
  String get documentationSubtitle;

  /// No description provided for @changelogTitle.
  ///
  /// In en, this message translates to:
  /// **'Changelog'**
  String get changelogTitle;

  /// No description provided for @changelogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Version history & updates'**
  String get changelogSubtitle;

  /// No description provided for @enableCustomHeaders.
  ///
  /// In en, this message translates to:
  /// **'Enable custom headers'**
  String get enableCustomHeaders;

  /// No description provided for @enableCustomHeadersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Attach extra HTTP headers to every LM Studio request'**
  String get enableCustomHeadersSubtitle;

  /// No description provided for @deleteMemoriesCount.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} memories?'**
  String deleteMemoriesCount(int count);

  /// No description provided for @deleteMemoriesConfirm.
  ///
  /// In en, this message translates to:
  /// **'These memories will be removed for good.'**
  String get deleteMemoriesConfirm;

  /// No description provided for @moveToCategory.
  ///
  /// In en, this message translates to:
  /// **'Move to category'**
  String get moveToCategory;

  /// No description provided for @nSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String nSelected(int count);

  /// No description provided for @movedToCategory.
  ///
  /// In en, this message translates to:
  /// **'Moved to {category}'**
  String movedToCategory(String category);

  /// No description provided for @moveCategoryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Move category'**
  String get moveCategoryTooltip;

  /// No description provided for @memoryScreenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Facts the AI keeps in mind about you across chats.'**
  String get memoryScreenSubtitle;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMe;

  /// No description provided for @rememberMeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use saved notes in future conversations'**
  String get rememberMeSubtitle;

  /// No description provided for @memoryPerPersona.
  ///
  /// In en, this message translates to:
  /// **'Keep private notes separate'**
  String get memoryPerPersona;

  /// No description provided for @memoryPerPersonaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Notes marked private stay with their persona. Character notes are always kept separate.'**
  String get memoryPerPersonaSubtitle;

  /// No description provided for @memoryOnDeviceExtraction.
  ///
  /// In en, this message translates to:
  /// **'Learn memories on-device'**
  String get memoryOnDeviceExtraction;

  /// No description provided for @memoryOnDeviceExtractionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let the local model extract facts too. Uses extra battery.'**
  String get memoryOnDeviceExtractionSubtitle;

  /// No description provided for @memoryScopeGlobal.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get memoryScopeGlobal;

  /// No description provided for @memoryScopeGlobalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Available in every chat'**
  String get memoryScopeGlobalSubtitle;

  /// No description provided for @memoryScopePrivate.
  ///
  /// In en, this message translates to:
  /// **'Private to persona'**
  String get memoryScopePrivate;

  /// No description provided for @memoryScopePrivateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A fact about you that only this persona sees'**
  String get memoryScopePrivateSubtitle;

  /// No description provided for @memoryScopeLore.
  ///
  /// In en, this message translates to:
  /// **'Character notes'**
  String get memoryScopeLore;

  /// No description provided for @memoryScopeLoreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Roleplay details for this character, never treated as facts about you'**
  String get memoryScopeLoreSubtitle;

  /// No description provided for @memoryVisibility.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get memoryVisibility;

  /// No description provided for @memoryChangeVisibility.
  ///
  /// In en, this message translates to:
  /// **'Change visibility'**
  String get memoryChangeVisibility;

  /// No description provided for @memoryScopeFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get memoryScopeFilterAll;

  /// No description provided for @memoryOrphaned.
  ///
  /// In en, this message translates to:
  /// **'Orphaned'**
  String get memoryOrphaned;

  /// No description provided for @memoryOrphanedHint.
  ///
  /// In en, this message translates to:
  /// **'These notes belong to a persona that no longer exists, so no chat can see them. Repair them to bring them back.'**
  String get memoryOrphanedHint;

  /// No description provided for @memoryMakeGlobal.
  ///
  /// In en, this message translates to:
  /// **'Make available to everyone'**
  String get memoryMakeGlobal;

  /// No description provided for @memorySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search notes'**
  String get memorySearchHint;

  /// No description provided for @memoryNoSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No notes match \"{query}\"'**
  String memoryNoSearchResults(String query);

  /// No description provided for @memoryPickPersona.
  ///
  /// In en, this message translates to:
  /// **'Choose a persona'**
  String get memoryPickPersona;

  /// No description provided for @memoryMovedToScope.
  ///
  /// In en, this message translates to:
  /// **'Moved to {scope}'**
  String memoryMovedToScope(String scope);

  /// No description provided for @memoryCountForPersona.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No memories} =1{1 memory} other{{count} memories}}'**
  String memoryCountForPersona(int count);

  /// No description provided for @personaMemoryWriteScope.
  ///
  /// In en, this message translates to:
  /// **'Save new memories as'**
  String get personaMemoryWriteScope;

  /// No description provided for @personaMemoryWriteScopeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Where facts learned in this persona\'s chats are filed'**
  String get personaMemoryWriteScopeSubtitle;

  /// No description provided for @memoryBrowseSection.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get memoryBrowseSection;

  /// No description provided for @memoryMultiSelectTip.
  ///
  /// In en, this message translates to:
  /// **'Tip: long-press a note to select several.'**
  String get memoryMultiSelectTip;

  /// No description provided for @memoryEmptyFilteredHint.
  ///
  /// In en, this message translates to:
  /// **'Add a note, or pick another category.'**
  String get memoryEmptyFilteredHint;

  /// No description provided for @memoryEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Save a few things about yourself — name, preferences, projects — so chats feel personal.'**
  String get memoryEmptyHint;

  /// No description provided for @memoryShareWith.
  ///
  /// In en, this message translates to:
  /// **'Share with'**
  String get memoryShareWith;

  /// No description provided for @memoryEveryone.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get memoryEveryone;

  /// No description provided for @memoryEveryoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Available in every chat'**
  String get memoryEveryoneSubtitle;

  /// No description provided for @memoryNoPersonasHint.
  ///
  /// In en, this message translates to:
  /// **'No personas yet. Create one in Settings → Personas.'**
  String get memoryNoPersonasHint;

  /// No description provided for @memoryNewNote.
  ///
  /// In en, this message translates to:
  /// **'New note'**
  String get memoryNewNote;

  /// No description provided for @memoryNoteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. I prefer short answers and live in Berlin'**
  String get memoryNoteHint;

  /// No description provided for @memoryEditNote.
  ///
  /// In en, this message translates to:
  /// **'Edit note'**
  String get memoryEditNote;

  /// No description provided for @monthsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}mo ago'**
  String monthsAgo(int count);

  /// No description provided for @moreTooltip.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreTooltip;

  /// No description provided for @closeSearch.
  ///
  /// In en, this message translates to:
  /// **'Close search'**
  String get closeSearch;

  /// No description provided for @moveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get moveTooltip;

  /// No description provided for @chatsTab.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chatsTab;

  /// No description provided for @groupsTab.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groupsTab;

  /// No description provided for @foldersTooltip.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get foldersTooltip;

  /// No description provided for @newFolder.
  ///
  /// In en, this message translates to:
  /// **'New folder'**
  String get newFolder;

  /// No description provided for @tapToReturnToCall.
  ///
  /// In en, this message translates to:
  /// **'Tap to return to call'**
  String get tapToReturnToCall;

  /// No description provided for @selectConversation.
  ///
  /// In en, this message translates to:
  /// **'Select a conversation'**
  String get selectConversation;

  /// No description provided for @selectConversationHint.
  ///
  /// In en, this message translates to:
  /// **'Pick one from the list, or start a new chat.'**
  String get selectConversationHint;

  /// No description provided for @noGroupChatsYet.
  ///
  /// In en, this message translates to:
  /// **'No group chats yet'**
  String get noGroupChatsYet;

  /// No description provided for @noGroupChatsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start a multi-persona conversation to chat with several AIs together.'**
  String get noGroupChatsSubtitle;

  /// No description provided for @newPersonaShort.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newPersonaShort;

  /// No description provided for @downloadOnDeviceModelTitle.
  ///
  /// In en, this message translates to:
  /// **'Download an on-device model'**
  String get downloadOnDeviceModelTitle;

  /// No description provided for @downloadOnDeviceModelBody.
  ///
  /// In en, this message translates to:
  /// **'Download a model to chat without a PC, or connect LM Studio / Ollama.'**
  String get downloadOnDeviceModelBody;

  /// No description provided for @browseModels.
  ///
  /// In en, this message translates to:
  /// **'Browse models'**
  String get browseModels;

  /// No description provided for @waitingForMac.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Mac'**
  String get waitingForMac;

  /// No description provided for @waitingForMacBody.
  ///
  /// In en, this message translates to:
  /// **'Connect your iPhone to your Mac with a USB cable, then open LM Mini on Mac and enable Share with phone (USB bridge).'**
  String get waitingForMacBody;

  /// No description provided for @arenaMode.
  ///
  /// In en, this message translates to:
  /// **'Arena mode'**
  String get arenaMode;

  /// No description provided for @voiceWhisperSizeInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Bigger models hear better'**
  String get voiceWhisperSizeInfoTitle;

  /// No description provided for @voiceWhisperSizeInfoBody.
  ///
  /// In en, this message translates to:
  /// **'Larger listening models are usually more accurate, especially with accents and background noise. They also use more storage and may load a bit slower.'**
  String get voiceWhisperSizeInfoBody;

  /// No description provided for @voiceRemoveListeningModelTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove listening model?'**
  String get voiceRemoveListeningModelTitle;

  /// No description provided for @voiceRemoveListeningModelBody.
  ///
  /// In en, this message translates to:
  /// **'This frees storage. Voice Call and the mic will need the model again before offline listening works.'**
  String get voiceRemoveListeningModelBody;

  /// No description provided for @voiceTtsOnDeviceNeural.
  ///
  /// In en, this message translates to:
  /// **'Downloaded voice'**
  String get voiceTtsOnDeviceNeural;

  /// No description provided for @voiceTtsPcVoice.
  ///
  /// In en, this message translates to:
  /// **'PC voice'**
  String get voiceTtsPcVoice;

  /// No description provided for @voiceTtsSystemVoice.
  ///
  /// In en, this message translates to:
  /// **'System voice'**
  String get voiceTtsSystemVoice;

  /// No description provided for @voiceTtsOnDeviceHint.
  ///
  /// In en, this message translates to:
  /// **'Natural voices you download. Works without internet.'**
  String get voiceTtsOnDeviceHint;

  /// No description provided for @voiceTtsPcHint.
  ///
  /// In en, this message translates to:
  /// **'Use a voice model on your computer via Share with phone'**
  String get voiceTtsPcHint;

  /// No description provided for @voiceTtsSystemHint.
  ///
  /// In en, this message translates to:
  /// **'Your phone\'s voices — ready now'**
  String get voiceTtsSystemHint;

  /// No description provided for @voiceSttOnDevice.
  ///
  /// In en, this message translates to:
  /// **'On this device'**
  String get voiceSttOnDevice;

  /// No description provided for @voiceSttWhisperHint.
  ///
  /// In en, this message translates to:
  /// **'Offline model — usually more accurate'**
  String get voiceSttWhisperHint;

  /// No description provided for @voiceSttSystemHint.
  ///
  /// In en, this message translates to:
  /// **'Built-in recognition — quick and simple'**
  String get voiceSttSystemHint;

  /// No description provided for @voiceSttSystemUnavailableOnMac.
  ///
  /// In en, this message translates to:
  /// **'Needs download'**
  String get voiceSttSystemUnavailableOnMac;

  /// No description provided for @voiceSttMacosRequiresWhisper.
  ///
  /// In en, this message translates to:
  /// **'App Store builds use on-device Whisper for listening. Download a model to enable it.'**
  String get voiceSttMacosRequiresWhisper;

  /// No description provided for @voiceSttMacosSystemOptionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Download Whisper to enable listening'**
  String get voiceSttMacosSystemOptionSubtitle;

  /// No description provided for @voiceSttMacosDownloadWhisper.
  ///
  /// In en, this message translates to:
  /// **'Download Whisper to enable listening'**
  String get voiceSttMacosDownloadWhisper;

  /// No description provided for @voiceSettingsIntro.
  ///
  /// In en, this message translates to:
  /// **'How replies are spoken, and how your voice is understood.'**
  String get voiceSettingsIntro;

  /// No description provided for @voiceSectionReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get voiceSectionReady;

  /// No description provided for @voiceSectionSpeaking.
  ///
  /// In en, this message translates to:
  /// **'Speaking'**
  String get voiceSectionSpeaking;

  /// No description provided for @voiceSectionListening.
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get voiceSectionListening;

  /// No description provided for @voiceSectionConversation.
  ///
  /// In en, this message translates to:
  /// **'Conversation'**
  String get voiceSectionConversation;

  /// No description provided for @voiceStatusSpeaking.
  ///
  /// In en, this message translates to:
  /// **'Speaking'**
  String get voiceStatusSpeaking;

  /// No description provided for @voiceStatusListening.
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get voiceStatusListening;

  /// No description provided for @voiceHowISpeak.
  ///
  /// In en, this message translates to:
  /// **'How I speak'**
  String get voiceHowISpeak;

  /// No description provided for @voiceImportPack.
  ///
  /// In en, this message translates to:
  /// **'Import voice pack'**
  String get voiceImportPack;

  /// No description provided for @voiceImportPackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Paste a GitHub URL to a voice pack'**
  String get voiceImportPackSubtitle;

  /// No description provided for @voiceHowIHearYou.
  ///
  /// In en, this message translates to:
  /// **'How I hear you'**
  String get voiceHowIHearYou;

  /// No description provided for @voiceHowIHearYouSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how your speech is turned into text.'**
  String get voiceHowIHearYouSubtitle;

  /// No description provided for @voiceListeningModel.
  ///
  /// In en, this message translates to:
  /// **'Listening model'**
  String get voiceListeningModel;

  /// No description provided for @voiceAboutModelSizes.
  ///
  /// In en, this message translates to:
  /// **'About model sizes'**
  String get voiceAboutModelSizes;

  /// No description provided for @voicePauseBeforeSend.
  ///
  /// In en, this message translates to:
  /// **'Pause before send'**
  String get voicePauseBeforeSend;

  /// No description provided for @voicePauseBeforeSendSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How long to wait after you stop talking'**
  String get voicePauseBeforeSendSubtitle;

  /// No description provided for @voiceListeningLimit.
  ///
  /// In en, this message translates to:
  /// **'Listening limit'**
  String get voiceListeningLimit;

  /// No description provided for @voiceListeningLimitSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Longest stretch before the mic restarts'**
  String get voiceListeningLimitSubtitle;

  /// No description provided for @voiceQuickTip.
  ///
  /// In en, this message translates to:
  /// **'Quick tip'**
  String get voiceQuickTip;

  /// No description provided for @voiceQuickTipBody.
  ///
  /// In en, this message translates to:
  /// **'For a more natural voice, download a language under Voice packs. System voice works right away.'**
  String get voiceQuickTipBody;

  /// No description provided for @voiceTestSampleHint.
  ///
  /// In en, this message translates to:
  /// **'Hear a short sample with your current settings'**
  String get voiceTestSampleHint;

  /// No description provided for @voiceTestNoPackReady.
  ///
  /// In en, this message translates to:
  /// **'Download a language under Voice packs, then try Test Voice.'**
  String get voiceTestNoPackReady;

  /// No description provided for @voiceChooseListeningModel.
  ///
  /// In en, this message translates to:
  /// **'Tap to choose a listening model'**
  String get voiceChooseListeningModel;

  /// No description provided for @voiceModelReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get voiceModelReady;

  /// No description provided for @voiceNeedsDownload.
  ///
  /// In en, this message translates to:
  /// **'Needs download'**
  String get voiceNeedsDownload;

  /// No description provided for @voiceDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get voiceDownloaded;

  /// No description provided for @voiceDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get voiceDownloadFailed;

  /// No description provided for @voiceFinishingSetup.
  ///
  /// In en, this message translates to:
  /// **'Finishing setup…'**
  String get voiceFinishingSetup;

  /// No description provided for @voiceDownloadingListeningModel.
  ///
  /// In en, this message translates to:
  /// **'Downloading listening model…'**
  String get voiceDownloadingListeningModel;

  /// No description provided for @voiceDownloadingVoice.
  ///
  /// In en, this message translates to:
  /// **'Downloading voice…'**
  String get voiceDownloadingVoice;

  /// No description provided for @voiceStartingDownload.
  ///
  /// In en, this message translates to:
  /// **'Starting download…'**
  String get voiceStartingDownload;

  /// No description provided for @voiceReady.
  ///
  /// In en, this message translates to:
  /// **'Voice ready'**
  String get voiceReady;

  /// No description provided for @voiceWarmingUp.
  ///
  /// In en, this message translates to:
  /// **'Warming up…'**
  String get voiceWarmingUp;

  /// No description provided for @voiceReadyToSpeak.
  ///
  /// In en, this message translates to:
  /// **'Ready to speak'**
  String get voiceReadyToSpeak;

  /// No description provided for @voiceDownloadOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Download on-device voice'**
  String get voiceDownloadOnDevice;

  /// No description provided for @voiceDownloadFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Download failed — tap to try again'**
  String get voiceDownloadFailedRetry;

  /// No description provided for @voiceSpokenReplyLanguage.
  ///
  /// In en, this message translates to:
  /// **'Spoken reply language'**
  String get voiceSpokenReplyLanguage;

  /// No description provided for @voiceSpokenReplyLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Language used when the assistant reads messages aloud.'**
  String get voiceSpokenReplyLanguageSubtitle;

  /// No description provided for @voiceRecognitionLanguage.
  ///
  /// In en, this message translates to:
  /// **'Recognition language'**
  String get voiceRecognitionLanguage;

  /// No description provided for @voiceRecognitionLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Used for the text mic and Voice Call — can differ from spoken replies.'**
  String get voiceRecognitionLanguageSubtitle;

  /// No description provided for @voiceEngineTitle.
  ///
  /// In en, this message translates to:
  /// **'Speaking voice'**
  String get voiceEngineTitle;

  /// No description provided for @voiceEngineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose where the spoken voice comes from.'**
  String get voiceEngineSubtitle;

  /// No description provided for @voiceChooseAVoice.
  ///
  /// In en, this message translates to:
  /// **'Choose a voice'**
  String get voiceChooseAVoice;

  /// No description provided for @voiceChooseAVoiceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Preview-friendly names for on-device speech.'**
  String get voiceChooseAVoiceSubtitle;

  /// No description provided for @voiceUseSystemDefault.
  ///
  /// In en, this message translates to:
  /// **'Use the system default voice'**
  String get voiceUseSystemDefault;

  /// No description provided for @welcomeWizardTitleGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get welcomeWizardTitleGetStarted;

  /// No description provided for @welcomeWizardTitleYourSetup.
  ///
  /// In en, this message translates to:
  /// **'Your setup'**
  String get welcomeWizardTitleYourSetup;

  /// No description provided for @welcomeWizardTitleLookAndFeel.
  ///
  /// In en, this message translates to:
  /// **'Look & feel'**
  String get welcomeWizardTitleLookAndFeel;

  /// No description provided for @welcomeWizardTitleAlmostDone.
  ///
  /// In en, this message translates to:
  /// **'Almost done'**
  String get welcomeWizardTitleAlmostDone;

  /// No description provided for @welcomeWizardTitleSetup.
  ///
  /// In en, this message translates to:
  /// **'Setup'**
  String get welcomeWizardTitleSetup;

  /// No description provided for @welcomeWizardLmStudioSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Run models on your Mac or PC'**
  String get welcomeWizardLmStudioSubtitle;

  /// No description provided for @welcomeWizardOllamaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Popular local server'**
  String get welcomeWizardOllamaSubtitle;

  /// No description provided for @welcomeWizardOmlxSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Apple Silicon desktop server'**
  String get welcomeWizardOmlxSubtitle;

  /// No description provided for @welcomeWizardJanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Local models from the JAN AI app'**
  String get welcomeWizardJanSubtitle;

  /// No description provided for @welcomeWizardUnslothSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unsloth Desktop on your computer'**
  String get welcomeWizardUnslothSubtitle;

  /// No description provided for @welcomeWizardThemeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a look you like. You can change this anytime.'**
  String get welcomeWizardThemeSubtitle;

  /// No description provided for @welcomeWizardModelReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get welcomeWizardModelReady;

  /// No description provided for @welcomeWizardConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get welcomeWizardConnected;

  /// No description provided for @welcomeWizardServerFound.
  ///
  /// In en, this message translates to:
  /// **'Server found'**
  String get welcomeWizardServerFound;

  /// No description provided for @welcomeWizardRequiresApiKey.
  ///
  /// In en, this message translates to:
  /// **'Requires API Key'**
  String get welcomeWizardRequiresApiKey;

  /// No description provided for @welcomeWizardScanHomeQr.
  ///
  /// In en, this message translates to:
  /// **'Scan LM Mini Home QR'**
  String get welcomeWizardScanHomeQr;

  /// No description provided for @welcomeWizardScanHomeQrSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pair with your Mac from Share with phone'**
  String get welcomeWizardScanHomeQrSubtitle;

  /// No description provided for @welcomeWizardModelsFound.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 model found} other{{count} models found}}'**
  String welcomeWizardModelsFound(int count);

  /// No description provided for @welcomeWizardLocalNetworkTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow network access'**
  String get welcomeWizardLocalNetworkTitle;

  /// No description provided for @welcomeWizardLocalNetworkBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ll be asked to allow local network access. Please allow it so LM Mini can find LM Mini Home, LM Studio, or Ollama running on your computer.'**
  String get welcomeWizardLocalNetworkBody;

  /// No description provided for @welcomeWizardLocalNetworkAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get welcomeWizardLocalNetworkAllow;

  /// No description provided for @welcomeWizardDownloadKeepsGoing.
  ///
  /// In en, this message translates to:
  /// **'You can leave this screen — the download keeps going, even if you leave the app.'**
  String get welcomeWizardDownloadKeepsGoing;

  /// No description provided for @welcomeWizardDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed. Tap to retry.'**
  String get welcomeWizardDownloadFailed;

  /// No description provided for @welcomeWizardAiDownloadingTitle.
  ///
  /// In en, this message translates to:
  /// **'AI is downloading'**
  String get welcomeWizardAiDownloadingTitle;

  /// No description provided for @welcomeWizardAiDownloadingBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ll be able to chat as soon as the perfect AI for your phone is ready. This is a one-time download.'**
  String get welcomeWizardAiDownloadingBody;

  /// No description provided for @onDeviceModels.
  ///
  /// In en, this message translates to:
  /// **'On-Device Models'**
  String get onDeviceModels;

  /// No description provided for @transcription.
  ///
  /// In en, this message translates to:
  /// **'Transcription'**
  String get transcription;

  /// No description provided for @widgetSettings.
  ///
  /// In en, this message translates to:
  /// **'Widget Settings'**
  String get widgetSettings;

  /// No description provided for @widgetSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure home screen widgets'**
  String get widgetSettingsSubtitle;

  /// No description provided for @setUpShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Set up Shortcuts'**
  String get setUpShortcuts;

  /// No description provided for @shareArenaSpeedResults.
  ///
  /// In en, this message translates to:
  /// **'Share Arena speed results'**
  String get shareArenaSpeedResults;

  /// No description provided for @browseOnDeviceModels.
  ///
  /// In en, this message translates to:
  /// **'Browse on-device models'**
  String get browseOnDeviceModels;

  /// No description provided for @homeDownloadModel.
  ///
  /// In en, this message translates to:
  /// **'Download model'**
  String get homeDownloadModel;

  /// No description provided for @usbMode.
  ///
  /// In en, this message translates to:
  /// **'USB Mode'**
  String get usbMode;

  /// No description provided for @usbModeHowItWorks.
  ///
  /// In en, this message translates to:
  /// **'How USB Mode works'**
  String get usbModeHowItWorks;

  /// No description provided for @switchToUsbTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch from Remote to USB?'**
  String get switchToUsbTitle;

  /// No description provided for @switchLabel.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get switchLabel;

  /// No description provided for @usbModeStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start USB Mode: {error}'**
  String usbModeStartFailed(String error);

  /// No description provided for @usbModeHowToUse.
  ///
  /// In en, this message translates to:
  /// **'How to use:'**
  String get usbModeHowToUse;

  /// No description provided for @openLmminiCom.
  ///
  /// In en, this message translates to:
  /// **'Open lmmini.com'**
  String get openLmminiCom;

  /// No description provided for @tapToUseServer.
  ///
  /// In en, this message translates to:
  /// **'Tap to use this server'**
  String get tapToUseServer;

  /// No description provided for @memoryPersonaFallback.
  ///
  /// In en, this message translates to:
  /// **'Persona'**
  String get memoryPersonaFallback;

  /// No description provided for @voicePickSystemVoiceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a built-in voice for spoken replies.'**
  String get voicePickSystemVoiceSubtitle;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// No description provided for @galleryLimitsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Photos up to 10 MB · Videos up to 200 MB'**
  String get galleryLimitsSubtitle;

  /// No description provided for @recordVideo.
  ///
  /// In en, this message translates to:
  /// **'Record a video'**
  String get recordVideo;

  /// No description provided for @attachmentsCount.
  ///
  /// In en, this message translates to:
  /// **'Attachments ({count}/{max})'**
  String attachmentsCount(int count, int max);

  /// No description provided for @viewProfile.
  ///
  /// In en, this message translates to:
  /// **'View profile'**
  String get viewProfile;

  /// No description provided for @personaAndModel.
  ///
  /// In en, this message translates to:
  /// **'Persona & model'**
  String get personaAndModel;

  /// No description provided for @chatOptions.
  ///
  /// In en, this message translates to:
  /// **'Chat options'**
  String get chatOptions;

  /// No description provided for @chatTab.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatTab;

  /// No description provided for @voiceTab.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get voiceTab;

  /// No description provided for @craftingPersona.
  ///
  /// In en, this message translates to:
  /// **'Crafting persona…'**
  String get craftingPersona;

  /// No description provided for @randomPersona.
  ///
  /// In en, this message translates to:
  /// **'Surprise me'**
  String get randomPersona;

  /// No description provided for @savePersona.
  ///
  /// In en, this message translates to:
  /// **'Save persona'**
  String get savePersona;

  /// No description provided for @downloadFinished.
  ///
  /// In en, this message translates to:
  /// **'Download finished.'**
  String get downloadFinished;

  /// No description provided for @downloadCancelled.
  ///
  /// In en, this message translates to:
  /// **'Download cancelled.'**
  String get downloadCancelled;

  /// No description provided for @downloadCancelFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t cancel in LM Studio. Stop it in LM Studio\'s Downloads list.'**
  String get downloadCancelFailed;

  /// No description provided for @newsBriefing.
  ///
  /// In en, this message translates to:
  /// **'News briefing'**
  String get newsBriefing;

  /// No description provided for @refreshNow.
  ///
  /// In en, this message translates to:
  /// **'Refresh now'**
  String get refreshNow;

  /// No description provided for @noBriefingYet.
  ///
  /// In en, this message translates to:
  /// **'No briefing yet'**
  String get noBriefingYet;

  /// No description provided for @newsSetPromptFirst.
  ///
  /// In en, this message translates to:
  /// **'Set a News widget prompt in Widget Settings first.'**
  String get newsSetPromptFirst;

  /// No description provided for @newsRefreshed.
  ///
  /// In en, this message translates to:
  /// **'News refreshed.'**
  String get newsRefreshed;

  /// No description provided for @newsRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Refresh failed: {error}'**
  String newsRefreshFailed(String error);

  /// No description provided for @themesTitle.
  ///
  /// In en, this message translates to:
  /// **'Themes'**
  String get themesTitle;

  /// No description provided for @createLabel.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get createLabel;

  /// No description provided for @browseLabel.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get browseLabel;

  /// No description provided for @signInToUploadThemes.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to upload themes'**
  String get signInToUploadThemes;

  /// No description provided for @deleteThemeTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete theme?'**
  String get deleteThemeTitle;

  /// No description provided for @deleteThemeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{name}\" from your downloaded themes?'**
  String deleteThemeConfirm(String name);

  /// No description provided for @uploadToCommunity.
  ///
  /// In en, this message translates to:
  /// **'Upload to community'**
  String get uploadToCommunity;

  /// No description provided for @installedLabel.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get installedLabel;

  /// No description provided for @getLabel.
  ///
  /// In en, this message translates to:
  /// **'Get'**
  String get getLabel;

  /// No description provided for @bestForYou.
  ///
  /// In en, this message translates to:
  /// **'Best for you'**
  String get bestForYou;

  /// No description provided for @loadingLabel.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loadingLabel;

  /// No description provided for @loadedLabel.
  ///
  /// In en, this message translates to:
  /// **'Loaded'**
  String get loadedLabel;

  /// No description provided for @notLoadedLabel.
  ///
  /// In en, this message translates to:
  /// **'Not loaded'**
  String get notLoadedLabel;

  /// No description provided for @reasoningLabel.
  ///
  /// In en, this message translates to:
  /// **'Reasoning'**
  String get reasoningLabel;

  /// No description provided for @imagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get imagesLabel;

  /// No description provided for @detailsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detailsTooltip;

  /// No description provided for @transcribeAudio.
  ///
  /// In en, this message translates to:
  /// **'Transcribe audio'**
  String get transcribeAudio;

  /// No description provided for @transcribeAudioSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload audio and ask AI about the transcript'**
  String get transcribeAudioSubtitle;

  /// No description provided for @trimSection.
  ///
  /// In en, this message translates to:
  /// **'Trim section'**
  String get trimSection;

  /// No description provided for @includeTimestamps.
  ///
  /// In en, this message translates to:
  /// **'Include timestamps'**
  String get includeTimestamps;

  /// No description provided for @phrasesLabel.
  ///
  /// In en, this message translates to:
  /// **'Phrases'**
  String get phrasesLabel;

  /// No description provided for @wordsLabel.
  ///
  /// In en, this message translates to:
  /// **'Words'**
  String get wordsLabel;

  /// No description provided for @transcriptionLanguage.
  ///
  /// In en, this message translates to:
  /// **'Transcription language'**
  String get transcriptionLanguage;

  /// No description provided for @searchLanguages.
  ///
  /// In en, this message translates to:
  /// **'Search languages…'**
  String get searchLanguages;

  /// No description provided for @transcribe.
  ///
  /// In en, this message translates to:
  /// **'Transcribe'**
  String get transcribe;

  /// No description provided for @shareTranscript.
  ///
  /// In en, this message translates to:
  /// **'Share transcript'**
  String get shareTranscript;

  /// No description provided for @transcriptionContextLargeToast.
  ///
  /// In en, this message translates to:
  /// **'These transcripts may be too large for the model\'s context. Branch from an earlier message if answers get incomplete.'**
  String get transcriptionContextLargeToast;

  /// No description provided for @transcriptionSubtitlesOn.
  ///
  /// In en, this message translates to:
  /// **'Subtitles on'**
  String get transcriptionSubtitlesOn;

  /// No description provided for @transcriptionSubtitlesOff.
  ///
  /// In en, this message translates to:
  /// **'Subtitles off'**
  String get transcriptionSubtitlesOff;

  /// No description provided for @transcriptionFullClip.
  ///
  /// In en, this message translates to:
  /// **'Full clip'**
  String get transcriptionFullClip;

  /// No description provided for @transcriptionJobRunning.
  ///
  /// In en, this message translates to:
  /// **'Transcribing…'**
  String get transcriptionJobRunning;

  /// No description provided for @transcriptionJobDone.
  ///
  /// In en, this message translates to:
  /// **'Transcribed'**
  String get transcriptionJobDone;

  /// No description provided for @transcriptionJobFailed.
  ///
  /// In en, this message translates to:
  /// **'Transcription failed'**
  String get transcriptionJobFailed;

  /// No description provided for @branchFromHere.
  ///
  /// In en, this message translates to:
  /// **'Branch from here'**
  String get branchFromHere;

  /// No description provided for @memoryUpdates.
  ///
  /// In en, this message translates to:
  /// **'Memory Updates'**
  String get memoryUpdates;

  /// No description provided for @promptWriteEmail.
  ///
  /// In en, this message translates to:
  /// **'Write an email'**
  String get promptWriteEmail;

  /// No description provided for @promptWriteEmailBody.
  ///
  /// In en, this message translates to:
  /// **'Help me write a clear, friendly email to '**
  String get promptWriteEmailBody;

  /// No description provided for @promptGiveIdeas.
  ///
  /// In en, this message translates to:
  /// **'Give me ideas'**
  String get promptGiveIdeas;

  /// No description provided for @promptGiveIdeasBody.
  ///
  /// In en, this message translates to:
  /// **'Brainstorm creative ideas with me about '**
  String get promptGiveIdeasBody;

  /// No description provided for @promptExplainSimply.
  ///
  /// In en, this message translates to:
  /// **'Explain simply'**
  String get promptExplainSimply;

  /// No description provided for @promptExplainSimplyBody.
  ///
  /// In en, this message translates to:
  /// **'Explain this in simple words: '**
  String get promptExplainSimplyBody;

  /// No description provided for @promptFixWriting.
  ///
  /// In en, this message translates to:
  /// **'Fix my writing'**
  String get promptFixWriting;

  /// No description provided for @promptFixWritingBody.
  ///
  /// In en, this message translates to:
  /// **'Improve this writing for clarity and tone:\n\n'**
  String get promptFixWritingBody;

  /// No description provided for @promptHelpStudy.
  ///
  /// In en, this message translates to:
  /// **'Help me study'**
  String get promptHelpStudy;

  /// No description provided for @promptHelpStudyBody.
  ///
  /// In en, this message translates to:
  /// **'Help me study this topic: '**
  String get promptHelpStudyBody;

  /// No description provided for @promptPlanTrip.
  ///
  /// In en, this message translates to:
  /// **'Plan a trip'**
  String get promptPlanTrip;

  /// No description provided for @promptPlanTripBody.
  ///
  /// In en, this message translates to:
  /// **'Help me plan a trip to '**
  String get promptPlanTripBody;

  /// No description provided for @promptSummarize.
  ///
  /// In en, this message translates to:
  /// **'Summarize this'**
  String get promptSummarize;

  /// No description provided for @promptSummarizeBody.
  ///
  /// In en, this message translates to:
  /// **'Summarize this clearly:\n\n'**
  String get promptSummarizeBody;

  /// No description provided for @promptChecklist.
  ///
  /// In en, this message translates to:
  /// **'Make a checklist'**
  String get promptChecklist;

  /// No description provided for @promptChecklistBody.
  ///
  /// In en, this message translates to:
  /// **'Make a practical checklist for '**
  String get promptChecklistBody;

  /// No description provided for @promptFunFact.
  ///
  /// In en, this message translates to:
  /// **'Tell me a fun fact'**
  String get promptFunFact;

  /// No description provided for @promptFunFactBody.
  ///
  /// In en, this message translates to:
  /// **'Tell me a fun fact about '**
  String get promptFunFactBody;

  /// No description provided for @promptQuizMe.
  ///
  /// In en, this message translates to:
  /// **'Quiz me'**
  String get promptQuizMe;

  /// No description provided for @promptQuizMeBody.
  ///
  /// In en, this message translates to:
  /// **'Quiz me on '**
  String get promptQuizMeBody;

  /// No description provided for @promptRoleplay.
  ///
  /// In en, this message translates to:
  /// **'Roleplay with me'**
  String get promptRoleplay;

  /// No description provided for @promptRoleplayBody.
  ///
  /// In en, this message translates to:
  /// **'Let\'s roleplay. You are '**
  String get promptRoleplayBody;

  /// No description provided for @promptCodeHelp.
  ///
  /// In en, this message translates to:
  /// **'Code help'**
  String get promptCodeHelp;

  /// No description provided for @promptCodeHelpBody.
  ///
  /// In en, this message translates to:
  /// **'Help me with this code problem:\n\n'**
  String get promptCodeHelpBody;

  /// No description provided for @promptDraftReply.
  ///
  /// In en, this message translates to:
  /// **'Draft a reply'**
  String get promptDraftReply;

  /// No description provided for @promptDraftReplyBody.
  ///
  /// In en, this message translates to:
  /// **'Draft a polite reply to this:\n\n'**
  String get promptDraftReplyBody;

  /// No description provided for @promptPracticeInterview.
  ///
  /// In en, this message translates to:
  /// **'Practice interview'**
  String get promptPracticeInterview;

  /// No description provided for @promptPracticeInterviewBody.
  ///
  /// In en, this message translates to:
  /// **'Practice interview questions for '**
  String get promptPracticeInterviewBody;

  /// No description provided for @promptMealIdeas.
  ///
  /// In en, this message translates to:
  /// **'Meal ideas'**
  String get promptMealIdeas;

  /// No description provided for @promptMealIdeasBody.
  ///
  /// In en, this message translates to:
  /// **'Suggest meal ideas using '**
  String get promptMealIdeasBody;

  /// No description provided for @promptWorkoutPlan.
  ///
  /// In en, this message translates to:
  /// **'Workout plan'**
  String get promptWorkoutPlan;

  /// No description provided for @promptWorkoutPlanBody.
  ///
  /// In en, this message translates to:
  /// **'Create a simple workout plan for '**
  String get promptWorkoutPlanBody;

  /// No description provided for @promptTranslateCasually.
  ///
  /// In en, this message translates to:
  /// **'Translate casually'**
  String get promptTranslateCasually;

  /// No description provided for @promptTranslateCasuallyBody.
  ///
  /// In en, this message translates to:
  /// **'Translate this casually:\n\n'**
  String get promptTranslateCasuallyBody;

  /// No description provided for @promptNameIdeas.
  ///
  /// In en, this message translates to:
  /// **'Name ideas'**
  String get promptNameIdeas;

  /// No description provided for @promptNameIdeasBody.
  ///
  /// In en, this message translates to:
  /// **'Brainstorm name ideas for '**
  String get promptNameIdeasBody;

  /// No description provided for @promptProsCons.
  ///
  /// In en, this message translates to:
  /// **'Pros and cons'**
  String get promptProsCons;

  /// No description provided for @promptProsConsBody.
  ///
  /// In en, this message translates to:
  /// **'List pros and cons of '**
  String get promptProsConsBody;

  /// No description provided for @promptRewriteShorter.
  ///
  /// In en, this message translates to:
  /// **'Rewrite shorter'**
  String get promptRewriteShorter;

  /// No description provided for @promptRewriteShorterBody.
  ///
  /// In en, this message translates to:
  /// **'Rewrite this shorter and clearer:\n\n'**
  String get promptRewriteShorterBody;

  /// No description provided for @promptTeachVocab.
  ///
  /// In en, this message translates to:
  /// **'Teach me vocab'**
  String get promptTeachVocab;

  /// No description provided for @promptTeachVocabBody.
  ///
  /// In en, this message translates to:
  /// **'Teach me useful vocabulary about '**
  String get promptTeachVocabBody;

  /// No description provided for @promptStoryTime.
  ///
  /// In en, this message translates to:
  /// **'Story time'**
  String get promptStoryTime;

  /// No description provided for @promptStoryTimeBody.
  ///
  /// In en, this message translates to:
  /// **'Tell a short story about '**
  String get promptStoryTimeBody;

  /// No description provided for @promptDebugWithMe.
  ///
  /// In en, this message translates to:
  /// **'Debug with me'**
  String get promptDebugWithMe;

  /// No description provided for @promptDebugWithMeBody.
  ///
  /// In en, this message translates to:
  /// **'Help me debug this:\n\n'**
  String get promptDebugWithMeBody;

  /// No description provided for @promptDailyMotivation.
  ///
  /// In en, this message translates to:
  /// **'Daily motivation'**
  String get promptDailyMotivation;

  /// No description provided for @promptDailyMotivationBody.
  ///
  /// In en, this message translates to:
  /// **'Give me a short motivational nudge about '**
  String get promptDailyMotivationBody;

  /// No description provided for @promptPlayDnd.
  ///
  /// In en, this message translates to:
  /// **'Play DnD'**
  String get promptPlayDnd;

  /// No description provided for @promptPlayDndBody.
  ///
  /// In en, this message translates to:
  /// **'Let\'s play a short D&D adventure. I am '**
  String get promptPlayDndBody;

  /// No description provided for @promptWordChain.
  ///
  /// In en, this message translates to:
  /// **'Word chain'**
  String get promptWordChain;

  /// No description provided for @promptWordChainBody.
  ///
  /// In en, this message translates to:
  /// **'Let\'s play word chain. Start with: '**
  String get promptWordChainBody;

  /// No description provided for @promptRiddleDuel.
  ///
  /// In en, this message translates to:
  /// **'Riddle duel'**
  String get promptRiddleDuel;

  /// No description provided for @promptRiddleDuelBody.
  ///
  /// In en, this message translates to:
  /// **'Give me a riddle to solve.'**
  String get promptRiddleDuelBody;

  /// No description provided for @promptWouldYouRather.
  ///
  /// In en, this message translates to:
  /// **'Would you rather'**
  String get promptWouldYouRather;

  /// No description provided for @promptWouldYouRatherBody.
  ///
  /// In en, this message translates to:
  /// **'Ask me a fun would-you-rather question.'**
  String get promptWouldYouRatherBody;

  /// No description provided for @promptEscapeRoom.
  ///
  /// In en, this message translates to:
  /// **'Escape room'**
  String get promptEscapeRoom;

  /// No description provided for @promptEscapeRoomBody.
  ///
  /// In en, this message translates to:
  /// **'Start a short text escape-room puzzle for me.'**
  String get promptEscapeRoomBody;

  /// No description provided for @promptTriviaBattle.
  ///
  /// In en, this message translates to:
  /// **'Trivia battle'**
  String get promptTriviaBattle;

  /// No description provided for @promptTriviaBattleBody.
  ///
  /// In en, this message translates to:
  /// **'Quiz me with trivia about '**
  String get promptTriviaBattleBody;

  /// No description provided for @promptStoryRpg.
  ///
  /// In en, this message translates to:
  /// **'Story RPG'**
  String get promptStoryRpg;

  /// No description provided for @promptStoryRpgBody.
  ///
  /// In en, this message translates to:
  /// **'Start a short story RPG. My character is '**
  String get promptStoryRpgBody;

  /// No description provided for @promptGuessNumber.
  ///
  /// In en, this message translates to:
  /// **'Guess the number'**
  String get promptGuessNumber;

  /// No description provided for @promptGuessNumberBody.
  ///
  /// In en, this message translates to:
  /// **'Let\'s play guess the number. Think of a number between 1 and 100.'**
  String get promptGuessNumberBody;

  /// No description provided for @promptTwoTruths.
  ///
  /// In en, this message translates to:
  /// **'Two truths one lie'**
  String get promptTwoTruths;

  /// No description provided for @promptTwoTruthsBody.
  ///
  /// In en, this message translates to:
  /// **'Let\'s play two truths and a lie. You go first.'**
  String get promptTwoTruthsBody;

  /// No description provided for @promptReadMyFile.
  ///
  /// In en, this message translates to:
  /// **'Read my file'**
  String get promptReadMyFile;

  /// No description provided for @promptWhatIsImage.
  ///
  /// In en, this message translates to:
  /// **'What is this image'**
  String get promptWhatIsImage;

  /// No description provided for @promptTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get promptTakePhoto;

  /// No description provided for @promptTranscribeAudio.
  ///
  /// In en, this message translates to:
  /// **'Transcribe audio'**
  String get promptTranscribeAudio;

  /// No description provided for @promptPersonaGenerator.
  ///
  /// In en, this message translates to:
  /// **'Persona Generator'**
  String get promptPersonaGenerator;

  /// No description provided for @personaShareMemoryCategoriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Categories to share'**
  String get personaShareMemoryCategoriesLabel;

  /// No description provided for @personaShareMemoryCategoriesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose which kinds of memories this persona can use in chats.'**
  String get personaShareMemoryCategoriesSubtitle;

  /// No description provided for @chooseFaceForBubbles.
  ///
  /// In en, this message translates to:
  /// **'Choose face for bubbles'**
  String get chooseFaceForBubbles;

  /// No description provided for @moveMemories.
  ///
  /// In en, this message translates to:
  /// **'Move memories'**
  String get moveMemories;

  /// No description provided for @deletePersonaAndMemories.
  ///
  /// In en, this message translates to:
  /// **'Delete persona + memories'**
  String get deletePersonaAndMemories;

  /// No description provided for @moveMemoriesTo.
  ///
  /// In en, this message translates to:
  /// **'Move memories to…'**
  String get moveMemoriesTo;

  /// No description provided for @globalSharedMemories.
  ///
  /// In en, this message translates to:
  /// **'Global (shared with all personas)'**
  String get globalSharedMemories;

  /// No description provided for @personaMemoriesAssignedHint.
  ///
  /// In en, this message translates to:
  /// **'{count} memory item(s) are assigned to \"{name}\".\nChoose what should happen to them:'**
  String personaMemoriesAssignedHint(int count, String name);

  /// No description provided for @homeSyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep chats in sync?'**
  String get homeSyncTitle;

  /// No description provided for @homeSyncBodyBoth.
  ///
  /// In en, this message translates to:
  /// **'This phone has {phoneChats} chats and LM Mini Home has {macChats}. Enable sync to merge conversations and folders so you can continue on either device. Uses your existing encrypted relay.'**
  String homeSyncBodyBoth(int phoneChats, int macChats);

  /// No description provided for @homeSyncBodyPhoneOnly.
  ///
  /// In en, this message translates to:
  /// **'Copy chats and folders from this phone to LM Mini Home, then keep them in sync over your encrypted relay.'**
  String get homeSyncBodyPhoneOnly;

  /// No description provided for @homeSyncBodyMacOnly.
  ///
  /// In en, this message translates to:
  /// **'Bring chats and folders from LM Mini Home onto this phone, then keep them in sync over your encrypted relay.'**
  String get homeSyncBodyMacOnly;

  /// No description provided for @homeSyncBodyGeneric.
  ///
  /// In en, this message translates to:
  /// **'Merge conversations and folders between this phone and LM Mini Home so you can continue on either device. Uses your existing encrypted relay.'**
  String get homeSyncBodyGeneric;

  /// No description provided for @homeSyncEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable sync'**
  String get homeSyncEnable;

  /// No description provided for @homeSyncNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get homeSyncNotNow;

  /// No description provided for @homeSyncSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync chats with Home'**
  String get homeSyncSettingsTitle;

  /// No description provided for @homeSyncSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Copy chats and folders between this phone and your Mac'**
  String get homeSyncSettingsSubtitle;

  /// No description provided for @homeSyncMergedToast.
  ///
  /// In en, this message translates to:
  /// **'Chats and folders are now in sync'**
  String get homeSyncMergedToast;

  /// No description provided for @homeSyncFailedToast.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sync. Open Share with phone on your Mac and try again.'**
  String get homeSyncFailedToast;

  /// No description provided for @homeSyncPersonasTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync personas'**
  String get homeSyncPersonasTitle;

  /// No description provided for @homeSyncPersonasSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Copy the ones you pick, including photos and memories'**
  String get homeSyncPersonasSubtitle;

  /// No description provided for @homeSyncPersonasPickTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose personas'**
  String get homeSyncPersonasPickTitle;

  /// No description provided for @homeSyncPersonasPickSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Checked personas copy between this device and Home, with their photo and memories.'**
  String get homeSyncPersonasPickSubtitle;

  /// No description provided for @homeSyncPersonasSave.
  ///
  /// In en, this message translates to:
  /// **'Save and sync'**
  String get homeSyncPersonasSave;

  /// No description provided for @homeSyncPersonasSavedToast.
  ///
  /// In en, this message translates to:
  /// **'Personas are now in sync'**
  String get homeSyncPersonasSavedToast;

  /// No description provided for @homeSyncPersonasEmpty.
  ///
  /// In en, this message translates to:
  /// **'No personas to copy yet.'**
  String get homeSyncPersonasEmpty;

  /// No description provided for @homeSyncPersonasUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach Home. Open Share with phone on your Mac, then try again.'**
  String get homeSyncPersonasUnreachable;

  /// No description provided for @homeSyncPersonasOnBoth.
  ///
  /// In en, this message translates to:
  /// **'On both devices'**
  String get homeSyncPersonasOnBoth;

  /// No description provided for @homeSyncPersonasOnHome.
  ///
  /// In en, this message translates to:
  /// **'LM Mini Home'**
  String get homeSyncPersonasOnHome;

  /// No description provided for @homeSyncPersonasOnPhone.
  ///
  /// In en, this message translates to:
  /// **'your phone'**
  String get homeSyncPersonasOnPhone;

  /// No description provided for @homeSyncPersonasThisPhone.
  ///
  /// In en, this message translates to:
  /// **'this phone'**
  String get homeSyncPersonasThisPhone;

  /// No description provided for @homeSyncPersonasOnDevice.
  ///
  /// In en, this message translates to:
  /// **'On {device}'**
  String homeSyncPersonasOnDevice(String device);

  /// No description provided for @homeSyncPersonasMemoryCount.
  ///
  /// In en, this message translates to:
  /// **'{count} memories'**
  String homeSyncPersonasMemoryCount(int count);

  /// No description provided for @homeSyncPersonasNoMemories.
  ///
  /// In en, this message translates to:
  /// **'No memories yet'**
  String get homeSyncPersonasNoMemories;

  /// No description provided for @reportToSupport.
  ///
  /// In en, this message translates to:
  /// **'Send to support'**
  String get reportToSupport;

  /// No description provided for @localhostConnectionHelp.
  ///
  /// In en, this message translates to:
  /// **'Can\'t connect to localhost. On a phone or tablet, localhost means this device — not your computer. In Settings, use your computer\'s IP address instead (for example http://192.168.1.10:1234) and keep both on the same Wi‑Fi.'**
  String get localhostConnectionHelp;

  /// No description provided for @lmStudioPcNotAllowingTitle.
  ///
  /// In en, this message translates to:
  /// **'Your PC is not allowing connections'**
  String get lmStudioPcNotAllowingTitle;

  /// No description provided for @lmStudioPcNotAllowingBody.
  ///
  /// In en, this message translates to:
  /// **'In LM Studio on your computer, open Developer → Server Settings and turn on Serve on Local Network.'**
  String get lmStudioPcNotAllowingBody;

  /// No description provided for @lmStudioHostDownTitle.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach your PC'**
  String get lmStudioHostDownTitle;

  /// No description provided for @lmStudioHostDownStep1.
  ///
  /// In en, this message translates to:
  /// **'Make sure the computer is on — not asleep or shut down.'**
  String get lmStudioHostDownStep1;

  /// No description provided for @lmStudioHostDownStep2.
  ///
  /// In en, this message translates to:
  /// **'In LM Studio, open Developer → Server Settings and turn on Serve on Local Network.'**
  String get lmStudioHostDownStep2;

  /// No description provided for @cantReachMacTitle.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach your Mac'**
  String get cantReachMacTitle;

  /// No description provided for @cantReachMacStep1.
  ///
  /// In en, this message translates to:
  /// **'Open Share with phone in LM Mini Home on your Mac.'**
  String get cantReachMacStep1;

  /// No description provided for @cantReachMacStep2.
  ///
  /// In en, this message translates to:
  /// **'Wait until it says Connected, then try again.'**
  String get cantReachMacStep2;

  /// No description provided for @lmStudioServerSettingsImageLabel.
  ///
  /// In en, this message translates to:
  /// **'LM Studio Developer → Server Settings. Serve on Local Network should be on.'**
  String get lmStudioServerSettingsImageLabel;

  /// No description provided for @modelMissingTitle.
  ///
  /// In en, this message translates to:
  /// **'This model isn\'t on your PC'**
  String get modelMissingTitle;

  /// No description provided for @modelMissingBody.
  ///
  /// In en, this message translates to:
  /// **'The selected model isn\'t available. Pick another from Model Selection.'**
  String get modelMissingBody;

  /// No description provided for @modelMissingBodyNamed.
  ///
  /// In en, this message translates to:
  /// **'“{model}” isn\'t on your computer. Pick another from Model Selection.'**
  String modelMissingBodyNamed(String model);

  /// No description provided for @outputTokensExhaustedTitle.
  ///
  /// In en, this message translates to:
  /// **'The model ran out of output tokens'**
  String get outputTokensExhaustedTitle;

  /// No description provided for @outputTokensExhaustedBody.
  ///
  /// In en, this message translates to:
  /// **'There weren\'t enough output tokens left to write a reply. Increase max tokens and try again.'**
  String get outputTokensExhaustedBody;

  /// No description provided for @thinkingBudgetRetryTitle.
  ///
  /// In en, this message translates to:
  /// **'Thinking used the output limit'**
  String get thinkingBudgetRetryTitle;

  /// No description provided for @thinkingBudgetRetryBody.
  ///
  /// In en, this message translates to:
  /// **'High thinking filled the output limit, so this reply uses low thinking. Raise max tokens to keep high thinking.'**
  String get thinkingBudgetRetryBody;

  /// No description provided for @adjustMaxTokens.
  ///
  /// In en, this message translates to:
  /// **'Adjust max tokens'**
  String get adjustMaxTokens;

  /// No description provided for @ggmlSchedulerCrashBody.
  ///
  /// In en, this message translates to:
  /// **'The model server crashed (llama.cpp scheduler). This isn\'t Mini. Lower context length and max tokens — very large values (for example 128k context) often cause this.'**
  String get ggmlSchedulerCrashBody;

  /// No description provided for @generationTerminatedBody.
  ///
  /// In en, this message translates to:
  /// **'LM Studio stopped the generation on your computer (the process was terminated).'**
  String get generationTerminatedBody;

  /// No description provided for @generationTerminatedHugeImageBody.
  ///
  /// In en, this message translates to:
  /// **'LM Studio stopped the generation on your computer. Your attached image is probably huge ({size}) — compress it and resend.'**
  String generationTerminatedHugeImageBody(String size);

  /// No description provided for @compressAndResendImages.
  ///
  /// In en, this message translates to:
  /// **'Compress image and resend'**
  String get compressAndResendImages;

  /// No description provided for @imageCompressFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t shrink the attached image. Try a smaller photo.'**
  String get imageCompressFailed;

  /// No description provided for @droppedChatBodyHelp.
  ///
  /// In en, this message translates to:
  /// **'Mini sent this chat, but it never reached LM Studio. If you run a proxy, tunnel, or extra URL in front of LM Studio, try without it — or point Mini straight at LM Studio (your computer\'s IP, USB, or Connect).'**
  String get droppedChatBodyHelp;

  /// No description provided for @comfyUiNoCheckpointsTitle.
  ///
  /// In en, this message translates to:
  /// **'ComfyUI has no image model'**
  String get comfyUiNoCheckpointsTitle;

  /// No description provided for @comfyUiNoCheckpointsBody.
  ///
  /// In en, this message translates to:
  /// **'ComfyUI has no checkpoint to load. Add a .safetensors file to ComfyUI’s models/checkpoints folder, then pick it in Image Generation settings.'**
  String get comfyUiNoCheckpointsBody;

  /// No description provided for @comfyUiNoCheckpointSelectedBody.
  ///
  /// In en, this message translates to:
  /// **'No image model is selected. Open Image Generation settings and pick a checkpoint.'**
  String get comfyUiNoCheckpointSelectedBody;

  /// No description provided for @comfyUiUnknownCheckpointBody.
  ///
  /// In en, this message translates to:
  /// **'ComfyUI doesn’t have checkpoint “{name}”. Pick another in Image Generation settings.'**
  String comfyUiUnknownCheckpointBody(String name);

  /// No description provided for @comfyUiWorkflowRejectedBody.
  ///
  /// In en, this message translates to:
  /// **'ComfyUI rejected the workflow. Check Image Generation settings.'**
  String get comfyUiWorkflowRejectedBody;

  /// No description provided for @comfyUiDiffusionOnlyTitle.
  ///
  /// In en, this message translates to:
  /// **'This graph needs your ComfyUI workflow'**
  String get comfyUiDiffusionOnlyTitle;

  /// No description provided for @comfyUiDiffusionOnlyBody.
  ///
  /// In en, this message translates to:
  /// **'Mini’s built-in workflow loads a classic SD checkpoint. Your Comfy Desktop graph uses a diffusion model (UNET) plus CLIP and VAE. Export it as API Format (Workflow → Export) and pick that file under Image Generation.'**
  String get comfyUiDiffusionOnlyBody;

  /// No description provided for @openImageSettings.
  ///
  /// In en, this message translates to:
  /// **'Image settings'**
  String get openImageSettings;

  /// No description provided for @imageGenUnreachableTitle.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach {name}'**
  String imageGenUnreachableTitle(String name);

  /// No description provided for @imageGenUnreachableBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing is answering at {url}. Start {name} on your computer and stay on the same Wi‑Fi.'**
  String imageGenUnreachableBody(String name, String url);

  /// No description provided for @imageGenUnreachableNoUrlBody.
  ///
  /// In en, this message translates to:
  /// **'No image generation server is set. Add ComfyUI or AUTOMATIC1111 in Image Generation settings.'**
  String get imageGenUnreachableNoUrlBody;

  /// No description provided for @sharedHostUpdateImageTitle.
  ///
  /// In en, this message translates to:
  /// **'Update image generation too?'**
  String get sharedHostUpdateImageTitle;

  /// No description provided for @sharedHostUpdateChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Update {name} too?'**
  String sharedHostUpdateChatTitle(String name);

  /// No description provided for @sharedHostUpdateBody.
  ///
  /// In en, this message translates to:
  /// **'{changedName} and {peerName} were both on {oldHost}. Update {peerName} to {newUrl}?'**
  String sharedHostUpdateBody(
      String changedName, String peerName, String oldHost, String newUrl);

  /// No description provided for @sharedHostUpdateConfirm.
  ///
  /// In en, this message translates to:
  /// **'Update and test'**
  String get sharedHostUpdateConfirm;

  /// No description provided for @sharedHostUpdateSkip.
  ///
  /// In en, this message translates to:
  /// **'Keep current'**
  String get sharedHostUpdateSkip;

  /// No description provided for @sharedHostTesting.
  ///
  /// In en, this message translates to:
  /// **'Testing {name}…'**
  String sharedHostTesting(String name);

  /// No description provided for @sharedHostTestSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get sharedHostTestSuccessTitle;

  /// No description provided for @sharedHostTestSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'Reached {name} at {url}.'**
  String sharedHostTestSuccessBody(String name, String url);

  /// No description provided for @sharedHostTestFailTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t connect'**
  String get sharedHostTestFailTitle;

  /// No description provided for @sharedHostTestFailBody.
  ///
  /// In en, this message translates to:
  /// **'Updated {name} to {url}, but Mini couldn\'t reach it. {error}'**
  String sharedHostTestFailBody(String name, String url, String error);

  /// No description provided for @supportTicketTitle.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get supportTicketTitle;

  /// No description provided for @supportTicketPrefillDescription.
  ///
  /// In en, this message translates to:
  /// **'A log file with the error details is attached. Add anything else that might help:'**
  String get supportTicketPrefillDescription;

  /// No description provided for @supportTicketSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Thanks — your report was sent.'**
  String get supportTicketSubmitted;

  /// No description provided for @supportTicketAlreadyOpen.
  ///
  /// In en, this message translates to:
  /// **'You already have an open report for this error.'**
  String get supportTicketAlreadyOpen;

  /// No description provided for @supportTicketViewExisting.
  ///
  /// In en, this message translates to:
  /// **'View report'**
  String get supportTicketViewExisting;

  /// No description provided for @supportTicketAlreadySending.
  ///
  /// In en, this message translates to:
  /// **'This error is already being reported.'**
  String get supportTicketAlreadySending;

  /// No description provided for @supportUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Support isn\'t available right now. Try again when you\'re online.'**
  String get supportUnavailable;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @uncaughtErrorSnack.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get uncaughtErrorSnack;

  /// No description provided for @errorLogLabel.
  ///
  /// In en, this message translates to:
  /// **'LOG'**
  String get errorLogLabel;

  /// No description provided for @appLock.
  ///
  /// In en, this message translates to:
  /// **'App Lock'**
  String get appLock;

  /// No description provided for @appLockSubtitleOff.
  ///
  /// In en, this message translates to:
  /// **'Require a PIN after the app is closed'**
  String get appLockSubtitleOff;

  /// No description provided for @appLockSubtitleOn.
  ///
  /// In en, this message translates to:
  /// **'Asks again after {duration}'**
  String appLockSubtitleOn(String duration);

  /// No description provided for @appLockUnlockTitle.
  ///
  /// In en, this message translates to:
  /// **'LM Mini is locked'**
  String get appLockUnlockTitle;

  /// No description provided for @appLockDescription.
  ///
  /// In en, this message translates to:
  /// **'Protect chats on this device with a numeric PIN and optional Face ID. The PIN stays on this device and is never synced.'**
  String get appLockDescription;

  /// No description provided for @appLockEnable.
  ///
  /// In en, this message translates to:
  /// **'Lock with PIN'**
  String get appLockEnable;

  /// No description provided for @appLockEnableSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ask for your PIN when you return'**
  String get appLockEnableSubtitle;

  /// No description provided for @appLockPinLength4.
  ///
  /// In en, this message translates to:
  /// **'4 digits'**
  String get appLockPinLength4;

  /// No description provided for @appLockPinLength6.
  ///
  /// In en, this message translates to:
  /// **'6 digits'**
  String get appLockPinLength6;

  /// No description provided for @appLockRequireAfter.
  ///
  /// In en, this message translates to:
  /// **'Ask again after'**
  String get appLockRequireAfter;

  /// No description provided for @appLockTimeoutImmediate.
  ///
  /// In en, this message translates to:
  /// **'Immediately'**
  String get appLockTimeoutImmediate;

  /// No description provided for @appLockTimeout15s.
  ///
  /// In en, this message translates to:
  /// **'15 seconds'**
  String get appLockTimeout15s;

  /// No description provided for @appLockTimeout1m.
  ///
  /// In en, this message translates to:
  /// **'1 minute'**
  String get appLockTimeout1m;

  /// No description provided for @appLockTimeout5m.
  ///
  /// In en, this message translates to:
  /// **'5 minutes'**
  String get appLockTimeout5m;

  /// No description provided for @appLockTimeout15m.
  ///
  /// In en, this message translates to:
  /// **'15 minutes'**
  String get appLockTimeout15m;

  /// No description provided for @appLockTimeout1h.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get appLockTimeout1h;

  /// No description provided for @appLockChangePin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get appLockChangePin;

  /// No description provided for @appLockEnterCurrentPin.
  ///
  /// In en, this message translates to:
  /// **'Enter current PIN'**
  String get appLockEnterCurrentPin;

  /// No description provided for @appLockChooseNewPin.
  ///
  /// In en, this message translates to:
  /// **'Choose a PIN'**
  String get appLockChooseNewPin;

  /// No description provided for @appLockConfirmPin.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get appLockConfirmPin;

  /// No description provided for @appLockPinsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'PINs didn’t match. Try again.'**
  String get appLockPinsDontMatch;

  /// No description provided for @appLockWrongPin.
  ///
  /// In en, this message translates to:
  /// **'Wrong PIN. Try again.'**
  String get appLockWrongPin;

  /// No description provided for @appLockTooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again in {seconds}s.'**
  String appLockTooManyAttempts(int seconds);

  /// No description provided for @appLockForgotHint.
  ///
  /// In en, this message translates to:
  /// **'If you forget your PIN, you can reset it with a verification email sent to your signed-in account. Sign in before you lose the PIN, or you won’t be able to recover it.'**
  String get appLockForgotHint;

  /// No description provided for @appLockProRequired.
  ///
  /// In en, this message translates to:
  /// **'App Lock is a Pro feature'**
  String get appLockProRequired;

  /// No description provided for @appLockEnabledToast.
  ///
  /// In en, this message translates to:
  /// **'App Lock is on'**
  String get appLockEnabledToast;

  /// No description provided for @appLockDisabledToast.
  ///
  /// In en, this message translates to:
  /// **'App Lock is off'**
  String get appLockDisabledToast;

  /// No description provided for @appLockChangedToast.
  ///
  /// In en, this message translates to:
  /// **'PIN updated'**
  String get appLockChangedToast;

  /// No description provided for @appLockBiometricsToggle.
  ///
  /// In en, this message translates to:
  /// **'Unlock with {method}'**
  String appLockBiometricsToggle(String method);

  /// No description provided for @appLockBiometricsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use Face ID, Touch ID, or a fingerprint instead of your PIN.'**
  String get appLockBiometricsSubtitle;

  /// No description provided for @appLockBiometricFaceId.
  ///
  /// In en, this message translates to:
  /// **'Face ID'**
  String get appLockBiometricFaceId;

  /// No description provided for @appLockBiometricFace.
  ///
  /// In en, this message translates to:
  /// **'Face unlock'**
  String get appLockBiometricFace;

  /// No description provided for @appLockBiometricTouchId.
  ///
  /// In en, this message translates to:
  /// **'Touch ID'**
  String get appLockBiometricTouchId;

  /// No description provided for @appLockBiometricFingerprint.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint'**
  String get appLockBiometricFingerprint;

  /// No description provided for @appLockBiometricGeneric.
  ///
  /// In en, this message translates to:
  /// **'biometrics'**
  String get appLockBiometricGeneric;

  /// No description provided for @appLockUnlockWithBiometrics.
  ///
  /// In en, this message translates to:
  /// **'Unlock with {method}'**
  String appLockUnlockWithBiometrics(String method);

  /// No description provided for @appLockBiometricsFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t unlock with {method}. Use your PIN.'**
  String appLockBiometricsFailed(String method);

  /// No description provided for @appLockSignInToRecover.
  ///
  /// In en, this message translates to:
  /// **'Sign in, or you won’t be able to recover App Lock if this PIN is lost.'**
  String get appLockSignInToRecover;

  /// No description provided for @appLockSignInToRecoverBound.
  ///
  /// In en, this message translates to:
  /// **'Sign in as {email}, or you won’t be able to recover App Lock if this PIN is lost.'**
  String appLockSignInToRecoverBound(String email);

  /// No description provided for @appLockNotSignedInNoRecovery.
  ///
  /// In en, this message translates to:
  /// **'You aren’t signed in. You won’t be able to recover this PIN if it’s lost.'**
  String get appLockNotSignedInNoRecovery;

  /// No description provided for @appLockForgotPin.
  ///
  /// In en, this message translates to:
  /// **'Forgot PIN?'**
  String get appLockForgotPin;

  /// No description provided for @appLockSendRecoveryEmail.
  ///
  /// In en, this message translates to:
  /// **'Email a verification link'**
  String get appLockSendRecoveryEmail;

  /// No description provided for @appLockRecoveryEmailSent.
  ///
  /// In en, this message translates to:
  /// **'We sent a verification email to {email}. Open it, then come back here.'**
  String appLockRecoveryEmailSent(String email);

  /// No description provided for @appLockRecoveryIVerified.
  ///
  /// In en, this message translates to:
  /// **'I verified — continue'**
  String get appLockRecoveryIVerified;

  /// No description provided for @appLockRecoveryResend.
  ///
  /// In en, this message translates to:
  /// **'Resend email'**
  String get appLockRecoveryResend;

  /// No description provided for @appLockRecoveryReauth.
  ///
  /// In en, this message translates to:
  /// **'Sign in again to reset your PIN'**
  String get appLockRecoveryReauth;

  /// No description provided for @appLockRecoveryWrongAccount.
  ///
  /// In en, this message translates to:
  /// **'This PIN is tied to {email}. Sign in with that account to recover it.'**
  String appLockRecoveryWrongAccount(String email);

  /// No description provided for @appLockRecoveryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'PIN recovery isn’t set up. You’ll need this PIN, or reinstall LM Mini.'**
  String get appLockRecoveryUnavailable;

  /// No description provided for @appLockRecoveryFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t verify your account. Try again.'**
  String get appLockRecoveryFailed;

  /// No description provided for @appLockRecoveryNoEmail.
  ///
  /// In en, this message translates to:
  /// **'This account has no email to send a verification link to.'**
  String get appLockRecoveryNoEmail;

  /// No description provided for @appLockRecoveryTooMany.
  ///
  /// In en, this message translates to:
  /// **'Too many emails. Wait a minute and try again.'**
  String get appLockRecoveryTooMany;

  /// No description provided for @appLockRecoverySetPin.
  ///
  /// In en, this message translates to:
  /// **'Choose a new PIN'**
  String get appLockRecoverySetPin;

  /// No description provided for @appLockContinueWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Continue with email'**
  String get appLockContinueWithEmail;

  /// No description provided for @appLockSignedInRecoverHint.
  ///
  /// In en, this message translates to:
  /// **'If you forget this PIN, we can email a verification link to {email}.'**
  String appLockSignedInRecoverHint(String email);

  /// No description provided for @appLockRecoveryAccount.
  ///
  /// In en, this message translates to:
  /// **'PIN recovery'**
  String get appLockRecoveryAccount;

  /// No description provided for @appLockRecoveryAccountOn.
  ///
  /// In en, this message translates to:
  /// **'Verification emails go to {email}'**
  String appLockRecoveryAccountOn(String email);

  /// No description provided for @appLockRecoveryAccountOff.
  ///
  /// In en, this message translates to:
  /// **'Sign in so you can recover a lost PIN'**
  String get appLockRecoveryAccountOff;

  /// No description provided for @appLockRecoveryAccountOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Without a signed-in account, a lost PIN can only be cleared by reinstalling the app.'**
  String get appLockRecoveryAccountOffSubtitle;

  /// No description provided for @appLockBackToPin.
  ///
  /// In en, this message translates to:
  /// **'Use PIN'**
  String get appLockBackToPin;

  /// No description provided for @premiumAppLock.
  ///
  /// In en, this message translates to:
  /// **'App Lock'**
  String get premiumAppLock;

  /// No description provided for @premiumAppLockTagline.
  ///
  /// In en, this message translates to:
  /// **'PIN-protect the app'**
  String get premiumAppLockTagline;

  /// No description provided for @premiumAppLockDescription.
  ///
  /// In en, this message translates to:
  /// **'Set a 4- or 6-digit PIN, unlock with Face ID, and recover a lost PIN with a verification email. The PIN stays on this device.'**
  String get premiumAppLockDescription;

  /// No description provided for @spritePanelShow.
  ///
  /// In en, this message translates to:
  /// **'Show {name}\'s expression'**
  String spritePanelShow(String name);

  /// No description provided for @personaExpressionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Expressions'**
  String get personaExpressionsTitle;

  /// No description provided for @personaExpressionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Character sprites that change with the mood of each reply. Name images after the expression, like joy.png or anger.png, or import a SillyTavern sprite zip.'**
  String get personaExpressionsSubtitle;

  /// No description provided for @personaExpressionsImport.
  ///
  /// In en, this message translates to:
  /// **'Import sprites'**
  String get personaExpressionsImport;

  /// No description provided for @personaExpressionsRemoveAll.
  ///
  /// In en, this message translates to:
  /// **'Remove all'**
  String get personaExpressionsRemoveAll;

  /// No description provided for @personaExpressionsRemoveAllConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove all expression sprites from {name}?'**
  String personaExpressionsRemoveAllConfirm(String name);

  /// No description provided for @personaExpressionsReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace image'**
  String get personaExpressionsReplace;

  /// No description provided for @personaExpressionsRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get personaExpressionsRemove;

  /// No description provided for @personaExpressionsImported.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No sprites added} =1{1 sprite added} other{{count} sprites added}}'**
  String personaExpressionsImported(int count);

  /// No description provided for @personaExpressionsUnmatched.
  ///
  /// In en, this message translates to:
  /// **'Skipped (not an expression name): {files}'**
  String personaExpressionsUnmatched(String files);

  /// No description provided for @personaExpressionsMissing.
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get personaExpressionsMissing;

  /// No description provided for @characterCardImport.
  ///
  /// In en, this message translates to:
  /// **'Import character card'**
  String get characterCardImport;

  /// No description provided for @characterCardImportedOne.
  ///
  /// In en, this message translates to:
  /// **'Imported {name}'**
  String characterCardImportedOne(String name);

  /// No description provided for @characterCardImportedMany.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} characters'**
  String characterCardImportedMany(int count);

  /// No description provided for @characterCardImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t import {file}: {reason}'**
  String characterCardImportFailed(String file, String reason);

  /// No description provided for @characterCardLoreSkipped.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 keyword lorebook entry wasn\'t imported} other{{count} keyword lorebook entries weren\'t imported}}'**
  String characterCardLoreSkipped(int count);

  /// No description provided for @appearanceExpressionSprites.
  ///
  /// In en, this message translates to:
  /// **'Character expressions'**
  String get appearanceExpressionSprites;

  /// No description provided for @appearanceExpressionSpritesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'For personas with expression sprites'**
  String get appearanceExpressionSpritesSubtitle;

  /// No description provided for @expressionSpriteModeOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get expressionSpriteModeOff;

  /// No description provided for @expressionSpriteModePanel.
  ///
  /// In en, this message translates to:
  /// **'Large sprite'**
  String get expressionSpriteModePanel;

  /// No description provided for @expressionSpriteModeAvatar.
  ///
  /// In en, this message translates to:
  /// **'Message avatar'**
  String get expressionSpriteModeAvatar;

  /// No description provided for @expressionSpriteModeBoth.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get expressionSpriteModeBoth;

  /// No description provided for @spriteGenerateButton.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get spriteGenerateButton;

  /// No description provided for @spriteGenerateTitle.
  ///
  /// In en, this message translates to:
  /// **'Generate expressions'**
  String get spriteGenerateTitle;

  /// No description provided for @spriteGenerateAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get spriteGenerateAppearance;

  /// No description provided for @spriteGenerateAppearanceHint.
  ///
  /// In en, this message translates to:
  /// **'Hair, eyes, clothing and art style'**
  String get spriteGenerateAppearanceHint;

  /// No description provided for @spriteGenerateSeed.
  ///
  /// In en, this message translates to:
  /// **'Seed'**
  String get spriteGenerateSeed;

  /// No description provided for @spriteGenerateSeedHelp.
  ///
  /// In en, this message translates to:
  /// **'The same seed keeps the character looking alike across expressions.'**
  String get spriteGenerateSeedHelp;

  /// No description provided for @spriteGenerateCore.
  ///
  /// In en, this message translates to:
  /// **'8 core'**
  String get spriteGenerateCore;

  /// No description provided for @spriteGenerateAll.
  ///
  /// In en, this message translates to:
  /// **'All 28'**
  String get spriteGenerateAll;

  /// No description provided for @spriteGenerateOnlyMissing.
  ///
  /// In en, this message translates to:
  /// **'Only missing expressions'**
  String get spriteGenerateOnlyMissing;

  /// No description provided for @spriteGenerateStart.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Generate 1 image} other{Generate {count} images}}'**
  String spriteGenerateStart(int count);

  /// No description provided for @spriteGenerateProgress.
  ///
  /// In en, this message translates to:
  /// **'Generating {current} of {total}: {label}'**
  String spriteGenerateProgress(int current, int total, String label);

  /// No description provided for @spriteGenerateNeedsImageGen.
  ///
  /// In en, this message translates to:
  /// **'Set up image generation first in Settings → Image Generation.'**
  String get spriteGenerateNeedsImageGen;

  /// No description provided for @spriteGenerateDone.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 expression generated} other{{count} expressions generated}}'**
  String spriteGenerateDone(int count);

  /// No description provided for @spriteGenerateFailed.
  ///
  /// In en, this message translates to:
  /// **'Stopped at {label}: {error}'**
  String spriteGenerateFailed(String label, String error);

  /// No description provided for @personaGreetingLabel.
  ///
  /// In en, this message translates to:
  /// **'First message (optional)'**
  String get personaGreetingLabel;

  /// No description provided for @personaGreetingHint.
  ///
  /// In en, this message translates to:
  /// **'What the character says when a new chat starts'**
  String get personaGreetingHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'de',
        'en',
        'es',
        'fr',
        'ru',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'ru':
      return AppLocalizationsRu();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
