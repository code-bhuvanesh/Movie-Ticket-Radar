/// API configuration and constants for PVR Cinema API
class ApiConstants {
  static const String apiBase =
      'https://api3.pvrcinemas.com/api/v1/booking/content';
  static const String apiCities = '$apiBase/city';
  static const String apiNowShowing = '$apiBase/nowshowing';
  static const String apiSessions = '$apiBase/msessions';

  static const String telegramApiBase = 'https://api.telegram.org/bot';

  static const String defaultTimeRange = '08:00-24:00';
  static const String defaultCity = 'Chennai';

  static Map<String, String> get headers => {
    'authority': 'api3.pvrcinemas.com',
    'accept': 'application/json, text/plain, */*',
    'accept-language': 'en-GB,en;q=0.9',
    'appversion': '1.0',
    'authorization': 'Bearer',
    'chain': 'PVR',
    'city': 'Chennai',
    'content-type': 'application/json',
    'country': 'INDIA',
    'dnt': '1',
    'origin': 'https://www.pvrcinemas.com',
    'platform': 'WEBSITE',
    'priority': 'u=1, i',
    'sec-ch-ua': '"Brave";v="143", "Chromium";v="143", "Not A(Brand";v="24"',
    'sec-ch-ua-mobile': '?0',
    'sec-ch-ua-platform': '"Windows"',
    'sec-fetch-dest': 'empty',
    'sec-fetch-mode': 'cors',
    'sec-fetch-site': 'same-site',
    'sec-gpc': '1',
    'user-agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36',
  };
}

/// App-wide settings keys
class StorageKeys {
  static const String tasks = 'tasks';
  static const String enableWindowsNotif = 'notifications_windows';
  static const String enableTelegramNotif = 'notifications_telegram';
  static const String telegramBotToken = 'telegram_bot_token';
  static const String telegramChatId = 'telegram_chat_id';
  static const String timeRange = 'time_range';
  static const String isDarkTheme = 'is_dark_theme';
  static const String logs = 'logs';
}
