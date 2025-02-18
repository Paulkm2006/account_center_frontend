import 'dart:convert';
import 'package:account_center_frontend/main.dart';
import 'package:account_center_frontend/services/auth_service.dart';
import 'package:http/http.dart' as http;
import '../models/account.dart';

class AccountService {
  

  Future<List<ListAccount>> getAccounts() async {
    final response = await http.get(
      Uri.parse('$apiUrl/account'), 
      headers: {
        "Authorization": "Bearer ${AuthService().getJwtCookie()}",
        "Content-Type": "application/json; charset=UTF-8",
        "Accept": "application/json; charset=UTF-8",
      },
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(utf8.decode(response.bodyBytes));
      return jsonList.map((json) => ListAccount.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load accounts');
    }
  }
  
  Future<Account> getAccountDetail(String id) async {
    final response = await http.get(
      Uri.parse('$apiUrl/account/$id'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${AuthService().getJwtCookie()}'}
    );

    if (response.statusCode == 200) {
      final jsonItem =json.decode(utf8.decode(response.bodyBytes));
      return Account.fromJson(jsonItem);
    } else {
      throw Exception('Failed to load account detail');
    }
  }

  Future<bool> deleteAccount(String id) async {
    final response = await http.delete(
      Uri.parse('$apiUrl/account/$id'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${AuthService().getJwtCookie()}'}
    );
    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Failed to delete account');
    }
  }
}
