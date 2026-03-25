import Foundation

/// Dynamic localization that works with the user's selected app language.
/// Falls back to English if a translation is missing.
/// Short version for common labels — just pass the English text, auto-keys by lowercasing
func L(_ english: String) -> String {
    let key = "ui.\(english.lowercased().replacingOccurrences(of: " ", with: "_"))"
    return t(key, fallback: english)
}

func t(_ key: String, fallback: String) -> String {
    // Always use system language — app language follows device settings
    let resolved = Locale.current.language.languageCode?.identifier ?? "en"
    // Try exact match first, then base language (e.g., "fr-CA" → "fr")
    if let translation = translations[resolved]?[key] {
        return translation
    }
    let base = resolved.split(separator: "-").first.map(String.init) ?? resolved
    if base != resolved, let translation = translations[base]?[key] {
        return translation
    }
    // Fall back to English
    if let translation = translations["en"]?[key] {
        return translation
    }
    return fallback
}

// MARK: - Translation Dictionaries

private let translations: [String: [String: String]] = [
    "en": [
        "app.name": "TABAI",
        "chat.placeholder": "Message TABAI",
        "chat.send": "Send", "chat.stop": "Stop", "chat.copy": "Copy",
        "chat.edit": "Edit", "chat.regenerate": "Regenerate", "chat.retry": "Retry",
        "tabs.chat": "Chat", "tabs.history": "History", "tabs.settings": "Settings",
        "auth.sign_in": "Sign In", "auth.email": "Email", "auth.password": "Password",
        "auth.forgot_password": "Forgot password?",
        "history.title": "History", "history.search": "Search",
        "settings.title": "Settings", "settings.theme": "Theme",
        "settings.language": "Language", "settings.sign_out": "Sign Out",
        // UI labels
        "ui.settings": "Settings", "ui.subscription": "Subscription", "ui.usage": "Usage",
        "ui.change_password": "Change Password", "ui.preferences": "Preferences",
        "ui.theme": "Theme", "ui.app_language": "App Language", "ui.speech_language": "Speech Language",
        "ui.notifications": "Notifications", "ui.voice_input": "Voice Input", "ui.haptics": "Haptics",
        "ui.about": "About", "ui.sign_out": "Sign Out", "ui.ask_anything": "Ask anything",
        "ui.new_thread": "New Thread", "ui.project": "Project", "ui.projects": "Projects",
        "ui.today": "Today", "ui.yesterday": "Yesterday", "ui.older": "Older",
        "ui.pinned": "Pinned", "ui.choose_model": "Choose Model", "ui.done": "Done",
        "ui.cancel": "Cancel", "ui.delete": "Delete", "ui.rename": "Rename",
        "ui.upgrade": "Upgrade", "ui.restore": "Restore", "ui.get": "Get",
        "ui.free": "Free", "ui.starter": "Starter", "ui.pro": "Pro", "ui.power": "Power",
        "ui.requests_today": "Requests today", "ui.5-hour_burst": "5-Hour Burst",
        "ui.daily_tokens": "Daily Tokens", "ui.weekly_tokens": "Weekly Tokens",
        "ui.free_plan": "Free plan",
    ],
    "tr": [
        "app.name": "TABAI",
        "chat.placeholder": "TABAI'a mesaj yaz",
        "chat.send": "G\u{00F6}nder", "chat.stop": "Durdur", "chat.copy": "Kopyala",
        "chat.edit": "D\u{00FC}zenle", "chat.regenerate": "Yeniden \u{00DC}ret", "chat.retry": "Tekrarla",
        "tabs.chat": "Sohbet", "tabs.history": "Ge\u{00E7}mi\u{015F}", "tabs.settings": "Ayarlar",
        "auth.sign_in": "Giri\u{015F} Yap", "auth.email": "E-posta", "auth.password": "\u{015E}ifre",
        "auth.forgot_password": "\u{015E}ifrenizi mi unuttunuz?",
        "history.title": "Ge\u{00E7}mi\u{015F}", "history.search": "Ara",
        "settings.title": "Ayarlar", "settings.theme": "Tema",
        "settings.language": "Dil", "settings.sign_out": "\u{00C7}\u{0131}k\u{0131}\u{015F} Yap",
        "ui.settings": "Ayarlar", "ui.subscription": "Abonelik", "ui.usage": "Kullan\u{0131}m",
        "ui.change_password": "\u{015E}ifre De\u{011F}i\u{015F}tir", "ui.preferences": "Tercihler",
        "ui.theme": "Tema", "ui.app_language": "Uygulama Dili", "ui.speech_language": "Konu\u{015F}ma Dili",
        "ui.notifications": "Bildirimler", "ui.voice_input": "Sesli Giri\u{015F}", "ui.haptics": "Titre\u{015F}im",
        "ui.about": "Hakk\u{0131}nda", "ui.sign_out": "\u{00C7}\u{0131}k\u{0131}\u{015F} Yap",
        "ui.ask_anything": "Her \u{015F}eyi sor",
        "ui.new_thread": "Yeni Konu", "ui.project": "Proje", "ui.projects": "Projeler",
        "ui.today": "Bug\u{00FC}n", "ui.yesterday": "D\u{00FC}n", "ui.older": "Eski",
        "ui.pinned": "Sabitlenmi\u{015F}", "ui.choose_model": "Model Se\u{00E7}",
        "ui.done": "Tamam", "ui.cancel": "\u{0130}ptal", "ui.delete": "Sil", "ui.rename": "Yeniden Adland\u{0131}r",
        "ui.upgrade": "Y\u{00FC}kselt", "ui.restore": "Geri Y\u{00FC}kle", "ui.get": "Al",
        "ui.requests_today": "Bug\u{00FC}nk\u{00FC} istekler", "ui.5-hour_burst": "5 Saatlik",
        "ui.daily_tokens": "G\u{00FC}nl\u{00FC}k", "ui.weekly_tokens": "Haftal\u{0131}k",
        "ui.free_plan": "\u{00DC}cretsiz plan",
    ],
    "fr": [
        "app.name": "TABAI",
        "chat.placeholder": "Message \u{00E0} TABAI",
        "chat.send": "Envoyer", "chat.stop": "Arr\u{00EA}ter", "chat.copy": "Copier",
        "chat.edit": "Modifier", "chat.regenerate": "Reg\u{00E9}n\u{00E9}rer", "chat.retry": "R\u{00E9}essayer",
        "tabs.chat": "Chat", "tabs.history": "Historique", "tabs.settings": "Param\u{00E8}tres",
        "auth.sign_in": "Connexion", "auth.email": "E-mail", "auth.password": "Mot de passe",
        "auth.forgot_password": "Mot de passe oubli\u{00E9} ?",
        "history.title": "Historique", "history.search": "Rechercher",
        "settings.title": "Param\u{00E8}tres", "settings.theme": "Th\u{00E8}me",
        "settings.language": "Langue", "settings.sign_out": "D\u{00E9}connexion",
        "ui.settings": "Param\u{00E8}tres", "ui.subscription": "Abonnement", "ui.usage": "Utilisation",
        "ui.preferences": "Pr\u{00E9}f\u{00E9}rences", "ui.about": "\u{00C0} propos",
        "ui.ask_anything": "Demandez n'importe quoi", "ui.new_thread": "Nouveau fil",
        "ui.today": "Aujourd'hui", "ui.yesterday": "Hier", "ui.older": "Plus ancien",
        "ui.done": "Termin\u{00E9}", "ui.cancel": "Annuler", "ui.delete": "Supprimer",
        "ui.upgrade": "Am\u{00E9}liorer", "ui.choose_model": "Choisir le mod\u{00E8}le",
    ],
    "de": [
        "app.name": "TABAI",
        "chat.placeholder": "Nachricht an TABAI",
        "chat.send": "Senden", "chat.stop": "Stopp", "chat.copy": "Kopieren",
        "chat.edit": "Bearbeiten", "chat.regenerate": "Neu generieren", "chat.retry": "Wiederholen",
        "tabs.chat": "Chat", "tabs.history": "Verlauf", "tabs.settings": "Einstellungen",
        "auth.sign_in": "Anmelden", "auth.email": "E-Mail", "auth.password": "Passwort",
        "auth.forgot_password": "Passwort vergessen?",
        "history.title": "Verlauf", "history.search": "Suchen",
        "settings.title": "Einstellungen", "settings.theme": "Design",
        "settings.language": "Sprache", "settings.sign_out": "Abmelden",
        "ui.settings": "Einstellungen", "ui.subscription": "Abonnement", "ui.usage": "Nutzung",
        "ui.preferences": "Einstellungen", "ui.about": "\u{00DC}ber",
        "ui.ask_anything": "Frag mich alles", "ui.new_thread": "Neuer Thread",
        "ui.today": "Heute", "ui.yesterday": "Gestern", "ui.older": "\u{00C4}lter",
        "ui.done": "Fertig", "ui.cancel": "Abbrechen", "ui.delete": "L\u{00F6}schen",
        "ui.upgrade": "Upgrade", "ui.choose_model": "Modell w\u{00E4}hlen",
    ],
    "es": [
        "app.name": "TABAI",
        "chat.placeholder": "Mensaje a TABAI",
        "chat.send": "Enviar", "chat.stop": "Detener", "chat.copy": "Copiar",
        "chat.edit": "Editar", "chat.regenerate": "Regenerar", "chat.retry": "Reintentar",
        "tabs.chat": "Chat", "tabs.history": "Historial", "tabs.settings": "Ajustes",
        "auth.sign_in": "Iniciar sesi\u{00F3}n", "auth.email": "Correo", "auth.password": "Contrase\u{00F1}a",
        "auth.forgot_password": "\u{00BF}Olvidaste tu contrase\u{00F1}a?",
        "history.title": "Historial", "history.search": "Buscar",
        "settings.title": "Ajustes", "settings.theme": "Tema",
        "settings.language": "Idioma", "settings.sign_out": "Cerrar sesi\u{00F3}n",
    ],
    "it": [
        "app.name": "TABAI",
        "chat.placeholder": "Messaggio a TABAI",
        "chat.send": "Invia", "chat.stop": "Ferma", "chat.copy": "Copia",
        "chat.edit": "Modifica", "chat.regenerate": "Rigenera", "chat.retry": "Riprova",
        "tabs.chat": "Chat", "tabs.history": "Cronologia", "tabs.settings": "Impostazioni",
        "auth.sign_in": "Accedi", "auth.email": "Email", "auth.password": "Password",
        "history.title": "Cronologia", "history.search": "Cerca",
        "settings.title": "Impostazioni", "settings.sign_out": "Esci",
    ],
    "pt": [
        "app.name": "TABAI",
        "chat.placeholder": "Mensagem para TABAI",
        "chat.send": "Enviar", "chat.stop": "Parar", "chat.copy": "Copiar",
        "chat.edit": "Editar", "chat.regenerate": "Regenerar", "chat.retry": "Tentar novamente",
        "tabs.chat": "Chat", "tabs.history": "Hist\u{00F3}rico", "tabs.settings": "Configura\u{00E7}\u{00F5}es",
        "auth.sign_in": "Entrar", "auth.email": "E-mail", "auth.password": "Senha",
        "history.title": "Hist\u{00F3}rico", "history.search": "Pesquisar",
        "settings.title": "Configura\u{00E7}\u{00F5}es", "settings.sign_out": "Sair",
    ],
    "ru": [
        "app.name": "TABAI",
        "chat.placeholder": "\u{0421}\u{043E}\u{043E}\u{0431}\u{0449}\u{0435}\u{043D}\u{0438}\u{0435} TABAI",
        "chat.send": "\u{041E}\u{0442}\u{043F}\u{0440}\u{0430}\u{0432}\u{0438}\u{0442}\u{044C}", "chat.stop": "\u{0421}\u{0442}\u{043E}\u{043F}", "chat.copy": "\u{041A}\u{043E}\u{043F}\u{0438}\u{0440}\u{043E}\u{0432}\u{0430}\u{0442}\u{044C}",
        "tabs.chat": "\u{0427}\u{0430}\u{0442}", "tabs.history": "\u{0418}\u{0441}\u{0442}\u{043E}\u{0440}\u{0438}\u{044F}", "tabs.settings": "\u{041D}\u{0430}\u{0441}\u{0442}\u{0440}\u{043E}\u{0439}\u{043A}\u{0438}",
        "auth.sign_in": "\u{0412}\u{043E}\u{0439}\u{0442}\u{0438}",
        "settings.sign_out": "\u{0412}\u{044B}\u{0439}\u{0442}\u{0438}",
    ],
    "ja": [
        "app.name": "TABAI",
        "chat.placeholder": "TABAI\u{306B}\u{30E1}\u{30C3}\u{30BB}\u{30FC}\u{30B8}",
        "chat.send": "\u{9001}\u{4FE1}", "chat.stop": "\u{505C}\u{6B62}", "chat.copy": "\u{30B3}\u{30D4}\u{30FC}",
        "tabs.chat": "\u{30C1}\u{30E3}\u{30C3}\u{30C8}", "tabs.history": "\u{5C65}\u{6B74}", "tabs.settings": "\u{8A2D}\u{5B9A}",
        "auth.sign_in": "\u{30B5}\u{30A4}\u{30F3}\u{30A4}\u{30F3}",
        "settings.sign_out": "\u{30B5}\u{30A4}\u{30F3}\u{30A2}\u{30A6}\u{30C8}",
    ],
    "ko": [
        "app.name": "TABAI",
        "chat.placeholder": "TABAI\u{C5D0} \u{BA54}\u{C2DC}\u{C9C0}",
        "chat.send": "\u{C804}\u{C1A1}", "chat.stop": "\u{C815}\u{C9C0}", "chat.copy": "\u{BCF5}\u{C0AC}",
        "tabs.chat": "\u{CC44}\u{D305}", "tabs.history": "\u{AE30}\u{B85D}", "tabs.settings": "\u{C124}\u{C815}",
        "auth.sign_in": "\u{B85C}\u{ADF8}\u{C778}",
        "settings.sign_out": "\u{B85C}\u{ADF8}\u{C544}\u{C6C3}",
    ],
    "zh-Hans": [
        "app.name": "TABAI",
        "chat.placeholder": "\u{7ED9} TABAI \u{53D1}\u{6D88}\u{606F}",
        "chat.send": "\u{53D1}\u{9001}", "chat.stop": "\u{505C}\u{6B62}", "chat.copy": "\u{590D}\u{5236}",
        "tabs.chat": "\u{804A}\u{5929}", "tabs.history": "\u{5386}\u{53F2}", "tabs.settings": "\u{8BBE}\u{7F6E}",
        "auth.sign_in": "\u{767B}\u{5F55}",
        "settings.sign_out": "\u{9000}\u{51FA}",
    ],
    "hi": [
        "app.name": "TABAI",
        "chat.send": "\u{092D}\u{0947}\u{091C}\u{0947}\u{0902}", "chat.stop": "\u{0930}\u{0941}\u{0915}\u{0947}\u{0902}",
        "tabs.chat": "\u{091A}\u{0948}\u{091F}", "tabs.settings": "\u{0938}\u{0947}\u{091F}\u{093F}\u{0902}\u{0917}\u{094D}\u{0938}",
        "auth.sign_in": "\u{0938}\u{093E}\u{0907}\u{0928} \u{0907}\u{0928}",
    ],
    "ar": [
        "app.name": "TABAI",
        "chat.placeholder": "TABAI \u{0631}\u{0633}\u{0627}\u{0644}\u{0629} \u{0625}\u{0644}\u{0649}",
        "chat.send": "\u{0625}\u{0631}\u{0633}\u{0627}\u{0644}", "chat.stop": "\u{0625}\u{064A}\u{0642}\u{0627}\u{0641}", "chat.copy": "\u{0646}\u{0633}\u{062E}",
        "tabs.chat": "\u{0645}\u{062D}\u{0627}\u{062F}\u{062B}\u{0629}", "tabs.history": "\u{0627}\u{0644}\u{0633}\u{062C}\u{0644}", "tabs.settings": "\u{0627}\u{0644}\u{0625}\u{0639}\u{062F}\u{0627}\u{062F}\u{0627}\u{062A}",
        "auth.sign_in": "\u{062A}\u{0633}\u{062C}\u{064A}\u{0644} \u{0627}\u{0644}\u{062F}\u{062E}\u{0648}\u{0644}",
        "settings.sign_out": "\u{062A}\u{0633}\u{062C}\u{064A}\u{0644} \u{0627}\u{0644}\u{062E}\u{0631}\u{0648}\u{062C}",
    ],
    "th": [
        "app.name": "TABAI",
        "chat.send": "\u{0E2A}\u{0E48}\u{0E07}", "chat.stop": "\u{0E2B}\u{0E22}\u{0E38}\u{0E14}",
        "tabs.chat": "\u{0E41}\u{0E0A}\u{0E17}", "tabs.settings": "\u{0E15}\u{0E31}\u{0E49}\u{0E07}\u{0E04}\u{0E48}\u{0E32}",
    ],
    "uk": [
        "app.name": "TABAI",
        "chat.send": "\u{041D}\u{0430}\u{0434}\u{0456}\u{0441}\u{043B}\u{0430}\u{0442}\u{0438}", "chat.stop": "\u{0421}\u{0442}\u{043E}\u{043F}",
        "tabs.chat": "\u{0427}\u{0430}\u{0442}", "tabs.settings": "\u{041D}\u{0430}\u{043B}\u{0430}\u{0448}\u{0442}\u{0443}\u{0432}\u{0430}\u{043D}\u{043D}\u{044F}",
        "auth.sign_in": "\u{0423}\u{0432}\u{0456}\u{0439}\u{0442}\u{0438}",
    ],
]
