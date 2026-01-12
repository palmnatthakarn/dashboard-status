import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'google_auth_service.dart';
import 'multi_shop_service.dart';

class AuthRepository {
  // Base URL provided by the user
  static const String baseUrl = 'https://smlaicloudapi.dev.dedepos.com';

  // Static token storage for use by other services
  static String? _authToken;

  // Static username storage
  static String? _username;

  // Token expiry tracking
  static DateTime? _tokenExpiry;

  // Refresh token storage
  static String? _refreshToken;

  // Password storage for re-authentication (encrypted in production)
  static String? _password;

  final GoogleAuthService _googleAuthService = GoogleAuthService();

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
  static const String _tokenKey = 'auth_token';
  static const String _usernameKey = 'auth_username';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _passwordKey = 'auth_password';

  /// Check for existing session
  Future<bool> checkSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      final username = prefs.getString(_usernameKey);
      final refreshToken = prefs.getString(_refreshTokenKey);
      final password = prefs.getString(_passwordKey);

      if (token != null && token.isNotEmpty) {
        _authToken = token;
        _username = username;
        _refreshToken = refreshToken;
        _password = password;
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
    String? password,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_usernameKey, username);
      if (refreshToken != null) {
        await prefs.setString(_refreshTokenKey, refreshToken);
      }
      if (password != null) {
        await prefs.setString(_passwordKey, password);
      }
    } catch (e) {
      log('💥 Error persisting session: $e');
    }
  }

  Future<void> _clearSession() async {
    try {
      log('🧹 Clearing session from SharedPreferences...');
      final prefs = await SharedPreferences.getInstance();

      // Remove all auth-related keys
      final tokenRemoved = await prefs.remove(_tokenKey);
      final usernameRemoved = await prefs.remove(_usernameKey);
      final refreshTokenRemoved = await prefs.remove(_refreshTokenKey);
      final passwordRemoved = await prefs.remove(_passwordKey);

      log('🧹 Token removed: $tokenRemoved');
      log('🧹 Username removed: $usernameRemoved');
      log('🧹 Refresh token removed: $refreshTokenRemoved');
      log('🧹 Password removed: $passwordRemoved');

      // Verify all keys are removed
      final verifyToken = prefs.getString(_tokenKey);
      final verifyUsername = prefs.getString(_usernameKey);
      final verifyRefreshToken = prefs.getString(_refreshTokenKey);
      final verifyPassword = prefs.getString(_passwordKey);

      if (verifyToken == null &&
          verifyUsername == null &&
          verifyRefreshToken == null &&
          verifyPassword == null) {
        log('✅ All session data successfully cleared from SharedPreferences');
      } else {
        log(
          '⚠️ Warning: Some session data may still exist in SharedPreferences',
        );
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

  /// Refresh token using stored credentials
  Future<bool> refreshTokenWithCredentials() async {
    if (_refreshToken == null && _password == null) {
      log('❌ No refresh token or password available');
      return false;
    }

    log('🔄 Attempting to refresh token...');

    try {
      // Since API doesn't have /auth/refresh endpoint,
      // we'll re-login with stored credentials
      if (_username != null && _password != null) {
        final newToken = await login(_username!, _password!);
        return newToken.isNotEmpty;
      } else if (_refreshToken != null) {
        // If we have refresh_token but no password,
        // we can't re-authenticate
        log('⚠️ Have refresh_token but no password for re-auth');
        return false;
      }
    } catch (e) {
      log('💥 Token refresh failed: $e');
      return false;
    }

    return false;
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
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      log('📡 Login response status: ${response.statusCode}');
      log('📄 Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        log('📄 Full login response: $data');

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
          _password = password; // Store for re-authentication

          // Extract token expiry
          if (extractedToken != null) {
            _extractTokenExpiry(extractedToken);
          }

          await _persistSession(
            extractedToken ?? '',
            username,
            refreshToken: refreshToken,
            password: password,
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

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      log('📡 Login/email response status: ${response.statusCode}');
      log('📄 Login/email response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        log('📄 Full login/email response: $data');

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
        final response = await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
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
    _password = null;
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
