// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'LM Mini';

  @override
  String get splashTagline => 'chat IA local';

  @override
  String get homeTitle => 'LM Mini';

  @override
  String get homeSearchHint => 'Rechercher des conversations...';

  @override
  String get allConversations => 'Toutes les conversations';

  @override
  String get noFoldersTitle => 'Aucun dossier';

  @override
  String get noFoldersSubtitle => 'Créez des dossiers pour organiser vos chats';

  @override
  String get noConversationsTitle => 'Aucune conversation';

  @override
  String get noConversationsSubtitle =>
      'Démarrez un nouveau chat pour commencer';

  @override
  String get newChat => 'Nouveau chat';

  @override
  String conversationCount(int count) {
    return '$count conversation(s)';
  }

  @override
  String get noModelsAvailable =>
      'Aucun modèle disponible. Vérifiez votre connexion à LM Studio.';

  @override
  String get noVisionModelAvailable =>
      'Aucun modèle de vision disponible. Chargez un modèle de vision dans LM Studio.';

  @override
  String get deleteConversationTitle => 'Supprimer la Conversation';

  @override
  String get deleteConversationMessage =>
      'Êtes-vous sûr de vouloir supprimer cette conversation ? Cette action est irréversible.';

  @override
  String get renameConversationTitle => 'Renommer la Conversation';

  @override
  String get conversationTitleLabel => 'Titre de la Conversation';

  @override
  String get deleteFolderTitle => 'Supprimer le Dossier';

  @override
  String get deleteFolderMessage =>
      'Les conversations de ce dossier ne seront pas supprimées.';

  @override
  String get moveToFolderTitle => 'Déplacer vers un Dossier';

  @override
  String get noFolder => 'Aucun Dossier';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get save => 'Enregistrer';

  @override
  String get close => 'Fermer';

  @override
  String get ok => 'OK';

  @override
  String get add => 'Ajouter';

  @override
  String get edit => 'Modifier';

  @override
  String get reset => 'Réinitialiser';

  @override
  String get retry => 'Réessayer';

  @override
  String get search => 'Rechercher';

  @override
  String get copy => 'Copier';

  @override
  String get copied => 'Copié !';

  @override
  String get copiedToClipboard => 'Copié dans le presse-papiers';

  @override
  String get dismiss => 'Ignorer';

  @override
  String get configure => 'Configurer';

  @override
  String get rename => 'Renommer';

  @override
  String get duplicate => 'Dupliquer';

  @override
  String get enabled => 'Activé';

  @override
  String get disabled => 'Désactivé';

  @override
  String get active => 'Actif';

  @override
  String get none => 'Aucun';

  @override
  String get auto => 'Auto';

  @override
  String get custom => 'Personnalisé';

  @override
  String get change => 'Changer';

  @override
  String get chatDefaultTitle => 'Chat';

  @override
  String get searchMessagesTooltip => 'Rechercher des messages';

  @override
  String get chatSettingsMenuItem => 'Paramètres du Chat';

  @override
  String get appearanceMenuItem => 'Apparence';

  @override
  String get exportAsPdf => 'Exporter en PDF';

  @override
  String get exportAsTxt => 'Exporter en TXT';

  @override
  String get exportAsMarkdown => 'Exporter en Markdown';

  @override
  String get exportAsJson => 'Exporter en JSON';

  @override
  String get exportAsObsidian => 'Exporter pour Obsidian';

  @override
  String get copyToClipboard => 'Copier dans le presse-papiers';

  @override
  String get exportAndShare => 'Exporter et partager';

  @override
  String get freeFormats => 'Standard';

  @override
  String get premiumFormats => 'Formats Pro';

  @override
  String get chatExported => 'Chat exporté';

  @override
  String get noModelSelectedTitle => 'Aucun Modèle Sélectionné';

  @override
  String get noModelSelectedSubtitle =>
      'Sélectionnez un modèle dans les paramètres pour commencer à discuter';

  @override
  String get openSettings => 'Ouvrir les Paramètres';

  @override
  String connectionError(String error) {
    return 'Erreur de Connexion : $error';
  }

  @override
  String get startConversation => 'Démarrez une conversation';

  @override
  String get typeMessageToBegin => 'Tapez un message pour commencer';

  @override
  String get searchMessagesTitle => 'Rechercher des Messages';

  @override
  String get searchQueryHint => 'Entrez votre recherche...';

  @override
  String get semanticSearchInfo =>
      'La recherche sémantique utilise l\'IA pour trouver des messages pertinents en fonction du sens, pas seulement des mots-clés.';

  @override
  String get noMessagesToSearch => 'Aucun message à rechercher';

  @override
  String get searchResults => 'Résultats de Recherche';

  @override
  String searchResultsFor(int count, String query) {
    return '$count résultat(s) pour \"$query\"';
  }

  @override
  String get noMessagesFound => 'Aucun message trouvé';

  @override
  String get tryDifferentSearch => 'Essayez une autre recherche';

  @override
  String get chatCustomizationSaved => 'Personnalisation du chat enregistrée';

  @override
  String get noMessagesToExport => 'Aucun message à exporter';

  @override
  String get exportingChat => 'Exportation du chat...';

  @override
  String get chatExportedAsPdf => 'Chat exporté en PDF';

  @override
  String get chatExportedAsTxt => 'Chat exporté en TXT';

  @override
  String exportFailed(String error) {
    return 'Échec de l\'exportation : $error';
  }

  @override
  String get chatSettingsUpdated =>
      'Paramètres du chat mis à jour (paramètres globaux remplacés)';

  @override
  String get chatSettingsReset =>
      'Paramètres du chat réinitialisés aux valeurs globales';

  @override
  String get you => 'Vous';

  @override
  String get assistant => 'Assistant';

  @override
  String get yesterday => 'Hier';

  @override
  String get showDetails => 'Afficher les détails';

  @override
  String get hideDetails => 'Masquer les détails';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsAdvancedMode => 'Avancé';

  @override
  String get settingsAdvancedModeTooltip =>
      'Afficher les options techniques pour les utilisateurs avancés';

  @override
  String get serverSection => 'SERVEUR';

  @override
  String get serverUrlLabel => 'URL du Serveur';

  @override
  String get serverUrlHint => 'http://localhost:1234';

  @override
  String get testConnectionRequired => 'Tester la Connexion (Requis)';

  @override
  String get testConnection => 'Tester la connexion';

  @override
  String get modelsSection => 'MODÈLES';

  @override
  String get modelSelection => 'Sélection du Modèle';

  @override
  String get noModelSelected => 'Aucun modèle sélectionné';

  @override
  String get modelParameters => 'Paramètres du Modèle';

  @override
  String get modelParametersSubtitle => 'Température, tokens, pénalités';

  @override
  String get modelParametersHelpTooltip => 'Signification de ces réglages';

  @override
  String get modelParametersHelpTitle => 'Guide rapide';

  @override
  String get modelParametersHelpIntro =>
      'Conseils simples pour chaque réglage. En cas de doute, gardez les valeurs par défaut — vous pourrez les changer plus tard. Certaines options n\'apparaissent que pour votre fournisseur d\'IA actuel.';

  @override
  String get topKHelp =>
      'Combien de choix de mots l\'IA examine. Plus bas = plus sûr et prévisible ; 0 = aucune limite.';

  @override
  String get reasoningHelp =>
      'Active ou désactive le mode thinking pour les modèles de raisonnement. Désactivé = réponses plus rapides sans trace de réflexion ; Activé (ou un niveau) demande au modèle de réfléchir étape par étape. Tous les modèles de raisonnement ne permettent pas de le désactiver.';

  @override
  String get reasoningHelpShort =>
      'Active ou désactive le thinking. Tous ne supportent pas Off.';

  @override
  String get systemPrompts => 'Personas et Prompts Système';

  @override
  String get defaultPrompt => 'Prompt par Défaut';

  @override
  String get appearanceSection => 'APPARENCE';

  @override
  String get appearance => 'Apparence';

  @override
  String get appearanceSubtitle => 'Thème, arrière-plans, avatars';

  @override
  String get supportSection => 'SUPPORT';

  @override
  String get rateApp => 'Évaluer LM Mini';

  @override
  String get rateAppSubtitle =>
      'Vous aimez l\'app ? Laissez un avis sur l\'App Store ⭐';

  @override
  String get hfBrowseTitle => 'Télécharger depuis Hugging Face';

  @override
  String get hfBrowseSubtitle =>
      'Parcourir les modèles GGUF — aucune clé API requise';

  @override
  String get hfBrowseTab => 'Parcourir';

  @override
  String get hfPasteTab => 'Coller un lien';

  @override
  String get hfSearchHint => 'Rechercher des modèles GGUF…';

  @override
  String get hfLoadingModels => 'Recherche sur Hugging Face…';

  @override
  String get hfNoModelsFound => 'Aucun modèle trouvé';

  @override
  String get hfNoModelsHint =>
      'Essayez un autre terme de recherche ou désactivez le filtre LM Studio.';

  @override
  String get hfLmStudioFilter => 'Compatible LM Studio';

  @override
  String get hfLmStudioFilterHint =>
      'Uniquement les modèles indiqués par Hugging Face comme compatibles avec LM Studio';

  @override
  String get hfChatModelsFilter => 'Modèles de chat';

  @override
  String get hfChatBadge => 'Chat';

  @override
  String get hfLmStudioBadge => 'LM Studio';

  @override
  String get hfPasteUrlHint => 'https://huggingface.co/owner/repo';

  @override
  String get hfModelInfo => 'Infos modèle';

  @override
  String hfDownloadsCount(String count) {
    return '$count téléchargements';
  }

  @override
  String hfLikesCount(String count) {
    return '$count j’aime';
  }

  @override
  String hfPipelineTag(String tag) {
    return 'Tâche : $tag';
  }

  @override
  String hfBaseModel(String model) {
    return 'Modèle de base : $model';
  }

  @override
  String hfLicense(String license) {
    return 'Licence : $license';
  }

  @override
  String get hfTagsSection => 'Étiquettes';

  @override
  String get hfQuantPickerHint =>
      'Quantification plus basse = fichier plus petit. Q4_K_M est un bon équilibre pour la plupart des appareils.';

  @override
  String get hfBackToModels => 'Retour aux modèles';

  @override
  String hfGgufFilesCount(int count) {
    return '$count fichier(s) GGUF disponible(s)';
  }

  @override
  String get hfDownloadInBackground =>
      'Téléchargement démarré — suivez la progression avec le bouton flottant. Vous pouvez continuer à parcourir ou fermer ce panneau.';

  @override
  String get hfQuantPickerHintLmStudio =>
      'Quantifications listées par votre serveur LM Studio. Choisissez-en une pour la télécharger sur le serveur.';

  @override
  String get hfDownloadDefaultQuant => 'Télécharger';

  @override
  String hfDownloadFailed(String error) {
    return 'Impossible de démarrer le téléchargement : $error';
  }

  @override
  String get hfPasteInstructions =>
      'Collez une URL de dépôt Hugging Face ou saisissez owner/repo. Vous choisirez ensuite une quantification.';

  @override
  String get hfPasteInstructionsLmStudio =>
      'Collez une URL Hugging Face, owner/repo, ou un ID de modèle LM Studio.';

  @override
  String get hfPasteLabel => 'Dépôt';

  @override
  String get hfInvalidRepo =>
      'Saisissez une URL Hugging Face valide ou owner/repo.';

  @override
  String get hfRecommended => 'Recommandé';

  @override
  String get reviewPromptTitle => 'Vous aimez LM Mini ?';

  @override
  String get reviewPromptMessage =>
      'Vous avez eu quelques excellents chats ! Auriez-vous un instant pour nous noter sur le Play Store ?';

  @override
  String get reviewPromptRate => 'Noter maintenant';

  @override
  String get reviewPromptLater => 'Plus tard';

  @override
  String get buyMeACoffee => 'Offrez-moi un Café';

  @override
  String get buyMeACoffeeSubtitle => 'Aidez à garder l\'IA caféinée ! 🤖';

  @override
  String get featureRequests => 'Demandes de Fonctionnalités';

  @override
  String get featureRequestsSubtitle =>
      'Votez pour des fonctionnalités ou soumettez vos idées';

  @override
  String get dataSection => 'DONNÉES';

  @override
  String get exportAllChats => 'Exporter Tous les Chats';

  @override
  String get exportAllChatsSubtitle =>
      'Télécharger toutes les conversations en fichier ZIP';

  @override
  String get importChats => 'Importer des Chats';

  @override
  String get importChatsSubtitle =>
      'Importer des exports de chat LM Studio (.md ou .zip)';

  @override
  String importSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chats importés avec succès',
      one: '1 chat importé avec succès',
    );
    return '$_temp0';
  }

  @override
  String get importFailed => 'Échec de l\'importation';

  @override
  String importPartial(int imported, int skipped) {
    return '$imported importé(s), $skipped ignoré(s)';
  }

  @override
  String get importing => 'Importation...';

  @override
  String get advancedSection => 'FONCTIONNALITÉS AVANCÉES';

  @override
  String get showRuntimeInfo => 'Afficher les Infos d\'Exécution';

  @override
  String get showRuntimeInfoSubtitle =>
      'Afficher l\'architecture du modèle et le temps d\'exécution';

  @override
  String get embeddingModel => 'Modèle d\'Embeddings';

  @override
  String get enableSemanticSearch => 'Activer la Recherche Sémantique';

  @override
  String get enableSemanticSearchSubtitle =>
      'Rechercher des messages pertinents avec les embeddings';

  @override
  String get toolCalling => 'Appel d\'Outils';

  @override
  String get toolCallingEnabled => 'Appel d\'outils activé';

  @override
  String get toolCallingDisabled => 'Appel d\'outils désactivé';

  @override
  String get legalSection => 'MENTIONS LÉGALES';

  @override
  String get privacyPolicy => 'Politique de Confidentialité';

  @override
  String get privacyPolicySubtitle =>
      'Les discussions restent sur vos appareils';

  @override
  String get termsOfService => 'Conditions d\'Utilisation';

  @override
  String get termsOfServiceSubtitle => 'Termes et conditions';

  @override
  String get appName => 'LM Mini';

  @override
  String get appTagline => 'Une application compagnon pour LM Studio';

  @override
  String get couldNotOpenLink => 'Impossible d\'ouvrir le lien';

  @override
  String get apiToken => 'Token API et USB';

  @override
  String get tokenConfigured => 'Token configuré';

  @override
  String get optionalAuthentication => 'Authentification optionnelle';

  @override
  String get apiTokenLabel => 'Token API';

  @override
  String get apiTokenHint => 'Entrez votre token API LM Studio';

  @override
  String get apiTokenHelp =>
      'Si votre serveur LM Studio nécessite une authentification, entrez votre token API ici. Il est optionnel et nécessaire uniquement si vous avez activé l\'authentification dans les paramètres de LM Studio.';

  @override
  String get apiTokenInfo =>
      'LM Studio 0.4.0+ prend en charge l\'authentification API. Activez-la dans LM Studio > Paramètres > Sécurité.';

  @override
  String get actionRequired => '- Action Requise';

  @override
  String get idleTtl => 'TTL Inactif';

  @override
  String get idleTtlDefault =>
      'Utilise la valeur par défaut de LM Studio (60 min)';

  @override
  String idleTtlMinutes(int value) {
    return 'Déchargement automatique après $value min d\'inactivité';
  }

  @override
  String idleTtlHoursMinutes(int hours, int mins) {
    return 'Déchargement automatique après $hours h $mins min d\'inactivité';
  }

  @override
  String get lmStudioDefault => 'Par défaut LM Studio';

  @override
  String get fiveMinutes => '5 minutes';

  @override
  String get fifteenMinutes => '15 minutes';

  @override
  String get thirtyMinutes => '30 minutes';

  @override
  String get oneHour => '1 heure';

  @override
  String get twoHours => '2 heures';

  @override
  String connectionSuccess(int count) {
    return 'Connecté ! $count modèles chargés';
  }

  @override
  String get connectionFailed => 'Connexion échouée';

  @override
  String get troubleshootingSteps => 'Étapes de Dépannage :';

  @override
  String get troubleshootStep1 =>
      'Assurez-vous que LM Studio est en cours d\'exécution';

  @override
  String get troubleshootStep2 =>
      'Dans LM Studio, ouvrez l\'onglet Développeur (icône ⚙️)';

  @override
  String get troubleshootStep3 =>
      'Activez le bouton \"Servir sur le Réseau Local\"';

  @override
  String get troubleshootStep4 =>
      'Vérifiez que le port du serveur correspond (par défaut : 1234)';

  @override
  String troubleshootStep5(String ip) {
    return 'Utilisez http://localhost:1234 pour les connexions locales';
  }

  @override
  String get lmStudioSettings => 'Paramètres LM Studio';

  @override
  String get serveOnLocalNetworkHelp =>
      'Le bouton \"Servir sur le Réseau Local\" doit être activé (affiché en orange/vert) dans l\'onglet Développeur de LM Studio.';

  @override
  String get networkConnections => 'Connexions Réseau :';

  @override
  String get networkConnectionsTips =>
      '• Remplacez \"localhost\" par l\'adresse IP de votre ordinateur\n• Assurez-vous que les deux appareils sont sur le même réseau\n• Vérifiez les paramètres du pare-feu pour le port 1234';

  @override
  String get noConversationsToExport => 'Aucune conversation à exporter';

  @override
  String exportingConversations(int count) {
    return 'Exportation de $count conversation(s)...';
  }

  @override
  String exportSuccess(int count) {
    return '$count conversation(s) exportée(s) avec succès';
  }

  @override
  String get languageSection => 'LANGUE';

  @override
  String get language => 'Langue';

  @override
  String get languageSubtitle => 'Choisissez votre langue préférée';

  @override
  String get systemDefault => 'Par Défaut du Système';

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
  String get toolsCallingTitle => 'Appel d\'Outils';

  @override
  String get toolCallingSection => 'APPEL D\'OUTILS';

  @override
  String get enableToolCallingAndMcps => 'Activer les Outils et les MCPs';

  @override
  String get enableToolCallingSubtitle =>
      'Permettre à l\'IA de chercher sur le web et d\'appeler des MCPs';

  @override
  String get builtInToolsSection => 'OUTILS INTÉGRÉS';

  @override
  String get builtInToolsInfo =>
      'Outils exécutés localement par l\'application lorsque l\'IA les demande';

  @override
  String get webSearch => 'Recherche Web';

  @override
  String get webSearchUsingSearxng => 'Utilise SearXNG';

  @override
  String get webSearchDisabled =>
      'Désactivé (configurez SearXNG ou passez à Pro)';

  @override
  String get integratedMcpsSection => 'MCPs INTÉGRÉS';

  @override
  String get integratedMcpsInfo =>
      'Utilisez les MCPs déjà configurés dans LM Studio. Ajoutez simplement leurs noms depuis votre mcp.json.';

  @override
  String get integratedMcpsAuthRequired =>
      'Les MCPs intégrés nécessitent l\'authentification activée dans LM Studio et un token API configuré dans Paramètres → Token API.';

  @override
  String get requiresApiToken => 'Nécessite un token API';

  @override
  String get setApiTokenTooltip =>
      'Définissez un token API dans les Paramètres pour activer';

  @override
  String get noIntegratedMcps => 'Aucun MCP intégré configuré';

  @override
  String get addManually => 'Ajouter Manuellement';

  @override
  String get importMcpJson => 'Importer mcp.json';

  @override
  String get ephemeralMcpsSection => 'MCPs ÉPHÉMÈRES';

  @override
  String get ephemeralMcpsInfo =>
      'Serveurs MCP HTTP envoyés par requête. Nécessite \"Autoriser les MCPs par requête\" dans LM Studio.';

  @override
  String get requiresPerRequestMcps =>
      'Nécessite : Développeur → Configuration du Serveur → Autoriser les MCPs par requête';

  @override
  String get noEphemeralMcps => 'Aucun MCP éphémère configuré';

  @override
  String get addHttpMcpServer => 'Ajouter un Serveur MCP HTTP';

  @override
  String get browseExampleMcps => 'Parcourir les Serveurs MCP d\'Exemple';

  @override
  String get addIntegratedMcpTitle => 'Ajouter un MCP';

  @override
  String get editIntegratedMcpTitle => 'Modifier le MCP';

  @override
  String get addIntegratedMcpInfo =>
      'Copiez le nom depuis le mcp.json de LM Studio et collez-le ici. Si vous voyez une clé nommée playwright, tapez playwright.';

  @override
  String get mcpNameLabel => 'Nom depuis mcp.json';

  @override
  String get mcpNameHint => 'playwright';

  @override
  String get mcpNameHelper =>
      'Lettres, chiffres et tirets uniquement — utilisez web-search, pas web_search.';

  @override
  String get exampleMcpJsonEntry => '💡 Exemple d\'entrée mcp.json :';

  @override
  String get nameIsRequired => 'Le nom est requis';

  @override
  String get mcpNameInvalidChars =>
      'Utilisez des tirets au lieu de underscores (LM Studio n\'accepte pas des noms comme web_search).';

  @override
  String get mcpNameAlreadyExists => 'Ce MCP est déjà ajouté';

  @override
  String addedMcp(String name) {
    return '$name ajouté';
  }

  @override
  String updatedMcp(String name) {
    return '$name mis à jour';
  }

  @override
  String get editMcpTooltip => 'Modifier le nom';

  @override
  String get unlimitedToolCalls => 'Appels d\'outils illimités';

  @override
  String get unlimitedToolCallsSubtitle =>
      'Supprimer la limite de 10 appels pour les MCP intégrés et éphémères (n\'affecte pas Pro Search)';

  @override
  String get unlimitedToolCallsOn =>
      'Aucune limite sur les itérations d\'appels d\'outils MCP';

  @override
  String get unlimitedToolCallsOff =>
      'Limité à 10 itérations d\'appels d\'outils';

  @override
  String get structuredOutput => 'Sortie Structurée';

  @override
  String get structuredOutputSubtitle => 'Forcer le format de réponse JSON';

  @override
  String get reasoningMode => 'Mode de Raisonnement';

  @override
  String get reasoningOff => 'Désactivé';

  @override
  String get reasoningLow => 'Faible';

  @override
  String get reasoningMedium => 'Moyen';

  @override
  String get reasoningHigh => 'Élevé';

  @override
  String get reasoningOn => 'Activé';

  @override
  String get reasoningDescOff => 'Pas de traces de raisonnement';

  @override
  String get reasoningDescLow => 'Raisonnement minimal';

  @override
  String get reasoningDescMedium => 'Raisonnement équilibré';

  @override
  String get reasoningDescHigh => 'Raisonnement détaillé';

  @override
  String get reasoningDescOn => 'Traces de raisonnement complètes';

  @override
  String get helpSection => 'AIDE';

  @override
  String get toolCallingGuide => 'Guide d\'Appel d\'Outils';

  @override
  String get toolCallingGuideSubtitle =>
      'Apprenez comment fonctionnent les appels d\'outils';

  @override
  String get searxngSetupGuide => 'Guide de Configuration SearXNG';

  @override
  String get searxngSetupGuideSubtitle =>
      'Configurez votre propre serveur de recherche';

  @override
  String get webSearchConfig => 'Configuration de la Recherche Web';

  @override
  String get howWebSearchWorks => '💡 Comment Fonctionne la Recherche Web';

  @override
  String get howWebSearchWorksSteps =>
      '1. L\'IA décide qu\'elle a besoin d\'informations actuelles\n2. L\'application recherche avec Premium Search ou SearXNG\n3. Les résultats sont envoyés à l\'IA\n4. L\'IA synthétise une réponse';

  @override
  String get searchResultsLabel => 'Résultats de Recherche : ';

  @override
  String get webSearchDisabledWarning =>
      'Recherche web désactivée. Configurez SearXNG ou passez à Pro.';

  @override
  String get searxngUrlOptional => 'URL SearXNG (Optionnel)';

  @override
  String get searxngUrlLabel => 'URL SearXNG';

  @override
  String get searxngUrlHint => 'http://localhost:8888';

  @override
  String get quickSetupDocker => '🐳 Configuration Rapide avec Docker :';

  @override
  String get dockerCommand => 'docker run -d -p 8888:8080 searxng/searxng';

  @override
  String get mcpBadge => 'MCP';

  @override
  String get mcpResultBadge => 'Résultat MCP';

  @override
  String get webSearchSourcesTitle => 'Sources';

  @override
  String get toolBadge => 'Outil';

  @override
  String get resultBadge => 'Résultat';

  @override
  String get failedToLoadImage => 'Échec du chargement de l\'image';

  @override
  String get thinking => 'Réflexion';

  @override
  String get think => 'Penser';

  @override
  String thoughtFor(String duration) {
    return 'A réfléchi pendant $duration';
  }

  @override
  String get performanceStats => 'Statistiques de Performance';

  @override
  String get regenerate => 'Régénérer';

  @override
  String get editMessage => 'Modifier le Message';

  @override
  String get editMessageHint => 'Modifiez votre message...';

  @override
  String get saveAndRegenerate => 'Enregistrer et Régénérer';

  @override
  String get deleteMessage => 'Supprimer le Message';

  @override
  String get deleteMessageConfirm =>
      'Êtes-vous sûr de vouloir supprimer ce message ?';

  @override
  String get mcpCallTitle => 'Appel MCP';

  @override
  String get mcpResultTitle => 'Résultat MCP';

  @override
  String get toolCallTitle => 'Appel d\'Outil';

  @override
  String get toolResultTitle => 'Résultat d\'Outil';

  @override
  String get attachFile => 'Joindre un Fichier';

  @override
  String get photoLibrary => 'Photothèque';

  @override
  String get attachImagesForVision =>
      'Joindre des images pour l\'analyse visuelle';

  @override
  String get requiresVisionModel =>
      'Nécessite un modèle avec capacité de vision';

  @override
  String get takePhoto => 'Prendre une Photo';

  @override
  String get captureImageWithCamera =>
      'Capturer une image avec l\'appareil photo';

  @override
  String get imageFromFiles => 'Image depuis Fichiers';

  @override
  String get pickImageFromFilesApp =>
      'Choisir une image depuis l\'app Fichiers';

  @override
  String get attachDocuments => 'Documents';

  @override
  String get attachDocumentsSubtitle =>
      'PDF, Markdown, Excel (.xlsx), CSV, texte, code et plus';

  @override
  String get textFileTxt => 'Fichier Texte (.txt)';

  @override
  String get attachPlainText => 'Joindre des documents texte brut';

  @override
  String get csvFileCsv => 'Fichier CSV (.csv)';

  @override
  String get attachSpreadsheetData => 'Joindre des données de tableur';

  @override
  String get pdfDocumentPdf => 'Document PDF (.pdf)';

  @override
  String get attachPdfDocuments => 'Joindre des documents PDF';

  @override
  String get mcpLabel => 'MCP :';

  @override
  String get typeMessageHint => 'Tapez un message...';

  @override
  String get attachFilesTooltip => 'Joindre des fichiers';

  @override
  String get customizeChat => 'Personnaliser le Chat';

  @override
  String get overrideGlobalAppearance =>
      'Remplacer l\'apparence globale pour ce chat';

  @override
  String get background => 'Arrière-plan';

  @override
  String get userAvatar => 'Avatar Utilisateur';

  @override
  String get assistantAvatar => 'Avatar Assistant';

  @override
  String get colorsSection => 'Couleurs';

  @override
  String get userBubble => 'Bulle Utilisateur';

  @override
  String get userText => 'Texte Utilisateur';

  @override
  String get assistantBubble => 'Bulle Assistant';

  @override
  String get assistantText => 'Texte Assistant';

  @override
  String get darkOverlay => 'Superposition Sombre';

  @override
  String get darkOverlayDescription =>
      'Ajuster l\'obscurité de la superposition de l\'image de fond';

  @override
  String get usingGlobal => 'Utilise global';

  @override
  String get useGlobal => 'Utiliser Global';

  @override
  String get setCustom => 'Personnaliser';

  @override
  String get customColor => 'Couleur personnalisée';

  @override
  String get defaultThemeColor => 'Couleur du thème par défaut';

  @override
  String get resetToDefault => 'Réinitialiser par défaut';

  @override
  String get pickAColor => 'Choisissez une couleur';

  @override
  String get chatSettingsTitle => 'Paramètres du Chat';

  @override
  String get overrideGlobalSettings =>
      'Remplacer les paramètres globaux uniquement pour ce chat';

  @override
  String get resetAll => 'Tout Réinitialiser';

  @override
  String get modelOverride => 'Modèle';

  @override
  String get noneSelected => 'Aucun sélectionné';

  @override
  String get systemPromptOverride => 'Persona';

  @override
  String get saved => 'Enregistrés';

  @override
  String get noSavedPromptsInfo =>
      'Aucune persona enregistrée. Allez dans Paramètres → Personas pour en créer.';

  @override
  String get selectSavedPromptHint => 'Sélectionner une persona...';

  @override
  String get enterCustomPromptHint =>
      'Entrez un prompt de persona personnalisé...';

  @override
  String get personaShareMemoriesLabel => 'Partager les souvenirs';

  @override
  String get personaShareMemoriesSubtitle =>
      'Si désactivé, cette persona ne recevra ni n\'apprendra de souvenirs dans les chats';

  @override
  String get webSearchOffForThisChat => 'Désactivé pour ce chat uniquement';

  @override
  String get reasoningOffForThisChat => 'Désactivé pour ce chat uniquement';

  @override
  String get temperatureOverride => 'Température';

  @override
  String get maxTokensOverride => 'Tokens Maximum';

  @override
  String get topPOverride => 'Top P';

  @override
  String get topKOverride => 'Top K';

  @override
  String get minPOverride => 'Min P';

  @override
  String get repeatPenaltyOverride => 'Pénalité de Répétition';

  @override
  String get contextLengthOverride => 'Longueur du Contexte';

  @override
  String get systemPromptsTitle => 'Personas et Prompts Système';

  @override
  String get addSystemPromptTooltip => 'Ajouter un prompt système';

  @override
  String get systemPromptsInfoText =>
      'Créez et gérez les prompts système. Liez-les à des modèles spécifiques ou utilisez-les globalement. Sélectionnez-en un pour l\'activer.';

  @override
  String get savedPromptsSection => 'PROMPTS ENREGISTRÉS';

  @override
  String get addSystemPrompt => 'Ajouter un Prompt Système';

  @override
  String get newPrompt => 'Nouveau Prompt';

  @override
  String get noPromptSet => 'Aucun prompt défini';

  @override
  String get editSystemPrompt => 'Modifier le Prompt Système';

  @override
  String get newSystemPrompt => 'Nouveau Prompt Système';

  @override
  String get promptNameLabel => 'Nom du Prompt';

  @override
  String get promptNameHint => 'ex., Assistant Code, Écrivain Créatif...';

  @override
  String get systemPromptLabel => 'Prompt Système';

  @override
  String get systemPromptEditorHint => 'Vous êtes un assistant utile qui...';

  @override
  String get bindToModels => 'Lier à des Modèles Spécifiques';

  @override
  String get bindToModelsSubtitle =>
      'Restreindre ce prompt à certains modèles. Sans liaison, il est disponible pour tous les modèles.';

  @override
  String get noModelsLoaded =>
      'Aucun modèle chargé. Connectez-vous à LM Studio et chargez des modèles pour lier ce prompt.';

  @override
  String get templatesSection => 'MODÈLES';

  @override
  String get pleaseEnterPromptName => 'Veuillez entrer un nom pour ce prompt';

  @override
  String get pleaseEnterPromptContent => 'Veuillez entrer le contenu du prompt';

  @override
  String get deleteSystemPromptTitle => 'Supprimer le Prompt Système ?';

  @override
  String deleteSystemPromptMessage(String name) {
    return 'Êtes-vous sûr de vouloir supprimer \"$name\" ? Cette action est irréversible.';
  }

  @override
  String get templateCodeAssistant => 'Assistant Code';

  @override
  String get templateCreativeWriter => 'Écrivain Créatif';

  @override
  String get templateConciseExpert => 'Expert Concis';

  @override
  String get templateResearcher => 'Chercheur';

  @override
  String get templateTutor => 'Tuteur';

  @override
  String get templateTechnicalWriter => 'Rédacteur Technique';

  @override
  String get downloadProgress => 'Progression du Téléchargement';

  @override
  String get progressLabel => 'Progression';

  @override
  String get speedLabel => 'Vitesse';

  @override
  String get etaLabel => 'Temps Estimé';

  @override
  String get statusLabel => 'Statut';

  @override
  String get notAvailable => 'N/D';

  @override
  String get calculating => 'Calcul en cours...';

  @override
  String get moveToFolderPopup => 'Déplacer vers un Dossier';

  @override
  String contextInfo(String used, String total) {
    return 'Contexte : $used / $total';
  }

  @override
  String get hideAvatars => 'Masquer les Avatars';

  @override
  String get hideAvatarsSubtitle =>
      'Supprimer les icônes d\'avatar des messages du chat';

  @override
  String get autoScroll => 'Défilement Auto';

  @override
  String get autoScrollSubtitle =>
      'Défiler vers le bas quand de nouveaux messages arrivent';

  @override
  String get editMcpServer => 'Modifier le Serveur MCP';

  @override
  String get addMcpServer => 'Ajouter un Serveur MCP';

  @override
  String get serverLabelRequired => 'Libellé du Serveur *';

  @override
  String get serverLabelHint => 'ex., huggingface, tiktoken';

  @override
  String get serverLabelHelper => 'Un nom pour identifier ce serveur';

  @override
  String get serverUrlRequired => 'URL du Serveur *';

  @override
  String get serverUrlMcpHint => 'https://huggingface.co/mcp';

  @override
  String get serverUrlHelper => 'URL HTTP/HTTPS du serveur MCP';

  @override
  String get authorizationOptional => 'Clé API (Optionnel)';

  @override
  String get authorizationHint => 'hf_xxxxxxxx ou Bearer hf_xxxxxxxx';

  @override
  String get authorizationHelper =>
      'Envoyée comme en-tête Authorization à ce MCP. Collez un jeton brut (Bearer est ajouté) ou la valeur complète de l\'en-tête.';

  @override
  String get additionalHeaders => 'En-têtes Supplémentaires';

  @override
  String get additionalHeadersHint => 'X-Custom-Header: valeur';

  @override
  String get additionalHeadersHelper =>
      'Un en-tête par ligne (nom: valeur).\nL\'autorisation est configurée ci-dessus.';

  @override
  String get labelAndUrlRequired => 'Le libellé et l\'URL sont requis';

  @override
  String get urlMustStartWithHttp =>
      'L\'URL doit commencer par http:// ou https://';

  @override
  String get mcpServerUpdated => 'Serveur MCP mis à jour';

  @override
  String get mcpServerAdded => 'Serveur MCP ajouté';

  @override
  String get importMcpJsonTitle => 'Importer mcp.json';

  @override
  String get pasteMcpJsonContent => 'Collez le contenu de votre mcp.json';

  @override
  String get mcpJsonLocation =>
      'À trouver dans : ~/.lmstudio/config/mcp.json\nOu dans LM Studio : Développeur → Configuration MCP → Ouvrir config';

  @override
  String get mcpJsonContentLabel => 'Contenu de mcp.json';

  @override
  String get mcpJsonContentHelper =>
      'Collez le contenu complet du fichier mcp.json';

  @override
  String get parseJson => 'Analyser le JSON';

  @override
  String foundMcpServers(int count) {
    return '$count serveur(s) MCP trouvé(s) :';
  }

  @override
  String get hasAuthHeaders => 'Possède des en-têtes d\'authentification';

  @override
  String importSelected(int count) {
    return 'Importer $count Sélectionné(s)';
  }

  @override
  String get pleasePasteMcpJson =>
      'Veuillez coller le contenu de votre mcp.json';

  @override
  String get noMcpServersFound => 'Aucun mcpServers trouvé dans le JSON';

  @override
  String get exampleMcpServers => 'Serveurs MCP d\'Exemple';

  @override
  String get gitMcpInfo =>
      'Ceux-ci utilisent GitMCP pour fournir la documentation des dépôts GitHub';

  @override
  String get browseMoreGitMcp => 'Voir plus sur gitmcp.io';

  @override
  String get fileNotFound => 'Fichier introuvable';

  @override
  String get openWithExternalApp => 'Ouvrir avec une app externe';

  @override
  String get previewNotAvailable => 'Aperçu non disponible';

  @override
  String get voiceMode => 'Mode Vocal';

  @override
  String get voiceSettings => 'Paramètres Vocaux';

  @override
  String get voiceSettingsSubtitle =>
      'Synthèse vocale, saisie vocale et mode vocal';

  @override
  String get voiceSection => 'Voix';

  @override
  String get voiceStatus => 'Statut';

  @override
  String get voiceTtsEngine => 'Moteur de Synthèse Vocale';

  @override
  String get voiceSttEngine => 'Moteur de Reconnaissance Vocale';

  @override
  String get voiceAvailable => 'Disponible';

  @override
  String get voiceUnavailable => 'Non disponible';

  @override
  String get voiceTtsSettings => 'Synthèse Vocale';

  @override
  String get voiceSttSettings => 'Reconnaissance Vocale';

  @override
  String get voiceSttProvider => 'Fournisseur de reconnaissance vocale';

  @override
  String get voiceSttProviderSystem => 'Voix système';

  @override
  String get voiceSttProviderSystemSubtitle =>
      'Apple Speech sur iOS, Google Speech sur Android';

  @override
  String get voiceSttProviderWhisper => 'Whisper sur l’appareil';

  @override
  String get voiceSttProviderWhisperSubtitle =>
      'Whisper sherpa-onnx hors ligne — plus précis, identique sur toutes les plateformes';

  @override
  String get voiceWhisperModelNotDownloaded => 'Modèle Whisper non téléchargé';

  @override
  String get voiceWhisperModelReady => 'Modèle Whisper prêt';

  @override
  String get voiceWhisperModelSize =>
      'Choisissez une taille — les modèles plus grands transcrivent plus précisément';

  @override
  String get voiceWhisperDownloadButton => 'Télécharger';

  @override
  String get voiceWhisperDownloading => 'Téléchargement du modèle Whisper…';

  @override
  String get voiceWhisperDownloadStarting => 'Démarrage du téléchargement…';

  @override
  String get voiceWhisperDownloadFailed => 'Échec du téléchargement';

  @override
  String get voiceWhisperDeleteModel =>
      'Supprimer le modèle Whisper sélectionné';

  @override
  String get voiceWhisperDeleteTitle => 'Supprimer le modèle Whisper ?';

  @override
  String get voiceWhisperDeleteMessage =>
      'Cela libère le modèle sélectionné du stockage de l’appareil. La reconnaissance vocale sur l’appareil reviendra à la voix système jusqu’à ce que vous téléchargiez à nouveau un modèle Whisper.';

  @override
  String get voiceWhisperDeleteConfirm => 'Supprimer';

  @override
  String get voiceWhisperFallback =>
      'Revient à la voix système si le modèle n’est pas téléchargé';

  @override
  String get voiceWhisperBiggerBetterTitle =>
      'Pourquoi des modèles plus grands ?';

  @override
  String get voiceWhisperBiggerBetterBody =>
      'Les modèles Whisper plus grands produisent en général des transcriptions plus précises — surtout avec les accents, l’audio faible, le bruit de fond et les mots rares. Ils nécessitent aussi plus de stockage et sont plus lents sur l’appareil.\n\nTiny convient à une parole courte et claire. Base ou Small convient mieux aux fichiers longs. Large v3 Turbo est le plus rapide/petit des grands modèles (Large v3 élagué). Le Large v3 complet est le plus précis, mais aussi le plus lourd.';

  @override
  String get voiceWhisperUseModel => 'Utiliser';

  @override
  String get voiceWhisperSelected => 'Sélectionné';

  @override
  String get voiceWhisperDownloaded => 'Téléchargé';

  @override
  String get audioSetupTitle => 'Configurer voix et audio';

  @override
  String get audioSetupMessage =>
      'Le chat vocal a besoin de la synthèse vocale pour que l’IA réponde à voix haute. Choisissez la voix neurale Kokoro sur l’appareil pour la meilleure qualité, ou utilisez les voix intégrées — aucun téléchargement requis.';

  @override
  String get audioSetupWhisperStatus => 'Reconnaissance vocale Whisper';

  @override
  String get audioSetupKokoroStatus => 'Voix neurale Kokoro';

  @override
  String get audioSetupStatusReady => 'Prêt';

  @override
  String get audioSetupStatusMissing => 'Non téléchargé';

  @override
  String get audioSetupOnDeviceButton => 'Télécharger la voix Kokoro';

  @override
  String get audioSetupOnDeviceSubtitle =>
      'TTS neuronal Kokoro · environ 300 Mo · fonctionne hors ligne';

  @override
  String get audioSetupSystemButton => 'Utiliser la voix système';

  @override
  String get audioSetupSystemSubtitle =>
      'STT et TTS intégrés — aucun téléchargement requis';

  @override
  String get audioSetupConfigureButton => 'Réglages vocaux';

  @override
  String get audioSetupNotNow => 'Pas maintenant';

  @override
  String get audioSetupDownloadingWhisper => 'Téléchargement de Whisper…';

  @override
  String get audioSetupDownloadingKokoro => 'Téléchargement de Kokoro…';

  @override
  String get audioSetupDownloadComplete => 'Modèles prêts';

  @override
  String get audioSetupContinueButton => 'Continuer';

  @override
  String get voiceModeSettings => 'Mode Vocal';

  @override
  String get voiceAutoRead => 'Lire les réponses automatiquement';

  @override
  String get voiceAutoReadSubtitle =>
      'Lire automatiquement les nouveaux messages de l\'assistant';

  @override
  String get voiceSpeechRate => 'Vitesse de parole';

  @override
  String get voicePitch => 'Hauteur';

  @override
  String get voiceLanguage => 'Langue vocale';

  @override
  String get voiceLanguageSubtitle =>
      'Language for spoken replies (text-to-speech)';

  @override
  String get voiceSttLanguage => 'Recognition language';

  @override
  String get voiceSttLanguageSubtitle =>
      'Used for the text mic and Voice Call. Can differ from spoken reply language.';

  @override
  String get voiceSelection => 'Sélection de la voix';

  @override
  String get voiceDefault => 'Par défaut';

  @override
  String get voiceTestVoice => 'Tester la voix';

  @override
  String get voiceTestVoiceSubtitle =>
      'Écouter un échantillon avec les paramètres vocaux actuels';

  @override
  String get voiceTestPhrase => 'Bonjour ! Voici comment je sonne maintenant.';

  @override
  String get voiceTestProgressInitializing => 'Démarrage du moteur TTS…';

  @override
  String get voiceTestProgressGenerating => 'Génération de la voix…';

  @override
  String get voiceTestProgressPreparing => 'Préparation de la lecture…';

  @override
  String get voiceTestProgressPlaying => 'Lecture de l’échantillon…';

  @override
  String get voiceTestProgressConnecting => 'Connexion à la voix distante…';

  @override
  String get voiceTestProgressComplete => 'Terminé';

  @override
  String get voiceKokoroEngineReady =>
      'Moteur prêt — le test devrait démarrer rapidement';

  @override
  String get voiceKokoroEngineWarming =>
      'Préchauffage du moteur sur l’appareil…';

  @override
  String get voiceAutoSend => 'Envoi automatique après la parole';

  @override
  String get voiceAutoSendSubtitle =>
      'Envoyer automatiquement le message à la fin de la reconnaissance vocale';

  @override
  String get voiceSttPauseFor => 'Silence avant envoi';

  @override
  String get voiceSttPauseForSubtitle =>
      'Secondes de silence avant l\'envoi de votre voix à l\'IA';

  @override
  String get voiceSttListenFor => 'Durée d\'écoute maximale';

  @override
  String get voiceSttListenForSubtitle =>
      'Arrêter l\'écoute après ce nombre de secondes même si vous parlez encore';

  @override
  String voiceSttSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String get voiceContinuousConversation => 'Conversation continue';

  @override
  String get voiceContinuousConversationSubtitle =>
      'Écouter automatiquement après la lecture de la réponse';

  @override
  String get voiceTapToSpeak => 'Appuyez pour parler';

  @override
  String get voiceListening => 'J\'écoute…';

  @override
  String get voiceThinking => 'Un instant…';

  @override
  String get voiceResponding => 'Je réponds…';

  @override
  String get voiceSpeaking => 'Je parle…';

  @override
  String get voiceConvoHintIdle => 'Appuyez sur le cercle pour parler';

  @override
  String get voiceConvoHintListening => 'Je vous écoute — prenez votre temps';

  @override
  String get voiceConvoHintStarting => 'Préparation du micro…';

  @override
  String get voiceConvoHintProcessing => 'Je réfléchis…';

  @override
  String get voiceConvoHintSpeaking => '';

  @override
  String get voiceNotAvailable =>
      'La reconnaissance vocale n\'est pas disponible sur cet appareil';

  @override
  String get voiceStartRecording => 'Démarrer la saisie vocale';

  @override
  String get voiceStopRecording => 'Arrêter l\'enregistrement';

  @override
  String get voiceDiscardRecording => 'Supprimer';

  @override
  String get voiceSelectLanguage => 'Choisir la langue';

  @override
  String get voiceSelectVoice => 'Choisir la voix';

  @override
  String get voiceNoVoicesAvailable =>
      'Aucune voix disponible pour cette langue';

  @override
  String get voiceAboutTitle => 'À propos du Mode Vocal';

  @override
  String get voiceAboutDescription =>
      'Le mode vocal utilise les moteurs vocaux natifs de votre appareil. La synthèse vocale utilise AVSpeechSynthesizer d\'Apple sur iOS et Google TTS sur Android. La reconnaissance vocale utilise Apple Speech Framework sur iOS et Google Speech sur Android. Tout le traitement se fait sur l\'appareil — aucune donnée n\'est envoyée à des serveurs externes.';

  @override
  String get voiceExitMode => 'Passer au clavier';

  @override
  String get voiceTtsProvider => 'Fournisseur TTS';

  @override
  String get voiceTtsProviderNative => 'Appareil (Natif)';

  @override
  String get voiceTtsProviderNativeSubtitle =>
      'Utilise les voix système intégrées — fonctionne hors ligne';

  @override
  String get voiceTtsProviderKokoro => 'Voix téléchargée';

  @override
  String get voiceTtsProviderKokoroSubtitle =>
      'Voix naturelles qui s’exécutent sur cet appareil';

  @override
  String get voiceTtsProviderKokoroRemote => 'Kokoro (PC)';

  @override
  String get voiceTtsProviderKokoroRemoteSubtitle =>
      'Exécutez Kokoro sur votre PC pour une voix plus rapide et de meilleure qualité';

  @override
  String get voiceTtsProviderElevenLabs => 'ElevenLabs';

  @override
  String get voiceTtsProviderElevenLabsSubtitle =>
      'Pro · votre clé API · voix cloud';

  @override
  String get voiceTtsElevenLabs => 'ElevenLabs';

  @override
  String get voiceTtsElevenLabsHint =>
      'Votre clé · voix de votre bibliothèque ElevenLabs';

  @override
  String get voiceElevenLabsApiKey => 'Clé API ElevenLabs';

  @override
  String get voiceElevenLabsApiKeyHint =>
      'Collez votre xi-api-key depuis elevenlabs.io';

  @override
  String get voiceElevenLabsTestKey => 'Vérifier la clé';

  @override
  String get voiceElevenLabsKeyInvalid =>
      'Cette clé n’a pas été acceptée. Vérifiez-la sur elevenlabs.io.';

  @override
  String get voiceElevenLabsKeyNetwork =>
      'Impossible de joindre ElevenLabs. Vérifiez votre connexion.';

  @override
  String get voiceElevenLabsKeyQuota => 'Cette clé n’a plus de quota.';

  @override
  String get voiceElevenLabsKeyUnknown =>
      'Impossible de vérifier cette clé. Réessayez.';

  @override
  String get voiceElevenLabsPrivacy =>
      'Le texte des réponses est envoyé à ElevenLabs avec votre clé. LM Mini stocke la clé uniquement sur cet appareil.';

  @override
  String get voiceElevenLabsModel => 'Modèle ElevenLabs';

  @override
  String get voiceElevenLabsVoice => 'Voix ElevenLabs';

  @override
  String get voiceElevenLabsNoVoices =>
      'Aucune voix dans ce compte. Ajoutez d’abord des voix dans la bibliothèque ElevenLabs.';

  @override
  String get voiceElevenLabsChangeKey => 'Changer la clé';

  @override
  String get voiceElevenLabsRemoveKey => 'Supprimer la clé';

  @override
  String get voiceElevenLabsReady => 'Connecté à ElevenLabs';

  @override
  String get voiceElevenLabsNoKey => 'Ajoutez votre clé API ElevenLabs';

  @override
  String get personaElevenLabsVoiceLabel => 'Voix ElevenLabs';

  @override
  String get personaElevenLabsVoiceGlobal =>
      'Utiliser la voix ElevenLabs globale';

  @override
  String get personaElevenLabsVoicePickerTitle => 'Voix ElevenLabs';

  @override
  String get personaElevenLabsVoiceAddKey =>
      'Ajoutez une clé API dans les réglages vocaux pour choisir une voix ElevenLabs';

  @override
  String get premiumElevenLabsTts => 'Voix ElevenLabs';

  @override
  String get premiumElevenLabsTtsTagline => 'TTS neural avec votre clé';

  @override
  String get premiumElevenLabsTtsDescription =>
      'Ajoutez votre clé API ElevenLabs et assignez des voix studio aux personas. Le chat vocal, la lecture auto et la lecture à voix haute utilisent le même moteur.';

  @override
  String get voiceTtsProviderGrok => 'Grok';

  @override
  String get voiceTtsProviderGrokSubtitle =>
      'Pro · votre clé API xAI · voix cloud';

  @override
  String get voiceTtsGrok => 'Grok';

  @override
  String get voiceTtsGrokHint => 'Votre clé · voix Grok de xAI';

  @override
  String get voiceGrokApiKey => 'Clé API xAI';

  @override
  String get voiceGrokApiKeyHint => 'Collez votre clé API depuis console.x.ai';

  @override
  String get voiceGrokTestKey => 'Vérifier la clé';

  @override
  String get voiceGrokKeyInvalid =>
      'Cette clé n’a pas été acceptée. Vérifiez-la sur console.x.ai.';

  @override
  String get voiceGrokKeyNetwork =>
      'Impossible de joindre xAI. Vérifiez votre connexion.';

  @override
  String get voiceGrokKeyQuota => 'Cette clé n’a plus de quota.';

  @override
  String get voiceGrokKeyUnknown =>
      'Impossible de vérifier cette clé. Réessayez.';

  @override
  String get voiceGrokPrivacy =>
      'Le texte des réponses est envoyé à xAI avec votre clé. LM Mini stocke la clé uniquement sur cet appareil.';

  @override
  String get voiceGrokVoice => 'Voix Grok';

  @override
  String get voiceGrokNoVoices =>
      'Aucune voix Grok disponible. Vérifiez la clé et réessayez.';

  @override
  String get voiceGrokChangeKey => 'Changer la clé';

  @override
  String get voiceGrokRemoveKey => 'Supprimer la clé';

  @override
  String get voiceGrokReady => 'Connecté à Grok';

  @override
  String get voiceGrokNoKey => 'Ajoutez votre clé API xAI';

  @override
  String get personaGrokVoiceLabel => 'Voix Grok';

  @override
  String get personaGrokVoiceGlobal => 'Utiliser la voix Grok globale';

  @override
  String get personaGrokVoicePickerTitle => 'Voix Grok';

  @override
  String get personaGrokVoiceAddKey =>
      'Ajoutez une clé API dans les réglages vocaux pour choisir une voix Grok';

  @override
  String get personaVoiceSection => 'Voix';

  @override
  String get personaVoiceProviderLabel => 'Fournisseur';

  @override
  String get personaVoiceProviderKokoro => 'Kokoro';

  @override
  String get personaVoiceProviderGlobal =>
      'Utiliser les réglages vocaux globaux';

  @override
  String get personaVoiceConfigureInSettings =>
      'Configurer dans Réglages → Voix';

  @override
  String get premiumGrokTts => 'Voix Grok';

  @override
  String get premiumGrokTtsTagline => 'TTS neural avec votre clé';

  @override
  String get premiumGrokTtsDescription =>
      'Ajoutez votre clé API xAI et assignez des voix Grok aux personas. Le chat vocal, la lecture auto et la lecture à voix haute utilisent le même moteur.';

  @override
  String get voiceRemoteKokoroConnected => 'Connecté à Kokoro sur le PC';

  @override
  String get voiceRemoteKokoroNotFound => 'Kokoro TTS introuvable sur le PC';

  @override
  String get voiceRemoteKokoroRequiresConnect =>
      'Nécessite Partager avec le téléphone sur Mac, ou LM Mini Connect sous Windows/Linux';

  @override
  String get voiceKokoroVoice => 'Voix Kokoro';

  @override
  String get voiceKokoroSpeed => 'Vitesse de parole';

  @override
  String get voiceKokoroModelReady => 'Modèle Kokoro prêt';

  @override
  String get voiceKokoroModelReadySubtitle => 'La voix téléchargée est prête';

  @override
  String get voiceKokoroModelNotDownloaded => 'Modèle Kokoro non téléchargé';

  @override
  String get voiceKokoroModelSize =>
      'Téléchargement requis (~400 Mo pack partagé)';

  @override
  String get voiceKokoroDownloading => 'Téléchargement du modèle Kokoro…';

  @override
  String get voiceKokoroDownloadStarting => 'Démarrage du téléchargement…';

  @override
  String get voiceKokoroDownloadButton => 'Télécharger';

  @override
  String get voiceKokoroDownloadFailed =>
      'Échec du téléchargement. Appuyez pour réessayer.';

  @override
  String get voiceKokoroFallback =>
      'Utilisera la voix native si le modèle Kokoro n\'est pas téléchargé';

  @override
  String get voiceKokoroDeleteModel => 'Supprimer le modèle Kokoro';

  @override
  String get voiceKokoroDeleteTitle => 'Supprimer le modèle Kokoro ?';

  @override
  String get voiceKokoroDeleteMessage =>
      'Cela supprimera tous les packs de langue TTS téléchargés. Vous pourrez les retélécharger plus tard.';

  @override
  String get voiceKokoroDeleteConfirm => 'Supprimer';

  @override
  String get voiceTtsLanguagePacksHint =>
      'L’anglais, l’espagnol, le français et le chinois partagent un téléchargement (~400 Mo). L’allemand et le russe sont plus petits (~34 Mo).';

  @override
  String get voiceTtsLanguagePacks => 'Packs de voix';

  @override
  String get voiceTtsLanguagePacksSubtitleNone =>
      'Téléchargez une langue pour parler sur cet appareil';

  @override
  String voiceTtsLanguagePacksSubtitleReady(int ready, int total) {
    return '$ready langues sur $total prêtes';
  }

  @override
  String voiceTtsLanguagePacksSubtitleDownloading(String name) {
    return 'Téléchargement de $name…';
  }

  @override
  String voiceTtsSharedPackSize(int size) {
    return 'Téléchargement partagé · ~$size Mo';
  }

  @override
  String voiceTtsPiperPackSize(int size) {
    return 'Téléchargement plus petit · ~$size Mo';
  }

  @override
  String get voiceTtsSharedPackDeleteMessage =>
      'Cela retire le téléchargement partagé pour l’anglais, l’espagnol, le français et le chinois. Vous pourrez le télécharger à nouveau plus tard.';

  @override
  String get connecting => 'Connexion...';

  @override
  String get saveAndTestConnection => 'Enregistrer et tester la connexion';

  @override
  String connectedTo(String provider) {
    return '✅ Connecté à $provider';
  }

  @override
  String connectionToFailed(String provider) {
    return '❌ Connexion à $provider échouée — vérifiez votre clé API';
  }

  @override
  String errorGeneric(String error) {
    return '❌ Erreur : $error';
  }

  @override
  String get provider => 'Fournisseur';

  @override
  String cloudApiKeyLabel(String provider) {
    return 'Clé API $provider';
  }

  @override
  String get enterApiKeyHint => 'Entrez votre clé API…';

  @override
  String getApiKey(String provider) {
    return 'Obtenir une clé API $provider';
  }

  @override
  String get baseUrl => 'URL de base';

  @override
  String get customBaseUrlOptional => 'URL de base personnalisée (optionnel)';

  @override
  String get accountSection => 'COMPTE';

  @override
  String get signIn => 'Se connecter';

  @override
  String get signInSubtitle =>
      'Connectez-vous pour activer la sauvegarde cloud';

  @override
  String get cloudServicesUnavailable => 'Services cloud indisponibles';

  @override
  String signedInVia(String method) {
    return 'Connecté via $method';
  }

  @override
  String get lmMiniProSection => 'LM MINI PRO';

  @override
  String get proActive => 'Pro Actif';

  @override
  String get allPremiumUnlocked => 'Toutes les fonctions premium débloquées';

  @override
  String get upgradeToPro => 'Passer à Pro';

  @override
  String get unlockPremiumFeatures =>
      'Débloquez toutes les fonctions premium ci-dessous';

  @override
  String get proBadge => 'PRO';

  @override
  String get proFeatureTag => 'Fonction Pro';

  @override
  String get betaBadge => 'BÊTA';

  @override
  String get imageGeneration => 'Génération d\'images';

  @override
  String get generatedImagesLibrary => 'Images générées';

  @override
  String get generatedImagesGallery => 'Galerie';

  @override
  String get generatedImagesShowInChat => 'Afficher dans le chat';

  @override
  String get generatedImagesLibrarySubtitle =>
      'Voir, ouvrir dans le chat ou supprimer';

  @override
  String get generatedImagesLibraryEmpty => 'Pas encore d\'images générées';

  @override
  String get generatedImagesLibraryEmptyHint =>
      'Les images générées dans le chat sont enregistrées ici.';

  @override
  String get generatedImagesSelect => 'Sélectionner';

  @override
  String get generatedImagesCancelSelect => 'OK';

  @override
  String generatedImagesDeleteN(int count) {
    return 'Supprimer $count';
  }

  @override
  String get generatedImagesDeleteConfirmTitle => 'Supprimer les images ?';

  @override
  String generatedImagesDeleteConfirmBody(int count) {
    return '$count image(s) seront retirées de cet appareil. Les messages du chat restent.';
  }

  @override
  String get generatedImagesOpenChat => 'Ouvrir dans le chat';

  @override
  String get saveToPhotos => 'Save to Photos';

  @override
  String get savedToPhotos => 'Saved to Photos';

  @override
  String get couldNotSaveToPhotos => 'Could not save this file.';

  @override
  String get share => 'Share';

  @override
  String get generatedImagesMissingFile => 'Fichier manquant';

  @override
  String get generatedImagesOrphan => 'Non lié à un chat';

  @override
  String get generatedImagesPrompt => 'Invite';

  @override
  String get generatedImagesNegativePrompt => 'Invite négative';

  @override
  String get generatedImagesDetails => 'Détails de génération';

  @override
  String get generatedImagesNoPrompt => 'Aucune invite enregistrée';

  @override
  String get generatedImagesChatUnavailable =>
      'Cette conversation n\'est plus disponible';

  @override
  String get generatedImagesVideo => 'Vidéo';

  @override
  String imageGenEnabled(String url) {
    return 'Activé — $url';
  }

  @override
  String get imageGenNotConfigured => 'Activé — Non configuré';

  @override
  String get cloudBackup => 'Sauvegarde cloud';

  @override
  String get encryptedBackupRestore => 'Sauvegarde et restauration chiffrées';

  @override
  String get e2eBanner =>
      'Chiffrement de bout en bout — votre phrase secrète ne quitte jamais cet appareil';

  @override
  String get analytics => 'Statistiques';

  @override
  String get analyticsSubtitle =>
      'Statistiques d\'utilisation, jetons et analyses de modèle';

  @override
  String get memory => 'Souvenirs';

  @override
  String memoryItemCount(int count) {
    return '$count éléments • Persistant entre les conversations';
  }

  @override
  String get premiumWebSearch => 'Recherche web premium';

  @override
  String get premiumWebSearchSubtitle =>
      'Recherche instantanée — pas besoin de SearXNG';

  @override
  String get urlReader => 'Lecteur d\'URL';

  @override
  String get urlReaderSubtitle => 'Lire et résumer n\'importe quelle page web';

  @override
  String get conversationBranching => 'Ramification de conversations';

  @override
  String get conversationBranchingSubtitle =>
      'Bifurquer les conversations depuis n\'importe quel message';

  @override
  String get cloudBackupPro => 'Sauvegarde cloud';

  @override
  String get cloudBackupProSubtitle =>
      'Sauvegarde et restauration chiffrées dans le cloud';

  @override
  String get analyticsDashboard => 'Tableau de bord statistiques';

  @override
  String get analyticsDashboardSubtitle =>
      'Statistiques d\'utilisation, jetons et analyses de modèle';

  @override
  String get cloudApiProviders => 'Fournisseurs d\'API cloud';

  @override
  String get cloudApiProvidersSubtitle => 'Mistral, DeepSeek et plus';

  @override
  String get addProviderLabel => 'Ajouter un fournisseur';

  @override
  String get noCloudProvidersTitle => 'Aucun fournisseur cloud';

  @override
  String get noCloudProvidersSubtitle =>
      'Touchez + pour ajouter un fournisseur d\'API cloud.\nUtilisez vos propres clés API pour Groq, DeepSeek et d\'autres services.';

  @override
  String get editProviderTitle => 'Modifier le fournisseur';

  @override
  String get addCloudProviderTitle => 'Ajouter un fournisseur cloud';

  @override
  String get providerLabel => 'Fournisseur';

  @override
  String get apiKeyLabel => 'Clé API';

  @override
  String get pasteLabel => 'Coller';

  @override
  String get baseUrlRequiredLabel => 'URL de base (obligatoire)';

  @override
  String get customBaseUrlOptionalLabel =>
      'URL de base personnalisée (optionnelle)';

  @override
  String get advancedLabel => 'Avancé';

  @override
  String get fetchingLabel => 'Récupération...';

  @override
  String get fetchAvailableModelsLabel => 'Récupérer les modèles disponibles';

  @override
  String get availableModelsLabel => 'Modèles disponibles :';

  @override
  String get suggestedModelsLabel => 'Modèles suggérés :';

  @override
  String get modelIdLabel => 'ID du modèle';

  @override
  String get disableCloudProviderSubtitle =>
      'Désactive la configuration sans la supprimer';

  @override
  String get setAsActiveProviderLabel => 'Définir comme fournisseur actif';

  @override
  String get deactivateLabel => 'Désactiver';

  @override
  String get switchedBackToLocalLmStudio => 'Retour à LM Studio local';

  @override
  String get saveChangesLabel => 'Enregistrer les modifications';

  @override
  String get enterDisplayNameError => 'Veuillez saisir un nom d\'affichage';

  @override
  String get enterApiKeyError => 'Veuillez saisir une clé API';

  @override
  String get enterBaseUrlError =>
      'Veuillez saisir une URL de base pour le fournisseur personnalisé';

  @override
  String get enterApiKeyFirst => 'Saisissez d\'abord une clé API';

  @override
  String failedToFetchModels(String error) {
    return 'Échec du chargement des modèles : $error';
  }

  @override
  String get deleteProviderTitle => 'Supprimer le fournisseur ?';

  @override
  String deleteProviderMessage(String name) {
    return 'Supprimer « $name » et sa clé API ?';
  }

  @override
  String deleteFirstPartyOpenAiServerMessage(String name) {
    return 'Supprimer « $name » de cet appareil ?\n\nVous ne pourrez plus l’ajouter depuis la liste. Pour vous reconnecter, ajoutez A.I Compatible API et définissez l’URL de base sur https://api.openai.com.';
  }

  @override
  String activeProviderSet(String name) {
    return '$name défini comme fournisseur actif';
  }

  @override
  String get memoryPro => 'Souvenirs';

  @override
  String get memoryProSubtitle =>
      'Souvenirs persistants entre les conversations';

  @override
  String get richExportShare => 'Export et partage enrichis';

  @override
  String get richExportShareSubtitle =>
      'Exporter vers Obsidian, Notes, Notion et plus';

  @override
  String autoUnloadAfter(String value) {
    return 'Déchargement auto après $value';
  }

  @override
  String get subscriptionRestore => 'Restaurer';

  @override
  String get subscriptionTerms => 'Conditions';

  @override
  String get subscriptionPrivacy => 'Confidentialité';

  @override
  String get secureYourAccount => 'Sécurisez votre compte';

  @override
  String get signInWithApple => 'Se connecter avec Apple';

  @override
  String get signInWithGoogle => 'Se connecter avec Google';

  @override
  String get subscriptionSecured => 'Votre abonnement est sécurisé';

  @override
  String get packagesNotAvailable => 'Forfaits pas encore disponibles.';

  @override
  String get welcomeToPro => '🎉 Bienvenue dans LM Mini Pro !';

  @override
  String get subscriptionRestored => '✅ Abonnement restauré !';

  @override
  String get noActiveSubscription => 'Aucun abonnement actif trouvé.';

  @override
  String get accountLinked => '✅ Compte lié !';

  @override
  String get account => 'Compte';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get emailLabel => 'E-mail';

  @override
  String get passwordLabel => 'Mot de passe';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get forgotPasswordNeedEmail =>
      'Saisissez d’abord votre e-mail, puis appuyez sur Mot de passe oublié.';

  @override
  String get forgotPasswordSent =>
      'Si un compte existe pour cet e-mail, nous avons envoyé un lien de réinitialisation. Vérifiez votre boîte de réception.';

  @override
  String get forgotPasswordFailed =>
      'Impossible d’envoyer l’e-mail de réinitialisation. Veuillez réessayer.';

  @override
  String get verificationEmailSent => 'E-mail de vérification envoyé !';

  @override
  String failedToSend(String error) {
    return 'Échec de l\'envoi : $error';
  }

  @override
  String get cloudBackupEnabled =>
      'Activé — votre compte prend en charge les sauvegardes chiffrées';

  @override
  String get endToEndEncryption => 'Chiffrement de bout en bout';

  @override
  String get e2eSubtitle =>
      'Sauvegardes chiffrées avec votre phrase secrète — nous ne pouvons pas les lire';

  @override
  String get upgradeForCloudBackup =>
      'Passez à Pro pour activer les sauvegardes cloud chiffrées';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get signOutConfirm => 'Se déconnecter ?';

  @override
  String get signedOut => 'Déconnecté.';

  @override
  String get goToAccount => 'Aller au compte';

  @override
  String get firebaseNotConfigured => 'Firebase n\'est pas configuré.';

  @override
  String get refresh => 'Actualiser';

  @override
  String get createBackup => 'Créer une sauvegarde';

  @override
  String get encryptBackupSubtitle =>
      'Chiffrer et sauvegarder toutes les conversations';

  @override
  String get backUpNow => 'Sauvegarder maintenant';

  @override
  String get yourBackups => 'VOS SAUVEGARDES';

  @override
  String get e2eBackupBanner => 'Chiffrement de bout en bout. ';

  @override
  String get e2eBackupDetail =>
      'Vos sauvegardes sont chiffrées avec votre phrase secrète avant de quitter cet appareil. Nous ne pouvons pas lire vos données.';

  @override
  String get exportingData => 'Exportation des données...';

  @override
  String get preparing => 'Préparation...';

  @override
  String get encrypting => 'Chiffrement...';

  @override
  String get uploading => 'Téléversement...';

  @override
  String get savingMetadata => 'Enregistrement des métadonnées...';

  @override
  String get done => 'Terminé !';

  @override
  String get noBackupsYet => 'Pas encore de sauvegardes';

  @override
  String get createFirstBackup =>
      'Créez votre première sauvegarde chiffrée ci-dessus';

  @override
  String get encrypted => 'Chiffré';

  @override
  String get restore => 'Restaurer';

  @override
  String get encryptionPassphraseLabel => 'Phrase secrète de chiffrement';

  @override
  String get enterStrongPassphrase => 'Entrez une phrase secrète forte';

  @override
  String get confirmPassphraseLabel => 'Confirmer la phrase secrète';

  @override
  String get passphraseRememberWarning =>
      'Retenez cette phrase secrète ! Si vous la perdez, vos sauvegardes ne pourront pas être récupérées. Nous ne la stockons nulle part.';

  @override
  String get passphraseRestoreHint =>
      'Entrez la même phrase secrète que vous avez utilisée lors de la création de cette sauvegarde.';

  @override
  String get minCharsRequired => 'Au moins 4 caractères requis.';

  @override
  String get passphrasesDoNotMatch =>
      'Les phrases secrètes ne correspondent pas.';

  @override
  String get encryptAndBackUp => 'Chiffrer et sauvegarder';

  @override
  String get decryptAndRestore => 'Déchiffrer et restaurer';

  @override
  String get encryptionPassphrase => 'Phrase secrète de chiffrement';

  @override
  String get savedPassphrasePrompt =>
      'Vous avez une phrase secrète enregistrée d\'une sauvegarde précédente. Souhaitez-vous utiliser la même ou en définir une nouvelle ?';

  @override
  String get newPassphrase => 'Nouvelle phrase secrète';

  @override
  String get useSame => 'Utiliser la même';

  @override
  String get setEncryptionPassphrase =>
      'Définir la phrase secrète de chiffrement';

  @override
  String get choosePassphraseBackup =>
      'Choisissez une phrase secrète pour chiffrer cette sauvegarde. Vous en aurez besoin pour restaurer sur n\'importe quel appareil.';

  @override
  String get choosePassphraseDetail =>
      'Choisissez une phrase secrète pour chiffrer votre sauvegarde. Cette phrase reste sur votre appareil — nous ne la voyons jamais. Vous en aurez besoin pour restaurer.';

  @override
  String backupFailed(String error) {
    return 'Sauvegarde échouée : $error';
  }

  @override
  String get restoreBackupConfirm => 'Restaurer la sauvegarde ?';

  @override
  String get restoreWarning =>
      'Cela REMPLACERA toutes vos conversations, messages et dossiers actuels par les données de cette sauvegarde.\n\nCette action est irréversible.';

  @override
  String get continueAction => 'Continuer';

  @override
  String get enterPassphrase => 'Entrer la phrase secrète';

  @override
  String get passphraseDecryptHint =>
      'Cette sauvegarde est chiffrée de bout en bout. Entrez la phrase secrète que vous avez utilisée lors de sa création.';

  @override
  String get wrongPassphrase =>
      'Phrase secrète incorrecte ou sauvegarde corrompue.';

  @override
  String restoreFailed(String error) {
    return 'Restauration échouée : $error';
  }

  @override
  String get deleteBackupConfirm => 'Supprimer la sauvegarde ?';

  @override
  String get deleteBackupWarning =>
      'Cela supprimera définitivement cette sauvegarde cloud chiffrée. Cette action est irréversible.';

  @override
  String get backupDeleted => 'Sauvegarde supprimée.';

  @override
  String deleteFailed(String error) {
    return 'Échec de la suppression : $error';
  }

  @override
  String get overview => 'APERÇU';

  @override
  String get messages => 'Messages';

  @override
  String get conversations => 'Conversations';

  @override
  String get totalTokens => 'Jetons totaux';

  @override
  String get avgResponse => 'Rép. moyenne';

  @override
  String get modelUsage => 'UTILISATION DU MODÈLE';

  @override
  String get noModelUsageData =>
      'Pas encore de données d\'utilisation du modèle.\nCommencez à discuter pour voir les statistiques ici.';

  @override
  String get analyticsSync =>
      'Les statistiques sont synchronisées avec votre compte et réinitialisées si vous vous déconnectez.';

  @override
  String get clearAllMemories => 'Effacer tous les souvenirs';

  @override
  String get memoryOn => 'Activée';

  @override
  String get memoryOff => 'Désactivée';

  @override
  String get memoryInfoText =>
      'Les éléments de mémoire sont injectés dans le prompt système pour que le LLM se souvienne de vous entre les conversations.';

  @override
  String get noMemoriesYet => 'Pas encore de souvenirs';

  @override
  String noMemoriesInCategory(String category) {
    return 'Aucun souvenir $category';
  }

  @override
  String get memoryTapToAdd =>
      'Appuyez sur + pour ajouter un nouveau souvenir ou choisissez une autre catégorie.';

  @override
  String get memoryAddHint =>
      'Ajoutez des faits sur vous que vous voulez que l\'IA retienne dans toutes les conversations.';

  @override
  String get addMemory => 'Ajouter un souvenir';

  @override
  String get category => 'Catégorie';

  @override
  String get editMemory => 'Modifier le souvenir';

  @override
  String get deleteMemory => 'Supprimer le souvenir';

  @override
  String removeMemoryConfirm(String content) {
    return 'Supprimer ce souvenir ?\n\n\"$content\"';
  }

  @override
  String get clearAllMemoriesTitle => 'Effacer tous les souvenirs';

  @override
  String clearAllMemoriesConfirm(int count) {
    return 'Cela supprimera définitivement les $count souvenirs. Cette action est irréversible.';
  }

  @override
  String get clearAll => 'Tout effacer';

  @override
  String get justNow => 'à l\'instant';

  @override
  String get categoryPersonal => 'Personnel';

  @override
  String get categoryPreferences => 'Préférences';

  @override
  String get categoryLifestyle => 'Lifestyle';

  @override
  String get categoryEmotional => 'Emotional';

  @override
  String get categoryTechnical => 'Technique';

  @override
  String get categoryWork => 'Travail';

  @override
  String get categoryGeneral => 'Général';

  @override
  String get categoryAll => 'Tous';

  @override
  String get modelManagement => 'Gestion des modèles';

  @override
  String get downloadNewModel => 'Télécharger un nouveau modèle';

  @override
  String get refreshModels => 'Actualiser les modèles';

  @override
  String get tapToSelect => 'Appuyez pour sélectionner';

  @override
  String modelSelected(String name) {
    return 'Sélectionné : $name';
  }

  @override
  String get unloadModelTooltip => 'Décharger le modèle de la mémoire';

  @override
  String get modelInfoTooltip => 'Info du modèle';

  @override
  String get loadedBadge => 'CHARGÉ';

  @override
  String get visionBadge => 'Vision';

  @override
  String get toolsBadge => 'Outils';

  @override
  String get selectedModel => 'Modèle sélectionné';

  @override
  String get unloading => 'Déchargement...';

  @override
  String get unload => 'Décharger';

  @override
  String get loaded => 'Chargé';

  @override
  String get loadModel => 'Charger le modèle';

  @override
  String get enterModelIdOrUrl =>
      'Entrez un ID de modèle ou une URL HuggingFace :';

  @override
  String get modelIdHint => 'microsoft/phi-4';

  @override
  String get modelIdHelper => 'ID du modèle ou https://huggingface.co/...';

  @override
  String get huggingFaceDetected =>
      'URL HuggingFace détectée — vous sélectionnerez une quantification';

  @override
  String get starting => 'Démarrage...';

  @override
  String get download => 'Télécharger';

  @override
  String get selectQuantization => 'Sélectionner la quantification';

  @override
  String get loadingQuantizations => 'Chargement des quantifications...';

  @override
  String get error => 'Erreur';

  @override
  String fetchQuantizationsFailed(String error) {
    return 'Échec de la récupération des quantifications : $error';
  }

  @override
  String get checkLmStudioRunning => 'Vérifiez que LM Studio est lancé';

  @override
  String get couldNotReachLmStudio =>
      'LM Mini n\'a pas pu joindre votre serveur.';

  @override
  String get couldNotLoadQuantizations =>
      'Impossible de charger les quantifications.';

  @override
  String get couldNotStartDownload =>
      'Impossible de démarrer le téléchargement.';

  @override
  String get noQuantizations => 'Aucune quantification';

  @override
  String get noGgufFiles => 'Aucun fichier GGUF trouvé dans ce dépôt';

  @override
  String foundQuantizations(int count) {
    return '$count quantification(s) GGUF trouvée(s)';
  }

  @override
  String get unknown => 'inconnu';

  @override
  String downloadingModel(String quantization) {
    return 'Téléchargement du modèle avec la quantification $quantization...';
  }

  @override
  String get modelAlreadyDownloaded => 'Modèle déjà téléchargé';

  @override
  String downloadFailed(String error) {
    return 'Échec du téléchargement : $error';
  }

  @override
  String get enterModelIdentifier =>
      'Veuillez entrer un identifiant de modèle ou une URL';

  @override
  String get modelAlreadyLoaded => 'Modèle déjà chargé';

  @override
  String get currentlyLoaded => 'Actuellement chargé :';

  @override
  String loadAlongsideWarning(String name) {
    return 'Charger \"$name\" aux côtés des modèles existants utilisera de la mémoire supplémentaire.';
  }

  @override
  String get unloadAllAndLoad => 'Tout décharger et charger';

  @override
  String get swap => 'Échanger';

  @override
  String get loadAlongside => 'Charger en parallèle';

  @override
  String get loadParamsConflictTitle => 'Paramètres de chargement différents';

  @override
  String loadParamsConflictBody(String name) {
    return '« $name » est déjà chargé dans LM Studio avec des paramètres différents de la configuration de chargement de LM Mini. Un rechargement peut prendre une minute et utiliser de la mémoire supplémentaire.';
  }

  @override
  String get loadParamsConflictTableHeader => 'Paramètres différents :';

  @override
  String get loadParamsLmStudio => 'LM Studio';

  @override
  String get loadParamsLmMini => 'LM Mini';

  @override
  String get loadParamsConflictHint =>
      'Conserver les paramètres LM Studio évite un rechargement. Décharger et recharger applique vos paramètres LM Mini. Charger en parallèle garde les deux instances en mémoire.';

  @override
  String get loadParamsUseExisting => 'Utiliser les paramètres LM Studio';

  @override
  String get loadParamsReloadWithMini =>
      'Décharger et charger avec les paramètres LM Mini';

  @override
  String get loadParamsLoadParallel =>
      'Charger avec les paramètres LM Mini (en parallèle)';

  @override
  String get reloadModelForContextTitle => 'Recharger le modèle ?';

  @override
  String reloadModelForContextBody(String name, String loaded, String desired) {
    return 'La longueur de contexte s\'applique au chargement du modèle. « $name » est chargé à $loaded. Le recharger avec $desired ?';
  }

  @override
  String get reloadModelForContextNow => 'Recharger';

  @override
  String get reloadModelForContextLater => 'Plus tard';

  @override
  String loadModelConfirm(String name) {
    return 'Charger \"$name\" en mémoire ?';
  }

  @override
  String get unloadModelTip =>
      'Vous pouvez décharger les modèles via le bouton d\'éjection ou depuis cet écran après le chargement.';

  @override
  String get modelLoadedSuccess => 'Modèle chargé avec succès';

  @override
  String get failedToLoadModel => 'Échec du chargement du modèle';

  @override
  String get modelInfo => 'Info du modèle';

  @override
  String get infoName => 'Nom';

  @override
  String get infoType => 'Type';

  @override
  String get infoArchitecture => 'Architecture';

  @override
  String get infoPublisher => 'Éditeur';

  @override
  String get infoQuantization => 'Quantification';

  @override
  String get infoParameters => 'Paramètres';

  @override
  String get infoSize => 'Taille';

  @override
  String get infoMaxContext => 'Contexte max.';

  @override
  String get infoLoadedContext => 'Contexte chargé';

  @override
  String get infoStatus => 'Statut';

  @override
  String get available => 'Disponible';

  @override
  String get capabilities => 'Capacités';

  @override
  String get standardTextGeneration => 'Génération de texte standard';

  @override
  String get unloadModelTitle => 'Décharger le modèle';

  @override
  String unloadModelConfirm(String name) {
    return 'Décharger \"$name\" de la mémoire ?';
  }

  @override
  String get freeResourcesTip => 'Cela libérera des ressources GPU/RAM.';

  @override
  String get modelUnloadedSuccess => 'Modèle déchargé avec succès';

  @override
  String get failedToUnloadModel => 'Échec du déchargement du modèle';

  @override
  String get enableImageGeneration => 'Activer la génération d\'images';

  @override
  String get showImageButtons =>
      'Afficher les boutons d\'image dans les messages du chat';

  @override
  String get serverConnection => 'Connexion au serveur';

  @override
  String get serverUrl => 'URL du serveur';

  @override
  String get test => 'Tester';

  @override
  String get connected => 'Connecté';

  @override
  String get model => 'Modèle';

  @override
  String get checkpoint => 'Point de contrôle';

  @override
  String get generationParameters => 'Paramètres de génération';

  @override
  String get negativePrompt => 'Prompt négatif';

  @override
  String get steps => 'Étapes';

  @override
  String get cfgScale => 'Échelle CFG';

  @override
  String get width => 'Largeur';

  @override
  String get height => 'Hauteur';

  @override
  String get sampler => 'Échantillonneur';

  @override
  String get scheduler => 'Planificateur';

  @override
  String get automatic => 'Automatique';

  @override
  String get seedLabel => 'Graine (-1 = aléatoire)';

  @override
  String get batchSize => 'Taille du lot';

  @override
  String get options => 'Options';

  @override
  String get restoreFaces => 'Restaurer les visages';

  @override
  String get restoreFacesSubtitle =>
      'Corriger les visages dans les images générées';

  @override
  String get tiling => 'Carrelage';

  @override
  String get tilingSubtitle => 'Générer des textures répétables sans coutures';

  @override
  String get promptOptions => 'Options de prompt';

  @override
  String get reviewPromptBeforeSending => 'Réviser le prompt avant l\'envoi';

  @override
  String get reviewPromptSubtitle =>
      'Modifier le prompt d\'image avant la génération';

  @override
  String get autoGenerateImage => 'Générer l\'image automatiquement';

  @override
  String get autoGenerateSubtitle =>
      'Générer automatiquement une image quand l\'IA fournit un prompt';

  @override
  String get resetToDefaults => 'Réinitialiser les valeurs par défaut';

  @override
  String get featureRequestsTitle => 'Demandes de fonctionnalités';

  @override
  String get featureRequestsUnavailable =>
      'Demandes de fonctionnalités indisponibles';

  @override
  String get featureRequestsUnavailableDetail =>
      'Cette fonctionnalité nécessite une connexion internet. Veuillez vérifier votre connexion et réessayer plus tard.';

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get votesLeft => 'restants';

  @override
  String get popular => 'Populaire';

  @override
  String get myRequests => 'Mes demandes';

  @override
  String get completed => 'Terminé';

  @override
  String get submitIdea => 'Soumettre une idée';

  @override
  String get noFeatureRequests => 'Pas encore de demandes de fonctionnalités';

  @override
  String get beFirstToSubmit => 'Soyez le premier à soumettre une idée !';

  @override
  String get noRequestsSubmitted => 'Aucune demande soumise';

  @override
  String get tapToSubmitFirst =>
      'Appuyez sur le bouton ci-dessous pour soumettre votre première idée !';

  @override
  String get noCompletedRequests => 'Aucune demande terminée';

  @override
  String get completedRequestsAppear =>
      'Les demandes terminées et refusées apparaîtront ici.';

  @override
  String get adminReplied => 'L\'admin a répondu';

  @override
  String get submitFeatureRequest => 'Soumettre une demande de fonctionnalité';

  @override
  String get titleRequired => 'Titre *';

  @override
  String get titleHint => 'Bref résumé de votre idée';

  @override
  String get descriptionRequired => 'Description *';

  @override
  String get descriptionHint =>
      'Décrivez votre demande de fonctionnalité en détail';

  @override
  String get yourNameOptional => 'Votre nom (optionnel)';

  @override
  String get leaveBlankAnonymous => 'Laissez vide pour soumettre anonymement';

  @override
  String get fillTitleAndDescription =>
      'Veuillez remplir le titre et la description';

  @override
  String get featureRequestSubmitted => 'Demande de fonctionnalité soumise !';

  @override
  String get submit => 'Soumettre';

  @override
  String get featureRequest => 'Demande de fonctionnalité';

  @override
  String get votedTooltip => 'Voté';

  @override
  String get voteForThis => 'Voter pour ceci';

  @override
  String get adminControls => 'Contrôles admin';

  @override
  String get changeStatus => 'Changer le statut';

  @override
  String get officialReply => 'Réponse officielle';

  @override
  String get deleteRequest => 'Supprimer la demande';

  @override
  String get unableToLoadComments => 'Impossible de charger les commentaires';

  @override
  String commentsCount(int count) {
    return 'Commentaires ($count)';
  }

  @override
  String get readMore => 'Lire la suite';

  @override
  String get showLess => 'Afficher moins';

  @override
  String get deleteYourRequest => 'Supprimer votre demande';

  @override
  String get anonymous => 'Anonyme';

  @override
  String get officialResponse => 'Réponse officielle';

  @override
  String get noCommentsYet => 'Pas encore de commentaires';

  @override
  String get beFirstToComment => 'Soyez le premier à partager vos idées !';

  @override
  String get adminBadge => 'ADMIN';

  @override
  String get moderatorBadge => 'MOD';

  @override
  String get experiencedUserBadge => 'EXP';

  @override
  String get adminManageSubmitter => 'Gérer l’auteur';

  @override
  String get adminManageUserTitle => 'Gérer l’utilisateur';

  @override
  String get adminUserUpdated => 'Utilisateur mis à jour';

  @override
  String get adminCommunityRoles => 'Rôles de la communauté';

  @override
  String get adminModeratorRole => 'Modérateur';

  @override
  String get adminModeratorRoleSubtitle =>
      'Peut contourner les limites anti-spam des commentaires et affiche un badge Mod';

  @override
  String get adminExperiencedUserRole => 'Utilisateur expérimenté';

  @override
  String get adminExperiencedUserRoleSubtitle =>
      'Affiche un badge Expérimenté sur les commentaires de demandes de fonctionnalités';

  @override
  String get adminGrantPremiumTitle => 'Accorder Pro offert';

  @override
  String get adminGrantPremiumSubtitle =>
      'Offrir LM Mini Pro gratuitement à cet utilisateur pour une durée limitée';

  @override
  String get adminGrantPremiumAmountLabel => 'Durée';

  @override
  String get adminGrantPremiumAmountHint => 'Saisir le montant';

  @override
  String get adminGrantPremiumUnitDays => 'Jours';

  @override
  String get adminGrantPremiumUnitWeeks => 'Semaines';

  @override
  String get adminGrantPremiumUnitMonths => 'Mois';

  @override
  String get adminGrantPremiumGrantButton => 'Accorder Pro';

  @override
  String get adminGrantPremiumInvalidAmount => 'Saisissez un nombre positif';

  @override
  String get adminGrantPremiumReasonLabel => 'Motif';

  @override
  String get adminGrantPremiumReasonHint =>
      'Facultatif — affiché à l’utilisateur (ex. Désolé pour le désagrément)';

  @override
  String adminGrantPremiumDurationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '1 jour',
    );
    return '$_temp0';
  }

  @override
  String adminGrantPremiumDurationWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count semaines',
      one: '1 semaine',
    );
    return '$_temp0';
  }

  @override
  String adminGrantPremiumDurationMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mois',
      one: '1 mois',
    );
    return '$_temp0';
  }

  @override
  String get adminRevokePremiumTitle => 'Révoquer le Pro offert';

  @override
  String get adminRevokePremiumMessage =>
      'Retirer l’accès Pro accordé par l’administrateur pour cet utilisateur ?';

  @override
  String get adminRevokePremiumConfirm => 'Révoquer';

  @override
  String get premiumGrantBannerTitle => 'Vous avez reçu Pro offert';

  @override
  String premiumGrantBannerBody(String duration) {
    return 'LM Mini Pro gratuit pendant $duration. Profitez des fonctions premium pendant cette période.';
  }

  @override
  String premiumGrantBannerReason(String reason) {
    return 'Motif : $reason';
  }

  @override
  String get premiumGrantDialogTitle => 'Pro offert débloqué';

  @override
  String premiumGrantDialogBody(String duration) {
    return 'Un administrateur vous a accordé LM Mini Pro gratuitement pendant $duration. Sauvegarde cloud, mémoire, analytique et plus sont maintenant disponibles.';
  }

  @override
  String premiumGrantDialogReason(String reason) {
    return 'Motif : $reason';
  }

  @override
  String get premiumGrantDialogButton => 'Super';

  @override
  String get youBadge => 'VOUS';

  @override
  String get deleteComment =>
      'Êtes-vous sûr de vouloir supprimer ce commentaire ?';

  @override
  String maxCommentsReached(int max) {
    return 'Vous avez posté $max commentaires d\'affilée. Attendez qu\'un autre utilisateur réponde.';
  }

  @override
  String get addYourName => 'Ajoutez votre nom';

  @override
  String get replyAsAdmin => 'Répondre en tant qu\'admin...';

  @override
  String get writeComment => 'Écrire un commentaire...';

  @override
  String get errorTryAgain => 'Erreur : veuillez réessayer.';

  @override
  String statusUpdated(String status) {
    return 'Statut mis à jour en $status';
  }

  @override
  String get addOfficialResponse => 'Ajouter une réponse officielle...';

  @override
  String get replySaved => 'Réponse enregistrée';

  @override
  String get deleteRequestConfirm =>
      'Êtes-vous sûr de vouloir supprimer cette demande ? Cette action est irréversible.';

  @override
  String get requestDeleted => 'Demande supprimée';

  @override
  String get deleteCommentTitle => 'Supprimer le commentaire';

  @override
  String get deleteCommentConfirm =>
      'Êtes-vous sûr de vouloir supprimer ce commentaire ?';

  @override
  String get commentDeleted => 'Commentaire supprimé';

  @override
  String get generationParametersSection => 'PARAMÈTRES DE GÉNÉRATION';

  @override
  String get temperature => 'Température';

  @override
  String get temperatureSubtitle =>
      'À quel point les réponses sont créatives ou ciblées. Plus bas = plus prudent ; plus haut = plus varié.';

  @override
  String get topP => 'Top P';

  @override
  String get topPSubtitle =>
      'Étendue des choix de mots autorisés. Plus bas = réponses plus ciblées.';

  @override
  String get minP => 'Min P';

  @override
  String get minPSubtitle =>
      'Ignore les mots très improbables. Plus haut = texte plus sûr et prévisible.';

  @override
  String get repeatPenalty => 'Pénalité de répétition';

  @override
  String get repeatPenaltySubtitle =>
      'Empêche l\'IA de répéter les mêmes phrases. 1.0 = désactivé.';

  @override
  String get frequencyPenalty => 'Pénalité de fréquence';

  @override
  String get frequencyPenaltySubtitle =>
      'Réduit les mots que l\'IA utilise trop souvent.';

  @override
  String get presencePenalty => 'Pénalité de présence';

  @override
  String get presencePenaltySubtitle =>
      'Pousse l\'IA à aborder de nouveaux sujets plutôt qu\'à réutiliser les anciens.';

  @override
  String get tokenLimits => 'LIMITES DE JETONS';

  @override
  String get maxOutputTokens => 'Jetons de sortie max.';

  @override
  String get maxOutputTokensSubtitle =>
      'Longueur maximale d\'une réponse. Plus haut = réponses plus longues (et plus d\'attente).';

  @override
  String get contextWindow => 'Fenêtre de contexte';

  @override
  String get contextWindowSubtitle =>
      'Combien de conversation l\'IA peut retenir à la fois. Plus haut = plus de mémoire.';

  @override
  String get modelLoadingConfig => 'CONFIG. DE CHARGEMENT DU MODÈLE';

  @override
  String get loadContextLength => 'Longueur de contexte';

  @override
  String get loadContextSubtitle =>
      'Combien de contexte le modèle peut utiliser pour le chat et au chargement dans LM Studio. Plus haut = plus de mémoire / VRAM.';

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
  String get evalBatchSize => 'Taille du lot d\'évaluation';

  @override
  String get evalBatchSubtitle =>
      'Quantité de texte traitée à la fois au chargement. Plus haut peut être plus rapide, mais utilise plus de mémoire.';

  @override
  String get numExperts => 'Nombre d\'experts';

  @override
  String get numExpertsSubtitle =>
      'Uniquement pour les modèles « mixture of experts ». Laissez vide en cas de doute.';

  @override
  String get flashAttention => 'Flash Attention';

  @override
  String get flashAttentionSubtitle =>
      'Accélère le modèle et peut réduire la mémoire. Gardez activé sauf problème.';

  @override
  String get offloadKvCache => 'Décharger le cache KV sur GPU';

  @override
  String get offloadKvCacheSubtitle =>
      'Utilise le GPU pour mémoriser le chat plus efficacement. Gardez activé si vous avez un GPU.';

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
      'Affiche la réflexion étape par étape de l\'IA lorsqu\'elle est disponible.';

  @override
  String get reasoningUnsupportedToast =>
      'Ce modèle ne prend pas en charge Reasoning dans LM Studio. Reasoning a été désactivé.';

  @override
  String get reasoningNotExposedChatHint =>
      'LM Studio ne permet pas de désactiver le raisonnement pour ce modèle. Essayez un autre modèle.';

  @override
  String get premiumSearchActive => 'Recherche Premium active';

  @override
  String get premiumSearchPlusSearxng => ' + SearXNG';

  @override
  String get webSearchDisabledAll =>
      'Recherche web désactivée pour tous les chats';

  @override
  String get configureSearch => 'Configurer la recherche';

  @override
  String get advancedFeaturesSection => 'FONCTIONNALITÉS AVANCÉES';

  @override
  String get howToolCallingWorks => 'Comment fonctionne l\'appel d\'outils';

  @override
  String get stepAskQuestion => 'Vous posez une question';

  @override
  String get stepAskExample => 'ex., \"Quel temps fait-il à Tokyo ?\"';

  @override
  String get stepAiRequestsTool => 'L\'IA demande un outil';

  @override
  String get stepAiRequestsExample =>
      'Le modèle décide qu\'il a besoin d\'une recherche web';

  @override
  String get stepAppExecutes => 'L\'app exécute l\'outil';

  @override
  String get stepAppExecutesExample =>
      'Recherche via Recherche Premium ou SearXNG';

  @override
  String get stepResultsSent => 'Résultats envoyés à l\'IA';

  @override
  String get stepResultsExample =>
      'Résultats de recherche ajoutés à la conversation';

  @override
  String get stepAiAnswers => 'L\'IA génère une réponse';

  @override
  String get stepAiAnswersExample => 'Le modèle synthétise une réponse utile';

  @override
  String get toolCallingModelNote => 'comme Qwen, Llama 3.1+ ou Mistral.';

  @override
  String get searxngSetup => 'Configuration de SearXNG';

  @override
  String get searxngDescription =>
      'SearXNG est un métamoteur de recherche gratuit et respectueux de la vie privée que vous pouvez auto-héberger.';

  @override
  String get dockerRecommended => 'Option 1 : Docker (Recommandé)';

  @override
  String get publicInstance => 'Option 2 : Utiliser une instance publique';

  @override
  String get findPublicInstances => 'Trouvez des instances publiques sur :';

  @override
  String get selfHostRecommended =>
      'L\'auto-hébergement est recommandé pour la fiabilité.';

  @override
  String get clipboardEmpty =>
      'Presse-papiers vide. Copiez d\'abord le contenu de votre mcp.json.';

  @override
  String get clipboardAccessFailed =>
      'Impossible d\'accéder au presse-papiers. Veuillez coller manuellement dans le champ ci-dessous.';

  @override
  String get pasteFromClipboard => 'Coller depuis le presse-papiers';

  @override
  String get httpServersImportNote =>
      'Serveurs HTTP → MCPs éphémères (envoyés à LM Studio par requête)';

  @override
  String get localMcpsImportNote =>
      'MCPs locaux → MCPs intégrés (utilise le format « mcp/nom »)';

  @override
  String get noValidMcpServers => 'Aucun serveur MCP valide trouvé';

  @override
  String get serverAlreadyAdded => 'Ce serveur est déjà ajouté';

  @override
  String get themeSection => 'THÈME';

  @override
  String get themeLabel => 'Thème';

  @override
  String get glassEffectsLabel => 'Effets verre';

  @override
  String get glassEffectsSubtitle =>
      'Flou givré sur les en-têtes et menus. Désactivez pour moins chauffer et économiser la batterie.';

  @override
  String get lowBatteryModeLabel => 'Mode économie de batterie';

  @override
  String get lowBatteryModeSubtitle =>
      'Désactive le verre, affiche du texte brut pendant le flux, et synchronise Home/iCloud seulement après le message. L’écran reste allumé jusqu’à la fin de la réponse pour ne pas couper le flux.';

  @override
  String get backgroundSection => 'ARRIÈRE-PLAN';

  @override
  String get chatBackground => 'Arrière-plan du chat';

  @override
  String get chatBackgroundSubtitle =>
      'Définir l\'arrière-plan par défaut pour tous les chats';

  @override
  String get avatarsSection => 'AVATARS';

  @override
  String get chatHeaderAvatarLabel => 'Avatar de l\'en-tête du chat';

  @override
  String get chatHeaderAvatarSubtitle =>
      'Afficher l\'image de profil dans la barre d\'application de la fenêtre de chat';

  @override
  String get avatarAboveMessageLabel => 'Avatar au-dessus du message';

  @override
  String get avatarAboveMessageSubtitle =>
      'Afficher l\'avatar au-dessus de la bulle de message au lieu de l\'afficher à côté';

  @override
  String get fullWidthAssistantLabel => 'Réponses pleine largeur';

  @override
  String get fullWidthAssistantSubtitle =>
      'Vos messages restent dans une bulle. Le texte de l’assistant utilise toute la ligne';

  @override
  String get tryFullWidthTitle => 'Essayez la nouvelle vue pleine largeur';

  @override
  String get tryFullWidthBody =>
      'Les réponses de l’assistant occupent toute la ligne, sans bulle. Vous pouvez revenir en arrière à tout moment dans Apparence.';

  @override
  String get tryFullWidthOpenAppearance => 'Ouvrir Apparence';

  @override
  String get tryFullWidthNotNow => 'Pas maintenant';

  @override
  String get streamingPhaseLoadingModel => 'Chargement du modèle';

  @override
  String get streamingPhaseProcessingPrompt => 'Traitement de la requête';

  @override
  String get streamingPhaseThinking => 'Réflexion';

  @override
  String get streamingPhaseWriting => 'Rédaction de la réponse';

  @override
  String get streamingPhaseSearching => 'Recherche';

  @override
  String get streamingPhaseUsingTools => 'Utilisation des outils';

  @override
  String streamingPhaseConnecting(String provider) {
    return 'Connexion à $provider…';
  }

  @override
  String get networkOfflineTitle => 'Vous êtes hors ligne';

  @override
  String get networkOfflineBody =>
      'Connectez-vous au Wi-Fi ou aux données mobiles, puis réessayez.';

  @override
  String networkNeedsWifiTitle(String provider) {
    return 'En données mobiles — $provider a besoin du Wi-Fi';
  }

  @override
  String networkNeedsWifiBody(String provider, String host) {
    return '$provider sur votre ordinateur ($host) n’est accessible que depuis le même réseau Wi-Fi que votre ordinateur. Connectez-vous à ce Wi-Fi, ou activez l’accès à distance pour l’utiliser partout.';
  }

  @override
  String networkLostWifiTitle(String provider) {
    return 'Connexion à $provider perdue';
  }

  @override
  String get networkLostWifiBody =>
      'Votre téléphone a quitté le Wi-Fi. Reconnectez-vous au même Wi-Fi que votre ordinateur, ou activez l’accès à distance pour continuer à discuter partout.';

  @override
  String get networkUseRemoteAccess => 'Utiliser l’accès à distance';

  @override
  String get networkSwitchProvider => 'Changer de fournisseur';

  @override
  String get messageNotDelivered => 'Non distribué · Touchez pour réessayer';

  @override
  String get messageRetrying => 'Envoi…';

  @override
  String get messageNotDeliveredA11y =>
      'Message non distribué. Touchez pour réessayer.';

  @override
  String get previewUserMessage => 'Quel socket a cette carte ?';

  @override
  String get bubbleAvatarSizeLabel => 'Taille de l\'avatar dans la bulle';

  @override
  String bubbleAvatarRadiusValue(int value) {
    return '${value}px de rayon';
  }

  @override
  String get userAvatarLabel => 'Avatar de l\'utilisateur';

  @override
  String get yourProfilePicture => 'Votre photo de profil';

  @override
  String get assistantAvatarLabel => 'Avatar de l\'assistant';

  @override
  String get aiAssistantPicture => 'Photo de l\'assistant IA';

  @override
  String get chatBehaviorSection => 'COMPORTEMENT DU CHAT';

  @override
  String get fontSizeLabel => 'Taille de police';

  @override
  String get iconSizeLabel => 'Taille des icônes';

  @override
  String pointsValue(int value) {
    return '${value}pt';
  }

  @override
  String get previewLabel => 'Aperçu';

  @override
  String get previewAssistantMessage =>
      'Bonjour ! Je suis votre assistant IA. Comment puis-je vous aider aujourd\'hui ? Voici un mot en **gras** et du `code en ligne`.';

  @override
  String get readAloud => 'Lire à voix haute';

  @override
  String appearanceActionTapped(String label) {
    return '$label activé';
  }

  @override
  String get autoScrollStreaming => 'Défilement auto pendant le streaming';

  @override
  String get autoScrollStreamingSubtitle =>
      'Défiler automatiquement vers les nouveaux messages';

  @override
  String get showChatStarters => 'Suggestions de nouveau chat';

  @override
  String get showChatStartersSubtitle =>
      'Afficher les pastilles de prompts sur les chats vides';

  @override
  String get useLegacyComposer => 'Saisie de message classique';

  @override
  String get useLegacyComposerSubtitle =>
      'Utiliser le composeur compact classique au lieu du nouvel input shine';

  @override
  String get hideAvatarsLabel => 'Masquer les avatars';

  @override
  String get moreSpaceForContent =>
      'Plus d\'espace pour le contenu des messages';

  @override
  String get enterKeyBehaviorLabel => 'Comportement de la touche Retour/Entrée';

  @override
  String get enterKeyAutoDescription =>
      'Envoyer avec les claviers physiques, insérer une nouvelle ligne avec les claviers virtuels';

  @override
  String get enterKeySendDescription =>
      'Entrée envoie le message (Maj+Entrée pour une nouvelle ligne)';

  @override
  String get enterKeyNewlineDescription =>
      'Entrée insère toujours une nouvelle ligne';

  @override
  String get sendLabel => 'Envoyer';

  @override
  String get newLineLabel => 'Nouvelle ligne';

  @override
  String get themeSystem => 'Système';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get backLabel => 'Retour';

  @override
  String get nextLabel => 'Suivant';

  @override
  String get getStartedLabel => 'Commencer';

  @override
  String get connectionSuccessful => 'Connexion réussie !';

  @override
  String get connectionFailedMessage => 'Échec de la connexion';

  @override
  String get lmStudioServerFoundNeedsKey =>
      'Serveur trouvé ! Ajoutez votre clé API ci-dessus, puis appuyez sur Tester la connexion.';

  @override
  String get lmStudioScanServerNeedsKey =>
      'Trouvé — ajoutez la clé API pour vous connecter';

  @override
  String lmStudioUsingServerNeedsKey(String url) {
    return 'Utilisation de $url. Ajoutez votre clé API ci-dessous, puis testez la connexion.';
  }

  @override
  String get lmStudioAuthDialogTitle => 'Serveur trouvé';

  @override
  String get lmStudioAuthDialogMessage =>
      'Ce serveur nécessite une clé API. Collez votre jeton LM Studio ci-dessous pour vous connecter.';

  @override
  String get lmStudioAuthHelpHint =>
      'Dans LM Studio, ouvrez le mode Développeur → Paramètres du serveur → Gérer les jetons pour créer ou copier votre clé API.';

  @override
  String get welcomeWizardTitle => 'Bienvenue sur LM Mini';

  @override
  String get welcomeWizardSubtitle =>
      'Discutez avec des modèles d\'IA exécutés sur votre réseau local via LM Studio. Configurons cela en quelques étapes rapides.';

  @override
  String get welcomeWizardThemeTitle => 'Choisissez votre thème';

  @override
  String get welcomeWizardThemeSystemSubtitle =>
      'Suivre les réglages de votre appareil';

  @override
  String get welcomeWizardThemeLightSubtitle => 'Net et lumineux';

  @override
  String get welcomeWizardThemeDarkSubtitle => 'Plus doux pour les yeux';

  @override
  String get welcomeWizardAppearanceTitle => 'Personnaliser l\'apparence';

  @override
  String get welcomeWizardAppearancePreviewMessage =>
      'Bonjour ! Voici à quoi ressembleront vos messages de chat.';

  @override
  String get welcomeWizardServerTitle => 'Se connecter à LM Studio';

  @override
  String get welcomeWizardServerSubtitle =>
      'Entrez l\'adresse IP de l\'ordinateur qui exécute LM Studio sur votre réseau local.';

  @override
  String get welcomeWizardLocalNetworkNote =>
      'iOS demandera l\'autorisation d\'accéder au réseau local lorsque vous testerez la connexion. Veuillez l\'autoriser.';

  @override
  String get apiTokenOptionalLabel => 'Jeton API (optionnel)';

  @override
  String get welcomeWizardChangeLater =>
      'Vous pourrez toujours modifier cela plus tard dans les paramètres.';

  @override
  String get welcomeWizardFindModelTitle => 'Trouver un modèle adapté';

  @override
  String get welcomeWizardFindModelSubtitle =>
      'Faites courir deux options et voyez laquelle est plus rapide sur votre setup. Environ une minute — ou ignorez si vous savez déjà.';

  @override
  String get welcomeWizardFindModelHelp => 'Aidez-moi à choisir';

  @override
  String get welcomeWizardFindModelSkip => 'Passer — je choisis moi-même';

  @override
  String get welcomeWizardExperienceTitle => 'How do you use AI?';

  @override
  String get welcomeWizardExperienceSubtitle =>
      'We\'ll tailor recommendations. You can change everything later.';

  @override
  String get welcomeWizardBeginnerTitle => 'Beginner';

  @override
  String get welcomeWizardBeginnerSubtitle =>
      'Restez simple — Paramètres plus clairs, et on vous suggère un bon modèle.';

  @override
  String get welcomeWizardPowerTitle => 'Power user';

  @override
  String get welcomeWizardPowerSubtitle =>
      'Paramètres complets et choix — modèles sur appareil et serveurs comme LM Studio.';

  @override
  String get welcomeWizardSetupTitleBeginner => 'Choisir un modèle';

  @override
  String get welcomeWizardSetupTitlePower => 'Choose your setup';

  @override
  String get welcomeWizardSetupSubtitleBeginner =>
      'Touchez un modèle pour le télécharger. Ou connectez un ordinateur en Wi‑Fi.';

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
  String get pickColor => 'Choisir une couleur';

  @override
  String get hueLabel => 'Teinte';

  @override
  String get saturationLabel => 'Saturation';

  @override
  String get lightnessLabel => 'Luminosité';

  @override
  String get alphaLabel => 'Alpha';

  @override
  String get hexLabel => 'Hex';

  @override
  String get personaModeLabel => 'Mode persona';

  @override
  String get personaModeSubtitle =>
      'Ajouter un avatar, une couleur d\'accent, une voix et un modèle préféré pour les chats de groupe';

  @override
  String get avatarLabel => 'Avatar';

  @override
  String get customAvatarSet => 'Avatar personnalisé défini';

  @override
  String get noAvatar => 'Aucun avatar';

  @override
  String get accentColorLabel => 'Couleur d\'accent';

  @override
  String get defaultLabel => 'Par défaut';

  @override
  String get preferredModelLabel => 'Modèle préféré';

  @override
  String get preferredModelAny => 'Aucun (utiliser n\'importe lequel)';

  @override
  String get personaChooseProviderTitle => 'Choisir le fournisseur';

  @override
  String get personaChooseProviderSubtitle =>
      'Vos fournisseurs configurés. Ajoutez-en d’autres dans Réglages.';

  @override
  String get personaCloudProvidersSection => 'Fournisseurs cloud';

  @override
  String get personaKokoroVoiceLabel => 'Voix Kokoro';

  @override
  String get personaKokoroVoiceSubtitle =>
      'Voix utilisée quand cette persona parle (chat vocal / lecture)';

  @override
  String get personaKokoroVoiceGlobal => 'Utiliser le réglage vocal global';

  @override
  String get personaKokoroVoicePickerTitle => 'Voix de la persona';

  @override
  String get personaKokoroSpeedLabel => 'Vitesse de parole';

  @override
  String get personaKokoroSpeedGlobal => 'Utiliser la vitesse globale';

  @override
  String personaKokoroSpeedValue(String speed) {
    return '${speed}x';
  }

  @override
  String get voiceWhisperModelLabel => 'Modèle Whisper';

  @override
  String get voiceWhisperModelTapToChoose =>
      'Appuyez pour choisir la taille et télécharger';

  @override
  String get imageGenSeedLabel => 'Graine de génération d\'image';

  @override
  String imageGenSeedFixed(int seed) {
    return 'Graine fixe : $seed';
  }

  @override
  String get imageGenSeedRandomGlobal =>
      'Aléatoire (utiliser le réglage global)';

  @override
  String get personaComfyWorkflowLabel => 'Workflow ComfyUI';

  @override
  String get personaComfyWorkflowUseGlobal => 'Utiliser le réglage global';

  @override
  String personaComfyWorkflowUnavailable(String path) {
    return '$path (actuellement indisponible)';
  }

  @override
  String get personaComfyWorkflowHelper =>
      'Utilisé lorsque le fournisseur de génération d\'images est ComfyUI. Laissez « global » pour utiliser Réglages → Génération d\'images.';

  @override
  String get personaComfyWorkflowNotComfy =>
      'Cette attribution s\'applique uniquement lorsque ComfyUI est le fournisseur d\'images actif.';

  @override
  String get personaComfyWorkflowRefresh => 'Actualiser les workflows';

  @override
  String get personaComfyWorkflowJsonLabel =>
      'JSON de workflow personnalisé (facultatif)';

  @override
  String get personaComfyWorkflowJsonHint =>
      'Laisser vide pour le workflow global / intégré';

  @override
  String get personaComfyWorkflowJsonHelper =>
      'Collez un workflow au format API. Prend en charge %PROMPT%, %LORA%, %LORA_WEIGHT% et d\'autres espaces réservés.';

  @override
  String get personaComfyWorkflowJsonIgnored =>
      'Ignoré tant qu\'un workflow enregistré est sélectionné';

  @override
  String personaComfyWorkflowJsonActive(int count) {
    return 'Workflow personnalisé ($count caractères)';
  }

  @override
  String get personaComfyWorkflowJsonClear => 'Effacer (global / défaut)';

  @override
  String get comfyUiDetails => 'Détails ComfyUI';

  @override
  String get comfyUiDetailsTitle => 'Requête ComfyUI';

  @override
  String get comfyUiDetailsCopy => 'Copier le JSON';

  @override
  String get comfyUiDetailsCopied => 'Copié dans le presse-papiers';

  @override
  String get resetToGlobal => 'Réinitialiser au global';

  @override
  String get setSeed => 'Définir la graine';

  @override
  String get pickAccentColor => 'Choisir la couleur d\'accent';

  @override
  String get imageGenSeedDialogDescription =>
      'Définissez une graine fixe pour que cette persona génère toujours des images cohérentes. Laissez vide pour aléatoire.';

  @override
  String get seedValueLabel => 'Valeur de graine';

  @override
  String get seedValueHint => 'p. ex. 42 (vide = aléatoire)';

  @override
  String get setLabel => 'Définir';

  @override
  String get selectPreferredModelTitle => 'Sélectionner le modèle préféré';

  @override
  String get branchCreated => '🔀 Branche créée';

  @override
  String get yamlFrontmatter => 'En-tête YAML';

  @override
  String get markdownFormat => 'Markdown';

  @override
  String get localNetworkBlocked => 'L\'accès au réseau local peut être bloqué';

  @override
  String get localNetworkFix =>
      'Allez dans Réglages → LM Mini → Réseau local et activez-le.';

  @override
  String get openAppSettings => 'Ouvrir les réglages de l\'app';

  @override
  String get memorySaved => 'Souvenir enregistré';

  @override
  String get proSearch => 'Recherche Pro';

  @override
  String get webSearchLabel => 'Recherche web';

  @override
  String get readUrl => 'Lire l\'URL';

  @override
  String get code => 'code';

  @override
  String couldNotOpenFile(String error) {
    return 'Impossible d\'ouvrir le fichier : $error';
  }

  @override
  String get tapOpenExternal =>
      'Appuyez sur « Ouvrir avec une app externe » pour voir ce fichier';

  @override
  String get proSearchEnabled => 'Recherche Pro activée';

  @override
  String get proSearchDisabled => 'Recherche Pro désactivée';

  @override
  String get thinkingEnabled => 'Réflexion activée pour ce chat';

  @override
  String get thinkingDisabled => 'Réflexion désactivée pour ce chat';

  @override
  String get codeSandbox => 'Sandbox de code';

  @override
  String get codeSandboxSubtitle =>
      'Exécutez Python ou JavaScript dans un sandbox sécurisé';

  @override
  String get codeSandboxEnabled => 'Sandbox de code activé';

  @override
  String get codeSandboxDisabled => 'Sandbox de code désactivé';

  @override
  String get searxngNotConfigured => 'Ajoutez une URL SearXNG pour activer';

  @override
  String get searxngConfiguredOff =>
      'Configuré — appuyez pour utiliser à la place de Recherche Pro';

  @override
  String get searxngConfigureFirst =>
      'Configurez une URL SearXNG avant d’activer';

  @override
  String get editSearxng => 'Modifier SearXNG';

  @override
  String get toolCallingLabel => 'Appel d\'outils';

  @override
  String get on => 'Activé';

  @override
  String get off => 'Désactivé';

  @override
  String get aiCanUseTools => 'L\'IA peut utiliser des outils dans ce chat';

  @override
  String get toolsDisabledChat => 'Outils désactivés pour ce chat';

  @override
  String get webSearchChat => 'Recherche web';

  @override
  String get aiCanSearchWeb => 'L\'IA peut chercher sur le web dans ce chat';

  @override
  String get webSearchDisabledChat => 'Recherche web désactivée pour ce chat';

  @override
  String get disableMemory => 'Désactiver la mémoire';

  @override
  String memoryItemsActive(int count) {
    return '$count éléments de mémoire actifs';
  }

  @override
  String get memoryDisabledChat =>
      'La mémoire est désactivée pour ce chat. L\'IA ne verra pas vos souvenirs enregistrés.';

  @override
  String get lmStudioLocal => 'LM Studio (Local)';

  @override
  String get modelNoLongerAvailable =>
      'Le modèle précédemment sélectionné n\'est plus disponible. Veuillez sélectionner un nouveau modèle.';

  @override
  String get noModelsForProvider =>
      'Aucun modèle trouvé pour ce fournisseur. Vérifiez la clé API.';

  @override
  String get noModelsCheckConnection =>
      'Aucun modèle trouvé. Vérifiez la connexion LM Studio.';

  @override
  String get selectModel => 'Sélectionner le modèle';

  @override
  String get goToModels => 'Aller aux modèles';

  @override
  String get reviewImagePrompt => 'Réviser le prompt d\'image';

  @override
  String get editImagePromptHint => 'Modifier le prompt d\'image...';

  @override
  String get generate => 'Générer';

  @override
  String get imageNotFound => 'Image non trouvée';

  @override
  String get cameraPermissionNeeded => 'Permission caméra requise';

  @override
  String get cameraPermissionExplain =>
      'Veuillez autoriser l\'accès à la caméra pour prendre des photos pour l\'analyse visuelle.';

  @override
  String get photosPermissionNeeded => 'Permission photos requise';

  @override
  String get photosPermissionExplain =>
      'Veuillez autoriser l\'accès à vos images pour l\'analyse visuelle.';

  @override
  String couldNotOpenFilePicker(String error) {
    return 'Impossible d\'ouvrir le sélecteur de fichiers : $error';
  }

  @override
  String get filePickerCouldNotCopy =>
      'Impossible de copier ce fichier. Enregistrez-le sur le téléphone (pas Drive ni Récents) et choisissez-le à nouveau.';

  @override
  String get signInToUseCloudBackup =>
      'Connectez-vous pour utiliser la sauvegarde cloud';

  @override
  String get cloudBackupRequiresAccount =>
      'La sauvegarde cloud nécessite un compte pour que vos sauvegardes chiffrées soient stockées en toute sécurité sous votre identité.';

  @override
  String get arguments => 'Arguments';

  @override
  String get selectLanguage => 'Sélectionner la langue';

  @override
  String get connectionPopupTitle => 'Non connecté';

  @override
  String get connectionPopupBody =>
      'LM Mini n\'a pas pu joindre LM Studio.\nRendez-vous dans les Réglages pour entrer l\'adresse de votre serveur.';

  @override
  String get connectionPopupDismiss => 'Plus tard';

  @override
  String get connectionPopupGoToSettings => 'Aller aux Réglages';

  @override
  String get remoteAccess => 'Accès à distance';

  @override
  String get scanQrCode => 'Scanner le code QR';

  @override
  String get connectedViaLmConnect => 'Connecté via LM Connect';

  @override
  String get disconnectRemoteToChangeSettings =>
      'LM Studio est couplé via LM Connect';

  @override
  String get disconnect => 'Déconnecter';

  @override
  String get unpair => 'Dissocier';

  @override
  String get useRemoteConnection => 'Discuter avec ce Mac';

  @override
  String get useRemoteConnectionOffSubtitle =>
      'Désactivé — ce téléphone utilise ses propres modèles. Activez pour utiliser ceux de LM Mini Home.';

  @override
  String get connectedViaLmStudio => 'Connecté via LM Studio';

  @override
  String get usingLocalServer => 'Utilisation du serveur local';

  @override
  String get testing => 'Test en cours...';

  @override
  String connectedLatency(int ms) {
    return 'Connecté — ${ms}ms';
  }

  @override
  String get notConnected => 'Non connecté';

  @override
  String get scanQrDescription =>
      'Scannez un code QR depuis l\'application de bureau LM Mini Connect pour accéder à votre LM Studio de n\'importe où.';

  @override
  String get remotePaired => 'Distant associé';

  @override
  String lastConnected(String time) {
    return 'Dernière connexion : $time';
  }

  @override
  String get reScanQrCode => 'Re-scanner le code QR';

  @override
  String get qrRequiresPro => 'Le scan de code QR nécessite LM Mini Pro';

  @override
  String get enterUrlManually => 'Saisir l’URL manuellement';

  @override
  String get enterUrlManuallySubtitle =>
      'Collez un lien d’appariement si la caméra n’est pas disponible';

  @override
  String get relayUrlHint => 'https://relay.lmmini.com/s/…';

  @override
  String get connectWithUrl => 'Se connecter avec l’URL';

  @override
  String get invalidRelayUrl =>
      'Ce n’est pas un lien d’appariement LM Mini valide. Copiez-le depuis Partager avec le téléphone sur votre Mac.';

  @override
  String get invalidQrCode =>
      'Code QR invalide. Utilisez l\'application LM Mini Connect pour en générer un.';

  @override
  String get pointCameraAtQr =>
      'Pointez votre caméra vers le code QR affiché dans l\'application de bureau LM Mini Connect';

  @override
  String get connectedToRemoteLmStudio => 'Connecté à LM Studio distant !';

  @override
  String get failedToConnect =>
      'Échec de la connexion. Assurez-vous que LM Mini Connect est en cours d\'exécution.';

  @override
  String get unpairRemote => 'Dissocier le distant';

  @override
  String get unpairRemoteDescription =>
      'Cela supprimera la connexion distante enregistrée. Vous pourrez vous réassocier en scannant un nouveau code QR.';

  @override
  String get setupGuide => 'Guide d\'installation';

  @override
  String get downloadLmMiniConnect => 'Obtenir LM Mini Home';

  @override
  String get availableForPlatforms =>
      'Téléchargement direct pour Mac · Connect pour Windows et Linux';

  @override
  String get setupStep1Title => 'Télécharger LM Mini Home';

  @override
  String get setupStep1Desc =>
      'Téléchargez LM Mini Home pour Mac depuis lmmini.com. Sous Windows et Linux, vous pouvez encore utiliser LM Mini Connect.';

  @override
  String get setupStep2Title => 'Partager avec le téléphone';

  @override
  String get setupStep2Desc =>
      'Dans LM Mini Home sur votre Mac, ouvrez Partager avec le téléphone et activez-le. La connexion au relais est immédiate.';

  @override
  String get setupStep3Title => 'Scanner le code QR';

  @override
  String get setupStep3Desc =>
      'Scannez le code QR affiché par LM Mini Home sur votre Mac. C’est tout !';

  @override
  String minutesAgo(int count) {
    return 'il y a ${count}min';
  }

  @override
  String hoursAgo(int count) {
    return 'il y a ${count}h';
  }

  @override
  String daysAgo(int count) {
    return 'il y a ${count}j';
  }

  @override
  String get selectAll => 'Tout sélectionner';

  @override
  String get moveToFolder => 'Déplacer vers le dossier';

  @override
  String get select => 'Sélectionner';

  @override
  String get dismissAction => 'Ignorer';

  @override
  String get createNewFolder => 'Créer un nouveau dossier';

  @override
  String deleteConversations(int count) {
    return 'Supprimer $count conversation(s) ? Cette action est irréversible.';
  }

  @override
  String get averages => 'MOYENNES';

  @override
  String get tokensPerChat => 'Tokens / Chat';

  @override
  String get msgsPerChat => 'Msgs / Chat';

  @override
  String get tokensPerMsg => 'Tokens / Msg';

  @override
  String get topModel => 'Modèle principal';

  @override
  String get liveActivityTitle => 'Live Activity';

  @override
  String get liveActivityTitleAndroid => 'Génération en arrière-plan';

  @override
  String get liveActivityDescription =>
      'Traitez votre requête IA même lorsque vous quittez l\'app ou verrouillez le téléphone';

  @override
  String get liveActivityDescriptionAndroid =>
      'Continuez la génération en quittant l\'app. Affiche la progression dans une notification persistante et empêche Android d\'interrompre le modèle en cours de réponse.';

  @override
  String get liveActivityAndroidOnDeviceOnly =>
      'Passez à un modèle GGUF ou MLX sur l’appareil pour utiliser la génération en arrière-plan sur Android.';

  @override
  String get liveActivityNotificationDenied =>
      'L\'autorisation de notification est requise pour la génération en arrière-plan sur Android.';

  @override
  String get premiumRemoteAccess => 'Accès à distance';

  @override
  String get premiumRemoteAccessTagline => 'LM Studio de n\'importe où';

  @override
  String get premiumRemoteAccessDescription =>
      'Accédez à votre LM Studio local de n\'importe où avec LM Mini Connect. Pas de redirection de port ni VPN — scannez un code QR et connectez-vous en toute sécurité.';

  @override
  String get premiumLiveActivity => 'Live Activity';

  @override
  String get premiumLiveActivityTagline => 'L\'IA fonctionne en arrière-plan';

  @override
  String get premiumLiveActivityDescription =>
      'Traitez votre requête IA même lorsque vous quittez l\'app ou verrouillez le téléphone. Suivez la progression en temps réel sur votre écran de verrouillage.';

  @override
  String get premiumWebSearchTagline =>
      'Aucune configuration de serveur requise';

  @override
  String get premiumWebSearchDescription =>
      'Recherchez instantanément sur le web pendant les conversations. Propulsé par des APIs de recherche cloud.';

  @override
  String get premiumCloudBackup => 'Sauvegarde cloud chiffrée';

  @override
  String get premiumCloudBackupTagline => 'Chiffrement AES-256-GCM';

  @override
  String get premiumCloudBackupDescription =>
      'Sauvegardez toutes les conversations dans le cloud avec un chiffrement de niveau militaire. Votre mot de passe ne quitte jamais votre appareil.';

  @override
  String get premiumUrlReader => 'Lecteur d\'URL';

  @override
  String get premiumUrlReaderTagline => 'Analyser n\'importe quelle page web';

  @override
  String get premiumUrlReaderDescription =>
      'Collez n\'importe quelle URL et votre modèle lit le contenu complet de la page.';

  @override
  String get premiumBranching => 'Ramification de conversations';

  @override
  String get premiumBranchingTagline => 'Explorez des chemins alternatifs';

  @override
  String get premiumBranchingDescription =>
      'Bifurquez n\'importe quelle conversation pour explorer des scénarios \"et si\".';

  @override
  String get premiumMemory => 'Souvenirs';

  @override
  String get premiumMemoryTagline => 'Se souvient de vous entre les chats';

  @override
  String get premiumMemoryDescription =>
      'Enregistrez des faits, des préférences et du contexte qui persistent dans toutes les conversations.';

  @override
  String get premiumAnalytics => 'Tableau de bord analytique';

  @override
  String get premiumAnalyticsTagline => 'Connaissez votre utilisation';

  @override
  String get premiumAnalyticsDescription =>
      'Suivez les tokens utilisés, les messages envoyés, l\'utilisation des modèles et les temps de réponse moyens.';

  @override
  String get premiumCloudApi => 'Fournisseurs Cloud API';

  @override
  String get premiumCloudApiTagline => 'Mistral, Anthropic et plus';

  @override
  String get premiumCloudApiDescription =>
      'Connectez des fournisseurs LLM cloud en plus de vos modèles locaux.';

  @override
  String get premiumExport => 'Exporter et Partager';

  @override
  String get premiumExportTagline => 'Obsidian, Notes, Notion et plus';

  @override
  String get premiumExportDescription =>
      'Exportez les conversations en Markdown, PDF ou texte brut formaté.';

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
  String get premiumOnDeviceLlmTagline =>
      'Modèles catalogue plus grands et import HF';

  @override
  String get premiumOnDeviceLlmDescription =>
      'Le chat sur l\'appareil est gratuit avec des modèles de démarrage sélectionnés. Pro débloque les téléchargements du catalogue au-delà de 2B paramètres et l\'import de vos propres modèles GGUF ou MLX depuis Hugging Face — entièrement hors ligne.';

  @override
  String get premiumHfBrowse => 'Import Hugging Face';

  @override
  String get premiumHfBrowseTagline => 'Apportez n\'importe quel modèle GGUF';

  @override
  String get premiumHfBrowseDescription =>
      'Recherchez sur Hugging Face, téléchargez des modèles GGUF sur votre appareil ou serveur LM Studio et utilisez-les dans LM Mini. Filtrez la compatibilité, suivez les téléchargements en arrière-plan et dépassez le catalogue gratuit — sans clé API.';

  @override
  String get onDeviceProviderLabel => 'Sur l\'appareil';

  @override
  String get onDeviceManageModels => 'Gérer les modèles sur l\'appareil';

  @override
  String get onDeviceGeneratingHint => 'Génération sur l\'appareil…';

  @override
  String get onDeviceEngineUnavailable => 'Moteur sur l\'appareil indisponible';

  @override
  String get onDeviceOpenBrowser => 'Ouvrir les modèles sur l\'appareil';

  @override
  String get onDeviceManagedHere =>
      'Les modèles sur l\'appareil sont gérés dans un navigateur dédié où vous pouvez télécharger, supprimer et activer.';

  @override
  String get onDeviceRemoteImageOnly =>
      'IA sur l\'appareil sélectionnée — l\'accès distant ne sert qu\'à la génération d\'images et à Kokoro (si configuré). Le chat reste sur cet appareil.';

  @override
  String get onDeviceProOnly => 'Pro uniquement';

  @override
  String get onDeviceInstalled => 'Installé';

  @override
  String get onDeviceUseModel => 'Utiliser';

  @override
  String get onDeviceRemoveModel => 'Supprimer';

  @override
  String get onDeviceDownloadAnyway => 'Télécharger quand même';

  @override
  String onDeviceNowUsing(String name) {
    return 'Utilise maintenant $name sur l\'appareil';
  }

  @override
  String get onDeviceEngineFllamaLabel => 'fllama (GGUF)';

  @override
  String onDeviceEngineSwitched(String engine) {
    return 'Passé à $engine. Le modèle précédent a été déchargé.';
  }

  @override
  String onDeviceEngineSwitchedCleared(String engine) {
    return 'Passé à $engine. Le modèle précédent n\'est pas compatible et a été désélectionné — choisissez-en un dans Modèles sur l\'appareil.';
  }

  @override
  String get onDeviceImportedLabel => 'Importé';

  @override
  String get onDeviceFreeLabel => 'Gratuit';

  @override
  String get onDeviceProLabel => 'Pro';

  @override
  String get onDeviceMayCrashLabel => 'Risque de crash';

  @override
  String get onDeviceModelMayCrashTitle => 'Ce modèle peut planter';

  @override
  String onDeviceModelMayCrashMessage(
      String name, String runtimeGb, String deviceRamGb) {
    return '$name nécessite environ $runtimeGb Go de mémoire à l\'exécution. Votre appareil dispose d\'environ $deviceRamGb Go pour les apps. Charger quand même peut figer ou faire planter l\'app.';
  }

  @override
  String get onDeviceContinueLoading => 'Continuer le chargement';

  @override
  String get yearly => 'Annuel';

  @override
  String get monthly => 'Mensuel';

  @override
  String get lifetime => 'À vie';

  @override
  String get subscriptionLifetimeBadge => 'Paiement unique';

  @override
  String get subscriptionLifetimeDisclaimer =>
      'Achat unique. Fonctions Pro sur votre compte tant que LM Mini est proposé et maintenu. N\'inclut pas les frais d\'API tierces ni les services hébergés séparément — voir les Conditions.';

  @override
  String subscriptionLifetimeUpgradeDisclaimer(String store) {
    return 'Lifetime est un achat unique séparé. Votre abonnement actuel ne sera pas annulé automatiquement et nous ne pouvons pas rembourser les frais d\'abonnement passés. Après l\'achat, annulez votre abonnement dans l\'$store.';
  }

  @override
  String get subscriptionUpgradeToLifetime => 'Passer à Lifetime';

  @override
  String subscriptionUpgradeToLifetimeSubtitle(String price) {
    return 'Payer une fois — $price';
  }

  @override
  String get duplicateSubscriptionDialogTitle => 'Annulez votre abonnement';

  @override
  String duplicateSubscriptionDialogBody(String store) {
    return 'Vous avez Pro Lifetime et un abonnement actif. Lifetime ne remplace pas automatiquement votre abonnement et nous ne pouvons pas rembourser les frais d\'abonnement. Veuillez annuler votre abonnement dans l\'$store pour éviter d\'autres prélèvements.';
  }

  @override
  String duplicateSubscriptionDialogManage(String store) {
    return 'Ouvrir l\'$store';
  }

  @override
  String get duplicateSubscriptionDialogDismiss => 'Compris';

  @override
  String get duplicateSubscriptionNoManageUrl =>
      'Ouvrez les réglages d\'abonnement de votre appareil pour annuler.';

  @override
  String supportLifetime(String price) {
    return 'Débloquer pour toujours — $price';
  }

  @override
  String get encryptionKey => 'Clé de chiffrement';

  @override
  String get encryptionEnabled => 'Chiffrement : Activé';

  @override
  String get encryptionDisabled => 'Chiffrement : Désactivé';

  @override
  String get encryptionKeyDescription =>
      'Clé de chiffrement de bout en bout pour l\'accès à distance. Doit correspondre à la clé dans LM Mini Connect.';

  @override
  String get editEncryptionKey => 'Modifier la clé de chiffrement';

  @override
  String get enterEncryptionKey => 'Entrer la clé de chiffrement';

  @override
  String get encryptionKeyUpdated => 'Clé de chiffrement mise à jour';

  @override
  String get keepLmMiniAlive => 'Gardez LM Mini\nen vie';

  @override
  String get supportTheApp =>
      'Soutenez l\'app et obtenez des avantages premium';

  @override
  String get mostFeaturesFree =>
      'La plupart des fonctions sont gratuites — Pro aide à couvrir les coûts serveur';

  @override
  String get thankYouSupport => 'Merci pour votre soutien !';

  @override
  String get helpingKeepAlive => 'Vous aidez à garder LM Mini en vie';

  @override
  String get linkSignInMethod =>
      'Associez une méthode de connexion pour conserver votre abonnement si vous changez d\'appareil.';

  @override
  String get paywallLinkAccountBody =>
      'Vous utilisez un compte anonyme. Associez Apple ou Google avant l\'achat pour que Pro se synchronise entre appareils et survive à une réinstallation.';

  @override
  String get continueAnonymously => 'Continuer anonymement';

  @override
  String signedInViaMethod(String method) {
    return 'Connecté via $method';
  }

  @override
  String get yourSubscriptionSecured => 'Votre abonnement est sécurisé';

  @override
  String subscriptionManagedThrough(String store) {
    return 'Abonnement géré via le $store.';
  }

  @override
  String get subscriptionsComingSoon => 'Abonnements bientôt disponibles';

  @override
  String get premiumPreview =>
      'Les fonctionnalités premium sont en cours de finalisation.\nVous pouvez activer le mode développeur ci-dessous pour les prévisualiser.';

  @override
  String get enableDeveloperPremium => 'Activer Premium développeur';

  @override
  String get disableDeveloperPremium => 'Désactiver Premium développeur';

  @override
  String get premiumEnabled => 'Premium activé (override développeur)';

  @override
  String get premiumDisabled => 'Premium désactivé';

  @override
  String supportYearly(String price) {
    return 'Soutenir — $price/an';
  }

  @override
  String supportMonthly(String price) {
    return 'Soutenir — $price/mois';
  }

  @override
  String get welcomeToLmMiniPro => 'Bienvenue sur LM Mini Pro !';

  @override
  String get connectedRemotely => 'Connecté à distance';

  @override
  String get pairedNotActive => 'Jumelé — pas actif';

  @override
  String get accessLmStudioAnywhere => 'Accédez à LM Studio de partout';

  @override
  String get appStore => 'App Store';

  @override
  String get googlePlayStore => 'Google Play Store';

  @override
  String get starterAttach => 'Joindre';

  @override
  String get starterImages => 'Images';

  @override
  String get starterMode => 'Mode';

  @override
  String get newGroupChat => 'Nouveau chat de groupe';

  @override
  String get groupChat => 'Chat de groupe';

  @override
  String get groupChatMultipleModels => 'Discuter avec plusieurs modèles';

  @override
  String get groupChatParticipants => 'Participants';

  @override
  String get groupChatTurnMode => 'Mode de tour';

  @override
  String get groupChatRoundRobin => 'Tour à tour';

  @override
  String get groupChatManual => 'Manuel';

  @override
  String get groupChatParallelStreaming => 'Streaming parallèle';

  @override
  String get groupChatAutoLoadUnload => 'Chargement/déchargement auto';

  @override
  String get groupChatStreamAllSimultaneously =>
      'Streamer tous les participants simultanément';

  @override
  String get groupChatAutoLoadModels => 'Charger les modèles automatiquement';

  @override
  String get groupChatAsk => 'Demander :';

  @override
  String get groupChatTapToReplyNudge => 'Touchez qui doit répondre';

  @override
  String get groupChatTrialBannerTitle =>
      'Chat de groupe — Gratuit pendant 7 jours !';

  @override
  String get groupChatTrialBannerBody =>
      'Essayez le chat de groupe gratuitement pendant 7 jours avec jusqu\'à 2 personas IA. Passez à LM Mini Pro pour un accès illimité.';

  @override
  String groupChatTrialDaysLeft(int days) {
    return '$days jours restants dans votre essai';
  }

  @override
  String get groupChatTrialExpired =>
      'Votre essai de 7 jours pour le chat de groupe est terminé. Passez à Pro pour continuer.';

  @override
  String get groupChatTrialGetPro => 'Passer à Pro';

  @override
  String get groupChatTrialDismiss => 'Compris';

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
  String get premiumGroupChat => 'Chat de groupe';

  @override
  String get premiumGroupChatTagline => 'Conversations multi-personas';

  @override
  String get premiumGroupChatDescription =>
      'Discutez avec plusieurs personas IA dans un fil — chacune avec son modèle, avatar et personnalité. Configuration gratuite ; l\'envoi de messages nécessite LM Mini Pro.';

  @override
  String get groupChatProRequiredTitle => 'Le chat de groupe nécessite Pro';

  @override
  String get groupChatProRequiredBody =>
      'Vous pouvez explorer la configuration et lire d\'anciennes conversations gratuitement. Passez à LM Mini Pro pour envoyer des messages et continuer à discuter avec plusieurs personas IA.';

  @override
  String get groupChatProRequiredUpgrade => 'Passer à Pro';

  @override
  String get groupChatLockedBanner =>
      'Le chat de groupe est en lecture seule sans Pro. Passez à Pro pour envoyer des messages.';

  @override
  String get premiumArena => 'Arène';

  @override
  String get premiumArenaTagline => 'Comparez les modèles côte à côte';

  @override
  String get premiumArenaDescription =>
      'Lancez le même prompt sur plusieurs modèles et comparez réponses, vitesse et compatibilité appareil. Le mode benchmark note les modèles avec une grille transparente.';

  @override
  String get startLabel => 'Démarrer';

  @override
  String groupChatInviteUpTo(int count) {
    return 'Invitez jusqu\'à $count modèles d\'IA à discuter ensemble. Chacun peut avoir sa propre persona, son avatar et son prompt système.';
  }

  @override
  String get groupChatPremiumParticipantsNote =>
      'Premium permet jusqu\'à 5 participants par chat de groupe.';

  @override
  String get groupChatUserNameHint =>
      'Comment les IA s\'adresseront à vous (par ex. Alex)';

  @override
  String get groupChatScenarioLabel =>
      'Scénario / à propos de vous (optionnel)';

  @override
  String get groupChatScenarioHint =>
      'par ex. « Nous sommes collègues dans une startup tech. Je suis chef de produit et je demande conseil à l\'équipe. »';

  @override
  String get groupChatTurnModeRoundRobinDescription =>
      'Tour à tour — tous les modèles répondent dans l\'ordre';

  @override
  String get groupChatTurnModeManualDescription =>
      'Manuel — tapez @Nom pour choisir qui répond';

  @override
  String get groupChatReplyToUserOnlyLabel =>
      'Répondre uniquement à l\'utilisateur';

  @override
  String get groupChatReplyToUserOnlySubtitle =>
      'Chaque IA ignore les autres IA, ce qui évite les échanges croisés sur les petits modèles';

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
      'Aucun modèle disponible. Connectez-vous d\'abord à LM Studio.';

  @override
  String get addModelLabel => 'Ajouter un modèle';

  @override
  String modelNumber(int number) {
    return 'Modèle $number';
  }

  @override
  String groupChatParticipantInfo(String name, String model) {
    return '$name\nModèle : $model';
  }

  @override
  String get customPromptSet => 'Prompt personnalisé défini';

  @override
  String get removeLabel => 'Retirer';

  @override
  String get displayNameLabel => 'Nom d\'affichage';

  @override
  String get displayNameHint => 'par ex. Professeur, Développeur, Artiste';

  @override
  String get customRequestHeaders => 'En-têtes de requête personnalisés';

  @override
  String get customRequestHeadersSubtitle =>
      'En-têtes facultatifs ajoutés à chaque requête LM Studio';

  @override
  String get customRequestHeadersHelp =>
      'À utiliser pour les reverse proxies ou passerelles d\'authentification nécessitant des en-têtes supplémentaires (par ex. les jetons de service Cloudflare Access, un jeton interne sous un nom d\'en-tête personnalisé, etc.). Les en-têtes sont envoyés à chaque requête vers votre serveur LM Studio.';

  @override
  String get cloudflareAccessSection => 'Cloudflare Access (jeton de service)';

  @override
  String get cloudflareAccessHelp =>
      'Si votre LM Studio est derrière une politique Cloudflare Access, collez ici l\'ID client et le secret du jeton de service. Ils sont envoyés en tant que CF-Access-Client-Id et CF-Access-Client-Secret à chaque requête, afin que l\'app puisse s\'authentifier sans connexion SSO interactive dans le navigateur.';

  @override
  String get cfAccessClientIdLabel => 'CF-Access-Client-Id';

  @override
  String get cfAccessClientSecretLabel => 'CF-Access-Client-Secret';

  @override
  String get addHeader => 'Ajouter un en-tête';

  @override
  String get removeHeader => 'Supprimer l\'en-tête';

  @override
  String get headerNameLabel => 'Nom de l\'en-tête';

  @override
  String get headerValueLabel => 'Valeur de l\'en-tête';

  @override
  String headersConfigured(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count en-têtes configurés',
      one: '1 en-tête configuré',
    );
    return '$_temp0';
  }

  @override
  String get noCustomHeaders => 'Aucun en-tête personnalisé';

  @override
  String get comfyUiUseNegativePromptTitle => 'Utiliser un prompt négatif';

  @override
  String get comfyUiUseNegativePromptSubtitle =>
      'Désactivé par défaut pour ComfyUI. Lorsqu\'il est désactivé, aucun prompt négatif n\'est envoyé au workflow.';

  @override
  String get documentationTitle => 'Documentation';

  @override
  String get documentationSubtitle =>
      'Guides de configuration pour le Chat de groupe, ComfyUI, le comportement du clavier, et plus';

  @override
  String get changelogTitle => 'Journal des modifications';

  @override
  String get changelogSubtitle => 'Historique des versions et mises à jour';

  @override
  String get enableCustomHeaders => 'Activer les en-têtes personnalisés';

  @override
  String get enableCustomHeadersSubtitle =>
      'Joindre des en-têtes HTTP supplémentaires à chaque requête LM Studio';

  @override
  String deleteMemoriesCount(int count) {
    return 'Supprimer $count souvenirs ?';
  }

  @override
  String get deleteMemoriesConfirm =>
      'Ces souvenirs seront définitivement supprimés.';

  @override
  String get moveToCategory => 'Déplacer vers une catégorie';

  @override
  String nSelected(int count) {
    return '$count sélectionné(s)';
  }

  @override
  String movedToCategory(String category) {
    return 'Déplacé vers $category';
  }

  @override
  String get moveCategoryTooltip => 'Déplacer la catégorie';

  @override
  String get memoryScreenSubtitle =>
      'Faits que l’IA retient à votre sujet d’une conversation à l’autre.';

  @override
  String get rememberMe => 'Se souvenir de moi';

  @override
  String get rememberMeSubtitle =>
      'Utiliser les notes enregistrées dans les prochaines conversations';

  @override
  String get memoryPerPersona => 'Par persona';

  @override
  String get memoryPerPersonaSubtitle =>
      'Partager les notes uniquement avec la persona active (et les globales)';

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
  String get memoryBrowseSection => 'Parcourir';

  @override
  String get memoryMultiSelectTip =>
      'Astuce : appui long sur une note pour en sélectionner plusieurs.';

  @override
  String get memoryEmptyFilteredHint =>
      'Ajoutez une note ou choisissez une autre catégorie.';

  @override
  String get memoryEmptyHint =>
      'Enregistrez quelques infos sur vous — nom, préférences, projets — pour des chats plus personnels.';

  @override
  String get memoryShareWith => 'Partager avec';

  @override
  String get memoryEveryone => 'Tout le monde';

  @override
  String get memoryEveryoneSubtitle => 'Disponible dans chaque chat';

  @override
  String get memoryNoPersonasHint =>
      'Pas encore de personas. Créez-en une dans Réglages → Personas.';

  @override
  String get memoryNewNote => 'Nouvelle note';

  @override
  String get memoryNoteHint =>
      'ex. Je préfère des réponses courtes et j’habite à Berlin';

  @override
  String get memoryEditNote => 'Modifier la note';

  @override
  String monthsAgo(int count) {
    return 'il y a $count mois';
  }

  @override
  String get moreTooltip => 'Plus';

  @override
  String get closeSearch => 'Fermer la recherche';

  @override
  String get moveTooltip => 'Déplacer';

  @override
  String get chatsTab => 'Chats';

  @override
  String get groupsTab => 'Groupes';

  @override
  String get foldersTooltip => 'Dossiers';

  @override
  String get newFolder => 'Nouveau dossier';

  @override
  String get tapToReturnToCall => 'Appuyer pour revenir à l’appel';

  @override
  String get selectConversation => 'Sélectionner une conversation';

  @override
  String get selectConversationHint =>
      'Choisissez-en une dans la liste ou démarrez un nouveau chat.';

  @override
  String get noGroupChatsYet => 'Pas encore de chats de groupe';

  @override
  String get noGroupChatsSubtitle =>
      'Démarrez une conversation multi-personas pour parler à plusieurs IA.';

  @override
  String get newPersonaShort => 'Nouveau';

  @override
  String get downloadOnDeviceModelTitle =>
      'Télécharger un modèle sur l’appareil';

  @override
  String get downloadOnDeviceModelBody =>
      'Téléchargez un modèle pour chatter sans PC, ou connectez LM Studio / Ollama.';

  @override
  String get browseModels => 'Parcourir les modèles';

  @override
  String get waitingForMac => 'En attente du Mac';

  @override
  String get waitingForMacBody =>
      'Branchez votre iPhone au Mac en USB, puis ouvrez LM Mini Connect sur le Mac.';

  @override
  String get arenaMode => 'Mode Arena';

  @override
  String get voiceWhisperSizeInfoTitle =>
      'Les plus grands modèles entendent mieux';

  @override
  String get voiceWhisperSizeInfoBody =>
      'Les modèles d’écoute plus grands sont généralement plus précis, surtout avec les accents et le bruit. Ils occupent aussi plus d’espace et peuvent charger un peu plus lentement.';

  @override
  String get voiceRemoveListeningModelTitle => 'Retirer le modèle d’écoute ?';

  @override
  String get voiceRemoveListeningModelBody =>
      'Cela libère de l’espace. Voice Call et le micro auront besoin du modèle à nouveau pour l’écoute hors ligne.';

  @override
  String get voiceTtsOnDeviceNeural => 'Voix téléchargée';

  @override
  String get voiceTtsPcVoice => 'Voix PC';

  @override
  String get voiceTtsSystemVoice => 'Voix système';

  @override
  String get voiceTtsOnDeviceHint =>
      'Voix naturelles à télécharger. Fonctionne sans internet.';

  @override
  String get voiceTtsPcHint =>
      'Utiliser un modèle vocal sur l’ordinateur via Partager avec le téléphone';

  @override
  String get voiceTtsSystemHint =>
      'Les voix de votre téléphone — prêtes tout de suite';

  @override
  String get voiceSttOnDevice => 'Sur cet appareil';

  @override
  String get voiceSttWhisperHint =>
      'Modèle hors ligne — généralement plus précis';

  @override
  String get voiceSttSystemHint => 'Reconnaissance intégrée — rapide et simple';

  @override
  String get voiceSttSystemUnavailableOnMac => 'Téléchargement requis';

  @override
  String get voiceSttMacosRequiresWhisper =>
      'Les builds App Store utilisent Whisper sur l’appareil pour l’écoute. Téléchargez un modèle pour l’activer.';

  @override
  String get voiceSttMacosSystemOptionSubtitle =>
      'Téléchargez Whisper pour activer l’écoute';

  @override
  String get voiceSttMacosDownloadWhisper =>
      'Téléchargez Whisper pour activer l’écoute';

  @override
  String get voiceSettingsIntro =>
      'Comment les réponses sont parlées et comment votre voix est comprise.';

  @override
  String get voiceSectionReady => 'Prêt';

  @override
  String get voiceSectionSpeaking => 'Parole';

  @override
  String get voiceSectionListening => 'Écoute';

  @override
  String get voiceSectionConversation => 'Conversation';

  @override
  String get voiceStatusSpeaking => 'Parole';

  @override
  String get voiceStatusListening => 'Écoute';

  @override
  String get voiceHowISpeak => 'Comment je parle';

  @override
  String get voiceImportPack => 'Importer un pack vocal';

  @override
  String get voiceImportPackSubtitle =>
      'Collez une URL GitHub vers un pack vocal';

  @override
  String get voiceHowIHearYou => 'Comment je vous entends';

  @override
  String get voiceHowIHearYouSubtitle =>
      'Choisissez comment votre parole devient du texte.';

  @override
  String get voiceListeningModel => 'Modèle d’écoute';

  @override
  String get voiceAboutModelSizes => 'À propos des tailles de modèle';

  @override
  String get voicePauseBeforeSend => 'Pause avant envoi';

  @override
  String get voicePauseBeforeSendSubtitle =>
      'Temps d’attente après que vous avez arrêté de parler';

  @override
  String get voiceListeningLimit => 'Limite d’écoute';

  @override
  String get voiceListeningLimitSubtitle =>
      'Durée max avant redémarrage du micro';

  @override
  String get voiceQuickTip => 'Astuce rapide';

  @override
  String get voiceQuickTipBody =>
      'Pour une voix plus naturelle, téléchargez une langue dans Packs de voix. La voix système fonctionne tout de suite.';

  @override
  String get voiceTestSampleHint =>
      'Écouter un court échantillon avec vos réglages actuels';

  @override
  String get voiceTestNoPackReady =>
      'Téléchargez une langue dans Packs de voix, puis réessayez Test Voice.';

  @override
  String get voiceChooseListeningModel =>
      'Appuyer pour choisir un modèle d’écoute';

  @override
  String get voiceModelReady => 'Prêt';

  @override
  String get voiceNeedsDownload => 'Téléchargement requis';

  @override
  String get voiceDownloaded => 'Téléchargé';

  @override
  String get voiceDownloadFailed => 'Échec du téléchargement';

  @override
  String get voiceFinishingSetup => 'Finalisation…';

  @override
  String get voiceDownloadingListeningModel =>
      'Téléchargement du modèle d’écoute…';

  @override
  String get voiceDownloadingVoice => 'Téléchargement de la voix…';

  @override
  String get voiceStartingDownload => 'Démarrage du téléchargement…';

  @override
  String get voiceReady => 'Voix prête';

  @override
  String get voiceWarmingUp => 'Préparation…';

  @override
  String get voiceReadyToSpeak => 'Prêt à parler';

  @override
  String get voiceDownloadOnDevice => 'Télécharger la voix sur l’appareil';

  @override
  String get voiceDownloadFailedRetry =>
      'Échec du téléchargement — appuyer pour réessayer';

  @override
  String get voiceSpokenReplyLanguage => 'Langue des réponses parlées';

  @override
  String get voiceSpokenReplyLanguageSubtitle =>
      'Langue utilisée quand l’assistant lit les messages à voix haute.';

  @override
  String get voiceRecognitionLanguage => 'Langue de reconnaissance';

  @override
  String get voiceRecognitionLanguageSubtitle =>
      'Pour le micro texte et Voice Call — peut différer des réponses parlées.';

  @override
  String get voiceEngineTitle => 'Voix parlée';

  @override
  String get voiceEngineSubtitle => 'Choisissez d’où vient la voix parlée.';

  @override
  String get voiceChooseAVoice => 'Choisir une voix';

  @override
  String get voiceChooseAVoiceSubtitle =>
      'Noms faciles à prévisualiser pour la voix sur l’appareil.';

  @override
  String get voiceUseSystemDefault => 'Utiliser la voix système par défaut';

  @override
  String get welcomeWizardTitleGetStarted => 'Commencer';

  @override
  String get welcomeWizardTitleYourSetup => 'Votre configuration';

  @override
  String get welcomeWizardTitleLookAndFeel => 'Apparence';

  @override
  String get welcomeWizardTitleAlmostDone => 'Presque terminé';

  @override
  String get welcomeWizardTitleSetup => 'Configuration';

  @override
  String get welcomeWizardLmStudioSubtitle =>
      'Exécutez des modèles sur Mac ou PC';

  @override
  String get welcomeWizardOllamaSubtitle => 'Serveur local populaire';

  @override
  String get welcomeWizardOmlxSubtitle => 'Serveur bureau Apple Silicon';

  @override
  String get welcomeWizardJanSubtitle => 'Modèles locaux via l’app JAN AI';

  @override
  String get welcomeWizardUnslothSubtitle =>
      'Unsloth Desktop sur votre ordinateur';

  @override
  String get welcomeWizardThemeSubtitle =>
      'Choisissez un style. Vous pourrez le changer à tout moment.';

  @override
  String get welcomeWizardModelReady => 'Prêt';

  @override
  String get welcomeWizardConnected => 'Connecté';

  @override
  String get welcomeWizardServerFound => 'Serveur trouvé';

  @override
  String get welcomeWizardRequiresApiKey => 'Clé API requise';

  @override
  String get welcomeWizardScanHomeQr => 'Scanner le QR LM Mini Home';

  @override
  String get welcomeWizardScanHomeQrSubtitle =>
      'Associez votre Mac via Partager avec le téléphone';

  @override
  String welcomeWizardModelsFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count modèles trouvés',
      one: '1 modèle trouvé',
    );
    return '$_temp0';
  }

  @override
  String get welcomeWizardLocalNetworkTitle => 'Autoriser l’accès réseau';

  @override
  String get welcomeWizardLocalNetworkBody =>
      'Vous serez invité à autoriser l’accès au réseau local. Acceptez pour que LM Mini puisse trouver LM Mini Home, LM Studio ou Ollama sur votre ordinateur.';

  @override
  String get welcomeWizardLocalNetworkAllow => 'Autoriser';

  @override
  String get welcomeWizardDownloadKeepsGoing =>
      'Vous pouvez quitter cet écran — le téléchargement continue, même si vous quittez l’app.';

  @override
  String get welcomeWizardDownloadFailed =>
      'Échec du téléchargement. Touchez pour réessayer.';

  @override
  String get welcomeWizardAiDownloadingTitle =>
      'L’IA est en cours de téléchargement';

  @override
  String get welcomeWizardAiDownloadingBody =>
      'Vous pourrez discuter dès que l’IA idéale pour votre téléphone sera prête. C’est un téléchargement unique.';

  @override
  String get onDeviceModels => 'Modèles sur l’appareil';

  @override
  String get transcription => 'Transcription';

  @override
  String get widgetSettings => 'Réglages des widgets';

  @override
  String get widgetSettingsSubtitle =>
      'Configurer les widgets de l’écran d’accueil';

  @override
  String get setUpShortcuts => 'Configurer les raccourcis';

  @override
  String get shareArenaSpeedResults =>
      'Partager les résultats de vitesse Arena';

  @override
  String get browseOnDeviceModels => 'Parcourir les modèles sur l’appareil';

  @override
  String get homeDownloadModel => 'Télécharger un modèle';

  @override
  String get usbMode => 'Mode USB';

  @override
  String get usbModeHowItWorks => 'Comment fonctionne le mode USB';

  @override
  String get switchToUsbTitle => 'Passer de Distant à USB ?';

  @override
  String get switchLabel => 'Basculer';

  @override
  String usbModeStartFailed(String error) {
    return 'Impossible de démarrer le mode USB : $error';
  }

  @override
  String get usbModeHowToUse => 'Comment l’utiliser :';

  @override
  String get openLmminiCom => 'Ouvrir lmmini.com';

  @override
  String get tapToUseServer => 'Appuyer pour utiliser ce serveur';

  @override
  String get memoryPersonaFallback => 'Persona';

  @override
  String get voicePickSystemVoiceSubtitle =>
      'Choisissez une voix intégrée pour les réponses parlées.';

  @override
  String get chooseFromGallery => 'Choisir depuis la galerie';

  @override
  String get galleryLimitsSubtitle =>
      'Photos jusqu’à 10 Mo · Vidéos jusqu’à 200 Mo';

  @override
  String get recordVideo => 'Enregistrer une vidéo';

  @override
  String attachmentsCount(int count, int max) {
    return 'Pièces jointes ($count/$max)';
  }

  @override
  String get viewProfile => 'Voir le profil';

  @override
  String get personaAndModel => 'Persona et modèle';

  @override
  String get chatOptions => 'Options du chat';

  @override
  String get chatTab => 'Chat';

  @override
  String get voiceTab => 'Voix';

  @override
  String get craftingPersona => 'Création de la persona…';

  @override
  String get randomPersona => 'Surprends-moi';

  @override
  String get savePersona => 'Enregistrer la persona';

  @override
  String get downloadFinished => 'Téléchargement terminé.';

  @override
  String get downloadCancelled => 'Téléchargement annulé.';

  @override
  String get downloadCancelFailed =>
      'Impossible d’annuler dans LM Studio. Arrêtez-le dans la liste des téléchargements de LM Studio.';

  @override
  String get newsBriefing => 'Briefing actualités';

  @override
  String get refreshNow => 'Actualiser maintenant';

  @override
  String get noBriefingYet => 'Pas encore de briefing';

  @override
  String get newsSetPromptFirst =>
      'Définissez d’abord un prompt du widget News dans Réglages des widgets.';

  @override
  String get newsRefreshed => 'Actualités mises à jour.';

  @override
  String newsRefreshFailed(String error) {
    return 'Échec de l’actualisation : $error';
  }

  @override
  String get themesTitle => 'Thèmes';

  @override
  String get createLabel => 'Créer';

  @override
  String get browseLabel => 'Parcourir';

  @override
  String get signInToUploadThemes =>
      'Connectez-vous pour téléverser des thèmes';

  @override
  String get deleteThemeTitle => 'Supprimer le thème ?';

  @override
  String deleteThemeConfirm(String name) {
    return 'Retirer « $name » de vos thèmes téléchargés ?';
  }

  @override
  String get uploadToCommunity => 'Téléverser vers la communauté';

  @override
  String get installedLabel => 'Installé';

  @override
  String get getLabel => 'Obtenir';

  @override
  String get bestForYou => 'Idéal pour vous';

  @override
  String get loadingLabel => 'Chargement';

  @override
  String get loadedLabel => 'Chargé';

  @override
  String get notLoadedLabel => 'Non chargé';

  @override
  String get reasoningLabel => 'Raisonnement';

  @override
  String get imagesLabel => 'Images';

  @override
  String get detailsTooltip => 'Détails';

  @override
  String get transcribeAudio => 'Transcrire l’audio';

  @override
  String get transcribeAudioSubtitle =>
      'Importer un audio et interroger l’IA sur la transcription';

  @override
  String get trimSection => 'Découper la section';

  @override
  String get includeTimestamps => 'Inclure les horodatages';

  @override
  String get phrasesLabel => 'Phrases';

  @override
  String get wordsLabel => 'Mots';

  @override
  String get transcriptionLanguage => 'Langue de transcription';

  @override
  String get searchLanguages => 'Rechercher des langues…';

  @override
  String get transcribe => 'Transcrire';

  @override
  String get shareTranscript => 'Partager la transcription';

  @override
  String get transcriptionContextLargeToast =>
      'Ces transcriptions peuvent être trop longues pour le contexte du modèle. Créez une branche à partir d’un message précédent si les réponses deviennent incomplètes.';

  @override
  String get transcriptionSubtitlesOn => 'Sous-titres activés';

  @override
  String get transcriptionSubtitlesOff => 'Sous-titres désactivés';

  @override
  String get transcriptionFullClip => 'Audio complet';

  @override
  String get transcriptionJobRunning => 'Transcription…';

  @override
  String get transcriptionJobDone => 'Transcrit';

  @override
  String get transcriptionJobFailed => 'Échec de la transcription';

  @override
  String get branchFromHere => 'Bifurquer depuis ici';

  @override
  String get memoryUpdates => 'Mises à jour mémoire';

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
  String get personaShareMemoryCategoriesLabel => 'Catégories à partager';

  @override
  String get personaShareMemoryCategoriesSubtitle =>
      'Choisissez quels types de souvenirs cette persona peut utiliser dans les chats.';

  @override
  String get chooseFaceForBubbles => 'Choisir le visage pour les bulles';

  @override
  String get moveMemories => 'Déplacer les souvenirs';

  @override
  String get deletePersonaAndMemories => 'Supprimer persona + souvenirs';

  @override
  String get moveMemoriesTo => 'Déplacer les souvenirs vers…';

  @override
  String get globalSharedMemories =>
      'Global (partagé avec toutes les personas)';

  @override
  String personaMemoriesAssignedHint(int count, String name) {
    return '$count souvenir(s) sont assignés à « $name ».\nChoisissez ce qu’il faut en faire :';
  }

  @override
  String get homeSyncTitle => 'Garder les discussions synchronisées ?';

  @override
  String homeSyncBodyBoth(int phoneChats, int macChats) {
    return 'Ce téléphone a $phoneChats discussions et LM Mini Home en a $macChats. Activez la synchro pour fusionner conversations et dossiers et continuer sur n’importe quel appareil. Utilise votre relais chiffré existant.';
  }

  @override
  String get homeSyncBodyPhoneOnly =>
      'Copiez les discussions et dossiers de ce téléphone vers LM Mini Home, puis gardez-les synchronisés via le relais chiffré.';

  @override
  String get homeSyncBodyMacOnly =>
      'Récupérez les discussions et dossiers de LM Mini Home sur ce téléphone, puis gardez-les synchronisés via le relais chiffré.';

  @override
  String get homeSyncBodyGeneric =>
      'Fusionnez conversations et dossiers entre ce téléphone et LM Mini Home pour continuer sur n’importe quel appareil. Utilise votre relais chiffré existant.';

  @override
  String get homeSyncEnable => 'Activer la synchro';

  @override
  String get homeSyncNotNow => 'Pas maintenant';

  @override
  String get homeSyncSettingsTitle => 'Synchroniser avec Home';

  @override
  String get homeSyncSettingsSubtitle =>
      'Fusionner conversations et dossiers via le relais chiffré';

  @override
  String get homeSyncMergedToast =>
      'Discussions et dossiers sont maintenant synchronisés';

  @override
  String get homeSyncFailedToast =>
      'Échec de la synchro. Ouvrez Share with phone sur le Mac et réessayez.';

  @override
  String get homeSyncPersonasTitle => 'Synchroniser les personas';

  @override
  String get homeSyncPersonasSubtitle =>
      'Copier celles que vous choisissez, photos et souvenirs compris';

  @override
  String get homeSyncPersonasPickTitle => 'Choisir les personas';

  @override
  String get homeSyncPersonasPickSubtitle =>
      'Les personas cochées sont copiées entre cet appareil et Home, avec leur photo et leurs souvenirs.';

  @override
  String get homeSyncPersonasSave => 'Enregistrer et synchroniser';

  @override
  String get homeSyncPersonasSavedToast => 'Personas synchronisées';

  @override
  String get homeSyncPersonasEmpty => 'Aucune persona à copier pour le moment.';

  @override
  String get homeSyncPersonasUnreachable =>
      'Impossible de joindre Home. Ouvrez Share with phone sur le Mac, puis réessayez.';

  @override
  String get homeSyncPersonasOnBoth => 'Sur les deux appareils';

  @override
  String get homeSyncPersonasOnHome => 'LM Mini Home';

  @override
  String get homeSyncPersonasOnPhone => 'votre téléphone';

  @override
  String get homeSyncPersonasThisPhone => 'ce téléphone';

  @override
  String homeSyncPersonasOnDevice(String device) {
    return 'Sur $device';
  }

  @override
  String homeSyncPersonasMemoryCount(int count) {
    return '$count souvenirs';
  }

  @override
  String get homeSyncPersonasNoMemories => 'Pas encore de souvenirs';

  @override
  String get reportToSupport => 'Envoyer au support';

  @override
  String get localhostConnectionHelp =>
      'Impossible de joindre localhost. Sur un téléphone, localhost désigne cet appareil, pas votre ordinateur. Dans Réglages, utilisez l’adresse IP de l’ordinateur (ex. http://192.168.1.10:1234) et restez sur le même Wi‑Fi.';

  @override
  String get lmStudioPcNotAllowingTitle => 'Votre PC refuse la connexion';

  @override
  String get lmStudioPcNotAllowingBody =>
      'Dans LM Studio, sur l’ordinateur, ouvrez Developer → Server Settings et activez Serve on Local Network.';

  @override
  String get lmStudioHostDownTitle => 'PC injoignable';

  @override
  String get lmStudioHostDownStep1 =>
      'Vérifiez que l’ordinateur est allumé — pas en veille ni éteint.';

  @override
  String get lmStudioHostDownStep2 =>
      'Dans LM Studio, ouvrez Developer → Server Settings et activez Serve on Local Network.';

  @override
  String get cantReachMacTitle => 'Mac injoignable';

  @override
  String get cantReachMacStep1 =>
      'Ouvrez Share with phone dans LM Mini Home sur le Mac.';

  @override
  String get cantReachMacStep2 =>
      'Attendez qu’il indique Connected, puis réessayez.';

  @override
  String get lmStudioServerSettingsImageLabel =>
      'LM Studio Developer → Server Settings. Serve on Local Network doit être activé.';

  @override
  String get modelMissingTitle => 'Ce modèle n’est pas sur votre PC';

  @override
  String get modelMissingBody =>
      'Le modèle choisi n’est pas disponible. Choisissez-en un autre dans Sélection du modèle.';

  @override
  String modelMissingBodyNamed(String model) {
    return '« $model » n’est pas sur l’ordinateur. Choisissez-en un autre dans Sélection du modèle.';
  }

  @override
  String get outputTokensExhaustedTitle =>
      'Le modèle n’a plus de jetons de sortie';

  @override
  String get outputTokensExhaustedBody =>
      'Les outils ont abouti, mais il ne restait pas assez de jetons pour la réponse. Augmentez le maximum et réessayez.';

  @override
  String get thinkingBudgetRetryTitle => 'Thinking used the output limit';

  @override
  String get thinkingBudgetRetryBody =>
      'High thinking filled the output limit, so this reply uses low thinking. Raise max tokens to keep high thinking.';

  @override
  String get adjustMaxTokens => 'Ajuster les jetons max';

  @override
  String get ggmlSchedulerCrashBody =>
      'Le serveur du modèle a planté (ordonnanceur llama.cpp). Ce n\'est pas Mini. Réduisez la longueur de contexte et le max de jetons — de très grandes valeurs (par exemple 128k de contexte) causent souvent cela.';

  @override
  String get generationTerminatedBody =>
      'LM Studio a arrêté la génération sur votre ordinateur (le processus a été terminé).';

  @override
  String generationTerminatedHugeImageBody(String size) {
    return 'LM Studio a arrêté la génération sur votre ordinateur. Votre image jointe est probablement énorme ($size) — compressez-la et renvoyez.';
  }

  @override
  String get compressAndResendImages => 'Compresser l\'image et renvoyer';

  @override
  String get imageCompressFailed =>
      'Impossible de réduire l\'image jointe. Essayez une photo plus petite.';

  @override
  String get droppedChatBodyHelp =>
      'Mini a envoyé ce chat, mais il n\'est jamais arrivé à LM Studio. Si un proxy, un tunnel ou une autre URL se trouve devant LM Studio, essayez sans — ou pointez Mini directement vers LM Studio (l\'IP de votre ordinateur, USB ou Connect).';

  @override
  String get comfyUiNoCheckpointsTitle => 'ComfyUI n’a pas de modèle d’image';

  @override
  String get comfyUiNoCheckpointsBody =>
      'ComfyUI n’a aucun checkpoint. Ajoutez un fichier .safetensors dans models/checkpoints de ComfyUI, puis choisissez-le dans Génération d’images.';

  @override
  String get comfyUiNoCheckpointSelectedBody =>
      'Aucun modèle d’image n’est sélectionné. Ouvrez Génération d’images et choisissez un checkpoint.';

  @override
  String comfyUiUnknownCheckpointBody(String name) {
    return 'ComfyUI n’a pas le checkpoint « $name ». Choisissez-en un autre dans Génération d’images.';
  }

  @override
  String get comfyUiWorkflowRejectedBody =>
      'ComfyUI a rejeté le workflow. Vérifiez Génération d’images.';

  @override
  String get comfyUiDiffusionOnlyTitle =>
      'Ce graphe a besoin de votre workflow ComfyUI';

  @override
  String get comfyUiDiffusionOnlyBody =>
      'Le workflow intégré de Mini charge un checkpoint SD classique. Votre graphe Comfy Desktop utilise un modèle de diffusion (UNET) plus CLIP et VAE. Exportez-le au format API (Workflow → Export) et choisissez ce fichier dans Génération d’images.';

  @override
  String get openImageSettings => 'Réglages image';

  @override
  String imageGenUnreachableTitle(String name) {
    return 'Impossible d’atteindre $name';
  }

  @override
  String imageGenUnreachableBody(String name, String url) {
    return 'Rien ne répond à $url. Lancez $name sur l’ordinateur et restez sur le même Wi‑Fi.';
  }

  @override
  String get imageGenUnreachableNoUrlBody =>
      'Aucun serveur d’images n’est défini. Ajoutez ComfyUI ou AUTOMATIC1111 dans Génération d’images.';

  @override
  String get sharedHostUpdateImageTitle =>
      'Mettre à jour aussi la génération d’images ?';

  @override
  String sharedHostUpdateChatTitle(String name) {
    return 'Mettre à jour aussi $name ?';
  }

  @override
  String sharedHostUpdateBody(
      String changedName, String peerName, String oldHost, String newUrl) {
    return '$changedName et $peerName étaient tous les deux sur $oldHost. Mettre $peerName sur $newUrl ?';
  }

  @override
  String get sharedHostUpdateConfirm => 'Mettre à jour et tester';

  @override
  String get sharedHostUpdateSkip => 'Garder l’actuel';

  @override
  String sharedHostTesting(String name) {
    return 'Test de $name…';
  }

  @override
  String get sharedHostTestSuccessTitle => 'Connecté';

  @override
  String sharedHostTestSuccessBody(String name, String url) {
    return '$name joignable à $url.';
  }

  @override
  String get sharedHostTestFailTitle => 'Connexion impossible';

  @override
  String sharedHostTestFailBody(String name, String url, String error) {
    return '$name a été mis à jour vers $url, mais Mini n’a pas pu le joindre. $error';
  }

  @override
  String get supportTicketTitle => 'Signaler un problème';

  @override
  String get supportTicketPrefillDescription =>
      'Un fichier journal avec les détails de l’erreur est joint. Ajoutez toute autre information utile :';

  @override
  String get supportTicketSubmitted =>
      'Merci — votre signalement a été envoyé.';

  @override
  String get supportTicketAlreadyOpen =>
      'Vous avez déjà un signalement ouvert pour cette erreur.';

  @override
  String get supportTicketViewExisting => 'Voir le signalement';

  @override
  String get supportTicketAlreadySending =>
      'Cette erreur est déjà en cours de signalement.';

  @override
  String get supportUnavailable =>
      'Le support n’est pas disponible pour le moment. Réessayez une fois en ligne.';

  @override
  String get somethingWentWrong => 'Une erreur s’est produite';

  @override
  String get uncaughtErrorSnack => 'Une erreur s’est produite.';

  @override
  String get errorLogLabel => 'LOG';

  @override
  String get appLock => 'Verrouillage';

  @override
  String get appLockSubtitleOff => 'Demander un code PIN après fermeture';

  @override
  String appLockSubtitleOn(String duration) {
    return 'Redemande après $duration';
  }

  @override
  String get appLockUnlockTitle => 'LM Mini est verrouillé';

  @override
  String get appLockDescription =>
      'Protégez les discussions de cet appareil avec un code PIN et Face ID en option. Le code reste sur cet appareil et n’est jamais synchronisé.';

  @override
  String get appLockEnable => 'Verrouiller avec un PIN';

  @override
  String get appLockEnableSubtitle => 'Demander le PIN au retour';

  @override
  String get appLockPinLength4 => '4 chiffres';

  @override
  String get appLockPinLength6 => '6 chiffres';

  @override
  String get appLockRequireAfter => 'Redemander après';

  @override
  String get appLockTimeoutImmediate => 'Immédiatement';

  @override
  String get appLockTimeout15s => '15 secondes';

  @override
  String get appLockTimeout1m => '1 minute';

  @override
  String get appLockTimeout5m => '5 minutes';

  @override
  String get appLockTimeout15m => '15 minutes';

  @override
  String get appLockTimeout1h => '1 heure';

  @override
  String get appLockChangePin => 'Changer le PIN';

  @override
  String get appLockEnterCurrentPin => 'Saisir le PIN actuel';

  @override
  String get appLockChooseNewPin => 'Choisir un PIN';

  @override
  String get appLockConfirmPin => 'Confirmer le PIN';

  @override
  String get appLockPinsDontMatch => 'Les PIN ne correspondent pas. Réessayez.';

  @override
  String get appLockWrongPin => 'PIN incorrect. Réessayez.';

  @override
  String appLockTooManyAttempts(int seconds) {
    return 'Trop de tentatives. Réessayez dans ${seconds}s.';
  }

  @override
  String get appLockForgotHint =>
      'Si vous oubliez le PIN, vous pouvez le réinitialiser via un e-mail de vérification envoyé à votre compte. Connectez-vous avant de perdre le PIN, sinon vous ne pourrez pas le récupérer.';

  @override
  String get appLockProRequired => 'Le verrouillage est une fonction Pro';

  @override
  String get appLockEnabledToast => 'Verrouillage activé';

  @override
  String get appLockDisabledToast => 'Verrouillage désactivé';

  @override
  String get appLockChangedToast => 'PIN mis à jour';

  @override
  String appLockBiometricsToggle(String method) {
    return 'Déverrouiller avec $method';
  }

  @override
  String get appLockBiometricsSubtitle =>
      'Utilisez Face ID, Touch ID ou l’empreinte à la place du PIN.';

  @override
  String get appLockBiometricFaceId => 'Face ID';

  @override
  String get appLockBiometricFace => 'Déverrouillage facial';

  @override
  String get appLockBiometricTouchId => 'Touch ID';

  @override
  String get appLockBiometricFingerprint => 'Empreinte';

  @override
  String get appLockBiometricGeneric => 'biométrie';

  @override
  String appLockUnlockWithBiometrics(String method) {
    return 'Déverrouiller avec $method';
  }

  @override
  String appLockBiometricsFailed(String method) {
    return 'Impossible de déverrouiller avec $method. Utilisez votre PIN.';
  }

  @override
  String get appLockSignInToRecover =>
      'Connectez-vous, sinon vous ne pourrez pas récupérer le verrouillage si ce PIN est perdu.';

  @override
  String appLockSignInToRecoverBound(String email) {
    return 'Connectez-vous en tant que $email, sinon vous ne pourrez pas récupérer le verrouillage si ce PIN est perdu.';
  }

  @override
  String get appLockNotSignedInNoRecovery =>
      'Vous n’êtes pas connecté. Vous ne pourrez pas récupérer ce PIN s’il est perdu.';

  @override
  String get appLockForgotPin => 'PIN oublié ?';

  @override
  String get appLockSendRecoveryEmail => 'Envoyer un lien de vérification';

  @override
  String appLockRecoveryEmailSent(String email) {
    return 'Nous avons envoyé un e-mail de vérification à $email. Ouvrez-le, puis revenez ici.';
  }

  @override
  String get appLockRecoveryIVerified => 'J’ai vérifié — continuer';

  @override
  String get appLockRecoveryResend => 'Renvoyer l’e-mail';

  @override
  String get appLockRecoveryReauth =>
      'Reconnectez-vous pour réinitialiser le PIN';

  @override
  String appLockRecoveryWrongAccount(String email) {
    return 'Ce PIN est lié à $email. Connectez-vous avec ce compte pour le récupérer.';
  }

  @override
  String get appLockRecoveryUnavailable =>
      'La récupération du PIN n’est pas configurée. Il vous faut ce PIN, ou réinstaller LM Mini.';

  @override
  String get appLockRecoveryFailed =>
      'Impossible de vérifier le compte. Réessayez.';

  @override
  String get appLockRecoveryNoEmail =>
      'Ce compte n’a pas d’e-mail pour envoyer un lien de vérification.';

  @override
  String get appLockRecoveryTooMany =>
      'Trop d’e-mails. Attendez une minute et réessayez.';

  @override
  String get appLockRecoverySetPin => 'Choisir un nouveau PIN';

  @override
  String get appLockContinueWithEmail => 'Continuer avec l’e-mail';

  @override
  String appLockSignedInRecoverHint(String email) {
    return 'Si vous oubliez ce PIN, nous pouvons envoyer un lien de vérification à $email.';
  }

  @override
  String get appLockRecoveryAccount => 'Récupération du PIN';

  @override
  String appLockRecoveryAccountOn(String email) {
    return 'Les e-mails de vérification vont à $email';
  }

  @override
  String get appLockRecoveryAccountOff =>
      'Connectez-vous pour pouvoir récupérer un PIN perdu';

  @override
  String get appLockRecoveryAccountOffSubtitle =>
      'Sans compte, un PIN perdu ne peut être effacé qu’en réinstallant l’app.';

  @override
  String get appLockBackToPin => 'Utiliser le PIN';

  @override
  String get premiumAppLock => 'Verrouillage';

  @override
  String get premiumAppLockTagline => 'Protéger l’app par PIN';

  @override
  String get premiumAppLockDescription =>
      'Définissez un PIN à 4 ou 6 chiffres, déverrouillez avec Face ID et récupérez un PIN perdu par e-mail de vérification. Le PIN reste sur cet appareil.';

  @override
  String spritePanelShow(String name) {
    return 'Afficher l’expression de $name';
  }

  @override
  String get personaExpressionsTitle => 'Expressions';

  @override
  String get personaExpressionsSubtitle =>
      'Des images du personnage qui changent selon l’humeur de chaque réponse. Nomme les images d’après l’expression, comme joy.png ou anger.png, ou importe un zip de sprites SillyTavern.';

  @override
  String get personaExpressionsImport => 'Importer des sprites';

  @override
  String get personaExpressionsRemoveAll => 'Tout supprimer';

  @override
  String personaExpressionsRemoveAllConfirm(String name) {
    return 'Supprimer tous les sprites d’expression de $name ?';
  }

  @override
  String get personaExpressionsReplace => 'Remplacer l’image';

  @override
  String get personaExpressionsRemove => 'Supprimer';

  @override
  String personaExpressionsImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sprites ajoutés',
      one: '1 sprite ajouté',
      zero: 'Aucun sprite ajouté',
    );
    return '$_temp0';
  }

  @override
  String personaExpressionsUnmatched(String files) {
    return 'Ignorés (pas un nom d’expression) : $files';
  }

  @override
  String get personaExpressionsMissing => 'Manquant';

  @override
  String get characterCardImport => 'Importer une carte de personnage';

  @override
  String characterCardImportedOne(String name) {
    return '$name importé';
  }

  @override
  String characterCardImportedMany(int count) {
    return '$count personnages importés';
  }

  @override
  String characterCardImportFailed(String file, String reason) {
    return 'Impossible d’importer $file : $reason';
  }

  @override
  String characterCardLoreSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entrées de lorebook par mot-clé n’ont pas été importées',
      one: '1 entrée de lorebook par mot-clé n’a pas été importée',
    );
    return '$_temp0';
  }

  @override
  String get appearanceExpressionSprites => 'Expressions du personnage';

  @override
  String get appearanceExpressionSpritesSubtitle =>
      'Pour les personas avec des sprites d’expression';

  @override
  String get expressionSpriteModeOff => 'Désactivé';

  @override
  String get expressionSpriteModePanel => 'Grand sprite';

  @override
  String get expressionSpriteModeAvatar => 'Avatar du message';

  @override
  String get expressionSpriteModeBoth => 'Les deux';

  @override
  String get spriteGenerateButton => 'Générer';

  @override
  String get spriteGenerateTitle => 'Générer des expressions';

  @override
  String get spriteGenerateAppearance => 'Apparence';

  @override
  String get spriteGenerateAppearanceHint =>
      'Cheveux, yeux, vêtements et style';

  @override
  String get spriteGenerateSeed => 'Graine';

  @override
  String get spriteGenerateSeedHelp =>
      'La même graine garde le personnage ressemblant d’une expression à l’autre.';

  @override
  String get spriteGenerateCore => '8 de base';

  @override
  String get spriteGenerateAll => 'Les 28';

  @override
  String get spriteGenerateOnlyMissing =>
      'Seulement les expressions manquantes';

  @override
  String spriteGenerateStart(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Générer $count images',
      one: 'Générer 1 image',
    );
    return '$_temp0';
  }

  @override
  String spriteGenerateProgress(int current, int total, String label) {
    return 'Génération $current sur $total : $label';
  }

  @override
  String get spriteGenerateNeedsImageGen =>
      'Configure d’abord la génération d’images dans Réglages → Génération d’images.';

  @override
  String spriteGenerateDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count expressions générées',
      one: '1 expression générée',
    );
    return '$_temp0';
  }

  @override
  String spriteGenerateFailed(String label, String error) {
    return 'Arrêté à $label : $error';
  }

  @override
  String get personaGreetingLabel => 'Premier message (facultatif)';

  @override
  String get personaGreetingHint =>
      'Ce que dit le personnage au début d’une nouvelle conversation';

  @override
  String get personaMemoryOwnOnlyNote =>
      'Ce persona garde sa propre mémoire : il ne voit que ce qu\'il a appris dans ses propres discussions, jamais tes souvenirs partagés.';

  @override
  String get remoteAccessSwitchTitle => 'Utiliser l\'accès à distance';

  @override
  String get remoteAccessSwitchOnSubtitle =>
      'Activé : accède à ton ordinateur de n’importe où.';

  @override
  String get remoteAccessSwitchOffSubtitle =>
      'Désactivé : utilise le serveur de ton réseau domestique. L’appairage est conservé.';

  @override
  String get remoteAccessSwitchConnecting => 'Connexion à ton ordinateur…';

  @override
  String get remoteAccessUnreachable =>
      'L’accès à distance est activé, mais ton ordinateur ne répond pas. Vérifie qu’il est allumé et qu’il partage.';

  @override
  String get remoteAccessTurnOnFailed =>
      'Impossible d’activer l’accès à distance. Réessaie.';

  @override
  String get remoteAccessTurnOffFailed =>
      'Impossible de désactiver l’accès à distance. Réessaie.';
}
