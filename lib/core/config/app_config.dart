import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static late String supabaseUrl;
  static late String supabaseAnonKey;
  static late String googleBooksApiKey;
  static late String googleWebClientId;

  static Future<void> init() async {
    await dotenv.load(fileName: '.env');
    supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
    supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
    googleBooksApiKey = dotenv.env['GOOGLE_BOOKS_API_KEY'] ?? '';
    googleWebClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? '';
  }
}
