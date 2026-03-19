import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'google_auth_service.dart';
import 'multi_shop_service.dart';

class AuthRepository {
  // Base URL is injected via --dart-define=BASE_URL=...
  // Dev launch config:  --dart-define=BASE_URL=https://api.dev.dedepos.com
  // Prod launch config: --dart-define=BASE_URL=https://api.dedepos.com
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://smlaicloudapi.dev.dedepos.com',
  );

  // Static token storage for use by other services
  static String? _authToken;

  // Static username storage
  static String? _username;

  // Token expiry tracking
  static DateTime? _tokenExpiry;

  // Refresh token storage
  static String? _refreshToken;

  final GoogleAuthService _googleAuthService = GoogleAuthService();

  /// Secure storage for sensitive data (iOS Keychain / Android Keystore)
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Get the current auth token
  static String? get token => _authToken;

  /// Get the current username
  static String? get username => _username;

  /// Check if user is authenticated
  static bool get isAuthenticated =>
      _authToken != null && _authToken!.isNotEmpty;

  /// Check if token is expired or about to expire (within 5 minutes)
  static bool get isTokenExpired {
    if (_authToken == null || _authToken!.isEmpty) return true;

    // Try to get expiry if we don't have it yet
    if (_tokenExpiry == null) {
      _extractTokenExpiry(_authToken!);
    }

    // If we still don't have expiry info (non-JWT token), assume it's valid
    // and let the server decide
    if (_tokenExpiry == null) {
      log(
        'ℹ️ No token expiry info available (non-JWT token?), assuming token is valid',
      );
      return false;
    }

    // Check if expired or expiring within 5 minutes
    final now = DateTime.now();
    final bufferTime = now.add(const Duration(minutes: 5));
    final isExpiring = bufferTime.isAfter(_tokenExpiry!);

    if (isExpiring) {
      final timeLeft = _tokenExpiry!.difference(now);
      log('⏰ Token is expiring in ${timeLeft.inMinutes} minutes');
    }

    return isExpiring;
  }

  // Endpoints
  static const String loginEndpoint = '/login';
  static const String logoutEndpoint = '/logout';
  static const String _refreshEndpoint = '/refresh';

  // SharedPreferences keys (non-sensitive)
  static const String _usernameKey = 'auth_username';

  // SecureStorage keys (sensitive — stored in iOS Keychain / Android Keystore)
  static const String _tokenKey = 'secure_auth_token';
  static const String _refreshTokenKey = 'secure_refresh_token';

  /// Check for existing session
  Future<bool> checkSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Access token now lives in secure storage
      final token = await _secureStorage.read(key: _tokenKey);
      final username = prefs.getString(_usernameKey);
      // Refresh token is stored in secure storage (Keychain/Keystore)
      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);

      if (token != null && token.isNotEmpty) {
        _authToken = token;
        _username = username;
        _refreshToken = refreshToken;
        _extractTokenExpiry(token);
        log('🔐 Session restored for user: $_username');

        // Check if token is expired
        if (isTokenExpired && _refreshToken != null) {
          log('⏰ Token expired, attempting refresh...');
          final refreshed = await refreshTokenWithCredentials();
          return refreshed;
        }

        return true;
      }
    } catch (e) {
      log('💥 Error checking session: $e');
    }
    return false;
  }

  Future<void> _persistSession(
    String token,
    String username, {
    String? refreshToken,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_usernameKey, username);
      if (refreshToken != null) {
        // Store refresh_token in secure encrypted storage
        await _secureStorage.write(
          key: _refreshTokenKey,
          value: refreshToken,
        );
      }
    } catch (e) {
      log('💥 Error persisting session: $e');
    }
  }

  Future<void> _clearSession() async {
    try {
      log('🧹 Clearing session from SharedPreferences...');
      final prefs = await SharedPreferences.getInstance();

      // Remove non-sensitive keys from SharedPreferences
      final usernameRemoved = await prefs.remove(_usernameKey);

      // Remove both tokens from secure storage
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);

      log('🧹 Username removed: $usernameRemoved');
      log('🧹 Tokens removed from secure storage');

      final verifyUsername = prefs.getString(_usernameKey);
      if (verifyUsername == null) {
        log('✅ All session data successfully cleared');
      } else {
        log('⚠️ Warning: Some session data may still exist in SharedPreferences');
      }
    } catch (e) {
      log('💥 Error clearing session: $e');
      rethrow;
    }
  }

  /// Extract token expiry from JWT
  static void _extractTokenExpiry(String token) {
    try {
      if (JwtDecoder.isExpired(token)) {
        log('⚠️ Token is already expired');
        _tokenExpiry = DateTime.now().subtract(const Duration(days: 1));
        return;
      }

      final expiryDate = JwtDecoder.getExpirationDate(token);
      _tokenExpiry = expiryDate;

      final timeUntilExpiry = expiryDate.difference(DateTime.now());
      log('🕐 Token expires at: $expiryDate');
      log('⏳ Time until expiry: ${timeUntilExpiry.inMinutes} minutes');
    } catch (e) {
      log('💥 Error extracting token expiry: $e');
      _tokenExpiry = null;
    }
  }

  /// Refresh access token using stored refresh_token via POST /refresh.
  /// Returns true if a new token was obtained, false → caller should force re-login.
  Future<bool> refreshTokenWithCredentials() async {
    if (_refreshToken == null) {
      log('❌ No refresh token available — user must re-login');
      return false;
    }

    log('🔄 Calling POST $baseUrl$_refreshEndpoint to get new access token...');

    try {
      final url = '$baseUrl$_refreshEndpoint';
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'token': _refreshToken}),
          )
          .timeout(const Duration(seconds: 10));

      log('📡 Refresh response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['token'] != null) {
          final newToken = data['token'] as String;

          // Update access token in secure storage
          _authToken = newToken;
          _extractTokenExpiry(newToken);

          await _secureStorage.write(key: _tokenKey, value: newToken);

          log('✅ Token refreshed successfully (${newToken.length} chars)');
          return true;
        } else {
          log('⚠️ Refresh failed: ${data['message'] ?? 'Unknown error'}');
          return false;
        }
      } else {
        log('❌ Refresh failed with status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      log('💥 Token refresh error: $e');
      return false;
    }
  }

  Future<String> login(String username, String password) async {
    final url = '$baseUrl$loginEndpoint';
    // Often APIs like this require a tenant or shop ID, but for basic login
    // usually username/password is sent in body.
    // Assuming standard JSON body structure.

    log('🔐 Attempting login to $url');

    // Store username for display purposes
    _username = username;

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      log('📡 Login response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          // Assuming the token is in 'token' or 'data.token'
          // Based on common patterns in this project's other services
          String? extractedToken;
          if (data['data'] != null && data['data']['token'] != null) {
            extractedToken = data['data']['token'];
            log('🔑 Token found in data.data.token');
          } else if (data['token'] != null) {
            extractedToken = data['token'];
            log('🔑 Token found in data.token');
          } else {
            // Fallback: Return the whole body as "token" if we can't find specific field
            extractedToken = response.body;
            log('⚠️ No token field found!');
          }

          // Extract refresh_token if available
          String? refreshToken;
          if (data['data'] != null && data['data']['refresh_token'] != null) {
            refreshToken = data['data']['refresh_token'];
            log('🔄 Refresh token found in data.data.refresh_token');
          } else if (data['refresh_token'] != null) {
            refreshToken = data['refresh_token'];
            log('🔄 Refresh token found in data.refresh_token');
          }

          // Store the token for use by other services
          _authToken = extractedToken;
          _username = username;
          _refreshToken = refreshToken;

          // Extract token expiry
          if (extractedToken != null) {
            _extractTokenExpiry(extractedToken);
          }

          await _persistSession(
            extractedToken ?? '',
            username,
            refreshToken: refreshToken,
          );

          log('🔑 Stored token (${extractedToken?.length ?? 0} chars)');
          if (refreshToken != null) {
            log('🔄 Stored refresh token (${refreshToken.length} chars)');
          }

          return extractedToken ?? '';
        } else {
          throw Exception(data['message'] ?? 'Login failed');
        }
      } else {
        throw Exception('Login failed with status: ${response.statusCode}');
      }
    } catch (e) {
      log('💥 Login error: $e');
      rethrow;
    }
  }

  Future<String> loginWithGoogle() async {
    log('🔐 Attempting Google login');
    try {
      // Step 1: Sign in with Google/Firebase
      final userCredential = await _googleAuthService.signInWithGoogle();
      if (userCredential == null || userCredential.user == null) {
        throw Exception('Google Sign-In canceled or failed');
      }

      final user = userCredential.user!;
      final email = user.email;

      if (email == null || email.isEmpty) {
        throw Exception('No email found in Google account');
      }

      log('📧 Google user email: $email');

      // Step 2: Prepare login request
      // Note: We can't call listShops() here because it requires a token
      // Using a default/placeholder shopid - user can select actual shop after login
      final shopId = '1'; // Default shop ID, will be updated after login
      log(
        '🏪 Using default shopid: $shopId (will select actual shop after login)',
      );

      // Step 3: Exchange email for backend token using /login/email endpoint
      final url = '$baseUrl/login/email';
      log('🔄 Exchanging Google email for backend token at: $url');

      final requestBody = {
        'email': email,
        'username': email, // Use email as username
        'shopid': shopId,
      };
      log('📤 Request body: $requestBody');

      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 15));

      log('📡 Login/email response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          // Extract backend token
          String? extractedToken;
          if (data['data'] != null && data['data']['token'] != null) {
            extractedToken = data['data']['token'];
            log('🔑 Backend token found in data.data.token');
          } else if (data['token'] != null) {
            extractedToken = data['token'];
            log('🔑 Backend token found in data.token');
          } else {
            log('⚠️ No token field found in response!');
            throw Exception('No token in response');
          }

          // Extract refresh_token if available
          String? refreshToken;
          if (data['data'] != null && data['data']['refresh_token'] != null) {
            refreshToken = data['data']['refresh_token'];
            log('🔄 Refresh token found in data.data.refresh_token');
          } else if (data['refresh_token'] != null) {
            refreshToken = data['refresh_token'];
            log('🔄 Refresh token found in data.refresh_token');
          }

          // Step 3: Store backend token (not Firebase token)
          _authToken = extractedToken;
          _username = email;
          _refreshToken = refreshToken;

          // Extract token expiry
          if (extractedToken != null) {
            _extractTokenExpiry(extractedToken);
          }

          await _persistSession(
            extractedToken ?? '',
            email,
            refreshToken: refreshToken,
          );

          log('🔑 Stored backend token (${extractedToken?.length ?? 0} chars)');
          if (refreshToken != null) {
            log('🔄 Stored refresh token (${refreshToken.length} chars)');
          }
          log('✅ Google Login Successful. User: $email');

          return extractedToken ?? '';
        } else {
          throw Exception(data['message'] ?? 'Login with email failed');
        }
      } else {
        throw Exception(
          'Login with email failed with status: ${response.statusCode}',
        );
      }
    } catch (e) {
      log('💥 Google Login error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    log('🔓 Starting logout process...');

    // Store token before clearing for API call
    final token = _authToken;

    // Step 1: Call logout API if token exists
    final url = '$baseUrl$logoutEndpoint';
    try {
      if (token != null && token.isNotEmpty) {
        log('🔓 Calling logout API with token...');
        final response = await http
            .post(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
            )
            .timeout(const Duration(seconds: 10));
        log('📡 Logout response status: ${response.statusCode}');
        if (response.statusCode == 200) {
          log('✅ Logout API call successful');
        } else {
          log('⚠️ Logout API returned: ${response.statusCode}');
        }
      }
    } catch (e) {
      log('💥 Logout API error (continuing anyway): $e');
    }

    // Step 2: Clear SharedPreferences FIRST (most important for persistence)
    log('🔓 Clearing SharedPreferences...');
    await _clearSession();

    // Step 3: Clear static variables in memory
    log('🔓 Clearing static variables...');
    _authToken = null;
    _username = null;
    _refreshToken = null;
    _tokenExpiry = null;
    log('✅ All static variables cleared');

    // Step 4: Reset shop selection state
    log('🔓 Resetting shop selection...');
    MultiShopService.resetShopSelection();

    // Step 5: Sign out from Google/Firebase
    try {
      log('🔓 Signing out from Google/Firebase...');
      await _googleAuthService.signOut();
      log('✅ Google/Firebase sign out successful');
    } catch (e) {
      log('💥 Google Logout error: $e');
    }

    log('✅ Logout process completed successfully');
  }
}
