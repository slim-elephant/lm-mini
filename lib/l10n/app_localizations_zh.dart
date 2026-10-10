// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'LM Mini';

  @override
  String get splashTagline => '本地AI聊天';

  @override
  String get homeTitle => 'LM Mini';

  @override
  String get homeSearchHint => '搜索对话...';

  @override
  String get allConversations => '所有对话';

  @override
  String get noFoldersTitle => '还没有文件夹';

  @override
  String get noFoldersSubtitle => '创建文件夹来组织您的聊天记录';

  @override
  String get noConversationsTitle => '还没有对话';

  @override
  String get noConversationsSubtitle => '开始新的聊天';

  @override
  String get newChat => '新聊天';

  @override
  String conversationCount(int count) {
    return '$count 对话';
  }

  @override
  String get noModelsAvailable => '无可用型号。请检查您的 LM Studio 连接。';

  @override
  String get noVisionModelAvailable => '没有可用的视觉模型。请在 LM Studio 中加载视觉模型。';

  @override
  String get deleteConversationTitle => '删除对话';

  @override
  String get deleteConversationMessage => '您确定要删除此对话吗？此操作无法撤消。';

  @override
  String get renameConversationTitle => '重命名对话';

  @override
  String get conversationTitleLabel => '对话标题';

  @override
  String get deleteFolderTitle => '删除文件夹';

  @override
  String get deleteFolderMessage => '这不会删除此文件夹中的对话。';

  @override
  String get moveToFolderTitle => '移至文件夹';

  @override
  String get noFolder => '无文件夹';

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get save => '节省';

  @override
  String get close => '关闭';

  @override
  String get ok => 'OK';

  @override
  String get add => '添加';

  @override
  String get edit => '编辑';

  @override
  String get reset => '重置';

  @override
  String get retry => '重试';

  @override
  String get search => '搜索';

  @override
  String get copy => '复制';

  @override
  String get copied => '复制了！';

  @override
  String get copiedToClipboard => '已复制到剪贴板';

  @override
  String get dismiss => '解雇';

  @override
  String get configure => '配置';

  @override
  String get rename => '重命名';

  @override
  String get duplicate => '复制';

  @override
  String get enabled => '启用';

  @override
  String get disabled => '残疾人';

  @override
  String get active => '积极的';

  @override
  String get none => '没有任何';

  @override
  String get auto => '汽车';

  @override
  String get custom => '风俗';

  @override
  String get change => '改变';

  @override
  String get chatDefaultTitle => '聊天';

  @override
  String get searchMessagesTooltip => '搜索消息';

  @override
  String get chatSettingsMenuItem => '聊天设置';

  @override
  String get appearanceMenuItem => '外貌';

  @override
  String get exportAsPdf => '导出为 PDF';

  @override
  String get exportAsTxt => '导出为 TXT';

  @override
  String get exportAsMarkdown => '导出为 Markdown';

  @override
  String get exportAsJson => '导出为 JSON';

  @override
  String get exportAsObsidian => '出口黑曜石';

  @override
  String get copyToClipboard => '复制到剪贴板';

  @override
  String get exportAndShare => '导出和分享';

  @override
  String get freeFormats => '标准';

  @override
  String get premiumFormats => '专业格式';

  @override
  String get chatExported => '聊天导出';

  @override
  String get noModelSelectedTitle => '未选择型号';

  @override
  String get noModelSelectedSubtitle => '请在设置中选择模型开始聊天';

  @override
  String get openSettings => '打开设置';

  @override
  String connectionError(String error) {
    return '连接错误：$error';
  }

  @override
  String get startConversation => '问候！今天我可以为您提供什么帮助吗？';

  @override
  String get typeMessageToBegin => '选择下面的建议，或输入消息以开始';

  @override
  String get searchMessagesTitle => '搜索消息';

  @override
  String get searchQueryHint => '输入搜索查询...';

  @override
  String get semanticSearchInfo => '语义搜索使用人工智能根据含义（而不仅仅是关键字）查找相关消息。';

  @override
  String get noMessagesToSearch => '没有可搜索的消息';

  @override
  String get searchResults => '搜索结果';

  @override
  String searchResultsFor(int count, String query) {
    return '$count 匹配“$query”';
  }

  @override
  String get noMessagesFound => '没有找到消息';

  @override
  String get tryDifferentSearch => '尝试不同的搜索查询';

  @override
  String get chatCustomizationSaved => '聊天自定义已保存';

  @override
  String get noMessagesToExport => '没有要导出的消息';

  @override
  String get exportingChat => '正在导出聊天记录...';

  @override
  String get chatExportedAsPdf => '聊天导出为 PDF';

  @override
  String get chatExportedAsTxt => '聊天导出为 TXT';

  @override
  String exportFailed(String error) {
    return '导出失败：$error';
  }

  @override
  String get chatSettingsUpdated => '聊天设置已更新（覆盖全局设置）';

  @override
  String get chatSettingsReset => '聊天设置重置为全局默认值';

  @override
  String get you => '你';

  @override
  String get assistant => '助手';

  @override
  String get yesterday => '昨天';

  @override
  String get showDetails => '显示详情';

  @override
  String get hideDetails => '隐藏详细信息';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsAdvancedMode => '先进的';

  @override
  String get settingsAdvancedModeTooltip => '为高级用户显示技术选项';

  @override
  String get serverSection => '服务器';

  @override
  String get serverUrlLabel => '服务器地址';

  @override
  String get serverUrlHint => 'http://本地主机:1234';

  @override
  String get testConnectionRequired => '测试连接（必填）';

  @override
  String get testConnection => '测试连接';

  @override
  String get modelsSection => '型号';

  @override
  String get modelSelection => '选型';

  @override
  String get noModelSelected => '未选择型号';

  @override
  String get modelParameters => '型号参数';

  @override
  String get modelParametersSubtitle => '温度、代币、惩罚';

  @override
  String get modelParametersHelpTooltip => '这些设置的含义';

  @override
  String get modelParametersHelpTitle => '快速指南';

  @override
  String get modelParametersHelpIntro =>
      '每个设置的简单提示。如果您不确定，请保留默认值 - 您以后可以随时更改它们。某些选项仅针对您当前的 AI 提供商显示。';

  @override
  String get topKHelp => 'AI 考虑了多少个单词选择。更低=更安全、更可预测； 0 = 无限制。';

  @override
  String get reasoningHelp =>
      '打开或关闭推理模型的思考模式。关闭 = 更快回复且无思考过程；开启（或某一级别）会让模型逐步思考。并非所有推理模型都支持关闭思考。';

  @override
  String get reasoningHelpShort => '打开或关闭思考。并非所有模型都支持关闭。';

  @override
  String get systemPrompts => '角色和系统提示';

  @override
  String get defaultPrompt => '默认提示';

  @override
  String get appearanceSection => '外貌';

  @override
  String get appearance => '外貌';

  @override
  String get appearanceSubtitle => '主题、背景、头像';

  @override
  String get supportSection => '支持';

  @override
  String get rateApp => '评价 LM 迷你';

  @override
  String get rateAppSubtitle => '喜欢这个应用程序吗？在 App Store 上发表评论 ⭐';

  @override
  String get hfBrowseTitle => '从抱脸下载';

  @override
  String get hfBrowseSubtitle => '浏览 GGUF 模型 — 无需 API 密钥';

  @override
  String get hfBrowseTab => '浏览';

  @override
  String get hfPasteTab => '粘贴链接';

  @override
  String get hfSearchHint => '搜索 GGUF 型号...';

  @override
  String get hfLoadingModels => '搜索拥抱脸...';

  @override
  String get hfNoModelsFound => '没有找到型号';

  @override
  String get hfNoModelsHint => '尝试不同的搜索词或关闭 LM Studio 过滤器。';

  @override
  String get hfLmStudioFilter => '兼容 LM Studio';

  @override
  String get hfLmStudioFilterHint => '仅 Hugging Face 列出的模型可与 LM Studio 配合使用';

  @override
  String get hfChatModelsFilter => '聊天模特';

  @override
  String get hfChatBadge => '聊天';

  @override
  String get hfLmStudioBadge => 'LM工作室';

  @override
  String get hfPasteUrlHint => 'https://huggingface.co/owner/repo';

  @override
  String get hfModelInfo => '型号信息';

  @override
  String hfDownloadsCount(String count) {
    return '$count 下载量';
  }

  @override
  String hfLikesCount(String count) {
    return '$count 赞';
  }

  @override
  String hfPipelineTag(String tag) {
    return '任务：$tag';
  }

  @override
  String hfBaseModel(String model) {
    return '基础型号：$model';
  }

  @override
  String hfLicense(String license) {
    return '许可证：$license';
  }

  @override
  String get hfTagsSection => '标签';

  @override
  String get hfQuantPickerHint => '较低的数量=较小的文件。 Q4_K_M 对于大多数设备来说是一个很好的平衡。';

  @override
  String get hfBackToModels => '返回型号';

  @override
  String hfGgufFilesCount(int count) {
    return '$count GGUF 文件可用';
  }

  @override
  String get hfDownloadInBackground => '下载已开始 — 使用浮动按钮跟踪进度。您可以继续浏览或关闭此面板。';

  @override
  String get hfQuantPickerHintLmStudio => 'LM Studio 服务器列出的量化。选择一个下载到服务器。';

  @override
  String get hfDownloadDefaultQuant => '下载';

  @override
  String hfDownloadFailed(String error) {
    return '无法开始下载：$error';
  }

  @override
  String get hfPasteInstructions =>
      '粘贴 Hugging Face 存储库 URL 或输入所有者/存储库。接下来您将选择一个量化。';

  @override
  String get hfPasteInstructionsLmStudio =>
      '粘贴 Hugging Face URL、所有者/存储库或 LM Studio 模型 ID。';

  @override
  String get hfPasteLabel => '存储库';

  @override
  String get hfInvalidRepo => '输入有效的 Hugging Face URL 或所有者/存储库。';

  @override
  String get hfRecommended => '受到推崇的';

  @override
  String get reviewPromptTitle => '喜欢 LM Mini 吗？';

  @override
  String get reviewPromptMessage => '你们进行了几次愉快的交谈！您介意在 Play 商店上留下快速评价吗？';

  @override
  String get reviewPromptRate => '立即评分';

  @override
  String get reviewPromptLater => '也许稍后';

  @override
  String get buyMeACoffee => '请我喝杯咖啡';

  @override
  String get buyMeACoffeeSubtitle => '帮助人工智能保持咖啡因！ 🤖';

  @override
  String get featureRequests => '支持/功能请求';

  @override
  String get featureRequestsSubtitle => '对功能进行投票或提交您的想法';

  @override
  String get dataSection => '数据';

  @override
  String get exportAllChats => '导出所有聊天记录';

  @override
  String get exportAllChatsSubtitle => '将所有对话下载为 ZIP 文件';

  @override
  String get importChats => '导入聊天记录';

  @override
  String get importChatsSubtitle => '导入 LM Studio 聊天导出（.md 或 .zip）';

  @override
  String importSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '成功导入 $count 个聊天',
      one: '成功导入 1 个聊天',
    );
    return '$_temp0';
  }

  @override
  String get importFailed => '导入失败';

  @override
  String importPartial(int imported, int skipped) {
    return '$imported 已导入，$skipped 已跳过';
  }

  @override
  String get importing => '输入...';

  @override
  String get advancedSection => '高级功能';

  @override
  String get showRuntimeInfo => '显示运行时信息';

  @override
  String get showRuntimeInfoSubtitle => '显示模型架构和运行时';

  @override
  String get embeddingModel => '嵌入模型';

  @override
  String get enableSemanticSearch => '启用语义搜索';

  @override
  String get enableSemanticSearchSubtitle => '使用嵌入查找相关消息';

  @override
  String get toolCalling => '工具调用';

  @override
  String get toolCallingEnabled => '启用工具调用';

  @override
  String get toolCallingDisabled => '工具调用已禁用';

  @override
  String get legalSection => '合法的';

  @override
  String get privacyPolicy => '隐私政策';

  @override
  String get privacyPolicySubtitle => '对话保存在您的设备上';

  @override
  String get termsOfService => '服务条款';

  @override
  String get termsOfServiceSubtitle => '条款和条件';

  @override
  String get appName => 'LM Mini';

  @override
  String get appTagline => '适用于 LM Studio、Ollama 和 oMLX 的 Pocket A.I 和配套应用程序';

  @override
  String get couldNotOpenLink => '无法打开链接';

  @override
  String get apiToken => 'API 令牌和 USB';

  @override
  String get tokenConfigured => '令牌已配置';

  @override
  String get optionalAuthentication => '可选身份验证';

  @override
  String get apiTokenLabel => 'API令牌';

  @override
  String get apiTokenHint => '输入您的 LM Studio API 令牌';

  @override
  String get apiTokenHelp =>
      '如果您的 LM Studio 服务器需要身份验证，请在此处输入您的 API 令牌。这是可选的，仅当您在 LM Studio 设置中启用了身份验证时才需要。';

  @override
  String get apiTokenInfo =>
      'LM Studio 0.4.0+支持API身份验证。在 LM Studio > 设置 > 安全中启用它。';

  @override
  String get actionRequired => '- 需要采取行动';

  @override
  String get idleTtl => '空闲TTL';

  @override
  String get idleTtlDefault => '使用 LM Studio 默认设置（60 分钟）';

  @override
  String idleTtlMinutes(int value) {
    return '空闲$value分钟后自动卸载';
  }

  @override
  String idleTtlHoursMinutes(int hours, int mins) {
    return '闲置 $hours 小时 $mins 分钟后自动卸载';
  }

  @override
  String get lmStudioDefault => 'LM Studio 默认';

  @override
  String get fiveMinutes => '5分钟';

  @override
  String get fifteenMinutes => '15分钟';

  @override
  String get thirtyMinutes => '30分钟';

  @override
  String get oneHour => '1小时';

  @override
  String get twoHours => '2小时';

  @override
  String connectionSuccess(int count) {
    return '已连接！已加载$count个模型';
  }

  @override
  String get connectionFailed => '连接失败';

  @override
  String get troubleshootingSteps => '故障排除步骤：';

  @override
  String get troubleshootStep1 => '确保 LM Studio 正在运行';

  @override
  String get troubleshootStep2 => '在 LM Studio 中，打开“开发人员”选项卡（⚙️ 图标）';

  @override
  String get troubleshootStep3 => '启用“在本地网络上提供服务”切换';

  @override
  String get troubleshootStep4 => '验证服务器端口匹配（默认：1234）';

  @override
  String troubleshootStep5(String ip) {
    return '对于本地连接，请使用您的 IP，例如$ip';
  }

  @override
  String get lmStudioSettings => 'LM工作室设置';

  @override
  String get serveOnLocalNetworkHelp =>
      '应在 LM Studio Developer 选项卡中启用“在本地网络上提供服务”开关（以橙色/绿色显示）。';

  @override
  String get networkConnections => '网络连接：';

  @override
  String get networkConnectionsTips =>
      '• 将“localhost”替换为您计算机的IP 地址\n• 确保两台设备位于同一网络上\n• 检查端口 1234 的防火墙设置';

  @override
  String get noConversationsToExport => '没有要导出的对话';

  @override
  String exportingConversations(int count) {
    return '正在导出 $count 对话...';
  }

  @override
  String exportSuccess(int count) {
    return '$count 对话导出成功';
  }

  @override
  String get languageSection => '语言';

  @override
  String get language => '语言';

  @override
  String get languageSubtitle => '选择您的首选语言';

  @override
  String get systemDefault => '系统默认值';

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
  String get toolsCallingTitle => '工具调用';

  @override
  String get toolCallingSection => '工具调用';

  @override
  String get enableToolCallingAndMcps => '启用工具调用和 MCP';

  @override
  String get enableToolCallingSubtitle => '允许 AI 搜索网络并呼叫 MCP';

  @override
  String get builtInToolsSection => '内置工具';

  @override
  String get builtInToolsInfo => '当 AI 请求时，应用程序在本地执行的工具';

  @override
  String get webSearch => '网页搜索';

  @override
  String get webSearchUsingSearxng => '使用SearXNG';

  @override
  String get webSearchDisabled => '已禁用（配置 SearXNG 或升级到 Pro）';

  @override
  String get integratedMcpsSection => '集成 MCP';

  @override
  String get integratedMcpsInfo =>
      '使用您已在 LM Studio 中设置的 MCP。只需在此处添加 mcp.json 中的他们的名字即可。';

  @override
  String get integratedMcpsAuthRequired =>
      '集成 MCP 需要在 LM Studio 中启用身份验证，并在设置 → API 令牌中设置 API 令牌。';

  @override
  String get requiresApiToken => '需要 API 令牌';

  @override
  String get setApiTokenTooltip => '在“设置”中设置 API 令牌以启用';

  @override
  String get noIntegratedMcps => '未配置集成 MCP';

  @override
  String get addManually => '手动添加';

  @override
  String get importMcpJson => '导入 mcp.json';

  @override
  String get ephemeralMcpsSection => '短暂的 MCP';

  @override
  String get ephemeralMcpsInfo =>
      'HTTP MCP 服务器按请求发送。需要在 LM Studio 中“允许每个请求 MCP”。';

  @override
  String get requiresPerRequestMcps => '需要：开发人员 → 服务器设置 → 允许每个请求 MCP';

  @override
  String get noEphemeralMcps => '未配置临时 MCP';

  @override
  String get addHttpMcpServer => '添加 HTTP MCP 服务器';

  @override
  String get browseExampleMcps => '浏览示例 MCP 服务器';

  @override
  String get addIntegratedMcpTitle => '添加MCP';

  @override
  String get editIntegratedMcpTitle => '编辑MCP';

  @override
  String get addIntegratedMcpInfo =>
      '从 LM Studio 的 mcp.json 复制名称并将其粘贴到此处。例如，如果您看到名为 playwright 的键，请键入 playwright。';

  @override
  String get mcpNameLabel => 'mcp.json 中的名称';

  @override
  String get mcpNameHint => '剧作家';

  @override
  String get mcpNameHelper => '仅限字母、数字和连字符 — 使用网络搜索，而不是 web_search。';

  @override
  String get exampleMcpJsonEntry => '💡 mcp.json 条目示例：';

  @override
  String get nameIsRequired => '姓名为必填项';

  @override
  String get mcpNameInvalidChars =>
      '使用连字符而不是下划线（LM Studio 不接受像 web_search 这样的名称）。';

  @override
  String get mcpNameAlreadyExists => '该 MCP 已添加';

  @override
  String addedMcp(String name) {
    return '添加$name';
  }

  @override
  String updatedMcp(String name) {
    return '已更新$name';
  }

  @override
  String get editMcpTooltip => '编辑姓名';

  @override
  String get unlimitedToolCalls => '无限次工具调用';

  @override
  String get unlimitedToolCallsSubtitle => '取消集成和临时 MCP 的 10 次调用限制（不影响专业搜索）';

  @override
  String get unlimitedToolCallsOn => 'MCP 工具调用迭代没有限制';

  @override
  String get unlimitedToolCallsOff => '限制为 10 次工具调用迭代';

  @override
  String get structuredOutput => '结构化输出';

  @override
  String get structuredOutputSubtitle => '强制 JSON 响应格式';

  @override
  String get reasoningMode => '推理模式';

  @override
  String get reasoningOff => '离开';

  @override
  String get reasoningLow => '低的';

  @override
  String get reasoningMedium => '中等的';

  @override
  String get reasoningHigh => '高的';

  @override
  String get reasoningOn => '在';

  @override
  String get reasoningDescOff => '没有推理痕迹';

  @override
  String get reasoningDescLow => '最少的推理';

  @override
  String get reasoningDescMedium => '平衡推理';

  @override
  String get reasoningDescHigh => '详细推理';

  @override
  String get reasoningDescOn => '完整的推理痕迹';

  @override
  String get helpSection => '帮助';

  @override
  String get toolCallingGuide => '工具调用指南';

  @override
  String get toolCallingGuideSubtitle => '了解工具如何工作';

  @override
  String get searxngSetupGuide => 'SearXNG 设置指南';

  @override
  String get searxngSetupGuideSubtitle => '设置您自己的搜索服务器';

  @override
  String get webSearchConfig => '网页搜索配置';

  @override
  String get howWebSearchWorks => '💡 网络搜索的工作原理';

  @override
  String get howWebSearchWorksSteps =>
      '1. AI 决定需要当前信息\n2. 使用 Premium Search 或 SearXNG 进行应用程序搜索\n3.结果发送回AI\n4. AI 综合答案';

  @override
  String get searchResultsLabel => '搜索结果：';

  @override
  String get webSearchDisabledWarning => '网络搜索已禁用。配置 SearXNG 或升级到 Pro。';

  @override
  String get searxngUrlOptional => 'SearXNG URL（可选）';

  @override
  String get searxngUrlLabel => '搜索XNG URL';

  @override
  String get searxngUrlHint => 'http://本地主机:8888';

  @override
  String get quickSetupDocker => '🐳 使用 Docker 快速设置：';

  @override
  String get dockerCommand => 'docker run -d -p 8888:8080 searxng/searxng';

  @override
  String get mcpBadge => 'MCP';

  @override
  String get mcpResultBadge => 'MCP 结果';

  @override
  String get webSearchSourcesTitle => '来源';

  @override
  String get toolBadge => '工具';

  @override
  String get resultBadge => '结果';

  @override
  String get failedToLoadImage => '加载图像失败';

  @override
  String get thinking => '思维';

  @override
  String get think => '思考';

  @override
  String thoughtFor(String duration) {
    return '为$duration思考';
  }

  @override
  String get performanceStats => '表现统计';

  @override
  String get regenerate => '再生';

  @override
  String get editMessage => '编辑留言';

  @override
  String get editMessageHint => '编辑您的消息...';

  @override
  String get saveAndRegenerate => '保存并重新生成';

  @override
  String get deleteMessage => '删除留言';

  @override
  String get deleteMessageConfirm => '您确定要删除此消息吗？';

  @override
  String get mcpCallTitle => 'MCP 呼叫';

  @override
  String get mcpResultTitle => 'MCP 结果';

  @override
  String get toolCallTitle => '工具调用';

  @override
  String get toolResultTitle => '工具结果';

  @override
  String get attachFile => '附加文件';

  @override
  String get photoLibrary => '照片库';

  @override
  String get attachImagesForVision => '附加图像以进行视觉分析';

  @override
  String get requiresVisionModel => '需要具有视觉能力的模型';

  @override
  String get takePhoto => '拍照';

  @override
  String get captureImageWithCamera => '用相机捕捉图像';

  @override
  String get imageFromFiles => '文件中的图像';

  @override
  String get pickImageFromFilesApp => '从“文件”应用程序中选择图像';

  @override
  String get attachDocuments => '文件';

  @override
  String get attachDocumentsSubtitle => 'PDF、Markdown、Excel (.xlsx)、CSV、文本、代码等';

  @override
  String get textFileTxt => '文本文件 (.txt)';

  @override
  String get attachPlainText => '附上纯文本文档';

  @override
  String get csvFileCsv => 'CSV 文件 (.csv)';

  @override
  String get attachSpreadsheetData => '附加电子表格数据';

  @override
  String get pdfDocumentPdf => 'PDF 文档 (.pdf)';

  @override
  String get attachPdfDocuments => '附上 PDF 文档';

  @override
  String get mcpLabel => 'MCP：';

  @override
  String get typeMessageHint => '输入消息...';

  @override
  String get attachFilesTooltip => '附加文件';

  @override
  String get customizeChat => '自定义聊天';

  @override
  String get overrideGlobalAppearance => '覆盖此聊天的全局外观设置';

  @override
  String get background => '背景';

  @override
  String get userAvatar => '用户头像';

  @override
  String get assistantAvatar => '助理头像';

  @override
  String get colorsSection => '颜色';

  @override
  String get userBubble => '用户泡沫';

  @override
  String get userText => '用户文本';

  @override
  String get assistantBubble => '助理泡泡';

  @override
  String get assistantText => '助理文字';

  @override
  String get darkOverlay => '昏暗的壁纸';

  @override
  String get darkOverlayDescription => '聊天背景的壁纸应该设置多暗';

  @override
  String get usingGlobal => '使用全局';

  @override
  String get useGlobal => '使用全局';

  @override
  String get setCustom => '设置自定义';

  @override
  String get customColor => '定制颜色';

  @override
  String get defaultThemeColor => '默认主题颜色';

  @override
  String get resetToDefault => '重置为默认值';

  @override
  String get pickAColor => '选择一种颜色';

  @override
  String get chatSettingsTitle => '聊天设置';

  @override
  String get overrideGlobalSettings => '仅覆盖此聊天的全局设置';

  @override
  String get resetAll => '全部重置';

  @override
  String get modelOverride => '模型';

  @override
  String get noneSelected => '未选择';

  @override
  String get systemPromptOverride => '人格面具';

  @override
  String get saved => '已保存';

  @override
  String get noSavedPromptsInfo => '没有保存的人物角色。转到“设置”→“角色”来创建一些角色。';

  @override
  String get selectSavedPromptHint => '选择一个人物...';

  @override
  String get enterCustomPromptHint => '输入自定义角色提示...';

  @override
  String get personaShareMemoriesLabel => '分享回忆';

  @override
  String get personaShareMemoriesSubtitle => '关闭后，此角色不会在聊天中接收或学习记忆';

  @override
  String get webSearchOffForThisChat => '仅此聊天关闭';

  @override
  String get reasoningOffForThisChat => '仅此聊天关闭';

  @override
  String get temperatureOverride => '温度';

  @override
  String get maxTokensOverride => '最大代币数';

  @override
  String get topPOverride => '顶P';

  @override
  String get topKOverride => '前K';

  @override
  String get minPOverride => '最小P';

  @override
  String get repeatPenaltyOverride => '重复处罚';

  @override
  String get contextLengthOverride => '上下文长度';

  @override
  String get systemPromptsTitle => '角色和系统提示';

  @override
  String get addSystemPromptTooltip => '添加提示或角色';

  @override
  String get systemPromptsInfoText =>
      '创建和管理系统提示。将它们绑定到特定模型或全局使用它们。选择一项以使其处于活动状态。';

  @override
  String get savedPromptsSection => '保存的提示';

  @override
  String get addSystemPrompt => '添加系统提示';

  @override
  String get newPrompt => '新提示或角色';

  @override
  String get noPromptSet => '没有设置提示';

  @override
  String get editSystemPrompt => '编辑系统提示';

  @override
  String get newSystemPrompt => '新提示或角色';

  @override
  String get promptNameLabel => '提示名称';

  @override
  String get promptNameHint => '例如，代码助理、创意作家……';

  @override
  String get systemPromptLabel => '系统提示';

  @override
  String get systemPromptEditorHint => '你是一个有用的助手，...';

  @override
  String get bindToModels => '绑定到特定模型';

  @override
  String get bindToModelsSubtitle => '将此提示限制为某些型号。解除绑定后，它适用于所有型号。';

  @override
  String get noModelsLoaded => '没有加载模型。连接到 LM Studio 并加载模型以绑定此提示。';

  @override
  String get templatesSection => '模板';

  @override
  String get pleaseEnterPromptName => '请输入此提示的名称';

  @override
  String get pleaseEnterPromptContent => '请输入提示内容';

  @override
  String get deleteSystemPromptTitle => '删除系统提示？';

  @override
  String deleteSystemPromptMessage(String name) {
    return '您确定要删除“$name”吗？此操作无法撤消。';
  }

  @override
  String get templateCodeAssistant => '代码助手';

  @override
  String get templateCreativeWriter => '创意作家';

  @override
  String get templateConciseExpert => '简洁专家';

  @override
  String get templateResearcher => '研究员';

  @override
  String get templateTutor => '导师';

  @override
  String get templateTechnicalWriter => '技术撰稿人';

  @override
  String get downloadProgress => '下载进度';

  @override
  String get progressLabel => '进步';

  @override
  String get speedLabel => '速度';

  @override
  String get etaLabel => '预计到达时间';

  @override
  String get statusLabel => '地位';

  @override
  String get notAvailable => '不适用';

  @override
  String get calculating => '正在计算...';

  @override
  String get moveToFolderPopup => '移至文件夹';

  @override
  String contextInfo(String used, String total) {
    return '上下文：$used / $total';
  }

  @override
  String get hideAvatars => '隐藏头像';

  @override
  String get hideAvatarsSubtitle => '从聊天消息中删除头像图标';

  @override
  String get autoScroll => '自动滚动';

  @override
  String get autoScrollSubtitle => '当新消息到达时滚动到底部';

  @override
  String get editMcpServer => '编辑 MCP 服务器';

  @override
  String get addMcpServer => '添加 MCP 服务器';

  @override
  String get serverLabelRequired => '服务器标签 *';

  @override
  String get serverLabelHint => '例如，huggingface、tiktoken';

  @override
  String get serverLabelHelper => '识别该服务器的名称';

  @override
  String get serverUrlRequired => '服务器网址 *';

  @override
  String get serverUrlMcpHint => 'https://huggingface.co/mcp';

  @override
  String get serverUrlHelper => 'MCP 服务器的 HTTP/HTTPS URL';

  @override
  String get authorizationOptional => 'API 密钥（可选）';

  @override
  String get authorizationHint => 'hf_xxxxxxxx 或 Bearer hf_xxxxxxxx';

  @override
  String get authorizationHelper =>
      '作为 Authorization 标头发送到此 MCP。可粘贴原始令牌（会自动加 Bearer）或完整标头值。';

  @override
  String get additionalHeaders => '附加标头';

  @override
  String get additionalHeadersHint => 'X-自定义标头：值';

  @override
  String get additionalHeadersHelper => '每行一个标题（名称：值）。\n上面设置了授权。';

  @override
  String get labelAndUrlRequired => '标签和 URL 为必填项';

  @override
  String get urlMustStartWithHttp => 'URL 必须以 http:// 或 https:// 开头';

  @override
  String get mcpServerUpdated => 'MCP服务器已更新';

  @override
  String get mcpServerAdded => '添加 MCP 服务器';

  @override
  String get importMcpJsonTitle => '导入 mcp.json';

  @override
  String get pasteMcpJsonContent => '粘贴您的 mcp.json 内容';

  @override
  String get mcpJsonLocation =>
      '位于：~/.lmstudio/config/mcp.json\n或者在 LM Studio 中：开发人员 → MCP 设置 → 打开配置';

  @override
  String get mcpJsonContentLabel => 'mcp.json 内容';

  @override
  String get mcpJsonContentHelper => '粘贴整个 mcp.json 文件内容';

  @override
  String get parseJson => '解析 JSON';

  @override
  String foundMcpServers(int count) {
    return '找到 $count MCP 服务器：';
  }

  @override
  String get hasAuthHeaders => '具有身份验证标头';

  @override
  String importSelected(int count) {
    return '导入$count所选';
  }

  @override
  String get pleasePasteMcpJson => '请粘贴您的 mcp.json 内容';

  @override
  String get noMcpServersFound => 'JSON 中未找到 mcpServer';

  @override
  String get exampleMcpServers => 'MCP 服务器示例';

  @override
  String get gitMcpInfo => '这些使用 GitMCP 提供来自 GitHub 存储库的文档';

  @override
  String get browseMoreGitMcp => '在 gitmcp.io 浏览更多内容';

  @override
  String get fileNotFound => '找不到文件';

  @override
  String get openWithExternalApp => '使用外部应用程序打开';

  @override
  String get previewNotAvailable => '预览不可用';

  @override
  String get voiceMode => '语音模式';

  @override
  String get voiceSettings => '语音设置';

  @override
  String get voiceSettingsSubtitle => '文本转语音、语音输入和语音模式';

  @override
  String get voiceSection => '嗓音';

  @override
  String get voiceStatus => '地位';

  @override
  String get voiceTtsEngine => '文本转语音引擎';

  @override
  String get voiceSttEngine => '语音识别引擎';

  @override
  String get voiceAvailable => '可用的';

  @override
  String get voiceUnavailable => '无法使用';

  @override
  String get voiceTtsSettings => '文字转语音';

  @override
  String get voiceSttSettings => '语音转文本';

  @override
  String get voiceSttProvider => '语音识别提供商';

  @override
  String get voiceSttProviderSystem => '系统讲话';

  @override
  String get voiceSttProviderSystemSubtitle =>
      'iOS 上的 Apple Speech，Android 上的 Google Speech';

  @override
  String get voiceSttProviderWhisper => '设备上的耳语';

  @override
  String get voiceSttProviderWhisperSubtitle =>
      '离线 sherpa-onnx Whisper — 更准确，在所有平台上的工作方式相同';

  @override
  String get voiceWhisperModelNotDownloaded => '耳语模型未下载';

  @override
  String get voiceWhisperModelReady => '耳语模型准备就绪';

  @override
  String get voiceWhisperModelSize => '选择尺寸 - 较大的型号转录更准确';

  @override
  String get voiceWhisperDownloadButton => '下载';

  @override
  String get voiceWhisperDownloading => '正在下载 Whisper 模型...';

  @override
  String get voiceWhisperDownloadStarting => '开始下载...';

  @override
  String get voiceWhisperDownloadFailed => '下载失败';

  @override
  String get voiceWhisperDeleteModel => '删除选定的 Whisper 模型';

  @override
  String get voiceWhisperDeleteTitle => '删除耳语模型？';

  @override
  String get voiceWhisperDeleteMessage =>
      '这会将所选模型从设备存储中释放。设备上的语音识别将回退到系统语音，直到您再次下载 Whisper 模型。';

  @override
  String get voiceWhisperDeleteConfirm => '删除';

  @override
  String get voiceWhisperFallback => '如果未下载模型，则返回系统语音';

  @override
  String get voiceWhisperBiggerBetterTitle => '为什么要选择更大的型号？';

  @override
  String get voiceWhisperBiggerBetterBody =>
      '较大的 Whisper 模型通常会生成更准确的文字记录，尤其是对于口音、安静的音频、背景噪音和不常见的单词。它们还需要更多存储空间，并且在您的设备上运行速度较慢。\n\nTiny 适合简短、清晰的演讲。 Base 或 Small 更适合较长的文件。 Large v3 Turbo 是大型模型中最快/最小的（经过修剪的 Large v3）。 Full Large v3 是最准确的，但也是最重的。';

  @override
  String get voiceWhisperUseModel => '使用';

  @override
  String get voiceWhisperSelected => '已选择';

  @override
  String get voiceWhisperDownloaded => '已下载';

  @override
  String get audioSetupTitle => '设置语音和音频';

  @override
  String get audioSetupMessage =>
      '语音聊天需要文本转语音才能让人工智能回复。选择设备上的 Kokoro 神经语音以获得最佳质量，或使用设备的内置语音 - 无需下载。';

  @override
  String get audioSetupWhisperStatus => '耳语语音识别';

  @override
  String get audioSetupKokoroStatus => 'Kokoro 神经语音';

  @override
  String get audioSetupStatusReady => '准备好';

  @override
  String get audioSetupStatusMissing => '未下载';

  @override
  String get audioSetupOnDeviceButton => '下载Kokoro语音';

  @override
  String get audioSetupOnDeviceSubtitle => 'Kokoro 神经 TTS · 约 300 MB · 离线工作';

  @override
  String get audioSetupSystemButton => '使用系统语音';

  @override
  String get audioSetupSystemSubtitle => '内置 STT 和 TTS — 无需下载';

  @override
  String get audioSetupConfigureButton => '语音设置';

  @override
  String get audioSetupNotNow => '现在不要';

  @override
  String get audioSetupDownloadingWhisper => '正在下载耳语...';

  @override
  String get audioSetupDownloadingKokoro => '正在下载心...';

  @override
  String get audioSetupDownloadComplete => '模型准备好了';

  @override
  String get audioSetupContinueButton => '继续';

  @override
  String get voiceModeSettings => '语音模式';

  @override
  String get voiceAutoRead => '自动读取回复';

  @override
  String get voiceAutoReadSubtitle => '自动朗读新的助理消息';

  @override
  String get voiceSpeechRate => '语速';

  @override
  String get voicePitch => '沥青';

  @override
  String get voiceLanguage => '语音语言';

  @override
  String get voiceLanguageSubtitle => '口头回复的语言（文本转语音）';

  @override
  String get voiceSttLanguage => '识别语言';

  @override
  String get voiceSttLanguageSubtitle => '用于文本麦克风和语音通话。可能与口头回复语言不同。';

  @override
  String get voiceSelection => '语音选择';

  @override
  String get voiceDefault => '默认';

  @override
  String get voiceTestVoice => '测试语音';

  @override
  String get voiceTestVoiceSubtitle => '播放样本以听听当前的语音设置';

  @override
  String get voiceTestPhrase => '你好！这就是我现在的声音。';

  @override
  String get voiceTestProgressInitializing => '启动 TTS 引擎...';

  @override
  String get voiceTestProgressGenerating => '生成语音...';

  @override
  String get voiceTestProgressPreparing => '正在准备播放...';

  @override
  String get voiceTestProgressPlaying => '播放样本...';

  @override
  String get voiceTestProgressConnecting => '正在连接远程语音...';

  @override
  String get voiceTestProgressComplete => '完毕';

  @override
  String get voiceKokoroEngineReady => '发动机准备就绪——测试应该很快开始';

  @override
  String get voiceKokoroEngineWarming => '正在预热设备上的引擎...';

  @override
  String get voiceAutoSend => '发言后自动发送';

  @override
  String get voiceAutoSendSubtitle => '语音识别结束时自动发送消息';

  @override
  String get voiceSttPauseFor => '发送前保持沉默';

  @override
  String get voiceSttPauseForSubtitle =>
      '在您停止讲话后，在发送消息之前静默几秒钟。这与 iOS 麦克风会话限制（约 15 秒块，自动处理）是分开的。';

  @override
  String get voiceSttListenFor => '最长收听时间';

  @override
  String get voiceSttListenForSubtitle =>
      '在应用程序重新打开麦克风之前，每个麦克风会话的硬上限。在 iOS 上，Apple 还在长演讲期间大约每 15 秒轮换一次会话。';

  @override
  String voiceSttSeconds(int seconds) {
    return '$seconds秒';
  }

  @override
  String get voiceContinuousConversation => '持续对话';

  @override
  String get voiceContinuousConversationSubtitle => '朗读响应后自动开始收听';

  @override
  String get voiceTapToSpeak => '点击即可说话';

  @override
  String get voiceListening => '正在听……';

  @override
  String get voiceThinking => '一会儿……';

  @override
  String get voiceResponding => '正在回复…';

  @override
  String get voiceSpeaking => '请讲…';

  @override
  String get voiceConvoHintIdle => '点击圆圈开始说话';

  @override
  String get voiceConvoHintListening => '我在听——慢慢来';

  @override
  String get voiceConvoHintStarting => '正在准备麦克风…';

  @override
  String get voiceConvoHintProcessing => '思维…';

  @override
  String get voiceConvoHintSpeaking => '';

  @override
  String get voiceNotAvailable => '此设备不支持语音识别';

  @override
  String get voiceStartRecording => '开始语音输入';

  @override
  String get voiceStopRecording => '停止录音';

  @override
  String get voiceDiscardRecording => '丢弃';

  @override
  String get voiceSelectLanguage => '选择语言';

  @override
  String get voiceSelectVoice => '选择语音';

  @override
  String get voiceNoVoicesAvailable => '该语言没有可用的语音';

  @override
  String get voiceAboutTitle => '关于语音模式';

  @override
  String get voiceAboutDescription =>
      '语音模式使用设备的本机语音引擎或设备上的 Kokoro 神经 TTS。文本转语音可以使用 iOS 上的 Apple AVSpeechSynthesizer、Android 上的 Google TTS 或设备上下载的 Kokoro-82M 神经模型。语音识别在 iOS 上使用 Apple Speech Framework，在 Android 上使用 Google Speech。所有处理都在设备上进行——没有数据发送到外部服务器。';

  @override
  String get voiceExitMode => '切换到键盘';

  @override
  String get voiceTtsProvider => 'TTS 提供商';

  @override
  String get voiceTtsProviderNative => '设备（本机）';

  @override
  String get voiceTtsProviderNativeSubtitle => '使用内置系统声音 — 离线工作';

  @override
  String get voiceTtsProviderKokoro => '已下载的语音';

  @override
  String get voiceTtsProviderKokoroSubtitle => '在此设备上运行的自然语音';

  @override
  String get voiceTtsProviderKokoroRemote => '心 (PC)';

  @override
  String get voiceTtsProviderKokoroRemoteSubtitle =>
      '在您的 PC 上运行 Kokoro 以获得更快、更高质量的语音';

  @override
  String get voiceTtsProviderElevenLabs => 'ElevenLabs';

  @override
  String get voiceTtsProviderElevenLabsSubtitle => 'Pro · 你的 API 密钥 · 云端语音';

  @override
  String get voiceTtsElevenLabs => 'ElevenLabs';

  @override
  String get voiceTtsElevenLabsHint => '你的密钥 · 来自 ElevenLabs 语音库';

  @override
  String get voiceElevenLabsApiKey => 'ElevenLabs API 密钥';

  @override
  String get voiceElevenLabsApiKeyHint => '粘贴 elevenlabs.io 上的 xi-api-key';

  @override
  String get voiceElevenLabsTestKey => '检查密钥';

  @override
  String get voiceElevenLabsKeyInvalid => '该密钥未被接受。请在 elevenlabs.io 核对。';

  @override
  String get voiceElevenLabsKeyNetwork => '无法连接 ElevenLabs。请检查网络。';

  @override
  String get voiceElevenLabsKeyQuota => '此密钥额度已用完。';

  @override
  String get voiceElevenLabsKeyUnknown => '无法验证此密钥。请重试。';

  @override
  String get voiceElevenLabsPrivacy =>
      '回复文本会随你的密钥发送到 ElevenLabs。LM Mini 仅在本机保存密钥。';

  @override
  String get voiceElevenLabsModel => 'ElevenLabs 模型';

  @override
  String get voiceElevenLabsVoice => 'ElevenLabs 语音';

  @override
  String get voiceElevenLabsNoVoices => '此账户没有语音。请先在 ElevenLabs 语音库中添加。';

  @override
  String get voiceElevenLabsChangeKey => '更换密钥';

  @override
  String get voiceElevenLabsRemoveKey => '移除密钥';

  @override
  String get voiceElevenLabsReady => '已连接 ElevenLabs';

  @override
  String get voiceElevenLabsNoKey => '添加 ElevenLabs API 密钥';

  @override
  String get personaElevenLabsVoiceLabel => 'ElevenLabs 语音';

  @override
  String get personaElevenLabsVoiceGlobal => '使用全局 ElevenLabs 语音';

  @override
  String get personaElevenLabsVoicePickerTitle => 'ElevenLabs 语音';

  @override
  String get personaElevenLabsVoiceAddKey =>
      '在语音设置中添加 API 密钥后即可选择 ElevenLabs 语音';

  @override
  String get premiumElevenLabsTts => 'ElevenLabs 语音';

  @override
  String get premiumElevenLabsTtsTagline => '自带密钥的神经 TTS';

  @override
  String get premiumElevenLabsTtsDescription =>
      '使用你的 ElevenLabs API 密钥，并为角色指定工作室级语音。语音聊天、自动朗读和气泡朗读使用同一引擎。';

  @override
  String get voiceTtsProviderGrok => 'Grok';

  @override
  String get voiceTtsProviderGrokSubtitle => 'Pro · 你的 xAI API 密钥 · 云端语音';

  @override
  String get voiceTtsGrok => 'Grok';

  @override
  String get voiceTtsGrokHint => '你的密钥 · 来自 xAI 的 Grok 语音';

  @override
  String get voiceGrokApiKey => 'xAI API 密钥';

  @override
  String get voiceGrokApiKeyHint => '粘贴 console.x.ai 上的 API 密钥';

  @override
  String get voiceGrokTestKey => '检查密钥';

  @override
  String get voiceGrokKeyInvalid => '该密钥未被接受。请在 console.x.ai 核对。';

  @override
  String get voiceGrokKeyNetwork => '无法连接 xAI。请检查网络。';

  @override
  String get voiceGrokKeyQuota => '此密钥额度已用完。';

  @override
  String get voiceGrokKeyUnknown => '无法验证此密钥。请重试。';

  @override
  String get voiceGrokPrivacy => '回复文本会随你的密钥发送到 xAI。LM Mini 仅在本机保存密钥。';

  @override
  String get voiceGrokVoice => 'Grok 语音';

  @override
  String get voiceGrokNoVoices => '没有可用的 Grok 语音。请检查密钥后重试。';

  @override
  String get voiceGrokChangeKey => '更换密钥';

  @override
  String get voiceGrokRemoveKey => '移除密钥';

  @override
  String get voiceGrokReady => '已连接 Grok';

  @override
  String get voiceGrokNoKey => '添加 xAI API 密钥';

  @override
  String get personaGrokVoiceLabel => 'Grok 语音';

  @override
  String get personaGrokVoiceGlobal => '使用全局 Grok 语音';

  @override
  String get personaGrokVoicePickerTitle => 'Grok 语音';

  @override
  String get personaGrokVoiceAddKey => '在语音设置中添加 API 密钥后即可选择 Grok 语音';

  @override
  String get personaVoiceSection => '语音';

  @override
  String get personaVoiceProviderLabel => '提供方';

  @override
  String get personaVoiceProviderKokoro => 'Kokoro';

  @override
  String get personaVoiceProviderGlobal => '使用全局语音设置';

  @override
  String get personaVoiceConfigureInSettings => '请在 设置 → 语音 中配置';

  @override
  String get premiumGrokTts => 'Grok 语音';

  @override
  String get premiumGrokTtsTagline => '自带密钥的神经 TTS';

  @override
  String get premiumGrokTtsDescription =>
      '使用你的 xAI API 密钥，并为角色指定 Grok 语音。语音聊天、自动朗读和气泡朗读使用同一引擎。';

  @override
  String get voiceRemoteKokoroConnected => '连接至 PC 上的 Kokoro';

  @override
  String get voiceRemoteKokoroNotFound => '在 PC 上找不到 Kokoro TTS';

  @override
  String get voiceRemoteKokoroRequiresConnect =>
      '需要在 Mac 上开启“与手机共享”，或在 Windows/Linux 上运行 LM Mini Connect';

  @override
  String get voiceKokoroVoice => '心的声音';

  @override
  String get voiceKokoroSpeed => '语速';

  @override
  String get voiceKokoroModelReady => 'Kokoro模型准备好了';

  @override
  String get voiceKokoroModelReadySubtitle => '已下载的语音已就绪';

  @override
  String get voiceKokoroModelNotDownloaded => 'Kokoro模型未下载';

  @override
  String get voiceKokoroModelSize => '需要下载（~400 MB 共享包）';

  @override
  String get voiceKokoroDownloading => '正在下载 Kokoro 模型...';

  @override
  String get voiceKokoroDownloadStarting => '开始下载...';

  @override
  String get voiceKokoroDownloadButton => '下载';

  @override
  String get voiceKokoroDownloadFailed => '下载失败。点击重试。';

  @override
  String get voiceKokoroFallback => '如果未下载 Kokoro 模型，将回退为原生语音';

  @override
  String get voiceKokoroDeleteModel => '删除心模型';

  @override
  String get voiceKokoroDeleteTitle => '删除Kokoro模型？';

  @override
  String get voiceKokoroDeleteMessage => '这将删除所有已下载的 TTS 语言包。您可以稍后重新下载。';

  @override
  String get voiceKokoroDeleteConfirm => '删除';

  @override
  String get voiceTtsLanguagePacksHint =>
      '英语、西班牙语、法语和中文共用一次下载（约 400 MB）。德语和俄语更小（各约 34 MB）。';

  @override
  String get voiceTtsLanguagePacks => '语音包';

  @override
  String get voiceTtsLanguagePacksSubtitleNone => '下载一种语言即可在本机朗读';

  @override
  String voiceTtsLanguagePacksSubtitleReady(int ready, int total) {
    return '$ready / $total 种语言已就绪';
  }

  @override
  String voiceTtsLanguagePacksSubtitleDownloading(String name) {
    return '正在下载 $name…';
  }

  @override
  String voiceTtsSharedPackSize(int size) {
    return '共享下载 · ~$size MB';
  }

  @override
  String voiceTtsPiperPackSize(int size) {
    return '较小下载 · ~$size MB';
  }

  @override
  String get voiceTtsSharedPackDeleteMessage =>
      '这将移除英语、西班牙语、法语和中文共用的下载。您可以稍后重新下载。';

  @override
  String get connecting => '正在连接...';

  @override
  String get saveAndTestConnection => '保存并测试连接';

  @override
  String connectedTo(String provider) {
    return '✅ 连接到 $provider';
  }

  @override
  String connectionToFailed(String provider) {
    return '❌ 连接到 $provider 失败 — 检查您的 API 密钥';
  }

  @override
  String errorGeneric(String error) {
    return '❌错误：$error';
  }

  @override
  String get provider => '提供者';

  @override
  String cloudApiKeyLabel(String provider) {
    return '$provider API 密钥';
  }

  @override
  String get enterApiKeyHint => '输入您的 API 密钥...';

  @override
  String getApiKey(String provider) {
    return '获取 $provider API 密钥';
  }

  @override
  String get baseUrl => '基本网址';

  @override
  String get customBaseUrlOptional => '自定义基本 URL（可选）';

  @override
  String get accountSection => '帐户';

  @override
  String get signIn => '登入';

  @override
  String get signInSubtitle => '登录以启用云备份';

  @override
  String get cloudServicesUnavailable => '云服务不可用';

  @override
  String signedInVia(String method) {
    return '通过$method登录';
  }

  @override
  String get lmMiniProSection => 'LM迷你PRO';

  @override
  String get proActive => '积极主动的';

  @override
  String get allPremiumUnlocked => '所有高级功能已解锁';

  @override
  String get upgradeToPro => '升级到专业版';

  @override
  String get unlockPremiumFeatures => '解锁以下所有高级功能';

  @override
  String get proBadge => '专业版';

  @override
  String get proFeatureTag => '专业功能';

  @override
  String get betaBadge => '测试版';

  @override
  String get imageGeneration => '图像生成';

  @override
  String get generatedImagesLibrary => '已生成的图片';

  @override
  String get generatedImagesGallery => '图库';

  @override
  String get generatedImagesShowInChat => '在对话中显示';

  @override
  String get generatedImagesLibrarySubtitle => '查看、在对话中打开或删除';

  @override
  String get generatedImagesLibraryEmpty => '还没有生成的图片';

  @override
  String get generatedImagesLibraryEmptyHint => '你在对话里生成的图片会保存在这里。';

  @override
  String get generatedImagesSelect => '选择';

  @override
  String get generatedImagesCancelSelect => '完成';

  @override
  String generatedImagesDeleteN(int count) {
    return '删除 $count 张';
  }

  @override
  String get generatedImagesDeleteConfirmTitle => '删除图片？';

  @override
  String generatedImagesDeleteConfirmBody(int count) {
    return '将从此设备删除 $count 张图片。聊天消息会保留。';
  }

  @override
  String get generatedImagesOpenChat => '在对话中打开';

  @override
  String get saveToPhotos => 'Save to Photos';

  @override
  String get savedToPhotos => 'Saved to Photos';

  @override
  String get couldNotSaveToPhotos => 'Could not save this file.';

  @override
  String get share => 'Share';

  @override
  String get generatedImagesMissingFile => '文件缺失';

  @override
  String get generatedImagesOrphan => '未关联对话';

  @override
  String get generatedImagesPrompt => '提示词';

  @override
  String get generatedImagesNegativePrompt => '负面提示词';

  @override
  String get generatedImagesDetails => '生成详情';

  @override
  String get generatedImagesNoPrompt => '未保存提示词';

  @override
  String get generatedImagesChatUnavailable => '该对话已不存在';

  @override
  String get generatedImagesVideo => '视频';

  @override
  String imageGenEnabled(String url) {
    return '已启用 — $url';
  }

  @override
  String get imageGenNotConfigured => '已启用 — 未配置';

  @override
  String get cloudBackup => '云备份';

  @override
  String get encryptedBackupRestore => '加密备份和恢复';

  @override
  String get e2eBanner => '端到端加密 - 您的密码永远不会离开此设备';

  @override
  String get analytics => '分析';

  @override
  String get analyticsSubtitle => '使用统计、代币和模型见解';

  @override
  String get memory => '回忆';

  @override
  String memoryItemCount(int count) {
    return '$count 项目 • 在聊天中持续存在';
  }

  @override
  String get premiumWebSearch => '高级网络搜索';

  @override
  String get premiumWebSearchSubtitle => '即时搜索 — 无需 SearXNG';

  @override
  String get urlReader => '网址阅读器';

  @override
  String get urlReaderSubtitle => '阅读并总结任何网页';

  @override
  String get conversationBranching => '对话分支';

  @override
  String get conversationBranchingSubtitle => '从任何消息中分叉对话';

  @override
  String get cloudBackupPro => '云备份';

  @override
  String get cloudBackupProSubtitle => '加密备份和恢复到云端';

  @override
  String get analyticsDashboard => '分析仪表板';

  @override
  String get analyticsDashboardSubtitle => '使用统计、代币和模型见解';

  @override
  String get cloudApiProviders => '云API提供商';

  @override
  String get cloudApiProvidersSubtitle => 'Mistral、DeepSeek 等';

  @override
  String get addProviderLabel => '添加提供商';

  @override
  String get noCloudProvidersTitle => '没有云提供商';

  @override
  String get noCloudProvidersSubtitle =>
      '点击 + 添加云 API 提供商。\n使用您自己的 Groq、DeepSeek 等 API 密钥。';

  @override
  String get editProviderTitle => '编辑提供商';

  @override
  String get addCloudProviderTitle => '添加云提供商';

  @override
  String get providerLabel => '提供者';

  @override
  String get apiKeyLabel => 'API密钥';

  @override
  String get pasteLabel => '粘贴';

  @override
  String get baseUrlRequiredLabel => '基本 URL（必填）';

  @override
  String get customBaseUrlOptionalLabel => '自定义基本 URL（可选）';

  @override
  String get advancedLabel => '先进的';

  @override
  String get fetchingLabel => '正在获取...';

  @override
  String get fetchAvailableModelsLabel => '获取可用型号';

  @override
  String get availableModelsLabel => '可用型号：';

  @override
  String get suggestedModelsLabel => '推荐型号：';

  @override
  String get modelIdLabel => '型号编号';

  @override
  String get disableCloudProviderSubtitle => '禁用保留配置但不使用它';

  @override
  String get setAsActiveProviderLabel => '设置为主动提供者';

  @override
  String get deactivateLabel => '停用';

  @override
  String get switchedBackToLocalLmStudio => '切换回本地LM Studio';

  @override
  String get saveChangesLabel => '保存更改';

  @override
  String get enterDisplayNameError => '请输入显示名称';

  @override
  String get enterApiKeyError => '请输入 API 密钥';

  @override
  String get enterBaseUrlError => '请输入自定义提供商的基本 URL';

  @override
  String get enterApiKeyFirst => '首先输入 API 密钥';

  @override
  String failedToFetchModels(String error) {
    return '获取模型失败：$error';
  }

  @override
  String get deleteProviderTitle => '删除提供商？';

  @override
  String deleteProviderMessage(String name) {
    return '删除“$name”及其 API 密钥？';
  }

  @override
  String deleteFirstPartyOpenAiServerMessage(String name) {
    return '要从这台设备移除“$name”吗？\n\n之后无法再从列表中添加此服务器。若要重新连接，请添加 A.I Compatible API，并将基础 URL 设为 https://api.openai.com。';
  }

  @override
  String activeProviderSet(String name) {
    return '$name 设置为活动提供者';
  }

  @override
  String get memoryPro => '回忆';

  @override
  String get memoryProSubtitle => '对话中的持久记忆';

  @override
  String get richExportShare => '丰富的导出和分享';

  @override
  String get richExportShareSubtitle => '导出到 Obsidian、Notes、Notion 等';

  @override
  String autoUnloadAfter(String value) {
    return '$value后自动卸载';
  }

  @override
  String get subscriptionRestore => '恢复';

  @override
  String get subscriptionTerms => '条款';

  @override
  String get subscriptionPrivacy => '隐私';

  @override
  String get secureYourAccount => '保护您的帐户';

  @override
  String get signInWithApple => '使用 Apple 登录';

  @override
  String get signInWithGoogle => '使用 Google 登录';

  @override
  String get subscriptionSecured => '您的订阅已受到保护';

  @override
  String get packagesNotAvailable => '套餐尚未提供。';

  @override
  String get welcomeToPro => '🎉 欢迎来到 LM Mini Pro！';

  @override
  String get subscriptionRestored => '✅ 订阅已恢复！';

  @override
  String get noActiveSubscription => '未找到有效订阅。';

  @override
  String get accountLinked => '✅ 帐户已关联！';

  @override
  String get account => '帐户';

  @override
  String get createAccount => '创建账户';

  @override
  String get emailLabel => '电子邮件';

  @override
  String get passwordLabel => '密码';

  @override
  String get forgotPassword => '忘记密码？';

  @override
  String get forgotPasswordNeedEmail => '请先输入电子邮件，再点「忘记密码？」。';

  @override
  String get forgotPasswordSent => '如果该邮箱已有账户，我们已发送重置链接。请查看收件箱。';

  @override
  String get forgotPasswordFailed => '无法发送重置邮件，请再试一次。';

  @override
  String get verificationEmailSent => '验证邮件已发送！';

  @override
  String failedToSend(String error) {
    return '发送失败：$error';
  }

  @override
  String get cloudBackupEnabled => '已启用 — 您的帐户支持加密备份';

  @override
  String get endToEndEncryption => '端到端加密';

  @override
  String get e2eSubtitle => '使用您的密码加密的备份 - 我们无法读取它们';

  @override
  String get upgradeForCloudBackup => '升级到专业版以启用加密云备份';

  @override
  String get signOut => '登出';

  @override
  String get signOutConfirm => '登出？';

  @override
  String get signedOut => '已退出。';

  @override
  String get goToAccount => '前往账户';

  @override
  String get firebaseNotConfigured => 'Firebase 未配置。';

  @override
  String get refresh => '刷新';

  @override
  String get createBackup => '创建备份';

  @override
  String get encryptBackupSubtitle => '加密并备份所有对话';

  @override
  String get backUpNow => '立即备份';

  @override
  String get yourBackups => '您的备份';

  @override
  String get e2eBackupBanner => '端到端加密。';

  @override
  String get e2eBackupDetail => '在离开此设备之前，您的备份将使用您的密码进行加密。我们无法读取您的数据。';

  @override
  String get exportingData => '正在导出数据...';

  @override
  String get preparing => '正在准备...';

  @override
  String get encrypting => '正在加密...';

  @override
  String get uploading => '正在上传...';

  @override
  String get savingMetadata => '正在保存元数据...';

  @override
  String get done => '完毕！';

  @override
  String get noBackupsYet => '还没有备份';

  @override
  String get createFirstBackup => '在上面创建您的第一个加密备份';

  @override
  String get encrypted => '加密的';

  @override
  String get restore => '恢复';

  @override
  String get encryptionPassphraseLabel => '加密密码';

  @override
  String get enterStrongPassphrase => '输入强密码';

  @override
  String get confirmPassphraseLabel => '确认密码';

  @override
  String get passphraseRememberWarning =>
      '记住这个密码！如果丢失，您的备份将无法恢复。我们不会将其存储在任何地方。';

  @override
  String get passphraseRestoreHint => '输入您在创建此备份时使用的相同密码。';

  @override
  String get minCharsRequired => '至少需要 4 个字符。';

  @override
  String get passphrasesDoNotMatch => '密码不匹配。';

  @override
  String get encryptAndBackUp => '加密和备份';

  @override
  String get decryptAndRestore => '解密与恢复';

  @override
  String get encryptionPassphrase => '加密密码';

  @override
  String get savedPassphrasePrompt => '您有以前备份中保存的密码。您想使用相同的密码还是设置新的密码？';

  @override
  String get newPassphrase => '新密码';

  @override
  String get useSame => '使用相同';

  @override
  String get setEncryptionPassphrase => '设置加密密码';

  @override
  String get choosePassphraseBackup => '选择一个密码来加密该备份。您需要它才能在任何设备上进行恢复。';

  @override
  String get choosePassphraseDetail =>
      '选择一个密码来加密您的备份。该密码保留在您的设备上 - 我们永远不会看到它。你需要它来恢复。';

  @override
  String backupFailed(String error) {
    return '备份失败：$error';
  }

  @override
  String get restoreBackupConfirm => '恢复备份？';

  @override
  String get restoreWarning => '这将使用此备份中的数据替换您当前的所有对话、消息和文件夹。\n\n此操作无法撤消。';

  @override
  String get continueAction => '继续';

  @override
  String get enterPassphrase => '输入密码';

  @override
  String get passphraseDecryptHint => '该备份是端到端加密的。输入您在创建时使用的密码。';

  @override
  String get wrongPassphrase => '密码错误或备份损坏。';

  @override
  String restoreFailed(String error) {
    return '恢复失败：$error';
  }

  @override
  String get deleteBackupConfirm => '删除备份？';

  @override
  String get deleteBackupWarning => '这将永久删除此加密的云备份。此操作无法撤消。';

  @override
  String get backupDeleted => '备份已删除。';

  @override
  String deleteFailed(String error) {
    return '删除失败：$error';
  }

  @override
  String get overview => '概述';

  @override
  String get messages => '留言';

  @override
  String get conversations => '对话';

  @override
  String get totalTokens => '代币总数';

  @override
  String get avgResponse => '平均响应';

  @override
  String get modelUsage => '型号使用';

  @override
  String get noModelUsageData => '尚无模型使用数据。\n在这里开始聊天以查看统计数据。';

  @override
  String get analyticsSync => '分析会同步到您的帐户，并在您退出时重置。';

  @override
  String get clearAllMemories => '清除所有记忆';

  @override
  String get memoryOn => '在';

  @override
  String get memoryOff => '离开';

  @override
  String get memoryInfoText => '记忆被注入系统提示中，以便法学硕士在对话中记住您。';

  @override
  String get noMemoriesYet => '还没有记忆';

  @override
  String noMemoriesInCategory(String category) {
    return '没有$category记忆';
  }

  @override
  String get memoryTapToAdd => '点击 + 添加新内存或选择不同的类别。';

  @override
  String get memoryAddHint => '添加您希望人工智能在所有对话中记住的有关您自己的事实。';

  @override
  String get addMemory => '添加内存';

  @override
  String get category => '类别';

  @override
  String get editMemory => '编辑内存';

  @override
  String get deleteMemory => '删除内存';

  @override
  String removeMemoryConfirm(String content) {
    return '删除这段记忆？\n\n“$content”';
  }

  @override
  String get clearAllMemoriesTitle => '清除所有记忆';

  @override
  String clearAllMemoriesConfirm(int count) {
    return '这将永久删除所有 $count 记忆。此操作无法撤消。';
  }

  @override
  String get clearAll => '全部清除';

  @override
  String get justNow => '现在';

  @override
  String get categoryPersonal => '个人的';

  @override
  String get categoryPreferences => '偏好设置';

  @override
  String get categoryLifestyle => 'Lifestyle';

  @override
  String get categoryEmotional => 'Emotional';

  @override
  String get categoryTechnical => '技术的';

  @override
  String get categoryWork => '工作';

  @override
  String get categoryGeneral => '一般的';

  @override
  String get categoryAll => '全部';

  @override
  String get modelManagement => '模型管理';

  @override
  String get downloadNewModel => '下载新模型';

  @override
  String get refreshModels => '刷新模型';

  @override
  String get tapToSelect => '点击选择';

  @override
  String modelSelected(String name) {
    return '已选择: $name';
  }

  @override
  String get unloadModelTooltip => '从内存中卸载模型';

  @override
  String get modelInfoTooltip => '型号信息';

  @override
  String get loadedBadge => '已加载';

  @override
  String get visionBadge => '想象';

  @override
  String get toolsBadge => '工具';

  @override
  String get selectedModel => '选定型号';

  @override
  String get unloading => '正在卸载...';

  @override
  String get unload => '卸下';

  @override
  String get loaded => '已加载';

  @override
  String get loadModel => '负载模型';

  @override
  String get enterModelIdOrUrl => '输入模型 ID 或 HuggingFace URL：';

  @override
  String get modelIdHint => '微软/phi-4';

  @override
  String get modelIdHelper => '型号 ID 或 https://huggingface.co/...';

  @override
  String get huggingFaceDetected => '检测到 HuggingFace URL - 您将选择量化';

  @override
  String get starting => '开始...';

  @override
  String get download => '下载';

  @override
  String get selectQuantization => '选择量化';

  @override
  String get loadingQuantizations => '正在加载量化...';

  @override
  String get error => '错误';

  @override
  String fetchQuantizationsFailed(String error) {
    return '无法获取量化：$error';
  }

  @override
  String get checkLmStudioRunning => '请确认 LM Studio 正在运行';

  @override
  String get couldNotReachLmStudio => 'LM Mini 无法连接到你的服务器。';

  @override
  String get couldNotLoadQuantizations => '无法加载量化。';

  @override
  String get couldNotStartDownload => '无法开始下载。';

  @override
  String get noQuantizations => '无量化';

  @override
  String get noGgufFiles => '在此存储库中找不到 GGUF 文件';

  @override
  String foundQuantizations(int count) {
    return '找到 $count GGUF 量化';
  }

  @override
  String get unknown => '未知';

  @override
  String downloadingModel(String quantization) {
    return '正在下载 $quantization 量化模型...';
  }

  @override
  String get modelAlreadyDownloaded => '模型已下载';

  @override
  String downloadFailed(String error) {
    return '下载失败：$error';
  }

  @override
  String get enterModelIdentifier => '请输入型号标识符或 URL';

  @override
  String get modelAlreadyLoaded => '模型已加载';

  @override
  String get currentlyLoaded => '目前已加载：';

  @override
  String loadAlongsideWarning(String name) {
    return '与现有模型一起加载“$name”将使用额外的内存。';
  }

  @override
  String get unloadAllAndLoad => '全部卸载并加载';

  @override
  String get swap => '交换';

  @override
  String get loadAlongside => '并排装载';

  @override
  String get loadParamsConflictTitle => '负载设置不同';

  @override
  String loadParamsConflictBody(String name) {
    return '“$name”已加载到 LM Studio 中，其设置与 LM Mini 的模型加载配置不同。重新加载可能需要一分钟时间并使用额外的内存。';
  }

  @override
  String get loadParamsConflictTableHeader => '参数不同：';

  @override
  String get loadParamsLmStudio => 'LM工作室';

  @override
  String get loadParamsLmMini => 'LM Mini';

  @override
  String get loadParamsConflictHint =>
      '使用 LM Studio 的加载设置可以避免重新加载。卸载和重新加载应用您的 LM Mini 设置。并行加载将两个实例保留在内存中。';

  @override
  String get loadParamsUseExisting => '使用 LM Studio 设置';

  @override
  String get loadParamsReloadWithMini => '使用 LM Mini 设置卸载和加载';

  @override
  String get loadParamsLoadParallel => '使用 LM Mini 设置加载（并行）';

  @override
  String get reloadModelForContextTitle => '重新加载模型？';

  @override
  String reloadModelForContextBody(String name, String loaded, String desired) {
    return '上下文长度在加载模型时生效。“$name”当前为 $loaded。要用 $desired 重新加载吗？';
  }

  @override
  String get reloadModelForContextNow => '重新加载';

  @override
  String get reloadModelForContextLater => '稍后';

  @override
  String loadModelConfirm(String name) {
    return '将“$name”加载到内存中？';
  }

  @override
  String get unloadModelTip => '您可以使用弹出按钮或加载后从此屏幕卸载模型。';

  @override
  String get modelLoadedSuccess => '模型加载成功';

  @override
  String get failedToLoadModel => '加载模型失败';

  @override
  String get modelInfo => '型号信息';

  @override
  String get infoName => '姓名';

  @override
  String get infoType => '类型';

  @override
  String get infoArchitecture => '建筑学';

  @override
  String get infoPublisher => '出版商';

  @override
  String get infoQuantization => '量化';

  @override
  String get infoParameters => '参数';

  @override
  String get infoSize => '尺寸';

  @override
  String get infoMaxContext => '最大上下文';

  @override
  String get infoLoadedContext => '加载上下文';

  @override
  String get infoStatus => '地位';

  @override
  String get available => '可用的';

  @override
  String get capabilities => '能力';

  @override
  String get standardTextGeneration => '标准文本生成';

  @override
  String get unloadModelTitle => '卸载模型';

  @override
  String unloadModelConfirm(String name) {
    return '从内存中卸载“$name”？';
  }

  @override
  String get freeResourcesTip => '这将释放 GPU/RAM 资源。';

  @override
  String get modelUnloadedSuccess => '模型卸载成功';

  @override
  String get failedToUnloadModel => '卸载模型失败';

  @override
  String get enableImageGeneration => '启用图像生成';

  @override
  String get showImageButtons => '在聊天消息上显示图像按钮';

  @override
  String get serverConnection => '服务器连接';

  @override
  String get serverUrl => '服务器地址';

  @override
  String get test => '测试';

  @override
  String get connected => '已连接';

  @override
  String get model => '模型';

  @override
  String get checkpoint => '检查站';

  @override
  String get generationParameters => '发电参数';

  @override
  String get negativePrompt => '否定提示';

  @override
  String get steps => '步骤';

  @override
  String get cfgScale => 'CFG规模';

  @override
  String get width => '宽度';

  @override
  String get height => '高度';

  @override
  String get sampler => '采样器';

  @override
  String get scheduler => '调度程序';

  @override
  String get automatic => '自动的';

  @override
  String get seedLabel => '种子（-1 = 随机）';

  @override
  String get batchSize => '批量大小';

  @override
  String get options => '选项';

  @override
  String get restoreFaces => '恢复面孔';

  @override
  String get restoreFacesSubtitle => '修复生成图像中的人脸';

  @override
  String get tiling => '平铺';

  @override
  String get tilingSubtitle => '生成无缝的可平铺纹理';

  @override
  String get promptOptions => '提示选项';

  @override
  String get reviewPromptBeforeSending => '发送前查看提示';

  @override
  String get reviewPromptSubtitle => '生成前编辑图片提示';

  @override
  String get autoGenerateImage => '自动生成图像';

  @override
  String get autoGenerateSubtitle => '当AI提示时自动生成图像';

  @override
  String get resetToDefaults => '重置为默认值';

  @override
  String get featureRequestsTitle => '功能请求';

  @override
  String get featureRequestsUnavailable => '功能请求不可用';

  @override
  String get featureRequestsUnavailableDetail => '此功能需要互联网连接。请检查您的连接并稍后重试。';

  @override
  String get tryAgain => '再试一次';

  @override
  String get votesLeft => '左边';

  @override
  String get popular => '受欢迎的';

  @override
  String get myRequests => '我的要求';

  @override
  String get completed => '完全的';

  @override
  String get submitIdea => '提交想法';

  @override
  String get noFeatureRequests => '尚无功能请求';

  @override
  String get beFirstToSubmit => '成为第一个提交想法的人！';

  @override
  String get noRequestsSubmitted => '没有提交任何请求';

  @override
  String get tapToSubmitFirst => '点击下面的按钮提交您的第一个想法！';

  @override
  String get noCompletedRequests => '没有已完成的请求';

  @override
  String get completedRequestsAppear => '已完成和已拒绝的请求将显示在此处。';

  @override
  String get adminReplied => '管理员回复';

  @override
  String get submitFeatureRequest => '提交功能请求';

  @override
  String get titleRequired => '标题 *';

  @override
  String get titleHint => '简要概述您的想法';

  @override
  String get descriptionRequired => '描述 *';

  @override
  String get descriptionHint => '详细描述您的功能请求';

  @override
  String get yourNameOptional => '你的名字（可选）';

  @override
  String get leaveBlankAnonymous => '留空以匿名提交';

  @override
  String get fillTitleAndDescription => '请填写标题和描述';

  @override
  String get featureRequestSubmitted => '已提交功能请求！';

  @override
  String get submit => '提交';

  @override
  String get featureRequest => '功能请求';

  @override
  String get votedTooltip => '已投票';

  @override
  String get voteForThis => '对此投票';

  @override
  String get adminControls => '管理控制';

  @override
  String get changeStatus => '更改状态';

  @override
  String get officialReply => '官方回复';

  @override
  String get deleteRequest => '删除请求';

  @override
  String get unableToLoadComments => '无法加载评论';

  @override
  String commentsCount(int count) {
    return '评论 ($count)';
  }

  @override
  String get readMore => '阅读更多';

  @override
  String get showLess => '显示较少';

  @override
  String get deleteYourRequest => '删除您的请求';

  @override
  String get anonymous => '匿名的';

  @override
  String get officialResponse => '官方回应';

  @override
  String get noCommentsYet => '还没有评论';

  @override
  String get beFirstToComment => '成为第一个分享您想法的人！';

  @override
  String get adminBadge => '行政';

  @override
  String get moderatorBadge => '模组';

  @override
  String get experiencedUserBadge => '经验值';

  @override
  String get adminManageSubmitter => '管理提交者';

  @override
  String get adminManageUserTitle => '管理用户';

  @override
  String get adminUserUpdated => '用户更新';

  @override
  String get adminCommunityRoles => '社区角色';

  @override
  String get adminModeratorRole => '主持人';

  @override
  String get adminModeratorRoleSubtitle => '可以绕过垃圾评论限制并显示 Mod 徽章';

  @override
  String get adminExperiencedUserRole => '有经验的用户';

  @override
  String get adminExperiencedUserRoleSubtitle => '在功能请求评论中显示经验丰富的徽章';

  @override
  String get adminGrantPremiumTitle => '授予免费 Pro';

  @override
  String get adminGrantPremiumSubtitle => '限时免费赠送该用户 LM Mini Pro';

  @override
  String get adminGrantPremiumAmountLabel => '期间';

  @override
  String get adminGrantPremiumAmountHint => '输入金额';

  @override
  String get adminGrantPremiumUnitDays => '天';

  @override
  String get adminGrantPremiumUnitWeeks => '周数';

  @override
  String get adminGrantPremiumUnitMonths => '几个月';

  @override
  String get adminGrantPremiumGrantButton => '格兰特·普罗';

  @override
  String get adminGrantPremiumInvalidAmount => '输入正数';

  @override
  String get adminGrantPremiumReasonLabel => '原因';

  @override
  String get adminGrantPremiumReasonHint => '可选 — 向用户显示（例如，抱歉给您带来麻烦）';

  @override
  String adminGrantPremiumDurationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 天',
      one: '1 天',
    );
    return '$_temp0';
  }

  @override
  String adminGrantPremiumDurationWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 周',
      one: '1 周',
    );
    return '$_temp0';
  }

  @override
  String adminGrantPremiumDurationMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个月',
      one: '1 个月',
    );
    return '$_temp0';
  }

  @override
  String get adminRevokePremiumTitle => '撤销免费 Pro';

  @override
  String get adminRevokePremiumMessage => '删除该用户的活动管理员授予的 Pro 访问权限？';

  @override
  String get adminRevokePremiumConfirm => '撤销';

  @override
  String get premiumGrantBannerTitle => '您收到了免费的 Pro';

  @override
  String premiumGrantBannerBody(String duration) {
    return '$duration 免费 LM Mini Pro。尽享高级功能。';
  }

  @override
  String premiumGrantBannerReason(String reason) {
    return '原因：$reason';
  }

  @override
  String get premiumGrantDialogTitle => '免费解锁专业版';

  @override
  String premiumGrantDialogBody(String duration) {
    return '管理员以 $duration 的价格免费授予您 LM Mini Pro。云备份、内存、分析等现已可用。';
  }

  @override
  String premiumGrantDialogReason(String reason) {
    return '原因：$reason';
  }

  @override
  String get premiumGrantDialogButton => '惊人的';

  @override
  String get youBadge => '你';

  @override
  String get deleteComment => '您确定要删除此评论吗？';

  @override
  String maxCommentsReached(int max) {
    return '您已连续发表$max条评论。等待其他用户回复。';
  }

  @override
  String get addYourName => '添加您的名字';

  @override
  String get replyAsAdmin => '以管理员身份回复...';

  @override
  String get writeComment => '写评论...';

  @override
  String get errorTryAgain => '错误：请重试。';

  @override
  String statusUpdated(String status) {
    return '状态更新为$status';
  }

  @override
  String get addOfficialResponse => '添加官方回复...';

  @override
  String get replySaved => '回复已保存';

  @override
  String get deleteRequestConfirm => '您确定要删除此功能请求吗？此操作无法撤消。';

  @override
  String get requestDeleted => '请求已删除';

  @override
  String get deleteCommentTitle => '删除评论';

  @override
  String get deleteCommentConfirm => '您确定要删除此评论吗？';

  @override
  String get commentDeleted => '评论已删除';

  @override
  String get generationParametersSection => '发电参数';

  @override
  String get temperature => '温度';

  @override
  String get temperatureSubtitle => '回复的创意与针对性如何。更低=更小心；更高=更多样。';

  @override
  String get topP => '顶P';

  @override
  String get topPSubtitle => '允许的单词选择范围有多大。更低=更有针对性的回复。';

  @override
  String get minP => '最小P';

  @override
  String get minPSubtitle => '忽略极不可能的单词选择。更高=更安全、更可预测的文本。';

  @override
  String get repeatPenalty => '重复处罚';

  @override
  String get repeatPenaltySubtitle => '阻止人工智能重复相同的短语。 1.0 = 关闭。';

  @override
  String get frequencyPenalty => '频率惩罚';

  @override
  String get frequencyPenaltySubtitle => '减少人工智能经常使用的单词。';

  @override
  String get presencePenalty => '出席处罚';

  @override
  String get presencePenaltySubtitle => '推动人工智能提出新主题，而不是重复使用旧主题。';

  @override
  String get tokenLimits => '代币限制';

  @override
  String get maxOutputTokens => '最大输出代币';

  @override
  String get maxOutputTokensSubtitle => '单个回复可以多长时间。更高=更长的答案（以及更多的等待）。';

  @override
  String get contextWindow => '上下文窗口';

  @override
  String get contextWindowSubtitle => '人工智能一次可以记住多少聊天内容。更高使用更多内存。';

  @override
  String get modelLoadingConfig => '模型加载配置';

  @override
  String get loadContextLength => '上下文长度';

  @override
  String get loadContextSubtitle =>
      '模型在聊天和在 LM Studio 中加载时可使用的上下文大小。更高会占用更多内存 / 显存。';

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
  String get evalBatchSize => '评估批量大小';

  @override
  String get evalBatchSubtitle => '加载时一次处理多少文本。更高可以更快，但使用更多内存。';

  @override
  String get numExperts => '专家人数';

  @override
  String get numExpertsSubtitle => '仅适用于“专家混合”模型。保留空白，除非您知道需要它。';

  @override
  String get flashAttention => '闪光注意';

  @override
  String get flashAttentionSubtitle => '加快模型速度并可以使用更少的内存。继续下去，除非有什么东西坏了。';

  @override
  String get offloadKvCache => '将 KV 缓存卸载到 GPU';

  @override
  String get offloadKvCacheSubtitle => '使用 GPU 更有效地记住聊天内容。如果您有 GPU，请继续。';

  @override
  String get resizeImageForPhysicalBatch => 'Resize images for physical batch';

  @override
  String get resizeImageForPhysicalBatchSubtitle =>
      'Shrink a photo when it would use more tokens than the local server\'s physical batch, so the model doesn\'t crash.';

  @override
  String get resizeImageForPhysicalBatchHelp =>
      'LM Studio, Ollama, Jan, Unsloth, oMLX, and on-device models keep a physical batch of 512 tokens. A full-size photo can take 560 or more vision tokens. The server then aborts and the model unloads. When this is on, Mini measures the photo and shrinks it so it stays under that batch. Turn it off to send the original image.';

  @override
  String get chainOfThoughtSubtitle => '如果可用的话，展示人工智能的逐步思维。';

  @override
  String get reasoningUnsupportedToast => '该模型不支持 LM Studio 中的推理。推理已被禁用。';

  @override
  String get reasoningNotExposedChatHint => 'LM Studio 不支持关闭此模型的推理。请换一个模型。';

  @override
  String get premiumSearchActive => '高级搜索活跃';

  @override
  String get premiumSearchPlusSearxng => '+ 西尔XNG';

  @override
  String get webSearchDisabledAll => '对所有聊天禁用网络搜索';

  @override
  String get configureSearch => '配置搜索';

  @override
  String get advancedFeaturesSection => '高级功能';

  @override
  String get howToolCallingWorks => '工具调用如何工作';

  @override
  String get stepAskQuestion => '你问一个问题';

  @override
  String get stepAskExample => '例如，“东京的天气怎么样？”';

  @override
  String get stepAiRequestsTool => 'AI需要一个工具';

  @override
  String get stepAiRequestsExample => '模型决定需要网络搜索';

  @override
  String get stepAppExecutes => '应用程序执行该工具';

  @override
  String get stepAppExecutesExample => '使用高级搜索或 SearXNG 进行搜索';

  @override
  String get stepResultsSent => '结果发送至 AI';

  @override
  String get stepResultsExample => '搜索结果已添加到对话中';

  @override
  String get stepAiAnswers => 'AI生成答案';

  @override
  String get stepAiAnswersExample => '模型综合了有用的响应';

  @override
  String get toolCallingModelNote => '例如 Qwen、Llama 3.1+ 或 Mistral。';

  @override
  String get searxngSetup => 'SearXNG 设置';

  @override
  String get searxngDescription => 'SearXNG 是一个免费、尊重隐私的元搜索引擎，您可以自行托管。';

  @override
  String get dockerRecommended => '选项 1：Docker（推荐）';

  @override
  String get publicInstance => '选项 2：使用公共实例';

  @override
  String get findPublicInstances => '查找公共实例：';

  @override
  String get selfHostRecommended => '为了可靠性，建议使用自托管。';

  @override
  String get clipboardEmpty => '剪贴板是空的。首先复制您的 mcp.json 内容。';

  @override
  String get clipboardAccessFailed => '无法访问剪贴板。请手动粘贴到下面的字段中。';

  @override
  String get pasteFromClipboard => '从剪贴板粘贴';

  @override
  String get httpServersImportNote => 'HTTP 服务器 → 临时 MCP（根据请求发送到 LM Studio）';

  @override
  String get localMcpsImportNote => '本地 MCP → 集成 MCP（使用“mcp/名称”格式）';

  @override
  String get noValidMcpServers => '未找到有效的 MCP 服务器';

  @override
  String get serverAlreadyAdded => '该服务器已添加';

  @override
  String get themeSection => '主题';

  @override
  String get themeLabel => '主题';

  @override
  String get glassEffectsLabel => '玻璃效果';

  @override
  String get glassEffectsSubtitle => '标题和菜单的磨砂模糊。关闭后更凉快、更省电。';

  @override
  String get lowBatteryModeLabel => '低电量模式';

  @override
  String get lowBatteryModeSubtitle =>
      '关闭玻璃效果，流式回复时只用纯文本，并在整条消息完成后再同步 Home/iCloud。回复结束前屏幕保持唤醒，以免连接被切断。';

  @override
  String get backgroundSection => '背景';

  @override
  String get chatBackground => '墙纸';

  @override
  String get chatBackgroundSubtitle => '每次聊天背后的照片';

  @override
  String get avatarsSection => '图片';

  @override
  String get chatHeaderAvatarLabel => '脸在上面';

  @override
  String get chatHeaderAvatarSubtitle => '在聊天标题中显示小图片';

  @override
  String get avatarAboveMessageLabel => '消息上方图片';

  @override
  String get avatarAboveMessageSubtitle => '将脸部放在气泡顶部';

  @override
  String get fullWidthAssistantLabel => '回复铺满宽度';

  @override
  String get fullWidthAssistantSubtitle => '你的消息仍在气泡里。助手文字占满整行';

  @override
  String get tryFullWidthTitle => '试试新的全宽视图';

  @override
  String get tryFullWidthBody => '助手回复铺满整行，文字后面没有气泡。你可以随时在外观设置里改回去。';

  @override
  String get tryFullWidthOpenAppearance => '打开外观';

  @override
  String get tryFullWidthNotNow => '以后再说';

  @override
  String get streamingPhaseLoadingModel => '正在加载模型';

  @override
  String get streamingPhaseProcessingPrompt => '正在处理提示';

  @override
  String get streamingPhaseThinking => '思考中';

  @override
  String get streamingPhaseWriting => '正在写回复';

  @override
  String get streamingPhaseSearching => '正在搜索';

  @override
  String get streamingPhaseUsingTools => '正在使用工具';

  @override
  String streamingPhaseConnecting(String provider) {
    return '正在连接 $provider…';
  }

  @override
  String get networkOfflineTitle => '你已离线';

  @override
  String get networkOfflineBody => '请连接 Wi-Fi 或移动数据后重试。';

  @override
  String networkNeedsWifiTitle(String provider) {
    return '正在使用移动数据 — $provider 需要家里的 Wi-Fi';
  }

  @override
  String networkNeedsWifiBody(String provider, String host) {
    return '电脑上的 $provider（$host）只能通过家里的 Wi-Fi 访问。请连接该 Wi-Fi，或开启远程访问以便随时随地使用。';
  }

  @override
  String networkLostWifiTitle(String provider) {
    return '与 $provider 的连接已断开';
  }

  @override
  String get networkLostWifiBody =>
      '手机已断开 Wi-Fi。请重新连接家里的 Wi-Fi，或开启远程访问以便随时随地继续聊天。';

  @override
  String get networkUseRemoteAccess => '使用远程访问';

  @override
  String get networkSwitchProvider => '切换提供商';

  @override
  String get previewUserMessage => '这块主板是什么接口？';

  @override
  String get bubbleAvatarSizeLabel => '图片尺寸';

  @override
  String bubbleAvatarRadiusValue(int value) {
    return '尺寸$value';
  }

  @override
  String get userAvatarLabel => '你';

  @override
  String get yourProfilePicture => '你在聊天中的样子';

  @override
  String get assistantAvatarLabel => '人工智能';

  @override
  String get aiAssistantPicture => 'AI 的默认外观';

  @override
  String get chatBehaviorSection => '聊天文字';

  @override
  String get fontSizeLabel => '文字大小';

  @override
  String get iconSizeLabel => '纽扣尺寸';

  @override
  String pointsValue(int value) {
    return '$value';
  }

  @override
  String get previewLabel => '预览';

  @override
  String get previewAssistantMessage =>
      '你好！我是你的人工智能助手。今天我能为您提供什么帮助？这是一个**粗体**单词和一些“内联代码”。';

  @override
  String get readAloud => '大声朗读';

  @override
  String appearanceActionTapped(String label) {
    return '$label 点击';
  }

  @override
  String get autoScrollStreaming => '关注新回复';

  @override
  String get autoScrollStreamingSubtitle => '保持聊天内容为最新出现的单词';

  @override
  String get showChatStarters => '新的聊天建议';

  @override
  String get showChatStartersSubtitle => '在空聊天中显示滚动提示药丸';

  @override
  String get useLegacyComposer => '经典消息输入框';

  @override
  String get useLegacyComposerSubtitle => '使用经典紧凑输入框，而不是新的光泽输入框';

  @override
  String get hideAvatarsLabel => '隐藏图片';

  @override
  String get moreSpaceForContent => '给消息更多的空间';

  @override
  String get enterKeyBehaviorLabel => '输入键';

  @override
  String get enterKeyAutoDescription => '在电脑键盘上发送，在电话上换行';

  @override
  String get enterKeySendDescription => 'Enter 发送 · Shift+Enter 换行';

  @override
  String get enterKeyNewlineDescription => 'Enter 总是开始新行';

  @override
  String get sendLabel => '发送';

  @override
  String get newLineLabel => '新线';

  @override
  String get themeSystem => '系统';

  @override
  String get themeLight => '光';

  @override
  String get themeDark => '黑暗的';

  @override
  String get backLabel => '后退';

  @override
  String get nextLabel => '下一个';

  @override
  String get getStartedLabel => '开始使用';

  @override
  String get connectionSuccessful => '连接成功！';

  @override
  String get connectionFailedMessage => '连接失败';

  @override
  String get lmStudioServerFoundNeedsKey => '服务器已找到！在上面添加您的 API 密钥，然后点击“测试连接”。';

  @override
  String get lmStudioScanServerNeedsKey => '找到 — 添加 API 密钥以进行连接';

  @override
  String lmStudioUsingServerNeedsKey(String url) {
    return '使用$url。在下面添加您的 API 密钥，然后测试连接。';
  }

  @override
  String get lmStudioAuthDialogTitle => '找到服务器';

  @override
  String get lmStudioAuthDialogMessage =>
      '该服务器需要 API 密钥。将您的 LM Studio 令牌粘贴到下面以进行连接。';

  @override
  String get lmStudioAuthHelpHint =>
      '在 LM Studio 中，打开开发人员模式 → 服务器设置 → 管理令牌以创建或复制您的 API 密钥。';

  @override
  String get welcomeWizardTitle => '欢迎来到LM迷你';

  @override
  String get welcomeWizardSubtitle =>
      '通过 LM Studio 与本地网络上运行的 AI 模型聊天。让我们通过几个快速步骤即可完成设置。';

  @override
  String get welcomeWizardThemeTitle => '选择您的主题';

  @override
  String get welcomeWizardThemeSystemSubtitle => '匹配您的设备设置';

  @override
  String get welcomeWizardThemeLightSubtitle => '干净明亮';

  @override
  String get welcomeWizardThemeDarkSubtitle => '轻松护眼';

  @override
  String get welcomeWizardAppearanceTitle => '自定义外观';

  @override
  String get welcomeWizardAppearancePreviewMessage => '你好！这就是您的聊天消息的外观。';

  @override
  String get welcomeWizardServerTitle => '连接到 LM Studio';

  @override
  String get welcomeWizardServerSubtitle => '输入本地网络上运行 LM Studio 的计算机的 IP 地址。';

  @override
  String get welcomeWizardLocalNetworkNote => '当您测试连接时，iOS 会请求本地网络权限。请允许。';

  @override
  String get apiTokenOptionalLabel => 'API 令牌（可选）';

  @override
  String get welcomeWizardChangeLater => '您稍后可以随时在“设置”中更改此设置。';

  @override
  String get welcomeWizardFindModelTitle => '找到适合的型号';

  @override
  String get welcomeWizardFindModelSubtitle =>
      '比较两个选项，看看哪个在您的设置上更快。大约需要一分钟——如果您已经知道自己想要什么，则可以跳过。';

  @override
  String get welcomeWizardFindModelHelp => '帮我选一下';

  @override
  String get welcomeWizardFindModelSkip => '跳过——我自己选择';

  @override
  String get welcomeWizardExperienceTitle => '你如何使用人工智能？';

  @override
  String get welcomeWizardExperienceSubtitle => '我们将量身定制建议。您可以稍后更改一切。';

  @override
  String get welcomeWizardBeginnerTitle => '初学者';

  @override
  String get welcomeWizardBeginnerSubtitle => '保持简单 - 更清晰的设置，我们将为您的手机推荐可靠的型号。';

  @override
  String get welcomeWizardPowerTitle => '高级用户';

  @override
  String get welcomeWizardPowerSubtitle =>
      '完整设置以及选项 - 设备上模型和桌面服务器（例如 LM Studio）。';

  @override
  String get welcomeWizardSetupTitleBeginner => '选择模型';

  @override
  String get welcomeWizardSetupTitlePower => '选择您的设置';

  @override
  String get welcomeWizardSetupSubtitleBeginner => '点选模型即可下载。也可以通过 Wi‑Fi 连接电脑。';

  @override
  String get welcomeWizardSetupSubtitlePower => '选择型号或连接桌面服务器。';

  @override
  String get welcomeWizardOnDeviceSection => '在此设备上';

  @override
  String get welcomeWizardComputerSection => '在您的计算机上';

  @override
  String get welcomeWizardScanningWifi => '正在查看 Wi-Fi...';

  @override
  String welcomeWizardFoundCount(int count) {
    return '找到$count';
  }

  @override
  String get welcomeWizardModelFasterBlurb => '快速回复。非常适合日常聊天。';

  @override
  String get welcomeWizardModelBalancedBlurb => '速度和质量的良好平衡。';

  @override
  String get welcomeWizardModelBestBlurb => '适合您设备的最强品质。';

  @override
  String get welcomeWizardNameTitle => 'AI 应该怎么称呼你？';

  @override
  String get welcomeWizardNameSubtitle => '名字或昵称是完美的。你可以跳过这个。';

  @override
  String get welcomeWizardNameHint => '例如亚历克斯';

  @override
  String get welcomeWizardFinish => '结束';

  @override
  String get welcomeWizardContinue => '继续';

  @override
  String get welcomeWizardSkip => '跳过';

  @override
  String get welcomeWizardConnectLmStudio => '连接LM工作室';

  @override
  String get welcomeWizardConnectOllama => '连接奥拉马';

  @override
  String get welcomeWizardConnectOmlx => '连接oMLX';

  @override
  String get pickColor => '选择颜色';

  @override
  String get hueLabel => '色调';

  @override
  String get saturationLabel => '饱和';

  @override
  String get lightnessLabel => '亮度';

  @override
  String get alphaLabel => '阿尔法';

  @override
  String get hexLabel => '十六进制';

  @override
  String get personaModeLabel => '角色模式';

  @override
  String get personaModeSubtitle => '添加头像、强调色、声音和群聊首选模型';

  @override
  String get avatarLabel => '阿凡达';

  @override
  String get customAvatarSet => '自定义头像集';

  @override
  String get noAvatar => '无头像';

  @override
  String get accentColorLabel => '强调色';

  @override
  String get defaultLabel => '默认';

  @override
  String get preferredModelLabel => '首选型号';

  @override
  String get preferredModelAny => '无（使用任何）';

  @override
  String get personaChooseProviderTitle => '选择提供方';

  @override
  String get personaChooseProviderSubtitle => '已配置的提供方。可在设置中添加更多。';

  @override
  String get personaCloudProvidersSection => '云提供方';

  @override
  String get personaKokoroVoiceLabel => '心的声音';

  @override
  String get personaKokoroVoiceSubtitle => '该角色说话时使用的语音（语音聊天/朗读）';

  @override
  String get personaKokoroVoiceGlobal => '使用全局语音设置';

  @override
  String get personaKokoroVoicePickerTitle => '角色声音';

  @override
  String get personaKokoroSpeedLabel => '语速';

  @override
  String get personaKokoroSpeedGlobal => '使用全球速度';

  @override
  String personaKokoroSpeedValue(String speed) {
    return '${speed}x';
  }

  @override
  String get voiceWhisperModelLabel => '耳语模型';

  @override
  String get voiceWhisperModelTapToChoose => '点击选择尺寸并下载';

  @override
  String get imageGenSeedLabel => '图像生成种子';

  @override
  String imageGenSeedFixed(int seed) {
    return '固定种子：$seed';
  }

  @override
  String get imageGenSeedRandomGlobal => '随机（使用全局设置）';

  @override
  String get personaComfyWorkflowLabel => 'ComfyUI 工作流程';

  @override
  String get personaComfyWorkflowUseGlobal => '使用全局设置';

  @override
  String personaComfyWorkflowUnavailable(String path) {
    return '$path（目前不可用）';
  }

  @override
  String get personaComfyWorkflowHelper =>
      '当图像生成提供程序是 ComfyUI 时使用。保留为全局以使用“设置”→“图像生成”。';

  @override
  String get personaComfyWorkflowNotComfy => '仅当 ComfyUI 是活动图像提供程序时，此分配才适用。';

  @override
  String get personaComfyWorkflowRefresh => '刷新工作流程';

  @override
  String get personaComfyWorkflowJsonLabel => '自定义工作流 JSON（可选）';

  @override
  String get personaComfyWorkflowJsonHint => '留空则使用全局 / 内置工作流';

  @override
  String get personaComfyWorkflowJsonHelper =>
      '粘贴 API 格式工作流。支持 %PROMPT%、%LORA%、%LORA_WEIGHT% 等占位符。';

  @override
  String get personaComfyWorkflowJsonIgnored => '已选择已保存工作流时忽略';

  @override
  String personaComfyWorkflowJsonActive(int count) {
    return '使用自定义工作流（$count 字符）';
  }

  @override
  String get personaComfyWorkflowJsonClear => '清除（使用全局 / 默认）';

  @override
  String get comfyUiDetails => 'ComfyUI 详情';

  @override
  String get comfyUiDetailsTitle => 'ComfyUI 请求';

  @override
  String get comfyUiDetailsCopy => '复制 JSON';

  @override
  String get comfyUiDetailsCopied => '已复制到剪贴板';

  @override
  String get resetToGlobal => '重置为全局';

  @override
  String get setSeed => '设定种子';

  @override
  String get pickAccentColor => '选择强调色';

  @override
  String get imageGenSeedDialogDescription => '设置固定种子，以便该角色始终生成一致的图像。留空为随机。';

  @override
  String get seedValueLabel => '种子价值';

  @override
  String get seedValueHint => '例如42（空白=随机）';

  @override
  String get setLabel => '放';

  @override
  String get selectPreferredModelTitle => '选择首选型号';

  @override
  String get branchCreated => '🔀 分支已创建';

  @override
  String get yamlFrontmatter => 'YAML 前沿问题';

  @override
  String get markdownFormat => '降价';

  @override
  String get localNetworkBlocked => '本地网络访问可能被阻止';

  @override
  String get localNetworkFix => '进入设置 → LM Mini → 本地网络并启用它。';

  @override
  String get openAppSettings => '打开应用程序设置';

  @override
  String get memorySaved => '内存已保存';

  @override
  String get proSearch => '专业搜索';

  @override
  String get webSearchLabel => '网页搜索';

  @override
  String get readUrl => '读取网址';

  @override
  String get code => '代码';

  @override
  String couldNotOpenFile(String error) {
    return '无法打开文件：$error';
  }

  @override
  String get tapOpenExternal => '点击“使用外部应用程序打开”即可查看该文件';

  @override
  String get proSearchEnabled => '专业搜索已启用';

  @override
  String get proSearchDisabled => '专业搜索已禁用';

  @override
  String get thinkingEnabled => '此聊天已开启思维';

  @override
  String get thinkingDisabled => '此聊天已关闭思维';

  @override
  String get codeSandbox => '代码沙箱';

  @override
  String get codeSandboxSubtitle => '在安全沙箱中运行 Python 或 JavaScript';

  @override
  String get codeSandboxEnabled => '代码沙盒已启用';

  @override
  String get codeSandboxDisabled => '代码沙盒已禁用';

  @override
  String get searxngNotConfigured => '添加 SearXNG URL 以启用';

  @override
  String get searxngConfiguredOff => '已配置 — 点击即可使用而不是 Pro Search';

  @override
  String get searxngConfigureFirst => '启用前配置 SearXNG URL';

  @override
  String get editSearxng => '编辑 SearXNG';

  @override
  String get toolCallingLabel => '工具调用';

  @override
  String get on => '在';

  @override
  String get off => '离开';

  @override
  String get aiCanUseTools => 'AI可以在这次聊天中使用工具';

  @override
  String get toolsDisabledChat => '此聊天已禁用工具';

  @override
  String get webSearchChat => '网页搜索';

  @override
  String get aiCanSearchWeb => 'AI可以在这个聊天中搜索网络';

  @override
  String get webSearchDisabledChat => '此聊天已禁用网络搜索';

  @override
  String get disableMemory => '禁用记忆';

  @override
  String memoryItemsActive(int count) {
    return '$count 记忆活跃';
  }

  @override
  String get memoryDisabledChat => '此聊天的记忆被禁用。 AI 不会看到您保存的项目。';

  @override
  String get lmStudioLocal => 'LM Studio（本地）';

  @override
  String get modelNoLongerAvailable => '之前选择的型号不再可用。请选择新型号。';

  @override
  String get noModelsForProvider => '没有找到该提供商的型号。检查 API 密钥。';

  @override
  String get noModelsCheckConnection => '没有找到型号。检查 LM Studio 连接。';

  @override
  String get selectModel => '选择型号';

  @override
  String get goToModels => '前往型号';

  @override
  String get reviewImagePrompt => '查看图像提示';

  @override
  String get editImagePromptHint => '编辑图像提示...';

  @override
  String get generate => '产生';

  @override
  String get imageNotFound => '找不到图片';

  @override
  String get cameraPermissionNeeded => '需要相机许可';

  @override
  String get cameraPermissionExplain => '请允许相机访问以拍摄照片以进行视觉分析。';

  @override
  String get photosPermissionNeeded => '需要照片许可';

  @override
  String get photosPermissionExplain => '请允许访问您的图像以进行视觉分析。';

  @override
  String couldNotOpenFilePicker(String error) {
    return '无法打开文件选择器：$error';
  }

  @override
  String get filePickerCouldNotCopy => '无法复制该文件。请先保存到本机（不要用网盘或最近项目），然后再选一次。';

  @override
  String get signInToUseCloudBackup => '登录使用云备份';

  @override
  String get cloudBackupRequiresAccount => '云备份需要一个帐户，以便您的加密备份以您的身份安全地存储。';

  @override
  String get arguments => '论点';

  @override
  String get selectLanguage => '选择语言';

  @override
  String get connectionPopupTitle => '选择提供商';

  @override
  String get connectionPopupBody => '连接 LM Studio、选择设备上模型或在“设置”中登录云提供商。';

  @override
  String get connectionPopupDismiss => '之后';

  @override
  String get connectionPopupGoToSettings => '前往“设置”';

  @override
  String get remoteAccess => '远程访问';

  @override
  String get scanQrCode => '扫描二维码';

  @override
  String get connectedViaLmConnect => '通过 LM Connect 连接';

  @override
  String get disconnectRemoteToChangeSettings =>
      '远程 LM Studio 通过 LM Connect 配对';

  @override
  String get disconnect => '断开';

  @override
  String get unpair => '取消配对';

  @override
  String get useRemoteConnection => '用这台 Mac 聊天';

  @override
  String get useRemoteConnectionOffSubtitle =>
      '关闭 — 手机使用自己的模型。打开后使用 LM Mini Home 上的模型。';

  @override
  String get connectedViaLmStudio => '通过 LM Studio 连接';

  @override
  String get usingLocalServer => '使用本地服务器';

  @override
  String get testing => '测试...';

  @override
  String connectedLatency(int ms) {
    return '已连接 — ${ms}ms';
  }

  @override
  String get notConnected => '未连接';

  @override
  String get scanQrDescription =>
      '从 Mac 上的 LM Mini（与手机共享）或旧版 LM Mini Connect 扫描二维码，即可从任何地方访问您的桌面模型。';

  @override
  String get remotePaired => '远程配对';

  @override
  String lastConnected(String time) {
    return '最后连接：$time';
  }

  @override
  String get reScanQrCode => '重新扫描二维码';

  @override
  String get qrRequiresPro => '二维码扫描需要LM Mini Pro';

  @override
  String get enterUrlManually => '手动输入网址';

  @override
  String get enterUrlManuallySubtitle => '无法使用相机时，粘贴配对链接';

  @override
  String get relayUrlHint => 'https://relay.lmmini.com/s/…';

  @override
  String get connectWithUrl => '使用网址连接';

  @override
  String get invalidRelayUrl => '这不是有效的 LM Mini 配对链接。请从 Mac 上的“与手机共享”复制。';

  @override
  String get invalidQrCode =>
      '二维码无效。在 Mac 上的 LM Mini（或旧版 Connect）中打开与手机共享以生成一个。';

  @override
  String get pointCameraAtQr => '将相机对准 Mac 上 LM Mini 中显示的二维码（与手机共享）';

  @override
  String get connectedToRemoteLmStudio => '已连接到远程 LM Studio！';

  @override
  String get failedToConnect =>
      '连接失败。确保 Mac 上的 LM Mini 已启用与手机共享（或旧版 Connect 正在运行）。';

  @override
  String get unpairRemote => '取消遥控器配对';

  @override
  String get unpairRemoteDescription => '这将删除已保存的远程连接。您可以通过扫描新的二维码重新配对。';

  @override
  String get setupGuide => '设置指南';

  @override
  String get downloadLmMiniConnect => '获取 LM Mini Home';

  @override
  String get availableForPlatforms => 'Mac 直接下载 · Windows 和 Linux 使用 Connect';

  @override
  String get setupStep1Title => '下载 LM Mini Home';

  @override
  String get setupStep1Desc =>
      '从 lmmini.com 下载 Mac 版 LM Mini Home。Windows 和 Linux 仍可使用 LM Mini Connect。';

  @override
  String get setupStep2Title => '与手机分享';

  @override
  String get setupStep2Desc => '在 Mac 上的 LM Mini Home 中打开“与手机共享”并开启。它会立即连接到中继。';

  @override
  String get setupStep3Title => '扫描二维码';

  @override
  String get setupStep3Desc => '扫描 Mac 上显示的二维码。就是这样！';

  @override
  String minutesAgo(int count) {
    return '${count}m 前';
  }

  @override
  String hoursAgo(int count) {
    return '$count小时前';
  }

  @override
  String daysAgo(int count) {
    return '$count天前';
  }

  @override
  String get selectAll => '选择全部';

  @override
  String get moveToFolder => '移至文件夹';

  @override
  String get select => '选择';

  @override
  String get dismissAction => '解雇';

  @override
  String get createNewFolder => '创建新文件夹';

  @override
  String deleteConversations(int count) {
    return '删除 $count 个对话？此操作无法撤消。';
  }

  @override
  String get averages => '平均值';

  @override
  String get tokensPerChat => '代币/聊天';

  @override
  String get msgsPerChat => '消息/聊天';

  @override
  String get tokensPerMsg => '代币/消息';

  @override
  String get topModel => '顶级模特';

  @override
  String get liveActivityTitle => '现场活动';

  @override
  String get liveActivityTitleAndroid => '背景生成';

  @override
  String get liveActivityDescription => '处理你的人工智能即使您退出应用程序或锁定应用程序也可以请求';

  @override
  String get liveActivityDescriptionAndroid =>
      '当您离开应用程序时继续生成 - 设备上模型、LM Studio 和云提供商。显示带有进度的静默持续通知，并使 HTTP 流在 Android 上保持活动状态。';

  @override
  String get liveActivityAndroidOnDeviceOnly =>
      '切换到设备上的 GGUF 或 MLX 模型以在 Android 上使用后台生成。';

  @override
  String get liveActivityNotificationDenied => 'Android 上的后台生成需要通知权限。';

  @override
  String get premiumRemoteAccess => '远程访问';

  @override
  String get premiumRemoteAccessTagline => '随时随地的 LM Studio';

  @override
  String get premiumRemoteAccessDescription =>
      '从任何地方访问您的 Mac 或 PC 模型。在 Mac 上，使用 LM Mini → 与手机共享。无端口转发或 VPN — 扫描二维码以获取加密中继。';

  @override
  String get premiumLiveActivity => '现场活动';

  @override
  String get premiumLiveActivityTagline => '人工智能。在后台运行';

  @override
  String get premiumLiveActivityDescription =>
      '处理你的人工智能即使您退出应用程序或锁定手机时也会发出请求。在锁定屏幕和动态岛上查看实时生成进度 - 无需切换即可查看代币计数和生成速度。';

  @override
  String get premiumWebSearchTagline => '无需服务器设置';

  @override
  String get premiumWebSearchDescription =>
      '在对话期间立即搜索网络。由云搜索 API 提供支持 — 无需自行托管 SearXNG 或配置任何内容。只需询问，您的模型就会从互联网上获取新鲜的实时信息。';

  @override
  String get premiumCloudBackup => '加密云备份';

  @override
  String get premiumCloudBackupTagline => 'AES-256-GCM 加密';

  @override
  String get premiumCloudBackupDescription =>
      '使用军用级加密将所有对话备份到云端。您的密码永远不会离开您的设备 - 即使我们也无法读取您的数据。一键在任何设备上恢复。';

  @override
  String get premiumUrlReader => '网址阅读器';

  @override
  String get premiumUrlReaderTagline => '分析任何网页';

  @override
  String get premiumUrlReaderDescription =>
      '粘贴任何 URL，您的模型就会读取整个页面内容。总结文章、分析文档、从表格中提取数据——所有这些都无需离开对话。';

  @override
  String get premiumBranching => '对话分支';

  @override
  String get premiumBranchingTagline => '探索替代路径';

  @override
  String get premiumBranchingDescription =>
      '从任何消息中分叉任何对话，以探索“假设”场景。比较不同的提示，尝试不同的方法，并保留最好的线索 - 所有这些都不会丢失原始线索。';

  @override
  String get premiumMemory => '回忆';

  @override
  String get premiumMemoryTagline => '在聊天中记住你';

  @override
  String get premiumMemoryDescription =>
      '保存所有对话中持续存在的事实、偏好和背景。每次你开始新的聊天时，你的模型都会知道你的名字、编码风格、首选语言以及你教给它的任何其他内容。';

  @override
  String get premiumAnalytics => '分析仪表板';

  @override
  String get premiumAnalyticsTagline => '了解您的使用情况';

  @override
  String get premiumAnalyticsDescription =>
      '跟踪使用的令牌、发送的消息、模型使用细分和平均响应时间。了解您的 AI 使用模式并通过精美的图表优化您的工作流程。';

  @override
  String get premiumCloudApi => '云API提供商';

  @override
  String get premiumCloudApiTagline => 'Mistral、Anthropic 等';

  @override
  String get premiumCloudApiDescription =>
      '连接到云 LLM 提供商以及您的本地模型。当您需要尖端性能时，请使用 Claude、Gemini 和 Mistral — 在本地和云之间无缝切换。';

  @override
  String get premiumExport => '丰富的导出和分享';

  @override
  String get premiumExportTagline => '黑曜石、笔记、概念等';

  @override
  String get premiumExportDescription =>
      '将对话导出为格式精美的 Markdown、PDF 或纯文本。直接分享到 Obsidian、Apple Notes、Notion 或任何应用程序。非常适合保存研究和见解。';

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
  String get premiumOnDeviceLlm => '设备上专业版';

  @override
  String get premiumOnDeviceLlmTagline => '更大的目录型号和高频进口';

  @override
  String get premiumOnDeviceLlmDescription =>
      '通过精选的入门模型，可以免费进行设备上聊天。 Pro 解锁超过 2B 参数的目录下载，并从 Hugging Face 导入您自己的 GGUF 或 MLX 模型 - 浏览、选择量化并完全离线运行。';

  @override
  String get premiumHfBrowse => '拥抱脸部导入';

  @override
  String get premiumHfBrowseTagline => '将任何 GGUF 模型带上车';

  @override
  String get premiumHfBrowseDescription =>
      '搜索 Hugging Face，将 GGUF 模型下载到您的设备或 LM Studio 服务器，并在 LM Mini 中运行它们。过滤兼容性、跟踪后台下载并扩展到免费目录之外 - 无需 API 密钥。';

  @override
  String get onDeviceProviderLabel => '设备上';

  @override
  String get onDeviceManageModels => '管理设备上模型';

  @override
  String get onDeviceGeneratingHint => '在设备上生成...';

  @override
  String get onDeviceEngineUnavailable => '设备上的引擎不可用';

  @override
  String get onDeviceOpenBrowser => '打开设备上的模型';

  @override
  String get onDeviceManagedHere => '设备上的模型在专用浏览器中进行管理，您可以在其中下载、删除和激活它们。';

  @override
  String get onDeviceRemoteImageOnly =>
      '选择设备上的 AI — 远程访问仅支持图像生成和 Kokoro 语音（如果已配置）。聊天保留在此设备上。';

  @override
  String get onDeviceProOnly => '仅限专业版';

  @override
  String get onDeviceInstalled => '已安装';

  @override
  String get onDeviceUseModel => '使用';

  @override
  String get onDeviceRemoveModel => '消除';

  @override
  String get onDeviceDownloadAnyway => '无论如何下载';

  @override
  String onDeviceNowUsing(String name) {
    return '现在在设备上使用 $name';
  }

  @override
  String get onDeviceEngineFllamaLabel => '羊驼 (GGUF)';

  @override
  String onDeviceEngineSwitched(String engine) {
    return '切换到$engine。以前的模型被卸载了。';
  }

  @override
  String onDeviceEngineSwitchedCleared(String engine) {
    return '切换到$engine。您之前的型号与此引擎不兼容，已被取消选择 - 在设备上型号中选择一个。';
  }

  @override
  String get onDeviceImportedLabel => '进口';

  @override
  String get onDeviceFreeLabel => '自由的';

  @override
  String get onDeviceProLabel => '专业版';

  @override
  String get onDeviceMayCrashLabel => '可能会崩溃';

  @override
  String get onDeviceModelMayCrashTitle => '该模型可能会崩溃';

  @override
  String onDeviceModelMayCrashMessage(
      String name, String runtimeGb, String deviceRamGb) {
    return '运行时$name大约需要${runtimeGb}GB内存。您的设备大约有 $deviceRamGb GB 可用于应用程序。无论如何加载可能会冻结或崩溃应用程序。';
  }

  @override
  String get onDeviceContinueLoading => '继续加载';

  @override
  String get yearly => '每年';

  @override
  String get monthly => '每月';

  @override
  String get lifetime => '寿命';

  @override
  String get subscriptionLifetimeBadge => '支付一次';

  @override
  String get subscriptionLifetimeDisclaimer =>
      '一次性购买。在提供和维护 LM Mini 的同时，您的帐户上还可以使用 Pro 功能。不包括第三方 API 费用，并可能不包括单独托管的服务 - 请参阅条款。';

  @override
  String subscriptionLifetimeUpgradeDisclaimer(String store) {
    return '终身是单独的一次性购买。您当前的订阅不会自动取消，我们也无法退还过去的订阅费用。购买后，在$store取消订阅。';
  }

  @override
  String get subscriptionUpgradeToLifetime => '升级至终身';

  @override
  String subscriptionUpgradeToLifetimeSubtitle(String price) {
    return '支付一次 — $price';
  }

  @override
  String get duplicateSubscriptionDialogTitle => '取消您的订阅';

  @override
  String duplicateSubscriptionDialogBody(String store) {
    return '您拥有 Lifetime Pro 和有效的订阅。终身不会自动替换您的订阅，并且我们无法退还订阅费用。请在$store取消订阅，以避免进一步计费。';
  }

  @override
  String duplicateSubscriptionDialogManage(String store) {
    return '打开$store';
  }

  @override
  String get duplicateSubscriptionDialogDismiss => '知道了';

  @override
  String get duplicateSubscriptionNoManageUrl => '打开您的设备订阅设置以取消。';

  @override
  String supportLifetime(String price) {
    return '永久解锁 — $price';
  }

  @override
  String get encryptionKey => '加密密钥';

  @override
  String get encryptionEnabled => '加密：开启';

  @override
  String get encryptionDisabled => '加密：关闭';

  @override
  String get encryptionKeyDescription =>
      '用于远程访问的端到端加密密钥。必须与 LM Mini Connect 中的密钥匹配。';

  @override
  String get editEncryptionKey => '编辑加密密钥';

  @override
  String get enterEncryptionKey => '输入加密密钥';

  @override
  String get encryptionKeyUpdated => '加密密钥已更新';

  @override
  String get keepLmMiniAlive => '保留 LM 迷你\n活着';

  @override
  String get supportTheApp => '支持该应用程序并获得额外福利';

  @override
  String get mostFeaturesFree => '大多数功能都是免费的 - Pro 有助于支付服务器成本';

  @override
  String get thankYouSupport => '感谢您的支持！';

  @override
  String get helpingKeepAlive => '你正在帮助 LM Mini 生存';

  @override
  String get linkSignInMethod => '链接登录方法以在您切换设备时保留您的订阅。';

  @override
  String get paywallLinkAccountBody =>
      '您使用的是匿名帐户。在购买前链接 Apple 或 Google，以便 Pro 可以跨设备同步并在重新安装后继续存在。';

  @override
  String get continueAnonymously => '匿名继续';

  @override
  String signedInViaMethod(String method) {
    return '通过$method登录';
  }

  @override
  String get yourSubscriptionSecured => '您的订阅已受到保护';

  @override
  String subscriptionManagedThrough(String store) {
    return '订阅通过$store管理。';
  }

  @override
  String get subscriptionsComingSoon => '订阅即将推出';

  @override
  String get premiumPreview => '高级功能正在最终确定中。\n您可以启用下面的开发者模式来预览它们。';

  @override
  String get enableDeveloperPremium => '启用开发者高级版';

  @override
  String get disableDeveloperPremium => '禁用开发者高级版';

  @override
  String get premiumEnabled => '启用高级版（开发覆盖）';

  @override
  String get premiumDisabled => '高级版已禁用';

  @override
  String supportYearly(String price) {
    return '支持 — $price/年';
  }

  @override
  String supportMonthly(String price) {
    return '支持 — $price/月';
  }

  @override
  String get welcomeToLmMiniPro => '欢迎来到LM Mini Pro！';

  @override
  String get connectedRemotely => '远程连接';

  @override
  String get pairedNotActive => '已配对 — 未激活';

  @override
  String get accessLmStudioAnywhere => '从任何地方访问 LM Studio';

  @override
  String get appStore => '应用商店';

  @override
  String get googlePlayStore => '谷歌应用商店';

  @override
  String get starterAttach => '附';

  @override
  String get starterImages => '图片';

  @override
  String get starterMode => '模式';

  @override
  String get newGroupChat => '新群聊';

  @override
  String get groupChat => '群聊';

  @override
  String get groupChatMultipleModels => '与多个模特聊天';

  @override
  String get groupChatParticipants => '参加者';

  @override
  String get groupChatTurnMode => '转弯模式';

  @override
  String get groupChatRoundRobin => '循环赛';

  @override
  String get groupChatManual => '手动的';

  @override
  String get groupChatParallelStreaming => '并行流';

  @override
  String get groupChatAutoLoadUnload => '自动加载/卸载';

  @override
  String get groupChatStreamAllSimultaneously => '同时直播所有参与者';

  @override
  String get groupChatAutoLoadModels => '需要时自动加载模型';

  @override
  String get groupChatAsk => '问：';

  @override
  String get groupChatTapToReplyNudge => '点选要回复的人';

  @override
  String get groupChatTrialBannerTitle => '群聊 — 7 天免费！';

  @override
  String get groupChatTrialBannerBody =>
      '免费试用最多 2 个 AI 角色的群聊 7 天。升级到 LM Mini Pro 即可获得无限制的参与者和永久访问权限。';

  @override
  String groupChatTrialDaysLeft(int days) {
    return '试用期还剩 $days 天';
  }

  @override
  String get groupChatTrialExpired => '您的 7 天群聊试用期已结束。升级到专业版以继续。';

  @override
  String get groupChatTrialGetPro => '获取专业版';

  @override
  String get groupChatTrialDismiss => '知道了';

  @override
  String get groupChatBetaTitle => '群聊';

  @override
  String get groupChatBetaSubtitle => '一次谈话。多个人工智能头脑。';

  @override
  String get groupChatBetaPremiumNote => '群聊目前处于测试阶段，所有人都可以免费预览';

  @override
  String get groupChatBetaBugReport => '发现错误？转到“设置”→“功能请求和支持”来报告问题并获得优先帮助。';

  @override
  String get groupChatBetaFreeNote =>
      '您可以免费访问最多 2 个角色 7 天。升级到专业版以获得无限的角色和永久访问权限。';

  @override
  String get groupChatBetaFeaturePersona => '每个角色都有自己的模型';

  @override
  String get groupChatBetaFeatureSystem => '每个系统提示都有独特的个性';

  @override
  String get groupChatBetaFeatureConvo => '多合一共享对话';

  @override
  String get groupChatBetaStartFree => '开始免费试用';

  @override
  String get groupChatBetaStartPremium => '尝试群聊';

  @override
  String get groupChatBetaLearnMore => '获取专业版';

  @override
  String get premiumGroupChat => '群聊';

  @override
  String get premiumGroupChatTagline => '多人对话';

  @override
  String get premiumGroupChatDescription =>
      '在一个线程中与多个人工智能角色聊天——每个角色都有自己的模型、头像和个性。自由设置；发送消息需要LM Mini Pro。';

  @override
  String get groupChatProRequiredTitle => '群聊需要专业版';

  @override
  String get groupChatProRequiredBody =>
      '您可以免费设置群聊。升级到 LM Mini Pro 即可使用多个 AI 角色开始聊天和发送消息。';

  @override
  String get groupChatProRequiredUpgrade => '升级到专业版';

  @override
  String get groupChatLockedBanner => '群聊在没有 Pro 的情况下是只读的。升级以发送新消息。';

  @override
  String get premiumArena => '竞技场';

  @override
  String get premiumArenaTagline => '并排比较模型';

  @override
  String get premiumArenaDescription =>
      '寻找您的模型是免费的。 Pro 可以解锁自定义提示比赛、竞技场中的云模型以及带有图表的私人比赛历史记录。';

  @override
  String get startLabel => '开始';

  @override
  String groupChatInviteUpTo(int count) {
    return '邀请最多$count位AI模特一起聊天。每个人都可以有自己的角色、头像和系统提示。';
  }

  @override
  String get groupChatPremiumParticipantsNote => 'Premium 允许每个群聊最多 5 名参与者。';

  @override
  String get groupChatUserNameHint => 'AI 将如何称呼您（例如 Alex）';

  @override
  String get groupChatScenarioLabel => '场景/关于你自己（可选）';

  @override
  String get groupChatScenarioHint => '例如“我们是一家科技初创公司的同事。我是一名产品经理，向团队寻求建议。”';

  @override
  String get groupChatTurnModeRoundRobinDescription => '循环法——所有模型按顺序响应';

  @override
  String get groupChatTurnModeManualDescription => '手动 — 输入 @Name 以选择回复者';

  @override
  String get groupChatReplyToUserOnlyLabel => '只回复你一个';

  @override
  String get groupChatReplyToUserOnlySubtitle => '每个人工智能都会忽略其他人工智能——最适合较小的模型';

  @override
  String get groupChatWhosInChat => '谁在聊天？';

  @override
  String get groupChatTapToInvite => '点按下面的人员即可邀请他们';

  @override
  String get groupChatAddPeople => '添加人员';

  @override
  String get groupChatInTheRoom => '在房间里';

  @override
  String get groupChatNeedTwo => '至少添加 2 个以开始';

  @override
  String get groupChatTakeTurnsTitle => '轮流';

  @override
  String get groupChatTakeTurnsSubtitle => '大家按顺序依次回答';

  @override
  String get groupChatTalkMentionedTitle => '提及时说话';

  @override
  String get groupChatTalkMentionedSubtitle => '如果一个人工智能命名另一个人工智能，那个人就可以加入';

  @override
  String get groupChatIChooseTitle => '我选择谁发言';

  @override
  String get groupChatIChooseSubtitle => '只有您@提及的人回复';

  @override
  String get groupChatHowTheyTalk => '他们如何说话';

  @override
  String get groupChatAboutYou => '关于你';

  @override
  String get groupChatSceneLabel => '场景（可选）';

  @override
  String get groupChatSceneHint => '例如我们是同事集思广益的产品创意';

  @override
  String get groupChatAutoLoadTitle => '节省本地模型的内存';

  @override
  String get groupChatAutoLoadSubtitle =>
      '在加载下一个模型之前卸载一个模型 - 当人们使用不同的 LM Studio、Ollama 或设备上模型时很有帮助';

  @override
  String get groupChatMoreOptions => '更多选择';

  @override
  String get groupChatHelpTooltip => '群聊的工作原理';

  @override
  String get groupChatHelpTitle => '群聊的工作原理';

  @override
  String get groupChatHelpIntro => '邀请至少两名 AI 人员参与一场对话。每个人都可以使用不同的模型和个性。';

  @override
  String get groupChatHelpTakeTurns => '轮流：每个人工智能按顺序回答你的消息。';

  @override
  String get groupChatHelpMentioned => '提及时说话：有人回复后，如果被点名，另一个人工智能可以继续。';

  @override
  String get groupChatHelpManual => '我选择谁发言：使用@Name，这样只有那个人回复。';

  @override
  String get groupChatHelpMemory =>
      '节省内存：对于本地模型，请先卸载前一个模型，然后再加载下一个模型，这样 RAM 较少的手机和 PC 仍然可以运行组。';

  @override
  String get groupChatHelpProvider => '点击房间中的某个人即可随时更改其提供商和型号。';

  @override
  String get groupChatStartProGate => '需要专业版才能启动';

  @override
  String get groupChatFixBeforeStart => '在开始之前修复突出显示的人物。';

  @override
  String get groupChatEditPerson => '编辑人物';

  @override
  String get groupChatProviderAndModel => '供应商和型号';

  @override
  String get groupChatChooseProviderModel => '选择提供商和型号';

  @override
  String get groupChatParallelEasy => '同时回复';

  @override
  String get groupChatParallelEasySubtitle => '当多个人工智能需要回答时，将它们集中在一起';

  @override
  String get noModelsAvailableConnectLmStudio => '无可用型号。首先连接到 LM Studio。';

  @override
  String get addModelLabel => '添加型号';

  @override
  String modelNumber(int number) {
    return '型号$number';
  }

  @override
  String groupChatParticipantInfo(String name, String model) {
    return '$name\n型号：$model';
  }

  @override
  String get customPromptSet => '自定义提示设置';

  @override
  String get removeLabel => '消除';

  @override
  String get displayNameLabel => '显示名称';

  @override
  String get displayNameHint => '例如教授、程序员、艺术家';

  @override
  String get customRequestHeaders => '自定义请求标头';

  @override
  String get customRequestHeadersSubtitle => '添加到每个 LM Studio 请求的可选标头';

  @override
  String get customRequestHeadersHelp =>
      '将此用于需要额外标头的反向代理或身份验证网关（例如 Cloudflare Access 服务令牌、自定义标头名称下的内部令牌等）。每个请求的标头都会发送到 LM Studio 服务器。';

  @override
  String get cloudflareAccessSection => 'Cloudflare 访问（服务令牌）';

  @override
  String get cloudflareAccessHelp =>
      '如果您的 LM Studio 采用 Cloudflare 访问策略，请将服务令牌客户端 ID 和密钥粘贴到此处。它们在每次请求时作为 CF-Access-Client-Id 和 CF-Access-Client-Secret 发送，因此应用程序无需交互式浏览器 SSO 登录即可进行身份验证。';

  @override
  String get cfAccessClientIdLabel => 'CF-Access-客户端 ID';

  @override
  String get cfAccessClientSecretLabel => 'CF-访问-客户端秘密';

  @override
  String get addHeader => '添加标题';

  @override
  String get removeHeader => '删除标题';

  @override
  String get headerNameLabel => '标头名称';

  @override
  String get headerValueLabel => '标头值';

  @override
  String headersConfigured(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已配置 $count 个请求头',
      one: '已配置 1 个请求头',
    );
    return '$_temp0';
  }

  @override
  String get noCustomHeaders => '没有自定义标头';

  @override
  String get comfyUiUseNegativePromptTitle => '使用否定提示';

  @override
  String get comfyUiUseNegativePromptSubtitle =>
      'ComfyUI 默认关闭。关闭时，不会向工作流程发送否定提示。';

  @override
  String get documentationTitle => '文档';

  @override
  String get documentationSubtitle => '群聊、ComfyUI、键盘行为等设置指南';

  @override
  String get changelogTitle => '变更日志';

  @override
  String get changelogSubtitle => '版本历史及更新';

  @override
  String get enableCustomHeaders => '启用自定义标头';

  @override
  String get enableCustomHeadersSubtitle => '为每个 LM Studio 请求附加额外的 HTTP 标头';

  @override
  String deleteMemoriesCount(int count) {
    return '删除$count条记忆？';
  }

  @override
  String get deleteMemoriesConfirm => '这些记忆将被永久删除。';

  @override
  String get moveToCategory => '移至类别';

  @override
  String nSelected(int count) {
    return '$count 已选择';
  }

  @override
  String movedToCategory(String category) {
    return '移至$category';
  }

  @override
  String get moveCategoryTooltip => '移动类别';

  @override
  String get memoryScreenSubtitle => '人工智能会在聊天过程中记住有关您的事实。';

  @override
  String get rememberMe => '记住账号';

  @override
  String get rememberMeSubtitle => '在以后的对话中使用保存的笔记';

  @override
  String get memoryPerPersona => '每个角色';

  @override
  String get memoryPerPersonaSubtitle => '仅共享活跃角色（和全局角色）的注释';

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
  String get memoryBrowseSection => '浏览';

  @override
  String get memoryMultiSelectTip => '提示：长按一个音符可以选择多个。';

  @override
  String get memoryEmptyFilteredHint => '添加注释，或选择其他类别。';

  @override
  String get memoryEmptyHint => '保存一些关于你自己的信息——姓名、偏好、项目——这样聊天就会感觉很私人。';

  @override
  String get memoryShareWith => '分享给';

  @override
  String get memoryEveryone => '每个人';

  @override
  String get memoryEveryoneSubtitle => '在每个聊天中都可用';

  @override
  String get memoryNoPersonasHint => '还没有人物角色。在“设置”→“角色”中创建一个。';

  @override
  String get memoryNewNote => '新笔记';

  @override
  String get memoryNoteHint => '例如我更喜欢简短的答案并且住在柏林';

  @override
  String get memoryEditNote => '编辑备注';

  @override
  String monthsAgo(int count) {
    return '$count前';
  }

  @override
  String get moreTooltip => '更多的';

  @override
  String get closeSearch => '关闭搜索';

  @override
  String get moveTooltip => '移动';

  @override
  String get chatsTab => '聊天记录';

  @override
  String get groupsTab => '团体';

  @override
  String get foldersTooltip => '文件夹';

  @override
  String get newFolder => '新建文件夹';

  @override
  String get tapToReturnToCall => '点击即可返回通话';

  @override
  String get selectConversation => '选择一个对话';

  @override
  String get selectConversationHint => '从列表中选择一个，或开始新的聊天。';

  @override
  String get noGroupChatsYet => '还没有群聊';

  @override
  String get noGroupChatsSubtitle => '启动多人对话，与多个 AI 一起聊天。';

  @override
  String get newPersonaShort => '新的';

  @override
  String get downloadOnDeviceModelTitle => '下载设备上的模型';

  @override
  String get downloadOnDeviceModelBody =>
      '下载模型无需 PC 即可聊天，或连接 LM Studio / Ollama。';

  @override
  String get browseModels => '浏览型号';

  @override
  String get waitingForMac => '等待Mac';

  @override
  String get waitingForMacBody =>
      '使用 USB 线将 iPhone 连接到 Mac，然后在 Mac 上打开 LM Mini 并启用与手机共享（USB 桥接器）。';

  @override
  String get arenaMode => '竞技场模式';

  @override
  String get voiceWhisperSizeInfoTitle => '型号越大听得越好';

  @override
  String get voiceWhisperSizeInfoBody =>
      '较大的聆听模型通常更准确，尤其是对于口音和背景噪音。它们还使用更多存储空间，并且加载速度可能会慢一些。';

  @override
  String get voiceRemoveListeningModelTitle => '删除监听模型？';

  @override
  String get voiceRemoveListeningModelBody =>
      '这可以释放存储空间。在离线收听之前，语音通话和麦克风将再次需要该模型。';

  @override
  String get voiceTtsOnDeviceNeural => '已下载的语音';

  @override
  String get voiceTtsPcVoice => '电脑语音';

  @override
  String get voiceTtsSystemVoice => '系统声音';

  @override
  String get voiceTtsOnDeviceHint => '需要下载的自然语音。无需联网也能用。';

  @override
  String get voiceTtsPcHint => '通过“与手机共享”在计算机上使用语音模型';

  @override
  String get voiceTtsSystemHint => '手机自带语音 — 立即可用';

  @override
  String get voiceSttOnDevice => '在此设备上';

  @override
  String get voiceSttWhisperHint => '离线模型——通常更准确';

  @override
  String get voiceSttSystemHint => '内置识别——快速、简单';

  @override
  String get voiceSttSystemUnavailableOnMac => '需要下载';

  @override
  String get voiceSttMacosRequiresWhisper =>
      'App Store 版本使用设备端 Whisper 进行听写。请下载模型以启用。';

  @override
  String get voiceSttMacosSystemOptionSubtitle => '下载 Whisper 以启用听写';

  @override
  String get voiceSttMacosDownloadWhisper => '下载 Whisper 以启用听写';

  @override
  String get voiceSettingsIntro => '如何回复，以及如何理解您的声音。';

  @override
  String get voiceSectionReady => '准备好';

  @override
  String get voiceSectionSpeaking => '请讲';

  @override
  String get voiceSectionListening => '听力';

  @override
  String get voiceSectionConversation => '对话';

  @override
  String get voiceStatusSpeaking => '请讲';

  @override
  String get voiceStatusListening => '听力';

  @override
  String get voiceHowISpeak => '我如何说话';

  @override
  String get voiceImportPack => '导入语音包';

  @override
  String get voiceImportPackSubtitle => '将 GitHub URL 粘贴到语音包';

  @override
  String get voiceHowIHearYou => '我怎么听到你的声音';

  @override
  String get voiceHowIHearYouSubtitle => '选择如何将您的语音转换为文本。';

  @override
  String get voiceListeningModel => '听力模型';

  @override
  String get voiceAboutModelSizes => '关于型号尺寸';

  @override
  String get voicePauseBeforeSend => '发送前暂停';

  @override
  String get voicePauseBeforeSendSubtitle => '停止说话后要等多久';

  @override
  String get voiceListeningLimit => '听力限制';

  @override
  String get voiceListeningLimitSubtitle => '麦克风重新启动前最长的一段时间';

  @override
  String get voiceQuickTip => '快速提示';

  @override
  String get voiceQuickTipBody => '想要更自然的声音，请在语音包里下载一种语言。系统语音可以马上使用。';

  @override
  String get voiceTestSampleHint => '聆听您当前设置的简短样本';

  @override
  String get voiceTestNoPackReady => '请先在语音包中下载一种语言，然后再试 Test Voice。';

  @override
  String get voiceChooseListeningModel => '点击选择聆听模式';

  @override
  String get voiceModelReady => '准备好';

  @override
  String get voiceNeedsDownload => '需要下载';

  @override
  String get voiceDownloaded => '已下载';

  @override
  String get voiceDownloadFailed => '下载失败';

  @override
  String get voiceFinishingSetup => '正在完成设置...';

  @override
  String get voiceDownloadingListeningModel => '正在下载听力模型...';

  @override
  String get voiceDownloadingVoice => '正在下载语音...';

  @override
  String get voiceStartingDownload => '开始下载...';

  @override
  String get voiceReady => '语音就绪';

  @override
  String get voiceWarmingUp => '正在热身……';

  @override
  String get voiceReadyToSpeak => '准备发言';

  @override
  String get voiceDownloadOnDevice => '下载设备上的语音';

  @override
  String get voiceDownloadFailedRetry => '下载失败 — 点击重试';

  @override
  String get voiceSpokenReplyLanguage => '口头回复语言';

  @override
  String get voiceSpokenReplyLanguageSubtitle => '助理大声朗读消息时使用的语言。';

  @override
  String get voiceRecognitionLanguage => '识别语言';

  @override
  String get voiceRecognitionLanguageSubtitle => '用于文本麦克风和语音通话 — 可能与口头回复不同。';

  @override
  String get voiceEngineTitle => '说话的声音';

  @override
  String get voiceEngineSubtitle => '选择语音从哪里来。';

  @override
  String get voiceChooseAVoice => '选择声音';

  @override
  String get voiceChooseAVoiceSubtitle => '设备上语音的预览友好名称。';

  @override
  String get voiceUseSystemDefault => '使用系统默认语音';

  @override
  String get welcomeWizardTitleGetStarted => '开始使用';

  @override
  String get welcomeWizardTitleYourSetup => '你的设置';

  @override
  String get welcomeWizardTitleLookAndFeel => '外观和感觉';

  @override
  String get welcomeWizardTitleAlmostDone => '快完成了';

  @override
  String get welcomeWizardTitleSetup => '设置';

  @override
  String get welcomeWizardLmStudioSubtitle => '在 Mac 或 PC 上运行模型';

  @override
  String get welcomeWizardOllamaSubtitle => '流行的本地服务器';

  @override
  String get welcomeWizardOmlxSubtitle => 'Apple Silicon 桌面服务器';

  @override
  String get welcomeWizardJanSubtitle => '来自 JAN AI 应用的本地模型';

  @override
  String get welcomeWizardUnslothSubtitle => '电脑上的 Unsloth Desktop';

  @override
  String get welcomeWizardThemeSubtitle => '选择您喜欢的外观。您可以随时更改此设置。';

  @override
  String get welcomeWizardModelReady => '准备好';

  @override
  String get welcomeWizardConnected => '已连接';

  @override
  String get welcomeWizardServerFound => '已找到服务器';

  @override
  String get welcomeWizardRequiresApiKey => '需要 API 密钥';

  @override
  String get welcomeWizardScanHomeQr => '扫描 LM Mini Home 二维码';

  @override
  String get welcomeWizardScanHomeQrSubtitle => '通过“与手机共享”与 Mac 配对';

  @override
  String welcomeWizardModelsFound(int count) {
    return '$count 个模型';
  }

  @override
  String get welcomeWizardLocalNetworkTitle => '允许网络访问';

  @override
  String get welcomeWizardLocalNetworkBody =>
      '接下来系统会请求访问本地网络。请允许，以便 LM Mini 查找电脑上运行的 LM Mini Home、LM Studio 或 Ollama。';

  @override
  String get welcomeWizardLocalNetworkAllow => '允许';

  @override
  String get welcomeWizardDownloadKeepsGoing => '你可以离开此页面，下载会继续，即使退出应用也不会中断。';

  @override
  String get welcomeWizardDownloadFailed => '下载失败。点按即可重试。';

  @override
  String get welcomeWizardAiDownloadingTitle => '正在下载 AI';

  @override
  String get welcomeWizardAiDownloadingBody => '等适合你手机的 AI 下载完成后即可聊天。只需下载一次。';

  @override
  String get onDeviceModels => '设备上模型';

  @override
  String get transcription => '转录';

  @override
  String get widgetSettings => '小部件设置';

  @override
  String get widgetSettingsSubtitle => '配置主屏幕小部件';

  @override
  String get setUpShortcuts => '设置快捷方式';

  @override
  String get shareArenaSpeedResults => '分享 Arena 速度结果';

  @override
  String get browseOnDeviceModels => '浏览设备上的型号';

  @override
  String get homeDownloadModel => '下载模型';

  @override
  String get usbMode => 'USB模式';

  @override
  String get usbModeHowItWorks => 'USB 模式的工作原理';

  @override
  String get switchToUsbTitle => '从远程切换到 USB？';

  @override
  String get switchLabel => '转变';

  @override
  String usbModeStartFailed(String error) {
    return '无法启动 USB 模式：$error';
  }

  @override
  String get usbModeHowToUse => '使用方法：';

  @override
  String get openLmminiCom => '打开 lmmini.com';

  @override
  String get tapToUseServer => '点击即可使用该服务器';

  @override
  String get memoryPersonaFallback => '人格面具';

  @override
  String get voicePickSystemVoiceSubtitle => '选择内置语音进行语音回复。';

  @override
  String get chooseFromGallery => '从画廊中选择';

  @override
  String get galleryLimitsSubtitle => '照片最大 10 MB · 视频最大 200 MB';

  @override
  String get recordVideo => '录制视频';

  @override
  String attachmentsCount(int count, int max) {
    return '附件 ($count/$max)';
  }

  @override
  String get viewProfile => '查看个人资料';

  @override
  String get personaAndModel => '人物与模型';

  @override
  String get chatOptions => '聊天选项';

  @override
  String get chatTab => '聊天';

  @override
  String get voiceTab => '嗓音';

  @override
  String get craftingPersona => '塑造人物形象……';

  @override
  String get randomPersona => '随机角色';

  @override
  String get savePersona => '保存角色';

  @override
  String get downloadFinished => '下载完毕。';

  @override
  String get downloadCancelled => '已取消下载。';

  @override
  String get downloadCancelFailed => '无法在 LM Studio 中取消。请在 LM Studio 的下载列表里停止。';

  @override
  String get newsBriefing => '新闻发布会';

  @override
  String get refreshNow => '立即刷新';

  @override
  String get noBriefingYet => '还没有简报';

  @override
  String get newsSetPromptFirst => '首先在小部件设置中设置新闻小部件提示。';

  @override
  String get newsRefreshed => '新闻刷新了。';

  @override
  String newsRefreshFailed(String error) {
    return '刷新失败：$error';
  }

  @override
  String get themesTitle => '主题';

  @override
  String get createLabel => '创造';

  @override
  String get browseLabel => '浏览';

  @override
  String get signInToUploadThemes => '请登录才能上传主题';

  @override
  String get deleteThemeTitle => '删除主题？';

  @override
  String deleteThemeConfirm(String name) {
    return '从下载的主题中删除“$name”？';
  }

  @override
  String get uploadToCommunity => '上传至社区';

  @override
  String get installedLabel => '已安装';

  @override
  String get getLabel => '得到';

  @override
  String get bestForYou => '最适合你的';

  @override
  String get loadingLabel => '加载中';

  @override
  String get loadedLabel => '已加载';

  @override
  String get notLoadedLabel => '未加载';

  @override
  String get reasoningLabel => '推理';

  @override
  String get imagesLabel => '图片';

  @override
  String get detailsTooltip => '细节';

  @override
  String get transcribeAudio => '转录音频';

  @override
  String get transcribeAudioSubtitle => '上传音频并向 AI 询问文字记录';

  @override
  String get trimSection => '修剪部分';

  @override
  String get includeTimestamps => '包括时间戳';

  @override
  String get phrasesLabel => '短语';

  @override
  String get wordsLabel => '字';

  @override
  String get transcriptionLanguage => '转录语言';

  @override
  String get searchLanguages => '搜索语言...';

  @override
  String get transcribe => '录制';

  @override
  String get shareTranscript => '分享成绩单';

  @override
  String get transcriptionContextLargeToast =>
      '这些转录本对于模型的上下文来说可能太大。如果答案不完整，则从较早的消息中分支。';

  @override
  String get transcriptionSubtitlesOn => '字幕开启';

  @override
  String get transcriptionSubtitlesOff => '字幕关闭';

  @override
  String get transcriptionFullClip => '完整剪辑';

  @override
  String get transcriptionJobRunning => '正在抄写…';

  @override
  String get transcriptionJobDone => '转录';

  @override
  String get transcriptionJobFailed => '转录失败';

  @override
  String get branchFromHere => '分支从这里开始';

  @override
  String get memoryUpdates => '内存更新';

  @override
  String get promptWriteEmail => '写一封电子邮件';

  @override
  String get promptWriteEmailBody => '帮我写一封清晰、友好的电子邮件至';

  @override
  String get promptGiveIdeas => '给我想法';

  @override
  String get promptGiveIdeasBody => '与我一起集思广益创意想法';

  @override
  String get promptExplainSimply => '简单解释一下';

  @override
  String get promptExplainSimplyBody => '用简单的话解释一下：';

  @override
  String get promptFixWriting => '修正我的写作';

  @override
  String get promptFixWritingBody => '改进这篇文章的清晰度和语气：';

  @override
  String get promptHelpStudy => '帮我学习';

  @override
  String get promptHelpStudyBody => '帮我研究一下这个话题：';

  @override
  String get promptPlanTrip => '计划一次旅行';

  @override
  String get promptPlanTripBody => '帮我计划一次旅行';

  @override
  String get promptSummarize => '总结一下这个';

  @override
  String get promptSummarizeBody => '总结清楚：';

  @override
  String get promptChecklist => '制定清单';

  @override
  String get promptChecklistBody => '制定一份实用的清单';

  @override
  String get promptFunFact => '告诉我一个有趣的事实';

  @override
  String get promptFunFactBody => '告诉我一个有趣的事实';

  @override
  String get promptQuizMe => '测验我';

  @override
  String get promptQuizMeBody => '测验我';

  @override
  String get promptRoleplay => '和我一起角色扮演';

  @override
  String get promptRoleplayBody => '我们来角色扮演吧。你是';

  @override
  String get promptCodeHelp => '代码帮助';

  @override
  String get promptCodeHelpBody => '帮我解决这个代码问题：';

  @override
  String get promptDraftReply => '起草回复';

  @override
  String get promptDraftReplyBody => '对此起草一份礼貌的答复：';

  @override
  String get promptPracticeInterview => '练习面试';

  @override
  String get promptPracticeInterviewBody => '练习面试问题';

  @override
  String get promptMealIdeas => '膳食创意';

  @override
  String get promptMealIdeasBody => '使用建议膳食想法';

  @override
  String get promptWorkoutPlan => '锻炼计划';

  @override
  String get promptWorkoutPlanBody => '制定一个简单的锻炼计划';

  @override
  String get promptTranslateCasually => '随便翻译一下';

  @override
  String get promptTranslateCasuallyBody => '随便翻译一下：';

  @override
  String get promptNameIdeas => '命名创意';

  @override
  String get promptNameIdeasBody => '集思广益的名字想法';

  @override
  String get promptProsCons => '优点和缺点';

  @override
  String get promptProsConsBody => '列出优点和缺点';

  @override
  String get promptRewriteShorter => '重写更短';

  @override
  String get promptRewriteShorterBody => '重写这个更短更清晰的：';

  @override
  String get promptTeachVocab => '教我生字';

  @override
  String get promptTeachVocabBody => '教我一些有用的词汇';

  @override
  String get promptStoryTime => '故事时间';

  @override
  String get promptStoryTimeBody => '讲一个关于';

  @override
  String get promptDebugWithMe => '和我一起调试';

  @override
  String get promptDebugWithMeBody => '帮我调试一下：';

  @override
  String get promptDailyMotivation => '每日动力';

  @override
  String get promptDailyMotivationBody => '给我一个简短的激励推动';

  @override
  String get promptPlayDnd => '玩免打扰';

  @override
  String get promptPlayDndBody => '让我们来玩一段简短的 D&D 冒险吧。我是';

  @override
  String get promptWordChain => '字链';

  @override
  String get promptWordChainBody => '我们来玩单词链吧。从以下开始：';

  @override
  String get promptRiddleDuel => '谜语决斗';

  @override
  String get promptRiddleDuelBody => '给我一个谜语来解答。';

  @override
  String get promptWouldYouRather => '你会宁愿';

  @override
  String get promptWouldYouRatherBody => '问我一个有趣的问题。';

  @override
  String get promptEscapeRoom => '密室逃脱';

  @override
  String get promptEscapeRoomBody => '为我开始一个简短的文字密室逃脱游戏。';

  @override
  String get promptTriviaBattle => '问答大战';

  @override
  String get promptTriviaBattleBody => '用一些琐事来测验我';

  @override
  String get promptStoryRpg => '故事角色扮演游戏';

  @override
  String get promptStoryRpgBody => '开始一个短篇故事角色扮演游戏。我的性格是';

  @override
  String get promptGuessNumber => '猜数字';

  @override
  String get promptGuessNumberBody => '我们来玩猜数字吧。想一个 1 到 100 之间的数字。';

  @override
  String get promptTwoTruths => '两个真理一个谎言';

  @override
  String get promptTwoTruthsBody => '让我们玩两个真理和一个谎言。你先走吧。';

  @override
  String get promptReadMyFile => '阅读我的文件';

  @override
  String get promptWhatIsImage => '这是什么图像';

  @override
  String get promptTakePhoto => '拍张照片';

  @override
  String get promptTranscribeAudio => '转录音频';

  @override
  String get promptPersonaGenerator => '角色生成器';

  @override
  String get personaShareMemoryCategoriesLabel => '分享类别';

  @override
  String get personaShareMemoryCategoriesSubtitle => '选择该角色可以在聊天中使用哪些类型的记忆。';

  @override
  String get chooseFaceForBubbles => '选择气泡的面';

  @override
  String get moveMemories => '移动记忆';

  @override
  String get deletePersonaAndMemories => '删除角色+记忆';

  @override
  String get moveMemoriesTo => '将记忆移至...';

  @override
  String get globalSharedMemories => '全局（与所有角色共享）';

  @override
  String personaMemoriesAssignedHint(int count, String name) {
    return '$count 内存项被分配给“$name”。\n选择他们应该发生什么：';
  }

  @override
  String get homeSyncTitle => '保持聊天同步？';

  @override
  String homeSyncBodyBoth(int phoneChats, int macChats) {
    return '这台手机有 $phoneChats 个聊天，LM Mini Home 有 $macChats 个。开启同步可合并对话和文件夹，方便在任一设备上继续。使用现有的加密中继。';
  }

  @override
  String get homeSyncBodyPhoneOnly =>
      '把这台手机上的聊天和文件夹复制到 LM Mini Home，之后通过加密中继保持同步。';

  @override
  String get homeSyncBodyMacOnly =>
      '把 LM Mini Home 上的聊天和文件夹带到这台手机，之后通过加密中继保持同步。';

  @override
  String get homeSyncBodyGeneric =>
      '合并这台手机和 LM Mini Home 上的对话与文件夹，方便在任一设备上继续。使用现有的加密中继。';

  @override
  String get homeSyncEnable => '开启同步';

  @override
  String get homeSyncNotNow => '暂不';

  @override
  String get homeSyncSettingsTitle => '与 Home 同步聊天';

  @override
  String get homeSyncSettingsSubtitle => '通过加密中继合并对话和文件夹';

  @override
  String get homeSyncMergedToast => '聊天和文件夹已同步';

  @override
  String get homeSyncFailedToast => '无法同步。请在 Mac 上打开 Share with phone 后再试。';

  @override
  String get homeSyncPersonasTitle => '同步角色';

  @override
  String get homeSyncPersonasSubtitle => '复制你勾选的角色，包括照片和记忆';

  @override
  String get homeSyncPersonasPickTitle => '选择角色';

  @override
  String get homeSyncPersonasPickSubtitle => '勾选的角色会在这台设备和 Home 之间复制，包括照片和记忆。';

  @override
  String get homeSyncPersonasSave => '保存并同步';

  @override
  String get homeSyncPersonasSavedToast => '角色已同步';

  @override
  String get homeSyncPersonasEmpty => '还没有可复制的角色。';

  @override
  String get homeSyncPersonasUnreachable =>
      '无法连接 Home。请在 Mac 上打开 Share with phone，然后再试。';

  @override
  String get homeSyncPersonasOnBoth => '两台设备都有';

  @override
  String get homeSyncPersonasOnHome => 'LM Mini Home';

  @override
  String get homeSyncPersonasOnPhone => '你的手机';

  @override
  String get homeSyncPersonasThisPhone => '这台手机';

  @override
  String homeSyncPersonasOnDevice(String device) {
    return '在$device';
  }

  @override
  String homeSyncPersonasMemoryCount(int count) {
    return '$count 条记忆';
  }

  @override
  String get homeSyncPersonasNoMemories => '还没有记忆';

  @override
  String get reportToSupport => '发送给支持';

  @override
  String get localhostConnectionHelp =>
      '无法连接到 localhost。在手机上，localhost 指的是这台设备，不是电脑。请在设置中填写电脑的 IP 地址（例如 http://192.168.1.10:1234），并保持同一 Wi‑Fi。';

  @override
  String get lmStudioPcNotAllowingTitle => '电脑未允许连接';

  @override
  String get lmStudioPcNotAllowingBody =>
      '在电脑上的 LM Studio 打开 Developer → Server Settings，打开 Serve on Local Network。';

  @override
  String get lmStudioHostDownTitle => '无法连到电脑';

  @override
  String get lmStudioHostDownStep1 => '请确认电脑已开机，没有休眠或关机。';

  @override
  String get lmStudioHostDownStep2 =>
      '在 LM Studio 打开 Developer → Server Settings，打开 Serve on Local Network。';

  @override
  String get cantReachMacTitle => '无法连到 Mac';

  @override
  String get cantReachMacStep1 => '在 Mac 上打开 LM Mini Home 的 Share with phone。';

  @override
  String get cantReachMacStep2 => '等到显示 Connected 后再试。';

  @override
  String get lmStudioServerSettingsImageLabel =>
      'LM Studio Developer → Server Settings。Serve on Local Network 需要打开。';

  @override
  String get modelMissingTitle => '电脑上没有这个模型';

  @override
  String get modelMissingBody => '所选模型不可用。请到模型选择里换一个。';

  @override
  String modelMissingBodyNamed(String model) {
    return '电脑上没有 “$model”。请到模型选择里换一个。';
  }

  @override
  String get outputTokensExhaustedTitle => '模型输出 token 已用尽';

  @override
  String get outputTokensExhaustedBody =>
      '工具已跑完，但没有剩余 token 写回复。请提高最大 token 后再试。';

  @override
  String get thinkingBudgetRetryTitle => 'Thinking used the output limit';

  @override
  String get thinkingBudgetRetryBody =>
      'High thinking filled the output limit, so this reply uses low thinking. Raise max tokens to keep high thinking.';

  @override
  String get adjustMaxTokens => '调整最大 token';

  @override
  String get ggmlSchedulerCrashBody =>
      '模型服务器崩溃了（llama.cpp 调度器）。这不是 Mini 的问题。请调低上下文长度和最大 token——过大的值（例如 128k 上下文）经常导致这种情况。';

  @override
  String get generationTerminatedBody => 'LM Studio 已在你的电脑上停止生成（进程被终止）。';

  @override
  String generationTerminatedHugeImageBody(String size) {
    return 'LM Studio 已在你的电脑上停止生成。你附加的图片可能太大（$size）——请压缩后重新发送。';
  }

  @override
  String get compressAndResendImages => '压缩图片并重新发送';

  @override
  String get imageCompressFailed => '无法缩小附加的图片。请换一张更小的照片。';

  @override
  String get droppedChatBodyHelp =>
      'Mini 已发出这条聊天，但从未到达 LM Studio。如果 LM Studio 前面有代理、隧道或额外网址，请先去掉它们——或让 Mini 直连 LM Studio（电脑 IP、USB 或 Connect）。';

  @override
  String get comfyUiNoCheckpointsTitle => 'ComfyUI 没有图像模型';

  @override
  String get comfyUiNoCheckpointsBody =>
      'ComfyUI 没有可加载的 checkpoint。请把 .safetensors 文件放到 ComfyUI 的 models/checkpoints 文件夹，然后在图像生成设置里选择它。';

  @override
  String get comfyUiNoCheckpointSelectedBody =>
      '还没有选择图像模型。请打开图像生成设置并选择一个 checkpoint。';

  @override
  String comfyUiUnknownCheckpointBody(String name) {
    return 'ComfyUI 没有 checkpoint “$name”。请在图像生成设置里换一个。';
  }

  @override
  String get comfyUiWorkflowRejectedBody => 'ComfyUI 拒绝了该工作流。请检查图像生成设置。';

  @override
  String get comfyUiDiffusionOnlyTitle => '这个工作流需要你的 ComfyUI 图';

  @override
  String get comfyUiDiffusionOnlyBody =>
      'Mini 内置工作流加载的是经典 SD checkpoint。你的 Comfy Desktop 图用的是 diffusion/UNET，再加上 CLIP 和 VAE。请导出为 API Format（Workflow → Export），然后在图像生成设置里选择该文件。';

  @override
  String get openImageSettings => '图像设置';

  @override
  String imageGenUnreachableTitle(String name) {
    return '无法连接 $name';
  }

  @override
  String imageGenUnreachableBody(String name, String url) {
    return '$url 没有响应。请在电脑上启动 $name，并保持同一 Wi‑Fi。';
  }

  @override
  String get imageGenUnreachableNoUrlBody =>
      '尚未设置图像生成服务器。请在图像生成设置中添加 ComfyUI 或 AUTOMATIC1111。';

  @override
  String get sharedHostUpdateImageTitle => '也更新图像生成地址？';

  @override
  String sharedHostUpdateChatTitle(String name) {
    return '也更新 $name？';
  }

  @override
  String sharedHostUpdateBody(
      String changedName, String peerName, String oldHost, String newUrl) {
    return '$changedName 和 $peerName 之前都在 $oldHost。要将 $peerName 改为 $newUrl 吗？';
  }

  @override
  String get sharedHostUpdateConfirm => '更新并测试';

  @override
  String get sharedHostUpdateSkip => '保持当前';

  @override
  String sharedHostTesting(String name) {
    return '正在测试 $name…';
  }

  @override
  String get sharedHostTestSuccessTitle => '已连接';

  @override
  String sharedHostTestSuccessBody(String name, String url) {
    return '已连接到 $name（$url）。';
  }

  @override
  String get sharedHostTestFailTitle => '无法连接';

  @override
  String sharedHostTestFailBody(String name, String url, String error) {
    return '已将 $name 更新为 $url，但 Mini 连不上。$error';
  }

  @override
  String get supportTicketTitle => '反馈问题';

  @override
  String get supportTicketPrefillDescription => '已附上包含错误详情的日志文件。如有补充请写在下面：';

  @override
  String get supportTicketSubmitted => '谢谢，报告已发送。';

  @override
  String get supportTicketAlreadyOpen => '你已经为这个错误提交过未关闭的反馈。';

  @override
  String get supportTicketViewExisting => '查看反馈';

  @override
  String get supportTicketAlreadySending => '正在提交同一错误的反馈。';

  @override
  String get supportUnavailable => '目前无法联系支持。请在联网后再试。';

  @override
  String get somethingWentWrong => '出了点问题';

  @override
  String get uncaughtErrorSnack => '出了点问题。';

  @override
  String get errorLogLabel => 'LOG';

  @override
  String get appLock => '应用锁';

  @override
  String get appLockSubtitleOff => '关闭应用后需要输入 PIN';

  @override
  String appLockSubtitleOn(String duration) {
    return '$duration后再次要求验证';
  }

  @override
  String get appLockUnlockTitle => 'LM Mini 已锁定';

  @override
  String get appLockDescription =>
      '用数字 PIN 和可选的面容 ID 保护此设备上的聊天。PIN 只保存在本机，不会同步。';

  @override
  String get appLockEnable => '使用 PIN 锁定';

  @override
  String get appLockEnableSubtitle => '返回时要求输入 PIN';

  @override
  String get appLockPinLength4 => '4 位';

  @override
  String get appLockPinLength6 => '6 位';

  @override
  String get appLockRequireAfter => '再次询问的间隔';

  @override
  String get appLockTimeoutImmediate => '立即';

  @override
  String get appLockTimeout15s => '15 秒';

  @override
  String get appLockTimeout1m => '1 分钟';

  @override
  String get appLockTimeout5m => '5 分钟';

  @override
  String get appLockTimeout15m => '15 分钟';

  @override
  String get appLockTimeout1h => '1 小时';

  @override
  String get appLockChangePin => '更改 PIN';

  @override
  String get appLockEnterCurrentPin => '输入当前 PIN';

  @override
  String get appLockChooseNewPin => '设置 PIN';

  @override
  String get appLockConfirmPin => '确认 PIN';

  @override
  String get appLockPinsDontMatch => '两次 PIN 不一致，请重试。';

  @override
  String get appLockWrongPin => 'PIN 错误，请重试。';

  @override
  String appLockTooManyAttempts(int seconds) {
    return '尝试次数过多，请 $seconds 秒后再试。';
  }

  @override
  String get appLockForgotHint =>
      '如果忘记 PIN，可以通过发送到已登录账户的验证邮件重置。请在丢失 PIN 之前登录，否则将无法找回。';

  @override
  String get appLockProRequired => '应用锁是 Pro 功能';

  @override
  String get appLockEnabledToast => '已开启应用锁';

  @override
  String get appLockDisabledToast => '已关闭应用锁';

  @override
  String get appLockChangedToast => 'PIN 已更新';

  @override
  String appLockBiometricsToggle(String method) {
    return '使用$method解锁';
  }

  @override
  String get appLockBiometricsSubtitle => '用面容 ID、触控 ID 或指纹代替输入 PIN。';

  @override
  String get appLockBiometricFaceId => '面容 ID';

  @override
  String get appLockBiometricFace => '面容解锁';

  @override
  String get appLockBiometricTouchId => '触控 ID';

  @override
  String get appLockBiometricFingerprint => '指纹';

  @override
  String get appLockBiometricGeneric => '生物识别';

  @override
  String appLockUnlockWithBiometrics(String method) {
    return '使用$method解锁';
  }

  @override
  String appLockBiometricsFailed(String method) {
    return '无法使用$method解锁，请改用 PIN。';
  }

  @override
  String get appLockSignInToRecover => '请登录，否则丢失此 PIN 后将无法找回应用锁。';

  @override
  String appLockSignInToRecoverBound(String email) {
    return '请以 $email 登录，否则丢失此 PIN 后将无法找回应用锁。';
  }

  @override
  String get appLockNotSignedInNoRecovery => '你尚未登录。如果丢失此 PIN，将无法找回。';

  @override
  String get appLockForgotPin => '忘记 PIN？';

  @override
  String get appLockSendRecoveryEmail => '发送验证邮件';

  @override
  String appLockRecoveryEmailSent(String email) {
    return '我们已向 $email 发送验证邮件。请打开邮件后再回来。';
  }

  @override
  String get appLockRecoveryIVerified => '我已验证 — 继续';

  @override
  String get appLockRecoveryResend => '重新发送邮件';

  @override
  String get appLockRecoveryReauth => '再次登录以重置 PIN';

  @override
  String appLockRecoveryWrongAccount(String email) {
    return '此 PIN 绑定到 $email。请用该账户登录以找回。';
  }

  @override
  String get appLockRecoveryUnavailable =>
      '尚未设置 PIN 找回。你需要记住此 PIN，或重新安装 LM Mini。';

  @override
  String get appLockRecoveryFailed => '无法验证账户，请重试。';

  @override
  String get appLockRecoveryNoEmail => '此账户没有可用于发送验证链接的邮箱。';

  @override
  String get appLockRecoveryTooMany => '发送次数过多，请稍等一分钟再试。';

  @override
  String get appLockRecoverySetPin => '设置新 PIN';

  @override
  String get appLockContinueWithEmail => '使用邮箱继续';

  @override
  String appLockSignedInRecoverHint(String email) {
    return '如果忘记此 PIN，我们可以向 $email 发送验证链接。';
  }

  @override
  String get appLockRecoveryAccount => 'PIN 找回';

  @override
  String appLockRecoveryAccountOn(String email) {
    return '验证邮件将发送到 $email';
  }

  @override
  String get appLockRecoveryAccountOff => '登录后才能找回丢失的 PIN';

  @override
  String get appLockRecoveryAccountOffSubtitle =>
      '如果没有登录账户，丢失的 PIN 只能通过重新安装应用清除。';

  @override
  String get appLockBackToPin => '使用 PIN';

  @override
  String get premiumAppLock => '应用锁';

  @override
  String get premiumAppLockTagline => '用 PIN 保护应用';

  @override
  String get premiumAppLockDescription =>
      '设置 4 或 6 位数字 PIN，可用面容 ID 解锁，并通过验证邮件找回丢失的 PIN。PIN 只保存在本机。';

  @override
  String spritePanelShow(String name) {
    return '显示$name的表情';
  }

  @override
  String get personaExpressionsTitle => '表情';

  @override
  String get personaExpressionsSubtitle =>
      '随每条回复情绪变化的角色立绘。按表情命名图片（如 joy.png、anger.png），或导入 SillyTavern 立绘压缩包。';

  @override
  String get personaExpressionsImport => '导入立绘';

  @override
  String get personaExpressionsRemoveAll => '全部移除';

  @override
  String personaExpressionsRemoveAllConfirm(String name) {
    return '移除$name的所有表情立绘？';
  }

  @override
  String get personaExpressionsReplace => '替换图片';

  @override
  String get personaExpressionsRemove => '移除';

  @override
  String personaExpressionsImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已添加 $count 张立绘',
      zero: '未添加立绘',
    );
    return '$_temp0';
  }

  @override
  String personaExpressionsUnmatched(String files) {
    return '已跳过（不是表情名称）：$files';
  }

  @override
  String get personaExpressionsMissing => '缺少';

  @override
  String get characterCardImport => '导入角色卡';

  @override
  String characterCardImportedOne(String name) {
    return '已导入$name';
  }

  @override
  String characterCardImportedMany(int count) {
    return '已导入 $count 个角色';
  }

  @override
  String characterCardImportFailed(String file, String reason) {
    return '无法导入 $file：$reason';
  }

  @override
  String characterCardLoreSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '有 $count 条关键词世界书条目未导入',
    );
    return '$_temp0';
  }

  @override
  String get appearanceExpressionSprites => '角色表情';

  @override
  String get appearanceExpressionSpritesSubtitle => '适用于有表情立绘的角色';

  @override
  String get expressionSpriteModeOff => '关闭';

  @override
  String get expressionSpriteModePanel => '大立绘';

  @override
  String get expressionSpriteModeAvatar => '消息头像';

  @override
  String get expressionSpriteModeBoth => '两者';

  @override
  String get spriteGenerateButton => '生成';

  @override
  String get spriteGenerateTitle => '生成表情';

  @override
  String get spriteGenerateAppearance => '外貌';

  @override
  String get spriteGenerateAppearanceHint => '发型、眼睛、服装和画风';

  @override
  String get spriteGenerateSeed => '种子';

  @override
  String get spriteGenerateSeedHelp => '使用相同种子可让角色在各表情中保持一致。';

  @override
  String get spriteGenerateCore => '8 个常用';

  @override
  String get spriteGenerateAll => '全部 28 个';

  @override
  String get spriteGenerateOnlyMissing => '仅生成缺少的表情';

  @override
  String spriteGenerateStart(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '生成 $count 张图片',
    );
    return '$_temp0';
  }

  @override
  String spriteGenerateProgress(int current, int total, String label) {
    return '正在生成第 $current/$total 张：$label';
  }

  @override
  String get spriteGenerateNeedsImageGen => '请先在“设置 → 图像生成”中完成设置。';

  @override
  String spriteGenerateDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已生成 $count 个表情',
    );
    return '$_temp0';
  }

  @override
  String spriteGenerateFailed(String label, String error) {
    return '在 $label 处停止：$error';
  }

  @override
  String get personaGreetingLabel => '开场白（可选）';

  @override
  String get personaGreetingHint => '新对话开始时角色说的话';

  @override
  String get personaMemoryOwnOnlyNote => '该角色拥有独立记忆：只能看到在自己聊天中学到的内容，看不到你的共享记忆。';
}
