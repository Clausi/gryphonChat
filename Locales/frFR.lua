local _, ns = ...

if GetLocale() ~= "frFR" then
    return
end

local L = ns.L

L["ADDON_LOADED"] = "Version %s chargée. Tapez /gryphonchat pour l'aide."
L["DEBUG_ON"] = "Sortie de débogage activée."
L["DEBUG_OFF"] = "Sortie de débogage désactivée."
L["HELP_HEADER"] = "Commandes :"
L["HELP_VERSION"] = "/gryphonchat version - affiche la version de l'addon"
L["HELP_DEBUG"] = "/gryphonchat debug - active ou désactive la sortie de débogage"
L["HELP_NOTIFY"] = "/gryphonchat notify on||off - messages automatiques de l'addon (p. ex. à la connexion)"
L["NOTIFY_ON"] = "Les messages automatiques sont activés pour ce personnage."
L["NOTIFY_OFF"] = "Les messages automatiques sont désactivés pour ce personnage. "
    .. "Les réponses aux commandes restent affichées."
L["COPY_URL_TITLE"] = "Copier le lien"
L["COPY_CHAT_TITLE"] = "Copier le chat : %s"
L["COPY_CHAT_TOOLTIP"] = "Copier le chat"
L["COPY_CHAT_EMPTY"] = "Cette fenêtre de chat n'a aucun message à copier."
L["COPY_HINT_LINE"] = "Ctrl+C copie, Échap ferme."
L["COPY_HINT_TEXT"] = "Tout est sélectionné : Ctrl+C copie, Échap ferme."
L["HELP_LINES"] = "/gryphonchat lines <50-5000> - lignes conservées par chaque fenêtre de chat (128 par défaut)"
L["LINES_INFO"] = "Les fenêtres de chat conservent %d lignes pour ce personnage."
L["LINES_SET"] = "Les fenêtres de chat conservent maintenant %d lignes pour ce personnage."
L["LINES_INVALID"] = "Veuillez saisir un nombre entier de lignes entre %d et %d."
