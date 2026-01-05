import SwiftUI
import Combine

/// Lightweight in-app localization manager.
/// Stores current language in UserDefaults and provides `t(_:)` for UI strings.
class Lang: ObservableObject {

    static let shared = Lang()

    /// Current language code (persisted in UserDefaults).
    @Published var current: String = UserDefaults.standard.string(forKey: "selectedLanguage") ?? "pl"

    /// Translation table: key -> (languageCode -> localizedString).
    let translations: [String: [String: String]] = [
        "reorder": ["pl":"Przeciągnij, aby zmienić kolejność", "en":"Drag to reorder"],
        "clear": ["pl":"Wyczyść", "en": "Clear"],
        "selectAll": ["pl":"Zaznacz wszystko", "en":"Select all"],

        "savingList": [
            "pl": "Zapisywanie listy…",
            "en": "Saving list…",
            "es": "Guardando list…",
            "fr": "Enregistrement de la liste…",
            "zh": "正在保存列表…",
            "hi": "सूची सहेजी जा रही है…",
            "ar": "جارٍ حفظ القائمة…",
            "bn": "তালিকা সংরক্ষণ করা হচ্ছে…",
            "pt": "Salvando lista…",
            "ru": "Сохранение списка…"
        ],

        "deleteSongFromPlaylistConfirm": [
            "pl": "Usunąć utwór tylko z tej playlisty?",
            "en": "Remove the song from this playlist only?",
            "es": "¿Eliminar la canción solo de esta lista de reproducción?",
            "fr": "Supprimer la chanson uniquement de cette playlist ?",
            "zh": "只从此播放列表中移除该歌曲？",
            "hi": "क्या केवल इस प्लेलिस्ट से गीत हटाना है?",
            "ar": "إزالة الأغنية من هذه القائمة فقط؟",
            "bn": "শুধুমাত্র এই প্লেলিস্ট থেকে গানটি সরাতে চান?",
            "pt": "Remover a música apenas desta playlist?",
            "ru": "Удалить песню только из этого плейлиста?"
        ],

        "rememberSliderTimeMode": [
            "pl": "Zapamiętaj ostatnio wybrany sposób pokazywania czasu pod suwakiem",
            "en": "Remember my last choice for time display under the slider",
            "es": "Recordar mi última elección para mostrar el tiempo bajo el deslizador",
            "fr": "Se souvenir de mon dernier choix d'affichage du temps sous le curseur",
            "zh": "记住我上次选择的滑块下方时间显示方式",
            "hi": "स्लाइडर के नीचे समय दिखाने का मेरा अंतिम चयन याद रखें",
            "ar": "تذكر آخر خيار لي لعرض الوقت تحت شريط التمرير",
            "bn": "স্লাইডারের নিচে সময় দেখানোর জন্য আমার সর্বশেষ নির্বাচন মনে রাখুন",
            "pt": "Lembrar minha última escolha de exibição de tempo sob o controle deslizante",
            "ru": "Запоминать мой последний выбор отображения времени под слайдером"
        ],

        "deleteAllSongs": [
            "pl": "Usuń wszystkie utwory",
            "en": "Delete all songs",
            "es": "Eliminar todas las canciones",
            "fr": "Supprimer toutes les chansons",
            "zh": "删除所有歌曲",
            "hi": "सभी गाने हटाएं",
            "ar": "حذف جميع الأغاني",
            "bn": "সব গান মুছে ফেলুন",
            "pt": "Excluir todas as músicas",
            "ru": "Удалить все песни"
        ],
        "deleteAllSongsConfirm": [
            "pl": "Czy na pewno usunąć wszystkie utwory z aplikacji? Pliki pozostaną w pamięci telefonu.",
            "en": "Are you sure you want to delete all songs from the app? The files will remain on your device.",
            "es": "¿Seguro que deseas eliminar todas las canciones de la aplicación? Los archivos permanecerán en tu dispositivo.",
            "fr": "Voulez-vous vraiment supprimer toutes les chansons de l'application ? Les fichiers resteront sur votre appareil.",
            "zh": "确定要从应用中删除所有歌曲吗？文件仍将保留在您的设备上。",
            "hi": "क्या आप वाकई ऐप से सभी गाने हटाना चाहते हैं? फ़ाइलें आपके फ़ोन में रहेंगी।",
            "ar": "هل أنت متأكد أنك تريد حذف جميع الأغاني من التطبيق؟ ستبقى الملفات على هاتفك.",
            "bn": "আপনি কি সত্যিই অ্যাপ থেকে সব গান মুছে ফেলতে চান? ফাইলগুলি আপনার ফোনে থাকবে।",
            "pt": "Tem certeza de que deseja excluir todas as músicas do aplicativo? Os arquivos permanecerão no seu dispositivo.",
            "ru": "Вы уверены, что хотите удалить все песни из приложения? Файлы останутся на вашем устройстве."
        ],

        "deleteSongNote": [
            "pl": "Utwór zostanie usunięty tylko z aplikacji. Plik pozostanie w pamięci telefonu.",
            "en": "The song will be removed only from the app. The file will remain on your device.",
            "es": "La canción se eliminará solo de la aplicación. El archivo permanecerá en tu dispositivo.",
            "fr": "La chanson sera supprimée uniquement de l'application. Le fichier restera sur votre appareil.",
            "zh": "歌曲只会从应用中移除，文件仍会保留在您的设备上。",
            "hi": "गाना केवल ऐप से हटाया जाएगा। फ़ाइल आपके फ़ोन में रहेगी।",
            "ar": "سيتم حذف الأغنية فقط من التطبيق. سيظل الملف على هاتفك.",
            "bn": "গানটি শুধুমাত্র অ্যাপ থেকে মুছে যাবে। ফাইলটি আপনার ফোনে থাকবে।",
            "pt": "A música será removida apenas do aplicativo. O arquivo permanecerá no seu dispositivo.",
            "ru": "Песня будет удалена только из приложения. Файл останется на вашем устройстве."
        ],

        "resumePlaybackOption": [
            "pl": "Wznów odtwarzanie od miejsca zatrzymania",
            "en": "Resume playback from where you left off",
            "es": "Reanudar la reproducción desde donde la dejaste",
            "fr": "Reprendre la lecture là où vous l'avez arrêtée",
            "zh": "从上次停止的地方恢复播放",
            "hi": "जहां छोड़ा था वहां से प्लेबैक फिर से शुरू करें",
            "ar": "استئناف التشغيل من حيث توقفت",
            "bn": "শেষবার যেখানে থেমেছিল, সেখান থেকে প্লেব্যাক শুরু করুন",
            "pt": "Retomar a reprodução de onde você parou",
            "ru": "Возобновить воспроизведение с того места, где вы остановились"
        ],

        "settings": [
            "pl": "Ustawienia",
            "en": "Settings",
            "es": "Configuración",
            "fr": "Paramètres",
            "zh": "设置",
            "hi": "सेटिंग्स",
            "ar": "الإعدادات",
            "bn": "সেটিংস",
            "pt": "Configurações",
            "ru": "Настройки"
        ],
        "songs": [
            "pl": "Lista utworów",
            "en": "Song list",
            "es": "Lista de canciones",
            "fr": "Liste des chansons",
            "zh": "歌曲列表",
            "hi": "गीत सूची",
            "ar": "قائمة الأغاني",
            "bn": "গানের তালিকা",
            "pt": "Lista de músicas",
            "ru": "Список песен"
        ],
        "nowPlaying": [
            "pl": "Teraz gra",
            "en": "Now playing",
            "es": "Reproduciendo",
            "fr": "Lecture en cours",
            "zh": "正在播放",
            "hi": "अब चल रहा है",
            "ar": "يتم التشغيل الآن",
            "bn": "এখন চলছে",
            "pt": "Tocando agora",
            "ru": "Сейчас играет"
        ],
        "reset": [
            "pl": "Resetuj aplikację",
            "en": "Reset app",
            "es": "Restablecer aplicación",
            "fr": "Réinitialiser l'application",
            "zh": "重置应用",
            "hi": "ऐप रीसेट करें",
            "ar": "إعادة تعيين التطبيق",
            "bn": "অ্যাপ রিসেট করুন",
            "pt": "Redefinir aplicativo",
            "ru": "Сбросить приложение"
        ],
        "theme": [
            "pl": "Motyw kolorów",
            "en": "Color theme",
            "es": "Tema de color",
            "fr": "Thème de couleur",
            "zh": "配色方案",
            "hi": "रंग थीम",
            "ar": "سمة الألوان",
            "bn": "রঙের থিম",
            "pt": "Tema de cores",
            "ru": "Цветовая тема"
        ],
        "language": [
            "pl": "Język",
            "en": "Language",
            "es": "Idioma",
            "fr": "Langue",
            "zh": "语言",
            "hi": "भाषा",
            "ar": "اللغة",
            "bn": "ভাষা",
            "pt": "Idioma",
            "ru": "Язык"
        ],
        "unsupportedFilesTitle": [
            "pl": "Nieobsługiwane pliki audio",
            "en": "Unsupported audio files",
            "es": "Archivos de audio no compatibles",
            "fr": "Fichiers audio non pris en charge",
            "zh": "不支持的音频文件",
            "hi": "असमर्थित ऑडियो फ़ाइलें",
            "ar": "ملفات صوتية غير مدعومة",
            "bn": "অসমর্থিত অডিও ফাইল",
            "pt": "Arquivos de áudio não suportados",
            "ru": "Неподдерживаемые аудиофайлы"
        ],
        "playlistName": [
            "pl": "Nazwa playlisty...",
            "en": "Playlist name...",
            "es": "Nombre de la lista...",
            "fr": "Nom de la playlist...",
            "zh": "播放列表名称...",
            "hi": "प्लेलिस्ट का नाम...",
            "ar": "اسم قائمة التشغيل...",
            "bn": "প্লেলিস্টের নাম...",
            "pt": "Nome da playlist...",
            "ru": "Имя плейлиста..."
        ],
        "create": [
            "pl": "Utwórz",
            "en": "Create",
            "es": "Crear",
            "fr": "Créer",
            "zh": "创建",
            "hi": "सृजन करें",
            "ar": "إنشاء",
            "bn": "তৈরি করুন",
            "pt": "Criar",
            "ru": "Создать"
        ],
        "deleteSongConfirm": [
            "pl": "Na pewno usunąć ten utwór?",
            "en": "Are you sure you want to delete this song?",
            "es": "¿Seguro que deseas eliminar esta canción?",
            "fr": "Voulez-vous vraiment supprimer cette chanson ?",
            "zh": "确定要删除这首歌吗？",
            "hi": "क्या आप वाकई इस गीत को हटाना चाहते हैं?",
            "ar": "هل أنت متأكد أنك تريد حذف هذه الأغنية؟",
            "bn": "আপনি কি নিশ্চিতভাবে এই গানটি মুছে ফেলতে চান?",
            "pt": "Tem certeza de que deseja excluir esta música?",
            "ru": "Вы уверены, что хотите удалить эту песню?"
        ],
        "deleteSongEverywhere": [
            "pl": "Ten plik jest także na Twoich playlistach. Usunięcie spowoduje, że zniknie z aplikacji i playlist. Usunąć?",
            "en": "This file is also on your playlists. Deleting will remove it from the app and all playlists. Delete?",
            "es": "Este archivo también está en tus listas de reproducción. Eliminarlo lo quitará de la app y de todas las listas. ¿Eliminar?",
            "fr": "Ce fichier est également dans vos playlists. La suppression l'enlèvera de l'application et de toutes les playlists. Supprimer ?",
            "zh": "此文件也在您的播放列表中。删除将使其从应用和所有播放列表中消失。确定删除？",
            "hi": "यह फ़ाइल आपकी प्लेलिस्ट्स में भी है। हटाने से यह ऐप और सभी प्लेलिस्ट्स से हट जाएगा। हटाएं?",
            "ar": "هذا الملف موجود أيضًا في قوائم التشغيل الخاصة بك. الحذف سيزيله من التطبيق وجميع القوائم. حذف؟",
            "bn": "এই ফাইলটি আপনার প্লেলিস্টেও রয়েছে। মুছে ফেললে অ্যাপ এবং সব প্লেলিস্ট থেকে সরে যাবে। মুছবেন?",
            "pt": "Este arquivo também está em suas playlists. Excluir irá removê-lo do app e de todas as playlists. Excluir?",
            "ru": "Этот файл также есть в ваших плейлистах. Удаление удалит его из приложения и всех плейлистов. Удалить?"
        ],
        "allSongs": [
            "pl": "Wszystkie utwory",
            "en": "All songs",
            "es": "Todas las canciones",
            "fr": "Toutes les chansons",
            "zh": "所有歌曲",
            "hi": "सभी गाने",
            "ar": "جميع الأغاني",
            "bn": "সব গান",
            "pt": "Todas as músicas",
            "ru": "Все песни"
        ],
        "searchSong": [
            "pl": "Szukaj utworu...",
            "en": "Search for a song...",
            "es": "Buscar canción...",
            "fr": "Rechercher une chanson...",
            "zh": "搜索歌曲...",
            "hi": "गीत खोजें...",
            "ar": "ابحث عن أغنية...",
            "bn": "গান খুঁজুন...",
            "pt": "Buscar música...",
            "ru": "Искать песню..."
        ],
        "addToPlaylist": [
            "pl": "Dodaj do playlisty",
            "en": "Add to playlist",
            "es": "Agregar a la lista",
            "fr": "Ajouter à la playlist",
            "zh": "添加到播放列表",
            "hi": "प्लेलिस्ट में जोड़ें",
            "ar": "أضف إلى قائمة التشغيل",
            "bn": "প্লেলিস্টে যোগ করুন",
            "pt": "Adicionar à playlist",
            "ru": "Добавить в плейлист"
        ],
        "yourPlaylists": [
            "pl": "Twoje playlisty",
            "en": "Your playlists",
            "es": "Tus listas",
            "fr": "Vos playlists",
            "zh": "你的播放列表",
            "hi": "आपकी प्लेलिस्ट्स",
            "ar": "قوائم التشغيل الخاصة بك",
            "bn": "আপনার প্লেলিস্ট",
            "pt": "Suas playlists",
            "ru": "Ваши плейлисты"
        ],
        "newPlaylist": [
            "pl": "Nowa playlista",
            "en": "New playlist",
            "es": "Nueva lista",
            "fr": "Nouvelle playlist",
            "zh": "新建播放列表",
            "hi": "नई प्लेलिस्ट",
            "ar": "قائمة تشغيل جديدة",
            "bn": "নতুন প্লেলিস্ট",
            "pt": "Nova playlist",
            "ru": "Новый плейлист"
        ],
        "deletePlaylistQ": [
            "pl": "Usuń playlistę?",
            "en": "Delete playlist?",
            "es": "¿Eliminar lista?",
            "fr": "Supprimer la playlist ?",
            "zh": "删除播放列表？",
            "hi": "प्लेलिस्ट हटाएं?",
            "ar": "حذف قائمة التشغيل؟",
            "bn": "প্লেলিস্ট মুছবেন?",
            "pt": "Excluir playlist?",
            "ru": "Удалить плейлист?"
        ],
        "deletePlaylistDesc": [
            "pl": "Tej operacji nie można cofnąć.",
            "en": "This action cannot be undone.",
            "es": "Esta acción no se puede deshacer.",
            "fr": "Cette action est irréversible.",
            "zh": "此操作无法撤销。",
            "hi": "यह क्रिया पूर्ववत नहीं की जा सकती।",
            "ar": "لا يمكن التراجع عن هذا الإجراء.",
            "bn": "এই কাজটি আর পূর্বাবস্থায় ফেরানো যাবে না।",
            "pt": "Esta ação não pode ser desfeita.",
            "ru": "Это действие нельзя отменить."
        ],
        "delete": [
            "pl": "Usuń",
            "en": "Delete",
            "es": "Eliminar",
            "fr": "Supprimer",
            "zh": "删除",
            "hi": "हटाएं",
            "ar": "حذف",
            "bn": "মুছুন",
            "pt": "Excluir",
            "ru": "Удалить"
        ],
        "cancel": [
            "pl": "Anuluj",
            "en": "Cancel",
            "es": "Cancelar",
            "fr": "Annuler",
            "zh": "取消",
            "hi": "रद्द करें",
            "ar": "إلغاء",
            "bn": "বাতিল করুন",
            "pt": "Cancelar",
            "ru": "Отмена"
        ],
        "songCountSingular": [
            "pl": "utwór",
            "en": "song",
            "es": "canción",
            "fr": "chanson",
            "zh": "歌曲",
            "hi": "गीत",
            "ar": "أغنية",
            "bn": "গান",
            "pt": "música",
            "ru": "песня"
        ],
        "songCountPlural": [
            "pl": "utwory",
            "en": "songs",
            "es": "canciones",
            "fr": "chansons",
            "zh": "歌曲",
            "hi": "गाने",
            "ar": "أغاني",
            "bn": "গানসমূহ",
            "pt": "músicas",
            "ru": "песни"
        ],
        "resetConfirm": [
            "pl": "Zostaną usunięte wszystkie utwory, playlisty oraz ustawienia aplikacji. Napewno usunąć?",
            "en": "All application data will be reset. Are you sure?",
            "es": "Todos los datos de la aplicación se restablecerán. ¿Estás seguro?",
            "fr": "Toutes les données de l'application seront réinitialisées. Êtes-vous sûr ?",
            "zh": "所有应用数据都将被重置。确定吗？",
            "hi": "सभी ऐप डेटा रीसेट हो जाएगा। क्या आप सुनिश्चित हैं?",
            "ar": "سيتم إعادة تعيين جميع بيانات التطبيق. هل أنت متأكد؟",
            "bn": "সব অ্যাপ ডেটা রিসেট হবে। আপনি কি নিশ্চিত?",
            "pt": "Todos os dados do aplicativo serão redefinidos. Tem certeza?",
            "ru": "Все данные приложения будут сброшены. Вы уверены?"
        ],
        "shareApp": [
            "pl": "Udostępnij aplikację",
            "en": "Share app",
            "es": "Compartir aplicación",
            "fr": "Partager l'application",
            "zh": "分享应用",
            "hi": "ऐप साझा करें",
            "ar": "شارك التطبيق",
            "bn": "অ্যাপ শেয়ার করুন",
            "pt": "Compartilhar app",
            "ru": "Поделиться приложением"
        ],
        "resetColors": [
            "pl": "Przywróć domyślne kolory",
            "en": "Reset colors",
            "es": "Restablecer colores",
            "fr": "Réinitialiser les couleurs",
            "zh": "重置颜色",
            "hi": "रंग रीसेट करें",
            "ar": "إعادة تعيين الألوان",
            "bn": "রং রিসেট করুন",
            "pt": "Redefinir cores",
            "ru": "Сбросить цвета"
        ],
        "color": [
            "pl": "Kolor",
            "en": "Color",
            "es": "Color",
            "fr": "Couleur",
            "zh": "颜色",
            "hi": "रंग",
            "ar": "لون",
            "bn": "রং",
            "pt": "Cor",
            "ru": "Цвет"
        ],
        "AppColors": [
            "pl": "Kolory aplikacji",
            "en": "App colors",
            "es": "Colores de la aplicación",
            "fr": "Couleurs de l'application",
            "zh": "应用颜色",
            "hi": "ऐप के रंग",
            "ar": "ألوان التطبيق",
            "bn": "অ্যাপের রং",
            "pt": "Cores do aplicativo",
            "ru": "Цвета приложения"
        ]
    ]

    /// Language display names used in the Settings picker.
    var languageNames: [String: String] = [
        "pl": "Polski",
        "en": "English",
        "es": "Español",
        "fr": "Français",
        "zh": "中文",
        "hi": "हिन्दी",
        "ar": "العربية",
        "bn": "বাংলা",
        "pt": "Português",
        "ru": "Русский"
    ]

    func displayName(for code: String) -> String {
        languageNames[code] ?? code
    }

    /// Returns a localized string for the provided key.
    /// Falls back to the key itself when missing.
    func t(_ key: String) -> String {
        translations[key]?[current] ?? key
    }

    /// Updates current language and persists the selection.
    func setLanguage(_ lang: String) {
        current = lang
        UserDefaults.standard.set(lang, forKey: "selectedLanguage")

        // Force UI refresh for any view observing this object.
        objectWillChange.send()
    }
}
