#!/usr/bin/env python3
"""One-shot script to add missing translations. Safe to delete after running."""
import json, sys, os

TRANSLATIONS = {
    'de': {
        'customRequestHeaders': 'Eigene Anfrage-Header',
        'customRequestHeadersSubtitle': 'Optionale Header, die jeder LM-Studio-Anfrage hinzugefügt werden',
        'customRequestHeadersHelp': 'Verwende dies für Reverse-Proxys oder Auth-Gateways, die zusätzliche Header benötigen (z. B. Cloudflare Access Service-Tokens, ein internes Token unter einem benutzerdefinierten Header-Namen usw.). Header werden bei jeder Anfrage an deinen LM-Studio-Server gesendet.',
        'cloudflareAccessSection': 'Cloudflare Access (Service-Token)',
        'cloudflareAccessHelp': 'Wenn dein LM Studio hinter einer Cloudflare-Access-Richtlinie steht, füge hier die Client-ID und das Secret des Service-Tokens ein. Sie werden bei jeder Anfrage als CF-Access-Client-Id und CF-Access-Client-Secret gesendet, sodass sich die App ohne interaktive Browser-SSO-Anmeldung authentifizieren kann.',
        'cfAccessClientIdLabel': 'CF-Access-Client-Id',
        'cfAccessClientSecretLabel': 'CF-Access-Client-Secret',
        'addHeader': 'Header hinzufügen',
        'removeHeader': 'Header entfernen',
        'headerNameLabel': 'Header-Name',
        'headerValueLabel': 'Header-Wert',
        'headersConfigured': '{count, plural, =1{1 Header konfiguriert} other{{count} Header konfiguriert}}',
        'noCustomHeaders': 'Keine eigenen Header',
        'comfyUiUseNegativePromptTitle': 'Negativen Prompt verwenden',
        'comfyUiUseNegativePromptSubtitle': 'Standardmäßig aus für ComfyUI. Wenn aus, wird kein negativer Prompt an den Workflow gesendet.',
        'documentationTitle': 'Dokumentation',
        'documentationSubtitle': 'Einrichtungsanleitungen für Gruppen-Chat, ComfyUI, Tastaturverhalten und mehr',
        'changelogTitle': 'Änderungsprotokoll',
        'changelogSubtitle': 'Versionsverlauf & Updates',
        'enableCustomHeaders': 'Eigene Header aktivieren',
        'enableCustomHeadersSubtitle': 'Zusätzliche HTTP-Header an jede LM-Studio-Anfrage anhängen',
    },
    'es': {
        'customRequestHeaders': 'Encabezados de solicitud personalizados',
        'customRequestHeadersSubtitle': 'Encabezados opcionales añadidos a cada solicitud de LM Studio',
        'customRequestHeadersHelp': 'Úsalo para proxies inversos o pasarelas de autenticación que requieren encabezados adicionales (por ejemplo, tokens de servicio de Cloudflare Access, un token interno con un nombre de encabezado personalizado, etc.). Los encabezados se envían en cada solicitud a tu servidor de LM Studio.',
        'cloudflareAccessSection': 'Cloudflare Access (token de servicio)',
        'cloudflareAccessHelp': 'Si tu LM Studio está detrás de una política de Cloudflare Access, pega aquí el ID de cliente y el secreto del token de servicio. Se envían como CF-Access-Client-Id y CF-Access-Client-Secret en cada solicitud, para que la app pueda autenticarse sin un inicio de sesión SSO interactivo en el navegador.',
        'cfAccessClientIdLabel': 'CF-Access-Client-Id',
        'cfAccessClientSecretLabel': 'CF-Access-Client-Secret',
        'addHeader': 'Añadir encabezado',
        'removeHeader': 'Quitar encabezado',
        'headerNameLabel': 'Nombre del encabezado',
        'headerValueLabel': 'Valor del encabezado',
        'headersConfigured': '{count, plural, =1{1 encabezado configurado} other{{count} encabezados configurados}}',
        'noCustomHeaders': 'Sin encabezados personalizados',
        'comfyUiUseNegativePromptTitle': 'Usar prompt negativo',
        'comfyUiUseNegativePromptSubtitle': 'Desactivado por defecto para ComfyUI. Cuando está desactivado, no se envía un prompt negativo al flujo de trabajo.',
        'documentationTitle': 'Documentación',
        'documentationSubtitle': 'Guías de configuración para Chat Grupal, ComfyUI, comportamiento del teclado y más',
        'changelogTitle': 'Registro de cambios',
        'changelogSubtitle': 'Historial de versiones y actualizaciones',
        'enableCustomHeaders': 'Activar encabezados personalizados',
        'enableCustomHeadersSubtitle': 'Adjuntar encabezados HTTP adicionales a cada solicitud de LM Studio',
    },
    'fr': {
        'customRequestHeaders': 'En-têtes de requête personnalisés',
        'customRequestHeadersSubtitle': 'En-têtes facultatifs ajoutés à chaque requête LM Studio',
        'customRequestHeadersHelp': "À utiliser pour les reverse proxies ou passerelles d'authentification nécessitant des en-têtes supplémentaires (par ex. les jetons de service Cloudflare Access, un jeton interne sous un nom d'en-tête personnalisé, etc.). Les en-têtes sont envoyés à chaque requête vers votre serveur LM Studio.",
        'cloudflareAccessSection': 'Cloudflare Access (jeton de service)',
        'cloudflareAccessHelp': "Si votre LM Studio est derrière une politique Cloudflare Access, collez ici l'ID client et le secret du jeton de service. Ils sont envoyés en tant que CF-Access-Client-Id et CF-Access-Client-Secret à chaque requête, afin que l'app puisse s'authentifier sans connexion SSO interactive dans le navigateur.",
        'cfAccessClientIdLabel': 'CF-Access-Client-Id',
        'cfAccessClientSecretLabel': 'CF-Access-Client-Secret',
        'addHeader': 'Ajouter un en-tête',
        'removeHeader': "Supprimer l'en-tête",
        'headerNameLabel': "Nom de l'en-tête",
        'headerValueLabel': "Valeur de l'en-tête",
        'headersConfigured': '{count, plural, =1{1 en-tête configuré} other{{count} en-têtes configurés}}',
        'noCustomHeaders': 'Aucun en-tête personnalisé',
        'comfyUiUseNegativePromptTitle': 'Utiliser un prompt négatif',
        'comfyUiUseNegativePromptSubtitle': "Désactivé par défaut pour ComfyUI. Lorsqu'il est désactivé, aucun prompt négatif n'est envoyé au workflow.",
        'documentationTitle': 'Documentation',
        'documentationSubtitle': 'Guides de configuration pour le Chat de groupe, ComfyUI, le comportement du clavier, et plus',
        'changelogTitle': 'Journal des modifications',
        'changelogSubtitle': 'Historique des versions et mises à jour',
        'enableCustomHeaders': 'Activer les en-têtes personnalisés',
        'enableCustomHeadersSubtitle': 'Joindre des en-têtes HTTP supplémentaires à chaque requête LM Studio',
    },
    'ru': {
        'customRequestHeaders': 'Пользовательские заголовки запроса',
        'customRequestHeadersSubtitle': 'Дополнительные заголовки, добавляемые к каждому запросу LM Studio',
        'customRequestHeadersHelp': 'Используйте это для обратных прокси или шлюзов аутентификации, которым требуются дополнительные заголовки (например, сервисные токены Cloudflare Access, внутренний токен под пользовательским именем заголовка и т. д.). Заголовки отправляются с каждым запросом к вашему серверу LM Studio.',
        'cloudflareAccessSection': 'Cloudflare Access (сервисный токен)',
        'cloudflareAccessHelp': 'Если ваш LM Studio находится за политикой Cloudflare Access, вставьте сюда идентификатор клиента и секрет сервисного токена. Они отправляются как CF-Access-Client-Id и CF-Access-Client-Secret с каждым запросом, чтобы приложение могло пройти аутентификацию без интерактивного входа SSO в браузере.',
        'cfAccessClientIdLabel': 'CF-Access-Client-Id',
        'cfAccessClientSecretLabel': 'CF-Access-Client-Secret',
        'addHeader': 'Добавить заголовок',
        'removeHeader': 'Удалить заголовок',
        'headerNameLabel': 'Имя заголовка',
        'headerValueLabel': 'Значение заголовка',
        'headersConfigured': '{count, plural, =1{Настроен 1 заголовок} other{Настроено {count} заголовков}}',
        'noCustomHeaders': 'Нет пользовательских заголовков',
        'comfyUiUseNegativePromptTitle': 'Использовать негативный промпт',
        'comfyUiUseNegativePromptSubtitle': 'По умолчанию отключено для ComfyUI. Когда отключено, негативный промпт не отправляется в воркфлоу.',
        'documentationTitle': 'Документация',
        'documentationSubtitle': 'Руководства по настройке группового чата, ComfyUI, поведения клавиатуры и многого другого',
        'changelogTitle': 'История изменений',
        'changelogSubtitle': 'История версий и обновлений',
        'enableCustomHeaders': 'Включить пользовательские заголовки',
        'enableCustomHeadersSubtitle': 'Прикреплять дополнительные HTTP-заголовки к каждому запросу LM Studio',
    },
}

# headersConfigured needs a placeholder metadata entry (plural).
PLACEHOLDERS = {
    'headersConfigured': {
        '@headersConfigured': {
            'placeholders': {'count': {'type': 'int'}}
        }
    },
}

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
L10N_DIR = os.path.join(ROOT, 'lib', 'l10n')

for locale, strings in TRANSLATIONS.items():
    path = os.path.join(L10N_DIR, f'app_{locale}.arb')
    with open(path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    added = 0
    for k, v in strings.items():
        if k not in data:
            data[k] = v
            added += 1
        # add metadata for plural strings if missing
        for meta_key, meta_val in PLACEHOLDERS.get(k, {}).items():
            if meta_key not in data:
                data[meta_key] = meta_val
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write('\n')
    print(f'{locale}: added {added} keys')

print('Done.')
