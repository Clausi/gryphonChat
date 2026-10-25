local _, ns = ...

if GetLocale() ~= "deDE" then
    return
end

local L = ns.L

L["ADDON_LOADED"] = "Version %s geladen. Tippe /gryphonchat für Hilfe."
L["DEBUG_ON"] = "Debug-Ausgabe aktiviert."
L["DEBUG_OFF"] = "Debug-Ausgabe deaktiviert."
L["HELP_HEADER"] = "Befehle:"
L["HELP_VERSION"] = "/gryphonchat version - zeigt die Addon-Version"
L["HELP_DEBUG"] = "/gryphonchat debug - schaltet die Debug-Ausgabe um"
L["HELP_NOTIFY"] = "/gryphonchat notify on||off - automatische Meldungen des Addons (z. B. beim Login)"
L["NOTIFY_ON"] = "Automatische Meldungen sind für diesen Charakter an."
L["NOTIFY_OFF"] = "Automatische Meldungen sind für diesen Charakter aus. Antworten auf Befehle erscheinen weiter."
L["COPY_URL_TITLE"] = "Link kopieren"
L["COPY_CHAT_TITLE"] = "Chat kopieren: %s"
L["COPY_CHAT_TOOLTIP"] = "Chat kopieren"
L["COPY_CHAT_EMPTY"] = "Dieses Chatfenster hat keine Nachrichten zum Kopieren."
L["COPY_HINT_LINE"] = "Strg+C kopiert, Esc schließt."
L["COPY_HINT_TEXT"] = "Alles ist markiert: Strg+C kopiert, Esc schließt."
L["HELP_LINES"] = "/gryphonchat lines <50-5000> - so viele Zeilen behält jedes Chatfenster dieses Charakters "
    .. "(Standard 128)"
L["LINES_INFO"] = "Chatfenster behalten für diesen Charakter %d Zeilen."
L["LINES_SET"] = "Chatfenster behalten für diesen Charakter jetzt %d Zeilen."
L["LINES_INVALID"] = "Bitte eine ganze Zahl an Zeilen zwischen %d und %d angeben."
