// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'LM Mini';

  @override
  String get splashTagline => 'локальный ИИ-чат';

  @override
  String get homeTitle => 'LM Mini';

  @override
  String get homeSearchHint => 'Поиск бесед...';

  @override
  String get allConversations => 'Все беседы';

  @override
  String get noFoldersTitle => 'Нет папок';

  @override
  String get noFoldersSubtitle => 'Создайте папки для организации чатов';

  @override
  String get noConversationsTitle => 'Нет бесед';

  @override
  String get noConversationsSubtitle => 'Начните новый чат';

  @override
  String get newChat => 'Новый чат';

  @override
  String conversationCount(int count) {
    return '$count беседа(ы)';
  }

  @override
  String get noModelsAvailable =>
      'Модели недоступны. Проверьте подключение к LM Studio.';

  @override
  String get noVisionModelAvailable =>
      'Модель с поддержкой зрения недоступна. Загрузите модель зрения в LM Studio.';

  @override
  String get deleteConversationTitle => 'Удалить Беседу';

  @override
  String get deleteConversationMessage =>
      'Вы уверены, что хотите удалить эту беседу? Это действие нельзя отменить.';

  @override
  String get renameConversationTitle => 'Переименовать Беседу';

  @override
  String get conversationTitleLabel => 'Название Беседы';

  @override
  String get deleteFolderTitle => 'Удалить Папку';

  @override
  String get deleteFolderMessage => 'Беседы в этой папке не будут удалены.';

  @override
  String get moveToFolderTitle => 'Переместить в Папку';

  @override
  String get noFolder => 'Без Папки';

  @override
  String get cancel => 'Отмена';

  @override
  String get delete => 'Удалить';

  @override
  String get save => 'Сохранить';

  @override
  String get close => 'Закрыть';

  @override
  String get ok => 'ОК';

  @override
  String get add => 'Добавить';

  @override
  String get edit => 'Редактировать';

  @override
  String get reset => 'Сбросить';

  @override
  String get retry => 'Повторить';

  @override
  String get search => 'Поиск';

  @override
  String get copy => 'Копировать';

  @override
  String get copied => 'Скопировано!';

  @override
  String get copiedToClipboard => 'Скопировано в буфер обмена';

  @override
  String get dismiss => 'Закрыть';

  @override
  String get configure => 'Настроить';

  @override
  String get rename => 'Переименовать';

  @override
  String get duplicate => 'Дублировать';

  @override
  String get enabled => 'Включено';

  @override
  String get disabled => 'Отключено';

  @override
  String get active => 'Активно';

  @override
  String get none => 'Нет';

  @override
  String get auto => 'Авто';

  @override
  String get custom => 'Пользовательский';

  @override
  String get change => 'Изменить';

  @override
  String get chatDefaultTitle => 'Чат';

  @override
  String get searchMessagesTooltip => 'Поиск сообщений';

  @override
  String get chatSettingsMenuItem => 'Настройки Чата';

  @override
  String get appearanceMenuItem => 'Оформление';

  @override
  String get exportAsPdf => 'Экспорт в PDF';

  @override
  String get exportAsTxt => 'Экспорт в TXT';

  @override
  String get exportAsMarkdown => 'Экспорт в Markdown';

  @override
  String get exportAsJson => 'Экспорт в JSON';

  @override
  String get exportAsObsidian => 'Экспорт для Obsidian';

  @override
  String get copyToClipboard => 'Скопировать в буфер обмена';

  @override
  String get exportAndShare => 'Экспорт и отправка';

  @override
  String get freeFormats => 'Стандартные';

  @override
  String get premiumFormats => 'Pro-форматы';

  @override
  String get chatExported => 'Чат экспортирован';

  @override
  String get noModelSelectedTitle => 'Модель Не Выбрана';

  @override
  String get noModelSelectedSubtitle =>
      'Выберите модель в настройках, чтобы начать чат';

  @override
  String get openSettings => 'Открыть Настройки';

  @override
  String connectionError(String error) {
    return 'Ошибка Подключения: $error';
  }

  @override
  String get startConversation => 'Начните беседу';

  @override
  String get typeMessageToBegin => 'Введите сообщение, чтобы начать';

  @override
  String get searchMessagesTitle => 'Поиск Сообщений';

  @override
  String get searchQueryHint => 'Введите запрос...';

  @override
  String get semanticSearchInfo =>
      'Семантический поиск использует ИИ для нахождения релевантных сообщений по смыслу, а не только по ключевым словам.';

  @override
  String get noMessagesToSearch => 'Нет сообщений для поиска';

  @override
  String get searchResults => 'Результаты Поиска';

  @override
  String searchResultsFor(int count, String query) {
    return '$count совпадение(й) для \"$query\"';
  }

  @override
  String get noMessagesFound => 'Сообщения не найдены';

  @override
  String get tryDifferentSearch => 'Попробуйте другой запрос';

  @override
  String get chatCustomizationSaved => 'Настройки чата сохранены';

  @override
  String get noMessagesToExport => 'Нет сообщений для экспорта';

  @override
  String get exportingChat => 'Экспорт чата...';

  @override
  String get chatExportedAsPdf => 'Чат экспортирован в PDF';

  @override
  String get chatExportedAsTxt => 'Чат экспортирован в TXT';

  @override
  String exportFailed(String error) {
    return 'Ошибка экспорта: $error';
  }

  @override
  String get chatSettingsUpdated =>
      'Настройки чата обновлены (глобальные настройки переопределены)';

  @override
  String get chatSettingsReset =>
      'Настройки чата сброшены к глобальным значениям';

  @override
  String get you => 'Вы';

  @override
  String get assistant => 'Ассистент';

  @override
  String get yesterday => 'Вчера';

  @override
  String get showDetails => 'Показать детали';

  @override
  String get hideDetails => 'Скрыть детали';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsAdvancedMode => 'Расширенные';

  @override
  String get settingsAdvancedModeTooltip =>
      'Показать технические параметры для опытных пользователей';

  @override
  String get serverSection => 'СЕРВЕР';

  @override
  String get serverUrlLabel => 'URL Сервера';

  @override
  String get serverUrlHint => 'http://localhost:1234';

  @override
  String get testConnectionRequired => 'Проверить Подключение (Обязательно)';

  @override
  String get testConnection => 'Проверить подключение';

  @override
  String get modelsSection => 'МОДЕЛИ';

  @override
  String get modelSelection => 'Выбор Модели';

  @override
  String get noModelSelected => 'Модель не выбрана';

  @override
  String get modelParameters => 'Параметры Модели';

  @override
  String get modelParametersSubtitle => 'Температура, токены, штрафы';

  @override
  String get modelParametersHelpTooltip => 'Что означают эти настройки';

  @override
  String get modelParametersHelpTitle => 'Краткий гид';

  @override
  String get modelParametersHelpIntro =>
      'Простые подсказки к каждой настройке. Если не уверены — оставьте значения по умолчанию, их всегда можно изменить. Часть опций видна только для текущего ИИ-провайдера.';

  @override
  String get topKHelp =>
      'Сколько вариантов слов рассматривает ИИ. Ниже = безопаснее и предсказуемее; 0 = без ограничения.';

  @override
  String get reasoningHelp =>
      'Включает или выключает режим мышления для моделей рассуждений. Выкл. = более быстрые ответы без следа мышления; Вкл. (или уровень) просит модель думать шаг за шагом. Не все модели рассуждений поддерживают отключение.';

  @override
  String get reasoningHelpShort =>
      'Вкл./выкл. мышление. Не все модели поддерживают Выкл.';

  @override
  String get systemPrompts => 'Персоны и системные промпты';

  @override
  String get defaultPrompt => 'Промпт по умолчанию';

  @override
  String get appearanceSection => 'ОФОРМЛЕНИЕ';

  @override
  String get appearance => 'Оформление';

  @override
  String get appearanceSubtitle => 'Тема, фоны, аватары';

  @override
  String get supportSection => 'ПОДДЕРЖКА';

  @override
  String get rateApp => 'Оценить LM Mini';

  @override
  String get rateAppSubtitle =>
      'Нравится приложение? Оставьте отзыв в App Store ⭐';

  @override
  String get hfBrowseTitle => 'Скачать с Hugging Face';

  @override
  String get hfBrowseSubtitle => 'Обзор GGUF-моделей — API-ключ не нужен';

  @override
  String get hfBrowseTab => 'Обзор';

  @override
  String get hfPasteTab => 'Вставить ссылку';

  @override
  String get hfSearchHint => 'Поиск GGUF-моделей…';

  @override
  String get hfLoadingModels => 'Поиск на Hugging Face…';

  @override
  String get hfNoModelsFound => 'Модели не найдены';

  @override
  String get hfNoModelsHint =>
      'Попробуйте другой запрос или отключите фильтр LM Studio.';

  @override
  String get hfLmStudioFilter => 'Совместимо с LM Studio';

  @override
  String get hfLmStudioFilterHint =>
      'Только модели, которые Hugging Face отмечает как совместимые с LM Studio';

  @override
  String get hfChatModelsFilter => 'Чат-модели';

  @override
  String get hfChatBadge => 'Чат';

  @override
  String get hfLmStudioBadge => 'LM Studio';

  @override
  String get hfPasteUrlHint => 'https://huggingface.co/owner/repo';

  @override
  String get hfModelInfo => 'О модели';

  @override
  String hfDownloadsCount(String count) {
    return '$count загрузок';
  }

  @override
  String hfLikesCount(String count) {
    return '$count отметок «нравится»';
  }

  @override
  String hfPipelineTag(String tag) {
    return 'Задача: $tag';
  }

  @override
  String hfBaseModel(String model) {
    return 'Базовая модель: $model';
  }

  @override
  String hfLicense(String license) {
    return 'Лицензия: $license';
  }

  @override
  String get hfTagsSection => 'Теги';

  @override
  String get hfQuantPickerHint =>
      'Меньшая квантизация = меньший файл. Q4_K_M — хороший баланс для большинства устройств.';

  @override
  String get hfBackToModels => 'Назад к моделям';

  @override
  String hfGgufFilesCount(int count) {
    return 'Доступно GGUF-файлов: $count';
  }

  @override
  String get hfDownloadInBackground =>
      'Загрузка начата — следите за прогрессом по плавающей кнопке. Можно продолжать просмотр или закрыть эту панель.';

  @override
  String get hfQuantPickerHintLmStudio =>
      'Квантизации, перечисленные вашим сервером LM Studio. Выберите одну для загрузки на сервер.';

  @override
  String get hfDownloadDefaultQuant => 'Скачать';

  @override
  String hfDownloadFailed(String error) {
    return 'Не удалось начать загрузку: $error';
  }

  @override
  String get hfPasteInstructions =>
      'Вставьте URL репозитория Hugging Face или введите owner/repo. Далее вы выберете квантизацию.';

  @override
  String get hfPasteInstructionsLmStudio =>
      'Вставьте URL Hugging Face, owner/repo или ID модели LM Studio.';

  @override
  String get hfPasteLabel => 'Репозиторий';

  @override
  String get hfInvalidRepo =>
      'Введите корректный URL Hugging Face или owner/repo.';

  @override
  String get hfRecommended => 'Рекомендуется';

  @override
  String get reviewPromptTitle => 'Нравится LM Mini?';

  @override
  String get reviewPromptMessage =>
      'У вас уже было несколько отличных чатов! Не оставите быструю оценку в Play Store?';

  @override
  String get reviewPromptRate => 'Оценить';

  @override
  String get reviewPromptLater => 'Позже';

  @override
  String get buyMeACoffee => 'Угостите Кофе';

  @override
  String get buyMeACoffeeSubtitle => 'Помогите ИИ оставаться бодрым! 🤖';

  @override
  String get featureRequests => 'Запросы Функций';

  @override
  String get featureRequestsSubtitle =>
      'Голосуйте за функции или отправляйте свои идеи';

  @override
  String get dataSection => 'ДАННЫЕ';

  @override
  String get exportAllChats => 'Экспортировать Все Чаты';

  @override
  String get exportAllChatsSubtitle => 'Скачать все беседы в ZIP-архиве';

  @override
  String get importChats => 'Импортировать Чаты';

  @override
  String get importChatsSubtitle =>
      'Импорт экспорта чатов LM Studio (.md или .zip)';

  @override
  String importSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count чатов успешно импортировано',
      one: '1 чат успешно импортирован',
    );
    return '$_temp0';
  }

  @override
  String get importFailed => 'Ошибка импорта';

  @override
  String importPartial(int imported, int skipped) {
    return '$imported импортировано, $skipped пропущено';
  }

  @override
  String get importing => 'Импорт...';

  @override
  String get advancedSection => 'РАСШИРЕННЫЕ ФУНКЦИИ';

  @override
  String get showRuntimeInfo => 'Показать Инфо о Выполнении';

  @override
  String get showRuntimeInfoSubtitle =>
      'Показать архитектуру модели и время выполнения';

  @override
  String get embeddingModel => 'Модель Эмбеддингов';

  @override
  String get enableSemanticSearch => 'Включить Семантический Поиск';

  @override
  String get enableSemanticSearchSubtitle =>
      'Искать релевантные сообщения с помощью эмбеддингов';

  @override
  String get toolCalling => 'Вызов Инструментов';

  @override
  String get toolCallingEnabled => 'Вызов инструментов включён';

  @override
  String get toolCallingDisabled => 'Вызов инструментов отключён';

  @override
  String get legalSection => 'ЮРИДИЧЕСКАЯ ИНФОРМАЦИЯ';

  @override
  String get privacyPolicy => 'Политика Конфиденциальности';

  @override
  String get privacyPolicySubtitle => 'Чаты остаются на ваших устройствах';

  @override
  String get termsOfService => 'Условия Использования';

  @override
  String get termsOfServiceSubtitle => 'Правила и условия';

  @override
  String get appName => 'LM Mini';

  @override
  String get appTagline => 'Приложение-компаньон для LM Studio';

  @override
  String get couldNotOpenLink => 'Не удалось открыть ссылку';

  @override
  String get apiToken => 'API-Токен и USB';

  @override
  String get tokenConfigured => 'Токен настроен';

  @override
  String get optionalAuthentication => 'Опциональная аутентификация';

  @override
  String get apiTokenLabel => 'API-Токен';

  @override
  String get apiTokenHint => 'Введите ваш API-токен LM Studio';

  @override
  String get apiTokenHelp =>
      'Если ваш сервер LM Studio требует аутентификации, введите API-токен здесь. Он необязателен и нужен только если вы включили аутентификацию в настройках LM Studio.';

  @override
  String get apiTokenInfo =>
      'LM Studio 0.4.0+ поддерживает аутентификацию API. Включите в LM Studio > Настройки > Безопасность.';

  @override
  String get actionRequired => '- Требуется Действие';

  @override
  String get idleTtl => 'TTL Простоя';

  @override
  String get idleTtlDefault =>
      'Используется значение LM Studio по умолчанию (60 мин)';

  @override
  String idleTtlMinutes(int value) {
    return 'Автоматическая выгрузка через $value мин простоя';
  }

  @override
  String idleTtlHoursMinutes(int hours, int mins) {
    return 'Автоматическая выгрузка через $hours ч $mins мин простоя';
  }

  @override
  String get lmStudioDefault => 'По умолчанию LM Studio';

  @override
  String get fiveMinutes => '5 минут';

  @override
  String get fifteenMinutes => '15 минут';

  @override
  String get thirtyMinutes => '30 минут';

  @override
  String get oneHour => '1 час';

  @override
  String get twoHours => '2 часа';

  @override
  String connectionSuccess(int count) {
    return 'Подключено! $count моделей загружено';
  }

  @override
  String get connectionFailed => 'Ошибка подключения';

  @override
  String get troubleshootingSteps => 'Шаги Устранения Неполадок:';

  @override
  String get troubleshootStep1 => 'Убедитесь, что LM Studio запущен';

  @override
  String get troubleshootStep2 =>
      'В LM Studio откройте вкладку Разработчик (значок ⚙️)';

  @override
  String get troubleshootStep3 =>
      'Включите переключатель \"Обслуживать в Локальной Сети\"';

  @override
  String get troubleshootStep4 =>
      'Проверьте, что порт сервера совпадает (по умолчанию: 1234)';

  @override
  String troubleshootStep5(String ip) {
    return 'Используйте http://localhost:1234 для локальных подключений';
  }

  @override
  String get lmStudioSettings => 'Настройки LM Studio';

  @override
  String get serveOnLocalNetworkHelp =>
      'Переключатель \"Обслуживать в Локальной Сети\" должен быть включён (оранжевый/зелёный) на вкладке Разработчик LM Studio.';

  @override
  String get networkConnections => 'Сетевые Подключения:';

  @override
  String get networkConnectionsTips =>
      '• Замените \"localhost\" на IP-адрес вашего компьютера\n• Убедитесь, что оба устройства в одной сети\n• Проверьте настройки файрвола для порта 1234';

  @override
  String get noConversationsToExport => 'Нет бесед для экспорта';

  @override
  String exportingConversations(int count) {
    return 'Экспорт $count беседы(бесед)...';
  }

  @override
  String exportSuccess(int count) {
    return '$count беседа(бесед) успешно экспортировано';
  }

  @override
  String get languageSection => 'ЯЗЫК';

  @override
  String get language => 'Язык';

  @override
  String get languageSubtitle => 'Выберите предпочитаемый язык';

  @override
  String get systemDefault => 'По Умолчанию Системы';

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
  String get toolsCallingTitle => 'Вызов Инструментов';

  @override
  String get toolCallingSection => 'ВЫЗОВ ИНСТРУМЕНТОВ';

  @override
  String get enableToolCallingAndMcps => 'Включить Инструменты и MCP';

  @override
  String get enableToolCallingSubtitle =>
      'Разрешить ИИ искать в интернете и вызывать MCP';

  @override
  String get builtInToolsSection => 'ВСТРОЕННЫЕ ИНСТРУМЕНТЫ';

  @override
  String get builtInToolsInfo =>
      'Инструменты, выполняемые локально приложением по запросу ИИ';

  @override
  String get webSearch => 'Веб-поиск';

  @override
  String get webSearchUsingSearxng => 'Использует SearXNG';

  @override
  String get webSearchDisabled =>
      'Отключено (настройте SearXNG или обновитесь до Pro)';

  @override
  String get integratedMcpsSection => 'ИНТЕГРИРОВАННЫЕ MCP';

  @override
  String get integratedMcpsInfo =>
      'Используйте MCP, уже настроенные в LM Studio. Просто добавьте их имена из mcp.json.';

  @override
  String get integratedMcpsAuthRequired =>
      'Интегрированные MCP требуют включённой аутентификации в LM Studio и API-токена в Настройки → API-Токен.';

  @override
  String get requiresApiToken => 'Требуется API-токен';

  @override
  String get setApiTokenTooltip =>
      'Установите API-токен в Настройках для включения';

  @override
  String get noIntegratedMcps => 'Интегрированные MCP не настроены';

  @override
  String get addManually => 'Добавить Вручную';

  @override
  String get importMcpJson => 'Импортировать mcp.json';

  @override
  String get ephemeralMcpsSection => 'ЭФЕМЕРНЫЕ MCP';

  @override
  String get ephemeralMcpsInfo =>
      'HTTP MCP-серверы, отправляемые с каждым запросом. Требуется \"Разрешить MCP по запросу\" в LM Studio.';

  @override
  String get requiresPerRequestMcps =>
      'Требуется: Разработчик → Настройки Сервера → Разрешить MCP по запросу';

  @override
  String get noEphemeralMcps => 'Эфемерные MCP не настроены';

  @override
  String get addHttpMcpServer => 'Добавить HTTP MCP-сервер';

  @override
  String get browseExampleMcps => 'Примеры MCP-серверов';

  @override
  String get addIntegratedMcpTitle => 'Добавить MCP';

  @override
  String get editIntegratedMcpTitle => 'Изменить MCP';

  @override
  String get addIntegratedMcpInfo =>
      'Скопируйте имя из mcp.json LM Studio и вставьте сюда. Если видите ключ playwright, введите playwright.';

  @override
  String get mcpNameLabel => 'Имя из mcp.json';

  @override
  String get mcpNameHint => 'playwright';

  @override
  String get mcpNameHelper =>
      'Только буквы, цифры и дефисы — web-search, не web_search.';

  @override
  String get exampleMcpJsonEntry => '💡 Пример записи mcp.json:';

  @override
  String get nameIsRequired => 'Имя обязательно';

  @override
  String get mcpNameInvalidChars =>
      'Используйте дефисы вместо подчёркиваний (LM Studio не принимает имена вроде web_search).';

  @override
  String get mcpNameAlreadyExists => 'Этот MCP уже добавлен';

  @override
  String addedMcp(String name) {
    return 'Добавлен $name';
  }

  @override
  String updatedMcp(String name) {
    return 'Обновлён $name';
  }

  @override
  String get editMcpTooltip => 'Изменить имя';

  @override
  String get unlimitedToolCalls => 'Неограниченные вызовы инструментов';

  @override
  String get unlimitedToolCallsSubtitle =>
      'Снять ограничение в 10 вызовов для интегрированных и эфемерных MCP (не влияет на Pro Search)';

  @override
  String get unlimitedToolCallsOn =>
      'Без ограничений на итерации вызовов MCP-инструментов';

  @override
  String get unlimitedToolCallsOff =>
      'Ограничено 10 итерациями вызовов инструментов';

  @override
  String get structuredOutput => 'Структурированный Вывод';

  @override
  String get structuredOutputSubtitle => 'Принудительный формат ответа JSON';

  @override
  String get reasoningMode => 'Режим Рассуждений';

  @override
  String get reasoningOff => 'Выключено';

  @override
  String get reasoningLow => 'Низкий';

  @override
  String get reasoningMedium => 'Средний';

  @override
  String get reasoningHigh => 'Высокий';

  @override
  String get reasoningOn => 'Включено';

  @override
  String get reasoningDescOff => 'Без следов рассуждений';

  @override
  String get reasoningDescLow => 'Минимальные рассуждения';

  @override
  String get reasoningDescMedium => 'Сбалансированные рассуждения';

  @override
  String get reasoningDescHigh => 'Подробные рассуждения';

  @override
  String get reasoningDescOn => 'Полные следы рассуждений';

  @override
  String get helpSection => 'ПОМОЩЬ';

  @override
  String get toolCallingGuide => 'Руководство по Инструментам';

  @override
  String get toolCallingGuideSubtitle =>
      'Узнайте, как работают вызовы инструментов';

  @override
  String get searxngSetupGuide => 'Руководство по Настройке SearXNG';

  @override
  String get searxngSetupGuideSubtitle =>
      'Настройте свой собственный поисковый сервер';

  @override
  String get webSearchConfig => 'Настройка Веб-поиска';

  @override
  String get howWebSearchWorks => '💡 Как Работает Веб-поиск';

  @override
  String get howWebSearchWorksSteps =>
      '1. ИИ решает, что ему нужна актуальная информация\n2. Приложение ищет через Премиум-поиск или SearXNG\n3. Результаты отправляются ИИ\n4. ИИ формирует ответ';

  @override
  String get searchResultsLabel => 'Результаты поиска: ';

  @override
  String get webSearchDisabledWarning =>
      'Веб-поиск отключён. Настройте SearXNG или обновитесь до Pro.';

  @override
  String get searxngUrlOptional => 'URL SearXNG (Необязательно)';

  @override
  String get searxngUrlLabel => 'URL SearXNG';

  @override
  String get searxngUrlHint => 'http://localhost:8888';

  @override
  String get quickSetupDocker => '🐳 Быстрая Настройка с Docker:';

  @override
  String get dockerCommand => 'docker run -d -p 8888:8080 searxng/searxng';

  @override
  String get mcpBadge => 'MCP';

  @override
  String get mcpResultBadge => 'Результат MCP';

  @override
  String get webSearchSourcesTitle => 'Источники';

  @override
  String get toolBadge => 'Инструмент';

  @override
  String get resultBadge => 'Результат';

  @override
  String get failedToLoadImage => 'Не удалось загрузить изображение';

  @override
  String get thinking => 'Размышление';

  @override
  String get think => 'Думать';

  @override
  String thoughtFor(String duration) {
    return 'Размышлял $duration';
  }

  @override
  String get performanceStats => 'Статистика Производительности';

  @override
  String get regenerate => 'Перегенерировать';

  @override
  String get editMessage => 'Редактировать Сообщение';

  @override
  String get editMessageHint => 'Отредактируйте сообщение...';

  @override
  String get saveAndRegenerate => 'Сохранить и Перегенерировать';

  @override
  String get deleteMessage => 'Удалить Сообщение';

  @override
  String get deleteMessageConfirm =>
      'Вы уверены, что хотите удалить это сообщение?';

  @override
  String get mcpCallTitle => 'Вызов MCP';

  @override
  String get mcpResultTitle => 'Результат MCP';

  @override
  String get toolCallTitle => 'Вызов Инструмента';

  @override
  String get toolResultTitle => 'Результат Инструмента';

  @override
  String get attachFile => 'Прикрепить Файл';

  @override
  String get photoLibrary => 'Фотобиблиотека';

  @override
  String get attachImagesForVision =>
      'Прикрепить изображения для анализа зрением';

  @override
  String get requiresVisionModel => 'Требуется модель с поддержкой зрения';

  @override
  String get takePhoto => 'Сделать Фото';

  @override
  String get captureImageWithCamera => 'Сделать снимок камерой';

  @override
  String get imageFromFiles => 'Изображение из Файлов';

  @override
  String get pickImageFromFilesApp => 'Выбрать изображение из приложения Файлы';

  @override
  String get attachDocuments => 'Документы';

  @override
  String get attachDocumentsSubtitle =>
      'PDF, Markdown, Excel (.xlsx), CSV, текст, код и другое';

  @override
  String get textFileTxt => 'Текстовый Файл (.txt)';

  @override
  String get attachPlainText => 'Прикрепить текстовые документы';

  @override
  String get csvFileCsv => 'CSV Файл (.csv)';

  @override
  String get attachSpreadsheetData => 'Прикрепить табличные данные';

  @override
  String get pdfDocumentPdf => 'PDF Документ (.pdf)';

  @override
  String get attachPdfDocuments => 'Прикрепить PDF-документы';

  @override
  String get mcpLabel => 'MCP:';

  @override
  String get typeMessageHint => 'Введите сообщение...';

  @override
  String get attachFilesTooltip => 'Прикрепить файлы';

  @override
  String get customizeChat => 'Настроить Чат';

  @override
  String get overrideGlobalAppearance =>
      'Переопределить глобальное оформление для этого чата';

  @override
  String get background => 'Фон';

  @override
  String get userAvatar => 'Аватар Пользователя';

  @override
  String get assistantAvatar => 'Аватар Ассистента';

  @override
  String get colorsSection => 'Цвета';

  @override
  String get userBubble => 'Пузырь Пользователя';

  @override
  String get userText => 'Текст Пользователя';

  @override
  String get assistantBubble => 'Пузырь Ассистента';

  @override
  String get assistantText => 'Текст Ассистента';

  @override
  String get darkOverlay => 'Тёмное Наложение';

  @override
  String get darkOverlayDescription =>
      'Настройте затемнение наложения фонового изображения';

  @override
  String get usingGlobal => 'Глобальные';

  @override
  String get useGlobal => 'Глобальные';

  @override
  String get setCustom => 'Настроить';

  @override
  String get customColor => 'Пользовательский цвет';

  @override
  String get defaultThemeColor => 'Цвет темы по умолчанию';

  @override
  String get resetToDefault => 'Сбросить по умолчанию';

  @override
  String get pickAColor => 'Выберите цвет';

  @override
  String get chatSettingsTitle => 'Настройки Чата';

  @override
  String get overrideGlobalSettings =>
      'Переопределить глобальные настройки только для этого чата';

  @override
  String get resetAll => 'Сбросить Всё';

  @override
  String get modelOverride => 'Модель';

  @override
  String get noneSelected => 'Не выбрано';

  @override
  String get systemPromptOverride => 'Персона';

  @override
  String get saved => 'Сохранённые';

  @override
  String get noSavedPromptsInfo =>
      'Нет сохранённых персон. Перейдите в Настройки → Персоны, чтобы создать.';

  @override
  String get selectSavedPromptHint => 'Выберите персону...';

  @override
  String get enterCustomPromptHint =>
      'Введите пользовательский промпт персоны...';

  @override
  String get personaShareMemoriesLabel => 'Делиться памятью';

  @override
  String get personaShareMemoriesSubtitle =>
      'Если выключено, эта персона не получит и не извлечёт память в чатах';

  @override
  String get webSearchOffForThisChat => 'Выключено только для этого чата';

  @override
  String get reasoningOffForThisChat => 'Выключено только для этого чата';

  @override
  String get temperatureOverride => 'Температура';

  @override
  String get maxTokensOverride => 'Макс. Токенов';

  @override
  String get topPOverride => 'Top P';

  @override
  String get topKOverride => 'Top K';

  @override
  String get minPOverride => 'Min P';

  @override
  String get repeatPenaltyOverride => 'Штраф за Повторения';

  @override
  String get contextLengthOverride => 'Длина Контекста';

  @override
  String get systemPromptsTitle => 'Персоны и системные промпты';

  @override
  String get addSystemPromptTooltip => 'Добавить системный промпт';

  @override
  String get systemPromptsInfoText =>
      'Создавайте и управляйте системными промптами. Привязывайте их к конкретным моделям или используйте глобально. Выберите один для активации.';

  @override
  String get savedPromptsSection => 'СОХРАНЁННЫЕ ПРОМПТЫ';

  @override
  String get addSystemPrompt => 'Добавить Системный Промпт';

  @override
  String get newPrompt => 'Новый Промпт';

  @override
  String get noPromptSet => 'Промпт не задан';

  @override
  String get editSystemPrompt => 'Редактировать Системный Промпт';

  @override
  String get newSystemPrompt => 'Новый Системный Промпт';

  @override
  String get promptNameLabel => 'Название Промпта';

  @override
  String get promptNameHint =>
      'напр., Помощник по Коду, Креативный Писатель...';

  @override
  String get systemPromptLabel => 'Системный Промпт';

  @override
  String get systemPromptEditorHint => 'Вы — полезный ассистент, который...';

  @override
  String get bindToModels => 'Привязать к Конкретным Моделям';

  @override
  String get bindToModelsSubtitle =>
      'Ограничить этот промпт определёнными моделями. Без привязки доступен для всех моделей.';

  @override
  String get noModelsLoaded =>
      'Модели не загружены. Подключитесь к LM Studio и загрузите модели для привязки этого промпта.';

  @override
  String get templatesSection => 'ШАБЛОНЫ';

  @override
  String get pleaseEnterPromptName => 'Пожалуйста, введите название промпта';

  @override
  String get pleaseEnterPromptContent =>
      'Пожалуйста, введите содержание промпта';

  @override
  String get deleteSystemPromptTitle => 'Удалить Системный Промпт?';

  @override
  String deleteSystemPromptMessage(String name) {
    return 'Вы уверены, что хотите удалить \"$name\"? Это действие нельзя отменить.';
  }

  @override
  String get templateCodeAssistant => 'Помощник по Коду';

  @override
  String get templateCreativeWriter => 'Креативный Писатель';

  @override
  String get templateConciseExpert => 'Лаконичный Эксперт';

  @override
  String get templateResearcher => 'Исследователь';

  @override
  String get templateTutor => 'Репетитор';

  @override
  String get templateTechnicalWriter => 'Технический Писатель';

  @override
  String get downloadProgress => 'Прогресс Загрузки';

  @override
  String get progressLabel => 'Прогресс';

  @override
  String get speedLabel => 'Скорость';

  @override
  String get etaLabel => 'Ожидаемое Время';

  @override
  String get statusLabel => 'Статус';

  @override
  String get notAvailable => 'Н/Д';

  @override
  String get calculating => 'Вычисление...';

  @override
  String get moveToFolderPopup => 'Переместить в Папку';

  @override
  String contextInfo(String used, String total) {
    return 'Контекст: $used / $total';
  }

  @override
  String get hideAvatars => 'Скрыть Аватары';

  @override
  String get hideAvatarsSubtitle => 'Убрать значки аватаров из сообщений чата';

  @override
  String get autoScroll => 'Автопрокрутка';

  @override
  String get autoScrollSubtitle =>
      'Прокручивать вниз при получении новых сообщений';

  @override
  String get editMcpServer => 'Редактировать MCP-сервер';

  @override
  String get addMcpServer => 'Добавить MCP-сервер';

  @override
  String get serverLabelRequired => 'Название Сервера *';

  @override
  String get serverLabelHint => 'напр., huggingface, tiktoken';

  @override
  String get serverLabelHelper => 'Имя для идентификации этого сервера';

  @override
  String get serverUrlRequired => 'URL Сервера *';

  @override
  String get serverUrlMcpHint => 'https://huggingface.co/mcp';

  @override
  String get serverUrlHelper => 'HTTP/HTTPS URL MCP-сервера';

  @override
  String get authorizationOptional => 'API-ключ (Необязательно)';

  @override
  String get authorizationHint => 'hf_xxxxxxxx или Bearer hf_xxxxxxxx';

  @override
  String get authorizationHelper =>
      'Отправляется как заголовок Authorization для этого MCP. Вставьте токен (Bearer добавится) или полное значение заголовка.';

  @override
  String get additionalHeaders => 'Дополнительные Заголовки';

  @override
  String get additionalHeadersHint => 'X-Custom-Header: значение';

  @override
  String get additionalHeadersHelper =>
      'Один заголовок на строку (имя: значение).\nАвторизация настраивается выше.';

  @override
  String get labelAndUrlRequired => 'Название и URL обязательны';

  @override
  String get urlMustStartWithHttp =>
      'URL должен начинаться с http:// или https://';

  @override
  String get mcpServerUpdated => 'MCP-сервер обновлён';

  @override
  String get mcpServerAdded => 'MCP-сервер добавлен';

  @override
  String get importMcpJsonTitle => 'Импортировать mcp.json';

  @override
  String get pasteMcpJsonContent => 'Вставьте содержимое вашего mcp.json';

  @override
  String get mcpJsonLocation =>
      'Расположение: ~/.lmstudio/config/mcp.json\nИли в LM Studio: Разработчик → Настройки MCP → Открыть конфиг';

  @override
  String get mcpJsonContentLabel => 'Содержимое mcp.json';

  @override
  String get mcpJsonContentHelper =>
      'Вставьте полное содержимое файла mcp.json';

  @override
  String get parseJson => 'Разобрать JSON';

  @override
  String foundMcpServers(int count) {
    return 'Найдено $count MCP-сервер(ов):';
  }

  @override
  String get hasAuthHeaders => 'Имеет заголовки аутентификации';

  @override
  String importSelected(int count) {
    return 'Импортировать $count выбранных';
  }

  @override
  String get pleasePasteMcpJson =>
      'Пожалуйста, вставьте содержимое вашего mcp.json';

  @override
  String get noMcpServersFound => 'mcpServers не найдены в JSON';

  @override
  String get exampleMcpServers => 'Примеры MCP-серверов';

  @override
  String get gitMcpInfo =>
      'Они используют GitMCP для предоставления документации из репозиториев GitHub';

  @override
  String get browseMoreGitMcp => 'Больше на gitmcp.io';

  @override
  String get fileNotFound => 'Файл не найден';

  @override
  String get openWithExternalApp => 'Открыть во внешнем приложении';

  @override
  String get previewNotAvailable => 'Предпросмотр недоступен';

  @override
  String get voiceMode => 'Голосовой режим';

  @override
  String get voiceSettings => 'Настройки голоса';

  @override
  String get voiceSettingsSubtitle =>
      'Озвучка текста, голосовой ввод и голосовой режим';

  @override
  String get voiceSection => 'Голос';

  @override
  String get voiceStatus => 'Статус';

  @override
  String get voiceTtsEngine => 'Движок озвучки текста';

  @override
  String get voiceSttEngine => 'Движок распознавания речи';

  @override
  String get voiceAvailable => 'Доступно';

  @override
  String get voiceUnavailable => 'Недоступно';

  @override
  String get voiceTtsSettings => 'Озвучка текста';

  @override
  String get voiceSttSettings => 'Распознавание речи';

  @override
  String get voiceSttProvider => 'Поставщик распознавания речи';

  @override
  String get voiceSttProviderSystem => 'Системная речь';

  @override
  String get voiceSttProviderSystemSubtitle =>
      'Apple Speech на iOS, Google Speech на Android';

  @override
  String get voiceSttProviderWhisper => 'Whisper на устройстве';

  @override
  String get voiceSttProviderWhisperSubtitle =>
      'Офлайн sherpa-onnx Whisper — точнее и одинаково на всех платформах';

  @override
  String get voiceWhisperModelNotDownloaded => 'Модель Whisper не загружена';

  @override
  String get voiceWhisperModelReady => 'Модель Whisper готова';

  @override
  String get voiceWhisperModelSize =>
      'Выберите размер — более крупные модели транскрибируют точнее';

  @override
  String get voiceWhisperDownloadButton => 'Скачать';

  @override
  String get voiceWhisperDownloading => 'Загрузка модели Whisper…';

  @override
  String get voiceWhisperDownloadStarting => 'Начало загрузки…';

  @override
  String get voiceWhisperDownloadFailed => 'Ошибка загрузки';

  @override
  String get voiceWhisperDeleteModel => 'Удалить выбранную модель Whisper';

  @override
  String get voiceWhisperDeleteTitle => 'Удалить модель Whisper?';

  @override
  String get voiceWhisperDeleteMessage =>
      'Выбранная модель будет удалена с устройства. Распознавание речи на устройстве вернётся к системной речи, пока вы снова не скачаете модель Whisper.';

  @override
  String get voiceWhisperDeleteConfirm => 'Удалить';

  @override
  String get voiceWhisperFallback =>
      'Переключается на системную речь, если модель не загружена';

  @override
  String get voiceWhisperBiggerBetterTitle => 'Зачем более крупные модели?';

  @override
  String get voiceWhisperBiggerBetterBody =>
      'Более крупные модели Whisper обычно дают более точные расшифровки — особенно с акцентами, тихим звуком, фоновым шумом и редкими словами. Им также нужно больше места, и они работают медленнее на устройстве.\n\nTiny подходит для короткой чёткой речи. Base или Small лучше для длинных файлов. Large v3 Turbo — самый быстрый/компактный из крупных моделей (урезанный Large v3). Полный Large v3 — самый точный, но и самый тяжёлый.';

  @override
  String get voiceWhisperUseModel => 'Использовать';

  @override
  String get voiceWhisperSelected => 'Выбрано';

  @override
  String get voiceWhisperDownloaded => 'Загружено';

  @override
  String get audioSetupTitle => 'Настройка голоса и аудио';

  @override
  String get audioSetupMessage =>
      'Голосовому чату нужен синтез речи, чтобы ИИ отвечал голосом. Выберите нейросеть Kokoro на устройстве для лучшего качества или встроенные голоса устройства — без загрузки.';

  @override
  String get audioSetupWhisperStatus => 'Распознавание речи Whisper';

  @override
  String get audioSetupKokoroStatus => 'Нейроголос Kokoro';

  @override
  String get audioSetupStatusReady => 'Готово';

  @override
  String get audioSetupStatusMissing => 'Не загружено';

  @override
  String get audioSetupOnDeviceButton => 'Скачать голос Kokoro';

  @override
  String get audioSetupOnDeviceSubtitle =>
      'Нейро TTS Kokoro · около 300 МБ · работает офлайн';

  @override
  String get audioSetupSystemButton => 'Использовать системную речь';

  @override
  String get audioSetupSystemSubtitle =>
      'Встроенные STT и TTS — загрузка не нужна';

  @override
  String get audioSetupConfigureButton => 'Настройки голоса';

  @override
  String get audioSetupNotNow => 'Не сейчас';

  @override
  String get audioSetupDownloadingWhisper => 'Загрузка Whisper…';

  @override
  String get audioSetupDownloadingKokoro => 'Загрузка Kokoro…';

  @override
  String get audioSetupDownloadComplete => 'Модели готовы';

  @override
  String get audioSetupContinueButton => 'Продолжить';

  @override
  String get voiceModeSettings => 'Голосовой режим';

  @override
  String get voiceAutoRead => 'Автоматически читать ответы';

  @override
  String get voiceAutoReadSubtitle =>
      'Автоматически озвучивать новые сообщения ассистента';

  @override
  String get voiceSpeechRate => 'Скорость речи';

  @override
  String get voicePitch => 'Тон';

  @override
  String get voiceLanguage => 'Язык голоса';

  @override
  String get voiceLanguageSubtitle =>
      'Language for spoken replies (text-to-speech)';

  @override
  String get voiceSttLanguage => 'Recognition language';

  @override
  String get voiceSttLanguageSubtitle =>
      'Used for the text mic and Voice Call. Can differ from spoken reply language.';

  @override
  String get voiceSelection => 'Выбор голоса';

  @override
  String get voiceDefault => 'По умолчанию';

  @override
  String get voiceTestVoice => 'Тест голоса';

  @override
  String get voiceTestVoiceSubtitle =>
      'Воспроизвести пример для прослушивания текущих настроек голоса';

  @override
  String get voiceTestPhrase => 'Привет! Вот как я звучу сейчас.';

  @override
  String get voiceTestProgressInitializing => 'Запуск движка TTS…';

  @override
  String get voiceTestProgressGenerating => 'Генерация речи…';

  @override
  String get voiceTestProgressPreparing => 'Подготовка воспроизведения…';

  @override
  String get voiceTestProgressPlaying => 'Воспроизведение образца…';

  @override
  String get voiceTestProgressConnecting => 'Подключение к удалённому голосу…';

  @override
  String get voiceTestProgressComplete => 'Готово';

  @override
  String get voiceKokoroEngineReady =>
      'Движок готов — тест должен начаться быстро';

  @override
  String get voiceKokoroEngineWarming => 'Прогрев движка на устройстве…';

  @override
  String get voiceAutoSend => 'Автоотправка после речи';

  @override
  String get voiceAutoSendSubtitle =>
      'Автоматически отправлять сообщение по окончании распознавания речи';

  @override
  String get voiceSttPauseFor => 'Пауза перед отправкой';

  @override
  String get voiceSttPauseForSubtitle =>
      'Секунды тишины перед отправкой речи в ИИ';

  @override
  String get voiceSttListenFor => 'Максимальное время прослушивания';

  @override
  String get voiceSttListenForSubtitle =>
      'Остановить прослушивание через столько секунд, даже если вы ещё говорите';

  @override
  String voiceSttSeconds(int seconds) {
    return '$seconds с';
  }

  @override
  String get voiceContinuousConversation => 'Непрерывная беседа';

  @override
  String get voiceContinuousConversationSubtitle =>
      'Автоматически начинать слушать после озвучки ответа';

  @override
  String get voiceTapToSpeak => 'Нажмите, чтобы говорить';

  @override
  String get voiceListening => 'Слушаю…';

  @override
  String get voiceThinking => 'Секунду…';

  @override
  String get voiceResponding => 'Отвечаю…';

  @override
  String get voiceSpeaking => 'Говорю…';

  @override
  String get voiceConvoHintIdle => 'Нажмите на круг, чтобы начать говорить';

  @override
  String get voiceConvoHintListening => 'Я слушаю — не торопитесь';

  @override
  String get voiceConvoHintStarting => 'Подготовка микрофона…';

  @override
  String get voiceConvoHintProcessing => 'Думаю…';

  @override
  String get voiceConvoHintSpeaking => '';

  @override
  String get voiceNotAvailable =>
      'Распознавание речи недоступно на этом устройстве';

  @override
  String get voiceStartRecording => 'Начать голосовой ввод';

  @override
  String get voiceStopRecording => 'Остановить запись';

  @override
  String get voiceDiscardRecording => 'Удалить';

  @override
  String get voiceSelectLanguage => 'Выбрать язык';

  @override
  String get voiceSelectVoice => 'Выбрать голос';

  @override
  String get voiceNoVoicesAvailable => 'Нет голосов для этого языка';

  @override
  String get voiceAboutTitle => 'О голосовом режиме';

  @override
  String get voiceAboutDescription =>
      'Голосовой режим использует встроенные речевые движки вашего устройства. Озвучка текста использует Apple AVSpeechSynthesizer на iOS и Google TTS на Android. Распознавание речи использует Apple Speech Framework на iOS и Google Speech на Android. Вся обработка происходит на устройстве — данные не отправляются на внешние серверы.';

  @override
  String get voiceExitMode => 'Переключиться на клавиатуру';

  @override
  String get voiceTtsProvider => 'Провайдер TTS';

  @override
  String get voiceTtsProviderNative => 'Устройство (Нативный)';

  @override
  String get voiceTtsProviderNativeSubtitle =>
      'Использует встроенные голоса — работает офлайн';

  @override
  String get voiceTtsProviderKokoro => 'Скачанный голос';

  @override
  String get voiceTtsProviderKokoroSubtitle =>
      'Естественные голоса, которые работают на этом устройстве';

  @override
  String get voiceTtsProviderKokoroRemote => 'Kokoro (ПК)';

  @override
  String get voiceTtsProviderKokoroRemoteSubtitle =>
      'Запустите Kokoro на ПК для более быстрой и качественной речи';

  @override
  String get voiceTtsProviderElevenLabs => 'ElevenLabs';

  @override
  String get voiceTtsProviderElevenLabsSubtitle =>
      'Pro · ваш API-ключ · облачные голоса';

  @override
  String get voiceTtsElevenLabs => 'ElevenLabs';

  @override
  String get voiceTtsElevenLabsHint =>
      'Ваш ключ · голоса из вашей библиотеки ElevenLabs';

  @override
  String get voiceElevenLabsApiKey => 'API-ключ ElevenLabs';

  @override
  String get voiceElevenLabsApiKeyHint => 'Вставьте xi-api-key с elevenlabs.io';

  @override
  String get voiceElevenLabsTestKey => 'Проверить ключ';

  @override
  String get voiceElevenLabsKeyInvalid =>
      'Этот ключ не принят. Проверьте его на elevenlabs.io.';

  @override
  String get voiceElevenLabsKeyNetwork =>
      'Не удалось связаться с ElevenLabs. Проверьте соединение.';

  @override
  String get voiceElevenLabsKeyQuota => 'У этого ключа закончилась квота.';

  @override
  String get voiceElevenLabsKeyUnknown =>
      'Не удалось проверить ключ. Попробуйте ещё раз.';

  @override
  String get voiceElevenLabsPrivacy =>
      'Текст ответов отправляется в ElevenLabs с вашим ключом. LM Mini хранит ключ только на этом устройстве.';

  @override
  String get voiceElevenLabsModel => 'Модель ElevenLabs';

  @override
  String get voiceElevenLabsVoice => 'Голос ElevenLabs';

  @override
  String get voiceElevenLabsNoVoices =>
      'В этом аккаунте нет голосов. Сначала добавьте голоса в библиотеке ElevenLabs.';

  @override
  String get voiceElevenLabsChangeKey => 'Сменить ключ';

  @override
  String get voiceElevenLabsRemoveKey => 'Удалить ключ';

  @override
  String get voiceElevenLabsReady => 'Подключено к ElevenLabs';

  @override
  String get voiceElevenLabsNoKey => 'Добавьте API-ключ ElevenLabs';

  @override
  String get personaElevenLabsVoiceLabel => 'Голос ElevenLabs';

  @override
  String get personaElevenLabsVoiceGlobal =>
      'Использовать глобальный голос ElevenLabs';

  @override
  String get personaElevenLabsVoicePickerTitle => 'Голос ElevenLabs';

  @override
  String get personaElevenLabsVoiceAddKey =>
      'Добавьте API-ключ в настройках голоса, чтобы выбрать голос ElevenLabs';

  @override
  String get premiumElevenLabsTts => 'Голоса ElevenLabs';

  @override
  String get premiumElevenLabsTtsTagline => 'Нейро TTS со своим ключом';

  @override
  String get premiumElevenLabsTtsDescription =>
      'Добавьте свой API-ключ ElevenLabs и назначьте студийные голоса персонам. Голосовой чат, автоозвучка и чтение вслух используют тот же движок.';

  @override
  String get voiceTtsProviderGrok => 'Grok';

  @override
  String get voiceTtsProviderGrokSubtitle =>
      'Pro · ваш API-ключ xAI · облачные голоса';

  @override
  String get voiceTtsGrok => 'Grok';

  @override
  String get voiceTtsGrokHint => 'Ваш ключ · голоса Grok от xAI';

  @override
  String get voiceGrokApiKey => 'API-ключ xAI';

  @override
  String get voiceGrokApiKeyHint => 'Вставьте API-ключ с console.x.ai';

  @override
  String get voiceGrokTestKey => 'Проверить ключ';

  @override
  String get voiceGrokKeyInvalid =>
      'Этот ключ не принят. Проверьте его на console.x.ai.';

  @override
  String get voiceGrokKeyNetwork =>
      'Не удалось связаться с xAI. Проверьте соединение.';

  @override
  String get voiceGrokKeyQuota => 'У этого ключа закончилась квота.';

  @override
  String get voiceGrokKeyUnknown =>
      'Не удалось проверить ключ. Попробуйте ещё раз.';

  @override
  String get voiceGrokPrivacy =>
      'Текст ответов отправляется в xAI с вашим ключом. LM Mini хранит ключ только на этом устройстве.';

  @override
  String get voiceGrokVoice => 'Голос Grok';

  @override
  String get voiceGrokNoVoices =>
      'Голоса Grok недоступны. Проверьте ключ и попробуйте ещё раз.';

  @override
  String get voiceGrokChangeKey => 'Сменить ключ';

  @override
  String get voiceGrokRemoveKey => 'Удалить ключ';

  @override
  String get voiceGrokReady => 'Подключено к Grok';

  @override
  String get voiceGrokNoKey => 'Добавьте API-ключ xAI';

  @override
  String get personaGrokVoiceLabel => 'Голос Grok';

  @override
  String get personaGrokVoiceGlobal => 'Использовать глобальный голос Grok';

  @override
  String get personaGrokVoicePickerTitle => 'Голос Grok';

  @override
  String get personaGrokVoiceAddKey =>
      'Добавьте API-ключ в настройках голоса, чтобы выбрать голос Grok';

  @override
  String get personaVoiceSection => 'Голос';

  @override
  String get personaVoiceProviderLabel => 'Провайдер';

  @override
  String get personaVoiceProviderKokoro => 'Kokoro';

  @override
  String get personaVoiceProviderGlobal =>
      'Использовать глобальные настройки голоса';

  @override
  String get personaVoiceConfigureInSettings => 'Настроить в Настройки → Голос';

  @override
  String get premiumGrokTts => 'Голоса Grok';

  @override
  String get premiumGrokTtsTagline => 'Нейро TTS со своим ключом';

  @override
  String get premiumGrokTtsDescription =>
      'Добавьте свой API-ключ xAI и назначьте голоса Grok персонам. Голосовой чат, автоозвучка и чтение вслух используют тот же движок.';

  @override
  String get voiceRemoteKokoroConnected => 'Подключено к Kokoro на ПК';

  @override
  String get voiceRemoteKokoroNotFound => 'Kokoro TTS не найден на ПК';

  @override
  String get voiceRemoteKokoroRequiresConnect =>
      'Нужен режим «Поделиться с телефоном» на Mac или LM Mini Connect на Windows/Linux';

  @override
  String get voiceKokoroVoice => 'Голос Kokoro';

  @override
  String get voiceKokoroSpeed => 'Скорость речи';

  @override
  String get voiceKokoroModelReady => 'Модель Kokoro готова';

  @override
  String get voiceKokoroModelReadySubtitle => 'Скачанный голос готов';

  @override
  String get voiceKokoroModelNotDownloaded => 'Модель Kokoro не загружена';

  @override
  String get voiceKokoroModelSize => 'Требуется загрузка (~400 МБ общий пакет)';

  @override
  String get voiceKokoroDownloading => 'Загрузка модели Kokoro…';

  @override
  String get voiceKokoroDownloadStarting => 'Начинается загрузка…';

  @override
  String get voiceKokoroDownloadButton => 'Загрузить';

  @override
  String get voiceKokoroDownloadFailed =>
      'Загрузка не удалась. Нажмите для повтора.';

  @override
  String get voiceKokoroFallback =>
      'Будет использован нативный голос, если модель Kokoro не загружена';

  @override
  String get voiceKokoroDeleteModel => 'Удалить модель Kokoro';

  @override
  String get voiceKokoroDeleteTitle => 'Удалить модель Kokoro?';

  @override
  String get voiceKokoroDeleteMessage =>
      'Это удалит все загруженные языковые пакеты TTS. Вы сможете загрузить их позже.';

  @override
  String get voiceKokoroDeleteConfirm => 'Удалить';

  @override
  String get voiceTtsLanguagePacksHint =>
      'Английский, испанский, французский и китайский используют одну загрузку (~400 МБ). Немецкий и русский меньше (~34 МБ).';

  @override
  String get voiceTtsLanguagePacks => 'Голосовые пакеты';

  @override
  String get voiceTtsLanguagePacksSubtitleNone =>
      'Скачайте язык, чтобы говорить на этом устройстве';

  @override
  String voiceTtsLanguagePacksSubtitleReady(int ready, int total) {
    return '$ready из $total языков готовы';
  }

  @override
  String voiceTtsLanguagePacksSubtitleDownloading(String name) {
    return 'Загрузка $name…';
  }

  @override
  String voiceTtsSharedPackSize(int size) {
    return 'Общая загрузка · ~$size МБ';
  }

  @override
  String voiceTtsPiperPackSize(int size) {
    return 'Меньшая загрузка · ~$size МБ';
  }

  @override
  String get voiceTtsSharedPackDeleteMessage =>
      'Это удалит общую загрузку для английского, испанского, французского и китайского. Вы сможете загрузить её снова позже.';

  @override
  String get connecting => 'Подключение...';

  @override
  String get saveAndTestConnection => 'Сохранить и проверить подключение';

  @override
  String connectedTo(String provider) {
    return '✅ Подключено к $provider';
  }

  @override
  String connectionToFailed(String provider) {
    return '❌ Подключение к $provider не удалось — проверьте API-ключ';
  }

  @override
  String errorGeneric(String error) {
    return '❌ Ошибка: $error';
  }

  @override
  String get provider => 'Провайдер';

  @override
  String cloudApiKeyLabel(String provider) {
    return 'API-ключ $provider';
  }

  @override
  String get enterApiKeyHint => 'Введите API-ключ…';

  @override
  String getApiKey(String provider) {
    return 'Получить API-ключ $provider';
  }

  @override
  String get baseUrl => 'Базовый URL';

  @override
  String get customBaseUrlOptional =>
      'Пользовательский базовый URL (необязательно)';

  @override
  String get accountSection => 'АККАУНТ';

  @override
  String get signIn => 'Войти';

  @override
  String get signInSubtitle =>
      'Войдите, чтобы включить облачное резервное копирование';

  @override
  String get cloudServicesUnavailable => 'Облачные сервисы недоступны';

  @override
  String signedInVia(String method) {
    return 'Вход через $method';
  }

  @override
  String get lmMiniProSection => 'LM MINI PRO';

  @override
  String get proActive => 'Pro Активен';

  @override
  String get allPremiumUnlocked => 'Все премиум-функции разблокированы';

  @override
  String get upgradeToPro => 'Перейти на Pro';

  @override
  String get unlockPremiumFeatures => 'Разблокируйте все премиум-функции ниже';

  @override
  String get proBadge => 'PRO';

  @override
  String get proFeatureTag => 'Pro-функция';

  @override
  String get betaBadge => 'БЕТА';

  @override
  String get imageGeneration => 'Генерация изображений';

  @override
  String get generatedImagesLibrary => 'Сгенерированные изображения';

  @override
  String get generatedImagesGallery => 'Галерея';

  @override
  String get generatedImagesShowInChat => 'Показать в чате';

  @override
  String get generatedImagesLibrarySubtitle =>
      'Просмотр, открытие в чате или удаление';

  @override
  String get generatedImagesLibraryEmpty =>
      'Пока нет сгенерированных изображений';

  @override
  String get generatedImagesLibraryEmptyHint =>
      'Изображения из чата сохраняются здесь.';

  @override
  String get generatedImagesSelect => 'Выбрать';

  @override
  String get generatedImagesCancelSelect => 'Готово';

  @override
  String generatedImagesDeleteN(int count) {
    return 'Удалить $count';
  }

  @override
  String get generatedImagesDeleteConfirmTitle => 'Удалить изображения?';

  @override
  String generatedImagesDeleteConfirmBody(int count) {
    return '$count изображ. будут удалены с устройства. Сообщения чата останутся.';
  }

  @override
  String get generatedImagesOpenChat => 'Открыть в чате';

  @override
  String get saveToPhotos => 'Save to Photos';

  @override
  String get savedToPhotos => 'Saved to Photos';

  @override
  String get couldNotSaveToPhotos => 'Could not save this file.';

  @override
  String get share => 'Share';

  @override
  String get generatedImagesMissingFile => 'Файл не найден';

  @override
  String get generatedImagesOrphan => 'Не привязано к чату';

  @override
  String get generatedImagesPrompt => 'Промпт';

  @override
  String get generatedImagesNegativePrompt => 'Негативный промпт';

  @override
  String get generatedImagesDetails => 'Параметры генерации';

  @override
  String get generatedImagesNoPrompt => 'Промпт не сохранён';

  @override
  String get generatedImagesChatUnavailable => 'Этот чат больше недоступен';

  @override
  String get generatedImagesVideo => 'Видео';

  @override
  String imageGenEnabled(String url) {
    return 'Включено — $url';
  }

  @override
  String get imageGenNotConfigured => 'Включено — Не настроено';

  @override
  String get cloudBackup => 'Облачное резервное копирование';

  @override
  String get encryptedBackupRestore =>
      'Зашифрованное резервное копирование и восстановление';

  @override
  String get e2eBanner =>
      'Сквозное шифрование — ваша парольная фраза никогда не покидает это устройство';

  @override
  String get analytics => 'Аналитика';

  @override
  String get analyticsSubtitle =>
      'Статистика использования, токены и аналитика моделей';

  @override
  String get memory => 'Воспоминания';

  @override
  String memoryItemCount(int count) {
    return '$count записей • Сохраняется между чатами';
  }

  @override
  String get premiumWebSearch => 'Премиум веб-поиск';

  @override
  String get premiumWebSearchSubtitle => 'Мгновенный поиск — без SearXNG';

  @override
  String get urlReader => 'Чтение URL';

  @override
  String get urlReaderSubtitle => 'Чтение и резюмирование любой веб-страницы';

  @override
  String get conversationBranching => 'Ветвление разговоров';

  @override
  String get conversationBranchingSubtitle =>
      'Создание ответвлений от любого сообщения';

  @override
  String get cloudBackupPro => 'Облачное резервное копирование';

  @override
  String get cloudBackupProSubtitle =>
      'Зашифрованное резервное копирование в облако';

  @override
  String get analyticsDashboard => 'Панель аналитики';

  @override
  String get analyticsDashboardSubtitle =>
      'Статистика использования, токены и аналитика моделей';

  @override
  String get cloudApiProviders => 'Облачные API-провайдеры';

  @override
  String get cloudApiProvidersSubtitle => 'Mistral, DeepSeek и др.';

  @override
  String get addProviderLabel => 'Добавить провайдера';

  @override
  String get noCloudProvidersTitle => 'Нет облачных провайдеров';

  @override
  String get noCloudProvidersSubtitle =>
      'Нажмите +, чтобы добавить провайдера облачного API.\nИспользуйте свои API-ключи для Groq, DeepSeek и других сервисов.';

  @override
  String get editProviderTitle => 'Изменить провайдера';

  @override
  String get addCloudProviderTitle => 'Добавить облачного провайдера';

  @override
  String get providerLabel => 'Провайдер';

  @override
  String get apiKeyLabel => 'API-ключ';

  @override
  String get pasteLabel => 'Вставить';

  @override
  String get baseUrlRequiredLabel => 'Базовый URL (обязательно)';

  @override
  String get customBaseUrlOptionalLabel =>
      'Пользовательский базовый URL (необязательно)';

  @override
  String get advancedLabel => 'Дополнительно';

  @override
  String get fetchingLabel => 'Загрузка...';

  @override
  String get fetchAvailableModelsLabel => 'Получить доступные модели';

  @override
  String get availableModelsLabel => 'Доступные модели:';

  @override
  String get suggestedModelsLabel => 'Рекомендуемые модели:';

  @override
  String get modelIdLabel => 'ID модели';

  @override
  String get disableCloudProviderSubtitle =>
      'Отключить конфигурацию, но сохранить её';

  @override
  String get setAsActiveProviderLabel => 'Сделать активным провайдером';

  @override
  String get deactivateLabel => 'Деактивировать';

  @override
  String get switchedBackToLocalLmStudio => 'Возврат к локальному LM Studio';

  @override
  String get saveChangesLabel => 'Сохранить изменения';

  @override
  String get enterDisplayNameError => 'Введите отображаемое имя';

  @override
  String get enterApiKeyError => 'Введите API-ключ';

  @override
  String get enterBaseUrlError =>
      'Введите базовый URL для пользовательского провайдера';

  @override
  String get enterApiKeyFirst => 'Сначала введите API-ключ';

  @override
  String failedToFetchModels(String error) {
    return 'Не удалось получить список моделей: $error';
  }

  @override
  String get deleteProviderTitle => 'Удалить провайдера?';

  @override
  String deleteProviderMessage(String name) {
    return 'Удалить «$name» и его API-ключ?';
  }

  @override
  String deleteFirstPartyOpenAiServerMessage(String name) {
    return 'Удалить «$name» с этого устройства?\n\nЭтот сервер больше нельзя добавить из списка. Чтобы подключить снова, добавьте A.I Compatible API и укажите https://api.openai.com как базовый URL.';
  }

  @override
  String activeProviderSet(String name) {
    return '$name назначен активным провайдером';
  }

  @override
  String get memoryPro => 'Воспоминания';

  @override
  String get memoryProSubtitle => 'Постоянные воспоминания между разговорами';

  @override
  String get richExportShare => 'Расширенный экспорт и обмен';

  @override
  String get richExportShareSubtitle =>
      'Экспорт в Obsidian, Заметки, Notion и др.';

  @override
  String autoUnloadAfter(String value) {
    return 'Авто-выгрузка через $value';
  }

  @override
  String get subscriptionRestore => 'Восстановить';

  @override
  String get subscriptionTerms => 'Условия';

  @override
  String get subscriptionPrivacy => 'Конфиденциальность';

  @override
  String get secureYourAccount => 'Защитите свой аккаунт';

  @override
  String get signInWithApple => 'Войти через Apple';

  @override
  String get signInWithGoogle => 'Войти через Google';

  @override
  String get subscriptionSecured => 'Ваша подписка защищена';

  @override
  String get packagesNotAvailable => 'Пакеты ещё недоступны.';

  @override
  String get welcomeToPro => '🎉 Добро пожаловать в LM Mini Pro!';

  @override
  String get subscriptionRestored => '✅ Подписка восстановлена!';

  @override
  String get noActiveSubscription => 'Активная подписка не найдена.';

  @override
  String get accountLinked => '✅ Аккаунт привязан!';

  @override
  String get account => 'Аккаунт';

  @override
  String get createAccount => 'Создать аккаунт';

  @override
  String get emailLabel => 'Эл. почта';

  @override
  String get passwordLabel => 'Пароль';

  @override
  String get forgotPassword => 'Забыли пароль?';

  @override
  String get forgotPasswordNeedEmail =>
      'Сначала введите email, затем нажмите «Забыли пароль?».';

  @override
  String get forgotPasswordSent =>
      'Если аккаунт с этим email существует, мы отправили ссылку для сброса. Проверьте входящие.';

  @override
  String get forgotPasswordFailed =>
      'Не удалось отправить письмо для сброса пароля. Попробуйте ещё раз.';

  @override
  String get verificationEmailSent => 'Письмо с подтверждением отправлено!';

  @override
  String failedToSend(String error) {
    return 'Не удалось отправить: $error';
  }

  @override
  String get cloudBackupEnabled =>
      'Включено — ваш аккаунт поддерживает зашифрованные резервные копии';

  @override
  String get endToEndEncryption => 'Сквозное шифрование';

  @override
  String get e2eSubtitle =>
      'Резервные копии зашифрованы вашей парольной фразой — мы не можем их прочитать';

  @override
  String get upgradeForCloudBackup =>
      'Перейдите на Pro для зашифрованного облачного резервного копирования';

  @override
  String get signOut => 'Выйти';

  @override
  String get signOutConfirm => 'Выйти?';

  @override
  String get signedOut => 'Выход выполнен.';

  @override
  String get goToAccount => 'Перейти к аккаунту';

  @override
  String get firebaseNotConfigured => 'Firebase не настроен.';

  @override
  String get refresh => 'Обновить';

  @override
  String get createBackup => 'Создать резервную копию';

  @override
  String get encryptBackupSubtitle => 'Зашифровать и сохранить все разговоры';

  @override
  String get backUpNow => 'Сохранить сейчас';

  @override
  String get yourBackups => 'ВАШИ РЕЗЕРВНЫЕ КОПИИ';

  @override
  String get e2eBackupBanner => 'Сквозное шифрование. ';

  @override
  String get e2eBackupDetail =>
      'Ваши резервные копии шифруются парольной фразой перед отправкой с устройства. Мы не можем прочитать ваши данные.';

  @override
  String get exportingData => 'Экспорт данных...';

  @override
  String get preparing => 'Подготовка...';

  @override
  String get encrypting => 'Шифрование...';

  @override
  String get uploading => 'Загрузка...';

  @override
  String get savingMetadata => 'Сохранение метаданных...';

  @override
  String get done => 'Готово!';

  @override
  String get noBackupsYet => 'Резервных копий пока нет';

  @override
  String get createFirstBackup =>
      'Создайте свою первую зашифрованную резервную копию выше';

  @override
  String get encrypted => 'Зашифровано';

  @override
  String get restore => 'Восстановить';

  @override
  String get encryptionPassphraseLabel => 'Парольная фраза шифрования';

  @override
  String get enterStrongPassphrase => 'Введите надёжную парольную фразу';

  @override
  String get confirmPassphraseLabel => 'Подтвердите парольную фразу';

  @override
  String get passphraseRememberWarning =>
      'Запомните эту парольную фразу! Если вы её потеряете, ваши резервные копии невозможно будет восстановить. Мы нигде её не храним.';

  @override
  String get passphraseRestoreHint =>
      'Введите ту же парольную фразу, которую вы использовали при создании этой резервной копии.';

  @override
  String get minCharsRequired => 'Требуется не менее 4 символов.';

  @override
  String get passphrasesDoNotMatch => 'Парольные фразы не совпадают.';

  @override
  String get encryptAndBackUp => 'Зашифровать и сохранить';

  @override
  String get decryptAndRestore => 'Расшифровать и восстановить';

  @override
  String get encryptionPassphrase => 'Парольная фраза шифрования';

  @override
  String get savedPassphrasePrompt =>
      'У вас есть сохранённая парольная фраза от предыдущей резервной копии. Хотите использовать ту же или задать новую?';

  @override
  String get newPassphrase => 'Новая парольная фраза';

  @override
  String get useSame => 'Использовать ту же';

  @override
  String get setEncryptionPassphrase => 'Задать парольную фразу шифрования';

  @override
  String get choosePassphraseBackup =>
      'Выберите парольную фразу для шифрования этой резервной копии. Она понадобится для восстановления на любом устройстве.';

  @override
  String get choosePassphraseDetail =>
      'Выберите парольную фразу для шифрования вашей резервной копии. Эта фраза остаётся на вашем устройстве — мы её никогда не видим. Она понадобится для восстановления.';

  @override
  String backupFailed(String error) {
    return 'Резервное копирование не удалось: $error';
  }

  @override
  String get restoreBackupConfirm => 'Восстановить резервную копию?';

  @override
  String get restoreWarning =>
      'Это ЗАМЕНИТ все ваши текущие разговоры, сообщения и папки данными из этой резервной копии.\n\nЭто действие нельзя отменить.';

  @override
  String get continueAction => 'Продолжить';

  @override
  String get enterPassphrase => 'Введите парольную фразу';

  @override
  String get passphraseDecryptHint =>
      'Эта резервная копия зашифрована сквозным шифрованием. Введите парольную фразу, которую вы использовали при её создании.';

  @override
  String get wrongPassphrase =>
      'Неверная парольная фраза или повреждённая резервная копия.';

  @override
  String restoreFailed(String error) {
    return 'Восстановление не удалось: $error';
  }

  @override
  String get deleteBackupConfirm => 'Удалить резервную копию?';

  @override
  String get deleteBackupWarning =>
      'Это навсегда удалит эту зашифрованную облачную резервную копию. Это действие нельзя отменить.';

  @override
  String get backupDeleted => 'Резервная копия удалена.';

  @override
  String deleteFailed(String error) {
    return 'Не удалось удалить: $error';
  }

  @override
  String get overview => 'ОБЗОР';

  @override
  String get messages => 'Сообщения';

  @override
  String get conversations => 'Разговоры';

  @override
  String get totalTokens => 'Всего токенов';

  @override
  String get avgResponse => 'Ср. ответ';

  @override
  String get modelUsage => 'ИСПОЛЬЗОВАНИЕ МОДЕЛИ';

  @override
  String get noModelUsageData =>
      'Данных об использовании модели пока нет.\nНачните общение, чтобы увидеть статистику здесь.';

  @override
  String get analyticsSync =>
      'Аналитика синхронизируется с вашим аккаунтом и сбрасывается при выходе.';

  @override
  String get clearAllMemories => 'Очистить все воспоминания';

  @override
  String get memoryOn => 'Вкл.';

  @override
  String get memoryOff => 'Выкл.';

  @override
  String get memoryInfoText =>
      'Элементы памяти внедряются в системный промпт, чтобы LLM помнил вас между разговорами.';

  @override
  String get noMemoriesYet => 'Воспоминаний пока нет';

  @override
  String noMemoriesInCategory(String category) {
    return 'Нет воспоминаний в категории $category';
  }

  @override
  String get memoryTapToAdd =>
      'Нажмите +, чтобы добавить новое воспоминание или выберите другую категорию.';

  @override
  String get memoryAddHint =>
      'Добавьте факты о себе, которые вы хотите, чтобы ИИ помнил во всех разговорах.';

  @override
  String get addMemory => 'Добавить воспоминание';

  @override
  String get category => 'Категория';

  @override
  String get editMemory => 'Редактировать воспоминание';

  @override
  String get deleteMemory => 'Удалить воспоминание';

  @override
  String removeMemoryConfirm(String content) {
    return 'Удалить это воспоминание?\n\n\"$content\"';
  }

  @override
  String get clearAllMemoriesTitle => 'Очистить все воспоминания';

  @override
  String clearAllMemoriesConfirm(int count) {
    return 'Это навсегда удалит все $count воспоминаний. Это действие нельзя отменить.';
  }

  @override
  String get clearAll => 'Очистить всё';

  @override
  String get justNow => 'только что';

  @override
  String get categoryPersonal => 'Личное';

  @override
  String get categoryPreferences => 'Предпочтения';

  @override
  String get categoryLifestyle => 'Lifestyle';

  @override
  String get categoryEmotional => 'Emotional';

  @override
  String get categoryTechnical => 'Техническое';

  @override
  String get categoryWork => 'Работа';

  @override
  String get categoryGeneral => 'Общее';

  @override
  String get categoryAll => 'Все';

  @override
  String get modelManagement => 'Управление моделями';

  @override
  String get downloadNewModel => 'Скачать новую модель';

  @override
  String get refreshModels => 'Обновить модели';

  @override
  String get tapToSelect => 'Нажмите для выбора';

  @override
  String modelSelected(String name) {
    return 'Выбрано: $name';
  }

  @override
  String get unloadModelTooltip => 'Выгрузить модель из памяти';

  @override
  String get modelInfoTooltip => 'Информация о модели';

  @override
  String get loadedBadge => 'ЗАГРУЖЕНА';

  @override
  String get visionBadge => 'Зрение';

  @override
  String get toolsBadge => 'Инструменты';

  @override
  String get selectedModel => 'Выбранная модель';

  @override
  String get unloading => 'Выгрузка...';

  @override
  String get unload => 'Выгрузить';

  @override
  String get loaded => 'Загружена';

  @override
  String get loadModel => 'Загрузить модель';

  @override
  String get enterModelIdOrUrl => 'Введите ID модели или URL HuggingFace:';

  @override
  String get modelIdHint => 'microsoft/phi-4';

  @override
  String get modelIdHelper => 'ID модели или https://huggingface.co/...';

  @override
  String get huggingFaceDetected =>
      'Обнаружен URL HuggingFace — вы выберете квантизацию';

  @override
  String get starting => 'Запуск...';

  @override
  String get download => 'Скачать';

  @override
  String get selectQuantization => 'Выбрать квантизацию';

  @override
  String get loadingQuantizations => 'Загрузка квантизаций...';

  @override
  String get error => 'Ошибка';

  @override
  String fetchQuantizationsFailed(String error) {
    return 'Не удалось получить квантизации: $error';
  }

  @override
  String get checkLmStudioRunning => 'Проверьте, запущен ли LM Studio';

  @override
  String get couldNotReachLmStudio => 'LM Mini не смог подключиться к серверу.';

  @override
  String get couldNotLoadQuantizations => 'Не удалось загрузить квантизации.';

  @override
  String get couldNotStartDownload => 'Не удалось начать загрузку.';

  @override
  String get noQuantizations => 'Нет квантизаций';

  @override
  String get noGgufFiles => 'В этом репозитории не найдены файлы GGUF';

  @override
  String foundQuantizations(int count) {
    return 'Найдено $count GGUF-квантизаций';
  }

  @override
  String get unknown => 'неизвестно';

  @override
  String downloadingModel(String quantization) {
    return 'Скачивание модели с квантизацией $quantization...';
  }

  @override
  String get modelAlreadyDownloaded => 'Модель уже скачана';

  @override
  String downloadFailed(String error) {
    return 'Скачивание не удалось: $error';
  }

  @override
  String get enterModelIdentifier =>
      'Пожалуйста, введите идентификатор модели или URL';

  @override
  String get modelAlreadyLoaded => 'Модель уже загружена';

  @override
  String get currentlyLoaded => 'Текущая загружена:';

  @override
  String loadAlongsideWarning(String name) {
    return 'Загрузка \"$name\" наряду с существующими моделями потребует дополнительной памяти.';
  }

  @override
  String get unloadAllAndLoad => 'Выгрузить все и загрузить';

  @override
  String get swap => 'Заменить';

  @override
  String get loadAlongside => 'Загрузить параллельно';

  @override
  String get loadParamsConflictTitle => 'Параметры загрузки различаются';

  @override
  String loadParamsConflictBody(String name) {
    return '«$name» уже загружена в LM Studio с настройками, отличными от конфигурации загрузки LM Mini. Перезагрузка может занять минуту и потребовать дополнительной памяти.';
  }

  @override
  String get loadParamsConflictTableHeader => 'Различающиеся параметры:';

  @override
  String get loadParamsLmStudio => 'LM Studio';

  @override
  String get loadParamsLmMini => 'LM Mini';

  @override
  String get loadParamsConflictHint =>
      'Использование настроек LM Studio избегает перезагрузки. Выгрузить и загрузить применит ваши настройки LM Mini. Параллельная загрузка оставит оба экземпляра в памяти.';

  @override
  String get loadParamsUseExisting => 'Использовать настройки LM Studio';

  @override
  String get loadParamsReloadWithMini =>
      'Выгрузить и загрузить с настройками LM Mini';

  @override
  String get loadParamsLoadParallel =>
      'Загрузить с настройками LM Mini (параллельно)';

  @override
  String get reloadModelForContextTitle => 'Перезагрузить модель?';

  @override
  String reloadModelForContextBody(String name, String loaded, String desired) {
    return 'Длина контекста задаётся при загрузке модели. «$name» загружена с $loaded. Перезагрузить с $desired?';
  }

  @override
  String get reloadModelForContextNow => 'Перезагрузить';

  @override
  String get reloadModelForContextLater => 'Не сейчас';

  @override
  String loadModelConfirm(String name) {
    return 'Загрузить \"$name\" в память?';
  }

  @override
  String get unloadModelTip =>
      'Вы можете выгрузить модели с помощью кнопки извлечения или с этого экрана после загрузки.';

  @override
  String get modelLoadedSuccess => 'Модель успешно загружена';

  @override
  String get failedToLoadModel => 'Не удалось загрузить модель';

  @override
  String get modelInfo => 'Информация о модели';

  @override
  String get infoName => 'Название';

  @override
  String get infoType => 'Тип';

  @override
  String get infoArchitecture => 'Архитектура';

  @override
  String get infoPublisher => 'Издатель';

  @override
  String get infoQuantization => 'Квантизация';

  @override
  String get infoParameters => 'Параметры';

  @override
  String get infoSize => 'Размер';

  @override
  String get infoMaxContext => 'Макс. контекст';

  @override
  String get infoLoadedContext => 'Загруженный контекст';

  @override
  String get infoStatus => 'Статус';

  @override
  String get available => 'Доступна';

  @override
  String get capabilities => 'Возможности';

  @override
  String get standardTextGeneration => 'Стандартная генерация текста';

  @override
  String get unloadModelTitle => 'Выгрузить модель';

  @override
  String unloadModelConfirm(String name) {
    return 'Выгрузить \"$name\" из памяти?';
  }

  @override
  String get freeResourcesTip => 'Это освободит ресурсы GPU/RAM.';

  @override
  String get modelUnloadedSuccess => 'Модель успешно выгружена';

  @override
  String get failedToUnloadModel => 'Не удалось выгрузить модель';

  @override
  String get enableImageGeneration => 'Включить генерацию изображений';

  @override
  String get showImageButtons =>
      'Показывать кнопки изображений в сообщениях чата';

  @override
  String get serverConnection => 'Подключение к серверу';

  @override
  String get serverUrl => 'URL сервера';

  @override
  String get test => 'Тест';

  @override
  String get connected => 'Подключено';

  @override
  String get model => 'Модель';

  @override
  String get checkpoint => 'Контрольная точка';

  @override
  String get generationParameters => 'Параметры генерации';

  @override
  String get negativePrompt => 'Негативный промпт';

  @override
  String get steps => 'Шаги';

  @override
  String get cfgScale => 'Шкала CFG';

  @override
  String get width => 'Ширина';

  @override
  String get height => 'Высота';

  @override
  String get sampler => 'Сэмплер';

  @override
  String get scheduler => 'Планировщик';

  @override
  String get automatic => 'Автоматически';

  @override
  String get seedLabel => 'Сид (-1 = случайный)';

  @override
  String get batchSize => 'Размер пакета';

  @override
  String get options => 'Параметры';

  @override
  String get restoreFaces => 'Восстановить лица';

  @override
  String get restoreFacesSubtitle =>
      'Исправить лица в сгенерированных изображениях';

  @override
  String get tiling => 'Тайлинг';

  @override
  String get tilingSubtitle => 'Генерировать бесшовные текстуры';

  @override
  String get promptOptions => 'Настройки промпта';

  @override
  String get reviewPromptBeforeSending => 'Проверить промпт перед отправкой';

  @override
  String get reviewPromptSubtitle =>
      'Редактировать промпт изображения перед генерацией';

  @override
  String get autoGenerateImage => 'Автогенерация изображения';

  @override
  String get autoGenerateSubtitle =>
      'Автоматически генерировать изображение, когда ИИ предоставляет промпт';

  @override
  String get resetToDefaults => 'Сбросить к настройкам по умолчанию';

  @override
  String get featureRequestsTitle => 'Запросы функций';

  @override
  String get featureRequestsUnavailable => 'Запросы функций недоступны';

  @override
  String get featureRequestsUnavailableDetail =>
      'Для этой функции требуется подключение к интернету. Проверьте подключение и попробуйте позже.';

  @override
  String get tryAgain => 'Попробовать снова';

  @override
  String get votesLeft => 'осталось';

  @override
  String get popular => 'Популярные';

  @override
  String get myRequests => 'Мои запросы';

  @override
  String get completed => 'Завершённые';

  @override
  String get submitIdea => 'Предложить идею';

  @override
  String get noFeatureRequests => 'Запросов функций пока нет';

  @override
  String get beFirstToSubmit => 'Будьте первым, кто предложит идею!';

  @override
  String get noRequestsSubmitted => 'Запросы не отправлены';

  @override
  String get tapToSubmitFirst =>
      'Нажмите кнопку ниже, чтобы отправить свою первую идею!';

  @override
  String get noCompletedRequests => 'Нет завершённых запросов';

  @override
  String get completedRequestsAppear =>
      'Завершённые и отклонённые запросы появятся здесь.';

  @override
  String get adminReplied => 'Админ ответил';

  @override
  String get submitFeatureRequest => 'Отправить запрос функции';

  @override
  String get titleRequired => 'Заголовок *';

  @override
  String get titleHint => 'Краткое описание вашей идеи';

  @override
  String get descriptionRequired => 'Описание *';

  @override
  String get descriptionHint => 'Подробно опишите запрос функции';

  @override
  String get yourNameOptional => 'Ваше имя (необязательно)';

  @override
  String get leaveBlankAnonymous => 'Оставьте пустым для анонимной отправки';

  @override
  String get fillTitleAndDescription =>
      'Пожалуйста, заполните заголовок и описание';

  @override
  String get featureRequestSubmitted => 'Запрос функции отправлен!';

  @override
  String get submit => 'Отправить';

  @override
  String get featureRequest => 'Запрос функции';

  @override
  String get votedTooltip => 'Проголосовано';

  @override
  String get voteForThis => 'Голосовать за это';

  @override
  String get adminControls => 'Управление админа';

  @override
  String get changeStatus => 'Изменить статус';

  @override
  String get officialReply => 'Официальный ответ';

  @override
  String get deleteRequest => 'Удалить запрос';

  @override
  String get unableToLoadComments => 'Не удалось загрузить комментарии';

  @override
  String commentsCount(int count) {
    return 'Комментарии ($count)';
  }

  @override
  String get readMore => 'Читать далее';

  @override
  String get showLess => 'Свернуть';

  @override
  String get deleteYourRequest => 'Удалить ваш запрос';

  @override
  String get anonymous => 'Аноним';

  @override
  String get officialResponse => 'Официальный ответ';

  @override
  String get noCommentsYet => 'Комментариев пока нет';

  @override
  String get beFirstToComment => 'Будьте первым, кто поделится мыслями!';

  @override
  String get adminBadge => 'АДМИН';

  @override
  String get moderatorBadge => 'MOD';

  @override
  String get experiencedUserBadge => 'EXP';

  @override
  String get adminManageSubmitter => 'Управление автором';

  @override
  String get adminManageUserTitle => 'Управление пользователем';

  @override
  String get adminUserUpdated => 'Пользователь обновлён';

  @override
  String get adminCommunityRoles => 'Роли сообщества';

  @override
  String get adminModeratorRole => 'Модератор';

  @override
  String get adminModeratorRoleSubtitle =>
      'Может обходить лимиты спама в комментариях и показывает значок Mod';

  @override
  String get adminExperiencedUserRole => 'Опытный пользователь';

  @override
  String get adminExperiencedUserRoleSubtitle =>
      'Показывает значок «Опытный» в комментариях к запросам функций';

  @override
  String get adminGrantPremiumTitle => 'Выдать бесплатный Pro';

  @override
  String get adminGrantPremiumSubtitle =>
      'Дать этому пользователю бесплатный LM Mini Pro на ограниченное время';

  @override
  String get adminGrantPremiumAmountLabel => 'Срок';

  @override
  String get adminGrantPremiumAmountHint => 'Введите значение';

  @override
  String get adminGrantPremiumUnitDays => 'Дни';

  @override
  String get adminGrantPremiumUnitWeeks => 'Недели';

  @override
  String get adminGrantPremiumUnitMonths => 'Месяцы';

  @override
  String get adminGrantPremiumGrantButton => 'Выдать Pro';

  @override
  String get adminGrantPremiumInvalidAmount => 'Введите положительное число';

  @override
  String get adminGrantPremiumReasonLabel => 'Причина';

  @override
  String get adminGrantPremiumReasonHint =>
      'Необязательно — показывается пользователю (например, Извините за неудобства)';

  @override
  String adminGrantPremiumDurationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дня',
      many: '$count дней',
      few: '$count дня',
      one: '1 день',
    );
    return '$_temp0';
  }

  @override
  String adminGrantPremiumDurationWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count недели',
      many: '$count недель',
      few: '$count недели',
      one: '1 неделя',
    );
    return '$_temp0';
  }

  @override
  String adminGrantPremiumDurationMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count месяца',
      many: '$count месяцев',
      few: '$count месяца',
      one: '1 месяц',
    );
    return '$_temp0';
  }

  @override
  String get adminRevokePremiumTitle => 'Отозвать бесплатный Pro';

  @override
  String get adminRevokePremiumMessage =>
      'Удалить активный Pro-доступ, выданный администратором этому пользователю?';

  @override
  String get adminRevokePremiumConfirm => 'Отозвать';

  @override
  String get premiumGrantBannerTitle => 'Вам выдан бесплатный Pro';

  @override
  String premiumGrantBannerBody(String duration) {
    return 'Бесплатный LM Mini Pro на $duration. Пользуйтесь премиум-функциями, пока действует доступ.';
  }

  @override
  String premiumGrantBannerReason(String reason) {
    return 'Причина: $reason';
  }

  @override
  String get premiumGrantDialogTitle => 'Бесплатный Pro разблокирован';

  @override
  String premiumGrantDialogBody(String duration) {
    return 'Администратор выдал вам бесплатный LM Mini Pro на $duration. Облачный бэкап, память, аналитика и другое уже доступны.';
  }

  @override
  String premiumGrantDialogReason(String reason) {
    return 'Причина: $reason';
  }

  @override
  String get premiumGrantDialogButton => 'Отлично';

  @override
  String get youBadge => 'ВЫ';

  @override
  String get deleteComment =>
      'Вы уверены, что хотите удалить этот комментарий?';

  @override
  String maxCommentsReached(int max) {
    return 'Вы отправили $max комментариев подряд. Дождитесь ответа другого пользователя.';
  }

  @override
  String get addYourName => 'Добавьте своё имя';

  @override
  String get replyAsAdmin => 'Ответить как админ...';

  @override
  String get writeComment => 'Написать комментарий...';

  @override
  String get errorTryAgain => 'Ошибка: попробуйте снова.';

  @override
  String statusUpdated(String status) {
    return 'Статус обновлён на $status';
  }

  @override
  String get addOfficialResponse => 'Добавить официальный ответ...';

  @override
  String get replySaved => 'Ответ сохранён';

  @override
  String get deleteRequestConfirm =>
      'Вы уверены, что хотите удалить этот запрос? Это действие нельзя отменить.';

  @override
  String get requestDeleted => 'Запрос удалён';

  @override
  String get deleteCommentTitle => 'Удалить комментарий';

  @override
  String get deleteCommentConfirm =>
      'Вы уверены, что хотите удалить этот комментарий?';

  @override
  String get commentDeleted => 'Комментарий удалён';

  @override
  String get generationParametersSection => 'ПАРАМЕТРЫ ГЕНЕРАЦИИ';

  @override
  String get temperature => 'Температура';

  @override
  String get temperatureSubtitle =>
      'Насколько ответы творческие или сосредоточенные. Ниже = осторожнее; выше = разнообразнее.';

  @override
  String get topP => 'Top P';

  @override
  String get topPSubtitle =>
      'Насколько широкий выбор слов допускается. Ниже = более сфокусированные ответы.';

  @override
  String get minP => 'Min P';

  @override
  String get minPSubtitle =>
      'Отсекает очень маловероятные слова. Выше = безопаснее и предсказуемее.';

  @override
  String get repeatPenalty => 'Штраф за повтор';

  @override
  String get repeatPenaltySubtitle =>
      'Мешает ИИ повторять одни и те же фразы. 1.0 = выкл.';

  @override
  String get frequencyPenalty => 'Штраф за частоту';

  @override
  String get frequencyPenaltySubtitle =>
      'Снижает слова, которые ИИ использует слишком часто.';

  @override
  String get presencePenalty => 'Штраф за присутствие';

  @override
  String get presencePenaltySubtitle =>
      'Подталкивает ИИ к новым темам вместо повторения старых.';

  @override
  String get tokenLimits => 'ЛИМИТЫ ТОКЕНОВ';

  @override
  String get maxOutputTokens => 'Макс. токенов на выходе';

  @override
  String get maxOutputTokensSubtitle =>
      'Насколько длинным может быть один ответ. Выше = длиннее (и дольше ждать).';

  @override
  String get contextWindow => 'Контекстное окно';

  @override
  String get contextWindowSubtitle =>
      'Сколько чата ИИ помнит сразу. Выше — больше памяти.';

  @override
  String get modelLoadingConfig => 'КОНФИГУРАЦИЯ ЗАГРУЗКИ МОДЕЛИ';

  @override
  String get loadContextLength => 'Длина контекста';

  @override
  String get loadContextSubtitle =>
      'Сколько контекста модель может использовать в чате и при загрузке в LM Studio. Выше — больше памяти / VRAM.';

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
  String get evalBatchSize => 'Размер пакета оценки';

  @override
  String get evalBatchSubtitle =>
      'Сколько текста обрабатывается за раз при загрузке. Выше может быть быстрее, но нужно больше памяти.';

  @override
  String get numExperts => 'Число экспертов';

  @override
  String get numExpertsSubtitle =>
      'Только для моделей «mixture of experts». Оставьте пустым, если не уверены.';

  @override
  String get flashAttention => 'Flash Attention';

  @override
  String get flashAttentionSubtitle =>
      'Ускоряет модель и может экономить память. Оставьте включённым, если нет сбоев.';

  @override
  String get offloadKvCache => 'Выгрузить KV-кэш на GPU';

  @override
  String get offloadKvCacheSubtitle =>
      'Использует GPU, чтобы эффективнее помнить чат. Включите, если есть GPU.';

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
      'Показывает пошаговые рассуждения ИИ, если они доступны.';

  @override
  String get reasoningUnsupportedToast =>
      'Эта модель не поддерживает Reasoning в LM Studio. Reasoning отключён.';

  @override
  String get reasoningNotExposedChatHint =>
      'LM Studio не позволяет отключить рассуждения для этой модели. Попробуйте другую модель.';

  @override
  String get premiumSearchActive => 'Премиум-поиск активен';

  @override
  String get premiumSearchPlusSearxng => ' + SearXNG';

  @override
  String get webSearchDisabledAll => 'Веб-поиск отключён для всех чатов';

  @override
  String get configureSearch => 'Настроить поиск';

  @override
  String get advancedFeaturesSection => 'РАСШИРЕННЫЕ ФУНКЦИИ';

  @override
  String get howToolCallingWorks => 'Как работает вызов инструментов';

  @override
  String get stepAskQuestion => 'Вы задаёте вопрос';

  @override
  String get stepAskExample => 'напр., «Какая погода в Токио?»';

  @override
  String get stepAiRequestsTool => 'ИИ запрашивает инструмент';

  @override
  String get stepAiRequestsExample => 'Модель решает, что нужен веб-поиск';

  @override
  String get stepAppExecutes => 'Приложение выполняет инструмент';

  @override
  String get stepAppExecutesExample => 'Ищет через Премиум-поиск или SearXNG';

  @override
  String get stepResultsSent => 'Результаты отправлены ИИ';

  @override
  String get stepResultsExample => 'Результаты поиска добавлены в разговор';

  @override
  String get stepAiAnswers => 'ИИ генерирует ответ';

  @override
  String get stepAiAnswersExample => 'Модель формирует полезный ответ';

  @override
  String get toolCallingModelNote => 'например Qwen, Llama 3.1+ или Mistral.';

  @override
  String get searxngSetup => 'Настройка SearXNG';

  @override
  String get searxngDescription =>
      'SearXNG — это бесплатный метапоисковик с уважением к приватности, который можно размещать самостоятельно.';

  @override
  String get dockerRecommended => 'Вариант 1: Docker (Рекомендуется)';

  @override
  String get publicInstance => 'Вариант 2: Использовать публичный экземпляр';

  @override
  String get findPublicInstances => 'Найдите публичные экземпляры на:';

  @override
  String get selfHostRecommended =>
      'Для надёжности рекомендуется самостоятельный хостинг.';

  @override
  String get clipboardEmpty =>
      'Буфер обмена пуст. Сначала скопируйте содержимое mcp.json.';

  @override
  String get clipboardAccessFailed =>
      'Не удалось получить доступ к буферу обмена. Вставьте вручную в поле ниже.';

  @override
  String get pasteFromClipboard => 'Вставить из буфера обмена';

  @override
  String get httpServersImportNote =>
      'HTTP-серверы → Эфемерные MCP (отправляются в LM Studio за запрос)';

  @override
  String get localMcpsImportNote =>
      'Локальные MCP → Интегрированные MCP (формат «mcp/имя»)';

  @override
  String get noValidMcpServers => 'Допустимых серверов MCP не найдено';

  @override
  String get serverAlreadyAdded => 'Этот сервер уже добавлен';

  @override
  String get themeSection => 'ТЕМА';

  @override
  String get themeLabel => 'Тема';

  @override
  String get glassEffectsLabel => 'Стеклянные эффекты';

  @override
  String get glassEffectsSubtitle =>
      'Размытие на шапках и меню. Выключите, чтобы телефон меньше нагревался.';

  @override
  String get lowBatteryModeLabel => 'Режим экономии батареи';

  @override
  String get lowBatteryModeSubtitle =>
      'Отключает стекло, показывает простой текст во время потока и синхронизирует Home/iCloud только после сообщения. Экран остаётся включённым до конца ответа, чтобы поток не оборвался.';

  @override
  String get backgroundSection => 'ФОН';

  @override
  String get chatBackground => 'Фон чата';

  @override
  String get chatBackgroundSubtitle =>
      'Установить фон по умолчанию для всех чатов';

  @override
  String get avatarsSection => 'АВАТАРЫ';

  @override
  String get chatHeaderAvatarLabel => 'Аватар в заголовке чата';

  @override
  String get chatHeaderAvatarSubtitle =>
      'Показывать фото профиля в верхней панели окна чата';

  @override
  String get avatarAboveMessageLabel => 'Аватар над сообщением';

  @override
  String get avatarAboveMessageSubtitle =>
      'Показывать аватар над пузырём сообщения, а не рядом с ним';

  @override
  String get fullWidthAssistantLabel => 'Ответы на всю ширину';

  @override
  String get fullWidthAssistantSubtitle =>
      'Ваши сообщения остаются в пузыре. Текст ассистента на всю строку';

  @override
  String get tryFullWidthTitle => 'Попробуйте новый вид на всю ширину';

  @override
  String get tryFullWidthBody =>
      'Ответы ассистента занимают всю строку без пузыря. Вернуться можно в любой момент в разделе Оформление.';

  @override
  String get tryFullWidthOpenAppearance => 'Открыть оформление';

  @override
  String get tryFullWidthNotNow => 'Не сейчас';

  @override
  String get streamingPhaseLoadingModel => 'Загрузка модели';

  @override
  String get streamingPhaseProcessingPrompt => 'Обработка запроса';

  @override
  String get streamingPhaseThinking => 'Думаю';

  @override
  String get streamingPhaseWriting => 'Пишу ответ';

  @override
  String get streamingPhaseSearching => 'Поиск';

  @override
  String get streamingPhaseUsingTools => 'Использование инструментов';

  @override
  String get previewUserMessage => 'Какой сокет у этой платы?';

  @override
  String get bubbleAvatarSizeLabel => 'Размер аватара в пузыре';

  @override
  String bubbleAvatarRadiusValue(int value) {
    return 'радиус ${value}px';
  }

  @override
  String get userAvatarLabel => 'Аватар пользователя';

  @override
  String get yourProfilePicture => 'Ваше фото профиля';

  @override
  String get assistantAvatarLabel => 'Аватар ассистента';

  @override
  String get aiAssistantPicture => 'Фото ИИ-ассистента';

  @override
  String get chatBehaviorSection => 'ПОВЕДЕНИЕ ЧАТА';

  @override
  String get fontSizeLabel => 'Размер шрифта';

  @override
  String get iconSizeLabel => 'Размер значков';

  @override
  String pointsValue(int value) {
    return '${value}pt';
  }

  @override
  String get previewLabel => 'Предпросмотр';

  @override
  String get previewAssistantMessage =>
      'Привет! Я ваш ИИ-помощник. Чем я могу помочь сегодня? Вот **жирное** слово и немного `встроенного кода`.';

  @override
  String get readAloud => 'Читать вслух';

  @override
  String appearanceActionTapped(String label) {
    return 'Нажато: $label';
  }

  @override
  String get autoScrollStreaming => 'Автопрокрутка при потоковой передаче';

  @override
  String get autoScrollStreamingSubtitle =>
      'Автоматически прокручивать к новым сообщениям';

  @override
  String get showChatStarters => 'Подсказки для нового чата';

  @override
  String get showChatStartersSubtitle =>
      'Показывать прокручиваемые подсказки в пустых чатах';

  @override
  String get useLegacyComposer => 'Классическое поле ввода';

  @override
  String get useLegacyComposerSubtitle =>
      'Использовать классический компактный ввод вместо нового shine-поля';

  @override
  String get hideAvatarsLabel => 'Скрыть аватары';

  @override
  String get moreSpaceForContent => 'Больше места для содержимого сообщений';

  @override
  String get enterKeyBehaviorLabel => 'Поведение клавиши Return/Enter';

  @override
  String get enterKeyAutoDescription =>
      'Отправлять на аппаратных клавиатурах, вставлять новую строку на экранных клавиатурах';

  @override
  String get enterKeySendDescription =>
      'Enter отправляет сообщение (Shift+Enter для новой строки)';

  @override
  String get enterKeyNewlineDescription =>
      'Enter всегда вставляет новую строку';

  @override
  String get sendLabel => 'Отправить';

  @override
  String get newLineLabel => 'Новая строка';

  @override
  String get themeSystem => 'Системная';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get backLabel => 'Назад';

  @override
  String get nextLabel => 'Далее';

  @override
  String get getStartedLabel => 'Начать';

  @override
  String get connectionSuccessful => 'Подключение выполнено успешно!';

  @override
  String get connectionFailedMessage => 'Не удалось подключиться';

  @override
  String get lmStudioServerFoundNeedsKey =>
      'Сервер найден! Добавьте API-ключ выше и нажмите «Проверить соединение».';

  @override
  String get lmStudioScanServerNeedsKey =>
      'Найден — добавьте API-ключ для подключения';

  @override
  String lmStudioUsingServerNeedsKey(String url) {
    return 'Используется $url. Добавьте API-ключ ниже и проверьте соединение.';
  }

  @override
  String get lmStudioAuthDialogTitle => 'Сервер найден';

  @override
  String get lmStudioAuthDialogMessage =>
      'Этому серверу нужен API-ключ. Вставьте токен LM Studio ниже, чтобы подключиться.';

  @override
  String get lmStudioAuthHelpHint =>
      'В LM Studio откройте режим разработчика → Настройки сервера → Управление токенами, чтобы создать или скопировать API-ключ.';

  @override
  String get welcomeWizardTitle => 'Добро пожаловать в LM Mini';

  @override
  String get welcomeWizardSubtitle =>
      'Общайтесь с ИИ-моделями, работающими в вашей локальной сети через LM Studio. Давайте настроим всё за несколько быстрых шагов.';

  @override
  String get welcomeWizardThemeTitle => 'Выберите тему';

  @override
  String get welcomeWizardThemeSystemSubtitle =>
      'Следовать настройкам устройства';

  @override
  String get welcomeWizardThemeLightSubtitle => 'Чистая и светлая';

  @override
  String get welcomeWizardThemeDarkSubtitle => 'Комфортна для глаз';

  @override
  String get welcomeWizardAppearanceTitle => 'Настроить внешний вид';

  @override
  String get welcomeWizardAppearancePreviewMessage =>
      'Привет! Так будут выглядеть ваши сообщения в чате.';

  @override
  String get welcomeWizardServerTitle => 'Подключение к LM Studio';

  @override
  String get welcomeWizardServerSubtitle =>
      'Введите IP-адрес компьютера, на котором запущен LM Studio в вашей локальной сети.';

  @override
  String get welcomeWizardLocalNetworkNote =>
      'iOS запросит разрешение на доступ к локальной сети, когда вы будете тестировать подключение. Пожалуйста, разрешите его.';

  @override
  String get apiTokenOptionalLabel => 'API-токен (необязательно)';

  @override
  String get welcomeWizardChangeLater =>
      'Вы всегда сможете изменить это позже в настройках.';

  @override
  String get welcomeWizardFindModelTitle => 'Найдите подходящую модель';

  @override
  String get welcomeWizardFindModelSubtitle =>
      'Сравните два варианта и посмотрите, какой быстрее на вашем устройстве. Около минуты — или пропустите, если уже знаете, что нужно.';

  @override
  String get welcomeWizardFindModelHelp => 'Помочь выбрать';

  @override
  String get welcomeWizardFindModelSkip => 'Пропустить — выберу сам';

  @override
  String get welcomeWizardExperienceTitle => 'How do you use AI?';

  @override
  String get welcomeWizardExperienceSubtitle =>
      'We\'ll tailor recommendations. You can change everything later.';

  @override
  String get welcomeWizardBeginnerTitle => 'Beginner';

  @override
  String get welcomeWizardBeginnerSubtitle =>
      'Проще: понятные Настройки и мы подскажем хорошую модель.';

  @override
  String get welcomeWizardPowerTitle => 'Power user';

  @override
  String get welcomeWizardPowerSubtitle =>
      'Полные Настройки и выбор — локальные модели и серверы вроде LM Studio.';

  @override
  String get welcomeWizardSetupTitleBeginner => 'Выберите модель';

  @override
  String get welcomeWizardSetupTitlePower => 'Choose your setup';

  @override
  String get welcomeWizardSetupSubtitleBeginner =>
      'Нажмите модель, чтобы скачать. Или подключите компьютер по Wi‑Fi.';

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
  String get pickColor => 'Выбрать цвет';

  @override
  String get hueLabel => 'Оттенок';

  @override
  String get saturationLabel => 'Насыщенность';

  @override
  String get lightnessLabel => 'Светлота';

  @override
  String get alphaLabel => 'Альфа';

  @override
  String get hexLabel => 'Hex';

  @override
  String get personaModeLabel => 'Режим персоны';

  @override
  String get personaModeSubtitle =>
      'Добавить аватар, акцентный цвет, голос и предпочитаемую модель для групповых чатов';

  @override
  String get avatarLabel => 'Аватар';

  @override
  String get customAvatarSet => 'Пользовательский аватар установлен';

  @override
  String get noAvatar => 'Нет аватара';

  @override
  String get accentColorLabel => 'Акцентный цвет';

  @override
  String get defaultLabel => 'По умолчанию';

  @override
  String get preferredModelLabel => 'Предпочитаемая модель';

  @override
  String get preferredModelAny => 'Нет (использовать любую)';

  @override
  String get personaChooseProviderTitle => 'Выберите провайдера';

  @override
  String get personaChooseProviderSubtitle =>
      'Ваши настроенные провайдеры. Добавьте ещё в Настройках.';

  @override
  String get personaCloudProvidersSection => 'Облачные провайдеры';

  @override
  String get personaKokoroVoiceLabel => 'Голос Kokoro';

  @override
  String get personaKokoroVoiceSubtitle =>
      'Голос, когда эта персона говорит (голосовой чат / озвучка)';

  @override
  String get personaKokoroVoiceGlobal =>
      'Использовать глобальную настройку голоса';

  @override
  String get personaKokoroVoicePickerTitle => 'Голос персоны';

  @override
  String get personaKokoroSpeedLabel => 'Скорость речи';

  @override
  String get personaKokoroSpeedGlobal => 'Использовать глобальную скорость';

  @override
  String personaKokoroSpeedValue(String speed) {
    return '${speed}x';
  }

  @override
  String get voiceWhisperModelLabel => 'Модель Whisper';

  @override
  String get voiceWhisperModelTapToChoose =>
      'Нажмите, чтобы выбрать размер и скачать';

  @override
  String get imageGenSeedLabel => 'Сид генерации изображений';

  @override
  String imageGenSeedFixed(int seed) {
    return 'Фиксированный сид: $seed';
  }

  @override
  String get imageGenSeedRandomGlobal =>
      'Случайно (использовать глобальную настройку)';

  @override
  String get personaComfyWorkflowLabel => 'Рабочий процесс ComfyUI';

  @override
  String get personaComfyWorkflowUseGlobal =>
      'Использовать глобальную настройку';

  @override
  String personaComfyWorkflowUnavailable(String path) {
    return '$path (сейчас недоступен)';
  }

  @override
  String get personaComfyWorkflowHelper =>
      'Используется, когда поставщик генерации изображений — ComfyUI. Оставьте «глобально», чтобы использовать Настройки → Генерация изображений.';

  @override
  String get personaComfyWorkflowNotComfy =>
      'Это назначение действует только когда активный поставщик изображений — ComfyUI.';

  @override
  String get personaComfyWorkflowRefresh => 'Обновить рабочие процессы';

  @override
  String get personaComfyWorkflowJsonLabel =>
      'Свой JSON workflow (необязательно)';

  @override
  String get personaComfyWorkflowJsonHint =>
      'Оставьте пустым для глобального / встроенного workflow';

  @override
  String get personaComfyWorkflowJsonHelper =>
      'Вставьте workflow в API-формате. Поддерживаются %PROMPT%, %LORA%, %LORA_WEIGHT% и другие плейсхолдеры.';

  @override
  String get personaComfyWorkflowJsonIgnored =>
      'Игнорируется, пока выбран сохранённый workflow';

  @override
  String personaComfyWorkflowJsonActive(int count) {
    return 'Свой workflow ($count символов)';
  }

  @override
  String get personaComfyWorkflowJsonClear =>
      'Очистить (глобальный / по умолчанию)';

  @override
  String get comfyUiDetails => 'Сведения ComfyUI';

  @override
  String get comfyUiDetailsTitle => 'Запрос ComfyUI';

  @override
  String get comfyUiDetailsCopy => 'Копировать JSON';

  @override
  String get comfyUiDetailsCopied => 'Скопировано в буфер обмена';

  @override
  String get resetToGlobal => 'Сбросить к глобальному';

  @override
  String get setSeed => 'Задать сид';

  @override
  String get pickAccentColor => 'Выбрать акцентный цвет';

  @override
  String get imageGenSeedDialogDescription =>
      'Задайте фиксированный сид, чтобы эта персона всегда генерировала согласованные изображения. Оставьте пустым для случайного выбора.';

  @override
  String get seedValueLabel => 'Значение сида';

  @override
  String get seedValueHint => 'например, 42 (пусто = случайно)';

  @override
  String get setLabel => 'Задать';

  @override
  String get selectPreferredModelTitle => 'Выбрать предпочитаемую модель';

  @override
  String get branchCreated => '🔀 Ветка создана';

  @override
  String get yamlFrontmatter => 'YAML-заголовок';

  @override
  String get markdownFormat => 'Markdown';

  @override
  String get localNetworkBlocked =>
      'Доступ к локальной сети может быть заблокирован';

  @override
  String get localNetworkFix =>
      'Перейдите в Настройки → LM Mini → Локальная сеть и включите.';

  @override
  String get openAppSettings => 'Открыть настройки приложения';

  @override
  String get memorySaved => 'Воспоминание сохранено';

  @override
  String get proSearch => 'Про-поиск';

  @override
  String get webSearchLabel => 'Веб-поиск';

  @override
  String get readUrl => 'Прочитать URL';

  @override
  String get code => 'код';

  @override
  String couldNotOpenFile(String error) {
    return 'Не удалось открыть файл: $error';
  }

  @override
  String get tapOpenExternal =>
      'Нажмите «Открыть во внешнем приложении» для просмотра файла';

  @override
  String get proSearchEnabled => 'Про-поиск включён';

  @override
  String get proSearchDisabled => 'Про-поиск выключен';

  @override
  String get thinkingEnabled => 'Размышления включены для этого чата';

  @override
  String get thinkingDisabled => 'Размышления выключены для этого чата';

  @override
  String get codeSandbox => 'Песочница кода';

  @override
  String get codeSandboxSubtitle =>
      'Запускайте Python или JavaScript в безопасной песочнице';

  @override
  String get codeSandboxEnabled => 'Песочница кода включена';

  @override
  String get codeSandboxDisabled => 'Песочница кода выключена';

  @override
  String get searxngNotConfigured => 'Добавьте URL SearXNG, чтобы включить';

  @override
  String get searxngConfiguredOff =>
      'Настроено — нажмите, чтобы использовать вместо Про-поиска';

  @override
  String get searxngConfigureFirst => 'Сначала настройте URL SearXNG';

  @override
  String get editSearxng => 'Изменить SearXNG';

  @override
  String get toolCallingLabel => 'Вызов инструментов';

  @override
  String get on => 'Вкл.';

  @override
  String get off => 'Выкл.';

  @override
  String get aiCanUseTools => 'ИИ может использовать инструменты в этом чате';

  @override
  String get toolsDisabledChat => 'Инструменты отключены для этого чата';

  @override
  String get webSearchChat => 'Веб-поиск';

  @override
  String get aiCanSearchWeb => 'ИИ может искать в интернете в этом чате';

  @override
  String get webSearchDisabledChat => 'Веб-поиск отключён для этого чата';

  @override
  String get disableMemory => 'Отключить память';

  @override
  String memoryItemsActive(int count) {
    return '$count элементов памяти активно';
  }

  @override
  String get memoryDisabledChat =>
      'Память отключена для этого чата. ИИ не увидит ваши сохранённые воспоминания.';

  @override
  String get lmStudioLocal => 'LM Studio (Локальный)';

  @override
  String get modelNoLongerAvailable =>
      'Ранее выбранная модель больше недоступна. Выберите новую модель.';

  @override
  String get noModelsForProvider =>
      'Модели для этого провайдера не найдены. Проверьте API-ключ.';

  @override
  String get noModelsCheckConnection =>
      'Модели не найдены. Проверьте подключение к LM Studio.';

  @override
  String get selectModel => 'Выбрать модель';

  @override
  String get goToModels => 'К моделям';

  @override
  String get reviewImagePrompt => 'Проверить промпт изображения';

  @override
  String get editImagePromptHint => 'Редактировать промпт изображения...';

  @override
  String get generate => 'Сгенерировать';

  @override
  String get imageNotFound => 'Изображение не найдено';

  @override
  String get cameraPermissionNeeded => 'Требуется разрешение камеры';

  @override
  String get cameraPermissionExplain =>
      'Разрешите доступ к камере для фотографирования с целью визуального анализа.';

  @override
  String get photosPermissionNeeded => 'Требуется разрешение для фото';

  @override
  String get photosPermissionExplain =>
      'Разрешите доступ к вашим изображениям для визуального анализа.';

  @override
  String couldNotOpenFilePicker(String error) {
    return 'Не удалось открыть файловый менеджер: $error';
  }

  @override
  String get filePickerCouldNotCopy =>
      'Не удалось скопировать файл. Сохраните его на телефон (не Drive и не Недавние) и выберите снова.';

  @override
  String get signInToUseCloudBackup =>
      'Войдите, чтобы использовать облачное резервное копирование';

  @override
  String get cloudBackupRequiresAccount =>
      'Облачное резервное копирование требует аккаунт, чтобы ваши зашифрованные резервные копии хранились безопасно под вашей учётной записью.';

  @override
  String get arguments => 'Аргументы';

  @override
  String get selectLanguage => 'Выбрать язык';

  @override
  String get connectionPopupTitle => 'Нет подключения';

  @override
  String get connectionPopupBody =>
      'LM Mini не удалось подключиться к LM Studio.\nПерейдите в Настройки, чтобы указать адрес сервера.';

  @override
  String get connectionPopupDismiss => 'Позже';

  @override
  String get connectionPopupGoToSettings => 'Перейти в Настройки';

  @override
  String get remoteAccess => 'Удалённый доступ';

  @override
  String get scanQrCode => 'Сканировать QR-код';

  @override
  String get connectedViaLmConnect => 'Подключено через LM Connect';

  @override
  String get disconnectRemoteToChangeSettings =>
      'LM Studio подключён через LM Connect';

  @override
  String get disconnect => 'Отключить';

  @override
  String get unpair => 'Отвязать';

  @override
  String get useRemoteConnection => 'Чат с этим Mac';

  @override
  String get useRemoteConnectionOffSubtitle =>
      'Выкл. — телефон использует свои модели. Включите, чтобы использовать модели LM Mini Home.';

  @override
  String get connectedViaLmStudio => 'Подключено через LM Studio';

  @override
  String get usingLocalServer => 'Используется локальный сервер';

  @override
  String get testing => 'Тестирование...';

  @override
  String connectedLatency(int ms) {
    return 'Подключено — $msмс';
  }

  @override
  String get notConnected => 'Не подключено';

  @override
  String get scanQrDescription =>
      'Отсканируйте QR-код из приложения LM Mini Connect на компьютере, чтобы подключиться к LM Studio откуда угодно.';

  @override
  String get remotePaired => 'Удалённое сопряжение';

  @override
  String lastConnected(String time) {
    return 'Последнее подключение: $time';
  }

  @override
  String get reScanQrCode => 'Пересканировать QR-код';

  @override
  String get qrRequiresPro => 'Сканирование QR-кода требует LM Mini Pro';

  @override
  String get enterUrlManually => 'Ввести URL вручную';

  @override
  String get enterUrlManuallySubtitle =>
      'Вставьте ссылку сопряжения, если камера недоступна';

  @override
  String get relayUrlHint => 'https://relay.lmmini.com/s/…';

  @override
  String get connectWithUrl => 'Подключиться по URL';

  @override
  String get invalidRelayUrl =>
      'Это недействительная ссылка сопряжения LM Mini. Скопируйте её в «Поделиться с телефоном» на Mac.';

  @override
  String get invalidQrCode =>
      'Недействительный QR-код. Используйте приложение LM Mini Connect для создания.';

  @override
  String get pointCameraAtQr =>
      'Наведите камеру на QR-код, показанный в приложении LM Mini Connect';

  @override
  String get connectedToRemoteLmStudio => 'Подключено к удалённому LM Studio!';

  @override
  String get failedToConnect =>
      'Не удалось подключиться. Убедитесь, что LM Mini Connect запущен.';

  @override
  String get unpairRemote => 'Отвязать удалённый доступ';

  @override
  String get unpairRemoteDescription =>
      'Это удалит сохранённое удалённое подключение. Вы можете повторно привязать, отсканировав новый QR-код.';

  @override
  String get setupGuide => 'Руководство по настройке';

  @override
  String get downloadLmMiniConnect => 'Скачать LM Mini Home';

  @override
  String get availableForPlatforms =>
      'Прямая загрузка для Mac · Connect для Windows и Linux';

  @override
  String get setupStep1Title => 'Скачать LM Mini Home';

  @override
  String get setupStep1Desc =>
      'Скачайте LM Mini Home для Mac с lmmini.com. На Windows и Linux по-прежнему можно использовать LM Mini Connect.';

  @override
  String get setupStep2Title => 'Поделиться с телефоном';

  @override
  String get setupStep2Desc =>
      'В LM Mini Home на Mac откройте «Поделиться с телефоном» и включите. Подключение к реле происходит сразу.';

  @override
  String get setupStep3Title => 'Сканировать QR-код';

  @override
  String get setupStep3Desc =>
      'Отсканируйте QR-код, который показывает LM Mini Home на Mac. Готово!';

  @override
  String minutesAgo(int count) {
    return '$countмин назад';
  }

  @override
  String hoursAgo(int count) {
    return '$countч назад';
  }

  @override
  String daysAgo(int count) {
    return '$countд назад';
  }

  @override
  String get selectAll => 'Выбрать все';

  @override
  String get moveToFolder => 'Переместить в папку';

  @override
  String get select => 'Выбрать';

  @override
  String get dismissAction => 'Закрыть';

  @override
  String get createNewFolder => 'Создать новую папку';

  @override
  String deleteConversations(int count) {
    return 'Удалить $count беседу(ы)? Это действие нельзя отменить.';
  }

  @override
  String get averages => 'СРЕДНИЕ';

  @override
  String get tokensPerChat => 'Токены / Чат';

  @override
  String get msgsPerChat => 'Сообщ. / Чат';

  @override
  String get tokensPerMsg => 'Токены / Сообщ.';

  @override
  String get topModel => 'Топ модель';

  @override
  String get liveActivityTitle => 'Live Activity';

  @override
  String get liveActivityTitleAndroid => 'Фоновая генерация';

  @override
  String get liveActivityDescription =>
      'Обрабатывайте запрос к ИИ, даже когда выходите из приложения или блокируете телефон';

  @override
  String get liveActivityDescriptionAndroid =>
      'Генерация продолжается при выходе из приложения. Прогресс в постоянном уведомлении; Android не прерывает модель посреди ответа.';

  @override
  String get liveActivityAndroidOnDeviceOnly =>
      'Переключитесь на локальную модель GGUF или MLX, чтобы использовать фоновую генерацию на Android.';

  @override
  String get liveActivityNotificationDenied =>
      'Для фоновой генерации на Android нужно разрешение на уведомления.';

  @override
  String get premiumRemoteAccess => 'Удалённый доступ';

  @override
  String get premiumRemoteAccessTagline => 'LM Studio откуда угодно';

  @override
  String get premiumRemoteAccessDescription =>
      'Получите доступ к локальному LM Studio откуда угодно с LM Mini Connect. Без проброса портов и VPN — просто отсканируйте QR-код.';

  @override
  String get premiumLiveActivity => 'Live Activity';

  @override
  String get premiumLiveActivityTagline => 'ИИ работает в фоне';

  @override
  String get premiumLiveActivityDescription =>
      'Обрабатывайте запрос к ИИ, даже когда выходите из приложения или блокируете телефон. Следите за прогрессом на экране блокировки.';

  @override
  String get premiumWebSearchTagline => 'Без настройки сервера';

  @override
  String get premiumWebSearchDescription =>
      'Мгновенный поиск в интернете во время разговоров. На базе облачных API поиска.';

  @override
  String get premiumCloudBackup =>
      'Зашифрованное облачное резервное копирование';

  @override
  String get premiumCloudBackupTagline => 'Шифрование AES-256-GCM';

  @override
  String get premiumCloudBackupDescription =>
      'Резервное копирование всех бесед в облако с шифрованием военного уровня. Ваш пароль никогда не покидает устройство.';

  @override
  String get premiumUrlReader => 'Чтение URL';

  @override
  String get premiumUrlReaderTagline => 'Анализ любой веб-страницы';

  @override
  String get premiumUrlReaderDescription =>
      'Вставьте любой URL и ваша модель прочитает полное содержимое страницы.';

  @override
  String get premiumBranching => 'Ветвление бесед';

  @override
  String get premiumBranchingTagline => 'Исследуйте альтернативные пути';

  @override
  String get premiumBranchingDescription =>
      'Разветвляйте любую беседу для исследования сценариев \"что если\".';

  @override
  String get premiumMemory => 'Воспоминания';

  @override
  String get premiumMemoryTagline => 'Помнит вас между чатами';

  @override
  String get premiumMemoryDescription =>
      'Сохраняйте факты, предпочтения и контекст, которые сохраняются во всех беседах.';

  @override
  String get premiumAnalytics => 'Панель аналитики';

  @override
  String get premiumAnalyticsTagline => 'Знайте своё использование';

  @override
  String get premiumAnalyticsDescription =>
      'Отслеживайте использованные токены, отправленные сообщения, использование моделей и среднее время ответа.';

  @override
  String get premiumCloudApi => 'Облачные API-провайдеры';

  @override
  String get premiumCloudApiTagline => 'Mistral, Anthropic и другие';

  @override
  String get premiumCloudApiDescription =>
      'Подключайте облачных LLM-провайдеров наряду с локальными моделями.';

  @override
  String get premiumExport => 'Экспорт и обмен';

  @override
  String get premiumExportTagline => 'Obsidian, Заметки, Notion и другие';

  @override
  String get premiumExportDescription =>
      'Экспортируйте беседы в форматированный Markdown, PDF или текст.';

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
      'Крупные модели каталога и импорт с HF';

  @override
  String get premiumOnDeviceLlmDescription =>
      'Локальный чат бесплатен с подобранными стартовыми моделями. Pro открывает загрузку из каталога моделей больше 2B параметров и импорт своих GGUF/MLX с Hugging Face — полностью офлайн.';

  @override
  String get premiumHfBrowse => 'Импорт с Hugging Face';

  @override
  String get premiumHfBrowseTagline => 'Любая GGUF-модель на борт';

  @override
  String get premiumHfBrowseDescription =>
      'Ищите на Hugging Face, загружайте GGUF на устройство или сервер LM Studio и используйте в LM Mini. Фильтры совместимости, фоновые загрузки и выход за пределы бесплатного каталога — без API-ключа.';

  @override
  String get onDeviceProviderLabel => 'Локально';

  @override
  String get onDeviceManageModels => 'Управлять локальными моделями';

  @override
  String get onDeviceGeneratingHint => 'Генерация на устройстве…';

  @override
  String get onDeviceEngineUnavailable => 'Локальный движок недоступен';

  @override
  String get onDeviceOpenBrowser => 'Открыть локальные модели';

  @override
  String get onDeviceManagedHere =>
      'Локальные модели управляются в отдельном экране: скачивание, удаление и активация.';

  @override
  String get onDeviceRemoteImageOnly =>
      'Выбран On-Device AI — удалённый доступ только для генерации изображений и голоса Kokoro (если настроен). Чат остаётся на этом устройстве.';

  @override
  String get onDeviceProOnly => 'Только Pro';

  @override
  String get onDeviceInstalled => 'Установлено';

  @override
  String get onDeviceUseModel => 'Использовать';

  @override
  String get onDeviceRemoveModel => 'Удалить';

  @override
  String get onDeviceDownloadAnyway => 'Всё равно скачать';

  @override
  String onDeviceNowUsing(String name) {
    return 'Теперь используется $name локально';
  }

  @override
  String get onDeviceEngineFllamaLabel => 'fllama (GGUF)';

  @override
  String onDeviceEngineSwitched(String engine) {
    return 'Переключено на $engine. Предыдущая модель выгружена.';
  }

  @override
  String onDeviceEngineSwitchedCleared(String engine) {
    return 'Переключено на $engine. Предыдущая модель несовместима и снята с выбора — выберите модель в разделе «Локальные модели».';
  }

  @override
  String get onDeviceImportedLabel => 'Импортирована';

  @override
  String get onDeviceFreeLabel => 'Бесплатно';

  @override
  String get onDeviceProLabel => 'Pro';

  @override
  String get onDeviceMayCrashLabel => 'Может упасть';

  @override
  String get onDeviceModelMayCrashTitle => 'Модель может вызвать сбой';

  @override
  String onDeviceModelMayCrashMessage(
      String name, String runtimeGb, String deviceRamGb) {
    return '$name требует около $runtimeGb ГБ памяти при работе. На устройстве доступно примерно $deviceRamGb ГБ для приложений. Загрузка может привести к зависанию или сбою.';
  }

  @override
  String get onDeviceContinueLoading => 'Всё равно загрузить';

  @override
  String get yearly => 'Годовой';

  @override
  String get monthly => 'Месячный';

  @override
  String get lifetime => 'Навсегда';

  @override
  String get subscriptionLifetimeBadge => 'Один раз';

  @override
  String get subscriptionLifetimeDisclaimer =>
      'Разовая покупка. Pro-функции на вашем аккаунте, пока LM Mini предлагается и поддерживается. Не включает плату за сторонние API и отдельно размещённые сервисы — см. Условия.';

  @override
  String subscriptionLifetimeUpgradeDisclaimer(String store) {
    return 'Lifetime — отдельная разовая покупка. Текущая подписка не отменится автоматически, и мы не можем вернуть уже списанные платежи. После покупки отмените подписку в $store.';
  }

  @override
  String get subscriptionUpgradeToLifetime => 'Перейти на Lifetime';

  @override
  String subscriptionUpgradeToLifetimeSubtitle(String price) {
    return 'Оплатить один раз — $price';
  }

  @override
  String get duplicateSubscriptionDialogTitle => 'Отмените подписку';

  @override
  String duplicateSubscriptionDialogBody(String store) {
    return 'У вас Lifetime Pro и активная подписка. Lifetime не заменяет подписку автоматически, и мы не можем вернуть платежи по подписке. Отмените подписку в $store, чтобы избежать дальнейших списаний.';
  }

  @override
  String duplicateSubscriptionDialogManage(String store) {
    return 'Открыть $store';
  }

  @override
  String get duplicateSubscriptionDialogDismiss => 'Понятно';

  @override
  String get duplicateSubscriptionNoManageUrl =>
      'Откройте настройки подписок на устройстве, чтобы отменить.';

  @override
  String supportLifetime(String price) {
    return 'Разблокировать навсегда — $price';
  }

  @override
  String get encryptionKey => 'Ключ шифрования';

  @override
  String get encryptionEnabled => 'Шифрование: Вкл';

  @override
  String get encryptionDisabled => 'Шифрование: Выкл';

  @override
  String get encryptionKeyDescription =>
      'Сквозной ключ шифрования для удалённого доступа. Должен совпадать с ключом в LM Mini Connect.';

  @override
  String get editEncryptionKey => 'Изменить ключ шифрования';

  @override
  String get enterEncryptionKey => 'Введите ключ шифрования';

  @override
  String get encryptionKeyUpdated => 'Ключ шифрования обновлён';

  @override
  String get keepLmMiniAlive => 'Поддержите\nLM Mini';

  @override
  String get supportTheApp =>
      'Поддержите приложение и получите премиум-привилегии';

  @override
  String get mostFeaturesFree =>
      'Большинство функций бесплатны — Pro помогает покрыть расходы на серверы';

  @override
  String get thankYouSupport => 'Спасибо за вашу поддержку!';

  @override
  String get helpingKeepAlive => 'Вы помогаете LM Mini оставаться на плаву';

  @override
  String get linkSignInMethod =>
      'Привяжите способ входа, чтобы сохранить подписку при смене устройства.';

  @override
  String get paywallLinkAccountBody =>
      'Вы используете анонимный аккаунт. Привяжите Apple или Google перед покупкой, чтобы Pro синхронизировался между устройствами и сохранялся после переустановки.';

  @override
  String get continueAnonymously => 'Продолжить анонимно';

  @override
  String signedInViaMethod(String method) {
    return 'Вход через $method';
  }

  @override
  String get yourSubscriptionSecured => 'Ваша подписка защищена';

  @override
  String subscriptionManagedThrough(String store) {
    return 'Подписка управляется через $store.';
  }

  @override
  String get subscriptionsComingSoon => 'Подписки скоро появятся';

  @override
  String get premiumPreview =>
      'Премиум-функции дорабатываются.\nВы можете включить режим разработчика ниже для предпросмотра.';

  @override
  String get enableDeveloperPremium => 'Включить Premium разработчика';

  @override
  String get disableDeveloperPremium => 'Отключить Premium разработчика';

  @override
  String get premiumEnabled => 'Premium включён (переопределение разработчика)';

  @override
  String get premiumDisabled => 'Premium отключён';

  @override
  String supportYearly(String price) {
    return 'Поддержать — $price/год';
  }

  @override
  String supportMonthly(String price) {
    return 'Поддержать — $price/мес';
  }

  @override
  String get welcomeToLmMiniPro => 'Добро пожаловать в LM Mini Pro!';

  @override
  String get connectedRemotely => 'Подключено удалённо';

  @override
  String get pairedNotActive => 'Сопряжено — не активно';

  @override
  String get accessLmStudioAnywhere => 'Доступ к LM Studio откуда угодно';

  @override
  String get appStore => 'App Store';

  @override
  String get googlePlayStore => 'Google Play Store';

  @override
  String get starterAttach => 'Файл';

  @override
  String get starterImages => 'Фото';

  @override
  String get starterMode => 'Режим';

  @override
  String get newGroupChat => 'Новый групповой чат';

  @override
  String get groupChat => 'Групповой чат';

  @override
  String get groupChatMultipleModels => 'Общайтесь с несколькими моделями';

  @override
  String get groupChatParticipants => 'Участники';

  @override
  String get groupChatTurnMode => 'Режим очерёдности';

  @override
  String get groupChatRoundRobin => 'По кругу';

  @override
  String get groupChatManual => 'Вручную';

  @override
  String get groupChatParallelStreaming => 'Параллельная трансляция';

  @override
  String get groupChatAutoLoadUnload => 'Авто загрузка/выгрузка';

  @override
  String get groupChatStreamAllSimultaneously =>
      'Транслировать всех участников одновременно';

  @override
  String get groupChatAutoLoadModels =>
      'Автоматически загружать модели при необходимости';

  @override
  String get groupChatAsk => 'Спросить:';

  @override
  String get groupChatTapToReplyNudge => 'Нажмите, кто должен ответить';

  @override
  String get groupChatTrialBannerTitle => 'Групповой чат — Бесплатно 7 дней!';

  @override
  String get groupChatTrialBannerBody =>
      'Попробуйте групповой чат бесплатно 7 дней с до 2 персонажами. Перейдите на LM Mini Pro для неограниченного доступа.';

  @override
  String groupChatTrialDaysLeft(int days) {
    return 'Осталось $days дней пробного периода';
  }

  @override
  String get groupChatTrialExpired =>
      'Ваш 7-дневный пробный период группового чата закончился. Перейдите на Pro, чтобы продолжить.';

  @override
  String get groupChatTrialGetPro => 'Получить Pro';

  @override
  String get groupChatTrialDismiss => 'Понятно';

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
  String get premiumGroupChat => 'Групповой чат';

  @override
  String get premiumGroupChatTagline => 'Многоперсонажные разговоры';

  @override
  String get premiumGroupChatDescription =>
      'Общайтесь с несколькими персонажами ИИ в одном чате — у каждого свой модель, аватар и характер. Настройка бесплатна; отправка сообщений требует LM Mini Pro.';

  @override
  String get groupChatProRequiredTitle => 'Групповой чат требует Pro';

  @override
  String get groupChatProRequiredBody =>
      'Вы можете бесплатно изучить настройку и читать старые чаты. Оформите LM Mini Pro, чтобы отправлять сообщения и продолжать общение с несколькими персонажами ИИ.';

  @override
  String get groupChatProRequiredUpgrade => 'Перейти на Pro';

  @override
  String get groupChatLockedBanner =>
      'Групповой чат доступен только для чтения без Pro. Оформите Pro, чтобы отправлять сообщения.';

  @override
  String get premiumArena => 'Арена';

  @override
  String get premiumArenaTagline => 'Сравнение моделей бок о бок';

  @override
  String get premiumArenaDescription =>
      'Запускайте один и тот же промпт на нескольких моделях и сравнивайте ответы, скорость и совместимость с устройством. Режим бенчмарка оценивает модели по прозрачной шкале.';

  @override
  String get startLabel => 'Начать';

  @override
  String groupChatInviteUpTo(int count) {
    return 'Добавьте до $count моделей ИИ в общий чат. У каждой может быть своя персона, аватар и системный промпт.';
  }

  @override
  String get groupChatPremiumParticipantsNote =>
      'Premium позволяет до 5 участников в одном групповом чате.';

  @override
  String get groupChatUserNameHint =>
      'Как ИИ будут обращаться к вам (например, Alex)';

  @override
  String get groupChatScenarioLabel => 'Сценарий / о себе (необязательно)';

  @override
  String get groupChatScenarioHint =>
      'например: «Мы коллеги в технологическом стартапе. Я продакт-менеджер и прошу у команды совета.»';

  @override
  String get groupChatTurnModeRoundRobinDescription =>
      'По очереди: все модели отвечают по порядку';

  @override
  String get groupChatTurnModeManualDescription =>
      'Вручную: введите @Имя, чтобы выбрать, кто отвечает';

  @override
  String get groupChatReplyToUserOnlyLabel => 'Отвечать только пользователю';

  @override
  String get groupChatReplyToUserOnlySubtitle =>
      'Каждый ИИ игнорирует других ИИ, что предотвращает перекрёстные ответы у небольших моделей';

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
      'Нет доступных моделей. Сначала подключитесь к LM Studio.';

  @override
  String get addModelLabel => 'Добавить модель';

  @override
  String modelNumber(int number) {
    return 'Модель $number';
  }

  @override
  String groupChatParticipantInfo(String name, String model) {
    return '$name\nМодель: $model';
  }

  @override
  String get customPromptSet => 'Пользовательский промпт задан';

  @override
  String get removeLabel => 'Удалить';

  @override
  String get displayNameLabel => 'Отображаемое имя';

  @override
  String get displayNameHint => 'например, Профессор, Разработчик, Художник';

  @override
  String get customRequestHeaders => 'Пользовательские заголовки запроса';

  @override
  String get customRequestHeadersSubtitle =>
      'Дополнительные заголовки, добавляемые к каждому запросу LM Studio';

  @override
  String get customRequestHeadersHelp =>
      'Используйте это для обратных прокси или шлюзов аутентификации, которым требуются дополнительные заголовки (например, сервисные токены Cloudflare Access, внутренний токен под пользовательским именем заголовка и т. д.). Заголовки отправляются с каждым запросом к вашему серверу LM Studio.';

  @override
  String get cloudflareAccessSection => 'Cloudflare Access (сервисный токен)';

  @override
  String get cloudflareAccessHelp =>
      'Если ваш LM Studio находится за политикой Cloudflare Access, вставьте сюда идентификатор клиента и секрет сервисного токена. Они отправляются как CF-Access-Client-Id и CF-Access-Client-Secret с каждым запросом, чтобы приложение могло пройти аутентификацию без интерактивного входа SSO в браузере.';

  @override
  String get cfAccessClientIdLabel => 'CF-Access-Client-Id';

  @override
  String get cfAccessClientSecretLabel => 'CF-Access-Client-Secret';

  @override
  String get addHeader => 'Добавить заголовок';

  @override
  String get removeHeader => 'Удалить заголовок';

  @override
  String get headerNameLabel => 'Имя заголовка';

  @override
  String get headerValueLabel => 'Значение заголовка';

  @override
  String headersConfigured(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Настроено $count заголовков',
      one: 'Настроен 1 заголовок',
    );
    return '$_temp0';
  }

  @override
  String get noCustomHeaders => 'Нет пользовательских заголовков';

  @override
  String get comfyUiUseNegativePromptTitle => 'Использовать негативный промпт';

  @override
  String get comfyUiUseNegativePromptSubtitle =>
      'По умолчанию отключено для ComfyUI. Когда отключено, негативный промпт не отправляется в воркфлоу.';

  @override
  String get documentationTitle => 'Документация';

  @override
  String get documentationSubtitle =>
      'Руководства по настройке группового чата, ComfyUI, поведения клавиатуры и многого другого';

  @override
  String get changelogTitle => 'История изменений';

  @override
  String get changelogSubtitle => 'История версий и обновлений';

  @override
  String get enableCustomHeaders => 'Включить пользовательские заголовки';

  @override
  String get enableCustomHeadersSubtitle =>
      'Прикреплять дополнительные HTTP-заголовки к каждому запросу LM Studio';

  @override
  String deleteMemoriesCount(int count) {
    return 'Удалить $count воспоминаний?';
  }

  @override
  String get deleteMemoriesConfirm =>
      'Эти воспоминания будут удалены навсегда.';

  @override
  String get moveToCategory => 'Переместить в категорию';

  @override
  String nSelected(int count) {
    return 'Выбрано: $count';
  }

  @override
  String movedToCategory(String category) {
    return 'Перемещено в $category';
  }

  @override
  String get moveCategoryTooltip => 'Переместить категорию';

  @override
  String get memoryScreenSubtitle =>
      'Факты, которые ИИ помнит о вас между чатами.';

  @override
  String get rememberMe => 'Запоминать меня';

  @override
  String get rememberMeSubtitle =>
      'Использовать сохранённые заметки в будущих разговорах';

  @override
  String get memoryPerPersona => 'По персонам';

  @override
  String get memoryPerPersonaSubtitle =>
      'Делиться заметками только с активной персоной (и глобальными)';

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
  String get memoryBrowseSection => 'Обзор';

  @override
  String get memoryMultiSelectTip =>
      'Совет: долгий тап по заметке, чтобы выбрать несколько.';

  @override
  String get memoryEmptyFilteredHint =>
      'Добавьте заметку или выберите другую категорию.';

  @override
  String get memoryEmptyHint =>
      'Сохраните немного о себе — имя, предпочтения, проекты — чтобы чаты были личнее.';

  @override
  String get memoryShareWith => 'Поделиться с';

  @override
  String get memoryEveryone => 'Все';

  @override
  String get memoryEveryoneSubtitle => 'Доступно в каждом чате';

  @override
  String get memoryNoPersonasHint =>
      'Пока нет персон. Создайте в Настройки → Персоны.';

  @override
  String get memoryNewNote => 'Новая заметка';

  @override
  String get memoryNoteHint =>
      'напр. Я предпочитаю короткие ответы и живу в Берлине';

  @override
  String get memoryEditNote => 'Изменить заметку';

  @override
  String monthsAgo(int count) {
    return '$count мес. назад';
  }

  @override
  String get moreTooltip => 'Ещё';

  @override
  String get closeSearch => 'Закрыть поиск';

  @override
  String get moveTooltip => 'Переместить';

  @override
  String get chatsTab => 'Чаты';

  @override
  String get groupsTab => 'Группы';

  @override
  String get foldersTooltip => 'Папки';

  @override
  String get newFolder => 'Новая папка';

  @override
  String get tapToReturnToCall => 'Нажмите, чтобы вернуться к звонку';

  @override
  String get selectConversation => 'Выберите беседу';

  @override
  String get selectConversationHint =>
      'Выберите из списка или начните новый чат.';

  @override
  String get noGroupChatsYet => 'Групповых чатов пока нет';

  @override
  String get noGroupChatsSubtitle =>
      'Начните мультиперсона-беседу, чтобы общаться с несколькими ИИ.';

  @override
  String get newPersonaShort => 'Новая';

  @override
  String get downloadOnDeviceModelTitle => 'Скачать модель на устройство';

  @override
  String get downloadOnDeviceModelBody =>
      'Скачайте модель для чата без ПК или подключите LM Studio / Ollama.';

  @override
  String get browseModels => 'Обзор моделей';

  @override
  String get waitingForMac => 'Ожидание Mac';

  @override
  String get waitingForMacBody =>
      'Подключите iPhone к Mac по USB и откройте LM Mini Connect на Mac.';

  @override
  String get arenaMode => 'Режим Arena';

  @override
  String get voiceWhisperSizeInfoTitle => 'Большие модели слышат лучше';

  @override
  String get voiceWhisperSizeInfoBody =>
      'Более крупные модели распознавания обычно точнее, особенно с акцентами и шумом. Они занимают больше места и могут загружаться чуть дольше.';

  @override
  String get voiceRemoveListeningModelTitle => 'Удалить модель распознавания?';

  @override
  String get voiceRemoveListeningModelBody =>
      'Это освободит место. Voice Call и микрофон снова потребуют модель для офлайн-распознавания.';

  @override
  String get voiceTtsOnDeviceNeural => 'Скачанный голос';

  @override
  String get voiceTtsPcVoice => 'Голос ПК';

  @override
  String get voiceTtsSystemVoice => 'Системный голос';

  @override
  String get voiceTtsOnDeviceHint =>
      'Естественные голоса, которые вы скачиваете. Работает без интернета.';

  @override
  String get voiceTtsPcHint =>
      'Голосовая модель на компьютере через «Поделиться с телефоном»';

  @override
  String get voiceTtsSystemHint => 'Голоса вашего телефона — готовы сразу';

  @override
  String get voiceSttOnDevice => 'На этом устройстве';

  @override
  String get voiceSttWhisperHint => 'Офлайн-модель — обычно точнее';

  @override
  String get voiceSttSystemHint => 'Встроенное распознавание — быстро и просто';

  @override
  String get voiceSttSystemUnavailableOnMac => 'Нужна загрузка';

  @override
  String get voiceSttMacosRequiresWhisper =>
      'Сборки App Store используют Whisper на устройстве для прослушивания. Скачайте модель, чтобы включить его.';

  @override
  String get voiceSttMacosSystemOptionSubtitle =>
      'Скачайте Whisper, чтобы включить прослушивание';

  @override
  String get voiceSttMacosDownloadWhisper =>
      'Скачайте Whisper, чтобы включить прослушивание';

  @override
  String get voiceSettingsIntro =>
      'Как произносятся ответы и как понимается ваш голос.';

  @override
  String get voiceSectionReady => 'Готово';

  @override
  String get voiceSectionSpeaking => 'Речь';

  @override
  String get voiceSectionListening => 'Слушание';

  @override
  String get voiceSectionConversation => 'Разговор';

  @override
  String get voiceStatusSpeaking => 'Речь';

  @override
  String get voiceStatusListening => 'Слушание';

  @override
  String get voiceHowISpeak => 'Как я говорю';

  @override
  String get voiceImportPack => 'Импорт голосового пакета';

  @override
  String get voiceImportPackSubtitle => 'Вставьте GitHub URL голосового пакета';

  @override
  String get voiceHowIHearYou => 'Как я вас слышу';

  @override
  String get voiceHowIHearYouSubtitle =>
      'Выберите, как речь превращается в текст.';

  @override
  String get voiceListeningModel => 'Модель распознавания';

  @override
  String get voiceAboutModelSizes => 'О размерах моделей';

  @override
  String get voicePauseBeforeSend => 'Пауза перед отправкой';

  @override
  String get voicePauseBeforeSendSubtitle =>
      'Сколько ждать после того, как вы замолчали';

  @override
  String get voiceListeningLimit => 'Лимит прослушивания';

  @override
  String get voiceListeningLimitSubtitle =>
      'Максимальный отрезок до перезапуска микрофона';

  @override
  String get voiceQuickTip => 'Быстрый совет';

  @override
  String get voiceQuickTipBody =>
      'Для более естественного голоса скачайте язык в разделе Голосовые пакеты. Системный голос работает сразу.';

  @override
  String get voiceTestSampleHint => 'Короткий образец с текущими настройками';

  @override
  String get voiceTestNoPackReady =>
      'Скачайте язык в разделе Голосовые пакеты, затем попробуйте Test Voice.';

  @override
  String get voiceChooseListeningModel =>
      'Нажмите, чтобы выбрать модель распознавания';

  @override
  String get voiceModelReady => 'Готово';

  @override
  String get voiceNeedsDownload => 'Нужна загрузка';

  @override
  String get voiceDownloaded => 'Загружено';

  @override
  String get voiceDownloadFailed => 'Ошибка загрузки';

  @override
  String get voiceFinishingSetup => 'Завершение настройки…';

  @override
  String get voiceDownloadingListeningModel => 'Загрузка модели распознавания…';

  @override
  String get voiceDownloadingVoice => 'Загрузка голоса…';

  @override
  String get voiceStartingDownload => 'Начало загрузки…';

  @override
  String get voiceReady => 'Голос готов';

  @override
  String get voiceWarmingUp => 'Подготовка…';

  @override
  String get voiceReadyToSpeak => 'Готов говорить';

  @override
  String get voiceDownloadOnDevice => 'Скачать голос на устройство';

  @override
  String get voiceDownloadFailedRetry =>
      'Ошибка загрузки — нажмите, чтобы повторить';

  @override
  String get voiceSpokenReplyLanguage => 'Язык голосовых ответов';

  @override
  String get voiceSpokenReplyLanguageSubtitle =>
      'Язык, когда ассистент читает сообщения вслух.';

  @override
  String get voiceRecognitionLanguage => 'Язык распознавания';

  @override
  String get voiceRecognitionLanguageSubtitle =>
      'Для текстового микрофона и Voice Call — может отличаться от голосовых ответов.';

  @override
  String get voiceEngineTitle => 'Голос речи';

  @override
  String get voiceEngineSubtitle => 'Выберите, откуда берётся голос.';

  @override
  String get voiceChooseAVoice => 'Выбрать голос';

  @override
  String get voiceChooseAVoiceSubtitle =>
      'Удобные для предпросмотра имена для голоса на устройстве.';

  @override
  String get voiceUseSystemDefault =>
      'Использовать системный голос по умолчанию';

  @override
  String get welcomeWizardTitleGetStarted => 'Начало';

  @override
  String get welcomeWizardTitleYourSetup => 'Ваша настройка';

  @override
  String get welcomeWizardTitleLookAndFeel => 'Внешний вид';

  @override
  String get welcomeWizardTitleAlmostDone => 'Почти готово';

  @override
  String get welcomeWizardTitleSetup => 'Настройка';

  @override
  String get welcomeWizardLmStudioSubtitle => 'Запуск моделей на Mac или PC';

  @override
  String get welcomeWizardOllamaSubtitle => 'Популярный локальный сервер';

  @override
  String get welcomeWizardOmlxSubtitle => 'Десктоп-сервер Apple Silicon';

  @override
  String get welcomeWizardJanSubtitle =>
      'Локальные модели из приложения JAN AI';

  @override
  String get welcomeWizardUnslothSubtitle =>
      'Unsloth Desktop на вашем компьютере';

  @override
  String get welcomeWizardThemeSubtitle =>
      'Выберите оформление. Можно изменить в любое время.';

  @override
  String get welcomeWizardModelReady => 'Готово';

  @override
  String get welcomeWizardConnected => 'Подключено';

  @override
  String get welcomeWizardServerFound => 'Сервер найден';

  @override
  String get welcomeWizardRequiresApiKey => 'Нужен API-ключ';

  @override
  String get welcomeWizardScanHomeQr => 'Сканировать QR LM Mini Home';

  @override
  String get welcomeWizardScanHomeQrSubtitle =>
      'Привязка к Mac через «Поделиться с телефоном»';

  @override
  String welcomeWizardModelsFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count моделей найдено',
      many: '$count моделей найдено',
      few: '$count модели найдены',
      one: '1 модель найдена',
    );
    return '$_temp0';
  }

  @override
  String get welcomeWizardLocalNetworkTitle => 'Разрешить доступ к сети';

  @override
  String get welcomeWizardLocalNetworkBody =>
      'Система попросит доступ к локальной сети. Разрешите его, чтобы LM Mini мог найти LM Mini Home, LM Studio или Ollama на вашем компьютере.';

  @override
  String get welcomeWizardLocalNetworkAllow => 'Разрешить';

  @override
  String get welcomeWizardDownloadKeepsGoing =>
      'Можно уйти с этого экрана — загрузка продолжится, даже если вы закроете приложение.';

  @override
  String get welcomeWizardDownloadFailed =>
      'Загрузка не удалась. Нажмите, чтобы повторить.';

  @override
  String get welcomeWizardAiDownloadingTitle => 'ИИ загружается';

  @override
  String get welcomeWizardAiDownloadingBody =>
      'Вы сможете начать чат, как только будет готова подходящая ИИ для вашего телефона. Это одноразовая загрузка.';

  @override
  String get onDeviceModels => 'Модели на устройстве';

  @override
  String get transcription => 'Транскрипция';

  @override
  String get widgetSettings => 'Настройки виджетов';

  @override
  String get widgetSettingsSubtitle => 'Настроить виджеты домашнего экрана';

  @override
  String get setUpShortcuts => 'Настроить Shortcuts';

  @override
  String get shareArenaSpeedResults => 'Делиться результатами скорости Arena';

  @override
  String get browseOnDeviceModels => 'Обзор моделей на устройстве';

  @override
  String get homeDownloadModel => 'Скачать модель';

  @override
  String get usbMode => 'Режим USB';

  @override
  String get usbModeHowItWorks => 'Как работает режим USB';

  @override
  String get switchToUsbTitle => 'Переключиться с Remote на USB?';

  @override
  String get switchLabel => 'Переключить';

  @override
  String usbModeStartFailed(String error) {
    return 'Не удалось запустить режим USB: $error';
  }

  @override
  String get usbModeHowToUse => 'Как пользоваться:';

  @override
  String get openLmminiCom => 'Открыть lmmini.com';

  @override
  String get tapToUseServer => 'Нажмите, чтобы использовать этот сервер';

  @override
  String get memoryPersonaFallback => 'Персона';

  @override
  String get voicePickSystemVoiceSubtitle =>
      'Выберите встроенный голос для голосовых ответов.';

  @override
  String get chooseFromGallery => 'Выбрать из галереи';

  @override
  String get galleryLimitsSubtitle => 'Фото до 10 МБ · Видео до 200 МБ';

  @override
  String get recordVideo => 'Записать видео';

  @override
  String attachmentsCount(int count, int max) {
    return 'Вложения ($count/$max)';
  }

  @override
  String get viewProfile => 'Профиль';

  @override
  String get personaAndModel => 'Персона и модель';

  @override
  String get chatOptions => 'Параметры чата';

  @override
  String get chatTab => 'Чат';

  @override
  String get voiceTab => 'Голос';

  @override
  String get craftingPersona => 'Создание персоны…';

  @override
  String get randomPersona => 'Удиви меня';

  @override
  String get savePersona => 'Сохранить персону';

  @override
  String get downloadFinished => 'Загрузка завершена.';

  @override
  String get downloadCancelled => 'Загрузка отменена.';

  @override
  String get downloadCancelFailed =>
      'Не удалось отменить в LM Studio. Остановите загрузку в списке загрузок LM Studio.';

  @override
  String get newsBriefing => 'Новостной брифинг';

  @override
  String get refreshNow => 'Обновить сейчас';

  @override
  String get noBriefingYet => 'Брифинга пока нет';

  @override
  String get newsSetPromptFirst =>
      'Сначала задайте промпт виджета новостей в настройках виджетов.';

  @override
  String get newsRefreshed => 'Новости обновлены.';

  @override
  String newsRefreshFailed(String error) {
    return 'Не удалось обновить: $error';
  }

  @override
  String get themesTitle => 'Темы';

  @override
  String get createLabel => 'Создать';

  @override
  String get browseLabel => 'Обзор';

  @override
  String get signInToUploadThemes => 'Войдите, чтобы загружать темы';

  @override
  String get deleteThemeTitle => 'Удалить тему?';

  @override
  String deleteThemeConfirm(String name) {
    return 'Удалить «$name» из загруженных тем?';
  }

  @override
  String get uploadToCommunity => 'Загрузить в сообщество';

  @override
  String get installedLabel => 'Установлено';

  @override
  String get getLabel => 'Получить';

  @override
  String get bestForYou => 'Лучше для вас';

  @override
  String get loadingLabel => 'Загрузка';

  @override
  String get loadedLabel => 'Загружено';

  @override
  String get notLoadedLabel => 'Не загружено';

  @override
  String get reasoningLabel => 'Рассуждение';

  @override
  String get imagesLabel => 'Изображения';

  @override
  String get detailsTooltip => 'Подробности';

  @override
  String get transcribeAudio => 'Транскрибировать аудио';

  @override
  String get transcribeAudioSubtitle =>
      'Загрузите аудио и спросите ИИ о транскрипте';

  @override
  String get trimSection => 'Обрезать участок';

  @override
  String get includeTimestamps => 'Включить метки времени';

  @override
  String get phrasesLabel => 'Фразы';

  @override
  String get wordsLabel => 'Слова';

  @override
  String get transcriptionLanguage => 'Язык транскрипции';

  @override
  String get searchLanguages => 'Поиск языков…';

  @override
  String get transcribe => 'Транскрибировать';

  @override
  String get shareTranscript => 'Поделиться транскриптом';

  @override
  String get transcriptionContextLargeToast =>
      'Эти транскрипты могут не поместиться в контекст модели. Создайте ветку от более раннего сообщения, если ответы станут неполными.';

  @override
  String get transcriptionSubtitlesOn => 'Субтитры вкл.';

  @override
  String get transcriptionSubtitlesOff => 'Субтитры выкл.';

  @override
  String get transcriptionFullClip => 'Весь фрагмент';

  @override
  String get transcriptionJobRunning => 'Транскрибирование…';

  @override
  String get transcriptionJobDone => 'Транскрибировано';

  @override
  String get transcriptionJobFailed => 'Ошибка транскрипции';

  @override
  String get branchFromHere => 'Ветка отсюда';

  @override
  String get memoryUpdates => 'Обновления памяти';

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
  String get personaShareMemoryCategoriesLabel => 'Категории для обмена';

  @override
  String get personaShareMemoryCategoriesSubtitle =>
      'Выберите, какие типы воспоминаний эта персона может использовать в чатах.';

  @override
  String get chooseFaceForBubbles => 'Выбрать лицо для пузырей';

  @override
  String get moveMemories => 'Переместить воспоминания';

  @override
  String get deletePersonaAndMemories => 'Удалить персону и воспоминания';

  @override
  String get moveMemoriesTo => 'Переместить воспоминания в…';

  @override
  String get globalSharedMemories => 'Глобальные (общие для всех персон)';

  @override
  String personaMemoriesAssignedHint(int count, String name) {
    return '$count воспоминание(й) привязано к «$name».\nВыберите, что с ними сделать:';
  }

  @override
  String get homeSyncTitle => 'Синхронизировать чаты?';

  @override
  String homeSyncBodyBoth(int phoneChats, int macChats) {
    return 'На этом телефоне $phoneChats чатов, в LM Mini Home — $macChats. Включите синхронизацию, чтобы объединить переписки и папки и продолжать на любом устройстве. Используется уже существующий зашифрованный релей.';
  }

  @override
  String get homeSyncBodyPhoneOnly =>
      'Скопируйте чаты и папки с этого телефона в LM Mini Home и дальше держите их синхронными через зашифрованный релей.';

  @override
  String get homeSyncBodyMacOnly =>
      'Перенесите чаты и папки из LM Mini Home на этот телефон и дальше держите их синхронными через зашифрованный релей.';

  @override
  String get homeSyncBodyGeneric =>
      'Объедините переписки и папки между этим телефоном и LM Mini Home, чтобы продолжать на любом устройстве. Используется уже существующий зашифрованный релей.';

  @override
  String get homeSyncEnable => 'Включить синхронизацию';

  @override
  String get homeSyncNotNow => 'Не сейчас';

  @override
  String get homeSyncSettingsTitle => 'Синхронизация с Home';

  @override
  String get homeSyncSettingsSubtitle =>
      'Объединять переписки и папки через зашифрованный релей';

  @override
  String get homeSyncMergedToast => 'Чаты и папки теперь синхронизированы';

  @override
  String get homeSyncFailedToast =>
      'Не удалось синхронизировать. Откройте Share with phone на Mac и попробуйте снова.';

  @override
  String get homeSyncPersonasTitle => 'Синхронизация персон';

  @override
  String get homeSyncPersonasSubtitle =>
      'Копировать выбранных, включая фото и воспоминания';

  @override
  String get homeSyncPersonasPickTitle => 'Выберите персон';

  @override
  String get homeSyncPersonasPickSubtitle =>
      'Отмеченные персоны копируются между этим устройством и Home вместе с фото и воспоминаниями.';

  @override
  String get homeSyncPersonasSave => 'Сохранить и синхронизировать';

  @override
  String get homeSyncPersonasSavedToast => 'Персоны синхронизированы';

  @override
  String get homeSyncPersonasEmpty => 'Пока нет персон для копирования.';

  @override
  String get homeSyncPersonasUnreachable =>
      'Не удаётся связаться с Home. Откройте Share with phone на Mac и попробуйте снова.';

  @override
  String get homeSyncPersonasOnBoth => 'На обоих устройствах';

  @override
  String get homeSyncPersonasOnHome => 'LM Mini Home';

  @override
  String get homeSyncPersonasOnPhone => 'ваш телефон';

  @override
  String get homeSyncPersonasThisPhone => 'этот телефон';

  @override
  String homeSyncPersonasOnDevice(String device) {
    return 'На $device';
  }

  @override
  String homeSyncPersonasMemoryCount(int count) {
    return '$count воспоминаний';
  }

  @override
  String get homeSyncPersonasNoMemories => 'Пока нет воспоминаний';

  @override
  String get reportToSupport => 'Отправить в поддержку';

  @override
  String get localhostConnectionHelp =>
      'Не удаётся подключиться к localhost. На телефоне localhost — это само устройство, а не компьютер. В настройках укажите IP компьютера (например http://192.168.1.10:1234) и будьте в одной Wi‑Fi сети.';

  @override
  String get lmStudioPcNotAllowingTitle => 'Компьютер не принимает подключение';

  @override
  String get lmStudioPcNotAllowingBody =>
      'В LM Studio на компьютере откройте Developer → Server Settings и включите Serve on Local Network.';

  @override
  String get lmStudioHostDownTitle => 'Компьютер недоступен';

  @override
  String get lmStudioHostDownStep1 =>
      'Убедитесь, что компьютер включён — не в сне и не выключен.';

  @override
  String get lmStudioHostDownStep2 =>
      'В LM Studio откройте Developer → Server Settings и включите Serve on Local Network.';

  @override
  String get cantReachMacTitle => 'Mac недоступен';

  @override
  String get cantReachMacStep1 =>
      'Откройте Share with phone в LM Mini Home на Mac.';

  @override
  String get cantReachMacStep2 =>
      'Дождитесь статуса Connected и попробуйте снова.';

  @override
  String get lmStudioServerSettingsImageLabel =>
      'LM Studio Developer → Server Settings. Serve on Local Network должен быть включён.';

  @override
  String get modelMissingTitle => 'Этой модели нет на компьютере';

  @override
  String get modelMissingBody =>
      'Выбранная модель недоступна. Выберите другую в выборе моделей.';

  @override
  String modelMissingBodyNamed(String model) {
    return '«$model» нет на компьютере. Выберите другую в выборе моделей.';
  }

  @override
  String get outputTokensExhaustedTitle => 'У модели закончились токены ответа';

  @override
  String get outputTokensExhaustedBody =>
      'Инструменты отработали, но на ответ не хватило токенов. Увеличьте лимит и попробуйте снова.';

  @override
  String get thinkingBudgetRetryTitle => 'Thinking used the output limit';

  @override
  String get thinkingBudgetRetryBody =>
      'High thinking filled the output limit, so this reply uses low thinking. Raise max tokens to keep high thinking.';

  @override
  String get adjustMaxTokens => 'Настроить макс. токены';

  @override
  String get ggmlSchedulerCrashBody =>
      'Сервер модели аварийно остановился (планировщик llama.cpp). Это не Mini. Уменьшите длину контекста и макс. число токенов — очень большие значения (например, контекст 128k) часто вызывают это.';

  @override
  String get generationTerminatedBody =>
      'LM Studio остановил генерацию на вашем компьютере (процесс был завершён).';

  @override
  String generationTerminatedHugeImageBody(String size) {
    return 'LM Studio остановил генерацию на вашем компьютере. Прикреплённое изображение, скорее всего, слишком большое ($size) — сожмите его и отправьте снова.';
  }

  @override
  String get compressAndResendImages => 'Сжать изображение и отправить снова';

  @override
  String get imageCompressFailed =>
      'Не удалось уменьшить прикреплённое изображение. Попробуйте фото поменьше.';

  @override
  String get droppedChatBodyHelp =>
      'Mini отправил этот чат, но он не дошёл до LM Studio. Если перед LM Studio стоит прокси, туннель или другой URL — попробуйте без него или подключите Mini напрямую (IP компьютера, USB или Connect).';

  @override
  String get comfyUiNoCheckpointsTitle => 'В ComfyUI нет модели изображения';

  @override
  String get comfyUiNoCheckpointsBody =>
      'В ComfyUI нет чекпоинта. Положите файл .safetensors в папку models/checkpoints ComfyUI и выберите его в «Генерация изображений».';

  @override
  String get comfyUiNoCheckpointSelectedBody =>
      'Модель изображения не выбрана. Откройте «Генерация изображений» и выберите чекпоинт.';

  @override
  String comfyUiUnknownCheckpointBody(String name) {
    return 'В ComfyUI нет чекпоинта «$name». Выберите другой в «Генерация изображений».';
  }

  @override
  String get comfyUiWorkflowRejectedBody =>
      'ComfyUI отклонил рабочий процесс. Проверьте «Генерация изображений».';

  @override
  String get comfyUiDiffusionOnlyTitle =>
      'Этому графу нужен ваш workflow ComfyUI';

  @override
  String get comfyUiDiffusionOnlyBody =>
      'Встроенный workflow Mini загружает классический SD-чекпоинт. Граф Comfy Desktop использует diffusion/UNET плюс CLIP и VAE. Экспортируйте его в API Format (Workflow → Export) и выберите файл в «Генерация изображений».';

  @override
  String get openImageSettings => 'Настройки изображений';

  @override
  String imageGenUnreachableTitle(String name) {
    return 'Не удаётся достучаться до $name';
  }

  @override
  String imageGenUnreachableBody(String name, String url) {
    return 'По адресу $url никто не отвечает. Запустите $name на компьютере и оставайтесь в той же Wi‑Fi сети.';
  }

  @override
  String get imageGenUnreachableNoUrlBody =>
      'Сервер генерации изображений не задан. Добавьте ComfyUI или AUTOMATIC1111 в настройках изображений.';

  @override
  String get sharedHostUpdateImageTitle =>
      'Обновить адрес генерации изображений тоже?';

  @override
  String sharedHostUpdateChatTitle(String name) {
    return 'Обновить $name тоже?';
  }

  @override
  String sharedHostUpdateBody(
      String changedName, String peerName, String oldHost, String newUrl) {
    return '$changedName и $peerName оба были на $oldHost. Сменить $peerName на $newUrl?';
  }

  @override
  String get sharedHostUpdateConfirm => 'Обновить и проверить';

  @override
  String get sharedHostUpdateSkip => 'Оставить как есть';

  @override
  String sharedHostTesting(String name) {
    return 'Проверка $name…';
  }

  @override
  String get sharedHostTestSuccessTitle => 'Подключено';

  @override
  String sharedHostTestSuccessBody(String name, String url) {
    return '$name доступен по $url.';
  }

  @override
  String get sharedHostTestFailTitle => 'Нет соединения';

  @override
  String sharedHostTestFailBody(String name, String url, String error) {
    return '$name обновлён на $url, но Mini не смог подключиться. $error';
  }

  @override
  String get supportTicketTitle => 'Сообщить о проблеме';

  @override
  String get supportTicketPrefillDescription =>
      'К отчёту прикреплён файл журнала с деталями ошибки. Добавьте всё, что может помочь:';

  @override
  String get supportTicketSubmitted => 'Спасибо — отчёт отправлен.';

  @override
  String get supportTicketAlreadyOpen =>
      'У вас уже есть открытый отчёт об этой ошибке.';

  @override
  String get supportTicketViewExisting => 'Открыть отчёт';

  @override
  String get supportTicketAlreadySending => 'Этот отчёт уже отправляется.';

  @override
  String get supportUnavailable =>
      'Поддержка сейчас недоступна. Попробуйте позже, когда будете в сети.';

  @override
  String get somethingWentWrong => 'Что-то пошло не так';

  @override
  String get uncaughtErrorSnack => 'Что-то пошло не так.';

  @override
  String get errorLogLabel => 'LOG';

  @override
  String get appLock => 'Блокировка';

  @override
  String get appLockSubtitleOff => 'Запрашивать PIN после закрытия приложения';

  @override
  String appLockSubtitleOn(String duration) {
    return 'Снова спросит через $duration';
  }

  @override
  String get appLockUnlockTitle => 'LM Mini заблокирован';

  @override
  String get appLockDescription =>
      'Защитите чаты на этом устройстве числовым PIN и при желании Face ID. Код хранится только здесь и не синхронизируется.';

  @override
  String get appLockEnable => 'Блокировать PIN-кодом';

  @override
  String get appLockEnableSubtitle => 'Спрашивать PIN при возврате';

  @override
  String get appLockPinLength4 => '4 цифры';

  @override
  String get appLockPinLength6 => '6 цифр';

  @override
  String get appLockRequireAfter => 'Спрашивать снова через';

  @override
  String get appLockTimeoutImmediate => 'Сразу';

  @override
  String get appLockTimeout15s => '15 секунд';

  @override
  String get appLockTimeout1m => '1 минута';

  @override
  String get appLockTimeout5m => '5 минут';

  @override
  String get appLockTimeout15m => '15 минут';

  @override
  String get appLockTimeout1h => '1 час';

  @override
  String get appLockChangePin => 'Сменить PIN';

  @override
  String get appLockEnterCurrentPin => 'Введите текущий PIN';

  @override
  String get appLockChooseNewPin => 'Придумайте PIN';

  @override
  String get appLockConfirmPin => 'Подтвердите PIN';

  @override
  String get appLockPinsDontMatch => 'PIN не совпадают. Попробуйте снова.';

  @override
  String get appLockWrongPin => 'Неверный PIN. Попробуйте снова.';

  @override
  String appLockTooManyAttempts(int seconds) {
    return 'Слишком много попыток. Повторите через $seconds с.';
  }

  @override
  String get appLockForgotHint =>
      'Если вы забудете PIN, его можно сбросить через письмо с подтверждением на привязанный аккаунт. Войдите в аккаунт до того, как потеряете PIN, иначе восстановить его будет нельзя.';

  @override
  String get appLockProRequired => 'Блокировка — функция Pro';

  @override
  String get appLockEnabledToast => 'Блокировка включена';

  @override
  String get appLockDisabledToast => 'Блокировка выключена';

  @override
  String get appLockChangedToast => 'PIN обновлён';

  @override
  String appLockBiometricsToggle(String method) {
    return 'Разблокировать через $method';
  }

  @override
  String get appLockBiometricsSubtitle =>
      'Face ID, Touch ID или отпечаток вместо PIN.';

  @override
  String get appLockBiometricFaceId => 'Face ID';

  @override
  String get appLockBiometricFace => 'Разблокировка по лицу';

  @override
  String get appLockBiometricTouchId => 'Touch ID';

  @override
  String get appLockBiometricFingerprint => 'Отпечаток';

  @override
  String get appLockBiometricGeneric => 'биометрия';

  @override
  String appLockUnlockWithBiometrics(String method) {
    return 'Разблокировать через $method';
  }

  @override
  String appLockBiometricsFailed(String method) {
    return 'Не удалось разблокировать через $method. Введите PIN.';
  }

  @override
  String get appLockSignInToRecover =>
      'Войдите в аккаунт, иначе вы не сможете восстановить блокировку, если этот PIN будет утерян.';

  @override
  String appLockSignInToRecoverBound(String email) {
    return 'Войдите как $email, иначе вы не сможете восстановить блокировку, если этот PIN будет утерян.';
  }

  @override
  String get appLockNotSignedInNoRecovery =>
      'Вы не вошли в аккаунт. Этот PIN нельзя будет восстановить, если он будет утерян.';

  @override
  String get appLockForgotPin => 'Забыли PIN?';

  @override
  String get appLockSendRecoveryEmail => 'Отправить ссылку для подтверждения';

  @override
  String appLockRecoveryEmailSent(String email) {
    return 'Мы отправили письмо с подтверждением на $email. Откройте его и вернитесь сюда.';
  }

  @override
  String get appLockRecoveryIVerified => 'Я подтвердил — продолжить';

  @override
  String get appLockRecoveryResend => 'Отправить письмо снова';

  @override
  String get appLockRecoveryReauth => 'Войдите снова, чтобы сбросить PIN';

  @override
  String appLockRecoveryWrongAccount(String email) {
    return 'Этот PIN привязан к $email. Войдите в этот аккаунт, чтобы восстановить его.';
  }

  @override
  String get appLockRecoveryUnavailable =>
      'Восстановление PIN не настроено. Нужен этот PIN или переустановка LM Mini.';

  @override
  String get appLockRecoveryFailed =>
      'Не удалось подтвердить аккаунт. Попробуйте снова.';

  @override
  String get appLockRecoveryNoEmail =>
      'У этого аккаунта нет почты для ссылки подтверждения.';

  @override
  String get appLockRecoveryTooMany =>
      'Слишком много писем. Подождите минуту и попробуйте снова.';

  @override
  String get appLockRecoverySetPin => 'Выберите новый PIN';

  @override
  String get appLockContinueWithEmail => 'Продолжить с почтой';

  @override
  String appLockSignedInRecoverHint(String email) {
    return 'Если вы забудете этот PIN, мы можем отправить ссылку подтверждения на $email.';
  }

  @override
  String get appLockRecoveryAccount => 'Восстановление PIN';

  @override
  String appLockRecoveryAccountOn(String email) {
    return 'Письма с подтверждением приходят на $email';
  }

  @override
  String get appLockRecoveryAccountOff =>
      'Войдите, чтобы можно было восстановить забытый PIN';

  @override
  String get appLockRecoveryAccountOffSubtitle =>
      'Без аккаунта потерянный PIN можно сбросить только переустановкой приложения.';

  @override
  String get appLockBackToPin => 'Ввести PIN';

  @override
  String get premiumAppLock => 'Блокировка';

  @override
  String get premiumAppLockTagline => 'Защита приложения PIN-кодом';

  @override
  String get premiumAppLockDescription =>
      'Задайте 4- или 6-значный PIN, разблокируйте через Face ID и восстановите забытый PIN письмом с подтверждением. PIN остаётся на этом устройстве.';

  @override
  String spritePanelShow(String name) {
    return 'Показать выражение $name';
  }

  @override
  String get personaExpressionsTitle => 'Выражения';

  @override
  String get personaExpressionsSubtitle =>
      'Изображения персонажа, которые меняются вместе с настроением ответа. Назовите файлы по выражению, например joy.png или anger.png, или импортируйте zip со спрайтами SillyTavern.';

  @override
  String get personaExpressionsImport => 'Импортировать спрайты';

  @override
  String get personaExpressionsRemoveAll => 'Удалить все';

  @override
  String personaExpressionsRemoveAllConfirm(String name) {
    return 'Удалить все спрайты выражений у $name?';
  }

  @override
  String get personaExpressionsReplace => 'Заменить изображение';

  @override
  String get personaExpressionsRemove => 'Удалить';

  @override
  String personaExpressionsImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Добавлено $count спрайтов',
      few: 'Добавлено $count спрайта',
      one: 'Добавлен $count спрайт',
      zero: 'Спрайты не добавлены',
    );
    return '$_temp0';
  }

  @override
  String personaExpressionsUnmatched(String files) {
    return 'Пропущено (не название выражения): $files';
  }

  @override
  String get personaExpressionsMissing => 'Нет';

  @override
  String get characterCardImport => 'Импортировать карточку персонажа';

  @override
  String characterCardImportedOne(String name) {
    return 'Импортирован персонаж $name';
  }

  @override
  String characterCardImportedMany(int count) {
    return 'Импортировано персонажей: $count';
  }

  @override
  String characterCardImportFailed(String file, String reason) {
    return 'Не удалось импортировать $file: $reason';
  }

  @override
  String characterCardLoreSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Не импортировано $count записей лорбука по ключевым словам',
      few: 'Не импортированы $count записи лорбука по ключевым словам',
      one: 'Не импортирована $count запись лорбука по ключевым словам',
    );
    return '$_temp0';
  }

  @override
  String get appearanceExpressionSprites => 'Выражения персонажа';

  @override
  String get appearanceExpressionSpritesSubtitle =>
      'Для персон со спрайтами выражений';

  @override
  String get expressionSpriteModeOff => 'Выкл.';

  @override
  String get expressionSpriteModePanel => 'Большой спрайт';

  @override
  String get expressionSpriteModeAvatar => 'Аватар сообщения';

  @override
  String get expressionSpriteModeBoth => 'Оба';

  @override
  String get spriteGenerateButton => 'Сгенерировать';

  @override
  String get spriteGenerateTitle => 'Сгенерировать выражения';

  @override
  String get spriteGenerateAppearance => 'Внешность';

  @override
  String get spriteGenerateAppearanceHint => 'Волосы, глаза, одежда и стиль';

  @override
  String get spriteGenerateSeed => 'Сид';

  @override
  String get spriteGenerateSeedHelp =>
      'Один и тот же сид сохраняет облик персонажа во всех выражениях.';

  @override
  String get spriteGenerateCore => '8 основных';

  @override
  String get spriteGenerateAll => 'Все 28';

  @override
  String get spriteGenerateOnlyMissing => 'Только недостающие';

  @override
  String spriteGenerateStart(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Сгенерировать $count изображений',
      few: 'Сгенерировать $count изображения',
      one: 'Сгенерировать $count изображение',
    );
    return '$_temp0';
  }

  @override
  String spriteGenerateProgress(int current, int total, String label) {
    return 'Генерация $current из $total: $label';
  }

  @override
  String get spriteGenerateNeedsImageGen =>
      'Сначала настройте генерацию изображений: Настройки → Генерация изображений.';

  @override
  String spriteGenerateDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Сгенерировано $count выражений',
      few: 'Сгенерировано $count выражения',
      one: 'Сгенерировано $count выражение',
    );
    return '$_temp0';
  }

  @override
  String spriteGenerateFailed(String label, String error) {
    return 'Остановлено на $label: $error';
  }

  @override
  String get personaGreetingLabel => 'Первое сообщение (необязательно)';

  @override
  String get personaGreetingHint => 'Что персонаж говорит в начале нового чата';
}
