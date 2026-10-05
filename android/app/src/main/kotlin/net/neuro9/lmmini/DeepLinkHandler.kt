package net.neuro9.lmmini

import android.net.Uri

/// Maps `lmmini://…` URLs to action strings consumed by Dart [DeepLinkService].
/// Mirrors the parser in `ios/Runner/AppDelegate.swift`.
object DeepLinkHandler {
    fun parse(uri: Uri): String? {
        if (uri.scheme != "lmmini") return null
        val host = uri.host ?: return null

        return when (host) {
            "newchat" -> "newChat"
            "camera" -> "newChatWithCamera"
            "chat" -> {
                uri.getQueryParameter("persona")?.let { return "personaChat:$it" }
                uri.getQueryParameter("id")?.let { return "openChat:$it" }
                "newChat"
            }
            "folder" -> uri.getQueryParameter("id")?.let { "openFolder:$it" }
            "news" -> "openNews"
            "shortcut" -> "shortcut:${uri}"
            else -> null
        }
    }
}
