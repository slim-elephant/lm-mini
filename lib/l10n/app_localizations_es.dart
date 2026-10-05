// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'LM Mini';

  @override
  String get splashTagline => 'chat de IA local';

  @override
  String get homeTitle => 'LM Mini';

  @override
  String get homeSearchHint => 'Buscar conversaciones...';

  @override
  String get allConversations => 'Todas las conversaciones';

  @override
  String get noFoldersTitle => 'Sin carpetas';

  @override
  String get noFoldersSubtitle => 'Crea carpetas para organizar tus chats';

  @override
  String get noConversationsTitle => 'Sin conversaciones';

  @override
  String get noConversationsSubtitle => 'Inicia un nuevo chat para comenzar';

  @override
  String get newChat => 'Nuevo chat';

  @override
  String conversationCount(int count) {
    return '$count conversación(es)';
  }

  @override
  String get noModelsAvailable =>
      'No hay modelos disponibles. Verifica tu conexión con LM Studio.';

  @override
  String get noVisionModelAvailable =>
      'No hay modelo de visión disponible. Carga un modelo de visión en LM Studio.';

  @override
  String get deleteConversationTitle => 'Eliminar Conversación';

  @override
  String get deleteConversationMessage =>
      '¿Estás seguro de que deseas eliminar esta conversación? Esta acción no se puede deshacer.';

  @override
  String get renameConversationTitle => 'Renombrar Conversación';

  @override
  String get conversationTitleLabel => 'Título de la Conversación';

  @override
  String get deleteFolderTitle => 'Eliminar Carpeta';

  @override
  String get deleteFolderMessage =>
      'Esto no eliminará las conversaciones de esta carpeta.';

  @override
  String get moveToFolderTitle => 'Mover a Carpeta';

  @override
  String get noFolder => 'Sin Carpeta';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get save => 'Guardar';

  @override
  String get close => 'Cerrar';

  @override
  String get ok => 'OK';

  @override
  String get add => 'Añadir';

  @override
  String get edit => 'Editar';

  @override
  String get reset => 'Restablecer';

  @override
  String get retry => 'Reintentar';

  @override
  String get search => 'Buscar';

  @override
  String get copy => 'Copiar';

  @override
  String get copied => '¡Copiado!';

  @override
  String get copiedToClipboard => 'Copiado al portapapeles';

  @override
  String get dismiss => 'Descartar';

  @override
  String get configure => 'Configurar';

  @override
  String get rename => 'Renombrar';

  @override
  String get duplicate => 'Duplicar';

  @override
  String get enabled => 'Activado';

  @override
  String get disabled => 'Desactivado';

  @override
  String get active => 'Activo';

  @override
  String get none => 'Ninguno';

  @override
  String get auto => 'Auto';

  @override
  String get custom => 'Personalizado';

  @override
  String get change => 'Cambiar';

  @override
  String get chatDefaultTitle => 'Chat';

  @override
  String get searchMessagesTooltip => 'Buscar mensajes';

  @override
  String get chatSettingsMenuItem => 'Configuración del Chat';

  @override
  String get appearanceMenuItem => 'Apariencia';

  @override
  String get exportAsPdf => 'Exportar como PDF';

  @override
  String get exportAsTxt => 'Exportar como TXT';

  @override
  String get exportAsMarkdown => 'Exportar como Markdown';

  @override
  String get exportAsJson => 'Exportar como JSON';

  @override
  String get exportAsObsidian => 'Exportar para Obsidian';

  @override
  String get copyToClipboard => 'Copiar al portapapeles';

  @override
  String get exportAndShare => 'Exportar y compartir';

  @override
  String get freeFormats => 'Estándar';

  @override
  String get premiumFormats => 'Formatos Pro';

  @override
  String get chatExported => 'Chat exportado';

  @override
  String get noModelSelectedTitle => 'Ningún Modelo Seleccionado';

  @override
  String get noModelSelectedSubtitle =>
      'Selecciona un modelo en ajustes para empezar a chatear';

  @override
  String get openSettings => 'Abrir Ajustes';

  @override
  String connectionError(String error) {
    return 'Error de Conexión: $error';
  }

  @override
  String get startConversation => 'Inicia una conversación';

  @override
  String get typeMessageToBegin => 'Escribe un mensaje para comenzar';

  @override
  String get searchMessagesTitle => 'Buscar Mensajes';

  @override
  String get searchQueryHint => 'Ingresa tu búsqueda...';

  @override
  String get semanticSearchInfo =>
      'La búsqueda semántica usa IA para encontrar mensajes relevantes basándose en el significado, no solo en palabras clave.';

  @override
  String get noMessagesToSearch => 'No hay mensajes para buscar';

  @override
  String get searchResults => 'Resultados de Búsqueda';

  @override
  String searchResultsFor(int count, String query) {
    return '$count coincidencia(s) para \"$query\"';
  }

  @override
  String get noMessagesFound => 'No se encontraron mensajes';

  @override
  String get tryDifferentSearch => 'Intenta con otra búsqueda';

  @override
  String get chatCustomizationSaved => 'Personalización del chat guardada';

  @override
  String get noMessagesToExport => 'No hay mensajes para exportar';

  @override
  String get exportingChat => 'Exportando chat...';

  @override
  String get chatExportedAsPdf => 'Chat exportado como PDF';

  @override
  String get chatExportedAsTxt => 'Chat exportado como TXT';

  @override
  String exportFailed(String error) {
    return 'Error al exportar: $error';
  }

  @override
  String get chatSettingsUpdated =>
      'Ajustes del chat actualizados (anulando ajustes globales)';

  @override
  String get chatSettingsReset =>
      'Ajustes del chat restablecidos a valores globales';

  @override
  String get you => 'Tú';

  @override
  String get assistant => 'Asistente';

  @override
  String get yesterday => 'Ayer';

  @override
  String get showDetails => 'Mostrar detalles';

  @override
  String get hideDetails => 'Ocultar detalles';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsAdvancedMode => 'Avanzado';

  @override
  String get settingsAdvancedModeTooltip =>
      'Mostrar opciones técnicas para usuarios avanzados';

  @override
  String get serverSection => 'SERVIDOR';

  @override
  String get serverUrlLabel => 'URL del Servidor';

  @override
  String get serverUrlHint => 'http://localhost:1234';

  @override
  String get testConnectionRequired => 'Probar Conexión (Requerido)';

  @override
  String get testConnection => 'Probar conexión';

  @override
  String get modelsSection => 'MODELOS';

  @override
  String get modelSelection => 'Selección de Modelo';

  @override
  String get noModelSelected => 'Ningún modelo seleccionado';

  @override
  String get modelParameters => 'Parámetros del Modelo';

  @override
  String get modelParametersSubtitle => 'Temperatura, tokens, penalizaciones';

  @override
  String get modelParametersHelpTooltip => 'Qué significan estos ajustes';

  @override
  String get modelParametersHelpTitle => 'Guía rápida';

  @override
  String get modelParametersHelpIntro =>
      'Consejos sencillos para cada ajuste. Si no estás seguro, deja los valores por defecto; siempre puedes cambiarlos después. Algunas opciones solo aparecen con tu proveedor de IA actual.';

  @override
  String get topKHelp =>
      'Cuántas opciones de palabras considera la IA. Más bajo = más seguro y predecible; 0 = sin límite.';

  @override
  String get reasoningHelp =>
      'Activa o desactiva el modo thinking en modelos de razonamiento. Apagado = respuestas más rápidas sin traza de pensamiento; Activado (o un nivel) pide al modelo pensar paso a paso. No todos los modelos de razonamiento permiten desactivarlo.';

  @override
  String get reasoningHelpShort =>
      'Activa o desactiva thinking. No todos admiten Apagado.';

  @override
  String get systemPrompts => 'Personas e Indicaciones del Sistema';

  @override
  String get defaultPrompt => 'Prompt Predeterminado';

  @override
  String get appearanceSection => 'APARIENCIA';

  @override
  String get appearance => 'Apariencia';

  @override
  String get appearanceSubtitle => 'Tema, fondos, avatares';

  @override
  String get supportSection => 'SOPORTE';

  @override
  String get rateApp => 'Valorar LM Mini';

  @override
  String get rateAppSubtitle =>
      '¿Te gusta la app? Deja una reseña en el App Store ⭐';

  @override
  String get hfBrowseTitle => 'Descargar desde Hugging Face';

  @override
  String get hfBrowseSubtitle =>
      'Explora modelos GGUF — no se necesita clave API';

  @override
  String get hfBrowseTab => 'Explorar';

  @override
  String get hfPasteTab => 'Pegar enlace';

  @override
  String get hfSearchHint => 'Buscar modelos GGUF…';

  @override
  String get hfLoadingModels => 'Buscando en Hugging Face…';

  @override
  String get hfNoModelsFound => 'No se encontraron modelos';

  @override
  String get hfNoModelsHint =>
      'Prueba otro término de búsqueda o desactiva el filtro de LM Studio.';

  @override
  String get hfLmStudioFilter => 'Compatible con LM Studio';

  @override
  String get hfLmStudioFilterHint =>
      'Solo modelos que Hugging Face indica como compatibles con LM Studio';

  @override
  String get hfChatModelsFilter => 'Modelos de chat';

  @override
  String get hfChatBadge => 'Chat';

  @override
  String get hfLmStudioBadge => 'LM Studio';

  @override
  String get hfPasteUrlHint => 'https://huggingface.co/owner/repo';

  @override
  String get hfModelInfo => 'Información del modelo';

  @override
  String hfDownloadsCount(String count) {
    return '$count descargas';
  }

  @override
  String hfLikesCount(String count) {
    return '$count me gusta';
  }

  @override
  String hfPipelineTag(String tag) {
    return 'Tarea: $tag';
  }

  @override
  String hfBaseModel(String model) {
    return 'Modelo base: $model';
  }

  @override
  String hfLicense(String license) {
    return 'Licencia: $license';
  }

  @override
  String get hfTagsSection => 'Etiquetas';

  @override
  String get hfQuantPickerHint =>
      'Cuantización más baja = archivo más pequeño. Q4_K_M es un buen equilibrio para la mayoría de dispositivos.';

  @override
  String get hfBackToModels => 'Volver a modelos';

  @override
  String hfGgufFilesCount(int count) {
    return '$count archivo(s) GGUF disponible(s)';
  }

  @override
  String get hfDownloadInBackground =>
      'Descarga iniciada — sigue el progreso con el botón flotante. Puedes seguir explorando o cerrar este panel.';

  @override
  String get hfQuantPickerHintLmStudio =>
      'Cuantizaciones listadas por tu servidor LM Studio. Elige una para descargarla al servidor.';

  @override
  String get hfDownloadDefaultQuant => 'Descargar';

  @override
  String hfDownloadFailed(String error) {
    return 'No se pudo iniciar la descarga: $error';
  }

  @override
  String get hfPasteInstructions =>
      'Pega una URL de repositorio de Hugging Face o escribe owner/repo. Luego elegirás una cuantización.';

  @override
  String get hfPasteInstructionsLmStudio =>
      'Pega una URL de Hugging Face, owner/repo o un ID de modelo de LM Studio.';

  @override
  String get hfPasteLabel => 'Repositorio';

  @override
  String get hfInvalidRepo =>
      'Introduce una URL de Hugging Face válida o owner/repo.';

  @override
  String get hfRecommended => 'Recomendado';

  @override
  String get reviewPromptTitle => '¿Te gusta LM Mini?';

  @override
  String get reviewPromptMessage =>
      '¡Has tenido unos chats geniales! ¿Te importaría dejarnos una valoración rápida en Play Store?';

  @override
  String get reviewPromptRate => 'Valorar ahora';

  @override
  String get reviewPromptLater => 'Quizá más tarde';

  @override
  String get buyMeACoffee => 'Invítame un Café';

  @override
  String get buyMeACoffeeSubtitle => '¡Ayuda a mantener la IA con cafeína! 🤖';

  @override
  String get featureRequests => 'Solicitudes de Funciones';

  @override
  String get featureRequestsSubtitle => 'Vota por funciones o envía tus ideas';

  @override
  String get dataSection => 'DATOS';

  @override
  String get exportAllChats => 'Exportar Todos los Chats';

  @override
  String get exportAllChatsSubtitle =>
      'Descarga todas las conversaciones como archivo ZIP';

  @override
  String get importChats => 'Importar Chats';

  @override
  String get importChatsSubtitle =>
      'Importar exportaciones de chat de LM Studio (.md o .zip)';

  @override
  String importSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chats importados con éxito',
      one: '1 chat importado con éxito',
    );
    return '$_temp0';
  }

  @override
  String get importFailed => 'Error al importar';

  @override
  String importPartial(int imported, int skipped) {
    return '$imported importado(s), $skipped omitido(s)';
  }

  @override
  String get importing => 'Importando...';

  @override
  String get advancedSection => 'FUNCIONES AVANZADAS';

  @override
  String get showRuntimeInfo => 'Mostrar Info de Ejecución';

  @override
  String get showRuntimeInfoSubtitle =>
      'Mostrar arquitectura del modelo y tiempo de ejecución';

  @override
  String get embeddingModel => 'Modelo de Embeddings';

  @override
  String get enableSemanticSearch => 'Habilitar Búsqueda Semántica';

  @override
  String get enableSemanticSearchSubtitle =>
      'Buscar mensajes relevantes usando embeddings';

  @override
  String get toolCalling => 'Llamada de Herramientas';

  @override
  String get toolCallingEnabled => 'Llamada de herramientas activada';

  @override
  String get toolCallingDisabled => 'Llamada de herramientas desactivada';

  @override
  String get legalSection => 'LEGAL';

  @override
  String get privacyPolicy => 'Política de Privacidad';

  @override
  String get privacyPolicySubtitle => 'Los chats se quedan en tus dispositivos';

  @override
  String get termsOfService => 'Términos de Servicio';

  @override
  String get termsOfServiceSubtitle => 'Términos y condiciones';

  @override
  String get appName => 'LM Mini';

  @override
  String get appTagline => 'Una app complementaria para LM Studio';

  @override
  String get couldNotOpenLink => 'No se pudo abrir el enlace';

  @override
  String get apiToken => 'Token de API y USB';

  @override
  String get tokenConfigured => 'Token configurado';

  @override
  String get optionalAuthentication => 'Autenticación opcional';

  @override
  String get apiTokenLabel => 'Token de API';

  @override
  String get apiTokenHint => 'Ingresa tu token de API de LM Studio';

  @override
  String get apiTokenHelp =>
      'Si tu servidor LM Studio requiere autenticación, ingresa tu token de API aquí. Es opcional y solo necesario si has habilitado la autenticación en los ajustes de LM Studio.';

  @override
  String get apiTokenInfo =>
      'LM Studio 0.4.0+ soporta autenticación por API. Habilítalo en LM Studio > Ajustes > Seguridad.';

  @override
  String get actionRequired => '- Acción Requerida';

  @override
  String get idleTtl => 'TTL Inactivo';

  @override
  String get idleTtlDefault =>
      'Usando valor predeterminado de LM Studio (60 min)';

  @override
  String idleTtlMinutes(int value) {
    return 'Descarga automática tras $value minutos inactivo';
  }

  @override
  String idleTtlHoursMinutes(int hours, int mins) {
    return 'Descarga automática tras $hours hr $mins min inactivo';
  }

  @override
  String get lmStudioDefault => 'Predeterminado de LM Studio';

  @override
  String get fiveMinutes => '5 minutos';

  @override
  String get fifteenMinutes => '15 minutos';

  @override
  String get thirtyMinutes => '30 minutos';

  @override
  String get oneHour => '1 hora';

  @override
  String get twoHours => '2 horas';

  @override
  String connectionSuccess(int count) {
    return '¡Conectado! $count modelos cargados';
  }

  @override
  String get connectionFailed => 'Conexión fallida';

  @override
  String get troubleshootingSteps => 'Pasos de Solución:';

  @override
  String get troubleshootStep1 =>
      'Asegúrate de que LM Studio esté ejecutándose';

  @override
  String get troubleshootStep2 =>
      'En LM Studio, abre la pestaña Desarrollador (ícono ⚙️)';

  @override
  String get troubleshootStep3 => 'Habilita el toggle \"Servir en Red Local\"';

  @override
  String get troubleshootStep4 =>
      'Verifica que el Puerto del Servidor coincida (predeterminado: 1234)';

  @override
  String troubleshootStep5(String ip) {
    return 'Usa http://localhost:1234 para conexiones locales';
  }

  @override
  String get lmStudioSettings => 'Configuración de LM Studio';

  @override
  String get serveOnLocalNetworkHelp =>
      'El toggle \"Servir en Red Local\" debe estar habilitado (mostrado en naranja/verde) en la pestaña Desarrollador de LM Studio.';

  @override
  String get networkConnections => 'Conexiones de Red:';

  @override
  String get networkConnectionsTips =>
      '• Reemplaza \"localhost\" con la dirección IP de tu computadora\n• Asegúrate de que ambos dispositivos estén en la misma red\n• Verifica la configuración del firewall para el puerto 1234';

  @override
  String get noConversationsToExport => 'No hay conversaciones para exportar';

  @override
  String exportingConversations(int count) {
    return 'Exportando $count conversación(es)...';
  }

  @override
  String exportSuccess(int count) {
    return '$count conversación(es) exportada(s) exitosamente';
  }

  @override
  String get languageSection => 'IDIOMA';

  @override
  String get language => 'Idioma';

  @override
  String get languageSubtitle => 'Elige tu idioma preferido';

  @override
  String get systemDefault => 'Predeterminado del Sistema';

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
  String get toolsCallingTitle => 'Llamada de Herramientas';

  @override
  String get toolCallingSection => 'LLAMADA DE HERRAMIENTAS';

  @override
  String get enableToolCallingAndMcps => 'Habilitar Herramientas y MCPs';

  @override
  String get enableToolCallingSubtitle =>
      'Permitir que la IA busque en la web y llame a MCPs';

  @override
  String get builtInToolsSection => 'HERRAMIENTAS INTEGRADAS';

  @override
  String get builtInToolsInfo =>
      'Herramientas ejecutadas localmente por la app cuando la IA las solicita';

  @override
  String get webSearch => 'Búsqueda Web';

  @override
  String get webSearchUsingSearxng => 'Usando SearXNG';

  @override
  String get webSearchDisabled =>
      'Desactivado (configura SearXNG o actualiza a Pro)';

  @override
  String get integratedMcpsSection => 'MCPs INTEGRADOS';

  @override
  String get integratedMcpsInfo =>
      'Usa los MCPs que ya configuraste en LM Studio. Solo añade aquí sus nombres desde tu mcp.json.';

  @override
  String get integratedMcpsAuthRequired =>
      'Los MCPs integrados requieren Autenticación habilitada en LM Studio y un token de API configurado en Ajustes → Token de API.';

  @override
  String get requiresApiToken => 'Requiere token de API';

  @override
  String get setApiTokenTooltip =>
      'Configura un token de API en Ajustes para habilitar';

  @override
  String get noIntegratedMcps => 'No hay MCPs integrados configurados';

  @override
  String get addManually => 'Añadir Manualmente';

  @override
  String get importMcpJson => 'Importar mcp.json';

  @override
  String get ephemeralMcpsSection => 'MCPs EFÍMEROS';

  @override
  String get ephemeralMcpsInfo =>
      'Servidores MCP HTTP enviados por solicitud. Requiere \"Permitir MCPs por solicitud\" en LM Studio.';

  @override
  String get requiresPerRequestMcps =>
      'Requiere: Desarrollador → Configuración del Servidor → Permitir MCPs por solicitud';

  @override
  String get noEphemeralMcps => 'No hay MCPs efímeros configurados';

  @override
  String get addHttpMcpServer => 'Añadir Servidor MCP HTTP';

  @override
  String get browseExampleMcps => 'Ver Servidores MCP de Ejemplo';

  @override
  String get addIntegratedMcpTitle => 'Añadir MCP';

  @override
  String get editIntegratedMcpTitle => 'Editar MCP';

  @override
  String get addIntegratedMcpInfo =>
      'Copia el nombre de mcp.json de LM Studio y pégalo aquí. Si ves una clave llamada playwright, escribe playwright.';

  @override
  String get mcpNameLabel => 'Nombre de mcp.json';

  @override
  String get mcpNameHint => 'playwright';

  @override
  String get mcpNameHelper =>
      'Solo letras, números y guiones — usa web-search, no web_search.';

  @override
  String get exampleMcpJsonEntry => '💡 Ejemplo de entrada mcp.json:';

  @override
  String get nameIsRequired => 'El nombre es obligatorio';

  @override
  String get mcpNameInvalidChars =>
      'Usa guiones en lugar de guiones bajos (LM Studio no acepta nombres como web_search).';

  @override
  String get mcpNameAlreadyExists => 'Ese MCP ya está añadido';

  @override
  String addedMcp(String name) {
    return 'Añadido $name';
  }

  @override
  String updatedMcp(String name) {
    return 'Actualizado $name';
  }

  @override
  String get editMcpTooltip => 'Editar nombre';

  @override
  String get unlimitedToolCalls => 'Llamadas de herramientas ilimitadas';

  @override
  String get unlimitedToolCallsSubtitle =>
      'Eliminar el límite de 10 llamadas para MCP integrados y efímeros (no afecta a Pro Search)';

  @override
  String get unlimitedToolCallsOn =>
      'Sin límite en las iteraciones de llamadas de herramientas MCP';

  @override
  String get unlimitedToolCallsOff =>
      'Limitado a 10 iteraciones de llamadas de herramientas';

  @override
  String get structuredOutput => 'Salida Estructurada';

  @override
  String get structuredOutputSubtitle => 'Forzar formato de respuesta JSON';

  @override
  String get reasoningMode => 'Modo de Razonamiento';

  @override
  String get reasoningOff => 'Apagado';

  @override
  String get reasoningLow => 'Bajo';

  @override
  String get reasoningMedium => 'Medio';

  @override
  String get reasoningHigh => 'Alto';

  @override
  String get reasoningOn => 'Activado';

  @override
  String get reasoningDescOff => 'Sin trazas de razonamiento';

  @override
  String get reasoningDescLow => 'Razonamiento mínimo';

  @override
  String get reasoningDescMedium => 'Razonamiento equilibrado';

  @override
  String get reasoningDescHigh => 'Razonamiento detallado';

  @override
  String get reasoningDescOn => 'Trazas de razonamiento completas';

  @override
  String get helpSection => 'AYUDA';

  @override
  String get toolCallingGuide => 'Guía de Herramientas';

  @override
  String get toolCallingGuideSubtitle =>
      'Aprende cómo funcionan las herramientas';

  @override
  String get searxngSetupGuide => 'Guía de Configuración de SearXNG';

  @override
  String get searxngSetupGuideSubtitle =>
      'Configura tu propio servidor de búsqueda';

  @override
  String get webSearchConfig => 'Configuración de Búsqueda Web';

  @override
  String get howWebSearchWorks => '💡 Cómo Funciona la Búsqueda Web';

  @override
  String get howWebSearchWorksSteps =>
      '1. La IA decide que necesita información actual\n2. La app busca usando Búsqueda Premium o SearXNG\n3. Los resultados se envían a la IA\n4. La IA sintetiza una respuesta';

  @override
  String get searchResultsLabel => 'Resultados de Búsqueda: ';

  @override
  String get webSearchDisabledWarning =>
      'Búsqueda web desactivada. Configura SearXNG o actualiza a Pro.';

  @override
  String get searxngUrlOptional => 'URL de SearXNG (Opcional)';

  @override
  String get searxngUrlLabel => 'URL de SearXNG';

  @override
  String get searxngUrlHint => 'http://localhost:8888';

  @override
  String get quickSetupDocker => '🐳 Configuración Rápida con Docker:';

  @override
  String get dockerCommand => 'docker run -d -p 8888:8080 searxng/searxng';

  @override
  String get mcpBadge => 'MCP';

  @override
  String get mcpResultBadge => 'Resultado MCP';

  @override
  String get webSearchSourcesTitle => 'Fuentes';

  @override
  String get toolBadge => 'Herramienta';

  @override
  String get resultBadge => 'Resultado';

  @override
  String get failedToLoadImage => 'Error al cargar imagen';

  @override
  String get thinking => 'Pensando';

  @override
  String get think => 'Pensar';

  @override
  String thoughtFor(String duration) {
    return 'Pensó durante $duration';
  }

  @override
  String get performanceStats => 'Estadísticas de Rendimiento';

  @override
  String get regenerate => 'Regenerar';

  @override
  String get editMessage => 'Editar Mensaje';

  @override
  String get editMessageHint => 'Edita tu mensaje...';

  @override
  String get saveAndRegenerate => 'Guardar y Regenerar';

  @override
  String get deleteMessage => 'Eliminar Mensaje';

  @override
  String get deleteMessageConfirm =>
      '¿Estás seguro de que deseas eliminar este mensaje?';

  @override
  String get mcpCallTitle => 'Llamada MCP';

  @override
  String get mcpResultTitle => 'Resultado MCP';

  @override
  String get toolCallTitle => 'Llamada de Herramienta';

  @override
  String get toolResultTitle => 'Resultado de Herramienta';

  @override
  String get attachFile => 'Adjuntar Archivo';

  @override
  String get photoLibrary => 'Biblioteca de Fotos';

  @override
  String get attachImagesForVision =>
      'Adjuntar imágenes para análisis de visión';

  @override
  String get requiresVisionModel =>
      'Requiere un modelo con capacidad de visión';

  @override
  String get takePhoto => 'Tomar Foto';

  @override
  String get captureImageWithCamera => 'Capturar imagen con la cámara';

  @override
  String get imageFromFiles => 'Imagen desde Archivos';

  @override
  String get pickImageFromFilesApp => 'Elegir una imagen desde la app Archivos';

  @override
  String get attachDocuments => 'Documentos';

  @override
  String get attachDocumentsSubtitle =>
      'PDF, Markdown, Excel (.xlsx), CSV, texto, código y más';

  @override
  String get textFileTxt => 'Archivo de Texto (.txt)';

  @override
  String get attachPlainText => 'Adjuntar documentos de texto plano';

  @override
  String get csvFileCsv => 'Archivo CSV (.csv)';

  @override
  String get attachSpreadsheetData => 'Adjuntar datos de hoja de cálculo';

  @override
  String get pdfDocumentPdf => 'Documento PDF (.pdf)';

  @override
  String get attachPdfDocuments => 'Adjuntar documentos PDF';

  @override
  String get mcpLabel => 'MCP:';

  @override
  String get typeMessageHint => 'Escribe un mensaje...';

  @override
  String get attachFilesTooltip => 'Adjuntar archivos';

  @override
  String get customizeChat => 'Personalizar Chat';

  @override
  String get overrideGlobalAppearance =>
      'Anular la apariencia global para este chat';

  @override
  String get background => 'Fondo';

  @override
  String get userAvatar => 'Avatar del Usuario';

  @override
  String get assistantAvatar => 'Avatar del Asistente';

  @override
  String get colorsSection => 'Colores';

  @override
  String get userBubble => 'Burbuja del Usuario';

  @override
  String get userText => 'Texto del Usuario';

  @override
  String get assistantBubble => 'Burbuja del Asistente';

  @override
  String get assistantText => 'Texto del Asistente';

  @override
  String get darkOverlay => 'Superposición Oscura';

  @override
  String get darkOverlayDescription =>
      'Ajusta la oscuridad de la superposición de la imagen de fondo';

  @override
  String get usingGlobal => 'Usando global';

  @override
  String get useGlobal => 'Usar Global';

  @override
  String get setCustom => 'Personalizar';

  @override
  String get customColor => 'Color personalizado';

  @override
  String get defaultThemeColor => 'Color del tema predeterminado';

  @override
  String get resetToDefault => 'Restablecer a predeterminado';

  @override
  String get pickAColor => 'Elige un color';

  @override
  String get chatSettingsTitle => 'Ajustes del Chat';

  @override
  String get overrideGlobalSettings =>
      'Anular ajustes globales solo para este chat';

  @override
  String get resetAll => 'Restablecer Todo';

  @override
  String get modelOverride => 'Modelo';

  @override
  String get noneSelected => 'Ninguno seleccionado';

  @override
  String get systemPromptOverride => 'Persona';

  @override
  String get saved => 'Guardados';

  @override
  String get noSavedPromptsInfo =>
      'Sin personas guardadas. Ve a Ajustes → Personas para crear algunas.';

  @override
  String get selectSavedPromptHint => 'Selecciona una persona...';

  @override
  String get enterCustomPromptHint =>
      'Ingresa un prompt de persona personalizado...';

  @override
  String get personaShareMemoriesLabel => 'Compartir memorias';

  @override
  String get personaShareMemoriesSubtitle =>
      'Si está desactivado, esta persona no recibirá ni aprenderá memorias en los chats';

  @override
  String get webSearchOffForThisChat => 'Desactivado solo para este chat';

  @override
  String get reasoningOffForThisChat => 'Desactivado solo para este chat';

  @override
  String get temperatureOverride => 'Temperatura';

  @override
  String get maxTokensOverride => 'Tokens Máximos';

  @override
  String get topPOverride => 'Top P';

  @override
  String get topKOverride => 'Top K';

  @override
  String get minPOverride => 'Min P';

  @override
  String get repeatPenaltyOverride => 'Penalización de Repetición';

  @override
  String get contextLengthOverride => 'Longitud del Contexto';

  @override
  String get systemPromptsTitle => 'Personas e Indicaciones del Sistema';

  @override
  String get addSystemPromptTooltip => 'Añadir prompt del sistema';

  @override
  String get systemPromptsInfoText =>
      'Crea y gestiona prompts del sistema. Vincúlalos a modelos específicos o úsalos globalmente. Selecciona uno para activarlo.';

  @override
  String get savedPromptsSection => 'PROMPTS GUARDADOS';

  @override
  String get addSystemPrompt => 'Añadir Prompt del Sistema';

  @override
  String get newPrompt => 'Nuevo Prompt';

  @override
  String get noPromptSet => 'Sin prompt definido';

  @override
  String get editSystemPrompt => 'Editar Prompt del Sistema';

  @override
  String get newSystemPrompt => 'Nuevo Prompt del Sistema';

  @override
  String get promptNameLabel => 'Nombre del Prompt';

  @override
  String get promptNameHint => 'ej., Asistente de Código, Escritor Creativo...';

  @override
  String get systemPromptLabel => 'Prompt del Sistema';

  @override
  String get systemPromptEditorHint => 'Eres un asistente útil que...';

  @override
  String get bindToModels => 'Vincular a Modelos Específicos';

  @override
  String get bindToModelsSubtitle =>
      'Restringe este prompt a ciertos modelos. Sin vincular, está disponible para todos los modelos.';

  @override
  String get noModelsLoaded =>
      'No hay modelos cargados. Conecta a LM Studio y carga modelos para vincular este prompt.';

  @override
  String get templatesSection => 'PLANTILLAS';

  @override
  String get pleaseEnterPromptName =>
      'Por favor ingresa un nombre para este prompt';

  @override
  String get pleaseEnterPromptContent =>
      'Por favor ingresa el contenido del prompt';

  @override
  String get deleteSystemPromptTitle => '¿Eliminar Prompt del Sistema?';

  @override
  String deleteSystemPromptMessage(String name) {
    return '¿Estás seguro de que deseas eliminar \"$name\"? Esto no se puede deshacer.';
  }

  @override
  String get templateCodeAssistant => 'Asistente de Código';

  @override
  String get templateCreativeWriter => 'Escritor Creativo';

  @override
  String get templateConciseExpert => 'Experto Conciso';

  @override
  String get templateResearcher => 'Investigador';

  @override
  String get templateTutor => 'Tutor';

  @override
  String get templateTechnicalWriter => 'Escritor Técnico';

  @override
  String get downloadProgress => 'Progreso de Descarga';

  @override
  String get progressLabel => 'Progreso';

  @override
  String get speedLabel => 'Velocidad';

  @override
  String get etaLabel => 'Tiempo Estimado';

  @override
  String get statusLabel => 'Estado';

  @override
  String get notAvailable => 'N/D';

  @override
  String get calculating => 'Calculando...';

  @override
  String get moveToFolderPopup => 'Mover a Carpeta';

  @override
  String contextInfo(String used, String total) {
    return 'Contexto: $used / $total';
  }

  @override
  String get hideAvatars => 'Ocultar Avatares';

  @override
  String get hideAvatarsSubtitle =>
      'Eliminar los íconos de avatar de los mensajes del chat';

  @override
  String get autoScroll => 'Auto-desplazamiento';

  @override
  String get autoScrollSubtitle =>
      'Desplazarse hacia abajo cuando lleguen nuevos mensajes';

  @override
  String get editMcpServer => 'Editar Servidor MCP';

  @override
  String get addMcpServer => 'Añadir Servidor MCP';

  @override
  String get serverLabelRequired => 'Etiqueta del Servidor *';

  @override
  String get serverLabelHint => 'ej., huggingface, tiktoken';

  @override
  String get serverLabelHelper => 'Un nombre para identificar este servidor';

  @override
  String get serverUrlRequired => 'URL del Servidor *';

  @override
  String get serverUrlMcpHint => 'https://huggingface.co/mcp';

  @override
  String get serverUrlHelper => 'URL HTTP/HTTPS del servidor MCP';

  @override
  String get authorizationOptional => 'Clave API (Opcional)';

  @override
  String get authorizationHint => 'hf_xxxxxxxx o Bearer hf_xxxxxxxx';

  @override
  String get authorizationHelper =>
      'Se envía como encabezado Authorization a este MCP. Pega un token (se añade Bearer) o el valor completo del encabezado.';

  @override
  String get additionalHeaders => 'Encabezados Adicionales';

  @override
  String get additionalHeadersHint => 'X-Custom-Header: valor';

  @override
  String get additionalHeadersHelper =>
      'Un encabezado por línea (nombre: valor).\nLa autorización se configura arriba.';

  @override
  String get labelAndUrlRequired => 'Etiqueta y URL son obligatorios';

  @override
  String get urlMustStartWithHttp =>
      'La URL debe comenzar con http:// o https://';

  @override
  String get mcpServerUpdated => 'Servidor MCP actualizado';

  @override
  String get mcpServerAdded => 'Servidor MCP añadido';

  @override
  String get importMcpJsonTitle => 'Importar mcp.json';

  @override
  String get pasteMcpJsonContent => 'Pega el contenido de tu mcp.json';

  @override
  String get mcpJsonLocation =>
      'Encuéntralo en: ~/.lmstudio/config/mcp.json\nO en LM Studio: Desarrollador → Configuración MCP → Abrir config';

  @override
  String get mcpJsonContentLabel => 'Contenido de mcp.json';

  @override
  String get mcpJsonContentHelper =>
      'Pega el contenido completo del archivo mcp.json';

  @override
  String get parseJson => 'Analizar JSON';

  @override
  String foundMcpServers(int count) {
    return 'Se encontraron $count servidor(es) MCP:';
  }

  @override
  String get hasAuthHeaders => 'Tiene encabezados de autenticación';

  @override
  String importSelected(int count) {
    return 'Importar $count Seleccionado(s)';
  }

  @override
  String get pleasePasteMcpJson => 'Por favor pega el contenido de tu mcp.json';

  @override
  String get noMcpServersFound => 'No se encontraron mcpServers en el JSON';

  @override
  String get exampleMcpServers => 'Servidores MCP de Ejemplo';

  @override
  String get gitMcpInfo =>
      'Estos usan GitMCP para proporcionar documentación de repos de GitHub';

  @override
  String get browseMoreGitMcp => 'Ver más en gitmcp.io';

  @override
  String get fileNotFound => 'Archivo no encontrado';

  @override
  String get openWithExternalApp => 'Abrir con app externa';

  @override
  String get previewNotAvailable => 'Vista previa no disponible';

  @override
  String get voiceMode => 'Modo de Voz';

  @override
  String get voiceSettings => 'Ajustes de Voz';

  @override
  String get voiceSettingsSubtitle =>
      'Texto a voz, entrada por voz y modo de voz';

  @override
  String get voiceSection => 'Voz';

  @override
  String get voiceStatus => 'Estado';

  @override
  String get voiceTtsEngine => 'Motor de Texto a Voz';

  @override
  String get voiceSttEngine => 'Motor de Reconocimiento de Voz';

  @override
  String get voiceAvailable => 'Disponible';

  @override
  String get voiceUnavailable => 'No disponible';

  @override
  String get voiceTtsSettings => 'Texto a Voz';

  @override
  String get voiceSttSettings => 'Voz a Texto';

  @override
  String get voiceSttProvider => 'Proveedor de reconocimiento de voz';

  @override
  String get voiceSttProviderSystem => 'Voz del sistema';

  @override
  String get voiceSttProviderSystemSubtitle =>
      'Apple Speech en iOS, Google Speech en Android';

  @override
  String get voiceSttProviderWhisper => 'Whisper en el dispositivo';

  @override
  String get voiceSttProviderWhisperSubtitle =>
      'Whisper sherpa-onnx sin conexión — más preciso, igual en todas las plataformas';

  @override
  String get voiceWhisperModelNotDownloaded => 'Modelo Whisper no descargado';

  @override
  String get voiceWhisperModelReady => 'Modelo Whisper listo';

  @override
  String get voiceWhisperModelSize =>
      'Elige un tamaño — los modelos más grandes transcriben con más precisión';

  @override
  String get voiceWhisperDownloadButton => 'Descargar';

  @override
  String get voiceWhisperDownloading => 'Descargando modelo Whisper…';

  @override
  String get voiceWhisperDownloadStarting => 'Iniciando descarga…';

  @override
  String get voiceWhisperDownloadFailed => 'Error en la descarga';

  @override
  String get voiceWhisperDeleteModel =>
      'Eliminar el modelo Whisper seleccionado';

  @override
  String get voiceWhisperDeleteTitle => '¿Eliminar modelo Whisper?';

  @override
  String get voiceWhisperDeleteMessage =>
      'Esto libera el modelo seleccionado del almacenamiento del dispositivo. El reconocimiento de voz en el dispositivo volverá a la voz del sistema hasta que descargues de nuevo un modelo Whisper.';

  @override
  String get voiceWhisperDeleteConfirm => 'Eliminar';

  @override
  String get voiceWhisperFallback =>
      'Usa la voz del sistema si el modelo no está descargado';

  @override
  String get voiceWhisperBiggerBetterTitle => '¿Por qué modelos más grandes?';

  @override
  String get voiceWhisperBiggerBetterBody =>
      'Los modelos Whisper más grandes suelen producir transcripciones más precisas — sobre todo con acentos, audio bajo, ruido de fondo y palabras poco comunes. También necesitan más almacenamiento y van más lentos en el dispositivo.\n\nTiny vale para habla corta y clara. Base o Small encajan mejor en archivos largos. Large v3 Turbo es el más rápido/pequeño de los grandes (Large v3 reducido). Large v3 completo es el más preciso, pero también el más pesado.';

  @override
  String get voiceWhisperUseModel => 'Usar';

  @override
  String get voiceWhisperSelected => 'Seleccionado';

  @override
  String get voiceWhisperDownloaded => 'Descargado';

  @override
  String get audioSetupTitle => 'Configurar voz y audio';

  @override
  String get audioSetupMessage =>
      'El chat de voz necesita texto a voz para que la IA responda hablando. Elige la voz neuronal Kokoro en el dispositivo para la mejor calidad, o usa las voces integradas del dispositivo — sin descarga.';

  @override
  String get audioSetupWhisperStatus => 'Reconocimiento de voz Whisper';

  @override
  String get audioSetupKokoroStatus => 'Voz neuronal Kokoro';

  @override
  String get audioSetupStatusReady => 'Listo';

  @override
  String get audioSetupStatusMissing => 'No descargado';

  @override
  String get audioSetupOnDeviceButton => 'Descargar voz Kokoro';

  @override
  String get audioSetupOnDeviceSubtitle =>
      'TTS neuronal Kokoro · unos 300 MB · funciona sin conexión';

  @override
  String get audioSetupSystemButton => 'Usar voz del sistema';

  @override
  String get audioSetupSystemSubtitle => 'STT y TTS integrados — sin descarga';

  @override
  String get audioSetupConfigureButton => 'Ajustes de voz';

  @override
  String get audioSetupNotNow => 'Ahora no';

  @override
  String get audioSetupDownloadingWhisper => 'Descargando Whisper…';

  @override
  String get audioSetupDownloadingKokoro => 'Descargando Kokoro…';

  @override
  String get audioSetupDownloadComplete => 'Modelos listos';

  @override
  String get audioSetupContinueButton => 'Continuar';

  @override
  String get voiceModeSettings => 'Modo de Voz';

  @override
  String get voiceAutoRead => 'Leer respuestas automáticamente';

  @override
  String get voiceAutoReadSubtitle =>
      'Leer automáticamente los nuevos mensajes del asistente';

  @override
  String get voiceSpeechRate => 'Velocidad del habla';

  @override
  String get voicePitch => 'Tono';

  @override
  String get voiceLanguage => 'Idioma de voz';

  @override
  String get voiceLanguageSubtitle =>
      'Language for spoken replies (text-to-speech)';

  @override
  String get voiceSttLanguage => 'Recognition language';

  @override
  String get voiceSttLanguageSubtitle =>
      'Used for the text mic and Voice Call. Can differ from spoken reply language.';

  @override
  String get voiceSelection => 'Selección de voz';

  @override
  String get voiceDefault => 'Predeterminada';

  @override
  String get voiceTestVoice => 'Probar voz';

  @override
  String get voiceTestVoiceSubtitle =>
      'Reproducir una muestra para escuchar la configuración de voz actual';

  @override
  String get voiceTestPhrase => '¡Hola! Así sueno ahora.';

  @override
  String get voiceTestProgressInitializing => 'Iniciando motor TTS…';

  @override
  String get voiceTestProgressGenerating => 'Generando voz…';

  @override
  String get voiceTestProgressPreparing => 'Preparando reproducción…';

  @override
  String get voiceTestProgressPlaying => 'Reproduciendo muestra…';

  @override
  String get voiceTestProgressConnecting => 'Conectando a voz remota…';

  @override
  String get voiceTestProgressComplete => 'Listo';

  @override
  String get voiceKokoroEngineReady =>
      'Motor listo — la prueba debería empezar rápido';

  @override
  String get voiceKokoroEngineWarming =>
      'Calentando el motor en el dispositivo…';

  @override
  String get voiceAutoSend => 'Enviar automáticamente después del habla';

  @override
  String get voiceAutoSendSubtitle =>
      'Enviar mensaje automáticamente cuando termine el reconocimiento de voz';

  @override
  String get voiceSttPauseFor => 'Silencio antes de enviar';

  @override
  String get voiceSttPauseForSubtitle =>
      'Segundos de silencio antes de enviar tu voz a la IA';

  @override
  String get voiceSttListenFor => 'Tiempo máximo de escucha';

  @override
  String get voiceSttListenForSubtitle =>
      'Dejar de escuchar tras este número de segundos aunque sigas hablando';

  @override
  String voiceSttSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String get voiceContinuousConversation => 'Conversación continua';

  @override
  String get voiceContinuousConversationSubtitle =>
      'Comenzar a escuchar automáticamente después de leer la respuesta';

  @override
  String get voiceTapToSpeak => 'Toca para hablar';

  @override
  String get voiceListening => 'Escuchando…';

  @override
  String get voiceThinking => 'Un momento…';

  @override
  String get voiceResponding => 'Respondiendo…';

  @override
  String get voiceSpeaking => 'Hablando…';

  @override
  String get voiceConvoHintIdle => 'Toca el círculo para empezar a hablar';

  @override
  String get voiceConvoHintListening => 'Te escucho — tómate tu tiempo';

  @override
  String get voiceConvoHintStarting => 'Preparando el micrófono…';

  @override
  String get voiceConvoHintProcessing => 'Pensando…';

  @override
  String get voiceConvoHintSpeaking => '';

  @override
  String get voiceNotAvailable =>
      'El reconocimiento de voz no está disponible en este dispositivo';

  @override
  String get voiceStartRecording => 'Iniciar entrada de voz';

  @override
  String get voiceStopRecording => 'Detener grabación';

  @override
  String get voiceDiscardRecording => 'Descartar';

  @override
  String get voiceSelectLanguage => 'Seleccionar idioma';

  @override
  String get voiceSelectVoice => 'Seleccionar voz';

  @override
  String get voiceNoVoicesAvailable =>
      'No hay voces disponibles para este idioma';

  @override
  String get voiceAboutTitle => 'Sobre el Modo de Voz';

  @override
  String get voiceAboutDescription =>
      'El modo de voz utiliza los motores de voz nativos de su dispositivo. El texto a voz usa AVSpeechSynthesizer de Apple en iOS y Google TTS en Android. El reconocimiento de voz usa Apple Speech Framework en iOS y Google Speech en Android. Todo el procesamiento se realiza en el dispositivo — no se envían datos a servidores externos.';

  @override
  String get voiceExitMode => 'Cambiar a teclado';

  @override
  String get voiceTtsProvider => 'Proveedor TTS';

  @override
  String get voiceTtsProviderNative => 'Dispositivo (Nativo)';

  @override
  String get voiceTtsProviderNativeSubtitle =>
      'Usa voces del sistema — funciona sin conexión';

  @override
  String get voiceTtsProviderKokoro => 'Voz descargada';

  @override
  String get voiceTtsProviderKokoroSubtitle =>
      'Voces naturales que se ejecutan en este dispositivo';

  @override
  String get voiceTtsProviderKokoroRemote => 'Kokoro (PC)';

  @override
  String get voiceTtsProviderKokoroRemoteSubtitle =>
      'Ejecuta Kokoro en tu PC para voz más rápida y de mayor calidad';

  @override
  String get voiceTtsProviderElevenLabs => 'ElevenLabs';

  @override
  String get voiceTtsProviderElevenLabsSubtitle =>
      'Pro · tu clave API · voces en la nube';

  @override
  String get voiceTtsElevenLabs => 'ElevenLabs';

  @override
  String get voiceTtsElevenLabsHint =>
      'Tu clave · voces de tu biblioteca de ElevenLabs';

  @override
  String get voiceElevenLabsApiKey => 'Clave API de ElevenLabs';

  @override
  String get voiceElevenLabsApiKeyHint => 'Pega tu xi-api-key de elevenlabs.io';

  @override
  String get voiceElevenLabsTestKey => 'Comprobar clave';

  @override
  String get voiceElevenLabsKeyInvalid =>
      'Esa clave no fue aceptada. Revísala en elevenlabs.io.';

  @override
  String get voiceElevenLabsKeyNetwork =>
      'No se pudo contactar con ElevenLabs. Comprueba tu conexión.';

  @override
  String get voiceElevenLabsKeyQuota => 'Esta clave no tiene cuota.';

  @override
  String get voiceElevenLabsKeyUnknown =>
      'No se pudo verificar esta clave. Inténtalo de nuevo.';

  @override
  String get voiceElevenLabsPrivacy =>
      'El texto de las respuestas se envía a ElevenLabs con tu clave. LM Mini guarda la clave solo en este dispositivo.';

  @override
  String get voiceElevenLabsModel => 'Modelo de ElevenLabs';

  @override
  String get voiceElevenLabsVoice => 'Voz de ElevenLabs';

  @override
  String get voiceElevenLabsNoVoices =>
      'No hay voces en esta cuenta. Añade voces en la biblioteca de ElevenLabs primero.';

  @override
  String get voiceElevenLabsChangeKey => 'Cambiar clave';

  @override
  String get voiceElevenLabsRemoveKey => 'Quitar clave';

  @override
  String get voiceElevenLabsReady => 'Conectado a ElevenLabs';

  @override
  String get voiceElevenLabsNoKey => 'Añade tu clave API de ElevenLabs';

  @override
  String get personaElevenLabsVoiceLabel => 'Voz ElevenLabs';

  @override
  String get personaElevenLabsVoiceGlobal => 'Usar la voz global de ElevenLabs';

  @override
  String get personaElevenLabsVoicePickerTitle => 'Voz ElevenLabs';

  @override
  String get personaElevenLabsVoiceAddKey =>
      'Añade una clave API en Ajustes de voz para elegir una voz de ElevenLabs';

  @override
  String get premiumElevenLabsTts => 'Voces ElevenLabs';

  @override
  String get premiumElevenLabsTtsTagline => 'TTS neuronal con tu clave';

  @override
  String get premiumElevenLabsTtsDescription =>
      'Usa tu clave API de ElevenLabs y asigna voces de estudio a las personas. El chat de voz, la lectura automática y leer en voz alta usan el mismo motor.';

  @override
  String get voiceTtsProviderGrok => 'Grok';

  @override
  String get voiceTtsProviderGrokSubtitle =>
      'Pro · tu clave API de xAI · voces en la nube';

  @override
  String get voiceTtsGrok => 'Grok';

  @override
  String get voiceTtsGrokHint => 'Tu clave · voces Grok de xAI';

  @override
  String get voiceGrokApiKey => 'Clave API de xAI';

  @override
  String get voiceGrokApiKeyHint => 'Pega tu clave API de console.x.ai';

  @override
  String get voiceGrokTestKey => 'Comprobar clave';

  @override
  String get voiceGrokKeyInvalid =>
      'Esa clave no fue aceptada. Revísala en console.x.ai.';

  @override
  String get voiceGrokKeyNetwork =>
      'No se pudo contactar con xAI. Comprueba tu conexión.';

  @override
  String get voiceGrokKeyQuota => 'Esta clave no tiene cuota.';

  @override
  String get voiceGrokKeyUnknown =>
      'No se pudo verificar esta clave. Inténtalo de nuevo.';

  @override
  String get voiceGrokPrivacy =>
      'El texto de las respuestas se envía a xAI con tu clave. LM Mini guarda la clave solo en este dispositivo.';

  @override
  String get voiceGrokVoice => 'Voz de Grok';

  @override
  String get voiceGrokNoVoices =>
      'No hay voces de Grok disponibles. Comprueba la clave e inténtalo de nuevo.';

  @override
  String get voiceGrokChangeKey => 'Cambiar clave';

  @override
  String get voiceGrokRemoveKey => 'Quitar clave';

  @override
  String get voiceGrokReady => 'Conectado a Grok';

  @override
  String get voiceGrokNoKey => 'Añade tu clave API de xAI';

  @override
  String get personaGrokVoiceLabel => 'Voz Grok';

  @override
  String get personaGrokVoiceGlobal => 'Usar la voz global de Grok';

  @override
  String get personaGrokVoicePickerTitle => 'Voz Grok';

  @override
  String get personaGrokVoiceAddKey =>
      'Añade una clave API en Ajustes de voz para elegir una voz de Grok';

  @override
  String get personaVoiceSection => 'Voz';

  @override
  String get personaVoiceProviderLabel => 'Proveedor';

  @override
  String get personaVoiceProviderKokoro => 'Kokoro';

  @override
  String get personaVoiceProviderGlobal => 'Usar ajustes de voz globales';

  @override
  String get personaVoiceConfigureInSettings => 'Configurar en Ajustes → Voz';

  @override
  String get premiumGrokTts => 'Voces Grok';

  @override
  String get premiumGrokTtsTagline => 'TTS neuronal con tu clave';

  @override
  String get premiumGrokTtsDescription =>
      'Usa tu clave API de xAI y asigna voces Grok a las personas. El chat de voz, la lectura automática y leer en voz alta usan el mismo motor.';

  @override
  String get voiceRemoteKokoroConnected => 'Conectado a Kokoro en el PC';

  @override
  String get voiceRemoteKokoroNotFound => 'Kokoro TTS no encontrado en el PC';

  @override
  String get voiceRemoteKokoroRequiresConnect =>
      'Requiere Compartir con el teléfono en Mac, o LM Mini Connect en Windows/Linux';

  @override
  String get voiceKokoroVoice => 'Voz de Kokoro';

  @override
  String get voiceKokoroSpeed => 'Velocidad del habla';

  @override
  String get voiceKokoroModelReady => 'Modelo Kokoro listo';

  @override
  String get voiceKokoroModelReadySubtitle => 'La voz descargada está lista';

  @override
  String get voiceKokoroModelNotDownloaded => 'Modelo Kokoro no descargado';

  @override
  String get voiceKokoroModelSize =>
      'Descarga necesaria (~400 MB paquete compartido)';

  @override
  String get voiceKokoroDownloading => 'Descargando modelo Kokoro…';

  @override
  String get voiceKokoroDownloadStarting => 'Iniciando descarga…';

  @override
  String get voiceKokoroDownloadButton => 'Descargar';

  @override
  String get voiceKokoroDownloadFailed =>
      'Descarga fallida. Toca para reintentar.';

  @override
  String get voiceKokoroFallback =>
      'Usará la voz nativa si el modelo Kokoro no está descargado';

  @override
  String get voiceKokoroDeleteModel => 'Eliminar modelo Kokoro';

  @override
  String get voiceKokoroDeleteTitle => '¿Eliminar modelo Kokoro?';

  @override
  String get voiceKokoroDeleteMessage =>
      'Esto eliminará todos los paquetes de idioma TTS descargados. Puedes volver a descargarlos después.';

  @override
  String get voiceKokoroDeleteConfirm => 'Eliminar';

  @override
  String get voiceTtsLanguagePacksHint =>
      'Inglés, español, francés y chino comparten una descarga (~400 MB). Alemán y ruso son más pequeñas (~34 MB cada una).';

  @override
  String get voiceTtsLanguagePacks => 'Paquetes de voz';

  @override
  String get voiceTtsLanguagePacksSubtitleNone =>
      'Descarga un idioma para hablar en este dispositivo';

  @override
  String voiceTtsLanguagePacksSubtitleReady(int ready, int total) {
    return '$ready de $total idiomas listos';
  }

  @override
  String voiceTtsLanguagePacksSubtitleDownloading(String name) {
    return 'Descargando $name…';
  }

  @override
  String voiceTtsSharedPackSize(int size) {
    return 'Descarga compartida · ~$size MB';
  }

  @override
  String voiceTtsPiperPackSize(int size) {
    return 'Descarga más pequeña · ~$size MB';
  }

  @override
  String get voiceTtsSharedPackDeleteMessage =>
      'Esto quita la descarga compartida de inglés, español, francés y chino. Puedes descargarla de nuevo más tarde.';

  @override
  String get connecting => 'Conectando...';

  @override
  String get saveAndTestConnection => 'Guardar y probar conexión';

  @override
  String connectedTo(String provider) {
    return '✅ Conectado a $provider';
  }

  @override
  String connectionToFailed(String provider) {
    return '❌ Conexión a $provider fallida — verifica tu clave API';
  }

  @override
  String errorGeneric(String error) {
    return '❌ Error: $error';
  }

  @override
  String get provider => 'Proveedor';

  @override
  String cloudApiKeyLabel(String provider) {
    return 'Clave API de $provider';
  }

  @override
  String get enterApiKeyHint => 'Introduce tu clave API…';

  @override
  String getApiKey(String provider) {
    return 'Obtener clave API de $provider';
  }

  @override
  String get baseUrl => 'URL base';

  @override
  String get customBaseUrlOptional => 'URL base personalizada (opcional)';

  @override
  String get accountSection => 'CUENTA';

  @override
  String get signIn => 'Iniciar sesión';

  @override
  String get signInSubtitle =>
      'Inicia sesión para activar la copia de seguridad en la nube';

  @override
  String get cloudServicesUnavailable => 'Servicios en la nube no disponibles';

  @override
  String signedInVia(String method) {
    return 'Conectado a través de $method';
  }

  @override
  String get lmMiniProSection => 'LM MINI PRO';

  @override
  String get proActive => 'Pro Activo';

  @override
  String get allPremiumUnlocked => 'Todas las funciones premium desbloqueadas';

  @override
  String get upgradeToPro => 'Mejorar a Pro';

  @override
  String get unlockPremiumFeatures =>
      'Desbloquea todas las funciones premium a continuación';

  @override
  String get proBadge => 'PRO';

  @override
  String get proFeatureTag => 'Función Pro';

  @override
  String get betaBadge => 'BETA';

  @override
  String get imageGeneration => 'Generación de imágenes';

  @override
  String get generatedImagesLibrary => 'Imágenes generadas';

  @override
  String get generatedImagesGallery => 'Galería';

  @override
  String get generatedImagesShowInChat => 'Mostrar en el chat';

  @override
  String get generatedImagesLibrarySubtitle =>
      'Ver, abrir en el chat o eliminar';

  @override
  String get generatedImagesLibraryEmpty => 'Aún no hay imágenes generadas';

  @override
  String get generatedImagesLibraryEmptyHint =>
      'Las imágenes que generes en el chat se guardan aquí.';

  @override
  String get generatedImagesSelect => 'Seleccionar';

  @override
  String get generatedImagesCancelSelect => 'Listo';

  @override
  String generatedImagesDeleteN(int count) {
    return 'Eliminar $count';
  }

  @override
  String get generatedImagesDeleteConfirmTitle => '¿Eliminar imágenes?';

  @override
  String generatedImagesDeleteConfirmBody(int count) {
    return 'Se quitarán $count imagen(es) de este dispositivo. Los mensajes del chat se quedan.';
  }

  @override
  String get generatedImagesOpenChat => 'Abrir en el chat';

  @override
  String get saveToPhotos => 'Save to Photos';

  @override
  String get savedToPhotos => 'Saved to Photos';

  @override
  String get couldNotSaveToPhotos => 'Could not save this file.';

  @override
  String get share => 'Share';

  @override
  String get generatedImagesMissingFile => 'Archivo no encontrado';

  @override
  String get generatedImagesOrphan => 'Sin chat asociado';

  @override
  String get generatedImagesPrompt => 'Prompt';

  @override
  String get generatedImagesNegativePrompt => 'Prompt negativo';

  @override
  String get generatedImagesDetails => 'Detalles de generación';

  @override
  String get generatedImagesNoPrompt => 'No hay prompt guardado';

  @override
  String get generatedImagesChatUnavailable =>
      'Este chat ya no está disponible';

  @override
  String get generatedImagesVideo => 'Vídeo';

  @override
  String imageGenEnabled(String url) {
    return 'Activado — $url';
  }

  @override
  String get imageGenNotConfigured => 'Activado — No configurado';

  @override
  String get cloudBackup => 'Copia de seguridad en la nube';

  @override
  String get encryptedBackupRestore =>
      'Copia de seguridad y restauración cifrada';

  @override
  String get e2eBanner =>
      'Cifrado de extremo a extremo — tu frase de contraseña nunca sale de este dispositivo';

  @override
  String get analytics => 'Estadísticas';

  @override
  String get analyticsSubtitle =>
      'Estadísticas de uso, tokens e información del modelo';

  @override
  String get memory => 'Memorias';

  @override
  String memoryItemCount(int count) {
    return '$count elementos • Persistente entre chats';
  }

  @override
  String get premiumWebSearch => 'Búsqueda web premium';

  @override
  String get premiumWebSearchSubtitle =>
      'Búsqueda instantánea — sin necesidad de SearXNG';

  @override
  String get urlReader => 'Lector de URL';

  @override
  String get urlReaderSubtitle => 'Lee y resume cualquier página web';

  @override
  String get conversationBranching => 'Ramificación de conversaciones';

  @override
  String get conversationBranchingSubtitle =>
      'Bifurca conversaciones desde cualquier mensaje';

  @override
  String get cloudBackupPro => 'Copia de seguridad en la nube';

  @override
  String get cloudBackupProSubtitle =>
      'Copia de seguridad cifrada y restauración en la nube';

  @override
  String get analyticsDashboard => 'Panel de estadísticas';

  @override
  String get analyticsDashboardSubtitle =>
      'Estadísticas de uso, tokens e información del modelo';

  @override
  String get cloudApiProviders => 'Proveedores de API en la nube';

  @override
  String get cloudApiProvidersSubtitle => 'Mistral, DeepSeek y más';

  @override
  String get addProviderLabel => 'Añadir proveedor';

  @override
  String get noCloudProvidersTitle => 'No hay proveedores en la nube';

  @override
  String get noCloudProvidersSubtitle =>
      'Toca + para añadir un proveedor de API en la nube.\nUsa tus propias claves API para Groq, DeepSeek y más.';

  @override
  String get editProviderTitle => 'Editar proveedor';

  @override
  String get addCloudProviderTitle => 'Añadir proveedor en la nube';

  @override
  String get providerLabel => 'Proveedor';

  @override
  String get apiKeyLabel => 'Clave API';

  @override
  String get pasteLabel => 'Pegar';

  @override
  String get baseUrlRequiredLabel => 'URL base (obligatoria)';

  @override
  String get customBaseUrlOptionalLabel => 'URL base personalizada (opcional)';

  @override
  String get advancedLabel => 'Avanzado';

  @override
  String get fetchingLabel => 'Obteniendo...';

  @override
  String get fetchAvailableModelsLabel => 'Obtener modelos disponibles';

  @override
  String get availableModelsLabel => 'Modelos disponibles:';

  @override
  String get suggestedModelsLabel => 'Modelos sugeridos:';

  @override
  String get modelIdLabel => 'ID del modelo';

  @override
  String get disableCloudProviderSubtitle =>
      'Desactiva la configuración sin dejar de conservarla';

  @override
  String get setAsActiveProviderLabel => 'Establecer como proveedor activo';

  @override
  String get deactivateLabel => 'Desactivar';

  @override
  String get switchedBackToLocalLmStudio => 'Se volvió a LM Studio local';

  @override
  String get saveChangesLabel => 'Guardar cambios';

  @override
  String get enterDisplayNameError => 'Introduce un nombre para mostrar';

  @override
  String get enterApiKeyError => 'Introduce una clave API';

  @override
  String get enterBaseUrlError =>
      'Introduce una URL base para el proveedor personalizado';

  @override
  String get enterApiKeyFirst => 'Introduce primero una clave API';

  @override
  String failedToFetchModels(String error) {
    return 'No se pudieron obtener los modelos: $error';
  }

  @override
  String get deleteProviderTitle => '¿Eliminar proveedor?';

  @override
  String deleteProviderMessage(String name) {
    return '¿Eliminar \"$name\" y su clave API?';
  }

  @override
  String deleteFirstPartyOpenAiServerMessage(String name) {
    return '¿Quitar “$name” de este dispositivo?\n\nYa no podrás añadir este servidor desde la lista. Para volver a conectarlo, añade A.I Compatible API y usa https://api.openai.com como URL base.';
  }

  @override
  String activeProviderSet(String name) {
    return '$name establecido como proveedor activo';
  }

  @override
  String get memoryPro => 'Memorias';

  @override
  String get memoryProSubtitle => 'Memorias persistentes entre conversaciones';

  @override
  String get richExportShare => 'Exportación y compartir enriquecidos';

  @override
  String get richExportShareSubtitle =>
      'Exportar a Obsidian, Notas, Notion y más';

  @override
  String autoUnloadAfter(String value) {
    return 'Descarga automática después de $value';
  }

  @override
  String get subscriptionRestore => 'Restaurar';

  @override
  String get subscriptionTerms => 'Términos';

  @override
  String get subscriptionPrivacy => 'Privacidad';

  @override
  String get secureYourAccount => 'Asegura tu cuenta';

  @override
  String get signInWithApple => 'Iniciar sesión con Apple';

  @override
  String get signInWithGoogle => 'Iniciar sesión con Google';

  @override
  String get subscriptionSecured => 'Tu suscripción está asegurada';

  @override
  String get packagesNotAvailable => 'Paquetes aún no disponibles.';

  @override
  String get welcomeToPro => '🎉 ¡Bienvenido a LM Mini Pro!';

  @override
  String get subscriptionRestored => '✅ ¡Suscripción restaurada!';

  @override
  String get noActiveSubscription => 'No se encontró suscripción activa.';

  @override
  String get accountLinked => '✅ ¡Cuenta vinculada!';

  @override
  String get account => 'Cuenta';

  @override
  String get createAccount => 'Crear cuenta';

  @override
  String get emailLabel => 'Correo electrónico';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get forgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get forgotPasswordNeedEmail =>
      'Escribe primero tu correo y luego pulsa ¿Olvidaste tu contraseña?';

  @override
  String get forgotPasswordSent =>
      'Si existe una cuenta con ese correo, enviamos un enlace para restablecerla. Revisa tu bandeja de entrada.';

  @override
  String get forgotPasswordFailed =>
      'No se pudo enviar el correo de restablecimiento. Inténtalo de nuevo.';

  @override
  String get verificationEmailSent => '¡Correo de verificación enviado!';

  @override
  String failedToSend(String error) {
    return 'Error al enviar: $error';
  }

  @override
  String get cloudBackupEnabled =>
      'Activado — tu cuenta soporta copias de seguridad cifradas';

  @override
  String get endToEndEncryption => 'Cifrado de extremo a extremo';

  @override
  String get e2eSubtitle =>
      'Copias de seguridad cifradas con tu frase de contraseña — no podemos leerlas';

  @override
  String get upgradeForCloudBackup =>
      'Mejora a Pro para activar copias de seguridad cifradas en la nube';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get signOutConfirm => '¿Cerrar sesión?';

  @override
  String get signedOut => 'Sesión cerrada.';

  @override
  String get goToAccount => 'Ir a Cuenta';

  @override
  String get firebaseNotConfigured => 'Firebase no está configurado.';

  @override
  String get refresh => 'Actualizar';

  @override
  String get createBackup => 'Crear copia de seguridad';

  @override
  String get encryptBackupSubtitle =>
      'Cifrar y respaldar todas las conversaciones';

  @override
  String get backUpNow => 'Respaldar ahora';

  @override
  String get yourBackups => 'TUS COPIAS DE SEGURIDAD';

  @override
  String get e2eBackupBanner => 'Cifrado de extremo a extremo. ';

  @override
  String get e2eBackupDetail =>
      'Tus copias de seguridad se cifran con tu frase de contraseña antes de salir de este dispositivo. No podemos leer tus datos.';

  @override
  String get exportingData => 'Exportando datos...';

  @override
  String get preparing => 'Preparando...';

  @override
  String get encrypting => 'Cifrando...';

  @override
  String get uploading => 'Subiendo...';

  @override
  String get savingMetadata => 'Guardando metadatos...';

  @override
  String get done => '¡Listo!';

  @override
  String get noBackupsYet => 'Aún no hay copias de seguridad';

  @override
  String get createFirstBackup =>
      'Crea tu primera copia de seguridad cifrada arriba';

  @override
  String get encrypted => 'Cifrado';

  @override
  String get restore => 'Restaurar';

  @override
  String get encryptionPassphraseLabel => 'Frase de contraseña de cifrado';

  @override
  String get enterStrongPassphrase =>
      'Introduce una frase de contraseña segura';

  @override
  String get confirmPassphraseLabel => 'Confirmar frase de contraseña';

  @override
  String get passphraseRememberWarning =>
      '¡Recuerda esta frase de contraseña! Si la pierdes, tus copias de seguridad no podrán recuperarse. No la almacenamos en ningún lugar.';

  @override
  String get passphraseRestoreHint =>
      'Introduce la misma frase de contraseña que usaste al crear esta copia de seguridad.';

  @override
  String get minCharsRequired => 'Se requieren al menos 4 caracteres.';

  @override
  String get passphrasesDoNotMatch => 'Las frases de contraseña no coinciden.';

  @override
  String get encryptAndBackUp => 'Cifrar y respaldar';

  @override
  String get decryptAndRestore => 'Descifrar y restaurar';

  @override
  String get encryptionPassphrase => 'Frase de contraseña de cifrado';

  @override
  String get savedPassphrasePrompt =>
      'Tienes una frase de contraseña guardada de una copia anterior. ¿Te gustaría usar la misma o establecer una nueva?';

  @override
  String get newPassphrase => 'Nueva frase de contraseña';

  @override
  String get useSame => 'Usar la misma';

  @override
  String get setEncryptionPassphrase =>
      'Establecer frase de contraseña de cifrado';

  @override
  String get choosePassphraseBackup =>
      'Elige una frase de contraseña para cifrar esta copia. La necesitarás para restaurar en cualquier dispositivo.';

  @override
  String get choosePassphraseDetail =>
      'Elige una frase de contraseña para cifrar tu copia. Esta frase se queda en tu dispositivo — nunca la vemos. La necesitarás para restaurar.';

  @override
  String backupFailed(String error) {
    return 'Copia de seguridad fallida: $error';
  }

  @override
  String get restoreBackupConfirm => '¿Restaurar copia de seguridad?';

  @override
  String get restoreWarning =>
      'Esto REEMPLAZARÁ todas tus conversaciones, mensajes y carpetas actuales con los datos de esta copia de seguridad.\n\nEsto no se puede deshacer.';

  @override
  String get continueAction => 'Continuar';

  @override
  String get enterPassphrase => 'Introducir frase de contraseña';

  @override
  String get passphraseDecryptHint =>
      'Esta copia está cifrada de extremo a extremo. Introduce la frase de contraseña que usaste al crearla.';

  @override
  String get wrongPassphrase =>
      'Frase de contraseña incorrecta o copia corrupta.';

  @override
  String restoreFailed(String error) {
    return 'Restauración fallida: $error';
  }

  @override
  String get deleteBackupConfirm => '¿Eliminar copia de seguridad?';

  @override
  String get deleteBackupWarning =>
      'Esto eliminará permanentemente esta copia de seguridad cifrada en la nube. No se puede deshacer.';

  @override
  String get backupDeleted => 'Copia de seguridad eliminada.';

  @override
  String deleteFailed(String error) {
    return 'Error al eliminar: $error';
  }

  @override
  String get overview => 'RESUMEN';

  @override
  String get messages => 'Mensajes';

  @override
  String get conversations => 'Conversaciones';

  @override
  String get totalTokens => 'Tokens totales';

  @override
  String get avgResponse => 'Resp. promedio';

  @override
  String get modelUsage => 'USO DEL MODELO';

  @override
  String get noModelUsageData =>
      'Aún no hay datos de uso del modelo.\nComienza a chatear para ver estadísticas aquí.';

  @override
  String get analyticsSync =>
      'Las estadísticas se sincronizan con tu cuenta y se reinician al cerrar sesión.';

  @override
  String get clearAllMemories => 'Borrar todos los recuerdos';

  @override
  String get memoryOn => 'Activada';

  @override
  String get memoryOff => 'Desactivada';

  @override
  String get memoryInfoText =>
      'Los elementos de memoria se inyectan en el prompt del sistema para que el LLM te recuerde entre conversaciones.';

  @override
  String get noMemoriesYet => 'Aún no hay recuerdos';

  @override
  String noMemoriesInCategory(String category) {
    return 'No hay recuerdos de $category';
  }

  @override
  String get memoryTapToAdd =>
      'Toca + para agregar un nuevo recuerdo o elige otra categoría.';

  @override
  String get memoryAddHint =>
      'Agrega datos sobre ti que quieras que la IA recuerde en todas las conversaciones.';

  @override
  String get addMemory => 'Agregar recuerdo';

  @override
  String get category => 'Categoría';

  @override
  String get editMemory => 'Editar recuerdo';

  @override
  String get deleteMemory => 'Eliminar recuerdo';

  @override
  String removeMemoryConfirm(String content) {
    return '¿Eliminar este recuerdo?\n\n\"$content\"';
  }

  @override
  String get clearAllMemoriesTitle => 'Borrar todos los recuerdos';

  @override
  String clearAllMemoriesConfirm(int count) {
    return 'Esto eliminará permanentemente todos los $count recuerdos. No se puede deshacer.';
  }

  @override
  String get clearAll => 'Borrar todo';

  @override
  String get justNow => 'ahora mismo';

  @override
  String get categoryPersonal => 'Personal';

  @override
  String get categoryPreferences => 'Preferencias';

  @override
  String get categoryLifestyle => 'Lifestyle';

  @override
  String get categoryEmotional => 'Emotional';

  @override
  String get categoryTechnical => 'Técnico';

  @override
  String get categoryWork => 'Trabajo';

  @override
  String get categoryGeneral => 'General';

  @override
  String get categoryAll => 'Todos';

  @override
  String get modelManagement => 'Gestión de modelos';

  @override
  String get downloadNewModel => 'Descargar nuevo modelo';

  @override
  String get refreshModels => 'Actualizar modelos';

  @override
  String get tapToSelect => 'Toca para seleccionar';

  @override
  String modelSelected(String name) {
    return 'Seleccionado: $name';
  }

  @override
  String get unloadModelTooltip => 'Descargar modelo de la memoria';

  @override
  String get modelInfoTooltip => 'Info del modelo';

  @override
  String get loadedBadge => 'CARGADO';

  @override
  String get visionBadge => 'Visión';

  @override
  String get toolsBadge => 'Herramientas';

  @override
  String get selectedModel => 'Modelo seleccionado';

  @override
  String get unloading => 'Descargando...';

  @override
  String get unload => 'Descargar';

  @override
  String get loaded => 'Cargado';

  @override
  String get loadModel => 'Cargar modelo';

  @override
  String get enterModelIdOrUrl =>
      'Introduce un ID de modelo o URL de HuggingFace:';

  @override
  String get modelIdHint => 'microsoft/phi-4';

  @override
  String get modelIdHelper => 'ID del modelo o https://huggingface.co/...';

  @override
  String get huggingFaceDetected =>
      'URL de HuggingFace detectada — seleccionarás una cuantización';

  @override
  String get starting => 'Iniciando...';

  @override
  String get download => 'Descargar';

  @override
  String get selectQuantization => 'Seleccionar cuantización';

  @override
  String get loadingQuantizations => 'Cargando cuantizaciones...';

  @override
  String get error => 'Error';

  @override
  String fetchQuantizationsFailed(String error) {
    return 'Error al obtener cuantizaciones: $error';
  }

  @override
  String get checkLmStudioRunning => 'Comprueba si LM Studio está en marcha';

  @override
  String get couldNotReachLmStudio => 'LM Mini no pudo alcanzar tu servidor.';

  @override
  String get couldNotLoadQuantizations =>
      'No se pudieron cargar las cuantizaciones.';

  @override
  String get couldNotStartDownload => 'No se pudo iniciar la descarga.';

  @override
  String get noQuantizations => 'Sin cuantizaciones';

  @override
  String get noGgufFiles =>
      'No se encontraron archivos GGUF en este repositorio';

  @override
  String foundQuantizations(int count) {
    return '$count cuantización(es) GGUF encontrada(s)';
  }

  @override
  String get unknown => 'desconocido';

  @override
  String downloadingModel(String quantization) {
    return 'Descargando modelo con cuantización $quantization...';
  }

  @override
  String get modelAlreadyDownloaded => 'Modelo ya descargado';

  @override
  String downloadFailed(String error) {
    return 'Descarga fallida: $error';
  }

  @override
  String get enterModelIdentifier =>
      'Por favor, introduce un identificador de modelo o URL';

  @override
  String get modelAlreadyLoaded => 'Modelo ya cargado';

  @override
  String get currentlyLoaded => 'Actualmente cargado:';

  @override
  String loadAlongsideWarning(String name) {
    return 'Cargar \"$name\" junto a los modelos existentes usará memoria adicional.';
  }

  @override
  String get unloadAllAndLoad => 'Descargar todo y cargar';

  @override
  String get swap => 'Intercambiar';

  @override
  String get loadAlongside => 'Cargar en paralelo';

  @override
  String get loadParamsConflictTitle => 'La configuración de carga difiere';

  @override
  String loadParamsConflictBody(String name) {
    return '\"$name\" ya está cargado en LM Studio con ajustes distintos a la configuración de carga de LM Mini. Volver a cargar puede tardar un minuto y usar memoria extra.';
  }

  @override
  String get loadParamsConflictTableHeader => 'Parámetros diferentes:';

  @override
  String get loadParamsLmStudio => 'LM Studio';

  @override
  String get loadParamsLmMini => 'LM Mini';

  @override
  String get loadParamsConflictHint =>
      'Usar la configuración de LM Studio evita recargar. Descargar y recargar aplica tus ajustes de LM Mini. Cargar en paralelo mantiene ambas instancias en memoria.';

  @override
  String get loadParamsUseExisting => 'Usar configuración de LM Studio';

  @override
  String get loadParamsReloadWithMini =>
      'Descargar y cargar con ajustes de LM Mini';

  @override
  String get loadParamsLoadParallel =>
      'Cargar con ajustes de LM Mini (en paralelo)';

  @override
  String get reloadModelForContextTitle => '¿Recargar el modelo?';

  @override
  String reloadModelForContextBody(String name, String loaded, String desired) {
    return 'La longitud de contexto se aplica al cargar el modelo. \"$name\" está cargado con $loaded. ¿Recargarlo con $desired?';
  }

  @override
  String get reloadModelForContextNow => 'Recargar';

  @override
  String get reloadModelForContextLater => 'Ahora no';

  @override
  String loadModelConfirm(String name) {
    return '¿Cargar \"$name\" en la memoria?';
  }

  @override
  String get unloadModelTip =>
      'Puedes descargar modelos usando el botón de expulsar o desde esta pantalla después de cargar.';

  @override
  String get modelLoadedSuccess => 'Modelo cargado exitosamente';

  @override
  String get failedToLoadModel => 'Error al cargar el modelo';

  @override
  String get modelInfo => 'Info del modelo';

  @override
  String get infoName => 'Nombre';

  @override
  String get infoType => 'Tipo';

  @override
  String get infoArchitecture => 'Arquitectura';

  @override
  String get infoPublisher => 'Editor';

  @override
  String get infoQuantization => 'Cuantización';

  @override
  String get infoParameters => 'Parámetros';

  @override
  String get infoSize => 'Tamaño';

  @override
  String get infoMaxContext => 'Contexto máx.';

  @override
  String get infoLoadedContext => 'Contexto cargado';

  @override
  String get infoStatus => 'Estado';

  @override
  String get available => 'Disponible';

  @override
  String get capabilities => 'Capacidades';

  @override
  String get standardTextGeneration => 'Generación de texto estándar';

  @override
  String get unloadModelTitle => 'Descargar modelo';

  @override
  String unloadModelConfirm(String name) {
    return '¿Descargar \"$name\" de la memoria?';
  }

  @override
  String get freeResourcesTip => 'Esto liberará recursos de GPU/RAM.';

  @override
  String get modelUnloadedSuccess => 'Modelo descargado exitosamente';

  @override
  String get failedToUnloadModel => 'Error al descargar el modelo';

  @override
  String get enableImageGeneration => 'Activar generación de imágenes';

  @override
  String get showImageButtons =>
      'Mostrar botones de imagen en mensajes del chat';

  @override
  String get serverConnection => 'Conexión del servidor';

  @override
  String get serverUrl => 'URL del servidor';

  @override
  String get test => 'Probar';

  @override
  String get connected => 'Conectado';

  @override
  String get model => 'Modelo';

  @override
  String get checkpoint => 'Punto de control';

  @override
  String get generationParameters => 'Parámetros de generación';

  @override
  String get negativePrompt => 'Prompt negativo';

  @override
  String get steps => 'Pasos';

  @override
  String get cfgScale => 'Escala CFG';

  @override
  String get width => 'Ancho';

  @override
  String get height => 'Alto';

  @override
  String get sampler => 'Muestreador';

  @override
  String get scheduler => 'Planificador';

  @override
  String get automatic => 'Automático';

  @override
  String get seedLabel => 'Semilla (-1 = aleatorio)';

  @override
  String get batchSize => 'Tamaño de lote';

  @override
  String get options => 'Opciones';

  @override
  String get restoreFaces => 'Restaurar caras';

  @override
  String get restoreFacesSubtitle => 'Corregir caras en imágenes generadas';

  @override
  String get tiling => 'Mosaico';

  @override
  String get tilingSubtitle => 'Generar texturas repetibles sin costuras';

  @override
  String get promptOptions => 'Opciones de prompt';

  @override
  String get reviewPromptBeforeSending => 'Revisar prompt antes de enviar';

  @override
  String get reviewPromptSubtitle =>
      'Editar el prompt de imagen antes de generar';

  @override
  String get autoGenerateImage => 'Generar imagen automáticamente';

  @override
  String get autoGenerateSubtitle =>
      'Generar imagen automáticamente cuando la IA proporcione un prompt';

  @override
  String get resetToDefaults => 'Restablecer valores predeterminados';

  @override
  String get featureRequestsTitle => 'Solicitudes de funciones';

  @override
  String get featureRequestsUnavailable =>
      'Solicitudes de funciones no disponibles';

  @override
  String get featureRequestsUnavailableDetail =>
      'Esta función requiere conexión a internet. Verifica tu conexión e inténtalo de nuevo más tarde.';

  @override
  String get tryAgain => 'Intentar de nuevo';

  @override
  String get votesLeft => 'restantes';

  @override
  String get popular => 'Popular';

  @override
  String get myRequests => 'Mis solicitudes';

  @override
  String get completed => 'Completado';

  @override
  String get submitIdea => 'Enviar idea';

  @override
  String get noFeatureRequests => 'Aún no hay solicitudes de funciones';

  @override
  String get beFirstToSubmit => '¡Sé el primero en enviar una idea!';

  @override
  String get noRequestsSubmitted => 'No hay solicitudes enviadas';

  @override
  String get tapToSubmitFirst =>
      '¡Toca el botón de abajo para enviar tu primera idea!';

  @override
  String get noCompletedRequests => 'No hay solicitudes completadas';

  @override
  String get completedRequestsAppear =>
      'Las solicitudes completadas y rechazadas aparecerán aquí.';

  @override
  String get adminReplied => 'Admin respondió';

  @override
  String get submitFeatureRequest => 'Enviar solicitud de función';

  @override
  String get titleRequired => 'Título *';

  @override
  String get titleHint => 'Breve resumen de tu idea';

  @override
  String get descriptionRequired => 'Descripción *';

  @override
  String get descriptionHint => 'Describe tu solicitud de función en detalle';

  @override
  String get yourNameOptional => 'Tu nombre (opcional)';

  @override
  String get leaveBlankAnonymous =>
      'Deja en blanco para enviar de forma anónima';

  @override
  String get fillTitleAndDescription =>
      'Por favor, completa el título y la descripción';

  @override
  String get featureRequestSubmitted => '¡Solicitud de función enviada!';

  @override
  String get submit => 'Enviar';

  @override
  String get featureRequest => 'Solicitud de función';

  @override
  String get votedTooltip => 'Votado';

  @override
  String get voteForThis => 'Votar por esto';

  @override
  String get adminControls => 'Controles de admin';

  @override
  String get changeStatus => 'Cambiar estado';

  @override
  String get officialReply => 'Respuesta oficial';

  @override
  String get deleteRequest => 'Eliminar solicitud';

  @override
  String get unableToLoadComments => 'No se pueden cargar los comentarios';

  @override
  String commentsCount(int count) {
    return 'Comentarios ($count)';
  }

  @override
  String get readMore => 'Leer más';

  @override
  String get showLess => 'Mostrar menos';

  @override
  String get deleteYourRequest => 'Eliminar tu solicitud';

  @override
  String get anonymous => 'Anónimo';

  @override
  String get officialResponse => 'Respuesta oficial';

  @override
  String get noCommentsYet => 'Aún no hay comentarios';

  @override
  String get beFirstToComment => '¡Sé el primero en compartir tus ideas!';

  @override
  String get adminBadge => 'ADMIN';

  @override
  String get moderatorBadge => 'MOD';

  @override
  String get experiencedUserBadge => 'EXP';

  @override
  String get adminManageSubmitter => 'Gestionar autor';

  @override
  String get adminManageUserTitle => 'Gestionar usuario';

  @override
  String get adminUserUpdated => 'Usuario actualizado';

  @override
  String get adminCommunityRoles => 'Roles de la comunidad';

  @override
  String get adminModeratorRole => 'Moderador';

  @override
  String get adminModeratorRoleSubtitle =>
      'Puede saltarse límites de spam en comentarios y muestra una insignia de Mod';

  @override
  String get adminExperiencedUserRole => 'Usuario experimentado';

  @override
  String get adminExperiencedUserRoleSubtitle =>
      'Muestra una insignia de Experimentado en comentarios de solicitudes de funciones';

  @override
  String get adminGrantPremiumTitle => 'Conceder Pro de cortesía';

  @override
  String get adminGrantPremiumSubtitle =>
      'Dar a este usuario LM Mini Pro gratis durante un tiempo limitado';

  @override
  String get adminGrantPremiumAmountLabel => 'Duración';

  @override
  String get adminGrantPremiumAmountHint => 'Introduce la cantidad';

  @override
  String get adminGrantPremiumUnitDays => 'Días';

  @override
  String get adminGrantPremiumUnitWeeks => 'Semanas';

  @override
  String get adminGrantPremiumUnitMonths => 'Meses';

  @override
  String get adminGrantPremiumGrantButton => 'Conceder Pro';

  @override
  String get adminGrantPremiumInvalidAmount => 'Introduce un número positivo';

  @override
  String get adminGrantPremiumReasonLabel => 'Motivo';

  @override
  String get adminGrantPremiumReasonHint =>
      'Opcional — se muestra al usuario (p. ej. Perdona las molestias)';

  @override
  String adminGrantPremiumDurationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String adminGrantPremiumDurationWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count semanas',
      one: '1 semana',
    );
    return '$_temp0';
  }

  @override
  String adminGrantPremiumDurationMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count meses',
      one: '1 mes',
    );
    return '$_temp0';
  }

  @override
  String get adminRevokePremiumTitle => 'Revocar Pro de cortesía';

  @override
  String get adminRevokePremiumMessage =>
      '¿Quitar el acceso Pro concedido por el administrador para este usuario?';

  @override
  String get adminRevokePremiumConfirm => 'Revocar';

  @override
  String get premiumGrantBannerTitle => 'Has recibido Pro de cortesía';

  @override
  String premiumGrantBannerBody(String duration) {
    return 'LM Mini Pro gratis durante $duration. Disfruta de las funciones premium mientras dure.';
  }

  @override
  String premiumGrantBannerReason(String reason) {
    return 'Motivo: $reason';
  }

  @override
  String get premiumGrantDialogTitle => 'Pro de cortesía desbloqueado';

  @override
  String premiumGrantDialogBody(String duration) {
    return 'Un administrador te ha concedido LM Mini Pro gratis durante $duration. Copia de seguridad en la nube, memoria, analíticas y más ya están disponibles.';
  }

  @override
  String premiumGrantDialogReason(String reason) {
    return 'Motivo: $reason';
  }

  @override
  String get premiumGrantDialogButton => 'Genial';

  @override
  String get youBadge => 'TÚ';

  @override
  String get deleteComment =>
      '¿Estás seguro de que quieres eliminar este comentario?';

  @override
  String maxCommentsReached(int max) {
    return 'Has publicado $max comentarios seguidos. Espera a que otro usuario responda.';
  }

  @override
  String get addYourName => 'Añade tu nombre';

  @override
  String get replyAsAdmin => 'Responder como Admin...';

  @override
  String get writeComment => 'Escribe un comentario...';

  @override
  String get errorTryAgain => 'Error: inténtalo de nuevo.';

  @override
  String statusUpdated(String status) {
    return 'Estado actualizado a $status';
  }

  @override
  String get addOfficialResponse => 'Añadir una respuesta oficial...';

  @override
  String get replySaved => 'Respuesta guardada';

  @override
  String get deleteRequestConfirm =>
      '¿Estás seguro de que quieres eliminar esta solicitud? No se puede deshacer.';

  @override
  String get requestDeleted => 'Solicitud eliminada';

  @override
  String get deleteCommentTitle => 'Eliminar comentario';

  @override
  String get deleteCommentConfirm =>
      '¿Estás seguro de que quieres eliminar este comentario?';

  @override
  String get commentDeleted => 'Comentario eliminado';

  @override
  String get generationParametersSection => 'PARÁMETROS DE GENERACIÓN';

  @override
  String get temperature => 'Temperatura';

  @override
  String get temperatureSubtitle =>
      'Qué tan creativas o enfocadas son las respuestas. Más bajo = más cuidadoso; más alto = más variado.';

  @override
  String get topP => 'Top P';

  @override
  String get topPSubtitle =>
      'Qué tan amplio es el rango de palabras permitidas. Más bajo = respuestas más enfocadas.';

  @override
  String get minP => 'Min P';

  @override
  String get minPSubtitle =>
      'Ignora palabras muy poco probables. Más alto = texto más seguro y predecible.';

  @override
  String get repeatPenalty => 'Penalización de repetición';

  @override
  String get repeatPenaltySubtitle =>
      'Evita que la IA repita las mismas frases. 1.0 = desactivado.';

  @override
  String get frequencyPenalty => 'Penalización de frecuencia';

  @override
  String get frequencyPenaltySubtitle =>
      'Reduce las palabras que la IA usa demasiado.';

  @override
  String get presencePenalty => 'Penalización de presencia';

  @override
  String get presencePenaltySubtitle =>
      'Anima a la IA a traer temas nuevos en lugar de repetir los de antes.';

  @override
  String get tokenLimits => 'LÍMITES DE TOKENS';

  @override
  String get maxOutputTokens => 'Tokens de salida máximos';

  @override
  String get maxOutputTokensSubtitle =>
      'Qué tan larga puede ser una sola respuesta. Más alto = respuestas más largas (y más espera).';

  @override
  String get contextWindow => 'Ventana de contexto';

  @override
  String get contextWindowSubtitle =>
      'Cuánto del chat puede recordar la IA a la vez. Más alto usa más memoria.';

  @override
  String get modelLoadingConfig => 'CONFIGURACIÓN DE CARGA DEL MODELO';

  @override
  String get loadContextLength => 'Longitud de contexto';

  @override
  String get loadContextSubtitle =>
      'Cuánto contexto puede usar el modelo en el chat y al cargarlo en LM Studio. Más alto usa más memoria / VRAM.';

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
  String get evalBatchSize => 'Tamaño de lote de evaluación';

  @override
  String get evalBatchSubtitle =>
      'Cuánto texto se procesa a la vez al cargar. Más alto puede ser más rápido, pero usa más memoria.';

  @override
  String get numExperts => 'Núm. de expertos';

  @override
  String get numExpertsSubtitle =>
      'Solo para modelos “mixture of experts”. Déjalo vacío si no estás seguro.';

  @override
  String get flashAttention => 'Flash Attention';

  @override
  String get flashAttentionSubtitle =>
      'Acelera el modelo y puede usar menos memoria. Déjalo activado salvo que falle algo.';

  @override
  String get offloadKvCache => 'Descargar caché KV a GPU';

  @override
  String get offloadKvCacheSubtitle =>
      'Usa la GPU para recordar el chat de forma más eficiente. Actívalo si tienes GPU.';

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
      'Muestra el pensamiento paso a paso de la IA cuando esté disponible.';

  @override
  String get reasoningUnsupportedToast =>
      'Este modelo no admite Reasoning en LM Studio. Reasoning se ha desactivado.';

  @override
  String get reasoningNotExposedChatHint =>
      'LM Studio no permite desactivar el razonamiento en este modelo. Prueba con otro modelo.';

  @override
  String get premiumSearchActive => 'Búsqueda Premium activa';

  @override
  String get premiumSearchPlusSearxng => ' + SearXNG';

  @override
  String get webSearchDisabledAll =>
      'Búsqueda web desactivada para todos los chats';

  @override
  String get configureSearch => 'Configurar búsqueda';

  @override
  String get advancedFeaturesSection => 'FUNCIONES AVANZADAS';

  @override
  String get howToolCallingWorks => 'Cómo funciona la llamada a herramientas';

  @override
  String get stepAskQuestion => 'Haces una pregunta';

  @override
  String get stepAskExample => 'ej., \"¿Cuál es el clima en Tokio?\"';

  @override
  String get stepAiRequestsTool => 'La IA solicita una herramienta';

  @override
  String get stepAiRequestsExample =>
      'El modelo decide que necesita búsqueda web';

  @override
  String get stepAppExecutes => 'La app ejecuta la herramienta';

  @override
  String get stepAppExecutesExample =>
      'Busca usando Búsqueda Premium o SearXNG';

  @override
  String get stepResultsSent => 'Resultados enviados a la IA';

  @override
  String get stepResultsExample =>
      'Resultados de búsqueda agregados a la conversación';

  @override
  String get stepAiAnswers => 'La IA genera una respuesta';

  @override
  String get stepAiAnswersExample => 'El modelo sintetiza una respuesta útil';

  @override
  String get toolCallingModelNote => 'como Qwen, Llama 3.1+ o Mistral.';

  @override
  String get searxngSetup => 'Configuración de SearXNG';

  @override
  String get searxngDescription =>
      'SearXNG es un metabuscador gratuito y respetuoso con la privacidad que puedes auto-alojar.';

  @override
  String get dockerRecommended => 'Opción 1: Docker (Recomendado)';

  @override
  String get publicInstance => 'Opción 2: Usar una instancia pública';

  @override
  String get findPublicInstances => 'Encuentra instancias públicas en:';

  @override
  String get selfHostRecommended =>
      'Se recomienda auto-alojar para mayor fiabilidad.';

  @override
  String get clipboardEmpty =>
      'Portapapeles vacío. Copia primero el contenido de tu mcp.json.';

  @override
  String get clipboardAccessFailed =>
      'No se pudo acceder al portapapeles. Por favor, pega manualmente en el campo de abajo.';

  @override
  String get pasteFromClipboard => 'Pegar del portapapeles';

  @override
  String get httpServersImportNote =>
      'Servidores HTTP → MCPs efímeros (enviados a LM Studio por solicitud)';

  @override
  String get localMcpsImportNote =>
      'MCPs locales → MCPs integrados (usan formato \"mcp/nombre\")';

  @override
  String get noValidMcpServers => 'No se encontraron servidores MCP válidos';

  @override
  String get serverAlreadyAdded => 'Este servidor ya está agregado';

  @override
  String get themeSection => 'TEMA';

  @override
  String get themeLabel => 'Tema';

  @override
  String get glassEffectsLabel => 'Efectos de cristal';

  @override
  String get glassEffectsSubtitle =>
      'Desenfoque esmerilado en encabezados y menús. Desactívalo para que el teléfono se caliente menos.';

  @override
  String get lowBatteryModeLabel => 'Modo de ahorro de batería';

  @override
  String get lowBatteryModeSubtitle =>
      'Apaga el cristal, muestra texto plano mientras llega la respuesta y sincroniza Home/iCloud solo al terminar el mensaje. La pantalla sigue encendida hasta que termine la respuesta para no cortar el flujo.';

  @override
  String get backgroundSection => 'FONDO';

  @override
  String get chatBackground => 'Fondo del chat';

  @override
  String get chatBackgroundSubtitle =>
      'Establecer fondo predeterminado para todos los chats';

  @override
  String get avatarsSection => 'AVATARES';

  @override
  String get chatHeaderAvatarLabel => 'Avatar del encabezado del chat';

  @override
  String get chatHeaderAvatarSubtitle =>
      'Mostrar la imagen de perfil en la barra superior de la ventana del chat';

  @override
  String get avatarAboveMessageLabel => 'Avatar encima del mensaje';

  @override
  String get avatarAboveMessageSubtitle =>
      'Mostrar el avatar encima de la burbuja del mensaje en lugar de a un lado';

  @override
  String get fullWidthAssistantLabel => 'Respuestas a ancho completo';

  @override
  String get fullWidthAssistantSubtitle =>
      'Tus mensajes siguen en una burbuja. El texto del asistente usa toda la fila';

  @override
  String get tryFullWidthTitle => 'Prueba la nueva vista a ancho completo';

  @override
  String get tryFullWidthBody =>
      'Las respuestas del asistente ocupan toda la fila, sin burbuja. Puedes volver atrás cuando quieras en Apariencia.';

  @override
  String get tryFullWidthOpenAppearance => 'Abrir Apariencia';

  @override
  String get tryFullWidthNotNow => 'Ahora no';

  @override
  String get streamingPhaseLoadingModel => 'Cargando modelo';

  @override
  String get streamingPhaseProcessingPrompt => 'Procesando la consulta';

  @override
  String get streamingPhaseThinking => 'Pensando';

  @override
  String get streamingPhaseWriting => 'Escribiendo respuesta';

  @override
  String get streamingPhaseSearching => 'Buscando';

  @override
  String get streamingPhaseUsingTools => 'Usando herramientas';

  @override
  String get previewUserMessage => '¿Qué zócalo tiene esta placa?';

  @override
  String get bubbleAvatarSizeLabel => 'Tamaño del avatar en la burbuja';

  @override
  String bubbleAvatarRadiusValue(int value) {
    return 'radio de ${value}px';
  }

  @override
  String get userAvatarLabel => 'Avatar del usuario';

  @override
  String get yourProfilePicture => 'Tu foto de perfil';

  @override
  String get assistantAvatarLabel => 'Avatar del asistente';

  @override
  String get aiAssistantPicture => 'Foto del asistente de IA';

  @override
  String get chatBehaviorSection => 'COMPORTAMIENTO DEL CHAT';

  @override
  String get fontSizeLabel => 'Tamaño de fuente';

  @override
  String get iconSizeLabel => 'Tamaño de iconos';

  @override
  String pointsValue(int value) {
    return '${value}pt';
  }

  @override
  String get previewLabel => 'Vista previa';

  @override
  String get previewAssistantMessage =>
      '¡Hola! Soy tu asistente de IA. ¿Cómo puedo ayudarte hoy? Aquí tienes una palabra en **negrita** y algo de `código en línea`.';

  @override
  String get readAloud => 'Leer en voz alta';

  @override
  String appearanceActionTapped(String label) {
    return 'Se pulsó $label';
  }

  @override
  String get autoScrollStreaming => 'Auto-desplazar durante transmisión';

  @override
  String get autoScrollStreamingSubtitle =>
      'Desplazarse automáticamente a nuevos mensajes';

  @override
  String get showChatStarters => 'Sugerencias de chat nuevo';

  @override
  String get showChatStartersSubtitle =>
      'Mostrar pastillas de prompts en chats vacíos';

  @override
  String get useLegacyComposer => 'Campo de mensaje clásico';

  @override
  String get useLegacyComposerSubtitle =>
      'Usar el compositor compacto clásico en lugar del nuevo input shine';

  @override
  String get hideAvatarsLabel => 'Ocultar avatares';

  @override
  String get moreSpaceForContent =>
      'Más espacio para el contenido de los mensajes';

  @override
  String get enterKeyBehaviorLabel =>
      'Comportamiento de la tecla Retorno/Enter';

  @override
  String get enterKeyAutoDescription =>
      'Enviar con teclados físicos e insertar nueva línea con teclados táctiles';

  @override
  String get enterKeySendDescription =>
      'Enter envía el mensaje (Mayús+Enter para nueva línea)';

  @override
  String get enterKeyNewlineDescription =>
      'Enter siempre inserta una nueva línea';

  @override
  String get sendLabel => 'Enviar';

  @override
  String get newLineLabel => 'Nueva línea';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get backLabel => 'Atrás';

  @override
  String get nextLabel => 'Siguiente';

  @override
  String get getStartedLabel => 'Comenzar';

  @override
  String get connectionSuccessful => '¡Conexión exitosa!';

  @override
  String get connectionFailedMessage => 'La conexión falló';

  @override
  String get lmStudioServerFoundNeedsKey =>
      '¡Servidor encontrado! Añade tu clave API arriba y luego toca Probar conexión.';

  @override
  String get lmStudioScanServerNeedsKey =>
      'Encontrado — añade la clave API para conectar';

  @override
  String lmStudioUsingServerNeedsKey(String url) {
    return 'Usando $url. Añade tu clave API abajo y prueba la conexión.';
  }

  @override
  String get lmStudioAuthDialogTitle => 'Servidor encontrado';

  @override
  String get lmStudioAuthDialogMessage =>
      'Este servidor requiere una clave API. Pega tu token de LM Studio abajo para conectar.';

  @override
  String get lmStudioAuthHelpHint =>
      'En LM Studio, abre el modo Desarrollador → Ajustes del servidor → Gestionar tokens para crear o copiar tu clave API.';

  @override
  String get welcomeWizardTitle => 'Bienvenido a LM Mini';

  @override
  String get welcomeWizardSubtitle =>
      'Chatea con modelos de IA que se ejecutan en tu red local mediante LM Studio. Vamos a configurarlo en unos pocos pasos rápidos.';

  @override
  String get welcomeWizardThemeTitle => 'Elige tu tema';

  @override
  String get welcomeWizardThemeSystemSubtitle =>
      'Coincidir con la configuración del dispositivo';

  @override
  String get welcomeWizardThemeLightSubtitle => 'Limpio y brillante';

  @override
  String get welcomeWizardThemeDarkSubtitle => 'Suave para la vista';

  @override
  String get welcomeWizardAppearanceTitle => 'Personalizar apariencia';

  @override
  String get welcomeWizardAppearancePreviewMessage =>
      '¡Hola! Así es como se verán tus mensajes de chat.';

  @override
  String get welcomeWizardServerTitle => 'Conectar con LM Studio';

  @override
  String get welcomeWizardServerSubtitle =>
      'Introduce la dirección IP del ordenador que ejecuta LM Studio en tu red local.';

  @override
  String get welcomeWizardLocalNetworkNote =>
      'iOS pedirá permiso para la red local cuando pruebes la conexión. Permítelo.';

  @override
  String get apiTokenOptionalLabel => 'Token de API (opcional)';

  @override
  String get welcomeWizardChangeLater =>
      'Siempre puedes cambiar esto más tarde en Ajustes.';

  @override
  String get welcomeWizardFindModelTitle => 'Encuentra un modelo que encaje';

  @override
  String get welcomeWizardFindModelSubtitle =>
      'Compara dos opciones y mira cuál es más rápida en tu equipo. Tarda aproximadamente un minuto — o sáltalo si ya sabes qué quieres.';

  @override
  String get welcomeWizardFindModelHelp => 'Ayúdame a elegir';

  @override
  String get welcomeWizardFindModelSkip => 'Saltar — yo elijo';

  @override
  String get welcomeWizardExperienceTitle => 'How do you use AI?';

  @override
  String get welcomeWizardExperienceSubtitle =>
      'We\'ll tailor recommendations. You can change everything later.';

  @override
  String get welcomeWizardBeginnerTitle => 'Beginner';

  @override
  String get welcomeWizardBeginnerSubtitle =>
      'Manténlo simple: Ajustes más claros y te sugerimos un buen modelo.';

  @override
  String get welcomeWizardPowerTitle => 'Power user';

  @override
  String get welcomeWizardPowerSubtitle =>
      'Ajustes completos y opciones: modelos en el dispositivo y servidores como LM Studio.';

  @override
  String get welcomeWizardSetupTitleBeginner => 'Elige un modelo';

  @override
  String get welcomeWizardSetupTitlePower => 'Choose your setup';

  @override
  String get welcomeWizardSetupSubtitleBeginner =>
      'Toca un modelo para descargarlo. O conecta un ordenador por Wi‑Fi.';

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
  String get pickColor => 'Elegir color';

  @override
  String get hueLabel => 'Matiz';

  @override
  String get saturationLabel => 'Saturación';

  @override
  String get lightnessLabel => 'Luminosidad';

  @override
  String get alphaLabel => 'Alfa';

  @override
  String get hexLabel => 'Hex';

  @override
  String get personaModeLabel => 'Modo persona';

  @override
  String get personaModeSubtitle =>
      'Añadir avatar, color de acento, voz y modelo preferido para chats grupales';

  @override
  String get avatarLabel => 'Avatar';

  @override
  String get customAvatarSet => 'Avatar personalizado configurado';

  @override
  String get noAvatar => 'Sin avatar';

  @override
  String get accentColorLabel => 'Color de acento';

  @override
  String get defaultLabel => 'Predeterminado';

  @override
  String get preferredModelLabel => 'Modelo preferido';

  @override
  String get preferredModelAny => 'Ninguno (usar cualquiera)';

  @override
  String get personaChooseProviderTitle => 'Elegir proveedor';

  @override
  String get personaChooseProviderSubtitle =>
      'Tus proveedores configurados. Añade más en Ajustes.';

  @override
  String get personaCloudProvidersSection => 'Proveedores en la nube';

  @override
  String get personaKokoroVoiceLabel => 'Voz Kokoro';

  @override
  String get personaKokoroVoiceSubtitle =>
      'Voz cuando esta persona habla (chat de voz / leer en voz alta)';

  @override
  String get personaKokoroVoiceGlobal => 'Usar la configuración global de voz';

  @override
  String get personaKokoroVoicePickerTitle => 'Voz de la persona';

  @override
  String get personaKokoroSpeedLabel => 'Velocidad del habla';

  @override
  String get personaKokoroSpeedGlobal => 'Usar velocidad global';

  @override
  String personaKokoroSpeedValue(String speed) {
    return '${speed}x';
  }

  @override
  String get voiceWhisperModelLabel => 'Modelo Whisper';

  @override
  String get voiceWhisperModelTapToChoose =>
      'Toca para elegir tamaño y descargar';

  @override
  String get imageGenSeedLabel => 'Semilla de imagen';

  @override
  String imageGenSeedFixed(int seed) {
    return 'Semilla fija: $seed';
  }

  @override
  String get imageGenSeedRandomGlobal =>
      'Aleatoria (usar la configuración global)';

  @override
  String get personaComfyWorkflowLabel => 'Flujo de trabajo de ComfyUI';

  @override
  String get personaComfyWorkflowUseGlobal => 'Usar la configuración global';

  @override
  String personaComfyWorkflowUnavailable(String path) {
    return '$path (no disponible actualmente)';
  }

  @override
  String get personaComfyWorkflowHelper =>
      'Se usa cuando el proveedor de generación de imágenes es ComfyUI. Déjalo en global para usar Ajustes → Generación de imágenes.';

  @override
  String get personaComfyWorkflowNotComfy =>
      'Esta asignación solo aplica cuando ComfyUI es el proveedor de imágenes activo.';

  @override
  String get personaComfyWorkflowRefresh => 'Actualizar flujos de trabajo';

  @override
  String get personaComfyWorkflowJsonLabel =>
      'JSON de flujo personalizado (opcional)';

  @override
  String get personaComfyWorkflowJsonHint =>
      'Déjalo vacío para usar el flujo global / integrado';

  @override
  String get personaComfyWorkflowJsonHelper =>
      'Pega un flujo en formato API. Admite %PROMPT%, %LORA%, %LORA_WEIGHT% y otros marcadores.';

  @override
  String get personaComfyWorkflowJsonIgnored =>
      'Se ignora mientras haya un flujo guardado seleccionado';

  @override
  String personaComfyWorkflowJsonActive(int count) {
    return 'Usando flujo personalizado ($count caracteres)';
  }

  @override
  String get personaComfyWorkflowJsonClear =>
      'Borrar (usar global / predeterminado)';

  @override
  String get comfyUiDetails => 'Detalles de ComfyUI';

  @override
  String get comfyUiDetailsTitle => 'Solicitud ComfyUI';

  @override
  String get comfyUiDetailsCopy => 'Copiar JSON';

  @override
  String get comfyUiDetailsCopied => 'Copiado al portapapeles';

  @override
  String get resetToGlobal => 'Restablecer al valor global';

  @override
  String get setSeed => 'Establecer semilla';

  @override
  String get pickAccentColor => 'Elegir color de acento';

  @override
  String get imageGenSeedDialogDescription =>
      'Establece una semilla fija para que esta persona genere imágenes coherentes siempre. Déjalo vacío para aleatoria.';

  @override
  String get seedValueLabel => 'Valor de semilla';

  @override
  String get seedValueHint => 'p. ej. 42 (vacío = aleatoria)';

  @override
  String get setLabel => 'Establecer';

  @override
  String get selectPreferredModelTitle => 'Seleccionar modelo preferido';

  @override
  String get branchCreated => '🔀 Rama creada';

  @override
  String get yamlFrontmatter => 'Encabezado YAML';

  @override
  String get markdownFormat => 'Markdown';

  @override
  String get localNetworkBlocked =>
      'El acceso a la red local puede estar bloqueado';

  @override
  String get localNetworkFix =>
      'Ve a Ajustes → LM Mini → Red local y actívalo.';

  @override
  String get openAppSettings => 'Abrir ajustes de la app';

  @override
  String get memorySaved => 'Recuerdo guardado';

  @override
  String get proSearch => 'Búsqueda Pro';

  @override
  String get webSearchLabel => 'Búsqueda web';

  @override
  String get readUrl => 'Leer URL';

  @override
  String get code => 'código';

  @override
  String couldNotOpenFile(String error) {
    return 'No se pudo abrir el archivo: $error';
  }

  @override
  String get tapOpenExternal =>
      'Toca \"Abrir con app externa\" para ver este archivo';

  @override
  String get proSearchEnabled => 'Búsqueda Pro activada';

  @override
  String get proSearchDisabled => 'Búsqueda Pro desactivada';

  @override
  String get thinkingEnabled => 'Pensamiento activado en este chat';

  @override
  String get thinkingDisabled => 'Pensamiento desactivado en este chat';

  @override
  String get codeSandbox => 'Sandbox de código';

  @override
  String get codeSandboxSubtitle =>
      'Ejecuta Python o JavaScript en un sandbox seguro';

  @override
  String get codeSandboxEnabled => 'Sandbox de código activado';

  @override
  String get codeSandboxDisabled => 'Sandbox de código desactivado';

  @override
  String get searxngNotConfigured => 'Añade una URL de SearXNG para activar';

  @override
  String get searxngConfiguredOff =>
      'Configurado — toca para usar en lugar de Búsqueda Pro';

  @override
  String get searxngConfigureFirst =>
      'Configura una URL de SearXNG antes de activar';

  @override
  String get editSearxng => 'Editar SearXNG';

  @override
  String get toolCallingLabel => 'Llamada a herramientas';

  @override
  String get on => 'Act.';

  @override
  String get off => 'Desact.';

  @override
  String get aiCanUseTools => 'La IA puede usar herramientas en este chat';

  @override
  String get toolsDisabledChat => 'Herramientas desactivadas para este chat';

  @override
  String get webSearchChat => 'Búsqueda web';

  @override
  String get aiCanSearchWeb => 'La IA puede buscar en la web en este chat';

  @override
  String get webSearchDisabledChat => 'Búsqueda web desactivada para este chat';

  @override
  String get disableMemory => 'Desactivar memoria';

  @override
  String memoryItemsActive(int count) {
    return '$count elementos de memoria activos';
  }

  @override
  String get memoryDisabledChat =>
      'La memoria está desactivada para este chat. La IA no verá tus recuerdos guardados.';

  @override
  String get lmStudioLocal => 'LM Studio (Local)';

  @override
  String get modelNoLongerAvailable =>
      'El modelo seleccionado anteriormente ya no está disponible. Por favor, selecciona uno nuevo.';

  @override
  String get noModelsForProvider =>
      'No se encontraron modelos para este proveedor. Verifica la clave API.';

  @override
  String get noModelsCheckConnection =>
      'No se encontraron modelos. Verifica la conexión de LM Studio.';

  @override
  String get selectModel => 'Seleccionar modelo';

  @override
  String get goToModels => 'Ir a modelos';

  @override
  String get reviewImagePrompt => 'Revisar prompt de imagen';

  @override
  String get editImagePromptHint => 'Editar prompt de imagen...';

  @override
  String get generate => 'Generar';

  @override
  String get imageNotFound => 'Imagen no encontrada';

  @override
  String get cameraPermissionNeeded => 'Se necesita permiso de cámara';

  @override
  String get cameraPermissionExplain =>
      'Por favor, permite el acceso a la cámara para tomar fotos para el análisis de visión.';

  @override
  String get photosPermissionNeeded => 'Se necesita permiso de fotos';

  @override
  String get photosPermissionExplain =>
      'Por favor, permite el acceso a tus imágenes para el análisis de visión.';

  @override
  String couldNotOpenFilePicker(String error) {
    return 'No se pudo abrir el selector de archivos: $error';
  }

  @override
  String get filePickerCouldNotCopy =>
      'No se pudo copiar ese archivo. Guárdalo en el teléfono (no Drive ni Recientes) y elígelo de nuevo.';

  @override
  String get signInToUseCloudBackup =>
      'Inicia sesión para usar la copia de seguridad en la nube';

  @override
  String get cloudBackupRequiresAccount =>
      'La copia de seguridad en la nube requiere una cuenta para que tus copias cifradas se almacenen de forma segura bajo tu identidad.';

  @override
  String get arguments => 'Argumentos';

  @override
  String get selectLanguage => 'Seleccionar idioma';

  @override
  String get connectionPopupTitle => 'Sin conexión';

  @override
  String get connectionPopupBody =>
      'LM Mini no pudo conectarse a LM Studio.\nVe a Ajustes para introducir la dirección de tu servidor.';

  @override
  String get connectionPopupDismiss => 'Más tarde';

  @override
  String get connectionPopupGoToSettings => 'Ir a Ajustes';

  @override
  String get remoteAccess => 'Acceso Remoto';

  @override
  String get scanQrCode => 'Escanear código QR';

  @override
  String get connectedViaLmConnect => 'Conectado vía LM Connect';

  @override
  String get disconnectRemoteToChangeSettings =>
      'LM Studio está emparejado vía LM Connect';

  @override
  String get disconnect => 'Desconectar';

  @override
  String get unpair => 'Desvincular';

  @override
  String get useRemoteConnection => 'Chatear con este Mac';

  @override
  String get useRemoteConnectionOffSubtitle =>
      'Desactivado: este teléfono usa sus propios modelos. Actívalo para usar los de LM Mini Home.';

  @override
  String get connectedViaLmStudio => 'Conectado vía LM Studio';

  @override
  String get usingLocalServer => 'Usando servidor local';

  @override
  String get testing => 'Probando...';

  @override
  String connectedLatency(int ms) {
    return 'Conectado — ${ms}ms';
  }

  @override
  String get notConnected => 'No conectado';

  @override
  String get scanQrDescription =>
      'Escanea un código QR de la app de escritorio LM Mini Connect para conectarte a tu LM Studio desde cualquier lugar.';

  @override
  String get remotePaired => 'Remoto vinculado';

  @override
  String lastConnected(String time) {
    return 'Última conexión: $time';
  }

  @override
  String get reScanQrCode => 'Re-escanear código QR';

  @override
  String get qrRequiresPro => 'Escanear código QR requiere LM Mini Pro';

  @override
  String get enterUrlManually => 'Introducir URL manualmente';

  @override
  String get enterUrlManuallySubtitle =>
      'Pega un enlace de emparejamiento si la cámara no está disponible';

  @override
  String get relayUrlHint => 'https://relay.lmmini.com/s/…';

  @override
  String get connectWithUrl => 'Conectar con URL';

  @override
  String get invalidRelayUrl =>
      'Ese no es un enlace de emparejamiento válido de LM Mini. Cópialo en Compartir con el teléfono en tu Mac.';

  @override
  String get invalidQrCode =>
      'Código QR inválido. Usa la app LM Mini Connect para generar uno.';

  @override
  String get pointCameraAtQr =>
      'Apunta tu cámara al código QR mostrado en la app de escritorio LM Mini Connect';

  @override
  String get connectedToRemoteLmStudio => '¡Conectado a LM Studio remoto!';

  @override
  String get failedToConnect =>
      'Error de conexión. Asegúrate de que LM Mini Connect esté ejecutándose.';

  @override
  String get unpairRemote => 'Desvincular remoto';

  @override
  String get unpairRemoteDescription =>
      'Esto eliminará la conexión remota guardada. Puedes volver a vincular escaneando un nuevo código QR.';

  @override
  String get setupGuide => 'Guía de configuración';

  @override
  String get downloadLmMiniConnect => 'Obtener LM Mini Home';

  @override
  String get availableForPlatforms =>
      'Descarga directa para Mac · Connect para Windows y Linux';

  @override
  String get setupStep1Title => 'Descargar LM Mini Home';

  @override
  String get setupStep1Desc =>
      'Descarga LM Mini Home para Mac desde lmmini.com. En Windows y Linux puedes seguir usando LM Mini Connect.';

  @override
  String get setupStep2Title => 'Compartir con el teléfono';

  @override
  String get setupStep2Desc =>
      'En LM Mini Home en tu Mac, abre Compartir con el teléfono y actívalo. Se conecta al relé al instante.';

  @override
  String get setupStep3Title => 'Escanear código QR';

  @override
  String get setupStep3Desc =>
      'Escanea el código QR que muestra LM Mini Home en tu Mac. ¡Listo!';

  @override
  String minutesAgo(int count) {
    return 'hace ${count}min';
  }

  @override
  String hoursAgo(int count) {
    return 'hace ${count}h';
  }

  @override
  String daysAgo(int count) {
    return 'hace ${count}d';
  }

  @override
  String get selectAll => 'Seleccionar todo';

  @override
  String get moveToFolder => 'Mover a carpeta';

  @override
  String get select => 'Seleccionar';

  @override
  String get dismissAction => 'Descartar';

  @override
  String get createNewFolder => 'Crear nueva carpeta';

  @override
  String deleteConversations(int count) {
    return '¿Eliminar $count conversación(es)? Esto no se puede deshacer.';
  }

  @override
  String get averages => 'PROMEDIOS';

  @override
  String get tokensPerChat => 'Tokens / Chat';

  @override
  String get msgsPerChat => 'Msgs / Chat';

  @override
  String get tokensPerMsg => 'Tokens / Msg';

  @override
  String get topModel => 'Modelo principal';

  @override
  String get liveActivityTitle => 'Live Activity';

  @override
  String get liveActivityTitleAndroid => 'Generación en segundo plano';

  @override
  String get liveActivityDescription =>
      'Procesa tu solicitud de IA incluso cuando sales de la app o bloqueas el teléfono';

  @override
  String get liveActivityDescriptionAndroid =>
      'Sigue generando al salir de la app. Muestra el progreso en una notificación persistente e impide que Android detenga el modelo a mitad de respuesta.';

  @override
  String get liveActivityAndroidOnDeviceOnly =>
      'Cambia a un modelo GGUF o MLX en el dispositivo para usar la generación en segundo plano en Android.';

  @override
  String get liveActivityNotificationDenied =>
      'Se requiere permiso de notificaciones para la generación en segundo plano en Android.';

  @override
  String get premiumRemoteAccess => 'Acceso Remoto';

  @override
  String get premiumRemoteAccessTagline => 'LM Studio desde cualquier lugar';

  @override
  String get premiumRemoteAccessDescription =>
      'Accede a tu LM Studio local desde cualquier lugar con LM Mini Connect. Sin reenvío de puertos ni VPN — solo escanea un código QR y conéctate de forma segura.';

  @override
  String get premiumLiveActivity => 'Live Activity';

  @override
  String get premiumLiveActivityTagline => 'La IA funciona en segundo plano';

  @override
  String get premiumLiveActivityDescription =>
      'Procesa tu solicitud de IA incluso cuando sales de la app o bloqueas el teléfono. Ve el progreso en tu pantalla de bloqueo y Dynamic Island.';

  @override
  String get premiumWebSearchTagline => 'Sin configuración de servidor';

  @override
  String get premiumWebSearchDescription =>
      'Busca en la web al instante durante las conversaciones. Impulsado por APIs de búsqueda en la nube.';

  @override
  String get premiumCloudBackup => 'Copia de seguridad cifrada';

  @override
  String get premiumCloudBackupTagline => 'Cifrado AES-256-GCM';

  @override
  String get premiumCloudBackupDescription =>
      'Respalda todas las conversaciones en la nube con cifrado de grado militar. Tu contraseña nunca sale de tu dispositivo.';

  @override
  String get premiumUrlReader => 'Lector de URL';

  @override
  String get premiumUrlReaderTagline => 'Analiza cualquier página web';

  @override
  String get premiumUrlReaderDescription =>
      'Pega cualquier URL y tu modelo lee el contenido completo de la página.';

  @override
  String get premiumBranching => 'Ramificación de conversaciones';

  @override
  String get premiumBranchingTagline => 'Explora caminos alternativos';

  @override
  String get premiumBranchingDescription =>
      'Bifurca cualquier conversación desde cualquier punto para explorar escenarios \"qué pasaría si\".';

  @override
  String get premiumMemory => 'Memorias';

  @override
  String get premiumMemoryTagline => 'Te recuerda entre chats';

  @override
  String get premiumMemoryDescription =>
      'Guarda hechos, preferencias y contexto que persisten en todas las conversaciones.';

  @override
  String get premiumAnalytics => 'Panel de análisis';

  @override
  String get premiumAnalyticsTagline => 'Conoce tu uso';

  @override
  String get premiumAnalyticsDescription =>
      'Rastrea tokens usados, mensajes enviados, uso de modelos y tiempos de respuesta promedio.';

  @override
  String get premiumCloudApi => 'Proveedores Cloud API';

  @override
  String get premiumCloudApiTagline => 'Mistral, Anthropic y más';

  @override
  String get premiumCloudApiDescription =>
      'Conecta proveedores de LLM en la nube junto a tus modelos locales.';

  @override
  String get premiumExport => 'Exportar y Compartir';

  @override
  String get premiumExportTagline => 'Obsidian, Notas, Notion y más';

  @override
  String get premiumExportDescription =>
      'Exporta conversaciones como Markdown, PDF o texto plano con formato.';

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
      'Modelos de catálogo más grandes e importación HF';

  @override
  String get premiumOnDeviceLlmDescription =>
      'El chat en el dispositivo es gratis con modelos iniciales curados. Pro desbloquea descargas del catálogo por encima de 2B parámetros e importar tus propios modelos GGUF o MLX desde Hugging Face — totalmente sin conexión.';

  @override
  String get premiumHfBrowse => 'Importación de Hugging Face';

  @override
  String get premiumHfBrowseTagline => 'Trae cualquier modelo GGUF';

  @override
  String get premiumHfBrowseDescription =>
      'Busca en Hugging Face, descarga modelos GGUF a tu dispositivo o servidor LM Studio y úsalos en LM Mini. Filtra compatibilidad, sigue descargas en segundo plano y ve más allá del catálogo gratuito — sin clave API.';

  @override
  String get onDeviceProviderLabel => 'En el dispositivo';

  @override
  String get onDeviceManageModels => 'Gestionar modelos en el dispositivo';

  @override
  String get onDeviceGeneratingHint => 'Generando en el dispositivo…';

  @override
  String get onDeviceEngineUnavailable =>
      'Motor en el dispositivo no disponible';

  @override
  String get onDeviceOpenBrowser => 'Abrir modelos en el dispositivo';

  @override
  String get onDeviceManagedHere =>
      'Los modelos en el dispositivo se gestionan en un explorador dedicado donde puedes descargar, eliminar y activar.';

  @override
  String get onDeviceRemoteImageOnly =>
      'IA en el dispositivo seleccionada: el acceso remoto solo potencia la generación de imágenes y Kokoro (si está configurado). El chat sigue en este dispositivo.';

  @override
  String get onDeviceProOnly => 'Solo Pro';

  @override
  String get onDeviceInstalled => 'Instalado';

  @override
  String get onDeviceUseModel => 'Usar';

  @override
  String get onDeviceRemoveModel => 'Eliminar';

  @override
  String get onDeviceDownloadAnyway => 'Descargar de todos modos';

  @override
  String onDeviceNowUsing(String name) {
    return 'Ahora usando $name en el dispositivo';
  }

  @override
  String get onDeviceEngineFllamaLabel => 'fllama (GGUF)';

  @override
  String onDeviceEngineSwitched(String engine) {
    return 'Cambiado a $engine. Se descargó el modelo anterior.';
  }

  @override
  String onDeviceEngineSwitchedCleared(String engine) {
    return 'Cambiado a $engine. El modelo anterior no es compatible y se deseleccionó — elige uno en Modelos en el dispositivo.';
  }

  @override
  String get onDeviceImportedLabel => 'Importado';

  @override
  String get onDeviceFreeLabel => 'Gratis';

  @override
  String get onDeviceProLabel => 'Pro';

  @override
  String get onDeviceMayCrashLabel => 'Puede fallar';

  @override
  String get onDeviceModelMayCrashTitle => 'Este modelo puede fallar';

  @override
  String onDeviceModelMayCrashMessage(
      String name, String runtimeGb, String deviceRamGb) {
    return '$name necesita aproximadamente $runtimeGb GB de memoria en ejecución. Tu dispositivo tiene unos $deviceRamGb GB disponibles para apps. Cargarlo puede congelar o bloquear la app.';
  }

  @override
  String get onDeviceContinueLoading => 'Continuar cargando';

  @override
  String get yearly => 'Anual';

  @override
  String get monthly => 'Mensual';

  @override
  String get lifetime => 'De por vida';

  @override
  String get subscriptionLifetimeBadge => 'Paga una vez';

  @override
  String get subscriptionLifetimeDisclaimer =>
      'Compra única. Funciones Pro en tu cuenta mientras LM Mini se ofrezca y mantenga. No incluye tarifas de API de terceros ni servicios alojados por separado — consulta los Términos.';

  @override
  String subscriptionLifetimeUpgradeDisclaimer(String store) {
    return 'Lifetime es una compra única aparte. Tu suscripción actual no se cancelará automáticamente y no podemos reembolsar cargos anteriores. Después de comprar, cancela tu suscripción en $store.';
  }

  @override
  String get subscriptionUpgradeToLifetime => 'Actualizar a Lifetime';

  @override
  String subscriptionUpgradeToLifetimeSubtitle(String price) {
    return 'Paga una vez — $price';
  }

  @override
  String get duplicateSubscriptionDialogTitle => 'Cancela tu suscripción';

  @override
  String duplicateSubscriptionDialogBody(String store) {
    return 'Tienes Pro Lifetime y una suscripción activa. Lifetime no reemplaza tu suscripción automáticamente y no podemos reembolsar cargos de suscripción. Cancela tu suscripción en $store para evitar más cobros.';
  }

  @override
  String duplicateSubscriptionDialogManage(String store) {
    return 'Abrir $store';
  }

  @override
  String get duplicateSubscriptionDialogDismiss => 'Entendido';

  @override
  String get duplicateSubscriptionNoManageUrl =>
      'Abre los ajustes de suscripción de tu dispositivo para cancelar.';

  @override
  String supportLifetime(String price) {
    return 'Desbloquear para siempre — $price';
  }

  @override
  String get encryptionKey => 'Clave de cifrado';

  @override
  String get encryptionEnabled => 'Cifrado: Activado';

  @override
  String get encryptionDisabled => 'Cifrado: Desactivado';

  @override
  String get encryptionKeyDescription =>
      'Clave de cifrado de extremo a extremo para acceso remoto. Debe coincidir con la clave en LM Mini Connect.';

  @override
  String get editEncryptionKey => 'Editar clave de cifrado';

  @override
  String get enterEncryptionKey => 'Ingresar clave de cifrado';

  @override
  String get encryptionKeyUpdated => 'Clave de cifrado actualizada';

  @override
  String get keepLmMiniAlive => 'Mantén LM Mini\ncon vida';

  @override
  String get supportTheApp => 'Apoya la app y obtén beneficios premium';

  @override
  String get mostFeaturesFree =>
      'La mayoría de funciones son gratis — Pro ayuda a cubrir los costos del servidor';

  @override
  String get thankYouSupport => '¡Gracias por tu apoyo!';

  @override
  String get helpingKeepAlive => 'Estás ayudando a mantener LM Mini con vida';

  @override
  String get linkSignInMethod =>
      'Vincula un método de inicio de sesión para conservar tu suscripción si cambias de dispositivo.';

  @override
  String get paywallLinkAccountBody =>
      'Estás en una cuenta anónima. Vincula Apple o Google antes de comprar para que Pro se sincronice entre dispositivos y sobreviva a reinstalar.';

  @override
  String get continueAnonymously => 'Continuar anónimamente';

  @override
  String signedInViaMethod(String method) {
    return 'Conectado vía $method';
  }

  @override
  String get yourSubscriptionSecured => 'Tu suscripción está asegurada';

  @override
  String subscriptionManagedThrough(String store) {
    return 'Suscripción gestionada a través de $store.';
  }

  @override
  String get subscriptionsComingSoon => 'Suscripciones próximamente';

  @override
  String get premiumPreview =>
      'Las funciones premium están siendo finalizadas.\nPuedes activar el modo desarrollador abajo para previsualizarlas.';

  @override
  String get enableDeveloperPremium => 'Activar Premium de desarrollador';

  @override
  String get disableDeveloperPremium => 'Desactivar Premium de desarrollador';

  @override
  String get premiumEnabled => 'Premium activado (override de desarrollador)';

  @override
  String get premiumDisabled => 'Premium desactivado';

  @override
  String supportYearly(String price) {
    return 'Apoyar — $price/año';
  }

  @override
  String supportMonthly(String price) {
    return 'Apoyar — $price/mes';
  }

  @override
  String get welcomeToLmMiniPro => '¡Bienvenido a LM Mini Pro!';

  @override
  String get connectedRemotely => 'Conectado remotamente';

  @override
  String get pairedNotActive => 'Vinculado — no activo';

  @override
  String get accessLmStudioAnywhere =>
      'Accede a LM Studio desde cualquier lugar';

  @override
  String get appStore => 'App Store';

  @override
  String get googlePlayStore => 'Google Play Store';

  @override
  String get starterAttach => 'Adjuntar';

  @override
  String get starterImages => 'Imágenes';

  @override
  String get starterMode => 'Modo';

  @override
  String get newGroupChat => 'Nuevo chat grupal';

  @override
  String get groupChat => 'Chat grupal';

  @override
  String get groupChatMultipleModels => 'Chatea con múltiples modelos';

  @override
  String get groupChatParticipants => 'Participantes';

  @override
  String get groupChatTurnMode => 'Modo de turno';

  @override
  String get groupChatRoundRobin => 'Por turnos';

  @override
  String get groupChatManual => 'Manual';

  @override
  String get groupChatParallelStreaming => 'Streaming paralelo';

  @override
  String get groupChatAutoLoadUnload => 'Carga/descarga automática';

  @override
  String get groupChatStreamAllSimultaneously =>
      'Transmitir todos los participantes simultáneamente';

  @override
  String get groupChatAutoLoadModels =>
      'Cargar modelos automáticamente cuando sea necesario';

  @override
  String get groupChatAsk => 'Preguntar:';

  @override
  String get groupChatTapToReplyNudge => 'Toca quién debe responder';

  @override
  String get groupChatTrialBannerTitle =>
      'Chat en grupo — ¡Gratis durante 7 días!';

  @override
  String get groupChatTrialBannerBody =>
      'Prueba el chat en grupo gratis durante 7 días con hasta 2 personas de IA. Actualiza a LM Mini Pro para acceso ilimitado.';

  @override
  String groupChatTrialDaysLeft(int days) {
    return '$days días restantes en tu prueba';
  }

  @override
  String get groupChatTrialExpired =>
      'Tu prueba de 7 días de chat en grupo ha terminado. Actualiza a Pro para continuar.';

  @override
  String get groupChatTrialGetPro => 'Obtener Pro';

  @override
  String get groupChatTrialDismiss => 'Entendido';

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
  String get premiumGroupChat => 'Chat en grupo';

  @override
  String get premiumGroupChatTagline => 'Conversaciones multi-persona';

  @override
  String get premiumGroupChatDescription =>
      'Chatea con varias personas de IA en un hilo — cada una con su modelo, avatar y personalidad. Configura gratis; enviar mensajes requiere LM Mini Pro.';

  @override
  String get groupChatProRequiredTitle => 'El chat grupal requiere Pro';

  @override
  String get groupChatProRequiredBody =>
      'Puedes explorar la configuración y leer conversaciones anteriores gratis. Actualiza a LM Mini Pro para enviar mensajes y seguir chateando con varias personas de IA.';

  @override
  String get groupChatProRequiredUpgrade => 'Actualizar a Pro';

  @override
  String get groupChatLockedBanner =>
      'El chat grupal es de solo lectura sin Pro. Actualiza para enviar mensajes.';

  @override
  String get premiumArena => 'Arena';

  @override
  String get premiumArenaTagline => 'Compara modelos lado a lado';

  @override
  String get premiumArenaDescription =>
      'Ejecuta el mismo prompt en varios modelos y compara respuestas, velocidad y compatibilidad con tu dispositivo. El modo benchmark puntúa modelos con una rúbrica transparente.';

  @override
  String get startLabel => 'Iniciar';

  @override
  String groupChatInviteUpTo(int count) {
    return 'Invita hasta $count modelos de IA a conversar juntos. Cada uno puede tener su propia personalidad, avatar y prompt del sistema.';
  }

  @override
  String get groupChatPremiumParticipantsNote =>
      'Premium permite hasta 5 participantes por chat grupal.';

  @override
  String get groupChatUserNameHint =>
      'Cómo se dirigirán a ti las IAs (p. ej. Alex)';

  @override
  String get groupChatScenarioLabel => 'Escenario / sobre ti (opcional)';

  @override
  String get groupChatScenarioHint =>
      'p. ej. «Somos colegas en una startup tecnológica. Soy gerente de producto y le pido consejo al equipo.»';

  @override
  String get groupChatTurnModeRoundRobinDescription =>
      'Por turnos: todos los modelos responden en orden';

  @override
  String get groupChatTurnModeManualDescription =>
      'Manual: escribe @Nombre para elegir quién responde';

  @override
  String get groupChatReplyToUserOnlyLabel => 'Responder solo al usuario';

  @override
  String get groupChatReplyToUserOnlySubtitle =>
      'Cada IA ignora a las demás; evita conversaciones cruzadas en modelos pequeños';

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
      'No hay modelos disponibles. Conéctate primero a LM Studio.';

  @override
  String get addModelLabel => 'Añadir modelo';

  @override
  String modelNumber(int number) {
    return 'Modelo $number';
  }

  @override
  String groupChatParticipantInfo(String name, String model) {
    return '$name\nModelo: $model';
  }

  @override
  String get customPromptSet => 'Prompt personalizado configurado';

  @override
  String get removeLabel => 'Quitar';

  @override
  String get displayNameLabel => 'Nombre para mostrar';

  @override
  String get displayNameHint => 'p. ej. Profesor, Programador, Artista';

  @override
  String get customRequestHeaders => 'Encabezados de solicitud personalizados';

  @override
  String get customRequestHeadersSubtitle =>
      'Encabezados opcionales añadidos a cada solicitud de LM Studio';

  @override
  String get customRequestHeadersHelp =>
      'Úsalo para proxies inversos o pasarelas de autenticación que requieren encabezados adicionales (por ejemplo, tokens de servicio de Cloudflare Access, un token interno con un nombre de encabezado personalizado, etc.). Los encabezados se envían en cada solicitud a tu servidor de LM Studio.';

  @override
  String get cloudflareAccessSection => 'Cloudflare Access (token de servicio)';

  @override
  String get cloudflareAccessHelp =>
      'Si tu LM Studio está detrás de una política de Cloudflare Access, pega aquí el ID de cliente y el secreto del token de servicio. Se envían como CF-Access-Client-Id y CF-Access-Client-Secret en cada solicitud, para que la app pueda autenticarse sin un inicio de sesión SSO interactivo en el navegador.';

  @override
  String get cfAccessClientIdLabel => 'CF-Access-Client-Id';

  @override
  String get cfAccessClientSecretLabel => 'CF-Access-Client-Secret';

  @override
  String get addHeader => 'Añadir encabezado';

  @override
  String get removeHeader => 'Quitar encabezado';

  @override
  String get headerNameLabel => 'Nombre del encabezado';

  @override
  String get headerValueLabel => 'Valor del encabezado';

  @override
  String headersConfigured(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count encabezados configurados',
      one: '1 encabezado configurado',
    );
    return '$_temp0';
  }

  @override
  String get noCustomHeaders => 'Sin encabezados personalizados';

  @override
  String get comfyUiUseNegativePromptTitle => 'Usar prompt negativo';

  @override
  String get comfyUiUseNegativePromptSubtitle =>
      'Desactivado por defecto para ComfyUI. Cuando está desactivado, no se envía un prompt negativo al flujo de trabajo.';

  @override
  String get documentationTitle => 'Documentación';

  @override
  String get documentationSubtitle =>
      'Guías de configuración para Chat Grupal, ComfyUI, comportamiento del teclado y más';

  @override
  String get changelogTitle => 'Registro de cambios';

  @override
  String get changelogSubtitle => 'Historial de versiones y actualizaciones';

  @override
  String get enableCustomHeaders => 'Activar encabezados personalizados';

  @override
  String get enableCustomHeadersSubtitle =>
      'Adjuntar encabezados HTTP adicionales a cada solicitud de LM Studio';

  @override
  String deleteMemoriesCount(int count) {
    return '¿Eliminar $count recuerdos?';
  }

  @override
  String get deleteMemoriesConfirm =>
      'Estos recuerdos se eliminarán de forma permanente.';

  @override
  String get moveToCategory => 'Mover a categoría';

  @override
  String nSelected(int count) {
    return '$count seleccionados';
  }

  @override
  String movedToCategory(String category) {
    return 'Movido a $category';
  }

  @override
  String get moveCategoryTooltip => 'Mover categoría';

  @override
  String get memoryScreenSubtitle =>
      'Hechos que la IA recuerda sobre ti en todos los chats.';

  @override
  String get rememberMe => 'Recuérdame';

  @override
  String get rememberMeSubtitle =>
      'Usar notas guardadas en futuras conversaciones';

  @override
  String get memoryPerPersona => 'Por persona';

  @override
  String get memoryPerPersonaSubtitle =>
      'Compartir notas solo con la persona activa (y las globales)';

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
  String get memoryBrowseSection => 'Explorar';

  @override
  String get memoryMultiSelectTip =>
      'Consejo: mantén pulsada una nota para seleccionar varias.';

  @override
  String get memoryEmptyFilteredHint =>
      'Añade una nota o elige otra categoría.';

  @override
  String get memoryEmptyHint =>
      'Guarda algunas cosas sobre ti — nombre, preferencias, proyectos — para que los chats se sientan personales.';

  @override
  String get memoryShareWith => 'Compartir con';

  @override
  String get memoryEveryone => 'Todos';

  @override
  String get memoryEveryoneSubtitle => 'Disponible en cada chat';

  @override
  String get memoryNoPersonasHint =>
      'Aún no hay personas. Crea una en Ajustes → Personas.';

  @override
  String get memoryNewNote => 'Nueva nota';

  @override
  String get memoryNoteHint =>
      'p. ej. Prefiero respuestas cortas y vivo en Berlín';

  @override
  String get memoryEditNote => 'Editar nota';

  @override
  String monthsAgo(int count) {
    return 'hace $count mes.';
  }

  @override
  String get moreTooltip => 'Más';

  @override
  String get closeSearch => 'Cerrar búsqueda';

  @override
  String get moveTooltip => 'Mover';

  @override
  String get chatsTab => 'Chats';

  @override
  String get groupsTab => 'Grupos';

  @override
  String get foldersTooltip => 'Carpetas';

  @override
  String get newFolder => 'Nueva carpeta';

  @override
  String get tapToReturnToCall => 'Toca para volver a la llamada';

  @override
  String get selectConversation => 'Selecciona una conversación';

  @override
  String get selectConversationHint =>
      'Elige una de la lista o inicia un chat nuevo.';

  @override
  String get noGroupChatsYet => 'Aún no hay chats grupales';

  @override
  String get noGroupChatsSubtitle =>
      'Inicia una conversación multipersona para chatear con varias IAs.';

  @override
  String get newPersonaShort => 'Nueva';

  @override
  String get downloadOnDeviceModelTitle =>
      'Descargar un modelo en el dispositivo';

  @override
  String get downloadOnDeviceModelBody =>
      'Descarga un modelo para chatear sin PC, o conecta LM Studio / Ollama.';

  @override
  String get browseModels => 'Explorar modelos';

  @override
  String get waitingForMac => 'Esperando al Mac';

  @override
  String get waitingForMacBody =>
      'Conecta tu iPhone al Mac con USB y abre LM Mini Connect en el Mac.';

  @override
  String get arenaMode => 'Modo Arena';

  @override
  String get voiceWhisperSizeInfoTitle => 'Los modelos grandes oyen mejor';

  @override
  String get voiceWhisperSizeInfoBody =>
      'Los modelos de escucha más grandes suelen ser más precisos, sobre todo con acentos y ruido. También usan más almacenamiento y pueden cargar un poco más lento.';

  @override
  String get voiceRemoveListeningModelTitle => '¿Quitar el modelo de escucha?';

  @override
  String get voiceRemoveListeningModelBody =>
      'Esto libera espacio. Voice Call y el micrófono necesitarán el modelo de nuevo para la escucha sin conexión.';

  @override
  String get voiceTtsOnDeviceNeural => 'Voz descargada';

  @override
  String get voiceTtsPcVoice => 'Voz del PC';

  @override
  String get voiceTtsSystemVoice => 'Voz del sistema';

  @override
  String get voiceTtsOnDeviceHint =>
      'Voces naturales que descargas. Funciona sin internet.';

  @override
  String get voiceTtsPcHint =>
      'Usar un modelo de voz en el ordenador vía Compartir con el teléfono';

  @override
  String get voiceTtsSystemHint => 'Las voces de tu teléfono — listas ahora';

  @override
  String get voiceSttOnDevice => 'En este dispositivo';

  @override
  String get voiceSttWhisperHint =>
      'Modelo sin conexión — suele ser más preciso';

  @override
  String get voiceSttSystemHint =>
      'Reconocimiento integrado — rápido y sencillo';

  @override
  String get voiceSttSystemUnavailableOnMac => 'Necesita descarga';

  @override
  String get voiceSttMacosRequiresWhisper =>
      'Las builds de App Store usan Whisper en el dispositivo para escuchar. Descarga un modelo para activarlo.';

  @override
  String get voiceSttMacosSystemOptionSubtitle =>
      'Descarga Whisper para activar la escucha';

  @override
  String get voiceSttMacosDownloadWhisper =>
      'Descarga Whisper para activar la escucha';

  @override
  String get voiceSettingsIntro =>
      'Cómo se hablan las respuestas y cómo se entiende tu voz.';

  @override
  String get voiceSectionReady => 'Listo';

  @override
  String get voiceSectionSpeaking => 'Hablar';

  @override
  String get voiceSectionListening => 'Escuchar';

  @override
  String get voiceSectionConversation => 'Conversación';

  @override
  String get voiceStatusSpeaking => 'Hablar';

  @override
  String get voiceStatusListening => 'Escuchar';

  @override
  String get voiceHowISpeak => 'Cómo hablo';

  @override
  String get voiceImportPack => 'Importar paquete de voz';

  @override
  String get voiceImportPackSubtitle =>
      'Pega una URL de GitHub a un paquete de voz';

  @override
  String get voiceHowIHearYou => 'Cómo te oigo';

  @override
  String get voiceHowIHearYouSubtitle =>
      'Elige cómo tu voz se convierte en texto.';

  @override
  String get voiceListeningModel => 'Modelo de escucha';

  @override
  String get voiceAboutModelSizes => 'Sobre tamaños de modelo';

  @override
  String get voicePauseBeforeSend => 'Pausa antes de enviar';

  @override
  String get voicePauseBeforeSendSubtitle =>
      'Cuánto esperar después de que dejes de hablar';

  @override
  String get voiceListeningLimit => 'Límite de escucha';

  @override
  String get voiceListeningLimitSubtitle =>
      'Tramo más largo antes de reiniciar el micrófono';

  @override
  String get voiceQuickTip => 'Consejo rápido';

  @override
  String get voiceQuickTipBody =>
      'Para una voz más natural, descarga un idioma en Paquetes de voz. La voz del sistema funciona de inmediato.';

  @override
  String get voiceTestSampleHint =>
      'Escucha una muestra corta con tu configuración actual';

  @override
  String get voiceTestNoPackReady =>
      'Descarga un idioma en Paquetes de voz y vuelve a probar Test Voice.';

  @override
  String get voiceChooseListeningModel =>
      'Toca para elegir un modelo de escucha';

  @override
  String get voiceModelReady => 'Listo';

  @override
  String get voiceNeedsDownload => 'Necesita descarga';

  @override
  String get voiceDownloaded => 'Descargado';

  @override
  String get voiceDownloadFailed => 'Error de descarga';

  @override
  String get voiceFinishingSetup => 'Terminando la configuración…';

  @override
  String get voiceDownloadingListeningModel => 'Descargando modelo de escucha…';

  @override
  String get voiceDownloadingVoice => 'Descargando voz…';

  @override
  String get voiceStartingDownload => 'Iniciando descarga…';

  @override
  String get voiceReady => 'Voz lista';

  @override
  String get voiceWarmingUp => 'Preparando…';

  @override
  String get voiceReadyToSpeak => 'Lista para hablar';

  @override
  String get voiceDownloadOnDevice => 'Descargar voz en el dispositivo';

  @override
  String get voiceDownloadFailedRetry =>
      'Error de descarga — toca para reintentar';

  @override
  String get voiceSpokenReplyLanguage => 'Idioma de respuestas habladas';

  @override
  String get voiceSpokenReplyLanguageSubtitle =>
      'Idioma al leer mensajes en voz alta.';

  @override
  String get voiceRecognitionLanguage => 'Idioma de reconocimiento';

  @override
  String get voiceRecognitionLanguageSubtitle =>
      'Para el micrófono de texto y Voice Call — puede diferir de las respuestas habladas.';

  @override
  String get voiceEngineTitle => 'Voz hablada';

  @override
  String get voiceEngineSubtitle => 'Elige de dónde viene la voz hablada.';

  @override
  String get voiceChooseAVoice => 'Elegir una voz';

  @override
  String get voiceChooseAVoiceSubtitle =>
      'Nombres fáciles de previsualizar para voz en el dispositivo.';

  @override
  String get voiceUseSystemDefault => 'Usar la voz predeterminada del sistema';

  @override
  String get welcomeWizardTitleGetStarted => 'Empezar';

  @override
  String get welcomeWizardTitleYourSetup => 'Tu configuración';

  @override
  String get welcomeWizardTitleLookAndFeel => 'Apariencia';

  @override
  String get welcomeWizardTitleAlmostDone => 'Casi listo';

  @override
  String get welcomeWizardTitleSetup => 'Configuración';

  @override
  String get welcomeWizardLmStudioSubtitle => 'Ejecuta modelos en tu Mac o PC';

  @override
  String get welcomeWizardOllamaSubtitle => 'Servidor local popular';

  @override
  String get welcomeWizardOmlxSubtitle =>
      'Servidor de escritorio Apple Silicon';

  @override
  String get welcomeWizardJanSubtitle => 'Modelos locales de la app JAN AI';

  @override
  String get welcomeWizardUnslothSubtitle => 'Unsloth Desktop en tu ordenador';

  @override
  String get welcomeWizardThemeSubtitle =>
      'Elige un estilo. Puedes cambiarlo cuando quieras.';

  @override
  String get welcomeWizardModelReady => 'Listo';

  @override
  String get welcomeWizardConnected => 'Conectado';

  @override
  String get welcomeWizardServerFound => 'Servidor encontrado';

  @override
  String get welcomeWizardRequiresApiKey => 'Requiere clave API';

  @override
  String get welcomeWizardScanHomeQr => 'Escanear QR de LM Mini Home';

  @override
  String get welcomeWizardScanHomeQrSubtitle =>
      'Empareja con tu Mac desde Compartir con el teléfono';

  @override
  String welcomeWizardModelsFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count modelos encontrados',
      one: '1 modelo encontrado',
    );
    return '$_temp0';
  }

  @override
  String get welcomeWizardLocalNetworkTitle => 'Permitir acceso a la red';

  @override
  String get welcomeWizardLocalNetworkBody =>
      'Se te pedirá permitir el acceso a la red local. Acéptalo para que LM Mini pueda encontrar LM Mini Home, LM Studio u Ollama en tu ordenador.';

  @override
  String get welcomeWizardLocalNetworkAllow => 'Permitir';

  @override
  String get welcomeWizardDownloadKeepsGoing =>
      'Puedes salir de esta pantalla: la descarga sigue, incluso si sales de la app.';

  @override
  String get welcomeWizardDownloadFailed =>
      'La descarga falló. Toca para reintentar.';

  @override
  String get welcomeWizardAiDownloadingTitle => 'La IA se está descargando';

  @override
  String get welcomeWizardAiDownloadingBody =>
      'Podrás chatear en cuanto esté lista la IA perfecta para tu teléfono. Es una descarga única.';

  @override
  String get onDeviceModels => 'Modelos en el dispositivo';

  @override
  String get transcription => 'Transcripción';

  @override
  String get widgetSettings => 'Ajustes de widgets';

  @override
  String get widgetSettingsSubtitle =>
      'Configurar widgets de la pantalla de inicio';

  @override
  String get setUpShortcuts => 'Configurar atajos';

  @override
  String get shareArenaSpeedResults =>
      'Compartir resultados de velocidad de Arena';

  @override
  String get browseOnDeviceModels => 'Explorar modelos en el dispositivo';

  @override
  String get homeDownloadModel => 'Descargar modelo';

  @override
  String get usbMode => 'Modo USB';

  @override
  String get usbModeHowItWorks => 'Cómo funciona el modo USB';

  @override
  String get switchToUsbTitle => '¿Cambiar de Remoto a USB?';

  @override
  String get switchLabel => 'Cambiar';

  @override
  String usbModeStartFailed(String error) {
    return 'No se pudo iniciar el modo USB: $error';
  }

  @override
  String get usbModeHowToUse => 'Cómo usarlo:';

  @override
  String get openLmminiCom => 'Abrir lmmini.com';

  @override
  String get tapToUseServer => 'Toca para usar este servidor';

  @override
  String get memoryPersonaFallback => 'Persona';

  @override
  String get voicePickSystemVoiceSubtitle =>
      'Elige una voz integrada para las respuestas habladas.';

  @override
  String get chooseFromGallery => 'Elegir de la galería';

  @override
  String get galleryLimitsSubtitle => 'Fotos hasta 10 MB · Vídeos hasta 200 MB';

  @override
  String get recordVideo => 'Grabar un vídeo';

  @override
  String attachmentsCount(int count, int max) {
    return 'Adjuntos ($count/$max)';
  }

  @override
  String get viewProfile => 'Ver perfil';

  @override
  String get personaAndModel => 'Persona y modelo';

  @override
  String get chatOptions => 'Opciones del chat';

  @override
  String get chatTab => 'Chat';

  @override
  String get voiceTab => 'Voz';

  @override
  String get craftingPersona => 'Creando persona…';

  @override
  String get randomPersona => 'Sorpréndeme';

  @override
  String get savePersona => 'Guardar persona';

  @override
  String get downloadFinished => 'Descarga finalizada.';

  @override
  String get downloadCancelled => 'Descarga cancelada.';

  @override
  String get downloadCancelFailed =>
      'No se pudo cancelar en LM Studio. Deténla en la lista de descargas de LM Studio.';

  @override
  String get newsBriefing => 'Resumen de noticias';

  @override
  String get refreshNow => 'Actualizar ahora';

  @override
  String get noBriefingYet => 'Aún no hay resumen';

  @override
  String get newsSetPromptFirst =>
      'Configura primero un prompt del widget de Noticias en Ajustes de widgets.';

  @override
  String get newsRefreshed => 'Noticias actualizadas.';

  @override
  String newsRefreshFailed(String error) {
    return 'Error al actualizar: $error';
  }

  @override
  String get themesTitle => 'Temas';

  @override
  String get createLabel => 'Crear';

  @override
  String get browseLabel => 'Explorar';

  @override
  String get signInToUploadThemes => 'Inicia sesión para subir temas';

  @override
  String get deleteThemeTitle => '¿Eliminar tema?';

  @override
  String deleteThemeConfirm(String name) {
    return '¿Quitar \"$name\" de tus temas descargados?';
  }

  @override
  String get uploadToCommunity => 'Subir a la comunidad';

  @override
  String get installedLabel => 'Instalado';

  @override
  String get getLabel => 'Obtener';

  @override
  String get bestForYou => 'Ideal para ti';

  @override
  String get loadingLabel => 'Cargando';

  @override
  String get loadedLabel => 'Cargado';

  @override
  String get notLoadedLabel => 'No cargado';

  @override
  String get reasoningLabel => 'Razonamiento';

  @override
  String get imagesLabel => 'Imágenes';

  @override
  String get detailsTooltip => 'Detalles';

  @override
  String get transcribeAudio => 'Transcribir audio';

  @override
  String get transcribeAudioSubtitle =>
      'Sube audio y pregunta a la IA sobre la transcripción';

  @override
  String get trimSection => 'Recortar sección';

  @override
  String get includeTimestamps => 'Incluir marcas de tiempo';

  @override
  String get phrasesLabel => 'Frases';

  @override
  String get wordsLabel => 'Palabras';

  @override
  String get transcriptionLanguage => 'Idioma de transcripción';

  @override
  String get searchLanguages => 'Buscar idiomas…';

  @override
  String get transcribe => 'Transcribir';

  @override
  String get shareTranscript => 'Compartir transcripción';

  @override
  String get transcriptionContextLargeToast =>
      'Estas transcripciones pueden ser demasiado grandes para el contexto del modelo. Crea una rama desde un mensaje anterior si las respuestas quedan incompletas.';

  @override
  String get transcriptionSubtitlesOn => 'Subtítulos activados';

  @override
  String get transcriptionSubtitlesOff => 'Subtítulos desactivados';

  @override
  String get transcriptionFullClip => 'Audio completo';

  @override
  String get transcriptionJobRunning => 'Transcribiendo…';

  @override
  String get transcriptionJobDone => 'Transcrito';

  @override
  String get transcriptionJobFailed => 'Error de transcripción';

  @override
  String get branchFromHere => 'Ramificar desde aquí';

  @override
  String get memoryUpdates => 'Actualizaciones de memoria';

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
  String get personaShareMemoryCategoriesLabel => 'Categorías a compartir';

  @override
  String get personaShareMemoryCategoriesSubtitle =>
      'Elige qué tipos de memorias puede usar esta persona en los chats.';

  @override
  String get chooseFaceForBubbles => 'Elegir cara para las burbujas';

  @override
  String get moveMemories => 'Mover memorias';

  @override
  String get deletePersonaAndMemories => 'Eliminar persona + memorias';

  @override
  String get moveMemoriesTo => 'Mover memorias a…';

  @override
  String get globalSharedMemories =>
      'Global (compartido con todas las personas)';

  @override
  String personaMemoriesAssignedHint(int count, String name) {
    return '$count memoria(s) están asignadas a \"$name\".\nElige qué debe pasar con ellas:';
  }

  @override
  String get homeSyncTitle => '¿Mantener los chats sincronizados?';

  @override
  String homeSyncBodyBoth(int phoneChats, int macChats) {
    return 'Este teléfono tiene $phoneChats chats y LM Mini Home tiene $macChats. Activa la sincronización para unir conversaciones y carpetas y continuar en cualquier dispositivo. Usa tu relay cifrado existente.';
  }

  @override
  String get homeSyncBodyPhoneOnly =>
      'Copia chats y carpetas de este teléfono a LM Mini Home y manténlos sincronizados por el relay cifrado.';

  @override
  String get homeSyncBodyMacOnly =>
      'Trae chats y carpetas de LM Mini Home a este teléfono y manténlos sincronizados por el relay cifrado.';

  @override
  String get homeSyncBodyGeneric =>
      'Une conversaciones y carpetas entre este teléfono y LM Mini Home para continuar en cualquier dispositivo. Usa tu relay cifrado existente.';

  @override
  String get homeSyncEnable => 'Activar sincronización';

  @override
  String get homeSyncNotNow => 'Ahora no';

  @override
  String get homeSyncSettingsTitle => 'Sincronizar chats con Home';

  @override
  String get homeSyncSettingsSubtitle =>
      'Une conversaciones y carpetas por el relay cifrado';

  @override
  String get homeSyncMergedToast => 'Chats y carpetas ya están sincronizados';

  @override
  String get homeSyncFailedToast =>
      'No se pudo sincronizar. Abre Share with phone en el Mac e inténtalo de nuevo.';

  @override
  String get homeSyncPersonasTitle => 'Sincronizar personas';

  @override
  String get homeSyncPersonasSubtitle =>
      'Copia las que elijas, con fotos y recuerdos';

  @override
  String get homeSyncPersonasPickTitle => 'Elegir personas';

  @override
  String get homeSyncPersonasPickSubtitle =>
      'Las personas marcadas se copian entre este dispositivo y Home, con su foto y recuerdos.';

  @override
  String get homeSyncPersonasSave => 'Guardar y sincronizar';

  @override
  String get homeSyncPersonasSavedToast => 'Personas sincronizadas';

  @override
  String get homeSyncPersonasEmpty => 'Aún no hay personas para copiar.';

  @override
  String get homeSyncPersonasUnreachable =>
      'No se puede alcanzar Home. Abre Share with phone en el Mac e inténtalo de nuevo.';

  @override
  String get homeSyncPersonasOnBoth => 'En ambos dispositivos';

  @override
  String get homeSyncPersonasOnHome => 'LM Mini Home';

  @override
  String get homeSyncPersonasOnPhone => 'tu teléfono';

  @override
  String get homeSyncPersonasThisPhone => 'este teléfono';

  @override
  String homeSyncPersonasOnDevice(String device) {
    return 'En $device';
  }

  @override
  String homeSyncPersonasMemoryCount(int count) {
    return '$count recuerdos';
  }

  @override
  String get homeSyncPersonasNoMemories => 'Aún no hay recuerdos';

  @override
  String get reportToSupport => 'Enviar a soporte';

  @override
  String get localhostConnectionHelp =>
      'No se puede conectar a localhost. En el teléfono, localhost es este dispositivo, no tu computadora. En Ajustes usa la IP de tu computadora (por ejemplo http://192.168.1.10:1234) y quédate en la misma Wi‑Fi.';

  @override
  String get lmStudioPcNotAllowingTitle => 'Tu PC no permite la conexión';

  @override
  String get lmStudioPcNotAllowingBody =>
      'En LM Studio, en el ordenador, abre Developer → Server Settings y activa Serve on Local Network.';

  @override
  String get lmStudioHostDownTitle => 'No se alcanza tu PC';

  @override
  String get lmStudioHostDownStep1 =>
      'Asegúrate de que el ordenador está encendido, no suspendido ni apagado.';

  @override
  String get lmStudioHostDownStep2 =>
      'En LM Studio, abre Developer → Server Settings y activa Serve on Local Network.';

  @override
  String get cantReachMacTitle => 'No se alcanza tu Mac';

  @override
  String get cantReachMacStep1 =>
      'Abre Share with phone en LM Mini Home en tu Mac.';

  @override
  String get cantReachMacStep2 =>
      'Espera a que diga Connected e inténtalo de nuevo.';

  @override
  String get lmStudioServerSettingsImageLabel =>
      'LM Studio Developer → Server Settings. Serve on Local Network debe estar activado.';

  @override
  String get modelMissingTitle => 'Este modelo no está en tu PC';

  @override
  String get modelMissingBody =>
      'El modelo elegido no está disponible. Elige otro en Selección de modelos.';

  @override
  String modelMissingBodyNamed(String model) {
    return '“$model” no está en tu ordenador. Elige otro en Selección de modelos.';
  }

  @override
  String get outputTokensExhaustedTitle =>
      'El modelo se quedó sin tokens de salida';

  @override
  String get outputTokensExhaustedBody =>
      'Las herramientas terminaron, pero no quedaron tokens para la respuesta. Sube el máximo de tokens e inténtalo de nuevo.';

  @override
  String get thinkingBudgetRetryTitle => 'Thinking used the output limit';

  @override
  String get thinkingBudgetRetryBody =>
      'High thinking filled the output limit, so this reply uses low thinking. Raise max tokens to keep high thinking.';

  @override
  String get adjustMaxTokens => 'Ajustar tokens máximos';

  @override
  String get ggmlSchedulerCrashBody =>
      'El servidor del modelo se bloqueó (programador de llama.cpp). No es Mini. Baja la longitud de contexto y los tokens máximos: valores muy altos (por ejemplo 128k de contexto) suelen causar esto.';

  @override
  String get generationTerminatedBody =>
      'LM Studio detuvo la generación en tu ordenador (el proceso se terminó).';

  @override
  String generationTerminatedHugeImageBody(String size) {
    return 'LM Studio detuvo la generación en tu ordenador. La imagen adjunta es probablemente enorme ($size): comprímela y vuelve a enviar.';
  }

  @override
  String get compressAndResendImages => 'Comprimir imagen y reenviar';

  @override
  String get imageCompressFailed =>
      'No se pudo reducir la imagen adjunta. Prueba con una foto más pequeña.';

  @override
  String get droppedChatBodyHelp =>
      'Mini envió este chat, pero nunca llegó a LM Studio. Si tienes un proxy, túnel u otra URL delante de LM Studio, pruébalo sin eso — o apunta Mini directo a LM Studio (la IP de tu ordenador, USB o Connect).';

  @override
  String get comfyUiNoCheckpointsTitle => 'ComfyUI no tiene modelo de imagen';

  @override
  String get comfyUiNoCheckpointsBody =>
      'ComfyUI no tiene ningún checkpoint. Añade un archivo .safetensors a la carpeta models/checkpoints de ComfyUI y elígelo en Generación de imágenes.';

  @override
  String get comfyUiNoCheckpointSelectedBody =>
      'No hay modelo de imagen seleccionado. Abre Generación de imágenes y elige un checkpoint.';

  @override
  String comfyUiUnknownCheckpointBody(String name) {
    return 'ComfyUI no tiene el checkpoint “$name”. Elige otro en Generación de imágenes.';
  }

  @override
  String get comfyUiWorkflowRejectedBody =>
      'ComfyUI rechazó el flujo de trabajo. Revisa Generación de imágenes.';

  @override
  String get comfyUiDiffusionOnlyTitle =>
      'Este grafo necesita tu flujo de ComfyUI';

  @override
  String get comfyUiDiffusionOnlyBody =>
      'El flujo integrado de Mini carga un checkpoint clásico de SD. Tu grafo de Comfy Desktop usa un modelo de difusión (UNET) más CLIP y VAE. Expórtalo en formato API (Workflow → Export) y elige ese archivo en Generación de imágenes.';

  @override
  String get openImageSettings => 'Ajustes de imagen';

  @override
  String imageGenUnreachableTitle(String name) {
    return 'No se alcanza $name';
  }

  @override
  String imageGenUnreachableBody(String name, String url) {
    return 'Nada responde en $url. Arranca $name en el ordenador y quédate en el mismo Wi‑Fi.';
  }

  @override
  String get imageGenUnreachableNoUrlBody =>
      'No hay servidor de imágenes. Añade ComfyUI o AUTOMATIC1111 en Generación de imágenes.';

  @override
  String get sharedHostUpdateImageTitle =>
      '¿Actualizar también la generación de imágenes?';

  @override
  String sharedHostUpdateChatTitle(String name) {
    return '¿Actualizar también $name?';
  }

  @override
  String sharedHostUpdateBody(
      String changedName, String peerName, String oldHost, String newUrl) {
    return '$changedName y $peerName estaban ambos en $oldHost. ¿Cambiar $peerName a $newUrl?';
  }

  @override
  String get sharedHostUpdateConfirm => 'Actualizar y probar';

  @override
  String get sharedHostUpdateSkip => 'Dejar como está';

  @override
  String sharedHostTesting(String name) {
    return 'Probando $name…';
  }

  @override
  String get sharedHostTestSuccessTitle => 'Conectado';

  @override
  String sharedHostTestSuccessBody(String name, String url) {
    return 'Se alcanzó $name en $url.';
  }

  @override
  String get sharedHostTestFailTitle => 'No se pudo conectar';

  @override
  String sharedHostTestFailBody(String name, String url, String error) {
    return 'Se actualizó $name a $url, pero Mini no pudo alcanzarlo. $error';
  }

  @override
  String get supportTicketTitle => 'Informar de un problema';

  @override
  String get supportTicketPrefillDescription =>
      'Se adjunta un archivo de registro con los detalles del error. Añade cualquier otra cosa que pueda ayudar:';

  @override
  String get supportTicketSubmitted => 'Gracias — tu informe se ha enviado.';

  @override
  String get supportTicketAlreadyOpen =>
      'Ya tienes un informe abierto para este error.';

  @override
  String get supportTicketViewExisting => 'Ver informe';

  @override
  String get supportTicketAlreadySending => 'Este error ya se está enviando.';

  @override
  String get supportUnavailable =>
      'El soporte no está disponible ahora. Inténtalo de nuevo cuando tengas conexión.';

  @override
  String get somethingWentWrong => 'Algo salió mal';

  @override
  String get uncaughtErrorSnack => 'Algo salió mal.';

  @override
  String get errorLogLabel => 'LOG';

  @override
  String get appLock => 'Bloqueo de la app';

  @override
  String get appLockSubtitleOff => 'Pedir un PIN al cerrar la app';

  @override
  String appLockSubtitleOn(String duration) {
    return 'Vuelve a pedirla tras $duration';
  }

  @override
  String get appLockUnlockTitle => 'LM Mini está bloqueada';

  @override
  String get appLockDescription =>
      'Protege los chats de este dispositivo con un PIN numérico y Face ID opcional. El PIN se queda en este dispositivo y no se sincroniza.';

  @override
  String get appLockEnable => 'Bloquear con PIN';

  @override
  String get appLockEnableSubtitle => 'Pedir el PIN al volver';

  @override
  String get appLockPinLength4 => '4 dígitos';

  @override
  String get appLockPinLength6 => '6 dígitos';

  @override
  String get appLockRequireAfter => 'Pedir de nuevo después de';

  @override
  String get appLockTimeoutImmediate => 'Inmediatamente';

  @override
  String get appLockTimeout15s => '15 segundos';

  @override
  String get appLockTimeout1m => '1 minuto';

  @override
  String get appLockTimeout5m => '5 minutos';

  @override
  String get appLockTimeout15m => '15 minutos';

  @override
  String get appLockTimeout1h => '1 hora';

  @override
  String get appLockChangePin => 'Cambiar PIN';

  @override
  String get appLockEnterCurrentPin => 'Introduce el PIN actual';

  @override
  String get appLockChooseNewPin => 'Elige un PIN';

  @override
  String get appLockConfirmPin => 'Confirma el PIN';

  @override
  String get appLockPinsDontMatch =>
      'Los PIN no coinciden. Inténtalo de nuevo.';

  @override
  String get appLockWrongPin => 'PIN incorrecto. Inténtalo de nuevo.';

  @override
  String appLockTooManyAttempts(int seconds) {
    return 'Demasiados intentos. Prueba de nuevo en ${seconds}s.';
  }

  @override
  String get appLockForgotHint =>
      'Si olvidas el PIN, puedes restablecerlo con un correo de verificación enviado a tu cuenta. Inicia sesión antes de perder el PIN, o no podrás recuperarlo.';

  @override
  String get appLockProRequired => 'El bloqueo es una función Pro';

  @override
  String get appLockEnabledToast => 'Bloqueo activado';

  @override
  String get appLockDisabledToast => 'Bloqueo desactivado';

  @override
  String get appLockChangedToast => 'PIN actualizado';

  @override
  String appLockBiometricsToggle(String method) {
    return 'Desbloquear con $method';
  }

  @override
  String get appLockBiometricsSubtitle =>
      'Usa Face ID, Touch ID o la huella en lugar del PIN.';

  @override
  String get appLockBiometricFaceId => 'Face ID';

  @override
  String get appLockBiometricFace => 'Desbloqueo facial';

  @override
  String get appLockBiometricTouchId => 'Touch ID';

  @override
  String get appLockBiometricFingerprint => 'Huella digital';

  @override
  String get appLockBiometricGeneric => 'biometría';

  @override
  String appLockUnlockWithBiometrics(String method) {
    return 'Desbloquear con $method';
  }

  @override
  String appLockBiometricsFailed(String method) {
    return 'No se pudo desbloquear con $method. Usa tu PIN.';
  }

  @override
  String get appLockSignInToRecover =>
      'Inicia sesión, o no podrás recuperar el bloqueo si pierdes este PIN.';

  @override
  String appLockSignInToRecoverBound(String email) {
    return 'Inicia sesión como $email, o no podrás recuperar el bloqueo si pierdes este PIN.';
  }

  @override
  String get appLockNotSignedInNoRecovery =>
      'No has iniciado sesión. No podrás recuperar este PIN si lo pierdes.';

  @override
  String get appLockForgotPin => '¿Olvidaste el PIN?';

  @override
  String get appLockSendRecoveryEmail => 'Enviar un enlace de verificación';

  @override
  String appLockRecoveryEmailSent(String email) {
    return 'Enviamos un correo de verificación a $email. Ábrelo y vuelve aquí.';
  }

  @override
  String get appLockRecoveryIVerified => 'Ya verifiqué — continuar';

  @override
  String get appLockRecoveryResend => 'Reenviar correo';

  @override
  String get appLockRecoveryReauth =>
      'Vuelve a iniciar sesión para restablecer el PIN';

  @override
  String appLockRecoveryWrongAccount(String email) {
    return 'Este PIN está vinculado a $email. Inicia sesión con esa cuenta para recuperarlo.';
  }

  @override
  String get appLockRecoveryUnavailable =>
      'La recuperación del PIN no está configurada. Necesitas este PIN o reinstalar LM Mini.';

  @override
  String get appLockRecoveryFailed =>
      'No se pudo verificar la cuenta. Inténtalo de nuevo.';

  @override
  String get appLockRecoveryNoEmail =>
      'Esta cuenta no tiene un correo para enviar el enlace de verificación.';

  @override
  String get appLockRecoveryTooMany =>
      'Demasiados correos. Espera un minuto e inténtalo de nuevo.';

  @override
  String get appLockRecoverySetPin => 'Elige un PIN nuevo';

  @override
  String get appLockContinueWithEmail => 'Continuar con correo';

  @override
  String appLockSignedInRecoverHint(String email) {
    return 'Si olvidas este PIN, podemos enviar un enlace de verificación a $email.';
  }

  @override
  String get appLockRecoveryAccount => 'Recuperación del PIN';

  @override
  String appLockRecoveryAccountOn(String email) {
    return 'Los correos de verificación van a $email';
  }

  @override
  String get appLockRecoveryAccountOff =>
      'Inicia sesión para poder recuperar un PIN perdido';

  @override
  String get appLockRecoveryAccountOffSubtitle =>
      'Sin una cuenta, un PIN perdido solo se borra reinstalando la app.';

  @override
  String get appLockBackToPin => 'Usar PIN';

  @override
  String get premiumAppLock => 'Bloqueo de la app';

  @override
  String get premiumAppLockTagline => 'Protege la app con un PIN';

  @override
  String get premiumAppLockDescription =>
      'Elige un PIN de 4 o 6 dígitos, desbloquea con Face ID y recupera un PIN perdido con un correo de verificación. El PIN se queda en este dispositivo.';
}
