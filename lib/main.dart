// lib/main.dart - VERSI LENGKAP DENGAN API HEALTH CHECK

import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'package:http/http.dart' as http;
import 'package:responsive_message_app_flutter/providers/auth_provider.dart';
import 'package:responsive_message_app_flutter/providers/message_provider.dart';
import 'package:responsive_message_app_flutter/screen/landing_page.dart';
import 'package:responsive_message_app_flutter/screen/home_screen.dart';
import 'package:responsive_message_app_flutter/screen/login_screen.dart';
import 'package:responsive_message_app_flutter/screen/register_screen.dart';
import 'package:responsive_message_app_flutter/screen/admin/dashboard_screen.dart';
import 'package:responsive_message_app_flutter/screen/admin/settings_screen.dart';
import 'package:responsive_message_app_flutter/screen/admin/reports_screen.dart';
import 'screen/guru/followup_screen.dart';
import 'package:responsive_message_app_flutter/screen/user/send_message_screen.dart';
import 'package:responsive_message_app_flutter/screen/user/view_messages_screen.dart';
import 'package:responsive_message_app_flutter/screen/wakepsek/dashboard_screen.dart';
import 'package:responsive_message_app_flutter/services/auth_service.dart';
import 'package:responsive_message_app_flutter/utils/helpers.dart';
import 'utils/screen_presets.dart';
import 'utils/environment.dart';

// ✅ Global Key untuk ScaffoldMessenger
final GlobalKey<ScaffoldMessengerState> globalScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

// Custom ScrollBehavior untuk mendukung horizontal scroll dengan mouse
class CustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.unknown,
  };
}

// ============================================================
// API HEALTH CHECK - CEK KONEKSI DI AWAL
// ============================================================
class ApiHealthCheck {
  static Future<String> getActiveBaseUrl() async {
    print('🔍 Starting API Health Check...');
    
    final urls = [
      'http://192.168.18.7:8090',
      'http://192.168.18.7:8091', 
      'http://localhost:8090',
      'http://127.0.0.1:8090',
    ];
    
    for (var url in urls) {
      try {
        print('📡 Testing API at: $url');
        final testUrl = Uri.parse('$url/responsive-message-app/api/message_types/public_list.php');
        
        final response = await http.get(
          testUrl,
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 5));
        
        if (response.statusCode == 200) {
          final trimmedBody = response.body.trim();
          // Cek apakah response adalah JSON (bukan source code PHP)
          if (trimmedBody.startsWith('{') || trimmedBody.startsWith('[')) {
            try {
              final decoded = jsonDecode(trimmedBody);
              if (decoded['success'] == true) {
                print('✅ Active API found: $url (Response is valid JSON)');
                return url;
              } else {
                print('⚠️ API at $url returned success=false, but still trying...');
                // Meskipun success=false, API bisa diakses, tetap gunakan
                return url;
              }
            } catch (e) {
              print('⚠️ API at $url returned invalid JSON: $e');
              // Bukan JSON yang valid, coba URL berikutnya
              continue;
            }
          } else {
            print('⚠️ API at $url returned non-JSON response (PHP source code?)');
            // Response bukan JSON, coba URL berikutnya
            continue;
          }
        } else {
          print('❌ Failed: $url - HTTP ${response.statusCode}');
        }
      } catch (e) {
        print('❌ Failed: $url - Error: $e');
      }
    }
    
    // Jika semua gagal, return default
    print('⚠️ No active API found, using default: ${urls[0]}');
    return urls[0];
  }
  
  // Method untuk test koneksi cepat
  static Future<bool> testConnection(String baseUrl) async {
    try {
      final url = Uri.parse('$baseUrl/responsive-message-app/api/message_types/public_list.php');
      final response = await http.get(url).timeout(const Duration(seconds: 3));
      
      if (response.statusCode == 200) {
        final trimmedBody = response.body.trim();
        if (trimmedBody.startsWith('{') || trimmedBody.startsWith('[')) {
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

// ============================================================
// MAIN FUNCTION DENGAN API HEALTH CHECK
// ============================================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize date formatting
  await initializeDateFormatting('id_ID', null);
  
  // ✅ CEK API YANG AKTIF SEBELUM RUN APP
  print('🚀 Starting application...');
  final activeUrl = await ApiHealthCheck.getActiveBaseUrl();
  print('📍 Setting base URL to: $activeUrl');
  
  // ✅ Set environment dinamis berdasarkan API yang aktif
  Environment.setBaseUrl(activeUrl);
  
  // Verify environment is set correctly
  print('🔧 Environment baseUrl: ${Environment.baseUrl}');
  print('🔧 Environment baseUrlRoot: ${Environment.baseUrlRoot}');
  
  // ✅ Only initialize window_manager on desktop platforms
  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    await windowManager.ensureInitialized();
    
    // Set ukuran default untuk desktop (Windows/macOS/Linux)
    await windowManager.setSize(const Size(412, 915));
    await windowManager.setMinimumSize(const Size(320, 480));
    print('🪟 Window manager initialized for desktop');
  }
  // For Android/iOS/web, window_manager is NOT initialized
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MessageProvider()),
      ],
      child: MaterialApp(
        title: 'SMKN 12 Jakarta - RMA',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: globalScaffoldMessengerKey, // ✅ Gunakan global key
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        scrollBehavior: CustomScrollBehavior(),
        initialRoute: '/',
        onGenerateRoute: (settings) {
          print('🔀 Navigating to: ${settings.name}');
          
          switch (settings.name) {
            case '/':
              return MaterialPageRoute(builder: (_) => const AuthCheck());
            case '/landing':
              return MaterialPageRoute(builder: (_) => const LandingPage());
            case '/login':
              return MaterialPageRoute(builder: (_) => const LoginScreen());
            case '/register':
              return MaterialPageRoute(builder: (_) => const RegisterScreen());
            case '/home':
              return MaterialPageRoute(builder: (_) => const HomeScreen());
            case '/admin':
              return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());
            case '/settings':
              return MaterialPageRoute(builder: (_) => const SettingsScreen());
            case '/reports':
              return MaterialPageRoute(builder: (_) => const ReportsScreen());
            case '/guru':
              return MaterialPageRoute(builder: (_) => const FollowupScreen());
            case '/followup':
              return MaterialPageRoute(builder: (_) => const FollowupScreen());
            case '/dashboard-guru':
              return MaterialPageRoute(builder: (_) => const FollowupScreen());
            case '/send-message':
              return MaterialPageRoute(builder: (_) => const SendMessageScreen());
            case '/send_message':
              return MaterialPageRoute(builder: (_) => const SendMessageScreen());
            case '/view_messages':
              return MaterialPageRoute(builder: (_) => const ViewMessagesScreen());
            case '/view-messages':
              return MaterialPageRoute(builder: (_) => const ViewMessagesScreen());
            case '/riwayat':
              return MaterialPageRoute(builder: (_) => const ViewMessagesScreen());
            case '/wakepsek':
              return MaterialPageRoute(builder: (_) => const WakepsekDashboardScreen());
            case '/kepsek':
              return MaterialPageRoute(builder: (_) => const WakepsekDashboardScreen());
            default:
              return MaterialPageRoute(builder: (_) => const LandingPage());
          }
        },
      ),
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  bool _isChecking = true;
  bool _isAuthenticated = false;
  String? _userType;
  String? _apiError;

  @override
  void initState() {
    super.initState();
    _checkAuthAndApi();
  }

  Future<void> _checkAuthAndApi() async {
    // First check API connection
    await _checkApiConnection();
    
    // Then check authentication
    await _checkAuth();
  }
  
  Future<void> _checkApiConnection() async {
    print('🔍 Checking API connection...');
    final isConnected = await ApiHealthCheck.testConnection(Environment.baseUrlRoot);
    
    if (!isConnected && mounted) {
      setState(() {
        _apiError = 'Tidak dapat terhubung ke server. Silakan periksa koneksi Anda.';
      });
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Tidak dapat terhubung ke server. Beberapa fitur mungkin tidak berfungsi.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 5),
        ),
      );
    } else {
      print('✅ API connection successful');
    }
  }

  Future<void> _checkAuth() async {
    final isLoggedIn = await AuthService.isLoggedIn();
    String? userType = await AuthService.getUserType();
    final token = await AuthService.getToken();
    
    print('🔐 Auth Check - isLoggedIn: $isLoggedIn');
    print('🔐 Auth Check - userType: $userType');
    print('🔐 Auth Check - token exists: ${token != null}');
    
    if (!isLoggedIn) {
      setState(() {
        _isAuthenticated = false;
        _userType = null;
        _isChecking = false;
      });
      return;
    }
    
    setState(() {
      _isAuthenticated = true;
      _userType = userType;
      _isChecking = false;
    });
  }

  String _getRouteName() {
    switch (_userType) {
      case 'Admin': return '/admin';
      case 'Kepala_Sekolah': 
      case 'Wakil_Kepala': 
        return '/wakepsek';
      case 'Guru_BK': 
      case 'Guru_Humas': 
      case 'Guru_Kurikulum': 
      case 'Guru_Kesiswaan': 
      case 'Guru_Sarana': 
        return '/guru';
      case 'Guru': 
      case 'Siswa': 
      case 'Orang_Tua': 
        return '/home';
      default: 
        return '/landing';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              if (_apiError != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _apiError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.orange),
                  ),
                )
              else
                const Text('Memeriksa koneksi...'),
            ],
          ),
        ),
      );
    }
    
    if (_isAuthenticated && _userType != null) {
      Future.microtask(() {
        Navigator.pushReplacementNamed(context, _getRouteName());
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    } else {
      Future.microtask(() {
        Navigator.pushReplacementNamed(context, '/landing');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
  }
}