import 'package:account_center_frontend/main.dart';
import 'package:http/http.dart' as http;
import 'package:web/web.dart';

class AuthService {
  Future<bool> checkJwtCookie() async {
    final jwt = getJwtCookie();
    if (jwt == null) {
      return false;
    }

    try {
      final response = await http.get(
        Uri.parse('$apiUrl/verify'),
        headers: {
          'Authorization': 'Bearer $jwt',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
  void setJwtCookie(String token) {
    final expirationDate = DateTime.now().add(const Duration(days: 7));
    final secure = window.location.protocol == 'https:' ? 'Secure;' : '';
    
    document.cookie = 'jwt=$token;'
        ' path=/;'
        ' expires=${exp.toUtc()};'
        ' $secure'
        ' SameSite=Strict;'
        ' domain=${window.location.hostname};';
  }

  String? getJwtCookie() {
    try {
      final cookies = document.cookie.split(';');
      for (final cookie in cookies) {
        final parts = cookie.trim().split('=');
        if (parts[0] == 'jwt') {
          return Uri.decodeComponent(parts[1]);
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }
}
