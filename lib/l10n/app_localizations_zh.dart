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
  String get splashTagline => '本地 AI 聊天';

  @override
  String get homeTitle => 'LM Mini';

  @override
  String get homeSearchHint => '搜索对话…';

  @override
  String get allConversations => '所有对话';

  @override
  String get noFoldersTitle => '还没有文件夹';

  @override
  String get noFoldersSubtitle => '创建文件夹来整理你的对话';

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
  String get noModelsAvailable => '没有可用的模型。请检查 LM Studio 连接。';

  @override
  String get noVisionModelAvailable => '没有可用的视觉模型。请在 LM Studio 中加载视觉模型。';

  @override
  String get deleteConversationTitle => '删除对话';

  @override
  String get deleteConversationMessage => '确定要删除此对话吗？此操作无法撤销。';

  @override
  String get renameConversationTitle => '重命名对话';

  @override
  String get conversationTitleLabel => '对话标题';

  @override
  String get deleteFolderTitle => '删除文件夹';

  @override
  String get deleteFolderMessage => '此操作不会删除文件夹中的对话。';

  @override
  String get moveToFolderTitle => '移至文件夹';

  @override
  String get noFolder => '无文件夹';

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get save => '保存';

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
  String get copied => '已复制！';

  @override
  String get copiedToClipboard => '已复制到剪贴板';

  @override
  String get dismiss => '关闭';

  @override
  String get configure => '配置';

  @override
  String get rename => '重命名';

  @override
  String get duplicate => '创建副本';

  @override
  String get enabled => '启用';

  @override
  String get disabled => '已禁用';

  @override
  String get active => '生效中';

  @override
  String get none => '无';

  @override
  String get auto => '自动';

  @override
  String get custom => '自定义';

  @override
  String get change => '更改';

  @override
  String get chatDefaultTitle => '聊天';

  @override
  String get searchMessagesTooltip => '搜索消息';

  @override
  String get chatSettingsMenuItem => '聊天设置';

  @override
  String get appearanceMenuItem => '外观';

  @override
  String get exportAsPdf => '导出为 PDF';

  @override
  String get exportAsTxt => '导出为 TXT';

  @override
  String get exportAsMarkdown => '导出为 Markdown';

  @override
  String get exportAsJson => '导出为 JSON';

  @override
  String get exportAsObsidian => '导出为 Obsidian 格式';

  @override
  String get copyToClipboard => '复制到剪贴板';

  @override
  String get exportAndShare => '导出并分享';

  @override
  String get freeFormats => '标准';

  @override
  String get premiumFormats => '专业格式';

  @override
  String get chatExported => '聊天已导出';

  @override
  String get noModelSelectedTitle => '未选择模型';

  @override
  String get noModelSelectedSubtitle => '请在设置中选择模型开始聊天';

  @override
  String get openSettings => '打开设置';

  @override
  String connectionError(String error) {
    return '连接错误：$error';
  }

  @override
  String get startConversation => '你好！今天有什么可以帮你的吗？';

  @override
  String get typeMessageToBegin => '选择下面的建议，或输入消息开始对话';

  @override
  String get searchMessagesTitle => '搜索消息';

  @override
  String get searchQueryHint => '输入搜索关键词…';

  @override
  String get semanticSearchInfo => '语义搜索使用 AI 按含义（而非仅靠关键词）查找相关消息。';

  @override
  String get noMessagesToSearch => '没有可搜索的消息';

  @override
  String get searchResults => '搜索结果';

  @override
  String searchResultsFor(int count, String query) {
    return '$count 条结果匹配“$query”';
  }

  @override
  String get noMessagesFound => '未找到消息';

  @override
  String get tryDifferentSearch => '试试其他搜索词';

  @override
  String get chatCustomizationSaved => '聊天自定义已保存';

  @override
  String get noMessagesToExport => '没有要导出的消息';

  @override
  String get exportingChat => '正在导出聊天记录…';

  @override
  String get chatExportedAsPdf => '聊天已导出为 PDF';

  @override
  String get chatExportedAsTxt => '聊天已导出为 TXT';

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
  String get hideDetails => '隐藏详情';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsAdvancedMode => '高级';

  @override
  String get settingsAdvancedModeTooltip => '为高级用户显示技术选项';

  @override
  String get serverSection => '服务器';

  @override
  String get serverUrlLabel => '服务器地址';

  @override
  String get serverUrlHint => 'http://localhost:1234';

  @override
  String get testConnectionRequired => '测试连接（必需）';

  @override
  String get testConnection => '测试连接';

  @override
  String get modelsSection => '模型';

  @override
  String get modelSelection => '选择模型';

  @override
  String get noModelSelected => '未选择模型';

  @override
  String get modelParameters => '模型参数';

  @override
  String get modelParametersSubtitle => '温度、Token、惩罚';

  @override
  String get modelParametersHelpTooltip => '这些设置的含义';

  @override
  String get modelParametersHelpTitle => '快速指南';

  @override
  String get modelParametersHelpIntro =>
      '每项设置都有简单说明。不确定时保持默认即可，以后随时可以改。部分选项仅在你当前的 AI 提供商下显示。';

  @override
  String get topKHelp => 'AI 每步考虑的候选词数量。越低越稳定、越可预测；0 表示不限制。';

  @override
  String get reasoningHelp =>
      '开启或关闭推理模型的思考模式。关闭后回复更快、不显示思考过程；开启（或某个级别）会让模型逐步思考。并非所有推理模型都支持关闭思考。';

  @override
  String get reasoningHelpShort => '开启或关闭思考。并非所有模型都支持关闭。';

  @override
  String get systemPrompts => '角色与系统提示词';

  @override
  String get defaultPrompt => '默认提示词';

  @override
  String get appearanceSection => '外观';

  @override
  String get appearance => '外观';

  @override
  String get appearanceSubtitle => '主题、背景、头像';

  @override
  String get supportSection => '支持';

  @override
  String get rateApp => '评价 LM Mini';

  @override
  String get rateAppSubtitle => '喜欢这个应用？去 App Store 给个好评吧 ⭐';

  @override
  String get hfBrowseTitle => '从 Hugging Face 下载';

  @override
  String get hfBrowseSubtitle => '浏览 GGUF 模型 — 无需 API 密钥';

  @override
  String get hfBrowseTab => '浏览';

  @override
  String get hfPasteTab => '粘贴链接';

  @override
  String get hfSearchHint => '搜索 GGUF 模型…';

  @override
  String get hfLoadingModels => '正在搜索 Hugging Face…';

  @override
  String get hfNoModelsFound => '未找到模型';

  @override
  String get hfNoModelsHint => '尝试不同的搜索词或关闭 LM Studio 过滤器。';

  @override
  String get hfLmStudioFilter => '兼容 LM Studio';

  @override
  String get hfLmStudioFilterHint => '仅 Hugging Face 列出的模型可与 LM Studio 配合使用';

  @override
  String get hfChatModelsFilter => '聊天模型';

  @override
  String get hfChatBadge => '聊天';

  @override
  String get hfLmStudioBadge => 'LM Studio';

  @override
  String get hfPasteUrlHint => 'https://huggingface.co/owner/repo';

  @override
  String get hfModelInfo => '模型信息';

  @override
  String hfDownloadsCount(String count) {
    return '$count 下载量';
  }

  @override
  String hfLikesCount(String count) {
    return '$count 个赞';
  }

  @override
  String hfPipelineTag(String tag) {
    return '任务：$tag';
  }

  @override
  String hfBaseModel(String model) {
    return '基础模型：$model';
  }

  @override
  String hfLicense(String license) {
    return '许可证：$license';
  }

  @override
  String get hfTagsSection => '标签';

  @override
  String get hfQuantPickerHint => '量化等级越低，文件越小。Q4_K_M 适合大多数设备。';

  @override
  String get hfBackToModels => '返回模型列表';

  @override
  String hfGgufFilesCount(int count) {
    return '$count GGUF 文件可用';
  }

  @override
  String get hfDownloadInBackground => '下载已开始 — 可用浮动按钮跟踪进度。你可以继续浏览或关闭此面板。';

  @override
  String get hfQuantPickerHintLmStudio =>
      '由你的 LM Studio 服务器列出的量化版本。选择一个下载到服务器。';

  @override
  String get hfDownloadDefaultQuant => '下载';

  @override
  String hfDownloadFailed(String error) {
    return '无法开始下载：$error';
  }

  @override
  String get hfPasteInstructions =>
      '粘贴 Hugging Face 仓库 URL，或输入 owner/repo。下一步选择量化版本。';

  @override
  String get hfPasteInstructionsLmStudio =>
      '粘贴 Hugging Face URL、owner/repo 或 LM Studio 模型 ID。';

  @override
  String get hfPasteLabel => '仓库';

  @override
  String get hfInvalidRepo => '请输入有效的 Hugging Face URL 或 owner/repo。';

  @override
  String get hfRecommended => '推荐';

  @override
  String get reviewPromptTitle => '喜欢 LM Mini 吗？';

  @override
  String get reviewPromptMessage => '已经聊得很愉快了！愿意去 Play 商店给个评分吗？';

  @override
  String get reviewPromptRate => '立即评分';

  @override
  String get reviewPromptLater => '稍后再说';

  @override
  String get buyMeACoffee => '请我喝杯咖啡';

  @override
  String get buyMeACoffeeSubtitle => '帮 AI 续上咖啡因！🤖';

  @override
  String get featureRequests => '支持/功能请求';

  @override
  String get featureRequestsSubtitle => '为功能投票或提交你的想法';

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
  String get importing => '正在导入…';

  @override
  String get advancedSection => '高级功能';

  @override
  String get showRuntimeInfo => '显示运行时信息';

  @override
  String get showRuntimeInfoSubtitle => '显示模型架构和运行时';

  @override
  String get embeddingModel => 'Embedding 模型';

  @override
  String get enableSemanticSearch => '启用语义搜索';

  @override
  String get enableSemanticSearchSubtitle => '使用 Embedding 查找相关消息';

  @override
  String get toolCalling => '工具调用';

  @override
  String get toolCallingEnabled => '启用工具调用';

  @override
  String get toolCallingDisabled => '工具调用已禁用';

  @override
  String get legalSection => '法律信息';

  @override
  String get privacyPolicy => '隐私政策';

  @override
  String get privacyPolicySubtitle => '对话仅保存在你的设备上';

  @override
  String get termsOfService => '服务条款';

  @override
  String get termsOfServiceSubtitle => '条款和条件';

  @override
  String get appName => 'LM Mini';

  @override
  String get appTagline => '为 LM Studio、Ollama 和 oMLX 打造的口袋 AI 伴侣应用';

  @override
  String get couldNotOpenLink => '无法打开链接';

  @override
  String get apiToken => 'API Token 和 USB';

  @override
  String get tokenConfigured => 'Token 已配置';

  @override
  String get optionalAuthentication => '可选身份验证';

  @override
  String get apiTokenLabel => 'API Token';

  @override
  String get apiTokenHint => '输入你的 LM Studio API Token';

  @override
  String get apiTokenHelp =>
      '如果 LM Studio 服务器需要身份验证，在此输入你的 API Token。可选填写，仅当你在 LM Studio 设置中启用了身份验证时才需要。';

  @override
  String get apiTokenInfo =>
      'LM Studio 0.4.0+ 支持 API 身份验证。可在 LM Studio > 设置 > 安全中开启。';

  @override
  String get actionRequired => '- 需要处理';

  @override
  String get idleTtl => '空闲 TTL';

  @override
  String get idleTtlDefault => '使用 LM Studio 默认设置（60 分钟）';

  @override
  String idleTtlMinutes(int value) {
    return '空闲$value分钟后自动卸载';
  }

  @override
  String idleTtlHoursMinutes(int hours, int mins) {
    return '空闲 $hours 小时 $mins 分钟后自动卸载';
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
  String get troubleshootStep3 => '开启“在本地网络提供服务”开关';

  @override
  String get troubleshootStep4 => '确认服务器端口一致（默认：1234）';

  @override
  String troubleshootStep5(String ip) {
    return '局域网连接请使用你的 IP，例如 $ip';
  }

  @override
  String get lmStudioSettings => 'LM Studio 设置';

  @override
  String get serveOnLocalNetworkHelp =>
      '请在 LM Studio 的 Developer 选项卡中开启“在本地网络提供服务”开关（显示为橙色/绿色）。';

  @override
  String get networkConnections => '网络连接：';

  @override
  String get networkConnectionsTips =>
      '• 将 localhost 替换为你电脑的 IP 地址\n• 确保两台设备在同一网络\n• 检查端口 1234 的防火墙设置';

  @override
  String get noConversationsToExport => '没有要导出的对话';

  @override
  String exportingConversations(int count) {
    return '正在导出 $count 个对话…';
  }

  @override
  String exportSuccess(int count) {
    return '已成功导出 $count 个对话';
  }

  @override
  String get languageSection => '语言';

  @override
  String get language => '语言';

  @override
  String get languageSubtitle => '选择你偏好的语言';

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
  String get enableToolCallingSubtitle => '允许 AI 联网搜索并调用 MCP';

  @override
  String get builtInToolsSection => '内置工具';

  @override
  String get builtInToolsInfo => 'AI 请求时由应用在本地执行的工具';

  @override
  String get webSearch => '网页搜索';

  @override
  String get webSearchUsingSearxng => '使用 SearXNG';

  @override
  String get webSearchDisabled => '已禁用（配置 SearXNG 或升级到 Pro）';

  @override
  String get integratedMcpsSection => '集成 MCP';

  @override
  String get integratedMcpsInfo =>
      '使用你已在 LM Studio 中配置的 MCP，只需在此填入它们在 mcp.json 中的名称。';

  @override
  String get integratedMcpsAuthRequired =>
      '使用集成 MCP 需在 LM Studio 中启用身份验证，并在设置 → API Token 中配置 API Token。';

  @override
  String get requiresApiToken => '需要 API Token';

  @override
  String get setApiTokenTooltip => '在设置中配置 API Token 以启用';

  @override
  String get noIntegratedMcps => '未配置集成 MCP';

  @override
  String get addManually => '手动添加';

  @override
  String get importMcpJson => '导入 mcp.json';

  @override
  String get ephemeralMcpsSection => '临时 MCP';

  @override
  String get ephemeralMcpsInfo =>
      '随每次请求发送的 HTTP MCP 服务器。需在 LM Studio 中开启“允许每个请求 MCP”。';

  @override
  String get requiresPerRequestMcps => '需要：Developer → 服务器设置 → 允许每个请求 MCP';

  @override
  String get noEphemeralMcps => '未配置临时 MCP';

  @override
  String get addHttpMcpServer => '添加 HTTP MCP 服务器';

  @override
  String get browseExampleMcps => '浏览示例 MCP 服务器';

  @override
  String get addIntegratedMcpTitle => '添加 MCP';

  @override
  String get editIntegratedMcpTitle => '编辑 MCP';

  @override
  String get addIntegratedMcpInfo =>
      '从 LM Studio 的 mcp.json 复制名称粘贴到这里。例如，看到名为 playwright 的键，就输入 playwright。';

  @override
  String get mcpNameLabel => 'mcp.json 中的名称';

  @override
  String get mcpNameHint => 'playwright';

  @override
  String get mcpNameHelper => '只能使用字母、数字和连字符 — 用 web-search，而不是 web_search。';

  @override
  String get exampleMcpJsonEntry => '💡 mcp.json 条目示例：';

  @override
  String get nameIsRequired => '名称为必填项';

  @override
  String get mcpNameInvalidChars =>
      '使用连字符而不是下划线（LM Studio 不接受像 web_search 这样的名称）。';

  @override
  String get mcpNameAlreadyExists => '该 MCP 已添加';

  @override
  String addedMcp(String name) {
    return '已添加 $name';
  }

  @override
  String updatedMcp(String name) {
    return '已更新 $name';
  }

  @override
  String get editMcpTooltip => '编辑名称';

  @override
  String get unlimitedToolCalls => '无限次工具调用';

  @override
  String get unlimitedToolCallsSubtitle => '取消集成和临时 MCP 的 10 次调用限制（不影响专业搜索）';

  @override
  String get unlimitedToolCallsOn => 'MCP 工具调用迭代次数无限制';

  @override
  String get unlimitedToolCallsOff => '工具调用迭代限制为 10 次';

  @override
  String get structuredOutput => '结构化输出';

  @override
  String get structuredOutputSubtitle => '强制 JSON 响应格式';

  @override
  String get reasoningMode => '思考模式';

  @override
  String get reasoningOff => '关闭';

  @override
  String get reasoningLow => '低';

  @override
  String get reasoningMedium => '中';

  @override
  String get reasoningHigh => '高';

  @override
  String get reasoningOn => '开启';

  @override
  String get reasoningDescOff => '不显示思考过程';

  @override
  String get reasoningDescLow => '少量思考';

  @override
  String get reasoningDescMedium => '适度思考';

  @override
  String get reasoningDescHigh => '详细思考';

  @override
  String get reasoningDescOn => '完整思考过程';

  @override
  String get helpSection => '帮助';

  @override
  String get toolCallingGuide => '工具调用指南';

  @override
  String get toolCallingGuideSubtitle => '了解工具如何工作';

  @override
  String get searxngSetupGuide => 'SearXNG 设置指南';

  @override
  String get searxngSetupGuideSubtitle => '搭建你自己的搜索服务器';

  @override
  String get webSearchConfig => '网页搜索配置';

  @override
  String get howWebSearchWorks => '💡 网络搜索的工作原理';

  @override
  String get howWebSearchWorksSteps =>
      '1. AI 判断需要实时信息\n2. 应用使用 Premium Search 或 SearXNG 进行搜索\n3. 结果返回给 AI\n4. AI 综合答案';

  @override
  String get searchResultsLabel => '搜索结果：';

  @override
  String get webSearchDisabledWarning => '网络搜索已禁用。配置 SearXNG 或升级到 Pro。';

  @override
  String get searxngUrlOptional => 'SearXNG URL（可选）';

  @override
  String get searxngUrlLabel => 'SearXNG URL';

  @override
  String get searxngUrlHint => 'http://localhost:8888';

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
  String get failedToLoadImage => '图片加载失败';

  @override
  String get thinking => '思考中';

  @override
  String get think => '思考';

  @override
  String thoughtFor(String duration) {
    return '思考了 $duration';
  }

  @override
  String get performanceStats => '性能统计';

  @override
  String get regenerate => '重新生成';

  @override
  String get editMessage => '编辑消息';

  @override
  String get editMessageHint => '编辑消息…';

  @override
  String get saveAndRegenerate => '保存并重新生成';

  @override
  String get deleteMessage => '删除消息';

  @override
  String get deleteMessageConfirm => '确定要删除此消息吗？';

  @override
  String get mcpCallTitle => 'MCP 调用';

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
  String get typeMessageHint => '输入消息…';

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
  String get assistantAvatar => '助手头像';

  @override
  String get colorsSection => '颜色';

  @override
  String get userBubble => '用户气泡';

  @override
  String get userText => '用户文本';

  @override
  String get assistantBubble => '助手气泡';

  @override
  String get assistantText => '助手文字';

  @override
  String get darkOverlay => '壁纸暗度';

  @override
  String get darkOverlayDescription => '聊天背景壁纸的暗度';

  @override
  String get usingGlobal => '使用全局';

  @override
  String get useGlobal => '使用全局';

  @override
  String get setCustom => '设置自定义';

  @override
  String get customColor => '自定义颜色';

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
  String get systemPromptOverride => '角色';

  @override
  String get saved => '已保存';

  @override
  String get noSavedPromptsInfo => '暂无已保存的角色。前往“设置”→“角色”创建。';

  @override
  String get selectSavedPromptHint => '选择角色…';

  @override
  String get enterCustomPromptHint => '输入自定义角色提示词…';

  @override
  String get personaShareMemoriesLabel => '共享记忆';

  @override
  String get personaShareMemoriesSubtitle => '关闭后，此角色不会在聊天中接收或学习记忆';

  @override
  String get webSearchOffForThisChat => '仅此聊天关闭';

  @override
  String get reasoningOffForThisChat => '仅此聊天关闭';

  @override
  String get temperatureOverride => '温度';

  @override
  String get maxTokensOverride => '最大 Token 数';

  @override
  String get topPOverride => 'Top-p';

  @override
  String get topKOverride => 'Top-k';

  @override
  String get minPOverride => 'Min-p';

  @override
  String get repeatPenaltyOverride => '重复惩罚';

  @override
  String get contextLengthOverride => '上下文长度';

  @override
  String get systemPromptsTitle => '角色与系统提示词';

  @override
  String get addSystemPromptTooltip => '添加提示词或角色';

  @override
  String get systemPromptsInfoText => '创建和管理系统提示词，可绑定到指定模型或全局使用。选择一项即启用。';

  @override
  String get savedPromptsSection => '已保存的提示词';

  @override
  String get addSystemPrompt => '添加系统提示词';

  @override
  String get newPrompt => '新建提示词或角色';

  @override
  String get noPromptSet => '未设置提示词';

  @override
  String get editSystemPrompt => '编辑系统提示词';

  @override
  String get newSystemPrompt => '新建提示词或角色';

  @override
  String get promptNameLabel => '提示词名称';

  @override
  String get promptNameHint => '例如：代码助手、创意写手…';

  @override
  String get systemPromptLabel => '系统提示词';

  @override
  String get systemPromptEditorHint => '你是一个乐于助人的助手…';

  @override
  String get bindToModels => '绑定到特定模型';

  @override
  String get bindToModelsSubtitle => '将此提示词限定给指定模型，未绑定时对所有模型可用。';

  @override
  String get noModelsLoaded => '未加载模型。请先连接 LM Studio 并加载模型，再绑定提示词。';

  @override
  String get templatesSection => '模板';

  @override
  String get pleaseEnterPromptName => '请输入提示词名称';

  @override
  String get pleaseEnterPromptContent => '请输入提示词内容';

  @override
  String get deleteSystemPromptTitle => '删除系统提示词？';

  @override
  String deleteSystemPromptMessage(String name) {
    return '确定要删除“$name”吗？此操作无法撤销。';
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
  String get progressLabel => '进度';

  @override
  String get speedLabel => '速度';

  @override
  String get etaLabel => '预计剩余时间';

  @override
  String get statusLabel => '状态';

  @override
  String get notAvailable => '不适用';

  @override
  String get calculating => '正在计算…';

  @override
  String get moveToFolderPopup => '移至文件夹';

  @override
  String contextInfo(String used, String total) {
    return '上下文：$used / $total';
  }

  @override
  String get hideAvatars => '隐藏头像';

  @override
  String get hideAvatarsSubtitle => '移除聊天消息中的头像图标';

  @override
  String get autoScroll => '自动滚动';

  @override
  String get autoScrollSubtitle => '有新消息时自动滚动到底部';

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
  String get serverUrlRequired => '服务器地址 *';

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
      '作为 Authorization 标头发送到此 MCP。可粘贴原始 Token（会自动加 Bearer）或完整标头值。';

  @override
  String get additionalHeaders => '附加标头';

  @override
  String get additionalHeadersHint => 'X-Custom-Header: value';

  @override
  String get additionalHeadersHelper =>
      '每行一个标头（名称: 值）。\nAPI Key / Authorization 已在上方设置。';

  @override
  String get labelAndUrlRequired => '标签和 URL 为必填项';

  @override
  String get urlMustStartWithHttp => 'URL 必须以 http:// 或 https:// 开头';

  @override
  String get mcpServerUpdated => 'MCP 服务器已更新';

  @override
  String get mcpServerAdded => '已添加 MCP 服务器';

  @override
  String get importMcpJsonTitle => '导入 mcp.json';

  @override
  String get pasteMcpJsonContent => '粘贴你的 mcp.json 内容';

  @override
  String get mcpJsonLocation =>
      '位于：~/.lmstudio/config/mcp.json\n或在 LM Studio 中：Developer → MCP 设置 → 打开配置';

  @override
  String get mcpJsonContentLabel => 'mcp.json 内容';

  @override
  String get mcpJsonContentHelper => '粘贴整个 mcp.json 文件内容';

  @override
  String get parseJson => '解析 JSON';

  @override
  String foundMcpServers(int count) {
    return '找到 $count 个 MCP 服务器：';
  }

  @override
  String get hasAuthHeaders => '包含身份验证标头';

  @override
  String importSelected(int count) {
    return '导入选中的 $count 个';
  }

  @override
  String get pleasePasteMcpJson => '请粘贴 mcp.json 内容';

  @override
  String get noMcpServersFound => 'JSON 中未找到 mcpServers';

  @override
  String get exampleMcpServers => 'MCP 服务器示例';

  @override
  String get gitMcpInfo => '这些使用 GitMCP 提供 GitHub 仓库的文档';

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
  String get voiceSection => '语音';

  @override
  String get voiceStatus => '状态';

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
  String get voiceSttProvider => '语音识别服务';

  @override
  String get voiceSttProviderSystem => '系统语音';

  @override
  String get voiceSttProviderSystemSubtitle =>
      'iOS 上的 Apple Speech，Android 上的 Google Speech';

  @override
  String get voiceSttProviderWhisper => '本机 Whisper';

  @override
  String get voiceSttProviderWhisperSubtitle =>
      '离线 sherpa-onnx Whisper — 更准确，各平台表现一致';

  @override
  String get voiceWhisperModelNotDownloaded => 'Whisper 模型未下载';

  @override
  String get voiceWhisperModelReady => 'Whisper 模型已就绪';

  @override
  String get voiceWhisperModelSize => '选择大小 — 越大的模型转写越准确';

  @override
  String get voiceWhisperDownloadButton => '下载';

  @override
  String get voiceWhisperDownloading => '正在下载 Whisper 模型…';

  @override
  String get voiceWhisperDownloadStarting => '开始下载…';

  @override
  String get voiceWhisperDownloadFailed => '下载失败';

  @override
  String get voiceWhisperDeleteModel => '删除选中的 Whisper 模型';

  @override
  String get voiceWhisperDeleteTitle => '删除 Whisper 模型？';

  @override
  String get voiceWhisperDeleteMessage =>
      '这会释放该模型占用的设备存储。在你重新下载 Whisper 模型之前，语音识别会回退到系统语音。';

  @override
  String get voiceWhisperDeleteConfirm => '删除';

  @override
  String get voiceWhisperFallback => '未下载模型时回退到系统语音';

  @override
  String get voiceWhisperBiggerBetterTitle => '为什么选更大的模型？';

  @override
  String get voiceWhisperBiggerBetterBody =>
      '更大的 Whisper 模型通常转写更准确 — 尤其在口音、轻声、背景噪音和生僻词上。代价是占用更多存储，在你的设备上运行也更慢。\n\nTiny 足以应对简短清晰的语音，较长的文件建议用 Base 或 Small。Large v3 Turbo 是大模型中最快、最小的（Large v3 的裁剪版）。Full Large v3 最准确，但体积也最大。';

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
      '语音聊天需要助手开口说话。下载语音包可获得最自然的声音，也可以直接使用手机内置语音 — 无需下载。';

  @override
  String get audioSetupWhisperStatus => 'Whisper 语音识别';

  @override
  String get audioSetupKokoroStatus => 'Kokoro 神经语音';

  @override
  String get audioSetupStatusReady => '就绪';

  @override
  String get audioSetupStatusMissing => '未下载';

  @override
  String get audioSetupOnDeviceButton => '下载 Kokoro 语音';

  @override
  String get audioSetupOnDeviceSubtitle => 'Kokoro 神经 TTS · 约 300 MB · 可离线使用';

  @override
  String get audioSetupSystemButton => '使用系统语音';

  @override
  String get audioSetupSystemSubtitle => '内置 STT 和 TTS — 无需下载';

  @override
  String get audioSetupConfigureButton => '语音设置';

  @override
  String get audioSetupNotNow => '暂不';

  @override
  String get audioSetupDownloadingWhisper => '正在下载 Whisper…';

  @override
  String get audioSetupDownloadingKokoro => '正在下载 Kokoro…';

  @override
  String get audioSetupDownloadComplete => '模型已就绪';

  @override
  String get audioSetupContinueButton => '继续';

  @override
  String get voiceModeSettings => '语音模式';

  @override
  String get voiceAutoRead => '自动朗读回复';

  @override
  String get voiceAutoReadSubtitle => '自动朗读新的助手消息';

  @override
  String get voiceSpeechRate => '语速';

  @override
  String get voicePitch => '音调';

  @override
  String get voiceLanguage => '语音语言';

  @override
  String get voiceLanguageSubtitle => '语音回复所用的语言（文本转语音）';

  @override
  String get voiceSttLanguage => '识别语言';

  @override
  String get voiceSttLanguageSubtitle => '用于文字输入的麦克风和语音通话，可与语音回复语言不同。';

  @override
  String get voiceSelection => '语音选择';

  @override
  String get voiceDefault => '默认';

  @override
  String get voiceTestVoice => '测试语音';

  @override
  String get voiceTestVoiceSubtitle => '播放一段示例，试听当前语音设置';

  @override
  String get voiceTestPhrase => '你好！这就是我现在的声音。';

  @override
  String get voiceTestProgressInitializing => '正在启动 TTS 引擎…';

  @override
  String get voiceTestProgressGenerating => '正在生成语音…';

  @override
  String get voiceTestProgressPreparing => '正在准备播放…';

  @override
  String get voiceTestProgressPlaying => '正在播放示例…';

  @override
  String get voiceTestProgressConnecting => '正在连接远程语音…';

  @override
  String get voiceTestProgressComplete => '完成';

  @override
  String get voiceKokoroEngineReady => '引擎已就绪 — 测试很快就会开始';

  @override
  String get voiceKokoroEngineWarming => '正在预热本机引擎…';

  @override
  String get voiceAutoSend => '说完自动发送';

  @override
  String get voiceAutoSendSubtitle => '语音识别结束后自动发送消息';

  @override
  String get voiceSttPauseFor => '发送前的静默时长';

  @override
  String get voiceSttPauseForSubtitle =>
      '停止说话后静默多少秒就发送消息。这与 iOS 麦克风会话限制（约 15 秒一段，自动处理）互不影响。';

  @override
  String get voiceSttListenFor => '最长聆听时间';

  @override
  String get voiceSttListenForSubtitle =>
      '每次麦克风会话的硬上限，达到后应用会重新开启麦克风。在 iOS 上，长时间讲话时 Apple 还会约每 15 秒轮换一次会话。';

  @override
  String voiceSttSeconds(int seconds) {
    return '$seconds秒';
  }

  @override
  String get voiceContinuousConversation => '持续对话';

  @override
  String get voiceContinuousConversationSubtitle => '回复朗读完后自动开始聆听';

  @override
  String get voiceTapToSpeak => '点击说话';

  @override
  String get voiceListening => '正在聆听…';

  @override
  String get voiceThinking => '稍等…';

  @override
  String get voiceResponding => '正在回复…';

  @override
  String get voiceSpeaking => '正在朗读…';

  @override
  String get voiceConvoHintIdle => '点击圆圈开始说话';

  @override
  String get voiceConvoHintListening => '我在听——慢慢来';

  @override
  String get voiceConvoHintStarting => '正在准备麦克风…';

  @override
  String get voiceConvoHintProcessing => '思考中…';

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
      '语音模式可以使用手机内置语音，也可以使用本机下载的语音。聆听可以使用系统内置识别，也可以使用你下载的离线模型。语音始终留在本机 — 不会发送到外部服务器。';

  @override
  String get voiceExitMode => '切换到键盘';

  @override
  String get voiceTtsProvider => 'TTS 提供商';

  @override
  String get voiceTtsProviderNative => '设备（本机）';

  @override
  String get voiceTtsProviderNativeSubtitle => '使用系统内置语音 — 可离线使用';

  @override
  String get voiceTtsProviderKokoro => '已下载的语音';

  @override
  String get voiceTtsProviderKokoroSubtitle => '在本机运行的自然语音';

  @override
  String get voiceTtsProviderKokoroRemote => 'Kokoro (PC)';

  @override
  String get voiceTtsProviderKokoroRemoteSubtitle =>
      '在 PC 上运行 Kokoro，语音更快、质量更高';

  @override
  String get voiceTtsProviderElevenLabs => 'ElevenLabs';

  @override
  String get voiceTtsProviderElevenLabsSubtitle => 'Pro · 你的 API 密钥 · 云端语音';

  @override
  String get voiceTtsElevenLabs => 'ElevenLabs';

  @override
  String get voiceTtsElevenLabsHint => '你的密钥 · 来自你的 ElevenLabs 语音库';

  @override
  String get voiceElevenLabsApiKey => 'ElevenLabs API 密钥';

  @override
  String get voiceElevenLabsApiKeyHint => '粘贴你在 elevenlabs.io 获取的 xi-api-key';

  @override
  String get voiceElevenLabsTestKey => '验证密钥';

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
      '使用你的 ElevenLabs API 密钥，为角色指定录音室级语音。语音聊天、自动朗读和气泡朗读使用同一引擎。';

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
  String get voiceGrokTestKey => '验证密钥';

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
  String get personaVoiceProviderLabel => '提供商';

  @override
  String get personaVoiceProviderKokoro => 'Kokoro';

  @override
  String get personaVoiceProviderGlobal => '使用全局语音设置';

  @override
  String get personaVoiceConfigureInSettings => '在“设置 → 语音”中配置';

  @override
  String get premiumGrokTts => 'Grok 语音';

  @override
  String get premiumGrokTtsTagline => '自带密钥的神经 TTS';

  @override
  String get premiumGrokTtsDescription =>
      '使用你的 xAI API 密钥，并为角色指定 Grok 语音。语音聊天、自动朗读和气泡朗读使用同一引擎。';

  @override
  String get voiceRemoteKokoroConnected => '已连接到 PC 上的 Kokoro';

  @override
  String get voiceRemoteKokoroNotFound => '在 PC 上找不到 Kokoro TTS';

  @override
  String get voiceRemoteKokoroRequiresConnect =>
      '需要在 Mac 上开启“与手机共享”，或在 Windows/Linux 上运行 LM Mini Connect';

  @override
  String get voiceKokoroVoice => 'Kokoro 语音';

  @override
  String get voiceKokoroSpeed => '语速';

  @override
  String get voiceKokoroModelReady => 'Kokoro 模型已就绪';

  @override
  String get voiceKokoroModelReadySubtitle => '已下载的语音已就绪';

  @override
  String get voiceKokoroModelNotDownloaded => 'Kokoro 模型未下载';

  @override
  String get voiceKokoroModelSize => '需要下载（~400 MB 共享包）';

  @override
  String get voiceKokoroDownloading => '正在下载 Kokoro 模型…';

  @override
  String get voiceKokoroDownloadStarting => '开始下载…';

  @override
  String get voiceKokoroDownloadButton => '下载';

  @override
  String get voiceKokoroDownloadFailed => '下载失败。点击重试。';

  @override
  String get voiceKokoroFallback => '如果未下载 Kokoro 模型，将回退为原生语音';

  @override
  String get voiceKokoroDeleteModel => '删除 Kokoro 模型';

  @override
  String get voiceKokoroDeleteTitle => '删除 Kokoro 模型？';

  @override
  String get voiceKokoroDeleteMessage => '这会删除所有已下载的 TTS 语言包，之后可以重新下载。';

  @override
  String get voiceKokoroDeleteConfirm => '删除';

  @override
  String get voiceTtsLanguagePacksHint =>
      '英语、西班牙语、法语和中文共用一次 Kokoro 下载（约 400 MB）。德语和俄语使用更小的 Piper 语音（各约 34 MB）。';

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
    return 'Kokoro · 共享下载 · ~$size MB';
  }

  @override
  String voiceTtsPiperPackSize(int size) {
    return 'Piper 语音 · 较小下载 · ~$size MB';
  }

  @override
  String get voiceTtsSharedPackDeleteMessage =>
      '这会移除英语、西班牙语、法语和中文共用的下载，之后可以重新下载。';

  @override
  String get connecting => '正在连接…';

  @override
  String get saveAndTestConnection => '保存并测试连接';

  @override
  String connectedTo(String provider) {
    return '✅ 已连接到 $provider';
  }

  @override
  String connectionToFailed(String provider) {
    return '❌ 连接 $provider 失败 — 请检查你的 API 密钥';
  }

  @override
  String errorGeneric(String error) {
    return '❌ 错误：$error';
  }

  @override
  String get provider => '提供商';

  @override
  String cloudApiKeyLabel(String provider) {
    return '$provider API 密钥';
  }

  @override
  String get enterApiKeyHint => '输入你的 API 密钥…';

  @override
  String getApiKey(String provider) {
    return '获取 $provider API 密钥';
  }

  @override
  String get baseUrl => '基础 URL';

  @override
  String get customBaseUrlOptional => '自定义基础 URL（可选）';

  @override
  String get accountSection => '账户';

  @override
  String get signIn => '登录';

  @override
  String get signInSubtitle => '登录以启用云备份';

  @override
  String get cloudServicesUnavailable => '云服务不可用';

  @override
  String signedInVia(String method) {
    return '通过$method登录';
  }

  @override
  String get lmMiniProSection => 'LM MINI PRO';

  @override
  String get proActive => 'Pro 已激活';

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
  String get saveToPhotos => '保存到相册';

  @override
  String get savedToPhotos => '已保存到相册';

  @override
  String get couldNotSaveToPhotos => '无法保存此文件。';

  @override
  String get share => '分享';

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
  String get e2eBanner => '端到端加密 — 你的密码永远不会离开本机';

  @override
  String get analytics => '分析';

  @override
  String get analyticsSubtitle => '使用统计、Token 和模型洞察';

  @override
  String get memory => '记忆';

  @override
  String memoryItemCount(int count) {
    return '$count 条 • 跨对话长期保留';
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
  String get conversationBranchingSubtitle => '可从任意消息分叉出对话';

  @override
  String get cloudBackupPro => '云备份';

  @override
  String get cloudBackupProSubtitle => '加密备份和恢复到云端';

  @override
  String get analyticsDashboard => '分析仪表板';

  @override
  String get analyticsDashboardSubtitle => '使用统计、Token 和模型洞察';

  @override
  String get cloudApiProviders => '云 API 提供商';

  @override
  String get cloudApiProvidersSubtitle => 'Mistral、DeepSeek 等';

  @override
  String get addProviderLabel => '添加提供商';

  @override
  String get noCloudProvidersTitle => '暂无云提供商';

  @override
  String get noCloudProvidersSubtitle =>
      '点击 + 添加云 API 提供商。\n使用你自己的 Groq、DeepSeek 等 API 密钥。';

  @override
  String get editProviderTitle => '编辑提供商';

  @override
  String get addCloudProviderTitle => '添加云提供商';

  @override
  String get providerLabel => '提供商';

  @override
  String get apiKeyLabel => 'API 密钥';

  @override
  String get pasteLabel => '粘贴';

  @override
  String get baseUrlRequiredLabel => '基础 URL（必填）';

  @override
  String get customBaseUrlOptionalLabel => '自定义基础 URL（可选）';

  @override
  String get advancedLabel => '高级';

  @override
  String get fetchingLabel => '正在获取…';

  @override
  String get fetchAvailableModelsLabel => '获取可用模型';

  @override
  String get availableModelsLabel => '可用模型：';

  @override
  String get suggestedModelsLabel => '推荐模型：';

  @override
  String get modelIdLabel => '模型 ID';

  @override
  String get disableCloudProviderSubtitle => '禁用后保留配置但不再使用';

  @override
  String get setAsActiveProviderLabel => '设为当前提供商';

  @override
  String get deactivateLabel => '停用';

  @override
  String get switchedBackToLocalLmStudio => '已切换回本地 LM Studio';

  @override
  String get saveChangesLabel => '保存更改';

  @override
  String get enterDisplayNameError => '请输入显示名称';

  @override
  String get enterApiKeyError => '请输入 API 密钥';

  @override
  String get enterBaseUrlError => '请输入自定义提供商的基础 URL';

  @override
  String get enterApiKeyFirst => '请先输入 API 密钥';

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
    return '$name 已设为当前提供商';
  }

  @override
  String get memoryPro => '记忆';

  @override
  String get memoryProSubtitle => '跨对话长期保留的记忆';

  @override
  String get richExportShare => '完整导出与分享';

  @override
  String get richExportShareSubtitle => '导出到 Obsidian、Notes、Notion 等';

  @override
  String autoUnloadAfter(String value) {
    return '$value 后自动卸载';
  }

  @override
  String get subscriptionRestore => '恢复';

  @override
  String get subscriptionTerms => '条款';

  @override
  String get subscriptionPrivacy => '隐私';

  @override
  String get secureYourAccount => '保护你的账户';

  @override
  String get signInWithApple => '使用 Apple 登录';

  @override
  String get signInWithGoogle => '使用 Google 登录';

  @override
  String get subscriptionSecured => '你的订阅已受保护';

  @override
  String get packagesNotAvailable => '套餐尚未提供。';

  @override
  String get welcomeToPro => '🎉 欢迎来到 LM Mini Pro！';

  @override
  String get subscriptionRestored => '✅ 订阅已恢复！';

  @override
  String get noActiveSubscription => '未找到有效订阅。';

  @override
  String get accountLinked => '✅ 账户已关联！';

  @override
  String get account => '账户';

  @override
  String get createAccount => '创建账户';

  @override
  String get emailLabel => '电子邮件';

  @override
  String get passwordLabel => '密码';

  @override
  String get forgotPassword => '忘记密码？';

  @override
  String get forgotPasswordNeedEmail => '请先输入邮箱，再点击“忘记密码？”。';

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
  String get cloudBackupEnabled => '已启用 — 你的账户支持加密备份';

  @override
  String get endToEndEncryption => '端到端加密';

  @override
  String get e2eSubtitle => '备份用你的密码加密 — 我们无法读取';

  @override
  String get upgradeForCloudBackup => '升级到专业版以启用加密云备份';

  @override
  String get signOut => '退出登录';

  @override
  String get signOutConfirm => '退出登录？';

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
  String get yourBackups => '你的备份';

  @override
  String get e2eBackupBanner => '端到端加密。';

  @override
  String get e2eBackupDetail => '备份在离开本机前会用你的密码加密，我们无法读取你的数据。';

  @override
  String get exportingData => '正在导出数据…';

  @override
  String get preparing => '正在准备…';

  @override
  String get encrypting => '正在加密…';

  @override
  String get uploading => '正在上传…';

  @override
  String get savingMetadata => '正在保存元数据…';

  @override
  String get done => '完成！';

  @override
  String get noBackupsYet => '还没有备份';

  @override
  String get createFirstBackup => '在上方创建你的第一个加密备份';

  @override
  String get encrypted => '已加密';

  @override
  String get restore => '恢复';

  @override
  String get encryptionPassphraseLabel => '加密密码';

  @override
  String get enterStrongPassphrase => '输入一个高强度密码';

  @override
  String get confirmPassphraseLabel => '确认密码';

  @override
  String get passphraseRememberWarning => '记住这个密码！一旦丢失，备份将无法恢复，我们不会在任何地方保存它。';

  @override
  String get passphraseRestoreHint => '输入创建此备份时使用的密码。';

  @override
  String get minCharsRequired => '至少需要 4 个字符。';

  @override
  String get passphrasesDoNotMatch => '两次输入的密码不一致。';

  @override
  String get encryptAndBackUp => '加密并备份';

  @override
  String get decryptAndRestore => '解密并恢复';

  @override
  String get encryptionPassphrase => '加密密码';

  @override
  String get savedPassphrasePrompt => '你有之前备份保存的密码。要沿用它，还是设置新的密码？';

  @override
  String get newPassphrase => '新密码';

  @override
  String get useSame => '沿用';

  @override
  String get setEncryptionPassphrase => '设置加密密码';

  @override
  String get choosePassphraseBackup => '选择一个密码来加密此备份，之后在任何设备上恢复都需要用到它。';

  @override
  String get choosePassphraseDetail =>
      '选择一个密码来加密备份。密码只保存在你的设备上 — 我们无法看到，恢复时需要用到它。';

  @override
  String backupFailed(String error) {
    return '备份失败：$error';
  }

  @override
  String get restoreBackupConfirm => '恢复备份？';

  @override
  String get restoreWarning => '这会用此备份中的数据替换你当前的所有对话、消息和文件夹。\n\n此操作无法撤消。';

  @override
  String get continueAction => '继续';

  @override
  String get enterPassphrase => '输入密码';

  @override
  String get passphraseDecryptHint => '此备份为端到端加密，输入创建时使用的密码。';

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
  String get messages => '消息';

  @override
  String get conversations => '对话';

  @override
  String get totalTokens => 'Token 总数';

  @override
  String get avgResponse => '平均回复';

  @override
  String get modelUsage => '模型使用情况';

  @override
  String get noModelUsageData => '还没有模型使用数据。\n开始对话即可在此查看统计。';

  @override
  String get analyticsSync => '分析数据会同步到你的账户，退出登录后会重置。';

  @override
  String get clearAllMemories => '清除所有记忆';

  @override
  String get memoryOn => '开';

  @override
  String get memoryOff => '关';

  @override
  String get memoryInfoText => '记忆会注入系统提示词，让 LLM 跨对话记住你。';

  @override
  String get noMemoriesYet => '还没有记忆';

  @override
  String noMemoriesInCategory(String category) {
    return '暂无$category记忆';
  }

  @override
  String get memoryTapToAdd => '点击 + 添加新记忆，或选择其他类别。';

  @override
  String get memoryAddHint => '添加你希望 AI 在所有对话中都记住的关于你的信息。';

  @override
  String get addMemory => '添加记忆';

  @override
  String get category => '类别';

  @override
  String get editMemory => '编辑记忆';

  @override
  String get deleteMemory => '删除记忆';

  @override
  String removeMemoryConfirm(String content) {
    return '删除这段记忆？\n\n“$content”';
  }

  @override
  String get clearAllMemoriesTitle => '清除所有记忆';

  @override
  String clearAllMemoriesConfirm(int count) {
    return '这将永久删除全部 $count 条记忆。此操作无法撤消。';
  }

  @override
  String get clearAll => '全部清除';

  @override
  String get justNow => '刚刚';

  @override
  String get categoryPersonal => '个人';

  @override
  String get categoryPreferences => '偏好设置';

  @override
  String get categoryLifestyle => '生活方式';

  @override
  String get categoryEmotional => '情感';

  @override
  String get categoryTechnical => '技术';

  @override
  String get categoryWork => '工作';

  @override
  String get categoryGeneral => '通用';

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
    return '已选择：$name';
  }

  @override
  String get unloadModelTooltip => '从内存中卸载模型';

  @override
  String get modelInfoTooltip => '模型信息';

  @override
  String get loadedBadge => '已加载';

  @override
  String get visionBadge => '视觉';

  @override
  String get toolsBadge => '工具';

  @override
  String get selectedModel => '已选模型';

  @override
  String get unloading => '正在卸载…';

  @override
  String get unload => '卸载';

  @override
  String get loaded => '已加载';

  @override
  String get loadModel => '加载模型';

  @override
  String get enterModelIdOrUrl => '输入模型 ID 或 HuggingFace URL：';

  @override
  String get modelIdHint => 'microsoft/phi-4';

  @override
  String get modelIdHelper => '模型 ID 或 https://huggingface.co/…';

  @override
  String get huggingFaceDetected => '检测到 HuggingFace URL — 接下来选择量化';

  @override
  String get starting => '启动中…';

  @override
  String get download => '下载';

  @override
  String get selectQuantization => '选择量化';

  @override
  String get loadingQuantizations => '正在加载量化…';

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
  String get noQuantizations => '暂无量化版本';

  @override
  String get noGgufFiles => '该仓库中未找到 GGUF 文件';

  @override
  String foundQuantizations(int count) {
    return '找到 $count 个 GGUF 量化版本';
  }

  @override
  String get unknown => '未知';

  @override
  String downloadingModel(String quantization) {
    return '正在下载 $quantization 量化模型…';
  }

  @override
  String get modelAlreadyDownloaded => '模型已下载';

  @override
  String downloadFailed(String error) {
    return '下载失败：$error';
  }

  @override
  String get enterModelIdentifier => '请输入模型 ID 或 URL';

  @override
  String get modelAlreadyLoaded => '模型已加载';

  @override
  String get currentlyLoaded => '目前已加载：';

  @override
  String loadAlongsideWarning(String name) {
    return '同时加载“$name”和现有模型会占用更多内存。';
  }

  @override
  String get unloadAllAndLoad => '全部卸载并加载';

  @override
  String get swap => '替换';

  @override
  String get loadAlongside => '同时加载';

  @override
  String get loadParamsConflictTitle => '加载设置不一致';

  @override
  String loadParamsConflictBody(String name) {
    return '“$name”已在 LM Studio 中加载，其设置与 LM Mini 的模型加载配置不同。重新加载可能需要一分钟，并占用额外内存。';
  }

  @override
  String get loadParamsConflictTableHeader => '参数不同：';

  @override
  String get loadParamsLmStudio => 'LM Studio';

  @override
  String get loadParamsLmMini => 'LM Mini';

  @override
  String get loadParamsConflictHint =>
      '沿用 LM Studio 的已加载设置可避免重新加载。卸载并重新加载会应用 LM Mini 的设置。同时加载则让两个实例都留在内存中。';

  @override
  String get loadParamsUseExisting => '使用 LM Studio 设置';

  @override
  String get loadParamsReloadWithMini => '卸载后按 LM Mini 设置加载';

  @override
  String get loadParamsLoadParallel => '使用 LM Mini 设置加载（并行）';

  @override
  String get reloadModelForContextTitle => '重新加载模型？';

  @override
  String reloadModelForContextBody(String name, String loaded, String desired) {
    return '上下文长度在加载模型时生效。“$name”当前加载为 $loaded。要用 $desired 重新加载吗？';
  }

  @override
  String get reloadModelForContextNow => '重新加载';

  @override
  String get reloadModelForContextLater => '暂不';

  @override
  String loadModelConfirm(String name) {
    return '将“$name”加载到内存中？';
  }

  @override
  String get unloadModelTip => '模型加载后，你可以用弹出按钮或在此页面卸载。';

  @override
  String get modelLoadedSuccess => '模型加载成功';

  @override
  String get failedToLoadModel => '加载模型失败';

  @override
  String get modelInfo => '模型信息';

  @override
  String get infoName => '名称';

  @override
  String get infoType => '类型';

  @override
  String get infoArchitecture => '架构';

  @override
  String get infoPublisher => '发布者';

  @override
  String get infoQuantization => '量化';

  @override
  String get infoParameters => '参数';

  @override
  String get infoSize => '大小';

  @override
  String get infoMaxContext => '最大上下文';

  @override
  String get infoLoadedContext => '已加载上下文';

  @override
  String get infoStatus => '状态';

  @override
  String get available => '可用';

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
  String get showImageButtons => '在对话消息上显示图像按钮';

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
  String get checkpoint => 'Checkpoint';

  @override
  String get generationParameters => '生成参数';

  @override
  String get negativePrompt => '负面提示词';

  @override
  String get steps => '采样步数';

  @override
  String get cfgScale => 'CFG 系数';

  @override
  String get width => '宽度';

  @override
  String get height => '高度';

  @override
  String get sampler => '采样器';

  @override
  String get scheduler => '调度器';

  @override
  String get automatic => '自动';

  @override
  String get seedLabel => '随机种子（-1 = 随机）';

  @override
  String get batchSize => '批量大小';

  @override
  String get options => '选项';

  @override
  String get restoreFaces => '面部修复';

  @override
  String get restoreFacesSubtitle => '修复生成图像中的人脸';

  @override
  String get tiling => '平铺';

  @override
  String get tilingSubtitle => '生成无缝的可平铺纹理';

  @override
  String get promptOptions => '提示词选项';

  @override
  String get reviewPromptBeforeSending => '发送前检查提示词';

  @override
  String get reviewPromptSubtitle => '生成前编辑图像提示词';

  @override
  String get autoGenerateImage => '自动生成图像';

  @override
  String get autoGenerateSubtitle => 'AI 提供提示词时自动生成图像';

  @override
  String get resetToDefaults => '重置为默认值';

  @override
  String get featureRequestsTitle => '功能请求';

  @override
  String get featureRequestsUnavailable => '功能请求不可用';

  @override
  String get featureRequestsUnavailableDetail => '此功能需要联网。请检查网络后重试。';

  @override
  String get tryAgain => '再试一次';

  @override
  String get votesLeft => '剩余';

  @override
  String get popular => '热门';

  @override
  String get myRequests => '我的请求';

  @override
  String get completed => '已完成';

  @override
  String get submitIdea => '提交想法';

  @override
  String get noFeatureRequests => '尚无功能请求';

  @override
  String get beFirstToSubmit => '快来第一个提交想法！';

  @override
  String get noRequestsSubmitted => '没有提交任何请求';

  @override
  String get tapToSubmitFirst => '点击下方按钮，提交你的第一个想法！';

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
  String get titleHint => '简要概括你的想法';

  @override
  String get descriptionRequired => '描述 *';

  @override
  String get descriptionHint => '详细描述你的功能请求';

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
  String get deleteYourRequest => '删除你的请求';

  @override
  String get anonymous => '匿名';

  @override
  String get officialResponse => '官方回应';

  @override
  String get noCommentsYet => '还没有评论';

  @override
  String get beFirstToComment => '来第一个分享你的想法吧！';

  @override
  String get adminBadge => '管理员';

  @override
  String get moderatorBadge => '版主';

  @override
  String get experiencedUserBadge => '资深';

  @override
  String get adminManageSubmitter => '管理提交者';

  @override
  String get adminManageUserTitle => '管理用户';

  @override
  String get adminUserUpdated => '用户已更新';

  @override
  String get adminCommunityRoles => '社区角色';

  @override
  String get adminModeratorRole => '版主';

  @override
  String get adminModeratorRoleSubtitle => '可绕过评论刷屏限制并显示 Mod 徽章';

  @override
  String get adminExperiencedUserRole => '资深用户';

  @override
  String get adminExperiencedUserRoleSubtitle => '在功能请求评论中显示资深徽章';

  @override
  String get adminGrantPremiumTitle => '授予免费 Pro';

  @override
  String get adminGrantPremiumSubtitle => '限时免费赠送该用户 LM Mini Pro';

  @override
  String get adminGrantPremiumAmountLabel => '时长';

  @override
  String get adminGrantPremiumAmountHint => '输入数量';

  @override
  String get adminGrantPremiumUnitDays => '天';

  @override
  String get adminGrantPremiumUnitWeeks => '周';

  @override
  String get adminGrantPremiumUnitMonths => '月';

  @override
  String get adminGrantPremiumGrantButton => '授予 Pro';

  @override
  String get adminGrantPremiumInvalidAmount => '输入正数';

  @override
  String get adminGrantPremiumReasonLabel => '原因';

  @override
  String get adminGrantPremiumReasonHint => '可选——会展示给用户（例如：抱歉给你带来麻烦）';

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
  String get adminRevokePremiumMessage => '要移除该用户由管理员授予的 Pro 权限吗？';

  @override
  String get adminRevokePremiumConfirm => '撤销';

  @override
  String get premiumGrantBannerTitle => '你获得了赠送的 Pro';

  @override
  String premiumGrantBannerBody(String duration) {
    return '免费获得 $duration 的 LM Mini Pro，有效期内尽享高级功能。';
  }

  @override
  String premiumGrantBannerReason(String reason) {
    return '原因：$reason';
  }

  @override
  String get premiumGrantDialogTitle => '已解锁赠送的 Pro';

  @override
  String premiumGrantDialogBody(String duration) {
    return '管理员向你赠送了 $duration 的 LM Mini Pro。云备份、记忆、分析等功能现已可用。';
  }

  @override
  String premiumGrantDialogReason(String reason) {
    return '原因：$reason';
  }

  @override
  String get premiumGrantDialogButton => '太棒了';

  @override
  String get youBadge => '你';

  @override
  String get deleteComment => '确定要删除这条评论吗？';

  @override
  String maxCommentsReached(int max) {
    return '你已连续发表 $max 条评论，请等待其他用户回复。';
  }

  @override
  String get addYourName => '添加你的名字';

  @override
  String get replyAsAdmin => '以管理员身份回复…';

  @override
  String get writeComment => '写评论…';

  @override
  String get errorTryAgain => '错误：请重试。';

  @override
  String statusUpdated(String status) {
    return '状态更新为$status';
  }

  @override
  String get addOfficialResponse => '添加官方回复…';

  @override
  String get replySaved => '回复已保存';

  @override
  String get deleteRequestConfirm => '确定要删除这条功能请求吗？此操作无法撤销。';

  @override
  String get requestDeleted => '请求已删除';

  @override
  String get deleteCommentTitle => '删除评论';

  @override
  String get deleteCommentConfirm => '确定要删除这条评论吗？';

  @override
  String get commentDeleted => '评论已删除';

  @override
  String get generationParametersSection => '生成参数';

  @override
  String get temperature => '温度';

  @override
  String get temperatureSubtitle => '决定回复有多发散还是多聚焦。越低越严谨；越高越多变。';

  @override
  String get topP => 'Top-p';

  @override
  String get topPSubtitle => '允许的候选词范围有多广。越低，回复越聚焦。';

  @override
  String get minP => 'Min-p';

  @override
  String get minPSubtitle => '过滤掉概率极低的候选词。越高，文本越稳妥、越可预测。';

  @override
  String get repeatPenalty => '重复惩罚';

  @override
  String get repeatPenaltySubtitle => '降低模型重复相同说法的概率。1.0 = 关闭。';

  @override
  String get frequencyPenalty => '频率惩罚';

  @override
  String get frequencyPenaltySubtitle => '减少模型过于常用的词。';

  @override
  String get presencePenalty => '存在惩罚';

  @override
  String get presencePenaltySubtitle => '鼓励模型聊新话题，而不是反复围绕旧话题。';

  @override
  String get tokenLimits => 'Token 限制';

  @override
  String get maxOutputTokens => '最大输出 Token';

  @override
  String get maxOutputTokensSubtitle => '单条回复最长能有多长。越高，回答越长（等待也越久）。';

  @override
  String get contextWindow => '上下文窗口';

  @override
  String get contextWindowSubtitle => '模型一次能记住多少对话内容。越高越占内存。';

  @override
  String get modelLoadingConfig => '模型加载配置';

  @override
  String get loadContextLength => '上下文长度';

  @override
  String get loadContextSubtitle =>
      '模型聊天时以及在 LM Studio 中加载时可用的上下文长度。越高越占内存/显存。';

  @override
  String get contextFitTitle => '上下文用满时';

  @override
  String get contextFitSubtitle =>
      '把历史压缩到已加载上下文的 90% 以内，让你继续聊天。压缩会生成一份摘要，服务器会话丢失时可以复用。';

  @override
  String get contextFitOff => '停止';

  @override
  String get contextFitRoll => '滚动';

  @override
  String get contextFitCutMiddle => '裁掉中间';

  @override
  String get contextFitOffHelp => '提示词超出模型上下文时报错。';

  @override
  String get contextFitRollHelp => '丢弃最早的消息，保留最近的消息。';

  @override
  String get contextFitCutMiddleHelp => '保留对话开头和最近几轮，丢弃中间部分。';

  @override
  String get compactChat => '压缩';

  @override
  String get compactingChat => '压缩中…';

  @override
  String get compactChatHint => '总结较早的消息，让你能在这个上下文窗口继续聊天。';

  @override
  String get compactChatDone => '对话已压缩。下次发送将使用摘要加新消息。';

  @override
  String get compactChatFailed => '无法压缩此对话，请重试。';

  @override
  String get compactChatNeedModel => '请先选择模型再压缩。';

  @override
  String get evalBatchSize => '评估批次大小';

  @override
  String get evalBatchSubtitle => '加载时一次处理多少文本。调高可能更快，但更占内存。';

  @override
  String get numExperts => '专家数量';

  @override
  String get numExpertsSubtitle => '仅适用于“专家混合”模型。不清楚需要时请留空。';

  @override
  String get flashAttention => 'Flash Attention';

  @override
  String get flashAttentionSubtitle => '加快模型速度，还能省内存。除非出问题，否则保持开启。';

  @override
  String get offloadKvCache => '将 KV 缓存卸载到 GPU';

  @override
  String get offloadKvCacheSubtitle => '用 GPU 更高效地保存对话上下文。有 GPU 就保持开启。';

  @override
  String get resizeImageForPhysicalBatch => '按物理批次缩小图片';

  @override
  String get resizeImageForPhysicalBatchSubtitle =>
      '当图片占用的 Token 超过本地服务器的物理批次时自动缩小，避免模型崩溃。';

  @override
  String get resizeImageForPhysicalBatchHelp =>
      'LM Studio、Ollama、Jan、Unsloth、oMLX 以及端侧模型的物理批次固定为 512 Token，一张原图可能占用 560 个甚至更多视觉 Token，导致服务器中止、模型被卸载。开启后，Mini 会测量图片尺寸并缩小，让它保持在批次限制内。关闭则发送原始图片。';

  @override
  String get chainOfThoughtSubtitle => '可用时显示 AI 的分步思考过程。';

  @override
  String get reasoningUnsupportedToast => '该模型在 LM Studio 中不支持思考，已关闭思考。';

  @override
  String get reasoningNotExposedChatHint => 'LM Studio 无法关闭此模型的思考功能，请换一个模型。';

  @override
  String get premiumSearchActive => '高级搜索已开启';

  @override
  String get premiumSearchPlusSearxng => '+ SearXNG';

  @override
  String get webSearchDisabledAll => '所有对话已关闭网络搜索';

  @override
  String get configureSearch => '配置搜索';

  @override
  String get advancedFeaturesSection => '高级功能';

  @override
  String get howToolCallingWorks => '工具调用的工作原理';

  @override
  String get stepAskQuestion => '你提出问题';

  @override
  String get stepAskExample => '例如，“东京的天气怎么样？”';

  @override
  String get stepAiRequestsTool => 'AI 请求调用工具';

  @override
  String get stepAiRequestsExample => '模型决定需要网络搜索';

  @override
  String get stepAppExecutes => '应用执行工具';

  @override
  String get stepAppExecutesExample => '使用高级搜索或 SearXNG 进行搜索';

  @override
  String get stepResultsSent => '结果发送至 AI';

  @override
  String get stepResultsExample => '搜索结果已添加到对话中';

  @override
  String get stepAiAnswers => 'AI 生成回答';

  @override
  String get stepAiAnswersExample => '模型综合生成有帮助的回答';

  @override
  String get toolCallingModelNote => '例如 Qwen、Llama 3.1+ 或 Mistral。';

  @override
  String get searxngSetup => 'SearXNG 设置';

  @override
  String get searxngDescription => 'SearXNG 是一个免费、注重隐私的元搜索引擎，可以自行托管。';

  @override
  String get dockerRecommended => '选项 1：Docker（推荐）';

  @override
  String get publicInstance => '选项 2：使用公共实例';

  @override
  String get findPublicInstances => '查找公共实例：';

  @override
  String get selfHostRecommended => '为保证可靠性，建议自托管。';

  @override
  String get clipboardEmpty => '剪贴板为空。请先复制你的 mcp.json 内容。';

  @override
  String get clipboardAccessFailed => '无法访问剪贴板。请手动粘贴到下方输入框。';

  @override
  String get pasteFromClipboard => '从剪贴板粘贴';

  @override
  String get httpServersImportNote => 'HTTP 服务器 → 临时 MCP（每次请求时发送给 LM Studio）';

  @override
  String get localMcpsImportNote => '本地 MCP → 集成 MCP（使用“mcp/name”格式）';

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
  String get glassEffectsSubtitle => '标题和菜单的磨砂模糊效果。关闭后发热更少、更省电。';

  @override
  String get lowBatteryModeLabel => '低电量模式';

  @override
  String get lowBatteryModeSubtitle =>
      '关闭玻璃效果，流式回复时只用纯文本，并在整条消息完成后再同步 Home/iCloud。回复结束前屏幕保持唤醒，以免流式输出被中断。';

  @override
  String get backgroundSection => '背景';

  @override
  String get chatBackground => '壁纸';

  @override
  String get chatBackgroundSubtitle => '每段对话的背景照片';

  @override
  String get avatarsSection => '图片';

  @override
  String get chatHeaderAvatarLabel => '顶部头像';

  @override
  String get chatHeaderAvatarSubtitle => '在对话顶部显示小头像';

  @override
  String get avatarAboveMessageLabel => '消息上方头像';

  @override
  String get avatarAboveMessageSubtitle => '把头像放在气泡上方';

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
  String get streamingPhaseProcessingPrompt => '正在处理提示词';

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
    return '正在使用移动数据 — $provider 需要 Wi-Fi';
  }

  @override
  String networkNeedsWifiBody(String provider, String host) {
    return '电脑上的 $provider（$host）只能在与电脑相同的 Wi-Fi 网络中访问。请连接该 Wi-Fi，或开启远程访问以便随时随地使用。';
  }

  @override
  String networkLostWifiTitle(String provider) {
    return '与 $provider 的连接已断开';
  }

  @override
  String get networkLostWifiBody =>
      '手机已断开 Wi-Fi。请重新连接与电脑相同的 Wi-Fi，或开启远程访问以便随时随地继续聊天。';

  @override
  String get networkUseRemoteAccess => '使用远程访问';

  @override
  String get networkSwitchProvider => '切换提供商';

  @override
  String get messageNotDelivered => '未送达 · 轻点重试';

  @override
  String get messageRetrying => '正在发送…';

  @override
  String get messageNotDeliveredA11y => '消息未送达。轻点重试。';

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
  String get assistantAvatarLabel => 'AI';

  @override
  String get aiAssistantPicture => 'AI 的默认外观';

  @override
  String get chatBehaviorSection => '对话文字';

  @override
  String get fontSizeLabel => '文字大小';

  @override
  String get iconSizeLabel => '按钮大小';

  @override
  String pointsValue(int value) {
    return '$value';
  }

  @override
  String get previewLabel => '预览';

  @override
  String get previewAssistantMessage =>
      '你好！我是你的 AI 助手。今天有什么可以帮你的？这是一个**粗体**词和一些 `inline code`。';

  @override
  String get readAloud => '大声朗读';

  @override
  String appearanceActionTapped(String label) {
    return '$label 已点击';
  }

  @override
  String get autoScrollStreaming => '自动跟随新回复';

  @override
  String get autoScrollStreamingSubtitle => '让对话始终滚动到最新内容';

  @override
  String get showChatStarters => '新对话建议';

  @override
  String get showChatStartersSubtitle => '在空对话中显示可滚动的提示词胶囊';

  @override
  String get useLegacyComposer => '经典消息输入框';

  @override
  String get useLegacyComposerSubtitle => '使用经典的紧凑输入框，替代新版闪光输入框';

  @override
  String get hideAvatarsLabel => '隐藏头像';

  @override
  String get moreSpaceForContent => '给消息更多空间';

  @override
  String get enterKeyBehaviorLabel => '回车键';

  @override
  String get enterKeyAutoDescription => '电脑键盘上回车发送，手机上换行';

  @override
  String get enterKeySendDescription => 'Enter 发送 · Shift+Enter 换行';

  @override
  String get enterKeyNewlineDescription => 'Enter 总是开始新行';

  @override
  String get sendLabel => '发送';

  @override
  String get newLineLabel => '换行';

  @override
  String get themeSystem => '系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get backLabel => '返回';

  @override
  String get nextLabel => '下一个';

  @override
  String get getStartedLabel => '开始使用';

  @override
  String get connectionSuccessful => '连接成功！';

  @override
  String get connectionFailedMessage => '连接失败';

  @override
  String get lmStudioServerFoundNeedsKey => '找到服务器！在上方输入你的 API 密钥，然后点按“测试连接”。';

  @override
  String get lmStudioScanServerNeedsKey => '已找到——添加 API 密钥即可连接';

  @override
  String lmStudioUsingServerNeedsKey(String url) {
    return '正在使用 $url。在下方输入 API 密钥后测试连接。';
  }

  @override
  String get lmStudioAuthDialogTitle => '找到服务器';

  @override
  String get lmStudioAuthDialogMessage =>
      '该服务器需要 API 密钥。在下方粘贴你的 LM Studio API Token 以连接。';

  @override
  String get lmStudioAuthHelpHint =>
      '在 LM Studio 中打开 开发者模式 → 服务器设置 → 管理 Token，创建或复制你的 API 密钥。';

  @override
  String get welcomeWizardThemeTitle => '选择主题';

  @override
  String get welcomeWizardAppearanceTitle => '自定义外观';

  @override
  String get welcomeWizardAppearancePreviewMessage => '你好！你的聊天消息会是这个样子。';

  @override
  String get apiTokenOptionalLabel => 'API Token（可选）';

  @override
  String get welcomeWizardExperienceTitle => '你平时怎么用 AI？';

  @override
  String get welcomeWizardExperienceSubtitle => '我们会据此给出推荐，之后随时可以更改。';

  @override
  String get welcomeWizardBeginnerTitle => '初学者';

  @override
  String get welcomeWizardBeginnerSubtitle => '保持简单——更精简的设置，并为你的手机推荐合适的模型。';

  @override
  String get welcomeWizardPowerTitle => '高级用户';

  @override
  String get welcomeWizardPowerSubtitle => '完整设置加更多选择——端侧模型和 LM Studio 等桌面服务器。';

  @override
  String get welcomeWizardSetupTitleBeginner => '选择模型';

  @override
  String get welcomeWizardSetupTitlePower => '选择你的配置';

  @override
  String get welcomeWizardSetupSubtitleBeginner => '点选模型即可下载。也可以通过 Wi‑Fi 连接电脑。';

  @override
  String get welcomeWizardSetupSubtitlePower => '选择模型，或连接桌面服务器。';

  @override
  String get welcomeWizardModelFasterBlurb => '快速回复。非常适合日常聊天。';

  @override
  String get welcomeWizardModelBalancedBlurb => '速度和质量的良好平衡。';

  @override
  String get welcomeWizardModelBestBlurb => '与你设备匹配的最强质量。';

  @override
  String get welcomeWizardNameTitle => 'AI 应该怎么称呼你？';

  @override
  String get welcomeWizardNameSubtitle => '名字或昵称就好，也可以跳过。';

  @override
  String get welcomeWizardNameHint => '例如亚历克斯';

  @override
  String get welcomeWizardFinish => '完成';

  @override
  String get welcomeWizardContinue => '继续';

  @override
  String get welcomeWizardSkip => '跳过';

  @override
  String get welcomeWizardConnectLmStudio => '连接 LM Studio';

  @override
  String get pickColor => '选择颜色';

  @override
  String get hueLabel => '色调';

  @override
  String get saturationLabel => '饱和度';

  @override
  String get lightnessLabel => '亮度';

  @override
  String get alphaLabel => '透明度';

  @override
  String get hexLabel => '十六进制';

  @override
  String get personaModeLabel => '角色模式';

  @override
  String get personaModeSubtitle => '为群聊设置头像、强调色、语音和首选模型';

  @override
  String get avatarLabel => '头像';

  @override
  String get customAvatarSet => '已设置自定义头像';

  @override
  String get noAvatar => '无头像';

  @override
  String get accentColorLabel => '强调色';

  @override
  String get defaultLabel => '默认';

  @override
  String get preferredModelLabel => '首选模型';

  @override
  String get preferredModelAny => '无（不限）';

  @override
  String get personaChooseProviderTitle => '选择提供商';

  @override
  String get personaChooseProviderSubtitle => '已配置的提供商。可在设置中添加更多。';

  @override
  String get personaCloudProvidersSection => '云端提供商';

  @override
  String get personaKokoroVoiceLabel => 'Kokoro 语音';

  @override
  String get personaKokoroVoiceSubtitle => '该角色说话时使用的语音（语音聊天/朗读）';

  @override
  String get personaKokoroVoiceGlobal => '使用全局语音设置';

  @override
  String get personaKokoroVoicePickerTitle => '角色语音';

  @override
  String get personaKokoroSpeedLabel => '语速';

  @override
  String get personaKokoroSpeedGlobal => '使用全局语速';

  @override
  String personaKokoroSpeedValue(String speed) {
    return '${speed}x';
  }

  @override
  String get voiceWhisperModelLabel => 'Whisper 模型';

  @override
  String get voiceWhisperModelTapToChoose => '点按选择模型大小并下载';

  @override
  String get imageGenSeedLabel => '图像生成随机种子';

  @override
  String imageGenSeedFixed(int seed) {
    return '固定随机种子：$seed';
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
      '仅在图像生成提供商为 ComfyUI 时生效。保持“全局”则使用 设置 → 图像生成。';

  @override
  String get personaComfyWorkflowNotComfy => '此设置仅在 ComfyUI 是当前图像提供商时生效。';

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
  String get personaComfyWorkflowJsonIgnored => '选择了已保存的工作流时忽略此项';

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
  String get setSeed => '设置随机种子';

  @override
  String get pickAccentColor => '选择强调色';

  @override
  String get imageGenSeedDialogDescription => '设置固定的随机种子，让该角色始终生成一致的图像。留空则随机。';

  @override
  String get seedValueLabel => '随机种子值';

  @override
  String get seedValueHint => '例如 42（留空 = 随机）';

  @override
  String get setLabel => '设定';

  @override
  String get selectPreferredModelTitle => '选择首选模型';

  @override
  String get branchCreated => '🔀 分支已创建';

  @override
  String get yamlFrontmatter => 'YAML 前置元数据';

  @override
  String get markdownFormat => 'Markdown';

  @override
  String get localNetworkBlocked => '本地网络访问可能被阻止';

  @override
  String get localNetworkFix => '打开 设置 → LM Mini → 本地网络 并开启该权限。';

  @override
  String get openAppSettings => '打开系统设置';

  @override
  String get memorySaved => '记忆已保存';

  @override
  String get proSearch => '专业搜索';

  @override
  String get webSearchLabel => '网络搜索';

  @override
  String get readUrl => '读取 URL';

  @override
  String get code => '代码';

  @override
  String couldNotOpenFile(String error) {
    return '无法打开文件：$error';
  }

  @override
  String get tapOpenExternal => '点按“使用外部应用打开”即可查看此文件';

  @override
  String get proSearchEnabled => '专业搜索已启用';

  @override
  String get proSearchDisabled => '专业搜索已禁用';

  @override
  String get thinkingEnabled => '此对话已开启思考';

  @override
  String get thinkingDisabled => '此对话已关闭思考';

  @override
  String get codeSandbox => '代码沙箱';

  @override
  String get codeSandboxSubtitle => '在安全沙箱中运行 Python 或 JavaScript';

  @override
  String get codeSandboxEnabled => '代码沙箱已启用';

  @override
  String get codeSandboxDisabled => '代码沙箱已禁用';

  @override
  String get searxngNotConfigured => '添加 SearXNG URL 以启用';

  @override
  String get searxngConfiguredOff => '已配置——点按可改用 SearXNG，替代 Pro Search';

  @override
  String get searxngConfigureFirst => '启用前配置 SearXNG URL';

  @override
  String get editSearxng => '编辑 SearXNG';

  @override
  String get toolCallingLabel => '工具调用';

  @override
  String get on => '开';

  @override
  String get off => '关';

  @override
  String get aiCanUseTools => 'AI 可以在此对话中使用工具';

  @override
  String get toolsDisabledChat => '此对话已禁用工具';

  @override
  String get webSearchChat => '网络搜索';

  @override
  String get aiCanSearchWeb => 'AI 可以在此对话中搜索网络';

  @override
  String get webSearchDisabledChat => '此对话已禁用网络搜索';

  @override
  String get disableMemory => '停用记忆';

  @override
  String memoryItemsActive(int count) {
    return '$count 条记忆生效';
  }

  @override
  String get memoryDisabledChat => '此对话已停用记忆，AI 不会看到你保存的条目。';

  @override
  String get lmStudioLocal => 'LM Studio（本地）';

  @override
  String get modelNoLongerAvailable => '之前选择的模型已不可用，请选择新的模型。';

  @override
  String get noModelsForProvider => '未找到该提供商的模型，请检查 API 密钥。';

  @override
  String get noModelsCheckConnection => '未找到模型。请检查 LM Studio 连接。';

  @override
  String get selectModel => '选择模型';

  @override
  String get goToModels => '前往模型列表';

  @override
  String get reviewImagePrompt => '检查图像提示词';

  @override
  String get editImagePromptHint => '编辑图像提示词…';

  @override
  String get generate => '生成';

  @override
  String get imageNotFound => '找不到图片';

  @override
  String get cameraPermissionNeeded => '需要相机权限';

  @override
  String get cameraPermissionExplain => '请允许使用相机来拍照，用于视觉分析。';

  @override
  String get photosPermissionNeeded => '需要照片权限';

  @override
  String get photosPermissionExplain => '请允许访问你的照片，以便进行视觉分析。';

  @override
  String couldNotOpenFilePicker(String error) {
    return '无法打开文件选择器：$error';
  }

  @override
  String get filePickerCouldNotCopy => '无法复制该文件。请先保存到本机（不要用网盘或最近项目），然后再选一次。';

  @override
  String get signInToUseCloudBackup => '登录后使用云备份';

  @override
  String get cloudBackupRequiresAccount => '云备份需要账户，你的加密备份将以你的身份安全存储。';

  @override
  String get arguments => '参数';

  @override
  String get selectLanguage => '选择语言';

  @override
  String get connectionPopupTitle => '选择提供商';

  @override
  String get connectionPopupBody => '连接 LM Studio、选择端侧模型，或在设置中登录云端提供商。';

  @override
  String get connectionPopupDismiss => '稍后';

  @override
  String get connectionPopupGoToSettings => '打开设置';

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
  String get testing => '测试中…';

  @override
  String connectedLatency(int ms) {
    return '已连接 — ${ms}ms';
  }

  @override
  String get notConnected => '未连接';

  @override
  String get scanQrDescription =>
      '在 Mac 上的 LM Mini（与手机共享）或旧版 LM Mini Connect 扫描二维码，即可在任何地方连接你的桌面模型。';

  @override
  String get remotePaired => '远程配对';

  @override
  String lastConnected(String time) {
    return '上次连接：$time';
  }

  @override
  String get reScanQrCode => '重新扫描二维码';

  @override
  String get qrRequiresPro => '二维码扫描需要 LM Mini Pro';

  @override
  String get enterUrlManually => '手动输入网址';

  @override
  String get enterUrlManuallySubtitle => '无法使用相机时，粘贴配对链接';

  @override
  String get relayUrlHint => 'https://relay.lmmini.com/s/…';

  @override
  String get connectWithUrl => '使用 URL 连接';

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
  String get unpairRemote => '解除配对';

  @override
  String get unpairRemoteDescription => '这会删除已保存的远程连接。扫描新的二维码即可重新配对。';

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
  String get setupStep2Title => '与手机共享';

  @override
  String get setupStep2Desc => '在 Mac 上打开 LM Mini Home 的“与手机共享”并开启，即可立即连接到中继。';

  @override
  String get setupStep3Title => '扫描二维码';

  @override
  String get setupStep3Desc => '扫描 Mac 上显示的二维码。搞定！';

  @override
  String minutesAgo(int count) {
    return '$count 分钟前';
  }

  @override
  String hoursAgo(int count) {
    return '$count 小时前';
  }

  @override
  String daysAgo(int count) {
    return '$count 天前';
  }

  @override
  String get selectAll => '选择全部';

  @override
  String get moveToFolder => '移至文件夹';

  @override
  String get select => '选择';

  @override
  String get dismissAction => '忽略';

  @override
  String get createNewFolder => '创建新文件夹';

  @override
  String deleteConversations(int count) {
    return '删除 $count 个对话？此操作无法撤消。';
  }

  @override
  String get averages => '平均值';

  @override
  String get tokensPerChat => 'Token/对话';

  @override
  String get msgsPerChat => '消息/对话';

  @override
  String get tokensPerMsg => 'Token/消息';

  @override
  String get topModel => '最常用模型';

  @override
  String get liveActivityTitle => '实时活动';

  @override
  String get liveActivityTitleAndroid => '后台生成';

  @override
  String get liveActivityDescription => '即使退出或锁定应用，也能继续处理 AI 请求。';

  @override
  String get liveActivityDescriptionAndroid =>
      '离开应用后继续生成——支持设备上模型、LM Studio 和云服务商。会显示一条带进度的静默常驻通知，并在 Android 上保持 HTTP 流不中断。';

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
      '随时随地访问你的 Mac 或 PC 上的模型。在 Mac 上使用 LM Mini → 与手机共享。无需端口转发或 VPN，扫描二维码即可通过加密中继连接。';

  @override
  String get premiumLiveActivity => '实时活动';

  @override
  String get premiumLiveActivityTagline => 'AI 在后台运行';

  @override
  String get premiumLiveActivityDescription =>
      '即使退出应用或锁定手机，也能继续处理 AI 请求。在锁定屏幕和动态岛上实时查看生成进度——不用切回应用，就能看到 Token 不断增加和生成速度。';

  @override
  String get premiumWebSearchTagline => '无需服务器设置';

  @override
  String get premiumWebSearchDescription =>
      '对话中随时搜索网页。由云搜索 API 驱动——无需自建 SearXNG，也不用任何配置。直接提问，模型就能从互联网获取最新的实时信息。';

  @override
  String get premiumCloudBackup => '加密云备份';

  @override
  String get premiumCloudBackupTagline => 'AES-256-GCM 加密';

  @override
  String get premiumCloudBackupDescription =>
      '使用军用级加密把所有对话备份到云端。你的口令不会离开设备——连我们也无法读取你的数据。在任何设备上一键恢复。';

  @override
  String get premiumUrlReader => 'URL 阅读器';

  @override
  String get premiumUrlReaderTagline => '分析任何网页';

  @override
  String get premiumUrlReaderDescription =>
      '粘贴任意 URL，模型会读取整个页面内容。总结文章、分析文档、从表格提取数据——全程无需离开对话。';

  @override
  String get premiumBranching => '对话分支';

  @override
  String get premiumBranchingTagline => '探索替代路径';

  @override
  String get premiumBranchingDescription =>
      '从任意消息处分叉对话，探索各种“假设”场景。比较不同的提示词、尝试不同方案，保留最满意的分支——原始对话不会丢失。';

  @override
  String get premiumMemory => '记忆';

  @override
  String get premiumMemoryTagline => '跨对话记住你';

  @override
  String get premiumMemoryDescription =>
      '保存跨对话保留的事实、偏好和上下文。每次开启新对话，模型都记得你的名字、代码风格、常用语言，以及你教给它的一切。';

  @override
  String get premiumAnalytics => '分析仪表盘';

  @override
  String get premiumAnalyticsTagline => '了解你的使用情况';

  @override
  String get premiumAnalyticsDescription =>
      '跟踪 Token 用量、发送消息数、各模型使用占比和平均响应时间。用精美图表了解你的 AI 使用习惯，优化工作流。';

  @override
  String get premiumCloudApi => '云 API 提供商';

  @override
  String get premiumCloudApiTagline => 'Mistral、Anthropic 等';

  @override
  String get premiumCloudApiDescription =>
      '在本地模型之外接入云端 LLM 提供商。需要顶级性能时可用 Claude、Gemini 和 Mistral——本地与云端无缝切换。';

  @override
  String get premiumExport => '多格式导出与分享';

  @override
  String get premiumExportTagline => 'Obsidian、Apple Notes、Notion 等';

  @override
  String get premiumExportDescription =>
      '将对话导出为格式精美的 Markdown、PDF 或纯文本。直接分享到 Obsidian、Apple Notes、Notion 或任何应用程序。非常适合保存研究和见解。';

  @override
  String get premiumCompactContext => '压缩上下文';

  @override
  String get premiumCompactContextTagline => '上下文满了也能继续聊';

  @override
  String get premiumCompactContextDescription =>
      '滚动淘汰旧消息、裁掉中段，或把长对话压缩成摘要——都由当前加载的模型完成，上下文窗口满了也不会中断对话。';

  @override
  String get premiumParamPresets => '参数预设';

  @override
  String get premiumParamPresetsTagline => '按模型和角色保存生成设置';

  @override
  String get premiumParamPresetsDescription =>
      '可按模型保存采样器和加载设置，也可在角色上选用自定义参数。免费版只使用应用内置的全局默认值。';

  @override
  String get paramPresetSetFor => '参数设置范围';

  @override
  String get paramPresetGlobalTab => '全局';

  @override
  String get paramPresetScopeHelpTitle => '参数如何生效';

  @override
  String get paramPresetScopeHelpIntro => '层级越具体，优先级越高。在某个对话里单独设置的参数仍然排在最上层。';

  @override
  String get paramPresetScopeHelpGlobal => '所有没有专属预设的模型都用这里的默认值，也就是应用自带的设置。';

  @override
  String get paramPresetScopeHelpModel =>
      '在“当前模型”标签页调整参数，只会保存为该模型的预设。点“使用全局参数”即可删除预设，让模型重新跟随全局设置。';

  @override
  String get paramPresetScopeHelpPersonaTitle => '角色';

  @override
  String get paramPresetScopeHelpPersona =>
      '如果角色指定了首选模型，开启“使用自定义参数”后，该角色活跃时会覆盖该模型的预设（或全局设置）。';

  @override
  String get paramPresetSelectedModelTab => '当前模型';

  @override
  String get paramPresetNoModel => '选择一个模型后即可为其保存预设。';

  @override
  String get paramPresetUsingGlobal => '此模型使用全局参数。';

  @override
  String get paramPresetUsingCustom => '此模型有自定义预设。';

  @override
  String get paramPresetUseGlobal => '使用全局参数';

  @override
  String get paramPresetUseGlobalSubtitle => '删除此模型的预设，恢复使用全局参数。';

  @override
  String get paramPresetModelLocked => '模型预设是 Pro 功能。全局参数仍适用于每个模型。';

  @override
  String get personaUseCustomParams => '使用自定义参数';

  @override
  String get personaUseCustomParamsSubtitle => '角色启用时覆盖此模型的参数';

  @override
  String get personaAdjustParams => '调整参数';

  @override
  String get personaAdjustParamsSubtitle => '温度、上下文等生成设置';

  @override
  String get premiumOnDeviceLlm => '设备上 Pro';

  @override
  String get premiumOnDeviceLlmTagline => '更大的目录模型和 Hugging Face 导入';

  @override
  String get premiumOnDeviceLlmDescription =>
      '设备上对话免费使用精选的入门模型。Pro 解锁目录中 3B 参数以上的模型，并支持从 Hugging Face 导入你自己的 GGUF 或 MLX 模型——浏览、挑选量化版本，全程离线运行。';

  @override
  String get premiumHfBrowse => 'Hugging Face 导入';

  @override
  String get premiumHfBrowseTagline => '导入任意 GGUF 模型';

  @override
  String get premiumHfBrowseDescription =>
      '在 Hugging Face 搜索，把 GGUF 模型下载到设备或 LM Studio 服务器，再在 LM Mini 中运行。可按兼容性筛选、查看后台下载进度，突破免费目录的限制——无需 API 密钥。';

  @override
  String get onDeviceProviderLabel => '设备上';

  @override
  String get onDeviceManageModels => '管理设备上模型';

  @override
  String get onDeviceGeneratingHint => '正在设备上生成…';

  @override
  String get onDeviceEngineUnavailable => '设备上的引擎不可用';

  @override
  String get onDeviceOpenBrowser => '打开设备上的模型';

  @override
  String get onDeviceManagedHere => '设备上的模型在专属页面中管理，可在此下载、移除和启用。';

  @override
  String get onDeviceRemoteImageOnly =>
      '已选择设备上 AI——远程访问只用于图像生成和 Kokoro 语音（如已配置）。对话仍在此设备上进行。';

  @override
  String get onDeviceProOnly => '仅限专业版';

  @override
  String get onDeviceInstalled => '已安装';

  @override
  String get onDeviceUseModel => '使用';

  @override
  String get onDeviceRemoveModel => '移除';

  @override
  String get onDeviceDownloadAnyway => '仍要下载';

  @override
  String onDeviceNowUsing(String name) {
    return '正在使用设备上的 $name';
  }

  @override
  String get onDeviceEngineFllamaLabel => 'fllama (GGUF)';

  @override
  String onDeviceEngineSwitched(String engine) {
    return '已切换到 $engine，之前的模型已卸载。';
  }

  @override
  String onDeviceEngineSwitchedCleared(String engine) {
    return '已切换到 $engine。之前的模型与此引擎不兼容，已被取消选择——请在“设备上模型”中重新选择。';
  }

  @override
  String get onDeviceImportedLabel => '已导入';

  @override
  String get onDeviceFreeLabel => '免费';

  @override
  String get onDeviceProLabel => '专业版';

  @override
  String get onDeviceMayCrashLabel => '可能会崩溃';

  @override
  String get onDeviceModelMayCrashTitle => '该模型可能会崩溃';

  @override
  String onDeviceModelMayCrashMessage(
      String name, String runtimeGb, String deviceRamGb) {
    return '$name 运行时大约需要 $runtimeGb GB 内存，而设备可用的应用内存约为 $deviceRamGb GB。仍要加载可能导致应用卡死或崩溃。';
  }

  @override
  String get onDeviceContinueLoading => '继续加载';

  @override
  String get yearly => '年付';

  @override
  String get monthly => '月付';

  @override
  String get lifetime => '终身';

  @override
  String get subscriptionLifetimeBadge => '一次付费';

  @override
  String get subscriptionLifetimeDisclaimer =>
      '一次性购买。只要 LM Mini 仍在提供和维护，你的账号就能使用 Pro 功能。不含第三方 API 费用，部分单独托管的服务可能不在此列——详见条款。';

  @override
  String subscriptionLifetimeUpgradeDisclaimer(String store) {
    return '终身版是单独的一次性购买。当前订阅不会自动取消，已产生的订阅费用也无法退还。购买后请在$store取消订阅。';
  }

  @override
  String get subscriptionUpgradeToLifetime => '升级到终身版';

  @override
  String subscriptionUpgradeToLifetimeSubtitle(String price) {
    return '一次付费 — $price';
  }

  @override
  String get duplicateSubscriptionDialogTitle => '取消你的订阅';

  @override
  String duplicateSubscriptionDialogBody(String store) {
    return '你同时拥有 Lifetime Pro 和有效订阅。终身版不会自动取代订阅，我们也无法退还订阅费用。请在$store取消订阅，避免继续扣费。';
  }

  @override
  String duplicateSubscriptionDialogManage(String store) {
    return '打开$store';
  }

  @override
  String get duplicateSubscriptionDialogDismiss => '知道了';

  @override
  String get duplicateSubscriptionNoManageUrl => '前往设备的订阅设置取消订阅。';

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
      '用于远程访问的端到端加密密钥。必须与 Mac 上 LM Mini Home 中的密钥一致。';

  @override
  String get editEncryptionKey => '编辑加密密钥';

  @override
  String get enterEncryptionKey => '输入加密密钥';

  @override
  String get encryptionKeyUpdated => '加密密钥已更新';

  @override
  String get thankYouSupport => '感谢你的支持！';

  @override
  String get helpingKeepAlive => '有你的支持，LM Mini 得以持续';

  @override
  String get linkSignInMethod => '绑定登录方式，换设备后订阅也不丢。';

  @override
  String get paywallLinkAccountBody =>
      '你使用的是匿名账号。购买前先绑定 Apple 或 Google，Pro 才能跨设备同步，重装后也不会丢失。';

  @override
  String get continueAnonymously => '匿名继续';

  @override
  String signedInViaMethod(String method) {
    return '通过$method登录';
  }

  @override
  String get yourSubscriptionSecured => '你的订阅已受保护';

  @override
  String subscriptionManagedThrough(String store) {
    return '订阅通过$store管理。';
  }

  @override
  String get subscriptionsComingSoon => '订阅即将推出';

  @override
  String get premiumPreview => '高级功能仍在完善中。\n可在下方启用开发者模式先行预览。';

  @override
  String get enableDeveloperPremium => '启用开发者高级版';

  @override
  String get disableDeveloperPremium => '禁用开发者高级版';

  @override
  String get premiumEnabled => '启用高级版（开发覆盖）';

  @override
  String get premiumDisabled => '高级版已禁用';

  @override
  String get welcomeToLmMiniPro => '欢迎使用 LM Mini Pro！';

  @override
  String get connectedRemotely => '远程连接';

  @override
  String get pairedNotActive => '已配对 — 未激活';

  @override
  String get accessLmStudioAnywhere => '从任何地方访问 LM Studio';

  @override
  String get appStore => '应用商店';

  @override
  String get googlePlayStore => 'Google Play 商店';

  @override
  String get starterAttach => '附件';

  @override
  String get starterImages => '图片';

  @override
  String get starterMode => '模式';

  @override
  String get newGroupChat => '新群聊';

  @override
  String get groupChat => '群聊';

  @override
  String get groupChatMultipleModels => '与多个模型对话';

  @override
  String get groupChatParticipants => '参与者';

  @override
  String get groupChatTurnMode => '发言模式';

  @override
  String get groupChatRoundRobin => '轮流';

  @override
  String get groupChatManual => '手动';

  @override
  String get groupChatParallelStreaming => '并行流式';

  @override
  String get groupChatAutoLoadUnload => '自动加载/卸载';

  @override
  String get groupChatStreamAllSimultaneously => '所有参与者同时流式输出';

  @override
  String get groupChatAutoLoadModels => '需要时自动加载模型';

  @override
  String get groupChatAsk => '提问：';

  @override
  String get groupChatTapToReplyNudge => '点选要回复的人';

  @override
  String get groupChatTrialBannerTitle => '群聊 — 7 天免费！';

  @override
  String get groupChatTrialBannerBody =>
      '群聊免费试用 7 天，最多可添加 2 个 AI 角色。升级到 LM Mini Pro 解锁无限参与者和永久使用。';

  @override
  String groupChatTrialDaysLeft(int days) {
    return '试用期还剩 $days 天';
  }

  @override
  String get groupChatTrialExpired => '7 天群聊试用已结束。升级到专业版继续使用。';

  @override
  String get groupChatTrialGetPro => '获取专业版';

  @override
  String get groupChatTrialDismiss => '知道了';

  @override
  String get groupChatBetaTitle => '群聊';

  @override
  String get groupChatBetaSubtitle => '一场对话，多个 AI 大脑。';

  @override
  String get groupChatBetaPremiumNote => '群聊目前处于测试阶段，所有人都能免费体验';

  @override
  String get groupChatBetaBugReport => '发现了 Bug？前往“设置”→“功能请求与支持”反馈，可获得优先帮助。';

  @override
  String get groupChatBetaFreeNote => '你可以免费体验 7 天，最多 2 个角色。升级到专业版解锁无限角色和永久使用。';

  @override
  String get groupChatBetaFeaturePersona => '每个角色都有自己的模型';

  @override
  String get groupChatBetaFeatureSystem => '独立系统提示词，个性各不同';

  @override
  String get groupChatBetaFeatureConvo => '全部在同一个共享对话中';

  @override
  String get groupChatBetaStartFree => '开始免费试用';

  @override
  String get groupChatBetaStartPremium => '尝试群聊';

  @override
  String get groupChatBetaLearnMore => '获取专业版';

  @override
  String get premiumGroupChat => '群聊';

  @override
  String get premiumGroupChatTagline => '多角色对话';

  @override
  String get premiumGroupChatDescription =>
      '在同一个对话里与多个 AI 角色聊天——每个角色都有自己的模型、头像和个性。可自由创建设置，发送消息需要 LM Mini Pro。';

  @override
  String get groupChatProRequiredTitle => '群聊需要专业版';

  @override
  String get groupChatProRequiredBody =>
      '群聊可以免费创建。升级到 LM Mini Pro 即可用多个 AI 角色开始对话、发送消息。';

  @override
  String get groupChatProRequiredUpgrade => '升级到专业版';

  @override
  String get groupChatLockedBanner => '没有 Pro 时群聊为只读。升级后才能发送新消息。';

  @override
  String get premiumArena => 'Arena Pro';

  @override
  String get premiumArenaTagline => '自定义比赛、云端模型和历史记录';

  @override
  String get premiumArenaDescription =>
      '寻找模型免费。Pro 可解锁自定义提示词比赛、竞技场云端模型，以及带图表的私人比赛历史。';

  @override
  String get startLabel => '开始';

  @override
  String groupChatInviteUpTo(int count) {
    return '邀请最多 $count 个 AI 模型一起对话，每个都可以有自己的角色、头像和系统提示词。';
  }

  @override
  String get groupChatPremiumParticipantsNote => 'Premium 允许每个群聊最多 5 名参与者。';

  @override
  String get groupChatUserNameHint => 'AI 将如何称呼你（例如 Alex）';

  @override
  String get groupChatScenarioLabel => '场景/关于你自己（可选）';

  @override
  String get groupChatScenarioHint => '例如“我们是一家科技初创公司的同事。我是一名产品经理，向团队寻求建议。”';

  @override
  String get groupChatTurnModeRoundRobinDescription => '轮流——所有模型依次回答';

  @override
  String get groupChatTurnModeManualDescription => '手动 — 输入 @Name 以选择回复者';

  @override
  String get groupChatReplyToUserOnlyLabel => '只回复你';

  @override
  String get groupChatReplyToUserOnlySubtitle => '每个 AI 都忽略其他 AI——最适合较小的模型';

  @override
  String get groupChatWhosInChat => '谁在聊天？';

  @override
  String get groupChatTapToInvite => '点按下方成员发出邀请';

  @override
  String get groupChatAddPeople => '添加成员';

  @override
  String get groupChatInTheRoom => '房间内';

  @override
  String get groupChatNeedTwo => '至少添加 2 个才能开始';

  @override
  String get groupChatTakeTurnsTitle => '轮流';

  @override
  String get groupChatTakeTurnsSubtitle => '大家按顺序依次回答';

  @override
  String get groupChatTalkMentionedTitle => '被提及时发言';

  @override
  String get groupChatTalkMentionedSubtitle => '如果一个 AI 点名了另一个，它就可以插话';

  @override
  String get groupChatIChooseTitle => '我选择谁发言';

  @override
  String get groupChatIChooseSubtitle => '只有你 @ 提及的人才会回复';

  @override
  String get groupChatHowTheyTalk => '它们的说话方式';

  @override
  String get groupChatAboutYou => '关于你';

  @override
  String get groupChatSceneLabel => '场景（可选）';

  @override
  String get groupChatSceneHint => '例如：我们是同事，正在头脑风暴一个产品创意';

  @override
  String get groupChatAutoLoadTitle => '节省本地模型的内存';

  @override
  String get groupChatAutoLoadSubtitle =>
      '加载下一个模型前先卸载上一个——当成员各自使用不同的 LM Studio、Ollama 或设备上模型时很实用';

  @override
  String get groupChatMoreOptions => '更多选项';

  @override
  String get groupChatHelpTooltip => '群聊的工作原理';

  @override
  String get groupChatHelpTitle => '群聊的工作原理';

  @override
  String get groupChatHelpIntro => '邀请至少两个 AI 成员进入同一场对话，每个成员可以用不同的模型和个性。';

  @override
  String get groupChatHelpTakeTurns => '轮流：每个 AI 按顺序回答你的消息。';

  @override
  String get groupChatHelpMentioned => '被提及时发言：一个 AI 回复后，被点名的 AI 可以接着说。';

  @override
  String get groupChatHelpManual => '我选择谁发言：用 @Name 指定，就只有它回复。';

  @override
  String get groupChatHelpMemory => '节省内存：本地模型先卸载上一个再加载下一个，让内存较小的手机和 PC 也能开群聊。';

  @override
  String get groupChatHelpProvider => '随时点按房间里的成员，更换其提供商和模型。';

  @override
  String get groupChatStartProGate => '需要专业版才能启动';

  @override
  String get groupChatFixBeforeStart => '开始前请先修正标红的成员。';

  @override
  String get groupChatEditPerson => '编辑成员';

  @override
  String get groupChatProviderAndModel => '提供商和模型';

  @override
  String get groupChatChooseProviderModel => '选择提供商和模型';

  @override
  String get groupChatParallelEasy => '同时回复';

  @override
  String get groupChatParallelEasySubtitle => '需要多个 AI 一起回答时，让它们同时流式输出';

  @override
  String get noModelsAvailableConnectLmStudio => '没有可用模型。请先连接 LM Studio。';

  @override
  String get addModelLabel => '添加模型';

  @override
  String modelNumber(int number) {
    return '模型 $number';
  }

  @override
  String groupChatParticipantInfo(String name, String model) {
    return '$name\n模型：$model';
  }

  @override
  String get customPromptSet => '自定义提示词设置';

  @override
  String get removeLabel => '移除';

  @override
  String get displayNameLabel => '显示名称';

  @override
  String get displayNameHint => '例如教授、程序员、艺术家';

  @override
  String get customRequestHeaders => '自定义请求标头';

  @override
  String get customRequestHeadersSubtitle => '可选的标头，会附加到每个 LM Studio 请求上';

  @override
  String get customRequestHeadersHelp =>
      '适用于需要额外标头的反向代理或身份验证网关（如 Cloudflare Access 服务 Token、自定义标头名下的内部 Token 等）。这些标头会随每个请求发送到你的 LM Studio 服务器。';

  @override
  String get cloudflareAccessSection => 'Cloudflare Access（服务 Token）';

  @override
  String get cloudflareAccessHelp =>
      '如果你的 LM Studio 处于 Cloudflare Access 策略之后，在此粘贴服务 Token 的 Client ID 和 Secret。它们会作为 CF-Access-Client-Id 和 CF-Access-Client-Secret 随每个请求发送，应用无需浏览器 SSO 登录即可完成身份验证。';

  @override
  String get cfAccessClientIdLabel => 'CF-Access-Client-Id';

  @override
  String get cfAccessClientSecretLabel => 'CF-Access-Client-Secret';

  @override
  String get addHeader => '添加标头';

  @override
  String get removeHeader => '删除标头';

  @override
  String get headerNameLabel => '标头名称';

  @override
  String get headerValueLabel => '标头值';

  @override
  String headersConfigured(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已配置 $count 个标头',
      one: '已配置 1 个标头',
    );
    return '$_temp0';
  }

  @override
  String get noCustomHeaders => '没有自定义标头';

  @override
  String get comfyUiUseNegativePromptTitle => '使用负面提示词';

  @override
  String get comfyUiUseNegativePromptSubtitle =>
      'ComfyUI 默认关闭。关闭时不会向工作流发送负面提示词。';

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
    return '删除 $count 条记忆？';
  }

  @override
  String get deleteMemoriesConfirm => '这些记忆将被永久删除。';

  @override
  String get moveToCategory => '移至类别';

  @override
  String nSelected(int count) {
    return '已选择 $count 项';
  }

  @override
  String movedToCategory(String category) {
    return '移至$category';
  }

  @override
  String get moveCategoryTooltip => '移动类别';

  @override
  String get memoryScreenSubtitle => 'AI 在各对话中记住的关于你的信息。';

  @override
  String get rememberMe => '记住我';

  @override
  String get rememberMeSubtitle => '在以后的对话中使用保存的笔记';

  @override
  String get memoryPerPersona => '私密笔记各自独立';

  @override
  String get memoryPerPersonaSubtitle => '标记为私密的笔记只保留在对应角色下。角色笔记始终相互独立。';

  @override
  String get memoryOnDeviceExtraction => '在设备上提取记忆';

  @override
  String get memoryOnDeviceExtractionSubtitle => '让本地模型也来提取信息，会额外耗电。';

  @override
  String get memoryScopeGlobal => '所有人';

  @override
  String get memoryScopeGlobalSubtitle => '在所有对话中可用';

  @override
  String get memoryScopePrivate => '仅此角色可见';

  @override
  String get memoryScopePrivateSubtitle => '只有这个角色能看到的个人信息。它看不到你的共享记忆';

  @override
  String get memoryScopeLore => '角色设定';

  @override
  String get memoryScopeLoreSubtitle => '这个角色的扮演设定，不会被视为关于你的信息。它看不到你的共享记忆';

  @override
  String get memoryVisibility => '可见范围';

  @override
  String get memoryChangeVisibility => '更改可见范围';

  @override
  String get memoryScopeFilterAll => '全部';

  @override
  String get memoryOrphaned => '已失效';

  @override
  String get memoryOrphanedHint => '这些笔记所属的角色已不存在，任何对话都看不到它们。修复后即可恢复。';

  @override
  String get memoryMakeGlobal => '设为所有人可见';

  @override
  String get memorySearchHint => '搜索笔记';

  @override
  String memoryNoSearchResults(String query) {
    return '没有匹配“$query”的笔记';
  }

  @override
  String get memoryPickPersona => '选择一个角色';

  @override
  String memoryMovedToScope(String scope) {
    return '已移至 $scope';
  }

  @override
  String memoryCountForPersona(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条记忆',
      one: '1 条记忆',
      zero: '没有记忆',
    );
    return '$_temp0';
  }

  @override
  String get personaMemoryWriteScope => '将新记忆保存为';

  @override
  String get personaMemoryWriteScopeSubtitle => '在此角色对话中学到的信息归入哪里';

  @override
  String get memoryBrowseSection => '浏览';

  @override
  String get memoryMultiSelectTip => '提示：长按笔记可多选。';

  @override
  String get memoryEmptyFilteredHint => '添加一条笔记，或选择其他分类。';

  @override
  String get memoryEmptyHint => '记下关于你自己的几点信息——姓名、偏好、项目，对话会更贴心。';

  @override
  String get memoryShareWith => '分享给';

  @override
  String get memoryEveryone => '所有人';

  @override
  String get memoryEveryoneSubtitle => '在每个聊天中都可用';

  @override
  String get memoryNoPersonasHint => '还没有角色。前往“设置”→“角色”创建一个。';

  @override
  String get memoryNewNote => '新笔记';

  @override
  String get memoryNoteHint => '例如：我偏好简短的回答，住在柏林';

  @override
  String get memoryEditNote => '编辑备注';

  @override
  String monthsAgo(int count) {
    return '$count 个月前';
  }

  @override
  String get moreTooltip => '更多';

  @override
  String get closeSearch => '关闭搜索';

  @override
  String get moveTooltip => '移动';

  @override
  String get chatsTab => '对话';

  @override
  String get groupsTab => '群聊';

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
  String get newPersonaShort => '新建';

  @override
  String get downloadOnDeviceModelTitle => '下载设备上的模型';

  @override
  String get downloadOnDeviceModelBody =>
      '下载模型即可脱离电脑聊天，也可以连接 LM Studio / Ollama。';

  @override
  String get browseModels => '浏览模型';

  @override
  String get waitingForMac => '等待 Mac';

  @override
  String get waitingForMacBody =>
      '用 USB 线把 iPhone 连到 Mac，然后在 Mac 上打开 LM Mini 并启用“与手机共享”（USB 桥接）。';

  @override
  String get arenaMode => '竞技场模式';

  @override
  String get voiceWhisperSizeInfoTitle => '模型越大，听得越准';

  @override
  String get voiceWhisperSizeInfoBody =>
      '更大的听写模型通常更准确，尤其是带口音或有背景噪音时。它们也更占存储，加载可能稍慢。';

  @override
  String get voiceRemoveListeningModelTitle => '删除监听模型？';

  @override
  String get voiceRemoveListeningModelBody =>
      '这会释放存储空间。但语音通话和麦克风要离线听写时，还需要用到这个模型。';

  @override
  String get voiceTtsOnDeviceNeural => '已下载的语音';

  @override
  String get voiceTtsPcVoice => '电脑语音';

  @override
  String get voiceTtsSystemVoice => '系统语音';

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
  String get voiceSettingsIntro => '回复如何朗读，以及你的语音如何被识别。';

  @override
  String get voiceSectionReady => '准备好';

  @override
  String get voiceSectionSpeaking => '朗读中';

  @override
  String get voiceSectionListening => '聆听中';

  @override
  String get voiceSectionConversation => '对话';

  @override
  String get voiceStatusSpeaking => '朗读中';

  @override
  String get voiceStatusListening => '聆听中';

  @override
  String get voiceHowISpeak => '我如何说话';

  @override
  String get voiceImportPack => '导入语音包';

  @override
  String get voiceImportPackSubtitle => '粘贴语音包的 GitHub URL';

  @override
  String get voiceHowIHearYou => '我怎么听你说话';

  @override
  String get voiceHowIHearYouSubtitle => '选择你的语音如何转成文字。';

  @override
  String get voiceListeningModel => '听写模型';

  @override
  String get voiceAboutModelSizes => '关于模型大小';

  @override
  String get voicePauseBeforeSend => '发送前暂停';

  @override
  String get voicePauseBeforeSendSubtitle => '停止说话后要等多久';

  @override
  String get voiceListeningLimit => '听写时长上限';

  @override
  String get voiceListeningLimitSubtitle => '麦克风重启前可连续听写的最长时间';

  @override
  String get voiceQuickTip => '快速提示';

  @override
  String get voiceQuickTipBody => '想要更自然的声音，请在语音包里下载一种语言。系统语音可以马上使用。';

  @override
  String get voiceTestSampleHint => '用当前设置试听一段短样例';

  @override
  String get voiceTestNoPackReady => '先在语音包中下载一种语言，再试“测试语音”。';

  @override
  String get voiceChooseListeningModel => '点按选择听写模型';

  @override
  String get voiceModelReady => '准备好';

  @override
  String get voiceNeedsDownload => '需要下载';

  @override
  String get voiceDownloaded => '已下载';

  @override
  String get voiceDownloadFailed => '下载失败';

  @override
  String get voiceFinishingSetup => '正在完成设置…';

  @override
  String get voiceDownloadingListeningModel => '正在下载听写模型…';

  @override
  String get voiceDownloadingVoice => '正在下载语音…';

  @override
  String get voiceStartingDownload => '开始下载…';

  @override
  String get voiceReady => '语音就绪';

  @override
  String get voiceWarmingUp => '正在预热…';

  @override
  String get voiceReadyToSpeak => '准备朗读';

  @override
  String get voiceDownloadOnDevice => '下载设备上的语音';

  @override
  String get voiceDownloadFailedRetry => '下载失败——点按重试';

  @override
  String get voiceSpokenReplyLanguage => '回复朗读语言';

  @override
  String get voiceSpokenReplyLanguageSubtitle => '助手朗读回复时使用的语言。';

  @override
  String get voiceRecognitionLanguage => '识别语言';

  @override
  String get voiceRecognitionLanguageSubtitle => '用于语音输入和语音通话——可以与朗读回复的语言不同。';

  @override
  String get voiceEngineTitle => '朗读语音';

  @override
  String get voiceEngineSubtitle => '选择朗读使用的声音来源。';

  @override
  String get voiceChooseAVoice => '选择声音';

  @override
  String get voiceChooseAVoiceSubtitle => '适合试听的设备端语音名称。';

  @override
  String get voiceUseSystemDefault => '使用系统默认语音';

  @override
  String get welcomeWizardTitleGetStarted => '开始使用';

  @override
  String get welcomeWizardTitleYourSetup => '你的设置';

  @override
  String get welcomeWizardTitleLookAndFeel => '外观';

  @override
  String get welcomeWizardTitleAlmostDone => '快完成了';

  @override
  String get welcomeWizardTitleSetup => '设置';

  @override
  String get welcomeWizardLmStudioSubtitle => '在 Mac 或 PC 上运行模型';

  @override
  String get welcomeWizardOllamaSubtitle => '常用的本地服务器';

  @override
  String get welcomeWizardOmlxSubtitle => 'Apple Silicon 桌面服务器';

  @override
  String get welcomeWizardJanSubtitle => '来自 JAN AI 应用的本地模型';

  @override
  String get welcomeWizardUnslothSubtitle => '电脑上的 Unsloth Desktop';

  @override
  String get welcomeWizardThemeSubtitle => '选择你喜欢的外观，随时可以更换。';

  @override
  String get welcomeWizardModelReady => '准备好';

  @override
  String get welcomeWizardConnected => '已连接';

  @override
  String get welcomeWizardServerFound => '已找到服务器';

  @override
  String get welcomeWizardRequiresApiKey => '需要 API 密钥';

  @override
  String welcomeWizardModelsFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '找到 $count 个模型',
      one: '找到 1 个模型',
    );
    return '$_temp0';
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
  String get browseOnDeviceModels => '浏览设备上的模型';

  @override
  String get homeDownloadModel => '下载模型';

  @override
  String get usbMode => 'USB 模式';

  @override
  String get usbModeHowItWorks => 'USB 模式的工作原理';

  @override
  String get switchToUsbTitle => '从远程切换到 USB？';

  @override
  String get switchLabel => '切换';

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
  String get memoryPersonaFallback => '角色';

  @override
  String get voicePickSystemVoiceSubtitle => '选择内置语音进行语音回复。';

  @override
  String get chooseFromGallery => '从相册中选择';

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
  String get personaAndModel => '角色与模型';

  @override
  String get chatOptions => '聊天选项';

  @override
  String get chatTab => '聊天';

  @override
  String get voiceTab => '语音';

  @override
  String get craftingPersona => '正在生成角色…';

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
  String get newsBriefing => '新闻简报';

  @override
  String get refreshNow => '立即刷新';

  @override
  String get noBriefingYet => '还没有简报';

  @override
  String get newsSetPromptFirst => '请先在小部件设置中设置新闻小部件的提示词。';

  @override
  String get newsRefreshed => '新闻已刷新。';

  @override
  String newsRefreshFailed(String error) {
    return '刷新失败：$error';
  }

  @override
  String get themesTitle => '主题';

  @override
  String get createLabel => '创建';

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
  String get getLabel => '获取';

  @override
  String get bestForYou => '为你推荐';

  @override
  String get loadingLabel => '加载中';

  @override
  String get loadedLabel => '已加载';

  @override
  String get notLoadedLabel => '未加载';

  @override
  String get reasoningLabel => '思考';

  @override
  String get imagesLabel => '图片';

  @override
  String get detailsTooltip => '详情';

  @override
  String get transcribeAudio => '转录音频';

  @override
  String get transcribeAudioSubtitle => '上传音频，就转录内容向 AI 提问';

  @override
  String get trimSection => '裁剪片段';

  @override
  String get includeTimestamps => '包括时间戳';

  @override
  String get phrasesLabel => '短语';

  @override
  String get wordsLabel => '单词';

  @override
  String get transcriptionLanguage => '转录语言';

  @override
  String get searchLanguages => '搜索语言…';

  @override
  String get transcribe => '转录';

  @override
  String get shareTranscript => '分享转录文本';

  @override
  String get transcriptionContextLargeToast =>
      '这些转录文本可能超出模型的上下文长度。如果回答不完整，可以从更早的消息分支。';

  @override
  String get transcriptionSubtitlesOn => '字幕开启';

  @override
  String get transcriptionSubtitlesOff => '字幕关闭';

  @override
  String get transcriptionFullClip => '完整剪辑';

  @override
  String get transcriptionJobRunning => '正在转录…';

  @override
  String get transcriptionJobDone => '已转录';

  @override
  String get transcriptionJobFailed => '转录失败';

  @override
  String get branchFromHere => '从这里分支';

  @override
  String get memoryUpdates => '记忆更新';

  @override
  String get promptWriteEmail => '写一封电子邮件';

  @override
  String get promptWriteEmailBody => '帮我写一封清晰、友好的邮件给';

  @override
  String get promptGiveIdeas => '帮我想点子';

  @override
  String get promptGiveIdeasBody => '和我一起头脑风暴：';

  @override
  String get promptExplainSimply => '简单解释一下';

  @override
  String get promptExplainSimplyBody => '用简单的话解释一下：';

  @override
  String get promptFixWriting => '帮我润色文稿';

  @override
  String get promptFixWritingBody => '帮我提升这段文字的清晰度和语气：\n\n';

  @override
  String get promptHelpStudy => '帮我学习';

  @override
  String get promptHelpStudyBody => '帮我学习这个主题：';

  @override
  String get promptPlanTrip => '计划一次旅行';

  @override
  String get promptPlanTripBody => '帮我规划一次旅行：';

  @override
  String get promptSummarize => '总结一下这个';

  @override
  String get promptSummarizeBody => '总结清楚：';

  @override
  String get promptChecklist => '列个清单';

  @override
  String get promptChecklistBody => '列一份实用的清单：';

  @override
  String get promptFunFact => '告诉我一个有趣的事实';

  @override
  String get promptFunFactBody => '告诉我一个有趣的事实：';

  @override
  String get promptQuizMe => '考考我';

  @override
  String get promptQuizMeBody => '就以下内容考考我：';

  @override
  String get promptRoleplay => '来一场角色扮演';

  @override
  String get promptRoleplayBody => '我们来角色扮演吧。你是';

  @override
  String get promptCodeHelp => '代码帮助';

  @override
  String get promptCodeHelpBody => '帮我解决这个代码问题：';

  @override
  String get promptDraftReply => '起草回复';

  @override
  String get promptDraftReplyBody => '帮我礼貌地回复以下内容：\n\n';

  @override
  String get promptPracticeInterview => '练习面试';

  @override
  String get promptPracticeInterviewBody => '针对以下内容练习面试问题：';

  @override
  String get promptMealIdeas => '餐食建议';

  @override
  String get promptMealIdeasBody => '根据以下内容给我餐食建议：';

  @override
  String get promptWorkoutPlan => '锻炼计划';

  @override
  String get promptWorkoutPlanBody => '制定一份简单的锻炼计划：';

  @override
  String get promptTranslateCasually => '口语化翻译';

  @override
  String get promptTranslateCasuallyBody => '把下面这段翻成口语：\n\n';

  @override
  String get promptNameIdeas => '命名创意';

  @override
  String get promptNameIdeasBody => '为以下内容想一些名字：';

  @override
  String get promptProsCons => '优点和缺点';

  @override
  String get promptProsConsBody => '列出以下内容的优缺点：';

  @override
  String get promptRewriteShorter => '改短一点';

  @override
  String get promptRewriteShorterBody => '帮我改得更短更清晰：\n\n';

  @override
  String get promptTeachVocab => '教我词汇';

  @override
  String get promptTeachVocabBody => '教我以下主题的实用词汇：';

  @override
  String get promptStoryTime => '故事时间';

  @override
  String get promptStoryTimeBody => '围绕以下主题讲一个短故事：';

  @override
  String get promptDebugWithMe => '和我一起调试';

  @override
  String get promptDebugWithMeBody => '帮我调试一下：';

  @override
  String get promptDailyMotivation => '每日动力';

  @override
  String get promptDailyMotivationBody => '给我一点关于以下话题的简短鼓励：';

  @override
  String get promptPlayDnd => '玩 D&D';

  @override
  String get promptPlayDndBody => '让我们来玩一段简短的 D&D 冒险吧。我是';

  @override
  String get promptWordChain => '词语接龙';

  @override
  String get promptWordChainBody => '我们来玩词语接龙，从这个词开始：';

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
  String get promptEscapeRoomBody => '来玩一个简短的文字密室逃脱。';

  @override
  String get promptTriviaBattle => '问答大战';

  @override
  String get promptTriviaBattleBody => '用以下主题的冷知识考考我：';

  @override
  String get promptStoryRpg => '故事角色扮演游戏';

  @override
  String get promptStoryRpgBody => '开始一段短篇故事 RPG，我的角色是';

  @override
  String get promptGuessNumber => '猜数字';

  @override
  String get promptGuessNumberBody => '我们来玩猜数字吧。想一个 1 到 100 之间的数字。';

  @override
  String get promptTwoTruths => '两真一假';

  @override
  String get promptTwoTruthsBody => '我们来玩两真一假，你先说。';

  @override
  String get promptReadMyFile => '阅读我的文件';

  @override
  String get promptWhatIsImage => '这是什么图片';

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
  String get chooseFaceForBubbles => '选择气泡头像';

  @override
  String get moveMemories => '移动记忆';

  @override
  String get deletePersonaAndMemories => '删除角色+记忆';

  @override
  String get moveMemoriesTo => '将记忆移至…';

  @override
  String get globalSharedMemories => '全局（与所有角色共享）';

  @override
  String personaMemoriesAssignedHint(int count, String name) {
    return '$count 条记忆属于“$name”。\n请选择如何处理：';
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
      '把 LM Mini Home 上的聊天和文件夹传到这台手机，之后通过加密中继保持同步。';

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
  String get homeSyncSettingsSubtitle => '在这台手机和 Mac 之间同步聊天和文件夹';

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
  String get reportToSupport => '发送给客服';

  @override
  String get localhostConnectionHelp =>
      '无法连接到 localhost。在手机上，localhost 指的是这台设备，不是电脑。请在设置中改用电脑的 IP 地址（例如 http://192.168.1.10:1234），并让两台设备连接同一个 Wi-Fi。';

  @override
  String get lmStudioPcNotAllowingTitle => '电脑未允许连接';

  @override
  String get lmStudioPcNotAllowingBody =>
      '在电脑上的 LM Studio 中打开 Developer → Server Settings，开启 Serve on Local Network。';

  @override
  String get lmStudioHostDownTitle => '无法连到电脑';

  @override
  String get lmStudioHostDownStep1 => '请确认电脑已开机，没有休眠或关机。';

  @override
  String get lmStudioHostDownStep2 =>
      '在 LM Studio 中打开 Developer → Server Settings，开启 Serve on Local Network。';

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
    return '电脑上没有“$model”。请到模型选择里换一个。';
  }

  @override
  String get outputTokensExhaustedTitle => '模型的输出 Token 已用尽';

  @override
  String get outputTokensExhaustedBody =>
      '剩余输出 Token 不足，无法生成回复。请调高最大 Token 后重试。';

  @override
  String get thinkingBudgetRetryTitle => '思考占满了输出上限';

  @override
  String get thinkingBudgetRetryBody =>
      '高强度思考占满了输出上限，这条回复已改用低强度思考。调高最大 Token 即可保留高强度思考。';

  @override
  String get adjustMaxTokens => '调整最大 Token';

  @override
  String get ggmlSchedulerCrashBody =>
      '模型服务器崩溃了（llama.cpp 调度器）。这不是 Mini 的问题。请调低上下文长度和最大 Token——过大的数值（例如 128k 上下文）经常导致这种情况。';

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
      'Mini 已发送这条聊天，但它从未到达 LM Studio。如果你在 LM Studio 前面用了代理、隧道或额外的 URL，请先去掉——或让 Mini 直连 LM Studio（电脑的 IP、USB 或 Connect）。';

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
  String get sharedHostUpdateSkip => '保持不变';

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
  String get supportUnavailable => '暂时无法联系客服，请联网后再试。';

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
    return '$duration 后再次要求验证';
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
  String get spriteGenerateSeed => '随机种子';

  @override
  String get spriteGenerateSeedHelp => '使用相同的随机种子，可让角色在各表情中保持一致。';

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

  @override
  String get remoteAccessSwitchTitle => '使用远程访问';

  @override
  String get remoteAccessSwitchOnSubtitle => '开启：随时随地连接你的电脑。';

  @override
  String get remoteAccessSwitchOffSubtitle => '关闭：使用家庭网络中的服务器。配对会保留。';

  @override
  String get remoteAccessSwitchConnecting => '正在连接你的电脑…';

  @override
  String get remoteAccessUnreachable => '远程访问已开启，但电脑没有响应。请确认电脑处于唤醒状态并已开启共享。';

  @override
  String get remoteAccessTurnOnFailed => '无法开启远程访问，请重试。';

  @override
  String get remoteAccessTurnOff => '关闭远程访问';

  @override
  String get remoteAccessTurnOffFailed => '无法关闭远程访问，请重试。';

  @override
  String get appleIntelligenceBadge => '设备内置';

  @override
  String get appleIntelligenceSubtitle => '无需下载 · 私密 · 可离线使用';

  @override
  String get appleIntelligenceUse => '使用';

  @override
  String get appleIntelligenceInUse => '使用中';

  @override
  String get appleIntelligenceTurnOn => '在“设置”中打开 Apple Intelligence 即可使用';

  @override
  String get appleIntelligenceGettingReady => 'Apple Intelligence 仍在准备中';

  @override
  String get appleIntelligenceNowUsing => '现在与 Apple Intelligence 聊天';

  @override
  String get onboardingOrDownloadModel => '或下载一个模型';

  @override
  String get homeRunOnboarding => '运行引导流程';

  @override
  String get onboardingDownloadModelTitle => '下载模型';

  @override
  String get onboardingDownloadModelSubtitle => '在本设备运行 · 私密 · 可离线';

  @override
  String get onboardingConnectComputerTitle => '连接你的电脑';

  @override
  String get onboardingConnectComputerSubtitle => 'LM Studio、Ollama、Unsloth 等';

  @override
  String onboardingServersFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '在你的 Wi-Fi 上找到 $count 台服务器',
    );
    return '$_temp0';
  }

  @override
  String onboardingModelReady(String name) {
    return '$name 已就绪';
  }

  @override
  String onboardingModelDownloading(String name, int percent) {
    return '正在下载 $name · $percent%';
  }

  @override
  String get onboardingChatStyleTitle => '聊天样式';

  @override
  String get onboardingChatStyleFullWidth => '全宽';

  @override
  String get onboardingChatStyleFullWidthHint => '回复占满整个屏幕';

  @override
  String get onboardingChatStyleBubbles => '气泡';

  @override
  String get onboardingChatStyleBubblesHint => '像发短信一样';

  @override
  String get firstChatNameQuestion => '你好！我该怎么称呼你？';

  @override
  String get firstChatNameHint => '你的名字或昵称';

  @override
  String get firstChatNameSave => '保存';

  @override
  String get firstChatNameSkip => '以后再说';

  @override
  String firstChatNameSaved(String name) {
    return '很高兴认识你，$name！我会记住的。';
  }

  @override
  String get firstChatNameMemoryChip => '已保存到记忆';

  @override
  String get paywallHeadline => '解锁 LM Mini Pro';

  @override
  String get paywallSubtitle => '网页搜索、云端模型、记忆、远程访问等。';

  @override
  String paywallFeatureIsPro(String feature) {
    return '$feature 是 Pro 功能';
  }

  @override
  String get paywallAlsoIncluded => 'Pro 还包括：';

  @override
  String paywallMoreFeatures(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '还有 $count 项 Pro 功能',
    );
    return '$_temp0';
  }

  @override
  String get paywallShowLess => '收起';

  @override
  String get paywallGetPro => '获取 Pro';

  @override
  String paywallPerMonth(String price) {
    return '$price/月';
  }

  @override
  String aiModelsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个 AI 模型',
    );
    return '$_temp0';
  }

  @override
  String modelFamilyOnDevice(int count) {
    return '本设备上 $count 个';
  }

  @override
  String get modelRecommended => '最佳质量';

  @override
  String get olderModelsTitle => '旧模型';

  @override
  String get olderModelsSubtitle => '更新前已下载';

  @override
  String get lockedSearchChip => '搜索';

  @override
  String get lockedCodeChip => '代码';

  @override
  String get premiumCodeSandboxTagline => '用真实代码得出精确答案';

  @override
  String get teaserSearchTitle => '让模型上网搜索';

  @override
  String get teaserSearchPoint1 => '模型为你查找实时信息：新闻、价格、天气、体育。';

  @override
  String get teaserSearchPoint2 => '只发送搜索词，绝不发送你的聊天内容。';

  @override
  String get teaserSearchPoint3 => '无需设置：不用 API 密钥或搜索服务器。答案附带来源。';

  @override
  String get teaserSearchDemoQuery => '今天东京天气？';

  @override
  String get teaserSearchDemoResult1 => 'AccuWeather · 东京预报';

  @override
  String get teaserSearchDemoResult2 => 'timeanddate.com · 东京今天';

  @override
  String get teaserSearchDemoResult3 => '日本气象厅';

  @override
  String get teaserSandboxTitle => '让模型运行代码';

  @override
  String get teaserSandboxPoint1 => '模型编写并运行 Python 或 JavaScript，给出精确答案。';

  @override
  String get teaserSandboxPoint2 => '适合数学、数据、单位换算和自我检查。';

  @override
  String get teaserSandboxPoint3 => '代码在隔离的沙盒中运行，绝不在你的设备上运行。';

  @override
  String get teaserSandboxDemoSafe => '沙盒';

  @override
  String get teaserSandboxDemoExact => '精确';

  @override
  String get teaserExportTitle => '把聊天保存到你的笔记里';

  @override
  String get teaserExportPoint1 => '将任意聊天以 Markdown 直接导出到 Obsidian 库。';

  @override
  String get teaserExportPoint2 => '也可保存为 PDF、文本或 JSON，或分享到任意应用。';

  @override
  String get teaserExportPoint3 => '思考过程、代码和图片都会一并保留，格式整齐。';

  @override
  String get teaserExportDemoFiles => '文件';

  @override
  String get teaserGroupTitle => '同时与多个 AI 聊天';

  @override
  String get teaserGroupPoint1 => '把多个角色和模型加入同一个聊天，让它们轮流回答。';

  @override
  String get teaserGroupPoint2 => '混合使用模型：手机本地模型、LM Studio 或云端模型。';

  @override
  String get teaserGroupPoint3 => '适合听取不同意见、辩论、角色扮演和头脑风暴。';

  @override
  String get teaserGroupDemoQuestion => '周末去哪个城市最好？';

  @override
  String get teaserGroupDemoReply1 => '里斯本：阳光充足，适合步行，美食很多。';

  @override
  String get teaserGroupDemoReply2 => '我选京都，寺庙和庭园很美。';

  @override
  String get teaserGroupDemoReply3 => '都不错。秋天里斯本更便宜。';

  @override
  String get teaserGroupDemoTag => '3 个 AI，一个聊天';

  @override
  String get newPersonaLabel => '新角色';

  @override
  String get fabChatLabel => '聊天';

  @override
  String get fabGroupLabel => '群聊';

  @override
  String get groupAutonomousPaused => '自动回复已暂停。发送消息或点按名字以继续。';

  @override
  String get teaserRemoteTitle => '随时随地使用电脑上的 AI';

  @override
  String get teaserRemotePoint1 => '通过移动数据或任意 Wi‑Fi，与 LM Studio、Ollama 等服务器聊天。';

  @override
  String get teaserRemotePoint2 => '连接已加密，只有已配对的手机才能接入。同一 Wi‑Fi 下的其他人无法读取。';

  @override
  String get teaserRemotePoint3 => '中继只转发消息，不会保存。在 LM Mini Connect 中扫码配对一次即可。';

  @override
  String get teaserRemoteDemoPhone => '手机';

  @override
  String get teaserRemoteDemoRelay => '安全中继';

  @override
  String get teaserRemoteDemoTag => '离家也能用';

  @override
  String get teaserLiveTitle => '离开应用，回复也不停';

  @override
  String get teaserLivePoint1 => '切换应用或锁屏，回复仍会继续生成。';

  @override
  String get teaserLivePoint2 => '在锁屏和灵动岛上查看进度。';

  @override
  String get teaserLivePoint3 => '回复完成时立即提醒你。';

  @override
  String get teaserLiveDemoWorking => 'LM Mini 正在写回复…';

  @override
  String get teaserLiveDemoDone => '回复已完成';

  @override
  String get teaserCompactTitle => '再也不会超出上下文';

  @override
  String get teaserCompactPoint1 => '聊天太长时，“压缩”会总结较早的内容。';

  @override
  String get teaserCompactPoint2 => '在同一个聊天中继续，不会丢失上下文。';

  @override
  String get teaserCompactPoint3 => '轻点一下，占用就会降下来。';

  @override
  String get teaserCompactDemoSummary => '早前聊天摘要：你的旅行计划、预算和日期。';

  @override
  String get teaserRemoteDemoServer => '家庭服务器';

  @override
  String get teaserRemoteDemoQuestion => '总结我的笔记';

  @override
  String get teaserRemoteDemoAnswer => '来自家中';

  @override
  String get teaserRemoteDemoBlocked => '已拦截';

  @override
  String get teaserRemoteDemoEncrypted => '已加密';

  @override
  String get teaserRemoteDemoPaired => '仅限你的手机';

  @override
  String get teaserRemoteDemoNotStored => '不保存';

  @override
  String get teaserLiveDemoIsland => '回复中';

  @override
  String get teaserLockTitle => '保护你的聊天隐私';

  @override
  String teaserLockPoint1(String method) {
    return '离开时 LM Mini 自动锁定，用$method或 PIN 解锁。';
  }

  @override
  String get teaserLockPoint2 => '别人拿起你的手机，只会看到锁，而不是你的聊天。';

  @override
  String get teaserLockPoint3 => '选择多久后重新锁定：立即或几分钟后。';

  @override
  String get teaserLockDemoUnlocked => '已解锁';

  @override
  String get teaserLockDemoFingerprint => '指纹';

  @override
  String appLockSubtitleBiometric(String method) {
    return '关闭应用后需要$method或 PIN';
  }

  @override
  String get biometricFaceId => '面容 ID';

  @override
  String get biometricTouchId => '触控 ID';

  @override
  String get biometricFingerprint => '指纹';

  @override
  String get biometricFaceUnlock => '面容解锁';

  @override
  String get teaserBranchTitle => '换条路试试，原来的也不会丢';

  @override
  String get teaserBranchPoint1 => '从任意消息创建分支，探索不同的问题或回答。';

  @override
  String get teaserBranchPoint2 => '原始对话保持原样。';

  @override
  String get teaserBranchPoint3 => '随时在分支间切换比较。';

  @override
  String get teaserBranchDemoQuestion => '规划一次三日游';

  @override
  String get teaserBranchDemoA => '分支 A';

  @override
  String get teaserBranchDemoB => '分支 B';

  @override
  String get teaserBranchDemoReplyA => '里斯本海滩游';

  @override
  String get teaserBranchDemoReplyB => '阿尔卑斯徒步';

  @override
  String get teaserStatsTitle => '看看模型的真实表现';

  @override
  String get teaserStatsPoint1 => '每个模型的速度、首个 Token 时间和 Token 数量。';

  @override
  String get teaserStatsPoint2 => '一眼找出手机或电脑上最快的模型。';

  @override
  String get teaserStatsPoint3 => '私密保存在你的账户中，换新设备也能看到。';

  @override
  String get teaserStatsDemoMessages => '条消息';

  @override
  String get teaserStatsDemoFirstToken => '首个 Token';

  @override
  String get teaserBackupTitle => '私密备份你的聊天';

  @override
  String get teaserBackupPoint1 => '聊天在上传前就在手机上用你自己的口令加密。';

  @override
  String get teaserBackupPoint2 => '连我们也无法读取。';

  @override
  String get teaserBackupPoint3 => '在新手机上用口令即可全部恢复。';

  @override
  String get teaserBackupDemoThis => '这部手机';

  @override
  String get teaserBackupDemoNew => '新手机';

  @override
  String get teaserBackupDemoRestored => '聊天已恢复';

  @override
  String get teaserHfTitle => '运行 Hugging Face 上的任意模型';

  @override
  String get teaserHfPoint1 => '搜索数千个 GGUF 模型，浏览免费。';

  @override
  String get teaserHfPoint2 => '选择适合你手机的大小，我们会检查能否运行。';

  @override
  String get teaserHfPoint3 => '下载一次，之后完全离线聊天。';

  @override
  String get teaserHfDemoFits => '适合';

  @override
  String get teaserHfDemoReady => '可离线使用';

  @override
  String get teaserMemoryTitle => '记得你的聊天';

  @override
  String get teaserMemoryPoint1 => '只需说一次：你的名字、饮食习惯、正在做的项目。';

  @override
  String get teaserMemoryPoint2 => '每个新聊天都已了解重要信息。';

  @override
  String get teaserMemoryPoint3 => '保存在此设备上。可随时查看、编辑或删除任何记忆。';

  @override
  String get teaserMemoryDemoTell => '我吃素，住在里斯本。';

  @override
  String get teaserMemoryDemoFact1 => '素食';

  @override
  String get teaserMemoryDemoFact2 => '住在里斯本';

  @override
  String get teaserMemoryDemoNewChat => '新聊天';

  @override
  String get teaserMemoryDemoAsk => '今晚吃什么？';

  @override
  String get teaserMemoryDemoReply => '这里有 3 家里斯本的素食餐厅…';

  @override
  String get chatUnavailable => '此聊天已不存在。';

  @override
  String get chatUnavailableBack => '返回聊天列表';

  @override
  String get connectionSecurity => '连接安全';

  @override
  String get connectionSecuritySubtitle =>
      '传输过程中已加密（HTTPS）。聊天会经过 LM Mini 中继，并非端到端加密。';

  @override
  String nudgeProPitch(int count) {
    return 'Pro 新增 $count 项功能，包括网页搜索、记忆，以及在手机上使用 Mac 的模型。其余功能仍然免费。';
  }

  @override
  String get nudgeProPitchShort => 'Pro 新增网页搜索、记忆，以及在手机上使用 Mac 的模型。其余功能仍然免费。';

  @override
  String nudgeFromPrice(String price) {
    return '按年付费，每月 $price 起';
  }

  @override
  String get imagePromptStyleTitle => '图像提示词风格';

  @override
  String imagePromptStyleHelp(String server) {
    return 'AI 为 $server 编写图像提示词的方式。留空则使用逗号分隔的标签。对于 Flux 或 Krea，可以试试：用一句自然的英文描述画面。';
  }

  @override
  String get aboutYouTitle => '关于你';

  @override
  String get aboutYouSubtitle => '你的名字，以及 AI 应该了解你的内容';

  @override
  String get aboutYouIntro => '保存在这台设备上，并随每次聊天发送，不用每次都自我介绍。';

  @override
  String get aboutYouNameLabel => '你的名字';

  @override
  String get aboutYouNameHint => 'AI 应该怎么称呼你';

  @override
  String get aboutYouAboutLabel => '关于你';

  @override
  String get aboutYouAboutHint => '例如：你做什么、喜欢什么、想要怎样的回答。';
}
